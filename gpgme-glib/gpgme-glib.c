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
  GDestroyNotify progress_destroy;
  GPtrArray *signers;
  GMutex lock;
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

  if (ctx->progress_destroy)
    ctx->progress_destroy (ctx->progress_user_data);

  g_mutex_clear (&ctx->lock);

  g_ptr_array_unref (ctx->signers);

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
  g_mutex_init (&ctx->lock);
  ctx->signers = g_ptr_array_new_with_free_func (g_object_unref);
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
  if (ctx->progress_destroy)
    ctx->progress_destroy (ctx->progress_user_data);

  ctx->progress_user_data = user_data;
  ctx->progress_destroy = destroy_data;

  gpgme_set_progress_cb (ctx->pointer, (gpgme_progress_cb_t) callback,
                         user_data);
}

struct _GGpgSubkey
{
  GObject parent;
  gpgme_subkey_t pointer;
  GGpgKey *owner;
  GGpgSubkeyFlags flags;
};

G_DEFINE_TYPE (GGpgSubkey, g_gpg_subkey, G_TYPE_OBJECT)

enum {
  SUBKEY_PROP_0,
  SUBKEY_PROP_POINTER,
  SUBKEY_PROP_OWNER,
  SUBKEY_PROP_FLAGS,
  SUBKEY_PROP_PUBKEY_ALGO,
  SUBKEY_PROP_LENGTH,
  SUBKEY_PROP_FINGERPRINT,
  SUBKEY_PROP_CREATED,
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

    case SUBKEY_PROP_OWNER:
      subkey->owner = g_value_dup_object (value);
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

    case SUBKEY_PROP_CREATED:
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
g_gpg_subkey_dispose (GObject *object)
{
  GGpgSubkey *subkey = G_GPG_SUBKEY (object);

  g_clear_object (&subkey->owner);

  G_OBJECT_CLASS (g_gpg_subkey_parent_class)->dispose (object);
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
  object_class->dispose = g_gpg_subkey_dispose;
  object_class->constructed = g_gpg_subkey_constructed;

  subkey_pspecs[SUBKEY_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);
  subkey_pspecs[SUBKEY_PROP_OWNER] =
    g_param_spec_object ("owner", NULL, NULL,
                         G_GPG_TYPE_KEY,
                         G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);
  subkey_pspecs[SUBKEY_PROP_FLAGS] =
    g_param_spec_flags ("flags", NULL, NULL,
                        G_GPG_TYPE_SUBKEY_FLAGS, 0,
                        G_PARAM_READABLE);
  subkey_pspecs[SUBKEY_PROP_PUBKEY_ALGO] =
    g_param_spec_enum ("pubkey-algo", NULL, NULL,
                       G_GPG_TYPE_PUBKEY_ALGO, G_GPG_PK_NONE,
                       G_PARAM_READABLE);
  subkey_pspecs[SUBKEY_PROP_LENGTH] =
    g_param_spec_uint ("length", NULL, NULL,
                       0, G_MAXUINT, 0,
                       G_PARAM_READABLE);
  subkey_pspecs[SUBKEY_PROP_FINGERPRINT] =
    g_param_spec_string ("fingerprint", NULL, NULL,
                         NULL,
                         G_PARAM_READABLE);
  subkey_pspecs[SUBKEY_PROP_CREATED] =
    g_param_spec_int64 ("created", NULL, NULL,
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
  GGpgUserId *owner;
  GGpgKeySigFlags flags;
};

G_DEFINE_TYPE (GGpgKeySig, g_gpg_key_sig, G_TYPE_OBJECT)

enum {
  KEY_SIG_PROP_0,
  KEY_SIG_PROP_POINTER,
  KEY_SIG_PROP_OWNER,
  KEY_SIG_PROP_FLAGS,
  KEY_SIG_PROP_PUBKEY_ALGO,
  KEY_SIG_PROP_KEY_ID,
  KEY_SIG_PROP_CREATED,
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

    case KEY_SIG_PROP_OWNER:
      key_sig->owner = g_value_dup_object (value);
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

    case KEY_SIG_PROP_KEY_ID:
      g_value_set_string (value, key_sig->pointer->keyid);
      break;

    case KEY_SIG_PROP_CREATED:
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
g_gpg_key_sig_dispose (GObject *object)
{
  GGpgKeySig *key_sig = G_GPG_KEY_SIG (object);

  g_clear_object (&key_sig->owner);

  G_OBJECT_CLASS (g_gpg_key_sig_parent_class)->dispose (object);
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
  object_class->dispose = g_gpg_key_sig_dispose;
  object_class->constructed = g_gpg_key_sig_constructed;

  key_sig_pspecs[KEY_SIG_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);
  key_sig_pspecs[KEY_SIG_PROP_OWNER] =
    g_param_spec_object ("owner", NULL, NULL,
                         G_GPG_TYPE_USER_ID,
                         G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);
  key_sig_pspecs[KEY_SIG_PROP_FLAGS] =
    g_param_spec_flags ("flags", NULL, NULL,
                        G_GPG_TYPE_KEY_SIG_FLAGS, 0,
                        G_PARAM_READABLE);
  key_sig_pspecs[KEY_SIG_PROP_PUBKEY_ALGO] =
    g_param_spec_enum ("pubkey-algo", NULL, NULL,
                       G_GPG_TYPE_PUBKEY_ALGO, G_GPG_PK_NONE,
                       G_PARAM_READABLE);
  key_sig_pspecs[KEY_SIG_PROP_KEY_ID] =
    g_param_spec_string ("key-id", NULL, NULL, "", G_PARAM_READABLE);
  key_sig_pspecs[KEY_SIG_PROP_CREATED] =
    g_param_spec_int64 ("created", NULL, NULL,
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
  GGpgKey *owner;
  GGpgUserIdFlags flags;
};

G_DEFINE_TYPE (GGpgUserId, g_gpg_user_id, G_TYPE_OBJECT);

enum {
  USER_ID_PROP_0,
  USER_ID_PROP_POINTER,
  USER_ID_PROP_OWNER,
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

    case USER_ID_PROP_OWNER:
      user_id->owner = g_value_dup_object (value);
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
g_gpg_user_id_dispose (GObject *object)
{
  GGpgUserId *user_id = G_GPG_USER_ID (object);

  g_clear_object (&user_id->owner);

  G_OBJECT_CLASS (g_gpg_user_id_parent_class)->dispose (object);
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
  object_class->dispose = g_gpg_user_id_dispose;
  object_class->constructed = g_gpg_user_id_constructed;

  user_id_pspecs[USER_ID_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);
  user_id_pspecs[USER_ID_PROP_OWNER] =
    g_param_spec_object ("owner", NULL, NULL,
                         G_GPG_TYPE_KEY,
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
 * Returns: (transfer full) (element-type GGpgKeySig): a list of #GGpgKeySig
 */
GList *
g_gpg_user_id_get_signatures (GGpgUserId *user_id)
{
  gpgme_key_sig_t signatures = user_id->pointer->signatures;
  GList *result = NULL;

  for (; signatures; signatures = signatures->next)
    {
      GGpgKeySig *signature =
        g_object_new (G_GPG_TYPE_KEY_SIG, "pointer", signatures,
                      "owner", user_id, NULL);
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
 * Returns: (transfer full) (element-type GGpgSubkey): a list of
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
        g_object_new (G_GPG_TYPE_SUBKEY, "pointer", subkeys, "owner", key,
                      NULL);
      result = g_list_append (result, subkey);
    }
  return result;
}

/**
 * g_gpg_key_get_uids:
 * @key: a #GGpgKey
 *
 * Returns: (transfer full) (element-type GGpgUserId): a list of
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
        g_object_new (G_GPG_TYPE_USER_ID, "pointer", uids, "owner", key, NULL);
      result = g_list_append (result, uid);
    }
  return result;
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
  GCancellable *cancellable;
  gulong cancellable_id;
  GGpgKeylistCallback keylist_callback;
  gpointer keylist_user_data;
  GDestroyNotify keylist_destroy;
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

  if (source->cancellable_id > 0)
    g_cancellable_disconnect (source->cancellable, source->cancellable_id);

  g_ptr_array_free (source->fds, TRUE);
  g_mutex_clear (&source->lock);
  g_object_unref (source->ctx);

  if (source->keylist_destroy)
    source->keylist_destroy (source->keylist_user_data);
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
      break;

    case GPGME_EVENT_NEXT_KEY:
      if (source->keylist_callback)
        {
          gpgme_key_t pointer = type_data;
          GGpgKey *key;

          gpgme_key_ref (pointer);
          key = g_object_new (G_GPG_TYPE_KEY, "pointer", pointer, NULL);
          source->keylist_callback (source->keylist_user_data, key);
        }
      break;

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

#define G_GPG_SOURCE_NEW(t,c) ((t *) g_gpg_source_new (c, sizeof (t)))

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

static void
g_gpg_source_connect_cancellable (struct GGpgSource *source,
                                  GCancellable *cancellable)
{
  if (cancellable)
    {
      source->cancellable = cancellable;
      source->cancellable_id =
        g_cancellable_connect (cancellable, G_CALLBACK (_g_gpg_source_cancel),
                               source, NULL);
    }
}

struct GGpgKeylistSource
{
  struct GGpgSource source;
  gchar *pattern;
  gboolean secret_only;
};

static void
g_gpg_keylist_source_finalize (GSource *_source)
{
  struct GGpgKeylistSource *source = (struct GGpgKeylistSource *) _source;
  g_free (source->pattern);
}

static void
_g_gpg_ctx_keylist_begin (GGpgCtx *ctx,
                          struct GGpgKeylistSource *source,
                          GTask *task,
                          GCancellable *cancellable)
{
  gpgme_error_t err;

  err = gpgme_op_keylist_start (ctx->pointer, source->pattern,
                                source->secret_only);
  if (err)
    {
      g_task_return_new_error (task, G_GPG_ERROR, gpgme_err_code (err),
                               "%s", gpgme_strerror (err));
      return;
    }

  g_gpg_source_connect_cancellable ((struct GGpgSource *) source, cancellable);
  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

/**
 * g_gpg_ctx_keylist:
 * @ctx: a #GGpgCtx
 * @pattern: (nullable): a string
 * @secret_only: if %TRUE, only list secret keys
 * @keylist_callback: (scope notified) (destroy keylist_destroy) (closure keylist_user_data): a #GGpgKeylistCallback
 * @keylist_user_data: a data for @keylist_callback
 * @keylist_destroy: a #GDestroyNotify
 * @cancellable: (nullable): a #GCancellable
 * @callback: a #GAsyncReadyCallback
 * @user_data: a user data
 *
 */
void
g_gpg_ctx_keylist (GGpgCtx *ctx, const gchar *pattern, gboolean secret_only,
                   GGpgKeylistCallback keylist_callback,
                   gpointer keylist_user_data,
                   GDestroyNotify keylist_destroy,
                   GCancellable *cancellable,
                   GAsyncReadyCallback callback,
                   gpointer user_data)
{
  GTask *task;
  struct GGpgKeylistSource *source;

  task = g_task_new (ctx, cancellable, callback, user_data);
  source = G_GPG_SOURCE_NEW (struct GGpgKeylistSource, ctx);
  source->source.keylist_callback = keylist_callback;
  source->source.keylist_user_data = keylist_user_data;
  source->source.keylist_destroy = keylist_destroy;
  source->pattern = g_strdup (pattern);
  source->secret_only = secret_only;
  g_task_set_task_data (task, source,
                        (GDestroyNotify) g_gpg_keylist_source_finalize);
  _g_gpg_ctx_keylist_begin (ctx, source, task, cancellable);
}

gboolean
g_gpg_ctx_keylist_finish (GGpgCtx *ctx, GAsyncResult *result,
                          GError **error)
{
  g_return_val_if_fail (g_task_is_valid (result, ctx), FALSE);
  return g_task_propagate_boolean (G_TASK (result), error);
}

struct GGpgGetKeyData
{
  gchar *fpr;
  GGpgGetKeyFlags flags;
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

  err = gpgme_get_key (ctx->pointer, data->fpr, &pointer, data->flags);
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
g_gpg_ctx_get_key (GGpgCtx *ctx, const gchar *fpr, GGpgGetKeyFlags flags,
                   GCancellable *cancellable,
                   GAsyncReadyCallback callback,
                   gpointer user_data)
{
  GTask *task;
  struct GGpgGetKeyData *data;

  task = g_task_new (ctx, cancellable, callback, user_data);
  data = g_new0 (struct GGpgGetKeyData, 1);
  data->fpr = g_strdup (fpr);
  data->flags = flags;
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

struct GGpgGenerateKeySource
{
  struct GGpgSource source;
  gchar *parms;
  GGpgData *pubkey;
  GGpgData *seckey;
};

static void
g_gpg_generate_key_source_finalize (GSource *_source)
{
  struct GGpgGenerateKeySource *source =
    (struct GGpgGenerateKeySource *) _source;
  g_free (source->parms);
  g_clear_object (&source->pubkey);
  g_clear_object (&source->seckey);
}

static void
_g_gpg_ctx_generate_key_begin (GGpgCtx *ctx,
                               struct GGpgGenerateKeySource *source,
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

  g_gpg_source_connect_cancellable ((struct GGpgSource *) source, cancellable);
  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

/**
 * g_gpg_ctx_generate_key:
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
g_gpg_ctx_generate_key (GGpgCtx *ctx, const gchar *parms,
                        GGpgData *pubkey, GGpgData *seckey,
                        GCancellable *cancellable,
                        GAsyncReadyCallback callback,
                        gpointer user_data)
{
  GTask *task;
  struct GGpgGenerateKeySource *source;

  task = g_task_new (ctx, cancellable, callback, user_data);
  source = G_GPG_SOURCE_NEW (struct GGpgGenerateKeySource, ctx);
  source->parms = g_strdup (parms);
  source->pubkey = pubkey ? g_object_ref (pubkey) : NULL;
  source->seckey = seckey ? g_object_ref (seckey) : NULL;
  g_task_set_task_data (task, source,
                        (GDestroyNotify) g_gpg_generate_key_source_finalize);
  _g_gpg_ctx_generate_key_begin (ctx, source, task, cancellable);
}

gboolean
g_gpg_ctx_generate_key_finish (GGpgCtx *ctx, GAsyncResult *result,
                               GError **error)
{
  g_return_val_if_fail (g_task_is_valid (result, ctx), FALSE);
  return g_task_propagate_boolean (G_TASK (result), error);
}

struct GGpgDeleteSource
{
  struct GGpgSource source;
  GGpgKey *key;
  GGpgDeleteFlags flags;
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
                               source->flags);
  if (err)
    {
      g_task_return_new_error (task, G_GPG_ERROR, gpgme_err_code (err),
                               "%s", gpgme_strerror (err));
      return;
    }

  g_gpg_source_connect_cancellable ((struct GGpgSource *) source, cancellable);
  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

void
g_gpg_ctx_delete (GGpgCtx *ctx, GGpgKey *key, GGpgDeleteFlags flags,
                  GCancellable *cancellable,
                  GAsyncReadyCallback callback,
                  gpointer user_data)
{
  GTask *task;
  struct GGpgDeleteSource *source;

  task = g_task_new (ctx, cancellable, callback, user_data);
  source = G_GPG_SOURCE_NEW (struct GGpgDeleteSource, ctx);
  source->key = g_object_ref (key);
  source->flags = flags;
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

struct GGpgChangePasswordSource
{
  struct GGpgSource source;
  GGpgKey *key;
  GGpgChangePasswordFlags flags;
};

static void
g_gpg_change_password_source_finalize (GSource *_source)
{
  struct GGpgChangePasswordSource *source =
    (struct GGpgChangePasswordSource *) _source;
  g_object_unref (source->key);
}

static void
_g_gpg_ctx_change_password_begin (GGpgCtx *ctx,
                                  struct GGpgChangePasswordSource *source,
                                  GTask *task,
                                  GCancellable *cancellable)
{
  gpgme_error_t err;

  err = gpgme_op_passwd_start (ctx->pointer, source->key->pointer,
                               source->flags);
  if (err)
    {
      g_task_return_new_error (task, G_GPG_ERROR, gpgme_err_code (err),
                               "%s", gpgme_strerror (err));
      return;
    }

  g_gpg_source_connect_cancellable ((struct GGpgSource *) source, cancellable);
  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

void
g_gpg_ctx_change_password (GGpgCtx *ctx, GGpgKey *key,
                           GGpgChangePasswordFlags flags,
                           GCancellable *cancellable,
                           GAsyncReadyCallback callback,
                           gpointer user_data)
{
  GTask *task;
  struct GGpgChangePasswordSource *source;

  task = g_task_new (ctx, cancellable, callback, user_data);
  source = G_GPG_SOURCE_NEW (struct GGpgChangePasswordSource, ctx);
  source->key = g_object_ref (key);
  source->flags = flags;
  g_task_set_task_data (task, source,
                        (GDestroyNotify) g_gpg_change_password_source_finalize);
  _g_gpg_ctx_change_password_begin (ctx, source, task, cancellable);
}

gboolean
g_gpg_ctx_change_password_finish (GGpgCtx *ctx, GAsyncResult *result,
                                  GError **error)
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
  GDestroyNotify destroy;
  GGpgData *out;
};

static void
g_gpg_edit_source_finalize (GSource *_source)
{
  struct GGpgEditSource *source = (struct GGpgEditSource *) _source;
  g_object_unref (source->key);
  g_object_unref (source->out);
  if (source->destroy)
    source->destroy (source->user_data);
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

  g_gpg_source_connect_cancellable ((struct GGpgSource *) source, cancellable);
  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

/**
 * g_gpg_ctx_edit:
 * @ctx: a #GGpgCtx
 * @key: a #GGpgKey
 * @edit_callback: (scope notified) (destroy edit_destroy) (closure edit_user_data): a #GGpgEditCallback
 * @edit_user_data: a data for @edit_callback
 * @edit_destroy: a #GDestroyNotify
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
                GDestroyNotify edit_destroy,
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
  source->destroy = edit_destroy;
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

  g_gpg_source_connect_cancellable ((struct GGpgSource *) source, cancellable);
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

struct GGpgImportSource
{
  struct GGpgSource source;
  GGpgData *keydata;
};

static void
g_gpg_import_source_finalize (GSource *_source)
{
  struct GGpgImportSource *source = (struct GGpgImportSource *) _source;
  g_object_unref (source->keydata);
}

static void
_g_gpg_ctx_import_begin (GGpgCtx *ctx,
                         struct GGpgImportSource *source,
                         GTask *task,
                         GCancellable *cancellable)
{
  gpgme_error_t err;

  err = gpgme_op_import_start (ctx->pointer, source->keydata->pointer);
  if (err)
    {
      g_task_return_new_error (task, G_GPG_ERROR, gpgme_err_code (err),
                               "%s", gpgme_strerror (err));
      return;
    }

  g_gpg_source_connect_cancellable ((struct GGpgSource *) source, cancellable);
  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

void
g_gpg_ctx_import (GGpgCtx *ctx,
                  GGpgData *keydata,
                  GCancellable *cancellable,
                  GAsyncReadyCallback callback,
                  gpointer user_data)
{
  GTask *task;
  struct GGpgImportSource *source;

  task = g_task_new (ctx, cancellable, callback, user_data);
  source = G_GPG_SOURCE_NEW (struct GGpgImportSource, ctx);
  source->keydata = g_object_ref (keydata);
  g_task_set_task_data (task, source,
                        (GDestroyNotify) g_gpg_import_source_finalize);
  _g_gpg_ctx_import_begin (ctx, source, task, cancellable);
}

gboolean
g_gpg_ctx_import_finish (GGpgCtx *ctx, GAsyncResult *result, GError **error)
{
  g_return_val_if_fail (g_task_is_valid (result, ctx), FALSE);
  return g_task_propagate_boolean (G_TASK (result), error);
}

struct GGpgImportKeysSource
{
  struct GGpgSource source;
  GGpgKey **keys;
};

static void
g_gpg_import_keys_source_finalize (GSource *_source)
{
  struct GGpgImportKeysSource *source = (struct GGpgImportKeysSource *) _source;
  GGpgKey **keys;
  for (keys = source->keys; *keys; keys++)
    g_object_unref (*keys);
  g_free (source->keys);
}

static void
_g_gpg_ctx_import_keys_begin (GGpgCtx *ctx,
                              struct GGpgImportKeysSource *source,
                              GTask *task,
                              GCancellable *cancellable)
{
  gpgme_error_t err;
  gpgme_key_t *keys;
  gsize i;

  for (i = 0; source->keys[i]; i++)
    ;

  keys = g_new0 (gpgme_key_t, i + 1);
  for (i = 0; source->keys[i]; i++)
    keys[i] = source->keys[i]->pointer;
  
  err = gpgme_op_import_keys_start (ctx->pointer, keys);
  g_free (keys);
  if (err)
    {
      g_task_return_new_error (task, G_GPG_ERROR, gpgme_err_code (err),
                               "%s", gpgme_strerror (err));
      return;
    }

  g_gpg_source_connect_cancellable ((struct GGpgSource *) source, cancellable);
  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

/**
 * g_gpg_ctx_import_keys:
 * @ctx: a #GGpgCtx
 * @keys: (array zero-terminated=1) (element-type GGpgKey): list of keys
 * @cancellable: (nullable): a #GCancellable
 * @callback: a callback
 * @user_data: a user data
 *
 */
void
g_gpg_ctx_import_keys (GGpgCtx *ctx,
                       GGpgKey **keys,
                       GCancellable *cancellable,
                       GAsyncReadyCallback callback,
                       gpointer user_data)
{
  GTask *task;
  struct GGpgImportKeysSource *source;
  gsize i;

  task = g_task_new (ctx, cancellable, callback, user_data);
  source = G_GPG_SOURCE_NEW (struct GGpgImportKeysSource, ctx);

  for (i = 0; keys[i]; i++)
    ;
  source->keys = g_new0 (GGpgKey *, i + 1);
  for (i = 0; keys[i]; i++)
    source->keys[i] = g_object_ref (keys[i]);

  g_task_set_task_data (task, source,
                        (GDestroyNotify) g_gpg_import_keys_source_finalize);
  _g_gpg_ctx_import_keys_begin (ctx, source, task, cancellable);
}

gboolean
g_gpg_ctx_import_keys_finish (GGpgCtx *ctx, GAsyncResult *result,
                              GError **error)
{
  g_return_val_if_fail (g_task_is_valid (result, ctx), FALSE);
  return g_task_propagate_boolean (G_TASK (result), error);
}

struct _GGpgRecipient
{
  GObject parent;
  gpgme_recipient_t pointer;
  GGpgDecryptResult *owner;
};

G_DEFINE_TYPE (GGpgRecipient, g_gpg_recipient, G_TYPE_OBJECT)

enum {
  RECIPIENT_PROP_0,
  RECIPIENT_PROP_POINTER,
  RECIPIENT_PROP_OWNER,
  RECIPIENT_LAST_PROP
};

static GParamSpec *recipient_pspecs[RECIPIENT_LAST_PROP] = { NULL, };

static void
g_gpg_recipient_set_property (GObject *object,
                              guint property_id,
                              const GValue *value,
                              GParamSpec *pspec)
{
  GGpgRecipient *recipient = G_GPG_RECIPIENT (object);

  switch (property_id)
    {
    case RECIPIENT_PROP_POINTER:
      recipient->pointer = g_value_get_pointer (value);
      break;

    case RECIPIENT_PROP_OWNER:
      recipient->owner = g_value_dup_object (value);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_recipient_dispose (GObject *object)
{
  GGpgRecipient *recipient = G_GPG_RECIPIENT (object);

  g_clear_object (&recipient->owner);

  G_OBJECT_CLASS (g_gpg_recipient_parent_class)->dispose (object);
}

static void
g_gpg_recipient_class_init (GGpgRecipientClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_recipient_set_property;
  object_class->dispose = g_gpg_recipient_dispose;

  recipient_pspecs[RECIPIENT_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);

  recipient_pspecs[RECIPIENT_PROP_OWNER] =
    g_param_spec_object ("owner", NULL, NULL,
                         G_GPG_TYPE_DECRYPT_RESULT,
                         G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);

  g_object_class_install_properties (object_class, RECIPIENT_LAST_PROP,
                                     recipient_pspecs);
}

static void
g_gpg_recipient_init (GGpgRecipient *recipient)
{
}

struct _GGpgDecryptResult
{
  GObject parent;
  gpgme_decrypt_result_t pointer;
};

G_DEFINE_TYPE (GGpgDecryptResult, g_gpg_decrypt_result, G_TYPE_OBJECT)

enum {
  DECRYPT_RESULT_PROP_0,
  DECRYPT_RESULT_PROP_POINTER,
  DECRYPT_RESULT_PROP_FILENAME,
  DECRYPT_RESULT_LAST_PROP
};

static GParamSpec *decrypt_result_pspecs[DECRYPT_RESULT_LAST_PROP] = { NULL, };

static void
g_gpg_decrypt_result_set_property (GObject *object,
                                   guint property_id,
                                   const GValue *value,
                                   GParamSpec *pspec)
{
  GGpgDecryptResult *decrypt_result = G_GPG_DECRYPT_RESULT (object);

  switch (property_id)
    {
    case DECRYPT_RESULT_PROP_POINTER:
      {
        gpgme_decrypt_result_t pointer = g_value_get_pointer (value);
        gpgme_result_ref (pointer);
        decrypt_result->pointer = pointer;
      }
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_decrypt_result_get_property (GObject *object,
                                   guint property_id,
                                   GValue *value,
                                   GParamSpec *pspec)
{
  GGpgDecryptResult *decrypt_result = G_GPG_DECRYPT_RESULT (object);

  switch (property_id)
    {
    case DECRYPT_RESULT_PROP_FILENAME:
      g_value_set_string (value, decrypt_result->pointer->file_name);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_decrypt_result_finalize (GObject *object)
{
  GGpgDecryptResult *decrypt_result = G_GPG_DECRYPT_RESULT (object);

  gpgme_result_unref (decrypt_result->pointer);

  G_OBJECT_CLASS (g_gpg_decrypt_result_parent_class)->finalize (object);
}

static void
g_gpg_decrypt_result_class_init (GGpgDecryptResultClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_decrypt_result_set_property;
  object_class->get_property = g_gpg_decrypt_result_get_property;
  object_class->finalize = g_gpg_decrypt_result_finalize;

  decrypt_result_pspecs[DECRYPT_RESULT_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);

  decrypt_result_pspecs[DECRYPT_RESULT_PROP_FILENAME] =
    g_param_spec_string ("filename", NULL, NULL,
                         "",
                         G_PARAM_READABLE);

  g_object_class_install_properties (object_class, DECRYPT_RESULT_LAST_PROP,
                                     decrypt_result_pspecs);
}

static void
g_gpg_decrypt_result_init (GGpgDecryptResult *decrypt_result)
{
}

/**
 * g_gpg_decrypt_result_get_recipients:
 * @decrypt_result: a #GGpgDecryptResult
 *
 * Returns: (transfer full) (element-type GGpgRecipient): a list of
 * #GGpgRecipient
 */
GList *
g_gpg_decrypt_result_get_recipients (GGpgDecryptResult *decrypt_result)
{
  gpgme_recipient_t recipients = decrypt_result->pointer->recipients;
  GList *result = NULL;

  for (; recipients; recipients = recipients->next)
    {
      GGpgRecipient *recipient =
        g_object_new (G_GPG_TYPE_RECIPIENT, "pointer", recipients,
                      "owner", decrypt_result, NULL);
      result = g_list_append (result, recipient);
    }
  return result;
}

struct GGpgDecryptSource
{
  struct GGpgSource source;
  GGpgData *cipher;
  GGpgData *plain;
};

static void
g_gpg_decrypt_source_finalize (GSource *_source)
{
  struct GGpgDecryptSource *source = (struct GGpgDecryptSource *) _source;
  g_object_unref (source->cipher);
  g_object_unref (source->plain);
}

static void
_g_gpg_ctx_decrypt_begin (GGpgCtx *ctx,
                          struct GGpgDecryptSource *source,
                          GTask *task,
                          GCancellable *cancellable)
{
  gpgme_error_t err;

  err = gpgme_op_decrypt_start (ctx->pointer, source->cipher->pointer,
                                source->plain->pointer);
  if (err)
    {
      g_task_return_new_error (task, G_GPG_ERROR, gpgme_err_code (err),
                               "%s", gpgme_strerror (err));
      return;
    }

  g_gpg_source_connect_cancellable ((struct GGpgSource *) source, cancellable);
  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

void
g_gpg_ctx_decrypt (GGpgCtx *ctx, GGpgData *cipher, GGpgData *plain,
                   GCancellable *cancellable,
                   GAsyncReadyCallback callback,
                   gpointer user_data)
{
  GTask *task;
  struct GGpgDecryptSource *source;

  task = g_task_new (ctx, cancellable, callback, user_data);
  source = G_GPG_SOURCE_NEW (struct GGpgDecryptSource, ctx);
  source->cipher = g_object_ref (cipher);
  source->plain = g_object_ref (plain);
  g_task_set_task_data (task, source,
                        (GDestroyNotify) g_gpg_decrypt_source_finalize);
  _g_gpg_ctx_decrypt_begin (ctx, source, task, cancellable);
}

gboolean
g_gpg_ctx_decrypt_finish (GGpgCtx *ctx, GAsyncResult *result, GError **error)
{
  g_return_val_if_fail (g_task_is_valid (result, ctx), FALSE);
  return g_task_propagate_boolean (G_TASK (result), error);
}

static void
_g_gpg_ctx_decrypt_verify_begin (GGpgCtx *ctx,
                                 struct GGpgDecryptSource *source,
                                 GTask *task,
                                 GCancellable *cancellable)
{
  gpgme_error_t err;

  err = gpgme_op_decrypt_verify_start (ctx->pointer, source->cipher->pointer,
                                       source->plain->pointer);
  if (err)
    {
      g_task_return_new_error (task, G_GPG_ERROR, gpgme_err_code (err),
                               "%s", gpgme_strerror (err));
      return;
    }

  g_gpg_source_connect_cancellable ((struct GGpgSource *) source, cancellable);
  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

void
g_gpg_ctx_decrypt_verify (GGpgCtx *ctx, GGpgData *cipher, GGpgData *plain,
                          GCancellable *cancellable,
                          GAsyncReadyCallback callback,
                          gpointer user_data)
{
  GTask *task;
  struct GGpgDecryptSource *source;

  task = g_task_new (ctx, cancellable, callback, user_data);
  source = G_GPG_SOURCE_NEW (struct GGpgDecryptSource, ctx);
  source->cipher = g_object_ref (cipher);
  source->plain = g_object_ref (plain);
  g_task_set_task_data (task, source,
                        (GDestroyNotify) g_gpg_decrypt_source_finalize);
  _g_gpg_ctx_decrypt_verify_begin (ctx, source, task, cancellable);
}

gboolean
g_gpg_ctx_decrypt_verify_finish (GGpgCtx *ctx, GAsyncResult *result,
                                 GError **error)
{
  g_return_val_if_fail (g_task_is_valid (result, ctx), FALSE);
  return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * g_gpg_ctx_decrypt_result:
 * @ctx: a #GGpgCtx
 *
 * Returns: (transfer full): a #GGpgDecryptResult
 */
GGpgDecryptResult *
g_gpg_ctx_decrypt_result (GGpgCtx *ctx)
{
  gpgme_decrypt_result_t decrypt_result;

  decrypt_result = gpgme_op_decrypt_result (ctx->pointer);
  g_return_val_if_fail (decrypt_result, NULL);
  return g_object_new (G_GPG_TYPE_DECRYPT_RESULT, "pointer", decrypt_result,
                       NULL);
}

struct _GGpgSignatureNotation
{
  GObject parent;
  gpgme_sig_notation_t pointer;
  GGpgSignature *owner;
  gchar *name;
  gchar *value;
  GGpgSignatureNotationFlags flags;
};

G_DEFINE_TYPE (GGpgSignatureNotation, g_gpg_signature_notation, G_TYPE_OBJECT)

enum {
  SIGNATURE_NOTATION_PROP_0,
  SIGNATURE_NOTATION_PROP_POINTER,
  SIGNATURE_NOTATION_PROP_OWNER,
  SIGNATURE_NOTATION_PROP_NAME,
  SIGNATURE_NOTATION_PROP_VALUE,
  SIGNATURE_NOTATION_PROP_FLAGS,
  SIGNATURE_NOTATION_LAST_PROP
};

static GParamSpec *signature_notation_pspecs[SIGNATURE_NOTATION_LAST_PROP] =
  { NULL, };

static void
g_gpg_signature_notation_set_property (GObject *object,
                                       guint property_id,
                                       const GValue *value,
                                       GParamSpec *pspec)
{
  GGpgSignatureNotation *signature_notation = G_GPG_SIGNATURE_NOTATION (object);

  switch (property_id)
    {
    case SIGNATURE_NOTATION_PROP_POINTER:
      signature_notation->pointer = g_value_get_pointer (value);
      break;

    case SIGNATURE_NOTATION_PROP_OWNER:
      signature_notation->owner = g_value_dup_object (value);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_signature_notation_get_property (GObject *object,
                                       guint property_id,
                                       GValue *value,
                                       GParamSpec *pspec)
{
  GGpgSignatureNotation *signature_notation = G_GPG_SIGNATURE_NOTATION (object);

  switch (property_id)
    {
    case SIGNATURE_NOTATION_PROP_NAME:
      g_value_set_string (value, signature_notation->name);
      break;

    case SIGNATURE_NOTATION_PROP_VALUE:
      g_value_set_string (value, signature_notation->value);
      break;

    case SIGNATURE_NOTATION_PROP_FLAGS:
      g_value_set_flags (value, signature_notation->pointer->flags);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_signature_notation_dispose (GObject *object)
{
  GGpgSignatureNotation *signature_notation = G_GPG_SIGNATURE_NOTATION (object);

  g_clear_object (&signature_notation->owner);

  G_OBJECT_CLASS (g_gpg_signature_notation_parent_class)->dispose (object);
}

static void
g_gpg_signature_notation_finalize (GObject *object)
{
  GGpgSignatureNotation *signature_notation = G_GPG_SIGNATURE_NOTATION (object);

  g_free (signature_notation->name);
  g_free (signature_notation->value);

  G_OBJECT_CLASS (g_gpg_signature_notation_parent_class)->finalize (object);
}

static void
g_gpg_signature_notation_constructed (GObject *object)
{
  GGpgSignatureNotation *signature_notation = G_GPG_SIGNATURE_NOTATION (object);

  G_OBJECT_CLASS (g_gpg_signature_notation_parent_class)->constructed (object);

  signature_notation->name =
    g_strndup (signature_notation->pointer->name,
               signature_notation->pointer->name_len);
  signature_notation->value =
    g_strndup (signature_notation->pointer->value,
               signature_notation->pointer->value_len);
}

static void
g_gpg_signature_notation_class_init (GGpgSignatureNotationClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_signature_notation_set_property;
  object_class->get_property = g_gpg_signature_notation_get_property;
  object_class->dispose = g_gpg_signature_notation_dispose;
  object_class->finalize = g_gpg_signature_notation_finalize;
  object_class->constructed = g_gpg_signature_notation_constructed;

  signature_notation_pspecs[SIGNATURE_NOTATION_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);
  signature_notation_pspecs[SIGNATURE_NOTATION_PROP_OWNER] =
    g_param_spec_object ("owner", NULL, NULL,
                         G_GPG_TYPE_SIGNATURE,
                         G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);
  signature_notation_pspecs[SIGNATURE_NOTATION_PROP_NAME] =
    g_param_spec_string ("name", NULL, NULL, "", G_PARAM_READABLE);
  signature_notation_pspecs[SIGNATURE_NOTATION_PROP_VALUE] =
    g_param_spec_string ("value", NULL, NULL, "", G_PARAM_READABLE);
  signature_notation_pspecs[SIGNATURE_NOTATION_PROP_FLAGS] =
    g_param_spec_flags ("flags", NULL, NULL,
                        G_GPG_TYPE_SIGNATURE_NOTATION_FLAGS, 0,
                        G_PARAM_READABLE);

  g_object_class_install_properties (object_class, SIGNATURE_NOTATION_LAST_PROP,
                                     signature_notation_pspecs);
}

static void
g_gpg_signature_notation_init (GGpgSignatureNotation *signature_notation)
{
}

struct _GGpgSignature
{
  GObject parent;
  gpgme_signature_t pointer;
  GGpgVerifyResult *owner;
  GGpgSignatureStatus status;
  GGpgSignatureFlags flags;
};

G_DEFINE_TYPE (GGpgSignature, g_gpg_signature, G_TYPE_OBJECT)

enum {
  SIGNATURE_PROP_0,
  SIGNATURE_PROP_POINTER,
  SIGNATURE_PROP_OWNER,
  SIGNATURE_PROP_SUMMARY,
  SIGNATURE_PROP_FINGERPRINT,
  SIGNATURE_PROP_STATUS,
  SIGNATURE_PROP_CREATED,
  SIGNATURE_PROP_EXPIRES,
  SIGNATURE_PROP_FLAGS,
  SIGNATURE_PROP_VALIDITY,
  SIGNATURE_PROP_PUBKEY_ALGO,
  SIGNATURE_PROP_HASH_ALGO,
  SIGNATURE_LAST_PROP
};

static GParamSpec *signature_pspecs[SIGNATURE_LAST_PROP] = { NULL, };

static void
g_gpg_signature_set_property (GObject *object,
                              guint property_id,
                              const GValue *value,
                              GParamSpec *pspec)
{
  GGpgSignature *signature = G_GPG_SIGNATURE (object);

  switch (property_id)
    {
    case SIGNATURE_PROP_POINTER:
      signature->pointer = g_value_get_pointer (value);
      break;

    case SIGNATURE_PROP_OWNER:
      signature->owner = g_value_dup_object (value);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_signature_get_property (GObject *object,
                              guint property_id,
                              GValue *value,
                              GParamSpec *pspec)
{
  GGpgSignature *signature = G_GPG_SIGNATURE (object);

  switch (property_id)
    {
    case SIGNATURE_PROP_SUMMARY:
      g_value_set_flags (value, signature->pointer->summary);
      break;

    case SIGNATURE_PROP_FINGERPRINT:
      g_value_set_string (value, signature->pointer->fpr);
      break;

    case SIGNATURE_PROP_STATUS:
      g_value_set_enum (value, signature->status);
      break;

    case SIGNATURE_PROP_CREATED:
      g_value_set_int64 (value, signature->pointer->timestamp);
      break;

    case SIGNATURE_PROP_EXPIRES:
      g_value_set_int64 (value, signature->pointer->exp_timestamp);
      break;

    case SIGNATURE_PROP_FLAGS:
      g_value_set_flags (value, signature->flags);
      break;

    case SIGNATURE_PROP_VALIDITY:
      g_value_set_enum (value, signature->pointer->validity);
      break;

    case SIGNATURE_PROP_PUBKEY_ALGO:
      g_value_set_enum (value, signature->pointer->pubkey_algo);
      break;

    case SIGNATURE_PROP_HASH_ALGO:
      g_value_set_enum (value, signature->pointer->hash_algo);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_signature_dispose (GObject *object)
{
  GGpgSignature *signature = G_GPG_SIGNATURE (object);

  g_clear_object (&signature->owner);

  G_OBJECT_CLASS (g_gpg_signature_parent_class)->dispose (object);
}

static void
g_gpg_signature_constructed (GObject *object)
{
  GGpgSignature *signature = G_GPG_SIGNATURE (object);

  G_OBJECT_CLASS (g_gpg_signature_parent_class)->constructed (object);

  switch (gpg_err_code (signature->pointer->status))
    {
    case G_GPG_ERROR_NO_ERROR:
      signature->status = G_GPG_SIGNATURE_STATUS_GOOD;
      break;

    case G_GPG_ERROR_BAD_SIGNATURE:
      signature->status = G_GPG_SIGNATURE_STATUS_BAD;
      break;

    case G_GPG_ERROR_NO_PUBKEY:
      signature->status = G_GPG_SIGNATURE_STATUS_NOKEY;
      break;

    case G_GPG_ERROR_NO_DATA:
      signature->status = G_GPG_SIGNATURE_STATUS_NOSIG;
      break;

    case G_GPG_ERROR_SIG_EXPIRED:
      signature->status = G_GPG_SIGNATURE_STATUS_GOOD_EXP;
      break;

    case G_GPG_ERROR_KEY_EXPIRED:
      signature->status = G_GPG_SIGNATURE_STATUS_GOOD_EXPKEY;
      break;

    default:
      signature->status = G_GPG_SIGNATURE_STATUS_ERROR;
      break;
    }

  signature->flags = 0;
  if (signature->pointer->wrong_key_usage)
    signature->flags |= G_GPG_SIGNATURE_FLAG_WRONG_KEY_USAGE;
  if (signature->pointer->chain_model)
    signature->flags |= G_GPG_SIGNATURE_FLAG_CHAIN_MODEL;

  switch (signature->pointer->pka_trust)
    {
    case 1:
      signature->flags |= G_GPG_SIGNATURE_FLAG_PKA_TRUST_BAD;
      break;

    case 2:
      signature->flags |= G_GPG_SIGNATURE_FLAG_PKA_TRUST_GOOD;
      break;

    default:
      break;
    }
}

static void
g_gpg_signature_class_init (GGpgSignatureClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_signature_set_property;
  object_class->get_property = g_gpg_signature_get_property;
  object_class->dispose = g_gpg_signature_dispose;
  object_class->constructed = g_gpg_signature_constructed;

  signature_pspecs[SIGNATURE_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);

  signature_pspecs[SIGNATURE_PROP_OWNER] =
    g_param_spec_object ("owner", NULL, NULL,
                         G_GPG_TYPE_VERIFY_RESULT,
                         G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);

  signature_pspecs[SIGNATURE_PROP_SUMMARY] =
    g_param_spec_flags ("summary", NULL, NULL,
                        G_GPG_TYPE_SIGNATURE_SUMMARY_FLAGS, 0,
                        G_PARAM_READABLE);
  signature_pspecs[SIGNATURE_PROP_FINGERPRINT] =
    g_param_spec_string ("fingerprint", NULL, NULL,
                         NULL,
                         G_PARAM_READABLE);
  signature_pspecs[SIGNATURE_PROP_STATUS] =
    g_param_spec_enum ("status", NULL, NULL,
                       G_GPG_TYPE_SIGNATURE_STATUS, 0,
                       G_PARAM_READABLE);
  signature_pspecs[SIGNATURE_PROP_CREATED] =
    g_param_spec_int64 ("created", NULL, NULL,
                        0, G_MAXINT64, 0,
                        G_PARAM_READABLE);
  signature_pspecs[SIGNATURE_PROP_EXPIRES] =
    g_param_spec_int64 ("expires", NULL, NULL,
                        0, G_MAXINT64, 0,
                        G_PARAM_READABLE);
  signature_pspecs[SIGNATURE_PROP_FLAGS] =
    g_param_spec_flags ("flags", NULL, NULL,
                        G_GPG_TYPE_SIGNATURE_FLAGS, 0,
                        G_PARAM_READABLE);
  signature_pspecs[SIGNATURE_PROP_VALIDITY] =
    g_param_spec_enum ("validity", NULL, NULL,
                       G_GPG_TYPE_VALIDITY, G_GPG_VALIDITY_UNKNOWN,
                       G_PARAM_READABLE);
  signature_pspecs[SIGNATURE_PROP_PUBKEY_ALGO] =
    g_param_spec_enum ("pubkey-algo", NULL, NULL,
                       G_GPG_TYPE_PUBKEY_ALGO, G_GPG_PK_NONE,
                       G_PARAM_READABLE);
  signature_pspecs[SIGNATURE_PROP_HASH_ALGO] =
    g_param_spec_enum ("hash-algo", NULL, NULL,
                       G_GPG_TYPE_HASH_ALGO, G_GPG_MD_NONE,
                       G_PARAM_READABLE);

  g_object_class_install_properties (object_class, SIGNATURE_LAST_PROP,
                                     signature_pspecs);
}

static void
g_gpg_signature_init (GGpgSignature *signature)
{
}

/**
 * g_gpg_signature_get_notations:
 * @signature: a #GGpgSignature
 *
 * Returns: (transfer full) (element-type GGpgSignatureNotation): a
 * list of #GGpgSignatureNotation
 */
GList *
g_gpg_signature_get_notations (GGpgSignature *signature)
{
  gpgme_sig_notation_t notations = signature->pointer->notations;
  GList *result = NULL;

  for (; notations; notations = notations->next)
    {
      GGpgSignatureNotation *notation =
        g_object_new (G_GPG_TYPE_SUBKEY, "pointer", notations,
                      "owner", signature, NULL);
      result = g_list_append (result, notation);
    }
  return result;
}

struct _GGpgVerifyResult
{
  GObject parent;
  gpgme_verify_result_t pointer;
};

G_DEFINE_TYPE (GGpgVerifyResult, g_gpg_verify_result, G_TYPE_OBJECT)

enum {
  VERIFY_RESULT_PROP_0,
  VERIFY_RESULT_PROP_POINTER,
  VERIFY_RESULT_PROP_FILENAME,
  VERIFY_RESULT_LAST_PROP
};

static GParamSpec *verify_result_pspecs[VERIFY_RESULT_LAST_PROP] = { NULL, };

static void
g_gpg_verify_result_set_property (GObject *object,
                                   guint property_id,
                                   const GValue *value,
                                   GParamSpec *pspec)
{
  GGpgVerifyResult *verify_result = G_GPG_VERIFY_RESULT (object);

  switch (property_id)
    {
    case VERIFY_RESULT_PROP_POINTER:
      {
        gpgme_verify_result_t pointer = g_value_get_pointer (value);
        gpgme_result_ref (pointer);
        verify_result->pointer = pointer;
      }
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_verify_result_get_property (GObject *object,
                                  guint property_id,
                                  GValue *value,
                                  GParamSpec *pspec)
{
  GGpgVerifyResult *verify_result = G_GPG_VERIFY_RESULT (object);

  switch (property_id)
    {
    case VERIFY_RESULT_PROP_FILENAME:
      g_value_set_string (value, verify_result->pointer->file_name);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_verify_result_finalize (GObject *object)
{
  GGpgVerifyResult *verify_result = G_GPG_VERIFY_RESULT (object);

  gpgme_result_unref (verify_result->pointer);

  G_OBJECT_CLASS (g_gpg_verify_result_parent_class)->finalize (object);
}

static void
g_gpg_verify_result_class_init (GGpgVerifyResultClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_verify_result_set_property;
  object_class->get_property = g_gpg_verify_result_get_property;
  object_class->finalize = g_gpg_verify_result_finalize;

  verify_result_pspecs[VERIFY_RESULT_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);

  verify_result_pspecs[VERIFY_RESULT_PROP_FILENAME] =
    g_param_spec_string ("filename", NULL, NULL,
                         "",
                         G_PARAM_READABLE);

  g_object_class_install_properties (object_class, VERIFY_RESULT_LAST_PROP,
                                     verify_result_pspecs);
}

static void
g_gpg_verify_result_init (GGpgVerifyResult *verify_result)
{
}

/**
 * g_gpg_verify_result_get_signatures:
 * @verify_result: a #GGpgVerifyResult
 *
 * Returns: (transfer full) (element-type GGpgSignature): a list of
 * #GGpgSignature
 */
GList *
g_gpg_verify_result_get_signatures (GGpgVerifyResult *verify_result)
{
  gpgme_signature_t signatures = verify_result->pointer->signatures;
  GList *result = NULL;

  for (; signatures; signatures = signatures->next)
    {
      GGpgSignature *signature =
        g_object_new (G_GPG_TYPE_SIGNATURE, "pointer", signatures,
                      "owner", verify_result, NULL);
      result = g_list_append (result, signature);
    }
  return result;
}

struct GGpgVerifySource
{
  struct GGpgSource source;
  GGpgData *sig;
  GGpgData *signed_text;
  GGpgData *plain;
};

static void
g_gpg_verify_source_finalize (GSource *_source)
{
  struct GGpgVerifySource *source = (struct GGpgVerifySource *) _source;
  g_object_unref (source->sig);
  g_object_unref (source->signed_text);
  g_object_unref (source->plain);
}

static void
_g_gpg_ctx_verify_begin (GGpgCtx *ctx,
                         struct GGpgVerifySource *source,
                         GTask *task,
                         GCancellable *cancellable)
{
  gpgme_error_t err;

  err = gpgme_op_verify_start (ctx->pointer, source->sig->pointer,
                               source->signed_text->pointer,
                               source->plain->pointer);
  if (err)
    {
      g_task_return_new_error (task, G_GPG_ERROR, gpgme_err_code (err),
                               "%s", gpgme_strerror (err));
      return;
    }

  g_gpg_source_connect_cancellable ((struct GGpgSource *) source, cancellable);
  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

void
g_gpg_ctx_verify (GGpgCtx *ctx, GGpgData *sig, GGpgData *signed_text,
                  GGpgData *plain,
                  GCancellable *cancellable,
                  GAsyncReadyCallback callback,
                  gpointer user_data)
{
  GTask *task;
  struct GGpgVerifySource *source;

  task = g_task_new (ctx, cancellable, callback, user_data);
  source = G_GPG_SOURCE_NEW (struct GGpgVerifySource, ctx);
  source->sig = g_object_ref (sig);
  source->signed_text = g_object_ref (signed_text);
  source->plain = g_object_ref (plain);
  g_task_set_task_data (task, source,
                        (GDestroyNotify) g_gpg_verify_source_finalize);
  _g_gpg_ctx_verify_begin (ctx, source, task, cancellable);
}

gboolean
g_gpg_ctx_verify_finish (GGpgCtx *ctx, GAsyncResult *result, GError **error)
{
  g_return_val_if_fail (g_task_is_valid (result, ctx), FALSE);
  return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * g_gpg_ctx_verify_result:
 * @ctx: a #GGpgCtx
 *
 * Returns: (transfer full): a #GGpgVerifyResult
 */
GGpgVerifyResult *
g_gpg_ctx_verify_result (GGpgCtx *ctx)
{
  gpgme_verify_result_t verify_result;

  verify_result = gpgme_op_verify_result (ctx->pointer);
  g_return_val_if_fail (verify_result, NULL);
  return g_object_new (G_GPG_TYPE_VERIFY_RESULT, "pointer", verify_result,
                       NULL);
}

void
g_gpg_ctx_add_signer (GGpgCtx *ctx, GGpgKey *key)
{
  g_mutex_lock (&ctx->lock);
  g_ptr_array_add (ctx->signers, g_object_ref (key));
  gpgme_signers_add (ctx->pointer, key->pointer);
  g_mutex_unlock (&ctx->lock);
}

guint
g_gpg_ctx_get_n_signers (GGpgCtx *ctx)
{
  return ctx->signers->len;
}

/**
 * g_gpg_ctx_get_signer:
 * @ctx: a #GGpgCtx
 * @index: the index
 *
 * Returns: (transfer none): a #GGpgKey
 */
GGpgKey *
g_gpg_ctx_get_signer (GGpgCtx *ctx, guint index)
{
  return g_ptr_array_index (ctx->signers, index);
}

void
g_gpg_ctx_clear_signers (GGpgCtx *ctx)
{
  g_mutex_lock (&ctx->lock);
  g_ptr_array_remove_range (ctx->signers, 0, ctx->signers->len);
  g_mutex_unlock (&ctx->lock);
}

struct _GGpgNewSignature
{
  GObject parent;
  gpgme_new_signature_t pointer;
  GGpgSignResult *owner;
};

G_DEFINE_TYPE (GGpgNewSignature, g_gpg_new_signature, G_TYPE_OBJECT)

enum {
  NEW_SIGNATURE_PROP_0,
  NEW_SIGNATURE_PROP_POINTER,
  NEW_SIGNATURE_PROP_OWNER,
  NEW_SIGNATURE_PROP_MODE,
  NEW_SIGNATURE_PROP_PUBKEY_ALGO,
  NEW_SIGNATURE_PROP_HASH_ALGO,
  NEW_SIGNATURE_PROP_CLASS,
  NEW_SIGNATURE_PROP_CREATED,
  NEW_SIGNATURE_PROP_FINGERPRINT,
  NEW_SIGNATURE_LAST_PROP
};

static GParamSpec *new_signature_pspecs[NEW_SIGNATURE_LAST_PROP] = { NULL, };

static void
g_gpg_new_signature_set_property (GObject *object,
                                  guint property_id,
                                  const GValue *value,
                                  GParamSpec *pspec)
{
  GGpgNewSignature *new_signature = G_GPG_NEW_SIGNATURE (object);

  switch (property_id)
    {
    case NEW_SIGNATURE_PROP_POINTER:
      new_signature->pointer = g_value_get_pointer (value);
      break;

    case NEW_SIGNATURE_PROP_OWNER:
      new_signature->owner = g_value_dup_object (value);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_new_signature_get_property (GObject *object,
                                  guint property_id,
                                  GValue *value,
                                  GParamSpec *pspec)
{
  GGpgNewSignature *new_signature = G_GPG_NEW_SIGNATURE (object);

  switch (property_id)
    {
    case NEW_SIGNATURE_PROP_MODE:
      g_value_set_enum (value, new_signature->pointer->type);
      break;

    case NEW_SIGNATURE_PROP_PUBKEY_ALGO:
      g_value_set_enum (value, new_signature->pointer->pubkey_algo);
      break;

    case NEW_SIGNATURE_PROP_HASH_ALGO:
      g_value_set_enum (value, new_signature->pointer->hash_algo);
      break;

    case NEW_SIGNATURE_PROP_CLASS:
      g_value_set_uint (value, new_signature->pointer->sig_class);
      break;

    case NEW_SIGNATURE_PROP_CREATED:
      g_value_set_int64 (value, new_signature->pointer->timestamp);
      break;

    case NEW_SIGNATURE_PROP_FINGERPRINT:
      g_value_set_string (value, new_signature->pointer->fpr);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_new_signature_dispose (GObject *object)
{
  GGpgNewSignature *new_signature = G_GPG_NEW_SIGNATURE (object);

  g_clear_object (&new_signature->owner);

  G_OBJECT_CLASS (g_gpg_new_signature_parent_class)->dispose (object);
}

static void
g_gpg_new_signature_class_init (GGpgNewSignatureClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_new_signature_set_property;
  object_class->get_property = g_gpg_new_signature_get_property;
  object_class->dispose = g_gpg_new_signature_dispose;

  new_signature_pspecs[NEW_SIGNATURE_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);

  new_signature_pspecs[NEW_SIGNATURE_PROP_OWNER] =
    g_param_spec_object ("owner", NULL, NULL,
                         G_GPG_TYPE_VERIFY_RESULT,
                         G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);

  new_signature_pspecs[NEW_SIGNATURE_PROP_MODE] =
    g_param_spec_enum ("mode", NULL, NULL,
                       G_GPG_TYPE_SIGN_MODE, G_GPG_SIGN_MODE_NORMAL,
                       G_PARAM_READABLE);
  new_signature_pspecs[NEW_SIGNATURE_PROP_PUBKEY_ALGO] =
    g_param_spec_enum ("pubkey-algo", NULL, NULL,
                       G_GPG_TYPE_PUBKEY_ALGO, G_GPG_PK_NONE,
                       G_PARAM_READABLE);
  new_signature_pspecs[NEW_SIGNATURE_PROP_HASH_ALGO] =
    g_param_spec_enum ("hash-algo", NULL, NULL,
                       G_GPG_TYPE_HASH_ALGO, G_GPG_MD_NONE,
                       G_PARAM_READABLE);
  new_signature_pspecs[NEW_SIGNATURE_PROP_CLASS] =
    g_param_spec_uint ("class", NULL, NULL,
                       0, G_MAXUINT, 0,
                       G_PARAM_READABLE);
  new_signature_pspecs[NEW_SIGNATURE_PROP_CREATED] =
    g_param_spec_int64 ("created", NULL, NULL,
                        0, G_MAXINT64, 0,
                        G_PARAM_READABLE);
  new_signature_pspecs[NEW_SIGNATURE_PROP_FINGERPRINT] =
    g_param_spec_string ("fingerprint", NULL, NULL,
                         NULL,
                         G_PARAM_READABLE);

  g_object_class_install_properties (object_class, NEW_SIGNATURE_LAST_PROP,
                                     new_signature_pspecs);
}

static void
g_gpg_new_signature_init (GGpgNewSignature *new_signature)
{
}

struct _GGpgInvalidKey
{
  GObject parent;
  gpgme_invalid_key_t pointer;
  GObject *owner;
};

G_DEFINE_TYPE (GGpgInvalidKey, g_gpg_invalid_key, G_TYPE_OBJECT)

enum {
  INVALID_KEY_PROP_0,
  INVALID_KEY_PROP_POINTER,
  INVALID_KEY_PROP_OWNER,
  INVALID_KEY_PROP_FINGERPRINT,
  INVALID_KEY_LAST_PROP
};

static GParamSpec *invalid_key_pspecs[INVALID_KEY_LAST_PROP] = { NULL, };

static void
g_gpg_invalid_key_set_property (GObject *object,
                                guint property_id,
                                const GValue *value,
                                GParamSpec *pspec)
{
  GGpgInvalidKey *invalid_key = G_GPG_INVALID_KEY (object);

  switch (property_id)
    {
    case INVALID_KEY_PROP_POINTER:
      invalid_key->pointer = g_value_get_pointer (value);
      break;

    case INVALID_KEY_PROP_OWNER:
      invalid_key->owner = g_value_dup_object (value);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_invalid_key_get_property (GObject *object,
                                guint property_id,
                                GValue *value,
                                GParamSpec *pspec)
{
  GGpgInvalidKey *invalid_key = G_GPG_INVALID_KEY (object);
  switch (property_id)
    {
    case INVALID_KEY_PROP_FINGERPRINT:
      g_value_set_string (value, invalid_key->pointer->fpr);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_invalid_key_dispose (GObject *object)
{
  GGpgInvalidKey *invalid_key = G_GPG_INVALID_KEY (object);

  g_clear_object (&invalid_key->owner);

  G_OBJECT_CLASS (g_gpg_invalid_key_parent_class)->finalize (object);
}

static void
g_gpg_invalid_key_class_init (GGpgInvalidKeyClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_invalid_key_set_property;
  object_class->get_property = g_gpg_invalid_key_get_property;
  object_class->dispose = g_gpg_invalid_key_dispose;

  invalid_key_pspecs[INVALID_KEY_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);
  invalid_key_pspecs[INVALID_KEY_PROP_OWNER] =
    g_param_spec_object ("owner", NULL, NULL,
                         G_TYPE_OBJECT,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);
  invalid_key_pspecs[INVALID_KEY_PROP_FINGERPRINT] =
    g_param_spec_string ("fingerprint", NULL, NULL,
                         NULL,
                         G_PARAM_READABLE);

  g_object_class_install_properties (object_class, INVALID_KEY_LAST_PROP,
                                     invalid_key_pspecs);
}

static void
g_gpg_invalid_key_init (GGpgInvalidKey *invalid_key)
{
}

struct _GGpgSignResult
{
  GObject parent;
  gpgme_sign_result_t pointer;
};

G_DEFINE_TYPE (GGpgSignResult, g_gpg_sign_result, G_TYPE_OBJECT)

enum {
  SIGN_RESULT_PROP_0,
  SIGN_RESULT_PROP_POINTER,
  SIGN_RESULT_LAST_PROP
};

static GParamSpec *sign_result_pspecs[SIGN_RESULT_LAST_PROP] = { NULL, };

static void
g_gpg_sign_result_set_property (GObject *object,
                                guint property_id,
                                const GValue *value,
                                GParamSpec *pspec)
{
  GGpgSignResult *sign_result = G_GPG_SIGN_RESULT (object);

  switch (property_id)
    {
    case SIGN_RESULT_PROP_POINTER:
      {
        gpgme_sign_result_t pointer = g_value_get_pointer (value);
        gpgme_result_ref (pointer);
        sign_result->pointer = pointer;
      }
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_sign_result_finalize (GObject *object)
{
  GGpgSignResult *sign_result = G_GPG_SIGN_RESULT (object);

  gpgme_result_unref (sign_result->pointer);

  G_OBJECT_CLASS (g_gpg_sign_result_parent_class)->finalize (object);
}

static void
g_gpg_sign_result_class_init (GGpgSignResultClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_sign_result_set_property;
  object_class->finalize = g_gpg_sign_result_finalize;

  sign_result_pspecs[SIGN_RESULT_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);

  g_object_class_install_properties (object_class, SIGN_RESULT_LAST_PROP,
                                     sign_result_pspecs);
}

static void
g_gpg_sign_result_init (GGpgSignResult *sign_result)
{
}

/**
 * g_gpg_sign_result_get_signatures:
 * @sign_result: a #GGpgSignResult
 *
 * Returns: (transfer full) (element-type GGpgNewSignature): a list of
 * #GGpgNewSignature
 */
GList *
g_gpg_sign_result_get_signatures (GGpgSignResult *sign_result)
{
  gpgme_new_signature_t signatures = sign_result->pointer->signatures;
  GList *result = NULL;

  for (; signatures; signatures = signatures->next)
    {
      GGpgNewSignature *signature =
        g_object_new (G_GPG_TYPE_NEW_SIGNATURE, "pointer", signatures,
                      "owner", sign_result, NULL);
      result = g_list_append (result, signature);
    }
  return result;
}

/**
 * g_gpg_sign_result_get_invalid_signers:
 * @sign_result: a #GGpgSignResult
 *
 * Returns: (transfer full) (element-type GGpgInvalidKey): a list of
 * #GGpgInvalidKey
 */
GList *
g_gpg_sign_result_get_invalid_signers (GGpgSignResult *sign_result)
{
  gpgme_invalid_key_t invalid_signers = sign_result->pointer->invalid_signers;
  GList *result = NULL;

  for (; invalid_signers; invalid_signers = invalid_signers->next)
    {
      GGpgInvalidKey *invalid_signer =
        g_object_new (G_GPG_TYPE_INVALID_KEY, "pointer", invalid_signers,
                      "owner", sign_result, NULL);
      result = g_list_append (result, invalid_signer);
    }
  return result;
}

struct GGpgSignSource
{
  struct GGpgSource source;
  GGpgData *plain;
  GGpgData *sig;
  GGpgSignMode mode;
};

static void
g_gpg_sign_source_finalize (GSource *_source)
{
  struct GGpgSignSource *source = (struct GGpgSignSource *) _source;
  g_object_unref (source->plain);
  g_object_unref (source->sig);
}

static void
_g_gpg_ctx_sign_begin (GGpgCtx *ctx,
                       struct GGpgSignSource *source,
                       GTask *task,
                       GCancellable *cancellable)
{
  gpgme_error_t err;

  err = gpgme_op_sign_start (ctx->pointer, source->plain->pointer,
                             source->sig->pointer, source->mode);
  if (err)
    {
      g_task_return_new_error (task, G_GPG_ERROR, gpgme_err_code (err),
                               "%s", gpgme_strerror (err));
      return;
    }

  g_gpg_source_connect_cancellable ((struct GGpgSource *) source, cancellable);
  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

void
g_gpg_ctx_sign (GGpgCtx *ctx, GGpgData *plain, GGpgData *sig, GGpgSignMode mode,
                GCancellable *cancellable,
                GAsyncReadyCallback callback,
                gpointer user_data)
{
  GTask *task;
  struct GGpgSignSource *source;

  task = g_task_new (ctx, cancellable, callback, user_data);
  source = G_GPG_SOURCE_NEW (struct GGpgSignSource, ctx);
  source->plain = g_object_ref (plain);
  source->sig = g_object_ref (sig);
  source->mode = mode;
  g_task_set_task_data (task, source,
                        (GDestroyNotify) g_gpg_sign_source_finalize);
  _g_gpg_ctx_sign_begin (ctx, source, task, cancellable);
}

gboolean
g_gpg_ctx_sign_finish (GGpgCtx *ctx, GAsyncResult *result, GError **error)
{
  g_return_val_if_fail (g_task_is_valid (result, ctx), FALSE);
  return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * g_gpg_ctx_sign_result:
 * @ctx: a #GGpgCtx
 *
 * Returns: (transfer full): a #GGpgSignResult
 */
GGpgSignResult *
g_gpg_ctx_sign_result (GGpgCtx *ctx)
{
  gpgme_sign_result_t sign_result;

  sign_result = gpgme_op_sign_result (ctx->pointer);
  g_return_val_if_fail (sign_result, NULL);
  return g_object_new (G_GPG_TYPE_SIGN_RESULT, "pointer", sign_result,
                       NULL);
}

struct _GGpgEncryptResult
{
  GObject parent;
  gpgme_encrypt_result_t pointer;
};

G_DEFINE_TYPE (GGpgEncryptResult, g_gpg_encrypt_result, G_TYPE_OBJECT)

enum {
  ENCRYPT_RESULT_PROP_0,
  ENCRYPT_RESULT_PROP_POINTER,
  ENCRYPT_RESULT_LAST_PROP
};

static GParamSpec *encrypt_result_pspecs[ENCRYPT_RESULT_LAST_PROP] = { NULL, };

static void
g_gpg_encrypt_result_set_property (GObject *object,
                                   guint property_id,
                                   const GValue *value,
                                   GParamSpec *pspec)
{
  GGpgEncryptResult *encrypt_result = G_GPG_ENCRYPT_RESULT (object);

  switch (property_id)
    {
    case ENCRYPT_RESULT_PROP_POINTER:
      {
        gpgme_encrypt_result_t pointer = g_value_get_pointer (value);
        gpgme_result_ref (pointer);
        encrypt_result->pointer = pointer;
      }
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
g_gpg_encrypt_result_finalize (GObject *object)
{
  GGpgEncryptResult *encrypt_result = G_GPG_ENCRYPT_RESULT (object);

  gpgme_result_unref (encrypt_result->pointer);

  G_OBJECT_CLASS (g_gpg_encrypt_result_parent_class)->finalize (object);
}

static void
g_gpg_encrypt_result_class_init (GGpgEncryptResultClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->set_property = g_gpg_encrypt_result_set_property;
  object_class->finalize = g_gpg_encrypt_result_finalize;

  encrypt_result_pspecs[ENCRYPT_RESULT_PROP_POINTER] =
    g_param_spec_pointer ("pointer", NULL, NULL,
                          G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY);

  g_object_class_install_properties (object_class, ENCRYPT_RESULT_LAST_PROP,
                                     encrypt_result_pspecs);
}

static void
g_gpg_encrypt_result_init (GGpgEncryptResult *encrypt_result)
{
}

/**
 * g_gpg_encrypt_result_get_invalid_recipients:
 * @encrypt_result: a #GGpgEncryptResult
 *
 * Returns: (transfer full) (element-type GGpgInvalidKey): a list of
 * #GGpgInvalidKey
 */
GList *
g_gpg_encrypt_result_get_invalid_recipients (GGpgEncryptResult *encrypt_result)
{
  gpgme_invalid_key_t invalid_recipients =
    encrypt_result->pointer->invalid_recipients;
  GList *result = NULL;

  for (; invalid_recipients; invalid_recipients = invalid_recipients->next)
    {
      GGpgInvalidKey *invalid_recipient =
        g_object_new (G_GPG_TYPE_INVALID_KEY, "pointer", invalid_recipients,
                      "owner", encrypt_result, NULL);
      result = g_list_append (result, invalid_recipient);
    }
  return result;
}

struct GGpgEncryptSource
{
  struct GGpgSource source;
  gpgme_key_t *recipients;
  GGpgEncryptFlags flags;
  GGpgData *plain;
  GGpgData *cipher;
};

static void
g_gpg_encrypt_source_finalize (GSource *_source)
{
  struct GGpgEncryptSource *source = (struct GGpgEncryptSource *) _source;
  gpgme_key_t *recipients = source->recipients;

  for (; *recipients; recipients++)
    gpgme_key_unref (*recipients);
  g_free (recipients);

  g_object_unref (source->cipher);
  g_object_unref (source->plain);
}

static void
_g_gpg_ctx_encrypt_begin (GGpgCtx *ctx,
                          struct GGpgEncryptSource *source,
                          GTask *task,
                          GCancellable *cancellable)
{
  gpgme_error_t err;

  err = gpgme_op_encrypt_start (ctx->pointer, source->recipients,
                                source->flags,
                                source->plain->pointer,
                                source->cipher->pointer);
  if (err)
    {
      g_task_return_new_error (task, G_GPG_ERROR, gpgme_err_code (err),
                               "%s", gpgme_strerror (err));
      return;
    }

  g_gpg_source_connect_cancellable ((struct GGpgSource *) source, cancellable);
  g_task_attach_source (task, (GSource *) source, _g_gpg_source_func);
  g_source_unref ((GSource *) source);
}

void
g_gpg_ctx_encrypt (GGpgCtx *ctx, GGpgKey **recipients,
                   GGpgData *plain, GGpgData *cipher,
                   GGpgEncryptFlags flags,
                   GCancellable *cancellable,
                   GAsyncReadyCallback callback,
                   gpointer user_data)
{
  GTask *task;
  struct GGpgEncryptSource *source;
  GPtrArray *array;

  array = g_ptr_array_new ();
  for (; *recipients; recipients++)
    {
      GGpgKey *recipient = *recipients;

      gpgme_key_ref (recipient->pointer);
      g_ptr_array_add (array, recipient->pointer);
    }
  g_ptr_array_add (array, NULL);

  task = g_task_new (ctx, cancellable, callback, user_data);
  source = G_GPG_SOURCE_NEW (struct GGpgEncryptSource, ctx);
  source->recipients = (gpgme_key_t *) g_ptr_array_free (array, FALSE);
  source->plain = g_object_ref (plain);
  source->cipher = g_object_ref (cipher);
  source->flags = flags;
  g_task_set_task_data (task, source,
                        (GDestroyNotify) g_gpg_encrypt_source_finalize);
  _g_gpg_ctx_encrypt_begin (ctx, source, task, cancellable);
}

gboolean
g_gpg_ctx_encrypt_finish (GGpgCtx *ctx, GAsyncResult *result, GError **error)
{
  g_return_val_if_fail (g_task_is_valid (result, ctx), FALSE);
  return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * g_gpg_ctx_encrypt_result:
 * @ctx: a #GGpgCtx
 *
 * Returns: (transfer full): a #GGpgEncryptResult
 */
GGpgEncryptResult *
g_gpg_ctx_encrypt_result (GGpgCtx *ctx)
{
  gpgme_encrypt_result_t encrypt_result;

  encrypt_result = gpgme_op_encrypt_result (ctx->pointer);
  g_return_val_if_fail (encrypt_result, NULL);
  return g_object_new (G_GPG_TYPE_ENCRYPT_RESULT, "pointer", encrypt_result,
                       NULL);
}
