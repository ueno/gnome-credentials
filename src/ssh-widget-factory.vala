namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/ssh-editor.ui")]
    class SshEditorDialog : Gtk.Dialog {
        [GtkChild]
        Gtk.Grid properties_grid;

        public SshItem item { construct set; get; }

        Gtk.Entry _comment_entry;
        uint _set_comment_idle_handler = 0;

        public SshEditorDialog (SshItem item) {
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

        void set_comment_in_idle () {
            if (this._set_comment_idle_handler > 0) {
                GLib.Source.remove (this._set_comment_idle_handler);
                this._set_comment_idle_handler = 0;
            }

            this._set_comment_idle_handler = GLib.Idle.add (() => {
                    var window = (Gtk.Window) this.get_toplevel ();
                    item.set_comment.begin (
                        this._comment_entry.get_text (),
                        (obj, res) => {
                            try {
                                item.set_comment.end (res);
                            } catch (GLib.Error e) {
                                show_error (window,
                                            _("Couldn't write comment: %s"),
                                            e.message);
                            }
                        });
                    this._set_comment_idle_handler = 0;
                    return GLib.Source.REMOVE;
                });
        }

        construct {
            var row_index = 0;
            var label = create_name_label (_("Name"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            this._comment_entry = new Gtk.Entry ();
            this._comment_entry.set_text (item.get_comment ());
            this._comment_entry.notify["text"].connect (set_comment_in_idle);
            properties_grid.attach (this._comment_entry, 1, row_index, 1, 1);
            row_index++;

            var key_type = item.get_key_type ();
            label = create_name_label (_("Algorithm"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (SshUtils.format_key_type (key_type));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            var key_size = item.get_key_size ();
            label = create_name_label (_("Strength"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (key_size == 0 ? _("Unknown") : _("%u bits").printf (key_size));
            properties_grid.attach (label, 1, row_index, 1, 1);
            row_index++;

            label = create_name_label (_("Location"));
            properties_grid.attach (label, 0, row_index, 1, 1);
            label = create_value_label (format_path (item.get_path ()));
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

    class SshWidgetFactory : WidgetFactory {
        public override Gtk.Widget create_list_box_row (Item _item) {
            var item = (SshItem) _item;
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);

            var heading_label = new Gtk.Label (item.get_label ());
            var context = heading_label.get_style_context ();
            context.add_class ("key-list-heading");
            heading_label.xalign = 0;
            heading_label.set_ellipsize (Pango.EllipsizeMode.END);
            box.pack_start (heading_label, false, false, 0);

            var name_label = new Gtk.Label (item.collection.item_type);
            context = name_label.get_style_context ();
            context.add_class ("key-list-type");
            context.add_class ("dim-label");
            box.pack_end (name_label, false, false, 0);
            box.show_all ();
            return box;
        }

        public override Gtk.Dialog create_editor_dialog (Item item) {
            return new SshEditorDialog ((SshItem) item);
        }
    }
}
