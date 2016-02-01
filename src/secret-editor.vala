namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/secret-editor-dialog.ui")]
    class SecretEditorDialog : EditorDialog {
        [GtkChild]
        Gtk.Grid properties_grid;

        [GtkChild]
        SecretEntry password_entry;

        [GtkChild]
        Gtk.Label notes_label;

        [GtkChild]
        Gtk.TextView notes_textview;

        Gtk.Entry _domain_entry;
        Gtk.Entry _account_entry;

        uint _set_password_idle_handler = 0;
        uint _set_label_idle_handler = 0;

        public SecretEditorDialog (Item item) {
            Object (item: item, use_header_bar: 1);
        }

        Gtk.Label create_name_label (string text) {
            var label = new Gtk.Label (text);
            label.get_style_context ().add_class ("dim-label");
            label.xalign = 1;
            return label;
        }

        construct {
            var _item = (SecretItem) item;
            var network_schema = _item.schema as SecretSchemaNetwork;
            if (network_schema != null) {
                var top = properties_grid.get_child_at (0, 0);
                var domain_label = create_name_label (network_schema.domain_label);
                domain_label.show ();
                properties_grid.attach_next_to (domain_label, top, Gtk.PositionType.TOP, 1, 1);
                this._domain_entry = new Gtk.Entry ();
                this._domain_entry.set_text (network_schema.get_domain (_item));
                this._domain_entry.show ();
                properties_grid.attach_next_to (this._domain_entry, domain_label, Gtk.PositionType.RIGHT, 1, 1);

                var account_label = create_name_label (network_schema.account_label);
                account_label.show ();
                properties_grid.insert_next_to (domain_label, Gtk.PositionType.BOTTOM);
                properties_grid.attach_next_to (account_label, domain_label, Gtk.PositionType.BOTTOM, 1, 1);
                this._account_entry = new Gtk.Entry ();
                this._account_entry.set_text (network_schema.get_account (_item));
                this._account_entry.show ();
                properties_grid.attach_next_to (this._account_entry, account_label, Gtk.PositionType.RIGHT, 1, 1);
            }

            var buffer = notes_textview.get_buffer ();
            buffer.set_text (item.get_label ());
            buffer.notify["text"].connect (set_label_in_idle);

            var desktop_id = _item.schema.get_desktop_id (_item);
            if (desktop_id != null) {
                var appinfo = new DesktopAppInfo (desktop_id);
                if (appinfo != null) {
                    properties_grid.insert_next_to (notes_label, Gtk.PositionType.BOTTOM);
                    var label = create_name_label (_("Added-by"));
                    label.show ();
                    properties_grid.attach_next_to (label, notes_label, Gtk.PositionType.BOTTOM, 1, 1);
                    var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
                    var gicon = appinfo.get_icon ();
                    if (gicon != null) {
                        var icon_theme = Gtk.IconTheme.get_default ();
                        var icon_info = icon_theme.lookup_by_gicon (gicon, 16, Gtk.IconLookupFlags.FORCE_SYMBOLIC);
                        var pixbuf = icon_info.load_icon ();
                        var icon = new Gtk.Image.from_pixbuf (pixbuf);
                        box.pack_start (icon, false, false, 0);
                    }
                    var name_label = new Gtk.Label (appinfo.get_name ());
                    box.pack_start (name_label, false, false, 0);
                    box.show_all ();
                    properties_grid.attach_next_to (box, label, Gtk.PositionType.RIGHT, 1, 1);
                }
            }

            _item.load_secret.begin (null, (obj, res) => {
                    try {
                        _item.load_secret.end (res);
                    } catch (GLib.Error e) {
                        warning ("cannot load secret: %s", e.message);
                        return;
                    }

                    var secret = _item.get_secret ();
                    if (secret != null) {
                        password_entry.set_text (secret.get_text ());
                        password_entry.notify["text"].connect (set_password_in_idle);
                    } else {
                        password_entry.set_text ("");
                        password_entry.set_sensitive (false);
                    }
                });
        }

        void set_password_in_idle () {
            if (this._set_password_idle_handler > 0) {
                GLib.Source.remove (this._set_password_idle_handler);
                this._set_password_idle_handler = 0;
            }

            this._set_password_idle_handler = GLib.Idle.add (() => {
                    var _item = (SecretItem) item;
                    var password = password_entry.get_text ();
                    var secret = _item.get_secret ();
                    if (secret != null && password != secret.get_text ()) {
                        var window = (Gtk.Window) this.get_toplevel ();
                        var new_secret = new Secret.Value (
                            password,
                            password.length,
                            secret.get_content_type ());
                        _item.set_secret.begin (
                            new_secret, null,
                            (obj, res) => {
                                try {
                                    _item.set_secret.end (res);
                                } catch (GLib.Error e) {
                                    Utils.show_error (window,
                                                      _("Couldn't write password: %s"),
                                                      e.message);
                                }
                            });
                    }
                    this._set_password_idle_handler = 0;
                    return GLib.Source.REMOVE;
                });
        }

        void set_label_in_idle () {
            if (this._set_label_idle_handler > 0) {
                GLib.Source.remove (this._set_label_idle_handler);
                this._set_label_idle_handler = 0;
            }

            this._set_label_idle_handler = GLib.Idle.add (() => {
                    var _item = (SecretItem) item;
                    var buffer = notes_textview.get_buffer ();
                    Gtk.TextIter start_iter, end_iter;
                    buffer.get_start_iter (out start_iter);
                    buffer.get_end_iter (out end_iter);
                    var text = buffer.get_text (start_iter, end_iter, false);
                    if (text != _item.get_label ()) {
                        var window = (Gtk.Window) this.get_toplevel ();
                        _item.set_label.begin (text, null, (obj, res) => {
                                try {
                                    _item.set_label.end (res);
                                } catch (GLib.Error e) {
                                    Utils.show_error (window,
                                                      _("Couldn't write label: %s"),
                                                      e.message);
                                }
                            });
                    }
                    this._set_label_idle_handler = 0;
                    return GLib.Source.REMOVE;
                });
         }

        public override void delete_item () {
            var _item = (SecretItem) item;
            var window = (Gtk.Window) this.get_toplevel ();
            var confirm_dialog =
                new Gtk.MessageDialog (window,
                                       Gtk.DialogFlags.MODAL,
                                       Gtk.MessageType.QUESTION,
                                       Gtk.ButtonsType.OK_CANCEL,
                                       _("Delete password \"%s\"? "),
                                       _item.get_label ());

            confirm_dialog.response.connect ((res) => {
                    if (res == Gtk.ResponseType.OK)
                        base.delete_item ();
                    confirm_dialog.destroy ();
                });
            confirm_dialog.show ();
        }
    }
}
