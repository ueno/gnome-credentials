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

        GLib.List<Item> get_selected_items () {
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

            action = new GLib.SimpleAction ("delete-selected", null);
            action.activate.connect (() => { delete_selected.begin (); });
            this._selection_actions.add_action (action);

            this._store = new GLib.ListStore (typeof (Item));
            this._filtered_store = new GLib.ListStore (typeof (Item));
            this._backends = {};
            this._adapters = new GLib.HashTable<Backend,ViewAdapter> (null, null);

            list_box.bind_model (this._store, this.create_item_widget);
            list_box.set_header_func (list_box_update_header_func);
            list_box.set_selection_mode (Gtk.SelectionMode.NONE);
            list_box.set_activate_on_single_click (true);
            list_box.row_activated.connect (row_activated);
            list_box_setup_scrolling (list_box, 0, scrolled_window);

            map.connect (on_map);
        }

        async void publish_selected () {
            var window = (Gtk.Window) get_toplevel ();
            var items = get_selected_items ();
            foreach (var item in items) {
                try {
                    yield item.publish (null);
                } catch (GLib.Error e) {
                    Utils.show_error (window,
                                      "Couldn't publish items: %s",
                                      e.message);
                    return;
                }
            }
            Utils.show_notification (window, "Published items");
        }

        async void delete_selected () {
            var window = (Gtk.Window) get_toplevel ();
            var items = get_selected_items ();
            foreach (var item in items) {
                try {
                    yield item.delete (null);
                } catch (GLib.Error e) {
                    Utils.show_error (window,
                                      "Couldn't delete items: %s",
                                      e.message);
                    return;
                }
            }
            Utils.show_notification (window, "Deleted items");
        }

        void on_map () {
            var toplevel = (Window) get_toplevel ();
            toplevel.insert_action_group ("list-panel", this._selection_actions);
            toplevel.selection_mode_toggle_button.bind_property (
                "active",
                this, "selection-mode",
                GLib.BindingFlags.SYNC_CREATE);
            toplevel.selection_mode_toggle_button.bind_property (
                "active",
                toplevel.selection_bar, "reveal-child",
                GLib.BindingFlags.SYNC_CREATE);
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
            adjust_view ();
        }

        void on_collection_removed (Collection collection) {
            for (var i = 0; i < this._store.get_n_items (); i++) {
                var item = (Item) this._store.get_item (i);
                if (item.collection == collection)
                    this._store.remove (i);
            }
            adjust_view ();
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
            adjust_view ();
        }

        void on_item_removed (Item item) {
            for (var i = 0; i < this._store.get_n_items (); i++) {
                if (this._store.get_item (i) == item) {
                    this._store.remove (i);
                    adjust_view ();
                }
            }
        }

        void adjust_view () {
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
            overlay.add_overlay (check_button);

            var row = adapter.create_list_box_row ((Item) object);
            row.margin_left = 12;
            row.margin_right = 12;
            overlay.add (row);
            return overlay;
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
                        var adapter = this._adapters.lookup (item.collection.backend);
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
