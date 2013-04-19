//  A Squeak VM for RiscOS machines
//  Suited to RISC OS > 4, preferably > 5
// See www.squeak.org for much more information
//
// tim Rowledge tim@rowledge.org
//
// License: MIT License -
// Copyright (C) <2013> <tim rowledge>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// This is sqRPCSecurity.c
// It provides some filesysem security apis - you can set up a directory as
// a 'trusted' place for users data, or restrict saving of the image file etc

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
