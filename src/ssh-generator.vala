namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/ssh-generator-dialog.ui")]
    class SshGeneratorDialog : GeneratorDialog {
        [GtkChild]
        Gtk.ComboBox key_type_combobox;

        [GtkChild]
        Gtk.SpinButton length_spinbutton;

        [GtkChild]
        Gtk.Button path_button;

        [GtkChild]
        Gtk.Entry comment_entry;

        public SshGeneratorDialog (Collection collection) {
            Object (collection: collection, use_header_bar: 1);
        }

        construct {
            var store = new Gtk.ListStore (2,
                                           typeof (SshKeySpec),
                                           typeof (string));
            var _collection = (SshCollection) collection;
            foreach (var spec in _collection.get_specs ()) {
                Gtk.TreeIter iter;
                store.append (out iter);
                store.set (iter, 0, spec, 1, spec.label);
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
            SshKeySpec? spec;
            key_type_combobox.get_model ().get (iter, 0, out spec);
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
            SshKeySpec? spec;
            key_type_combobox.get_model ().get (iter, 0, out spec);

            return new SshGeneratedItemParameters (
                path_button.get_data ("credentails-selected-path"),
                comment_entry.get_text (),
                spec,
                length_spinbutton.get_value_as_int ());
        }
    }
}
