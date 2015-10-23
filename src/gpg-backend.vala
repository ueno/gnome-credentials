namespace Credentials {
    class GpgItem : Item {
        GGpg.Key _content;
        public GGpg.Key content {
            construct set {
                this._content = value;
            }
        }

        public GGpg.Validity owner_trust {
            get {
                return this._content.owner_trust;
            }
        }

        public GLib.List<GGpg.Subkey> get_subkeys () {
            return this._content.get_subkeys ();
        }

        public async void load_content (GLib.Cancellable? cancellable) throws GLib.Error {
            var pubkey = this._content.get_subkeys ().first ().data;
            var ctx = new GGpg.Ctx ();
            ctx.protocol = ((GpgCollection) collection).protocol;
            this._content = yield ctx.get_key (pubkey.fingerprint, 1, cancellable);
        }

        public signal void content_changed ();

        public GLib.List<GGpg.UserId> get_uids () {
            return this._content.get_uids ();
        }

        public GpgItem (Collection collection, GGpg.Key content) {
            Object (collection: collection, content: content);
        }

        public string get_label () {
            GGpg.UserId uid = this._content.get_uids ().first ().data;
            if (uid.email != "")
                return uid.email;
            return uid.uid;
        }

        public override int compare (Item other) {
            var difference = collection.compare (((Item) other).collection);
            if (difference != 0)
                return difference;

            var label = get_label ();
            var other_label = ((GpgItem) other).get_label ();

            return GLib.strcmp (label, other_label);
        }

        public override async void delete (GLib.Cancellable? cancellable) throws GLib.Error {
            var ctx = new GGpg.Ctx ();
            ctx.protocol = ((GpgCollection) collection).protocol;
            yield ctx.delete (this._content, 1, cancellable);
        }

        public async void edit (GpgEditCommand command, GLib.Cancellable? cancellable) throws GLib.Error {
            var ctx = new GGpg.Ctx ();
            ctx.protocol = ((GpgCollection) collection).protocol;
            var data = new GGpg.Data ();
            yield ctx.edit (this._content, command.edit_callback,
                            data, cancellable);
        }
    }

    class GpgCollection : Collection {
        public GGpg.Protocol protocol { construct set; get; }
        GLib.HashTable<GpgItem,void*> _items;

        public override bool locked {
            get {
                return false;
            }
        }

        public GpgCollection (Backend backend,
                              string name,
                              GGpg.Protocol protocol)
        {
            Object (backend: backend, name: name, protocol: protocol);
        }

        construct {
            this._items = new GLib.HashTable<GpgItem,void*> (null, null);
        }

        public override async void load_items () throws GLib.Error {
            var ctx = new GGpg.Ctx ();

            ctx.protocol = protocol;
            ctx.keylist_start (null, 1);

            while (true) {
                var key = ctx.keylist_next ();
                if (key == null)
                    break;
                var item = new GpgItem (this, key);
                this._items.add (item);
                item_added (item);
            }
        }

        public override GLib.List<Item> get_items () {
            GLib.List<Item> items = null;
            var iter = GLib.HashTableIter<GpgItem,void*> (this._items);
            GpgItem item;
            while (iter.next (out item, null)) {
                items.append (item);
            }
            return items;
        }

        public override int compare (Collection other) {
            var difference = backend.compare (((Collection) other).backend);
            if (difference != 0)
                return difference;

            var other_name = ((GpgCollection) other).name;

            return GLib.strcmp (name, other_name);
        }
    }

    struct GpgCollectionEntry {
        GGpg.Protocol protocol;
        string name;
    }

    class GpgBackend : Backend {
        static construct {
            GGpg.check_version (null);
        }

        static const GpgCollectionEntry[] entries = {
            { GGpg.Protocol.OPENPGP, "PGP" }
        };

        GLib.HashTable<string,GpgCollection> _collections;

        public override bool has_locked {
            get {
                return false;
            }
        }

        public GpgBackend (string name) {
            Object (name: name);
        }

        construct {
            this._collections =
                new GLib.HashTable<string,GpgCollection> (GLib.str_hash,
                                                          GLib.str_equal);
        }

        public override async void load_collections () throws GLib.Error {
            foreach (var entry in entries) {
                var collection = new GpgCollection (this,
                                                    entry.name,
                                                    entry.protocol);
                this._collections.insert (entry.name, collection);
                collection_added (collection);
            }
        }

        public override GLib.List<Collection> get_collections () {
            GLib.List<Collection> collections = null;
            var iter = GLib.HashTableIter<string,GpgCollection> (this._collections);
            GpgCollection collection;
            while (iter.next (null, out collection)) {
                collections.append (collection);
            }
            return collections;
        }

        public override int compare (Backend other) {
            return GLib.strcmp (name, other.name);
        }
    }
}
