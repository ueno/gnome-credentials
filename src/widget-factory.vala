namespace Credentials {
    abstract class WidgetFactory : GLib.Object {
        public Backend backend { construct set; get; }
        public abstract Gtk.Widget create_list_box_row (Item item);
        public abstract EditorDialog create_editor_dialog (Item item);
        public virtual signal void attached (ListPanel panel) {
        }
   }

    abstract class GenerativeWidgetFactory : WidgetFactory {
        public abstract GeneratorDialog create_generator_dialog (GenerativeCollection collection);

        public void show_generator_dialog (Gtk.Window transient_for,
                                           GenerativeCollection collection)
        {
            var dialog = create_generator_dialog (collection);
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.set_transient_for (transient_for);
            dialog.show ();
        }
    }
}
