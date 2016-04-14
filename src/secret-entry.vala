namespace Credentials {
    class SecretEntry : Gtk.Entry {
        construct {
            this.buffer = new Egg.SecureEntryBuffer ();
            this.icon_release.connect (on_icon_release);
            this.visibility = false;
            this.secondary_icon_name = "credentials-edit-toggle-visibility-symbolic";
            this.secondary_icon_activatable = true;
            this.secondary_icon_sensitive = true;
        }

        void on_icon_release (Gtk.EntryIconPosition icon_pos, Gdk.Event event) {
            if (icon_pos == Gtk.EntryIconPosition.SECONDARY)
                this.visibility = !this.visibility;
        }
    }
}