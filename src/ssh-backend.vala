namespace Credentials {
    errordomain SshError {
        FAILED,
        INVALID_FORMAT,
        NOT_SUPPORTED
    }

    class SshItem : Item {
        SshKey _content;
        public SshKey content {
            construct set {
                this._content = value;
            }
        }

        public SshKeySpec spec {
            get {
                return this._content.spec;
            }
        }

        public SshKeyType key_type {
            get {
                return this._content.spec.key_type;
            }
        }

        public uint length {
            get {
                return this._content.blob.length;
            }
        }

        public SshItem (Collection collection, SshKey content) {
            Object (collection: collection, content: content);
        }

        async void load_content (GLib.Cancellable? cancellable) throws GLib.Error {
            this._content = ((SshBackend) collection.backend).parse (
                this._content.path);
            changed ();
        }

        public override string get_label () {
            return format_path (this._content.path);
        }

        public string path {
            get {
                return this._content.path;
            }
        }

        public string comment {
            get {
                return this._content.comment;
            }
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

    class SshGenerateParameters : Parameters, GLib.Object {
        public string path { construct set; get; }
        public string comment { construct set; get; }
        public SshKeyType key_type { construct set; get; }
        public uint length { construct set; get; }
        public int64 expires { construct set; get; }

        public SshGenerateParameters (string path, string comment,
                                      SshKeyType key_type,
                                      uint length)
        {
            Object (path: path, comment: comment,
                    key_type: key_type, length: length);
        }
    }

    class SshCollection : Collection, ItemGenerator {
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
            var seen = new GLib.GenericSet<string> (GLib.str_hash,
                                                    GLib.str_equal);
            var dir = GLib.Dir.open (path);
            while (true) {
                var basename = dir.read_name ();
                if (basename == null)
                    break;
                if (!basename.has_suffix (".pub"))
                    continue;

                var filename = GLib.Path.build_filename (path, basename);

                SshKey pubkey;
                try {
                    pubkey = ((SshBackend) backend).parse (filename);
                } catch (GLib.Error e) {
                    warning ("cannot read public key %s: %s",
                             filename, e.message);
                    continue;
                }

                seen.add (filename);
                if (!this._items.contains (pubkey.path)) {
                    var item = new SshItem (this, pubkey);
                    this._items.insert (pubkey.path, item);
                    item_added (item);
                }
            }

            var iter = GLib.HashTableIter<string,SshItem> (this._items);
            string path;
            SshItem item;
            while (iter.next (out path, out item)) {
                if (!seen.contains (path)) {
                    iter.remove();
                    item_removed (item);
                }
            }
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

        string[] parameters_to_arguments (SshGenerateParameters parameters) {
            var spec = ((SshBackend) backend).get_spec (parameters.key_type);
            string[] args = { "ssh-keygen", "-q" };
            args += "-f";
            args += parameters.path;
            args += "-b";
            args += parameters.length.to_string ();
            args += "-t";
            args += spec.keygen_argument;
            args += "-C";
            args += parameters.comment;
            return args;
        }

        public async void generate_item (Parameters parameters,
                                         GLib.Cancellable? cancellable) throws GLib.Error {
            var args = parameters_to_arguments (
                (SshGenerateParameters) parameters);
            var subprocess =
                new GLib.Subprocess.newv (args,
                                          GLib.SubprocessFlags.NONE);
            try {
                yield subprocess.wait_async (null);
                if (subprocess.get_exit_status () != 0)
                    throw new SshError.FAILED ("cannot generate key");
                load_items.begin ();
            } catch (GLib.Error e) {
                throw e;
            }
        }

        public void set_progress_callback (ProgressCallback callback) {
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
        SshKeyParser _parser;

        public override bool has_locked {
            get {
                return false;
            }
        }

        public SshBackend (string name) {
            Object (name: name);
            this._parser = new SshKeyParser ();
        }

        public SshKeySpec get_spec (SshKeyType type) {
            return this._parser.get_spec (type);
        }

        public SshKey parse (string filename) throws GLib.Error {
            var mapped = new GLib.MappedFile (filename, false);
            var bytes = mapped.get_bytes ();
            return this._parser.parse (filename, bytes);
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
