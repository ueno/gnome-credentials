namespace Credentials {
    class SshViewAdapter : ViewAdapter {
        public override void attached (Backend backend, ListPanel list_panel) {
            backend.collection_added.connect ((collection) => {
                    var key_list_panel = (KeyListPanel) list_panel;
                    key_list_panel.register_generator_action_for_collection (collection);
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

        public override GeneratorDialog create_generator_dialog (Collection collection) {
            return new SshGeneratorDialog (collection);
        }
    }
}
