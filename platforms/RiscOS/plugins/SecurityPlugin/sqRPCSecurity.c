/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@sumeru.stanford.edu & http://sumeru.stanford.edu/tim              */
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

static char secureUserDirectory[MAXDIRNAMELENGTH];     /* imagepath/secure/    */
static char untrustedUserDirectory[MAXDIRNAMELENGTH];  /* imagepath/untrusted/ */
static int  untrustedUserDirectoryLen;
static char buf[MAXDIRNAMELENGTH];

static char* fromSqueak(char* string, int len) {
	sqFilenameFromString(buf, (int)string, len);
	PRINTF(("sec: fromSqueak - input: %s, out: %s\n",string, buf));
	return buf;
}

static char* toSqueak(char* string) {
extern void sqStringFromFilename( int sqString, char*fileName, int sqSize);
int len = strlen(string);
	sqStringFromFilename((int)buf, string, len);
	buf[len] = 0;
	PRINTF(("sec: toSqueak - input: %s, out: %s\n",string, buf));
	return buf;
}

/* file security ***********************************************************/


static int allowFileAccess= 1;  /* full access to files */


static int isAccessiblePathName(char *pathName) {
	int  pathLen;
                                                
	pathLen= strlen(pathName);
	PRINTF(("sec: isAccessiblePathName - %s\n", pathName));
	return (pathLen >= untrustedUserDirectoryLen
	   && 0 == strncmp(pathName, untrustedUserDirectory, untrustedUserDirectoryLen));
}


static int isAccessibleFileName(char *fileName) {
	char pathName[MAXDIRNAMELENGTH];
	int pathLen= strrchr(fileName, '.') - fileName;

	strncpy(pathName, fileName, pathLen);
	pathName[pathLen]= '\0';

	return isAccessiblePathName(pathName);
}


/* directory access */


int ioCanCreatePathOfSize(char* pathString, int pathStringLength)
{
  if (allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}


int ioCanListPathOfSize(char* pathString, int pathStringLength)
{
  if (allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}


int ioCanDeletePathOfSize(char* pathString, int pathStringLength)
{
  if (allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}


/* file access */


int ioCanOpenFileOfSizeWritable(char* pathString, int pathStringLength, int writeFlag)
{
  if (allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}


int ioCanOpenAsyncFileOfSizeWritable(char* pathString, int pathStringLength, int writeFlag)
{
  return ioCanOpenFileOfSizeWritable(pathString, pathStringLength, writeFlag);
}


int ioCanDeleteFileOfSize(char* pathString, int pathStringLength)
{
  if (allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}

int ioCanRenameFileOfSize(char* pathString, int pathStringLength)
{
  if (allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}


int ioCanGetFileTypeOfSize(char* pathString, int pathStringLength)
{
  return 1; /* we don't have file types */
}


int ioCanSetFileTypeOfSize(char* pathString, int pathStringLength)
{
  return 1; /* we don't have file types */
}


/* disabling/querying */


int ioDisableFileAccess(void)
{
  allowFileAccess= 0;
  return 1;
}


int ioHasFileAccess(void)
{
  return allowFileAccess;
}


/* image security **********************************************************/


static int allowImageWrite= 1;  /* allow writing the image */


int ioCanRenameImage(void)
{
  return allowImageWrite; /* only when we're allowed to save the image */
}

int ioCanWriteImage(void)
{
  return allowImageWrite;
}

int ioDisableImageWrite(void)
{
  allowImageWrite= 0;
  return 1;
}


/* socket security - for now it's all or nothing ***************************/


static int allowSocketAccess= 1; /* allow access to sockets */


int ioCanCreateSocketOfType(int netType, int socketType)
{
  return allowSocketAccess;
}


int ioCanConnectToPort(int netAddr, int port)
{
  return allowSocketAccess;
}


int ioCanListenOnPort(int s, int port)
{
  return allowSocketAccess;
}


int ioDisableSocketAccess()
{
  allowSocketAccess= 0;
  return 1;
}


int ioHasSocketAccess()
{
  return allowSocketAccess;
}


/* SecurityPlugin primitive support ****************************************/


char *ioGetSecureUserDirectory(void)
{
/*  if (secureUserDirectory[0] == '\0')
    return (char *)success(false);
*/
	PRINTF(("sec: getSecureUserDir - %s\n", secureUserDirectory));
  return toSqueak(secureUserDirectory);
}


char *ioGetUntrustedUserDirectory(void)
{
	PRINTF(("sec: getUntrustedUserDir - %s\n", untrustedUserDirectory));
  return toSqueak(untrustedUserDirectory);
}


/* note: following is called from VM directly, not from plugin */
int ioInitSecurity(void)
{
  int imagePathLen= strrchr(imageName, '.') - imageName;

  /* establish the secure user directory */
  strncpy(secureUserDirectory, imageName, imagePathLen);
  strcpy(secureUserDirectory+imagePathLen, ".secure");

  /* establish untrusted user directory */
  strncpy(untrustedUserDirectory, imageName, imagePathLen);
  strcpy(untrustedUserDirectory+imagePathLen, ".untrusted");
  untrustedUserDirectoryLen= strlen(untrustedUserDirectory);

	PRINTF(("Sec: init secure dir: %s, unsecure: %s\n", secureUserDirectory, untrustedUserDirectory));
  return 1;
}
