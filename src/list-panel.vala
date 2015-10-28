namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/list-panel.ui")]
    abstract class ListPanel : Gtk.Stack {
        [GtkChild]
        protected Gtk.ListBox list_box;

        GLib.ListStore _store;
        GLib.ListStore _filtered_store;
        Backend[] _backends;
        GLib.HashTable<Backend,WidgetFactory> _factories;
        Generator[] _generators;
        GLib.Menu _generator_menu;
        Gtk.Popover _generator_popover;

        construct {
            this._store = new GLib.ListStore (typeof (Item));
            this._filtered_store = new GLib.ListStore (typeof (Item));
            this._backends = {};
            this._factories = new GLib.HashTable<Backend,WidgetFactory> (null,
                                                                         null);
            this._generators = {};
            this._generator_menu = new GLib.Menu ();
            this._generator_popover = new Gtk.Popover (null);
            this._generator_popover.bind_model (this._generator_menu, "key");
            map.connect (on_map);

            list_box.bind_model (this._store, this.create_item_widget);
            list_box.set_header_func (list_box_update_header_func);
            list_box.set_selection_mode (Gtk.SelectionMode.NONE);
            list_box.set_activate_on_single_click (true);
            list_box.row_activated.connect (row_activated);
            list_box_setup_scrolling (list_box, 0);
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
                });
            for (var i = 0; i < this._store.get_n_items (); i++) {
                var item = (Item) this._store.get_item (i);
                if (item.match (words))
                    this._filtered_store.append (item);
            }
            if (this._filtered_store.get_n_items () == 0)
                this.visible_child_name = "unavailable";
            list_box_adjust_scrolling (list_box);
        }

        void on_map () {
            Window toplevel = (Window) this.get_toplevel ();
            toplevel.new_button.set_popover (this._generator_popover);

            var group = new GLib.SimpleActionGroup ();
            ((GLib.ActionMap) group).add_action_entries (actions, this);
            toplevel.insert_action_group ("key", group);
        }

        protected void register_backend (Backend backend,
                                         WidgetFactory factory)
        {
            this._backends += backend;
            backend.collection_added.connect (on_collection_added);
            backend.collection_removed.connect (on_collection_removed);
            this._factories.set (backend, factory);
        }

        void on_collection_added (Collection collection) {
            collection.item_added.connect (on_item_added);
            collection.item_removed.connect (on_item_removed);
            collection.load_items.begin ();
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
                            list_box_adjust_scrolling (list_box);
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
            list_box_adjust_scrolling (list_box);
            if (this._store.get_n_items () == 0)
                this.visible_child_name = "empty";
            else
                this.visible_child_name = "listing";
        }

        void activate_generate (GLib.SimpleAction action,
                                GLib.Variant? parameter)
        {
            var index = parameter.get_uint32 ();

            var generator = this._generators[index];
            var factory = generator.get_data<WidgetFactory> (
                "credentials-widget-factory");
            var dialog = factory.create_generator_dialog (generator);
            return_if_fail (dialog != null);
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.set_transient_for ((Gtk.Window) this.get_toplevel ());
            dialog.show ();
        }

        static const GLib.ActionEntry[] actions = {
            { "generate", activate_generate, "u", null, null }
        };

        void register_generator (Generator generator, Backend backend) {
            var index = this._generators.length;
            this._generators += generator;

            var item = new GLib.MenuItem (
                _("Generate %s").printf (generator.item_type), null);
            item.set_action_and_target ("generate", "u", index);
            this._generator_menu.append_item (item);

            var factory = this._factories.lookup (backend);
            generator.set_data<WidgetFactory> ("credentials-widget-factory",
                                               factory);
        }

        async void load () {
            this._store.remove_all ();
            this._generators = {};
            this._generator_menu.remove_all ();
            foreach (var backend in this._backends) {
                try {
                    yield backend.load_collections ();
                } catch (GLib.Error e) {
                    warning ("cannot load collections: %s", e.message);
                    continue;
                }
                var collections = backend.get_collections ();
                foreach (var collection in collections) {
                    if (collection is Generator)
                        register_generator ((Generator) collection, backend);
                }
            }
        }

        Gtk.Widget create_item_widget (GLib.Object object) {
            var backend = ((Item) object).collection.backend;
            var factory = this._factories.lookup (backend);
            return factory.create_list_box_row ((Item) object);
        }

        void row_activated (Gtk.ListBox list_box, Gtk.ListBoxRow? row) {
            if (row != null) {
                var item = (Item) this._store.get_item (row.get_index ());
                var factory = this._factories.lookup (item.collection.backend);
                var dialog = factory.create_editor_dialog (item);
                dialog.response.connect_after ((res) => {
                        dialog.destroy ();
                    });
                dialog.set_transient_for (
                    (Gtk.Window) this.get_toplevel ());
                dialog.show ();
            }
        }
    }
}
