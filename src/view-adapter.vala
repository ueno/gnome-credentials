namespace Credentials {
    abstract class ViewAdapter : GLib.Object {
        public abstract Gtk.Widget create_list_box_row (Item item);
        public abstract EditorDialog create_editor_dialog (Item item);
        public virtual GeneratorDialog create_generator_dialog (Collection collection) {
            return_val_if_reached (null);
        }

        public virtual signal void attached (Backend backend, ListPanel panel) {
        }
    }
}
