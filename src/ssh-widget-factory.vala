namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/ssh-editor.ui")]
    class SshEditorDialog : Gtk.Dialog {
        [GtkChild]
        Gtk.Grid properties_grid;

        public SshItem item { construct set; get; }

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
                    item.set_comment.begin (
                        this._comment_entry.get_text (),
                        null,
                        (obj, res) => {
                            try {
                                item.set_comment.end (res);
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
            var row_index = 0;
            var label = create_name_label (_("Name"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            this._comment_entry = new Gtk.Entry ();
            this._comment_entry.set_text (item.comment);
            this._comment_entry.notify["text"].connect (set_comment_in_idle);
            properties_grid.attach (this._comment_entry, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Algorithm"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (item.spec.label);
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Strength"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (item.length == 0 ? _("Unknown") : _("%u bits").printf (item.length));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Location"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (format_path (item.path));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Fingerprint"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (format_fingerprint (item.get_fingerprint ()));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Remote Access"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            this._authorized_switch = new Gtk.Switch ();
            this._authorized_switch.set_halign (Gtk.Align.START);
            item.bind_property ("authorized",
                                this._authorized_switch, "active",
                                GLib.BindingFlags.SYNC_CREATE |
                                GLib.BindingFlags.BIDIRECTIONAL);
            properties_grid.attach (this._authorized_switch, 1, row_index, 1, 1);
            row_index++;

            properties_grid.show_all ();
        }

        [GtkCallback]
        void on_change_password_clicked (Gtk.Button button) {
            var window = (Gtk.Window) this.get_toplevel ();
            item.change_password.begin (null, (obj, res) => {
                        try {
                            item.change_password.end (res);
                        } catch (GLib.Error e) {
                            show_error (window,
                                        _("Couldn't change password: %s"),
                                        e.message);
                        }
                });
        }

        public override void response (int res) {
            var window = (Gtk.Window) this.get_toplevel ();
            switch (res) {
            case EditorResponse.DELETE:
                item.delete.begin (null, (obj, res) => {
                        try {
                            item.delete.end (res);
                        } catch (GLib.Error e) {
                            show_error (window,
                                        _("Couldn't delete key: %s"),
                                        e.message);
                        }
                    });
                break;
            case EditorResponse.DONE:
                break;
            }
        }
    }

    [GtkTemplate (ui = "/org/gnome/Credentials/ssh-generator.ui")]
    class SshGeneratorDialog : Gtk.Dialog {
        [GtkChild]
        Gtk.ComboBox key_type_combobox;
        [GtkChild]
        Gtk.SpinButton length_spinbutton;
        [GtkChild]
        Gtk.Button path_button;
        [GtkChild]
        Gtk.Entry comment_entry;

        public SshCollection collection { construct set; get; }

        public SshGeneratorDialog (SshCollection collection) {
            Object (collection: collection, use_header_bar: 1);
        }

        construct {
            var backend = (SshBackend) collection.backend;
            var store = new Gtk.ListStore (2,
                                           typeof (SshKeyType),
                                           typeof (string));
            var enum_class =
                (EnumClass) typeof (SshKeyType).class_ref ();
            for (var index = enum_class.minimum;
                 index <= enum_class.maximum;
                 index++) {
                if (enum_class.get_value (index) == null)
                    continue;

                var key_type = (SshKeyType) index;

                Gtk.TreeIter iter;
                store.append (out iter);
                var spec = backend.get_spec (key_type);
                store.set (iter,
                           0, index,
                           1, spec.label);
            }

            key_type_combobox.set_model (store);
            var renderer = new Gtk.CellRendererText ();
            key_type_combobox.pack_start (renderer, true);
            key_type_combobox.set_attributes (renderer, "text", 1);
            key_type_combobox.changed.connect (on_key_type_changed);
            key_type_combobox.set_active (0);

            var homedir = GLib.Environment.get_home_dir ();
            var sshdir = GLib.Path.build_filename (homedir, ".ssh");
            path_button.clicked.connect (() => {
                    var chooser = new Gtk.FileChooserDialog (
                        _("SSH Key Location"),
                        (Gtk.Window) this.get_toplevel (),
                        Gtk.FileChooserAction.SAVE,
                        _("_Cancel"),
                        Gtk.ResponseType.CANCEL,
                        _("_OK"),
                        Gtk.ResponseType.OK);
                    chooser.set_modal (true);
                    chooser.set_current_folder (sshdir);
                    chooser.set_select_multiple (false);
                    chooser.set_local_only (true);
                    chooser.response.connect ((res) => {
                            if (res == Gtk.ResponseType.OK) {
                                var path = chooser.get_filename ();
                                path_button.set_label (format_path (path));
                                path_button.set_data ("credentails-selected-path", path);
                            }
                            chooser.destroy ();
                        });
                    chooser.show ();
                });
            ((Gtk.Label) path_button.get_child ()).xalign = 0;
            comment_entry.set_text (GLib.Environment.get_real_name ());
        }

        string key_type_to_keygen_basename (SshKeyType key_type) {
            switch (key_type) {
            case SshKeyType.RSA:
                return "id_rsa";
            case SshKeyType.DSA:
                return "id_dsa";
            case SshKeyType.ECDSA:
                return "id_ecdsa";
            case SshKeyType.ED25519:
                return "id_ed25519";
            default:
                return_val_if_reached (null);
            }
        }

        void on_key_type_changed () {
            Gtk.TreeIter iter;
            key_type_combobox.get_active_iter (out iter);
            SshKeyType key_type;
            key_type_combobox.get_model ().get (iter, 0, out key_type);
            var backend = (SshBackend) collection.backend;
            var spec = backend.get_spec (key_type);
            var adjustment = new Gtk.Adjustment (spec.default_length,
                                                 spec.min_length,
                                                 spec.max_length,
                                                 1,
                                                 1,
                                                 0);
            length_spinbutton.set_adjustment (adjustment);
            length_spinbutton.set_editable (true);

            var homedir = GLib.Environment.get_home_dir ();
            var basename = key_type_to_keygen_basename (key_type);
            var path = GLib.Path.build_filename (homedir, ".ssh", basename);
            path_button.set_label (format_path (path));
            path_button.set_data ("credentials-selected-path", path);
        }

        public override void response (int res) {
            if (res == Gtk.ResponseType.OK) {
                Gtk.TreeIter iter;
                key_type_combobox.get_active_iter (out iter);
                SshKeyType key_type;
                key_type_combobox.get_model ().get (iter, 0, out key_type);

                var parameters = new SshGeneratedKeyParameters (
                    path_button.get_data ("credentails-selected-path"),
                    comment_entry.get_text (),
                    key_type,
                    length_spinbutton.get_value_as_int ());

                var window = (Gtk.Window) this.get_toplevel ();
                var app_window = (Window) window.get_transient_for ();

                collection.generate_item.begin (
                    parameters, null,
                    (obj, res) => {
                        try {
                            collection.generate_item.end (res);
                            show_notification (app_window,
                                               _("%s key generated"),
                                               collection.item_type);
                        } catch (GLib.Error e) {
                            show_error (app_window,
                                        "Couldn't generate SSH key: %s",
                                        e.message);
                        }
                    });
            }
        }
    }

    class SshWidgetFactory : WidgetFactory {
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

        public override Gtk.Dialog create_editor_dialog (Item item) {
            return new SshEditorDialog ((SshItem) item);
        }
    }
}
