[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "config.h")]
namespace Config {
    public const string PACKAGE_NAME;
    public const string PACKAGE_VERSION;
    public const string PACKAGE_DESKTOP_NAME;
}

[CCode (cheader_filename = "p11-kit/pkcs11.h")]
namespace CKF
{
        public const ulong TOKEN_INITIALIZED;
}
