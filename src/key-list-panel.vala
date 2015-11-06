namespace Credentials {
    class KeyListPanel : ListPanel {
        GLib.Menu _generator_menu;
        Gtk.Popover _generator_popover;
        GLib.SimpleActionGroup _generator_action_group;

        construct {
            this._generator_action_group = new GLib.SimpleActionGroup ();
            this._generator_menu = new GLib.Menu ();
            this._generator_popover = new Gtk.Popover (null);
            this._generator_popover.bind_model (this._generator_menu,
                                                "generator");

            Backend backend = new GpgBackend ("Gpg");
            WidgetFactory factory = new GpgWidgetFactory ();
            register_backend (backend, factory);

            backend.collection_added.connect ((_collection) => {
                    var collection = (GpgCollection) _collection;
                    if (collection.protocol == GGpg.Protocol.OPENPGP) {
                        var action = new GLib.SimpleAction ("openpgp", null);
                        action.activate.connect (() => {
                                activate_generate_openpgp (collection);
                            });
                        this._generator_action_group.add_action (action);
                    }
                });

            var item = new GLib.MenuItem (_("Generate PGP Key"), "openpgp");
            this._generator_menu.append_item (item);

            backend = new SshBackend ("Ssh");
            factory = new SshWidgetFactory ();
            register_backend (backend, factory);

            backend.collection_added.connect ((collection) => {
                    var action = new GLib.SimpleAction ("ssh", null);
                    action.activate.connect (() => {
                            activate_generate_ssh ((SshCollection) collection);
                        });
                    this._generator_action_group.add_action (action);
                });

            item = new GLib.MenuItem (_("Generate SSH Key"), "ssh");
            this._generator_menu.append_item (item);

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

        void activate_generate_openpgp (GpgCollection collection) {
            var dialog = new GpgGeneratorDialog (collection);
            return_if_fail (dialog != null);
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.set_transient_for ((Gtk.Window) this.get_toplevel ());
            dialog.show ();
        }

        void activate_generate_ssh (SshCollection collection) {
            var dialog = new SshGeneratorDialog (collection);
            return_if_fail (dialog != null);
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.set_transient_for ((Gtk.Window) this.get_toplevel ());
            dialog.show ();
        }
    }
}
