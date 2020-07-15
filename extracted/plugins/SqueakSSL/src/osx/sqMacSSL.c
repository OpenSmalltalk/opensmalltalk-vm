/****************************************************************************
 *   PROJECT: SqueakSSL implementation for Mac OS X
 *   FILE:    sqMac2SSL.c
 *   CONTENT: SSL platform functions
 *
 *   AUTHORS:  Andreas Raab (ar)
 *
 *             Tobias Pape (topa)
 *               Hasso Plattner Institute, Postdam, Germany
 *****************************************************************************/
#include "sq.h"
#include "SqueakSSL.h"
#include <string.h>
#include <stdarg.h>

#import <Security/Security.h>

typedef struct sqSSL {
    int state;
    int certFlags;
    int loglevel;

    char* certName;
    char* peerName;
    char* serverName;

    SSLContextRef ctx;
    CFArrayRef certs;

    /* internal data buffer */
    char* dataBuf;
    int dataLen;
    int dataMax;

    /* external data buffer */
    char* outBuf;
    int outLen;
    int outMax;
} sqSSL;


/********************************************************************/
#pragma mark Global State
/********************************************************************/

static sqSSL** handleBuf = NULL;
static sqInt handleMax = 0;

static char* emptyString = "";

// Max lengh of a Certificate common name or DNS Host name
#define MAX_HOSTNAME_LENGTH 253


/********************************************************************/
#pragma mark Forward Declarations
/********************************************************************/

#include "pharovm/debug.h"

static int logStatus(OSStatus status, const char* restrict format, ...);
static OSStatus sqExtractPeerName(sqSSL* ssl);
static OSStatus sqGetPeerCertificates(sqSSL* ssl);
static sqSSL* sqSSLFromHandle(sqInt handle);
OSStatus sqSetupSSL(sqSSL* ssl, int isServer);

OSStatus SqueakSSLRead(SSLConnectionRef connection, void* data,
                       size_t* dataLength);

OSStatus SqueakSSLWrite(SSLConnectionRef connection, const void* data,
                        size_t* dataLength);


/********************************************************************/
#pragma mark -
#pragma mark Internal Helper
/********************************************************************/

static int logStatus(OSStatus status, const char* restrict format, ...)
{
    int ret = 0;
    char buffer[1024];

    memset(buffer, 0, sizeof(buffer));

    va_list args;
    va_start(args, format);

    CFErrorRef _e = CFErrorCreate(NULL, kCFErrorDomainOSStatus, status, NULL);
    CFStringRef _sdesc = CFErrorCopyDescription(_e);
    CFStringRef _sreas = CFErrorCopyFailureReason(_e);
    CFStringRef _sreco = CFErrorCopyRecoverySuggestion(_e);

    ret += vsprintf(buffer, format, args);

    logTrace(buffer);

    logTrace("Status (%d): %s (%s): %s\n",
                  (int)status,
                  CFStringGetCStringPtr(_sdesc, kCFStringEncodingUTF8),
                  CFStringGetCStringPtr(_sreas, kCFStringEncodingUTF8),
                  CFStringGetCStringPtr(_sreco, kCFStringEncodingUTF8));

    if (_sreco) CFRelease(_sreco);
    if (_sreas) CFRelease(_sreas);
    if (_sdesc) CFRelease(_sdesc);
    if (_e)     CFRelease(_e);

    va_end(args);

    return ret;
}

/* sqSSLFromHandle: Maps a handle to an SSL */
static sqSSL* sqSSLFromHandle(sqInt handle)
{
    return handle < handleMax ? handleBuf[handle] : NULL;
}

/* sqSetupSSL: Common SSL setup task */
OSStatus sqSetupSSL(sqSSL* ssl, int isServer)
{
    OSStatus status = noErr;

    logTrace("sqSetupSSL: Setting up new context\n");
    /* Create the new context */
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
    ssl->ctx = SSLCreateContext(NULL,
                                isServer ?  kSSLServerSide : kSSLClientSide,
                                kSSLStreamType);
#else
    status = SSLNewContext(isServer, &ssl->ctx);
    if (status != noErr) {
        logStatus(status, "SSLNewContext failed");
        return status;
    }
#endif // MAC_OS_X_VERSION_MAX_ALLOWED >= 1080

    /* Set the connection ref */
    status = SSLSetConnection(ssl->ctx, ssl);
    if (status != noErr) {
        logStatus(status, "SSLSetConnection failed");
        return status;
    }

    /* Set up the read/write functions */
    status = SSLSetIOFuncs(ssl->ctx, SqueakSSLRead, SqueakSSLWrite);
    if (status != noErr) {
        logStatus(status, "SSLSetIOFuncs failed");
        return status;
    }

#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
    /* At least TLS 1 */
    status = SSLSetProtocolVersionMin(ssl->ctx, kTLSProtocol1);
#else
    /* Prefer TLS 1 */
    status = SSLSetProtocolVersionEnabled(ssl->ctx, kTLSProtocol1, true);
#endif // MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
    if (status != noErr) {
        logStatus(status, "SSLSetProtocolVersion{Min,Enabled} failed");
        return status;
    }


#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
    /* Disable cert verification since we do that ourselves */
    status = SSLSetSessionOption(ssl->ctx,
                                 isServer
                                    ? kSSLSessionOptionBreakOnClientAuth
                                    : kSSLSessionOptionBreakOnServerAuth,
                                 true);
    if (status != noErr) {
        logStatus(status, "kSSLSessionOptionBreakOn*Auth failed");
        return status;
    }
#else
    /* Disable cert verification since we do that ourselves */
    status = SSLSetEnableCertVerify(ssl->ctx, false);
    if (status != noErr) {
        logStatus(status, "SSLSetEnableCertVerify failed");
        return status;
    }
#endif // MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
    if (&SSLSetSessionOption != NULL) {
        status = SSLSetSessionOption(ssl->ctx, kSSLSessionOptionSendOneByteRecord,true);
        if (status != noErr) {
            logStatus(status, "kSSLSessionOptionSendOneByteRecord*Auth failed");
            return status;
        }
    }

    if (ssl->serverName) {
        /* Try for SNI */
#if !(MAC_OS_X_VERSION_MAX_ALLOWED >= 1070)
        status = SSLSetPeerDomainName(ssl->ctx, ssl->serverName,
                                      strlen(ssl->serverName));
#else
        status = SSLSetPeerDomainName(ssl->ctx, ssl->serverName,
                                      strnlen(ssl->serverName, MAX_HOSTNAME_LENGTH - 1));
#endif // MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
        if (status != noErr) {
            logStatus(status, "SSLSetPeerDomainName failed");
            return status;
        }
    }

    return status;
}

/* sqExtractPeerName: Extract a copy of the first common name from the
                      certificate obtained in a handshake
 */
static OSStatus sqExtractPeerName(sqSSL* ssl)
{
    OSStatus status = noErr;
    if (CFArrayGetCount(ssl->certs) <= 0) {
        // No cert -> no peer name available
        return status;
    }

    if (ssl->peerName) {
        free(ssl->peerName);
        ssl->peerName = NULL;
    }

    if (ssl->certFlags == SQSSL_OK && ssl->serverName != NULL) {
        // The certificate was already deemed OK by the trust evaulation.
        // This includes matching anything like CN, sAN, or wildcard certs.
        // Therefore, we _copy_ the server name to the peer name such
        // that a match or equality comparison on the Smalltalk side wont
        // fail, which is correct.
#if !(MAC_OS_X_VERSION_MAX_ALLOWED >= 1070)
        ssl->peerName = strdup(ssl->serverName);
#else
        ssl->peerName = strndup(ssl->serverName, MAX_HOSTNAME_LENGTH);
#endif
    } else {
        // Either the cert was not ok OR we weren't given a server name.
        // In the former case, the Smalltalk code typically bails early but
        // copying over the CN does not hurt. In the latter case, we can just
        // guess the users' intention and fall back to the legacy behavior:
        // copying the peername no matter what.
        char peerName[MAX_HOSTNAME_LENGTH + 1];
        CFStringRef cfName = NULL;
        SecCertificateRef cert = (SecCertificateRef)CFArrayGetValueAtIndex(ssl->certs, 0);
        status = SecCertificateCopyCommonName(cert, &cfName);
        if (status == noErr) {
            CFStringGetCString(cfName, peerName, sizeof(peerName), kCFStringEncodingUTF8);
#if !(MAC_OS_X_VERSION_MAX_ALLOWED >= 1070)
            ssl->peerName = strdup(peerName);
#else
            ssl->peerName = strndup(peerName, MAX_HOSTNAME_LENGTH);
#endif
            CFRelease(cfName);
        }
    }
    return status;
}

/* sqGetPeerCertificates: Copy certificates sent for subsequent processing.
 */
static OSStatus sqGetPeerCertificates(sqSSL* ssl)
{
    OSStatus status = noErr;
    SecTrustRef trust = {0};
    CFIndex certCount = 0;
    status = SSLCopyPeerTrust(ssl->ctx, &trust);
    if (status != noErr) {
        return status;
    }
    if (trust == NULL) {
        return -1;
    }
    certCount = SecTrustGetCertificateCount(trust);
    CFMutableArrayRef ca = CFArrayCreateMutable(kCFAllocatorDefault,
                                                certCount,
                                                &kCFTypeArrayCallBacks);
    if (ca == NULL) {
        return errSecAllocate;
    } else {
        for (CFIndex i = 0; i < certCount; i++) {
            CFArrayAppendValue(ca, SecTrustGetCertificateAtIndex(trust, i));
        }
        ssl->certs = ca;
    }
    CFRelease(trust);
    return status;
}


/* sqVerifyCert: Verify the validity of the remote certificate */
static OSStatus sqVerifyCert(sqSSL *ssl, int isServer)
{

    OSStatus status = noErr;
    SecTrustRef trust = {0};
    SecTrustResultType trust_eval = 0;

    ssl->certFlags = SQSSL_NO_CERTIFICATE;
    status = SSLCopyPeerTrust(ssl->ctx, &trust);
    if (trust == NULL || status != noErr){
        logStatus(status, "sqConnectSSL: SSLCopyPeerTrust");
        return SQSSL_GENERIC_ERROR;
    }
    /* <rant>
     * Apple can't be bothered to return something more detailed than
     * 'maaaybe that worked', although their own api would like more detailed
     * results (sslCrypto.c:tls_verify_peer_cert). But noooooo, sslVerifyCertChain
     * also just calls SecTrustEvaluate() and meaningfully asks (in the 10.12 version)
       "
             Do we really need to return things like:
                     errSSLNoRootCert
                     errSSLUnknownRootCert
                     errSSLCertExpired
                     errSSLCertNotYetValid
                     errSSLHostNameMismatch
             for our client to see what went wrong, or should we just always
             return
                     errSSLXCertChainInvalid
             when something is wrong?
       "
     * Yes, Apple, that would be _extremely_ helpful >:(.
     * </rant>
     *
     * Since we only have yes/no/maybe, we cannot return specific reasons here.
     */
    status = SecTrustEvaluate(trust, &trust_eval);
    CFRelease(trust);
    if(status != noErr) {
        logStatus(status, "sqConnectSSL: SecTrustEvaluate");
        return status;
    }
    switch (trust_eval) {
        case kSecTrustResultUnspecified:
        case kSecTrustResultProceed:
            ssl->certFlags = 0; // OK
            break;
        case kSecTrustResultRecoverableTrustFailure:
            // Maybe: Expired, untrusted root, ... but we don't know
            ssl->certFlags = SQSSL_OTHER_ISSUE;
            break;
        default:
            // Fatal
            ssl->certFlags = SQSSL_NO_CERTIFICATE;
            break;
    }
    return status;
}

#pragma mark -
#pragma mark Callbacks

/********************************************************************/
/********************************************************************/
/********************************************************************/

/* SqueakSSLRead: Custom read function for Secure Transport */
OSStatus SqueakSSLRead(SSLConnectionRef connection, void* data,
                       size_t* dataLength)
{
    sqSSL* ssl = (sqSSL*)connection;
    size_t sz = *dataLength;

    logTrace("SqueakSSLRead: Requesting %d bytes, having %d bytes\n",
              (int)sz, ssl->dataLen);

    if (ssl->dataLen < sz) {
        sz = ssl->dataLen;
    }
    memcpy(data, ssl->dataBuf, sz);

    /* Did we have enough data? */
    if (sz == *dataLength) {
        /* Adjust read buffer */
        memmove(ssl->dataBuf, ssl->dataBuf+sz, ssl->dataLen - sz);
        ssl->dataLen -= sz;
        *dataLength = sz;
        return noErr;
    }

    ssl->dataLen = 0;
    *dataLength = sz;
    return errSSLWouldBlock;
}

/* SqueakSSLRead: Custom write function for Secure Transport */
OSStatus SqueakSSLWrite(SSLConnectionRef connection, const void* data,
                        size_t* dataLength)
{
    sqSSL* ssl = (sqSSL*)connection;
    size_t sz = ssl->outMax - ssl->outLen;

    logTrace("SqueakSSLWrite: Writing %d bytes, having %d free\n",
              (int)*dataLength, (int)sz);
    if (sz == 0) {
        *dataLength = 0;
        return errSSLWouldBlock;
    }

    if (*dataLength < sz) {
        sz = *dataLength;
    }
    memcpy(ssl->outBuf + ssl->outLen, data, sz);
    ssl->outLen += sz;
    *dataLength = sz;
    return noErr;
}

/********************************************************************/
#pragma mark -
#pragma mark Plugin Interface
/********************************************************************/

/* sqCreateSSL: Creates a new SSL instance.
        Arguments: None.
        Returns: SSL handle.
*/
sqInt sqCreateSSL(void)
{
    sqInt handle = 0;
    sqSSL* ssl = NULL;


    ssl = calloc(1, sizeof(sqSSL));
    ssl->loglevel = 0;

    /* Find a free handle */
    for (handle = 1; handle < handleMax; handle++) {
        if (handleBuf[handle] == NULL) {
            break;
        }
    }

    if (handle >= handleMax) {
        const int delta = 100;
        /* Resize the handle buffer */
        handleBuf = (sqSSL**)realloc(handleBuf,
                                     (handleMax + delta) * sizeof(sqSSL*));
        for (int i = handleMax; i < handleMax + delta; i++) {
            handleBuf[i] = NULL;
        }
        handleMax += delta;
    }
    handleBuf[handle] = ssl;
    return handle;
}

/* sqDestroySSL: Destroys an SSL instance.
        Arguments:
                handle - the SSL handle
        Returns: Non-zero if successful.
*/
sqInt sqDestroySSL(sqInt handle)
{
    sqSSL* ssl = sqSSLFromHandle(handle);
    if (ssl == NULL) {
        return 0;
    }

    if (ssl->ctx) {
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
        CFRelease(ssl->ctx);
#else
        SSLDisposeContext(ssl->ctx);
#endif // MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
    }

    if (ssl->certName) {
        free(ssl->certName);
        ssl->certName = NULL;
    }
    if (ssl->peerName) {
        free(ssl->peerName);
        ssl->peerName = NULL;
    }
    if (ssl->serverName) {
        free(ssl->serverName);
        ssl->serverName = NULL;
    }

    free(ssl);
    handleBuf[handle] = NULL;
    return 1;
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
sqInt sqConnectSSL(sqInt handle, char* srcBuf, sqInt srcLen, char* dstBuf,
                   sqInt dstLen)
{
    OSStatus status;
    sqSSL* ssl = sqSSLFromHandle(handle);

    logTrace("sqConnectSSL: %x\n", (int)ssl);

    /* Verify state of session */
    if (ssl == NULL
        || (ssl->state != SQSSL_UNUSED && ssl->state != SQSSL_CONNECTING)) {
        return SQSSL_INVALID_STATE;
    }

    /* Set up the output buffer */
    ssl->outBuf = dstBuf;
    ssl->outLen = 0;
    ssl->outMax = dstLen;

    if (ssl->dataLen + srcLen > ssl->dataMax) {
        /* resize the data buffer */
        ssl->dataMax += (srcLen < 4096) ? (4096) : (srcLen + 1024);
        ssl->dataBuf = realloc(ssl->dataBuf, ssl->dataMax);
        if (!ssl->dataBuf) {
            return SQSSL_OUT_OF_MEMORY;
        }
    }
    logTrace("sqConnectSSL: input token %" PRIdSQINT " bytes\n", srcLen);
    memcpy(ssl->dataBuf + ssl->dataLen, srcBuf, srcLen);
    ssl->dataLen += srcLen;

    /* Establish initial connection */
    if (ssl->state == SQSSL_UNUSED) {
        ssl->state = SQSSL_CONNECTING;
        logTrace("sqConnectSSL: Setting up SSL\n");
        status = sqSetupSSL(ssl, 0);
        if (status != noErr) {
            return SQSSL_GENERIC_ERROR;
        }
    }

    status = SSLHandshake(ssl->ctx);
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
    if (status == errSSLServerAuthCompleted) {
        OSStatus secStatus = sqVerifyCert(ssl, true);
        if(secStatus != noErr) {
            logStatus(secStatus, "sqConnectSSL: sqVerifyCert");
            // we should but currently _cannot_ return here.
            // return SQSSL_GENERIC_ERROR;
        }
        // Continue Handshake
        status = SSLHandshake(ssl->ctx);
    }
#endif // MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
    if (status == errSSLWouldBlock) {
        /* Return token to caller */
        logTrace("sqConnectSSL: Produced %d token bytes\n", ssl->outLen);
        return ssl->outLen ? ssl->outLen : SQSSL_NEED_MORE_DATA;
    } else if (status != noErr) {
        logStatus(status, "sqConnectSSL: SSLHandshake");
        return SQSSL_GENERIC_ERROR;
    }
    ssl->state = SQSSL_CONNECTED;

    /* Extract the peer name from the cert */
    status = sqGetPeerCertificates(ssl);
    if (status == noErr) {
        sqExtractPeerName(ssl);
    }
    return SQSSL_OK;
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
sqInt sqAcceptSSL(sqInt handle, char* srcBuf, sqInt srcLen, char* dstBuf,
                  sqInt dstLen)
{
    OSStatus status = noErr;
    sqSSL* ssl = sqSSLFromHandle(handle);

    /* Verify state of session */
    if (ssl == NULL
        || (ssl->state != SQSSL_UNUSED && ssl->state != SQSSL_ACCEPTING)) {
        return SQSSL_INVALID_STATE;
    }

    /* Set up the output buffer */
    ssl->outBuf = dstBuf;
    ssl->outLen = 0;
    ssl->outMax = dstLen;

    if (ssl->dataLen + srcLen > ssl->dataMax) {
        /* resize the data buffer */
        ssl->dataMax += (srcLen < 4096) ? (4096) : (srcLen + 1024);
        ssl->dataBuf = realloc(ssl->dataBuf, ssl->dataMax);
        if (!ssl->dataBuf) {
            return SQSSL_OUT_OF_MEMORY;
        }
    }
    logTrace("sqConnectSSL: input token %" PRIdSQINT " bytes\n", srcLen);
    memcpy(ssl->dataBuf + ssl->dataLen, srcBuf, srcLen);
    ssl->dataLen += srcLen;

    /* Establish initial connection */
    if (ssl->state == SQSSL_UNUSED) {
        ssl->state = SQSSL_ACCEPTING;
        logTrace("sqAcceptSSL: Setting up SSL\n");
        status = sqSetupSSL(ssl, 1);
        if (status != noErr) {
            return SQSSL_GENERIC_ERROR;
        }
        logTrace("sqAcceptSSL: setting accept state\n");
    }

    status = SSLHandshake(ssl->ctx);
    if (status == errSSLWouldBlock) {
        /* Return token to caller */
        return ssl->outLen ? ssl->outLen : SQSSL_NEED_MORE_DATA;
    }
    if (status != noErr) {
        logTrace("sqConnectSSL: SSLHandshake returned %d\n", (int)status);
        return SQSSL_GENERIC_ERROR;
    }
    /* We are connected. Verify the cert. */
    ssl->state = SQSSL_CONNECTED;
        return SQSSL_OK;
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
sqInt sqEncryptSSL(sqInt handle, char* srcBuf, sqInt srcLen, char* dstBuf,
                   sqInt dstLen)
{
    size_t nbytes = 0;
    OSStatus status = noErr;
    sqSSL* ssl = sqSSLFromHandle(handle);

    if (ssl == NULL || ssl->state != SQSSL_CONNECTED) {
        return SQSSL_INVALID_STATE;
    }

    /* Set up the output buffer */
    ssl->outBuf = dstBuf;
    ssl->outLen = 0;
    ssl->outMax = dstLen;

    logTrace("sqEncryptSSL: Encrypting %" PRIdSQINT " bytes\n", srcLen);

    status = SSLWrite(ssl->ctx, srcBuf, srcLen, &nbytes);
    if (nbytes != srcLen) {
        return SQSSL_GENERIC_ERROR;
    }
    if (status == errSSLWouldBlock || status == noErr
        || status == errSSLClosedGraceful) {
        return ssl->outLen;
    }
    logStatus(status, "sqDecryptSSL: SSLWrite");
    return SQSSL_GENERIC_ERROR;
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
sqInt sqDecryptSSL(sqInt handle, char* srcBuf, sqInt srcLen, char* dstBuf,
                   sqInt dstLen)
{
    size_t nbytes = 0;
    OSStatus status = noErr;
    sqSSL* ssl = sqSSLFromHandle(handle);

    if (ssl == NULL || ssl->state != SQSSL_CONNECTED) {
        return SQSSL_INVALID_STATE;
    }

    if (ssl->dataLen + srcLen > ssl->dataMax) {
        /* resize the read buffer */
        ssl->dataMax += (srcLen < 4096) ? (4096) : (srcLen + 1024);
        ssl->dataBuf = realloc(ssl->dataBuf, ssl->dataMax);
        if (!ssl->dataBuf) {
            return SQSSL_OUT_OF_MEMORY;
        }
    }
    logTrace("sqDecryptSSL: Input data %" PRIdSQINT " bytes\n", srcLen);
    memcpy(ssl->dataBuf + ssl->dataLen, srcBuf, srcLen);
    ssl->dataLen += srcLen;

    logTrace("sqDecryptSSL: Decrypting %d bytes\n", ssl->dataLen);

    status = SSLRead(ssl->ctx, dstBuf, dstLen, &nbytes);
    if (status == errSSLWouldBlock || status == noErr
        || status == errSSLClosedGraceful) {
        return nbytes;
    }
    logStatus(status, "sqDecryptSSL: SSLRead");
    return SQSSL_GENERIC_ERROR;
}

/* sqGetStringPropertySSL: Retrieve a string property from SSL.
        Arguments:
                handle - the ssl handle
                propID - the property id to retrieve
        Returns: The string value of the property.
*/
char* sqGetStringPropertySSL(sqInt handle, int propID)
{
    sqSSL* ssl = sqSSLFromHandle(handle);

    if (ssl == NULL) {
        return NULL;
    }

    switch (propID) {
    case SQSSL_PROP_PEERNAME:	return ssl->peerName ? ssl->peerName : emptyString;
    case SQSSL_PROP_CERTNAME:   return ssl->certName;
    case SQSSL_PROP_SERVERNAME: return ssl->serverName;
    default:
        logTrace("sqGetStringPropertySSL: Unknown property ID %d\n", propID);
        return NULL;
    }
    return NULL;
}

/* sqSetStringPropertySSL: Set a string property in SSL.
        Arguments:
                handle - the ssl handle
                propID - the property id to retrieve
                propName - the property string
                propLen  - the length of the property string
        Returns: Non-zero if successful.
*/
sqInt sqSetStringPropertySSL(sqInt handle, int propID, char* propName,
                             sqInt propLen)
{
    sqSSL* ssl = sqSSLFromHandle(handle);
    char* property = NULL;

    if (ssl == NULL) return 0;

    if (propLen) {
        property = malloc(propLen + 1);
        memcpy(property, propName, propLen);
        property[propLen] = '\0';
    }

    logTrace("sqSetStringPropertySSL(%d): %s\n",
              propID, property ? property : "(null)");

    switch(propID) {
    case SQSSL_PROP_CERTNAME:
        if (ssl->certName) {
            free(ssl->certName);
        }
        ssl->certName = property;
        break;
    case SQSSL_PROP_SERVERNAME:
        if (ssl->serverName) {
            free(ssl->serverName);
        }
        ssl->serverName = property;
        break;
    default:
        if (property) {
            free(property);
        }
        logTrace("sqSetStringPropertySSL: Unknown property ID %d\n", propID);
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
sqInt sqGetIntPropertySSL(sqInt handle, sqInt propID)
{
    sqSSL* ssl = sqSSLFromHandle(handle);

    if (ssl == NULL) {
        return 0;
    }

    switch(propID) {
    case SQSSL_PROP_SSLSTATE:  return ssl->state;
    case SQSSL_PROP_CERTSTATE: return ssl->certFlags;
    case SQSSL_PROP_VERSION:   return SQSSL_VERSION;
    case SQSSL_PROP_LOGLEVEL:  return ssl->loglevel;
    default:
        logTrace("sqGetIntPropertySSL: Unknown property ID %" PRIdSQINT "\n", propID);
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
sqInt sqSetIntPropertySSL(sqInt handle, sqInt propID, sqInt propValue)
{
    sqSSL* ssl = sqSSLFromHandle(handle);
    if (ssl == NULL) {
        return 0;
    }

    switch(propID) {
    case SQSSL_PROP_SSLSTATE:  // falltrough
    case SQSSL_PROP_CERTSTATE: // falltrough
    case SQSSL_PROP_VERSION:
        logTrace("sqSetIntPropertySSL: property is readonly %" PRIdSQINT "\n", propID);
        break;
    case SQSSL_PROP_LOGLEVEL:
        ssl->loglevel = (int)propValue;
        break;
    default:
        logTrace("sqSetIntPropertySSL: Unknown property ID %" PRIdSQINT "\n", propID);
        return 0;
    }
    return 1;
}
