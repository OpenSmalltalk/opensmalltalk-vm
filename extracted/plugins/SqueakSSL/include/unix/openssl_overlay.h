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
 * This overlay supports using OpenSSL from 0.9.8 to at least 1.1 at runtime.
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

#define SQSSL_OPENSSL_LINKED 1

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/x509v3.h>

#include "pharovm/debug.h"

#define NULL_FUNC ((void*(*)())NULL)

/**********************************************************************/
#if defined(SQSSL_OPENSSL_LINKED)
/**********************************************************************/
/*
 *      If we are working linked, we do not do any magic.
 *      In fact, we just re-wire the sqo_ names to their actual ones and
 *      unavailiable ones to NULL
 */
/**********************************************************************/
#define sqo_ASN1_STRING_length ASN1_STRING_length
#define sqo_BIO_free_all BIO_free_all
#define sqo_BIO_new BIO_new
#define sqo_BIO_s_mem BIO_s_mem
#define sqo_BIO_ctrl_pending BIO_ctrl_pending
#define sqo_BIO_set_close BIO_set_close
#define sqo_BIO_ctrl BIO_ctrl
#define sqo_BIO_write BIO_write
#define sqo_BIO_read BIO_read
#define sqo_ERR_print_errors_fp ERR_print_errors_fp
#define sqo_SSL_CTX_new SSL_CTX_new
#define sqo_SSL_CTX_free SSL_CTX_free
#define sqo_SSL_CTX_set_cipher_list SSL_CTX_set_cipher_list
#define sqo_SSL_CTX_set_default_verify_paths SSL_CTX_set_default_verify_paths
#define sqo_SSL_CTX_ctrl SSL_CTX_ctrl
#define sqo_SSL_CTX_use_PrivateKey_file SSL_CTX_use_PrivateKey_file
#define sqo_SSL_CTX_use_certificate_file SSL_CTX_use_certificate_file
#define sqo_SSL_accept SSL_accept
#define sqo_SSL_connect SSL_connect
#define sqo_SSL_free SSL_free
#define sqo_SSL_ctrl SSL_ctrl
#define sqo_SSL_get_error SSL_get_error
#define sqo_SSL_get_peer_certificate SSL_get_peer_certificate
#define sqo_SSL_get_verify_result SSL_get_verify_result
#define sqo_SSL_new SSL_new
#define sqo_SSL_read SSL_read
#define sqo_SSL_set_accept_state SSL_set_accept_state
#define sqo_SSL_set_bio SSL_set_bio
#define sqo_SSL_set_connect_state SSL_set_connect_state
#define sqo_SSL_set_tlsext_host_name SSL_set_tlsext_host_name
#define sqo_SSL_write SSL_write
#define sqo_X509_NAME_get_text_by_NID X509_NAME_get_text_by_NID
#define sqo_X509_get_subject_name X509_get_subject_name
#define sqo_X509_get_ext_d2i X509_get_ext_d2i
#define sqo_X509_free X509_free

#define sqo_SKM_sk_num SKM_sk_num
#define sqo_SKM_sk_value SKM_sk_value
#define sqo_SKM_sk_free SKM_sk_free
#define sqo_SKM_sk_pop_free SKM_sk_pop_free
#define sqo_sk_GENERAL_NAME_num sk_GENERAL_NAME_num
#define sqo_sk_GENERAL_NAME_value sk_GENERAL_NAME_value
#define sqo_sk_GENERAL_NAME_free sk_GENERAL_NAME_free
#define sqo_sk_GENERAL_NAME_pop_free sk_GENERAL_NAME_pop_free

#if OPENSSL_VERSION_NUMBER >= 0x10002000L
#define sqo_X509_check_ip_asc X509_check_ip_asc
#define sqo_X509_check_host X509_check_host
#elif  OPENSSL_VERSION_NUMBER < 0x10002000L
#define sqo_X509_check_ip_asc NULL_FUNC
#define sqo_X509_check_host NULL_FUNC
#endif

#if OPENSSL_VERSION_NUMBER >= 0x10100000L
#define sqo_SSL_CTX_set_options SSL_CTX_set_options
#define sqo_BIO_test_flags BIO_test_flags
#define sqo_OPENSSL_init_ssl OPENSSL_init_ssl
#define sqo_OPENSSL_sk_new_null OPENSSL_sk_new_null
#define sqo_OPENSSL_sk_push OPENSSL_sk_push
#define sqo_OPENSSL_sk_free OPENSSL_sk_free
#define sqo_OPENSSL_sk_value OPENSSL_sk_value
#define sqo_OPENSSL_sk_num OPENSSL_sk_num
#define sqo_OPENSSL_sk_pop_free OPENSSL_sk_pop_free
#define sqo_TLS_method TLS_method

#define sqo_ASN1_STRING_get0_data ASN1_STRING_get0_data
#define sqo_ASN1_STRING_data NULL_FUNC

#define sqo_sk_new_null NULL_FUNC
#define sqo_sk_push NULL_FUNC
#define sqo_sk_free NULL_FUNC
#define sqo_sk_value NULL_FUNC
#define sqo_sk_num NULL_FUNC
#define sqo_sk_pop_free NULL_FUNC
#define sqo_SSLv23_method NULL_FUNC

#define sqo_SSL_library_init NULL_FUNC
#define sqo_SSL_load_error_strings NULL_FUNC

#elif OPENSSL_VERSION_NUMBER < 0x10100000L

// do not #define sqo_SSL_CTX_set_options, is already
#define sqo_BIO_test_flags NULL_FUNC
#define sqo_OPENSSL_init_ssl NULL_FUNC
#define sqo_OPENSSL_sk_new_null NULL_FUNC
#define sqo_OPENSSL_sk_push NULL_FUNC
#define sqo_OPENSSL_sk_free NULL_FUNC
#define sqo_OPENSSL_sk_value NULL_FUNC
#define sqo_OPENSSL_sk_num NULL_FUNC
#define sqo_OPENSSL_sk_pop_free NULL_FUNC
#define sqo_TLS_method NULL_FUNC

#define sqo_ASN1_STRING_get0_data NULL_FUNC

#define sqo_ASN1_STRING_data ASN1_STRING_data

#define sqo_sk_new_null sk_new_null
#define sqo_sk_push sk_push
#define sqo_sk_free sk_free
#define sqo_sk_value sk_value
#define sqo_sk_num sk_num
#define sqo_sk_pop_free sk_pop_free
#define sqo_SSLv23_method SSLv23_method

#define sqo_SSL_library_init SSL_library_init
#define sqo_SSL_load_error_strings SSL_load_error_strings

#define sk_GENERAL_NAME_freefunc void(*)(void*)

#endif

/**********************************************************************/
/**********************************************************************/
/**********************************************************************/
/**********************************************************************/
/**********************************************************************/
/**********************************************************************/
#elif !defined(SQSSL_OPENSSL_LINKED)
/**********************************************************************/
/* Welcome to dynamic loading land, where the declarations are made up and the
 * pointers do not matter.
 */
/**********************************************************************/
/**********************************************************************/
/**********************************************************************/
/**********************************************************************/
/**********************************************************************/
/**********************************************************************/

#if OPENSSL_VERSION_NUMBER < 0x10100000L
#  define OPENSSL_STACK _STACK
#  define sk_GENERAL_NAME_freefunc void(*)(void*)
#  define OPENSSL_INIT_SETTINGS struct ossl_init_settings_st
OPENSSL_INIT_SETTINGS;

#if !defined(inline)
#  if defined(__GNUC__)
#    define ossl_inline __inline__
#  else
#    define ossl_inline /**/
#  endif
#else
#  define ossl_inline inline
#endif

# else
#  define _STACK OPENSSL_STACK
#  define STACK OPENSSL_STACK
#  define CHECKED_STACK_OF(type, st) (OPENSSL_STACK*)st
# endif

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
 * SQO_DECL110 (OpenSSL >= 1.1.0)
 *    (NAME will not be defined in < 1.1.0)
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
  SQO_DECL110(unsigned long, SSL_CTX_set_options, SSL_CTX *ctx, unsigned long op) \
  SQO_DECL110(int, BIO_test_flags, const BIO *b, int flags)             \
                                                                        \
  SQO_DECL110(const unsigned char *, ASN1_STRING_get0_data, const ASN1_STRING *x) \
                                                                        \
  SQO_DECL098(STACK *, sk_new_null, void)                               \
  SQO_DECL098(int, sk_push, STACK *st, char *data)                      \
  SQO_DECL098(void, sk_free, STACK *st)                                 \
  SQO_DECL098(char *, sk_value, STACK *st, int i)                       \
  SQO_DECL098(int, sk_num, STACK *st)                                   \
  SQO_DECL098(void, sk_pop_free, STACK *st, void (*func) (void *))      \
  SQO_DECL098(SSL_METHOD *, SSLv23_method, void)                        \
  SQO_DECL098(SSL_CTX *, SSL_CTX_new, SSL_METHOD *a)                    \
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
  SQO_DECL110(OPENSSL_STACK *, OPENSSL_sk_new_null, void)               \
  SQO_DECL110(int, OPENSSL_sk_push, OPENSSL_STACK *st, void *data)      \
  SQO_DECL110(void, OPENSSL_sk_free, OPENSSL_STACK *st)                 \
  SQO_DECL110(void *, OPENSSL_sk_value, const OPENSSL_STACK *st, int i) \
  SQO_DECL110(int, OPENSSL_sk_num, const OPENSSL_STACK *st)             \
  SQO_DECL110(void, OPENSSL_sk_pop_free, OPENSSL_STACK *st, void (*func) (void *)) \
  SQO_DECL110(SSL_METHOD *, TLS_method, void)                        \
                                                                        \
  SQO_DECL_IF(int, SSL_library_init, void)                              \
  SQO_DECL_IF(void, SSL_load_error_strings, void)                       \
  SQO_DECL110(int, OPENSSL_init_ssl, uint64_t opts, const OPENSSL_INIT_SETTINGS *settings) \
  /* backstop */


/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
/***********************************************************************/
/***********************************************************************/

#if OPENSSL_VERSION_NUMBER >= 0x10000000L
#define SQO_DECL098 SQO_DECL_NO
#define SQO_DECL100 SQO_DECL_IF
#else
#define SQO_DECL098 SQO_DECL___
#define SQO_DECL100 SQO_DECL_NO
#endif
#define SQO_DECL102 SQO_DECL_IF
#define SQO_DECL110 SQO_DECL_IF

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


/**********************************************************************/
#include <dlfcn.h>

#if !defined(SQO_DL_FLAGS)
#  if !defined(__OpenBSD__)
#    define SQO_DL_FLAGS (RTLD_NOW | RTLD_GLOBAL | RTLD_NODELETE)
#  else
#    define SQO_DL_FLAGS (RTLD_NOW | RTLD_GLOBAL)
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
#if !defined(__has_attribute)
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
#if defined(RTLD_NODELETE)
  if (!(SQO_DL_FLAGS & RTLD_NODELETE)) {
#endif
    if (dlhandle_self) { dlclose(dlhandle_self); }
    if (dlhandle_crypto) { dlclose(dlhandle_crypto); }
    if (dlhandle_ssl) { dlclose(dlhandle_ssl);}
#if defined(RTLD_NODELETE)
  }
#endif
}


/*
 * It may be the case that the libs we try to load are not exactly named as we like
 * So we
 *  * enumerate all plausible library paths
 *  * enumerate all libs there matching our name
 * * and report back the _names_ (NOT the full paths, we want dlopen to
 *      consider whaterver it has to)
 */

/*
 * The Paths part >>
 */
#if !defined(__MACH__)
/* This is to find possible library locations. */

#include <limits.h>
#include <link.h>
#include <glob.h>
#include <libgen.h>

#define _SQO_MAX_LIBS 32
static char* _sqo_dynamic_lib_dirs[_SQO_MAX_LIBS] = { NULL };
static size_t _sqo_dynamic_lib_dir_count = 0;

static bool _sqo_insert_dynamic_lib_dir(char* dir)
{
    bool found = false;
    for (size_t i  = 0; i < _sqo_dynamic_lib_dir_count; i ++) {
        if (strncmp(_sqo_dynamic_lib_dirs[i], dir, PATH_MAX) == 0) {
            found = true;
            break;
        }
    }
    if (!found) {
        _sqo_dynamic_lib_dirs[_sqo_dynamic_lib_dir_count++] = dir;
    }
    return found;
}



static int _sqo_find_lib_dirs(struct dl_phdr_info *info, size_t size, void *data)
{
    if (info->dlpi_name[0] != '\0') {
        char* myname = strdup(info->dlpi_name);
        char* dir = dirname(myname);
        if (dir[0] == '.' && dir[1] == '\0') {
            // was empty
            free(myname);
        } else {
            if (_sqo_insert_dynamic_lib_dir(dir)) {
                free(myname);
            }
        }
    }
    // Stop if we would go out of bounds.
    return !(_sqo_dynamic_lib_dir_count < _SQO_MAX_LIBS);
}

static void _sqo_dynamic_lib_dirs_reset(void)
{
    for (size_t i = 0; i < _sqo_dynamic_lib_dir_count; i++) {
        free(_sqo_dynamic_lib_dirs[i]);
        _sqo_dynamic_lib_dirs[i] = NULL;
    }
    _sqo_dynamic_lib_dir_count = 0;
}
#undef _SQO_MAX_LIBS
#endif // !__MACH__

/*      Find all paths that may contain dynamic libraries.
 *      Returns their count. libs may be NULL to get allocation size
 */
static size_t _sqo_lib_paths(size_t const n, char (*libs[n]))
{
    size_t num_libs = 0;
    (void)(n);

#define _SQO_ADD_LIB(L) do {                                          \
        logTrace("Library path %zu at %s\n", num_libs, L);        \
        if (libs != NULL) libs[num_libs] = strdup(L);                \
        num_libs++;                                                     \
    } while (0)
    /*
     *  Add all paths on the LD_LIBRARY_PATH
     */
    char* ld_library_path = getenv("LD_LIBRARY_PATH");
    if (ld_library_path != NULL) {
        if (libs == NULL) {
            /* just count */
            for (char* in_llp = ld_library_path; *in_llp != '\0'; in_llp++) {
                if (*in_llp == ':' || *in_llp == ';') {
                    num_libs++;
                }
            }
        } else {
            char* current = NULL, *tofree, *path;
            tofree = path = strdup(ld_library_path);
            while ((path != NULL) && ((current = strsep(&path, ":;")) != NULL)) {
                if (*current != '\0') {
                    _SQO_ADD_LIB(current);
                }
            }
            free(tofree);
        }
    }

#if !defined(__MACH__)
    if (_sqo_dynamic_lib_dirs[0] == NULL) {
        dl_iterate_phdr(&_sqo_find_lib_dirs, NULL);
    }
    for (size_t i = 0; i < _sqo_dynamic_lib_dir_count; i++) {
        _SQO_ADD_LIB(_sqo_dynamic_lib_dirs[i]);
    }
#endif //!defined(__MACH__)

    _SQO_ADD_LIB("/lib");
    _SQO_ADD_LIB("/usr/lib");
    _SQO_ADD_LIB("/usr/local/lib");
#if INTPTR_MAX == INT32_MAX
    _SQO_ADD_LIB("/lib32");
    _SQO_ADD_LIB("/usr/lib32");
    _SQO_ADD_LIB("/usr/local/lib32");
#elif INTPTR_MAX == INT64_MAX
    _SQO_ADD_LIB("/lib64");
    _SQO_ADD_LIB("/usr/lib64");
    _SQO_ADD_LIB("/usr/local/lib64");
#endif

    return num_libs;

#undef _SQO_ADD_LIB
}

/*
 * << The Paths part
 * The Names part >>
 */

#if defined(__linux__)
static int (*_sqo_strverscmp)(const void* a, const void* b) =
    (int (*)(const void* a, const void* b))strverscmp;
#else
#include <ctype.h>
static int _sqo_strverscmp(const char* a, const char* b)
{
    char* left = (char*) a;
    char* right = (char*) b;
    while (*left && *right) {
        /* strcmp */
        while (*left && *right &&
               !isdigit(*left) && !isdigit(*right) && *left == *right) {
            left++;
            right++;
        }
        if (!isdigit(*left) && !isdigit(*right)) {
            break;
        }
        long lnum = strtol(left, &left, 10);
        long rnum = strtol(right, &right, 10);
        if (lnum != rnum) {
            return lnum - rnum;
        }
    }
    return *left - *right;
}
#endif  /* defined(__linux__) */


static int _sqo_versioncmp(const void* a, const void* b)
{
    char* left = *((char**) a);
    char* right = *((char**) b);
    return _sqo_strverscmp(right, left);
}

/*
 *      enumerate all plausible paths and try the names found in numeric order.
 */
void* _sqo_dlopen_any(const char* name, int mode)
{
    size_t num_dirs = _sqo_lib_paths(0, NULL);
    char* dirs[num_dirs];
    _sqo_lib_paths(num_dirs, dirs);
    size_t name_len = strnlen(name, PATH_MAX);

#define _SQO_MAX_LIBNAMES 64
    char* libnames[_SQO_MAX_LIBNAMES] = {NULL};
    size_t libname_count = 0;

    for (
         size_t dir_idx = 0;
         dir_idx < num_dirs && libname_count < _SQO_MAX_LIBNAMES;
         dir_idx++
    ) {
        char* possible_files  = NULL;
        int written = asprintf(&possible_files, "%s/%s.*", dirs[dir_idx], name);
        if (written <= 0) {
            continue;
        }
        glob_t g = {0};
        if (0 == glob(possible_files, GLOB_NOSORT, NULL, &g)) {
            if (g.gl_pathc > 0) {
                for (size_t i = 0; i < g.gl_pathc; i++) {
                    char* fullfile = basename(g.gl_pathv[i]);
                    if (strnlen(fullfile, PATH_MAX) > name_len) {
                        libnames[libname_count] = strndup(fullfile, PATH_MAX);
                        libname_count++;
                    }
                }
            }
            globfree(&g);
        }
        free(possible_files);
    }
    qsort(libnames,  libname_count, sizeof(char*), _sqo_versioncmp);

    void* handle = NULL;
    for (size_t i = 0; handle == NULL && i < libname_count; i++) {
        logTrace("Trying %s for %s\n", libnames[i], name);
        handle = dlopen(libnames[i], mode);
    }
    for (size_t i = 0; i < libname_count; i++) { free(libnames[i]); }
    return handle;
}

/*
 *      Try to open the openssl lib named _name_ in mode.
 *
 *      Zeroth, if name is NULL, go straight to dlopen.
 *      First, try the version most closely matching our compiletime version.
 *      Second, try the non-versioned bare name.
 *      Third, enumerate all plausible paths and try the names found
 *             in numeric order.
 */
void* _sqo_dlopen(const char* name, int mode)
{
    /* 0. */
    if (name == NULL) {
        return  dlopen(name, mode);
    }
    void* handle = NULL;
    /* 1. */
  #if defined(SHLIB_VERSION_NUMBER)
    char* newname = NULL;
    int written = asprintf(&newname, "%s." SHLIB_VERSION_NUMBER, name);
    if (written > 0) {
        if ((handle = dlopen(newname, mode)) != NULL) {
            logTrace("Found %s at %s\n", name, newname);
            free(newname);
            return handle;
        }
    }
#endif
    /* 2. */
    if ((handle = dlopen(name, mode)) != NULL) {
        logTrace("Found %s proper\n", name);
        return handle;
    }
    /* 3. */
    return _sqo_dlopen_any(name, mode);
}


  /*
 * Macro that lookups a symbol in a library and does immediately
 * return the address when found.
 *
 * (with optional debug output)
 */
#define SQO_HAS_FOUND_SYM(s,n,h)                                \
    do {                                                        \
        if ((s = dlsym(h, n))) {                                \
            logTrace("Found symbol %s in " #h "\n", n);      \
            return s;                                           \
        }                                                       \
    } while (0)

/*
 * Macro that lookups a symbol in a _named_ library.
 * Loads library if not yet done.
 * Uses SQO_HAS_FOUND_SYM, therefore immediately returns when found.
 */
#define SQO_FIND_SYM(sym, name, where, dlname)                          \
    do {                                                                \
        if (!dlhandle_ ## where) {                                      \
            logTrace("Loading %s\n",(dlname)?(dlname):"self");       \
            dlhandle_ ## where = _sqo_dlopen(dlname, SQO_DL_FLAGS);     \
        }                                                               \
        if (dlhandle_ ## where) {                                       \
            SQO_HAS_FOUND_SYM(sym, name, dlhandle_ ## where);           \
        }                                                               \
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
  logTrace("Cannot find %s\n", name);
  return sym;
}

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
#define SQO_DECL___(ret, name, ...) ret (*sqo_ ## name)(__VA_ARGS__) = NULL;
#define SQO_DECL_IF(ret, name, ...) ret (*sqo_ ## name)(__VA_ARGS__) = NULL;
#define SQO_DECL_NO(ret, name, ...) /**/

/* THIS LINE IS VITAL */
SQO_DECLARATIONS

#undef SQO_DECL___
#undef SQO_DECL_NO
#undef SQO_DECL_IF


/*
 * List of re-defined OpenSSL macros
 *
 * This is necessary to "redirect" the usage of un-prefixed symbols to
 * sqo_-prefixed ones.
 */

#define sqo_BIO_set_close(b,c) (int)sqo_BIO_ctrl(b,BIO_CTRL_SET_CLOSE,(c),NULL)
#define sqo_SSL_set_tlsext_host_name(s,name) sqo_SSL_ctrl(s,SSL_CTRL_SET_TLSEXT_HOSTNAME,TLSEXT_NAMETYPE_host_name,(char *)name)


struct sqo_bio_st {
    void* _x1; void* _x2;  char* _x3; int _x4; int _x5;
    int flags;
};

static ossl_inline int sqo_BIO_should_retry(BIO* b){
    if (sqo_BIO_test_flags) {
        return sqo_BIO_test_flags(b, BIO_FLAGS_SHOULD_RETRY);
    } else {
        return ((struct sqo_bio_st*)b)->flags & BIO_FLAGS_SHOULD_RETRY;
    }
}

#if OPENSSL_VERSION_NUMBER < 0x10100000L

#define sqo_SSL_CTX_set_options(ctx,op) sqo_SSL_CTX_ctrl((ctx),SSL_CTRL_OPTIONS,(op),NULL)

#define sqo_SKM_sk_num(type, st) sqo_sk_num(CHECKED_STACK_OF(type, st))
#define sqo_SKM_sk_value(type, st,i) ((type *)sqo_sk_value(CHECKED_STACK_OF(type, st), i))
#define sqo_SKM_sk_free(type, st) sqo_sk_free(CHECKED_STACK_OF(type, st))
#define sqo_SKM_sk_pop_free(type, st, free_func) sqo_sk_pop_free(CHECKED_STACK_OF(type, st), CHECKED_SK_FREE_FUNC(type, free_func))
#define sqo_sk_GENERAL_NAME_num(st) sqo_SKM_sk_num(GENERAL_NAME, (st))
#define sqo_sk_GENERAL_NAME_value(st, i) sqo_SKM_sk_value(GENERAL_NAME, (st), (i))
#define sqo_sk_GENERAL_NAME_free(st) sqo_SKM_sk_free(GENERAL_NAME, (st))
#define sqo_sk_GENERAL_NAME_pop_free(st, free_func) sqo_SKM_sk_pop_free(GENERAL_NAME, (st), (free_func))
# else
static ossl_inline int
    sqo_sk_GENERAL_NAME_num(const STACK_OF(GENERAL_NAME)* sk)
{ return sqo_OPENSSL_sk_num((const OPENSSL_STACK*)sk);}
static ossl_inline GENERAL_NAME*
    sqo_sk_GENERAL_NAME_value(const STACK_OF(GENERAL_NAME)* sk, int idx)
{ return (GENERAL_NAME*)sqo_OPENSSL_sk_value((const OPENSSL_STACK*)sk, idx);}
static ossl_inline void
    sqo_sk_GENERAL_NAME_free(const STACK_OF(GENERAL_NAME)* sk)
{ return sqo_OPENSSL_sk_free((OPENSSL_STACK*)sk);}
static ossl_inline void
    sqo_sk_GENERAL_NAME_pop_free(const STACK_OF(GENERAL_NAME)* sk, sk_GENERAL_NAME_freefunc f)
{ return sqo_OPENSSL_sk_pop_free((OPENSSL_STACK*)sk, (OPENSSL_sk_freefunc)f);}
#endif

#endif /* !defined(SQSSL_OPENSSL_LINKED) */
/**********************************************************************/



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

#if defined(OPENSSL_INIT_LOAD_SSL_STRINGS)
#define sqo_OPENSSL_INIT_LOAD_SSL_STRINGS OPENSSL_INIT_LOAD_SSL_STRINGS
#else
#define sqo_OPENSSL_INIT_LOAD_SSL_STRINGS 0x00000002L
#endif

#if defined(OPENSSL_INIT_LOAD_CRYPTO_STRINGS)
#define sqo_OPENSSL_INIT_LOAD_CRYPTO_STRINGS OPENSSL_INIT_LOAD_CRYPTO_STRINGS
#else
#define sqo_OPENSSL_INIT_LOAD_CRYPTO_STRINGS 0x00000002L
#endif

#define sqo_SSL_ERROR_WANT_READ SSL_ERROR_WANT_READ
#define sqo_SSL_ERROR_ZERO_RETURN SSL_ERROR_ZERO_RETURN

#if defined(SSL_ERROR_WANT_X509_LOOKUP)
#define sqo_SSL_ERROR_WANT_X509_LOOKUP SSL_ERROR_WANT_X509_LOOKUP
#else
#define sqo_SSL_ERROR_WANT_X509_LOOKUP 4
#endif


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
#if !defined(SQSSL_OPENSSL_LINKED)
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
#define SQO_DECL___(ret, name, ...) \
  if (!(sqo_ ## name = (ret (*)(__VA_ARGS__)) _sqo_find(#name)))      \
    return false;
#define SQO_DECL_IF(ret, name, ...)                             \
  sqo_ ## name = (ret (*)(__VA_ARGS__)) _sqo_find(#name);
#define SQO_DECL_NO(ret, name, ...) /**/

  /* THIS LINE IS VITAL */
  SQO_DECLARATIONS


#undef SQO_DECL___
#undef SQO_DECL_NO
#undef SQO_DECL_IF

#if !defined(SQSSL_OPENSSL_LINKED) && !defined(__MACH__)
  _sqo_dynamic_lib_dirs_reset();
#endif

#endif  /* defined(SQSSL_OPENSSL_LINKED) */


  if (sqo_SSL_library_init) {
      sqo_SSL_library_init();
      sqo_SSL_load_error_strings();
  } else if (sqo_OPENSSL_init_ssl) {
      sqo_OPENSSL_init_ssl(sqo_OPENSSL_INIT_LOAD_SSL_STRINGS |
                           sqo_OPENSSL_INIT_LOAD_CRYPTO_STRINGS,
                           NULL);
  } else {
      return false;
  }

  return true;
}

#undef SQO_DECLARATIONS


/* !defined(SQ_OPENSSL_OVERLAY_H) */
#endif
/* EOF */
