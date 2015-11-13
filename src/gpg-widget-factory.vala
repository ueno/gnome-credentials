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

        public override Gtk.Widget create_generator_menu_button (GenerativeCollection collection) {
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            var label = new Gtk.Label (_("PGP Key"));
            var context = label.get_style_context ();
            context.add_class ("generator-label");
            label.halign = Gtk.Align.START;
            box.pack_start (label, false, false, 0);

            var hint_label = new Gtk.Label (_("For email and file encryption"));
            hint_label.halign = Gtk.Align.START;
            context = hint_label.get_style_context ();
            context.add_class ("dim-label");
            context.add_class ("generator-hints");
            box.pack_end (hint_label, false, false, 0);
            box.show_all ();
            return box;
        }

        public override GeneratorDialog create_generator_dialog (GenerativeCollection collection) {
            return new GpgGeneratorDialog (collection);
        }
    }
}
