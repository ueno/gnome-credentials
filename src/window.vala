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
        public Gtk.Button selection_mode_enable_button;

        [GtkChild]
        Gtk.Button selection_mode_cancel_button;

        [GtkChild]
        Gtk.Revealer selection_bar;

        [GtkChild]
        Gtk.Button selection_publish_button;

        [GtkChild]
        Gtk.Button selection_export_button;

        [GtkChild]
        Gtk.Button selection_delete_button;

        [GtkChild]
        Gtk.ToggleButton search_active_button;

        public bool search_active { get; set; default = false; }

        Gtk.StackSwitcher _switcher;
        Gtk.MenuButton _selection_menu_button;
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
                                      selection_mode_enable_button, "visible",
                                      GLib.BindingFlags.SYNC_CREATE |
                                      GLib.BindingFlags.INVERT_BOOLEAN);
            this._area.bind_property ("selection-mode",
                                      selection_mode_cancel_button, "visible",
                                      GLib.BindingFlags.SYNC_CREATE);
            this._area.bind_property ("selection-mode",
                                      selection_bar, "reveal-child",
                                      GLib.BindingFlags.SYNC_CREATE);
            this._area.bind_property ("selection-mode",
                                      generators_menu_button, "visible",
                                      GLib.BindingFlags.SYNC_CREATE |
                                      GLib.BindingFlags.INVERT_BOOLEAN);
            this._area.bind_property ("selection-mode",
                                      main_header_bar, "show-close-button",
                                      GLib.BindingFlags.SYNC_CREATE |
                                      GLib.BindingFlags.INVERT_BOOLEAN);
            this._area.bind_property ("selection-mode",
                                      search_active_button, "visible",
                                      GLib.BindingFlags.SYNC_CREATE |
                                      GLib.BindingFlags.INVERT_BOOLEAN);
            this._area.bind_property ("selection-count",
                                      selection_publish_button, "sensitive",
                                      GLib.BindingFlags.SYNC_CREATE,
                                      transform_is_greater_than_zero);
            this._area.bind_property ("selection-count",
                                      selection_export_button, "sensitive",
                                      GLib.BindingFlags.SYNC_CREATE,
                                      transform_is_greater_than_zero);
            this._area.bind_property ("selection-count",
                                      selection_delete_button, "sensitive",
                                      GLib.BindingFlags.SYNC_CREATE,
                                      transform_is_greater_than_zero);
            var builder = new Gtk.Builder.from_resource (
                "/org/gnome/Credentials/selection-menu.ui");
            var menu = (GLib.MenuModel) builder.get_object ("selection-menu");
            this._selection_menu_button = new Gtk.MenuButton ();
            this._selection_menu_button.get_style_context ().add_class ("selection-menu");
            this._selection_menu_button.set_menu_model (menu);
            this._selection_menu_button.show ();
            this._area.notify["selection-mode"].connect ((s, p) => {
                    var context = main_header_bar.get_style_context ();
                    if (this._area.selection_mode) {
                        context.add_class ("selection-mode");
                        main_header_bar.set_custom_title (this._selection_menu_button);
                    } else {
                        context.remove_class ("selection-mode");
                        main_header_bar.set_custom_title (this._switcher);
                    }
                });

            this._area.notify["selection-count"].connect ((s, p) => {
                    if (this._area.selection_mode) {
                        string label;
                        if (this._area.selection_count == 0) {
                            label = _("Click on items to select them");
                        } else {
                            label = ngettext ("%d selected",
                                              "%d selected",
                                              this._area.selection_count).printf (this._area.selection_count);
                        }
                        this._selection_menu_button.set_label (label);
                    }
                });

            selection_mode_enable_button.clicked.connect (on_selection_mode_enable_button_clicked);
            selection_mode_cancel_button.clicked.connect (on_selection_mode_cancel_button_clicked);
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

        void on_selection_mode_enable_button_clicked (Gtk.Button button) {
            this._area.selection_mode = true;
        }

        void on_selection_mode_cancel_button_clicked (Gtk.Button button) {
            this._area.selection_mode = false;
        }

        bool transform_is_greater_than_zero (GLib.Binding binding,
                                             GLib.Value source_value,
                                             ref GLib.Value target_value)
        {
            var u = source_value.get_uint ();
            target_value.set_boolean (u > 0);
            return true;
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

        [GtkCallback]
        void on_stop_search (Gtk.SearchEntry entry) {
            this._cancellable.cancel ();
        }

        public void add_notification (Gtk.Widget notification) {
            overlay.add_overlay (notification);
        }
    }

    class ContentArea : Gtk.Stack {
        GLib.Settings _settings;

        public bool selection_mode { construct set; get; default = false; }
        public uint selection_count {
            get {
                var list_panel = visible_child as ListPanel;
                if (list_panel == null)
                    return 0;
                else
                    return list_panel.get_selected_items ().length ();
            }
        }

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
            passwords_panel.selection_changed.connect (() => {
                    notify_property ("selection-count");
                });

            var keys_panel = new Credentials.KeyListPanel ();
            bind_property ("selection-mode",
                           keys_panel, "selection-mode",
                           GLib.BindingFlags.SYNC_CREATE);
            keys_panel.selection_changed.connect (() => {
                    notify_property ("selection-count");
                });
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
