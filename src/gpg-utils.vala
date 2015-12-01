namespace Credentials.GpgUtils {
    static string format_generator_progress_type (string what) {
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

    static string format_protocol (GGpg.Protocol protocol) {
        switch (protocol) {
        case GGpg.Protocol.OPENPGP:
            return _("PGP");
        case GGpg.Protocol.CMS:
            return _("CMS");
        default:
            return_val_if_reached (_("Unknown"));
        }
    }

    static string format_pubkey_algo (GGpg.PubkeyAlgo pubkey_algo) {
        switch (pubkey_algo) {
        case GGpg.PubkeyAlgo.RSA:
        case GGpg.PubkeyAlgo.RSA_E:
        case GGpg.PubkeyAlgo.RSA_S:
            return _("RSA");
        case GGpg.PubkeyAlgo.ELG:
        case GGpg.PubkeyAlgo.ELG_E:
            return _("ElGamal");
        case GGpg.PubkeyAlgo.DSA:
            return _("DSA");
        case GGpg.PubkeyAlgo.ECDSA:
            return _("ECDSA");
        case GGpg.PubkeyAlgo.ECDH:
            return _("ECDH");
        default:
            return_val_if_reached (_("Unknown"));
        }
    }

    static string format_validity (GGpg.Validity validity) {
        switch (validity) {
        case GGpg.Validity.UNKNOWN:
            return _("Unknown");
        case GGpg.Validity.UNDEFINED:
            return _("Undefined");
        case GGpg.Validity.NEVER:
            return _("Never");
        case GGpg.Validity.MARGINAL:
            return _("Marginal");
        case GGpg.Validity.FULL:
            return _("Full");
        case GGpg.Validity.ULTIMATE:
            return _("Ultimate");
        default:
            return_val_if_reached (_("Invalid"));
        }
    }

    static string format_fingerprint (string fingerprint) {
        var builder = new GLib.StringBuilder ();
        for (var i = 0; i < fingerprint.length / 4; i++) {
            if (i > 0) {
                builder.append_c (' ');
                if (i % 5 == 0)
                    builder.append_c (' ');
            }
            builder.append (fingerprint[4 * i : 4 * i + 4]);
        }
        return builder.str;
    }

    static string format_expires (int64 expires) {
        if (expires == 0)
            return _("Forever");

        var date = new DateTime.from_unix_utc (expires);
        return date.to_local ().format ("%Y-%m-%d");
    }

    static string format_subkey_status (GGpg.SubkeyFlags flags) {
        string[] status = {};

        if ((flags & GGpg.SubkeyFlags.REVOKED) != 0)
            status += _("revoked");
        if ((flags & GGpg.SubkeyFlags.EXPIRED) != 0)
            status += _("expired");
        if ((flags & GGpg.SubkeyFlags.DISABLED) != 0)
            status += _("disabled");
        if ((flags & GGpg.SubkeyFlags.INVALID) != 0)
            status += _("invalid");

        if (status.length == 0)
            return _("enabled");

        return string.joinv (", ", status);
    }

    static string format_usage (GGpg.SubkeyFlags flags) {
        string[] uses = {};
        if ((flags & GGpg.SubkeyFlags.CAN_ENCRYPT) != 0)
            uses += _("encrypt");
        if ((flags & GGpg.SubkeyFlags.CAN_SIGN) != 0)
            uses += _("sign");
        if ((flags & GGpg.SubkeyFlags.CAN_AUTHENTICATE) != 0)
            uses += _("authenticate");
        if ((flags & GGpg.SubkeyFlags.CAN_CERTIFY) != 0)
            uses += _("certify");
        return string.joinv (", ", uses);
    }
}
