namespace Credentials {
    class ModelButton : Gtk.Button {
        public string primary_text { construct set; get; }
        public string secondary_text { construct set; get; }

        public ModelButton (string primary_text, string secondary_text) {
            Object (primary_text: primary_text, secondary_text: secondary_text);
        }

        construct {
            this.set_relief (Gtk.ReliefStyle.NONE);
            var context = this.get_style_context ();
            context.add_class ("menuitem");

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            box.margin_start = 12;
            box.margin_end = 12;
            box.margin_top = 3;
            box.margin_bottom = 3;
            box.halign = Gtk.Align.FILL;
            this.add (box);

            var primary_label = new Gtk.Label (primary_text);
            primary_label.halign = Gtk.Align.START;
            context = primary_label.get_style_context ();
            context.add_class ("primary-label");
            box.add (primary_label);

            var secondary_label = new Gtk.Label (secondary_text);
            secondary_label.halign = Gtk.Align.START;
            context = secondary_label.get_style_context ();
            context.add_class ("secondary-label");
            context.add_class ("dim-label");
            box.add (secondary_label);

            box.show_all ();
        }

        public override void clicked () {
            var popover = this.get_ancestor (typeof (Gtk.Popover));
            if (popover != null)
                popover.hide ();
        }
    }
}