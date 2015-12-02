namespace Credentials {
    const uint MAX_ROWS_VISIBLE = 10;

    static void list_box_update_header_func (Gtk.ListBoxRow row,
                                             Gtk.ListBoxRow? before)
    {
        if (before != null && row.get_header () == null) {
            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            row.set_header (separator);
        }
    }

    static void list_box_adjust_scrolling (Gtk.ListBox list_box,
                                           bool resize = true) {
        var scrolled_window =
            list_box.get_data<Gtk.ScrolledWindow> (
                "credentials-scrolling-scrolled-window");
        if (scrolled_window == null)
            return;
        var children = list_box.get_children ();
        var n_rows = children.length ();
        var num_max_rows =
            list_box.get_data<uint> ("credentials-max-rows-visible");
        if (n_rows >= num_max_rows) {
            var total_row_height = 0;
            var i = 0;
            foreach (var child in children) {
                if (i++ >= num_max_rows)
                    break;
                int row_height;
                child.get_preferred_height (out row_height, null);
                total_row_height += row_height;
            }
            scrolled_window.set_min_content_height (resize ? total_row_height : -1);
            scrolled_window.set_policy (Gtk.PolicyType.NEVER,
                                        Gtk.PolicyType.AUTOMATIC);
        } else {
            scrolled_window.set_min_content_height (-1);
            scrolled_window.set_policy (Gtk.PolicyType.NEVER,
                                        Gtk.PolicyType.NEVER);
        }
    }

    static void list_box_setup_scrolling (Gtk.ListBox list_box,
                                          uint num_max_rows,
                                          owned Gtk.ScrolledWindow? scrolled_window = null)
    {
        var parent = list_box.get_parent ();
        if (scrolled_window == null) {
            scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.show ();

            parent.remove (list_box);
            scrolled_window.add (list_box);
            parent.add (scrolled_window);
        }

        if (num_max_rows == 0)
            num_max_rows = MAX_ROWS_VISIBLE;

        list_box.set_data ("credentials-scrolling-scrolled-window",
                           scrolled_window);
        list_box.set_data ("credentials-max-rows-visible",
                           num_max_rows);
    }
}
