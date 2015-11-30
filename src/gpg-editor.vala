namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-add-subkey.ui")]
    class GpgAddSubkeyDialog : Gtk.Dialog {
        [GtkChild]
        Gtk.ComboBox key_type_combobox;

        [GtkChild]
        Gtk.SpinButton length_spinbutton;

        [GtkChild]
        Gtk.MenuButton expires_button;

        public GpgItem item { construct set; get; }

        GpgExpirationSpec _expires;

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

            var expires = GpgExpirationSpec (GpgExpirationFormat.NEVER, 0);
            var popover = new GpgExpiresPopover (expires, false);
            popover.closed.connect (() => {
                    this._expires = popover.get_spec ();
                    expires_button.label = this._expires.to_string ();
                });
            expires_button.set_popover (popover);
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
                    this._expires);
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

    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-expires.ui")]
    class GpgExpiresPopover : Gtk.Popover {
        [GtkChild]
        Gtk.ToggleButton forever_button;

        [GtkChild]
        Gtk.Box date_box;

        [GtkChild]
        Gtk.SpinButton date_spinbutton;

        [GtkChild]
        Gtk.ComboBox date_combobox;

        public GpgExpirationSpec expires { construct set; get; }
        public bool use_calendar { construct set; get; }
        Gtk.Calendar _calendar;

        public GpgExpiresPopover (GpgExpirationSpec expires,
                                  bool use_calendar)
        {
            Object (expires: expires, use_calendar: use_calendar);
        }

        construct {
            if (expires.format == GpgExpirationFormat.NEVER) {
                forever_button.active = true;
            }

            if (use_calendar) {
                var parent = date_box.get_parent ();
                parent.remove (date_box);
                this._calendar = new Gtk.Calendar ();
                this._calendar.show ();
                parent.add (this._calendar);

                if (expires.format == GpgExpirationFormat.DATE) {
                    var date = new GLib.DateTime.from_unix_utc (expires.value);
                    date = date.to_local ();
                    this._calendar.select_month (date.get_month () - 1,
                                             date.get_year ());
                    this._calendar.select_day (date.get_day_of_month ());
                }

                forever_button.bind_property ("active",
                                              this._calendar, "sensitive",
                                              GLib.BindingFlags.SYNC_CREATE |
                                              GLib.BindingFlags.INVERT_BOOLEAN);

            } else {
                int64 value;
                if (expires.format == GpgExpirationFormat.NEVER ||
                    expires.format == GpgExpirationFormat.DATE)
                    value = 0;
                else
                    value = expires.value;

                var adjustment = new Gtk.Adjustment (value,
                                                     0,
                                                     double.MAX,
                                                     1,
                                                     1,
                                                     0);
                date_spinbutton.set_adjustment (adjustment);

                var renderer = new Gtk.CellRendererText ();
                date_combobox.pack_start (renderer, true);
                date_combobox.set_attributes (renderer, "text", 0);
                date_combobox.set_active (0);

                forever_button.bind_property ("active",
                                              date_spinbutton, "sensitive",
                                              GLib.BindingFlags.SYNC_CREATE |
                                              GLib.BindingFlags.INVERT_BOOLEAN);
                forever_button.bind_property ("active",
                                              date_combobox, "sensitive",
                                              GLib.BindingFlags.SYNC_CREATE |
                                              GLib.BindingFlags.INVERT_BOOLEAN);
            }
        }

        public GpgExpirationSpec get_spec () {
            if (forever_button.active) {
                return GpgExpirationSpec (GpgExpirationFormat.NEVER, 0);
            }

            if (this._calendar != null) {
                uint year, month, day;
                this._calendar.get_date (out year, out month, out day);
                var new_date = new GLib.DateTime.local ((int) year,
                                                        (int) month + 1,
                                                        (int) day,
                                                        0,
                                                        0,
                                                        0);
                var date = new GLib.DateTime.from_unix_utc (expires.value);
                date = date.to_local ();
                if (new_date.get_year () == date.get_year () &&
                    new_date.get_month () == date.get_month () &&
                    new_date.get_day_of_month () == date.get_day_of_month ())
                    new_date = date;

                return GpgExpirationSpec (GpgExpirationFormat.DATE,
                                          new_date.to_utc ().to_unix ());
            }

            var value = date_spinbutton.get_value_as_int ();
            if (value == 0) {
                return GpgExpirationSpec (GpgExpirationFormat.NEVER, 0);
            }

            Gtk.TreeIter iter;
            date_combobox.get_active_iter (out iter);
            GpgExpirationFormat format;
            date_combobox.get_model ().get (iter, 1, out format);
            return GpgExpirationSpec (format, value);
        }
    }

    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-editor-widget.ui")]
    class GpgEditorWidget : Gtk.Stack {
        [GtkChild]
        Gtk.Button add_subkey_button;

        [GtkChild]
        Gtk.Button delete_subkey_button;

        [GtkChild]
        Gtk.ListBox subkey_list_box;

        [GtkChild]
        Gtk.Button add_user_id_button;

        [GtkChild]
        Gtk.Button delete_user_id_button;

        [GtkChild]
        Gtk.ListBox user_id_list_box;

        [GtkChild]
        Gtk.ComboBox trust_combobox;

        [GtkChild]
        Gtk.Label key_id_label;

        [GtkChild]
        Gtk.Label pubkey_algo_label;

        [GtkChild]
        Gtk.Label length_label;

        [GtkChild]
        Gtk.Label fingerprint_label;

        [GtkChild]
        Gtk.Label status_label;

        [GtkChild]
        Gtk.Label created_label;

        [GtkChild]
        Gtk.Stack expires_stack;

        [GtkChild]
        Gtk.Button change_password_button;

        [GtkChild]
        Gtk.Label usage_label;

        [GtkChild]
        Gtk.Label user_id_label;

        [GtkChild]
        Gtk.Grid user_id_properties_grid;

        [GtkChild]
        Gtk.Label validity_label;

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
                var subkey_item = new GpgEditorSubkeyItem (index, subkey);
                this._subkey_store.append (subkey_item);
                if (this._subkey_item != null &&
                    this._subkey_item.index == index)
                    this._subkey_item = subkey_item;
                index++;
            }

            list_box_adjust_scrolling (subkey_list_box);

            if (this._subkey_item != null)
                update_subkey_properties (this._subkey_item);
        }

        [GtkCallback]
        void on_delete_subkey_clicked (Gtk.Button button) {
            var dialog = new Gtk.MessageDialog (
                (Gtk.Window) this.get_toplevel (),
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.QUESTION,
                Gtk.ButtonsType.OK_CANCEL,
                _("Remove subkey \"%s\"? "),
                this._subkey_item.subkey.key_id);
            dialog.response.connect ((res) => {
                    if (res == Gtk.ResponseType.OK)
                        call_edit_delkey (this._subkey_item.index);
                    dialog.destroy ();
                    visible_child_name = "main";
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
            dialog.set_transient_for ((Gtk.Window) this.get_toplevel ());
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.show ();
        }

        void update_subkey_properties (GpgEditorSubkeyItem item) {
            key_id_label.label = item.subkey.key_id;
            pubkey_algo_label.label =
                GpgUtils.format_pubkey_algo (item.subkey.pubkey_algo);
            length_label.label = _("%u bits").printf (item.subkey.length);
            fingerprint_label.label =
                GpgUtils.format_fingerprint (item.subkey.fingerprint);
            status_label.label =
                GpgUtils.format_subkey_status (item.subkey.flags);
            created_label.label =
                format_date (new GLib.DateTime.from_unix_utc (item.subkey.created), DateFormat.FULL);
            var expires_text = GpgUtils.format_expires (item.subkey.expires);
            if (((GpgItem) this.item).has_secret) {
                expires_stack.visible_child_name = "button";
                var expires_button =
                    (Gtk.MenuButton) expires_stack.visible_child;
                expires_button.label = expires_text;
                GpgExpirationSpec expires;
                if (item.subkey.expires == 0)
                    expires = GpgExpirationSpec (GpgExpirationFormat.NEVER, 0);
                else
                    expires = GpgExpirationSpec (GpgExpirationFormat.DATE,
                                                 item.subkey.expires);
                var popover = new GpgExpiresPopover (expires, true);
                expires_button.set_popover (popover);
                popover.closed.connect (() => {
                        var spec = popover.get_spec ();
                        if (!spec.equal (expires))
                            call_edit_expire (item.index, spec);
                    });
            } else {
                expires_stack.visible_child_name = "label";
                var expires_label = (Gtk.Label) expires_stack.visible_child;
                expires_label.label = expires_text;
            }
            usage_label.label = GpgUtils.format_usage (item.subkey.flags);
        }

        void call_edit_expire (uint index, GpgExpirationSpec spec) {
            var _item = (GpgItem) item;
            var window = (Gtk.Window) this.get_toplevel ();
            var command = new GpgExpireEditCommand (index, spec);
            _item.edit.begin (command, null, (obj, res) => {
                    try {
                        _item.edit.end (res);
                    } catch (GLib.Error e) {
                        show_error (window,
                                    "Couldn't change expiration: %s",
                                    e.message);
                    }
                });
        }

        [GtkCallback]
        void on_subkey_selected (Gtk.ListBox list_box, Gtk.ListBoxRow? row) {
            if (row != null) {
                var index = row.get_index ();
                this._subkey_item =
                    (GpgEditorSubkeyItem) this._subkey_store.get_item (index);
                update_subkey_properties (this._subkey_item);
                visible_child_name = "subkey";
            }
        }

        GLib.ListStore _user_id_store;

        Gtk.Widget create_user_id_widget (GLib.Object object) {
            var user_id_item = (GpgEditorUserIdItem) object;
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
            var text = escape_invalid_chars (user_id_item.user_id.uid);
            var label = new Gtk.Label (text);
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
                var item = new GpgEditorUserIdItem (index, uid);
                this._user_id_store.append (item);
                index++;
            }

            list_box_adjust_scrolling (user_id_list_box);
        }

        [GtkCallback]
        void on_delete_user_id_clicked (Gtk.Button button) {
            var dialog = new Gtk.MessageDialog (
                (Gtk.Window) this.get_toplevel (),
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.QUESTION,
                Gtk.ButtonsType.OK_CANCEL,
                _("Remove user ID \"%s\"? "),
                this._user_id_item.user_id.uid);
            dialog.response.connect ((res) => {
                    if (res == Gtk.ResponseType.OK)
                        call_edit_deluid (this._user_id_item.index);
                    dialog.destroy ();
                    visible_child_name = "main";
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
            dialog.set_transient_for ((Gtk.Window) this.get_toplevel ());
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.show ();
        }

        void insert_property (Gtk.Grid grid, int row,
                              string name, string value) {
            grid.insert_row (row);
            var name_label = new Gtk.Label (name);
            name_label.xalign = 1;
            var context = name_label.get_style_context ();
            context.add_class ("dim-label");
            name_label.show ();
            grid.attach (name_label, 0, row, 1, 1);

            var value_label = new Gtk.Label (value);
            value_label.xalign = 0;
            value_label.show ();
            grid.attach (value_label, 1, row, 1, 1);
        }

        void update_user_id_properties (GpgEditorUserIdItem item) {
            user_id_label.label = item.user_id.uid;
            if (item.user_id.comment != "" &&
                item.user_id.comment != item.user_id.uid)
                insert_property (user_id_properties_grid, 1,
                                 _("Comment"), item.user_id.comment);
            if (item.user_id.email != "" &&
                item.user_id.email != item.user_id.uid)
                insert_property (user_id_properties_grid, 1,
                                 _("Email"), item.user_id.email);
            if (item.user_id.name != "" &&
                item.user_id.name != item.user_id.uid)
                insert_property (user_id_properties_grid, 1,
                                 _("Name"), item.user_id.name);
            validity_label.label =
                GpgUtils.format_validity (item.user_id.validity);
        }

        [GtkCallback]
        void on_user_id_selected (Gtk.ListBox list_box, Gtk.ListBoxRow? row) {
            if (row != null) {
                var index = row.get_index ();
                this._user_id_item =
                    (GpgEditorUserIdItem) this._user_id_store.get_item (index);
                update_user_id_properties (this._user_id_item);
                visible_child_name = "user_id";
            }
        }

        public GpgItem item { construct set; get; }

        public GpgEditorWidget (GpgItem item) {
            Object (item: item);
        }

        construct {
            this._user_id_store =
                new GLib.ListStore (typeof (GpgEditorUserIdItem));
            user_id_list_box.bind_model (this._user_id_store,
                                         create_user_id_widget);
            user_id_list_box.set_header_func (list_box_update_header_func);
            list_box_setup_scrolling (user_id_list_box, 0);
            item.changed.connect (update_user_id_list);
            update_user_id_list ();

            this._subkey_store =
                new GLib.ListStore (typeof (GpgEditorSubkeyItem));
            subkey_list_box.bind_model (this._subkey_store,
                                        create_subkey_widget);
            subkey_list_box.set_header_func (list_box_update_header_func);
            list_box_setup_scrolling (subkey_list_box, 0);
            item.changed.connect (update_subkey_list);
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
            item.changed.connect (update_trust);
            update_trust ();

            item.bind_property ("has-secret",
                                add_subkey_button, "visible",
                                GLib.BindingFlags.SYNC_CREATE);
            item.bind_property ("has-secret",
                                delete_subkey_button, "visible",
                                GLib.BindingFlags.SYNC_CREATE);
            item.bind_property ("has-secret",
                                add_user_id_button, "visible",
                                GLib.BindingFlags.SYNC_CREATE);
            item.bind_property ("has-secret",
                                delete_user_id_button, "visible",
                                GLib.BindingFlags.SYNC_CREATE);
            item.bind_property ("has-secret",
                                change_password_button, "visible",
                                GLib.BindingFlags.SYNC_CREATE);
        }

        void update_trust () {
            var model = trust_combobox.get_model ();
            Gtk.TreeIter iter;
            if (model.get_iter_first (out iter)) {
                do {
                    GGpg.Validity validity;
                    model.get (iter, 1, out validity);
                    if (validity == item.owner_trust) {
                        trust_combobox.set_active_iter (iter);
                        break;
                    }
                } while (model.iter_next (ref iter));
            }
        }

        void on_trust_changed () {
            Gtk.TreeIter iter;
            trust_combobox.get_active_iter (out iter);

            GGpg.Validity validity;
            trust_combobox.get_model ().get (iter, 1, out validity);
            if (validity == item.owner_trust)
                return;

            var command = new GpgTrustEditCommand (validity);
            var window = (Gtk.Window) this.get_toplevel ();
            item.edit.begin (command, null, (obj, res) => {
                    try {
                        item.edit.end (res);
                    } catch (GLib.Error e) {
                        show_error (window,
                                    "Couldn't change owner trust: %s",
                                    e.message);
                    }
                });
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
    }

    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-editor-dialog.ui")]
    class GpgEditorDialog : EditorDialog {
        [GtkChild]
        Gtk.Button delete_button;

        [GtkChild]
        Gtk.Button back_button;

        [GtkChild]
        Gtk.Box box;

        GpgEditorWidget _widget;

        public GpgEditorDialog (Item item) {
            Object (item: item, use_header_bar: 1);
        }

        construct {
            this._widget = new GpgEditorWidget ((GpgItem) item);
            this._widget.notify["visible-child"].connect (() => {
                    if (this._widget.visible_child_name == "main") {
                        delete_button.show ();
                        back_button.hide ();
                    } else {
                        delete_button.hide ();
                        back_button.show ();
                    }
                });
            this._widget.show ();
            box.pack_start (this._widget, true, true, 0);
        }

        [GtkCallback]
        void on_back_clicked (Gtk.Button button) {
            this._widget.visible_child_name = "main";
        }
    }
}
