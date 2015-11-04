namespace Credentials {
    class SshItem : Item {
        Gcr.Parsed _content;
        public Gcr.Parsed content {
            construct set {
                this._content = value;
            }
        }

        public SshItem (Collection collection, Gcr.Parsed content) {
            Object (collection: collection, content: content);
        }

        async void load_content (GLib.Cancellable? cancellable) throws GLib.Error {
            var parser = new Gcr.Parser ();
            var filename = this._content.get_filename ();
            parser.set_filename (filename);
            parser.parsed.connect (() => {
                    this._content = parser.get_parsed ();
                    changed ();
                });

            var file = GLib.File.new_for_path (filename);
                file.read_async.begin (
                    GLib.Priority.DEFAULT, null, (obj, res) => {
                        GLib.InputStream stream;
                        try {
                            stream = file.read_async.end (res);
                        } catch (GLib.Error e) {
                            return;
                        }
                        parser.parse_stream_async.begin (stream, null);
                    });
        }

        public override string get_label () {
            return format_path (this._content.get_filename ());
        }

        public string get_path () {
            return this._content.get_filename ();
        }

        public string get_comment () {
            return this._content.get_label ();
        }

        public async void set_comment (string comment) throws GLib.Error {
            var mapped = new GLib.MappedFile (this._content.get_filename (),
                                              false);
            var bytes = mapped.get_bytes ();
            var count = 0;
            var offset = 0;
            while (offset < bytes.get_size ()) {
                if (bytes.get (offset++) == ' ') {
                    count++;
                    while (offset < bytes.get_size () &&
                           bytes.get (offset) == ' ')
                        offset++;
                }
                if (count == 2)
                    break;
            }

            GLib.ByteArray buffer;

            if (count == 0)
                throw new GLib.IOError.FAILED ("not an OpenSSH public key");

            buffer = GLib.Bytes.unref_to_array (bytes);
            if (count == 1)
                buffer.append (new uint8[1] { ' ' });
            else if (offset < buffer.len)
                buffer.remove_range (offset, buffer.len - offset);
            buffer.append (comment.data);

            var file = GLib.File.new_for_path (this._content.get_filename ());
            file.replace_contents (buffer.data,
                                   null,
                                   true,
                                   GLib.FileCreateFlags.NONE,
                                   null);
            load_content.begin (null);
        }

        public ulong get_key_type () {
            var attributes = this._content.get_attributes ();
            var attribute = attributes.find (CKA.KEY_TYPE);
            return attribute.get_ulong ();
        }

        public uint get_key_size () {
            return SshUtils.compute_key_size (get_key_type (),
                                              this._content.get_attributes ());
        }

        public override int compare (Item other) {
            var difference = collection.compare (((Item) other).collection);
            if (difference != 0)
                return difference;

            var filename = this._content.get_filename ();
            var other_filename = ((SshItem) other)._content.get_filename ();

            return GLib.strcmp (filename, other_filename);
        }

        public override bool match (string[] words) {
            string[] attributes = {};
            attributes += GLib.Path.get_basename (this._content.get_filename ());
            attributes += this._content.get_label ();

            foreach (var attribute in attributes) {
                var matched = true;
                foreach (var word in words) {
                    if (attribute.casefold ().str (word.casefold ()) == null) {
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
            var filename = this._content.get_filename ();
            var file = GLib.File.new_for_path (filename);
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

                var parser = new Gcr.Parser ();
                var filename = GLib.Path.build_filename (path, basename);
                parser.set_filename (filename);
                parser.parsed.connect (() => {
                        add_item (parser.get_parsed ());
                    });

                var file = GLib.File.new_for_path (filename);
                file.read_async.begin (
                    GLib.Priority.DEFAULT, null, (obj, res) => {
                        GLib.InputStream stream;
                        try {
                            stream = file.read_async.end (res);
                        } catch (GLib.Error e) {
                            return;
                        }
                        parser.parse_stream_async.begin (stream, null);
                    });
            }
        }

        void add_item (Gcr.Parsed parsed) {
            var item = new SshItem (this, parsed);
            this._items.insert (parsed.get_filename (), item);
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
