namespace Credentials {
    class KeyListPanel : ListPanel {
        construct {
            var backend = new GpgBackend ("Gpg");
            var factory = new GpgWidgetFactory ();
            register_backend (backend, factory);

            map.connect (on_map);
        }

        void on_map () {
            Window toplevel = (Window) this.get_toplevel ();
            toplevel.unlock_button.set_visible (false);
            toplevel.menu_button.set_visible (true);
            toplevel.new_button.set_visible (true);
        }
    }
}
