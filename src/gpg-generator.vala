namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-generator.ui")]
    class GpgGeneratorDialog : GeneratorDialog {
        [GtkChild]
        Gtk.ComboBox key_type_combobox;

        [GtkChild]
        Gtk.SpinButton length_spinbutton;

        [GtkChild]
        Gtk.Entry name_entry;

        [GtkChild]
        Gtk.Entry email_entry;

        [GtkChild]
        Gtk.Entry comment_entry;

        public GpgGeneratorDialog (GenerativeCollection collection) {
            Object (collection: collection, use_header_bar: 1);
        }

        construct {
            var store = new Gtk.ListStore (2,
                                           typeof (GpgGeneratedKeySpec),
                                           typeof (string));
            var _collection = (GpgCollection) collection;
            foreach (var spec in _collection.get_generated_key_specs ()) {
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

            name_entry.set_text (GLib.Environment.get_real_name ());
        }

        void on_key_type_changed () {
            Gtk.TreeIter iter;
            key_type_combobox.get_active_iter (out iter);
            GpgGeneratedKeySpec? spec;
            key_type_combobox.get_model ().get (iter, 0, out spec);
            var adjustment = new Gtk.Adjustment (spec.default_length,
                                                 spec.min_length,
                                                 spec.max_length,
                                                 1,
                                                 1,
                                                 0);
            length_spinbutton.set_adjustment (adjustment);
            length_spinbutton.set_editable (true);
        }

        public override GeneratedItemParameters build_parameters () {
            Gtk.TreeIter iter;
            key_type_combobox.get_active_iter (out iter);
            GpgGeneratedKeySpec? spec;
            key_type_combobox.get_model ().get (iter, 0, out spec);

            return new GpgGeneratedItemParameters (
                spec,
                name_entry.get_text (),
                email_entry.get_text (),
                comment_entry.get_text (),
                length_spinbutton.get_value_as_int (),
                0);
        }
    }
}
