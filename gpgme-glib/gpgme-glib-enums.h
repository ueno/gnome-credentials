#ifndef GPGME_GLIB_ENUMS_H_
#define GPGME_GLIB_ENUMS_H_

#include <glib-object.h>

G_BEGIN_DECLS

typedef enum
  {
    G_GPG_DATA_ENCODING_NONE   = 0,     /* Not specified.  */
    G_GPG_DATA_ENCODING_BINARY = 1,
    G_GPG_DATA_ENCODING_BASE64 = 2,
    G_GPG_DATA_ENCODING_ARMOR  = 3,     /* Either PEM or OpenPGP Armor.  */
    G_GPG_DATA_ENCODING_URL    = 4,     /* LF delimited URL list.        */
    G_GPG_DATA_ENCODING_URLESC = 5,     /* Ditto, but percent escaped.   */
    G_GPG_DATA_ENCODING_URL0   = 6      /* Nul delimited URL list.       */
  }
GGpgDataEncoding;

typedef enum
  {
    G_GPG_DATA_TYPE_INVALID      = 0,   /* Not detected.  */
    G_GPG_DATA_TYPE_UNKNOWN      = 1,
    G_GPG_DATA_TYPE_PGP_SIGNED   = 0x10,
    G_GPG_DATA_TYPE_PGP_OTHER    = 0x12,
    G_GPG_DATA_TYPE_PGP_KEY      = 0x13,
    G_GPG_DATA_TYPE_CMS_SIGNED   = 0x20,
    G_GPG_DATA_TYPE_CMS_ENCRYPTED= 0x21,
    G_GPG_DATA_TYPE_CMS_OTHER    = 0x22,
    G_GPG_DATA_TYPE_X509_CERT    = 0x23,
    G_GPG_DATA_TYPE_PKCS12       = 0x24,
  }
GGpgDataType;

typedef enum
  {
    G_GPG_PK_RSA   = 1,
    G_GPG_PK_RSA_E = 2,
    G_GPG_PK_RSA_S = 3,
    G_GPG_PK_ELG_E = 16,
    G_GPG_PK_DSA   = 17,
    G_GPG_PK_ELG   = 20,
    G_GPG_PK_ECDSA = 301,
    G_GPG_PK_ECDH  = 302
  }
GGpgPubkeyAlgo;

typedef enum
  {
    G_GPG_MD_NONE          = 0,
    G_GPG_MD_MD5           = 1,
    G_GPG_MD_SHA1          = 2,
    G_GPG_MD_RMD160        = 3,
    G_GPG_MD_MD2           = 5,
    G_GPG_MD_TIGER         = 6,   /* TIGER/192. */
    G_GPG_MD_HAVAL         = 7,   /* HAVAL, 5 pass, 160 bit. */
    G_GPG_MD_SHA256        = 8,
    G_GPG_MD_SHA384        = 9,
    G_GPG_MD_SHA512        = 10,
    G_GPG_MD_MD4           = 301,
    G_GPG_MD_CRC32         = 302,
    G_GPG_MD_CRC32_RFC1510 = 303,
    G_GPG_MD_CRC24_RFC2440 = 304
  }
GGpgHashAlgo;

typedef enum
  {
    G_GPG_SIG_MODE_NORMAL = 0,
    G_GPG_SIG_MODE_DETACH = 1,
    G_GPG_SIG_MODE_CLEAR  = 2
  }
GGpgSigMode;

typedef enum
  {
    G_GPG_VALIDITY_UNKNOWN   = 0,
    G_GPG_VALIDITY_UNDEFINED = 1,
    G_GPG_VALIDITY_NEVER     = 2,
    G_GPG_VALIDITY_MARGINAL  = 3,
    G_GPG_VALIDITY_FULL      = 4,
    G_GPG_VALIDITY_ULTIMATE  = 5
  }
GGpgValidity;

typedef enum
  {
    G_GPG_PROTOCOL_OpenPGP = 0,  /* The default mode.  */
    G_GPG_PROTOCOL_CMS     = 1,
    G_GPG_PROTOCOL_GPGCONF = 2,  /* Special code for gpgconf.  */
    G_GPG_PROTOCOL_ASSUAN  = 3,  /* Low-level access to an Assuan server.  */
    G_GPG_PROTOCOL_G13     = 4,
    G_GPG_PROTOCOL_UISERVER= 5,
    G_GPG_PROTOCOL_DEFAULT = 254,
    G_GPG_PROTOCOL_UNKNOWN = 255
  }
GGpgProtocol;

typedef enum
  {
    G_GPG_KEYLIST_MODE_LOCAL = 1 << 0,
    G_GPG_KEYLIST_MODE_EXTERN = 1 << 1,
    G_GPG_KEYLIST_MODE_SIGS = 1 << 2,
    G_GPG_KEYLIST_MODE_SIG_NOTATIONS = 1 << 3,
    G_GPG_KEYLIST_MODE_WITH_SECRET = 1 << 4,
    G_GPG_KEYLIST_MODE_EPHEMERAL = 1 << 7,
    G_GPG_KEYLIST_MODE_VALIDATE = 1 << 8
  }
GGpgKeylistMode;

typedef enum
  {
    G_GPG_PINENTRY_MODE_DEFAULT  = 0,
    G_GPG_PINENTRY_MODE_ASK      = 1,
    G_GPG_PINENTRY_MODE_CANCEL   = 2,
    G_GPG_PINENTRY_MODE_ERROR    = 3,
    G_GPG_PINENTRY_MODE_LOOPBACK = 4
  }
GGpgPinentryMode;

typedef enum
  {
    G_GPG_STATUS_EOF = 0,
    /* mkstatus processing starts here */
    G_GPG_STATUS_ENTER = 1,
    G_GPG_STATUS_LEAVE = 2,
    G_GPG_STATUS_ABORT = 3,

    G_GPG_STATUS_GOODSIG = 4,
    G_GPG_STATUS_BADSIG = 5,
    G_GPG_STATUS_ERRSIG = 6,

    G_GPG_STATUS_BADARMOR = 7,

    G_GPG_STATUS_RSA_OR_IDEA = 8,      /* (legacy) */
    G_GPG_STATUS_KEYEXPIRED = 9,
    G_GPG_STATUS_KEYREVOKED = 10,

    G_GPG_STATUS_TRUST_UNDEFINED = 11,
    G_GPG_STATUS_TRUST_NEVER = 12,
    G_GPG_STATUS_TRUST_MARGINAL = 13,
    G_GPG_STATUS_TRUST_FULLY = 14,
    G_GPG_STATUS_TRUST_ULTIMATE = 15,

    G_GPG_STATUS_SHM_INFO = 16,        /* (legacy) */
    G_GPG_STATUS_SHM_GET = 17,         /* (legacy) */
    G_GPG_STATUS_SHM_GET_BOOL = 18,    /* (legacy) */
    G_GPG_STATUS_SHM_GET_HIDDEN = 19,  /* (legacy) */

    G_GPG_STATUS_NEED_PASSPHRASE = 20,
    G_GPG_STATUS_VALIDSIG = 21,
    G_GPG_STATUS_SIG_ID = 22,
    G_GPG_STATUS_ENC_TO = 23,
    G_GPG_STATUS_NODATA = 24,
    G_GPG_STATUS_BAD_PASSPHRASE = 25,
    G_GPG_STATUS_NO_PUBKEY = 26,
    G_GPG_STATUS_NO_SECKEY = 27,
    G_GPG_STATUS_NEED_PASSPHRASE_SYM = 28,
    G_GPG_STATUS_DECRYPTION_FAILED = 29,
    G_GPG_STATUS_DECRYPTION_OKAY = 30,
    G_GPG_STATUS_MISSING_PASSPHRASE = 31,
    G_GPG_STATUS_GOOD_PASSPHRASE = 32,
    G_GPG_STATUS_GOODMDC = 33,
    G_GPG_STATUS_BADMDC = 34,
    G_GPG_STATUS_ERRMDC = 35,
    G_GPG_STATUS_IMPORTED = 36,
    G_GPG_STATUS_IMPORT_OK = 37,
    G_GPG_STATUS_IMPORT_PROBLEM = 38,
    G_GPG_STATUS_IMPORT_RES = 39,
    G_GPG_STATUS_FILE_START = 40,
    G_GPG_STATUS_FILE_DONE = 41,
    G_GPG_STATUS_FILE_ERROR = 42,

    G_GPG_STATUS_BEGIN_DECRYPTION = 43,
    G_GPG_STATUS_END_DECRYPTION = 44,
    G_GPG_STATUS_BEGIN_ENCRYPTION = 45,
    G_GPG_STATUS_END_ENCRYPTION = 46,

    G_GPG_STATUS_DELETE_PROBLEM = 47,
    G_GPG_STATUS_GET_BOOL = 48,
    G_GPG_STATUS_GET_LINE = 49,
    G_GPG_STATUS_GET_HIDDEN = 50,
    G_GPG_STATUS_GOT_IT = 51,
    G_GPG_STATUS_PROGRESS = 52,
    G_GPG_STATUS_SIG_CREATED = 53,
    G_GPG_STATUS_SESSION_KEY = 54,
    G_GPG_STATUS_NOTATION_NAME = 55,
    G_GPG_STATUS_NOTATION_DATA = 56,
    G_GPG_STATUS_POLICY_URL = 57,
    G_GPG_STATUS_BEGIN_STREAM = 58,    /* (legacy) */
    G_GPG_STATUS_END_STREAM = 59,      /* (legacy) */
    G_GPG_STATUS_KEY_CREATED = 60,
    G_GPG_STATUS_USERID_HINT = 61,
    G_GPG_STATUS_UNEXPECTED = 62,
    G_GPG_STATUS_INV_RECP = 63,
    G_GPG_STATUS_NO_RECP = 64,
    G_GPG_STATUS_ALREADY_SIGNED = 65,
    G_GPG_STATUS_SIGEXPIRED = 66,      /* (legacy) */
    G_GPG_STATUS_EXPSIG = 67,
    G_GPG_STATUS_EXPKEYSIG = 68,
    G_GPG_STATUS_TRUNCATED = 69,
    G_GPG_STATUS_ERROR = 70,
    G_GPG_STATUS_NEWSIG = 71,
    G_GPG_STATUS_REVKEYSIG = 72,
    G_GPG_STATUS_SIG_SUBPACKET = 73,
    G_GPG_STATUS_NEED_PASSPHRASE_PIN = 74,
    G_GPG_STATUS_SC_OP_FAILURE = 75,
    G_GPG_STATUS_SC_OP_SUCCESS = 76,
    G_GPG_STATUS_CARDCTRL = 77,
    G_GPG_STATUS_BACKUP_KEY_CREATED = 78,
    G_GPG_STATUS_PKA_TRUST_BAD = 79,
    G_GPG_STATUS_PKA_TRUST_GOOD = 80,
    G_GPG_STATUS_PLAINTEXT = 81,
    G_GPG_STATUS_INV_SGNR = 82,
    G_GPG_STATUS_NO_SGNR = 83,
    G_GPG_STATUS_SUCCESS = 84,
    G_GPG_STATUS_DECRYPTION_INFO = 85,
    G_GPG_STATUS_PLAINTEXT_LENGTH = 86,
    G_GPG_STATUS_MOUNTPOINT = 87,
    G_GPG_STATUS_PINENTRY_LAUNCHED = 88,
    G_GPG_STATUS_ATTRIBUTE = 89,
    G_GPG_STATUS_BEGIN_SIGNING = 90,
    G_GPG_STATUS_KEY_NOT_CREATED = 91
  }
GGpgStatusCode;

typedef enum
  {
    G_GPG_ERROR_NO_ERROR = 0,
    G_GPG_ERROR_GENERAL = 1,
    G_GPG_ERROR_UNKNOWN_PACKET = 2,
    G_GPG_ERROR_UNKNOWN_VERSION = 3,
    G_GPG_ERROR_PUBKEY_ALGO = 4,
    G_GPG_ERROR_DIGEST_ALGO = 5,
    G_GPG_ERROR_BAD_PUBKEY = 6,
    G_GPG_ERROR_BAD_SECKEY = 7,
    G_GPG_ERROR_BAD_SIGNATURE = 8,
    G_GPG_ERROR_NO_PUBKEY = 9,
    G_GPG_ERROR_CHECKSUM = 10,
    G_GPG_ERROR_BAD_PASSPHRASE = 11,
    G_GPG_ERROR_CIPHER_ALGO = 12,
    G_GPG_ERROR_KEYRING_OPEN = 13,
    G_GPG_ERROR_INV_PACKET = 14,
    G_GPG_ERROR_INV_ARMOR = 15,
    G_GPG_ERROR_NO_USER_ID = 16,
    G_GPG_ERROR_NO_SECKEY = 17,
    G_GPG_ERROR_WRONG_SECKEY = 18,
    G_GPG_ERROR_BAD_KEY = 19,
    G_GPG_ERROR_COMPR_ALGO = 20,
    G_GPG_ERROR_NO_PRIME = 21,
    G_GPG_ERROR_NO_ENCODING_METHOD = 22,
    G_GPG_ERROR_NO_ENCRYPTION_SCHEME = 23,
    G_GPG_ERROR_NO_SIGNATURE_SCHEME = 24,
    G_GPG_ERROR_INV_ATTR = 25,
    G_GPG_ERROR_NO_VALUE = 26,
    G_GPG_ERROR_NOT_FOUND = 27,
    G_GPG_ERROR_VALUE_NOT_FOUND = 28,
    G_GPG_ERROR_SYNTAX = 29,
    G_GPG_ERROR_BAD_MPI = 30,
    G_GPG_ERROR_INV_PASSPHRASE = 31,
    G_GPG_ERROR_SIG_CLASS = 32,
    G_GPG_ERROR_RESOURCE_LIMIT = 33,
    G_GPG_ERROR_INV_KEYRING = 34,
    G_GPG_ERROR_TRUSTDB = 35,
    G_GPG_ERROR_BAD_CERT = 36,
    G_GPG_ERROR_INV_USER_ID = 37,
    G_GPG_ERROR_UNEXPECTED = 38,
    G_GPG_ERROR_TIME_CONFLICT = 39,
    G_GPG_ERROR_KEYSERVER = 40,
    G_GPG_ERROR_WRONG_PUBKEY_ALGO = 41,
    G_GPG_ERROR_TRIBUTE_TO_D_A = 42,
    G_GPG_ERROR_WEAK_KEY = 43,
    G_GPG_ERROR_INV_KEYLEN = 44,
    G_GPG_ERROR_INV_ARG = 45,
    G_GPG_ERROR_BAD_URI = 46,
    G_GPG_ERROR_INV_URI = 47,
    G_GPG_ERROR_NETWORK = 48,
    G_GPG_ERROR_UNKNOWN_HOST = 49,
    G_GPG_ERROR_SELFTEST_FAILED = 50,
    G_GPG_ERROR_NOT_ENCRYPTED = 51,
    G_GPG_ERROR_NOT_PROCESSED = 52,
    G_GPG_ERROR_UNUSABLE_PUBKEY = 53,
    G_GPG_ERROR_UNUSABLE_SECKEY = 54,
    G_GPG_ERROR_INV_VALUE = 55,
    G_GPG_ERROR_BAD_CERT_CHAIN = 56,
    G_GPG_ERROR_MISSING_CERT = 57,
    G_GPG_ERROR_NO_DATA = 58,
    G_GPG_ERROR_BUG = 59,
    G_GPG_ERROR_NOT_SUPPORTED = 60,
    G_GPG_ERROR_INV_OP = 61,
    G_GPG_ERROR_TIMEOUT = 62,
    G_GPG_ERROR_INTERNAL = 63,
    G_GPG_ERROR_EOF_GCRYPT = 64,
    G_GPG_ERROR_INV_OBJ = 65,
    G_GPG_ERROR_TOO_SHORT = 66,
    G_GPG_ERROR_TOO_LARGE = 67,
    G_GPG_ERROR_NO_OBJ = 68,
    G_GPG_ERROR_NOT_IMPLEMENTED = 69,
    G_GPG_ERROR_CONFLICT = 70,
    G_GPG_ERROR_INV_CIPHER_MODE = 71,
    G_GPG_ERROR_INV_FLAG = 72,
    G_GPG_ERROR_INV_HANDLE = 73,
    G_GPG_ERROR_TRUNCATED = 74,
    G_GPG_ERROR_INCOMPLETE_LINE = 75,
    G_GPG_ERROR_INV_RESPONSE = 76,
    G_GPG_ERROR_NO_AGENT = 77,
    G_GPG_ERROR_AGENT = 78,
    G_GPG_ERROR_INV_DATA = 79,
    G_GPG_ERROR_ASSUAN_SERVER_FAULT = 80,
    G_GPG_ERROR_ASSUAN = 81,
    G_GPG_ERROR_INV_SESSION_KEY = 82,
    G_GPG_ERROR_INV_SEXP = 83,
    G_GPG_ERROR_UNSUPPORTED_ALGORITHM = 84,
    G_GPG_ERROR_NO_PIN_ENTRY = 85,
    G_GPG_ERROR_PIN_ENTRY = 86,
    G_GPG_ERROR_BAD_PIN = 87,
    G_GPG_ERROR_INV_NAME = 88,
    G_GPG_ERROR_BAD_DATA = 89,
    G_GPG_ERROR_INV_PARAMETER = 90,
    G_GPG_ERROR_WRONG_CARD = 91,
    G_GPG_ERROR_NO_DIRMNGR = 92,
    G_GPG_ERROR_DIRMNGR = 93,
    G_GPG_ERROR_CERT_REVOKED = 94,
    G_GPG_ERROR_NO_CRL_KNOWN = 95,
    G_GPG_ERROR_CRL_TOO_OLD = 96,
    G_GPG_ERROR_LINE_TOO_LONG = 97,
    G_GPG_ERROR_NOT_TRUSTED = 98,
    G_GPG_ERROR_CANCELED = 99,
    G_GPG_ERROR_BAD_CA_CERT = 100,
    G_GPG_ERROR_CERT_EXPIRED = 101,
    G_GPG_ERROR_CERT_TOO_YOUNG = 102,
    G_GPG_ERROR_UNSUPPORTED_CERT = 103,
    G_GPG_ERROR_UNKNOWN_SEXP = 104,
    G_GPG_ERROR_UNSUPPORTED_PROTECTION = 105,
    G_GPG_ERROR_CORRUPTED_PROTECTION = 106,
    G_GPG_ERROR_AMBIGUOUS_NAME = 107,
    G_GPG_ERROR_CARD = 108,
    G_GPG_ERROR_CARD_RESET = 109,
    G_GPG_ERROR_CARD_REMOVED = 110,
    G_GPG_ERROR_INV_CARD = 111,
    G_GPG_ERROR_CARD_NOT_PRESENT = 112,
    G_GPG_ERROR_NO_PKCS15_APP = 113,
    G_GPG_ERROR_NOT_CONFIRMED = 114,
    G_GPG_ERROR_CONFIGURATION = 115,
    G_GPG_ERROR_NO_POLICY_MATCH = 116,
    G_GPG_ERROR_INV_INDEX = 117,
    G_GPG_ERROR_INV_ID = 118,
    G_GPG_ERROR_NO_SCDAEMON = 119,
    G_GPG_ERROR_SCDAEMON = 120,
    G_GPG_ERROR_UNSUPPORTED_PROTOCOL = 121,
    G_GPG_ERROR_BAD_PIN_METHOD = 122,
    G_GPG_ERROR_CARD_NOT_INITIALIZED = 123,
    G_GPG_ERROR_UNSUPPORTED_OPERATION = 124,
    G_GPG_ERROR_WRONG_KEY_USAGE = 125,
    G_GPG_ERROR_NOTHING_FOUND = 126,
    G_GPG_ERROR_WRONG_BLOB_TYPE = 127,
    G_GPG_ERROR_MISSING_VALUE = 128,
    G_GPG_ERROR_HARDWARE = 129,
    G_GPG_ERROR_PIN_BLOCKED = 130,
    G_GPG_ERROR_USE_CONDITIONS = 131,
    G_GPG_ERROR_PIN_NOT_SYNCED = 132,
    G_GPG_ERROR_INV_CRL = 133,
    G_GPG_ERROR_BAD_BER = 134,
    G_GPG_ERROR_INV_BER = 135,
    G_GPG_ERROR_ELEMENT_NOT_FOUND = 136,
    G_GPG_ERROR_IDENTIFIER_NOT_FOUND = 137,
    G_GPG_ERROR_INV_TAG = 138,
    G_GPG_ERROR_INV_LENGTH = 139,
    G_GPG_ERROR_INV_KEYINFO = 140,
    G_GPG_ERROR_UNEXPECTED_TAG = 141,
    G_GPG_ERROR_NOT_DER_ENCODED = 142,
    G_GPG_ERROR_NO_CMS_OBJ = 143,
    G_GPG_ERROR_INV_CMS_OBJ = 144,
    G_GPG_ERROR_UNKNOWN_CMS_OBJ = 145,
    G_GPG_ERROR_UNSUPPORTED_CMS_OBJ = 146,
    G_GPG_ERROR_UNSUPPORTED_ENCODING = 147,
    G_GPG_ERROR_UNSUPPORTED_CMS_VERSION = 148,
    G_GPG_ERROR_UNKNOWN_ALGORITHM = 149,
    G_GPG_ERROR_INV_ENGINE = 150,
    G_GPG_ERROR_PUBKEY_NOT_TRUSTED = 151,
    G_GPG_ERROR_DECRYPT_FAILED = 152,
    G_GPG_ERROR_KEY_EXPIRED = 153,
    G_GPG_ERROR_SIG_EXPIRED = 154,
    G_GPG_ERROR_ENCODING_PROBLEM = 155,
    G_GPG_ERROR_INV_STATE = 156,
    G_GPG_ERROR_DUP_VALUE = 157,
    G_GPG_ERROR_MISSING_ACTION = 158,
    G_GPG_ERROR_MODULE_NOT_FOUND = 159,
    G_GPG_ERROR_INV_OID_STRING = 160,
    G_GPG_ERROR_INV_TIME = 161,
    G_GPG_ERROR_INV_CRL_OBJ = 162,
    G_GPG_ERROR_UNSUPPORTED_CRL_VERSION = 163,
    G_GPG_ERROR_INV_CERT_OBJ = 164,
    G_GPG_ERROR_UNKNOWN_NAME = 165,
    G_GPG_ERROR_LOCALE_PROBLEM = 166,
    G_GPG_ERROR_NOT_LOCKED = 167,
    G_GPG_ERROR_PROTOCOL_VIOLATION = 168,
    G_GPG_ERROR_INV_MAC = 169,
    G_GPG_ERROR_INV_REQUEST = 170,
    G_GPG_ERROR_UNKNOWN_EXTN = 171,
    G_GPG_ERROR_UNKNOWN_CRIT_EXTN = 172,
    G_GPG_ERROR_LOCKED = 173,
    G_GPG_ERROR_UNKNOWN_OPTION = 174,
    G_GPG_ERROR_UNKNOWN_COMMAND = 175,
    G_GPG_ERROR_NOT_OPERATIONAL = 176,
    G_GPG_ERROR_NO_PASSPHRASE = 177,
    G_GPG_ERROR_NO_PIN = 178,
    G_GPG_ERROR_NOT_ENABLED = 179,
    G_GPG_ERROR_NO_ENGINE = 180,
    G_GPG_ERROR_MISSING_KEY = 181,
    G_GPG_ERROR_TOO_MANY = 182,
    G_GPG_ERROR_LIMIT_REACHED = 183,
    G_GPG_ERROR_NOT_INITIALIZED = 184,
    G_GPG_ERROR_MISSING_ISSUER_CERT = 185,
    G_GPG_ERROR_NO_KEYSERVER = 186,
    G_GPG_ERROR_INV_CURVE = 187,
    G_GPG_ERROR_UNKNOWN_CURVE = 188,
    G_GPG_ERROR_DUP_KEY = 189,
    G_GPG_ERROR_AMBIGUOUS = 190,
    G_GPG_ERROR_NO_CRYPT_CTX = 191,
    G_GPG_ERROR_WRONG_CRYPT_CTX = 192,
    G_GPG_ERROR_BAD_CRYPT_CTX = 193,
    G_GPG_ERROR_CRYPT_CTX_CONFLICT = 194,
    G_GPG_ERROR_BROKEN_PUBKEY = 195,
    G_GPG_ERROR_BROKEN_SECKEY = 196,
    G_GPG_ERROR_MAC_ALGO = 197,
    G_GPG_ERROR_FULLY_CANCELED = 198,
    G_GPG_ERROR_UNFINISHED = 199,
    G_GPG_ERROR_BUFFER_TOO_SHORT = 200,
    G_GPG_ERROR_SEXP_INV_LEN_SPEC = 201,
    G_GPG_ERROR_SEXP_STRING_TOO_LONG = 202,
    G_GPG_ERROR_SEXP_UNMATCHED_PAREN = 203,
    G_GPG_ERROR_SEXP_NOT_CANONICAL = 204,
    G_GPG_ERROR_SEXP_BAD_CHARACTER = 205,
    G_GPG_ERROR_SEXP_BAD_QUOTATION = 206,
    G_GPG_ERROR_SEXP_ZERO_PREFIX = 207,
    G_GPG_ERROR_SEXP_NESTED_DH = 208,
    G_GPG_ERROR_SEXP_UNMATCHED_DH = 209,
    G_GPG_ERROR_SEXP_UNEXPECTED_PUNC = 210,
    G_GPG_ERROR_SEXP_BAD_HEX_CHAR = 211,
    G_GPG_ERROR_SEXP_ODD_HEX_NUMBERS = 212,
    G_GPG_ERROR_SEXP_BAD_OCT_CHAR = 213,
    G_GPG_ERROR_NO_CERT_CHAIN = 226,
    G_GPG_ERROR_CERT_TOO_LARGE = 227,
    G_GPG_ERROR_INV_RECORD = 228,
    G_GPG_ERROR_BAD_MAC = 229,
    G_GPG_ERROR_UNEXPECTED_MSG = 230,
    G_GPG_ERROR_COMPR_FAILED = 231,
    G_GPG_ERROR_WOULD_WRAP = 232,
    G_GPG_ERROR_FATAL_ALERT = 233,
    G_GPG_ERROR_NO_CIPHER = 234,
    G_GPG_ERROR_MISSING_CLIENT_CERT = 235,
    G_GPG_ERROR_CLOSE_NOTIFY = 236,
    G_GPG_ERROR_TICKET_EXPIRED = 237,
    G_GPG_ERROR_BAD_TICKET = 238,
    G_GPG_ERROR_UNKNOWN_IDENTITY = 239,
    G_GPG_ERROR_BAD_HS_CERT = 240,
    G_GPG_ERROR_BAD_HS_CERT_REQ = 241,
    G_GPG_ERROR_BAD_HS_CERT_VER = 242,
    G_GPG_ERROR_BAD_HS_CHANGE_CIPHER = 243,
    G_GPG_ERROR_BAD_HS_CLIENT_HELLO = 244,
    G_GPG_ERROR_BAD_HS_SERVER_HELLO = 245,
    G_GPG_ERROR_BAD_HS_SERVER_HELLO_DONE = 246,
    G_GPG_ERROR_BAD_HS_FINISHED = 247,
    G_GPG_ERROR_BAD_HS_SERVER_KEX = 248,
    G_GPG_ERROR_BAD_HS_CLIENT_KEX = 249,
    G_GPG_ERROR_BOGUS_STRING = 250,
    G_GPG_ERROR_KEY_DISABLED = 252,
    G_GPG_ERROR_KEY_ON_CARD = 253,
    G_GPG_ERROR_INV_LOCK_OBJ = 254,
    G_GPG_ERROR_ASS_GENERAL = 257,
    G_GPG_ERROR_ASS_ACCEPT_FAILED = 258,
    G_GPG_ERROR_ASS_CONNECT_FAILED = 259,
    G_GPG_ERROR_ASS_INV_RESPONSE = 260,
    G_GPG_ERROR_ASS_INV_VALUE = 261,
    G_GPG_ERROR_ASS_INCOMPLETE_LINE = 262,
    G_GPG_ERROR_ASS_LINE_TOO_LONG = 263,
    G_GPG_ERROR_ASS_NESTED_COMMANDS = 264,
    G_GPG_ERROR_ASS_NO_DATA_CB = 265,
    G_GPG_ERROR_ASS_NO_INQUIRE_CB = 266,
    G_GPG_ERROR_ASS_NOT_A_SERVER = 267,
    G_GPG_ERROR_ASS_NOT_A_CLIENT = 268,
    G_GPG_ERROR_ASS_SERVER_START = 269,
    G_GPG_ERROR_ASS_READ_ERROR = 270,
    G_GPG_ERROR_ASS_WRITE_ERROR = 271,
    G_GPG_ERROR_ASS_TOO_MUCH_DATA = 273,
    G_GPG_ERROR_ASS_UNEXPECTED_CMD = 274,
    G_GPG_ERROR_ASS_UNKNOWN_CMD = 275,
    G_GPG_ERROR_ASS_SYNTAX = 276,
    G_GPG_ERROR_ASS_CANCELED = 277,
    G_GPG_ERROR_ASS_NO_INPUT = 278,
    G_GPG_ERROR_ASS_NO_OUTPUT = 279,
    G_GPG_ERROR_ASS_PARAMETER = 280,
    G_GPG_ERROR_ASS_UNKNOWN_INQUIRE = 281,
    G_GPG_ERROR_USER_1 = 1024,
    G_GPG_ERROR_USER_2 = 1025,
    G_GPG_ERROR_USER_3 = 1026,
    G_GPG_ERROR_USER_4 = 1027,
    G_GPG_ERROR_USER_5 = 1028,
    G_GPG_ERROR_USER_6 = 1029,
    G_GPG_ERROR_USER_7 = 1030,
    G_GPG_ERROR_USER_8 = 1031,
    G_GPG_ERROR_USER_9 = 1032,
    G_GPG_ERROR_USER_10 = 1033,
    G_GPG_ERROR_USER_11 = 1034,
    G_GPG_ERROR_USER_12 = 1035,
    G_GPG_ERROR_USER_13 = 1036,
    G_GPG_ERROR_USER_14 = 1037,
    G_GPG_ERROR_USER_15 = 1038,
    G_GPG_ERROR_USER_16 = 1039,
    G_GPG_ERROR_MISSING_ERRNO = 16381,
    G_GPG_ERROR_UNKNOWN_ERRNO = 16382,
    G_GPG_ERROR_EOF = 16383,

    /* The following error codes are used to map system errors.  */
#define G_GPG_ERROR_SYSTEM_ERROR        (1 << 15)
    G_GPG_ERROR_E2BIG = G_GPG_ERROR_SYSTEM_ERROR | 0,
    G_GPG_ERROR_EACCES = G_GPG_ERROR_SYSTEM_ERROR | 1,
    G_GPG_ERROR_EADDRINUSE = G_GPG_ERROR_SYSTEM_ERROR | 2,
    G_GPG_ERROR_EADDRNOTAVAIL = G_GPG_ERROR_SYSTEM_ERROR | 3,
    G_GPG_ERROR_EADV = G_GPG_ERROR_SYSTEM_ERROR | 4,
    G_GPG_ERROR_EAFNOSUPPORT = G_GPG_ERROR_SYSTEM_ERROR | 5,
    G_GPG_ERROR_EAGAIN = G_GPG_ERROR_SYSTEM_ERROR | 6,
    G_GPG_ERROR_EALREADY = G_GPG_ERROR_SYSTEM_ERROR | 7,
    G_GPG_ERROR_EAUTH = G_GPG_ERROR_SYSTEM_ERROR | 8,
    G_GPG_ERROR_EBACKGROUND = G_GPG_ERROR_SYSTEM_ERROR | 9,
    G_GPG_ERROR_EBADE = G_GPG_ERROR_SYSTEM_ERROR | 10,
    G_GPG_ERROR_EBADF = G_GPG_ERROR_SYSTEM_ERROR | 11,
    G_GPG_ERROR_EBADFD = G_GPG_ERROR_SYSTEM_ERROR | 12,
    G_GPG_ERROR_EBADMSG = G_GPG_ERROR_SYSTEM_ERROR | 13,
    G_GPG_ERROR_EBADR = G_GPG_ERROR_SYSTEM_ERROR | 14,
    G_GPG_ERROR_EBADRPC = G_GPG_ERROR_SYSTEM_ERROR | 15,
    G_GPG_ERROR_EBADRQC = G_GPG_ERROR_SYSTEM_ERROR | 16,
    G_GPG_ERROR_EBADSLT = G_GPG_ERROR_SYSTEM_ERROR | 17,
    G_GPG_ERROR_EBFONT = G_GPG_ERROR_SYSTEM_ERROR | 18,
    G_GPG_ERROR_EBUSY = G_GPG_ERROR_SYSTEM_ERROR | 19,
    G_GPG_ERROR_ECANCELED = G_GPG_ERROR_SYSTEM_ERROR | 20,
    G_GPG_ERROR_ECHILD = G_GPG_ERROR_SYSTEM_ERROR | 21,
    G_GPG_ERROR_ECHRNG = G_GPG_ERROR_SYSTEM_ERROR | 22,
    G_GPG_ERROR_ECOMM = G_GPG_ERROR_SYSTEM_ERROR | 23,
    G_GPG_ERROR_ECONNABORTED = G_GPG_ERROR_SYSTEM_ERROR | 24,
    G_GPG_ERROR_ECONNREFUSED = G_GPG_ERROR_SYSTEM_ERROR | 25,
    G_GPG_ERROR_ECONNRESET = G_GPG_ERROR_SYSTEM_ERROR | 26,
    G_GPG_ERROR_ED = G_GPG_ERROR_SYSTEM_ERROR | 27,
    G_GPG_ERROR_EDEADLK = G_GPG_ERROR_SYSTEM_ERROR | 28,
    G_GPG_ERROR_EDEADLOCK = G_GPG_ERROR_SYSTEM_ERROR | 29,
    G_GPG_ERROR_EDESTADDRREQ = G_GPG_ERROR_SYSTEM_ERROR | 30,
    G_GPG_ERROR_EDIED = G_GPG_ERROR_SYSTEM_ERROR | 31,
    G_GPG_ERROR_EDOM = G_GPG_ERROR_SYSTEM_ERROR | 32,
    G_GPG_ERROR_EDOTDOT = G_GPG_ERROR_SYSTEM_ERROR | 33,
    G_GPG_ERROR_EDQUOT = G_GPG_ERROR_SYSTEM_ERROR | 34,
    G_GPG_ERROR_EEXIST = G_GPG_ERROR_SYSTEM_ERROR | 35,
    G_GPG_ERROR_EFAULT = G_GPG_ERROR_SYSTEM_ERROR | 36,
    G_GPG_ERROR_EFBIG = G_GPG_ERROR_SYSTEM_ERROR | 37,
    G_GPG_ERROR_EFTYPE = G_GPG_ERROR_SYSTEM_ERROR | 38,
    G_GPG_ERROR_EGRATUITOUS = G_GPG_ERROR_SYSTEM_ERROR | 39,
    G_GPG_ERROR_EGREGIOUS = G_GPG_ERROR_SYSTEM_ERROR | 40,
    G_GPG_ERROR_EHOSTDOWN = G_GPG_ERROR_SYSTEM_ERROR | 41,
    G_GPG_ERROR_EHOSTUNREACH = G_GPG_ERROR_SYSTEM_ERROR | 42,
    G_GPG_ERROR_EIDRM = G_GPG_ERROR_SYSTEM_ERROR | 43,
    G_GPG_ERROR_EIEIO = G_GPG_ERROR_SYSTEM_ERROR | 44,
    G_GPG_ERROR_EILSEQ = G_GPG_ERROR_SYSTEM_ERROR | 45,
    G_GPG_ERROR_EINPROGRESS = G_GPG_ERROR_SYSTEM_ERROR | 46,
    G_GPG_ERROR_EINTR = G_GPG_ERROR_SYSTEM_ERROR | 47,
    G_GPG_ERROR_EINVAL = G_GPG_ERROR_SYSTEM_ERROR | 48,
    G_GPG_ERROR_EIO = G_GPG_ERROR_SYSTEM_ERROR | 49,
    G_GPG_ERROR_EISCONN = G_GPG_ERROR_SYSTEM_ERROR | 50,
    G_GPG_ERROR_EISDIR = G_GPG_ERROR_SYSTEM_ERROR | 51,
    G_GPG_ERROR_EISNAM = G_GPG_ERROR_SYSTEM_ERROR | 52,
    G_GPG_ERROR_EL2HLT = G_GPG_ERROR_SYSTEM_ERROR | 53,
    G_GPG_ERROR_EL2NSYNC = G_GPG_ERROR_SYSTEM_ERROR | 54,
    G_GPG_ERROR_EL3HLT = G_GPG_ERROR_SYSTEM_ERROR | 55,
    G_GPG_ERROR_EL3RST = G_GPG_ERROR_SYSTEM_ERROR | 56,
    G_GPG_ERROR_ELIBACC = G_GPG_ERROR_SYSTEM_ERROR | 57,
    G_GPG_ERROR_ELIBBAD = G_GPG_ERROR_SYSTEM_ERROR | 58,
    G_GPG_ERROR_ELIBEXEC = G_GPG_ERROR_SYSTEM_ERROR | 59,
    G_GPG_ERROR_ELIBMAX = G_GPG_ERROR_SYSTEM_ERROR | 60,
    G_GPG_ERROR_ELIBSCN = G_GPG_ERROR_SYSTEM_ERROR | 61,
    G_GPG_ERROR_ELNRNG = G_GPG_ERROR_SYSTEM_ERROR | 62,
    G_GPG_ERROR_ELOOP = G_GPG_ERROR_SYSTEM_ERROR | 63,
    G_GPG_ERROR_EMEDIUMTYPE = G_GPG_ERROR_SYSTEM_ERROR | 64,
    G_GPG_ERROR_EMFILE = G_GPG_ERROR_SYSTEM_ERROR | 65,
    G_GPG_ERROR_EMLINK = G_GPG_ERROR_SYSTEM_ERROR | 66,
    G_GPG_ERROR_EMSGSIZE = G_GPG_ERROR_SYSTEM_ERROR | 67,
    G_GPG_ERROR_EMULTIHOP = G_GPG_ERROR_SYSTEM_ERROR | 68,
    G_GPG_ERROR_ENAMETOOLONG = G_GPG_ERROR_SYSTEM_ERROR | 69,
    G_GPG_ERROR_ENAVAIL = G_GPG_ERROR_SYSTEM_ERROR | 70,
    G_GPG_ERROR_ENEEDAUTH = G_GPG_ERROR_SYSTEM_ERROR | 71,
    G_GPG_ERROR_ENETDOWN = G_GPG_ERROR_SYSTEM_ERROR | 72,
    G_GPG_ERROR_ENETRESET = G_GPG_ERROR_SYSTEM_ERROR | 73,
    G_GPG_ERROR_ENETUNREACH = G_GPG_ERROR_SYSTEM_ERROR | 74,
    G_GPG_ERROR_ENFILE = G_GPG_ERROR_SYSTEM_ERROR | 75,
    G_GPG_ERROR_ENOANO = G_GPG_ERROR_SYSTEM_ERROR | 76,
    G_GPG_ERROR_ENOBUFS = G_GPG_ERROR_SYSTEM_ERROR | 77,
    G_GPG_ERROR_ENOCSI = G_GPG_ERROR_SYSTEM_ERROR | 78,
    G_GPG_ERROR_ENODATA = G_GPG_ERROR_SYSTEM_ERROR | 79,
    G_GPG_ERROR_ENODEV = G_GPG_ERROR_SYSTEM_ERROR | 80,
    G_GPG_ERROR_ENOENT = G_GPG_ERROR_SYSTEM_ERROR | 81,
    G_GPG_ERROR_ENOEXEC = G_GPG_ERROR_SYSTEM_ERROR | 82,
    G_GPG_ERROR_ENOLCK = G_GPG_ERROR_SYSTEM_ERROR | 83,
    G_GPG_ERROR_ENOLINK = G_GPG_ERROR_SYSTEM_ERROR | 84,
    G_GPG_ERROR_ENOMEDIUM = G_GPG_ERROR_SYSTEM_ERROR | 85,
    G_GPG_ERROR_ENOMEM = G_GPG_ERROR_SYSTEM_ERROR | 86,
    G_GPG_ERROR_ENOMSG = G_GPG_ERROR_SYSTEM_ERROR | 87,
    G_GPG_ERROR_ENONET = G_GPG_ERROR_SYSTEM_ERROR | 88,
    G_GPG_ERROR_ENOPKG = G_GPG_ERROR_SYSTEM_ERROR | 89,
    G_GPG_ERROR_ENOPROTOOPT = G_GPG_ERROR_SYSTEM_ERROR | 90,
    G_GPG_ERROR_ENOSPC = G_GPG_ERROR_SYSTEM_ERROR | 91,
    G_GPG_ERROR_ENOSR = G_GPG_ERROR_SYSTEM_ERROR | 92,
    G_GPG_ERROR_ENOSTR = G_GPG_ERROR_SYSTEM_ERROR | 93,
    G_GPG_ERROR_ENOSYS = G_GPG_ERROR_SYSTEM_ERROR | 94,
    G_GPG_ERROR_ENOTBLK = G_GPG_ERROR_SYSTEM_ERROR | 95,
    G_GPG_ERROR_ENOTCONN = G_GPG_ERROR_SYSTEM_ERROR | 96,
    G_GPG_ERROR_ENOTDIR = G_GPG_ERROR_SYSTEM_ERROR | 97,
    G_GPG_ERROR_ENOTEMPTY = G_GPG_ERROR_SYSTEM_ERROR | 98,
    G_GPG_ERROR_ENOTNAM = G_GPG_ERROR_SYSTEM_ERROR | 99,
    G_GPG_ERROR_ENOTSOCK = G_GPG_ERROR_SYSTEM_ERROR | 100,
    G_GPG_ERROR_ENOTSUP = G_GPG_ERROR_SYSTEM_ERROR | 101,
    G_GPG_ERROR_ENOTTY = G_GPG_ERROR_SYSTEM_ERROR | 102,
    G_GPG_ERROR_ENOTUNIQ = G_GPG_ERROR_SYSTEM_ERROR | 103,
    G_GPG_ERROR_ENXIO = G_GPG_ERROR_SYSTEM_ERROR | 104,
    G_GPG_ERROR_EOPNOTSUPP = G_GPG_ERROR_SYSTEM_ERROR | 105,
    G_GPG_ERROR_EOVERFLOW = G_GPG_ERROR_SYSTEM_ERROR | 106,
    G_GPG_ERROR_EPERM = G_GPG_ERROR_SYSTEM_ERROR | 107,
    G_GPG_ERROR_EPFNOSUPPORT = G_GPG_ERROR_SYSTEM_ERROR | 108,
    G_GPG_ERROR_EPIPE = G_GPG_ERROR_SYSTEM_ERROR | 109,
    G_GPG_ERROR_EPROCLIM = G_GPG_ERROR_SYSTEM_ERROR | 110,
    G_GPG_ERROR_EPROCUNAVAIL = G_GPG_ERROR_SYSTEM_ERROR | 111,
    G_GPG_ERROR_EPROGMISMATCH = G_GPG_ERROR_SYSTEM_ERROR | 112,
    G_GPG_ERROR_EPROGUNAVAIL = G_GPG_ERROR_SYSTEM_ERROR | 113,
    G_GPG_ERROR_EPROTO = G_GPG_ERROR_SYSTEM_ERROR | 114,
    G_GPG_ERROR_EPROTONOSUPPORT = G_GPG_ERROR_SYSTEM_ERROR | 115,
    G_GPG_ERROR_EPROTOTYPE = G_GPG_ERROR_SYSTEM_ERROR | 116,
    G_GPG_ERROR_ERANGE = G_GPG_ERROR_SYSTEM_ERROR | 117,
    G_GPG_ERROR_EREMCHG = G_GPG_ERROR_SYSTEM_ERROR | 118,
    G_GPG_ERROR_EREMOTE = G_GPG_ERROR_SYSTEM_ERROR | 119,
    G_GPG_ERROR_EREMOTEIO = G_GPG_ERROR_SYSTEM_ERROR | 120,
    G_GPG_ERROR_ERESTART = G_GPG_ERROR_SYSTEM_ERROR | 121,
    G_GPG_ERROR_EROFS = G_GPG_ERROR_SYSTEM_ERROR | 122,
    G_GPG_ERROR_ERPCMISMATCH = G_GPG_ERROR_SYSTEM_ERROR | 123,
    G_GPG_ERROR_ESHUTDOWN = G_GPG_ERROR_SYSTEM_ERROR | 124,
    G_GPG_ERROR_ESOCKTNOSUPPORT = G_GPG_ERROR_SYSTEM_ERROR | 125,
    G_GPG_ERROR_ESPIPE = G_GPG_ERROR_SYSTEM_ERROR | 126,
    G_GPG_ERROR_ESRCH = G_GPG_ERROR_SYSTEM_ERROR | 127,
    G_GPG_ERROR_ESRMNT = G_GPG_ERROR_SYSTEM_ERROR | 128,
    G_GPG_ERROR_ESTALE = G_GPG_ERROR_SYSTEM_ERROR | 129,
    G_GPG_ERROR_ESTRPIPE = G_GPG_ERROR_SYSTEM_ERROR | 130,
    G_GPG_ERROR_ETIME = G_GPG_ERROR_SYSTEM_ERROR | 131,
    G_GPG_ERROR_ETIMEDOUT = G_GPG_ERROR_SYSTEM_ERROR | 132,
    G_GPG_ERROR_ETOOMANYREFS = G_GPG_ERROR_SYSTEM_ERROR | 133,
    G_GPG_ERROR_ETXTBSY = G_GPG_ERROR_SYSTEM_ERROR | 134,
    G_GPG_ERROR_EUCLEAN = G_GPG_ERROR_SYSTEM_ERROR | 135,
    G_GPG_ERROR_EUNATCH = G_GPG_ERROR_SYSTEM_ERROR | 136,
    G_GPG_ERROR_EUSERS = G_GPG_ERROR_SYSTEM_ERROR | 137,
    G_GPG_ERROR_EWOULDBLOCK = G_GPG_ERROR_SYSTEM_ERROR | 138,
    G_GPG_ERROR_EXDEV = G_GPG_ERROR_SYSTEM_ERROR | 139,
    G_GPG_ERROR_EXFULL = G_GPG_ERROR_SYSTEM_ERROR | 140,

    /* This is one more than the largest allowed entry.  */
    G_GPG_ERROR_CODE_DIM = 65536
  }
GGpgError;

typedef enum
  {
    G_GPG_SUBKEY_FLAG_REVOKED = 1 << 0,
    G_GPG_SUBKEY_FLAG_EXPIRED = 1 << 1,
    G_GPG_SUBKEY_FLAG_DISABLED = 1 << 2,
    G_GPG_SUBKEY_FLAG_INVALID = 1 << 3,
    G_GPG_SUBKEY_FLAG_CAN_ENCRYPT = 1 << 4,
    G_GPG_SUBKEY_FLAG_CAN_SIGN = 1 << 5,
    G_GPG_SUBKEY_FLAG_CAN_CERTIFY = 1 << 6,
    G_GPG_SUBKEY_FLAG_SECRET = 1 << 7,
    G_GPG_SUBKEY_FLAG_CAN_AUTHENTICATE = 1 << 8,
    G_GPG_SUBKEY_FLAG_IS_QUALIFIED = 1 << 9,
    G_GPG_SUBKEY_FLAG_IS_CARDKEY = 1 << 10
  }
GGpgSubkeyFlags;

typedef enum
  {
    G_GPG_USER_ID_FLAG_REVOKED = 1 << 0,
    G_GPG_USER_ID_FLAG_INVALID = 1 << 1
  }
GGpgUserIdFlags;

typedef enum
  {
    G_GPG_KEY_SIG_FLAG_REVOKED = 1 << 0,
    G_GPG_KEY_SIG_FLAG_EXPIRED = 1 << 1,
    G_GPG_KEY_SIG_FLAG_INVALID = 1 << 2,
    G_GPG_KEY_SIG_FLAG_EXPORTABLE = 1 << 3
  }
GGpgKeySigFlags;

typedef enum
  {
    G_GPG_KEY_FLAG_REVOKED = 1 << 0,
    G_GPG_KEY_FLAG_EXPIRED = 1 << 1,
    G_GPG_KEY_FLAG_DISABLED = 1 << 2,
    G_GPG_KEY_FLAG_INVALID = 1 << 3,
    G_GPG_KEY_FLAG_CAN_ENCRYPT = 1 << 4,
    G_GPG_KEY_FLAG_CAN_SIGN = 1 << 5,
    G_GPG_KEY_FLAG_CAN_CERTIFY = 1 << 6,
    G_GPG_KEY_FLAG_SECRET = 1 << 7,
    G_GPG_KEY_FLAG_CAN_AUTHENTICATE = 1 << 8,
    G_GPG_KEY_FLAG_IS_QUALIFIED = 1 << 9
  }
GGpgKeyFlags;

typedef enum
  {
    G_GPG_GET_KEY_FLAG_NONE = 0,
    G_GPG_GET_KEY_FLAG_SECRET = 1
  }
GGpgGetKeyFlags;

typedef enum
  {
    G_GPG_DELETE_FLAG_NONE = 0,
    G_GPG_DELETE_FLAG_ALLOW_SECRET = 1
  }
GGpgDeleteFlags;

typedef enum
  {
    G_GPG_CHANGE_PASSWORD_FLAG_NONE = 0
  }
GGpgChangePasswordFlags;

typedef enum
  {
    G_GPG_EXPORT_MODE_EXTERN = 2,
    G_GPG_EXPORT_MODE_MINIMAL = 4
  }
GGpgExportMode;

G_END_DECLS

#endif  /* GPGME_GLIB_ENUMS_H_ */
