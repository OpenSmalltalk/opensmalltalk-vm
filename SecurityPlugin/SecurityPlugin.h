/* security plugin header file */

/* image writing */
int ioDisableImageWrite(void);
int ioCanWriteImage(void);

/* untrusted and secure directory locations */
char *ioGetSecureUserDirectory(void);
char *ioGetUntrustedUserDirectory(void);

/* following must be called by the VM before interpret() */
int ioInitSecurity(void);
int ioCanListenOnPort(int s, int port);
int ioCanConnectToPort(int netAddr, int port);
int ioCanCreateSocketOfType(int netType, int socketType);
int ioCanCreateSocketOfType(int netType, int socketType);
int ioCanConnectToPort(int netAddr, int port);
int ioDisableSocketAccess(void);
int ioHasSocketAccess(void);
int ioCanCreatePathOfSize(char* pathString, int pathStringLength);
int ioCanDeleteFileOfSize(char* pathString, int pathStringLength);
int ioCanDeletePathOfSize(char* pathString, int pathStringLength);
int ioCanGetFileTypeOfSize(char* pathString, int pathStringLength);
int ioCanListPathOfSize(char* pathString, int pathStringLength);
int ioCanOpenAsyncFileOfSizeWritable(char* pathString, int pathStringLength, int writeFlag);
int ioCanOpenFileOfSizeWritable(char* pathString, int pathStringLength, int writeFlag);
int ioCanRenameFileOfSize(char* pathString, int pathStringLength);
int ioCanRenameImage(void);
int ioCanSetFileTypeOfSize(char* pathString, int pathStringLength);
int ioDisableFileAccess(void);
int ioHasFileAccess(void);
