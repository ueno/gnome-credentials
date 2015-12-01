namespace Credentials {
    class SecretWidgetFactory : WidgetFactory {
        public SecretWidgetFactory (Backend backend) {
            Object (backend: backend);
        }

        string format_use (SecretUse use) {
            switch (use) {
            case SecretUse.OTHER:
                return _("other");
            case SecretUse.WEBSITE:
                return _("website");
            case SecretUse.NETWORK:
                return _("network");
            default:
                return_val_if_reached (_("invalid"));
            }
        }

        public override Gtk.Widget create_list_box_row (Item _item) {
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

            var item = (SecretItem) _item;

            var heading = new Gtk.Label (format_use (item.use));
            var context = heading.get_style_context ();
            context.add_class ("password-list-heading");
            heading.xalign = 0;
            box.pack_start (heading, false, false, 0);

            var modified = (int64) item.get_modified ();
            var date = new GLib.DateTime.from_unix_utc (modified);
            var date_string =
                Credentials.format_date (date.to_local (),
                                         Credentials.DateFormat.REGULAR);
            var date_label = new Gtk.Label (date_string);
            context = date_label.get_style_context ();
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
