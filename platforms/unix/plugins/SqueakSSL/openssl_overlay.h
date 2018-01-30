#ifndef SQ_OPENSSL_OVERLAY_H
#define SQ_OPENSSL_OVERLAY_H 1

#include <stdbool.h>
#include <dlfcn.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/x509v3.h>


static void* dlhandle_self = NULL;
static void* dlhandle_crypto = NULL;
static void* dlhandle_ssl = NULL;

#ifndef __has_attribute
#define __has_attribute(x) 0
#endif

#if __has_attribute(constructor) \
  || defined(__GNUC__)
#define SQO_CONSTRUCTOR __attribute__((constructor))
#else
#define SQO_CONSTRUCTOR /**/
#endif

void SQO_CONSTRUCTOR fini(void)
{
  if (dlhandle_self) { dlclose(dlhandle_self); }
  if (dlhandle_crypto) { dlclose(dlhandle_crypto); }
  if (dlhandle_ssl) { dlclose(dlhandle_ssl);}
}

#if (defined(DEBUG) || defined(DEBUGVM)) && !defined(NDEBUG)
#define SQO_HAS_FOUND_SYM(s,n,h)                                \
  do {                                                          \
    s = dlsym(h, n);                                            \
    if (s) {                                                    \
      fprintf(stderr, "Found symbol %s in " #h "\n", n);        \
      return s;                                                 \
    }                                                           \
  } while (0)
#else
#define SQO_HAS_FOUND_SYM(s,n,h)                \
  do {                                          \
    if ((s = dlsym(h, n))) {                    \
      return s;                                 \
    }                                           \
  } while (0)
#endif

#if !defined(SQO_DL_FLAGS)
#define SQO_DL_FLAGS RTLD_NOW | RTLD_GLOBAL | RTLD_NODELETE
#endif

#define SQO_FIND_SYM(sym, name, where, dlname)                  \
  do {                                                          \
    if (!dlhandle_ ## where) {                                  \
      dlhandle_ ## where = dlopen(dlname, SQO_DL_FLAGS);        \
      if (!dlhandle_ ## where) {                                \
        fprintf(stderr, "cannot load from " #dlname "\n"); \
        abort();                                                \
      }                                                         \
    }                                                           \
    if (dlhandle_ ## where) {                                   \
      SQO_HAS_FOUND_SYM(sym, name, dlhandle_ ## where);         \
    }                                                           \
  } while (0)
  

static inline void* _sqo_find(const char* name)
{
  void* sym = NULL;
  SQO_HAS_FOUND_SYM(sym, name, RTLD_DEFAULT);
  SQO_FIND_SYM(sym, name, self, NULL); 
  SQO_FIND_SYM(sym, name, ssl, "libssl.so"); 
  SQO_FIND_SYM(sym, name, crypto, "libcrypto.so");
  return sym;
}


unsigned char *(*sqo_ASN1_STRING_data)(ASN1_STRING *x);
int (*sqo_ASN1_STRING_length)(const ASN1_STRING *x);
void (*sqo_BIO_free_all)(BIO *a);
BIO *(*sqo_BIO_new)(BIO_METHOD *type);
BIO_METHOD *(*sqo_BIO_s_mem)(void);
long (*sqo_BIO_ctrl)(BIO *bp, int cmd, long larg, void *parg);
size_t (*sqo_BIO_ctrl_pending)(BIO *bp);
int (*sqo_BIO_write)(BIO *b, const void *data, int len);
int (*sqo_BIO_read)(BIO *b, void *data, int len);
void (*sqo_ERR_print_errors_fp)(FILE *fp);
void (*sqo_SSL_CTX_free)(SSL_CTX *);

#if OPENSSL_VERSION_NUMBER >= 0x10000000L
const SSL_METHOD *(*sqo_SSLv23_method)(void);
SSL_CTX *(*sqo_SSL_CTX_new)(const SSL_METHOD *a);
#else
SSL_METHOD *(*sqo_SSLv23_method)(void);
SSL_CTX *(*sqo_SSL_CTX_new)(SSL_METHOD *a);
#endif

int (*sqo_SSL_CTX_set_cipher_list)(SSL_CTX *, const char *str);
int (*sqo_SSL_CTX_set_default_verify_paths)(SSL_CTX *ctx);
long (*sqo_SSL_CTX_ctrl)(SSL_CTX *ctx, int cmd, long larg, void *parg);
int (*sqo_SSL_CTX_use_PrivateKey_file)(SSL_CTX *ctx, const char *file, int type);
int (*sqo_SSL_CTX_use_certificate_file)(SSL_CTX *ctx, const char *file, int type);
int (*sqo_SSL_accept)(SSL *ssl);
int (*sqo_SSL_connect)(SSL *ssl);
void (*sqo_SSL_free)(SSL *ssl);
long (*sqo_SSL_ctrl)(SSL *ssl, int cmd, long larg, void *parg);
int (*sqo_SSL_get_error)(const SSL *s, int ret_code);
X509 *(*sqo_SSL_get_peer_certificate)(const SSL *s);
long (*sqo_SSL_get_verify_result)(const SSL *ssl);
int (*sqo_SSL_library_init)(void);
void (*sqo_SSL_load_error_strings)(void);
SSL *(*sqo_SSL_new)(SSL_CTX *ctx);
int (*sqo_SSL_read)(SSL *ssl, void *buf, int num);
void (*sqo_SSL_set_accept_state)(SSL *s);
void (*sqo_SSL_set_bio)(SSL *s, BIO *rbio, BIO *wbio);
void (*sqo_SSL_set_connect_state)(SSL *s);
int (*sqo_SSL_write)(SSL *ssl, const void *buf, int num);
int (*sqo_X509_NAME_get_text_by_NID)(X509_NAME *name, int nid, char *buf, int len);
X509_NAME *(*sqo_X509_get_subject_name)(X509 *a);
void *(*sqo_X509_get_ext_d2i)(X509 *x, int nid, int *crit, int *idx);
void (*sqo_X509_free)(X509 *ssl);

// OPENSSL_VERSION_NUMBER >= 0x10002000L
int (*sqo_X509_check_ip_asc)(X509 *x, const char *ipasc, unsigned int flags);
int (*sqo_X509_check_host)(X509 *x, const char *chk, size_t chklen, unsigned int flags, char **peername);

#if OPENSSL_VERSION_NUMBER >= 0x10000000L
_STACK *(*sqo_sk_new_null)(void);
int (*sqo_sk_push)(_STACK *st, void *data);
void (*sqo_sk_free)(_STACK *st);
void *(*sqo_sk_value)(const _STACK *st, int i);
int (*sqo_sk_num)(const _STACK *st);
void (*sqo_sk_pop_free)(_STACK *st, void (*func) (void *));
#else
STACK *(*sqo_sk_new_null)(void);
int (*sqo_sk_push)(STACK *st, char *data);
void (*sqo_sk_free)(STACK *st);
char *(*sqo_sk_value)(STACK *st, int i);
int (*sqo_sk_num)(STACK *st);
void (*sqo_sk_pop_free)(STACK *st, void (*func) (void *));
#endif // OPENSSL_VERSION_NUMBER >= 0x10000000L

#define sqo_BIO_set_close(b,c)                          \
  (int)sqo_BIO_ctrl(b,BIO_CTRL_SET_CLOSE,(c),NULL)

#define sqo_SSL_set_tlsext_host_name(s,name)                            \
  sqo_SSL_ctrl(s,SSL_CTRL_SET_TLSEXT_HOSTNAME,TLSEXT_NAMETYPE_host_name,(char *)name)

#define sqo_SSL_CTX_set_options(ctx,op)                 \
  sqo_SSL_CTX_ctrl((ctx),SSL_CTRL_OPTIONS,(op),NULL)

#define sqo_SKM_sk_num(type, st)                \
  sqo_sk_num(CHECKED_STACK_OF(type, st))
#define sqo_SKM_sk_value(type, st,i)                    \
  ((type *)sqo_sk_value(CHECKED_STACK_OF(type, st), i))
#define sqo_SKM_sk_free(type, st)               \
  sqo_sk_free(CHECKED_STACK_OF(type, st))
#define sqo_SKM_sk_pop_free(type, st, free_func)                        \
  sqo_sk_pop_free(CHECKED_STACK_OF(type, st), CHECKED_SK_FREE_FUNC(type, free_func))
#define sqo_sk_GENERAL_NAME_num(st)             \
  sqo_SKM_sk_num(GENERAL_NAME, (st))
#define sqo_sk_GENERAL_NAME_value(st, i)        \
  sqo_SKM_sk_value(GENERAL_NAME, (st), (i))
#define sqo_sk_GENERAL_NAME_free(st)            \
  sqo_SKM_sk_free(GENERAL_NAME, (st))
#define sqo_sk_GENERAL_NAME_pop_free(st, free_func)     \
  sqo_SKM_sk_pop_free(GENERAL_NAME, (st), (free_func))

#if !defined(X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS)
#define X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS 0x10
#endif

bool loadLibrary(void)
{
#if defined(SQSSL_FORCE_LINK_OPENSSL)
  sqo_ASN1_STRING_data = &ASN1_STRING_data;
  sqo_ASN1_STRING_length = &ASN1_STRING_length;
  sqo_BIO_free_all = &BIO_free_all;
  sqo_BIO_new = &BIO_new;
  sqo_BIO_s_mem = &BIO_s_mem;
  sqo_BIO_ctrl = &BIO_ctrl;
  sqo_BIO_ctrl_pending = &BIO_ctrl_pending;
  sqo_BIO_write = &BIO_write;
  sqo_BIO_read = &BIO_read;
  sqo_ERR_print_errors_fp = &ERR_print_errors_fp;
  sqo_SSL_CTX_free = &SSL_CTX_free;
  sqo_SSLv23_method = &SSLv23_method;
  sqo_SSL_CTX_new = &SSL_CTX_new;
  sqo_SSL_CTX_set_cipher_list = &SSL_CTX_set_cipher_list;
  sqo_SSL_CTX_set_default_verify_paths = &SSL_CTX_set_default_verify_paths;
  sqo_SSL_CTX_ctrl = &SSL_CTX_ctrl;
  sqo_SSL_CTX_use_PrivateKey_file = &SSL_CTX_use_PrivateKey_file;
  sqo_SSL_CTX_use_certificate_file = &SSL_CTX_use_certificate_file;
  sqo_SSL_accept = &SSL_accept;
  sqo_SSL_connect = &SSL_connect;
  sqo_SSL_free = &SSL_free;
  sqo_SSL_ctrl = &SSL_ctrl;
  sqo_SSL_get_error = &SSL_get_error;
  sqo_SSL_get_peer_certificate = &SSL_get_peer_certificate;
  sqo_SSL_get_verify_result = &SSL_get_verify_result;
  sqo_SSL_library_init = &SSL_library_init;
  sqo_SSL_load_error_strings = &SSL_load_error_strings;
  sqo_SSL_new = &SSL_new;
  sqo_SSL_read = &SSL_read;
  sqo_SSL_set_accept_state = &SSL_set_accept_state;
  sqo_SSL_set_bio = &SSL_set_bio;
  sqo_SSL_set_connect_state = &SSL_set_connect_state;
  sqo_SSL_write = &SSL_write;
  sqo_X509_NAME_get_text_by_NID = &X509_NAME_get_text_by_NID;
  sqo_X509_get_subject_name = &X509_get_subject_name;
  sqo_X509_get_ext_d2i = &X509_get_ext_d2i;
  sqo_X509_free = &X509_free;
#if OPENSSL_VERSION_NUMBER >= 0x10002000L
  sqo_X509_check_ip_asc = &X509_check_ip_asc;
  sqo_X509_check_host = &X509_check_host;    
#else
  sqo_X509_check_ip_asc = NULL;
  sqo_X509_check_host = NULL;
#endif

  sqo_sk_new_null = &sk_new_null;
  sqo_sk_push = &sk_push;
  sqo_sk_free = &sk_free;
  sqo_sk_value = &sk_value;
  sqo_sk_num = &sk_num;
  sqo_sk_pop_free = &sk_pop_free;

  return true;
#else 

#define _C(X) if ((X) == NULL) return false
  _C(sqo_ASN1_STRING_data = (unsigned char *(*)(ASN1_STRING *x)) _sqo_find("ASN1_STRING_data"));
  _C(sqo_ASN1_STRING_length = (int (*)(const ASN1_STRING *x)) _sqo_find("ASN1_STRING_length"));
  _C(sqo_BIO_free_all = (void (*)(BIO *a)) _sqo_find("BIO_free_all"));
  _C(sqo_BIO_new = (BIO *(*)(BIO_METHOD *type)) _sqo_find("BIO_new"));
  _C(sqo_BIO_s_mem = (BIO_METHOD *(*)(void)) _sqo_find("BIO_s_mem"));
  _C(sqo_BIO_ctrl = (long (*)(BIO *bp, int cmd, long larg, void *parg)) _sqo_find("BIO_ctrl"));
  _C(sqo_BIO_ctrl_pending = (size_t (*)(BIO *)) _sqo_find("BIO_ctrl_pending"));
  _C(sqo_BIO_write = (int (*)(BIO *b, const void *data, int len)) _sqo_find("BIO_write"));
  _C(sqo_BIO_read = (int (*)(BIO *b, void *data, int len)) _sqo_find("BIO_read"));
  _C(sqo_ERR_print_errors_fp = (void (*)(FILE *fp)) _sqo_find("ERR_print_errors_fp"));
  _C(sqo_SSL_CTX_free = (void (*)(SSL_CTX *)) _sqo_find("SSL_CTX_free"));

#if OPENSSL_VERSION_NUMBER >= 0x10000000L
  _C(sqo_SSLv23_method = (const SSL_METHOD *(*)(void)) _sqo_find("SSLv23_method"));
  _C(sqo_SSL_CTX_new = (SSL_CTX *(*)(const SSL_METHOD *a)) _sqo_find("SSL_CTX_new"));
#else
  _C(sqo_SSLv23_method = (SSL_METHOD *(*)(void)) _sqo_find("SSLv23_method"));
  _C(sqo_SSL_CTX_new = (SSL_CTX *(*)(SSL_METHOD *a)) _sqo_find("SSL_CTX_new"));
#endif

  _C(sqo_SSL_CTX_set_cipher_list = (int (*)(SSL_CTX *, const char *str)) _sqo_find("SSL_CTX_set_cipher_list"));
  _C(sqo_SSL_CTX_set_default_verify_paths = (int (*)(SSL_CTX *ctx)) _sqo_find("SSL_CTX_set_default_verify_paths"));
  _C(sqo_SSL_CTX_ctrl = (long (*)(SSL_CTX *ctx, int cmd, long larg, void *parg)) _sqo_find("SSL_CTX_ctrl"));
  _C(sqo_SSL_CTX_use_PrivateKey_file = (int (*)(SSL_CTX *ctx, const char *file, int type)) _sqo_find("SSL_CTX_use_PrivateKey_file"));
  _C(sqo_SSL_CTX_use_certificate_file = (int (*)(SSL_CTX *ctx, const char *file, int type)) _sqo_find("SSL_CTX_use_certificate_file"));
  _C(sqo_SSL_accept = (int (*)(SSL *ssl)) _sqo_find("SSL_accept"));
  _C(sqo_SSL_connect = (int (*)(SSL *ssl)) _sqo_find("SSL_connect"));
  _C(sqo_SSL_free = (void (*)(SSL *ssl)) _sqo_find("SSL_free"));
  _C(sqo_SSL_ctrl = (long (*)(SSL *ssl, int cmd, long larg, void *parg)) _sqo_find("SSL_ctrl"));
  _C(sqo_SSL_get_error = (int (*)(const SSL *s, int ret_code)) _sqo_find("SSL_get_error"));
  _C(sqo_SSL_get_peer_certificate = (X509 *(*)(const SSL *s)) _sqo_find("SSL_get_peer_certificate"));
  _C(sqo_SSL_get_verify_result = (long (*)(const SSL *ssl)) _sqo_find("SSL_get_verify_result"));
  _C(sqo_SSL_library_init = (int (*)(void)) _sqo_find("SSL_library_init"));
  _C(sqo_SSL_load_error_strings = (void (*)(void)) _sqo_find("SSL_load_error_strings"));
  _C(sqo_SSL_new = (SSL *(*)(SSL_CTX *ctx)) _sqo_find("SSL_new"));
  _C(sqo_SSL_read = (int (*)(SSL *ssl, void *buf, int num)) _sqo_find("SSL_read"));
  _C(sqo_SSL_set_accept_state = (void (*)(SSL *s)) _sqo_find("SSL_set_accept_state"));
  _C(sqo_SSL_set_bio = (void (*)(SSL *s, BIO *rbio, BIO *wbio)) _sqo_find("SSL_set_bio"));
  _C(sqo_SSL_set_connect_state = (void (*)(SSL *s)) _sqo_find("SSL_set_connect_state"));
  _C(sqo_SSL_write = (int (*)(SSL *ssl, const void *buf, int num)) _sqo_find("SSL_write"));
  _C(sqo_X509_NAME_get_text_by_NID = (int (*)(X509_NAME *name, int nid, char *buf, int len)) _sqo_find("X509_NAME_get_text_by_NID"));
  _C(sqo_X509_get_subject_name = (X509_NAME *(*)(X509 *a)) _sqo_find("X509_get_subject_name"));
  _C(sqo_X509_get_ext_d2i = (void *(*)(X509 *x, int nid, int *crit, int *idx)) _sqo_find("X509_get_ext_d2i"));
  _C(sqo_X509_free = (void (*)(X509 *)) _sqo_find("X509_free"));
  sqo_X509_check_ip_asc = (int (*)(X509 *x, const char *ipasc, unsigned int flags)) _sqo_find("X509_check_ip_asc");
  sqo_X509_check_host = (int (*)(X509 *x, const char *chk, size_t chklen, unsigned int flags, char **peername)) _sqo_find("X509_check_host");

#if OPENSSL_VERSION_NUMBER >= 0x10000000L
  _C(sqo_sk_new_null = (_STACK *(*)(void)) _sqo_find("sk_new_null"));
  _C(sqo_sk_push = (int (*)(_STACK *st, void *data)) _sqo_find("sk_push"));
  _C(sqo_sk_free = (void (*)(_STACK *st)) _sqo_find("sk_free"));
  _C(sqo_sk_value = (void *(*)(const _STACK *st, int i)) _sqo_find("sk_value"));
  _C(sqo_sk_num = (int (*)(const _STACK *st)) _sqo_find("sk_num"));
  _C(sqo_sk_pop_free = (void (*)(_STACK *st, void (*func) (void *))) _sqo_find("sk_pop_free"));
#else
  _C(sqo_sk_new_null = (STACK *(*)(void)) _sqo_find("sk_new_null"));
  _C(sqo_sk_push = (int (*)(STACK *st, char *data)) _sqo_find("sk_push"));
  _C(sqo_sk_free = (void (*)(STACK *st)) _sqo_find("sk_free"));
  _C(sqo_sk_value = (char *(*)(STACK *st, int i)) _sqo_find("sk_value"));
  _C(sqo_sk_num = (int (*)(STACK *st)) _sqo_find("sk_num"));
  _C(sqo_sk_pop_free = (void (*)(STACK *st, void (*func) (void *))) _sqo_find("sk_pop_free"));
#endif // OPENSSL_VERSION_NUMBER >= 0x10000000L
  return true;
#endif
}

#endif
