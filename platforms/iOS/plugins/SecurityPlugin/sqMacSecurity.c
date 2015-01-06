//  John M McIntosh on 5/15/08.
//  Copyright Corporate Smalltalk Consulting Ltd 2000-2008. All rights reserved.
/*
 Copyright (c) 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
 MIT License
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

The end-user documentation included with the redistribution, if any, must include the following acknowledgment: 
"This product includes software developed by Corporate Smalltalk Consulting Ltd (http://www.smalltalkconsulting.com) 
and its contributors", in the same place and form as other third-party acknowledgments. 
Alternately, this acknowledgment may appear in the software itself, in the same form and location as other 
such third-party acknowledgments.
*/
//

//JMM 2/13/01 create docs folder if non-existant
//JMM 4/4/01  look for documents/My Squeak folder versus just documents as secure location
//JMM 5/3/01  path was wrong for unsecure folder which uncovered a bug in lookupPath
//JMM 8/15/01 only allow call to ioInitSecurity Once, also return  proper return code
//JMM 9/5/01  make it as a plugin
// 3.7.0bx Nov 24th, 2003 JMM gCurrentVMEncoding
//May 16th, 2008. IPhone

#include "sq.h"
#include "SecurityPlugin.h"
#include "FilePlugin.h"
#include <limits.h>
typedef unsigned char                   Boolean;
#define DELIMITERInt '/'

extern struct VirtualMachine * interpreterProxy;

#define fromSqueak(string,length) string
void fixPath(char *path);
sqInt dir_CreateSecurity(char *pathString, sqInt pathStringLength);
sqInt _ioSetFileAccess(sqInt enable);

static char secureUserDirectory[PATH_MAX];
static char untrustedUserDirectory[PATH_MAX];
static Boolean gInitialized = false;

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* file security */
static sqInt allowFileAccess = 1;  /* full access to files */

static sqInt isAccessiblePathName(char *pathName) {
  sqInt i;
  /* Check if the path/file name is subdirectory of the image path */
  for(i=0; i<strlen(untrustedUserDirectory)-1; i++)
    if(untrustedUserDirectory[i] != pathName[i]) return 0;
  /* special check for the trusted directory */
  if(pathName[i] == 0) return 1; /* allow access to trusted directory */
  /* check last character in image path (e.g., backslash) */
  if(untrustedUserDirectory[i] != pathName[i]) return 0;

return 1;
}

static sqInt isAccessibleFileName(char *fileName) {
  sqInt i;
  /* Check if the path/file name is subdirectory of the image path */
  for(i=0; i<strlen(untrustedUserDirectory); i++)
    if(untrustedUserDirectory[i] != fileName[i]) return 0;
  return 1;
}

/* directory access */
sqInt ioCanCreatePathOfSize(char* pathString, sqInt pathStringLength) {
#pragma unused(pathStringLength)
  if(allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}

sqInt ioCanListPathOfSize(char* pathString, sqInt pathStringLength) {
#pragma unused(pathStringLength)
  if(allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}

sqInt ioCanDeletePathOfSize(char* pathString, sqInt pathStringLength) {
#pragma unused(pathStringLength)
  if(allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}

/* file access */
sqInt ioCanOpenFileOfSizeWritable(char* pathString, sqInt pathStringLength, sqInt writeFlag) {
#pragma unused(pathStringLength,writeFlag)
  if(allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}

sqInt ioCanOpenAsyncFileOfSizeWritable(char* pathString, sqInt pathStringLength, sqInt writeFlag) {
  return ioCanOpenFileOfSizeWritable(pathString,pathStringLength,writeFlag);
}
sqInt ioCanDeleteFileOfSize(char* pathString, sqInt pathStringLength) {
#pragma unused(pathStringLength)
  if(allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}

sqInt ioCanRenameFileOfSize(char* pathString, sqInt pathStringLength) {
#pragma unused(pathStringLength)
  if(allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}


sqInt ioCanGetFileTypeOfSize(char* pathString, sqInt pathStringLength) {
#pragma unused(pathString,pathStringLength)
  return 1; /* of no importance here */
}

sqInt ioCanSetFileTypeOfSize(char* pathString, sqInt pathStringLength) {
#pragma unused(pathString,pathStringLength)
  return 1; /* of no importance here */
}

/* disabling/querying */
sqInt ioDisableFileAccess(void) {
  allowFileAccess = 0;
 return 0;
}

sqInt ioHasFileAccess(void) {
  return allowFileAccess;
}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* image security */

static sqInt allowImageWrite = 1;  /* allow writing the image */

sqInt ioCanRenameImage(void) {
  return allowImageWrite; /* only when we're allowed to save the image */
}

sqInt ioCanWriteImage() {
  return allowImageWrite;
}

sqInt ioDisableImageWrite() {
  allowImageWrite = 0;
	return 0;
}


/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* socket security - for now it's all or nothing */
static sqInt allowSocketAccess = 1; /* allow access to sockets */

sqInt ioCanCreateSocketOfType(sqInt netType, sqInt socketType) {
#pragma unused(netType,socketType)
  return allowSocketAccess;
}

sqInt ioCanConnectToPort(sqInt netAddr, sqInt port) {
#pragma unused(netAddr,port)
  return allowSocketAccess;
}

sqInt ioCanListenOnPort(sqInt  s, sqInt port) {
#pragma unused(s,port)
  return allowSocketAccess;
}

sqInt ioDisableSocketAccess() {
  allowSocketAccess = 0;
	return 0;
}

sqInt ioHasSocketAccess() {
  return allowSocketAccess;
}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* SecurityPlugin primitive support */


char *ioGetSecureUserDirectory(void) {
  return  secureUserDirectory;
}

char *ioGetUntrustedUserDirectory(void) {
  return untrustedUserDirectory;
}

/* note: following is called from VM directly, not from plugin */
sqInt ioInitSecurity(void) {
  extern char gSqueakUntrustedDirectoryName[],gSqueakTrustedDirectoryName[];
  
  if (gInitialized) return 1;
  gInitialized  = true;

  secureUserDirectory[0] = 0x00;
  strlcpy(secureUserDirectory, gSqueakTrustedDirectoryName,PATH_MAX);
  untrustedUserDirectory[0] = 0x00;
  strlcpy(untrustedUserDirectory, gSqueakUntrustedDirectoryName,PATH_MAX);
  return 1;
}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* private entries for restoring rights */
sqInt _ioSetImageWrite(sqInt enable);

sqInt _ioSetImageWrite(sqInt enable) {
  if(enable == allowImageWrite) return 1;
  allowImageWrite = enable;
  return 1;
}

sqInt _ioSetFileAccess(sqInt enable);

sqInt _ioSetFileAccess(sqInt enable) {
  if(enable == allowFileAccess) return 1;
  allowFileAccess = enable;
  return 1;
}

sqInt _ioSetSocketAccess(sqInt enable);

sqInt _ioSetSocketAccess(sqInt enable) {
  if(enable == allowSocketAccess) return 1;
  allowSocketAccess = enable;
  return 1;
}


void fixPath(char *path) {
    long i;
    for(i=strlen(path);i>0;i--) 
        if(path[i-1]==DELIMITERInt) {
            path[i-1]=0x00;
            return;
        }
}

sqInt dir_CreateSecurity(char *pathString, sqInt pathStringLength) {
	/* Create a new directory with the given path. By default, this
	   directory is created in the current directory. Use
	   a full path name such as "MyDisk:Working:New Folder" to
	   create folders elsewhere. */

    //JMM tests create file in Vm directory, other place, other volume
	return (sqInt) dir_Create(pathString, pathStringLength);
}
