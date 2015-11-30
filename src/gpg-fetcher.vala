namespace Credentials {
    enum GpgFetcherResponse {
        IMPORT = -11
    }

    [GtkTemplate (ui = "/org/gnome/Credentials/gpg-fetcher.ui")]
    class GpgFetcherDialog : Gtk.Dialog {
        [GtkChild]
        Gtk.ListBox list_box;

        [GtkChild]
        Gtk.Button import_button;

        [GtkChild]
        Gtk.Button back_button;

        [GtkChild]
        Gtk.Stack main_stack;

        [GtkChild]
        Gtk.Spinner spinner;

        [GtkChild]
        Gtk.Stack search_stack;
        
        [GtkChild]
        Gtk.Box box;

        GLib.ListStore _store;
        GLib.Cancellable _cancellable;

        public GpgCollection collection { construct set; get; }

        uint _spinner_timeout_id = 0;

        GpgItem _item = null;
        GpgEditorWidget _widget = null;

        public GpgFetcherDialog (GpgCollection collection) {
            Object (collection: collection, use_header_bar: 1);
        }

        construct {
            this.search_stack.set_visible_child_name ("initial");
            this._store = new GLib.ListStore (typeof (GpgItem));
            list_box.bind_model (this._store, create_key_widget);
            list_box.set_header_func (list_box_update_header_func);
            list_box_setup_scrolling (list_box, 7);
            var header_bar = this.get_header_bar ();
            back_button.bind_property ("visible",
                                       header_bar, "show-close-button",
                                       GLib.BindingFlags.SYNC_CREATE |
                                       GLib.BindingFlags.INVERT_BOOLEAN);
            this._cancellable = new GLib.Cancellable ();
            this._cancellable.connect (clear_matches);
        }

        Gtk.Widget create_key_widget (GLib.Object object) {
            var item = (GpgItem) object;
            GLib.List<GGpg.UserId> uids = item.get_uids ();
            string[] secondary_labels = {};
            string primary_label = "";
            string primary_name = "";
            if (uids != null) {
                GGpg.UserId uid = uids.first ().data;
                primary_name = escape_invalid_chars (uid.name);
                if (primary_name != "") {
                    primary_label = primary_name;
                    if (uid.email != "")
                        secondary_labels += uid.email;
                } else
                    primary_label = uid.email;

                var count = 0;
                foreach (var uid2 in uids.next) {
                    string secondary_label = "";
                    var secondary_name = escape_invalid_chars (uid2.name);
                    if (secondary_name == "")
                        secondary_label = uid2.email;
                    else {
                        if (secondary_name != primary_name) {
                            if (uid2.email != "")
                                secondary_label = "%s: %s".printf (
                                    secondary_name,
                                    uid2.email);
                            else
                                secondary_label = secondary_name;
                        } else
                            secondary_label = uid2.email;
                    }

                    count++;
                    if (secondary_labels.length == 1) {
                        var remaining = uids.next.length () - count;
                        if (remaining > 0)
                            secondary_label =
                                _("%s, and %d more…").printf (secondary_label,
                                                              remaining);
                        secondary_labels += secondary_label;
                        break;
                    }
                    secondary_labels += secondary_label;
                }
            }

            while (secondary_labels.length < 1)
                secondary_labels += "";

            if (primary_label == "")
                primary_label = _("(empty user ID)");

            var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
            vbox.show ();

            var label = new Gtk.Label (primary_label);
            label.halign = Gtk.Align.START;
            label.ellipsize = Pango.EllipsizeMode.END;
            label.show ();
            vbox.pack_start (label, false, false, 0);

            foreach (var secondary_label in secondary_labels) {
                label = new Gtk.Label (secondary_label);
                var context = label.get_style_context ();
                context.add_class ("secondary-label");
                context.add_class ("dim-label");
                label.halign = Gtk.Align.START;
                label.ellipsize = Pango.EllipsizeMode.END;
                label.show ();
                vbox.pack_start (label, false, false, 0);
            }

            var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
            hbox.margin_start = 12;
            hbox.margin_end = 12;
            hbox.margin_top = 3;
            hbox.margin_bottom = 3;
            hbox.pack_start (vbox, false, false, 0);
            return hbox;
        }

        void clear_matches () {
            this._store.remove_all ();
            list_box_adjust_scrolling (list_box);
        }

        void start_spinner () {
            this._spinner_timeout_id = GLib.Timeout.add (500, () => {
                    this.search_stack.visible_child_name = "loading";
                    spinner.start ();
                    this._spinner_timeout_id = 0;
                    return GLib.Source.REMOVE;
                });
        }

        void stop_spinner () {
            if (this._spinner_timeout_id > 0) {
                GLib.Source.remove (this._spinner_timeout_id);
                this._spinner_timeout_id = 0;
            }
            spinner.stop ();
            if (this._store.get_n_items () > 0)
                this.search_stack.visible_child_name = "listing";
            else
                this.search_stack.visible_child_name = "initial";
        }

        [GtkCallback]
        void on_search_activate (Gtk.Entry entry) {
            this._cancellable.cancel ();

            var text = entry.get_text ().strip();
            if (text.length == 0)
                return;

            this._cancellable.reset ();
            var ctx = new GGpg.Ctx ();
            ctx.protocol = GGpg.Protocol.OPENPGP;
            ctx.keylist_mode = GGpg.KeylistMode.EXTERN;

            start_spinner ();
            ctx.keylist.begin (
                text, false,
                (key) => {
                    var context = GLib.MainContext.default ();
                    context.invoke (() => {
                            var uids = key.get_uids ();
                            if (uids != null) {
                                this._store.append (new GpgItem (collection, key));
                                list_box_adjust_scrolling (list_box);
                            }
                            return GLib.Source.REMOVE;
                        });
                },
                this._cancellable,
                (obj, res) => {
                    try {
                        ctx.keylist.end (res);
                    } catch (GLib.IOError.CANCELLED e) {
                    } catch (GLib.Error e) {
                        warning ("failed to list keys: %s", e.message);
                    }
                    stop_spinner ();
                });
        }

        [GtkCallback]
        void on_key_selected (Gtk.ListBox list_box, Gtk.ListBoxRow? row) {
            if (row != null) {
                var index = row.get_index ();
                this._item = (GpgItem) this._store.get_item (index);
                if (this._widget != null) {
                    box.remove (this._widget);
                }
                this._widget = new GpgEditorWidget (this._item);
                this._widget.bind_property ("visible-child-name",
                                            import_button, "visible",
                                            GLib.BindingFlags.SYNC_CREATE,
                                            transform_visible_child_name);
                this._widget.show ();
                box.pack_start (this._widget, true, true, 0);
                main_stack.visible_child_name = "browse";
                back_button.show ();
            }
        }

        bool transform_visible_child_name (GLib.Binding binding,
                                           GLib.Value source_value,
                                           ref GLib.Value target_value)
        {
            var name = source_value.get_string ();
            target_value.set_boolean (name == "main");
            return true;
        }

        [GtkCallback]
        void on_back_clicked (Gtk.Button button) {
            if (this._widget != null &&
                this._widget.visible_child_name != "main") {
                this._widget.visible_child_name = "main";
            } else {
                main_stack.visible_child_name = "search";
                import_button.hide ();
                back_button.hide ();
            }
        }

        public override void response (int res) {
            if (res == GpgFetcherResponse.IMPORT) {
                if (this._item != null) {
                    var window = (Gtk.Window) this.get_transient_for ();
                    collection.import_items.begin (
                        new GpgItem[] { this._item }, this._cancellable,
                        (obj, res) => {
                            try {
                                var result = collection.import_items.end (res);
                                show_notification (window,
                                                   _("%d keys imported (%d new, %d unchanged)"),
                                                   result.considered,
                                                   result.imported,
                                                   result.unchanged);
                            } catch (GLib.Error e) {
                                show_error (window,
                                            "Couldn't import keys: %s",
                                            e.message);
                            }
                        });
                }
            }
        }
    }
}
