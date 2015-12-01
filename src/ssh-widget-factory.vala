namespace Credentials {
    class SshWidgetFactory : GenerativeWidgetFactory {
        public SshWidgetFactory (Backend backend) {
            Object (backend: backend);
        }

        public override void attached (ListPanel list_panel) {
            backend.collection_added.connect ((collection) => {
                    var key_list_panel = (KeyListPanel) list_panel;
                    var action = new GLib.SimpleAction (collection.name, null);
                    action.activate.connect (() => {
                            show_generator_dialog ((Gtk.Window) list_panel.get_toplevel (),
                                                   (GenerativeCollection) collection);
                        });
                    key_list_panel.register_generator_action (action);
                });
        }

        public override Gtk.Widget create_list_box_row (Item _item) {
            var item = (SshItem) _item;
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);

            var heading_label = new Gtk.Label (item.get_label ());
            var context = heading_label.get_style_context ();
            context.add_class ("key-list-heading");
            heading_label.xalign = 0;
            heading_label.set_ellipsize (Pango.EllipsizeMode.END);
            box.pack_start (heading_label, false, false, 0);

            var name_label = new Gtk.Label (item.collection.item_type);
            context = name_label.get_style_context ();
            context.add_class ("key-list-type");
            context.add_class ("dim-label");
            box.pack_end (name_label, false, false, 0);
            box.show_all ();
            return box;
        }

        public override EditorDialog create_editor_dialog (Item item) {
            return new SshEditorDialog ((SshItem) item);
        }

        public override GeneratorDialog create_generator_dialog (GenerativeCollection collection) {
            return new SshGeneratorDialog (collection);
        }
    }
}
