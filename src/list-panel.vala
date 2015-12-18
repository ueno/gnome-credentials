namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/list-panel.ui")]
    abstract class ListPanel : Gtk.Stack {
        [GtkChild]
        Gtk.ScrolledWindow scrolled_window;

        [GtkChild]
        protected Gtk.ListBox list_box;

        GLib.ListStore _store;
        GLib.ListStore _filtered_store;
        Backend[] _backends;
        GLib.HashTable<Backend,ViewAdapter> _adapters;

        GLib.SimpleActionGroup _selection_actions;

        public bool selection_mode { construct set; get; default = false; }

        public GLib.List<Item> get_selected_items () {
            GLib.List<Item> result = null;
            for (var i = 0; i < this._store.get_n_items (); i++) {
                var row = list_box.get_row_at_index (i);
                var item = (Item) this._store.get_item (i);
                var children = row.get_children ();
                var container = (Gtk.Container) children.first ().data;
                foreach (var child in container.get_children ()) {
                    var check_button = child as Gtk.CheckButton;
                    if (check_button == null)
                        continue;
                    if (check_button.active) {
                        result.append (item);
                        break;
                    }
                }
            }
            return result;
        }

        construct {
            this._selection_actions = new GLib.SimpleActionGroup ();
            var action = new GLib.SimpleAction ("publish-selected", null);
            action.activate.connect (() => { publish_selected.begin (); });
            this._selection_actions.add_action (action);

            action = new GLib.SimpleAction ("export-selected", null);
            action.activate.connect (() => { export_selected.begin (); });
            this._selection_actions.add_action (action);

            action = new GLib.SimpleAction ("delete-selected", null);
            action.activate.connect (() => { delete_selected.begin (); });
            this._selection_actions.add_action (action);

            action = new GLib.SimpleAction ("select-all", null);
            action.activate.connect ((v) => { select_all (); });
            this._selection_actions.add_action (action);

            action = new GLib.SimpleAction ("unselect-all", null);
            action.activate.connect ((v) => { unselect_all (); });
            this._selection_actions.add_action (action);

            this._store = new GLib.ListStore (typeof (Item));
            this._filtered_store = new GLib.ListStore (typeof (Item));
            this._backends = {};
            this._adapters = new GLib.HashTable<Backend,ViewAdapter> (null, null);

            list_box.bind_model (this._store, this.create_item_widget);
            list_box.set_header_func (list_box_update_header_func);
            list_box.row_activated.connect (row_activated);
            list_box_setup_scrolling (list_box, 0, scrolled_window);

            notify["selection-mode"].connect (() => {
                    selection_changed ();
                });

            bind_property ("selection-mode",
                           list_box, "activate-on-single-click",
                           GLib.BindingFlags.SYNC_CREATE |
                           GLib.BindingFlags.INVERT_BOOLEAN);

            map.connect (on_map);
        }

        struct ItemSelection {
            GenericArray<Item> items;
        }

        async void publish_selected () {
            var window = (Gtk.Window) get_toplevel ();
            var items = get_selected_items ();
            var selections = new GLib.HashTable<Collection,ItemSelection?> (null, null);
            foreach (var item in items) {
                if (!selections.contains (item.collection)) {
                    var selection = ItemSelection () { items = new GenericArray<Item> () };
                    selections.insert (item.collection, selection);
                }
                var selection = selections.lookup (item.collection);
                selection.items.add (item);
            }
            var iter = GLib.HashTableIter<Collection,ItemSelection?> (selections);
            Collection collection;
            ItemSelection? selection;
            while (iter.next (out collection, out selection)) {
                try {
                    yield collection.export_to_server (selection.items.data,
                                                       null);
                } catch (GLib.Error e) {
                    Utils.show_error (window,
                                      _("Couldn't publish items: %s"),
                                      e.message);
                    return;
                }
            }
            Utils.show_notification (window, _("Published items"));
        }

        async void export_selected () {
            var window = (Gtk.Window) get_toplevel ();
            var items = get_selected_items ();
            var selections = new GLib.HashTable<Collection,ItemSelection?> (null, null);
            foreach (var item in items) {
                if (!selections.contains (item.collection)) {
                    var selection = ItemSelection () { items = new GenericArray<Item> () };
                    selections.insert (item.collection, selection);
                }
                var selection = selections.lookup (item.collection);
                selection.items.add (item);
            }
            var iter = GLib.HashTableIter<Collection,ItemSelection?> (selections);
            Collection collection;
            ItemSelection? selection;
            while (iter.next (out collection, out selection)) {
                var dialog = new Gtk.FileChooserDialog (
                    _("Export %s").printf (collection.item_type),
                    window,
                    Gtk.FileChooserAction.SAVE,
                    _("_Cancel"),
                    Gtk.ResponseType.CANCEL,
                    _("_Export"),
                    Gtk.ResponseType.ACCEPT);

                var res = dialog.run ();
                if (res == Gtk.ResponseType.ACCEPT) {
                    try {
                        var bytes = yield collection.export_to_bytes (
                            selection.items.data, null);
                        var path = dialog.get_filename ();
                        var file = GLib.File.new_for_path (path);
                        file.replace_contents (bytes.get_data (),
                                               null,
                                               true,
                                               GLib.FileCreateFlags.NONE,
                                               null,
                                               null);
                        Utils.show_notification (
                            window,
                            _("Exported %s items").printf (collection.item_type));
                    } catch (GLib.Error e) {
                        Utils.show_error (
                            window,
                            _("Couldn't export items: %s"),
                            e.message);
                    }
                }
                dialog.destroy ();
            }
        }

        async void delete_selected () {
            var window = (Gtk.Window) get_toplevel ();
            var items = get_selected_items ();
            foreach (var item in items) {
                try {
                    yield item.delete (null);
                } catch (GLib.Error e) {
                    Utils.show_error (window,
                                      _("Couldn't delete items: %s"),
                                      e.message);
                    return;
                }
            }
            Utils.show_notification (window, _("Deleted items"));
        }

        void select_all () {
            set_selection_active (true);
        }

        void unselect_all () {
            set_selection_active (false);
        }

        void set_selection_active (bool active) {
            for (var i = 0; i < this._store.get_n_items (); i++) {
                var row = list_box.get_row_at_index (i);
                var children = row.get_children ();
                var container = (Gtk.Container) children.first ().data;
                foreach (var child in container.get_children ()) {
                    var check_button = child as Gtk.CheckButton;
                    if (check_button == null)
                        continue;
                    check_button.active = active;
                }
            }
        }

        void on_map () {
            var toplevel = (Window) get_toplevel ();
            toplevel.insert_action_group ("list-panel",
                                          this._selection_actions);
        }

        public override void constructed () {
            base.constructed ();
            load.begin ();
        }

        public async void filter_items (string[] words,
                                        GLib.Cancellable cancellable)
        {
            this._filtered_store.remove_all ();
            list_box.bind_model (this._filtered_store, this.create_item_widget);
            cancellable.connect (() => {
                    list_box.bind_model (this._store, this.create_item_widget);
                    this.visible_child_name = "listing";
                    list_box_adjust_scrolling (list_box, false);
                });
            for (var i = 0; i < this._store.get_n_items (); i++) {
                var item = (Item) this._store.get_item (i);
                if (item.match (words))
                    this._filtered_store.append (item);
            }
            if (this._filtered_store.get_n_items () == 0)
                this.visible_child_name = "unavailable";
            else
                this.visible_child_name = "listing";
            list_box_adjust_scrolling (list_box, false);
        }

        protected virtual void register_backend (Backend backend,
                                                 ViewAdapter adapter)
        {
            this._backends += backend;
            backend.collection_added.connect (on_collection_added);
            backend.collection_removed.connect (on_collection_removed);
            this._adapters.set (backend, adapter);
            adapter.attached (backend, this);
        }

        protected ViewAdapter get_view_adapter (Backend backend) {
            return this._adapters.lookup (backend);
        }

        void on_collection_added (Collection collection) {
            collection.item_added.connect (on_item_added);
            collection.item_removed.connect (on_item_removed);
            collection.load_items.begin (null);
            sync_visible_child ();
        }

        void on_collection_removed (Collection collection) {
            for (var i = 0; i < this._store.get_n_items (); i++) {
                var item = (Item) this._store.get_item (i);
                if (item.collection == collection)
                    this._store.remove (i);
            }
            sync_visible_child ();
        }

        void on_item_added (Item item) {
            this._store.insert_sorted (item, (a, b) => {
                    var item1 = (Item) a;
                    var item2 = (Item) b;
                    return item1.compare (item2);
                });
            item.changed.connect (() => {
                    for (var i = 0; i < this._store.get_n_items (); i++) {
                        if (this._store.get_item (i) == item) {
                            this._store.items_changed (i, 1, 1);
                            list_box_adjust_scrolling (list_box, false);
                        }
                    }
                });
            sync_visible_child ();
        }

        void on_item_removed (Item item) {
            for (var i = 0; i < this._store.get_n_items (); i++) {
                if (this._store.get_item (i) == item) {
                    this._store.remove (i);
                    sync_visible_child ();
                }
            }
        }

        void sync_visible_child () {
            if (this._store.get_n_items () == 0)
                this.visible_child_name = "empty";
            else
                this.visible_child_name = "listing";
            list_box_adjust_scrolling (list_box, false);
        }

        async void load () {
            this._store.remove_all ();
            foreach (var backend in this._backends) {
                try {
                    yield backend.load_collections (null);
                } catch (GLib.Error e) {
                    warning ("cannot load collections: %s", e.message);
                    continue;
                }
            }
        }

        Gtk.Widget create_item_widget (GLib.Object object) {
            var backend = ((Item) object).collection.backend;
            var adapter = this._adapters.lookup (backend);
            var overlay = new Gtk.Overlay ();
            var check_button = new Gtk.CheckButton ();
            bind_property ("selection-mode",
                           check_button, "visible",
                           GLib.BindingFlags.SYNC_CREATE);
            notify["selection-mode"].connect (() => {
                    if (!selection_mode)
                        check_button.active = false;
                });
            check_button.halign = Gtk.Align.START;
            check_button.toggled.connect (on_check_button_toggled);
            overlay.add_overlay (check_button);

            var row = adapter.create_list_box_row ((Item) object);
            row.margin_left = 12;
            row.margin_right = 12;
            overlay.add (row);
            return overlay;
        }

        public signal void selection_changed ();

        void on_check_button_toggled () {
            selection_changed ();
        }

        void row_activated (Gtk.ListBox list_box, Gtk.ListBoxRow? row) {
            if (row != null) {
                var item = (Item) this._store.get_item (row.get_index ());
                item.load_content.begin (
                    null,
                    (obj, res) => {
                        try {
                            item.load_content.end (res);
                        } catch (GLib.Error e) {
                            warning ("failed to load content: %s", e.message);
                        }
                        var backend = item.collection.backend;
                        var adapter = this._adapters.lookup (backend);
                        var dialog = adapter.create_editor_dialog (item);
                        dialog.response.connect_after ((res) => {
                                dialog.destroy ();
                            });
                        dialog.set_transient_for (
                            (Gtk.Window) this.get_toplevel ());
                        dialog.show ();
                    });
            }
        }
    }
}
