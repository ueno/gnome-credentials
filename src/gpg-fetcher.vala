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

        GLib.ListStore _store;
        GLib.Cancellable _cancellable;

        public GpgCollection collection { construct set; get; }

        public GpgFetcherDialog (GpgCollection collection) {
            Object (collection: collection, use_header_bar: 1);
        }

        construct {
            this._store = new GLib.ListStore (typeof (GGpg.Key));
            list_box.bind_model (this._store, create_key_widget);
            list_box.set_header_func (list_box_update_header_func);
            list_box_setup_scrolling (list_box, 4);
            this._cancellable = new GLib.Cancellable ();
            this._cancellable.connect (clear_matches);
        }

        Gtk.Widget create_key_widget (GLib.Object object) {
            var key = (GGpg.Key) object;
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
            box.margin_start = 12;
            box.margin_end = 12;
            box.margin_top = 3;
            box.margin_bottom = 3;
            GLib.List<GGpg.UserId> uids = key.get_uids ();
            string[] secondary_labels = {};
            string primary_label = "";
            string primary_name = "";
            if (uids != null) {
                GGpg.UserId uid = uids.first ().data;
                primary_name = uid.name;
                if (!primary_name.validate (-1)) {
                    warning ("invalid byte sequence: %s", primary_name);
                    primary_name = "";
                }
                if (primary_name != "") {
                    primary_label = primary_name;
                    if (uid.email != "")
                        secondary_labels += uid.email;
                } else
                    primary_label = uid.email;

                var count = 0;
                foreach (var uid2 in uids.next) {
                    string secondary_label = "";
                    var secondary_name = uid2.name;
                    if (!secondary_name.validate (-1)) {
                        warning ("invalid byte sequence: %s", secondary_name);
                        secondary_name = "";
                    }
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
                primary_label = _("unknown user ID");

            var label = new Gtk.Label (primary_label);
            label.halign = Gtk.Align.START;
            label.ellipsize = Pango.EllipsizeMode.END;
            label.show ();
            box.pack_start (label, false, false, 0);

            foreach (var secondary_label in secondary_labels) {
                label = new Gtk.Label (secondary_label);
                var context = label.get_style_context ();
                context.add_class ("secondary-label");
                context.add_class ("dim-label");
                label.halign = Gtk.Align.START;
                label.ellipsize = Pango.EllipsizeMode.END;
                label.show ();
                box.pack_start (label, false, false, 0);
            }

            box.set_data ("credentials-list-box-row-object", object);
            return box;
        }

        void clear_matches () {
            this._store.remove_all ();
            list_box_adjust_scrolling (list_box);
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
            ctx.keylist.begin (
                text, false,
                (key) => {
                    var context = GLib.MainContext.default ();
                    context.invoke (() => {
                            this._store.append (key);
                            list_box_adjust_scrolling (list_box);
                            return GLib.Source.REMOVE;
                        });
                },
                this._cancellable);
        }

        [GtkCallback]
        void on_selected_rows_changed (Gtk.ListBox list_box) {
            var rows = list_box.get_selected_rows ();
            import_button.visible = rows != null;
        }
    }
}
