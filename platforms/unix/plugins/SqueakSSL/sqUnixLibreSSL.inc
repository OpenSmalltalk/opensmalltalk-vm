/* -*- mode: c; -*- */
/****************************************************************************
 *   PROJECT: SqueakSSL implementation for Unix
 *   FILE:    sqUnixLibreSSL.c
 *   CONTENT: SSL platform functions
 *
 *   AUTHORS:  Ian Piumarta (ikp)
 *             David T. Lewis (dtl)
 *
 *             Tobias Pape (topa)
 *               Hasso Plattner Institute, Potsdam, Germany
 *****************************************************************************/

#include "sq.h"
#include "SqueakSSL.h"

#include <tls.h>

typedef struct sqSSL {
    int state;
    int certFlags;
    int loglevel;

    char *certName;
    char *peerName;
    char *serverName;

    struct tls_config* config;
    struct tls* tls;
    struct tls* server_tls;

    char* readBuf;
    sqInt readLen;
    sqInt readMax;

    char* writeBuf;
    sqInt writeLen;
    sqInt writeMax;
} sqSSL;

/* By convention, the sqSSL object is named ssl and has its logLevel >= 0 */
#define LOG(...) do if (ssl->loglevel) {                    \
    printf("(%-4d)%s: ", __LINE__,  __func__);              \
    printf( __VA_ARGS__);                                   \
} while(0)


enum ssl_side { CLIENT = 0, SERVER = 1};
static const size_t DNS_NAME_MAX = 255;

/* Declarations */

sqInt sqSetupSSL(sqSSL* ssl, int isServer);
sqInt sqHandshakeSSL(sqSSL* ssl, char* srcBuf, sqInt srcLen, char* dstBuf, sqInt dstLen);
sqInt sqConsumeReadBuf(sqSSL* ssl, void* buffer, sqInt buflen);
sqInt sqProduceReadBuf(sqSSL* ssl, const void* buffer, sqInt buflen);
sqInt sqConsumeWriteBuf(sqSSL* ssl, void* buffer, sqInt buflen);
sqInt sqProduceWriteBuf(sqSSL* ssl, const void* buffer, sqInt buflen);

/* ========== */

sqInt sqConsumeReadBuf(sqSSL* ssl, void* buffer, sqInt buflen)
{
    if (ssl->readLen < buflen) return SQSSL_NEED_MORE_DATA; 
    memcpy(buffer, ssl->readBuf, buflen);
    /* move remaining data to front */
    memmove(ssl->readBuf,
            ssl->readBuf + buflen,
            ssl->readLen - buflen);
    ssl->readLen -= buflen;
    return buflen;
}

sqInt sqProduceReadBuf(sqSSL* ssl, const void* buffer, sqInt buflen)
{
    if (ssl->readMax - ssl->readLen < buflen) {
        /* add buflen + 1k but make at least 4k */
        ssl->readMax += (buflen < 4096) ? 4096 : (buflen + 1024);
        ssl->readBuf = realloc(ssl->readBuf, ssl->readMax);
        if (ssl->readBuf == NULL) return SQSSL_OUT_OF_MEMORY;
    }
    memcpy(ssl->readBuf + ssl->readLen, buffer, buflen);
    ssl->readLen += buflen;
    return buflen;
}

sqInt sqConsumeWriteBuf(sqSSL* ssl, void* buffer, sqInt buflen)
{
    if (ssl->writeLen > buflen) return SQSSL_NEED_MORE_DATA;
    /* drain data */
    sqInt transferred = ssl->writeLen;
    ssl->writeLen = 0;
    memcpy(buffer, ssl->writeBuf, transferred);
    return transferred; 
}

sqInt sqProduceWriteBuf(sqSSL* ssl, const void* buffer, sqInt buflen)
{
    if (ssl->writeMax - ssl->writeLen < buflen) {
        /* add buflen + 1k but make at least 4k */
        ssl->writeMax += (buflen < 4096) ? 4096 : (buflen + 1024);
        ssl->writeBuf = realloc(ssl->writeBuf, ssl->writeMax);
        if (ssl->writeBuf == NULL) {
            return SQSSL_OUT_OF_MEMORY;
        }
    }
    memcpy(ssl->writeBuf + ssl->writeLen, buffer, buflen);
    ssl->writeLen += buflen;
    return buflen;
}


ssize_t sqReadSSL(struct tls* tls, void* buffer, size_t buflen, void* payload)
{
    sqSSL* ssl = (sqSSL*) payload;
    sqInt consumed = 0;
    LOG("%4zu bytes expected; buffer %4" PRIdSQINT " bytes\n",
        buflen, ssl->readLen);
    consumed = sqConsumeReadBuf(ssl, buffer, buflen);
    if (consumed == SQSSL_NEED_MORE_DATA) {
        return TLS_WANT_POLLIN;
    } else {
        return consumed;
    }
}

ssize_t sqWriteSSL(struct tls* tls, const void* buf, size_t buflen, void* payload)
{
    sqSSL* ssl = (sqSSL*) payload;
    sqInt produced = 0;
    LOG("%4zu bytes pending; buffer size %4" PRIdSQINT " bytes\n",
              buflen, ssl->writeLen);
    produced = sqProduceWriteBuf(ssl, buf, buflen);
    if (produced == SQSSL_NEED_MORE_DATA) {
        return TLS_WANT_POLLOUT;
    } else {
        return produced;
    }
}
/********************************************************************/
/********************************************************************/
/********************************************************************/

/* sslFromHandle: Maps a handle to an SSL */
static sqSSL *sslFromHandle(sqInt handle) {
    /* untag known SSL pointer. We disguised the handle */
    return (sqSSL*)(handle & ~1);
}

/* sqSetupSSL: Common SSL setup tasks */
sqInt sqSetupSSL(sqSSL *ssl, int side) {
    struct tls* the_tls = NULL;

    if (ssl->tls != NULL || ssl->server_tls != NULL || ssl->config == NULL) return -1;

    /* if a cert is provided, use it */
    if (ssl->certName) {
        LOG("sqSetupSSL: Using cert file %s\n", ssl->certName);
        if (tls_config_set_cert_file(ssl->config, ssl->certName) == -1) goto err;
        if (tls_config_set_key_file(ssl->config, ssl->certName) == -1) goto err;
    }
    /* XXX: TODO: fix */
    tls_config_insecure_noverifycert(ssl->config);
    tls_config_insecure_noverifyname(ssl->config);

    if (side == CLIENT) {
        the_tls = ssl->tls = tls_client();
    } else if (side == SERVER) {
        the_tls = ssl->server_tls = tls_server();
    }

    if (the_tls == NULL) goto err;

    if (tls_configure(the_tls, ssl->config) == -1) goto err;

    return SQSSL_OK;

err:
    fprintf(stderr, "%s", tls_config_error(ssl->config));
    return SQSSL_GENERIC_ERROR;
}

char* sqExtractCNFromSubject(const char* subject)
{
    char* peerName = NULL;
    size_t subject_length = strnlen(subject, 1024); /* for good measure */
    char* cn = strstr(subject, "CN=");

    if (cn != NULL) {
        /* "CN=" found, lets see if we have room after it */
        if (cn + 3 /*CN=*/ < subject + subject_length - 1) {
            cn += 3;
            size_t cn_length = strnlen(cn, DNS_NAME_MAX);

            char* eocn = strchr(cn, '/');
            if (eocn != NULL) {
                /* something's after the CN, cut it */
                cn_length = (size_t) (eocn - cn);
            }
            peerName = strndup(cn, cn_length);
        }
    }
    return peerName;
}

/********************************************************************/
/********************************************************************/
/********************************************************************/

/* sqCreateSSL: Creates a new SSL instance.
        Arguments: None.
        Returns: SSL handle.
*/
sqInt sqCreateSSL(void) {
    sqInt handle = 0;
    sqSSL* ssl = NULL;

    tls_init();

    ssl = calloc(1, sizeof(sqSSL));
    ssl->config = tls_config_new();
    /* We use the fact that the SSLs are pointers and tag them as Smalltalk integers,
       so nobody comes to the idea to use them as pointers */
    handle = ((sqInt) ssl) | 1;
    return handle;
}

/* sqDestroySSL: Destroys an SSL instance.
        Arguments:
                handle - the SSL handle
        Returns: Non-zero if successful.
*/
sqInt sqDestroySSL(sqInt handle) {
    sqSSL *ssl = sslFromHandle(handle);
    if (ssl == NULL) return 0;

    if (ssl->tls) {
        /* TODO: closing communication */
        tls_close(ssl->tls);
        tls_free(ssl->tls);
    }
    if (ssl->server_tls) {
        /* TODO: closing communication */
        tls_close(ssl->server_tls);
        tls_free(ssl->server_tls);
    }
    if (ssl->config) tls_config_free(ssl->config);

    free(ssl->certName);
    free(ssl->peerName);
    free(ssl->serverName);

    free(ssl->writeBuf);
    free(ssl->readBuf);

    free(ssl);
    return 1;
}


sqInt sqHandshakeSSL(sqSSL* ssl, char* srcBuf, sqInt srcLen, char* dstBuf, sqInt dstLen)
{
    ssize_t handshake_result = -1;
    ssize_t transferred = 0;
    /* Do handshake (may return here on POLLIN) */
    handshake_result = tls_handshake(ssl->tls);
    transferred = sqConsumeWriteBuf(ssl, dstBuf, dstLen);
    if (handshake_result != 0) {
        if (handshake_result != TLS_WANT_POLLIN &&
            handshake_result != TLS_WANT_POLLOUT
        ) {
            LOG("handshake failed (%zd)\n", handshake_result);
            fprintf(stdout, "%s\n", tls_error(ssl->tls));
            return SQSSL_GENERIC_ERROR;
        }
        if (transferred > 0) {
            return transferred;
        } else {
            return SQSSL_NEED_MORE_DATA;
        }
    }
    LOG("connected\n");
    ssl->state = SQSSL_CONNECTED;

    if (tls_peer_cert_provided(ssl->tls) == 1) {
        if (ssl->serverName != NULL &&
            tls_peer_cert_contains_name(ssl->tls, ssl->serverName)) {
            ssl->peerName = strndup(ssl->serverName,
                                    strnlen(ssl->serverName,
                                            DNS_NAME_MAX));
        } else {
            ssl->peerName = sqExtractCNFromSubject(tls_peer_cert_subject(ssl->tls));
        }
        LOG("peerName = %s\n", ssl->peerName);
    } else {
        LOG("No peer cert\n");
        ssl->certFlags = SQSSL_NO_CERTIFICATE;
    }
    return transferred;
}


/* sqConnectSSL: Start/continue an SSL client handshake.
        Arguments:
                handle - the SSL handle
                srcBuf - the input token sent by the remote peer
                srcLen - the size of the input token
                dstBuf - the output buffer for a new token
                dstLen - the size of the output buffer
        Returns: The size of the output token or an error code.
*/
sqInt sqConnectSSL(sqInt handle, char* srcBuf, sqInt srcLen, char *dstBuf, sqInt dstLen)
{
    sqSSL *ssl = sslFromHandle(handle);
    LOG("%p\n", ssl);

    /* Verify state of session */
    if (ssl == NULL || (ssl->state != SQSSL_UNUSED && ssl->state != SQSSL_CONNECTING)) {
        return SQSSL_INVALID_STATE;
    }

    if (srcLen > 0) LOG("push %ld bytes\n", (long)srcLen);
    sqProduceReadBuf(ssl, srcBuf, srcLen);

    if (ssl->state == SQSSL_UNUSED) {
        /* Establish initial connection */
        ssl->state = SQSSL_CONNECTING;
        LOG("Setting up SSL\n");
        if (sqSetupSSL(ssl, 0) != SQSSL_OK) return SQSSL_GENERIC_ERROR;

        if (tls_connect_cbs(ssl->tls, sqReadSSL, sqWriteSSL, ssl, ssl->serverName) == -1) {
            fprintf(stderr, "%s\n", tls_error(ssl->tls));
            return SQSSL_GENERIC_ERROR;
        }
    }
    LOG("Proceed handshake\n");
    return sqHandshakeSSL(ssl, srcBuf, srcLen, dstBuf, dstLen);
}

/* sqAcceptSSL: Start/continue an SSL server handshake.
        Arguments:
                handle - the SSL handle
                srcBuf - the input token sent by the remote peer
                srcLen - the size of the input token
                dstBuf - the output buffer for a new token
                dstLen - the size of the output buffer
        Returns: The size of the output token or an error code.
*/
sqInt sqAcceptSSL(sqInt handle, char* srcBuf, sqInt srcLen, char *dstBuf, sqInt dstLen) {

  sqSSL *ssl = sslFromHandle(handle);

    LOG("%p\n", ssl);

    /* Verify state of session */
    if (ssl == NULL || (ssl->state != SQSSL_UNUSED && ssl->state != SQSSL_ACCEPTING)) {
        return SQSSL_INVALID_STATE;
    }

    if (srcLen > 0) LOG("push %ld bytes\n", (long)srcLen);
    sqProduceReadBuf(ssl, srcBuf, srcLen);

    if (ssl->state == SQSSL_UNUSED) {
        /* Establish initial connection */
        ssl->state = SQSSL_ACCEPTING;
        LOG("Setting up SSL\n");
        if (sqSetupSSL(ssl, 1) != SQSSL_OK) return SQSSL_GENERIC_ERROR;
        if (tls_accept_cbs(ssl->server_tls, &ssl->tls, sqReadSSL, sqWriteSSL, ssl) == -1) {
            fprintf(stderr, "%s\n", tls_error(ssl->tls));
            return SQSSL_GENERIC_ERROR;
        }
    }
    LOG("Proceed handshake\n");
    return sqHandshakeSSL(ssl, srcBuf, srcLen, dstBuf, dstLen);
}

/* sqEncryptSSL: Encrypt data for SSL transmission.
        Arguments:
                handle - the SSL handle
                srcBuf - the unencrypted input data
                srcLen - the size of the input data
                dstBuf - the output buffer for the encrypted contents
                dstLen - the size of the output buffer
        Returns: The size of the output generated or an error code.
*/
sqInt sqEncryptSSL(sqInt handle, char* srcBuf, sqInt srcLen, char *dstBuf, sqInt dstLen) {
    sqSSL *ssl = sslFromHandle(handle);
    ssize_t out = 0;
    ssize_t transferred = 0;

    if (ssl == NULL || ssl->state != SQSSL_CONNECTED) return SQSSL_INVALID_STATE;

    LOG("Encrypting %" PRIdSQINT " bytes\n", srcLen);
    out = tls_write(ssl->tls, srcBuf, srcLen);
    if (out <= 0) {
        if (out == TLS_WANT_POLLIN || out == TLS_WANT_POLLOUT) {
            return SQSSL_NEED_MORE_DATA;
        } else {
            return SQSSL_GENERIC_ERROR;
            fprintf(stdout, "%s\n", tls_error(ssl->tls));
        }
    }
    transferred = sqConsumeWriteBuf(ssl, dstBuf, dstLen);
    LOG("out: %zu, transf: %" PRIdSQINT " bytes\n", out, transferred);
    return transferred;
}

/* sqDecryptSSL: Decrypt data for SSL transmission.
        Arguments:
                handle - the SSL handle
                srcBuf - the encrypted input data
                srcLen - the size of the input data
                dstBuf - the output buffer for the decrypted contents
                dstLen - the size of the output buffer
        Returns: The size of the output generated or an error code.
*/
sqInt sqDecryptSSL(sqInt handle, char* srcBuf, sqInt srcLen, char *dstBuf, sqInt dstLen) {
    sqSSL *ssl = sslFromHandle(handle);
    ssize_t in = 0;
    ssize_t transferred = 0;

    if (ssl == NULL || ssl->state != SQSSL_CONNECTED) return SQSSL_INVALID_STATE;

    LOG("Decrypting %" PRIdSQINT " bytes\n", srcLen);

    sqProduceReadBuf(ssl, srcBuf, srcLen);
    in = tls_read(ssl->tls, dstBuf, dstLen);
    if (in <= 0) {
        if (in == TLS_WANT_POLLIN || in == TLS_WANT_POLLOUT) {
            return 0; //? SQSSL_NEED_MORE_DATA;
        } else {
            fprintf(stdout, "%s\n", tls_error(ssl->tls));
            return SQSSL_GENERIC_ERROR;
        }
    }
    LOG("in: %zu bytes\n", in);
    return (sqInt) in;
}

/* sqGetStringPropertySSL: Retrieve a string property from SSL.
        Arguments:
                handle - the ssl handle
                propID - the property id to retrieve
        Returns: The string value of the property.
*/
char* sqGetStringPropertySSL(sqInt handle, int propID) {
    sqSSL *ssl = sslFromHandle(handle);

    if (ssl == NULL) return NULL;
    switch(propID) {
    case SQSSL_PROP_PEERNAME:   return ssl->peerName;
    case SQSSL_PROP_CERTNAME:   return ssl->certName;
    case SQSSL_PROP_SERVERNAME:         return ssl->serverName;
    default:
        LOG("Unknown property ID %d\n", propID);
        return NULL;
    }
    // unreachable
}

/* sqSetStringPropertySSL: Set a string property in SSL.
        Arguments:
                handle - the ssl handle
                propID - the property id to retrieve
                propName - the property string
                propLen - the length of the property string
        Returns: Non-zero if successful.
*/
sqInt sqSetStringPropertySSL(sqInt handle, int propID, char *propName, sqInt propLen) {
    sqSSL *ssl = sslFromHandle(handle);
    char *property = NULL;

    if (ssl == NULL) return 0;

    if (propLen) {
        property = strndup(propName, propLen);
    }

    LOG("sqSetStringPropertySSL(%d): %s\n", propID, property ? property : "(null)");

    switch(propID) {
    case SQSSL_PROP_CERTNAME:
        if (ssl->certName) free(ssl->certName);
        ssl->certName = property;
        break;
    case SQSSL_PROP_SERVERNAME:
        if (ssl->serverName) free(ssl->serverName);
        ssl->serverName = property;
        break;
    default:
        if (property) free(property);
        LOG("Unknown property ID %d\n", propID);
        return 0;
    }
    return 1;
}

/* sqGetIntPropertySSL: Retrieve an integer property from SSL.
        Arguments:
                handle - the ssl handle
                propID - the property id to retrieve
        Returns: The integer value of the property.
*/
sqInt sqGetIntPropertySSL(sqInt handle, sqInt propID) {
    sqSSL *ssl = sslFromHandle(handle);

    if (ssl == NULL) return 0;
    switch(propID) {
    case SQSSL_PROP_SSLSTATE: return ssl->state;
    case SQSSL_PROP_CERTSTATE: return ssl->certFlags;
    case SQSSL_PROP_VERSION: return SQSSL_VERSION;
    case SQSSL_PROP_LOGLEVEL: return ssl->loglevel;
    default:
        LOG("Unknown property ID %ld\n", (long)propID);
        return 0;
    }
    return 0;
}

/* sqSetIntPropertySSL: Set an integer property in SSL.
        Arguments:
                handle - the ssl handle
                propID - the property id to retrieve
                propValue - the property value
        Returns: Non-zero if successful.
*/
sqInt sqSetIntPropertySSL(sqInt handle, sqInt propID, sqInt propValue) {
    sqSSL *ssl = sslFromHandle(handle);
    if (ssl == NULL) return 0;

    switch(propID) {
    case SQSSL_PROP_LOGLEVEL: ssl->loglevel = propValue; break;
    default:
        LOG("Unknown property ID %ld\n", (long)propID);
        return 0;
    }
    return 1;
}
