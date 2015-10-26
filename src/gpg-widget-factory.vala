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
                        item.content_changed ();
                    });
            }
        }
    }

    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-editor.ui")]
    class GpgEditorDialog : Gtk.Dialog {
        [GtkChild]
        Gtk.ListBox user_id_list_box;
        [GtkChild]
        Gtk.Button add_uid_button;
        [GtkChild]
        Gtk.Button remove_uid_button;
        [GtkChild]
        Gtk.Grid properties_grid;

        public GpgItem item { construct set; get; }

        public GpgEditorDialog (GpgItem item) {
            Object (item: item, use_header_bar: 1);
        }

        Gtk.Widget create_user_id_widget (GLib.Object object) {
            var label = new Gtk.Label (((GGpg.UserId) object).uid);
            label.xalign = 0;
            return label;
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
        GLib.HashTable<string,GGpg.UserId> _uids;

        void on_content_changed () {
            item.load_content.begin (null, (obj, res) => {
                    try {
                        item.load_content.end (res);
                    } catch (GLib.Error e) {
                        return;
                    }
                    update_user_id_list ();
                });
        }

        void update_user_id_list () {
            var seen = new GLib.HashTable<string,void*> (GLib.str_hash,
                                                         GLib.str_equal);
            foreach (var uid in item.get_uids ()) {
                seen.add (uid.uid);
                if (!this._uids.contains (uid.uid)) {
                    this._uids.insert (uid.uid, uid);
                    this._store.append (uid);
                }
            }

            var iter = GLib.HashTableIter<string,GGpg.UserId> (this._uids);
            string uid_string;
            GGpg.UserId uid;
            while (iter.next (out uid_string, out uid)) {
                if (!seen.contains (uid_string)) {
                    iter.remove ();
                    for (var position = 0;
                         position < this._store.get_n_items ();
                         position++) {
                        var _uid =
                            (GGpg.UserId) this._store.get_item (position);
                        if (_uid.uid == uid_string) {
                            this._store.remove (position);
                            break;
                        }
                    }
                }
            }

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
                    item.content_changed ();
                });
        }

        construct {
            this._uids = new GLib.HashTable<string,GGpg.UserId> (GLib.str_hash,
                                                                 GLib.str_equal);
            this._store = new GLib.ListStore (typeof (GGpg.UserId));
            foreach (var uid in item.get_uids ()) {
                this._store.append (uid);
                this._uids.insert (uid.uid, uid);
            }
            user_id_list_box.bind_model (this._store,
                                         this.create_user_id_widget);
            user_id_list_box.set_selection_mode (Gtk.SelectionMode.SINGLE);
            user_id_list_box.set_header_func (list_box_update_header_func);
            list_box_setup_scrolling (user_id_list_box, 0);
            list_box_adjust_scrolling (user_id_list_box);
            item.content_changed.connect (on_content_changed);

            add_uid_button.clicked.connect (() => {
                    var dialog = new GpgAddUserIdDialog (item);
                    dialog.set_transient_for (this);
                    dialog.response.connect_after ((res) => {
                            dialog.destroy ();
                        });
                    dialog.show ();
                });
            remove_uid_button.clicked.connect (() => {
                    var row = user_id_list_box.get_selected_row ();
                    var uid =
                        (GGpg.UserId) this._store.get_item (row.get_index ());
                    var confirm_dialog =
                        new Gtk.MessageDialog (this,
                                               Gtk.DialogFlags.MODAL,
                                               Gtk.MessageType.QUESTION,
                                               Gtk.ButtonsType.OK_CANCEL,
                                               _("Remove user ID \"%s\"? "),
                                               uid.uid);
                    confirm_dialog.response.connect ((res) => {
                            if (res == Gtk.ResponseType.OK)
                                edit_del_uid (row.get_index () + 1);
                            confirm_dialog.destroy ();
                        });
                    confirm_dialog.show ();
                });
            user_id_list_box.row_selected.connect ((row) => {
                    sync_buttons ();
                });
            sync_buttons ();

            var row_index = 0;
            var label = create_name_label (_("Owner trust"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (GpgStrings.format_validity (item.owner_trust));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            var subkeys = item.get_subkeys ();
            var pubkey = subkeys.first ().data;

            label = create_name_label (_("Algorithm"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (GpgStrings.format_pubkey_algo (pubkey.pubkey_algo));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Strength"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (_("%u bits").printf (pubkey.length));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Fingerprint"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (pubkey.fingerprint);
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

        void sync_buttons () {
            if (user_id_list_box.get_selected_row () == null)
                remove_uid_button.set_sensitive (false);
            else {
                var children = user_id_list_box.get_children ();
                remove_uid_button.set_sensitive (children.length () > 0);
            }
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
                                        _("Couldn't delete password: %s"),
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
                var enum_value = enum_class.get_value (index);
                if (enum_value == null ||
                    enum_value.value_nick.has_prefix ("reserved"))
                    continue;

                var key_type = (GpgGenerateKeyType) index;

                Gtk.TreeIter iter;
                store.append (out iter);
                store.set (iter,
                           0, index,
                           1, GpgStrings.format_key_type (key_type));
            }

            key_type_combobox.set_model (store);
            var renderer = new Gtk.CellRendererText ();
            key_type_combobox.pack_start (renderer, true);
            key_type_combobox.set_attributes (renderer, "text", 1);
            key_type_combobox.set_active (0);
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
                    1024,
                    0);
                collection.generate_item (parameters, null,
                                          (obj, res) => {
                                              try {
                                                  collection.generate_item.end (res);
                                              } catch (GLib.Error e) {
                                                  warning ("cannot generate item: %s", e.message);
                                              }
                                              print ("generated\n");
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
            var name = new Gtk.Label (_("%s Key").printf (GpgStrings.format_protocol (protocol)));
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

        public override Gtk.Dialog create_generator_dialog (Generator generator) {
            return new GpgGeneratorDialog ((GpgCollection) generator);
        }
    }
}
