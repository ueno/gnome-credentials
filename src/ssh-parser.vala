namespace Credentials {
    class SshKey : GLib.Object {
        public string path { construct set; get; }
        public string magic { construct set; get; }
        public SshBlob blob { construct set; get; }
        public string comment { construct set; get; }
        public SshKeySpec spec { construct set; get; }
        public SshCurveSpec curve_spec { construct set; get; }

        public SshKey (string path, string magic, SshBlob blob, string comment,
                       SshKeySpec spec, SshCurveSpec? curve_spec)
        {
            Object (path: path, magic: magic, blob: blob, comment: comment,
                    spec: spec, curve_spec: curve_spec);
        }

        static const uint8[] SPACE = { ' ' };
        static const uint8[] NEWLINE = { '\n' };

        public GLib.Bytes to_bytes () {
            var buffer = new GLib.ByteArray ();
            buffer.append (magic.data);
            buffer.append (SPACE);
            buffer.append (GLib.Base64.encode (blob.to_bytes ().get_data ()).data);
            buffer.append (SPACE);
            buffer.append (comment.data);
            buffer.append (NEWLINE);
            return GLib.ByteArray.free_to_bytes (buffer);
        }

        public virtual string get_fingerprint () {
            return GLib.Checksum.compute_for_bytes (GLib.ChecksumType.MD5,
                                                    blob.to_bytes ());
        }
    }

    enum SshKeyType {
        RSA,
        DSA,
        ECDSA,
        ED25519
    }

    interface SshKeySpec : GLib.Object {
        public abstract SshKeyType key_type { get; }
        public abstract uint min_length { get; }
        public abstract uint max_length { get; }
        public abstract uint default_length { get; }

        public abstract string keygen_argument { get; }
        public abstract string default_filename { get; }
        public abstract string label { get; }
    }

    enum SshCurveType {
        X9_62_PRIME256V1,
        SECP384R1,
        SECP521R1
    }

    interface SshCurveSpec : GLib.Object {
        public abstract SshCurveType curve_type { get; }
        public abstract string name { get; }
        public abstract uint length { get; }
    }

    interface SshBlob : GLib.Object {
        public abstract uint length { get; }
        public abstract GLib.Bytes to_bytes ();
    }

    interface SshBlobParser : GLib.Object {
        public abstract SshBlob parse (GLib.Bytes bytes) throws GLib.Error;
    }

    class SshKeyParser : GLib.Object {
        GLib.HashTable<string,SshBlobParser> _blob_parsers;
        GLib.HashTable<string,SshKeySpec> _specs;
        GLib.HashTable<string,SshCurveSpec> _curve_specs;
        GLib.HashTable<SshKeyType,SshKeySpec> _type_to_spec;

        construct {
            this._blob_parsers =
                new GLib.HashTable<string,SshBlobParser> (GLib.str_hash,
                                                          GLib.str_equal);
            this._specs =
                new GLib.HashTable<string,SshKeySpec> (GLib.str_hash,
                                                       GLib.str_equal);
            this._curve_specs =
                new GLib.HashTable<string,SshCurveSpec> (GLib.str_hash,
                                                         GLib.str_equal);
            this._type_to_spec =
                new GLib.HashTable<SshKeyType,SshKeySpec> (null, null);

            register ("ssh-rsa", new SshKeySpecRsa (), null,
                      new SshBlobParserRsa ());
            register ("ssh-dss", new SshKeySpecDsa (), null,
                      new SshBlobParserDsa ());

            SshCurveSpec curve_spec;

            curve_spec = new SshCurveSpecNistp256 ();
            register ("ecdsa-sha2-nistp256",
                      new SshKeySpecEcdsa (), curve_spec,
                      new SshBlobParserEcdsa (curve_spec));
            curve_spec = new SshCurveSpecNistp384 ();
            register ("ecdsa-sha2-nistp384",
                      new SshKeySpecEcdsa (), curve_spec,
                      new SshBlobParserEcdsa (curve_spec));
            curve_spec = new SshCurveSpecNistp521 ();
            register ("ecdsa-sha2-nistp521",
                      new SshKeySpecEcdsa (), curve_spec,
                      new SshBlobParserEcdsa (curve_spec));

            register ("ssh-ed25519", new SshKeySpecEd25519 (), null,
                      new SshBlobParserEd25519 ());
        }

        public void register (string magic, SshKeySpec spec,
                              SshCurveSpec? curve_spec,
                              SshBlobParser parser)
        {
            this._blob_parsers.insert (magic, parser);
            this._specs.insert (magic, spec);
            this._type_to_spec.insert (spec.key_type, spec);
            if (curve_spec != null)
                this._curve_specs.insert (magic, curve_spec);
        }

        public SshKeySpec get_spec (SshKeyType type) {
            return this._type_to_spec.lookup (type);
        }

        public SshKey parse (string path,
                             GLib.Bytes bytes) throws GLib.Error
        {
            int start_offset = 0;
            int end_offset = 0;

            for (; end_offset < bytes.get_size (); end_offset++) {
                if (bytes.get (end_offset) == ' ')
                    break;
            }
            if (end_offset == bytes.get_size ())
                throw new SshError.INVALID_FORMAT ("no space after key type");

            var magic_bytes = bytes.slice (start_offset, end_offset);
            var magic_string = bytes_to_string (magic_bytes);

            end_offset++;
            if (end_offset == bytes.get_size ())
                throw new SshError.INVALID_FORMAT ("no key data");

            start_offset = end_offset;
            for (; end_offset < bytes.get_size (); end_offset++) {
                if (bytes.get (end_offset) == ' ')
                    break;
            }
            if (end_offset == bytes.get_size ())
                throw new SshError.INVALID_FORMAT ("no space after key data");

            var key_bytes = bytes.slice (start_offset, end_offset);
            var key_bytes_encoded = bytes_to_string (key_bytes);
            var key_bytes_decoded = GLib.Base64.decode (key_bytes_encoded);

            key_bytes = new GLib.Bytes (key_bytes_decoded);
            var next_offset = 0;
            var magic_string_embedded = SshUtils.read_string (key_bytes,
                                                              ref next_offset);
            if (magic_string_embedded != magic_string)
                throw new SshError.INVALID_FORMAT ("magic mismatch");

            end_offset++;
            if (end_offset == bytes.get_size ())
                throw new SshError.INVALID_FORMAT ("no comment");

            start_offset = end_offset;
            for (; end_offset < bytes.get_size (); end_offset++) {
                if (bytes.get (end_offset) == '\n')
                    break;
            }

            var comment_bytes = bytes.slice (start_offset, end_offset);
            var comment = bytes_to_string (comment_bytes);

            var blob_parser = this._blob_parsers.lookup (magic_string);
            if (blob_parser == null) {
                throw new SshError.NOT_SUPPORTED ("%s is not supported",
                                                  magic_string);
            }
            var blob = blob_parser.parse (key_bytes);
            var spec = this._specs.lookup (magic_string);
            var curve_spec = this._curve_specs.lookup (magic_string);
            return new SshKey (path, magic_string, blob, comment,
                               spec, curve_spec);
        }
    }

    class SshKeySpecRsa : SshKeySpec, GLib.Object {
        public SshKeyType key_type { get { return SshKeyType.RSA; } }
        public uint min_length { get { return 1024; } }
        public uint max_length { get { return 4096; } }
        public uint default_length { get { return 2048; } }

        public string keygen_argument { get { return "rsa"; } }
        public string default_filename { get { return "id_rsa"; } }
        public string label { get { return _("RSA"); } }
    }

    class SshBlobRsa : SshBlob, GLib.Object {
        GCrypt.MPI _public_exponent;
        GCrypt.MPI _modulus;

        public uint length { get { return this._modulus.get_nbits (); } }

        public SshBlobRsa (GCrypt.MPI public_exponent, GCrypt.MPI modulus) {
            this._public_exponent = public_exponent.copy ();
            this._modulus = modulus.copy ();
        }

        public GLib.Bytes to_bytes () {
            var array = new GLib.ByteArray ();

            SshUtils.write_mpi (array, this._public_exponent);
            SshUtils.write_mpi (array, this._modulus);

            return GLib.ByteArray.free_to_bytes (array);
        }
    }

    class SshBlobParserRsa : SshBlobParser, GLib.Object {
        public SshBlob parse (GLib.Bytes bytes) throws GLib.Error {
            var offset = 0;

            SshUtils.read_string (bytes, ref offset);
            var public_exponent = SshUtils.read_mpi (bytes, ref offset);
            var modulus = SshUtils.read_mpi (bytes, ref offset);

            return new SshBlobRsa (public_exponent, modulus);
        }
    }

    class SshKeySpecDsa : SshKeySpec, GLib.Object {
        public SshKeyType key_type { get { return SshKeyType.DSA; } }
        public uint min_length { get { return 1024; } }
        public uint max_length { get { return 3072; } }
        public uint default_length { get { return 2048; } }

        public string magic { get { return "ssh-dss"; } }
        public string keygen_argument { get { return "dsa"; } }
        public string default_filename { get { return "id_dsa"; } }
        public string label { get { return _("DSA"); } }
    }

    class SshBlobDsa : SshBlob, GLib.Object {
        GCrypt.MPI _p;
        GCrypt.MPI _q;
        GCrypt.MPI _g;
        GCrypt.MPI _public_key;

        public SshBlobDsa (GCrypt.MPI p, GCrypt.MPI q, GCrypt.MPI g,
                           GCrypt.MPI public_key)
        {
            this._p = p.copy ();
            this._q = q.copy ();
            this._g = g.copy ();
            this._public_key = public_key.copy ();
        }

        public uint length { get { return this._p.get_nbits (); } }

        public GLib.Bytes to_bytes () {
            var array = new GLib.ByteArray ();

            SshUtils.write_mpi (array, this._p);
            SshUtils.write_mpi (array, this._q);
            SshUtils.write_mpi (array, this._g);
            SshUtils.write_mpi (array, this._public_key);

            return GLib.ByteArray.free_to_bytes (array);
        }
    }

    class SshBlobParserDsa : SshBlobParser, GLib.Object {
        public SshBlob parse (GLib.Bytes bytes) throws GLib.Error {
            var offset = 0;

            SshUtils.read_string (bytes, ref offset);
            var p = SshUtils.read_mpi (bytes, ref offset);
            var q = SshUtils.read_mpi (bytes, ref offset);
            var g = SshUtils.read_mpi (bytes, ref offset);
            var public_key = SshUtils.read_mpi (bytes, ref offset);

            return new SshBlobDsa (p, q, g, public_key);
        }
    }

    class SshCurveSpecNistp256 : SshCurveSpec, GLib.Object {
        public SshCurveType curve_type {
            get {
                return SshCurveType.X9_62_PRIME256V1;
            }
        }

        public string name { get { return "nistp256"; } }
        public uint length { get { return 256; } }
    }

    class SshCurveSpecNistp384 : SshCurveSpec, GLib.Object {
        public SshCurveType curve_type {
            get {
                return SshCurveType.SECP384R1;
            }
        }

        public string name { get { return "nistp384"; } }
        public uint length { get { return 384; } }
    }

    class SshCurveSpecNistp521 : SshCurveSpec, GLib.Object {
        public SshCurveType curve_type {
            get {
                return SshCurveType.SECP521R1;
            }
        }

        public string name { get { return "nistp521"; } }
        public uint length { get { return 521; } }
    }

    class SshKeySpecEcdsa : SshKeySpec, GLib.Object {
        public SshKeyType key_type { get { return SshKeyType.ECDSA; } }
        public uint min_length { get { return 256; } }
        public uint max_length { get { return 521; } }
        public uint default_length { get { return 256; } }

        public string keygen_argument { get { return "ecdsa"; } }
        public string default_filename { get { return "id_ecdsa"; } }
        public string label { get { return _("ECDSA"); } }
    }

    class SshBlobEcdsa : SshBlob, GLib.Object {
        SshCurveSpec _spec;
        string _point;

        public SshBlobEcdsa (SshCurveSpec spec, string point) {
            this._spec = spec;
            this._point = point;
        }

        public uint length { get { return this._spec.length; } }

        public GLib.Bytes to_bytes () {
            var array = new GLib.ByteArray ();

            SshUtils.write_string (array, this._spec.name);
            SshUtils.write_string (array, this._point);

            return GLib.ByteArray.free_to_bytes (array);
        }
    }

    class SshBlobParserEcdsa : SshBlobParser, GLib.Object {
        SshCurveSpec _spec;

        public SshBlobParserEcdsa (SshCurveSpec spec) {
            this._spec = spec;
        }

        public SshBlob parse (GLib.Bytes bytes) throws GLib.Error {
            var offset = 0;

            SshUtils.read_string (bytes, ref offset);
            var name = SshUtils.read_string (bytes, ref offset);
            if (name != this._spec.name)
                throw new SshError.INVALID_FORMAT ("curve name mismatch");
            var point = SshUtils.read_string (bytes, ref offset);
            return new SshBlobEcdsa (this._spec, point);
        }
    }

    class SshKeySpecEd25519 : SshKeySpec, GLib.Object {
        public SshKeyType key_type { get { return SshKeyType.ED25519; } }
        public uint min_length { get { return 256; } }
        public uint max_length { get { return 256; } }
        public uint default_length { get { return 256; } }

        public string keygen_argument { get { return "ed25519"; } }
        public string default_filename { get { return "id_ed25519"; } }
        public string label { get { return _("Ed25519"); } }
    }

    class SshBlobEd25519 : SshBlob, GLib.Object {
        string _pk;

        public SshBlobEd25519 (string pk) {
            this._pk = pk;
        }

        public uint length { get { return 256; } }

        public GLib.Bytes to_bytes () {
            var array = new GLib.ByteArray ();

            SshUtils.write_string (array, this._pk);

            return GLib.ByteArray.free_to_bytes (array);
        }
    }

    class SshBlobParserEd25519 : SshBlobParser, GLib.Object {
        public SshBlob parse (GLib.Bytes bytes) throws GLib.Error {
            var offset = 0;

            SshUtils.read_string (bytes, ref offset);
            var pk = SshUtils.read_string (bytes, ref offset);
            return new SshBlobEd25519 (pk);
        }
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

        static void write_string (GLib.ByteArray array, string s) {
            array.append (s.data);
        }

        static void write_mpi (GLib.ByteArray array, GCrypt.MPI mpi) {
            size_t n_written = 0;

            mpi.print (GCrypt.MPI.Format.SSH, null, 0, out n_written);
            var data = new uchar[n_written];

            mpi.print (GCrypt.MPI.Format.SSH, data, n_written, out n_written);
            array.append (data);
        }
    }
}
