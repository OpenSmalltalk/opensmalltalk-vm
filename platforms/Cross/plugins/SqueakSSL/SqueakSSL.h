#ifndef SqueakSSL_H
#define SqueakSSL_H

/**********************************************************/
/* SqueakSSL Version Information                          */
/* Version 1: Inital version                              */
/* Version 2: SNI support by Levente Uzonyi and help by   */
/*            Marcel Taeumel and Tobias Pape              */
/**********************************************************/


#define SQSSL_VERSION 2

/*************************/
/* SSL connection states */
/*************************/

#define SQSSL_UNUSED 0
#define SQSSL_ACCEPTING 1
#define SQSSL_CONNECTING 2
#define SQSSL_CONNECTED 3

/********************************************/
/* Return codes from the core SSL functions */
/********************************************/

#define SQSSL_OK 0
#define SQSSL_NEED_MORE_DATA -1
#define SQSSL_INVALID_STATE -2
#define SQSSL_BUFFER_TOO_SMALL -3
#define SQSSL_INPUT_TOO_LARGE -4
#define SQSSL_GENERIC_ERROR -5
#define SQSSL_OUT_OF_MEMORY -6

/**************************************/
/* SqueakSSL certificate status bits. */
/**************************************/

#define SQSSL_NO_CERTIFICATE -1
#define SQSSL_OTHER_ISSUE    0x0001
#define SQSSL_UNTRUSTED_ROOT 0x0002
#define SQSSL_CERT_EXPIRED   0x0004
#define SQSSL_WRONG_USAGE    0x0008
#define SQSSL_INVALID_CN     0x0010
#define SQSSL_CERT_REVOKED   0x0020


/****************************************/
/* SqueakSSL getInt/setInt property IDs */
/****************************************/
#define SQSSL_PROP_VERSION  0
#define SQSSL_PROP_LOGLEVEL 1
#define SQSSL_PROP_SSLSTATE 2
#define SQSSL_PROP_CERTSTATE 3

/**********************************************/
/* SqueakSSL getString/setString property IDs */
/**********************************************/
#define SQSSL_PROP_PEERNAME 0
#define SQSSL_PROP_CERTNAME 1
#define SQSSL_PROP_SERVERNAME 2

/* sqCreateSSL: Creates a new SSL instance.
	Arguments: None.
	Returns: SSL handle.
*/
sqInt sqCreateSSL(void);

/* sqDestroySSL: Destroys an SSL instance.
	Arguments:
		handle - the SSL handle
	Returns: Non-zero if successful.
*/
sqInt sqDestroySSL(sqInt handle);

/* sqAcceptSSL: Start/continue an SSL server handshake.
	Arguments:
		handle - the SSL handle
		srcBuf - the input token sent by the remote peer
		srcLen - the size of the input token
		dstBuf - the output buffer for a new token
		dstLen - the size of the output buffer
	Returns: The size of the output token or an error code.
*/
sqInt sqAcceptSSL(sqInt handle, char* srcBuf, sqInt srcLen, char *dstBuf, sqInt dstLen);

/* sqConnectSSL: Start/continue an SSL client handshake.
	Arguments:
		handle - the SSL handle
		srcBuf - the input token sent by the remote peer
		srcLen - the size of the input token
		dstBuf - the output buffer for a new token
		dstLen - the size of the output buffer
	Returns: The size of the output token or an error code.
*/
sqInt sqConnectSSL(sqInt handle, char* srcBuf, sqInt srcLen, char *dstBuf, sqInt dstLen);

/* sqEncryptSSL: Encrypt data for SSL transmission.
	Arguments:
		handle - the SSL handle
		srcBuf - the unencrypted input data
		srcLen - the size of the input data
		dstBuf - the output buffer for the encrypted contents
		dstLen - the size of the output buffer
	Returns: The size of the output generated or an error code.
*/
sqInt sqEncryptSSL(sqInt handle, char* srcBuf, sqInt srcLen, char *dstBuf, sqInt dstLen);

/* sqDecryptSSL: Decrypt data for SSL transmission.
	Arguments:
		handle - the SSL handle
		srcBuf - the encrypted input data
		srcLen - the size of the input data
		dstBuf - the output buffer for the decrypted contents
		dstLen - the size of the output buffer
	Returns: The size of the output generated or an error code.
*/
sqInt sqDecryptSSL(sqInt handle, char* srcBuf, sqInt srcLen, char *dstBuf, sqInt dstLen);

/* sqGetStringPropertySSL: Retrieve a string property from SSL.
	Arguments:
		handle - the ssl handle
		propID - the property id to retrieve
	Returns: The string value of the property.
*/
char* sqGetStringPropertySSL(sqInt handle, int propID);

/* sqSetStringPropertySSL: Set a string property in SSL.
	Arguments:
		handle - the ssl handle
		propID - the property id to retrieve
		propName - the property string
		propLen  - the length of the property string
	Returns: Non-zero if successful.
*/
sqInt sqSetStringPropertySSL(sqInt handle, int propID, char *propName, sqInt propLen);

/* sqGetIntPropertySSL: Retrieve an integer property from SSL.
	Arguments:
		handle - the ssl handle
		propID - the property id to retrieve
	Returns: The integer value of the property.
*/
sqInt sqGetIntPropertySSL(sqInt handle, sqInt propID);

/* sqSetIntPropertySSL: Set an integer property in SSL.
	Arguments:
		handle - the ssl handle
		propID - the property id to retrieve
		propValue - the property value
	Returns: Non-zero if successful.
*/
sqInt sqSetIntPropertySSL(sqInt handle, sqInt propID, sqInt propValue);

#endif
