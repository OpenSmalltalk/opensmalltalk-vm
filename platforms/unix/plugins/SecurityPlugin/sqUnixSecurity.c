/* sqUnixSecurity.c -- directory operations for Unix
 * 
 * Note: According to Ian Piumarta, the Unix VM is inherently insecure since
 *       pluggable primitives can access all of libc! It would need 
 *       some linker magic to hide these from dlsym(). 
 *
 *       A workaround would be to disallow lookups via dlsym() when
 *       fileaccess is disallowed - internal plugins should still work ...
 *
 * Author: Bert Freudenberg (heavily based on Andreas Raab's sqWin32Security.c)
 */

#include "sq.h"
#include <sys/param.h>

static char secureUserDirectory[MAXPATHLEN];     /* imagepath/secure/    */
static char untrustedUserDirectory[MAXPATHLEN];  /* imagepath/untrusted/ */
static int  untrustedUserDirectoryLen;

static char* fromSqueak(char* string, int len)
{
  static char buf[MAXPATHLEN];
  strncpy(buf, string, len);
  buf[len]= '\0';
  return buf;
}

/* file security ***********************************************************/


static int allowFileAccess= 1;  /* full access to files */


static int isAccessiblePathName(char *pathName)
{
   char realPathName[MAXPATHLEN];
   int  realPathLen;
                                                   
   realpath(pathName, realPathName);
   realPathLen= strlen(realPathName);

   return (realPathLen >= untrustedUserDirectoryLen
	   && 0 == strncmp(realPathName, untrustedUserDirectory, untrustedUserDirectoryLen));
}


static int isAccessibleFileName(char *fileName)
{
  char pathName[MAXPATHLEN];
  int pathLen= strrchr(fileName, '/') - fileName;

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


int ioCanListenOnPort(void* s, int port)
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
  return secureUserDirectory;
}


char *ioGetUntrustedUserDirectory(void)
{
  return untrustedUserDirectory;
}


/* note: following is called from VM directly, not from plugin */
int ioInitSecurity(void)
{
  int imagePathLen= strrchr(imageName, '/') - imageName;

  /* establish the secure user directory */
  strncpy(secureUserDirectory, imageName, imagePathLen);
  strcpy(secureUserDirectory+imagePathLen, "/secure");

  /* establish untrusted user directory */
  strncpy(untrustedUserDirectory, imageName, imagePathLen);
  strcpy(untrustedUserDirectory+imagePathLen, "/untrusted");
  untrustedUserDirectoryLen= strlen(untrustedUserDirectory);

  return 1;
}
