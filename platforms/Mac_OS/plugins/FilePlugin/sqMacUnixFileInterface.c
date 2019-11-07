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
#include "sqUnixCharConv.h"

	extern CFStringEncoding gCurrentVMEncoding;

/* sqUnixFile.c -- directory operations for Unix
 * 
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 */

/* Author: Ian.Piumarta@INRIA.Fr
 * 

 3.8.15b3  Feb 19th, 2007 JMM fix bug with crash on bogus file path.
 3.8.17b4  Apr 27th, 2007 JMM note from Tetsuya HAYASHI, tetha@st.rim.or.jp, tetha@mac.com
						I've found the latest mac vm (or recent version) fails to normalize UTF file name.
						It seems to be the function convertChars() of sqMacUnixFileInterface.c, which normalizes only decompose when converting squeak string to unix, but I think it needs pre-combined when unix string to squeak, and I noticed normalization form should be canonical (exactly should be kCFStringNormalizationFormC) for pre-combined.

 */

#include "sq.h"
#include "FilePlugin.h"
#include "sqUnixCharConv.h"
#include "sqMacEncoding.h"
#include "sqMacTime.h"
#include "sqMacImageIO.h"

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
static char lastPath[DOCUMENT_NAME_SIZE+1];
static int  lastPathValid = false;
static int  lastIndex= -1;
static DIR *openDir= 0;


/*** Functions ***/

int convertChars(char *from, int fromLen, void *fromCode, char *to, int toLen, void *toCode, int norm, int term);
sqInt	ioFilenamefromStringofLengthresolveAliasesRetry(char* dst, char* src, sqInt num, sqInt resolveAlias, Boolean retry);
static CFURLRef makeFileSystemURLFromString(char *pathString,int length,CFStringEncoding encoding);
static OSErr getFInfo(char *filename,FSCatalogInfo *catInfo,CFStringEncoding encoding);
OSStatus SetVMPathFromApplicationDirectory();

sqInt
dir_Create(char *pathString, sqInt pathStringLength)
{
  /* Create a new directory with the given path. By default, this
     directory is created relative to the cwd. */
  char name[DOCUMENT_NAME_SIZE+1];
  if (pathStringLength >= DOCUMENT_NAME_SIZE)
    return false;
  if (!ioFilenamefromStringofLengthresolveAliasesRetry(name,pathString, pathStringLength, false, true))
     return false;
  return mkdir(name, 0777) == 0;	/* rwxrwxrwx & ~umask */
}


sqInt
dir_Delete(char *pathString, sqInt pathStringLength)
{
  /* Delete the existing directory with the given path. */
  char name[DOCUMENT_NAME_SIZE+1];
  if (pathStringLength >= DOCUMENT_NAME_SIZE)
    return false;
  if (!ioFilenamefromStringofLengthresolveAliasesRetry(name,pathString, pathStringLength, false, true))
    return false;
  if (strcmp(lastPath, name) == 0)
		lastPath[0] = 0x00;
		
  return rmdir(name) == 0;
}


sqInt
dir_Delimitor(void)
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


sqInt
dir_Lookup(char *pathString, sqInt pathStringLength, sqInt index,
/* outputs: */  char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
		sqInt *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt *posixPermissions, sqInt *isSymlink)
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
  char unixPath[DOCUMENT_NAME_SIZE+1];
  struct stat statBuf;

  /* default return values */
  *name             = 0;
  *nameLength       = 0;
  *creationDate     = 0;
  *modificationDate = 0;
  *isDirectory      = false;
  *sizeIfFile       = 0;

  if (pathStringLength == 0)
    strcpy(unixPath, ".");
  else  {
	if (!ioFilenamefromStringofLengthresolveAliasesRetry(unixPath, pathString,pathStringLength, true, true))
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

  *nameLength= ux2sqPath(dirEntry->d_name, nameLen, name, 256, 0);

  {
    char terminatedName[DOCUMENT_NAME_SIZE+1];
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
		OSErr err;
		
		err = getFSRef(unixPath,&targetFSRef,kCFStringEncodingUTF8);
		if (!err) {
			FSResolveAliasFileWithMountFlags(&targetFSRef,true,&targetIsFolder,&wasAliased,kResolveAliasFileNoUI);
			if (wasAliased && targetIsFolder) {
				*isDirectory= true;
				return ENTRY_FOUND;
			}
		}
	}
  if (S_ISDIR(statBuf.st_mode))
    *isDirectory= true;
  else
    *sizeIfFile= statBuf.st_size;

  return ENTRY_FOUND;
}

sqInt
dir_EntryLookup(char *pathString, sqInt pathStringLength, char* nameString, sqInt nameStringLength,
/* outputs: */  char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
		sqInt *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt *posixPermissions, sqInt *isSymlink)
{
  /* Lookup the given name in the given directory,
     Set the name, name length, creation date,
     creation time, directory flag, and file size (if the entry is a file).
     Return:	0 	if a entry is found at the given index
     		1	if there is no such entry in the directory
		2	if the given path has bad syntax or does not reach a directory
  */
  
  char unixPath[DOCUMENT_NAME_SIZE+1];
  struct stat statBuf;

  /* default return values */
  *name             = 0;
  *nameLength       = 0;
  *creationDate     = 0;
  *modificationDate = 0;
  *isDirectory      = false;
  *sizeIfFile       = 0;

  if (pathStringLength == 0)
    strcpy(unixPath, ".");
  else  {
	if (!ioFilenamefromStringofLengthresolveAliasesRetry(unixPath, pathString,pathStringLength, true, true))
		return BAD_PATH;
	}

  char terminatedName[DOCUMENT_NAME_SIZE+1];
  strncpy(terminatedName, nameString, nameStringLength);
  terminatedName[nameStringLength]= '\0';
  strcat(unixPath, "/");
  strcat(unixPath, terminatedName);
  if (stat(unixPath, &statBuf) && lstat(unixPath, &statBuf)) {
	return NO_MORE_ENTRIES;
  }

  /* To match the results of dir_Lookup, copy back the file name */
  *nameLength = ux2sqPath(nameString, nameStringLength, name, 256, 0);

  /* last change time */
  *creationDate= convertToSqueakTime(statBuf.st_ctime);
  /* modification time */
  *modificationDate= convertToSqueakTime(statBuf.st_mtime);
	{
		FSRef targetFSRef;
		Boolean	targetIsFolder,wasAliased;
		OSErr err;
		err = getFSRef(unixPath,&targetFSRef,kCFStringEncodingUTF8);
		if (!err) {
			FSResolveAliasFileWithMountFlags(&targetFSRef,true,&targetIsFolder,&wasAliased,kResolveAliasFileNoUI);
			if (wasAliased && targetIsFolder) {
				*isDirectory= true;
				return ENTRY_FOUND;
			}
		}
	}
  if (S_ISDIR(statBuf.st_mode))
    *isDirectory= true;
  else
    *sizeIfFile= statBuf.st_size;

  return ENTRY_FOUND;
}


int wanderDownPath(char *src,int bytes,char *possiblePath, Boolean resolveLastAlias);

sqInt sqGetFilenameFromString(char * aCharBuffer, char * aFilenameString, sqInt filenameLength, sqInt aBoolean){
	ioFilenamefromStringofLengthresolveAliasesRetry(aCharBuffer,(char *) aFilenameString, filenameLength, aBoolean, true);
	return 0;
}

void		sqFilenameFromStringOpen(char *buffer,sqInt fileIndex, long fileLength) {
	ioFilenamefromStringofLengthresolveAliasesRetry(buffer,(char *) fileIndex, fileLength, true, true);
}

void		sqFilenameFromString(char *buffer,sqInt fileIndex, long fileLength) {
	ioFilenamefromStringofLengthresolveAliasesRetry(buffer,(char *) fileIndex, fileLength, false, true);
}

sqInt	ioFilenamefromStringofLengthresolveAliasesRetry(char* dst, char* src, sqInt num, sqInt resolveAlias, Boolean retry) {
 int		bytes;
 FSRef targetFSRef;
 OSStatus err; 
 
 if (retry)
	bytes = sq2uxPath(src, num, dst, DOCUMENT_NAME_SIZE, 1);
 else {
	memcpy(dst,src,num);
	dst[num] = 0x00;
	bytes = num;
 }
  		
 err = getFSRef(dst,&targetFSRef,kCFStringEncodingUTF8); 
 if (retry) {
	if (err) {
		char possiblePath[DOCUMENT_NAME_SIZE+1];
		
		bytes = wanderDownPath(dst,bytes,possiblePath,resolveAlias);
		if (bytes) 
			strcpy(dst,possiblePath);
		return bytes;
	}
 }

  if (err == 0 && resolveAlias) {
		Boolean	targetIsFolder,wasAliased;
		err = FSResolveAliasFileWithMountFlags(&targetFSRef,true,&targetIsFolder,&wasAliased,kResolveAliasFileNoUI);
		if (err || wasAliased == false)
			return bytes; 
		PathToFileViaFSRef(dst, DOCUMENT_NAME_SIZE, &targetFSRef,kCFStringEncodingUTF8);
		bytes = strlen(dst);
	 }
  
 return bytes;
}

static CFURLRef makeFileSystemURLFromString(char *pathString,int length, CFStringEncoding encoding) {
    CFStringRef tmpStrRef;
 	CFMutableStringRef filePath;
    CFURLRef    sillyThing;
	
	tmpStrRef = CFStringCreateWithBytes(kCFAllocatorDefault,(UInt8 *) pathString,
										length, encoding, true);
    if (tmpStrRef == nil)
        return null;
	filePath = CFStringCreateMutableCopy(NULL, 0, tmpStrRef);
	CFRelease(tmpStrRef);
	if (encoding == kCFStringEncodingUTF8) 
		CFStringNormalize(filePath, kCFStringNormalizationFormD); 
    sillyThing = CFURLCreateWithFileSystemPath (kCFAllocatorDefault,filePath,kCFURLPOSIXPathStyle,false);
	CFRelease(filePath);
	return sillyThing;
}

OSErr getFSRef(char *pathString,FSRef *theFSRef,CFStringEncoding encoding)
{	
    CFURLRef sillyThing;

	sillyThing = makeFileSystemURLFromString(pathString,strlen(pathString),encoding);
	if (sillyThing == NULL) {
		return -2000;
	}
	
    if (CFURLGetFSRef(sillyThing,theFSRef) == false) {		
        CFRelease(sillyThing);
        return -3000;
	} 
            
	CFRelease(sillyThing);
    return 0;
}

/* Returns in gCurrentVMEncoding */

int getLastPathComponentInCurrentEncoding(char *pathString,char * lastPathPart,CFStringEncoding encoding) {
    CFURLRef    sillyThing;
    CFStringRef tmpStrRef;

	sillyThing = makeFileSystemURLFromString(pathString,strlen(pathString),encoding);
	if (sillyThing == NULL) 
		return -2000;
	tmpStrRef = CFURLCopyLastPathComponent(sillyThing);
    CFRelease(sillyThing);
	CFMutableStringRef mutableStr= CFStringCreateMutableCopy(NULL, 0, tmpStrRef);
	CFRelease(tmpStrRef);
	// HFS+ imposes Unicode2.1 decomposed UTF-8 encoding on all path elements
	if (gCurrentVMEncoding == kCFStringEncodingUTF8) 
		CFStringNormalize(mutableStr, kCFStringNormalizationFormC); // pre-combined
  
	CFStringGetCString (mutableStr, lastPathPart,256, gCurrentVMEncoding);
	CFRelease(mutableStr);
	return 0;
}



void PathToFileViaFSRef(char *pathName, int pathNameMax, FSRef *theFSRef,CFStringEncoding encoding) {        
        CFURLRef sillyThing;
        CFStringRef filePath;
        Boolean isDirectory;
		
		pathName[0]=  0x00;
        sillyThing =  CFURLCreateFromFSRef (kCFAllocatorDefault, theFSRef);
		if (sillyThing == NULL)
			return;
        isDirectory = CFURLHasDirectoryPath(sillyThing);
        
        filePath = CFURLCopyFileSystemPath (sillyThing, kCFURLPOSIXPathStyle);
        CFRelease(sillyThing);
        
  		CFMutableStringRef mutableStr= CFStringCreateMutableCopy(NULL, 0, filePath);
          CFRelease(filePath);
  
  		// HFS+ imposes Unicode2.1 decomposed UTF-8 encoding on all path elements
  		if (encoding == kCFStringEncodingUTF8) 
  			CFStringNormalize(mutableStr, kCFStringNormalizationFormC); // pre-combined
  
          CFStringGetCString (mutableStr, pathName,pathNameMax, encoding);
			CFRelease(mutableStr);
        
        if (isDirectory)
            strcat(pathName,"/");
}


static OSErr getFInfo(char *filename,FSCatalogInfo *catInfo,CFStringEncoding encoding) {
   FSRef	theFSRef;
   OSErr	err;
   
	err =  getFSRef(filename,&theFSRef,encoding);
	if (err != 0)
		return err;
    err = FSGetCatalogInfo (&theFSRef,kFSCatInfoFinderInfo,catInfo,nil,nil,nil);
    return noErr;
}

OSErr getFInfoViaFSRef(FSRef *theFSRef,	FInfo *finderInfo) {
   OSErr	err;
	FSCatalogInfo catInfo;
	
	err = FSGetCatalogInfo (theFSRef,kFSCatInfoFinderInfo,&catInfo,nil,nil,nil);
	memcpy(finderInfo,&catInfo.finderInfo,sizeof(FInfo));	
	return err;
	
}
sqInt
dir_SetMacFileTypeAndCreator(char *filename, sqInt filenameSize, char *fType, char *fCreator) {
	/* Set the Macintosh type and creator of the given file. */
	/* Note: On other platforms, this is just a noop. */

    FSCatalogInfo catInfo;
	FInfo	finderInfo;
    OSErr	err;
    FSRef	theFSRef;
	char	fileNameBuffer[DOCUMENT_NAME_SIZE+1];
	int		bytes;
	
 	bytes = ioFilenamefromStringofLengthresolveAliasesRetry(fileNameBuffer,filename, filenameSize, true, true);
	if (bytes == 0) 
		return false;
    if (getFInfo(fileNameBuffer,&catInfo,kCFStringEncodingUTF8) != noErr)
        return false;
	memcpy(&finderInfo,&catInfo.finderInfo,16);
	finderInfo.fdType = CFSwapInt32HostToBig(*((int *) fType));
	finderInfo.fdCreator = CFSwapInt32HostToBig(*((int *) fCreator));
	memcpy(&catInfo.finderInfo,&finderInfo,16);
	
	err =  getFSRef(fileNameBuffer,&theFSRef,kCFStringEncodingUTF8);
	if (err != 0)
		return err;
   err = FSSetCatalogInfo (&theFSRef,kFSCatInfoFinderInfo,&catInfo);

    return true;
}

sqInt
dir_GetMacFileTypeAndCreator(char *filename, sqInt filenameSize, char *fType, char *fCreator) {
	/* Get the Macintosh type and creator of the given file. */
	/* Note: On other platforms, this is just a noop. */

    FSCatalogInfo catInfo;
	FInfo	finderInfo;
	char	fileNameBuffer[DOCUMENT_NAME_SIZE+1];
	int		bytes;
	
 	bytes = ioFilenamefromStringofLengthresolveAliasesRetry(fileNameBuffer,filename, filenameSize, true, true);
	if (bytes == 0) 
		return false;
    
    if (getFInfo(fileNameBuffer,&catInfo,kCFStringEncodingUTF8) != noErr)
        return false;
		
	memcpy(&finderInfo,&catInfo.finderInfo,16);
	*((int *) fType) = CFSwapInt32BigToHost(finderInfo.fdType);
	*((int *) fCreator) = CFSwapInt32BigToHost(finderInfo.fdCreator);

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
	CFRelease(vmPathString);
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
	
    DisposeNavObjectFilterUPP(filterProc);
	NavDialogDispose(navDialog);	
		
	if (anErr != noErr)
		return anErr;
		
	if (!outReply.validRecord) {
		anErr = NavDisposeReply(&outReply);
		return -1;
	}

	// Get the file
	anErr = AEGetNthPtr(&(outReply.selection), 1, typeFSRef, NULL, NULL, &fileAsFSRef, sizeof(FSRef), NULL);
	PathToFileViaFSRef(pathName,DOCUMENT_NAME_SIZE, &fileAsFSRef, gCurrentVMEncoding);

	//  Dispose of NavReplyRecord, resources, descriptors
	anErr = NavDisposeReply(&outReply);

    return 0;
}


pascal Boolean findImageFilterProc(AEDesc* theItem, void* info, 
                            NavCallBackUserData callBackUD,
                            NavFilterModes filterMode)
{
#pragma unused(filterMode,callBackUD)
    NavFileOrFolderInfo* theInfo = (NavFileOrFolderInfo*)info;
    
    if (theItem->descriptorType == typeFSRef) {
        char checkSuffix[256],pathName[1024];
        OSErr 	error;
        Boolean check;
		FSRef theFSRef;
		
        if (theInfo->isFolder)
            return true;
            
        if (theInfo->fileAndFolder.fileInfo.finderInfo.fdType == 'STim')
            return true;
            
        error = AEGetDescData(theItem,&theFSRef,sizeof(FSRef));
		if (error != noErr) 
            return true;
		PathToFileViaFSRef(pathName, 1024, &theFSRef,kCFStringEncodingUTF8);
		getLastPathComponentInCurrentEncoding(pathName,checkSuffix,kCFStringEncodingUTF8);        
        check = IsImageName(checkSuffix);

        if (check) 
            return true;
        else {
           return false;
		}
    }
    return true;
}

int wanderDownPath(char *src,int bytes,char *parts,Boolean resolveLastAlias) {
	char tokens[DOCUMENT_NAME_SIZE+1],results[DOCUMENT_NAME_SIZE+1];
	Boolean firstTime =  true;
	char *token,*nexttoken;
	int	tokenLength,numberOfBytes;
	
	parts[0] = 0x00;
	memcpy(tokens,src,bytes);
	tokens[bytes] = 0x00;
	token = strtok((char*) tokens,"/");
    if (token == 0) 
		return 0;
    while (token)  {
        tokenLength = strlen(token);
        if (firstTime) {
            firstTime = false;
			strcat(parts,"/");
			strcat(parts,token);
			numberOfBytes = ioFilenamefromStringofLengthresolveAliasesRetry(results, parts, strlen(parts), true, false);
			strcat(parts,"/");
			if (numberOfBytes) {
				strcpy(parts,results);
			} else {
				strcpy(parts,token);
			}
			token = strtok(nil,"/"); 
         } else {
			if (parts[strlen(parts)-1] != '/')
				strcat(parts,"/");
			strcat(parts,token);
			nexttoken = strtok(nil,"/"); 
			if (nexttoken == nil) 
				numberOfBytes = ioFilenamefromStringofLengthresolveAliasesRetry(results, parts, strlen(parts), resolveLastAlias, false);
			else
				numberOfBytes = ioFilenamefromStringofLengthresolveAliasesRetry(results, parts, strlen(parts), true, false);
			if (numberOfBytes) 
				strcpy(parts,results);
			else 
				strcpy(parts,token);
			token = nexttoken;
         }
    }
	return strlen(parts);
}

  int sq2uxPath(char *from, int fromLen, char *to, int toLen, int term)	
  {			
	CFStringEncoding unixEncoding = kCFStringEncodingUTF8;
    int n= convertChars(from, fromLen, (char *) gCurrentVMEncoding, to, toLen,(char *)  unixEncoding, true, term);		
    return n;									
  }

  int ux2sqPath(char *from, int fromLen, char *to, int toLen, int term)	
  {										
	CFStringEncoding unixEncoding = kCFStringEncodingUTF8;
    int n= convertChars(from, fromLen,(char *)  unixEncoding, to, toLen, (char *) gCurrentVMEncoding, false, term);		
    return n;									
  }

#define min(X, Y) (  ((X)>(Y)) ? (Y) : (X) )

static int convertCopy(char *from, int fromLen, char *to, int toLen, int term)
{
  int len= min(toLen - term, fromLen);
  strncpy(to, from, len);
  if (term) to[len]= '\0';
  return len;
}

int convertChars(char *from, int fromLen, void *fromCode, char *to, int toLen, void *toCode, int norm, int term)
{
  CFStringRef	     cfs= CFStringCreateWithBytes(NULL, (UInt8 *) from, fromLen, (CFStringEncoding)fromCode, 0);
  if (cfs == NULL) {
      toLen = 0;
	  to[toLen]= '\0';
	  return toLen;
	}
	
  CFMutableStringRef str= CFStringCreateMutableCopy(NULL, 0, cfs);
  CFRelease(cfs);
  if (norm) // HFS+ imposes Unicode2.1 decomposed UTF-8 encoding on all path elements
    CFStringNormalize(str, kCFStringNormalizationFormD); // canonical decomposition
  else
    CFStringNormalize(str, kCFStringNormalizationFormC); // pre-combined
  {
    CFRange rng= CFRangeMake(0, CFStringGetLength(str));
    CFIndex len= 0;
    CFIndex num= CFStringGetBytes(str, rng, (CFStringEncoding)toCode, '?', 0, (UInt8 *)to, toLen - term, &len);
    CFRelease(str);
    if (!num)
      return convertCopy(from, fromLen, to, toLen, term);
    if (term)
      to[len]= '\0';
    return len;
  }
}
