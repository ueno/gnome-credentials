namespace Credentials {
    abstract class GeneratorDialog : Gtk.Dialog {
        public Collection collection { construct set; get; }

        public abstract GeneratedItemParameters build_parameters ();

        public virtual void generate_item () {
            var parameters = build_parameters ();
            var window = (Gtk.Window) this.get_transient_for ();
            collection.generate_item.begin (
                parameters, null,
                (obj, res) => {
                    try {
                        collection.generate_item.end (res);
                        // XXX: The notification area covers the newly
                        // added entry.  Maybe we should consider a
                        // better way to show the progress of
                        // generation.
#if false
                        Utils.show_notification (window,
                                                 _("%s generated"),
                                                 collection.item_type);
#endif
                    } catch (GLib.Error e) {
                        Utils.show_error (window,
                                          "Couldn't generate item: %s",
                                          e.message);
                    }
                });
        }

        public override void response (int res) {
            if (res == Gtk.ResponseType.OK)
                generate_item ();
        }
    }
}
