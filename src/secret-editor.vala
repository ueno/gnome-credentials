namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/secret-editor-dialog.ui")]
    class SecretEditorDialog : EditorDialog {
        [GtkChild]
        Gtk.Entry label_entry;

        [GtkChild]
        Gtk.Entry password_entry;

        [GtkChild]
        Gtk.CheckButton show_check_button;

        uint _set_label_idle_handler = 0;
        uint _set_password_idle_handler = 0;

        public SecretEditorDialog (Item item) {
            Object (item: item, use_header_bar: 1);
        }

        construct {
            var _item = (SecretItem) item;
            label_entry.set_text (item.get_label ());
            label_entry.notify["text"].connect (set_label_in_idle);
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
            show_check_button.bind_property ("active",
                                             password_entry, "visibility",
                                             GLib.BindingFlags.SYNC_CREATE |
                                             GLib.BindingFlags.BIDIRECTIONAL);
        }

        void set_label_in_idle () {
            if (this._set_label_idle_handler > 0) {
                GLib.Source.remove (this._set_label_idle_handler);
                this._set_label_idle_handler = 0;
            }

            this._set_label_idle_handler = GLib.Idle.add (() => {
                    var _item = (SecretItem) item;
                    var text = label_entry.get_text ();
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
