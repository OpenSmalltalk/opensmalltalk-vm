#ifndef SQ_OPENSSL_OVERLAY_H
#define SQ_OPENSSL_OVERLAY_H 1
/****************************************************************************
 *   PROJECT: SqueakSSL implementation for Linux/Unix
 *   FILE:    openssl_overlay.h
 *   CONTENT: Overlay OpenSSL for Linux/Unix
 *
 *   AUTHORS: Tobias Pape (topa)
 *               Hasso Plattner Institute, Potsdam, Germany
 *****************************************************************************
 *   When we dynamically link against OpenSSL, the bundles are not
 *   portable, as CentOS and friends use other SO_NAMEs than Debian and
 *   friends. Also, soft-fallback for later features such as host name
 *   verification is hard.
 *
 *   When we statically link, we might lack behind the OS, the binaries
 *   are bigger, and the legal situation is less clear.
 *
 *   So we now support not linking at all but rather lookup all necessary
 *   functions/symbols at runtime.
 *
 *   This can be disabled with SQSSL_OPENSSL_LINKED which effectively
 *   results in the dynamically-linked behavior. (This is preferable for
 *   platform builds, eg, debs and rpms)
 *****************************************************************************/
#include <stdbool.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/x509v3.h>

/*
 * List of all used OpenSSL functions in the following format:
 *
 * SQO_DECL___(RETURN_TYPE, NAME, ARGS...)
 *
 * For symbols that appeared first version XYZ (X >=1) use SQO_DECLXYZ,
 * for example:
 *
 * SQO_DECL102 (Available since OpenSSL 1.0.2)
 *     (NAME will have value NULL in OpenSSL < 1.0.2)
 *
 * SPECIAL CASE FOR OLD OPENSSL
 * For symbols with different types in 0.9.8 / 1.0.0 use:
 *
 * SQO_DECL098 (OpenSSL <= 0.9.8)
 *    (NAME will not be defined in > 0.9.8)
 * SQO_DECL100 (OpenSSL >= 1.0.0)
 *    (NAME will not be defined in < 1.0.0)
 *
 */
#define SQO_DECLARATIONS                                                \
  /**/                                                                  \
  SQO_DECL___(unsigned char *, ASN1_STRING_data, ASN1_STRING *x)        \
  SQO_DECL___(int, ASN1_STRING_length, const ASN1_STRING *x)            \
  SQO_DECL___(void, BIO_free_all, BIO *a)                               \
  SQO_DECL___(BIO *, BIO_new, BIO_METHOD *type)                         \
  SQO_DECL___(BIO_METHOD *, BIO_s_mem, void)                            \
  SQO_DECL___(size_t, BIO_ctrl_pending, BIO *bp)                        \
  SQO_DECL___(long, BIO_ctrl, BIO *bp, int cmd, long larg, void *parg)  \
  SQO_DECL___(int, BIO_write, BIO *b, const void *data, int len)        \
  SQO_DECL___(int, BIO_read, BIO *b, void *data, int len)               \
  SQO_DECL___(void, ERR_print_errors_fp, FILE *fp)                      \
  SQO_DECL___(void, SSL_CTX_free, SSL_CTX *)                            \
  SQO_DECL___(int, SSL_CTX_set_cipher_list, SSL_CTX *, const char *str) \
  SQO_DECL___(int, SSL_CTX_set_default_verify_paths, SSL_CTX *ctx)      \
  SQO_DECL___(long, SSL_CTX_ctrl, SSL_CTX *ctx, int cmd, long larg, void *parg) \
  SQO_DECL___(int, SSL_CTX_use_PrivateKey_file, SSL_CTX *ctx, const char *file, int type) \
  SQO_DECL___(int, SSL_CTX_use_certificate_file, SSL_CTX *ctx, const char *file, int type) \
  SQO_DECL___(int, SSL_accept, SSL *ssl)                                \
  SQO_DECL___(int, SSL_connect, SSL *ssl)                               \
  SQO_DECL___(void, SSL_free, SSL *ssl)                                 \
  SQO_DECL___(long, SSL_ctrl, SSL *ssl, int cmd, long larg, void *parg) \
  SQO_DECL___(int, SSL_get_error, const SSL *s, int ret_code)           \
  SQO_DECL___(X509 *, SSL_get_peer_certificate, const SSL *s)           \
  SQO_DECL___(long, SSL_get_verify_result, const SSL *ssl)              \
  SQO_DECL___(int, SSL_library_init, void)                              \
  SQO_DECL___(void, SSL_load_error_strings, void)                       \
  SQO_DECL___(SSL *, SSL_new, SSL_CTX *ctx)                             \
  SQO_DECL___(int, SSL_read, SSL *ssl, void *buf, int num)              \
  SQO_DECL___(void, SSL_set_accept_state, SSL *s)                       \
  SQO_DECL___(void, SSL_set_bio, SSL *s, BIO *rbio, BIO *wbio)          \
  SQO_DECL___(void, SSL_set_connect_state, SSL *s)                      \
  SQO_DECL___(int, SSL_write, SSL *ssl, const void *buf, int num)       \
  SQO_DECL___(int, X509_NAME_get_text_by_NID, X509_NAME *name, int nid, char *buf, int len) \
  SQO_DECL___(X509_NAME *, X509_get_subject_name, X509 *a)              \
  SQO_DECL___(void *, X509_get_ext_d2i, X509 *x, int nid, int *crit, int *idx) \
  SQO_DECL___(void, X509_free, X509 *ssl)                               \
                                                                        \
  SQO_DECL102(int, X509_check_ip_asc, X509 *x, const char *ipasc, unsigned int flags) \
  SQO_DECL102(int, X509_check_host, X509 *x, const char *chk, size_t chklen, unsigned int flags, char **peername) \
                                                                        \
  SQO_DECL100(_STACK *, sk_new_null, void)                              \
  SQO_DECL100(int, sk_push, _STACK *st, void *data)                     \
  SQO_DECL100(void, sk_free, _STACK *st)                                \
  SQO_DECL100(void *, sk_value, const _STACK *st, int i)                \
  SQO_DECL100(int, sk_num, const _STACK *st)                            \
  SQO_DECL100(void, sk_pop_free, _STACK *st, void (*func) (void *))     \
  SQO_DECL100(const SSL_METHOD *, SSLv23_method, void)                  \
  SQO_DECL100(SSL_CTX *, SSL_CTX_new, const SSL_METHOD *a)              \
                                                                        \
  SQO_DECL098(STACK *, sk_new_null, void)                               \
  SQO_DECL098(int, sk_push, STACK *st, char *data)                      \
  SQO_DECL098(void, sk_free, STACK *st)                                 \
  SQO_DECL098(char *, sk_value, STACK *st, int i)                       \
  SQO_DECL098(int, sk_num, STACK *st)                                   \
  SQO_DECL098(void, sk_pop_free, STACK *st, void (*func) (void *))      \
  SQO_DECL098(SSL_METHOD *, SSLv23_method, void)                        \
  SQO_DECL098(SSL_CTX *, SSL_CTX_new, SSL_METHOD *a)                    \
  /* backstop */

/*
 * List of re-defined OpenSSL macros
 *
 * This is necessary to "redirect" the usage of un-prefixed symbols to
 * sqo_-prefixed ones.
 */
#define sqo_BIO_set_close(b,c) (int)sqo_BIO_ctrl(b,BIO_CTRL_SET_CLOSE,(c),NULL)
#define sqo_SSL_set_tlsext_host_name(s,name) sqo_SSL_ctrl(s,SSL_CTRL_SET_TLSEXT_HOSTNAME,TLSEXT_NAMETYPE_host_name,(char *)name)
#define sqo_SSL_CTX_set_options(ctx,op) sqo_SSL_CTX_ctrl((ctx),SSL_CTRL_OPTIONS,(op),NULL)
#define sqo_SKM_sk_num(type, st) sqo_sk_num(CHECKED_STACK_OF(type, st))
#define sqo_SKM_sk_value(type, st,i) ((type *)sqo_sk_value(CHECKED_STACK_OF(type, st), i))
#define sqo_SKM_sk_free(type, st) sqo_sk_free(CHECKED_STACK_OF(type, st))
#define sqo_SKM_sk_pop_free(type, st, free_func) sqo_sk_pop_free(CHECKED_STACK_OF(type, st), CHECKED_SK_FREE_FUNC(type, free_func))
#define sqo_sk_GENERAL_NAME_num(st) sqo_SKM_sk_num(GENERAL_NAME, (st))
#define sqo_sk_GENERAL_NAME_value(st, i) sqo_SKM_sk_value(GENERAL_NAME, (st), (i))
#define sqo_sk_GENERAL_NAME_free(st) sqo_SKM_sk_free(GENERAL_NAME, (st))
#define sqo_sk_GENERAL_NAME_pop_free(st, free_func) sqo_SKM_sk_pop_free(GENERAL_NAME, (st), (free_func))

/*
 * List of optional OpenSSL constants
 *
 * This is necessary to allow usage of those constants with newer
 * dynamically loaded libraries, but whilst using older versions at
 * compile time.
 */
#if defined(X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS)
#define sqo_X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS
#else
#define sqo_X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS 0x10
#endif


/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
/***********************************************************************/

#if OPENSSL_VERSION_NUMBER >= 0x10000000L
#define SQO_DECL098 SQO_DECL_NO
#define SQO_DECL100 SQO_DECL___
#else
#define SQO_DECL098 SQO_DECL___
#define SQO_DECL100 SQO_DECL_NO
#endif

#if OPENSSL_VERSION_NUMBER >= 0x10002000L
#define SQO_DECL102 SQO_DECL___
#else
#define SQO_DECL102 SQO_DECL_IF
#endif

/*
 *  WARNING: Here be dragons!
 *
 *  Only change things beyond this line if you know exactly what
 *  will happen.
 *
 *  The following stanzas will do this:
 *
 *  * When compiling non-linked (dynamically loaded):
 *    * find dl-header, define helper macros for symbol lookup
 *    * define static handles for dynamic libraries
 *    * helper function that does actual lookup
 *    * helper function that unloads libraries on SqueakSSL unload
 *
 *  * Declare all necessary OpenSSL symbols, prefixed with sqo_
 *
 *  * "loadLibrary" function to be called once by SqueakSSL:
 *    * When compiling linked (not dynamically loaded):
 *      * alias all necessary OpenSSL symbols to sqo_ prefixed
 *    * otherwise, when compiling non-linked (dynamically loaded):
 *      * lookup every symbol and assign to sqo_ prefixed name
 *
 *  That's it, essentially.
 */
#if !defined(SQSSL_OPENSSL_LINKED)

#include <dlfcn.h>

#if !defined(SQO_DL_FLAGS)
#  if !defined(__OpenBSD__)
#    define SQO_DL_FLAGS RTLD_NOW | RTLD_GLOBAL | RTLD_NODELETE
#  else
#    define SQO_DL_FLAGS RTLD_NOW | RTLD_GLOBAL
#  endif
#endif /* !defined(SQO_DL_FLAGS) */

/*
 * Handles for the dlopen'ed dynamic libraries
 *
 */
static void* dlhandle_self = NULL;
static void* dlhandle_crypto = NULL;
static void* dlhandle_ssl = NULL;


/*
 * Helpers to make sure the loaded library handles are closed when
 * this module is unloaded (w/ care for at lease GCC and llvm/clang)
 */
#ifndef __has_attribute
#define __has_attribute(x) 0
#endif

#if __has_attribute(destructor) \
  || defined(__GNUC__)
#define SQO_DESTRUCTOR __attribute__((destructor))
#else
#define SQO_DESTRUCTOR /**/
#endif

void SQO_DESTRUCTOR fini(void)
{
  if (dlhandle_self) { dlclose(dlhandle_self); }
  if (dlhandle_crypto) { dlclose(dlhandle_crypto); }
  if (dlhandle_ssl) { dlclose(dlhandle_ssl);}
}

/*
 * Macro that lookups a symbol in a library and does immediately
 * return the address when found.
 *
 * (with optional debug output)
 */
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

/*
 * Macro that lookups a symbol in a _named_ library.
 * Loads library if not yet done.
 * Uses SQO_HAS_FOUND_SYM, therefore immediately returns when found.
 */
#define SQO_FIND_SYM(sym, name, where, dlname)                  \
  do {                                                          \
    if (!dlhandle_ ## where) {                                  \
      dlhandle_ ## where = dlopen(dlname, SQO_DL_FLAGS);        \
    }                                                           \
    if (dlhandle_ ## where) {                                   \
      SQO_HAS_FOUND_SYM(sym, name, dlhandle_ ## where);         \
    }                                                           \
  } while (0)


/*
 * Find symbol named "name" in one of the following namespaces
 * (in order):
 *
 * 1. Already loaded dynamic objects
 * 2. The running executable itself
 * 3. libssl.so (as in OpenSSL)
 * 4. libcrypto.so (as in OpenSSL)
 */
static inline void* _sqo_find(const char* name)
{
  void* sym = NULL;
  SQO_HAS_FOUND_SYM(sym, name, RTLD_DEFAULT);
  SQO_FIND_SYM(sym, name, self, NULL);
  SQO_FIND_SYM(sym, name, ssl, "libssl.so");
  SQO_FIND_SYM(sym, name, crypto, "libcrypto.so");
  return sym;
}

#endif /* !defined(SQSSL_OPENSSL_LINKED) */


/*
 *
 *
 *
 *      DECLARE ALL NECESSARY SYMBOLS AS FOUND IN SQO_DECLARATIONS
 *
 *
 *
 *
 */
#define SQO_DECL___(ret, name, ...) ret (*sqo_ ## name)(__VA_ARGS__);
#define SQO_DECL_IF(ret, name, ...) ret (*sqo_ ## name)(__VA_ARGS__);
#define SQO_DECL_NO(ret, name, ...) /**/

/* THIS LINE IS VITAL */
SQO_DECLARATIONS

#undef SQO_DECL___
#undef SQO_DECL_NO
#undef SQO_DECL_IF

/*
 * Function that makes sure that all sqo_ prefixed OpenSSL names are
 * actually available.
 *
 * Returns
 *      true    when all required symbols could be loaded/are linked
 *      false   when at least one required symbol could not be loaded
 *
 * Call this exactly once!
 */
bool loadLibrary(void)
{

/*
 *
 *
 *
 *      ASSING ALL NECESSARY SYMBOLS AS FOUND IN SQO_DECLARATIONS
 *
 *
 *
 *
 */
#if defined(SQSSL_OPENSSL_LINKED)
#  define SQO_DECL___(ret, name, ...) sqo_ ## name = &name;
#  define SQO_DECL_NO(ret, name, ...) /**/
#  define SQO_DECL_IF(ret, name, ...) sqo_ ## name = NULL;
#else /* defined(SQSSL_OPENSSL_LINKED) */
#  define SQO_DECL___(ret, name, ...)                                   \
    if (NULL ==                                                         \
        (sqo_ ## name = (ret (*)(__VA_ARGS__)) _sqo_find(#name))) {     \
      return false;                                                     \
    }
#  define SQO_DECL_IF(ret, name, ...) \
    sqo_ ## name =(ret (*)(__VA_ARGS__)) _sqo_find(#name);
#  define SQO_DECL_NO(ret, name, ...) /**/
#endif  /* defined(SQSSL_OPENSSL_LINKED) */

/* THIS LINE IS VITAL */
  SQO_DECLARATIONS


#undef SQO_DECL___
#undef SQO_DECL_NO
#undef SQO_DECL_IF

    return true;
}

#undef SQO_DECLARATIONS
/* !defined(SQ_OPENSSL_OVERLAY_H) */
#endif
/* EOF */
