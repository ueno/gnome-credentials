namespace Credentials {
    class KeyListPanel : ListPanel {
        Gtk.Popover _generators_popover;

        construct {
            var builder = new Gtk.Builder.from_resource (
                "/org/gnome/Credentials/menu.ui");
            this._generators_popover =
                (Gtk.Popover) builder.get_object ("generators-popover");

            register_backend (new GpgBackend ("Gpg"), new GpgViewAdapter ());
            register_backend (new SshBackend ("Ssh"), new SshViewAdapter ());

            map.connect (on_map);
        }

        void on_map () {
            Window toplevel = (Window) this.get_toplevel ();
            toplevel.unlock_button.set_visible (false);
            toplevel.generators_menu_button.show ();
            toplevel.generators_menu_button.set_popover (this._generators_popover);
            toplevel.selection_mode_enable_button.show ();
        }
    }
}
