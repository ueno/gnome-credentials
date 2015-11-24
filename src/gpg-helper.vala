namespace Credentials {
    namespace GpgUtils {
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
    }

    abstract class GpgEditCommand : GLib.Object {
        protected abstract void action (uint state, int fd) throws GLib.Error;
        protected abstract uint transit (uint state,
                                         GGpg.StatusCode status,
                                         string args) throws GLib.Error;

        public static const string QUIT = "quit";
        public static const string YES = "Y";
        public static const string NO = "N";
        public static const string PROMPT = "keyedit.prompt";
        public static const string SAVE = "keyedit.save.okay";

        public uint state { set; get; }

        protected void send_string (int fd, string s) throws GLib.Error {
            ssize_t retval = 0;

            do {
                retval = Posix.write (fd, s, s.length);
            } while (retval < 0 && Posix.errno == Posix.EINTR);

            if (retval < 0)
                throw new GLib.IOError.FAILED ("failed to send string");
        }

        public bool edit_callback (GGpg.StatusCode status,
                                   string args,
                                   int fd) throws GLib.Error
        {
            // The gpg executable returned a status code which is
            // unknown to GPGME.
            if ((int) status == -1)
                return true;

            switch (status) {
            case GGpg.StatusCode.EOF:
            case GGpg.StatusCode.GOT_IT:
            case GGpg.StatusCode.NEED_PASSPHRASE:
            case GGpg.StatusCode.GOOD_PASSPHRASE:
            case GGpg.StatusCode.BAD_PASSPHRASE:
            case GGpg.StatusCode.USERID_HINT:
            case GGpg.StatusCode.SIGEXPIRED:
            case GGpg.StatusCode.KEYEXPIRED:
            case GGpg.StatusCode.PROGRESS:
            case GGpg.StatusCode.KEY_CREATED:
            case GGpg.StatusCode.ALREADY_SIGNED:
            case GGpg.StatusCode.MISSING_PASSPHRASE:
            case GGpg.StatusCode.PINENTRY_LAUNCHED:
                return true;
            default:
                this.state = transit (this.state, status, args);
                action (this.state, fd);
                return true;
            }
        }
    }

    enum GpgAddUidState {
        START,
        COMMAND,
        NAME,
        EMAIL,
        COMMENT,
        QUIT,
        SAVE,
        ERROR
    }

    class GpgAddUidEditCommand : GpgEditCommand {
        public string name { construct set; get; }
        public string email { construct set; get; }
        public string comment { construct set; get; }

        public GpgAddUidEditCommand (string name,
                                     string email,
                                     string comment)
        {
            Object (name: name, email: email, comment: comment);
        }

        public override void action (uint state, int fd) throws GLib.Error {
            switch (state) {
            case GpgAddUidState.COMMAND:
                send_string (fd, "adduid");
                break;

            case GpgAddUidState.NAME:
                send_string (fd, name);
                break;

            case GpgAddUidState.EMAIL:
                send_string (fd, email);
                break;

            case GpgAddUidState.COMMENT:
                send_string (fd, comment);
                break;

            case GpgAddUidState.QUIT:
                send_string (fd, QUIT);
                break;

            case GpgAddUidState.SAVE:
                send_string (fd, YES);
                break;

            default:
                throw new GGpg.Error.GENERAL ("invalid state in adduid command");
            }
            send_string (fd, "\n");
        }

        public override uint transit (uint state,
                                      GGpg.StatusCode status,
                                      string args) throws GLib.Error
        {
            switch (state) {
            case GpgAddUidState.START:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgAddUidState.COMMAND;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgAddUidState.COMMAND:
                if (status == GGpg.StatusCode.GET_LINE &&
                    args == "keygen.name")
                    return GpgAddUidState.NAME;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgAddUidState.NAME:
                if (status == GGpg.StatusCode.GET_LINE &&
                    args == "keygen.email")
                    return GpgAddUidState.EMAIL;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgAddUidState.EMAIL:
                if (status == GGpg.StatusCode.GET_LINE &&
                    args == "keygen.comment")
                    return GpgAddUidState.COMMENT;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgAddUidState.COMMENT:
                return GpgAddUidState.QUIT;

            case GpgAddUidState.QUIT:
                if (status == GGpg.StatusCode.GET_BOOL && args == SAVE)
                    return GpgAddUidState.SAVE;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgAddUidState.ERROR:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgAddUidState.QUIT;
                else
                    return GpgAddUidState.ERROR;
            default:
                throw new GGpg.Error.GENERAL ("invalid state %u", state);
            }
        }
    }

    enum GpgDelUidState {
        START,
        SELECT,
        COMMAND,
        CONFIRM,
        QUIT,
        SAVE,
        ERROR
    }

    class GpgDelUidEditCommand : GpgEditCommand {
        public uint index { construct set; get; }

        public GpgDelUidEditCommand (uint index) {
            Object (index: index);
        }

        public override void action (uint state, int fd) throws GLib.Error {
            switch (state) {
            case GpgDelUidState.SELECT:
                send_string (fd, "uid %u".printf (index));
                break;
            case GpgDelUidState.COMMAND:
                send_string (fd, "deluid");
                break;
            case GpgDelUidState.CONFIRM:
                send_string (fd, YES);
                break;
            case GpgDelUidState.QUIT:
                send_string (fd, QUIT);
                break;
            case GpgDelUidState.SAVE:
                send_string (fd, YES);
                break;
            default:
                throw new GGpg.Error.GENERAL ("invalid state in deluid command");
            }
            send_string (fd, "\n");
        }

        protected override uint transit (uint state,
                                         GGpg.StatusCode status,
                                         string args) throws GLib.Error
        {
            switch (state) {
            case GpgDelUidState.START:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgDelUidState.SELECT;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgDelUidState.SELECT:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgDelUidState.COMMAND;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgDelUidState.COMMAND:
                if (status == GGpg.StatusCode.GET_BOOL &&
                    args == "keyedit.remove.uid.okay")
                    return GpgDelUidState.CONFIRM;
                else if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgDelUidState.QUIT;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgDelUidState.CONFIRM:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgDelUidState.QUIT;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgDelUidState.QUIT:
                if (status == GGpg.StatusCode.GET_BOOL && args == SAVE)
                    return GpgDelUidState.SAVE;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgDelUidState.ERROR:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgDelUidState.QUIT;
                else
                    return GpgDelUidState.ERROR;

            default:
                throw new GGpg.Error.GENERAL ("invalid state %u", state);
            }
        }
    }

    enum GpgDelKeyState {
        START,
        SELECT,
        COMMAND,
        CONFIRM,
        QUIT,
        ERROR
    }

    class GpgDelKeyEditCommand : GpgEditCommand {
        public uint index { construct set; get; }

        public GpgDelKeyEditCommand (uint index) {
            Object (index: index);
        }

        public override void action (uint state, int fd) throws GLib.Error {
            switch (state) {
            case GpgDelKeyState.SELECT:
                send_string (fd, "key %u".printf (index));
                break;
            case GpgDelKeyState.COMMAND:
                send_string (fd, "delkey");
                break;
            case GpgDelKeyState.CONFIRM:
                send_string (fd, YES);
                break;
            case GpgDelKeyState.QUIT:
                send_string (fd, QUIT);
                break;
            default:
                throw new GGpg.Error.GENERAL ("invalid state in deluid command");
            }
            send_string (fd, "\n");
        }

        protected override uint transit (uint state,
                                         GGpg.StatusCode status,
                                         string args) throws GLib.Error
        {
            switch (state) {
            case GpgDelKeyState.START:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgDelKeyState.SELECT;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgDelKeyState.SELECT:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgDelKeyState.COMMAND;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgDelKeyState.COMMAND:
                if (status == GGpg.StatusCode.GET_BOOL &&
                    args == "keyedit.remove.uid.okay")
                    return GpgDelKeyState.CONFIRM;
                else if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgDelKeyState.QUIT;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgDelKeyState.CONFIRM:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgDelKeyState.QUIT;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgDelKeyState.QUIT:
                if (status == GGpg.StatusCode.GET_BOOL && args == SAVE)
                    return GpgDelKeyState.CONFIRM;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgDelKeyState.ERROR:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgDelKeyState.QUIT;
                else
                    return GpgDelKeyState.ERROR;

            default:
                throw new GGpg.Error.GENERAL ("invalid state %u", state);
            }
        }
    }
}
