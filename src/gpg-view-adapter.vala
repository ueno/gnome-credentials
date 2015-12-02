namespace Credentials {
    class GpgViewAdapter : ViewAdapter {
        public override void attached (Backend backend, ListPanel list_panel) {
            backend.collection_added.connect ((collection) => {
                    var key_list_panel = (KeyListPanel) list_panel;
                    var action = new GLib.SimpleAction ("locate", null);
                    action.activate.connect (() => {
                            show_fetcher_dialog ((Gtk.Window) list_panel.get_toplevel (),
                                                 (GpgCollection) collection);
                        });
                    key_list_panel.register_generator_action (action);
                    key_list_panel.register_generator_action_for_collection (collection);
                });
        }

        public override Gtk.Widget create_list_box_row (Item _item) {
            var item = (GpgItem) _item;
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);

            var heading = new Gtk.Label (Utils.escape_invalid_chars (item.get_label ()));
            var context = heading.get_style_context ();
            context.add_class ("key-list-heading");
            heading.xalign = 0;
            heading.set_ellipsize (Pango.EllipsizeMode.END);
            box.pack_start (heading, false, false, 0);

            var protocol = ((GpgCollection) item.collection).protocol;
            var name = new Gtk.Label (_("%s Key").printf (GpgUtils.format_protocol (protocol)));
            context = name.get_style_context ();
            context.add_class ("key-list-type");
            context.add_class ("dim-label");
            box.pack_end (name, false, false, 0);
            box.show_all ();
            return box;
        }

        public override EditorDialog create_editor_dialog (Item item) {
            return new GpgEditorDialog (item);
        }

        void show_fetcher_dialog (Gtk.Window transient_for,
                                  GpgCollection collection)
        {
            var dialog = create_fetcher_dialog (collection);
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.set_transient_for (transient_for);
            dialog.show ();
        }

        Gtk.Dialog create_fetcher_dialog (GpgCollection collection) {
            return new GpgFetcherDialog (collection);
        }

        public override GeneratorDialog create_generator_dialog (Collection collection) {
            return new GpgGeneratorDialog (collection);
        }
    }
}
