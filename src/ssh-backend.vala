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

        public string path { construct set; get; }

        string _etag;
        public string etag {
            construct set {
                this._etag = value;
            }
        }

        public string comment {
            get {
                return this._content.comment;
            }
        }

        public SshItem (Collection collection, SshKey content,
                        string path, string etag)
        {
            Object (collection: collection, content: content,
                    path: path, etag: etag);
        }

        async void load_content (GLib.Cancellable? cancellable) throws GLib.Error {
            var file = GLib.File.new_for_path (this.path);
            uint8[] contents;
            file.load_contents (cancellable, out contents, out this._etag);
            var bytes = new GLib.Bytes (contents);
            this._content = ((SshBackend) collection.backend).parse (bytes);
            changed ();
        }

        public override string get_label () {
            return format_path (this.path);
        }

        public string get_fingerprint () {
            return this._content.get_fingerprint ();
        }

        public async void set_comment (string comment,
                                       GLib.Cancellable? cancellable) throws GLib.Error
        {
            this._content.comment = comment;
            var bytes = this._content.to_bytes ();
            var file = GLib.File.new_for_path (this.path);
            file.replace_contents (bytes.get_data (),
                                   this._etag,
                                   true,
                                   GLib.FileCreateFlags.NONE,
                                   out this._etag,
                                   cancellable);
            load_content.begin (cancellable);
        }

        public override int compare (Item other) {
            var difference = collection.compare (((Item) other).collection);
            if (difference != 0)
                return difference;

            var other_path = ((SshItem) other).path;

            return GLib.strcmp (this.path, other_path);
        }

        public override bool match (string[] words) {
            string[] attributes = {};
            attributes += GLib.Path.get_basename (this.path);
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
            var file = GLib.File.new_for_path (this.path);
            yield file.delete_async (GLib.Priority.DEFAULT, null);
            collection.item_removed (this);
        }
    }

    class SshGeneratedKeyParameters : GeneratedKeyParameters, GLib.Object {
        public string path { construct set; get; }
        public string comment { construct set; get; }
        public SshKeyType key_type { construct set; get; }
        public uint length { construct set; get; }
        public int64 expires { construct set; get; }

        public SshGeneratedKeyParameters (string path, string comment,
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
        GLib.FileMonitor _monitor;

        public SshCollection (Backend backend, string name, string path)
        {
            Object (backend: backend, name: name, path: path);
        }

        construct {
            this._items = new GLib.HashTable<string,SshItem> (GLib.str_hash,
                                                              GLib.str_equal);
            var file = GLib.File.new_for_path (path);
            try {
                this._monitor = file.monitor_directory (GLib.FileMonitorFlags.NONE, null);
                this._monitor.changed.connect (on_monitor_changed);
            } catch (GLib.Error e) {
                warning ("cannot monitor directory %s: %s", path, e.message);
            }
        }

        void on_monitor_changed (GLib.File file,
                                 GLib.File? other_file,
                                 GLib.FileMonitorEvent event_type)
        {
            switch (event_type) {
            case GLib.FileMonitorEvent.CHANGED:
            case GLib.FileMonitorEvent.DELETED:
            case GLib.FileMonitorEvent.CREATED:
                load_items.begin (null);
                break;
            default:
                break;
            }
        }

        public override async void load_items (GLib.Cancellable? cancellable) throws GLib.Error {
            var seen = new GLib.GenericSet<string> (GLib.str_hash,
                                                    GLib.str_equal);
            var dir = GLib.Dir.open (path);
            while (true) {
                if (cancellable.is_cancelled ())
                    return;
                var basename = dir.read_name ();
                if (basename == null)
                    break;
                if (!basename.has_suffix (".pub"))
                    continue;

                var path = GLib.Path.build_filename (path, basename);
                var file = GLib.File.new_for_path (path);

                SshKey key;
                string etag;
                try {
                    uint8[] contents;
                    file.load_contents (cancellable, out contents, out etag);
                    var bytes = new GLib.Bytes (contents);
                    key = ((SshBackend) backend).parse (bytes);
                } catch (GLib.Error e) {
                    warning ("cannot read public key %s: %s",
                             path, e.message);
                    continue;
                }

                seen.add (path);
                if (!this._items.contains (path)) {
                    var item = new SshItem (this, key, path, etag);
                    this._items.insert (path, item);
                    item_added (item);
                }
            }

            var iter = GLib.HashTableIter<string,SshItem> (this._items);
            string path;
            SshItem item;
            while (iter.next (out path, out item)) {
                if (cancellable.is_cancelled ())
                    return;
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

        string[] parameters_to_arguments (SshGeneratedKeyParameters parameters) {
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

        public async void generate_item (GeneratedKeyParameters parameters,
                                         GLib.Cancellable? cancellable) throws GLib.Error {
            var args = parameters_to_arguments (
                (SshGeneratedKeyParameters) parameters);
            var subprocess =
                new GLib.Subprocess.newv (args,
                                          GLib.SubprocessFlags.NONE);
            try {
                yield subprocess.wait_async (null);
                if (subprocess.get_exit_status () != 0)
                    throw new SshError.FAILED ("cannot generate key");
                load_items.begin (cancellable);
            } catch (GLib.Error e) {
                throw e;
            }
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

        public SshKey parse (GLib.Bytes bytes) throws GLib.Error {
            return this._parser.parse (bytes);
        }

        public override async void load_collections (GLib.Cancellable? cancellable) throws GLib.Error {
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
