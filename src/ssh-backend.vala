namespace Credentials {
    class SshItem : Item {
        SshPublicKey _content;
        public SshPublicKey content {
            construct set {
                this._content = value;
            }
        }

        public SshItem (Collection collection, SshPublicKey content) {
            Object (collection: collection, content: content);
        }

        async void load_content (GLib.Cancellable? cancellable) throws GLib.Error {
            var mapped = new GLib.MappedFile (this._content.path, false);
            var bytes = mapped.get_bytes ();
            this._content = SshPublicKey.parse (this._content.path, bytes);
            changed ();
        }

        public override string get_label () {
            return format_path (this._content.path);
        }

        public string get_path () {
            return this._content.path;
        }

        public string get_comment () {
            return this._content.comment;
        }

        public string get_fingerprint () {
            return this._content.get_fingerprint ();
        }

        public async void set_comment (string comment) throws GLib.Error {
            this._content.comment = comment;
            var bytes = this._content.to_bytes ();
            var file = GLib.File.new_for_path (this._content.path);
            file.replace_contents (bytes.get_data (),
                                   null,
                                   true,
                                   GLib.FileCreateFlags.NONE,
                                   null);
            load_content.begin (null);
        }

        public SshKeyType get_key_type () {
            return this._content.key_type;
        }

        public uint get_key_size () {
            return this._content.length;
        }

        public override int compare (Item other) {
            var difference = collection.compare (((Item) other).collection);
            if (difference != 0)
                return difference;

            var path = this._content.path;
            var other_path = ((SshItem) other)._content.path;

            return GLib.strcmp (path, other_path);
        }

        public override bool match (string[] words) {
            string[] attributes = {};
            attributes += GLib.Path.get_basename (this._content.path);
            attributes += this._content.comment;

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

        public override async void delete (GLib.Cancellable? cancellable) throws GLib.Error {
            var file = GLib.File.new_for_path (this._content.path);
            yield file.delete_async (GLib.Priority.DEFAULT, null);
            collection.item_removed (this);
        }
    }

    class SshCollection : Collection {
        GLib.HashTable<string,SshItem> _items;

        public override string item_type {
            get {
                return _("SSH Key");
            }
        }

        public override bool locked {
            get {
                return false;
            }
        }

        public string path { construct set; get; }

        public SshCollection (Backend backend, string name, string path)
        {
            Object (backend: backend, name: name, path: path);
        }

        construct {
            this._items = new GLib.HashTable<string,SshItem> (GLib.str_hash,
                                                              GLib.str_equal);
        }

        public override async void load_items () throws GLib.Error {
            var dir = GLib.Dir.open (path);
            while (true) {
                var basename = dir.read_name ();
                if (basename == null)
                    break;
                if (!basename.has_suffix (".pub"))
                    continue;

                var filename = GLib.Path.build_filename (path, basename);
                var mapped = new GLib.MappedFile (filename, false);
                var bytes = mapped.get_bytes ();
                try {
                    var pubkey = SshPublicKey.parse (filename, bytes);
                    add_item (pubkey);
                } catch (GLib.Error e) {
                    warning ("cannot read public key %s: %s",
                             filename, e.message);
                }
            }
        }

        void add_item (SshPublicKey pubkey) {
            var item = new SshItem (this, pubkey);
            this._items.insert (pubkey.path, item);
            item_added (item);
        }

        public override GLib.List<Item> get_items () {
            GLib.List<Item> items = null;
            var iter = GLib.HashTableIter<string,SshItem> (this._items);
            SshItem item;
            while (iter.next (null, out item)) {
                items.append (item);
            }
            return items;
        }

        public override int compare (Collection other) {
            var difference = backend.compare (((Collection) other).backend);
            if (difference != 0)
                return difference;

            var other_name = ((SshCollection) other).name;

            return GLib.strcmp (name, other_name);
        }
    }

    class SshBackend : Backend {
        SshCollection _collection;

        public override bool has_locked {
            get {
                return false;
            }
        }

        public SshBackend (string name) {
            Object (name: name);
        }

        public override async void load_collections () throws GLib.Error {
            var sshdir =
                GLib.Path.build_filename (GLib.Environment.get_home_dir (),
                                          ".ssh");
            this._collection = new SshCollection (this, name, sshdir);
            collection_added (this._collection);
        }

        public override GLib.List<Collection> get_collections () {
            GLib.List<Collection> collections = null;
            collections.append (this._collection);
            return collections;
        }

        public override int compare (Backend other) {
            return GLib.strcmp (name, other.name);
        }
    }
}
