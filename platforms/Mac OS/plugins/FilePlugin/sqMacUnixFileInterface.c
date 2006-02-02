/*
 *  sqMacUnixFileInterface.c
 *  SqueakVMUNIXPATHS
 *
 *  Created by John M McIntosh on 31/01/06.
 *  Copyright 2006 Corporate Smalltalk Consulting Ltd. All rights reserved, licensed under the Squeak-L license.
 *
 */

#include <Carbon/Carbon.h>
#include "sqMacUnixFileInterface.h"
#include "sqMacUIConstants.h"

#if TARGET_API_MAC_CARBON
	extern CFStringEncoding gCurrentVMEncoding;
#endif 

/* sqUnixFile.c -- directory operations for Unix
 * 
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *      You are NOT ALLOWED to distribute modified versions of this file
 *      under its original name.  If you modify this file then you MUST
 *      rename it before making your modifications available publicly.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following additional restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. You must not distribute (or make publicly available by any
 *      means) a modified copy of this file unless you first rename it.
 * 
 *   3. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 */

/* Author: Ian.Piumarta@INRIA.Fr
 * 
 * Last edited: 2004-06-13 19:42:03 by piumarta on emilia.local
 */

#include "sq.h"
#include "FilePlugin.h"
#include "sqUnixCharConv.h"
#include "sqMacEncoding.h"

#ifdef HAVE_DIRENT_H
# include <dirent.h>
# define NAMLEN(dirent) strlen((dirent)->d_name)
#else
# define dirent direct
# define NAMLEN(dirent) (dirent)->d_namlen
# ifdef HAVE_SYS_NDIR_H
#  include <sys/ndir.h>
# endif
# ifdef HAVE_SYS_DIR_H
#  include <sys/dir.h>
# endif
# ifdef HAVE_NDIR_H
#  include <ndir.h>
# endif
#endif

#ifdef HAVE_UNISTD_H
# include <sys/types.h>
# include <unistd.h>
#endif

#include <time.h>
#include <errno.h>
#include <string.h>
#include <sys/param.h>
#include <sys/stat.h>

/***
	The interface to the directory primitive is path based.
	That is, the client supplies a Squeak string describing
	the path to the directory on every call. To avoid traversing
	this path on every call, a cache is maintained of the last
	path seen, along with the Mac volume and folder reference
	numbers corresponding to that path.
***/

/*** Constants ***/
#define ENTRY_FOUND     0
#define NO_MORE_ENTRIES 1
#define BAD_PATH        2


/*** Variables ***/
char lastPath[MAXPATHLEN+1];
int  lastPathValid = false;
int  lastIndex= -1;
DIR *openDir= 0;
int IsImageName(char *name);

/*** Functions ***/

extern time_t convertToSqueakTime(time_t unixTime);
void PathToFileViaFSRef(char *pathName, int pathNameMax, FSRef *theFSRef, Boolean retryWithDirectory,char * rememberName,CFStringEncoding encoding);
OSErr getFSRef(char *pathString,FSRef *theFSRef,CFStringEncoding encoding);
sqInt	ioFilenamefromStringofLengthresolveAliases(char* dst, char* src, sqInt num, sqInt resolveAlias);

sqInt dir_Create(char *pathString, sqInt pathStringLength)
{
  /* Create a new directory with the given path. By default, this
     directory is created relative to the cwd. */
  char name[MAXPATHLEN+1];
  if (pathStringLength >= MAXPATHLEN)
    return false;
  if (!sq2uxPath(pathString, pathStringLength, name, MAXPATHLEN, 1))
    return false;
  return mkdir(name, 0777) == 0;	/* rwxrwxrwx & ~umask */
}


sqInt dir_Delete(char *pathString, sqInt pathStringLength)
{
  /* Delete the existing directory with the given path. */
  char name[MAXPATHLEN+1];
  if (pathStringLength >= MAXPATHLEN)
    return false;
  if (!sq2uxPath(pathString, pathStringLength, name, MAXPATHLEN, 1))
    return false;
  return rmdir(name) == 0;
}


sqInt dir_Delimitor(void)
{
  return DELIMITERInt;
}


static int maybeOpenDir(char *unixPath)
{
  /* if the last opendir was to the same directory, re-use the directory
     pointer from last time.  Otherwise close the previous directory,
     open the new one, and save its name.  Return true if the operation
     was successful, false if not. */
  if (!lastPathValid || strcmp(lastPath, unixPath))
    {
      /* invalidate the old, open the new */
      if (lastPathValid)
	closedir(openDir);
      lastPathValid= false;
      strcpy(lastPath, unixPath);
      if ((openDir= opendir(unixPath)) == 0)
	return false;
      lastPathValid= true;
      lastIndex= 0;	/* first entry is index 1 */
    }
  return true;
}


sqInt dir_Lookup(char *pathString, sqInt pathStringLength, sqInt index,
/* outputs: */  char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
		sqInt *isDirectory, squeakFileOffsetType *sizeIfFile)
{
  /* Lookup the index-th entry of the directory with the given path, starting
     at the root of the file system. Set the name, name length, creation date,
     creation time, directory flag, and file size (if the entry is a file).
     Return:	0 	if a entry is found at the given index
     		1	if the directory has fewer than index entries
		2	if the given path has bad syntax or does not reach a directory
  */

  int i;
  int nameLen= 0;
  struct dirent *dirEntry= 0;
  char unixPath[MAXPATHLEN+1];
  struct stat statBuf;

  /* default return values */
  *name             = 0;
  *nameLength       = 0;
  *creationDate     = 0;
  *modificationDate = 0;
  *isDirectory      = false;
  *sizeIfFile       = 0;

  if ((pathStringLength == 0))
    strcpy(unixPath, ".");
  else  {
	if (!ioFilenamefromStringofLengthresolveAliases(unixPath, pathString,pathStringLength, true))
		return BAD_PATH;
	}

  /* get file or directory info */
  if (!maybeOpenDir(unixPath))
    return BAD_PATH;

  if (++lastIndex == index)
    index= 1;		/* fake that the dir is rewound and we want the first entry */
  else
    {
      rewinddir(openDir);	/* really rewind it, and read to the index */
      lastIndex= index;
    }

  for (i= 0; i < index; i++)
    {
    nextEntry:
      do
	{ 
	  errno= 0; 
	  dirEntry= readdir(openDir);
	}
      while ((dirEntry == 0) && (errno == EINTR));

      if (!dirEntry)
	return NO_MORE_ENTRIES;
      
      nameLen= NAMLEN(dirEntry);

      /* ignore '.' and '..' (these are not *guaranteed* to be first) */
      if (nameLen < 3 && dirEntry->d_name[0] == '.')
	if (nameLen == 1 || dirEntry->d_name[1] == '.')
	  goto nextEntry;
    }

  *nameLength= ux2sqPath(dirEntry->d_name, nameLen, name, MAXPATHLEN, 0);

  {
    char terminatedName[MAXPATHLEN];
    strncpy(terminatedName, dirEntry->d_name, nameLen);
    terminatedName[nameLen]= '\0';
    strcat(unixPath, "/");
    strcat(unixPath, terminatedName);
    if (stat(unixPath, &statBuf) && lstat(unixPath, &statBuf))
      {
	/* We can't stat the entry, but failing here would invalidate
	   the whole directory --bertf */
	return ENTRY_FOUND;
      }
  }

  /* last change time */
  *creationDate= convertToSqueakTime(statBuf.st_ctime);
  /* modification time */
  *modificationDate= convertToSqueakTime(statBuf.st_mtime);
	{
		FSRef targetFSRef;
		Boolean	targetIsFolder,wasAliased;
		
		getFSRef(unixPath,&targetFSRef,kCFStringEncodingUTF8);
		FSResolveAliasFileWithMountFlags(&targetFSRef,true,&targetIsFolder,&wasAliased,kResolveAliasFileNoUI);
		if (wasAliased && targetIsFolder) {
			*isDirectory= true;
			return ENTRY_FOUND;
		}
	}
  if (S_ISDIR(statBuf.st_mode))
    *isDirectory= true;
  else
    *sizeIfFile= statBuf.st_size;

  return ENTRY_FOUND;
}


void		sqFilenameFromStringOpen(char *buffer,long fileIndex, long fileLength) {
	ioFilenamefromStringofLengthresolveAliases(buffer,(char *) fileIndex, fileLength, true);
}

sqInt	ioFilenamefromStringofLengthresolveAliases(char* dst, char* src, sqInt num, sqInt resolveAlias) {
 int bytes;
 
 bytes = sq2uxPath(src, num, dst, MAXPATHLEN, 1);
 if(resolveAlias) {
	FSRef targetFSRef;
	Boolean	targetIsFolder,wasAliased;
	
	getFSRef(dst,&targetFSRef,kCFStringEncodingUTF8);
	FSResolveAliasFileWithMountFlags(&targetFSRef,true,&targetIsFolder,&wasAliased,0);
	if (wasAliased) {
		PathToFileViaFSRef(dst, num, &targetFSRef, false,nil,kCFStringEncodingUTF8);
		bytes = strlen(dst);
	}
 }
 return bytes;
}

OSErr getFSRef(char *pathString,FSRef *theFSRef,CFStringEncoding encoding)
{	
    CFURLRef    sillyThing;
    CFStringRef tmpStrRef;
	CFMutableStringRef filePath;
    
    tmpStrRef = CFStringCreateWithBytes(kCFAllocatorDefault,(UInt8 *) pathString,
										strlen(pathString), encoding, true);
    if (tmpStrRef == nil)
        return -1000;
	filePath = CFStringCreateMutableCopy(NULL, 0, tmpStrRef);
	if (encoding == kCFStringEncodingUTF8) 
		CFStringNormalize(filePath, kCFStringNormalizationFormD);
    sillyThing = CFURLCreateWithFileSystemPath (kCFAllocatorDefault,filePath,kCFURLPOSIXPathStyle,false);
	CFRelease(tmpStrRef);
	if (sillyThing == NULL) {
		CFRelease(filePath);
		return -2000;
	}
	
    if (CFURLGetFSRef(sillyThing,theFSRef) == false) {
		Boolean check;
		UInt8	possiblePath[MAXPATHLEN+1];
		check = CFURLGetFileSystemRepresentation (sillyThing,true,possiblePath,MAXPATHLEN);
        CFRelease(filePath);
        CFRelease(sillyThing);
        return -3000;
	} 
            
    CFRelease(filePath);
	CFRelease(sillyThing);
    return 0;
}

/* Returns in gCurrentVMEncoding */

int getLastPathComponent(char *pathString,char * lastPathPart,CFStringEncoding encoding) {
    CFURLRef    sillyThing;
    CFStringRef tmpStrRef;
	CFMutableStringRef filePath;
 
    tmpStrRef = CFStringCreateWithBytes(kCFAllocatorDefault,(UInt8 *) pathString,
										strlen(pathString), encoding, true);
    if (tmpStrRef == nil)
        return -1000;
	filePath = CFStringCreateMutableCopy(NULL, 0, tmpStrRef);
	if (encoding == kCFStringEncodingUTF8) 
		CFStringNormalize(filePath, kCFStringNormalizationFormD);
    sillyThing = CFURLCreateWithFileSystemPath (kCFAllocatorDefault,filePath,kCFURLPOSIXPathStyle,false);
	CFRelease(tmpStrRef);
	CFRelease(filePath);
	if (sillyThing == NULL) 
		return -2000;
	tmpStrRef = CFURLCopyLastPathComponent(sillyThing);
    CFRelease(sillyThing);
	CFMutableStringRef mutableStr= CFStringCreateMutableCopy(NULL, 0, tmpStrRef);
	CFRelease(tmpStrRef);
	// HFS+ imposes Unicode2.1 decomposed UTF-8 encoding on all path elements
	if (gCurrentVMEncoding == kCFStringEncodingUTF8) 
		CFStringNormalize(mutableStr, kCFStringNormalizationFormKC); // pre-combined
  
	CFStringGetCString (mutableStr, lastPathPart,256, gCurrentVMEncoding);
	CFRelease(mutableStr);
	return 0;
}


/* Fill in the given string with the full path from a root volume to the given file. */
/* From FSSpec to C-string pathName */
/* FSSpec -> FSRef -> URL(Unix) -> HPFS+ */
int PathToFile(char *pathName, int pathNameMax, FSSpec *where,CFStringEncoding encoding) {        
        FSRef	theFSRef;
        OSErr	error;
        Boolean retryWithDirectory=false;
        char	rememberName[256];
        
        *pathName = 0x00;
        error = FSpMakeFSRef (where, &theFSRef);
        if (error != noErr) {
			FSSpec	failureRetry;
			
			retryWithDirectory = true;
            failureRetry = *where;
            CopyCStringToPascal(":",failureRetry.name);
            CopyPascalStringToC(where->name,(char *) &rememberName);
            error = FSpMakeFSRef(&failureRetry,&theFSRef);
            if (error != noErr) 
                return -1;
		}
        
		PathToFileViaFSRef(pathName,pathNameMax,&theFSRef,retryWithDirectory,rememberName,encoding);
        return 0;
}

void PathToFileViaFSRef(char *pathName, int pathNameMax, FSRef *theFSRef, Boolean retryWithDirectory,char * rememberName,CFStringEncoding encoding) {        
        CFURLRef sillyThing;
        CFStringRef filePath;
        Boolean isDirectory;
		
        sillyThing =  CFURLCreateFromFSRef (kCFAllocatorDefault, theFSRef);
        isDirectory = CFURLHasDirectoryPath(sillyThing);
        
        filePath = CFURLCopyFileSystemPath (sillyThing, kCFURLPOSIXPathStyle);
        CFRelease(sillyThing);
        
  		CFMutableStringRef mutableStr= CFStringCreateMutableCopy(NULL, 0, filePath);
          CFRelease(filePath);
  
  		// HFS+ imposes Unicode2.1 decomposed UTF-8 encoding on all path elements
  		if (encoding == kCFStringEncodingUTF8) 
  			CFStringNormalize(mutableStr, kCFStringNormalizationFormKC); // pre-combined
  
          CFStringGetCString (mutableStr, pathName,pathNameMax, encoding);
        
        if (retryWithDirectory) {
            strcat(pathName,"/");
            strcat(pathName,rememberName);
            isDirectory = false;
        }
        if (isDirectory)
            strcat(pathName,"/");
}


OSErr getFInfo(char *filename,FInfo *finderInfo,CFStringEncoding encoding) {
   FSRef	theFSRef;
   FSCatalogInfo catInfo;
   OSErr	err;
   
	err =  getFSRef(filename,&theFSRef,encoding);
	if (err != 0)
		return err;
    err = FSGetCatalogInfo (&theFSRef,kFSCatInfoFinderInfo,&catInfo,nil,nil,nil);
	memcpy(finderInfo,catInfo.finderInfo,sizeof(FInfo));
    return noErr;
}

int dir_SetMacFileTypeAndCreator(char *filename, int filenameSize, char *fType, char *fCreator) {
	/* Set the Macintosh type and creator of the given file. */
	/* Note: On other platforms, this is just a noop. */

    FInfo   finderInfo;
    FSCatalogInfo catInfo;
    OSErr	err;
    FSRef	theFSRef;
	char	fileNameBuffer[MAXPATHLEN+1];
	
	memcpy(fileNameBuffer,filename,filenameSize);
	fileNameBuffer[filenameSize] = 0x00;
    if (getFInfo(fileNameBuffer,&finderInfo,gCurrentVMEncoding) != noErr)
        return false;
       
	finderInfo.fdType = *((int *) fType);
	finderInfo.fdCreator = *((int *) fCreator);
	
	err =  getFSRef(fileNameBuffer,&theFSRef,gCurrentVMEncoding);
	if (err != 0)
		return err;
	memcpy(&catInfo.finderInfo,&finderInfo,8);
    err = FSSetCatalogInfo (&theFSRef,kFSCatInfoFinderInfo,&catInfo);

    return true;
}

int dir_GetMacFileTypeAndCreator(char *filename, int filenameSize, char *fType, char *fCreator) {
	/* Get the Macintosh type and creator of the given file. */
	/* Note: On other platforms, this is just a noop. */

    FInfo   finderInfo;
	char	fileNameBuffer[MAXPATHLEN+1];
	
	memcpy(fileNameBuffer,filename,filenameSize);
	fileNameBuffer[filenameSize] = 0x00;
    
    if (getFInfo(fileNameBuffer,&finderInfo,gCurrentVMEncoding) != noErr)
        return false;
       
	*((int *) fType) = finderInfo.fdType;
	*((int *) fCreator) = finderInfo.fdCreator;

	return true;
}

OSStatus SetVMPathFromApplicationDirectory() {
	CFBundleRef mainBundle;
	CFURLRef	bundleURL,bundleURLPrefix;
	CFStringRef filePath;

	CFMutableStringRef vmPathString;
	mainBundle = CFBundleGetMainBundle();   
	bundleURL = CFBundleCopyBundleURL(mainBundle);
	bundleURLPrefix = CFURLCreateCopyDeletingLastPathComponent(NULL,bundleURL);
	CFRelease(bundleURL);	
	filePath = CFURLCopyFileSystemPath (bundleURLPrefix, kCFURLPOSIXPathStyle);
	CFRelease(bundleURLPrefix);	
	vmPathString = CFStringCreateMutableCopy(NULL, 0, filePath);
	CFStringAppendCString(vmPathString, "/", kCFStringEncodingMacRoman);
	SetVMPathFromCFString(vmPathString);
	CFRelease(filePath);
	
	return 0;		
}

pascal Boolean findImageFilterProc(AEDesc* theItem, void* info, 
                            NavCallBackUserData callBackUD,
                            NavFilterModes filterMode);
							
OSErr squeakFindImage(char* pathName)
{
    NavDialogCreationOptions    dialogOptions;
    NavObjectFilterUPP  filterProc =  NewNavObjectFilterUPP(findImageFilterProc);
    OSErr               anErr = noErr;
    NavDialogRef		navDialog;
	FSRef fileAsFSRef;
	
    //  Specify default options for dialog box
    anErr = NavGetDefaultDialogCreationOptions(&dialogOptions);
    if (anErr != noErr)
		return anErr;
		

	//  Adjust the options to fit our needs
	//  Set default location option
	dialogOptions.optionFlags |= kNavSelectDefaultLocation;
	dialogOptions.optionFlags  |= kNavAllFilesInPopup;
	dialogOptions.optionFlags  |= kNavSelectAllReadableItem;
	//  Clear preview option
	dialogOptions.optionFlags  ^= kNavAllowPreviews;
	
				
	// Call NavGetFile() with specified options and
	// declare our app-defined functions and type list
	NavCreateChooseFileDialog (
			&dialogOptions,
			nil,
			nil,
			nil,
			filterProc,
			nil,
			&navDialog);
	anErr = NavDialogRun (navDialog);
	if (anErr != noErr )
		return anErr;
		
	NavReplyRecord outReply;
	anErr = NavDialogGetReply (navDialog,&outReply);
	if (anErr != noErr )
		return anErr;
		
	// Get the file
	anErr = AEGetNthPtr(&(outReply.selection), 1, typeFSRef, NULL, NULL, &fileAsFSRef, sizeof(FSRef), NULL);
	//  Dispose of NavReplyRecord, resources, descriptors
	anErr = NavDisposeReply(&outReply);
	PathToFileViaFSRef(pathName,MAXPATHLEN, &fileAsFSRef, false,NULL,gCurrentVMEncoding);

    DisposeNavObjectFilterUPP(filterProc);
    return anErr;
}


pascal Boolean findImageFilterProc(AEDesc* theItem, void* info, 
                            NavCallBackUserData callBackUD,
                            NavFilterModes filterMode)
{
#pragma unused(filterMode,callBackUD)
    NavFileOrFolderInfo* theInfo = (NavFileOrFolderInfo*)info;
    
    if (theItem->descriptorType == typeFSRef) {
        char checkSuffix[256];
        OSErr 	error;
        Boolean check;
		FSRef theFSRef;
        FSSpec	theSpec;
		
        if (theInfo->isFolder)
            return true;
            
        if (theInfo->fileAndFolder.fileInfo.finderInfo.fdType == 'STim')
            return true;
            
        error = AEGetDescData(theItem,&theFSRef,sizeof(FSRef));
        if (error != noErr) 
            return true;
		error = FSGetCatalogInfo (&theFSRef,kFSCatInfoNone,nil,nil,&theSpec,nil);
        if (error != noErr) 
            return true;
       
        CopyPascalStringToC(theSpec.name,checkSuffix);
        check = IsImageName(checkSuffix);
        if (check) 
            return true;
        else
            return false;
    }
    return true;
}

