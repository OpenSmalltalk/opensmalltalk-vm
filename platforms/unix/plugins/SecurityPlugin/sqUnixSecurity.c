/* sqUnixSecurity.c -- directory operations for Unix/MacOS
 * 
 * Author: Bert Freudenberg (heavily based on Andreas Raab's sqWin32Security.c)
 * 
 * Last edited: 2005-03-19 20:47:40 by piumarta on squeak.hpl.hp.com
 * 
 * Note: According to Ian Piumarta, the Unix VM is inherently insecure since
 *       pluggable primitives can access all of libc! It would need 
 *       some linker magic to hide these from dlsym(). 
 * 
 *       A workaround would be to disallow lookups via dlsym() when
 *       fileaccess is disallowed - internal plugins should still work ...
 */

#include "sq.h"
#include "SecurityPlugin.h"

#include <unistd.h>
#include <sys/param.h>

static char secureUserDirectory[MAXPATHLEN+1];     /* imagepath/secure/    */
static char untrustedUserDirectory[MAXPATHLEN+1];  /* imagepath/untrusted/ */
static int  untrustedUserDirectoryLen;

static char* fromSqueak(char* string, int len)
{
  static char buf[MAXPATHLEN+1];
  strncpy(buf, string, len);
  buf[len] = '\0';
  return buf;
}

/* environment security *******************************************************/
static int allowEnvironmentAccess = 1; /* full access to C environment */

sqInt ioDisableEnvironmentAccess(void) { return allowEnvironmentAccess = 0; }
sqInt ioHasEnvironmentAccess(void) { return allowEnvironmentAccess; }

/* file security ***********************************************************/
static sqInt allowFileAccess = 1;  /* full access to files */


static int
isAccessiblePathName(char *pathName)
{
   char realPathName[MAXPATHLEN+1];
   int  realPathLen;

   realpath(pathName, realPathName);
   realPathLen = strlen(realPathName);

   return (realPathLen >= untrustedUserDirectoryLen
	   && 0 == strncmp(realPathName, untrustedUserDirectory, untrustedUserDirectoryLen));
}


static int
isAccessibleFileName(char *fileName)
{
  char pathName[MAXPATHLEN+1];
  int pathLen = strrchr(fileName, '/') - fileName;

  strncpy(pathName, fileName, pathLen);
  pathName[pathLen] = '\0';

  return isAccessiblePathName(pathName);
}


/* directory access */


sqInt
ioCanCreatePathOfSize(char* pathString, sqInt pathStringLength)
{
  if (allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}


sqInt
ioCanListPathOfSize(char* pathString, sqInt pathStringLength)
{
  if (allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}


sqInt
ioCanDeletePathOfSize(char* pathString, sqInt pathStringLength)
{
  if (allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}


/* file access */


sqInt
ioCanOpenFileOfSizeWritable(char* pathString, sqInt pathStringLength, sqInt writeFlag)
{
  if (allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}


sqInt
ioCanOpenAsyncFileOfSizeWritable(char* pathString, sqInt pathStringLength, sqInt writeFlag)
{
  return ioCanOpenFileOfSizeWritable(pathString, pathStringLength, writeFlag);
}


sqInt
ioCanDeleteFileOfSize(char* pathString, sqInt pathStringLength)
{
  if (allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}

sqInt
ioCanRenameFileOfSize(char* pathString, sqInt pathStringLength)
{
  if (allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}


sqInt
ioCanGetFileTypeOfSize(char* pathString, sqInt pathStringLength)
{
  return 1; /* we don't have file types */
}


sqInt
ioCanSetFileTypeOfSize(char* pathString, sqInt pathStringLength)
{
  return 1; /* we don't have file types */
}


/* disabling/querying */

sqInt
ioDisableFileAccess(void) { return allowFileAccess = 0; }
sqInt
ioHasFileAccess(void) { return allowFileAccess; }


/* image security **********************************************************/
static sqInt allowImageWrite = 1;  /* allow writing the image */

sqInt
ioCanRenameImage(void)
{
  return allowImageWrite; /* only when we're allowed to save the image */
}

sqInt
ioCanWriteImage(void) { return allowImageWrite; }
sqInt
ioDisableImageWrite(void) { return allowImageWrite = 0; }


/* socket security - for now it's all or nothing ***************************/
static sqInt allowSocketAccess = 1; /* allow access to sockets */

sqInt
ioCanCreateSocketOfType(sqInt netType, sqInt socketType)
{
  return allowSocketAccess;
}
sqInt
ioCanConnectToPort(sqInt addr, sqInt port) { return allowSocketAccess; }
sqInt
ioCanListenOnPort(sqInt s, sqInt port) { return allowSocketAccess; }
sqInt
ioDisableSocketAccess(void) { return allowSocketAccess = 0; }
sqInt
ioHasSocketAccess(void) { return allowSocketAccess; }


/* SecurityPlugin primitive support ****************************************/

char *
ioGetSecureUserDirectory(void)
{
  if (secureUserDirectory[0] == '\0') {
    success(false);
	return 0;
  }
  return secureUserDirectory;
}


char *
ioGetUntrustedUserDirectory(void)
{
  return untrustedUserDirectory;
}


/* note: the following is called from the VM directly, not from the plugin */
sqInt
ioInitSecurity(void)
{
  char *squeakUserDirectory;
  char *slash = strrchr(imageName, '/');
  int imagePathLen = slash ? slash - imageName : 0;

  /* establish the secure user directory, always relative to the image file */
  if (imagePathLen)
    strncpy(secureUserDirectory, imageName, imagePathLen);
  else {
    getcwd(secureUserDirectory,MAXPATHLEN);
	imagePathLen = strlen(secureUserDirectory);
  }

  strcpy(secureUserDirectory + imagePathLen, "/secure");

  /* establish the untrusted user directory; optional or relative to image */
  squeakUserDirectory = getenv("SQUEAK_USERDIR");
  if (!squeakUserDirectory) {
      strncpy(untrustedUserDirectory, secureUserDirectory, imagePathLen);
      strcpy(untrustedUserDirectory + imagePathLen, "/My Squeak");
  }
  else {
      int lastChar = strlen(squeakUserDirectory);
      /*  path is not allowed to end with "/" */
      if ('/' == squeakUserDirectory[lastChar - 1])
        squeakUserDirectory[lastChar - 1] = '\0';
      strcpy(untrustedUserDirectory, squeakUserDirectory);
  }
  untrustedUserDirectoryLen = strlen(untrustedUserDirectory);

  return 1;
}
