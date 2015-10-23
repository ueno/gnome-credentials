namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/secret-editor.ui")]
    class SecretEditorDialog : Gtk.Dialog {
        [GtkChild]
        Gtk.Entry label_entry;
        [GtkChild]
        Gtk.Entry password_entry;
        [GtkChild]
        Gtk.CheckButton show_check_button;

        public SecretItem item { construct set; get; }

        public SecretEditorDialog (SecretItem item) {
            Object (item: item, use_header_bar: 1);
        }

        construct {
            label_entry.set_text (item.get_label ());
            item.load_secret.begin (null, (obj, res) => {
                    try {
                        item.load_secret.end (res);
                    } catch (GLib.Error e) {
                        warning ("cannot load secret: %s", e.message);
                        return;
                    }

                    var secret = item.get_secret ();
                    if (secret != null)
                        password_entry.set_text (secret.get_text ());
                    else {
                        password_entry.set_text ("");
                        password_entry.set_sensitive (false);
                    }
                });
            show_check_button.bind_property ("active",
                                             password_entry, "visibility",
                                             GLib.BindingFlags.SYNC_CREATE |
                                             GLib.BindingFlags.BIDIRECTIONAL);
        }

        void delete_item () {
            var window = (Gtk.Window) this.get_toplevel ();
            var confirm_dialog =
                new Gtk.MessageDialog (window,
                                       Gtk.DialogFlags.MODAL,
                                       Gtk.MessageType.QUESTION,
                                       Gtk.ButtonsType.OK_CANCEL,
                                       _("Delete password \"%s\"? "),
                                       item.get_label ());

            confirm_dialog.response.connect ((res) => {
                    if (res == Gtk.ResponseType.OK)
                        item.delete.begin (null, (obj, res) => {
                                try {
                                    item.delete.end (res);
                                } catch (GLib.Error e) {
                                    show_error (window,
                                                _("Couldn't delete password: %s"),
                                                e.message);
                                }
                            });
                    confirm_dialog.destroy ();
                });
            confirm_dialog.show ();
        }

        void save_item () {
            var window = (Gtk.Window) this.get_toplevel ();
            var label = label_entry.get_text ();
            if (label != item.get_label ()) {
                item.set_label.begin (label, null, (obj, res) => {
                        try {
                            item.set_label.end (res);
                        } catch (GLib.Error e) {
                            show_error (window,
                                        _("Couldn't write label: %s"),
                                        e.message);
                        }
                    });
            }

            var password = password_entry.get_text ();
            var secret = item.get_secret ();
            if (secret != null && password != secret.get_text ()) {
                var new_secret = new Secret.Value (password, password.length,
                                                   secret.get_content_type ());
                item.set_secret.begin (
                    new_secret, null,
                    (obj, res) => {
                        try {
                            item.set_secret.end (res);
                        } catch (GLib.Error e) {
                            show_error (window,
                                        _("Couldn't write password: %s"),
                                        e.message);
                        }
                    });
            }
        }

        public override void response (int res) {
            switch (res) {
            case EditorResponse.DELETE:
                delete_item ();
                break;
            case EditorResponse.DONE:
                save_item ();
                break;
            }
        }
    }

    class SecretWidgetFactory : WidgetFactory {
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

        public override Gtk.Dialog create_editor_dialog (Item item) {
            return new SecretEditorDialog ((SecretItem) item);
        }

        public override Gtk.Dialog create_generator_dialog () {
            return_val_if_reached (null);
        }
    }
}
