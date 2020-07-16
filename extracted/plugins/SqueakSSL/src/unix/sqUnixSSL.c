/* -*- mode: c; -*- */

#include "sq.h"
#include "SqueakSSL.h"

#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/x509v3.h>

#include <strings.h>
#include <string.h>
#include <stddef.h>
#include <stdbool.h>

#include <arpa/inet.h>

#include <sys/param.h>

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


#include "pharovm/debug.h"

static sqSSL **handleBuf = NULL;
static sqInt handleMax = 0;


#define MAX_HOSTNAME_LENGTH 253
enum sqMatchResult {
	MATCH_FOUND = 1, // matches OpenSSL X509_check_host
	NO_MATCH_DONE_YET = -1,
	NO_MATCH_FOUND = 0, // matches OpenSSL X509_check_host
	INVALID_IP_STRING = -2, // matches OpenSSL X509_check_ip_asc
	NO_SAN_PRESENT = -3
};

static char* emptyString = "";

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

	logTrace("sqCopyBioSSL: %d bytes pending; buffer size %ld\n",
				nbytes, (long)dstLen);
	if(nbytes > dstLen) return -1;
	return BIO_read(bio, dstBuf, dstLen);
}


enum sqMatchResult sqVerifyIP(sqSSL* ssl, X509* cert, const char* serverName, const size_t serverNameLength);
enum sqMatchResult sqVerifyDNS(sqSSL* ssl, X509* cert, const char* serverName, const size_t serverNameLength);
enum sqMatchResult sqVerifyNameInner(sqSSL* ssl, X509* cert, const void* serverName, const size_t serverNameLength, const int matchType);
char* sqVerifyFindStar(char* sANData, size_t sANDataSize);
sqInt sqVerifySAN(sqSSL* ssl, const GENERAL_NAME* sAN, const void* data, const size_t dataSizeIn, const int matchType);

enum sqMatchResult sqVerifyIP(sqSSL* ssl, X509* cert, const char* serverName, const size_t serverNameLength) {
	struct in6_addr addr = { 0 }; // placeholder, longest of in_addr and in6_addr
	int af = AF_INET6;
	size_t addrSize = sizeof(struct in6_addr);
	int strToAddrWorked = 0;

	if (serverName == NULL) { return INVALID_IP_STRING; }
	if (memchr(serverName, '.', MIN(INET_ADDRSTRLEN, serverNameLength))) {
		// there's a dot somewhere in the first bytes, look for IPV4
		af = AF_INET;
		addrSize = sizeof(struct in_addr);
	}
	strToAddrWorked = inet_pton(af, serverName, &addr);
	if (strToAddrWorked != 1) { return INVALID_IP_STRING; }

	return sqVerifyNameInner(ssl, cert, &addr, addrSize, GEN_IPADD);
}


enum sqMatchResult sqVerifyDNS(sqSSL* ssl, X509* cert, const char* serverName, const size_t serverNameLength) {
	return sqVerifyNameInner(ssl, cert, serverName, serverNameLength, GEN_DNS);
}

enum sqMatchResult sqVerifyNameInner(sqSSL* ssl, X509* cert, const void* serverName, const size_t serverNameLength, const int matchType) {
	enum sqMatchResult matchFound = NO_MATCH_FOUND;

	STACK_OF(GENERAL_NAME)* sANs = X509_get_ext_d2i(cert, NID_subject_alt_name, NULL, NULL);
	if (!sANs) {
		logTrace("sqVerifyNameInner: No sAN names\n");
		matchFound = NO_SAN_PRESENT;
	} else {
		int i = 0;
		int sANCount = sk_GENERAL_NAME_num(sANs);
		for (i = 0; i < sANCount && matchFound != MATCH_FOUND; ++i) {
			const GENERAL_NAME* sAN = sk_GENERAL_NAME_value(sANs, i);
			if ((sAN->type == matchType) &&
			    sqVerifySAN(ssl, sAN, serverName, serverNameLength, matchType)) {
				matchFound = MATCH_FOUND;
				break;
			}
		}
		sk_pop_free(sANs, sk_free);
	}
	return matchFound;
}

char* sqVerifyFindStar(char* sANData, size_t sANDataSize) {
	ptrdiff_t starPosition = 0;
	char* safeptr = NULL;
	char* label = NULL;
	int starFound = 0;
	size_t labelCount = 0;
	char ptr[MAX_HOSTNAME_LENGTH + 1] = {0};
	memcpy(ptr, sANData, MIN(MAX_HOSTNAME_LENGTH + 1, sANDataSize));

#define FAIL_STAR(x) do { if (x) { return NULL; } } while (0)

	for (label = strtok_r(ptr, ".", &safeptr);
	     label != NULL;
	     label = strtok_r(NULL, ".", &safeptr), labelCount++) {
		char* currentStar = strchr(label, '*'); // \0-termination is guaranteed by strtok_r
		size_t labelLength = strlen(label);  // \0-termination is guaranteed by strtok_r
		if (currentStar != NULL) {
			// only one star per label
			FAIL_STAR(labelLength > 1 && (NULL != strchr(currentStar + 1, '*')));
			// only one star per pattern
			FAIL_STAR(starFound);
			// cannot match partial idna
			FAIL_STAR(0 == strncasecmp(label, "xn--", MIN(labelLength, 4)));
			// star not permissible in non-leftmost label
			FAIL_STAR(labelCount >= 1);

			// first label, star is ok.
			starFound = 1;
			starPosition = currentStar - ptr;
		}
	}
	// no star found, nothing to report
	FAIL_STAR(!starFound);
	// star in last two labels
	FAIL_STAR(labelCount < 3);
	return sANData + starPosition;
#undef FAIL_STAR
}

sqInt sqVerifySAN(sqSSL* ssl, const GENERAL_NAME* sAN, const void* data, const size_t dataSizeIn, const int matchType) {

	char* sANData = ASN1_STRING_data(sAN->d.ia5);
	size_t sANDataSize = (size_t) ASN1_STRING_length(sAN->d.ia5);
	size_t dataSize = dataSizeIn;

	logTrace("sqVerifyNameInner: checking sAN %.*s\n", matchType == GEN_DNS ? (int) sANDataSize : 5 , matchType == GEN_DNS ? sANData : "an IP");
	// For IPs, exact match only.
	if (matchType == GEN_IPADD) {
		return (sANDataSize == dataSize) && !memcmp(sANData, data, sANDataSize);
	}

	// Normalize dns names by dropping traling dots if any
	if (sANData[sANDataSize - 1] == '.') { sANDataSize--; }
	if (((char*)data)[dataSize - 1] == '.') { dataSize--; }

#define NOPE(x) do { if ((x)) return 0; } while (0)
#define YEAH(x) do { if ((x)) return 1; } while (0)

	// Exact match always wins
	YEAH((sANDataSize == dataSize) && (0 == strncasecmp(sANData, data, sANDataSize)));
	// wildcard matching not for IPs et al.
	NOPE(matchType != GEN_DNS);

	// Malformed DNS name
	NOPE(sANDataSize != strnlen(sANData, sANDataSize));

	{
		char* serverName = (char*) data;
		size_t serverNameSize = dataSize;
		char* starPosition = NULL;
		char* sANDataSuffix = NULL;
		char* serverNameSuffix = NULL;
		ptrdiff_t prefixLength = 0;
		ptrdiff_t suffixLength = 0;
		ptrdiff_t matchLength = 0;

		// Contrary to general certificate machting, we are only
		// interested in setting up an SSL connection, so we do _NOT_
		// allow data (aka serverNames) that start with a '.'
		NOPE(serverName[0] == '.');

		starPosition = sqVerifyFindStar(sANData, sANDataSize);
		// Since exact matches are already covered and we excluded
		// leading '.' in the server name, we bail if no _valid_ star
		// found in the sAN data here.
		NOPE(starPosition == NULL);

		prefixLength = starPosition - sANData;
		suffixLength = (sANData + sANDataSize - 1) - starPosition;
		matchLength = serverNameSize - (suffixLength + prefixLength);
		sANDataSuffix = starPosition + 1;
		serverNameSuffix = serverName + serverNameSize - suffixLength;

		// check that prefix matches.
		NOPE(0 != strncasecmp(sANData, serverName, (size_t) prefixLength));
		// check that suffix matches
		NOPE(0 != strncasecmp(sANDataSuffix, serverNameSuffix, (size_t) suffixLength));
		// complete star labels (*.example.com) must match at least one character
		NOPE(prefixLength == 0 && sANDataSuffix[0] == '.' && matchLength < 1);
		// no more than one serverName label can match the star -> cannot contain periods
		NOPE(matchLength > 0 && (NULL != memchr(serverName + prefixLength, '.', matchLength )));
	}
	return 1;
#undef NOPE
#undef YEAH
}

/* sqSetupSSL: Common SSL setup tasks */
sqInt sqSetupSSL(sqSSL *ssl, int server) {
	/* Fixme. Needs to use specified version */
	logTrace("sqSetupSSL: setting method\n");

	ssl->method = (SSL_METHOD*) SSLv23_method();

	logTrace("sqSetupSSL: Creating context\n");
	ssl->ctx = SSL_CTX_new(ssl->method);
	logTrace("sqSetupSSL: Disabling SSLv2 and SSLv3\n");
	SSL_CTX_set_options(ssl->ctx, SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3);

	if(!ssl->ctx) ERR_print_errors_fp(stdout);

	logTrace("sqSetupSSL: setting cipher list\n");
	SSL_CTX_set_cipher_list(ssl->ctx, "!ADH:HIGH:MEDIUM:@STRENGTH");

	/* if a cert is provided, use it */
	if(ssl->certName) {
		logTrace("sqSetupSSL: Using cert file %s\n", ssl->certName);

        if(SSL_CTX_use_certificate_file(ssl->ctx, ssl->certName, SSL_FILETYPE_PEM)<=0) {
			ERR_print_errors_fp(stderr);
		}
		if(SSL_CTX_use_PrivateKey_file(ssl->ctx, ssl->certName, SSL_FILETYPE_PEM)<=0) {
			ERR_print_errors_fp(stderr);
		}
	}

	/* Set up trusted CA */
	logTrace("sqSetupSSL: No root CA given; using default verify paths\n");
	if(SSL_CTX_set_default_verify_paths(ssl->ctx) <=0)
		ERR_print_errors_fp(stderr);

	logTrace("sqSetupSSL: Creating SSL\n");
	ssl->ssl = SSL_new(ssl->ctx);
	logTrace("sqSetupSSL: setting bios\n");
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
	int result;
	char peerName[MAX_HOSTNAME_LENGTH + 1];
	X509 *cert;
	sqSSL *ssl = sslFromHandle(handle);

	logTrace("sqConnectSSL: %p\n", ssl);

	/* Verify state of session */
	if(ssl == NULL || (ssl->state != SQSSL_UNUSED && ssl->state != SQSSL_CONNECTING)) {
		return SQSSL_INVALID_STATE;
	}

	/* Establish initial connection */
	if(ssl->state == SQSSL_UNUSED) {
		ssl->state = SQSSL_CONNECTING;
		logTrace("sqConnectSSL: Setting up SSL\n");
		if(!sqSetupSSL(ssl, 0)) return SQSSL_GENERIC_ERROR;
		logTrace("sqConnectSSL: Setting connect state\n");
		SSL_set_connect_state(ssl->ssl);
	}

	logTrace("sqConnectSSL: BIO_write %ld bytes\n", (long)srcLen);


	if(srcLen > 0) {
		int n = BIO_write(ssl->bioRead, srcBuf, srcLen);

		if(n < srcLen) {
			logTrace("sqConnectSSL: BIO too small for input\n");
			return SQSSL_GENERIC_ERROR;
		}
		if(n < 0) {
			logTrace("sqConnectSSL: BIO_write failed\n");
				return SQSSL_GENERIC_ERROR;
		}
	}

	/* if a server name is provided, use it */
	if(ssl->serverName) {
		logTrace("sqSetupSSL: Using server name %s\n", ssl->serverName);
		SSL_set_tlsext_host_name(ssl->ssl, ssl->serverName);
	}

	logTrace("sqConnectSSL: SSL_connect\n");
	result = SSL_connect(ssl->ssl);
	if(result <= 0) {
		int error = SSL_get_error(ssl->ssl, result);
		if(error != SSL_ERROR_WANT_READ) {
			logTrace("sqConnectSSL: SSL_connect failed\n");
			ERR_print_errors_fp(stdout);
			return SQSSL_GENERIC_ERROR;
		}
		logTrace("sqConnectSSL: sqCopyBioSSL\n");
		return sqCopyBioSSL(ssl, ssl->bioWrite, dstBuf, dstLen);
	}

	/* We are connected. Verify the cert. */
	ssl->state = SQSSL_CONNECTED;

	logTrace("sqConnectSSL: SSL_get_peer_certificate\n");
	cert = SSL_get_peer_certificate(ssl->ssl);
	logTrace("sqConnectSSL: cert = %p\n", cert);
	/* Fail if no cert received. */
	if(cert) {
		/*
		 * Verify that peer is the one we expect (by name, via cert)
		 *
		 * Note, this goes beyond checking the commonName:
		 * 1. If cert has sAN of dNSName type it MUST be used (even if
		 *	cn is present)
		 * 2. Cert w/o sAN (and cn only)  is DEPRECATED
		 * 3. Cert has multiple sAN/dNSName, anyone SHALL match
		 * 4. Wildcard match have several restrictions (cf RFCs 6125,
		 *	2181, 2595, or Microsoft doc 258858)
		 * 5. IP Addresses MUST be of type iPAddress, NOT dNSName
		 *
		 * Due to 4., name checking is not as simple as
		 *	"certificateName match: * peerName" on the image side.
		 *
		 * To allow image side reaction to server-name matches we
		 *	**copy the `serverName` into the `peerName` property.
		 *	Thus, the image side can check as
		 *
				peerNameMatches
					^ self peerName = self serverName
		 *
		 * or likewise.
		 */
		enum sqMatchResult matched = NO_MATCH_DONE_YET;
		if (ssl->peerName) { free(ssl->peerName); }
		ssl->peerName = NULL;

		if (ssl->serverName) {
			const size_t serverNameLength = strnlen(ssl->serverName, MAX_HOSTNAME_LENGTH);
                        if (X509_check_ip_asc && X509_check_host) {
				logTrace("sqConnectSSL: X509_check_host.");
				/* Try IP first, expect INVALID_IP_STRING to continue with hostname */
				matched = (enum sqMatchResult) X509_check_ip_asc(cert, ssl->serverName, 0);
				if (matched == INVALID_IP_STRING) {
					matched = (enum sqMatchResult) X509_check_host(cert, ssl->serverName, serverNameLength, X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS, NULL);
				}
			} else {
				matched = sqVerifyIP(ssl, cert, ssl->serverName, serverNameLength);
				if (matched == INVALID_IP_STRING) {
					matched = sqVerifyDNS(ssl, cert, ssl->serverName, serverNameLength);
				}
			}
			if (matched == MATCH_FOUND) {
				logTrace("sqConnectSSL: check hostname OK\n");
				ssl->peerName = strndup(ssl->serverName, serverNameLength);
			} else {
				logTrace("sqConnectSSL: check hostname NOT OK\n");
			}
		}
		// fallback for missing sAN or non-provided serverName
		if (matched == NO_MATCH_DONE_YET || matched == NO_SAN_PRESENT) {
			X509_NAME_get_text_by_NID(X509_get_subject_name(cert),
						      NID_commonName, peerName,
						      sizeof(peerName));
			logTrace("sqConnectSSL: peerName = %s\n", peerName);
			ssl->peerName = strndup(peerName, sizeof(peerName) - 1);
		}
		X509_free(cert);

		/* Check the result of verification */
		result = SSL_get_verify_result(ssl->ssl);
		logTrace("sqConnectSSL: SSL_get_verify_result = %d\n", result);
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
	int result;
	char peerName[MAX_HOSTNAME_LENGTH + 1];
	X509 *cert;
	sqSSL *ssl = sslFromHandle(handle);

	/* Verify state of session */
	if(ssl == NULL || (ssl->state != SQSSL_UNUSED && ssl->state != SQSSL_ACCEPTING)) {
		return SQSSL_INVALID_STATE;
	}

	/* Establish initial connection */
	if(ssl->state == SQSSL_UNUSED) {
		ssl->state = SQSSL_ACCEPTING;
		logTrace("sqAcceptSSL: Setting up SSL\n");
		if(!sqSetupSSL(ssl, 1)) return SQSSL_GENERIC_ERROR;
		logTrace("sqAcceptSSL: setting accept state\n");
		SSL_set_accept_state(ssl->ssl);
	}

	logTrace("sqAcceptSSL: BIO_write %ld bytes\n", (long)srcLen);

	if(srcLen > 0) {
		int n = BIO_write(ssl->bioRead, srcBuf, srcLen);

		if(n < srcLen) {
			logTrace("sqAcceptSSL: BIO_write wrote less than expected\n");
			return SQSSL_GENERIC_ERROR;
		}
		if(n < 0) {
			logTrace("sqAcceptSSL: BIO_write failed\n");
			return SQSSL_GENERIC_ERROR;
		}
	}

	logTrace("sqAcceptSSL: SSL_accept\n");
	result = SSL_accept(ssl->ssl);

	if(result <= 0) {
		int count = 0;
		int error = SSL_get_error(ssl->ssl, result);
		if(error != SSL_ERROR_WANT_READ) {
			logTrace("sqAcceptSSL: SSL_accept failed\n");
			ERR_print_errors_fp(stdout);
			return SQSSL_GENERIC_ERROR;
		}
		logTrace("sqAcceptSSL: sqCopyBioSSL\n");
		count = sqCopyBioSSL(ssl, ssl->bioWrite, dstBuf, dstLen);
		return count ? count : SQSSL_NEED_MORE_DATA;
	}

	/* We are connected. Verify the cert. */
	ssl->state = SQSSL_CONNECTED;

	logTrace("sqAcceptSSL: SSL_get_peer_certificate\n");
	cert = SSL_get_peer_certificate(ssl->ssl);
	logTrace("sqAcceptSSL: cert = %p\n", cert);

	if(cert) {
		X509_NAME_get_text_by_NID(X509_get_subject_name(cert),
					      NID_commonName, peerName,
					      sizeof(peerName));
		logTrace("sqAcceptSSL: peerName = %s\n", peerName);
		ssl->peerName = strndup(peerName, sizeof(peerName) - 1);
		X509_free(cert);

		/* Check the result of verification */
		result = SSL_get_verify_result(ssl->ssl);
		logTrace("sqAcceptSSL: SSL_get_verify_result = %d\n", result);
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

	logTrace("sqEncryptSSL: Encrypting %ld bytes\n", (long)srcLen);

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

	if (srcLen > 0) {
		nbytes = BIO_write(ssl->bioRead, srcBuf, srcLen);
		if(nbytes != srcLen) {
			logTrace("sqDecryptSSL: Only wrote %ld bytes\n", (long)nbytes);
			return SQSSL_GENERIC_ERROR;
		}
	}
	nbytes = SSL_read(ssl->ssl, dstBuf, dstLen);
	if(nbytes <= 0) {
		int error = SSL_get_error(ssl->ssl, nbytes);
		if(
			error != SSL_ERROR_WANT_READ &&
			error != SSL_ERROR_ZERO_RETURN &&
			error != SSL_ERROR_WANT_X509_LOOKUP
		) {
			logTrace("sqDecryptSSL: Got error %d\n", error);
			return SQSSL_GENERIC_ERROR;
		}
		nbytes = 0;
	} else {
		logTrace("sqDecryptSSL: Decrypted %ld bytes\n", (long)nbytes);
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
		case SQSSL_PROP_PEERNAME:	return ssl->peerName ? ssl->peerName : emptyString;
		case SQSSL_PROP_CERTNAME:	return ssl->certName;
		case SQSSL_PROP_SERVERNAME:	return ssl->serverName;
		default:
			logTrace("sqGetStringPropertySSL: Unknown property ID %d\n", propID);
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

	logTrace("sqSetStringPropertySSL(%d): %s\n", propID, property ? property : "(null)");

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
sqInt sqGetIntPropertySSL(sqInt handle, sqInt propID) {
	sqSSL *ssl = sslFromHandle(handle);

	if(ssl == NULL) return 0;
	switch(propID) {
		case SQSSL_PROP_SSLSTATE: return ssl->state;
		case SQSSL_PROP_CERTSTATE: return ssl->certFlags;
		case SQSSL_PROP_VERSION: return SQSSL_VERSION;
		case SQSSL_PROP_LOGLEVEL: return ssl->loglevel;
		default:
			logTrace("sqGetIntPropertySSL: Unknown property ID %ld\n", (long)propID);
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
			logTrace("sqSetIntPropertySSL: Unknown property ID %ld\n", (long)propID);
			return 0;
	}
	return 1;
}
