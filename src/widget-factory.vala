namespace Credentials {
    enum EditorResponse {
        DONE = -5,
        DELETE = -6
    }

    abstract class WidgetFactory : GLib.Object {
        public abstract Gtk.Widget create_list_box_row (Item item);
        public abstract Gtk.Dialog create_editor_dialog (Item item); 
        public abstract Gtk.Dialog create_generator_dialog ();

        public virtual string get_action_label (string action_name) {
            return_val_if_reached (null);
        }
   }
}
