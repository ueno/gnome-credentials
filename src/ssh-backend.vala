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

        public bool authorized {
            get {
                return ((SshCollection) this.collection).is_authorized (this._content);
            }
            set {
                try {
                    ((SshCollection) this.collection).set_authorized (this._content, value, null);
                } catch (GLib.Error e) {
                    warning ("cannot set authorized: %s", e.message);
                }
            }
        }

        public SshItem (Collection collection, SshKey content,
                        string path, string etag)
        {
            Object (collection: collection, content: content,
                    path: path, etag: etag);
        }

        public override async void load_content (GLib.Cancellable? cancellable) throws GLib.Error {
            var file = GLib.File.new_for_path (this.path);
            uint8[] contents;
            file.load_contents (cancellable, out contents, out this._etag);
            var bytes = new GLib.Bytes (contents);
            this._content = ((SshBackend) collection.backend).parse (bytes);
            changed ();
        }

        public override string get_label () {
            return Utils.format_path (this.path);
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
            yield load_content (cancellable);
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

        public async void change_password (GLib.Cancellable? cancellable) throws GLib.Error {
            string[] args = { "ssh-keygen", "-q", "-p" };
            args += "-f";
            args += path[0:path.last_index_of (".pub")];
            var subprocess =
                new GLib.Subprocess.newv (args,
                                          GLib.SubprocessFlags.NONE);
            yield subprocess.wait_async (null);
            if (subprocess.get_exit_status () != 0)
                throw new SshError.FAILED ("cannot change password");
        }

        public GLib.Bytes to_bytes () {
            return this._content.to_bytes ();
        }
    }

    class SshGeneratedItemParameters : GeneratedItemParameters {
        public string path { construct set; get; }
        public string comment { construct set; get; }
        public SshKeySpec spec { construct set; get; }
        public uint length { construct set; get; }

        public SshGeneratedItemParameters (string path, string comment,
                                           SshKeySpec spec, uint length)
        {
            Object (path: path, comment: comment, spec: spec, length: length);
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
        GLib.FileMonitor _monitor;

        string _authorized_keys_path;
        string _authorized_keys_etag;
        GLib.Bytes _authorized_keys_bytes;
        GLib.FileMonitor _authorized_keys_monitor;

        public SshCollection (Backend backend, string name, string path) {
            Object (backend: backend, name: name, path: path);
        }

        construct {
            this._items = new GLib.HashTable<string,SshItem> (GLib.str_hash,
                                                              GLib.str_equal);
            var file = GLib.File.new_for_path (path);
            try {
                this._monitor =
                    file.monitor_directory (GLib.FileMonitorFlags.NONE, null);
                this._monitor.changed.connect (on_monitor_changed);
            } catch (GLib.Error e) {
                warning ("cannot monitor directory %s: %s", path, e.message);
            }

            this._authorized_keys_path = GLib.Path.build_filename (path, "authorized_keys");
            var authorized_keys_file = GLib.File.new_for_path (this._authorized_keys_path);
            try {
                this._authorized_keys_monitor = authorized_keys_file.monitor_file (GLib.FileMonitorFlags.NONE, null);
                this._authorized_keys_monitor.changed.connect (on_authorized_keys_monitor_changed);
            } catch (GLib.Error e) {
                warning ("cannot monitor file %s: %s", this._authorized_keys_path, e.message);
            }
            load_authorized_keys.begin (null);
        }

        void on_monitor_changed (GLib.File file,
                                 GLib.File? other_file,
                                 GLib.FileMonitorEvent event_type)
        {
            switch (event_type) {
            case GLib.FileMonitorEvent.CHANGED:
            case GLib.FileMonitorEvent.DELETED:
            case GLib.FileMonitorEvent.CREATED:
                load_items.begin (null, (obj, res) => {
                        try {
                            load_items.end (res);
                        } catch (GLib.Error e) {
                            warning ("cannot load items: %s", e.message);
                        }
                    });
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

        public bool is_authorized (SshKey key) {
            var memory = new GLib.MemoryInputStream.from_bytes (this._authorized_keys_bytes);
            var input = new GLib.DataInputStream (memory);
            var bytes = key.to_bytes ();
            while (true) {
                string line;
                try {
                    line = input.read_line ();
                    if (line == null)
                        break;
                } catch (GLib.Error e) {
                    warning ("cannot read line: %s", e.message);
                    continue;
                }
                var index = line.index_of_char (' ');
                if (index < 0)
                    continue;
                index = line.index_of_char (' ', index + 1);
                if (index < 0)
                    continue;
                if (GLib.Memory.cmp (line.data, bytes.get_data (), index) == 0)
                    return true;
            }
            return false;
        }

        public void set_authorized (SshKey key, bool authorized, GLib.Cancellable? cancellable) throws GLib.Error {
            var memory = new GLib.MemoryInputStream.from_bytes (this._authorized_keys_bytes);
            var input = new GLib.DataInputStream (memory);
            var output = new GLib.MemoryOutputStream.resizable ();
            var bytes = key.to_bytes ();
            while (true) {
                string line = input.read_line (null, cancellable);
                if (line == null)
                    break;
                var index = line.index_of_char (' ');
                if (index < 0)
                    continue;
                index = line.index_of_char (' ', index + 1);
                if (index < 0)
                    continue;
                if (GLib.Memory.cmp (line.data, bytes.get_data (), index) == 0) {
                    if (authorized)
                        return;
                } else {
                    output.write (line.data, cancellable);
                    output.write ("\n".data, cancellable);
                }
            }
            if (authorized)
                output.write_bytes (bytes, cancellable);
            var size = output.get_data_size ();
            var data = output.get_data ()[0:size];
            var file = GLib.File.new_for_path (this._authorized_keys_path);
            file.replace_contents (data,
                                   this._authorized_keys_etag,
                                   true,
                                   GLib.FileCreateFlags.NONE,
                                   out this._authorized_keys_etag,
                                   cancellable);
            this._authorized_keys_bytes = new GLib.Bytes (data);
        }

        public signal void authorized_keys_changed ();

        async void load_authorized_keys (GLib.Cancellable? cancellable) throws GLib.Error {
            var file = GLib.File.new_for_path (this._authorized_keys_path);
            uint8[] contents;
            string etag;
            file.load_contents (cancellable,
                                out contents,
                                out etag);
            if (etag != this._authorized_keys_etag) {
                this._authorized_keys_bytes = new GLib.Bytes (contents);
                authorized_keys_changed ();
            }
        }

        void on_authorized_keys_monitor_changed (GLib.File file,
                                                 GLib.File? other_file,
                                                 GLib.FileMonitorEvent event_type)
        {
            switch (event_type) {
            case GLib.FileMonitorEvent.CHANGED:
            case GLib.FileMonitorEvent.DELETED:
            case GLib.FileMonitorEvent.CREATED:
                load_authorized_keys.begin (null);
                break;
            default:
                break;
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

        string[] parameters_to_arguments (SshGeneratedItemParameters parameters) {
            string[] args = { "ssh-keygen", "-q" };
            args += "-f";
            args += parameters.path;
            args += "-b";
            args += parameters.length.to_string ();
            args += "-t";
            args += parameters.spec.keygen_argument;
            args += "-C";
            args += parameters.comment;
            return args;
        }

        public unowned GLib.List<SshKeySpec?> get_specs () {
            return ((SshBackend) backend).get_specs ();
        }

        public override async void generate_item (GeneratedItemParameters parameters,
                                                  GLib.Cancellable? cancellable) throws GLib.Error {
            var args = parameters_to_arguments (
                (SshGeneratedItemParameters) parameters);
            var subprocess =
                new GLib.Subprocess.newv (args,
                                          GLib.SubprocessFlags.NONE);
            yield subprocess.wait_async (null);
            if (subprocess.get_exit_status () != 0)
                throw new SshError.FAILED ("cannot generate key");
            yield load_items (cancellable);
        }

        public override async GLib.Bytes export_to_bytes (Item[] items,
                                                          GLib.Cancellable? cancellable) throws GLib.Error
        {
            var buffer = new GLib.ByteArray ();
            foreach (var item in items) {
                var bytes = ((SshItem) item).to_bytes ();
                buffer.append (bytes.get_data ());
            }
            return GLib.ByteArray.free_to_bytes (buffer);
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

        public unowned GLib.List<SshKeySpec?> get_specs () {
            return this._parser.get_specs ();
        }

        public SshKey parse (GLib.Bytes bytes) throws GLib.Error {
            return this._parser.parse (bytes);
        }

        public override async void load_collections (GLib.Cancellable? cancellable) throws GLib.Error {
            var sshdir =
                GLib.Path.build_filename (GLib.Environment.get_home_dir (),
                                          ".ssh");
            this._collection = new SshCollection (this, "ssh", sshdir);
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
