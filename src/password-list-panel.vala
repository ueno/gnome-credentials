namespace Credentials {
    class PasswordListPanel : ListPanel {
        SecretBackend _backend;
        ulong _notify_has_locked_id = 0;
        ulong _unlock_button_clicked_id = 0;

        construct {
            this._backend = new SecretBackend ("Secret");
            this._notify_has_locked_id = this._backend.notify["has-locked"].connect (on_notify_has_locked);

            register_backend (this._backend, new SecretViewAdapter ());
            map.connect (on_map);
        }

        void on_notify_has_locked (GLib.ParamSpec pspec) {
            if (this._notify_has_locked_id > 0)
                this._backend.disconnect (this._notify_has_locked_id);
            try_unlock_collections ();
        }

        void try_unlock_collections () {
            Window toplevel = (Window) this.get_toplevel ();
            var collections = this._backend.get_collections ();
            foreach (var collection in collections) {
                if (collection.locked) {
                    var dialog = new Gtk.MessageDialog (
                        toplevel,
                        Gtk.DialogFlags.MODAL,
                        Gtk.MessageType.QUESTION,
                        Gtk.ButtonsType.OK_CANCEL,
                        _("\"%s\" is locked.  Unlock? "),
                        collection.name);
                    dialog.response.connect ((res) => {
                            if (res == Gtk.ResponseType.OK)
                                collection.unlock.begin (null);
                            dialog.destroy ();
                        });
                    dialog.show ();
                }
            }
        }

        void on_map () {
            Window toplevel = (Window) this.get_toplevel ();
            toplevel.generators_menu_button.hide ();
            toplevel.selection_mode_enable_button.hide ();

            this._backend.bind_property ("has-locked",
                                         toplevel.unlock_button, "visible",
                                         GLib.BindingFlags.DEFAULT |
                                         GLib.BindingFlags.SYNC_CREATE);

            if (this._unlock_button_clicked_id == 0)
                this._unlock_button_clicked_id = toplevel.unlock_button.clicked.connect (try_unlock_collections);
        }
    }
}
