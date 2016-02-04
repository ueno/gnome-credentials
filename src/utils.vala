namespace Credentials.Utils {
    static string format_path (string path) {
        var home_dir = GLib.Environment.get_home_dir ();
        if (path.has_prefix (home_dir))
            return GLib.Path.build_filename ("~", path.substring (home_dir.length));
        return path;
    }

    static string bytes_to_string (GLib.Bytes bytes) {
        string *result = GLib.malloc0 (bytes.get_size () + 1);
        char *dest = (char *) result;
        GLib.Memory.copy (dest, bytes.get_data (), bytes.get_size ());
        dest += bytes.get_size ();
        *dest = '\0';

        return (owned) result;
    }

    static string escape_invalid_chars (string s) {
        var buffer = new GLib.StringBuilder ();
        char *start = (char *) s;
        while (true) {
            char *end;
            if (((string) start).validate (-1, out end)) {
                buffer.append ((string) start);
                break;
            } else {
                buffer.append_len ((string) start, (ssize_t) (end - start));
                buffer.append_printf ("\\x%02X", *end & 0xFF);
                start = end + 1;
            }
        }
        return buffer.str;
    }

    enum DateFormat {
        REGULAR,
        FULL
    }

    // FIXME: Use GDesktopClockFormat
    enum ClockFormat {
        @24H,
        @12H
    }

    static string format_date (GLib.DateTime date,
                               DateFormat date_format)
    {
        unowned string format;

        if (date_format != DateFormat.FULL) {
            var now = new GLib.DateTime.now_local ();
            var days_ago = now.difference (date) / (24 * 60 * 60 * 1000 * 1000L);
            var settings = new GLib.Settings ("org.gnome.desktop.interface");
            var use_24 = settings.get_enum ("clock-format") == ClockFormat.24H;

            // Show only the time if date is on today
            if (days_ago < 1) {
                if (use_24) {
                    /* Translators: Time in 24h format */
                    format = N_("%H:%M");
                } else {
                    /* Translators: Time in 12h format */
                    format = N_("%l:%M %p");
                }
            }
            // Show the word "Yesterday" and time if date is on yesterday
            else if (days_ago < 2) {
                if (date_format == DateFormat.REGULAR) {
                    // xgettext:no-c-format
                    format = N_("Yesterday");
                } else {
                    if (use_24) {
                        /* Translators: this is the word Yesterday followed by
                         * a time in 24h format. i.e. "Yesterday 23:04" */
                        // xgettext:no-c-format
                        format = N_("Yesterday %H:%M");
                    } else {
                        /* Translators: this is the word Yesterday followed by
                         * a time in 12h format. i.e. "Yesterday 9:04 PM" */
                        // xgettext:no-c-format
                        format = N_("Yesterday %l:%M %p");
                    }
                }
            } else if (date.get_year () == now.get_year ()) {
                if (date_format == DateFormat.REGULAR) {
                    /* Translators: this is the day of the month followed
                     * by the abbreviated month name i.e. "3 Feb" */
                    // xgettext:no-c-format
                    format = N_("%-e %b");
                } else {
                    if (use_24) {
                        /* Translators: this is the day of the month followed
                         * by the abbreviated month name followed by a time in
                         * 24h format i.e. "3 Feb 23:04" */
                        // xgettext:no-c-format
                        format = N_("%-e %b %H:%M");
                    } else {
                        /* Translators: this is the day of the month followed
                         * by the abbreviated month name followed by a time in
                         * 12h format i.e. "3 Feb 9:04" */
                        // xgettext:no-c-format
                        format = N_("%-e %b %l:%M %p");
                    }
                }
            } else {
                if (date_format == DateFormat.REGULAR) {
                    /* Translators: this is the day of the month
                     * followed by the abbreviated month name followed
                     * by the year i.e. "3 Feb 2015" */
                    // xgettext:no-c-format
                    format = N_("%-e %b %Y");
                } else {
                    if (use_24) {
                        /* Translators: this is the day number
                         * followed by the abbreviated month name
                         * followed by the year followed by a time in
                         * 24h format i.e. "3 Feb 2015 23:04" */
                        // xgettext:no-c-format
                        format = N_("%-e %b %Y %H:%M");
                    } else {
                        /* Translators: this is the day number
                         * followed by the abbreviated month name
                         * followed by the year followed by a time in
                         * 12h format i.e. "3 Feb 2015 9:04 PM" */
                        // xgettext:no-c-format
                        format = N_("%-e %b %Y %l:%M %p");
                    }
                }
            }
        } else {
            // xgettext:no-c-format
            format = N_("%c");
        }

        return date.format (format);
    }

    static void show_error (Gtk.Window transient_for, string format, ...) {
        var dialog = new Gtk.MessageDialog (transient_for,
                                            Gtk.DialogFlags.MODAL,
                                            Gtk.MessageType.ERROR,
                                            Gtk.ButtonsType.CLOSE,
                                            "%s",
                                            format.vprintf (va_list ()));
        dialog.response.connect ((res) => { dialog.destroy (); });
        dialog.show ();
    }

    static void show_notification (Gtk.Window window, string format, ...) {
        var notification = new Gd.Notification ();
        var grid = new Gtk.Grid ();
        grid.valign = Gtk.Align.CENTER;
        notification.add (grid);
        var label = new Gtk.Label (format.vprintf (va_list ()));
        label.valign = Gtk.Align.CENTER;
        grid.add (label);
        notification.show_all ();
        notification.timeout = 5;
        ((Window) window).add_notification (notification);
    }

    static void grid_bind_row_property (GLib.Object source_object,
                                        string source_property,
                                        Gtk.Grid grid,
                                        int row,
                                        string target_property,
                                        GLib.BindingFlags flags,
                                        owned GLib.BindingTransformFunc? transform = null)
    {
        for (var column = 0; ; column++) {
            var widget = grid.get_child_at (column, row);
            if (widget == null)
                break;
            source_object.bind_property (source_property,
                                         widget, target_property,
                                         flags,
                                         (owned) transform);
        }
    }

    static bool transform_is_non_empty_string (GLib.Binding binding,
                                               GLib.Value source_value,
                                               ref GLib.Value target_value)
    {
        var s = source_value.get_string ();
        target_value.set_boolean (s != "");
        return true;
    }

    static string format_domain (string domain) {
        var soup_uri = new Soup.URI (domain);
        if (soup_uri == null)
            return domain;
        var host = soup_uri.get_host ();

        try {
            return Soup.tld_get_base_domain (host);
        } catch (Error e) {
            return host;
        }
    }
}
