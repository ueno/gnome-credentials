namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/main.ui")]
    class Window : Gtk.ApplicationWindow {
        [GtkChild]
        Gtk.Overlay overlay;

        [GtkChild]
        Gtk.Grid main_grid;

        [GtkChild]
        Gtk.HeaderBar main_header_bar;

        [GtkChild]
        Gtk.SearchBar main_search_bar;

        [GtkChild]
        Gtk.SearchEntry main_search_entry;

        [GtkChild]
        public Gtk.Button unlock_button;

        [GtkChild]
        public Gtk.MenuButton new_button;

        [GtkChild]
        public Gtk.MenuButton menu_button;

        [GtkChild]
        Gtk.ToggleButton search_active_button;

        public bool search_active { get; set; default = false; }

        ContentArea _area;
        GLib.Cancellable _cancellable;

        public Window (Gtk.Application app) {
            Object (application: app,
                    title: GLib.Environment.get_application_name (),
                    default_width: 640,
                    default_height: 480);
        }

        construct {
            var action = new GLib.SimpleAction ("about", null);
            action.activate.connect (() => { this.activate_about (); });
            add_action (action);

            this.bind_property ("search-active",
                                this.search_active_button, "active",
                                GLib.BindingFlags.SYNC_CREATE |
                                GLib.BindingFlags.BIDIRECTIONAL);
            this.bind_property ("search-active",
                                this.main_search_bar, "search-mode-enabled",
                                GLib.BindingFlags.SYNC_CREATE |
                                GLib.BindingFlags.BIDIRECTIONAL);
            this.main_search_bar.connect_entry (this.main_search_entry);

            this._area = new Credentials.ContentArea ();

            var swicher = new Gtk.StackSwitcher ();
            swicher.set_stack (this._area);
            swicher.show ();
            main_header_bar.set_custom_title (swicher);

            this.main_grid.add (this._area);
            this.main_grid.show_all ();

            key_press_event.connect ((ev) => {
                    return this.main_search_bar.handle_event (ev);
                });

            this._cancellable = new GLib.Cancellable ();
        }

        void activate_about () {
            string[] authors = {
                "Daiki Ueno <dueno@src.gnome.org>"
            };
            string[] artists = {
                "Allan Day <allanpday@gmail.com>"
            };

            var dialog = new Gtk.AboutDialog ();
            dialog.set_authors (authors);
            dialog.set_artists (artists);
            // TRANSLATORS: put your names here, one name per line.
            dialog.set_translator_credits (_("translator-credits"));
            dialog.set_program_name (_("Credentials"));
            dialog.set_copyright ("Copyright 2015 Daiki Ueno");
            dialog.set_license_type (Gtk.License.GPL_2_0);
            dialog.set_logo_icon_name (Config.PACKAGE_DESKTOP_NAME);
            dialog.set_version (Config.PACKAGE_VERSION);
            dialog.set_wrap_license (true);

            dialog.set_modal (true);
            dialog.set_transient_for (this);

            dialog.show ();
            dialog.response.connect (() => { dialog.destroy (); });
        }

        [GtkCallback]
        void on_search_changed (Gtk.SearchEntry entry) {
            var text = entry.get_text ().strip();

            this._cancellable.reset ();
            if (text.length > 0)
                this._area.filter_items.begin (text.split_set (" \t", -1),
                                               this._cancellable);
            else
                this._cancellable.cancel ();
        }

        public void add_notification (Gtk.Widget notification) {
            overlay.add_overlay (notification);
        }
    }

    class ContentArea : Gtk.Stack {
        GLib.Settings _settings;

        public ContentArea () {
            Object (hexpand: true, vexpand: true);
        }

        construct {
            this._settings = new GLib.Settings (Config.PACKAGE_DESKTOP_NAME);

            var passwords_panel = new Credentials.PasswordListPanel ();
            this.add_titled (passwords_panel, "passwords", _("Passwords"));

            var keys_panel = new Credentials.KeyListPanel ();
            this.add_titled (keys_panel, "keys", _("Keys"));
        }

        public async void filter_items (string[] words,
                                        GLib.Cancellable cancellable)
        {
            var panel = (ListPanel) this.visible_child;
            yield panel.filter_items (words, cancellable);
        }
    }
}
