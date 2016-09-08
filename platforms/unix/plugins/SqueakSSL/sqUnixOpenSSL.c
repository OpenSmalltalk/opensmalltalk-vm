#include "sq.h"
#include "SqueakSSL.h"

#include "openssl/ssl.h"
#include "openssl/err.h"

typedef struct sqSSL {
	int state;
	int certFlags;
	int loglevel;

	char *certName;
	char *peerName;
	char *serverName;

	SSL_METHOD *method;
	SSL_CTX *ctx;
	SSL *ssl;
	BIO *bioRead;
	BIO *bioWrite;
} sqSSL;


static sqSSL **handleBuf = NULL;
static sqInt handleMax = 0;

/********************************************************************/
/********************************************************************/
/********************************************************************/

/* sslFromHandle: Maps a handle to an SSL */
static sqSSL *sslFromHandle(sqInt handle) {
	return handle < handleMax ? handleBuf[handle] : NULL;
}

/* sqCopyBioSSL: Copies data from a BIO into an out buffer */
sqInt sqCopyBioSSL(sqSSL *ssl, BIO *bio, char *dstBuf, sqInt dstLen) {
	int nbytes = BIO_ctrl_pending(bio);

	if(ssl->loglevel) printf("sqCopyBioSSL: %d bytes pending; buffer size %ld\n", 
				nbytes, (long)dstLen);
	if(nbytes > dstLen) return -1;
	return BIO_read(bio, dstBuf, dstLen);
}

/* sqSetupSSL: Common SSL setup tasks */
sqInt sqSetupSSL(sqSSL *ssl, int server) {

	/* Fixme. Needs to use specified version */
	if(ssl->loglevel) printf("sqSetupSSL: setting method\n");
	ssl->method = (SSL_METHOD*) SSLv23_method();
	if(ssl->loglevel) printf("sqSetupSSL: Creating context\n");
	ssl->ctx = SSL_CTX_new(ssl->method);
	if(ssl->loglevel) printf("sqSetupSSL: Disabling SSLv2 and SSLv3\n");
	SSL_CTX_set_options(ssl->ctx, SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3);

	if(!ssl->ctx) ERR_print_errors_fp(stdout);

	if(ssl->loglevel) printf("sqSetupSSL: setting cipher list\n");
	SSL_CTX_set_cipher_list(ssl->ctx, "!ADH:HIGH:MEDIUM:@STRENGTH");

	/* if a cert is provided, use it */
	if(ssl->certName) {
		if(ssl->loglevel) printf("sqSetupSSL: Using cert file %s\n", ssl->certName);
		if(SSL_CTX_use_certificate_file(ssl->ctx, ssl->certName, SSL_FILETYPE_PEM)<=0)
			ERR_print_errors_fp(stderr);

		if(SSL_CTX_use_PrivateKey_file(ssl->ctx, ssl->certName, SSL_FILETYPE_PEM)<=0)
			ERR_print_errors_fp(stderr);
	}

	/* Set up trusted CA */
	if(ssl->loglevel) printf("sqSetupSSL: No root CA given; using default verify paths\n");
	if(SSL_CTX_set_default_verify_paths(ssl->ctx) <=0)
		ERR_print_errors_fp(stderr);

	if(ssl->loglevel) printf("sqSetupSSL: Creating SSL\n");
	ssl->ssl = SSL_new(ssl->ctx);
	if(ssl->loglevel) printf("sqSetupSSL: setting bios\n");
	SSL_set_bio(ssl->ssl, ssl->bioRead, ssl->bioWrite);
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

	SSL_library_init();
	SSL_load_error_strings();

	ssl = calloc(1, sizeof(sqSSL));
	ssl->bioRead = BIO_new(BIO_s_mem());
	ssl->bioWrite = BIO_new(BIO_s_mem());
	BIO_set_close(ssl->bioRead, BIO_CLOSE);
	BIO_set_close(ssl->bioWrite, BIO_CLOSE);
	
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

	if(ssl->ctx) SSL_CTX_free(ssl->ctx);

	if(ssl->ssl) { 
		SSL_free(ssl->ssl); // This will also free bioRead and bioWrite
	} else {
		// SSL_new didn't get called, have to free bioRead and bioWrite manually
		BIO_free_all(ssl->bioRead);
		BIO_free_all(ssl->bioWrite);
	}

	if(ssl->certName) free(ssl->certName);
	if(ssl->peerName) free(ssl->peerName);
	if(ssl->serverName) free(ssl->serverName);

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
	int result, n;
	char peerName[256];
	X509 *cert;
	sqSSL *ssl = sslFromHandle(handle);

	if(ssl->loglevel) printf("sqConnectSSL: %p\n", ssl);

	/* Verify state of session */
	if(ssl == NULL || (ssl->state != SQSSL_UNUSED && ssl->state != SQSSL_CONNECTING)) {
		return SQSSL_INVALID_STATE;
	}

	/* Establish initial connection */
	if(ssl->state == SQSSL_UNUSED) {
		ssl->state = SQSSL_CONNECTING;
		if(ssl->loglevel) print("sqConnectSSL: Setting up SSL\n");
		if(!sqSetupSSL(ssl, 0)) return SQSSL_GENERIC_ERROR;
		if(ssl->loglevel) print("sqConnectSSL: Setting connect state\n");
		SSL_set_connect_state(ssl->ssl);
	}

	if(ssl->loglevel) printf("sqConnectSSL: BIO_write %ld bytes\n", (long)srcLen);

	n = BIO_write(ssl->bioRead, srcBuf, srcLen);

	if(n < srcLen) {
		if(ssl->loglevel) printf("sqConnectSSL: BIO too small for input\n");
		return SQSSL_GENERIC_ERROR; 
	}
	if(n < 0) {
		if(ssl->loglevel) printf("sqConnectSSL: BIO_write failed\n");
		return SQSSL_GENERIC_ERROR;
	}

	/* if a server name is provided, use it */
	if(ssl->serverName) {
		if(ssl->loglevel) printf("sqSetupSSL: Using server name %s\n", ssl->serverName);
		SSL_set_tlsext_host_name(ssl->ssl, ssl->serverName);
	}

	if(ssl->loglevel) printf("sqConnectSSL: SSL_connect\n");
	result = SSL_connect(ssl->ssl);
	if(result <= 0) {
		int error = SSL_get_error(ssl->ssl, result);
		if(error != SSL_ERROR_WANT_READ) {
			if(ssl->loglevel) printf("sqConnectSSL: SSL_connect failed\n");
			ERR_print_errors_fp(stdout);
			return SQSSL_GENERIC_ERROR;
		}
		if(ssl->loglevel) printf("sqConnectSSL: sqCopyBioSSL\n");
		return sqCopyBioSSL(ssl, ssl->bioWrite, dstBuf, dstLen);
	}

	/* We are connected. Verify the cert. */
	ssl->state = SQSSL_CONNECTED;

	if(ssl->loglevel) printf("sqConnectSSL: SSL_get_peer_certificate\n");
	cert = SSL_get_peer_certificate(ssl->ssl);
	if(ssl->loglevel) printf("sqConnectSSL: cert = %p\n", cert);
	/* Fail if no cert received. */
	if(cert) {
		X509_NAME_get_text_by_NID(X509_get_subject_name(cert), 
					NID_commonName, peerName, 
					sizeof(peerName));
		if(ssl->loglevel) printf("sqConnectSSL: peerName = %s\n", peerName);
		ssl->peerName = strndup(peerName, sizeof(peerName) - 1);
		X509_free(cert);

		/* Check the result of verification */
		result = SSL_get_verify_result(ssl->ssl);
		if(ssl->loglevel) printf("sqConnectSSL: SSL_get_verify_result = %d\n", result);
		/* FIXME: Figure out the actual failure reason */
		ssl->certFlags = result ? SQSSL_OTHER_ISSUE : SQSSL_OK;
	} else {
		ssl->certFlags = SQSSL_NO_CERTIFICATE;
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
	int result, n;
	char peerName[256];
	X509 *cert;
	sqSSL *ssl = sslFromHandle(handle);

	/* Verify state of session */
	if(ssl == NULL || (ssl->state != SQSSL_UNUSED && ssl->state != SQSSL_ACCEPTING)) {
		return SQSSL_INVALID_STATE;
	}

	/* Establish initial connection */
	if(ssl->state == SQSSL_UNUSED) {
		ssl->state = SQSSL_ACCEPTING;
		if(ssl->loglevel) printf("sqAcceptSSL: Setting up SSL\n");
		if(!sqSetupSSL(ssl, 1)) return SQSSL_GENERIC_ERROR;
		if(ssl->loglevel) printf("sqAcceptSSL: setting accept state\n");
		SSL_set_accept_state(ssl->ssl);
	}

	if(ssl->loglevel) printf("sqAcceptSSL: BIO_write %ld bytes\n", (long)srcLen);

	n = BIO_write(ssl->bioRead, srcBuf, srcLen);

	if(n < srcLen) {
		if(ssl->loglevel) printf("sqAcceptSSL: BIO_write wrote less than expected\n");
		return SQSSL_GENERIC_ERROR; 
	}
	if(n < 0) {
		if(ssl->loglevel) printf("sqAcceptSSL: BIO_write failed\n");
		return SQSSL_GENERIC_ERROR;
	}

	if(ssl->loglevel) printf("sqAcceptSSL: SSL_accept\n");
	result = SSL_accept(ssl->ssl);

	if(result <= 0) {
		int count = 0;
		int error = SSL_get_error(ssl->ssl, result);
		if(error != SSL_ERROR_WANT_READ) {
			if(ssl->loglevel) printf("sqAcceptSSL: SSL_accept failed\n");
			ERR_print_errors_fp(stdout);
			return SQSSL_GENERIC_ERROR;
		}
		if(ssl->loglevel) printf("sqAcceptSSL: sqCopyBioSSL\n");
		count = sqCopyBioSSL(ssl, ssl->bioWrite, dstBuf, dstLen);
		return count ? count : SQSSL_NEED_MORE_DATA;
	}

	/* We are connected. Verify the cert. */
	ssl->state = SQSSL_CONNECTED;

	if(ssl->loglevel) printf("sqAcceptSSL: SSL_get_peer_certificate\n");
	cert = SSL_get_peer_certificate(ssl->ssl);
	if(ssl->loglevel) printf("sqAcceptSSL: cert = %p\n", cert);

	if(cert) {
		X509_NAME_get_text_by_NID(X509_get_subject_name(cert), 
					NID_commonName, peerName, 
					sizeof(peerName));
		if(ssl->loglevel) printf("sqAcceptSSL: peerName = %s\n", peerName);
		ssl->peerName = strndup(peerName, sizeof(peerName) - 1);
		X509_free(cert);

		/* Check the result of verification */
		result = SSL_get_verify_result(ssl->ssl);
		if(ssl->loglevel) printf("sqAcceptSSL: SSL_get_verify_result = %d\n", result);
		/* FIXME: Figure out the actual failure reason */
		ssl->certFlags = result ? SQSSL_OTHER_ISSUE : SQSSL_OK;
	} else {
		ssl->certFlags = SQSSL_NO_CERTIFICATE;
	}
	return sqCopyBioSSL(ssl, ssl->bioWrite, dstBuf, dstLen);
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
	int nbytes;
	sqSSL *ssl = sslFromHandle(handle);

	if(ssl == NULL || ssl->state != SQSSL_CONNECTED) return SQSSL_INVALID_STATE;

	if(ssl->loglevel) printf("sqEncryptSSL: Encrypting %ld bytes\n", (long)srcLen);

	nbytes = SSL_write(ssl->ssl, srcBuf, srcLen);
	if(nbytes != srcLen) return SQSSL_GENERIC_ERROR;
	return sqCopyBioSSL(ssl, ssl->bioWrite, dstBuf, dstLen);
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
	int nbytes;
	sqSSL *ssl = sslFromHandle(handle);

	if(ssl == NULL || ssl->state != SQSSL_CONNECTED) return SQSSL_INVALID_STATE;

	nbytes = BIO_write(ssl->bioRead, srcBuf, srcLen);
	if(nbytes != srcLen) return SQSSL_GENERIC_ERROR;
	nbytes = SSL_read(ssl->ssl, dstBuf, dstLen);
	if(nbytes <= 0) {
		int error = SSL_get_error(ssl->ssl, nbytes);
		if(error != SSL_ERROR_WANT_READ && error != SSL_ERROR_ZERO_RETURN) {
			return SQSSL_GENERIC_ERROR;
		}
		nbytes = 0;
	}
	return nbytes;
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
		case SQSSL_PROP_PEERNAME:	return ssl->peerName;
		case SQSSL_PROP_CERTNAME:	return ssl->certName;
		case SQSSL_PROP_SERVERNAME:	return ssl->serverName;
		default:
			if(ssl->loglevel) printf("sqGetStringPropertySSL: Unknown property ID %d\n", propID);
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

	if(ssl == NULL) return 0;

	if(propLen) {
		property = strndup(propName, propLen);
	};

	if(ssl->loglevel) printf("sqSetStringPropertySSL(%d): %s\n", propID, property ? property : "(null)");

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
			if(property) free(property);
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
sqInt sqGetIntPropertySSL(sqInt handle, sqInt propID) {
	sqSSL *ssl = sslFromHandle(handle);

	if(ssl == NULL) return 0;
	switch(propID) {
		case SQSSL_PROP_SSLSTATE: return ssl->state;
		case SQSSL_PROP_CERTSTATE: return ssl->certFlags;
		case SQSSL_PROP_VERSION: return SQSSL_VERSION;
		case SQSSL_PROP_LOGLEVEL: return ssl->loglevel;
		default:
			if(ssl->loglevel) printf("sqGetIntPropertySSL: Unknown property ID %ld\n", (long)propID);
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
			if(ssl->loglevel) printf("sqSetIntPropertySSL: Unknown property ID %ld\n", (long)propID);
			return 0;
	}
	return 1;
}
