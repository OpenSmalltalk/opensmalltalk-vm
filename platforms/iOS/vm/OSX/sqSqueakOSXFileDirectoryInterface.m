//
//  sqSqueakOSXFileDirectoryInterface.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 09-11-11.
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
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

/* The resolve Alias logic is via 
 http://blacktree-alchemy.googlecode.com/svn/branches/B5X/README.markdown
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this software except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


//

#import "sqSqueakOSXFileDirectoryInterface.h"
#import "SqueakOSXAppDelegate.h"

extern SqueakOSXAppDelegate *gDelegateApp;


@implementation sqSqueakOSXFileDirectoryInterface
- (BOOL) setWorkingDirectory {
	if (1) 
		return 1;
	//for people wanting to do  ./Squeak.app foobar.image  zingger.st
	
	
	NSString *path = [gDelegateApp.squeakApplication.vmPathStringURL path];
	BOOL results = [[NSFileManager defaultManager] changeCurrentDirectoryPath: path];
	return results;
}

- (NSString *)resolvedAliasFiles:(NSString *)filePath {
    NSArray *components = [[filePath stringByStandardizingPath] pathComponents];
	NSString *thisComponent;
	NSString *path = AUTORELEASEOBJ([[NSString alloc] init]);
	for (thisComponent in components) {
		path = [path stringByAppendingPathComponent:thisComponent];
		if (![[NSFileManager defaultManager] fileExistsAtPath:path])
			continue;
		LSItemInfoRecord infoRec;
		LSCopyItemInfoForURL((__bridge CFURLRef) [NSURL fileURLWithPath:path], kLSRequestBasicFlagsOnly, &infoRec);
        if (infoRec.flags & kLSItemInfoIsAliasFile) {
			path = [self resolveAliasAtPath:path];
        }
	}

	return path;
}

- (NSString *)resolveAliasAtPath:(NSString *)aliasFullPath {
	NSString *outString = nil;
	NSURL *url;
	FSRef aliasRef;
	Boolean targetIsFolder;
	Boolean wasAliased;
	
    url = [NSURL fileURLWithPath:aliasFullPath];
    
    if (!CFURLGetFSRef((CFURLRef)url, &aliasRef)
        || (FSResolveAliasFileWithMountFlags(&aliasRef, true, &targetIsFolder, &wasAliased, kResolveAliasFileNoUI) != noErr)) {
        return nil;
    }
	
	if ((url = (NSURL *)CFBridgingRelease(CFURLCreateFromFSRef(kCFAllocatorDefault, &aliasRef)))) {
        outString = [url path];
	}
    
    return outString;
}

@end



