namespace Credentials {
    class KeyListPanel : ListPanel {
        GLib.MenuModel _generator_menu;

        construct {
            var menu = new GLib.Menu ();
            this._generator_menu = menu;

            var backend = new GpgBackend ("Gpg");
            var factory = new GpgWidgetFactory ();
            var index = register_backend (backend, factory);
            var item = new GLib.MenuItem (factory.get_action_label ("generate"),
                                          null);
            item.set_action_and_target ("generate", "u", index);
            menu.append_item (item);

            map.connect (on_map);
        }

        void activate_generate (GLib.SimpleAction action,
                                GLib.Variant? parameter)
        {
            var index = parameter.get_uint32 ();

            var backend = get_backend (index);
            if (backend == null)
                return;

            var factory = get_widget_factory (backend);
            var dialog = factory.create_generator_dialog ();
            return_if_fail (dialog != null);
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.set_transient_for ((Gtk.Window) this.get_toplevel ());
            dialog.show ();
        }

        static const GLib.ActionEntry[] actions = {
            { "generate", activate_generate, "u", null, null }
        };

        void on_map () {
            Window toplevel = (Window) this.get_toplevel ();
            toplevel.unlock_button.set_visible (false);
            toplevel.menu_button.set_visible (true);
            toplevel.new_button.set_visible (true);

            var group = new GLib.SimpleActionGroup ();
            ((GLib.ActionMap) group).add_action_entries (actions, this);
            toplevel.insert_action_group ("key", group);

            var generator_popover = new Gtk.Popover (null);
            generator_popover.bind_model (this._generator_menu, "key");
            toplevel.new_button.set_popover (generator_popover);
        }
    }
}
