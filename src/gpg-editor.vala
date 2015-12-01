namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-add-subkey-dialog.ui")]
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

    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-add-user-id-dialog.ui")]
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

    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-expires-popover.ui")]
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

    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-edit-subkey-widget.ui")]
    class GpgEditSubkeyWidget : Gtk.Box {
        [GtkChild]
        Gtk.Label key_id_label;

        [GtkChild]
        Gtk.Label pubkey_algo_label;

        [GtkChild]
        Gtk.Label length_label;

        [GtkChild]
        Gtk.Label fingerprint_label;

        [GtkChild]
        Gtk.Label usage_label;

        [GtkChild]
        Gtk.Label status_label;

        [GtkChild]
        Gtk.Label created_label;

        [GtkChild]
        Gtk.Stack expires_stack;

        [GtkChild]
        Gtk.Button delete_button;

        public GpgItem item { construct set; get; }

        uint _index;
        public uint index {
            construct set {
                this._index = value;
            }
            get {
                return this._index;
            }
        }

        GGpg.Subkey _subkey;
        public GGpg.Subkey subkey {
            construct set {
                this._subkey = value;
                update_properties ();
            }
        }

        public GpgEditSubkeyWidget (GpgItem item, uint index, GGpg.Subkey subkey) {
            Object (item: item, index: index, subkey: subkey);
        }

        construct {
            Gtk.Grid grid;
            int index;

            grid = (Gtk.Grid) usage_label.get_parent ();
            grid.child_get (usage_label, "top-attach", out index);
            grid_bind_row_property (usage_label, "label",
                                    grid, index, "visible",
                                    GLib.BindingFlags.SYNC_CREATE,
                                    transform_is_non_empty_string);
        }

        public signal void deleted ();

        [GtkCallback]
        void on_delete_clicked (Gtk.Button button) {
            deleted ();
        }

        void update_properties () {
            key_id_label.label = this._subkey.key_id;
            pubkey_algo_label.label =
                GpgUtils.format_pubkey_algo (this._subkey.pubkey_algo);
            length_label.label = _("%u bits").printf (this._subkey.length);
            fingerprint_label.label =
                GpgUtils.format_fingerprint (this._subkey.fingerprint);
            status_label.label =
                GpgUtils.format_subkey_status (this._subkey.flags);
            var created_date =
                new GLib.DateTime.from_unix_utc (this._subkey.created);
            created_label.label = format_date (created_date, DateFormat.FULL);

            var expires_text =
                GpgUtils.format_expires (this._subkey.expires);
            if (item.has_secret) {
                expires_stack.visible_child_name = "button";
                var expires_button =
                    (Gtk.MenuButton) expires_stack.visible_child;
                expires_button.label = expires_text;
                GpgExpirationSpec expires;
                if (this._subkey.expires == 0)
                    expires = GpgExpirationSpec (GpgExpirationFormat.NEVER, 0);
                else
                    expires = GpgExpirationSpec (GpgExpirationFormat.DATE,
                                                 this._subkey.expires);
                var popover = new GpgExpiresPopover (expires, true);
                expires_button.set_popover (popover);
                popover.closed.connect (() => {
                        var spec = popover.get_spec ();
                        if (!spec.equal (expires))
                            call_edit_expire (this._index, spec);
                    });
            } else {
                expires_stack.visible_child_name = "label";
                var expires_label = (Gtk.Label) expires_stack.visible_child;
                expires_label.label = expires_text;
            }

            usage_label.label = GpgUtils.format_usage (this._subkey.flags);

            var primary = item.get_subkeys ().first ().data;
            if (!item.has_secret || this._subkey.key_id == primary.key_id)
                delete_button.hide ();
            else
                delete_button.show ();
       }

        void call_edit_expire (uint index, GpgExpirationSpec spec) {
            var window = (Gtk.Window) this.get_toplevel ();
            var command = new GpgExpireEditCommand (index, spec);
            item.edit.begin (command, null, (obj, res) => {
                    try {
                        item.edit.end (res);
                    } catch (GLib.Error e) {
                        show_error (window,
                                    "Couldn't change expiration: %s",
                                    e.message);
                    }
                });
        }
    }

    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-edit-user-id-widget.ui")]
    class GpgEditUserIdWidget : Gtk.Box {
        [GtkChild]
        Gtk.Button delete_button;

        [GtkChild]
        Gtk.Label user_id_label;

        [GtkChild]
        Gtk.Label name_label;

        [GtkChild]
        Gtk.Label email_label;

        [GtkChild]
        Gtk.Label comment_label;

        [GtkChild]
        Gtk.Label validity_label;

        public GpgItem item { construct set; get; }

        GGpg.UserId _user_id;
        public GGpg.UserId user_id {
            construct set {
                this._user_id = value;
                update_properties ();
            }
        }

        public GpgEditUserIdWidget (GpgItem item, GGpg.UserId user_id) {
            Object (item: item, user_id: user_id);
        }

        construct {
            Gtk.Grid grid;
            int index;

            grid = (Gtk.Grid) name_label.get_parent ();
            grid.child_get (name_label, "top-attach", out index);
            grid_bind_row_property (name_label, "label",
                                    grid, index, "visible",
                                    GLib.BindingFlags.SYNC_CREATE,
                                    transform_is_non_empty_string);

            grid = (Gtk.Grid) email_label.get_parent ();
            grid.child_get (email_label, "top-attach", out index);
            grid_bind_row_property (email_label, "label",
                                    grid, index, "visible",
                                    GLib.BindingFlags.SYNC_CREATE,
                                    transform_is_non_empty_string);

            grid = (Gtk.Grid) comment_label.get_parent ();
            grid.child_get (comment_label, "top-attach", out index);
            grid_bind_row_property (comment_label, "label",
                                    grid, index, "visible",
                                    GLib.BindingFlags.SYNC_CREATE,
                                    transform_is_non_empty_string);
        }

        public signal void deleted ();

        [GtkCallback]
        void on_delete_clicked (Gtk.Button button) {
            deleted ();
        }

        void update_properties () {
            user_id_label.label = this._user_id.uid;

            if (this._user_id.name != "" &&
                this._user_id.name != this._user_id.uid) {
                name_label.label = this._user_id.name;
            } else {
                name_label.label = "";
            }

            if (this._user_id.email != "" &&
                this._user_id.email != this._user_id.uid) {
                email_label.label = this._user_id.email;
            } else {
                email_label.label = "";
            }

            if (this._user_id.comment != "" &&
                this._user_id.comment != this._user_id.uid) {
                comment_label.label = this._user_id.comment;
            } else {
                comment_label.label = "";
            }

            validity_label.label =
                GpgUtils.format_validity (this._user_id.validity);

            if (!item.has_secret || item.get_uids ().next == null)
                delete_button.hide ();
            else
                delete_button.show ();
        }
    }

    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-editor-widget.ui")]
    class GpgEditorWidget : Gtk.Stack {
        [GtkChild]
        Gtk.Button add_subkey_button;

        [GtkChild]
        Gtk.ListBox subkey_list_box;

        [GtkChild]
        Gtk.Button add_user_id_button;

        [GtkChild]
        Gtk.ListBox user_id_list_box;

        [GtkChild]
        Gtk.ComboBox trust_combobox;

        [GtkChild]
        Gtk.Button change_password_button;

        GGpg.Subkey? _subkey;
        GGpg.UserId? _user_id;

        GLib.ListStore _subkey_store;
        GLib.ListStore _user_id_store;

        public GpgItem item { construct set; get; }

        public GpgEditorWidget (GpgItem item) {
            Object (item: item);
        }

        construct {
            this._subkey_store = new GLib.ListStore (typeof (GGpg.Subkey));
            subkey_list_box.bind_model (this._subkey_store,
                                        create_subkey_widget);
            subkey_list_box.set_header_func (list_box_update_header_func);
            list_box_setup_scrolling (subkey_list_box, 0);
            item.changed.connect (update_subkey_list);
            update_subkey_list ();

            this._user_id_store = new GLib.ListStore (typeof (GGpg.UserId));
            user_id_list_box.bind_model (this._user_id_store,
                                         create_user_id_widget);
            user_id_list_box.set_header_func (list_box_update_header_func);
            list_box_setup_scrolling (user_id_list_box, 0);
            item.changed.connect (update_user_id_list);
            update_user_id_list ();

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

            Gtk.Grid grid;
            int index;

            grid = (Gtk.Grid) trust_combobox.get_parent ();
            grid.child_get (trust_combobox, "top-attach", out index);
            grid_bind_row_property (item,
                                   "keylist-mode",
                                    grid, index, "visible",
                                    GLib.BindingFlags.SYNC_CREATE,
                                    transform_keylist_mode_is_local);

            item.bind_property ("has-secret",
                                add_subkey_button, "visible",
                                GLib.BindingFlags.SYNC_CREATE);
            item.bind_property ("has-secret",
                                add_user_id_button, "visible",
                                GLib.BindingFlags.SYNC_CREATE);
            item.bind_property ("has-secret",
                                change_password_button, "visible",
                                GLib.BindingFlags.SYNC_CREATE);
        }

        bool transform_keylist_mode_is_local (GLib.Binding binding,
                                              GLib.Value source_value,
                                              ref GLib.Value target_value)
        {
            var flags = source_value.get_flags ();
            target_value.set_boolean ((flags & GGpg.KeylistMode.EXTERN) == 0);
            return true;
        }

        Gtk.Widget create_subkey_widget (GLib.Object object) {
            var subkey = (GGpg.Subkey) object;
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            var label = new Gtk.Label (subkey.key_id);
            label.margin_start = 20;
            label.margin_end = 20;
            label.margin_top = 6;
            label.margin_bottom = 6;
            label.xalign = 0;
            box.pack_start (label, false, false, 0);

            var usage = GpgUtils.format_usage (subkey.flags);
            if (usage != "") {
                label = new Gtk.Label (_("used for: %s").printf (usage));
                label.margin_start = 20;
                label.margin_end = 20;
                label.xalign = 0;
                var context = label.get_style_context ();
                context.add_class ("secondary-label");
                context.add_class ("dim-label");
                box.pack_start (label, false, false, 0);
            }

            box.show_all ();
            return box;
        }

        void update_subkey_list () {
            this._subkey_store.remove_all ();
            foreach (var subkey in item.get_subkeys ()) {
                this._subkey_store.append (subkey);
                if (this._subkey != null &&
                    subkey.key_id == this._subkey.key_id) {
                    this._subkey = subkey;
                    var edit_widget = (GpgEditSubkeyWidget) get_child_by_name ("subkey");
                    edit_widget.subkey = this._subkey;
                }
            }

            list_box_adjust_scrolling (subkey_list_box);
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

        void delete_subkey (GGpg.Subkey subkey) {
            // Re-enumerate subkeys, considering the case where a new
            // subkey is added during the session.
            var index = 0;
            foreach (var _subkey in item.get_subkeys ()) {
                if (_subkey.key_id == subkey.key_id)
                    break;
                index++;
            }
            var dialog = new Gtk.MessageDialog (
                (Gtk.Window) this.get_toplevel (),
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.QUESTION,
                Gtk.ButtonsType.OK_CANCEL,
                _("Remove subkey \"%s\"? "),
                subkey.key_id);
            dialog.response.connect ((res) => {
                    if (res == Gtk.ResponseType.OK) {
                        call_edit_delkey (index);
                        visible_child_name = "main";
                    }
                    dialog.destroy ();
                });
            dialog.show ();
        }

        void call_edit_delkey (uint index) {
            var window = (Gtk.Window) this.get_toplevel ();
            var command = new GpgDelKeyEditCommand (index);
            item.edit.begin (command, null, (obj, res) => {
                    try {
                        item.edit.end (res);
                    } catch (GLib.Error e) {
                        show_error (window,
                                    "Couldn't remove subkey: %s",
                                    e.message);
                    }
                });
        }

        [GtkCallback]
        void on_subkey_selected (Gtk.ListBox list_box, Gtk.ListBoxRow? row) {
            if (row != null) {
                var index = row.get_index ();
                this._subkey = (GGpg.Subkey) this._subkey_store.get_item (index);
                var edit_widget = (GpgEditSubkeyWidget) get_child_by_name ("subkey");
                if (edit_widget == null) {
                    edit_widget = new GpgEditSubkeyWidget (item, index, this._subkey);
                    edit_widget.deleted.connect (() => {
                            delete_subkey (this._subkey);
                        });
                    add_named (edit_widget, "subkey");
                } else {
                    edit_widget.subkey = this._subkey;
                }
                visible_child_name = "subkey";
            }
        }

        Gtk.Widget create_user_id_widget (GLib.Object object) {
            var user_id = (GGpg.UserId) object;
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
            var text = escape_invalid_chars (user_id.uid);
            var label = new Gtk.Label (text);
            label.margin_start = 20;
            label.margin_end = 20;
            label.margin_top = 6;
            label.margin_bottom = 6;
            label.ellipsize = Pango.EllipsizeMode.END;
            box.pack_start (label, false, false, 6);
            box.show_all ();
            return box;
        }

        void update_user_id_list () {
            this._user_id_store.remove_all ();
            foreach (var user_id in item.get_uids ()) {
                this._user_id_store.append (user_id);
                if (this._user_id != null && user_id.uid == this._user_id.uid) {
                    this._user_id = user_id;
                    var edit_widget = (GpgEditUserIdWidget) get_child_by_name ("user_id");
                    edit_widget.user_id = this._user_id;
                }
            }

            list_box_adjust_scrolling (user_id_list_box);
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

        [GtkCallback]
        void on_user_id_selected (Gtk.ListBox list_box, Gtk.ListBoxRow? row) {
            if (row != null) {
                var index = row.get_index ();
                this._user_id = (GGpg.UserId) this._user_id_store.get_item (index);
                var edit_widget = (GpgEditUserIdWidget) get_child_by_name ("user_id");
                if (edit_widget == null) {
                    edit_widget = new GpgEditUserIdWidget (item, this._user_id);
                    edit_widget.deleted.connect (() => {
                            delete_user_id (this._user_id);
                        });
                    add_named (edit_widget, "user_id");
                } else {
                    edit_widget.user_id = this._user_id;
                }
                visible_child_name = "user_id";
            }
        }

        void delete_user_id (GGpg.UserId user_id) {
            // Re-enumerate user IDs, considering the case where a new
            // user ID is added during the session.
            var index = 0;
            foreach (var _user_id in item.get_uids ()) {
                if (_user_id.uid == user_id.uid)
                    break;
                index++;
            }

            var dialog = new Gtk.MessageDialog (
                (Gtk.Window) this.get_toplevel (),
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.QUESTION,
                Gtk.ButtonsType.OK_CANCEL,
                _("Remove user ID \"%s\"? "),
                user_id.uid);
            dialog.response.connect ((res) => {
                    if (res == Gtk.ResponseType.OK) {
                        call_edit_deluid (index);
                        visible_child_name = "main";
                    }
                    dialog.destroy ();
                });
            dialog.show ();
        }

        void call_edit_deluid (uint index) {
            var window = (Gtk.Window) this.get_toplevel ();
            var command = new GpgDelUidEditCommand (index);
            item.edit.begin (command, null, (obj, res) => {
                    try {
                        item.edit.end (res);
                    } catch (GLib.Error e) {
                        show_error (window,
                                    "Couldn't add user ID: %s", e.message);
                    }
                });
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
