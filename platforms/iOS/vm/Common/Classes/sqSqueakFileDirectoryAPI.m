//
//  sqSqueakFileDirectoryAPI.m
//  
//
//  Created by John M McIntosh on 6/14/08.
//
//
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
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

V1.05b1 Add auto release pool to wrap getting directory information
V1.05b1 fix issue with sqGetFilenameFromString when getting target of symbolic link ensure we make a copy
 */
//

#import "sqSqueakFileDirectoryAPI.h"
#import "sqSqueakAppDelegate.h"
#import "sq.h"
#import "FilePlugin.h"

#define DELIMITERInt '/'

extern sqSqueakAppDelegate *gDelegateApp;

sqInt dir_GetMacFileTypeAndCreator(char *filename, sqInt filenameSize, char *fType, char *fCreator){
	//API Documented
	/* filename is file name
	 filenameSize is size of file name
	 fType and fCreator is type and creator codes (4 bytes preallocated)
	 */
    @autoreleasepool {
    sqInt status = [gDelegateApp.squeakApplication.fileDirectoryLogic dir_GetMacFileTypeAndCreator: filename
                                                                                          fileNameSize: filenameSize
                                                                                                 fType: fType
                                                                                              fCreator: fCreator];
    return status;
    }
}

sqInt dir_SetMacFileTypeAndCreator(char *filename, sqInt filenameSize, char *fType, char *fCreator) {
	//API Documented
	/* filename is file name
	 filenameSize is size of file name
	 fType and fCreator is type and creator codes (4 bytes)
	 */
	@autoreleasepool {
        sqInt status = [gDelegateApp.squeakApplication.fileDirectoryLogic dir_SetMacFileTypeAndCreator: filename
			fileNameSize: filenameSize
			fType: fType
			fCreator: fCreator];

	return status;
    }
}

sqInt dir_Delimitor(void)
{
	//API Documented
	return DELIMITERInt;
}
sqInt dir_Lookup2(char *pathString, sqInt pathStringLength, sqInt index,
                  /* outputs */
                  char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
                  sqInt *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt *posixPermissions, sqInt *isSymlink);
#if !defined(PharoVM)
# define PharoVM 0
#endif

#if PharoVM
sqInt dir_Lookup(char *pathString, sqInt pathStringLength, sqInt index,
                 /* outputs: */
                 char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
                 sqInt *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt *posixPermissionsVar, sqInt *isSymlinkVar)
#else
sqInt dir_Lookup(char *pathString, sqInt pathStringLength, sqInt index,
                 /* outputs: */
                 char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
                 sqInt *isDirectory, squeakFileOffsetType *sizeIfFile)
#define posixPermissionsVar nil
#define isSymlinkVar nil
#endif
{
    @autoreleasepool {
        sqInt status = dir_Lookup2(pathString, pathStringLength, index, name, nameLength, creationDate, modificationDate, isDirectory, sizeIfFile,posixPermissionsVar,isSymlinkVar);
        return status;
    }
}


sqInt dir_Lookup2(char *pathString, sqInt pathStringLength, sqInt index,
                 /* outputs */
                 char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
				 sqInt *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt *posixPermissions, sqInt *isSymlink)
{
	//API Documented
	/* Lookup the index-th entry of the directory with the given path, starting
	 at the root of the file system. Set the name, name length, creation date,
	 creation time, directory flag, and file size (if the entry is a file).
	 Return:	0 	if a entry is found at the given index
	 1	if the directory has fewer than index entries
	 2	if the given path has bad syntax or does not reach a directory
	 */
	
	/*Implementation notes
	 if pathStringLength = 0 then we use the current working directory
	 if pathStringLength > 0 then we resolve the pathString and alias */
    sqInt status =
			[gDelegateApp.squeakApplication.fileDirectoryLogic dir_Lookup: pathString 
			length: pathStringLength 
			index:  index 
			name:  name
			length: nameLength 
			creationDate: creationDate 
			modificationDate: modificationDate
			isDirectory: isDirectory
			sizeIfFile: sizeIfFile
            posixPermissions: posixPermissions
            isSymlink: isSymlink];
	return status;
}

#if PharoVM
sqInt dir_EntryLookup(char *pathString, sqInt pathStringLength, char* nameString, sqInt nameStringLength,
                      /* outputs: */
                      char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
                      sqInt *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt *posixPermissionsVar, sqInt *isSymlinkVar)
#else
sqInt dir_EntryLookup(char *pathString, sqInt pathStringLength, char* nameString, sqInt nameStringLength,
                      /* outputs: */
                      char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
                      sqInt *isDirectory, squeakFileOffsetType *sizeIfFile)
#endif
{

	/*Implementation notes
	 if pathStringLength = 0 then we use the current working directory
	 if pathStringLength > 0 then we resolve the pathString and alias */
    @autoreleasepool {
     sqInt status =
	[gDelegateApp.squeakApplication.fileDirectoryLogic
				  dir_EntryLookup: pathString 
						   length: pathStringLength 
							returnName: nameString
					  returnNameLength: nameStringLength	
							 name: name
						   length: nameLength 
					 creationDate: creationDate 
				 modificationDate: modificationDate
					  isDirectory: isDirectory
					   sizeIfFile: sizeIfFile
				 posixPermissions: (PharoVM ? posixPermissionsVar : nil)
						isSymlink:  (PharoVM ? isSymlinkVar : nil)];
	return status;
    }
}

sqInt dir_Create(char *pathString, sqInt pathStringLength){
	//API Documented
        @autoreleasepool {
	sqInt status = [gDelegateApp.squeakApplication.fileDirectoryLogic
			dir_Create: pathString 
			length: pathStringLength];
	return status;
        }
}

sqInt dir_Delete(char *pathString, sqInt pathStringLength){
	    @autoreleasepool {
            sqInt status = [gDelegateApp.squeakApplication.fileDirectoryLogic
			dir_Delete: pathString 
			length: pathStringLength];
	return status;
        }
}

NSString* createFilePathFromString(char * aFilenameString,
									sqInt filenameLength, sqInt resolveAlias) {
	NSString * filePath = AUTORELEASEOBJ([[NSString alloc] initWithBytes: aFilenameString length: (NSUInteger) filenameLength encoding: NSUTF8StringEncoding]);
	if (!filePath) {
		return NULL;
	}
	
	if (resolveAlias) {
		filePath = [gDelegateApp.squeakApplication.fileDirectoryLogic resolvedAliasFiles: filePath];
	} else {
		NSString *owningDirectoryPath = [filePath stringByDeletingLastPathComponent];
		NSString *newFilePath = [gDelegateApp.squeakApplication.fileDirectoryLogic resolvedAliasFiles: owningDirectoryPath];
		filePath = [newFilePath stringByAppendingPathComponent: [filePath lastPathComponent]];
	}
	return filePath;
}

sqInt sqGetFilenameFromString(char * aCharBuffer, char * aFilenameString,
							  sqInt filenameLength, sqInt resolveAlias) {
	//API Documented
    @autoreleasepool {
	BOOL ok;
	
	if (!aCharBuffer || !aFilenameString)
		return 0;

	NSString *filePath = createFilePathFromString(aFilenameString,filenameLength,resolveAlias);
	
	ok = [filePath getFileSystemRepresentation: aCharBuffer maxLength: 1000];  
	//1000 is coded by callers, really should pass in, but historical issue, this also includes null byte which is accounted for by maxLength
	//Obviously this is a problem that lets a caller do a buffer overflow? 
    }
	return 0;
}

/* This routine is exposed but no-one seems to call it from the VM
 in the past the macintosh VM used this to set the working directory based
 on where the VM was opened from, but it seems now post os-x no-one uses it */

sqInt dir_PathToWorkingDir(char *pathName, sqInt pathNameMax){
	//API Documented
	return 0;
}
