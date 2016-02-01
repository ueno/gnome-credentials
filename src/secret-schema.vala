namespace Credentials {
    interface SecretSchema : GLib.Object {
        public abstract SecretUse use { get; }
        public abstract string? get_desktop_id (SecretItem item);
    }

    abstract class SecretSchemaBase : GLib.Object, SecretSchema {
        public virtual SecretUse use {
            get {
                return SecretUse.INVALID;
            }
        }

        public virtual string? get_desktop_id (SecretItem item) {
            return null;
        }
    }

    abstract class SecretSchemaNetwork : SecretSchemaBase {
        public override SecretUse use {
            get {
                return SecretUse.NETWORK;
            }
        }

        public virtual string? domain_label {
            get {
                return _("Domain");
            }
        }

        public virtual string? account_label {
            get {
                return _("Account");
            }
        }

        public virtual string? get_domain (SecretItem item) {
            return null;
        }

        public virtual string? get_account (SecretItem item) {
            return null;
        }

        public virtual string? format_domain (SecretItem item) {
            var domain = get_domain (item);
            if (domain == null)
                return null;
            var soup_uri = new Soup.URI (domain);
            if (soup_uri == null)
                return domain;
            var host = soup_uri.get_host ();

            try {
                return Soup.tld_get_base_domain (host);
            } catch (Error e) {
                return host;
            }
        }

        public virtual string? format_account (SecretItem item) {
            return get_account (item);
        }
    }

    abstract class SecretSchemaWebsite : SecretSchemaNetwork {
        public override SecretUse use {
            get {
                return SecretUse.WEBSITE;
            }
        }

        public override string? domain_label {
            get {
                return _("URL");
            }
        }

        public override string? account_label {
            get {
                return _("Username");
            }
        }

        public virtual string? get_uri (SecretItem item) {
            return null;
        }

        public override string? get_domain (SecretItem item) {
            return get_uri (item);
        }
    }

    class SecretSchemaEpiphany : SecretSchemaWebsite {
        public override string? get_desktop_id (SecretItem item) {
            return "epiphany.desktop";
        }

        public override string? get_uri (SecretItem item) {
            var attributes = item.get_attributes ();
            return attributes.lookup ("uri");
        }

        public override string? get_account (SecretItem item) {
            var attributes = item.get_attributes ();
            return attributes.lookup ("username");
        }
    }

    class SecretSchemaChrome : SecretSchemaWebsite {
        public override string? get_uri (SecretItem item) {
            var attributes = item.get_attributes ();
            return attributes.lookup ("origin_uri");
        }
    }

    class SecretSchemaGoa : SecretSchemaNetwork {
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

        Goa.Account? get_goa_account (SecretItem item) {
            var attributes = item.get_attributes ();
            var value = attributes.lookup ("goa-identity");
            if (value == null)
                return null;
            var index = value.last_index_of (":");
            if (index < 0)
                return null;
            return this._accounts.lookup (value[index + 1 : value.length]);
        }

        public override string? get_domain (SecretItem item) {
            var account = get_goa_account (item);
            if (account == null)
                return null;
            return account.provider_name;
        }

        public override string? get_account (SecretItem item) {
            var account = get_goa_account (item);
            if (account == null)
                return null;
            return account.presentation_identity;
        }
    }

    class SecretSchemaNetworkPassword : SecretSchemaNetwork {
        public override string? get_domain (SecretItem item) {
            var attributes = item.get_attributes ();
            return attributes.lookup ("domain");
        }

        public override string? get_account (SecretItem item) {
            var attributes = item.get_attributes ();
            var value = attributes.lookup ("user");
            return value;
        }
    }
}