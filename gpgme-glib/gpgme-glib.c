#include "config.h"
#include <gpgme.h>
#include "gpgme-glib/gpgme-glib.h"

GQuark
g_gpg_error_quark (void)
{
  return g_quark_from_static_string ("g-gpg-error-quark");
}

/**
 * g_gpg_check_version:
 * @version: (nullable): minimum required version of GPGME
 *
 */
void
g_gpg_check_version (const gchar *version)
{
  gpgme_check_version (version);
}

struct _GGpgEngineInfo
{
  GObject parent;
  gpgme_engine_info_t pointer;
};

G_DEFINE_TYPE (GGpgEngineInfo, g_gpg_engine_info, G_TYPE_OBJECT)

enum {
  ENGINE_INFO_PROP_0,
  ENGINE_INFO_PROP_POINTER,
  ENGINE_INFO_PROP_PROTOCOL,
  ENGINE_INFO_PROP_EXECUTABLE_NAME,
  ENGINE_INFO_PROP_VERSION,
  ENGINE_INFO_PROP_REQUIRED_VERSION,
  ENGINE_INFO_PROP_HOME_DIR,
  ENGINE_INFO_LAST_PROP
};

static GParamSpec *engine_info_pspecs[ENGINE_INFO_LAST_PROP] = { NULL, };

static void
g_gpg_engine_info_set_property (GObject *object,
                                guint property_id,
                                const GValue *value,
                                GParamSpec *pspec)
{
  GGpgEngineInfo *engine_info = G_GPG_ENGINE_INFO (object);

  switch (property_id)
    {
    case ENGINE_INFO_PROP_POINTER:
      engine_info->pointer = g_value_get_pointer (value);
      break;

    case ENGINE_INFO_PROP_PROTOCOL:
      engine_info->pointer->protocol = g_value_get_enum (value);
      break;

    case ENGINE_INFO_PROP_EXECUTABLE_NAME:
      g_free (engine_info->pointer->file_name);
      engine_info->pointer->file_name = g_value_dup_string (value);
      break;

    case ENGINE_INFO_PROP_VERSION:
      g_free (engine_info->pointer->version);
      engine_info->pointer->version = g_value_dup_string (value);
      break;

    case ENGINE_INFO_PROP_HOME_DIR:
      g_free (engine_info->pointer->home_dir);
      engine_info->pointer->home_dir = g_value_dup_string (value);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_engine_info_get_property (GObject *object,
                                guint property_id,
                                GValue *value,
                                GParamSpec *pspec)
{
  GGpgEngineInfo *engine_info = G_GPG_ENGINE_INFO (object);

  switch (property_id)
    {
    case ENGINE_INFO_PROP_PROTOCOL:
      g_value_set_enum (value, engine_info->pointer->protocol);
      break;

    case ENGINE_INFO_PROP_EXECUTABLE_NAME:
      g_value_set_string (value, engine_info->pointer->file_name);
      break;

    case ENGINE_INFO_PROP_VERSION:
      g_value_set_string (value, engine_info->pointer->version);
      break;

    case ENGINE_INFO_PROP_REQUIRED_VERSION:
      g_value_set_string (value, engine_info->pointer->req_version);
      break;

    case ENGINE_INFO_PROP_HOME_DIR:
      g_value_set_string (value, engine_info->pointer->home_dir);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_engine_info_class_init (GGpgEngineInfoClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_engine_info_set_property;
  object_class->get_property = g_gpg_engine_info_get_property;

  engine_info_pspecs[ENGINE_INFO_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);
  engine_info_pspecs[ENGINE_INFO_PROP_PROTOCOL] =
    g_param_spec_enum ("protocol", NULL, NULL,
                       G_GPG_TYPE_PROTOCOL, G_GPG_PROTOCOL_OpenPGP,
                       G_PARAM_READWRITE);
  engine_info_pspecs[ENGINE_INFO_PROP_EXECUTABLE_NAME] =
    g_param_spec_string ("executable-name", NULL, NULL, "", G_PARAM_READWRITE);
  engine_info_pspecs[ENGINE_INFO_PROP_VERSION] =
    g_param_spec_string ("version", NULL, NULL, "", G_PARAM_READWRITE);
  engine_info_pspecs[ENGINE_INFO_PROP_REQUIRED_VERSION] =
    g_param_spec_string ("required-version", NULL, NULL, "", G_PARAM_READABLE);
  engine_info_pspecs[ENGINE_INFO_PROP_HOME_DIR] =
    g_param_spec_string ("home-dir", NULL, NULL, "", G_PARAM_READWRITE);

  g_object_class_install_properties (object_class, ENGINE_INFO_LAST_PROP,
                                     engine_info_pspecs);
}

static void
g_gpg_engine_info_init (GGpgEngineInfo *engine_info)
{
}

struct _GGpgData
{
  GObject parent;
  gpgme_data_t pointer;
};

G_DEFINE_TYPE (GGpgData, g_gpg_data, G_TYPE_OBJECT)

enum {
  DATA_PROP_0,
  DATA_PROP_POINTER,
  DATA_LAST_PROP
};

static GParamSpec *data_pspecs[DATA_LAST_PROP] = { NULL, };

static void
g_gpg_data_set_property (GObject *object,
                         guint property_id,
                         const GValue *value,
                         GParamSpec *pspec)
{
  GGpgData *data = G_GPG_DATA (object);

  switch (property_id)
    {
    case DATA_PROP_POINTER:
      data->pointer = g_value_get_pointer (value);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_data_finalize (GObject *object)
{
  GGpgData *data = G_GPG_DATA (object);

  g_clear_pointer (&data->pointer, (GDestroyNotify) gpgme_data_release);

  G_OBJECT_CLASS (g_gpg_data_parent_class)->finalize (object);
}

static void
g_gpg_data_class_init (GGpgDataClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_data_set_property;
  object_class->finalize = g_gpg_data_finalize;

  data_pspecs[DATA_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);

  g_object_class_install_properties (object_class, DATA_LAST_PROP, data_pspecs);
}

static void
g_gpg_data_init (GGpgData *data)
{
}

GGpgData *
g_gpg_data_new (void)
{
  gpgme_data_t data;
  gpgme_error_t err;

  err = gpgme_data_new (&data);
  g_return_val_if_fail (err == 0, NULL);

  return g_object_new (G_GPG_TYPE_DATA, "pointer", data, NULL);
}

GGpgData *
g_gpg_data_new_from_bytes (GBytes *bytes)
{
  gpgme_data_t data;
  gconstpointer ptr;
  gsize size;
  gpgme_error_t err;

  ptr = g_bytes_get_data (bytes, &size);
  err = gpgme_data_new_from_mem (&data, ptr, size, 0);
  g_return_val_if_fail (err == 0, NULL);

  return g_object_new (G_GPG_TYPE_DATA, "pointer", data, NULL);
}

GGpgData *
g_gpg_data_new_from_fd (gint fd, GError **error)
{
  gpgme_data_t data;
  gpgme_error_t err;

  err = gpgme_data_new_from_fd (&data, fd);
  g_return_val_if_fail (err == 0, NULL);

  return g_object_new (G_GPG_TYPE_DATA, "pointer", data, NULL);
}

gssize
g_gpg_data_read (GGpgData *data, gpointer buffer, gsize size)
{
  return gpgme_data_read (data->pointer, buffer, size);
}

gssize
g_gpg_data_write (GGpgData *data, gconstpointer buffer, gsize size)
{
  return gpgme_data_write (data->pointer, buffer, size);
}

goffset
g_gpg_data_seek (GGpgData *data, goffset offset, GSeekType whence)
{
  return gpgme_data_seek (data->pointer, offset, whence);
}

/**
 * g_gpg_data_free_to_bytes:
 * @data: (transfer full): a #GGpgData
 *
 * Returns: (transfer full): a new #GBytes
 */
GBytes *
g_gpg_data_free_to_bytes (GGpgData *data)
{
  size_t size;
  char *ptr = gpgme_data_release_and_get_mem (data->pointer, &size);
  data->pointer = NULL;
  return g_bytes_new_with_free_func (ptr, size, gpgme_free, ptr);
}

struct _GGpgCtx
{
  GObject parent;
  gpgme_ctx_t pointer;
  gpointer progress_user_data;
  GDestroyNotify progress_destroy_data;
};

G_DEFINE_TYPE (GGpgCtx, g_gpg_ctx, G_TYPE_OBJECT)

enum {
  CTX_PROP_0,
  CTX_PROP_POINTER,
  CTX_PROP_PROTOCOL,
  CTX_PROP_ARMOR,
  CTX_PROP_TEXTMODE,
  CTX_PROP_INCLUDE_CERTS,
  CTX_PROP_KEYLIST_MODE,
  CTX_PROP_PINENTRY_MODE,
  CTX_PROP_ENGINE_INFO,
  CTX_LAST_PROP
};

static GParamSpec *ctx_pspecs[CTX_LAST_PROP] = { NULL, };

static void
g_gpg_ctx_set_property (GObject *object,
                        guint property_id,
                        const GValue *value,
                        GParamSpec *pspec)
{
  GGpgCtx *ctx = G_GPG_CTX (object);

  switch (property_id)
    {
    case CTX_PROP_POINTER:
      ctx->pointer = g_value_get_pointer (value);
      break;

    case CTX_PROP_PROTOCOL:
      gpgme_set_protocol (ctx->pointer, g_value_get_enum (value));
      break;

    case CTX_PROP_ARMOR:
      gpgme_set_armor (ctx->pointer, g_value_get_boolean (value));
      break;

    case CTX_PROP_TEXTMODE:
      gpgme_set_textmode (ctx->pointer, g_value_get_boolean (value));
      break;

    case CTX_PROP_INCLUDE_CERTS:
      gpgme_set_include_certs (ctx->pointer, g_value_get_boolean (value));
      break;

    case CTX_PROP_KEYLIST_MODE:
      gpgme_set_keylist_mode (ctx->pointer, g_value_get_flags (value));
      break;

    case CTX_PROP_PINENTRY_MODE:
      gpgme_set_pinentry_mode (ctx->pointer, g_value_get_enum (value));
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_ctx_get_property (GObject *object,
                        guint property_id,
                        GValue *value,
                        GParamSpec *pspec)
{
  GGpgCtx *ctx = G_GPG_CTX (object);

  switch (property_id)
    {
    case CTX_PROP_PROTOCOL:
      g_value_set_enum (value, gpgme_get_protocol (ctx->pointer));
      break;

    case CTX_PROP_ARMOR:
      g_value_set_boolean (value, gpgme_get_armor (ctx->pointer));
      break;

    case CTX_PROP_TEXTMODE:
      g_value_set_boolean (value, gpgme_get_textmode (ctx->pointer));
      break;

    case CTX_PROP_INCLUDE_CERTS:
      g_value_set_boolean (value, gpgme_get_include_certs (ctx->pointer));
      break;

    case CTX_PROP_KEYLIST_MODE:
      g_value_set_flags (value, gpgme_get_keylist_mode (ctx->pointer));
      break;

    case CTX_PROP_PINENTRY_MODE:
      g_value_set_enum (value, gpgme_get_pinentry_mode (ctx->pointer));
      break;

    case CTX_PROP_ENGINE_INFO:
      g_value_set_object (value, gpgme_ctx_get_engine_info (ctx->pointer));
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_ctx_finalize (GObject *object)
{
  GGpgCtx *ctx = G_GPG_CTX (object);

  gpgme_release (ctx->pointer);

  if (ctx->progress_destroy_data)
    g_clear_pointer (&ctx->progress_user_data, ctx->progress_destroy_data);

  G_OBJECT_CLASS (g_gpg_ctx_parent_class)->finalize (object);
}

static void
g_gpg_ctx_class_init (GGpgCtxClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_ctx_set_property;
  object_class->get_property = g_gpg_ctx_get_property;
  object_class->finalize = g_gpg_ctx_finalize;

  ctx_pspecs[CTX_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);
  ctx_pspecs[CTX_PROP_PROTOCOL] =
    g_param_spec_enum ("protocol", NULL, NULL,
                       G_GPG_TYPE_PROTOCOL, G_GPG_PROTOCOL_OpenPGP,
                       G_PARAM_READWRITE);
  ctx_pspecs[CTX_PROP_ARMOR] =
    g_param_spec_boolean ("armor", NULL, NULL, FALSE, G_PARAM_READWRITE);
  ctx_pspecs[CTX_PROP_TEXTMODE] =
    g_param_spec_boolean ("textmode", NULL, NULL, FALSE, G_PARAM_READWRITE);
  ctx_pspecs[CTX_PROP_INCLUDE_CERTS] =
    g_param_spec_boolean ("include_certs", NULL, NULL, FALSE,
                          G_PARAM_READWRITE);
  ctx_pspecs[CTX_PROP_KEYLIST_MODE] =
    g_param_spec_flags ("keylist-mode", NULL, NULL,
                        G_GPG_TYPE_KEYLIST_MODE, G_GPG_KEYLIST_MODE_LOCAL,
                        G_PARAM_READWRITE);
  ctx_pspecs[CTX_PROP_PINENTRY_MODE] =
    g_param_spec_enum ("pinentry-mode", NULL, NULL,
                       G_GPG_TYPE_PINENTRY_MODE, G_GPG_PINENTRY_MODE_DEFAULT,
                       G_PARAM_READWRITE);
  ctx_pspecs[CTX_PROP_ENGINE_INFO] =
    g_param_spec_object ("engine-info", NULL, NULL,
                         G_GPG_TYPE_ENGINE_INFO, G_PARAM_READABLE);

  g_object_class_install_properties (object_class, CTX_LAST_PROP, ctx_pspecs);
}

static void
g_gpg_ctx_init (GGpgCtx *ctx)
{
}

GGpgCtx *
g_gpg_ctx_new (GError **error)
{
  gpgme_ctx_t ctx;
  gpgme_error_t err;

  err = gpgme_new (&ctx);
  if (err)
    {
      g_set_error (error, G_GPG_ERROR, gpgme_err_code (err),
                   "%s", gpgme_strerror (err));
      return NULL;
    }

  return g_object_new (G_GPG_TYPE_CTX, "pointer", ctx, NULL);
}

void
g_gpg_ctx_set_progress_callback (GGpgCtx *ctx,
                                 GGpgProgressCallback callback,
                                 gpointer user_data,
                                 GDestroyNotify destroy_data)
{
  if (ctx->progress_destroy_data)
    g_clear_pointer (&ctx->progress_user_data, ctx->progress_destroy_data);

  ctx->progress_user_data = user_data;
  ctx->progress_destroy_data = destroy_data;

  gpgme_set_progress_cb (ctx->pointer, (gpgme_progress_cb_t) callback,
                         user_data);
}

struct _GGpgSubkey
{
  GObject parent;
  gpgme_subkey_t pointer;
  GGpgSubkeyFlags flags;
};

G_DEFINE_TYPE (GGpgSubkey, g_gpg_subkey, G_TYPE_OBJECT)

enum {
  SUBKEY_PROP_0,
  SUBKEY_PROP_POINTER,
  SUBKEY_PROP_FLAGS,
  SUBKEY_PROP_PUBKEY_ALGO,
  SUBKEY_PROP_LENGTH,
  SUBKEY_PROP_FINGERPRINT,
  SUBKEY_PROP_TIMESTAMP,
  SUBKEY_PROP_EXPIRES,
  SUBKEY_PROP_CARD_NUMBER,
  SUBKEY_PROP_CURVE,
  SUBKEY_LAST_PROP
};

static GParamSpec *subkey_pspecs[SUBKEY_LAST_PROP] = { NULL, };

static void
g_gpg_subkey_set_property (GObject *object,
                        guint property_id,
                        const GValue *value,
                        GParamSpec *pspec)
{
  GGpgSubkey *subkey = G_GPG_SUBKEY (object);

  switch (property_id)
    {
    case SUBKEY_PROP_POINTER:
      subkey->pointer = g_value_get_pointer (value);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_subkey_get_property (GObject *object,
                           guint property_id,
                           GValue *value,
                           GParamSpec *pspec)
{
  GGpgSubkey *subkey = G_GPG_SUBKEY (object);

  switch (property_id)
    {
    case SUBKEY_PROP_FLAGS:
      g_value_set_flags (value, subkey->flags);
      break;

    case SUBKEY_PROP_PUBKEY_ALGO:
      g_value_set_enum (value, subkey->pointer->pubkey_algo);
      break;

    case SUBKEY_PROP_LENGTH:
      g_value_set_uint (value, subkey->pointer->length);
      break;

    case SUBKEY_PROP_FINGERPRINT:
      g_value_set_string (value, subkey->pointer->fpr);
      break;

    case SUBKEY_PROP_TIMESTAMP:
      g_value_set_int64 (value, subkey->pointer->timestamp);
      break;

    case SUBKEY_PROP_EXPIRES:
      g_value_set_int64 (value, subkey->pointer->expires);
      break;

    case SUBKEY_PROP_CARD_NUMBER:
      g_value_set_string (value, subkey->pointer->card_number);
      break;

#if defined(GPGME_VERSION_NUMBER) && GPGME_VERSION_NUMBER >= 0x010500
    case SUBKEY_PROP_CURVE:
      g_value_set_string (value, subkey->pointer->curve);
      break;
#endif

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_subkey_constructed (GObject *object)
{
  GGpgSubkey *subkey = G_GPG_SUBKEY (object);

  G_OBJECT_CLASS (g_gpg_subkey_parent_class)->constructed (object);

  subkey->flags = 0;

  if (subkey->pointer->revoked)
    subkey->flags |= G_GPG_SUBKEY_FLAG_REVOKED;
  if (subkey->pointer->expired)
    subkey->flags |= G_GPG_SUBKEY_FLAG_EXPIRED;
  if (subkey->pointer->disabled)
    subkey->flags |= G_GPG_SUBKEY_FLAG_DISABLED;
  if (subkey->pointer->invalid)
    subkey->flags |= G_GPG_SUBKEY_FLAG_INVALID;
  if (subkey->pointer->can_encrypt)
    subkey->flags |= G_GPG_SUBKEY_FLAG_CAN_ENCRYPT;
  if (subkey->pointer->can_sign)
    subkey->flags |= G_GPG_SUBKEY_FLAG_CAN_SIGN;
  if (subkey->pointer->can_certify)
    subkey->flags |= G_GPG_SUBKEY_FLAG_CAN_CERTIFY;
  if (subkey->pointer->secret)
    subkey->flags |= G_GPG_SUBKEY_FLAG_SECRET;
  if (subkey->pointer->can_authenticate)
    subkey->flags |= G_GPG_SUBKEY_FLAG_CAN_AUTHENTICATE;
  if (subkey->pointer->is_qualified)
    subkey->flags |= G_GPG_SUBKEY_FLAG_IS_QUALIFIED;
  if (subkey->pointer->is_cardkey)
    subkey->flags |= G_GPG_SUBKEY_FLAG_IS_CARDKEY;
}

static void
g_gpg_subkey_class_init (GGpgSubkeyClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_subkey_set_property;
  object_class->get_property = g_gpg_subkey_get_property;
  object_class->constructed = g_gpg_subkey_constructed;

  subkey_pspecs[SUBKEY_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);
  subkey_pspecs[SUBKEY_PROP_FLAGS] =
    g_param_spec_flags ("flags", NULL, NULL,
                        G_GPG_TYPE_SUBKEY_FLAGS, 0,
                        G_PARAM_READABLE);
  subkey_pspecs[SUBKEY_PROP_PUBKEY_ALGO] =
    g_param_spec_enum ("pubkey-algo", NULL, NULL,
                       G_GPG_TYPE_PUBKEY_ALGO,
                       G_GPG_PK_RSA,
                       G_PARAM_READABLE);
  subkey_pspecs[SUBKEY_PROP_LENGTH] =
    g_param_spec_uint ("length", NULL, NULL,
                       0, G_MAXUINT, 0,
                       G_PARAM_READABLE);
  subkey_pspecs[SUBKEY_PROP_FINGERPRINT] =
    g_param_spec_string ("fingerprint", NULL, NULL,
                         NULL,
                         G_PARAM_READABLE);
  subkey_pspecs[SUBKEY_PROP_TIMESTAMP] =
    g_param_spec_int64 ("timestamp", NULL, NULL,
                        0, G_MAXINT64, 0,
                        G_PARAM_READABLE);
  subkey_pspecs[SUBKEY_PROP_EXPIRES] =
    g_param_spec_int64 ("expires", NULL, NULL,
                        0, G_MAXINT64, 0,
                        G_PARAM_READABLE);
  subkey_pspecs[SUBKEY_PROP_CARD_NUMBER] =
    g_param_spec_string ("card-number", NULL, NULL,
                         NULL,
                         G_PARAM_READABLE);
  subkey_pspecs[SUBKEY_PROP_CURVE] =
    g_param_spec_string ("curve", NULL, NULL,
                         NULL,
                         G_PARAM_READABLE);

  g_object_class_install_properties (object_class, SUBKEY_LAST_PROP,
                                     subkey_pspecs);
}

static void
g_gpg_subkey_init (GGpgSubkey *subkey)
{
}

struct _GGpgKeySig
{
  GObject parent;
  gpgme_key_sig_t pointer;
  GGpgKeySigFlags flags;
};

G_DEFINE_TYPE (GGpgKeySig, g_gpg_key_sig, G_TYPE_OBJECT)

enum {
  KEY_SIG_PROP_0,
  KEY_SIG_PROP_POINTER,
  KEY_SIG_PROP_FLAGS,
  KEY_SIG_PROP_PUBKEY_ALGO,
  KEY_SIG_PROP_KEYID,
  KEY_SIG_PROP_TIMESTAMP,
  KEY_SIG_PROP_EXPIRES,
  KEY_SIG_PROP_UID,
  KEY_SIG_PROP_NAME,
  KEY_SIG_PROP_EMAIL,
  KEY_SIG_PROP_COMMENT,
  KEY_SIG_PROP_SIG_CLASS,
  KEY_SIG_LAST_PROP
};

static GParamSpec *key_sig_pspecs[KEY_SIG_LAST_PROP] = { NULL, };

static void
g_gpg_key_sig_set_property (GObject *object,
                            guint property_id,
                            const GValue *value,
                            GParamSpec *pspec)
{
  GGpgKeySig *key_sig = G_GPG_KEY_SIG (object);

  switch (property_id)
    {
    case KEY_SIG_PROP_POINTER:
      key_sig->pointer = g_value_get_pointer (value);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_key_sig_get_property (GObject *object,
                            guint property_id,
                            GValue *value,
                            GParamSpec *pspec)
{
  GGpgKeySig *key_sig = G_GPG_KEY_SIG (object);

  switch (property_id)
    {
    case KEY_SIG_PROP_FLAGS:
      g_value_set_flags (value, key_sig->flags);
      break;

    case KEY_SIG_PROP_PUBKEY_ALGO:
      g_value_set_enum (value, key_sig->pointer->pubkey_algo);
      break;

    case KEY_SIG_PROP_KEYID:
      g_value_set_string (value, key_sig->pointer->keyid);
      break;

    case KEY_SIG_PROP_TIMESTAMP:
      g_value_set_int64 (value, key_sig->pointer->timestamp);
      break;

    case KEY_SIG_PROP_EXPIRES:
      g_value_set_int64 (value, key_sig->pointer->expires);
      break;

    case KEY_SIG_PROP_UID:
      g_value_set_string (value, key_sig->pointer->uid);
      break;

    case KEY_SIG_PROP_NAME:
      g_value_set_string (value, key_sig->pointer->name);
      break;

    case KEY_SIG_PROP_EMAIL:
      g_value_set_string (value, key_sig->pointer->email);
      break;

    case KEY_SIG_PROP_COMMENT:
      g_value_set_string (value, key_sig->pointer->comment);
      break;

    case KEY_SIG_PROP_SIG_CLASS:
      g_value_set_uint (value, key_sig->pointer->sig_class);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_key_sig_constructed (GObject *object)
{
  GGpgKeySig *key_sig = G_GPG_KEY_SIG (object);

  G_OBJECT_CLASS (g_gpg_key_sig_parent_class)->constructed (object);

  key_sig->flags = 0;

  if (key_sig->pointer->revoked)
    key_sig->flags |= G_GPG_KEY_SIG_FLAG_REVOKED;
  if (key_sig->pointer->expired)
    key_sig->flags |= G_GPG_KEY_SIG_FLAG_EXPIRED;
  if (key_sig->pointer->invalid)
    key_sig->flags |= G_GPG_KEY_SIG_FLAG_INVALID;
  if (key_sig->pointer->exportable)
    key_sig->flags |= G_GPG_KEY_SIG_FLAG_EXPORTABLE;
}

static void
g_gpg_key_sig_class_init (GGpgKeySigClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_key_sig_set_property;
  object_class->get_property = g_gpg_key_sig_get_property;
  object_class->constructed = g_gpg_key_sig_constructed;

  key_sig_pspecs[KEY_SIG_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);
  key_sig_pspecs[KEY_SIG_PROP_FLAGS] =
    g_param_spec_flags ("flags", NULL, NULL,
                        G_GPG_TYPE_KEY_SIG_FLAGS,
                        0,
                        G_PARAM_READABLE);
  key_sig_pspecs[KEY_SIG_PROP_PUBKEY_ALGO] =
    g_param_spec_enum ("pubkey-algo", NULL, NULL,
                       G_GPG_TYPE_PUBKEY_ALGO,
                       G_GPG_PK_RSA,
                       G_PARAM_READABLE);
  key_sig_pspecs[KEY_SIG_PROP_KEYID] =
    g_param_spec_string ("keyid", NULL, NULL, "", G_PARAM_READABLE);
  key_sig_pspecs[KEY_SIG_PROP_TIMESTAMP] =
    g_param_spec_int64 ("timestamp", NULL, NULL,
                        0, G_MAXINT64, 0,
                        G_PARAM_READABLE);
  key_sig_pspecs[KEY_SIG_PROP_EXPIRES] =
    g_param_spec_int64 ("expires", NULL, NULL,
                        0, G_MAXINT64, 0,
                        G_PARAM_READABLE);
  key_sig_pspecs[KEY_SIG_PROP_UID] =
    g_param_spec_string ("uid", NULL, NULL, "", G_PARAM_READABLE);
  key_sig_pspecs[KEY_SIG_PROP_NAME] =
    g_param_spec_string ("name", NULL, NULL, "", G_PARAM_READABLE);
  key_sig_pspecs[KEY_SIG_PROP_EMAIL] =
    g_param_spec_string ("email", NULL, NULL, "", G_PARAM_READABLE);
  key_sig_pspecs[KEY_SIG_PROP_COMMENT] =
    g_param_spec_string ("comment", NULL, NULL, "", G_PARAM_READABLE);
  key_sig_pspecs[KEY_SIG_PROP_SIG_CLASS] =
    g_param_spec_uint ("sig-class", NULL, NULL,
                       0, G_MAXUINT, 0,
                       G_PARAM_READABLE);

  g_object_class_install_properties (object_class, KEY_SIG_LAST_PROP,
                                     key_sig_pspecs);
}

static void
g_gpg_key_sig_init (GGpgKeySig *key_sig)
{
}

struct _GGpgUserId
{
  GObject parent;
  gpgme_user_id_t pointer;
  GGpgUserIdFlags flags;
};

G_DEFINE_TYPE (GGpgUserId, g_gpg_user_id, G_TYPE_OBJECT);

enum {
  USER_ID_PROP_0,
  USER_ID_PROP_POINTER,
  USER_ID_PROP_FLAGS,
  USER_ID_PROP_VALIDITY,
  USER_ID_PROP_UID,
  USER_ID_PROP_NAME,
  USER_ID_PROP_EMAIL,
  USER_ID_PROP_COMMENT,
  USER_ID_LAST_PROP
};

static GParamSpec *user_id_pspecs[USER_ID_LAST_PROP] = { NULL, };

static void
g_gpg_user_id_set_property (GObject *object,
                         guint property_id,
                         const GValue *value,
                         GParamSpec *pspec)
{
  GGpgUserId *user_id = G_GPG_USER_ID (object);

  switch (property_id)
    {
    case USER_ID_PROP_POINTER:
      user_id->pointer = g_value_get_pointer (value);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_user_id_get_property (GObject *object,
                         guint property_id,
                         GValue *value,
                         GParamSpec *pspec)
{
  GGpgUserId *user_id = G_GPG_USER_ID (object);

  switch (property_id)
    {
    case USER_ID_PROP_FLAGS:
      g_value_set_flags (value, user_id->flags);
      break;

    case USER_ID_PROP_VALIDITY:
      g_value_set_enum (value, user_id->pointer->validity);
      break;

    case USER_ID_PROP_UID:
      g_value_set_string (value, user_id->pointer->uid);
      break;

    case USER_ID_PROP_NAME:
      g_value_set_string (value, user_id->pointer->name);
      break;

    case USER_ID_PROP_EMAIL:
      g_value_set_string (value, user_id->pointer->email);
      break;

    case USER_ID_PROP_COMMENT:
      g_value_set_string (value, user_id->pointer->comment);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_user_id_constructed (GObject *object)
{
  GGpgUserId *user_id = G_GPG_USER_ID (object);

  G_OBJECT_CLASS (g_gpg_user_id_parent_class)->constructed (object);

  user_id->flags = 0;
  if (user_id->pointer->revoked)
    user_id->flags |= G_GPG_USER_ID_FLAG_REVOKED;
  if (user_id->pointer->invalid)
    user_id->flags |= G_GPG_USER_ID_FLAG_INVALID;
}

static void
g_gpg_user_id_class_init (GGpgUserIdClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_user_id_set_property;
  object_class->get_property = g_gpg_user_id_get_property;
  object_class->constructed = g_gpg_user_id_constructed;

  user_id_pspecs[USER_ID_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);
  user_id_pspecs[USER_ID_PROP_FLAGS] =
    g_param_spec_flags ("flags", NULL, NULL,
                        G_GPG_TYPE_USER_ID_FLAGS, 0,
                        G_PARAM_READABLE);
  user_id_pspecs[USER_ID_PROP_VALIDITY] =
    g_param_spec_enum ("validity", NULL, NULL,
                       G_GPG_TYPE_VALIDITY, G_GPG_VALIDITY_UNKNOWN,
                       G_PARAM_READABLE);
  user_id_pspecs[USER_ID_PROP_UID] =
    g_param_spec_string ("uid", NULL, NULL, "", G_PARAM_READABLE);
  user_id_pspecs[USER_ID_PROP_NAME] =
    g_param_spec_string ("name", NULL, NULL, "", G_PARAM_READABLE);
  user_id_pspecs[USER_ID_PROP_EMAIL] =
    g_param_spec_string ("email", NULL, NULL, "", G_PARAM_READABLE);
  user_id_pspecs[USER_ID_PROP_COMMENT] =
    g_param_spec_string ("comment", NULL, NULL, "", G_PARAM_READABLE);

  g_object_class_install_properties (object_class, USER_ID_LAST_PROP,
                                     user_id_pspecs);
}

static void
g_gpg_user_id_init (GGpgUserId *user_id)
{
}

/**
 * g_gpg_user_id_get_signatures:
 * @user_id: a #GGpgUserId
 *
 * Returns: (transfer container) (element-type GGpgKeySig): a list of #GGpgKeySig
 */
GList *
g_gpg_user_id_get_signatures (GGpgUserId *user_id)
{
  gpgme_key_sig_t signatures = user_id->pointer->signatures;
  GList *result = NULL;

  for (; signatures; signatures = signatures->next)
    {
      GGpgKeySig *signature =
        g_object_new (G_GPG_TYPE_KEY_SIG, "pointer", signatures, NULL);
      result = g_list_append (result, signature);
    }
  return result;
}

struct _GGpgKey
{
  GObject parent;
  gpgme_key_t pointer;
  GGpgKeyFlags flags;
};

G_DEFINE_TYPE (GGpgKey, g_gpg_key, G_TYPE_OBJECT)

enum {
  KEY_PROP_0,
  KEY_PROP_POINTER,
  KEY_PROP_FLAGS,
  KEY_PROP_PROTOCOL,
  KEY_PROP_ISSUER_SERIAL,
  KEY_PROP_ISSUER_NAME,
  KEY_PROP_CHAIN_ID,
  KEY_PROP_OWNER_TRUST,
  KEY_PROP_KEYLIST_MODE,
  KEY_LAST_PROP
};

static GParamSpec *key_pspecs[KEY_LAST_PROP] = { NULL, };

static void
g_gpg_key_set_property (GObject *object,
                        guint property_id,
                        const GValue *value,
                        GParamSpec *pspec)
{
  GGpgKey *key = G_GPG_KEY (object);

  switch (property_id)
    {
    case KEY_PROP_POINTER:
      key->pointer = g_value_get_pointer (value);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_key_get_property (GObject *object,
                        guint property_id,
                        GValue *value,
                        GParamSpec *pspec)
{
  GGpgKey *key = G_GPG_KEY (object);

  switch (property_id)
    {
    case KEY_PROP_FLAGS:
      g_value_set_flags (value, key->flags);
      break;

    case KEY_PROP_PROTOCOL:
      g_value_set_enum (value, key->pointer->protocol);
      break;

    case KEY_PROP_ISSUER_SERIAL:
      g_value_set_string (value, key->pointer->issuer_serial);
      break;

    case KEY_PROP_ISSUER_NAME:
      g_value_set_string (value, key->pointer->issuer_name);
      break;

    case KEY_PROP_CHAIN_ID:
      g_value_set_string (value, key->pointer->chain_id);
      break;

    case KEY_PROP_OWNER_TRUST:
      g_value_set_enum (value, key->pointer->owner_trust);
      break;

    case KEY_PROP_KEYLIST_MODE:
      g_value_set_flags (value, key->pointer->keylist_mode);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_key_finalize (GObject *object)
{
  GGpgKey *key = G_GPG_KEY (object);

  gpgme_key_unref (key->pointer);

  G_OBJECT_CLASS (g_gpg_key_parent_class)->finalize (object);
}

static void
g_gpg_key_constructed (GObject *object)
{
  GGpgKey *key = G_GPG_KEY (object);

  G_OBJECT_CLASS (g_gpg_key_parent_class)->constructed (object);

  key->flags = 0;
  if (key->pointer->revoked)
    key->flags |= G_GPG_KEY_FLAG_REVOKED;
  if (key->pointer->expired)
    key->flags |= G_GPG_KEY_FLAG_EXPIRED;
  if (key->pointer->disabled)
    key->flags |= G_GPG_KEY_FLAG_DISABLED;
  if (key->pointer->invalid)
    key->flags |= G_GPG_KEY_FLAG_INVALID;
  if (key->pointer->can_encrypt)
    key->flags |= G_GPG_KEY_FLAG_CAN_ENCRYPT;
  if (key->pointer->can_sign)
    key->flags |= G_GPG_KEY_FLAG_CAN_SIGN;
  if (key->pointer->can_certify)
    key->flags |= G_GPG_KEY_FLAG_CAN_CERTIFY;
  if (key->pointer->secret)
    key->flags |= G_GPG_KEY_FLAG_SECRET;
  if (key->pointer->can_authenticate)
    key->flags |= G_GPG_KEY_FLAG_CAN_AUTHENTICATE;
}

static void
g_gpg_key_class_init (GGpgKeyClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_key_set_property;
  object_class->get_property = g_gpg_key_get_property;
  object_class->finalize = g_gpg_key_finalize;
  object_class->constructed = g_gpg_key_constructed;

  key_pspecs[KEY_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);
  key_pspecs[KEY_PROP_FLAGS] =
    g_param_spec_flags ("flags", NULL, NULL,
                        G_GPG_TYPE_KEY_FLAGS, 0,
                        G_PARAM_READABLE);
  key_pspecs[KEY_PROP_PROTOCOL] =
    g_param_spec_enum ("protocol", NULL, NULL,
                       G_GPG_TYPE_PROTOCOL, G_GPG_PROTOCOL_OpenPGP,
                       G_PARAM_READABLE);
  key_pspecs[KEY_PROP_ISSUER_SERIAL] =
    g_param_spec_string ("issuer-serial", NULL, NULL, NULL, G_PARAM_READABLE);
  key_pspecs[KEY_PROP_ISSUER_NAME] =
    g_param_spec_string ("issuer-name", NULL, NULL, NULL, G_PARAM_READABLE);
  key_pspecs[KEY_PROP_CHAIN_ID] =
    g_param_spec_string ("chain-id", NULL, NULL, NULL, G_PARAM_READABLE);
  key_pspecs[KEY_PROP_OWNER_TRUST] =
    g_param_spec_enum ("owner-trust", NULL, NULL,
                       G_GPG_TYPE_VALIDITY, G_GPG_VALIDITY_UNKNOWN,
                       G_PARAM_READABLE);
  key_pspecs[KEY_PROP_KEYLIST_MODE] =
    g_param_spec_flags ("keylist-mode", NULL, NULL,
                        G_GPG_TYPE_KEYLIST_MODE, G_GPG_KEYLIST_MODE_LOCAL,
                        G_PARAM_READABLE);

  g_object_class_install_properties (object_class, KEY_LAST_PROP, key_pspecs);
}

static void
g_gpg_key_init (GGpgKey *key)
{
}

/**
 * g_gpg_key_get_subkeys:
 * @key: a #GGpgKey
 *
 * Returns: (transfer container) (element-type GGpgSubkey): a list of
 * #GGpgSubkey
 */
GList *
g_gpg_key_get_subkeys (GGpgKey *key)
{
  gpgme_subkey_t subkeys = key->pointer->subkeys;
  GList *result = NULL;

  for (; subkeys; subkeys = subkeys->next)
    {
      GGpgSubkey *subkey =
        g_object_new (G_GPG_TYPE_SUBKEY, "pointer", subkeys, NULL);
      result = g_list_append (result, subkey);
    }
  return result;
}

/**
 * g_gpg_key_get_uids:
 * @key: a #GGpgKey
 *
 * Returns: (transfer container) (element-type GGpgUserId): a list of
 * #GGpgUserId
 */
GList *
g_gpg_key_get_uids (GGpgKey *key)
{
  gpgme_user_id_t uids = key->pointer->uids;
  GList *result = NULL;

  for (; uids; uids = uids->next)
    {
      GGpgUserId *uid =
        g_object_new (G_GPG_TYPE_USER_ID, "pointer", uids, NULL);
      result = g_list_append (result, uid);
    }
  return result;
}

/**
 * g_gpg_ctx_keylist_start:
 * @ctx: a #GGpgCtx
 * @pattern: (nullable): a string
 * @secret_only: if non-zero, only list secret keys
 * @error: error location
 *
 */
gboolean
g_gpg_ctx_keylist_start (GGpgCtx *ctx, const gchar *pattern, gint secret_only,
                      GError **error)
{
  gpgme_error_t err;

  err = gpgme_op_keylist_start (ctx->pointer, pattern, secret_only);
  if (err)
    {
      g_set_error (error, G_GPG_ERROR, gpgme_err_code (err),
                   "%s", gpgme_strerror (err));
      return FALSE;
    }
  return TRUE;
}

/**
 * g_gpg_ctx_keylist_next:
 * @ctx: a #GGpgCtx
 * @error: error location
 *
 * Returns: (transfer full): a #GGpgKey
 */
GGpgKey *
g_gpg_ctx_keylist_next (GGpgCtx *ctx, GError **error)
{
  gpgme_key_t key;
  gpgme_error_t err;

  err = gpgme_op_keylist_next (ctx->pointer, &key);
  if (err)
    {
      if (gpgme_err_code (err) != GPG_ERR_EOF)
        g_set_error (error, G_GPG_ERROR, err, "%s", gpgme_strerror (err));
      return NULL;
    }

  return g_object_new (G_GPG_TYPE_KEY, "pointer", key, NULL);
}

gboolean
g_gpg_ctx_keylist_end (GGpgCtx *ctx, GError **error)
{
  gpgme_error_t err;

  err = gpgme_op_keylist_end (ctx->pointer);
  if (err)
    {
      g_set_error (error, G_GPG_ERROR, gpgme_err_code (err),
                   "%s", gpgme_strerror (err));
      return FALSE;
    }

  return TRUE;
}

struct GGpgSource;

struct GGpgSourceFd
{
  gint fd;
  GIOCondition events;
  gpointer tag;
  gpgme_io_cb_t fnc;
  void *fnc_data;
  struct GGpgSource *source;
};

typedef enum
  {
    G_GPG_SOURCE_STATE_NONE,
    G_GPG_SOURCE_STATE_START,
    G_GPG_SOURCE_STATE_DONE
  }
GGpgSourceState;

struct GGpgSource
{
  GSource base;
  GPtrArray *fds;
  GGpgSourceState state;
  gpgme_error_t err;
  GGpgCtx *ctx;
  GMutex lock;
};

static gboolean
g_gpg_source_prepare (GSource *_source, gint *timeout)
{
  struct GGpgSource *source = (struct GGpgSource *) _source;

  if (source->state == G_GPG_SOURCE_STATE_DONE)
    return TRUE;

  *timeout = -1;
  return FALSE;
}

static gboolean
g_gpg_source_check (GSource *_source)
{
  struct GGpgSource *source = (struct GGpgSource *) _source;
  gint index;

  if (source->state == G_GPG_SOURCE_STATE_DONE)
    return TRUE;

  for (index = 0; index < source->fds->len; index++)
    {
      struct GGpgSourceFd *fd = g_ptr_array_index (source->fds, index);
      if (fd->tag)
        {
          GIOCondition revents = g_source_query_unix_fd (_source, fd->tag);
          if (revents != 0)
            return TRUE;
        }
    }

  return FALSE;
}

static gboolean
g_gpg_source_dispatch (GSource *_source,
                       GSourceFunc callback,
                       gpointer user_data)
{
  struct GGpgSource *source = (struct GGpgSource *) _source;
  gint index;

  g_return_val_if_fail (callback, FALSE);

  for (index = 0; index < source->fds->len; index++)
    {
      struct GGpgSourceFd *fd = g_ptr_array_index (source->fds, index);
      if (fd->tag)
        {
          GIOCondition revents = g_source_query_unix_fd (_source, fd->tag);
          if (revents != 0)
            fd->fnc (fd->fnc_data, fd->fd);
        }
    }

  return callback (user_data);
}

static void
g_gpg_source_finalize (GSource *_source)
{
  struct GGpgSource *source = (struct GGpgSource *) _source;
  gint index;

  for (index = 0; index < source->fds->len; index++)
    {
      struct GGpgSourceFd *fd = g_ptr_array_index (source->fds, index);
      if (fd->tag)
        {
          g_source_remove_unix_fd (_source, fd->tag);
          fd->tag = NULL;
        }
    }
  g_ptr_array_free (source->fds, TRUE);
  g_mutex_clear (&source->lock);
  g_object_unref (source->ctx);
}

static GSourceFuncs g_gpg_source_funcs =
  {
    g_gpg_source_prepare,
    g_gpg_source_check,
    g_gpg_source_dispatch,
    g_gpg_source_finalize
  };

static gpgme_error_t
g_gpg_add_io_cb (void *data, int fd, int dir, gpgme_io_cb_t fnc, void *fnc_data,
                 void **r_tag)
{
  struct GGpgSource *source = data;
  struct GGpgSourceFd *to_add;

  to_add = g_new0 (struct GGpgSourceFd, 1);
  to_add->fd = fd;
  if (dir)
    to_add->events = G_IO_IN | G_IO_HUP | G_IO_ERR;
  else
    to_add->events = G_IO_OUT | G_IO_ERR;
  to_add->tag = NULL;
  to_add->fnc = fnc;
  to_add->fnc_data = fnc_data;
  to_add->source = source;

  g_mutex_lock (&source->lock);
  g_ptr_array_add (source->fds, to_add);
  if (source->state == G_GPG_SOURCE_STATE_START)
    to_add->tag = g_source_add_unix_fd ((GSource *) source, to_add->fd,
                                        to_add->events);
  g_mutex_unlock (&source->lock);
  *r_tag = to_add;

  return 0;
}

static void
g_gpg_remove_io_cb (void *tag)
{
  struct GGpgSourceFd *fd = tag;
  struct GGpgSource *source = fd->source;

  if (!fd->tag)
    return;

  g_mutex_lock (&source->lock);
  if (fd->tag)
    {
      g_source_remove_unix_fd ((GSource *) source, fd->tag);
      fd->tag = NULL;
    }
  fd->fd = -1;
  g_mutex_unlock (&source->lock);
}

static void
g_gpg_event_io_cb (void *data, gpgme_event_io_t type, void *type_data)
{
  struct GGpgSource *source = data;

  switch (type)
    {
    case GPGME_EVENT_START:
      source->state = G_GPG_SOURCE_STATE_START;
      {
        gint index;

        g_mutex_lock (&source->lock);
        for (index = 0; index < source->fds->len; index++)
          {
            struct GGpgSourceFd *fd = g_ptr_array_index (source->fds, index);
            fd->tag = g_source_add_unix_fd ((GSource *) source, fd->fd,
                                            fd->events);
          }
        g_mutex_unlock (&source->lock);
      }
      break;

    case GPGME_EVENT_DONE:
      source->state = G_GPG_SOURCE_STATE_DONE;
      source->err = *(gpgme_error_t *) type_data;
      {
        gint index;

        g_mutex_lock (&source->lock);
        for (index = 0; index < source->fds->len; index++)
          {
            struct GGpgSourceFd *fd = g_ptr_array_index (source->fds, index);
            if (fd->tag)
              {
                g_source_remove_unix_fd ((GSource *) source, fd->tag);
                fd->tag = NULL;
              }
          }
        g_mutex_unlock (&source->lock);
      }

    default:
      break;
    }
}

static GSource *
g_gpg_source_new (GGpgCtx *ctx, gsize size)
{
  struct GGpgSource *source;
  struct gpgme_io_cbs io_cbs;

  source = (struct GGpgSource *) g_source_new (&g_gpg_source_funcs, size);
  g_source_set_can_recurse ((GSource *) source, TRUE);
  source->fds = g_ptr_array_new_with_free_func (g_free);
  g_mutex_init (&source->lock);
  source->ctx = g_object_ref (ctx);

  io_cbs.add = g_gpg_add_io_cb;
  io_cbs.add_priv = source;
  io_cbs.remove = g_gpg_remove_io_cb;
  io_cbs.event = g_gpg_event_io_cb;
  io_cbs.event_priv = source;
  gpgme_set_io_cbs (ctx->pointer, &io_cbs);

  return (GSource *) source;
}

static gboolean
_g_gpg_source_func (gpointer user_data)
{
  GTask *task = user_data;
  struct GGpgSource *source = g_task_get_task_data (task);

  if (source->state == G_GPG_SOURCE_STATE_DONE)
    {
      if (source->err)
        g_task_return_new_error (task, G_GPG_ERROR,
                                 gpgme_err_code (source->err),
                                 "%s", gpgme_strerror (source->err));
      else
        g_task_return_boolean (task, TRUE);
      g_object_unref (task);
      return G_SOURCE_REMOVE;
    }
  return G_SOURCE_CONTINUE;
}

static void
_g_gpg_source_cancel (GCancellable *cancellable, struct GGpgSource *source)
{
  gpgme_cancel (source->ctx->pointer);
}

struct GGpgGetKeyData
{
  gchar *fpr;
  gint secret;
};

static void
g_gpg_get_key_data_free (struct GGpgGetKeyData *data)
{
  g_free (data->fpr);
  g_free (data);
}

static void
g_gpg_get_key_thread (GTask *task,
                gpointer source_object,
                gpointer task_data,
                GCancellable *cancellable)
{
  GGpgCtx *ctx = source_object;
  struct GGpgGetKeyData *data = task_data;
  GGpgKey *key;
  gpgme_key_t pointer;
  gpgme_error_t err;

  err = gpgme_get_key (ctx->pointer, data->fpr, &pointer, data->secret);
  if (err)
    g_task_return_new_error (task, G_GPG_ERROR, gpgme_err_code (err),
                             "%s", gpgme_strerror (err));
  else
    {
      key = g_object_new (G_GPG_TYPE_KEY, "pointer", pointer, NULL);
      g_task_return_pointer (task, key, g_object_unref);
    }
}

void
g_gpg_ctx_get_key (GGpgCtx *ctx, const gchar *fpr, gint secret,
                   GCancellable *cancellable,
                   GAsyncReadyCallback callback,
                   gpointer user_data)
{
  GTask *task;
  struct GGpgGetKeyData *data;

  task = g_task_new (ctx, cancellable, callback, user_data);
  data = g_new0 (struct GGpgGetKeyData, 1);
  data->fpr = g_strdup (fpr);
  data->secret = secret;
  g_task_set_task_data (task, data, (GDestroyNotify) g_gpg_get_key_data_free);
  g_task_run_in_thread (task, g_gpg_get_key_thread);
  g_object_unref (task);
}

/**
 * g_gpg_ctx_get_key_finish:
 * @ctx: a #GGpgCtx
 * @result: a #GAsyncResult
 * @error: error location
 *
 * Returns: (transfer full): a new #GGpgKey
 */
GGpgKey *
g_gpg_ctx_get_key_finish (GGpgCtx *ctx, GAsyncResult *result, GError **error)
{
  g_return_val_if_fail (g_task_is_valid (result, ctx), FALSE);
  return g_task_propagate_pointer (G_TASK (result), error);
}

#define G_GPG_SOURCE_NEW(t,c) ((t *) g_gpg_source_new (c, sizeof (t)))

struct GGpgGenkeySource
{
  struct GGpgSource source;
  gchar *parms;
  GGpgData *pubkey;
  GGpgData *seckey;
};

static void
g_gpg_genkey_source_finalize (GSource *_source)
{
  struct GGpgGenkeySource *source = (struct GGpgGenkeySource *) _source;
  g_free (source->parms);
  g_clear_object (&source->pubkey);
  g_clear_object (&source->seckey);
}

static void
_g_gpg_ctx_genkey_begin (GGpgCtx *ctx,
                         struct GGpgGenkeySource *source,
                         GTask *task,
                         GCancellable *cancellable)
{
  gpgme_error_t err;

  err = gpgme_op_genkey_start (ctx->pointer, source->parms,
                               source->pubkey ? source->pubkey->pointer : NULL,
                               source->seckey ? source->seckey->pointer : NULL);
  if (err)
    {
      g_task_return_new_error (task, G_GPG_ERROR, gpgme_err_code (err),
                               "%s", gpgme_strerror (err));
      return;
    }

  if (cancellable)
    g_cancellable_connect (cancellable, G_CALLBACK (_g_gpg_source_cancel),
                           source, NULL);

  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

/**
 * g_gpg_ctx_genkey:
 * @ctx: a #GGpgCtx
 * @parms: parameters
 * @pubkey: (nullable): data holding generated public key
 * @seckey: (nullable): data holding generated secret key
 * @cancellable: (nullable): a #GCancellable
 * @callback: a #GAsyncReadyCallback
 * @user_data: a user data
 *
 */
void
g_gpg_ctx_genkey (GGpgCtx *ctx, const gchar *parms,
                  GGpgData *pubkey, GGpgData *seckey,
                  GCancellable *cancellable,
                  GAsyncReadyCallback callback,
                  gpointer user_data)
{
  GTask *task;
  struct GGpgGenkeySource *source;

  task = g_task_new (ctx, cancellable, callback, user_data);
  source = G_GPG_SOURCE_NEW (struct GGpgGenkeySource, ctx);
  source->parms = g_strdup (parms);
  source->pubkey = pubkey ? g_object_ref (pubkey) : NULL;
  source->seckey = seckey ? g_object_ref (seckey) : NULL;
  g_task_set_task_data (task, source,
                        (GDestroyNotify) g_gpg_genkey_source_finalize);
  _g_gpg_ctx_genkey_begin (ctx, source, task, cancellable);
}

gboolean
g_gpg_ctx_genkey_finish (GGpgCtx *ctx, GAsyncResult *result, GError **error)
{
  g_return_val_if_fail (g_task_is_valid (result, ctx), FALSE);
  return g_task_propagate_boolean (G_TASK (result), error);
}

struct GGpgDeleteSource
{
  struct GGpgSource source;
  GGpgKey *key;
  gint allow_secret;
};

static void
g_gpg_delete_source_finalize (GSource *_source)
{
  struct GGpgDeleteSource *source = (struct GGpgDeleteSource *) _source;
  g_object_unref (source->key);
}

static void
_g_gpg_ctx_delete_begin (GGpgCtx *ctx,
                         struct GGpgDeleteSource *source,
                         GTask *task,
                         GCancellable *cancellable)
{
  gpgme_error_t err;

  err = gpgme_op_delete_start (ctx->pointer, source->key->pointer,
                               source->allow_secret);
  if (err)
    {
      g_task_return_new_error (task, G_GPG_ERROR, gpgme_err_code (err),
                               "%s", gpgme_strerror (err));
      return;
    }

  if (cancellable)
    g_cancellable_connect (cancellable, G_CALLBACK (_g_gpg_source_cancel),
                           source, NULL);

  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

void
g_gpg_ctx_delete (GGpgCtx *ctx, GGpgKey *key,
                  gint allow_secret,
                  GCancellable *cancellable,
                  GAsyncReadyCallback callback,
                  gpointer user_data)
{
  GTask *task;
  struct GGpgDeleteSource *source;

  task = g_task_new (ctx, cancellable, callback, user_data);
  source = G_GPG_SOURCE_NEW (struct GGpgDeleteSource, ctx);
  source->key = g_object_ref (key);
  source->allow_secret = allow_secret;
  g_task_set_task_data (task, source,
                        (GDestroyNotify) g_gpg_delete_source_finalize);
  _g_gpg_ctx_delete_begin (ctx, source, task, cancellable);
}

gboolean
g_gpg_ctx_delete_finish (GGpgCtx *ctx, GAsyncResult *result, GError **error)
{
  g_return_val_if_fail (g_task_is_valid (result, ctx), FALSE);
  return g_task_propagate_boolean (G_TASK (result), error);
}

struct GGpgEditSource
{
  struct GGpgSource source;
  GGpgKey *key;
  GGpgEditCallback callback;
  gpointer user_data;
  GGpgData *out;
};

static void
g_gpg_edit_source_finalize (GSource *_source)
{
  struct GGpgEditSource *source = (struct GGpgEditSource *) _source;
  g_object_unref (source->key);
  g_object_unref (source->out);
}

static gpgme_error_t
_g_gpg_edit_cb (void *opaque,
                gpgme_status_code_t status,
                const char *args, int fd)
{
  struct GGpgEditSource *source = opaque;
  GError *error = NULL;

  if (!source->callback (source->user_data, status, args, fd, &error))
    {
      gpgme_err_code_t code = error->code;

      g_error_free (error);
      return gpgme_err_make (GPG_ERR_SOURCE_UNKNOWN, code);
    }
  return 0;
}

static void
_g_gpg_ctx_edit_begin (GGpgCtx *ctx,
                       struct GGpgEditSource *source,
                       GTask *task,
                       GCancellable *cancellable)
{
  gpgme_error_t err;

  err = gpgme_op_edit_start (ctx->pointer, source->key->pointer, _g_gpg_edit_cb,
                             source, source->out->pointer);
  if (err)
    {
      g_task_return_new_error (task, G_GPG_ERROR, gpgme_err_code (err),
                               "%s", gpgme_strerror (err));
      return;
    }

  if (cancellable)
    g_cancellable_connect (cancellable, G_CALLBACK (_g_gpg_source_cancel),
                           source, NULL);

  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

/**
 * g_gpg_ctx_edit:
 * @ctx: a #GGpgCtx
 * @key: a #GGpgKey
 * @edit_callback: (scope async): a #GGpgEditCallback
 * @edit_user_data: a data for @edit_callback
 * @out: a #GGpgData
 * @cancellable: a #GCancellable
 * @callback: a callback
 * @user_data: a data for @callback
 *
 */
void
g_gpg_ctx_edit (GGpgCtx *ctx,
                GGpgKey *key,
                GGpgEditCallback edit_callback,
                gpointer edit_user_data,
                GGpgData *out,
                GCancellable *cancellable,
                GAsyncReadyCallback callback,
                gpointer user_data)
{
  GTask *task;
  struct GGpgEditSource *source;

  task = g_task_new (ctx, cancellable, callback, user_data);
  source = G_GPG_SOURCE_NEW (struct GGpgEditSource, ctx);
  source->key = g_object_ref (key);
  source->callback = edit_callback;
  source->user_data = edit_user_data;
  source->out = g_object_ref (out);
  g_task_set_task_data (task, source,
                        (GDestroyNotify) g_gpg_edit_source_finalize);
  _g_gpg_ctx_edit_begin (ctx, source, task, cancellable);
}

gboolean
g_gpg_ctx_edit_finish (GGpgCtx *ctx, GAsyncResult *result, GError **error)
{
  g_return_val_if_fail (g_task_is_valid (result, ctx), FALSE);
  return g_task_propagate_boolean (G_TASK (result), error);
}

struct GGpgExportSource
{
  struct GGpgSource source;
  GGpgKey *key;
  GGpgExportMode mode;
  GGpgData *keydata;
};

static void
g_gpg_export_source_finalize (GSource *_source)
{
  struct GGpgExportSource *source = (struct GGpgExportSource *) _source;
  g_free (source->key);
  g_object_unref (source->keydata);
}

static void
_g_gpg_ctx_export_begin (GGpgCtx *ctx,
                         struct GGpgExportSource *source,
                         GTask *task,
                         GCancellable *cancellable)
{
  gpgme_key_t keys[2] = { NULL, NULL };
  gpgme_error_t err;

  keys[0] = source->key->pointer;
  err = gpgme_op_export_keys_start (ctx->pointer, keys, source->mode,
                                    source->keydata->pointer);
  if (err)
    {
      g_task_return_new_error (task, G_GPG_ERROR, gpgme_err_code (err),
                               "%s", gpgme_strerror (err));
      return;
    }

  if (cancellable)
    g_cancellable_connect (cancellable, G_CALLBACK (_g_gpg_source_cancel),
                           source, NULL);

  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

void
g_gpg_ctx_export (GGpgCtx *ctx,
                  GGpgKey *key,
                  GGpgExportMode mode,
                  GGpgData *keydata,
                  GCancellable *cancellable,
                  GAsyncReadyCallback callback,
                  gpointer user_data)
{
  GTask *task;
  struct GGpgExportSource *source;

  task = g_task_new (ctx, cancellable, callback, user_data);
  source = G_GPG_SOURCE_NEW (struct GGpgExportSource, ctx);
  source->key = g_object_ref (key);
  source->mode = mode;
  source->keydata = g_object_ref (keydata);
  g_task_set_task_data (task, source,
                        (GDestroyNotify) g_gpg_export_source_finalize);
  _g_gpg_ctx_export_begin (ctx, source, task, cancellable);
}

gboolean
g_gpg_ctx_export_finish (GGpgCtx *ctx, GAsyncResult *result, GError **error)
{
  g_return_val_if_fail (g_task_is_valid (result, ctx), FALSE);
  return g_task_propagate_boolean (G_TASK (result), error);
}
