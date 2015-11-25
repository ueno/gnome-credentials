namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-add-user-id.ui")]
    class GpgAddUserIdDialog : Gtk.Dialog {
        [GtkChild]
        Gtk.Entry name_entry;
        [GtkChild]
        Gtk.Entry email_entry;
        [GtkChild]
        Gtk.Entry comment_entry;

        public GpgItem item { construct set; get; }

        public GpgAddUserIdDialog (GpgItem item) {
            Object (item: item, use_header_bar: 1);
        }

        construct {
            name_entry.set_text (GLib.Environment.get_real_name ());
        }

        public override void response (int res) {
            if (res == Gtk.ResponseType.OK) {
                var window = (Gtk.Window) this.get_toplevel ();
                var command =
                    new GpgAddUidEditCommand (name_entry.get_text (),
                                              email_entry.get_text (),
                                              comment_entry.get_text ());
                item.edit.begin (command, null, (obj, res) => {
                        try {
                            item.edit.end (res);
                        } catch (GLib.Error e) {
                            show_error (window,
                                        "Couldn't add user ID: %s",
                                        e.message);
                        }
                    });
            }
        }
    }

    class GpgEditorUserIdItem : GLib.Object {
        public int index { construct set; get; }
        public GGpg.UserId user_id { construct set; get; }

        public GpgEditorUserIdItem (int index, GGpg.UserId user_id) {
            Object (index: index, user_id: user_id);
        }
    }

    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-add-subkey.ui")]
    class GpgAddSubkeyDialog : Gtk.Dialog {
        [GtkChild]
        Gtk.ComboBox key_type_combobox;

        [GtkChild]
        Gtk.SpinButton length_spinbutton;

        public GpgItem item { construct set; get; }

        public GpgAddSubkeyDialog (GpgItem item) {
            Object (item: item, use_header_bar: 1);
        }

        construct {
            var store = new Gtk.ListStore (2,
                                           typeof (GpgGeneratedKeySpec),
                                           typeof (string));
            foreach (var spec in item.get_generated_key_specs ()) {
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

        public override void response (int res) {
            if (res == Gtk.ResponseType.OK) {
                Gtk.TreeIter iter;
                key_type_combobox.get_active_iter (out iter);
                GpgGeneratedKeySpec? spec;
                key_type_combobox.get_model ().get (iter, 0, out spec);

                var window = (Gtk.Window) this.get_toplevel ();
                var command = new GpgAddKeyEditCommand (
                    spec.key_type,
                    length_spinbutton.get_value_as_int (),
                    0);
                item.edit.begin (command, null, (obj, res) => {
                        try {
                            item.edit.end (res);
                        } catch (GLib.Error e) {
                            show_error (window,
                                        "Couldn't add user ID: %s",
                                        e.message);
                        }
                    });
            }
        }
    }

    class GpgEditorSubkeyItem : GLib.Object {
        public int index { construct set; get; }
        public GGpg.Subkey subkey { construct set; get; }

        public GpgEditorSubkeyItem (int index, GGpg.Subkey subkey) {
            Object (index: index, subkey: subkey);
        }
    }

    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-editor.ui")]
    class GpgEditorDialog : EditorDialog {
        [GtkChild]
        Gtk.ListBox user_id_list_box;

        [GtkChild]
        Gtk.ListBox subkey_list_box;

        [GtkChild]
        Gtk.Grid properties_grid;

        Gtk.Label _pubkey_algo_label;
        Gtk.Label _length_label;
        Gtk.Label _fingerprint_label;
        Gtk.Label _expires_label;
        Gtk.Label _usage_label;

        public GpgEditorDialog (Item item) {
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

        GLib.ListStore _user_id_store;

        Gtk.Widget create_user_id_widget (GLib.Object object) {
            var user_id_item = (GpgEditorUserIdItem) object;
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
            var label = new Gtk.Label (escape_invalid_chars (user_id_item.user_id.uid));
            label.margin_start = 20;
            label.margin_end = 20;
            label.margin_top = 6;
            label.margin_bottom = 6;
            box.pack_start (label, false, false, 6);
            box.show_all ();
            return box;
        }

        void update_user_id_list () {
            var _item = (GpgItem) item;
            this._user_id_store.remove_all ();
            int index = 1;
            foreach (var uid in _item.get_uids ()) {
                this._user_id_store.append (new GpgEditorUserIdItem (index, uid));
                index++;
            }

            list_box_adjust_scrolling (user_id_list_box);
        }

        void on_delete_user_id_clicked (GpgEditorUserIdItem item) {
            var dialog = new Gtk.MessageDialog (this,
                                                Gtk.DialogFlags.MODAL,
                                                Gtk.MessageType.QUESTION,
                                                Gtk.ButtonsType.OK_CANCEL,
                                                _("Remove user ID \"%s\"? "),
                                                item.user_id.uid);
            dialog.response.connect ((res) => {
                    if (res == Gtk.ResponseType.OK)
                        call_edit_deluid (item.index);
                    dialog.destroy ();
                });
            dialog.show ();
        }

        void call_edit_deluid (uint index) {
            var _item = (GpgItem) item;
            var window = (Gtk.Window) this.get_toplevel ();
            var command = new GpgDelUidEditCommand (index);
            _item.edit.begin (command, null, (obj, res) => {
                    try {
                        _item.edit.end (res);
                    } catch (GLib.Error e) {
                        show_error (window,
                                    "Couldn't add user ID: %s", e.message);
                    }
                });
        }

        [GtkCallback]
        void on_add_user_id_clicked (Gtk.ToolButton button) {
            var dialog = new GpgAddUserIdDialog ((GpgItem) item);
            dialog.set_transient_for (this);
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.show ();
        }

        GLib.ListStore _subkey_store;

        Gtk.Widget create_subkey_widget (GLib.Object object) {
            var subkey_item = (GpgEditorSubkeyItem) object;
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            var label = new Gtk.Label (subkey_item.subkey.key_id);
            label.margin_start = 20;
            label.margin_end = 20;
            label.margin_top = 6;
            label.margin_bottom = 6;
            box.pack_start (label, false, false, 0);
            box.show_all ();
            return box;
        }

        void update_subkey_list () {
            var _item = (GpgItem) item;
            this._subkey_store.remove_all ();
            int index = 0;
            foreach (var subkey in _item.get_subkeys ()) {
                this._subkey_store.append (new GpgEditorSubkeyItem (index, subkey));
                index++;
            }

            list_box_adjust_scrolling (subkey_list_box);
        }

        void on_delete_subkey_clicked (GpgEditorSubkeyItem item) {
            var dialog = new Gtk.MessageDialog (this,
                                                Gtk.DialogFlags.MODAL,
                                                Gtk.MessageType.QUESTION,
                                                Gtk.ButtonsType.OK_CANCEL,
                                                _("Remove subkey \"%s\"? "),
                                                item.subkey.key_id);
            dialog.response.connect ((res) => {
                    if (res == Gtk.ResponseType.OK)
                        call_edit_delkey (item.index);
                    dialog.destroy ();
                });
            dialog.show ();
        }

        void call_edit_delkey (uint index) {
            var _item = (GpgItem) item;
            var window = (Gtk.Window) this.get_toplevel ();
            var command = new GpgDelKeyEditCommand (index);
            _item.edit.begin (command, null, (obj, res) => {
                    try {
                        _item.edit.end (res);
                    } catch (GLib.Error e) {
                        show_error (window,
                                    "Couldn't remove subkey: %s",
                                    e.message);
                    }
                });
        }

        [GtkCallback]
        void on_add_subkey_clicked (Gtk.ToolButton button) {
            var dialog = new GpgAddSubkeyDialog ((GpgItem) item);
            dialog.set_transient_for (this);
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.show ();
        }

        construct {
            var _item = (GpgItem) item;

            this._user_id_store = new GLib.ListStore (typeof (GpgEditorUserIdItem));
            user_id_list_box.bind_model (this._user_id_store, create_user_id_widget);
            user_id_list_box.set_header_func (list_box_update_header_func);
            list_box_setup_scrolling (user_id_list_box, 0);
            _item.changed.connect (update_user_id_list);
            update_user_id_list ();

            this._subkey_store = new GLib.ListStore (typeof (GpgEditorSubkeyItem));
            subkey_list_box.bind_model (this._subkey_store, create_subkey_widget);
            subkey_list_box.set_header_func (list_box_update_header_func);
            list_box_setup_scrolling (subkey_list_box, 0);
            _item.changed.connect (update_subkey_list);
            update_subkey_list ();

            var row_index = 0;
            var label = create_name_label (_("Owner trust"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (GpgUtils.format_validity (_item.owner_trust));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Algorithm"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            this._pubkey_algo_label = create_value_label ("");
            properties_grid.attach (this._pubkey_algo_label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Strength"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            this._length_label = create_value_label ("");
            properties_grid.attach (this._length_label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Fingerprint"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            this._fingerprint_label = create_value_label ("");
            this._fingerprint_label.max_width_chars = 28;
            this._fingerprint_label.wrap = true;
            this._fingerprint_label.wrap_mode = Pango.WrapMode.WORD;
            properties_grid.attach (this._fingerprint_label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Valid until"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            this._expires_label = create_value_label ("");
            properties_grid.attach (this._expires_label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Use for"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            this._usage_label = create_value_label ("");
            properties_grid.attach (this._usage_label, 1, row_index, 1, 1);
            row_index++;

            var row = subkey_list_box.get_row_at_index (0);
            if (row != null)
                subkey_list_box.select_row (row);
            properties_grid.show_all ();
        }

        void update_subkey_properties (GpgEditorSubkeyItem item) {
            this._pubkey_algo_label.label = GpgUtils.format_pubkey_algo (item.subkey.pubkey_algo);
            this._length_label.label = _("%u bits").printf (item.subkey.length);
            this._fingerprint_label.label = GpgUtils.format_fingerprint (item.subkey.fingerprint);
            this._expires_label.label = GpgUtils.format_expires (item.subkey.expires);
            this._usage_label.label = GpgUtils.format_usage (item.subkey.flags);
        }

        [GtkCallback]
        void on_change_password_clicked (Gtk.Button button) {
            var _item = (GpgItem) item;
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

        [GtkCallback]
        void on_subkey_selected (Gtk.ListBox list_box, Gtk.ListBoxRow? row) {
            if (row != null) {
                var item = (GpgEditorSubkeyItem) this._subkey_store.get_item (row.get_index ());
                update_subkey_properties (item);
            }
        }
    }
}
