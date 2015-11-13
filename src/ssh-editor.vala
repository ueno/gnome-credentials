namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/ssh-editor.ui")]
    class SshEditorDialog : EditorDialog {
        [GtkChild]
        Gtk.Grid properties_grid;

        Gtk.Entry _comment_entry;
        uint _set_comment_idle_handler = 0;

        Gtk.Switch _authorized_switch;

        public SshEditorDialog (SshItem item) {
            Object (item: item, use_header_bar: 1);
        }

        Gtk.Label create_name_label (string text) {
            var label = new Gtk.Label (text);
            label.get_style_context ().add_class ("dim-label");
            label.xalign = 1;
            return label;
        }

        Gtk.Label create_value_label (string text) {
            var label = new Gtk.Label (text);
            label.xalign = 0;
            return label;
        }

        void set_comment_in_idle () {
            if (this._set_comment_idle_handler > 0) {
                GLib.Source.remove (this._set_comment_idle_handler);
                this._set_comment_idle_handler = 0;
            }

            this._set_comment_idle_handler = GLib.Idle.add (() => {
                    var window = (Gtk.Window) this.get_toplevel ();
                    var _item = (SshItem) item;
                    _item.set_comment.begin (
                        this._comment_entry.get_text (),
                        null,
                        (obj, res) => {
                            try {
                                _item.set_comment.end (res);
                            } catch (GLib.Error e) {
                                show_error (window,
                                            _("Couldn't write comment: %s"),
                                            e.message);
                            }
                        });
                    this._set_comment_idle_handler = 0;
                    return GLib.Source.REMOVE;
                });
        }

        construct {
            var _item = (SshItem) item;
            var row_index = 0;
            var label = create_name_label (_("Name"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            this._comment_entry = new Gtk.Entry ();
            this._comment_entry.set_text (_item.comment);
            this._comment_entry.notify["text"].connect (set_comment_in_idle);
            properties_grid.attach (this._comment_entry, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Algorithm"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (_item.spec.label);
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Strength"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (_item.length == 0 ? _("Unknown") : _("%u bits").printf (_item.length));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Location"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (format_path (_item.path));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Fingerprint"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (format_fingerprint (_item.get_fingerprint ()));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Remote Access"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            this._authorized_switch = new Gtk.Switch ();
            this._authorized_switch.set_halign (Gtk.Align.START);
            _item.bind_property ("authorized",
                                 this._authorized_switch, "active",
                                 GLib.BindingFlags.SYNC_CREATE |
                                 GLib.BindingFlags.BIDIRECTIONAL);
            properties_grid.attach (this._authorized_switch, 1, row_index, 1, 1);
            row_index++;

            properties_grid.show_all ();
        }

        [GtkCallback]
        void on_change_password_clicked (Gtk.Button button) {
            var _item = (SshItem) item;
            var window = (Gtk.Window) this.get_toplevel ();
            _item.change_password.begin (null, (obj, res) => {
                        try {
                            _item.change_password.end (res);
                        } catch (GLib.Error e) {
                            show_error (window,
                                        _("Couldn't change password: %s"),
                                        e.message);
                        }
                });
        }
    }
}
