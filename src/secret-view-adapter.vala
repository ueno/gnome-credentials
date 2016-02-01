namespace Credentials {
    delegate Gtk.Widget SecretItemRenderFunc (SecretItem item);

    class SecretViewAdapter : ViewAdapter {
        string format_use (SecretUse use) {
            var enum_class = (EnumClass) typeof (SecretUse).class_ref ();
            var enum_value = enum_class.get_value (use);
            return enum_value.value_nick;
        }

        Gtk.Widget render_base (SecretItem item) {
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            var context = box.get_style_context ();
            context.add_class ("password-list-details");

            var domain_label = new Gtk.Label (format_use (item.schema.use));
            context = domain_label.get_style_context ();
            context.add_class ("password-list-domain");
            box.pack_start (domain_label, false, false, 0);
            return box;
        }

        Gtk.Widget render_network (SecretItem item) {
            var network_schema = item.schema as SecretSchemaNetwork;
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            var context = box.get_style_context ();
            context.add_class ("password-list-details");

            var domain = network_schema.format_domain (item);
            if (domain == null)
                domain = format_use (item.schema.use);

            var domain_label = new Gtk.Label (domain);
            domain_label.xalign = 0;
            context = domain_label.get_style_context ();
            context.add_class ("password-list-domain");
            box.pack_start (domain_label, false, false, 0);

            var account = network_schema.format_account (item);
            if (account == null)
                account = "";
            var account_label = new Gtk.Label (account);
            account_label.xalign = 0;
            context = account_label.get_style_context ();
            context.add_class ("dim-label");
            context.add_class ("password-list-account");
            box.pack_end (account_label, false, false, 0);
            return box;
        }

        public override Gtk.Widget create_list_box_row (Item _item) {
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

            var item = (SecretItem) _item;
            Gtk.Widget widget;
            if (item.schema is SecretSchemaNetwork) {
                widget = render_network (item);
            } else {
                widget = render_base (item);
            }
            box.pack_start (widget, true, true, 0);

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
