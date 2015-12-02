namespace Credentials {
    enum GpgExpirationFormat {
        NEVER = 0,
        DAYS = 1,
        WEEKS = 2,
        MONTHS = 3,
        YEARS = 4,
        DATE = 5
    }

    struct GpgExpirationSpec {
        GpgExpirationFormat format;
        int64 value;

        public GpgExpirationSpec (GpgExpirationFormat format,
                                  int64 value)
        {
            this.format = format;
            this.value = value;
        }

        public bool equal (GpgExpirationSpec spec) {
            return format == spec.format && value == spec.value;
        }

        public string to_string () {
            switch (format) {
            case GpgExpirationFormat.NEVER:
                return _("Forever");

            case GpgExpirationFormat.DAYS:
                return ngettext ("%d day", "%d days", (ulong) value).printf (value);

            case GpgExpirationFormat.WEEKS:
                return ngettext ("%d week", "%d weeks", (ulong) value).printf (value);

            case GpgExpirationFormat.MONTHS:
                return ngettext ("%d month", "%d months", (ulong) value).printf (value);

            case GpgExpirationFormat.YEARS:
                return ngettext ("%d year", "%d years", (ulong) value).printf (value);

            case GpgExpirationFormat.DATE:
                return new GLib.DateTime.from_unix_utc (value).to_local ().format ("%Y-%m-%d");
            }
            return_val_if_reached (null);
        }

        public string indicator () {
            switch (format) {
            case GpgExpirationFormat.NEVER:
                return "0";

            case GpgExpirationFormat.DAYS:
                return value.to_string ();

            case GpgExpirationFormat.WEEKS:
                return "%dw".printf ((int) value);

            case GpgExpirationFormat.MONTHS:
                return "%dm".printf ((int) value);

            case GpgExpirationFormat.YEARS:
                return "%dy".printf ((int) value);

            case GpgExpirationFormat.DATE:
                return new GLib.DateTime.from_unix_utc (value).format (
                    "%Y%m%dT%H%M%S");
            }
            return_val_if_reached (null);
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
                send_string (fd, "uid %u".printf (index + 1));
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

    enum GpgAddKeyState {
        START,
        COMMAND,
        TYPE,
        LENGTH,
        EXPIRES,
        QUIT,
        SAVE,
        ERROR
    }

    class GpgAddKeyEditCommand : GpgEditCommand {
        public GpgGeneratedKeyType key_type { construct set; get; default = GpgGeneratedKeyType.DSA_SIGN; }
        public uint length { construct set; get; }
        public GpgExpirationSpec expires { construct set; get; }

        public GpgAddKeyEditCommand (GpgGeneratedKeyType key_type,
                                     uint length,
                                     GpgExpirationSpec expires)
        {
            Object (key_type: key_type, length: length, expires: expires);
        }

        public override void action (uint state, int fd) throws GLib.Error {
            switch (state) {
            case GpgAddKeyState.COMMAND:
                send_string (fd, "addkey");
                break;

            case GpgAddKeyState.TYPE:
                send_string (fd, ((int) key_type).to_string ());
                break;

            case GpgAddKeyState.LENGTH:
                send_string (fd, length.to_string ());
                break;

            case GpgAddKeyState.EXPIRES:
                send_string (fd, expires.indicator ());
                break;

            case GpgAddKeyState.QUIT:
                send_string (fd, QUIT);
                break;

            case GpgAddKeyState.SAVE:
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
            case GpgAddKeyState.START:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgAddKeyState.COMMAND;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgAddKeyState.COMMAND:
            case GpgAddKeyState.TYPE:
            case GpgAddKeyState.LENGTH:
            case GpgAddKeyState.EXPIRES:
                if (status == GGpg.StatusCode.GET_LINE &&
                    args == "keygen.algo")
                    return GpgAddKeyState.TYPE;
                if (status == GGpg.StatusCode.GET_LINE &&
                    args == "keygen.size")
                    return GpgAddKeyState.LENGTH;
                if (status == GGpg.StatusCode.GET_LINE &&
                    args == "keygen.valid")
                    return GpgAddKeyState.EXPIRES;
                if (status == GGpg.StatusCode.GET_LINE &&
                    args == PROMPT)
                    return GpgAddKeyState.QUIT;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgAddKeyState.QUIT:
                if (status == GGpg.StatusCode.GET_BOOL && args == SAVE)
                    return GpgAddKeyState.SAVE;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgAddKeyState.ERROR:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgAddKeyState.QUIT;
                else
                    return GpgAddKeyState.ERROR;
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
                    args == "keyedit.remove.subkey.okay")
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

    enum GpgTrustState {
        START,
        COMMAND,
        VALUE,
        CONFIRM,
        QUIT,
        ERROR
    }

    class GpgTrustEditCommand : GpgEditCommand {
        public GGpg.Validity validity { construct set; get; }

        public GpgTrustEditCommand (GGpg.Validity validity)
        {
            Object (validity: validity);
        }

        public override void action (uint state, int fd) throws GLib.Error {
            switch (state) {
            case GpgTrustState.COMMAND:
                send_string (fd, "trust");
                break;

            case GpgTrustState.VALUE:
                send_string (fd, ((int) validity).to_string ());
                break;

            case GpgTrustState.CONFIRM:
                send_string (fd, YES);
                break;

            case GpgTrustState.QUIT:
                send_string (fd, QUIT);
                break;

            default:
                throw new GGpg.Error.GENERAL ("invalid state in trust command");
            }
            send_string (fd, "\n");
        }

        public override uint transit (uint state,
                                      GGpg.StatusCode status,
                                      string args) throws GLib.Error
        {
            switch (state) {
            case GpgTrustState.START:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgTrustState.COMMAND;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgTrustState.COMMAND:
                if (status == GGpg.StatusCode.GET_LINE &&
                    args == "edit_ownertrust.value")
                    return GpgTrustState.VALUE;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgTrustState.VALUE:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgTrustState.QUIT;
                else if (status == GGpg.StatusCode.GET_BOOL &&
                         args == "edit_ownertrust.set_ultimate.okay")
                    return GpgTrustState.CONFIRM;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgTrustState.CONFIRM:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgTrustState.QUIT;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgTrustState.QUIT:
                if (status == GGpg.StatusCode.GET_BOOL && args == SAVE)
                    return GpgTrustState.CONFIRM;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgTrustState.ERROR:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgTrustState.QUIT;
                else
                    return GpgTrustState.ERROR;
            default:
                throw new GGpg.Error.GENERAL ("invalid state %u", state);
            }
        }
    }

    enum GpgExpireState {
        START,
        SELECT,
        COMMAND,
        DATE,
        QUIT,
        SAVE,
        ERROR
    }

    class GpgExpireEditCommand : GpgEditCommand {
        public uint index { construct set; get; }
        public GpgExpirationSpec spec { construct set; get; }

        public GpgExpireEditCommand (uint index, GpgExpirationSpec spec) {
            Object (index: index, spec: spec);
        }

        public override void action (uint state, int fd) throws GLib.Error {
            switch (state) {
            case GpgExpireState.SELECT:
                send_string (fd, "key %u".printf (index));
                break;

            case GpgExpireState.COMMAND:
                send_string (fd, "expire");
                break;

            case GpgExpireState.DATE:
                send_string (fd, spec.indicator ());
                break;

            case GpgExpireState.QUIT:
                send_string (fd, QUIT);
                break;

            case GpgExpireState.SAVE:
                send_string (fd, YES);
                break;

            default:
                throw new GGpg.Error.GENERAL ("invalid state in expire command");
            }
            send_string (fd, "\n");
        }

        public override uint transit (uint state,
                                      GGpg.StatusCode status,
                                      string args) throws GLib.Error
        {
            switch (state) {
            case GpgExpireState.START:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgExpireState.SELECT;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgExpireState.SELECT:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgExpireState.COMMAND;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgExpireState.COMMAND:
                if (status == GGpg.StatusCode.GET_LINE &&
                    args == "keygen.valid")
                    return GpgExpireState.DATE;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgExpireState.DATE:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgExpireState.QUIT;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgExpireState.QUIT:
                if (status == GGpg.StatusCode.GET_BOOL && args == SAVE)
                    return GpgExpireState.SAVE;
                throw new GGpg.Error.GENERAL ("invalid response at state %u",
                                              state);

            case GpgExpireState.ERROR:
                if (status == GGpg.StatusCode.GET_LINE && args == PROMPT)
                    return GpgExpireState.QUIT;
                else
                    return GpgExpireState.ERROR;
            default:
                throw new GGpg.Error.GENERAL ("invalid state %u", state);
            }
        }
    }
}
