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
                                        "Couldn't add user ID: %s", e.message);
                        }
                    });
            }
        }
    }

    class GpgEditorUserIdItem : GLib.Object {
        public int index { construct set; get; }
        public GGpg.UserId? user_id { construct set; get; }

        public GpgEditorUserIdItem (int index, GGpg.UserId? user_id) {
            Object (index: index, user_id: user_id);
        }
    }

    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-editor.ui")]
    class GpgEditorDialog : Gtk.Dialog {
        [GtkChild]
        Gtk.ListBox user_id_list_box;
        [GtkChild]
        Gtk.Grid properties_grid;

        public GpgItem item { construct set; get; }

        public GpgEditorDialog (GpgItem item) {
            Object (item: item, use_header_bar: 1);
        }

        Gtk.Widget create_user_id_widget (GLib.Object object) {
            var user_id_item = (GpgEditorUserIdItem) object;
            if (user_id_item.index == 0) {
                var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
                var gicon = new GLib.ThemedIcon ("list-add-symbolic");
                var image =
                    new Gtk.Image.from_gicon (gicon,
                                              Gtk.IconSize.SMALL_TOOLBAR);
                var button = new Gtk.Button ();
                button.set_image (image);
                button.relief = Gtk.ReliefStyle.NONE;
                button.clicked.connect (() => {
                        var dialog = new GpgAddUserIdDialog (item);
                        dialog.set_transient_for (this);
                        dialog.response.connect_after ((res) => {
                                dialog.destroy ();
                            });
                        dialog.show ();
                    });
                box.pack_start (button, true, true, 0);
                box.show_all ();
                return box;
            } else {
                var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
                var label = new Gtk.Label (user_id_item.user_id.uid);
                box.pack_start (label, false, false, 10);
                var gicon = new GLib.ThemedIcon ("window-close-symbolic");
                var image =
                    new Gtk.Image.from_gicon (gicon,
                                              Gtk.IconSize.SMALL_TOOLBAR);
                var button = new Gtk.Button ();
                button.set_image (image);
                button.relief = Gtk.ReliefStyle.NONE;
                button.clicked.connect (() => {
                    var confirm_dialog =
                        new Gtk.MessageDialog (this,
                                               Gtk.DialogFlags.MODAL,
                                               Gtk.MessageType.QUESTION,
                                               Gtk.ButtonsType.OK_CANCEL,
                                               _("Remove user ID \"%s\"? "),
                                               user_id_item.user_id.uid);
                    confirm_dialog.response.connect ((res) => {
                            if (res == Gtk.ResponseType.OK)
                                edit_del_uid (user_id_item.index);
                            confirm_dialog.destroy ();
                        });
                    confirm_dialog.show ();
                });
                box.pack_end (button, false, false, 0);
                box.show_all ();
                return box;
            }
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

        GLib.ListStore _store;

        void update_user_id_list () {
            this._store.remove_all ();
            int index = 1;
            foreach (var uid in item.get_uids ()) {
                var item = new GpgEditorUserIdItem (index, uid);
                this._store.append (item);
                index++;
            }

            this._store.append (new GpgEditorUserIdItem (0, null));
            list_box_adjust_scrolling (user_id_list_box);
        }

        void edit_del_uid (uint index) {
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

        construct {
            this._store = new GLib.ListStore (typeof (GpgEditorUserIdItem));
            user_id_list_box.bind_model (this._store,
                                         this.create_user_id_widget);
            user_id_list_box.set_selection_mode (Gtk.SelectionMode.NONE);
            user_id_list_box.set_header_func (list_box_update_header_func);
            list_box_setup_scrolling (user_id_list_box, 0);
            item.changed.connect (update_user_id_list);
            update_user_id_list ();

            var row_index = 0;
            var label = create_name_label (_("Owner trust"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (GpgUtils.format_validity (item.owner_trust));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            var subkeys = item.get_subkeys ();
            var pubkey = subkeys.first ().data;

            label = create_name_label (_("Algorithm"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (GpgUtils.format_pubkey_algo (pubkey.pubkey_algo));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Strength"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (_("%u bits").printf (pubkey.length));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Fingerprint"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (format_fingerprint (pubkey.fingerprint));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Valid until"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            if (pubkey.expires == 0)
                label = create_value_label (_("Never"));
            else {
                var expires = new DateTime.from_unix_utc (pubkey.expires);
                var date_string = format_date (expires.to_local (),
                                               DateFormat.FULL);
                label = create_value_label (date_string);
            }
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            properties_grid.show_all ();
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
                                        _("Couldn't delete PGP key: %s"),
                                        e.message);
                        }
                    });
                break;
            case EditorResponse.DONE:
                break;
            }
        }
    }

    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-generator.ui")]
    class GpgGeneratorDialog : Gtk.Dialog {
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

        public GpgCollection collection { construct set; get; }

        public GpgGeneratorDialog (GpgCollection collection) {
            Object (collection: collection, use_header_bar: 1);
        }

        construct {
            var store = new Gtk.ListStore (2,
                                           typeof (GpgGenerateKeyType),
                                           typeof (string));
            var enum_class =
                (EnumClass) typeof (GpgGenerateKeyType).class_ref ();
            for (var index = enum_class.minimum;
                 index <= enum_class.maximum;
                 index++) {
                if (enum_class.get_value (index) == null)
                    continue;

                var key_type = (GpgGenerateKeyType) index;

                Gtk.TreeIter iter;
                store.append (out iter);
                store.set (iter,
                           0, index,
                           1, GpgUtils.format_key_type (key_type));
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
            GpgGenerateKeyType key_type;
            key_type_combobox.get_model ().get (iter, 0, out key_type);
            var length = GpgUtils.get_generate_key_length (key_type);
            var adjustment = new Gtk.Adjustment (length._default,
                                                 length.min,
                                                 length.max,
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
                GpgGenerateKeyType key_type;
                key_type_combobox.get_model ().get (iter, 0, out key_type);

                var parameters = new GpgGenerateParameters (
                    name_entry.get_text (),
                    email_entry.get_text (),
                    comment_entry.get_text (),
                    key_type,
                    length_spinbutton.get_value_as_int (),
                    0);

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
                                        "Couldn't generate PGP key: %s",
                                        e.message);
                        }
                    });
            }
        }
    }

    class GpgWidgetFactory : WidgetFactory {
        public override Gtk.Widget create_list_box_row (Item _item) {
            var item = (GpgItem) _item;
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);

            var heading = new Gtk.Label (item.get_label ());
            var context = heading.get_style_context ();
            context.add_class ("key-list-heading");
            heading.xalign = 0;
            heading.set_ellipsize (Pango.EllipsizeMode.END);
            box.pack_start (heading, false, false, 0);

            var protocol = ((GpgCollection) item.collection).protocol;
            var name = new Gtk.Label (_("%s Key").printf (GpgUtils.format_protocol (protocol)));
            context = name.get_style_context ();
            context.add_class ("key-list-type");
            context.add_class ("dim-label");
            box.pack_end (name, false, false, 0);
            box.show_all ();
            return box;
        }

        public override Gtk.Dialog create_editor_dialog (Item item) {
            return new GpgEditorDialog ((GpgItem) item);
        }
    }
}
