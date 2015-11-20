class Credentials.Application : Gtk.Application
{
    public Application () {
        Object (application_id: Config.PACKAGE_DESKTOP_NAME);
    }

    construct {
        GLib.Environment.set_application_name (_("Credentials"));
    }

    public override void startup () {
        base.startup ();

        var provider = new Gtk.CssProvider ();
        try {
            provider.load_from_file (
                GLib.File.new_for_uri (
                    "resource:///org/gnome/Credentials/application.css"));
            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            warning ("cannot load CSS: %s", e.message);
        }

        var action = new GLib.SimpleAction ("quit", null);
        action.activate.connect (() => { this.quit (); });
        add_action (action);

        var builder = new Gtk.Builder.from_resource (
            "/org/gnome/Credentials/app-menu.ui");
        var menu = (GLib.MenuModel) builder.get_object ("app-menu");
        this.set_app_menu (menu);
    }

    public override void activate () {
        (new Credentials.Window (this)).show ();
    }

    public override void shutdown () {
        base.shutdown ();
    }
}

public int main (string[] args) {
    GCrypt.check_version (GCrypt.VERSION);
    GCrypt.control (GCrypt.ControlCommand.DISABLE_SECMEM, 0);
    GCrypt.control (GCrypt.ControlCommand.INITIALIZATION_FINISHED, 0);

    GGpg.check_version (null);

    // The type "CredentialsModelButton" is referred to from a
    // GtkBuilder file.
    typeof (Credentials.ModelButton).class_ref ();

    return (new Credentials.Application ()).run (args);
}
