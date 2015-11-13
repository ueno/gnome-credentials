namespace Credentials {
    class KeyListPanel : ListPanel {
        Gtk.Popover _generator_popover;
        GLib.SimpleActionGroup _generator_action_group;

        construct {
            this._generator_action_group = new GLib.SimpleActionGroup ();
            this._generator_popover = new Gtk.Popover (null);
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
            box.margin = 10;
            box.show ();
            this._generator_popover.add (box);

            register_backend (new GpgBackend ("Gpg"), new GpgWidgetFactory ());
            register_backend (new SshBackend ("Ssh"), new SshWidgetFactory ());

            map.connect (on_map);
        }

        void on_map () {
            Window toplevel = (Window) this.get_toplevel ();
            toplevel.unlock_button.set_visible (false);
            toplevel.new_button.set_visible (true);
            toplevel.new_button.set_popover (this._generator_popover);
            toplevel.new_button.insert_action_group (
                "generator", this._generator_action_group);
        }

        protected override void register_backend (Backend backend,
                                                  WidgetFactory factory)
        {
            base.register_backend (backend, factory);
            backend.collection_added.connect ((collection) => {
                    register_generator ((GenerativeCollection) collection,
                                        (GenerativeWidgetFactory) factory);
                });
        }

        void register_generator (GenerativeCollection collection,
                                 GenerativeWidgetFactory factory)
        {
            var action = new GLib.SimpleAction (collection.name, null);
            action.activate.connect (() => {
                    activate_generate (collection, factory);
                });
            this._generator_action_group.add_action (action);
            var widget = factory.create_generator_menu_button (collection);
            var button = new Gtk.ModelButton ();
            button.action_name = "generator.%s".printf (collection.name);
            button.get_child ().destroy ();
            button.add (widget);
            button.show_all ();
            var box = (Gtk.Box) this._generator_popover.get_child ();
            box.add (button);
        }

        void activate_generate (GenerativeCollection collection,
                                GenerativeWidgetFactory factory)
        {
            var dialog = factory.create_generator_dialog (collection);
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.set_transient_for ((Gtk.Window) this.get_toplevel ());
            dialog.show ();
        }
    }
}
