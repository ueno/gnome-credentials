namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/secret-generator-dialog.ui")]
    class SecretGeneratorDialog : GeneratorDialog {
        [GtkChild]
        Gtk.Entry name_entry;

        [GtkChild]
        Gtk.Entry email_entry;

        [GtkChild]
        SecretEntry password_entry;

        [GtkChild]
        Gtk.LevelBar password_level;

        [GtkChild]
        Gtk.TextView notes_textview;

		[GtkChild]
		Gtk.Button generate_button;

        PasswordQuality.Settings _pwquality;

        public SecretGeneratorDialog (Collection collection) {
            Object (collection: collection, use_header_bar: 1);
        }

        construct {
            name_entry.set_text (GLib.Environment.get_real_name ());
			name_entry.bind_property ("text",
									  generate_button, "sensitive",
									  GLib.BindingFlags.SYNC_CREATE,
									  Utils.transform_is_non_empty_string);

            this._pwquality = new PasswordQuality.Settings ();
            password_entry.bind_property ("text",
                                          password_level, "value",
                                          GLib.BindingFlags.SYNC_CREATE,
                                          transform_password_quality);
        }

        bool transform_password_quality (GLib.Binding binding,
                                         GLib.Value source_value,
                                         ref GLib.Value target_value)
        {
            var password = source_value.get_string ();
            var quality = this._pwquality.check (password);
            if (quality < 0) {
                // XXX: Should the error message be shown somewhere?
                target_value.set_double (0);
            } else {
                var min_level = password_level.get_min_value ();
                var max_level = password_level.get_max_value ();
                var level = (quality / (max_level - min_level)) + min_level;
                target_value.set_double (level);
            }
            return true;
        }

        [GtkCallback]
        void on_generate_password_clicked (Gtk.Button button) {
            string password;

            // XXX: The parameters should be specified through the UI
            var error = this._pwquality.generate (16, out password);
            if (error == PasswordQuality.Error.SUCCESS)
                password_entry.set_text (password);
        }

        public override GeneratedItemParameters build_parameters () {
            var buffer = notes_textview.get_buffer ();
            Gtk.TextIter start_iter, end_iter;
            buffer.get_start_iter (out start_iter);
            buffer.get_end_iter (out end_iter);
            var notes = buffer.get_text (start_iter, end_iter, false);

            return new SecretGeneratedItemParameters (
                name_entry.get_text (),
                email_entry.get_text (),
                notes,
                password_entry.get_text ());
        }
    }
}
