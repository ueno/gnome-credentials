#ifndef GPGME_GLIB_H_
#define GPGME_GLIB_H_

#include <gio/gio.h>
#include "gpgme-glib/gpgme-glib-enumtypes.h"

G_BEGIN_DECLS

#define G_GPG_ERROR (g_gpg_error_quark ())
GQuark g_gpg_error_quark (void);

#define G_GPG_TYPE_DATA (g_gpg_data_get_type ())
G_DECLARE_FINAL_TYPE (GGpgData, g_gpg_data, G_GPG, DATA, GObject)

#define G_GPG_TYPE_CTX (g_gpg_ctx_get_type ())
G_DECLARE_FINAL_TYPE (GGpgCtx, g_gpg_ctx, G_GPG, CTX, GObject)

#define G_GPG_TYPE_ENGINE_INFO (g_gpg_engine_info_get_type ())
G_DECLARE_FINAL_TYPE (GGpgEngineInfo, g_gpg_engine_info, G_GPG, ENGINE_INFO,
                      GObject)

#define G_GPG_TYPE_KEY_SIG (g_gpg_key_sig_get_type ())
G_DECLARE_FINAL_TYPE (GGpgKeySig, g_gpg_key_sig, G_GPG, KEY_SIG, GObject)

#define G_GPG_TYPE_USER_ID (g_gpg_user_id_get_type ())
G_DECLARE_FINAL_TYPE (GGpgUserId, g_gpg_user_id, G_GPG, USER_ID, GObject)

#define G_GPG_TYPE_SUBKEY (g_gpg_subkey_get_type ())
G_DECLARE_FINAL_TYPE (GGpgSubkey, g_gpg_subkey, G_GPG, SUBKEY, GObject)

#define G_GPG_TYPE_KEY (g_gpg_key_get_type ())
G_DECLARE_FINAL_TYPE (GGpgKey, g_gpg_key, G_GPG, KEY, GObject)

void g_gpg_check_version (const gchar *version);

GGpgData *g_gpg_data_new (void);
GGpgData *g_gpg_data_new_from_bytes (GBytes *bytes);
GGpgData *g_gpg_data_new_from_fd (gint fd, GError **error);
gssize g_gpg_data_read (GGpgData *data, gpointer buffer, gsize size);
gssize g_gpg_data_write (GGpgData *data, gconstpointer buffer, gsize size);
goffset g_gpg_data_seek (GGpgData *data, goffset offset, GSeekType whence);
GBytes *g_gpg_data_free_to_bytes (GGpgData *data);

GGpgCtx *g_gpg_ctx_new (GError **error);

typedef void (*GGpgProgressCallback) (gpointer user_data,
                                      const gchar *what,
                                      gint type,
                                      gint current,
                                      gint total);

void g_gpg_ctx_set_progress_callback (GGpgCtx *ctx,
                                      GGpgProgressCallback callback,
                                      gpointer user_data,
                                      GDestroyNotify destroy_data);

gboolean g_gpg_ctx_keylist_start (GGpgCtx *ctx, const gchar *pattern,
                                  gint secret_only, GError **error);
GGpgKey *g_gpg_ctx_keylist_next (GGpgCtx *ctx, GError **error);
gboolean g_gpg_ctx_keylist_end (GGpgCtx *ctx, GError **error);

void g_gpg_ctx_get_key (GGpgCtx *ctx, const gchar *fpr, gint secret,
                        GCancellable *cancellable,
                        GAsyncReadyCallback callback,
                        gpointer user_data);
GGpgKey *g_gpg_ctx_get_key_finish (GGpgCtx *ctx, GAsyncResult *result,
                                   GError **error);

void g_gpg_ctx_generate_key (GGpgCtx *ctx, const gchar *parms,
                             GGpgData *pubkey, GGpgData *seckey,
                             GCancellable *cancellable,
                             GAsyncReadyCallback callback,
                             gpointer user_data);
gboolean g_gpg_ctx_generate_key_finish (GGpgCtx *ctx, GAsyncResult *result,
                                        GError **error);

void g_gpg_ctx_delete (GGpgCtx *ctx,
                       GGpgKey *key,
                       gint allow_secret,
                       GCancellable *cancellable,
                       GAsyncReadyCallback callback,
                       gpointer user_data);
gboolean g_gpg_ctx_delete_finish (GGpgCtx *ctx, GAsyncResult *result,
                                  GError **error);

typedef gboolean (*GGpgEditCallback) (gpointer user_data,
                                GGpgStatusCode status,
                                const gchar *args, gint fd,
                                GError **error);

void g_gpg_ctx_edit (GGpgCtx *ctx,
                     GGpgKey *key,
                     GGpgEditCallback edit_callback,
                     gpointer edit_user_data,
                     GGpgData *out,
                     GCancellable *cancellable,
                     GAsyncReadyCallback callback,
                     gpointer user_data);
gboolean g_gpg_ctx_edit_finish (GGpgCtx *ctx, GAsyncResult *result,
                                GError **error);

void g_gpg_ctx_export (GGpgCtx *ctx,
                       GGpgKey *key,
                       GGpgExportMode mode,
                       GGpgData *keydata,
                       GCancellable *cancellable,
                       GAsyncReadyCallback callback,
                       gpointer user_data);
gboolean g_gpg_ctx_export_finish (GGpgCtx *ctx, GAsyncResult *result,
                                  GError **error);

void g_gpg_ctx_import (GGpgCtx *ctx,
                       GGpgData *keydata,
                       GCancellable *cancellable,
                       GAsyncReadyCallback callback,
                       gpointer user_data);
gboolean g_gpg_ctx_import_finish (GGpgCtx *ctx, GAsyncResult *result,
                                  GError **error);

GList *g_gpg_key_get_subkeys (GGpgKey *key);
GList *g_gpg_key_get_uids (GGpgKey *key);

GList *g_gpg_user_id_get_signatures (GGpgUserId *user_id);

G_END_DECLS

#endif  /* GPGME_GLIB_H_ */
