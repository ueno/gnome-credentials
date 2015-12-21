namespace Credentials {
    class SecretViewAdapter : ViewAdapter {
        public override Gtk.Widget create_list_box_row (Item _item) {
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

            var item = (SecretItem) _item;

            var details_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            var context = details_box.get_style_context ();
            context.add_class ("password-list-details");

            var domain = item.format_domain ();
            if (domain == null) {
                domain = item.format_use ();
            }

            var domain_label = new Gtk.Label (domain);
            domain_label.xalign = 0;
            context = domain_label.get_style_context ();
            context.add_class ("password-list-domain");
            details_box.pack_start (domain_label, false, false, 0);

            var account = item.format_account ();
            if (account != null) {
                var account_label = new Gtk.Label (account);
                account_label.xalign = 0;
                context = account_label.get_style_context ();
                context.add_class ("dim-label");
                context.add_class ("password-list-account");
                details_box.pack_end (account_label, false, false, 0);
            }

            box.pack_start (details_box, true, true, 0);

            var modified = (int64) item.get_modified ();
            var date = new GLib.DateTime.from_unix_utc (modified);
            var date_string = Utils.format_date (date.to_local (),
                                                 Utils.DateFormat.REGULAR);
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
