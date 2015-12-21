namespace Credentials {
    interface SecretSchema : GLib.Object {
        public abstract SecretUse use { get; }
        public abstract string? format_domain (SecretItem item);
        public abstract string? format_account (SecretItem item);
    }

    class SecretSchemaDefault : GLib.Object, SecretSchema {
        public virtual SecretUse use {
            get {
                return SecretUse.INVALID;
            }
        }

        public virtual string? format_domain (SecretItem item) {
            return null;
        }

        public virtual string? format_account (SecretItem item) {
            return null;
        }
    }

    class SecretSchemaEpiphany : SecretSchemaDefault {
        public override SecretUse use {
            get {
                return SecretUse.WEBSITE;
            }
        }

        public override string? format_domain (SecretItem item) {
            var attributes = item.get_attributes ();
            var value = attributes.lookup ("uri");
            if (value == null)
                return null;

            var uri = new Soup.URI (value);
            try {
                return Soup.tld_get_base_domain (uri.get_host ());
            } catch (Error e) {
                return uri.get_host ();
            }
        }

        public override string? format_account (SecretItem item) {
            var attributes = item.get_attributes ();
            var value = attributes.lookup ("username");
            return value;
        }
    }

    class SecretSchemaChrome : SecretSchemaDefault {
        public override SecretUse use {
            get {
                return SecretUse.WEBSITE;
            }
        }

        public override string? format_domain (SecretItem item) {
            var attributes = item.get_attributes ();
            var value = attributes.lookup ("origin_uri");
            if (value == null)
                return null;

            var uri = new Soup.URI (value);
            try {
                return Soup.tld_get_base_domain (uri.get_host ());
            } catch (Error e) {
                return uri.get_host ();
            }
        }
    }

    class SecretSchemaGoa : SecretSchemaDefault {
        public override SecretUse use {
            get {
                return SecretUse.NETWORK;
            }
        }

        public Goa.Client client { get; construct set; }
        GLib.HashTable<string,Goa.Account> _accounts;

        public SecretSchemaGoa (Goa.Client client) {
            Object (client: client);
        }

        public override void constructed () {
            base.constructed ();
            this._accounts = new GLib.HashTable<string,Goa.Account> (GLib.str_hash, GLib.str_equal);
            foreach (var object in client.get_accounts ()) {
                var account = object.get_account ();
                this._accounts.insert (account.id, account);
            }
        }

        Goa.Account? get_account (SecretItem item) {
            var attributes = item.get_attributes ();
            var value = attributes.lookup ("goa-identity");
            if (value == null)
                return null;
            var index = value.last_index_of (":");
            if (index < 0)
                return null;
            return this._accounts.lookup (value[index + 1 : value.length]);
        }

        public override string? format_domain (SecretItem item) {
            var account = get_account (item);
            return account.provider_name;
        }

        public override string? format_account (SecretItem item) {
            var account = get_account (item);
            return account.presentation_identity;
        }
    }

    class SecretSchemaNetworkPassword : SecretSchemaDefault {
        public override string? format_domain (SecretItem item) {
            var attributes = item.get_attributes ();
            var value = attributes.lookup ("domain");
            if (value == null)
                return null;

            var uri = new Soup.URI (value);
            try {
                return Soup.tld_get_base_domain (uri.get_host ());
            } catch (Error e) {
                return uri.get_host ();
            }
        }

        public override string? format_account (SecretItem item) {
            var attributes = item.get_attributes ();
            var value = attributes.lookup ("user");
            return value;
        }
    }
}