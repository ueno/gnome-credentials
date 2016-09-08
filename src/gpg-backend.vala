namespace Credentials {
    // These values should be in sync with ask_algo() in gnupg/g10/keygen.c.
    enum GpgGeneratedKeyType {
        RSA_RSA = 1,
        DSA_ELGAMAL = 2,
        DSA_SIGN = 3,
        RSA_SIGN = 4,
        ELGAMAL_ENCRYPT = 5,
        RSA_ENCRYPT = 6,
        DSA_CAP = 7,
        RSA_CAP = 8,
        ECC_ECC = 9,
        ECC_SIGN = 10,
        ECC_CAP = 11,
        ECC_ENCRYPT = 12
    }

    enum GpgGeneratedKeyUsage {
        SIGN,
        ENCRYPT,
        SIGN_ENCRYPT
    }

    struct GpgGeneratedKeySpec {
        public GpgGeneratedKeyType key_type;
        public GpgGeneratedKeyUsage usage;
        public GGpg.PubkeyAlgo algo;
        public GGpg.PubkeyAlgo subkey_algo;
        public uint min_length;
        public uint max_length;
        public uint default_length;

        public string label;

        public GpgGeneratedKeySpec (GpgGeneratedKeyType key_type,
                                    GpgGeneratedKeyUsage usage,
                                    GGpg.PubkeyAlgo algo,
                                    GGpg.PubkeyAlgo subkey_algo,
                                    uint min_length,
                                    uint max_length,
                                    uint default_length,
                                    string label)
        {
            this.key_type = key_type;
            this.usage = usage;
            this.algo = algo;
            this.subkey_algo = subkey_algo;
            this.min_length = min_length;
            this.max_length = max_length;
            this.default_length = default_length;
            this.label = label;
        }
    }

    class GpgItemGenerationParameters : ItemGenerationParameters {
        public GpgGeneratedKeySpec spec { construct set; get; }
        public string name { construct set; get; }
        public string email { construct set; get; }
        public string comment { construct set; get; }
        public uint length { construct set; get; }
        public GpgExpirationSpec expires { construct set; get; }

        public GpgItemGenerationParameters (GpgGeneratedKeySpec spec,
                                           string name,
                                           string email,
                                           string comment,
                                           uint length,
                                           GpgExpirationSpec expires)
        {
            Object (spec: spec, name: name, email: email, comment: comment,
                    length: length, expires: expires);
        }
    }

    class GpgItem : Item {
        GGpg.Key _content;
        public GGpg.Key content {
            construct set {
                this._content = value;
            }
        }

        internal GGpg.Key get_content () {
            return this._content;
        }

        public GGpg.Validity owner_trust {
            get {
                return this._content.owner_trust;
            }
        }

        public bool has_secret {
            get {
                var subkeys = this._content.get_subkeys ();
                var pubkey = subkeys.first ().data;
                return (pubkey.flags & GGpg.SubkeyFlags.SECRET) != 0;
            }
        }

        public GGpg.KeylistMode keylist_mode {
            get {
                return this._content.keylist_mode;
            }
        }

        GLib.List<GpgGeneratedKeySpec?> _specs;

        construct {
            this._specs = null;
            register (GpgGeneratedKeySpec (GpgGeneratedKeyType.DSA_SIGN,
                                           GpgGeneratedKeyUsage.SIGN,
                                           GGpg.PubkeyAlgo.DSA,
                                           GGpg.PubkeyAlgo.NONE,
                                           1024, 3072, 2048,
                                           _("DSA (sign only)")));
            register (GpgGeneratedKeySpec (GpgGeneratedKeyType.RSA_SIGN,
                                           GpgGeneratedKeyUsage.SIGN,
                                           GGpg.PubkeyAlgo.RSA,
                                           GGpg.PubkeyAlgo.NONE,
                                           1024, 4096, 2048,
                                           _("RSA (sign only)")));
            register (GpgGeneratedKeySpec (GpgGeneratedKeyType.ELGAMAL_ENCRYPT,
                                           GpgGeneratedKeyUsage.ENCRYPT,
                                           GGpg.PubkeyAlgo.ELG,
                                           GGpg.PubkeyAlgo.NONE,
                                           1024, 4096, 2048,
                                           _("ElGamal (encrypt only)")));
            register (GpgGeneratedKeySpec (GpgGeneratedKeyType.RSA_ENCRYPT,
                                           GpgGeneratedKeyUsage.ENCRYPT,
                                           GGpg.PubkeyAlgo.RSA,
                                           GGpg.PubkeyAlgo.NONE,
                                           1024, 4096, 2048,
                                           _("RSA (encrypt only)")));
            // TODO: Enable them once figuring out how to determine
            // supported algorithms from GPGME
#if false
            register (GpgGeneratedKeySpec (GpgGeneratedKeyType.ECC_SIGN,
                                           GpgGeneratedKeyUsage.SIGN,
                                           GGpg.PubkeyAlgo.ECDSA,
                                           GGpg.PubkeyAlgo.NONE,
                                           256, 521, 256,
                                           _("ECC (sign only)")));
            register (GpgGeneratedKeySpec (GpgGeneratedKeyType.ECC_ENCRYPT,
                                           GpgGeneratedKeyUsage.ENCRYPT,
                                           GGpg.PubkeyAlgo.ECDH,
                                           GGpg.PubkeyAlgo.NONE,
                                           256, 521, 256,
                                           _("ECC (encrypt only)")));
#endif
        }

        void register (GpgGeneratedKeySpec spec) {
            this._specs.append (spec);
        }

        public unowned GLib.List<GpgGeneratedKeySpec?> get_generated_key_specs () {
            return this._specs;
        }

        public GLib.List<GGpg.Subkey> get_subkeys () {
            return this._content.get_subkeys ();
        }

        public override async void load_content (GLib.Cancellable? cancellable) throws GLib.Error {
            var pubkey = this._content.get_subkeys ().first ().data;
            var ctx = new GGpg.Ctx ();
            ctx.protocol = ((GpgCollection) collection).protocol;
            var patterns = new string[] { pubkey.fingerprint };

            // First, try to load the secret key.
            yield ctx.keylist (patterns,
                               true,
                               (key) => {
                                   this._content = key;
                               },
                               cancellable);

            // If there is no corresponding secret key, load
            // the public key.
            if (!has_secret) {
                yield ctx.keylist (patterns,
                                   false,
                                   (key) => {
                                       this._content = key;
                                   },
                                   cancellable);
            }
        }

        public GLib.List<GGpg.UserId> get_uids () {
            return this._content.get_uids ();
        }

        public GpgItem (Collection collection, GGpg.Key content) {
            Object (collection: collection, content: content);
        }

        public override string get_label () {
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

        public override bool match (string[] words) {
            string[] attributes = {};
            var uids = this._content.get_uids ();
            foreach (var uid in uids) {
                attributes += uid.uid;
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

        public override async void delete (GLib.Cancellable? cancellable) throws GLib.Error {
            var ctx = new GGpg.Ctx ();
            ctx.protocol = ((GpgCollection) collection).protocol;
            yield ctx.delete (this._content, GGpg.DeleteFlags.ALLOW_SECRET,
                              cancellable);
            collection.item_removed (this);
        }

        public async void edit (GpgEditCommand command, GLib.Cancellable? cancellable) throws GLib.Error {
            var ctx = new GGpg.Ctx ();
            ctx.protocol = ((GpgCollection) collection).protocol;
            var data = new GGpg.Data ();
            yield ctx.edit (this._content, command.edit_callback,
                            data, cancellable);
            yield load_content (cancellable);
            changed ();
        }

        public async void change_password (GLib.Cancellable? cancellable) throws GLib.Error {
            var ctx = new GGpg.Ctx ();
            ctx.protocol = ((GpgCollection) collection).protocol;
            yield ctx.change_password (this._content,
                                       GGpg.ChangePasswordFlags.NONE,
                                       cancellable);
        }
    }

    class GpgCollection : Collection {
        public GGpg.Protocol protocol { construct set; get; }
        GLib.HashTable<string,GpgItem> _items;
        GLib.List<GpgGeneratedKeySpec?> _specs;

        public override string item_type {
            get {
                return _("PGP Key");
            }
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
            this._specs = null;
            register (GpgGeneratedKeySpec (GpgGeneratedKeyType.RSA_RSA,
                                           GpgGeneratedKeyUsage.SIGN_ENCRYPT,
                                           GGpg.PubkeyAlgo.RSA,
                                           GGpg.PubkeyAlgo.RSA,
                                           1024, 4096, 2048,
                                           _("RSA and RSA")));
            register (GpgGeneratedKeySpec (GpgGeneratedKeyType.DSA_ELGAMAL,
                                           GpgGeneratedKeyUsage.SIGN_ENCRYPT,
                                           GGpg.PubkeyAlgo.DSA,
                                           GGpg.PubkeyAlgo.ELG,
                                           1024, 3072, 2048,
                                           _("DSA and ElGamal")));
            register (GpgGeneratedKeySpec (GpgGeneratedKeyType.DSA_SIGN,
                                           GpgGeneratedKeyUsage.SIGN,
                                           GGpg.PubkeyAlgo.DSA,
                                           GGpg.PubkeyAlgo.NONE,
                                           1024, 3072, 2048,
                                           _("DSA (sign only)")));
            register (GpgGeneratedKeySpec (GpgGeneratedKeyType.RSA_SIGN,
                                           GpgGeneratedKeyUsage.SIGN,
                                           GGpg.PubkeyAlgo.RSA,
                                           GGpg.PubkeyAlgo.NONE,
                                           1024, 4096, 2048,
                                           _("RSA (sign only)")));
            // TODO: Enable them once figuring out how to determine
            // supported algorithms from GPGME
#if false
            register (GpgGeneratedKeySpec (GpgGeneratedKeyType.ECC_ECC,
                                           GpgGeneratedKeyUsage.SIGN_ENCRYPT,
                                           GGpg.PubkeyAlgo.ECDSA,
                                           GGpg.PubkeyAlgo.ECDH,
                                           256, 521, 256,
                                           _("ECC and ECC")));
            register (GpgGeneratedKeySpec (GpgGeneratedKeyType.ECC_SIGN,
                                           GpgGeneratedKeyUsage.SIGN,
                                           GGpg.PubkeyAlgo.ECDSA,
                                           GGpg.PubkeyAlgo.NONE,
                                           256, 521, 256,
                                           _("ECC (sign only)")));
#endif
        }

        void register (GpgGeneratedKeySpec spec) {
            this._specs.append (spec);
        }

        public unowned GLib.List<GpgGeneratedKeySpec?> get_generated_key_specs () {
            return this._specs;
        }

        public override async void load_items (GLib.Cancellable? cancellable) throws GLib.Error {
            var seen = new GLib.GenericSet<string> (GLib.str_hash,
                                                    GLib.str_equal);
            var ctx = new GGpg.Ctx ();

            ctx.protocol = protocol;
            yield ctx.keylist (null, false, (key) => {
                    var pubkey = key.get_subkeys ().first ().data;
                    seen.add (pubkey.fingerprint);
                    if (!this._items.contains (pubkey.fingerprint)) {
                        var item = new GpgItem (this, key);
                        this._items.insert (pubkey.fingerprint, item);
                        item_added (item);
                    }
                }, cancellable);

            var iter = GLib.HashTableIter<string,GpgItem> (this._items);
            string fingerprint;
            GpgItem item;
            while (iter.next (out fingerprint, out item)) {
                if (cancellable.is_cancelled ())
                    return;
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

        string pubkey_algo_name (GGpg.PubkeyAlgo algo) {
            return_val_if_fail (algo != GGpg.PubkeyAlgo.NONE, null);
            var enum_class = (EnumClass) typeof (GGpg.PubkeyAlgo).class_ref ();
            var enum_value = enum_class.get_value (algo);
            return enum_value.value_nick.up ();
        }

        string parameters_to_string (GpgItemGenerationParameters parameters) {
            var buffer = new StringBuilder ();
            buffer.append ("<GnupgKeyParms format=\"internal\">\n");
            buffer.append_printf ("Key-Type: %s\n",
                                  pubkey_algo_name (parameters.spec.algo));
            switch (parameters.spec.usage) {
            case GpgGeneratedKeyUsage.SIGN:
            case GpgGeneratedKeyUsage.SIGN_ENCRYPT:
                buffer.append ("Key-Usage: sign\n");
                break;
            case GpgGeneratedKeyUsage.ENCRYPT:
                buffer.append ("Key-Usage: encrypt\n");
                break;
            }
            buffer.append_printf ("Key-Length: %u\n", parameters.length);

            if (parameters.spec.subkey_algo != GGpg.PubkeyAlgo.NONE) {
                buffer.append_printf ("Subkey-Type: %s\n",
                                      pubkey_algo_name (parameters.spec.subkey_algo));
                // FIXME: we assume the generated subkey is only for
                // encryption and has the same length as the primary key.
                buffer.append ("Subkey-Usage: encrypt\n");
                buffer.append_printf ("Subkey-Length: %u\n", parameters.length);
            }

            buffer.append_printf ("Name-Real: %s\n", parameters.name);
            if (parameters.email.length > 0)
                buffer.append_printf ("Name-Email: %s\n", parameters.email);
            if (parameters.comment.length > 0)
                buffer.append_printf ("Name-Comment: %s\n", parameters.comment);
            buffer.append ("Expire-Date: %s\n".printf (parameters.expires.indicator ()));
            buffer.append ("</GnupgKeyParms>\n");
            return buffer.str;
        }

        void progress_callback_wrapper (string what, int type,
                                        int current, int total)
        {
            progress_changed (GpgUtils.format_generator_progress_type (what),
                              (double) current / (double) total);
        }

        public override async void generate_item (ItemGenerationParameters parameters,
                                         GLib.Cancellable? cancellable) throws GLib.Error
        {
            var ctx = new GGpg.Ctx ();
            ctx.protocol = protocol;
            ctx.set_progress_callback (this.progress_callback_wrapper);
            yield ctx.generate_key (
                parameters_to_string ((GpgItemGenerationParameters) parameters),
                null, null,
                cancellable);
            yield load_items (cancellable);
        }

        public async GGpg.ImportResult import_items (GpgItem[] items,
                                                     GLib.Cancellable? cancellable) throws GLib.Error
        {
            var ctx = new GGpg.Ctx ();
            ctx.protocol = protocol;
            GGpg.Key[] keys = {};
            foreach (var item in items) {
                keys += item.get_content ();
            }
            yield ctx.import_keys (keys, cancellable);
            yield load_items (cancellable);
            return ctx.import_result ();
        }

        public async GGpg.ImportResult import_from_bytes (GLib.Bytes bytes,
                                                          GLib.Cancellable? cancellable) throws GLib.Error
        {
            var ctx = new GGpg.Ctx ();
            ctx.protocol = protocol;
            var data = new GGpg.Data.from_bytes (bytes);
            yield ctx.import (data, cancellable);
            yield load_items (cancellable);
            return ctx.import_result ();
        }

        public override async void export_to_server (Item[] items,
                                                     GLib.Cancellable? cancellable) throws GLib.Error {
            var ctx = new GGpg.Ctx ();
            ctx.protocol = protocol;
            GGpg.Key[] keys = {};
            foreach (var item in items) {
                keys += ((GpgItem) item).get_content ();
            }
            yield ctx.export_keys (keys, GGpg.ExportMode.EXTERN, null,
                                   cancellable);
        }

        public override async GLib.Bytes export_to_bytes (Item[] items,
                                                          GLib.Cancellable? cancellable) throws GLib.Error
        {
            var ctx = new GGpg.Ctx ();
            ctx.protocol = protocol;
            ctx.armor = true;
            GGpg.Key[] keys = {};
            foreach (var item in items) {
                keys += ((GpgItem) item).get_content ();
            }
            var data = new GGpg.Data ();
            yield ctx.export_keys (keys, 0, data, cancellable);
            return data.free_to_bytes ();
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
        const GpgCollectionEntry[] entries = {
            { GGpg.Protocol.OPENPGP, "openpgp" }
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

        public override async void load_collections (GLib.Cancellable? cancellable) throws GLib.Error {
            foreach (var entry in entries) {
                if (cancellable.is_cancelled ())
                    return;
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
