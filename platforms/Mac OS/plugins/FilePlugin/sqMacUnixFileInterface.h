/*
 *  sqMacUnixFileInterface.h
 *  SqueakVMUNIXPATHS
 *
 *  Created by John M McIntosh on 31/01/06.
 *  Copyright 2006 Corporate Smalltalk Consulting Ltd. All rights reserved, released under the Squeak-L license.
 *
 */
#include "sqMacUIConstants.h"

OSStatus SetVMPathFromApplicationDirectory();
int PathToFileViaFSSpec(char *pathName, int pathNameMax, FSSpec *workingDirectory,UInt32 encoding);
int getLastPathComponentInCurrentEncoding(char *pathString,char * lastPathPart,CFStringEncoding encoding);
extern UInt32 gCurrentVMEncoding;
OSErr squeakFindImage(char *pathName);
OSErr getFSRef(char *pathString,FSRef *theFSRef,CFStringEncoding encoding);
void PathToFileViaFSRef(char *pathName, int pathNameMax, FSRef *theFSRef, Boolean retryWithDirectory,char * rememberName,CFStringEncoding encoding);
