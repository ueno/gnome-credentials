namespace Credentials {
    interface SecretAttributeFormatter : GLib.Object {
        public abstract string format (string attribute);
    }

    class SecretAttributeFormatterDomain : GLib.Object, SecretAttributeFormatter {
        public string format (string attribute) {
            return Utils.format_domain (attribute);
        }
    }

    class SecretAttributeFormatterSimple : GLib.Object, SecretAttributeFormatter {
        public string format (string attribute) {
            return attribute;
        }
    }

    interface SecretSchema : GLib.Object {
        public struct Attribute {
            public string name;
            public string label;
            public Attribute (string name, string label) {
                this.name = name;
                this.label = label;
            }
        }

        public abstract SecretUse use { get; }
        public abstract unowned GLib.List<Attribute?> get_attributes ();

        public abstract string? get_desktop_id (SecretItem item);
        public abstract string? get_attribute (SecretItem item, string name);
        public abstract string format_attribute (string name, string value);
        public abstract string get_title (SecretItem item);
        public abstract string? get_secondary_title (SecretItem item);
        public abstract bool is_valid (SecretItem item);
    }

    abstract class SecretSchemaBase : GLib.Object, SecretSchema {
        GLib.List<SecretSchema.Attribute?> _attributes;
        GLib.HashTable<string,SecretAttributeFormatter> _formatters;

        construct {
            this._attributes = null;
            this._formatters = new GLib.HashTable<string,SecretAttributeFormatter> (str_hash, str_equal);
        }

        public virtual SecretUse use {
            get {
                return SecretUse.INVALID;
            }
        }

        public virtual unowned GLib.List<SecretSchema.Attribute?> get_attributes () {
            return this._attributes;
        }

        public virtual string? get_desktop_id (SecretItem item) {
            return null;
        }

        public virtual string? get_attribute (SecretItem item, string name) {
            var attributes = item.get_attributes ();
            return attributes.lookup (name);
        }

        public virtual string format_attribute (string name, string value) {
            var formatter = this._formatters.lookup (name);
            return_val_if_fail (formatter != null, null);
            return formatter.format (value);
        }

        protected virtual void register_attribute (SecretSchema.Attribute attribute,
                                                   SecretAttributeFormatter formatter)
        {
            this._attributes.append (attribute);
            this._formatters.insert (attribute.name, formatter);
        }

        string format_use (SecretUse use) {
            var enum_class = (EnumClass) typeof (SecretUse).class_ref ();
            var enum_value = enum_class.get_value (use);
            return enum_value.value_nick;
        }

        public virtual string get_title (SecretItem item) {
            return format_use (item.use);
        }

        public virtual string? get_secondary_title (SecretItem item) {
            return null;
        }

        public virtual bool is_valid (SecretItem item) {
            return true;
        }
    }

    abstract class SecretSchemaNetwork : SecretSchemaBase {
        public override SecretUse use {
            get {
                return SecretUse.NETWORK;
            }
        }
    }

    abstract class SecretSchemaWebsite : SecretSchemaNetwork {
        public override SecretUse use {
            get {
                return SecretUse.WEBSITE;
            }
        }
    }

    class SecretSchemaEpiphany : SecretSchemaWebsite {
        const string ATTR_URI = "uri";
        const string ATTR_USERNAME = "username";

        public override string? get_desktop_id (SecretItem item) {
            return "epiphany.desktop";
        }

        construct {
            SecretSchema.Attribute attr;

            attr = SecretSchema.Attribute (ATTR_URI, N_("URL"));
            register_attribute (attr, new SecretAttributeFormatterDomain ());

            attr = SecretSchema.Attribute (ATTR_USERNAME, N_("Username"));
            register_attribute (attr, new SecretAttributeFormatterSimple ());
        }

        public override string get_title (SecretItem item) {
            var value = get_attribute (item, ATTR_URI);
            return_val_if_fail (value != null, "");
            return format_attribute (ATTR_URI, value);
        }

        public override string? get_secondary_title (SecretItem item) {
            var value = get_attribute (item, ATTR_USERNAME);
            return_val_if_fail (value != null, null);
            return format_attribute (ATTR_USERNAME, value);
        }
    }

    class SecretSchemaChrome : SecretSchemaWebsite {
        const string ATTR_ORIGIN_URI = "origin_uri";

        construct {
            SecretSchema.Attribute attr;

            attr = SecretSchema.Attribute (ATTR_ORIGIN_URI, N_("URL"));
            register_attribute (attr, new SecretAttributeFormatterDomain ());
        }

        public override string get_title (SecretItem item) {
            var value = get_attribute (item, ATTR_ORIGIN_URI);
            return_val_if_fail (value != null, "");
            return format_attribute (ATTR_ORIGIN_URI, value);
        }
    }

    class SecretSchemaNetworkPassword : SecretSchemaNetwork {
        const string ATTR_DOMAIN = "domain";
        const string ATTR_USER = "user";

        construct {
            SecretSchema.Attribute attr;

            attr = SecretSchema.Attribute (ATTR_DOMAIN, N_("Domain"));
            register_attribute (attr, new SecretAttributeFormatterDomain ());

            attr = SecretSchema.Attribute (ATTR_USER, N_("Username"));
            register_attribute (attr, new SecretAttributeFormatterSimple ());
        }

        public override string get_title (SecretItem item) {
            var value = get_attribute (item, ATTR_DOMAIN);
            return_val_if_fail (value != null, "");
            return format_attribute (ATTR_DOMAIN, value);
        }

        public override string? get_secondary_title (SecretItem item) {
            var value = get_attribute (item, ATTR_USER);
            return_val_if_fail (value != null, null);
            return format_attribute (ATTR_USER, value);
        }
    }

    class SecretSchemaGoa : SecretSchemaNetwork {
        const string ATTR_PROVIDER = "provider";
        const string ATTR_IDENTITY = "identity";

        public Goa.Client client { get; construct set; }
        GLib.HashTable<string,Goa.Account> _accounts;

        public SecretSchemaGoa (Goa.Client client) {
            Object (client: client);
        }

        construct {
            SecretSchema.Attribute attr;

            attr = SecretSchema.Attribute (ATTR_PROVIDER, _("Provider"));
            register_attribute (attr, new SecretAttributeFormatterSimple ());

            attr = SecretSchema.Attribute (ATTR_IDENTITY, _("Identity"));
            register_attribute (attr, new SecretAttributeFormatterSimple ());
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
            return_val_if_fail (value != null, null);

            var index = value.last_index_of (":");
            return_val_if_fail (index >= 0, null);

            return this._accounts.lookup (value[index + 1 : value.length]);
        }

        public override string? get_attribute (SecretItem item, string name) {
            var account = get_goa_account (item);
            return_val_if_fail (account != null, null);

            if (name == ATTR_PROVIDER)
                return account.provider_name;
            else if (name == ATTR_IDENTITY)
                return account.presentation_identity;

            return_val_if_reached (null);
        }

        public override string get_title (SecretItem item) {
            var value = get_attribute (item, ATTR_PROVIDER);
            return_val_if_fail (value != null, "");
            return format_attribute (ATTR_PROVIDER, value);
        }

        public override string? get_secondary_title (SecretItem item) {
            var value = get_attribute (item, ATTR_IDENTITY);
            return_val_if_fail (value != null, null);
            return format_attribute (ATTR_IDENTITY, value);
        }

        public override bool is_valid (SecretItem item) {
            return get_goa_account (item) != null;
        }
    }
}
