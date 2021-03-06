namespace Credentials {
    errordomain BackendError {
        FAILED,
        INVALID_ARGUMENT,
        NOT_SUPPORTED
    }

    abstract class Item : GLib.Object {
        public Collection collection { construct set; get; }
        public signal void changed ();

        public abstract string get_label ();

        public virtual async void delete (GLib.Cancellable? cancellable) throws GLib.Error {
            throw new BackendError.NOT_SUPPORTED ("not supported");
        }

        public abstract async void load_content (GLib.Cancellable? cancellable) throws GLib.Error;

        public abstract int compare (Item other);

        public virtual bool match (string[] words) {
            return false;
        }
    }

    abstract class Collection : GLib.Object {
        public string name { construct set; get; }
        public Backend backend { construct set; get; }
        public abstract string item_type { get; }
        public abstract bool locked { get; }

        public abstract async void load_items (GLib.Cancellable? cancellable) throws GLib.Error;
        public abstract GLib.List<Item> get_items ();

        public virtual async void unlock (GLib.TlsInteraction? interaction,
                                          GLib.Cancellable? cancellable) throws GLib.Error
        {
            throw new BackendError.NOT_SUPPORTED ("not supported");
        }

        public signal void item_added (Item item);
        public signal void item_removed (Item item);

        public signal void progress_changed (string label, double fraction);
        public virtual async void generate_item (GeneratedItemParameters parameters, GLib.Cancellable? cancellable) throws GLib.Error {
            throw new BackendError.NOT_SUPPORTED ("not supported");
        }

        public virtual async void export_to_server (Item[] items,
                                                    GLib.Cancellable? cancellable) throws GLib.Error {
            throw new BackendError.NOT_SUPPORTED ("not supported");
        }

        public virtual async GLib.Bytes export_to_bytes (Item[] items,
                                                         GLib.Cancellable? cancellable) throws GLib.Error
        {
            throw new BackendError.NOT_SUPPORTED ("not supported");
        }

        public abstract int compare (Collection other);
    }

    abstract class GeneratedItemParameters : GLib.Object {
    }

    abstract class Backend : GLib.Object {
        public string name { construct set; get; }
        public abstract bool has_locked { get; }

        public abstract async void load_collections (GLib.Cancellable? cancellable) throws GLib.Error;
        public abstract GLib.List<Collection> get_collections ();

        public signal void collection_added (Collection collection);
        public signal void collection_removed (Collection collection);

        public abstract int compare (Backend other);
    }
}
