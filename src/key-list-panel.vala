namespace Credentials {
    class KeyListPanel : ListPanel {
        GLib.Menu _generator_menu;
        Gtk.Popover _generator_popover;
        GLib.SimpleActionGroup _generator_action_group;

        construct {
            this._generator_action_group = new GLib.SimpleActionGroup ();

            var backend = new GpgBackend ("Gpg");
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

            var factory = new GpgWidgetFactory ();
            register_backend (backend, factory);

            this._generator_menu = new GLib.Menu ();
            var item = new GLib.MenuItem (_("Generate PGP Key"), "openpgp");
            this._generator_menu.append_item (item);
            this._generator_popover = new Gtk.Popover (null);
            this._generator_popover.bind_model (this._generator_menu,
                                                "generator");

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
    }
}
