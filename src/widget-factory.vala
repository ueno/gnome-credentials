namespace Credentials {
    abstract class WidgetFactory : GLib.Object {
        public abstract Gtk.Widget create_list_box_row (Item item);
        public abstract EditorDialog create_editor_dialog (Item item);
   }

    abstract class GenerativeWidgetFactory : WidgetFactory {
        public abstract Gtk.Widget create_generator_menu_button (GenerativeCollection collection);
        public abstract GeneratorDialog create_generator_dialog (GenerativeCollection collection);
   }
}
