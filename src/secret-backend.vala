namespace Credentials {
    enum SecretUse {
        OTHER,
        INVALID,
        WEBSITE,
        NETWORK,
    }

    class SecretItem : Item {
        Secret.Item _content;
        public Secret.Item content {
            construct set {
                this._content = value;
            }
        }

        SecretSchema _schema = null;
        public SecretSchema schema {
            get {
                return this._schema;
            }
        }

        public override void constructed () {
            base.constructed ();
            this._schema = ((SecretBackend) collection.backend).get_schema (this._content.get_schema_name ());
        }

        public SecretUse use {
            get {
                return this._schema.use;
            }
        }

        public uint64 get_modified () {
            return this._content.get_modified ();
        }

        public override string get_label () {
            return this._content.get_label ();
        }

        public Secret.Value? get_secret () {
            return this._content.get_secret ();
        }

        public GLib.HashTable<string,string> get_attributes () {
            return this._content.get_attributes ();
        }

        public async void load_secret (GLib.Cancellable? cancellable) throws GLib.Error {
            yield this._content.load_secret (cancellable);
        }

        public async void set_label (string label,
                                     GLib.Cancellable? cancellable) throws GLib.Error {
            yield this._content.set_label (label, cancellable);
        }

        public async void set_secret (Secret.Value value,
                                      GLib.Cancellable? cancellable) throws GLib.Error {
            yield this._content.set_secret (value, cancellable);
        }

        public async void set_attributes (Secret.Schema? schema,
                                          GLib.HashTable<string,string> attributes,
                                          GLib.Cancellable? cancellable) throws GLib.Error {
            yield this._content.set_attributes (schema, attributes, cancellable);
        }

        public override async void delete (GLib.Cancellable? cancellable) throws GLib.Error {
            yield this._content.delete (cancellable);
            collection.item_removed (this);
        }

        public override async void load_content (GLib.Cancellable? cancellable) throws GLib.Error {
        }

        public SecretItem (Collection collection, Secret.Item content) {
            Object (collection: collection, content: content);
        }

        public override int compare (Item other) {
            var difference = collection.compare (((Item) other).collection);
            if (difference != 0)
                return difference;

            var modified = this._content.get_modified ();
            var other_modified = ((SecretItem) other).get_modified ();

            if (modified > other_modified)
                return -1;
            if (modified < other_modified)
                return 1;
            return 0;
        }

        public override bool match (string[] words) {
            string[] attributes = {};
            attributes += this._content.get_label ();
            var _attributes = this._content.get_attributes ();
            var iter = GLib.HashTableIter<string,string> (_attributes);
            string value;
            while (iter.next (null, out value)) {
                attributes += value;
            }

            foreach (var attribute in attributes) {
                var matched = true;
                foreach (var word in words) {
                    if (attribute.casefold ().index_of (word.casefold ()) == -1) {
                        matched = false;
                        break;
                    }
                }
                if (matched)
                    return true;
            }
            return false;
        }
    }

    class SecretCollection : Collection {
        GLib.HashTable<string,SecretItem> _items;

        Secret.Collection _content;
        public Secret.Collection content {
            construct set {
                this._content = value;
            }
        }

        public override string item_type {
            get {
                return _("Password");
            }
        }

        public override bool locked {
            get {
                return this._content.get_locked ();
            }
        }

        public string get_label () {
            return this._content.get_label ();
        }

        public override async void unlock (GLib.TlsInteraction? interaction,
                                           GLib.Cancellable? cancellable) throws GLib.Error
        {
            var service = this._content.get_service ();
            GLib.List<GLib.DBusProxy> objects = null;
            GLib.List<GLib.DBusProxy> unlocked;
            objects.append (this._content);
            yield service.unlock (objects, cancellable, out unlocked);
            if (unlocked.length () > 0)
                backend.notify_property ("has-locked");
        }

        public SecretCollection (Backend backend, Secret.Collection content) {
            Object (backend: backend,
                    name: content.get_label (),
                    content: content);
        }

        construct {
            this._items =
                new GLib.HashTable<string,SecretItem> (GLib.str_hash,
                                                       GLib.str_equal);

            this._content.notify["items"].connect (on_items_changed);
            this._content.notify["locked"].connect (on_locked_changed);
        }

        void on_items_changed () {
            var seen = new GLib.GenericSet<string> (GLib.str_hash,
                                                    GLib.str_equal);
            GLib.List<Secret.Item> items = null;
            if (!_content.get_locked ())
                items = _content.get_items ();
            foreach (var _item in items) {
                var object_path = _item.get_object_path ();
                seen.add (object_path);
                if (!this._items.contains (object_path))
                    add_item (_item);
            }

            var iter = GLib.HashTableIter<string,SecretItem> (this._items);
            string object_path;
            SecretItem item;
            while (iter.next (out object_path, out item)) {
                if (!seen.contains (object_path)) {
                    iter.remove();
                    item_removed (item);
                }
            }
        }

        void on_locked_changed () {
            on_items_changed ();
            backend.notify_property ("has-locked");
        }

        public override async void load_items (GLib.Cancellable? cancellable) throws GLib.Error {
            if (!_content.get_locked ()) {
                foreach (var item in _content.get_items ()) {
                    if (cancellable.is_cancelled ())
                        return;
                    add_item (item);
                }
            }
        }

        public override GLib.List<Item> get_items () {
            GLib.List<Item> items = null;
            var iter = GLib.HashTableIter<string,SecretItem> (this._items);
            SecretItem item;
            while (iter.next (null, out item)) {
                items.append (item);
            }
            return items;
        }

        void add_item (Secret.Item _item) {
            var object_path = _item.get_object_path ();

            var name = _item.get_schema_name ();
            var schema = ((SecretBackend) backend).get_schema (name);
            if (schema == null)
                return;

            var item = new SecretItem (this, _item);
            if (!schema.is_valid (item))
                return;

            this._items.insert (object_path, item);
            item_added (item);
        }

        public override int compare (Collection other) {
            var difference = backend.compare (((Collection) other).backend);
            if (difference != 0)
                return difference;

            var label = _content.get_label ();
            var other_label = ((SecretCollection) other).get_label ();

            return GLib.strcmp (label, other_label);
        }
    }

    class SecretBackend : Backend {
        GLib.HashTable<string,string> _aliases;
        GLib.HashTable<string,SecretCollection> _collections;
        GLib.HashTable<string,SecretSchema> _schemas;

        public override bool has_locked {
            get {
                var iter = GLib.HashTableIter<string,SecretCollection> (this._collections);
                SecretCollection collection;
                while (iter.next (null, out collection)) {
                    if (collection.locked)
                        return true;
                }
                return false;
            }
        }

        construct {
            this._aliases =
                new GLib.HashTable<string,string> (GLib.str_hash,
                                                   GLib.str_equal);
            this._collections =
                new GLib.HashTable<string,SecretCollection> (GLib.str_hash,
                                                             GLib.str_equal);
            this._schemas =
                new GLib.HashTable<string,SecretSchema> (GLib.str_hash,
                                                         GLib.str_equal);

            this._schemas.insert ("org.epiphany.FormPassword",
                                  new SecretSchemaEpiphany ());
            this._schemas.insert ("x.internal.Chrome",
                                  new SecretSchemaChrome ());
            this._schemas.insert ("org.gnome.keyring.NetworkPassword",
                                  new SecretSchemaNetworkPassword ());
            try {
                var client = new Goa.Client.sync ();
                this._schemas.insert ("org.gnome.OnlineAccounts",
                                      new SecretSchemaGoa (client));
            } catch (Error e) {
                warning ("cannot create GOA client: %s", e.message);
            }
        }

        public SecretBackend (string name) {
            Object (name: name);
        }

        public override async void load_collections (GLib.Cancellable? cancellable) throws GLib.Error {
            Secret.Service service =
                yield Secret.Service.get (Secret.ServiceFlags.OPEN_SESSION,
                                          cancellable);

            if (cancellable.is_cancelled ())
                return;

            yield service.load_collections (cancellable);
            if (cancellable.is_cancelled ())
                return;

            yield load_aliases (service, cancellable);
            if (cancellable.is_cancelled ())
                return;

            this._collections.remove_all ();
            var collections = service.get_collections ();
            foreach (var _collection in collections) {
                if (cancellable.is_cancelled ())
                    return;

                var object_path = _collection.get_object_path ();
                if (this._aliases.lookup ("session") == object_path)
                    continue;

                var collection = new SecretCollection (this, _collection);
                this._collections.insert (object_path, collection);
                collection_added (collection);
            }
            notify_property ("has-locked");
        }

        public override GLib.List<Collection> get_collections () {
            GLib.List<Collection> collections = null;
            var iter = GLib.HashTableIter<string,SecretCollection> (this._collections);
            SecretCollection collection;
            while (iter.next (null, out collection)) {
                collections.append (collection);
            }
            return collections;
        }

        async void load_aliases (Secret.Service service, GLib.Cancellable? cancellable) {
            string[] names = { "default", "session", "login" };

            this._aliases.remove_all ();
            foreach (var name in names) {
                if (cancellable.is_cancelled ())
                    return;
                try {
                    var object_path =
                        yield service.read_alias_dbus_path (name, null);
                    if (object_path != null)
                        this._aliases.insert (name, object_path);
                } catch (GLib.Error e) {
                    warning ("cannot read alias %s: %s", name, e.message);
                }
            }
        }

        public SecretSchema? get_schema (string name) {
            return this._schemas.lookup (name);
        }

        public override int compare (Backend other) {
            return 0;
        }
    }
}
