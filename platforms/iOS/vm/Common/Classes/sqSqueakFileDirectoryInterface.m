//
//  sqSqueakFileDirectoryInterface.m
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
*/
//

#import "sqSqueakFileDirectoryInterface.h"
#import "sqSqueakFileDirectoryAPI.h"

@implementation sqSqueakFileDirectoryInterface
@synthesize lastPathForDirLookup;
@synthesize lastIndexForDirLookup;
@synthesize directoryContentsForDirLookup;

- (BOOL) setWorkingDirectory {
	//	"changeCurrentDirectoryPath:("
	return YES;
}

- (sqInt) dir_EntryLookup: (const char *) pathString 
			  length: (sqInt) pathStringLength 
		  returnName: (char *) nameString
	returnNameLength: (sqInt) nameStringLength	
				name: (char *) name
			  length: (sqInt *) nameLength 
		creationDate: (sqInt *) creationDate 
	modificationDate: (sqInt *) modificationDate
		 isDirectory: (sqInt *) isDirectory 
		  sizeIfFile: (squeakFileOffsetType *) sizeIfFile {
#warning this is not implementation
	return 0;
}


- (sqInt) dir_Lookup: (const char *) pathString 
			  length: (sqInt) pathStringLength 
			   index: (sqInt) index 
				name: (char *) name
			  length: (sqInt *) nameLength 
		creationDate: (sqInt *) creationDate 
	modificationDate: (sqInt *) modificationDate
		 isDirectory: (sqInt *) isDirectory 
		  sizeIfFile: (squeakFileOffsetType *) sizeIfFile {
	
	NSFileManager * fileMgr = [NSFileManager defaultManager];
	NSString*	directoryPath = NULL;
	NSString*	filePath;
	NSString*	fileName;
	NSDictionary * fileAttributes;
	BOOL		readDirectory = false;
	
	/*** Constants ***/
	
#define ENTRY_FOUND     0
#define NO_MORE_ENTRIES 1
#define BAD_PATH        2
	
	
	/* default return values */
	*name             = 0;
	*nameLength       = 0;
	*creationDate     = 0;
	*modificationDate = 0;
	*isDirectory      = false;
	*sizeIfFile       = 0;

	if (pathStringLength <= 0) {
		self.lastPathForDirLookup =[fileMgr currentDirectoryPath];
	}
	
	if (pathStringLength > 0) 
		directoryPath = [[NSString alloc] initWithBytes: pathString length: (NSUInteger) pathStringLength encoding: NSUTF8StringEncoding];
	if (directoryPath == NULL)
		return BAD_PATH;
	
	if ([self.lastPathForDirLookup isEqualToString: directoryPath]) {
		if (lastIndexForDirLookup >= index)
			readDirectory = true;
	} else {
		readDirectory = true;
	}
	
	if (readDirectory) {
		self.directoryContentsForDirLookup = [fileMgr contentsOfDirectoryAtPath: directoryPath error: NULL];
		
		if (!directoryContentsForDirLookup) {
			NSString *newFilePath = [self resolvedAliasFiles: directoryPath];
			self.directoryContentsForDirLookup = [fileMgr contentsOfDirectoryAtPath: newFilePath error: NULL];
			if (!directoryContentsForDirLookup) {
				return BAD_PATH;
			} else {
				self.lastPathForDirLookup = directoryPath;
			}
		} else {
			self.lastPathForDirLookup = directoryPath;
		}
	}
		
	lastIndexForDirLookup = index;  //Note index is 1 based, but objc is 0 based
	
	if (index < 1 || (NSUInteger) index > [directoryContentsForDirLookup count])
		return NO_MORE_ENTRIES;
	
	filePath = directoryContentsForDirLookup[(NSUInteger) (index-1)];
	filePath = [[ lastPathForDirLookup stringByAppendingString: @"/"] stringByAppendingString: filePath] ;
	fileName = [[filePath lastPathComponent] precomposedStringWithCanonicalMapping];
	strlcpy(name,[fileName UTF8String],256);
	*nameLength = (sqInt) strlen(name);

	//This minics the unix port where we resolve the file name, but the symbolic file lookup can fail. 
	//The unix port says, oh file was there, but stat/lstat fails, so mmm kinda continue
	//However to deal with Finder Aliases we have to be more clever.
	
	NSError *error;
	NSString *fileType;
	NSString *newFilePath = [self resolvedAliasFiles: filePath];
	
	fileAttributes = [fileMgr attributesOfItemAtPath: filePath error: &error];  

	if ([filePath isEqualToString: newFilePath]) {
		if (!fileAttributes) {
			return ENTRY_FOUND;
		}
		fileType = fileAttributes[NSFileType];
		*isDirectory = [fileType isEqualToString: NSFileTypeDirectory] ? 1 : 0;
	} else {
		NSDictionary *fileAttributesPossibleAlias = [fileMgr attributesOfItemAtPath: newFilePath error: &error];  // do symbolic link
		if (!fileAttributes) 
			fileAttributes = fileAttributesPossibleAlias;
		
		fileType = fileAttributesPossibleAlias[NSFileType];
		*isDirectory = [fileType isEqualToString: NSFileTypeDirectory] ? 1 : 0;
	}

	*creationDate = convertToSqueakTime(fileAttributes[NSFileCreationDate]);
	*modificationDate = convertToSqueakTime(fileAttributes[NSFileModificationDate]);
	*sizeIfFile = [fileAttributes[NSFileSize] integerValue];
	
	/* POSSIBLE IPHONE BUG CHECK */
	if (*creationDate == 0) 
		*creationDate = *modificationDate;
	
	return ENTRY_FOUND;
}

- (sqInt) dir_Create: (char *) pathString
			  length: (sqInt) pathStringLength; {
	NSFileManager * fileMgr = [NSFileManager defaultManager];
	NSString*	directoryPath = NULL;
	BOOL	ok;
	
	if (pathString == nil || 
		pathStringLength <= 0 ||
		pathStringLength >= PATH_MAX) //This is not a null terminated string so >= versus >
		return 0;
	
	directoryPath = createFilePathFromString(pathString,pathStringLength, 1);
	
	if (directoryPath == NULL)
		return 0;
	
#warning what file permissions are used here? Defaults according to the manual, but unix port sets permissions & with defaults
	
	NSError *error;
	ok = [fileMgr createDirectoryAtPath: directoryPath withIntermediateDirectories: NO attributes: NULL error: &error];

	return ok;
}

- (sqInt) dir_Delete: (char *) pathString
			  length: (sqInt) pathStringLength; {
	NSFileManager * fileMgr = [NSFileManager defaultManager];
	NSString*	directoryPath = NULL;
	BOOL	ok;
	NSArray *directoryContentsForDirLookupCheck;
	
	if (pathString == nil || 
		pathStringLength <= 0 ||
		pathStringLength >= PATH_MAX)  //This is not a null terminated string so >= versus >
		return 0;
	
	directoryPath = createFilePathFromString(pathString,pathStringLength, 1);
	
	if (directoryPath == NULL)
		return 0;
	
	NSError *error;
	directoryContentsForDirLookupCheck = [fileMgr contentsOfDirectoryAtPath: directoryPath error: &error];
	
	if (directoryContentsForDirLookupCheck == NULL || ([directoryContentsForDirLookupCheck count])) {
		/* We don't recursive delete directory, that is too dangerous, let the squeak programmer do it 
		 which is why if the directory content count is > 0 we abort the delete */
		return 0;
	}
	
	/* The call below deletes the file, link, or directory 
	 (including, recursively, all subdirectories, files, and links in the directory) identified by a given path.
	 See comment above to protect against disaster, so in theory the directory has to be empty */
	
	ok = [fileMgr removeItemAtPath: directoryPath error: NULL];
	
	/*Ensure we note we need to clean up the cached directory */
	
	if (lastPathForDirLookup) {
		self.lastPathForDirLookup = NULL;		
	}
	return ok;
}


- (sqInt) dir_GetMacFileTypeAndCreator: (char *) filename
						  fileNameSize: (sqInt) filenameSize
								 fType: (char *) fType
							  fCreator: (char *) fCreator {
	
	NSFileManager * fileMgr = [NSFileManager defaultManager];

	if (filename == nil || 
		filenameSize <= 0 ||
		!fType || 
		!fCreator)
		return 0;
	
	bzero(fType, 4);
	bzero(fCreator, 4);
	NSString *filePath = createFilePathFromString(filename,filenameSize, 1);
	
	if (!filePath) 
		return 0;
	
	NSError *error;
	NSDictionary * fileAttributes = [fileMgr  attributesOfItemAtPath:filePath error:&error];
	
	if (!fileAttributes) 
		return 0;
	
	NSNumber	*typeCode	= fileAttributes[NSFileHFSTypeCode];
	NSNumber	*creatorCode = fileAttributes[NSFileHFSCreatorCode];
	if (creatorCode == NULL || typeCode == NULL) 
		return 0;
	
	*((uint32_t *) fType)	= (uint32_t) CFSwapInt32BigToHost([typeCode unsignedIntValue]);
	*((uint32_t *) fCreator)= (uint32_t) CFSwapInt32BigToHost([creatorCode unsignedIntValue]);
	
	return 1;
}

- (sqInt) dir_SetMacFileTypeAndCreator: (char *) filename
						  fileNameSize: (sqInt) filenameSize
								 fType: (char *) fType
							  fCreator: (char *) fCreator {
	
	NSFileManager * fileMgr = [NSFileManager defaultManager];

	if (filename == nil || 
		filenameSize <= 0 ||
		!fType || 
		!fCreator)
		return 0;
	
	NSString *filePath = createFilePathFromString(filename,filenameSize, 1);	
	
	if (!filePath) {
		return 0;
	}
	
	NSNumber *typeCode = [NSNumber numberWithUnsignedLong: CFSwapInt32HostToBig(*((uint32_t *) fType))];
	NSNumber *creatorCode = [NSNumber numberWithUnsignedLong: CFSwapInt32HostToBig(*((uint32_t *) fCreator))];

	
    BOOL ok=[fileMgr  setAttributes:  @{ NSFileHFSTypeCode : typeCode, NSFileHFSCreatorCode: creatorCode} ofItemAtPath: filePath
													 error: NULL];
	return ok;
}

- (NSString *) resolvedAliasFiles: (NSString *) filePath {
	return filePath;
}

@end
