namespace Credentials {
    class GpgWidgetFactory : GenerativeWidgetFactory {
        public override Gtk.Widget create_list_box_row (Item _item) {
            var item = (GpgItem) _item;
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);

            var heading = new Gtk.Label (item.get_label ());
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

        public override GeneratorDialog create_generator_dialog (GenerativeCollection collection) {
            return new GpgGeneratorDialog (collection);
        }
    }
}
