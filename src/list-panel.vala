namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/list-panel.ui")]
    abstract class ListPanel : Gtk.Box {
        [GtkChild]
        protected Gtk.ListBox list_box;

        protected GLib.ListStore _store;
        protected Backend[] _backends;
        protected GLib.HashTable<Backend,WidgetFactory> _factories;

        construct {
            this._store = new GLib.ListStore (typeof (Item));
            this._backends = {};
            this._factories = new GLib.HashTable<Backend,WidgetFactory> (null,
                                                                         null);

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

        protected uint register_backend (Backend backend,
                                         WidgetFactory factory)
        {
            var index = this._backends.length;
            this._backends += backend;
            backend.collection_added.connect (on_collection_added);
            backend.collection_removed.connect (on_collection_removed);
            this._factories.set (backend, factory);
            return index;
        }

        protected Backend get_backend (uint index) {
            return this._backends[index];
        }

        protected WidgetFactory get_widget_factory (Backend backend) {
            return this._factories.lookup (backend);
        }

        void on_collection_added (Collection collection) {
            collection.item_added.connect (on_item_added);
            collection.item_removed.connect (on_item_removed);
            collection.load_items.begin ();
        }

        void on_collection_removed (Collection collection) {
            for (var i = 0; i < this._store.get_n_items (); i++) {
                var item = (Item) this._store.get_item (i);
                if (item.collection == collection)
                    this._store.remove (i);
            }
            list_box_adjust_scrolling (list_box);
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
            list_box_adjust_scrolling (list_box);
        }

        void on_item_removed (Item item) {
            for (var i = 0; i < this._store.get_n_items (); i++) {
                if (this._store.get_item (i) == item) {
                    this._store.remove (i);
                    list_box_adjust_scrolling (list_box);
                }
            }
        }

        async void load () {
            this._store.remove_all ();
            foreach (var backend in this._backends) {
                backend.load_collections.begin ();
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
