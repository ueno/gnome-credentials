namespace Credentials {
    class GpgViewAdapter : ViewAdapter {
        public override void attached (Backend backend, ListPanel list_panel) {
            backend.collection_added.connect ((collection) => {
                    var key_list_panel = (KeyListPanel) list_panel;
                    var action = new GLib.SimpleAction ("locate", null);
                    action.activate.connect (() => {
                            show_fetcher_dialog ((Gtk.Window) list_panel.get_toplevel (),
                                                 (GpgCollection) collection);
                        });
                    key_list_panel.register_generator_action (action);

                    action = new GLib.SimpleAction ("import", null);
                    action.activate.connect (() => {
                            show_importer_dialog ((Gtk.Window) list_panel.get_toplevel (),
                                                  (GpgCollection) collection);
                        });
                    key_list_panel.register_generator_action (action);
                });
        }

        public override Gtk.Widget create_list_box_row (Item _item) {
            var item = (GpgItem) _item;
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);

            var heading = new Gtk.Label (Utils.escape_invalid_chars (item.get_label ()));
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

        public override EditorDialog create_editor_dialog (Item item) {
            return new GpgEditorDialog (item);
        }

        void show_fetcher_dialog (Gtk.Window transient_for,
                                  GpgCollection collection)
        {
            var dialog = create_fetcher_dialog (collection);
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.set_transient_for (transient_for);
            dialog.show ();
        }

        Gtk.Dialog create_fetcher_dialog (GpgCollection collection) {
            return new GpgFetcherDialog (collection);
        }

        public override GeneratorDialog create_generator_dialog (Collection collection) {
            return new GpgGeneratorDialog (collection);
        }

        void show_importer_dialog (Gtk.Window transient_for,
                                   GpgCollection collection)
        {
            var dialog = new Gtk.FileChooserDialog (
                _("Open Key File"),
                transient_for,
                Gtk.FileChooserAction.OPEN,
                _("_Cancel"),
                Gtk.ResponseType.CANCEL,
                _("_Open"),
                Gtk.ResponseType.ACCEPT);

            var filter = new Gtk.FileFilter ();
            filter.add_pattern ("*.gpg");
            filter.add_pattern ("*.asc");
            filter.set_name (_("PGP Key"));
            dialog.set_filter (filter);

            dialog.response.connect ((res) => {
                    if (res == Gtk.ResponseType.ACCEPT) {
                        var path = dialog.get_filename ();
                        var file = GLib.File.new_for_path (path);

                        try {
                            uint8[] contents;
                            string etag;
                            file.load_contents (null, out contents, out etag);
                            var bytes = new GLib.Bytes (contents);
                            collection.import_from_bytes.begin (
                                bytes, null,
                                (obj, res) => {
                                    try {
                                        var result = collection.import_from_bytes.end (res);
                                        Utils.show_notification (
                                            transient_for,
                                            _("%d keys imported (%d new, %d unchanged)"),
                                            result.considered,
                                            result.imported,
                                            result.unchanged);
                                    } catch (GLib.Error e) {
                                        Utils.show_error (
                                            transient_for,
                                            _("Couldn't import keys: %s"),
                                            e.message);
                                    }
                                });
                        } catch (GLib.Error e) {
                            Utils.show_error (transient_for,
                                              _("Couldn't read file %s: %s"),
                                              path, e.message);
                        }
                    }
                    dialog.destroy ();
                });
            dialog.show ();
        }
    }
}
