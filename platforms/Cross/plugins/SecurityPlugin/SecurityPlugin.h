/* security plugin header file */

/* image writing */
sqInt ioDisableImageWrite(void);
sqInt ioCanWriteImage(void);

/* untrusted and secure directory locations */
char *ioGetSecureUserDirectory(void);
char *ioGetUntrustedUserDirectory(void);

/* following must be called by the VM before interpret() */
sqInt ioInitSecurity(void);
sqInt ioCanListenOnPort(sqInt s, sqInt port);
sqInt ioCanConnectToPort(sqInt netAddr, sqInt port);
sqInt ioCanCreateSocketOfType(sqInt netType, sqInt socketType);
sqInt ioCanCreateSocketOfType(sqInt netType, sqInt socketType);
sqInt ioCanConnectToPort(sqInt netAddr, sqInt port);
sqInt ioDisableSocketAccess(void);
sqInt ioHasSocketAccess(void);
sqInt ioCanCreatePathOfSize(char* pathString, sqInt pathStringLength);
sqInt ioCanDeleteFileOfSize(char* pathString, sqInt pathStringLength);
sqInt ioCanDeletePathOfSize(char* pathString, sqInt pathStringLength);
sqInt ioCanGetFileTypeOfSize(char* pathString, sqInt pathStringLength);
sqInt ioCanListPathOfSize(char* pathString, sqInt pathStringLength);
sqInt ioCanOpenAsyncFileOfSizeWritable(char* pathString, sqInt pathStringLength, sqInt writeFlag);
sqInt ioCanOpenFileOfSizeWritable(char* pathString, sqInt pathStringLength, sqInt writeFlag);
sqInt ioCanRenameFileOfSize(char* pathString, sqInt pathStringLength);
sqInt ioCanRenameImage(void);
sqInt ioCanSetFileTypeOfSize(char* pathString, sqInt pathStringLength);
sqInt ioDisableFileAccess(void);
sqInt ioHasFileAccess(void);
