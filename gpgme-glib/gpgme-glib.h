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

#define G_GPG_TYPE_RECIPIENT (g_gpg_recipient_get_type ())
G_DECLARE_FINAL_TYPE (GGpgRecipient, g_gpg_recipient, G_GPG, RECIPIENT,
                      GObject)

#define G_GPG_TYPE_DECRYPT_RESULT (g_gpg_decrypt_result_get_type ())
G_DECLARE_FINAL_TYPE (GGpgDecryptResult, g_gpg_decrypt_result,
                      G_GPG, DECRYPT_RESULT, GObject)

#define G_GPG_TYPE_SIGNATURE_NOTATION (g_gpg_signature_notation_get_type ())
G_DECLARE_FINAL_TYPE (GGpgSignatureNotation, g_gpg_signature_notation,
                      G_GPG, SIGNATURE_NOTATION, GObject)

#define G_GPG_TYPE_SIGNATURE (g_gpg_signature_get_type ())
G_DECLARE_FINAL_TYPE (GGpgSignature, g_gpg_signature,
                      G_GPG, SIGNATURE, GObject)

#define G_GPG_TYPE_VERIFY_RESULT (g_gpg_verify_result_get_type ())
G_DECLARE_FINAL_TYPE (GGpgVerifyResult, g_gpg_verify_result,
                      G_GPG, VERIFY_RESULT, GObject)

#define G_GPG_TYPE_NEW_SIGNATURE (g_gpg_new_signature_get_type ())
G_DECLARE_FINAL_TYPE (GGpgNewSignature, g_gpg_new_signature,
                      G_GPG, NEW_SIGNATURE, GObject)

#define G_GPG_TYPE_INVALID_KEY (g_gpg_invalid_key_get_type ())
G_DECLARE_FINAL_TYPE (GGpgInvalidKey, g_gpg_invalid_key,
                      G_GPG, INVALID_KEY, GObject)

#define G_GPG_TYPE_SIGN_RESULT (g_gpg_sign_result_get_type ())
G_DECLARE_FINAL_TYPE (GGpgSignResult, g_gpg_sign_result,
                      G_GPG, SIGN_RESULT, GObject)

#define G_GPG_TYPE_ENCRYPT_RESULT (g_gpg_encrypt_result_get_type ())
G_DECLARE_FINAL_TYPE (GGpgEncryptResult, g_gpg_encrypt_result,
                      G_GPG, ENCRYPT_RESULT, GObject)

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
void g_gpg_ctx_add_signer (GGpgCtx *ctx, GGpgKey *key);
guint g_gpg_ctx_get_n_signers (GGpgCtx *ctx);
GGpgKey *g_gpg_ctx_get_signer (GGpgCtx *ctx, guint index);
void g_gpg_ctx_clear_signers (GGpgCtx *ctx);

gboolean g_gpg_ctx_keylist_start (GGpgCtx *ctx, const gchar *pattern,
                                  gboolean secret_only, GError **error);
GGpgKey *g_gpg_ctx_keylist_next (GGpgCtx *ctx, GError **error);
gboolean g_gpg_ctx_keylist_end (GGpgCtx *ctx, GError **error);

void g_gpg_ctx_get_key (GGpgCtx *ctx, const gchar *fpr,
                        GGpgGetKeyFlags flags,
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
                       GGpgDeleteFlags flags,
                       GCancellable *cancellable,
                       GAsyncReadyCallback callback,
                       gpointer user_data);
gboolean g_gpg_ctx_delete_finish (GGpgCtx *ctx, GAsyncResult *result,
                                  GError **error);

void g_gpg_ctx_change_password (GGpgCtx *ctx,
                                GGpgKey *key,
                                GGpgChangePasswordFlags flags,
                                GCancellable *cancellable,
                                GAsyncReadyCallback callback,
                                gpointer user_data);
gboolean g_gpg_ctx_change_password_finish (GGpgCtx *ctx, GAsyncResult *result,
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

void g_gpg_ctx_decrypt (GGpgCtx *ctx,
                        GGpgData *cipher,
                        GGpgData *plain,
                        GCancellable *cancellable,
                        GAsyncReadyCallback callback,
                        gpointer user_data);
gboolean g_gpg_ctx_decrypt_finish (GGpgCtx *ctx, GAsyncResult *result,
                                   GError **error);
GGpgDecryptResult *g_gpg_ctx_decrypt_result (GGpgCtx *ctx);
GList *g_gpg_decrypt_result_get_recipients (GGpgDecryptResult *decrypt_result);

void g_gpg_ctx_verify (GGpgCtx *ctx, GGpgData *sig, GGpgData *signed_text,
                       GGpgData *plain,
                       GCancellable *cancellable,
                       GAsyncReadyCallback callback,
                       gpointer user_data);
gboolean g_gpg_ctx_verify_finish (GGpgCtx *ctx, GAsyncResult *result,
                                  GError **error);
GGpgVerifyResult *g_gpg_ctx_verify_result (GGpgCtx *ctx);

GList *g_gpg_verify_result_get_signatures (GGpgVerifyResult *verify_result);
GList *g_gpg_signature_get_notations (GGpgSignature *signature);

void g_gpg_ctx_decrypt_verify (GGpgCtx *ctx, GGpgData *cipher, GGpgData *plain,
                               GCancellable *cancellable,
                               GAsyncReadyCallback callback,
                               gpointer user_data);
gboolean g_gpg_ctx_decrypt_verify_finish (GGpgCtx *ctx, GAsyncResult *result,
                                          GError **error);

void g_gpg_ctx_sign (GGpgCtx *ctx, GGpgData *plain, GGpgData *sig,
                     GGpgSignMode mode,
                     GCancellable *cancellable,
                     GAsyncReadyCallback callback,
                     gpointer user_data);
gboolean g_gpg_ctx_sign_finish (GGpgCtx *ctx, GAsyncResult *result,
                                GError **error);
GGpgSignResult *g_gpg_ctx_sign_result (GGpgCtx *ctx);
GList *g_gpg_sign_result_get_signatures (GGpgSignResult *sign_result);
GList *g_gpg_sign_result_get_invalid_signers (GGpgSignResult *sign_result);

void g_gpg_ctx_encrypt (GGpgCtx *ctx, GGpgKey **recipients,
                        GGpgData *plain, GGpgData *cipher,
                        GGpgEncryptFlags flags,
                        GCancellable *cancellable,
                        GAsyncReadyCallback callback,
                        gpointer user_data);
gboolean g_gpg_ctx_encrypt_finish (GGpgCtx *ctx, GAsyncResult *result,
                                   GError **error);
GGpgEncryptResult *g_gpg_ctx_encrypt_result (GGpgCtx *ctx);
GList *g_gpg_encrypt_result_get_invalid_recipients (GGpgEncryptResult *encrypt_result);

GList *g_gpg_key_get_subkeys (GGpgKey *key);
GList *g_gpg_key_get_uids (GGpgKey *key);

GList *g_gpg_user_id_get_signatures (GGpgUserId *user_id);

G_END_DECLS

#endif  /* GPGME_GLIB_H_ */
