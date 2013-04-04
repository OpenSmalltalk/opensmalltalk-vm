/* sqMacSSL.c: SqueakSSL implementation based on Mac OSX Security Services */
#include "sq.h"
#include "SqueakSSL.h"

#include <Security/Security.h>
#include <Security/SecCertificate.h>

typedef struct sqSSL {
	int state;
	int certFlags;
	int loglevel;

	char *certName;
	char *peerName;

	
	SSLContextRef ctx;
	CFArrayRef certs;

	/* internal data buffer */
	char *dataBuf;
	int dataLen;
	int dataMax;
	
	/* external data buffer */
	char *outBuf;
	int outLen;
	int outMax;
} sqSSL;


static sqSSL **handleBuf = NULL;
static sqInt handleMax = 0;


/********************************************************************/
/********************************************************************/
/********************************************************************/

/* SqueakSSLRead: Custom read function for Secure Transport */
OSStatus SqueakSSLRead(SSLConnectionRef connection, void *data,
					   size_t *dataLength) {
	sqSSL *ssl = (sqSSL*) connection;
	size_t sz = *dataLength;

	if(ssl->loglevel) 
		printf("SqueakSSLRead: Requesting %d bytes, having %d bytes\n", 
			   (int)sz, ssl->dataLen);
	if(ssl->dataLen < sz) sz = ssl->dataLen;
	memcpy(data, ssl->dataBuf, sz);
	/* Did we have enough data? */
	if(sz == *dataLength) {
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
OSStatus SqueakSSLWrite(SSLConnectionRef connection, const void *data,
						size_t *dataLength) {
	sqSSL *ssl = (sqSSL*) connection;
	size_t sz = ssl->outMax - ssl->outLen;
	
	if(ssl->loglevel) 
		printf("SqueakSSLWrite: Writing %d bytes, having %d free\n", 
			   (int)*dataLength, (int)sz);
	if(sz == 0) {
		*dataLength = 0;
		return errSSLWouldBlock;
	}
	if(*dataLength < sz) sz = *dataLength;
	memcpy(ssl->outBuf + ssl->outLen, data, sz);
	ssl->outLen += sz;
	*dataLength = sz;
	return noErr;
}

/********************************************************************/
/********************************************************************/
/********************************************************************/

/* sslFromHandle: Maps a handle to an SSL */
static sqSSL *sslFromHandle(sqInt handle) {
	return handle < handleMax ? handleBuf[handle] : NULL;
}

/* sqSetupSSL: Common SSL setup task */

int sqSetupSSL(sqSSL *ssl, int isServer) {
	OSStatus status;

	if(ssl->loglevel) printf("sqSetupSSL: Setting up new context\n");
	/* Create the new context */
	status = SSLNewContext(isServer, &ssl->ctx);
	if(status) {
		if(ssl->loglevel) printf("SSLNewContext failed: code = %d\n", (int)status);
		return 0;
	}
	/* Set the connection ref */
	status = SSLSetConnection(ssl->ctx, ssl);
	if(status) {
		if(ssl->loglevel) printf("SSLSetConnection failed: code = %d\n", (int)status);
		return 0;
	}
	
	/* Set up the read/write functions */
	status = SSLSetIOFuncs(ssl->ctx,SqueakSSLRead, SqueakSSLWrite);
	if(status) {
		if(ssl->loglevel) printf("SSLSetIOFuncs failed: code = %d\n", (int)status);
		return 0;
	}

	/* Enable desired protocols */
	status = SSLSetProtocolVersionEnabled(ssl->ctx, kSSLProtocol2, false);
	if(status) {
		if(ssl->loglevel) printf("SSLSetProtocolVersionEnabled failed: code = %d\n", (int)status);
		return 0;
	}

	status = SSLSetProtocolVersionEnabled(ssl->ctx, kSSLProtocol3, true);
	if(status) {
		if(ssl->loglevel) printf("SSLSetProtocolVersionEnabled failed: code = %d\n", (int)status);
		return 0;
	}

	status = SSLSetProtocolVersionEnabled(ssl->ctx, kTLSProtocol1, true);
	if(status) {
		if(ssl->loglevel) printf("SSLSetProtocolVersionEnabled failed: code = %d\n", (int)status);
		return 0;
	}
	/* Disable cert verification since we do that ourselves */
	status = SSLSetEnableCertVerify(ssl->ctx, false);
	if(status) {
		if(ssl->loglevel) printf("SSLSetEnableCertVerify failed: code = %d\n", (int)status);
		return 0;
	}

	return 1;
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
	sqSSL *ssl = NULL;


	ssl = calloc(1, sizeof(sqSSL));
	ssl->loglevel = 0;

	/* Find a free handle */
	for(handle = 1; handle < handleMax; handle++)
		if(handleBuf[handle] == NULL) break;

	if(handle >= handleMax) {
		int i, delta = 100;
		/* Resize the handle buffer */
		handleBuf = realloc(handleBuf, (handleMax+delta)*sizeof(void*));
		for(i = handleMax; i < handleMax+delta; i++)
			handleBuf[i] = NULL;
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
sqInt sqDestroySSL(sqInt handle) {
	sqSSL *ssl = sslFromHandle(handle);
	if(ssl == NULL) return 0;

	if(ssl->certName) free(ssl->certName);
	if(ssl->peerName) free(ssl->peerName);

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
sqInt sqConnectSSL(sqInt handle, char* srcBuf, sqInt srcLen, char *dstBuf, sqInt dstLen) {
	OSStatus status;
	sqSSL *ssl = sslFromHandle(handle);

	if(ssl->loglevel) printf("sqConnectSSL: %x\n", (int)ssl);

	/* Verify state of session */
	if(ssl == NULL || (ssl->state != SQSSL_UNUSED && ssl->state != SQSSL_CONNECTING)) {
		return SQSSL_INVALID_STATE;
	}

	/* Set up the output buffer */
	ssl->outBuf = dstBuf;
	ssl->outLen = 0;
	ssl->outMax = dstLen;

	if(ssl->dataLen + srcLen > ssl->dataMax) {
		/* resize the data buffer */
		ssl->dataMax += (srcLen < 4096) ? (4096) : (srcLen+1024);
		ssl->dataBuf = realloc(ssl->dataBuf, ssl->dataMax);
		if(!ssl->dataBuf) return SQSSL_OUT_OF_MEMORY;
	}
	if(ssl->loglevel) printf("sqConnectSSL: input token %d bytes\n", srcLen);
	memcpy(ssl->dataBuf + ssl->dataLen, srcBuf, srcLen);
	ssl->dataLen += srcLen;

	/* Establish initial connection */
	if(ssl->state == SQSSL_UNUSED) {
		ssl->state = SQSSL_CONNECTING;
		if(ssl->loglevel) printf("sqConnectSSL: Setting up SSL\n");
		if(!sqSetupSSL(ssl, 0)) return SQSSL_GENERIC_ERROR;
	}

	status = SSLHandshake(ssl->ctx);
	if(status == errSSLWouldBlock) {
		/* Return token to caller */
		if(ssl->loglevel) printf("sqConnectSSL: Produced %d token bytes\n", ssl->outLen);
		return ssl->outLen ? ssl->outLen : SQSSL_NEED_MORE_DATA;
	}
	if(status != noErr) {
		if(ssl->loglevel) printf("sqConnectSSL: SSLHandshake returned %d\n", (int)status);
		return SQSSL_GENERIC_ERROR;
	}
	/* We are connected. Verify the cert. */
	ssl->state = SQSSL_CONNECTED;
	ssl->certFlags = -1;

	/* Extract the peer name from the cert */
	status = SSLCopyPeerCertificates(ssl->ctx, &ssl->certs);
	if(status == noErr) {
		if(CFArrayGetCount(ssl->certs) > 0) {
			char peerName[256];
			CFStringRef cfName;
			SecCertificateRef cert = (SecCertificateRef) CFArrayGetValueAtIndex(ssl->certs, 0);
			status = SecCertificateCopyCommonName(cert, &cfName);
			if(status == noErr) {
				CFStringGetCString(cfName, peerName, sizeof(peerName), kCFStringEncodingUTF8);
				ssl->peerName = strdup(peerName);
				CFRelease(cfName);
			}
		}
	}
	return 0;
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
	OSStatus status;
	sqSSL *ssl = sslFromHandle(handle);

	/* Verify state of session */
	if(ssl == NULL || (ssl->state != SQSSL_UNUSED && ssl->state != SQSSL_ACCEPTING)) {
		return SQSSL_INVALID_STATE;
	}

	/* Set up the output buffer */
	ssl->outBuf = dstBuf;
	ssl->outLen = 0;
	ssl->outMax = dstLen;
	
	if(ssl->dataLen + srcLen > ssl->dataMax) {
		/* resize the data buffer */
		ssl->dataMax += (srcLen < 4096) ? (4096) : (srcLen+1024);
		ssl->dataBuf = realloc(ssl->dataBuf, ssl->dataMax);
		if(!ssl->dataBuf) return SQSSL_OUT_OF_MEMORY;
	}
	if(ssl->loglevel) printf("sqConnectSSL: input token %d bytes\n", srcLen);
	memcpy(ssl->dataBuf + ssl->dataLen, srcBuf, srcLen);
	ssl->dataLen += srcLen;
	
	/* Establish initial connection */
	if(ssl->state == SQSSL_UNUSED) {
		ssl->state = SQSSL_ACCEPTING;
		if(ssl->loglevel) printf("sqAcceptSSL: Setting up SSL\n");
		if(!sqSetupSSL(ssl, 1)) return SQSSL_GENERIC_ERROR;
		if(ssl->loglevel) printf("sqAcceptSSL: setting accept state\n");
	}

	status = SSLHandshake(ssl->ctx);
	if(status == errSSLWouldBlock) {
		/* Return token to caller */
		return ssl->outLen ? ssl->outLen : SQSSL_NEED_MORE_DATA;
	}
	if(status != noErr) {
		if(ssl->loglevel) printf("sqConnectSSL: SSLHandshake returned %d\n", (int)status);
		return SQSSL_GENERIC_ERROR;
	}
	/* We are connected. Verify the cert. */
	ssl->state = SQSSL_CONNECTED;
	return 0;
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
	size_t nbytes;
	OSStatus status;
	sqSSL *ssl = sslFromHandle(handle);

	if(ssl == NULL || ssl->state != SQSSL_CONNECTED) return SQSSL_INVALID_STATE;

	/* Set up the output buffer */
	ssl->outBuf = dstBuf;
	ssl->outLen = 0;
	ssl->outMax = dstLen;
	
	if(ssl->loglevel) printf("sqEncryptSSL: Encrypting %d bytes\n", srcLen);

	status = SSLWrite(ssl->ctx, srcBuf, srcLen, &nbytes);
	if(nbytes != srcLen) return SQSSL_GENERIC_ERROR;
		if(status == errSSLWouldBlock || status == noErr) return ssl->outLen;
	if(ssl->loglevel) printf("sqDecryptSSL: SSLWrite returned %d\n", (int)status);
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
sqInt sqDecryptSSL(sqInt handle, char* srcBuf, sqInt srcLen, char *dstBuf, sqInt dstLen) {
	size_t nbytes = 0;
	OSStatus status;
	sqSSL *ssl = sslFromHandle(handle);

	if(ssl == NULL || ssl->state != SQSSL_CONNECTED) return SQSSL_INVALID_STATE;

	if(ssl->dataLen + srcLen > ssl->dataMax) {
		/* resize the read buffer */
		ssl->dataMax += (srcLen < 4096) ? (4096) : (srcLen+1024);
		ssl->dataBuf = realloc(ssl->dataBuf, ssl->dataMax);
		if(!ssl->dataBuf) return SQSSL_OUT_OF_MEMORY;
	}
	if(ssl->loglevel) printf("sqDecryptSSL: Input data %d bytes\n", srcLen);
	memcpy(ssl->dataBuf + ssl->dataLen, srcBuf, srcLen);
	ssl->dataLen += srcLen;
	
	if(ssl->loglevel) printf("sqDecryptSSL: Decrypting %d bytes\n", ssl->dataLen);

	status = SSLRead(ssl->ctx, dstBuf, dstLen, &nbytes);
	if(status == errSSLWouldBlock || status == noErr) return nbytes;
	if(ssl->loglevel) printf("sqDecryptSSL: SSLRead returned %d\n", (int)status);
	return SQSSL_GENERIC_ERROR;
}

/* sqGetStringPropertySSL: Retrieve a string property from SSL.
	Arguments:
		handle - the ssl handle
		propID - the property id to retrieve
	Returns: The string value of the property.
*/
char* sqGetStringPropertySSL(sqInt handle, int propID) {
	sqSSL *ssl = sslFromHandle(handle);

	if(ssl == NULL) return NULL;
	switch(propID) {
		case SQSSL_PROP_PEERNAME:  return ssl->peerName;
		case SQSSL_PROP_CERTNAME:  return ssl->certName;
		default:
			if(ssl->loglevel) printf("sqGetStringPropertySSL: Unknown property ID %d\n", propID);
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
sqInt sqSetStringPropertySSL(sqInt handle, int propID, char *propName, sqInt propLen) {
	sqSSL *ssl = sslFromHandle(handle);
	char *property = NULL;

	if(ssl == NULL) return 0;

	if(propLen) {
	  property = calloc(1, propLen+1);
	  memcpy(property, propName, propLen);
	};

	if(ssl->loglevel) printf("sqSetStringPropertySSL(%d): %s\n", propID, property);

	switch(propID) {
		case SQSSL_PROP_CERTNAME: ssl->certName = property; break;
		default: 
			if(ssl->loglevel) printf("sqSetStringPropertySSL: Unknown property ID %d\n", propID);
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
int sqGetIntPropertySSL(sqInt handle, int propID) {
	sqSSL *ssl = sslFromHandle(handle);

	if(ssl == NULL) return 0;
	switch(propID) {
		case SQSSL_PROP_SSLSTATE: return ssl->state;
		case SQSSL_PROP_CERTSTATE: return ssl->certFlags;
		case SQSSL_PROP_VERSION: return 1;
		case SQSSL_PROP_LOGLEVEL: return ssl->loglevel;
		default:
			if(ssl->loglevel) printf("sqGetIntPropertySSL: Unknown property ID %d\n", propID);
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
	if(ssl == NULL) return 0;

	switch(propID) {
		case SQSSL_PROP_LOGLEVEL: ssl->loglevel = propValue; break;
		default:
			if(ssl->loglevel) printf("sqSetIntPropertySSL: Unknown property ID %d\n", propID);
			return 0;
	}
	return 1;
}
