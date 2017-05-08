namespace Credentials {
    class PasswordListPanel : ListPanel {
        SecretBackend _backend;

        construct {
            this._backend = new SecretBackend ("Secret");

            register_backend (this._backend, new SecretViewAdapter ());
            map.connect (on_map);
        }

        void on_map () {
            Window toplevel = (Window) this.get_toplevel ();
            toplevel.add_button.show ();
            toplevel.generators_menu_button.hide ();
            toplevel.selection_mode_enable_button.hide ();

            this._backend.bind_property ("has-locked",
                                         toplevel.unlock_button, "visible",
                                         GLib.BindingFlags.DEFAULT |
                                         GLib.BindingFlags.SYNC_CREATE);
        }
    }
}
