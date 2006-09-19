/* sqUnixSecurity.c -- directory operations for Unix
 * 
 * Author: Bert Freudenberg (heavily based on Andreas Raab's sqWin32Security.c)
 * 
 * Last edited: 2006-09-19 07:00:06 by piumarta on ubuntu
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


static sqInt allowFileAccess= 1;  /* full access to files */


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


sqInt ioCanCreatePathOfSize(char* pathString, sqInt pathStringLength)
{
  if (allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}


sqInt ioCanListPathOfSize(char* pathString, sqInt pathStringLength)
{
  if (allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}


sqInt ioCanDeletePathOfSize(char* pathString, sqInt pathStringLength)
{
  if (allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}


/* file access */


sqInt ioCanOpenFileOfSizeWritable(char* pathString, sqInt pathStringLength, sqInt writeFlag)
{
  if (allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}


sqInt ioCanOpenAsyncFileOfSizeWritable(char* pathString, sqInt pathStringLength, sqInt writeFlag)
{
  return ioCanOpenFileOfSizeWritable(pathString, pathStringLength, writeFlag);
}


sqInt ioCanDeleteFileOfSize(char* pathString, sqInt pathStringLength)
{
  if (allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}

sqInt ioCanRenameFileOfSize(char* pathString, sqInt pathStringLength)
{
  if (allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}


sqInt ioCanGetFileTypeOfSize(char* pathString, sqInt pathStringLength)
{
  return 1; /* we don't have file types */
}


sqInt ioCanSetFileTypeOfSize(char* pathString, sqInt pathStringLength)
{
  return 1; /* we don't have file types */
}


/* disabling/querying */


sqInt ioDisableFileAccess(void)
{
  allowFileAccess= 0;
  return 1;
}


sqInt ioHasFileAccess(void)
{
  return allowFileAccess;
}


/* image security **********************************************************/


static sqInt allowImageWrite= 1;  /* allow writing the image */


sqInt ioCanRenameImage(void)
{
  return allowImageWrite; /* only when we're allowed to save the image */
}

sqInt ioCanWriteImage(void)
{
  return allowImageWrite;
}

sqInt ioDisableImageWrite(void)
{
  allowImageWrite= 0;
  return 1;
}


/* socket security - for now it's all or nothing ***************************/


static sqInt allowSocketAccess= 1; /* allow access to sockets */


sqInt ioCanCreateSocketOfType(sqInt netType, sqInt socketType)
{
  return allowSocketAccess;
}


sqInt ioCanConnectToPort(sqInt netAddr, sqInt port)
{
  return allowSocketAccess;
}


sqInt ioCanListenOnPort(sqInt s, sqInt port)
{
  return allowSocketAccess;
}


sqInt ioDisableSocketAccess()
{
  allowSocketAccess= 0;
  return 1;
}


sqInt ioHasSocketAccess()
{
  return allowSocketAccess;
}


/* SecurityPlugin primitive support ****************************************/


char *ioGetSecureUserDirectory(void)
{
  if (secureUserDirectory[0] == '\0')
    return (char *)success(false);
  return secureUserDirectory;
}


char *ioGetUntrustedUserDirectory(void)
{
  return untrustedUserDirectory;
}


/* note: following is called from VM directly, not from plugin */

sqInt ioInitSecurity(void)
{
  int imagePathLen= strrchr(imageName, '/') - imageName;
  char *directory= 0;

  /* establish the secure user directory */
  directory= getenv("SQUEAK_SECUREDIR");
  if (0 == directory)
    {
      strncpy(secureUserDirectory, imageName, imagePathLen);
      strcpy(secureUserDirectory + imagePathLen, "/secure");
    }
  else
    {
      int lastChar= strlen(directory);
      /*  path is not allowed to end with "/" */
      if ('/' == directory[lastChar - 1])
	directory[lastChar - 1]= '\0';
      strcpy(secureUserDirectory, directory);
    }

  /* establish untrusted user directory */
  directory= getenv("SQUEAK_USERDIR");
  if (0 == directory)
    {
      strncpy(untrustedUserDirectory, imageName, imagePathLen);
      strcpy(untrustedUserDirectory + imagePathLen, "/My Squeak");
    }
  else
    {
      int lastChar= strlen(directory);
      /*  path is not allowed to end with "/" */
      if ('/' == directory[lastChar - 1])
	directory[lastChar - 1]= '\0';
      strcpy(untrustedUserDirectory, directory);
    }
  untrustedUserDirectoryLen= strlen(untrustedUserDirectory);

  return 1;
}
