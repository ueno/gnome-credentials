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
        Gtk.TextView notes_textview;

        public SecretGeneratorDialog (Collection collection) {
            Object (collection: collection, use_header_bar: 1);
        }

        construct {
            name_entry.set_text (GLib.Environment.get_real_name ());
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
