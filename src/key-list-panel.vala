namespace Credentials {
    class KeyListPanel : ListPanel {
        Gtk.Popover _generators_popover;
        GLib.SimpleActionGroup _generator_actions;

        Gtk.Popover _tools_popover;
        GLib.SimpleActionGroup _tool_actions;

        construct {
            var builder = new Gtk.Builder.from_resource (
                "/org/gnome/Credentials/menu.ui");
            this._generators_popover =
                (Gtk.Popover) builder.get_object ("generators-popover");
            this._generator_actions = new GLib.SimpleActionGroup ();
            this._generators_popover.insert_action_group (
                "generator", this._generator_actions);

            this._tools_popover =
                (Gtk.Popover) builder.get_object ("tools-popover");
            this._tool_actions = new GLib.SimpleActionGroup ();
            this._tools_popover.insert_action_group (
                "tool", this._tool_actions);

            register_backend (new GpgBackend ("Gpg"), new GpgWidgetFactory ());
            register_backend (new SshBackend ("Ssh"), new SshWidgetFactory ());

            map.connect (on_map);
        }

        void on_map () {
            Window toplevel = (Window) this.get_toplevel ();
            toplevel.unlock_button.set_visible (false);
            toplevel.generators_menu_button.set_visible (true);
            toplevel.generators_menu_button.set_popover (this._generators_popover);
            toplevel.tools_menu_button.set_visible (false);
            toplevel.tools_menu_button.set_popover (this._tools_popover);
        }

        protected override void register_backend (Backend backend,
                                                  WidgetFactory factory)
        {
            base.register_backend (backend, factory);
            backend.collection_added.connect ((collection) => {
                    ((GenerativeWidgetFactory) factory).register_generator_actions (
                        this,
                        this._generator_actions,
                        (GenerativeCollection) collection);
                    factory.register_tool_actions (this,
                                                   this._tool_actions,
                                                   collection);
                });
        }
    }
}
