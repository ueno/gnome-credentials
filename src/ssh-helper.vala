namespace Credentials {
    namespace SshUtils {
        static string format_key_type (ulong key_type) {
            switch (key_type) {
            case CKK.RSA:
                return _("RSA");
            case CKK.DSA:
                return _("DSA");
            case CKK.ECDSA:
                return _("ECDSA");
            default:
                return _("Unknown");
            }
        }

        static uint compute_key_size (ulong key_type,
                                      Gck.Attributes attributes)
        {
            switch (key_type) {
            case CKK.RSA:
            {
                var attribute = attributes.find (CKA.MODULUS);
                return (uint) attribute.get_data ().length / 8 * 8 * 8;
            }
            case CKK.DSA:
            {
                var attribute = attributes.find (CKA.PRIME);
                return (uint) attribute.get_data ().length / 8 * 8 * 8;
            }
            case CKK.ECDSA:
                // FIXME: check curve in CKA.EC_PARAMS
                return 0;
            default:
                return 0;
            }
        }
    }
}
