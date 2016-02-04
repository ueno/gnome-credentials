namespace Credentials {
    class SecretViewAdapter : ViewAdapter {
        Gtk.Widget create_title_widget (SecretItem item)
        {
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            var context = box.get_style_context ();
            context.add_class ("password-list-details");

            var title = item.schema.get_title (item);
            var label = new Gtk.Label (title);
            label.xalign = 0;
            context = label.get_style_context ();
            context.add_class ("password-list-title");
            box.pack_start (label, false, false, 0);

            var secondary_title = item.schema.get_secondary_title (item);
            if (secondary_title != null) {
                var secondary_label = new Gtk.Label (secondary_title);
                secondary_label.xalign = 0;
                context = secondary_label.get_style_context ();
                context.add_class ("password-list-secondary-title");
                context.add_class ("dim-label");
                box.pack_start (secondary_label, false, false, 0);
            }

            return box;
        }

        public override Gtk.Widget create_list_box_row (Item _item) {
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

            var item = (SecretItem) _item;
            var title = create_title_widget (item);
            box.pack_start (title, true, true, 0);

            var modified = (int64) item.get_modified ();
            var date = new GLib.DateTime.from_unix_utc (modified);
            var date_string = Utils.format_date (date.to_local (),
                                                 Utils.DateFormat.REGULAR);
            var date_label = new Gtk.Label (date_string);
            var context = date_label.get_style_context ();
            context.add_class ("password-list-modified");
            context.add_class ("dim-label");
            box.pack_end (date_label, false, false, 0);
            box.show_all ();
            return box;
        }

        public override EditorDialog create_editor_dialog (Item item) {
            return new SecretEditorDialog (item);
        }
    }
}
