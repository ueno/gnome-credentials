namespace Credentials {
    enum GpgGenerateKeyType {
        RSA_RSA,
        DSA_ELGAMAL,
        DSA,
        RSA_SIGN,
        ELGAMAL,
        RSA_ENCRYPT,
        ECC_ECC,
        ECC_SIGN,
        ECC_ENCRYPT
    }

    struct GpgGenerateKeyLength {
        uint min;
        uint max;
        uint _default;
    }

    class GpgGenerateParameters : Parameters, GLib.Object {
        public string name { construct set; get; }
        public string email { construct set; get; }
        public string comment { construct set; get; }
        public GpgGenerateKeyType key_type { construct set; get; }
        public uint length { construct set; get; }
        public int64 expires { construct set; get; }

        public GpgGenerateParameters (string name, string email, string comment,
                                      GpgGenerateKeyType key_type,
                                      uint length,
                                      int64 expires)
        {
            Object (name: name, email: email, comment: comment,
                    key_type: key_type, length: length, expires: expires);
        }
    }

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

        async void load_content (GLib.Cancellable? cancellable) throws GLib.Error {
            var pubkey = this._content.get_subkeys ().first ().data;
            var ctx = new GGpg.Ctx ();
            ctx.protocol = ((GpgCollection) collection).protocol;
            this._content = yield ctx.get_key (pubkey.fingerprint, 1, cancellable);
        }

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
            try {
                yield ctx.delete (this._content, 1, cancellable);
                collection.item_removed (this);
            } catch (GLib.Error e) {
                throw e;
            }
        }

        public async void edit (GpgEditCommand command, GLib.Cancellable? cancellable) throws GLib.Error {
            var ctx = new GGpg.Ctx ();
            ctx.protocol = ((GpgCollection) collection).protocol;
            var data = new GGpg.Data ();
            try {
                yield ctx.edit (this._content, command.edit_callback,
                                data, cancellable);
                yield load_content (cancellable);
                changed ();
            } catch (GLib.Error e) {
                throw e;
            }
        }
    }

    class GpgCollection : Collection, Generator {
        public GGpg.Protocol protocol { construct set; get; }
        GLib.HashTable<string,GpgItem> _items;

        public string item_type {
            get {
                return _("PGP Key");
            }
        }

        ProgressCallback _progress_callback = null;

        public void set_progress_callback (ProgressCallback progress_callback) {
            this._progress_callback = progress_callback;
        }

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
            this._items = new GLib.HashTable<string,GpgItem> (GLib.str_hash,
                                                              GLib.str_equal);
        }

        public override async void load_items () throws GLib.Error {
            var seen = new GLib.HashTable<string,void*> (GLib.str_hash,
                                                         GLib.str_equal);
            var ctx = new GGpg.Ctx ();

            ctx.protocol = protocol;
            ctx.keylist_start (null, 1);

            while (true) {
                var key = ctx.keylist_next ();
                if (key == null)
                    break;
                var pubkey = key.get_subkeys ().first ().data;
                seen.add (pubkey.fingerprint);
                if (!this._items.contains (pubkey.fingerprint)) {
                    var item = new GpgItem (this, key);
                    this._items.insert (pubkey.fingerprint, item);
                    item_added (item);
                }
            }

            var iter = GLib.HashTableIter<string,GpgItem> (this._items);
            string fingerprint;
            GpgItem item;
            while (iter.next (out fingerprint, out item)) {
                if (!seen.contains (fingerprint)) {
                    iter.remove();
                    item_removed (item);
                }
            }
        }

        public override GLib.List<Item> get_items () {
            GLib.List<Item> items = null;
            var iter = GLib.HashTableIter<string,GpgItem> (this._items);
            GpgItem item;
            while (iter.next (null, out item)) {
                items.append (item);
            }
            return items;
        }

        string format_parameters (GpgGenerateParameters parameters) {
            var buffer = new StringBuilder ();
            buffer.append ("<GnupgKeyParms format=\"internal\">\n");
            switch (parameters.key_type) {
            case GpgGenerateKeyType.RSA_RSA:
                buffer.append ("Key-Type: RSA\n");
                buffer.append ("Key-Usage: sign\n");
                buffer.append_printf ("Key-Length: %u\n", parameters.length);
                buffer.append ("Subkey-Type: RSA\n");
                buffer.append ("Subkey-Usage: encrypt\n");
                buffer.append_printf ("Subkey-Length: %u\n", parameters.length);
                break;
            case GpgGenerateKeyType.DSA_ELGAMAL:
                buffer.append ("Key-Type: DSA\n");
                buffer.append ("Key-Usage: sign\n");
                buffer.append_printf ("Key-Length: %u\n", parameters.length);
                buffer.append ("Subkey-Type: ELG-e\n");
                buffer.append ("Subkey-Usage: encrypt\n");
                buffer.append_printf ("Subkey-Length: %u\n", parameters.length);
                break;
            case GpgGenerateKeyType.DSA:
                buffer.append ("Key-Type: DSA\n");
                buffer.append ("Key-Usage: sign\n");
                buffer.append_printf ("Key-Length: %u\n", parameters.length);
                break;
            case GpgGenerateKeyType.RSA_SIGN:
                buffer.append ("Key-Type: RSA\n");
                buffer.append ("Key-Usage: sign\n");
                buffer.append_printf ("Key-Length: %u\n", parameters.length);
                break;
            case GpgGenerateKeyType.ELGAMAL:
                buffer.append ("Key-Type: ELG-E\n");
                buffer.append ("Key-Usage: encrypt\n");
                buffer.append_printf ("Key-Length: %u\n", parameters.length);
                break;
            case GpgGenerateKeyType.RSA_ENCRYPT:
                buffer.append ("Key-Type: RSA\n");
                buffer.append ("Key-Usage: encrypt\n");
                buffer.append_printf ("Key-Length: %u\n", parameters.length);
                break;
            case GpgGenerateKeyType.ECC_ECC:
                buffer.append ("Key-Type: ECDSA\n");
                buffer.append ("Key-Usage: sign\n");
                buffer.append_printf ("Key-Length: %u\n", parameters.length);
                buffer.append ("Subkey-Type: ECDH\n");
                buffer.append ("Subkey-Usage: encrypt\n");
                buffer.append_printf ("Subkey-Length: %u\n", parameters.length);
                break;
            case GpgGenerateKeyType.ECC_SIGN:
                buffer.append ("Key-Type: ECDSA\n");
                buffer.append ("Key-Usage: sign\n");
                buffer.append_printf ("Key-Length: %u\n", parameters.length);
                break;
            case GpgGenerateKeyType.ECC_ENCRYPT:
                buffer.append ("Key-Type: ECDH\n");
                buffer.append ("Key-Usage: encrypt\n");
                buffer.append_printf ("Key-Length: %u\n", parameters.length);
                break;
            default:
                return_if_reached ();
            }

            buffer.append_printf ("Name-Real: %s\n", parameters.name);
            if (parameters.email.length > 0)
                buffer.append_printf ("Name-Email: %s\n", parameters.email);
            if (parameters.comment.length > 0)
                buffer.append_printf ("Name-Comment: %s\n", parameters.comment);
            buffer.append ("Expire-Date: 0\n");
            buffer.append ("</GnupgKeyParms>\n");
            return buffer.str;
        }

        string get_progress_label (string what) {
            if (what == "pk_dsa")
                return _("Generating DSA key");
            else if (what == "pk_elg")
                return _("Generating ElGamal key");
            else if (what == "primegen")
                return _("Generating prime numbers");
            else if (what == "need_entropy")
                return _("Gathering entropy");
            return_val_if_reached ("Generating key");
        }

        void progress_callback_wrapper (string what, int type,
                                        int current, int total)
        {
            this._progress_callback (get_progress_label (what),
                                     (double) current / (double) total);
        }

        public async void generate_item (Parameters parameters,
                                         GLib.Cancellable? cancellable) throws GLib.Error {
            var ctx = new GGpg.Ctx ();
            ctx.protocol = protocol;
            if (this._progress_callback != null)
                ctx.set_progress_callback (this.progress_callback_wrapper);
            try {
                yield ctx.genkey (
                    format_parameters ((GpgGenerateParameters) parameters),
                    null, null,
                    cancellable);
                load_items ();
            } catch (GLib.Error e) {
                throw e;
            }
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
