namespace Credentials {
    class KeyListPanel : ListPanel {
        Gtk.Popover _generator_popover;
        GLib.SimpleActionGroup _generator_action_group;

        construct {
            // The type "CredentialsModelButton" is referred to from
            // the GtkBuilder file.
            typeof (ModelButton).class_ref ();
            var builder = new Gtk.Builder.from_resource (
                "/org/gnome/Credentials/key-generator-menu.ui");
            this._generator_popover =
                (Gtk.Popover) builder.get_object ("generator-popover");

            this._generator_action_group = new GLib.SimpleActionGroup ();
            this._generator_popover.insert_action_group (
                "generator", this._generator_action_group);

            register_backend (new GpgBackend ("Gpg"), new GpgWidgetFactory ());
            register_backend (new SshBackend ("Ssh"), new SshWidgetFactory ());

            map.connect (on_map);
        }

        void on_map () {
            Window toplevel = (Window) this.get_toplevel ();
            toplevel.unlock_button.set_visible (false);
            toplevel.new_button.set_visible (true);
            toplevel.new_button.set_popover (this._generator_popover);
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
                    show_generator_dialog (collection, factory);
                });
            this._generator_action_group.add_action (action);
        }

        void show_generator_dialog (GenerativeCollection collection,
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
