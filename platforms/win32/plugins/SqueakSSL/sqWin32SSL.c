/****************************************************************************
*   PROJECT: SqueakSSL implementation for Windows
*   FILE:    sqWin32SSL.c
*   CONTENT: SSL platform functions
*
*   AUTHORS:  Andreas Raab (ar)
*
*             Marcel Taeumel (mt)
*               Hasso Plattner Institute, Postdam, Germany
*             Tobias Pape (topa)
*               Hasso Plattner Institute, Postdam, Germany
*****************************************************************************/

#include <windows.h>
#include <errno.h>
#include <malloc.h>

#include "sq.h"
#include "SqueakSSL.h"

#define SECURITY_WIN32
#include <security.h>
#include <schannel.h>
#include <wincrypt.h>

typedef struct sqSSL {
	int state;
	int certFlags;
	int loglevel;

	char *certName;
	char *peerName;
	char *serverName;

	CredHandle sslCred;
	CtxtHandle sslCtxt;
	
	SecBufferDesc sbdIn;
	SecBufferDesc sbdOut;
	SecBuffer inbuf[4];
	SecBuffer outbuf[4];

	/* internal data buffer */
	char *dataBuf;
	int dataLen;
	int dataMax;

	SecPkgContext_StreamSizes sslSizes;
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


/* sqPrintSBD: Prints a SecurityBuffer for debugging */
static void sqPrintSBD(char *title, SecBufferDesc sbd) {
	unsigned int i;
	printf("%s\n", title);
	for(i=0; i<sbd.cBuffers; i++) {
		SecBuffer *buf = sbd.pBuffers + i;
		printf("\tbuf[%d]: %d (%d bytes) ptr=%x\n", i,buf->BufferType, buf->cbBuffer, (int)buf->pvBuffer);
	}
}

/* sqCopyExtraData: Retains any SECBUFFER_EXTRA data. */
static void sqCopyExtraData(sqSSL *ssl, SecBufferDesc sbd) {
	unsigned int i;
	if(sbd.pBuffers[0].BufferType == SECBUFFER_MISSING) {
		if(ssl->loglevel) printf("sqCopyExtra: Encountered SECBUFFER_MISSING; retaining %d bytes\n", ssl->dataLen);
		return;
	}
	ssl->dataLen = 0;
	for(i=0; i<sbd.cBuffers; i++) {
		SecBuffer *buf = sbd.pBuffers + i;
		if(buf->BufferType == SECBUFFER_EXTRA) {
			int count = buf->cbBuffer;
			char *srcPtr = buf->pvBuffer;
			char *dstPtr = ssl->dataBuf + ssl->dataLen;
			if(ssl->loglevel) printf("sqCopyExtraData: Retaining %d bytes\n", count);
			/* I *think* the extra buffers are always in input range.
			   Make sure that's the case or at least report it if not. */
			if(srcPtr < dstPtr || (srcPtr + count) > (ssl->dataBuf + ssl->dataMax)) {
				if(ssl->loglevel) printf("sqCopyExtraDataSSL: Encountered out-of-range extra buffer\n");
			}
			if(srcPtr != dstPtr) {
				/* memmove() not memcpy() since the memory mayoverlap */
				memmove(dstPtr, srcPtr, count);
			}
			ssl->dataLen += count;
		}
	}
}

/* Copies the data from a SecBufferDesc to dstBuf */
static sqInt sqCopyDescToken(sqSSL *ssl, SecBufferDesc sbd, char *dstBuf, sqInt dstLen) {
	unsigned int i;
	int result = 0;

	if(ssl->loglevel) printf("sqCopyDescToken: \n");
	for(i = 0; i < sbd.cBuffers; i++) {
		SecBuffer *buf = sbd.pBuffers + i;
		if(ssl->loglevel) printf("\t type=%d, size=%d\n", buf->BufferType, buf->cbBuffer);
		if(buf->BufferType == SECBUFFER_TOKEN) {
			int count = buf->cbBuffer;
			if(count > dstLen) return SQSSL_BUFFER_TOO_SMALL;
			memcpy(dstBuf, buf->pvBuffer, count);
			result += count;
			dstBuf += count;
			dstLen -= count;
			FreeContextBuffer(buf->pvBuffer);
		}
		if(buf->BufferType == SECBUFFER_EXTRA) {
			/* XXXX: Preserve contents for the next round */
			if(ssl->loglevel) printf("sqCopyDescToken: Unexpectedly encountered SECBUFFER_EXTRA\n");
		}
	}
	return result;
}

/* Set up the local certificate for SSL */
#define MAX_NAME_SIZE 4096
static sqInt sqSetupCert(sqSSL *ssl, char *certName, int server) {
	SCHANNEL_CRED sc_cred = { 0 };
	SECURITY_STATUS ret;
	HCERTSTORE hStore;
	PCCERT_CONTEXT pContext = NULL;
	DWORD dwPropSize;
	WCHAR wFriendlyName[MAX_NAME_SIZE];
	char  bFriendlyName[MAX_NAME_SIZE];

	if(certName) {
		hStore = CertOpenSystemStore(0, L"MY");
		if(!hStore) {
			if(ssl->loglevel) printf("sqSetupCert: CertOpenSystemStore failed\n");
			return 0;
		}
		pContext = NULL;

		/* Enumerate the certificate store to find the cert with the given friendly name */
		while(pContext = CertEnumCertificatesInStore(hStore, pContext)) {
			if(ssl->loglevel) printf("Checking certificate: ");
			dwPropSize = MAX_NAME_SIZE * sizeof(WCHAR);
			if(!CertGetCertificateContextProperty(pContext, CERT_FRIENDLY_NAME_PROP_ID, wFriendlyName, &dwPropSize)) {
				if(ssl->loglevel) printf("<no friendly name>");
				continue;
			}
			if(!WideCharToMultiByte(CP_UTF8, 0, wFriendlyName, -1, bFriendlyName, MAX_NAME_SIZE, NULL, NULL)) {
				if(ssl->loglevel) printf("<utf-8 conversion failure>");
				continue;
			}
			if(ssl->loglevel) printf("%s\n", bFriendlyName);
			if(strcmp(certName, bFriendlyName) == 0) break;
		}

		if(pContext == 0) {
			/* For compatibility with older versions of SqueakSSL, attempt to match against subject string */
			pContext = CertFindCertificateInStore(hStore, X509_ASN_ENCODING | PKCS_7_ASN_ENCODING,
												  0, CERT_FIND_SUBJECT_STR_A, certName, NULL);
		}

		if(!pContext) {
			if(ssl->loglevel) printf("sqSetupCert: No suitable certificate  found\n");
			CertCloseStore(hStore, 0);
			return 0;
		}
	}

	sc_cred.dwVersion = SCHANNEL_CRED_VERSION;
	sc_cred.dwFlags = SCH_CRED_NO_DEFAULT_CREDS | SCH_CRED_MANUAL_CRED_VALIDATION;
	sc_cred.grbitEnabledProtocols = server ? SP_PROT_TLS1_SERVER | SP_PROT_SSL3_SERVER : 0;
	sc_cred.dwMinimumCipherStrength = 0;
	sc_cred.dwMaximumCipherStrength = 0;

	if(pContext) {
		sc_cred.cCreds = 1;
		sc_cred.paCred = &pContext;
	} else {
		sc_cred.cCreds = 0;
	}

	ret = AcquireCredentialsHandle(NULL, UNISP_NAME, 
									server ? SECPKG_CRED_INBOUND : SECPKG_CRED_OUTBOUND, 
									NULL, &sc_cred, NULL, NULL, &ssl->sslCred, NULL);
	if(ssl->loglevel) printf("AquireCredentialsHandle returned: %x\n", ret);

	if(pContext) {
		CertCloseStore(hStore, 0);
	    CertFreeCertificateContext(pContext);
	}

	if (ret != SEC_E_OK) {
		if(ssl->loglevel) printf("AquireCredentialsHandle error: %x\n", ret);
		return 0;
	}
	return 1;
}

/* sqExtractPeerName: Extract the name from the cert of the remote peer. */
static int sqExtractPeerName(sqSSL *ssl) {
	SECURITY_STATUS ret;
	PCCERT_CONTEXT certHandle = NULL;
	PCERT_NAME_INFO certInfo = NULL;
	PCERT_RDN_ATTR certAttr = NULL;
	DWORD dwSize = 0;
	int cbPeerName = 0;
	LPTSTR tmpBuf = NULL;
	DWORD cchTmpBuf = 0;

	if(ssl->peerName) {
		free(ssl->peerName);
		ssl->peerName = NULL;
	}
	ret = QueryContextAttributes(&ssl->sslCtxt, SECPKG_ATTR_REMOTE_CERT_CONTEXT, (PVOID)&certHandle);
	/* No credentials were provided; can't extract peer name */
	if(ret == SEC_E_NO_CREDENTIALS) return 1;

	if(ret != SEC_E_OK) {
		if(ssl->loglevel) printf("sqExtractPeerName: QueryContextAttributes failed (code = %x)\n", ret);
		return 0;
	}

	/* Extract CN from certificate */
	cchTmpBuf = CertGetNameString(certHandle, CERT_NAME_ATTR_TYPE, 0, szOID_COMMON_NAME, NULL, 0);
	tmpBuf = (LPTSTR)alloca(cchTmpBuf * sizeof(TCHAR));
	CertGetNameString(certHandle, CERT_NAME_ATTR_TYPE, 0, szOID_COMMON_NAME, tmpBuf, cchTmpBuf);

#ifdef _UNICODE
	/* Convert wide to UTF8 */
	cbPeerName = WideCharToMultiByte(CP_UTF8, 0, tmpBuf, -1, NULL, 0, NULL, NULL);
	if (cbPeerName == 0) return 0;
	ssl->peerName = calloc(1, cbPeerName);
	WideCharToMultiByte(CP_UTF8, 0, tmpBuf, -1, ssl->peerName, cbPeerName, NULL, NULL);
#else
	ssl->peerName = _strdup(tmpBuf);
#endif
	
	if(ssl->loglevel) printf("sqExtractPeerName: Peer name is %s\n", ssl->peerName);

	CertFreeCertificateContext(certHandle);

	return 1;
}

/* sqVerifyCert: Verify the validity of the remote certificate */
static int sqVerifyCert(sqSSL *ssl, int isServer) {
	SECURITY_STATUS ret;
	PCCERT_CONTEXT certHandle = NULL;
	PCCERT_CHAIN_CONTEXT chainContext = NULL;
	CERT_CHAIN_PARA chainPara;
	SSL_EXTRA_CERT_CHAIN_POLICY_PARA epp;
	CERT_CHAIN_POLICY_PARA policyPara;
	CERT_CHAIN_POLICY_STATUS policyStatus;
	
	static LPSTR serverUsage[] = {
		szOID_PKIX_KP_SERVER_AUTH,
		szOID_SERVER_GATED_CRYPTO,
		szOID_SGC_NETSCAPE
	};
	static LPSTR clientUsage[] = {
		szOID_PKIX_KP_CLIENT_AUTH
	};
	
	ret = QueryContextAttributes(&ssl->sslCtxt, SECPKG_ATTR_REMOTE_CERT_CONTEXT, (PVOID)&certHandle);
	/* No credentials were provided */
	if(ret == SEC_E_NO_CREDENTIALS) {
		ssl->certFlags = SQSSL_NO_CERTIFICATE;
		return 1;
	}

	memset(&chainPara, 0, sizeof(chainPara));
	chainPara.cbSize = sizeof(chainPara);
	chainPara.RequestedUsage.dwType = USAGE_MATCH_TYPE_OR;
	if(!isServer) {
		chainPara.RequestedUsage.Usage.cUsageIdentifier = 3;
		chainPara.RequestedUsage.Usage.rgpszUsageIdentifier = serverUsage;
	} else {
		chainPara.RequestedUsage.Usage.cUsageIdentifier = 1;
		chainPara.RequestedUsage.Usage.rgpszUsageIdentifier = clientUsage;
	}
	if(!CertGetCertificateChain(NULL, certHandle, NULL,
                                certHandle->hCertStore,
								&chainPara, 0, NULL, &chainContext)) {
		CertFreeCertificateContext(certHandle);
		ssl->certFlags = SQSSL_OTHER_ISSUE;
		goto done;
	}
	
	memset(&epp, 0, sizeof(epp));
	epp.cbSize = sizeof(epp);
	epp.dwAuthType = AUTHTYPE_SERVER;
	epp.fdwChecks = 0;
	epp.pwszServerName = NULL;

	memset(&policyPara, 0, sizeof(policyPara));
	policyPara.cbSize = sizeof(policyPara);
	policyPara.dwFlags = 0;
	policyPara.pvExtraPolicyPara = &epp;
	memset(&policyStatus, 0, sizeof(policyStatus));
	policyStatus.cbSize = sizeof(policyStatus);

	/* We loop here CertVerifyCertificateChainPolicy() returns only a 
	   single error even if there is more than one issue with the cert. */
	ssl->certFlags = 0;
	while(true) {
		if (!CertVerifyCertificateChainPolicy(
           CERT_CHAIN_POLICY_SSL,
           chainContext,
           &policyPara,
           &policyStatus)) {
				ssl->certFlags |= SQSSL_OTHER_ISSUE;
				goto done;
		}
		switch(policyStatus.dwError) {
			case SEC_E_OK:
				goto done;
			case CERT_E_UNTRUSTEDROOT:
				if(ssl->certFlags & SQSSL_UNTRUSTED_ROOT) goto done;
				ssl->certFlags |= SQSSL_UNTRUSTED_ROOT;
				epp.fdwChecks  |= 0x00000100; /* SECURITY_FLAG_IGNORE_UNKNOWN_CA */
				break;
			case CERT_E_EXPIRED:
				if(ssl->certFlags & SQSSL_CERT_EXPIRED) goto done;
				ssl->certFlags |= SQSSL_CERT_EXPIRED;
				epp.fdwChecks  |= 0x00002000;  /* SECURITY_FLAG_IGNORE_CERT_DATE_INVALID */
				break;
			case CERT_E_WRONG_USAGE:
				if(ssl->certFlags & SQSSL_WRONG_USAGE) goto done;
				ssl->certFlags |= SQSSL_WRONG_USAGE;
				epp.fdwChecks  |= 0x00000200;   /* SECURITY_FLAG_IGNORE_WRONG_USAGE */
			case CERT_E_REVOKED:
				if(ssl->certFlags & SQSSL_CERT_REVOKED) goto done;
				ssl->certFlags |= SQSSL_CERT_REVOKED;
				epp.fdwChecks  |= 0x00000080;   /* SECURITY_FLAG_IGNORE_REVOCATION */
				break;
			default:
				ssl->certFlags |= SQSSL_OTHER_ISSUE;
				goto done;
		}
	}
done:
	CertFreeCertificateChain(chainContext);
	CertFreeCertificateContext(certHandle);
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
	sqInt handle;
	sqSSL *ssl = NULL;

	ssl = calloc(1, sizeof(sqSSL));

	ssl->sbdIn.ulVersion = SECBUFFER_VERSION;
	ssl->sbdIn.cBuffers = 4;
	ssl->sbdIn.pBuffers = ssl->inbuf;

	ssl->sbdOut.ulVersion = SECBUFFER_VERSION;
	ssl->sbdOut.cBuffers = 4;
	ssl->sbdOut.pBuffers = ssl->outbuf;

	/* Find a free handle */
	for(handle = 1; handle < handleMax; handle++)
		if(handleBuf[handle] == NULL) break;

	if(handle >= handleMax) {
		const int delta = 100;
		int i;
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

	FreeCredentialsHandle(&ssl->sslCred);
	DeleteSecurityContext(&ssl->sslCtxt);

	if(ssl->certName) free(ssl->certName);
	if(ssl->peerName) free(ssl->peerName);
	if(ssl->serverName) free(ssl->serverName);
	if(ssl->dataBuf) free(ssl->dataBuf);

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
	SecBufferDesc *sbdIn = NULL;
	SECURITY_STATUS ret;
	SCHANNEL_CRED sc_cred = { 0 };
	ULONG sslFlags, retFlags;
	sqSSL *ssl = sslFromHandle(handle);
	LPTSTR serverName = NULL;
	int ccServerName = 0;

	/* Verify state of session */
	if(ssl == NULL || (ssl->state != SQSSL_UNUSED && ssl->state != SQSSL_CONNECTING)) {
		return SQSSL_INVALID_STATE;
	}

	if(ssl->dataLen + srcLen > ssl->dataMax) {
		/* resize the data buffer */
		ssl->dataMax += (srcLen < 4096) ? (4096) : (srcLen+1024);
		ssl->dataBuf = realloc(ssl->dataBuf, ssl->dataMax);
		if (!ssl->dataBuf) return SQSSL_OUT_OF_MEMORY;
	}
	if(ssl->loglevel) 
		printf("sqConnectSSL: input token %d bytes\n", srcLen);
	memcpy(ssl->dataBuf + ssl->dataLen, srcBuf, srcLen);
	ssl->dataLen += srcLen;

	/* Standard flags for SSL connection */
	sslFlags = 
		ISC_REQ_ALLOCATE_MEMORY | ISC_REQ_CONFIDENTIALITY | ISC_REQ_EXTENDED_ERROR |
		ISC_REQ_INTEGRITY | ISC_REQ_REPLAY_DETECT | ISC_REQ_STREAM |
		ISC_REQ_MANUAL_CRED_VALIDATION;

	/* Set up the input and output buffers */
	ssl->inbuf[0].BufferType = SECBUFFER_TOKEN;
	ssl->inbuf[0].cbBuffer = ssl->dataLen;
	ssl->inbuf[0].pvBuffer = ssl->dataBuf;
	ssl->inbuf[1].BufferType = SECBUFFER_EMPTY;
	ssl->inbuf[1].cbBuffer = 0;
	ssl->inbuf[1].pvBuffer = NULL;
	ssl->inbuf[2].BufferType = SECBUFFER_EMPTY;
	ssl->inbuf[2].cbBuffer = 0;
	ssl->inbuf[2].pvBuffer = NULL;
	ssl->inbuf[3].BufferType = SECBUFFER_EMPTY;
	ssl->inbuf[3].cbBuffer = 0;
	ssl->inbuf[3].pvBuffer = NULL;
	ssl->sbdIn.cBuffers = 4;

	ssl->outbuf[0].BufferType = SECBUFFER_EMPTY;
	ssl->outbuf[0].cbBuffer = 0;
	ssl->outbuf[0].pvBuffer = NULL;
	ssl->outbuf[1].BufferType = SECBUFFER_EMPTY;
	ssl->outbuf[1].cbBuffer = 0;
	ssl->outbuf[1].pvBuffer = NULL;
	ssl->sbdOut.cBuffers = 2;

	if(ssl->loglevel) printf("sqConnectSSL: Input to InitSecCtxt is %d bytes\n", ssl->dataLen);

#ifdef _UNICODE
	if(ssl->serverName) {
		ccServerName = MultiByteToWideChar(CP_UTF8, 0, ssl->serverName, -1, NULL, 0);
		if (ccServerName == 0) {
			return SQSSL_GENERIC_ERROR;
		}
		serverName = (LPTSTR)alloca(ccServerName * sizeof(TCHAR));
		if (MultiByteToWideChar(CP_UTF8, 0, ssl->serverName, -1, serverName, ccServerName) == 0) {
			return SQSSL_GENERIC_ERROR;
		}
	}
#else
	if(ssl->serverName) serverName = ssl->serverName;
#endif

	if(ssl->state == SQSSL_UNUSED) {
		ssl->state = SQSSL_CONNECTING;

		if (!sqSetupCert(ssl, ssl->certName, 0)) {
			return SQSSL_GENERIC_ERROR;
		}
		ret = InitializeSecurityContext(&ssl->sslCred, NULL, serverName,
										sslFlags, 0, 0, NULL, 0, &ssl->sslCtxt,
										&ssl->sbdOut, &retFlags, NULL);
	} else {
		ret = InitializeSecurityContext(&ssl->sslCred, &ssl->sslCtxt, serverName,
										sslFlags, 0, 0, &ssl->sbdIn, 0, NULL,
										&ssl->sbdOut, &retFlags, NULL);
	}

	if(ssl->loglevel) printf("InitializeSecurityContext returned: %x\n", ret);

	if(ssl->loglevel) sqPrintSBD("Input Buffers:", ssl->sbdIn);
	if(ssl->loglevel) sqPrintSBD("Output Buffers:", ssl->sbdOut);

	if(ret != SEC_E_OK) {
		int count;
		/* Handle various failure conditions */
		switch(ret) {
			case SEC_E_INCOMPLETE_MESSAGE:
				/* not enough data for the handshake to complete */
				return SQSSL_NEED_MORE_DATA;
			case SEC_I_CONTINUE_NEEDED:
				/* Send contents back to peer and come back with more data */
				count = sqCopyDescToken(ssl, ssl->sbdOut, dstBuf, dstLen);
				/* Sanity checks for buffers */
				if(ssl->inbuf[0].BufferType != SECBUFFER_TOKEN) {
					if(ssl->loglevel) printf("sqConnectSSL: Unexpected buffer[0].BufferType -- %d\n", ssl->inbuf[0].BufferType);
				}
				if(ssl->inbuf[2].BufferType != SECBUFFER_EMPTY) {
					if(ssl->loglevel) printf("sqConnectSSL: Unexpected buffer[2].BufferType -- %d\n", ssl->inbuf[0].BufferType);
				}

				/* If there is SECBUFFER_EXTRA in the input we need to retain it */
				if(ssl->inbuf[1].BufferType == SECBUFFER_EXTRA) {
					int extra = ssl->inbuf[1].cbBuffer;
					if(ssl->loglevel) printf("sqConnectSSL: Retaining %d token bytes\n", extra);
					memmove(ssl->dataBuf, ssl->dataBuf + (ssl->dataLen - extra), extra);
					ssl->dataLen = extra;
				} else ssl->dataLen = 0;
				
				/* Don't return zero (SQSSL_OK) when more data is needed */
				return count ? count : SQSSL_NEED_MORE_DATA;
			default:
				if(ssl->loglevel) printf("Unexpected return code %lu\n", (unsigned long)ret);
				return SQSSL_GENERIC_ERROR;
		}
	}

	/* TODO: Look at retFlags */
	ssl->state = SQSSL_CONNECTED;
	/* If there is SECBUFFER_EXTRA in the input we need to retain it */
	if(ssl->inbuf[1].BufferType == SECBUFFER_EXTRA) {
		int extra = ssl->inbuf[1].cbBuffer;
		if(ssl->loglevel) printf("sqConnectSSL: Retaining %d token bytes\n", extra);
		memmove(ssl->dataBuf, ssl->dataBuf + (ssl->dataLen - extra), extra);
		ssl->dataLen = extra;
	} else {
		sqCopyExtraData(ssl, ssl->sbdOut);
	}
    ret = QueryContextAttributes(&ssl->sslCtxt, SECPKG_ATTR_STREAM_SIZES, &ssl->sslSizes);
	if(ssl->loglevel) printf("sqConnectSSL: Maximum message size is %d bytes\n", ssl->sslSizes.cbMaximumMessage);

	/* Extract the peer name */
	sqExtractPeerName(ssl);

	/* Verify the certificate (sets certFlags) */
	sqVerifyCert(ssl, false);

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
sqInt sqAcceptSSL(sqInt handle, char* srcBuf, sqInt srcLen, char *dstBuf, sqInt dstLen) {
	SECURITY_STATUS ret;
	SCHANNEL_CRED sc_cred = { 0 };
 	ULONG sslFlags, retFlags;
	sqSSL *ssl = sslFromHandle(handle);

	/* Verify state of session */
	if(ssl == NULL || (ssl->state != SQSSL_UNUSED && ssl->state != SQSSL_ACCEPTING)) {
		return SQSSL_INVALID_STATE;
	}

	/* Standard flags for SSL connection */
	sslFlags = 
		ASC_REQ_ALLOCATE_MEMORY | ASC_REQ_CONFIDENTIALITY | ASC_REQ_EXTENDED_ERROR |
		ASC_REQ_INTEGRITY | ASC_REQ_REPLAY_DETECT | ASC_REQ_STREAM;

	ssl->inbuf[0].BufferType = SECBUFFER_TOKEN;
	ssl->inbuf[0].cbBuffer = srcLen;
	ssl->inbuf[0].pvBuffer = srcBuf;
	ssl->inbuf[1].BufferType = SECBUFFER_EMPTY;
	ssl->inbuf[1].cbBuffer = 0;
	ssl->inbuf[1].pvBuffer = NULL;

	ssl->sbdIn.cBuffers = 2;

	ssl->outbuf[0].BufferType = SECBUFFER_EMPTY;
	ssl->outbuf[0].cbBuffer = 0;
	ssl->outbuf[0].pvBuffer = NULL;
	ssl->outbuf[1].BufferType = SECBUFFER_EMPTY;
	ssl->outbuf[1].cbBuffer = 0;
	ssl->outbuf[1].pvBuffer = NULL;

	ssl->sbdOut.cBuffers = 2;

	if(ssl->state == SQSSL_UNUSED) {
		ssl->state = SQSSL_ACCEPTING;

		if(!sqSetupCert(ssl, ssl->certName, 1)) 
			return SQSSL_GENERIC_ERROR;

		ret = AcceptSecurityContext(&ssl->sslCred, NULL, &ssl->sbdIn, sslFlags,
									SECURITY_NATIVE_DREP, &ssl->sslCtxt, &ssl->sbdOut,
									&retFlags, NULL);
	} else {
		ret = AcceptSecurityContext(&ssl->sslCred, &ssl->sslCtxt, &ssl->sbdIn, sslFlags,
									SECURITY_NATIVE_DREP, &ssl->sslCtxt, &ssl->sbdOut,
									&retFlags, NULL);
	}

	if(ssl->loglevel) printf("AcceptSecurityContext returned: %x\n", ret);

	if(ret != SEC_E_OK) {
		/* Handle various failure conditions */
		switch(ret) {
			case SEC_E_INCOMPLETE_MESSAGE:
				/* not enough data for the handshake to complete */
				return SQSSL_NEED_MORE_DATA;
			case SEC_I_CONTINUE_NEEDED:
				/* Send contents back to peer and come back with more data */
				return sqCopyDescToken(ssl, ssl->sbdOut, dstBuf, dstLen);
			default:
				if(ssl->loglevel) printf("Unexpected return code %d\n", ret);
				return SQSSL_GENERIC_ERROR;
		}
	}

	/* TODO: Look at retFlags */
	ssl->state = SQSSL_CONNECTED;
    ret = QueryContextAttributes(&ssl->sslCtxt, SECPKG_ATTR_STREAM_SIZES, &ssl->sslSizes);
	if(ssl->loglevel) printf("sqAcceptSSL: Maximum message size is %d bytes\n", ssl->sslSizes.cbMaximumMessage);

	/* Extract the peer name */
	sqExtractPeerName(ssl);

	/* Verify the certificate (sets certFlags) */
	sqVerifyCert(ssl, true);

	return sqCopyDescToken(ssl, ssl->sbdOut, dstBuf, dstLen);
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
	SECURITY_STATUS ret;
	sqInt total;
	sqSSL *ssl = sslFromHandle(handle);

	if(ssl == NULL || ssl->state != SQSSL_CONNECTED) return SQSSL_INVALID_STATE;

	if(ssl->loglevel) printf("sqEncryptSSL: Encrypting %d bytes\n", srcLen);

	if(srcLen > (int)ssl->sslSizes.cbMaximumMessage) 
		return SQSSL_INPUT_TOO_LARGE;

	ssl->inbuf[0].BufferType = SECBUFFER_STREAM_HEADER;
	ssl->inbuf[0].cbBuffer = ssl->sslSizes.cbHeader;
	ssl->inbuf[0].pvBuffer = dstBuf;

	ssl->inbuf[1].BufferType = SECBUFFER_DATA;
	ssl->inbuf[1].cbBuffer = srcLen;
	ssl->inbuf[1].pvBuffer = dstBuf + ssl->inbuf[0].cbBuffer;

	ssl->inbuf[2].BufferType = SECBUFFER_STREAM_TRAILER;
	ssl->inbuf[2].cbBuffer = ssl->sslSizes.cbTrailer;
	ssl->inbuf[2].pvBuffer = dstBuf + ssl->inbuf[0].cbBuffer + ssl->inbuf[1].cbBuffer;

	ssl->inbuf[3].BufferType = SECBUFFER_EMPTY;
	ssl->inbuf[3].cbBuffer = 0;
	ssl->inbuf[3].pvBuffer = NULL;  

	ssl->sbdIn.cBuffers = 4;

	/* Check to ensure that encrypted contents fits dstBuf.
	   Fail with BUFFER_TOO_SMALL to allow caller to retry. */
	total = ssl->inbuf[0].cbBuffer + ssl->inbuf[1].cbBuffer + ssl->inbuf[2].cbBuffer;
	if(dstLen < total) return SQSSL_BUFFER_TOO_SMALL;

	memcpy(ssl->inbuf[1].pvBuffer, srcBuf, srcLen);

	if(ssl->loglevel) printf("Header: %d; Data: %d; Trailer: %d\n", 
			ssl->inbuf[0].cbBuffer, ssl->inbuf[1].cbBuffer, ssl->inbuf[2].cbBuffer);

	ret = EncryptMessage(&ssl->sslCtxt, 0, &ssl->sbdIn, 0);

	if (ret != SEC_E_OK) {
		if(ssl->loglevel) printf("EncryptMessage returned: %x\n", ret);
		return SQSSL_GENERIC_ERROR;
	}

	/* Return total amount of encrypted contents.
	   Must recompute total here since trailer may be overestimated */
	total = ssl->inbuf[0].cbBuffer + ssl->inbuf[1].cbBuffer + ssl->inbuf[2].cbBuffer;
	return total;
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
	int i, total;
	SECURITY_STATUS ret;
	sqSSL *ssl = sslFromHandle(handle);

	if(ssl == NULL || ssl->state != SQSSL_CONNECTED) return SQSSL_INVALID_STATE;

	/* Workaround for a strange Windows issue: Directly after an SSL handshake
	   has completed, calling DecryptMessage() with empty input can fail with
	   SEC_E_INVALID_TOKEN for no apparent reason. */
	if(!ssl->dataLen && !srcLen) return 0;

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

	ssl->inbuf[0].BufferType = SECBUFFER_DATA;
	ssl->inbuf[0].cbBuffer = ssl->dataLen;
	ssl->inbuf[0].pvBuffer = ssl->dataBuf;

	ssl->inbuf[1].BufferType = SECBUFFER_EMPTY;
	ssl->inbuf[1].cbBuffer = 0;
	ssl->inbuf[1].pvBuffer = NULL;

	ssl->inbuf[2].BufferType = SECBUFFER_EMPTY;
	ssl->inbuf[2].cbBuffer = 0;
	ssl->inbuf[2].pvBuffer = NULL;  

	ssl->inbuf[3].BufferType = SECBUFFER_EMPTY;
	ssl->inbuf[3].cbBuffer = 0;
	ssl->inbuf[3].pvBuffer = NULL;  

	ssl->sbdIn.cBuffers = 4;
	ret = DecryptMessage(&ssl->sslCtxt, &ssl->sbdIn, 0, 0);

	if(ret == SEC_I_CONTEXT_EXPIRED) {
		/* The remote has shut down the ssl session */
		ssl->dataLen = 0;
		return 0;
	}

	/* Copy the result into destination buffer */
	total = 0;
	for(i=0;i<4;i++) {
		int buftype = ssl->inbuf[i].BufferType;
		int count = ssl->inbuf[i].cbBuffer;
		char *buffer = ssl->inbuf[i].pvBuffer;
		if(ssl->loglevel) printf("buf[%d]: %d (%d bytes) ptr=%x\n", i,buftype, count, (int)buffer);
		if(buftype == SECBUFFER_DATA) {
			if(count > dstLen) return SQSSL_BUFFER_TOO_SMALL;
			memcpy(dstBuf, buffer, count);
			dstBuf += count;
			total += count;
			dstLen -= count;
		}
	}

	/* We ran out of steam. Hopefully this was because we've produced
	   a bunch'o bits from the decryption. */
	if(ret == SEC_E_OK || ret == SEC_E_INCOMPLETE_MESSAGE) {
		/* Retain any remaining extra buffers and return output */
		sqCopyExtraData(ssl, ssl->sbdIn);
		/* Return the total number of bytes decrypted */
		return total;		
	}

	if(ssl->loglevel) printf("DecryptMessage returned: %x\n", ret);
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
		case SQSSL_PROP_SERVERNAME: return ssl->serverName;
		default:
			if(ssl->loglevel) printf("sqGetStringPropertySSL: Unknown property ID %d\n", propID);
			return NULL;
	}
	return NULL;
}

/* sqAddPfxCertToStore: Adds a PFX certificate to MY certificate store. 
   Arguments:
		pfxData - the contents of the PFX certificate file
		pfxLen - the length of the PFX certificate file
		passData - the utf8 encoded password for the file
		passLen - the size of the password
   Returns: 1 on success, 0 on failure
*/
static sqInt sqAddPfxCertToStore(char *pfxData, sqInt pfxLen, char *passData, sqInt passLen) {
	PCCERT_CONTEXT pContext;
	HCERTSTORE pfxStore, myStore;
	CRYPT_DATA_BLOB blob;
	WCHAR widePass[4096];

	/* Verify that this is a PFX file */
	blob.cbData = pfxLen;
	blob.pbData = pfxData;
	if(!PFXIsPFXBlob(&blob)) return 0; /* Not a PFX blob */

	/* Verify that the password is all right */
	widePass[0] = 0;
	if(passLen > 0) {
		DWORD wideLen = MultiByteToWideChar(CP_UTF8, 0, passData, passLen, widePass, 4095);
		widePass[wideLen] = 0;
	}
	if(!PFXVerifyPassword(&blob, widePass, 0)) return 0; /* Invalid password */

	/* Import the PFX blob into a temporary store */
	pfxStore = PFXImportCertStore(&blob, widePass, 0);
	if(!pfxStore) return 0;

	/* And copy the certificates to MY store */
	myStore = CertOpenSystemStore(0, L"MY");
	pContext = NULL;
	while(pContext = CertEnumCertificatesInStore(pfxStore, pContext)) {
		CertAddCertificateContextToStore(myStore, pContext, CERT_STORE_ADD_REPLACE_EXISTING, NULL);
	}
	CertCloseStore(myStore, 0);
	CertCloseStore(pfxStore, 0);
	return 1;
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
	  property[propLen] = '\0';
	};

	if(ssl->loglevel) printf("sqSetStringPropertySSL(%d): %s\n", propID, property ? property : "(null)");

	switch(propID) {
		case SQSSL_PROP_CERTNAME:
			if(ssl->certName) free(ssl->certName);
			ssl->certName = property;
			break;
		case SQSSL_PROP_SERVERNAME:
			if(ssl->serverName) free(ssl->serverName);
			ssl->serverName = property;
			break;
		/* Platform specific: Adds a .PFX file to MY certificate store w/o password.
		   Useful for installing the default test certificate in SqueakSSL. */
		case 10001:
			if(property) free(property);
			return sqAddPfxCertToStore(propName, propLen, NULL, 0);
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
int sqGetIntPropertySSL(sqInt handle, int propID) {
	sqSSL *ssl = sslFromHandle(handle);

	if(ssl == NULL) return 0;
	switch(propID) {
		case SQSSL_PROP_SSLSTATE: return ssl->state;
		case SQSSL_PROP_CERTSTATE: return ssl->certFlags;
		case SQSSL_PROP_VERSION: return SQSSL_VERSION;
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
