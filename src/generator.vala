namespace Credentials {
    abstract class GeneratorDialog : Gtk.Dialog {
        public GenerativeCollection collection { construct set; get; }

        public abstract GeneratedItemParameters build_parameters ();

        public override void response (int res) {
            if (res == Gtk.ResponseType.OK) {
                var window = (Gtk.Window) this.get_transient_for ();

                var parameters = build_parameters ();
                collection.generate_item.begin (
                    parameters, null,
                    (obj, res) => {
                        try {
                            collection.generate_item.end (res);
                            show_notification (window,
                                               _("%s generated"),
                                               collection.item_type);
                        } catch (GLib.Error e) {
                            show_error (window,
                                        "Couldn't generate item: %s",
                                        e.message);
                        }
                    });
            }
        }
    }
}
