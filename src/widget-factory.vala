namespace Credentials {
    abstract class WidgetFactory : GLib.Object {
        public abstract Gtk.Widget create_list_box_row (Item item);
        public abstract EditorDialog create_editor_dialog (Item item);
        public virtual void register_tool_actions (Gtk.Widget widget,
                                                   GLib.ActionMap map,
                                                   Collection collection)
        {
        }
   }

    abstract class GenerativeWidgetFactory : WidgetFactory {
        public abstract GeneratorDialog create_generator_dialog (GenerativeCollection collection);

        public void register_generator_actions (Gtk.Widget widget,
                                                GLib.ActionMap map,
                                                GenerativeCollection collection)
        {
            var action = new GLib.SimpleAction (collection.name, null);
            action.activate.connect (() => {
                    show_generator_dialog (widget, collection);
                });
            map.add_action (action);
        }

        void show_generator_dialog (Gtk.Widget widget,
                                    GenerativeCollection collection)
        {
            var dialog = create_generator_dialog (collection);
            dialog.response.connect_after ((res) => {
                    dialog.destroy ();
                });
            dialog.set_transient_for ((Gtk.Window) widget.get_toplevel ());
            dialog.show ();
        }
    }
}
