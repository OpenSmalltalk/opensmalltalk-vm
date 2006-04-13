/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@rowledge.org & http://www.rowledge.org/tim                        */
/*  Known to work on RiscOS >3.7 for StrongARM RPCs and Iyonix,           */
/*  other machines not yet tested.                                        */
/*                       sqRPCSecurity.c                                  */
/*  Connect to Squeak's security stuff                                    */
/**************************************************************************/

/* To recompile this reliably you will need    */           
/* OSLib -  http://ro-oslib.sourceforge.net/   */
/* Castle/AcornC/C++, the Acorn TCPIPLib       */
/* and a little luck                           */
/* debugging stuff; uncomment for debugging trace */
//#define DEBUG

#include "sq.h"
#include "SecurityPlugin.h"

static char secureUserDirectory[MAXDIRNAMELENGTH];    /* imagepath/secure/   */
static char untrustedUserDirectory[MAXDIRNAMELENGTH]; /* imagepath/untrusted/ */
static int  untrustedUserDirectoryLen;
char name[MAXDIRNAMELENGTH];

/* file security ***********************************************************/


static int allowFileAccess= 1;  /* full access to files */


static int isAccessiblePathName(char *pathName, int pathLength) {
	int  pathLen;

	if (!canonicalizeFilenameToString(pathName, pathLength, name))
		return false;

	pathLen= strlen(name);
	PRINTF(("\\t sec: isAccessiblePathName - %s\n", name));
	return (pathLen >= untrustedUserDirectoryLen
		&& 0 == strncmp(name, untrustedUserDirectory, untrustedUserDirectoryLen));
}

static int isAccessibleFileName(char *fileName, int pathLength) {
	int pathLen= strrchr(fileName, '.') - fileName;
	char *lastDot;
	if (!canonicalizeFilenameToString(fileName, pathLength, name))
		return false;
	lastDot = strrchr(name, '.');
	if (lastDot) *lastDot = '\0';
	pathLen = strlen(name);
	PRINTF(("\\t sec: isAccessibleFileName - %s\n", name));
	return (pathLen >= untrustedUserDirectoryLen
		&& 0 == strncmp(name, untrustedUserDirectory, untrustedUserDirectoryLen));
}


/* directory access */


int ioCanCreatePathOfSize(char* pathString, int pathStringLength) {
	if (allowFileAccess) return 1;
	return isAccessiblePathName(pathString, pathStringLength);
}


int ioCanListPathOfSize(char* pathString, int pathStringLength) {
	if (allowFileAccess) return 1;
	return isAccessiblePathName(pathString, pathStringLength);
}


int ioCanDeletePathOfSize(char* pathString, int pathStringLength) {
	if (allowFileAccess) return 1;
	return isAccessiblePathName(pathString, pathStringLength);
}


/* file access */


int ioCanOpenFileOfSizeWritable(char* pathString, int pathStringLength, int writeFlag) {
	if (allowFileAccess) return 1;
	return isAccessibleFileName(pathString, pathStringLength);
}


int ioCanOpenAsyncFileOfSizeWritable(char* pathString, int pathStringLength, int writeFlag) {
	return ioCanOpenFileOfSizeWritable(pathString, pathStringLength, writeFlag);
}


int ioCanDeleteFileOfSize(char* pathString, int pathStringLength) {
	if (allowFileAccess) return 1;
	return isAccessibleFileName(pathString, pathStringLength);
}

int ioCanRenameFileOfSize(char* pathString, int pathStringLength) {
	if (allowFileAccess) return 1;
	return isAccessibleFileName(pathString, pathStringLength);
}


int ioCanGetFileTypeOfSize(char* pathString, int pathStringLength) {
	return 1; /* we don't have file types */
}


int ioCanSetFileTypeOfSize(char* pathString, int pathStringLength) {
	return 1; /* we don't have file types */
}


/* disabling/querying */


int ioDisableFileAccess(void) {
	allowFileAccess= 0;
	return 1;
}


int ioHasFileAccess(void) {
	return allowFileAccess;
}


/* image security **********************************************************/


static int allowImageWrite= 1;  /* allow writing the image */


int ioCanRenameImage(void) {
	return allowImageWrite; /* only when we're allowed to save the image */
}

int ioCanWriteImage(void) {
	return allowImageWrite;
}

int ioDisableImageWrite(void) {
	allowImageWrite= 0;
	return 1;
}


/* socket security - for now it's all or nothing ***************************/


static int allowSocketAccess= 1; /* allow access to sockets */


int ioCanCreateSocketOfType(int netType, int socketType) {
	return allowSocketAccess;
}


int ioCanConnectToPort(int netAddr, int port) {
	return allowSocketAccess;
}


int ioCanListenOnPort(int s, int port) {
	return allowSocketAccess;
}


int ioDisableSocketAccess() {
	allowSocketAccess= 0;
	return 1;
}


int ioHasSocketAccess() {
	return allowSocketAccess;
}


/* SecurityPlugin primitive support ****************************************/


char *ioGetSecureUserDirectory(void) {
	PRINTF(("\\t sec: getSecureUserDir - %s\n", secureUserDirectory));
	return secureUserDirectory;
}


char *ioGetUntrustedUserDirectory(void) {
	PRINTF(("\\t sec: getUntrustedUserDir - %s\n", untrustedUserDirectory));
	return untrustedUserDirectory;
}

int ioInitSecurity(void) {
char * imageName = getImageName();
extern void sqStringFromFilename( char * sqString, char*fileName, int sqSize);
	int len;
	int imagePathLen= strrchr(imageName, '.') - imageName;

	/* establish the secure user directory */
	#define SecDir ".secure\0"

	strncpy(secureUserDirectory, imageName, imagePathLen);
	strcpy(secureUserDirectory+imagePathLen, SecDir);
	len = strlen(secureUserDirectory);
	sqStringFromFilename(secureUserDirectory, secureUserDirectory, len);

	/* establish untrusted user directory */
	#define UnsecDir ".untrusted\0"

	strncpy(untrustedUserDirectory, imageName, imagePathLen);
	strcpy(untrustedUserDirectory+imagePathLen, UnsecDir);
	untrustedUserDirectoryLen = strlen(untrustedUserDirectory);
	sqStringFromFilename(untrustedUserDirectory, untrustedUserDirectory, untrustedUserDirectoryLen);

	PRINTF(("\\t sec: init secure dir: %s, unsecure: %s\n", secureUserDirectory, untrustedUserDirectory));
  return 1;
}
