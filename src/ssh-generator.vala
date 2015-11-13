namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/ssh-generator.ui")]
    class SshGeneratorDialog : GeneratorDialog {
        [GtkChild]
        Gtk.ComboBox key_type_combobox;

        [GtkChild]
        Gtk.SpinButton length_spinbutton;

        [GtkChild]
        Gtk.Button path_button;

        [GtkChild]
        Gtk.Entry comment_entry;

        public SshGeneratorDialog (GenerativeCollection collection) {
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
            var basename = spec.keygen_argument;
            var path = GLib.Path.build_filename (homedir, ".ssh", basename);
            path_button.set_label (format_path (path));
            path_button.set_data ("credentials-selected-path", path);
        }

        public override GeneratedItemParameters build_parameters () {
            Gtk.TreeIter iter;
            key_type_combobox.get_active_iter (out iter);
            SshKeyType key_type;
            key_type_combobox.get_model ().get (iter, 0, out key_type);

            return new SshGeneratedItemParameters (
                path_button.get_data ("credentails-selected-path"),
                comment_entry.get_text (),
                key_type,
                length_spinbutton.get_value_as_int ());
        }
    }
}
