//
//  sqSqueakOSXApplication+imageReadWrite.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 09-11-13.
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
//

#import "sqSqueakOSXApplication+imageReadWrite.h"
#import "sqSqueakMainApplication+vmAndImagePath.h"
#import "sqSqueakOSXInfoPlistInterface.h"
#import "SqueakOSXAppDelegate.h"

extern SqueakOSXAppDelegate *gDelegateApp;

@implementation sqSqueakOSXApplication (imageReadWrite) 
- (void) attempToOpenImageFromOpenPanel {
	NSOpenPanel *panel= [NSOpenPanel openPanel];
	[panel setTitle: NSLocalizedString(@"SelectImagePanePrompt",nil)];
	[panel setFloatingPanel: YES];
	[panel setOneShot: YES];
	[panel setReleasedWhenClosed: YES];
	[panel setAllowedFileTypes:  @[@"image"]];
	 
	[panel center];
	
	if (NSOKButton == [panel runModal]) {
		NSArray *urls= [panel URLs];
		if (1 == [urls count])
			[self setImageNamePathIfItWasReadable: [urls[0] path]];
    } else {
		exit(142);
	}
}

- (BOOL) setImageNamePathIfItWasReadable: (NSString *) filePath {
	BOOL fileIsReadable = [[NSFileManager defaultManager] isReadableFileAtPath: filePath];
	if (fileIsReadable) {
		[(sqSqueakOSXInfoPlistInterface*)[self infoPlistInterfaceLogic] setOverrideSqueakImageName: filePath];
		[self imageNamePut: [filePath UTF8String]];
	}
	return fileIsReadable;
}


- (void) findImageViaBundleOrPreferences {
	@autoreleasepool {
	
	/* Check for squeak image name in resource directory if not found 
	 then check for image after resolving image name incase it's a ./ or ../ or ~/ etc 
	 plus also could be in working directory? 
	 
	 So first let's see if the imageName is a partial path, if so use it. 
	 otherwise check the resource directory then the vmpath.
	 
	 */
	
		NSBundle *mainBundle = [NSBundle mainBundle];
		NSString *resourcePath = [mainBundle resourcePath];
		BOOL fileIsReadable;
//	extern char	imageName[];
		
#warning do we check for imageName that is elsewhere? like ~/Foo/squeak.image
		
		NSString *possibleImage;
		NSString *imageNameString;
		
		if (gDelegateApp.possibleImageNameAtLaunchTime) {
			imageNameString = possibleImage = gDelegateApp.possibleImageNameAtLaunchTime;
		} else {
			    imageNameString = @(imageName);
				possibleImage = [imageNameString stringByStandardizingPath];
		}

        if ([imageNameString isEqualToString: possibleImage]) {
			if ([possibleImage isAbsolutePath]) {
				fileIsReadable = [self setImageNamePathIfItWasReadable: possibleImage];			
			} else {
				NSString *fullResourcePathToImage = [resourcePath stringByAppendingPathComponent: imageNameString];
				fileIsReadable = [self setImageNamePathIfItWasReadable: fullResourcePathToImage];
				if (!fileIsReadable){
					NSString *vmPath = [self.vmPathStringURL path];
					NSString *fullVMPathToImage = [vmPath stringByAppendingPathComponent: imageNameString];
					fileIsReadable = [self setImageNamePathIfItWasReadable: fullVMPathToImage];
				}		
			}
		} else {
			fileIsReadable = [self setImageNamePathIfItWasReadable: possibleImage];
		}
		
		// At this point we did not find a file name in the resources or in the vm directory or via a set image name
		if (!fileIsReadable) {
                [self attempToOpenImageFromOpenPanel];
		}
		
		return;
	}
}

- (void) imageNamePut:(const char *) sqImageName {
	if (!sqImageName) 
		return;
	[super imageNamePut: sqImageName];
	[gDelegateApp.window setRepresentedURL: self.imageNameURL];
	[gDelegateApp.window setTitle: [[self.imageNameURL path] lastPathComponent]];
}
@end
