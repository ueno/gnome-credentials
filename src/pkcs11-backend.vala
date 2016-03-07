namespace Credentials {
    class Interaction : GLib.TlsInteraction {
    }

    class Pkcs11Item : Item {
        Pkcs11PrivateKey _content;
        public Pkcs11PrivateKey content {
            construct set {
                this._content = value;
            }
        }

        public override string get_label () {
            return this._content.get_label ();
        }

        public override async void delete (GLib.Cancellable? cancellable) throws GLib.Error {
            if (yield this._content.destroy_async (cancellable))
                collection.item_removed (this);
        }

        public override async void load_content (GLib.Cancellable? cancellable) throws GLib.Error {
        }

        public Pkcs11Item (Collection collection, Pkcs11PrivateKey content) {
            Object (collection: collection, content: content);
        }

        public override int compare (Item other) {
            // FIXME
            return 0;
        }

        public override bool match (string[] words) {
            // FIXME
            return false;
        }
    }

    class Pkcs11Collection : Collection {
		static const ulong[] PRIVATE_KEY_ATTRS = {
			CKA.MODULUS_BITS,
			CKA.ID,
			CKA.LABEL,
			CKA.CLASS,
			CKA.KEY_TYPE,
			CKA.MODIFIABLE
		};

        GLib.HashTable<Gck.Attribute,Pkcs11Item> _items;
        GLib.HashTable<ulong?, GLib.Object> _handle_to_object;

        Gck.Slot _content;
        public Gck.Slot content {
            construct set {
                this._content = value;
            }
        }

        Gck.Session? _session;

        public override string item_type {
            get {
                return _("Private Key");
            }
        }

        public override bool locked {
            get {
                // FIXME
                return false;
            }
        }

        public string get_label () {
			var token = this._content.get_token_info();
			if (token == null)
				return _("Unknown");
			return token.label;
        }

        bool is_logged_in () {
            if (this._session == null)
                return false;
            var info = this._session.get_info();
            if (info == null)
                return false;
            return info.state == CKS.RW_USER_FUNCTIONS ||
                info.state == CKS.RO_USER_FUNCTIONS ||
                info.state == CKS.RW_SO_FUNCTIONS;
        }

        Gck.SessionOptions calculate_session_options () {
            var info = this._content.get_token_info ();
            if ((info.flags & CKF.WRITE_PROTECTED) == CKF.WRITE_PROTECTED)
                return Gck.SessionOptions.READ_ONLY;
            else
                return Gck.SessionOptions.READ_WRITE;
        }

        async void ensure_session (GLib.Cancellable? cancellable) throws GLib.Error {
            if (this._session == null) {
                var options = calculate_session_options ();
                this._session = yield this._content.open_session_async (
                    options | Gck.SessionOptions.LOGIN_USER,
                    cancellable);
                this._session.set_interaction (new Interaction ());
            }
        }

        public override async void unlock (GLib.TlsInteraction? interaction,
                                           GLib.Cancellable? cancellable) throws GLib.Error
        {
            if (!is_logged_in ()) {
                yield ensure_session (cancellable);
                yield this._session.login_interactive_async (CKU.USER,
                                                             interaction,
                                                             cancellable);
            }
        }

        public Pkcs11Collection (Backend backend, Gck.Slot content) {
            Object (backend: backend,
                    name: content.get_info ().slot_description,
                    content: content);
        }

        construct {
            this._items = new GLib.HashTable<Gck.Attribute,Pkcs11Item> (Gck.Attribute.hash,
                                                                        Gck.Attribute.equal);
            this._handle_to_object = new GLib.HashTable<ulong?,Gck.Object> (GLib.int64_hash, GLib.int64_equal);
        }

        public override async void load_items (GLib.Cancellable? cancellable) throws GLib.Error {
            var builder = new Gck.Builder (Gck.BuilderFlags.NONE);
            builder.add_boolean (CKA.TOKEN, true);
            builder.add_ulong(CKA.CLASS, CKO.PRIVATE_KEY);

            yield ensure_session (cancellable);
            var enumerator = this._session.enumerate_objects (builder.end ());
            enumerator.set_object_type (typeof (Pkcs11PrivateKey),
                                        PRIVATE_KEY_ATTRS);

            while (true) {
                var objects = yield enumerator.next_async (16, cancellable);

                foreach (var object in objects) {
                    if (!(object is Gck.Object && object is Gck.ObjectCache))
                        continue;

                    var handle = ((Gck.Object) object).handle;
                    this._handle_to_object.replace (handle, object);

                    var attributes = ((Gck.ObjectCache) object).attributes;
                    if (attributes != null) {
                        Gck.Attribute? attribute = attributes.find (CKA.ID);
                        if (attribute != null) {
                            var item = new Pkcs11Item (this, (Pkcs11PrivateKey) object);
                            this._items.insert (attribute, item);
                            item_added (item);
                        }
                    }
                }
            }
        }

        public override GLib.List<Item> get_items () {
            GLib.List<Item> items = null;
            var iter = GLib.HashTableIter<Gck.Attribute,Pkcs11Item> (this._items);
            Pkcs11Item item;
            while (iter.next (null, out item)) {
                items.append (item);
            }
            return items;
        }

        public override int compare (Collection other) {
            var difference = backend.compare (((Collection) other).backend);
            if (difference != 0)
                return difference;

            var label = this.get_label ();
            var other_label = ((Pkcs11Collection) other).get_label ();

            return GLib.strcmp (label, other_label);
        }
    }

    class Pkcs11Backend : Backend {
        GLib.HashTable<Gck.Slot,Pkcs11Collection> _collections;

        public override bool has_locked {
            get {
                return false;
            }
        }

        construct {
            _collections = new GLib.HashTable<Gck.Slot,Pkcs11Collection> (Gck.Slot.hash, Gck.Slot.equal);
        }

        public Pkcs11Backend (string name) {
            Object (name: name);
        }

        public override async void load_collections (GLib.Cancellable? cancellable) throws GLib.Error {
            var modules = yield Gck.modules_initialize_registered_async (cancellable);
            var slots = Gck.modules_get_slots (modules, true);
            foreach (var slot in slots) {
                var token = slot.get_token_info ();
                if (token == null)
                    continue;

                var collection = new Pkcs11Collection (this, slot);
                this._collections.insert (slot, collection);
                collection_added (collection);
            }
        }

        public override GLib.List<Collection> get_collections () {
            GLib.List<Collection> collections = null;
            var iter = GLib.HashTableIter<Gck.Slot,Pkcs11Collection> (this._collections);
            Pkcs11Collection collection;
            while (iter.next (null, out collection)) {
                collections.append (collection);
            }
            return collections;
        }

        public override int compare (Backend other) {
            return 0;
        }
    }
}
