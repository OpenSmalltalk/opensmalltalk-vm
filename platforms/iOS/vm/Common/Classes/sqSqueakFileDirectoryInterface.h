//
//  sqSqueakFileDirectoryInterface.h
//  
//
//  Created by John M McIntosh on 6/14/08.
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

#import <Foundation/Foundation.h>
#import "sq.h"

@interface sqSqueakFileDirectoryInterface : NSObject {
	NSString* lastPathForDirLookup;
	NSInteger lastIndexForDirLookup;
	NSArray * directoryContentsForDirLookup;	
}
- (BOOL) setWorkingDirectory;
- (sqInt) dir_EntryLookup: (const char *) pathString 
			  length: (sqInt) pathStringLength 
		  returnName: (char *) nameString
	returnNameLength: (sqInt) nameStringLength	
				name: (char *) name
			  length: (sqInt *) nameLength 
		creationDate: (sqInt *) creationDate 
	modificationDate: (sqInt *) modificationDate
		 isDirectory: (sqInt *) isDirectory
		  sizeIfFile: (squeakFileOffsetType *) sizeIfFile
    posixPermissions: (sqInt *)posix
           isSymlink: (sqInt *) isSymlink;

- (sqInt) dir_Lookup: (const char *) pathString
			  length: (sqInt) pathStringLength 
			   index: (sqInt) index 
				name: (char *) name
			  length: (sqInt *) nameLength 
		creationDate: (sqInt *) creationDate 
	modificationDate: (sqInt *) modificationDate
		 isDirectory: (sqInt *) isDirectory
		  sizeIfFile: (squeakFileOffsetType *) sizeIfFile
    posixPermissions: (sqInt *)posixPermissions
           isSymlink: (sqInt *) isSymlink;

- (sqInt) dir_Create: (char *) pathString
			  length: (sqInt) pathStringLength;
- (sqInt) dir_Delete: (char *) pathString
			  length: (sqInt) pathStringLength;
- (sqInt) dir_GetMacFileTypeAndCreator: (char *) filename
						  fileNameSize: (sqInt) filenameSize
								 fType: (char *) fType
							  fCreator: (char *) fCreator;
- (sqInt) dir_SetMacFileTypeAndCreator: (char *) filename
						  fileNameSize: (sqInt) filenameSize
								 fType: (char *) fType
							  fCreator: (char *) fCreator;
- (NSString *) resolvedAliasFiles: (NSString *) filePath;

@property (nonatomic,strong) NSString* lastPathForDirLookup;
@property (nonatomic,assign) NSInteger lastIndexForDirLookup;
@property (nonatomic,strong) NSArray * directoryContentsForDirLookup;

@end

sqInt convertToSqueakTime(NSDate *givenDate);
