namespace Credentials {
    enum SshKeyType {
        UNKNOWN,
        RSA,
        DSA,
        ECDSA,
        ED25519
    }

    errordomain SshError {
        FAILED,
        INVALID_FORMAT,
        NOT_SUPPORTED
    }

    abstract class SshPublicKey : GLib.Object {
        public string path { construct set; get; }
        public SshKeyType key_type { construct set; get; }
        public GLib.Bytes bytes { construct set; get; }
        public string comment { construct set; get; }
        public uint length { construct set; get; }

        public static SshPublicKey parse (string path,
                                          GLib.Bytes bytes) throws GLib.Error
        {
            size_t start_offset = 0;
            size_t end_offset = 0;

            for (; end_offset < bytes.get_size (); end_offset++) {
                if (bytes.get ((int) end_offset) == ' ')
                    break;
            }
            if (end_offset == bytes.get_size ())
                throw new SshError.INVALID_FORMAT ("no space after key type");

            var key_type_bytes = bytes.slice ((int) start_offset,
                                              (int) end_offset);
            var key_type_string = bytes_to_string (key_type_bytes);

            end_offset++;
            if (end_offset == bytes.get_size ())
                throw new SshError.INVALID_FORMAT ("no key data");

            start_offset = end_offset;
            for (; end_offset < bytes.get_size (); end_offset++) {
                if (bytes.get ((int) end_offset) == ' ')
                    break;
            }
            if (end_offset == bytes.get_size ())
                throw new SshError.INVALID_FORMAT ("no space after key data");

            var key_bytes = bytes.slice ((int) start_offset, (int) end_offset);
            var key_bytes_encoded = bytes_to_string (key_bytes);
            var key_bytes_decoded = GLib.Base64.decode (key_bytes_encoded);

            key_bytes = new GLib.Bytes (key_bytes_decoded);
            var next_offset = 0;
            var key_type_embedded = SshUtils.read_string (key_bytes,
                                                          ref next_offset);
            if (key_type_embedded != key_type_string)
                throw new SshError.INVALID_FORMAT ("key type mismatch");
            var key_type = SshUtils.key_type_from_string (key_type_string);
            if (key_type == SshKeyType.UNKNOWN)
                throw new SshError.INVALID_FORMAT ("unknown key type");

            end_offset++;
            if (end_offset == bytes.get_size ())
                throw new SshError.INVALID_FORMAT ("no comment");

            start_offset = end_offset;
            for (; end_offset < bytes.get_size (); end_offset++) {
                if (bytes.get ((int) end_offset) == '\n')
                    break;
            }

            var comment_bytes = bytes.slice ((int) start_offset,
                                             (int) end_offset);
            var comment = bytes_to_string (comment_bytes);

            switch (key_type) {
            case SshKeyType.RSA:
                return SshPublicKeyRSA.parse (path, key_type, key_bytes,
                                              comment);
            case SshKeyType.DSA:
                return SshPublicKeyDSA.parse (path, key_type, key_bytes,
                                              comment);
            case SshKeyType.ECDSA:
                return SshPublicKeyECDSA.parse (path, key_type, key_bytes,
                                                comment);
            case SshKeyType.ED25519:
                return SshPublicKeyED25519.parse (path, key_type, key_bytes,
                                                  comment);
            default:
                throw new SshError.NOT_SUPPORTED ("%s is not supported",
                                                  key_type_string);
            }
        }

        public GLib.Bytes to_bytes () {
            var space = new uint8[1] { ' ' };
            var newline = new uint8[1] { '\n' };
            var buffer = new GLib.ByteArray ();
            buffer.append (SshUtils.key_type_to_string (key_type).data);
            buffer.append (space);
            buffer.append (GLib.Base64.encode (bytes.get_data ()).data);
            buffer.append (space);
            buffer.append (comment.data);
            buffer.append (newline);
            return GLib.ByteArray.free_to_bytes (buffer);
        }

        public virtual string get_fingerprint () {
            return GLib.Checksum.compute_for_bytes (GLib.ChecksumType.MD5,
                                                    bytes);
        }
    }

    class SshPublicKeyRSA : SshPublicKey {
        GCrypt.MPI _public_exponent;
        GCrypt.MPI _modulus;

        SshPublicKeyRSA (string path,
                         SshKeyType key_type,
                         GLib.Bytes bytes,
                         string comment,
                         GCrypt.MPI public_exponent,
                         GCrypt.MPI modulus)
        {
            Object (path: path,
                    bytes: bytes,
                    key_type: key_type,
                    comment: comment,
                    length: modulus.get_nbits ());
            this._public_exponent = public_exponent.copy ();
            this._modulus = modulus.copy ();
        }

        public static SshPublicKey parse (string path,
                                          SshKeyType key_type,
                                          GLib.Bytes bytes,
                                          string comment)
            throws GLib.Error
        {
            var offset = 0;
            size_t n_scanned = 0;

            SshUtils.read_string (bytes, ref offset);
            var public_exponent = SshUtils.read_mpi (bytes, ref offset);
            var modulus = SshUtils.read_mpi (bytes, ref offset);

            return new SshPublicKeyRSA (path,
                                        key_type,
                                        bytes,
                                        comment,
                                        public_exponent,
                                        modulus);
        }
    }

    class SshPublicKeyDSA : SshPublicKey {
        public SshPublicKeyDSA (string path,
                                SshKeyType key_type,
                                GLib.Bytes bytes,
                                string comment,
                                uint length)
        {
            Object (path: path,
                    key_type: key_type,
                    bytes: bytes,
                    comment: comment,
                    length: length);
        }

        public static SshPublicKey parse (string path,
                                          SshKeyType key_type,
                                          GLib.Bytes bytes,
                                          string comment)
            throws GLib.Error
        {
            var offset = 0;
            size_t n_scanned = 0;

            SshUtils.read_string (bytes, ref offset);
            var p = SshUtils.read_mpi (bytes, ref offset);
            SshUtils.read_mpi (bytes, ref offset);
            SshUtils.read_mpi (bytes, ref offset);
            SshUtils.read_mpi (bytes, ref offset);

            return new SshPublicKeyDSA (path,
                                        key_type,
                                        bytes,
                                        comment,
                                        p.get_nbits ());
        }
    }

    class SshPublicKeyECDSA : SshPublicKey {
        public SshPublicKeyECDSA (string path,
                                  SshKeyType key_type,
                                  GLib.Bytes bytes,
                                  string comment,
                                  uint length)
        {
            Object (path: path,
                    key_type: key_type,
                    bytes: bytes,
                    comment: comment,
                    length: length);
        }

        public static SshPublicKey parse (string path,
                                          SshKeyType key_type,
                                          GLib.Bytes bytes,
                                          string comment)
            throws GLib.Error
        {
            var offset = 0;
            size_t n_scanned = 0;

            SshUtils.read_string (bytes, ref offset);
            var curve_name = SshUtils.read_string (bytes, ref offset);
            var curve_nid = SshUtils.curve_name_to_nid (curve_name);
            if (curve_nid != SshUtils.key_type_to_curve_nid (key_type))
                throw new SshError.FAILED ("invalid key format");
            var length = SshUtils.curve_nid_to_length (curve_nid);
            return new SshPublicKeyECDSA (path,
                                          key_type,
                                          bytes,
                                          comment,
                                          length);
        }
    }

    class SshPublicKeyED25519 : SshPublicKey {
        public SshPublicKeyED25519 (string path,
                                    SshKeyType key_type,
                                    GLib.Bytes bytes,
                                    string comment,
                                    uint length)
        {
            Object (path: path,
                    key_type: key_type,
                    bytes: bytes,
                    comment: comment,
                    length: length);
        }

        public static SshPublicKey parse (string path,
                                          SshKeyType key_type,
                                          GLib.Bytes bytes,
                                          string comment)
            throws GLib.Error
        {
            return new SshPublicKeyED25519 (path,
                                            key_type,
                                            bytes,
                                            comment,
                                            256);
        }
    }

    namespace SshNID {
        const int UNDEFINED = 0;
        const int X9_62_PRIME256V1 = 415;
        const int SECP384R1 = 715;
        const int SECP521R1 = 716;
    }

    namespace SshUtils {
        static uint read_length (GLib.Bytes bytes,
                                 ref int offset) throws GLib.Error
        {
            if (bytes.get_size () - offset < 4)
                throw new SshError.INVALID_FORMAT ("premature end of data");

            var result = ((bytes.get (offset) << 24) |
                          (bytes.get (offset + 1) << 16) |
                          (bytes.get (offset + 2) << 8) |
                          bytes.get (offset + 3));
            offset += 4;
            return result;
        }

        static string read_string (GLib.Bytes bytes,
                                   ref int offset) throws GLib.Error
        {
            var length = read_length (bytes, ref offset);
            if (bytes.get_size () - offset < length)
                throw new SshError.FAILED ("premature end of data");

            var result = bytes.slice (offset, offset + (int) length);
            offset += (int) length;
            return bytes_to_string (result);
        }

        static GCrypt.MPI read_mpi (GLib.Bytes bytes,
                                    ref int offset) throws GLib.Error
        {
            GCrypt.MPI result;
            size_t n_scanned = 0;

            var slice = bytes.slice (offset, (int) bytes.get_size ());
            var err = GCrypt.MPI.scan (out result,
                                       GCrypt.MPI.Format.SSH,
                                       slice.get_data (),
                                       slice.get_size (),
                                       out n_scanned);
            if (err != 0)
                throw new SshError.FAILED ("premature end of data");
            offset += (int) n_scanned;
            return result;
        }

        struct KeyTypeEntry {
            string name;
            SshKeyType type;
            int nid;
        }

        static const KeyTypeEntry[] key_types = {
            { "ssh-ed25519", SshKeyType.ED25519,
              SshNID.UNDEFINED },
            { "ssh-rsa", SshKeyType.RSA,
              SshNID.UNDEFINED },
            { "ssh-dss", SshKeyType.DSA,
              SshNID.UNDEFINED },
            { "ecdsa-sha2-nistp256", SshKeyType.ECDSA,
              SshNID.X9_62_PRIME256V1 },
            { "ecdsa-sha2-nistp384", SshKeyType.ECDSA,
              SshNID.SECP384R1 },
            { "ecdsa-sha2-nistp521", SshKeyType.ECDSA,
              SshNID.SECP521R1 }
        };

        static uint curve_nid_to_length (int nid) {
            switch (nid) {
            case SshNID.X9_62_PRIME256V1:
                return 256;
            case SshNID.SECP384R1:
                return 384;
            case SshNID.SECP521R1:
                return 521;
            default:
                return_val_if_reached (0);
            }
        }

        static SshKeyType key_type_from_string (string name) {
            foreach (var entry in key_types) {
                if (entry.name == name)
                    return entry.type;
            }
            return_val_if_reached (SshKeyType.UNKNOWN);
        }

        static string key_type_to_string (SshKeyType type) {
            foreach (var entry in key_types) {
                if (entry.type == type)
                    return entry.name;
            }
            return_val_if_reached (null);
        }

        static int curve_name_to_nid (string name) {
            if (name == "nistp256")
                return SshNID.X9_62_PRIME256V1;
            else if (name == "nistp384")
                return SshNID.SECP384R1;
            else if (name == "nistp521")
                return SshNID.SECP521R1;
            else
                return_val_if_reached (SshNID.UNDEFINED);
        }

        static int key_type_to_curve_nid (SshKeyType type) {
            foreach (var entry in key_types) {
                if (entry.type == type)
                    return entry.nid;
            }
            return_val_if_reached (SshNID.UNDEFINED);
        }

        static string format_key_type (SshKeyType key_type) {
            switch (key_type) {
            case SshKeyType.RSA:
                return _("RSA");
            case SshKeyType.DSA:
                return _("DSA");
            case SshKeyType.ECDSA:
                return _("ECDSA");
            case SshKeyType.ED25519:
                return _("Ed25519");
            default:
                return _("Unknown");
            }
        }
    }
}
