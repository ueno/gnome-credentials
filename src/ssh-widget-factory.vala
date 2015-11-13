namespace Credentials {
    class SshWidgetFactory : GenerativeWidgetFactory {
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

        public override Gtk.Widget create_generator_menu_button (GenerativeCollection collection) {
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            var label = new Gtk.Label (_("Secure Shell Key"));
            var context = label.get_style_context ();
            context.add_class ("generator-label");
            label.halign = Gtk.Align.START;
            box.pack_start (label, false, false, 0);

            var hint_label = new Gtk.Label (_("For accessing other computer"));
            hint_label.halign = Gtk.Align.START;
            context = hint_label.get_style_context ();
            context.add_class ("dim-label");
            context.add_class ("generator-hints");
            box.pack_end (hint_label, false, false, 0);
            box.show_all ();
            return box;
        }

        public override GeneratorDialog create_generator_dialog (GenerativeCollection collection) {
            return new SshGeneratorDialog (collection);
        }
    }
}
