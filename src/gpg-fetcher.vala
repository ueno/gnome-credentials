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
        Gtk.Button select_button;

        [GtkChild]
        Gtk.Spinner spinner;

        [GtkChild]
        Gtk.Stack stack;

        GLib.ListStore _store;
        GLib.Cancellable _cancellable;

        public GpgCollection collection { construct set; get; }

        uint _spinner_timeout_id = 0;

        public GpgFetcherDialog (GpgCollection collection) {
            Object (collection: collection, use_header_bar: 1);
        }

        construct {
            this.stack.set_visible_child_name ("default");
            this._store = new GLib.ListStore (typeof (GpgItem));
            list_box.bind_model (this._store, create_key_widget);
            list_box.set_header_func (list_box_update_header_func);
            list_box_setup_scrolling (list_box, 6);
            select_button.bind_property ("active", import_button, "visible",
                                         GLib.BindingFlags.SYNC_CREATE);
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

            while (secondary_labels.length < 2)
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
            var button = new Gtk.CheckButton ();
            select_button.bind_property ("active", button, "visible",
                                         GLib.BindingFlags.SYNC_CREATE);
            hbox.pack_end (button, false, false, 0);
            return hbox;
        }

        void clear_matches () {
            this._store.remove_all ();
            list_box_adjust_scrolling (list_box);
        }

        void start_spinner () {
            this._spinner_timeout_id = GLib.Timeout.add (500, () => {
                    this.stack.visible_child_name = "loading";
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
                this.stack.visible_child_name = "listing";
            else
                this.stack.visible_child_name = "default";
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
        void on_selection_mode_toggled (Gtk.ToggleButton button) {
            var context = this.get_header_bar ().get_style_context ();
            if (button.active)
                context.add_class ("selection-mode");
            else
                context.remove_class ("selection-mode");
        }

        public override void response (int res) {
            if (res == GpgFetcherResponse.IMPORT) {
                GpgItem[] items = {};
                for (var i = 0; i < this._store.get_n_items (); i++) {
                    var selected = false;
                    var row = list_box.get_row_at_index (i);
                    var box = (Gtk.Box) row.get_child ();
                    foreach (var child in box.get_children ()) {
                        if (child is Gtk.CheckButton) {
                            selected = ((Gtk.ToggleButton) child).active;
                            break;
                        }
                    }
                    if (selected) {
                        var item = (GpgItem) this._store.get_item (i);
                        items += item;
                    }
                }
                if (items.length > 0) {
                    var window = (Gtk.Window) this.get_transient_for ();
                    collection.import_items.begin (
                        items, this._cancellable,
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

        [GtkCallback]
        void on_back_clicked (Gtk.Button button) {
        }
    }
}
