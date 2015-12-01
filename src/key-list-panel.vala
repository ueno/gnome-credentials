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

            register_backend (new GpgBackend ("Gpg"), new GpgViewAdapter ());
            register_backend (new SshBackend ("Ssh"), new SshViewAdapter ());

            map.connect (on_map);
        }

        void on_map () {
            Window toplevel = (Window) this.get_toplevel ();
            toplevel.unlock_button.set_visible (false);
            toplevel.generators_menu_button.set_visible (true);
            toplevel.generators_menu_button.set_popover (this._generators_popover);
            toplevel.tools_menu_button.set_visible (true);
            toplevel.tools_menu_button.set_popover (this._tools_popover);
        }

        public override void register_tool_action (GLib.SimpleAction action) {
            this._tool_actions.add_action (action);
        }

        public virtual void register_generator_action (Collection collection) {
            var action = new GLib.SimpleAction (collection.name, null);
            action.activate.connect (() => {
                    show_generator_dialog (collection);
                });
            this._generator_actions.add_action (action);
        }

        void show_generator_dialog (Collection collection) {
            var adapter = get_view_adapter (collection.backend);
            var dialog = adapter.create_generator_dialog (collection);
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.set_transient_for ((Gtk.Window) this.get_toplevel ());
            dialog.show ();
        }
    }
}
