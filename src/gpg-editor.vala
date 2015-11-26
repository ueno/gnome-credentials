namespace Credentials {
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

                var window = (Gtk.Window) this.get_transient_for ();
                var command = new GpgAddKeyEditCommand (
                    spec.key_type,
                    length_spinbutton.get_value_as_int (),
                    0);
                item.edit.begin (command, null, (obj, res) => {
                        try {
                            item.edit.end (res);
                        } catch (GLib.Error e) {
                            show_error (window,
                                        "Couldn't add subkey: %s",
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
                var window = (Gtk.Window) this.get_transient_for ();
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

    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-editor.ui")]
    class GpgEditorDialog : EditorDialog {
        [GtkChild]
        Gtk.Button delete_button;

        [GtkChild]
        Gtk.Button back_button;

        [GtkChild]
        Gtk.ListBox subkey_list_box;

        [GtkChild]
        Gtk.ListBox user_id_list_box;

        [GtkChild]
        Gtk.ComboBox trust_combobox;

        [GtkChild]
        Gtk.Stack stack;

        [GtkChild]
        Gtk.Label key_id_label;

        [GtkChild]
        Gtk.Label pubkey_algo_label;

        [GtkChild]
        Gtk.Label length_label;

        [GtkChild]
        Gtk.Label fingerprint_label;

        [GtkChild]
        Gtk.Label expires_label;

        [GtkChild]
        Gtk.Label usage_label;

        [GtkChild]
        Gtk.Label name_label;

        [GtkChild]
        Gtk.Label email_label;

        [GtkChild]
        Gtk.Label comment_label;

        [GtkChild]
        Gtk.Label validity_label;

        public GpgEditorDialog (Item item) {
            Object (item: item, use_header_bar: 1);
        }

        GpgEditorSubkeyItem? _subkey_item;
        GpgEditorUserIdItem? _user_id_item;

        GLib.ListStore _subkey_store;

        Gtk.Widget create_subkey_widget (GLib.Object object) {
            var subkey_item = (GpgEditorSubkeyItem) object;
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            var label = new Gtk.Label (subkey_item.subkey.key_id);
            label.margin_start = 20;
            label.margin_end = 20;
            label.margin_top = 6;
            label.margin_bottom = 6;
            label.xalign = 0;
            box.pack_start (label, false, false, 0);

            var usage = GpgUtils.format_usage (subkey_item.subkey.flags);
            label = new Gtk.Label (_("used for: %s").printf (usage));
            label.margin_start = 20;
            label.margin_end = 20;
            label.xalign = 0;
            var context = label.get_style_context ();
            context.add_class ("secondary-label");
            context.add_class ("dim-label");
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

        [GtkCallback]
        void on_delete_subkey_clicked (Gtk.Button button) {
            var dialog = new Gtk.MessageDialog (
                this,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.QUESTION,
                Gtk.ButtonsType.OK_CANCEL,
                _("Remove subkey \"%s\"? "),
                this._subkey_item.subkey.key_id);
            dialog.response.connect ((res) => {
                    if (res == Gtk.ResponseType.OK)
                        call_edit_delkey (this._subkey_item.index);
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
        void on_add_subkey_clicked (Gtk.Button button) {
            var dialog = new GpgAddSubkeyDialog ((GpgItem) item);
            dialog.set_transient_for (this);
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.show ();
        }

        void update_subkey_properties (GpgEditorSubkeyItem item) {
            key_id_label.label = item.subkey.key_id;
            pubkey_algo_label.label = GpgUtils.format_pubkey_algo (item.subkey.pubkey_algo);
            length_label.label = _("%u bits").printf (item.subkey.length);
            fingerprint_label.label = GpgUtils.format_fingerprint (item.subkey.fingerprint);
            expires_label.label = GpgUtils.format_expires (item.subkey.expires);
            usage_label.label = GpgUtils.format_usage (item.subkey.flags);
        }

        [GtkCallback]
        void on_subkey_selected (Gtk.ListBox list_box, Gtk.ListBoxRow? row) {
            if (row != null) {
                this._subkey_item = (GpgEditorSubkeyItem) this._subkey_store.get_item (row.get_index ());
                update_subkey_properties (this._subkey_item);
                delete_button.hide ();
                back_button.show ();
                stack.visible_child_name = "subkey";
            }
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

        [GtkCallback]
        void on_delete_user_id_clicked (Gtk.Button button) {
            var dialog = new Gtk.MessageDialog (this,
                                                Gtk.DialogFlags.MODAL,
                                                Gtk.MessageType.QUESTION,
                                                Gtk.ButtonsType.OK_CANCEL,
                                                _("Remove user ID \"%s\"? "),
                this._user_id_item.user_id.uid);
            dialog.response.connect ((res) => {
                    if (res == Gtk.ResponseType.OK)
                        call_edit_deluid (this._user_id_item.index);
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
        void on_add_user_id_clicked (Gtk.Button button) {
            var dialog = new GpgAddUserIdDialog ((GpgItem) item);
            dialog.set_transient_for (this);
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.show ();
        }

        void set_nullable_label (Gtk.Label label, string text) {
            var context = label.get_style_context ();
            if (text == "") {
                label.label = _("(none)");
                context.add_class ("dim-label");
            } else {
                label.label = text;
                context.remove_class ("dim-label");
            }
        }

        void update_user_id_properties (GpgEditorUserIdItem item) {
            set_nullable_label (name_label, item.user_id.name);
            set_nullable_label (email_label, item.user_id.email);
            set_nullable_label (comment_label, item.user_id.comment);
            validity_label.label = GpgUtils.format_validity (item.user_id.validity);
        }

        [GtkCallback]
        void on_user_id_selected (Gtk.ListBox list_box, Gtk.ListBoxRow? row) {
            if (row != null) {
                this._user_id_item = (GpgEditorUserIdItem) this._user_id_store.get_item (row.get_index ());
                update_user_id_properties (this._user_id_item);
                delete_button.hide ();
                back_button.show ();
                stack.visible_child_name = "user_id";
            }
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

            var store = (Gtk.ListStore) trust_combobox.get_model ();
            var enum_class = (EnumClass) typeof (GGpg.Validity).class_ref ();
            for (var i = enum_class.minimum; i <= enum_class.maximum; i++) {
                var enum_value = enum_class.get_value (i);
                Gtk.TreeIter iter;
                store.append (out iter);
                store.set (iter, 0, enum_value.value_nick, 1, i);
            }
            var renderer = new Gtk.CellRendererText ();
            trust_combobox.pack_start (renderer, true);
            trust_combobox.set_attributes (renderer, "text", 0);
            trust_combobox.changed.connect (on_trust_changed);
            _item.changed.connect (update_trust);
            update_trust ();
        }

        void update_trust () {
            var _item = (GpgItem) item;

            var model = trust_combobox.get_model ();
            Gtk.TreeIter iter;
            if (model.get_iter_first (out iter)) {
                do {
                    GGpg.Validity validity;
                    model.get (iter, 1, out validity);
                    if (validity == _item.owner_trust) {
                        trust_combobox.set_active_iter (iter);
                        break;
                    }
                } while (model.iter_next (ref iter));
            }
        }

        void on_trust_changed () {
            var _item = (GpgItem) item;

            Gtk.TreeIter iter;
            trust_combobox.get_active_iter (out iter);

            GGpg.Validity validity;
            trust_combobox.get_model ().get (iter, 1, out validity);
            if (validity == _item.owner_trust)
                return;

            var command = new GpgTrustEditCommand (validity);
            var window = (Gtk.Window) this.get_toplevel ();
            _item.edit.begin (command, null, (obj, res) => {
                    try {
                        _item.edit.end (res);
                    } catch (GLib.Error e) {
                        show_error (window,
                                    "Couldn't change owner trust: %s",
                                    e.message);
                    }
                });
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
        void on_back_clicked (Gtk.Button button) {
            delete_button.show ();
            back_button.hide ();
            stack.visible_child_name = "main";
        }
    }
}
