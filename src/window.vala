namespace Credentials {
    [GtkTemplate (ui = "/org/gnome/Credentials/window.ui")]
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
        public Gtk.MenuButton generators_menu_button;

        [GtkChild]
        public Gtk.ToggleButton selection_mode_toggle_button;

        [GtkChild]
        public Gtk.Revealer selection_bar;

        [GtkChild]
        Gtk.ToggleButton search_active_button;

        public bool search_active { get; set; default = false; }

        Gtk.StackSwitcher _switcher;
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
            action.activate.connect (() => { activate_about (); });
            add_action (action);

            bind_property ("search-active",
                           search_active_button, "active",
                           GLib.BindingFlags.SYNC_CREATE |
                           GLib.BindingFlags.BIDIRECTIONAL);
            bind_property ("search-active",
                           main_search_bar, "search-mode-enabled",
                           GLib.BindingFlags.SYNC_CREATE |
                           GLib.BindingFlags.BIDIRECTIONAL);
            main_search_bar.connect_entry (main_search_entry);

            this._area = new Credentials.ContentArea ();
            this._area.bind_property ("selection-mode",
                                      generators_menu_button, "visible",
                                      GLib.BindingFlags.SYNC_CREATE |
                                      GLib.BindingFlags.INVERT_BOOLEAN);
            this._area.bind_property ("selection-mode",
                                      search_active_button, "visible",
                                      GLib.BindingFlags.SYNC_CREATE |
                                      GLib.BindingFlags.INVERT_BOOLEAN);
            this._area.notify["selection-mode"].connect ((s, p) => {
                    var context = main_header_bar.get_style_context ();
                    if (this._area.selection_mode) {
                        context.add_class ("selection-mode");
                        main_header_bar.set_custom_title (null);
                        main_header_bar.set_title (_("Selection"));
                    } else {
                        context.remove_class ("selection-mode");
                        main_header_bar.set_custom_title (this._switcher);
                    }
                });

            selection_mode_toggle_button.bind_property ("active",
                                                        this._area, "selection-mode",
                                                        GLib.BindingFlags.SYNC_CREATE);
            this._switcher = new Gtk.StackSwitcher ();
            this._switcher.set_stack (this._area);
            this._switcher.show ();
            main_header_bar.set_custom_title (this._switcher);

            main_grid.attach (this._area, 0, 1, 1, 1);
            main_grid.show_all ();

            key_press_event.connect ((ev) => {
                    return main_search_bar.handle_event (ev);
                });

            this._cancellable = new GLib.Cancellable ();

            this._area.notify["visible-child"].connect (() => {
                    this._cancellable.cancel ();
                    search_active = false;
                });
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
            this._cancellable.cancel ();
            this._cancellable.reset ();

            var text = entry.get_text ().strip();
            if (text.length == 0)
                return;

            this._area.filter_items.begin (text.split_set (" \t", -1),
                                           this._cancellable);
        }

        public void add_notification (Gtk.Widget notification) {
            overlay.add_overlay (notification);
        }
    }

    class ContentArea : Gtk.Stack {
        GLib.Settings _settings;

        public bool selection_mode { construct set; get; default = false; }

        public ContentArea () {
            Object (hexpand: true, vexpand: true);
        }

        construct {
            this._settings = new GLib.Settings (Config.PACKAGE_DESKTOP_NAME);

            var passwords_panel = new Credentials.PasswordListPanel ();
            bind_property ("selection-mode",
                           passwords_panel, "selection-mode",
                           GLib.BindingFlags.SYNC_CREATE);
            add_titled (passwords_panel, "passwords", _("Passwords"));

            var keys_panel = new Credentials.KeyListPanel ();
            bind_property ("selection-mode",
                           keys_panel, "selection-mode",
                           GLib.BindingFlags.SYNC_CREATE);
            add_titled (keys_panel, "keys", _("Keys"));
        }

        public async void filter_items (string[] words,
                                        GLib.Cancellable cancellable)
        {
            var panel = (ListPanel) visible_child;
            yield panel.filter_items (words, cancellable);
        }
    }
}
