namespace Credentials {
    enum EditorResponse {
        DONE = -5,
        DELETE = -6
    }

    abstract class EditorDialog : Gtk.Dialog {
        public Item item { construct set; get; }

        public virtual void delete_item () {
            var window = (Gtk.Window) this.get_toplevel ();
            item.delete.begin (null, (obj, res) => {
                    try {
                        item.delete.end (res);
                    } catch (GLib.Error e) {
                        show_error (window,
                                    _("Couldn't delete item: %s"),
                                    e.message);
                    }
                });
        }

        public override void response (int res) {
            if (res == EditorResponse.DELETE)
                delete_item ();
        }
    }
}
