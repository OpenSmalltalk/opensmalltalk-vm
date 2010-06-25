//
//  sqSqueakVmAndImagePathAPI.m
//
//  Created by John M McIntosh on 6/19/08.
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
/* imageName is a character stored and known by the VM
 but we use a URI for image name. So a bit of house keeping is required to sync the two data items
*/

#import "sqSqueakVmAndImagePathAPI.h"
#import "sqSqueakAppDelegate.h"
#import "sqSqueakMainApplication+vmAndImagePath.h"

extern sqSqueakAppDelegate *gDelegateApp;
char	imageName[PATH_MAX]="Squeak.image";

char *getImageName(void) {
	return (char *) [gDelegateApp.squeakApplication getImageName];
}	

sqInt imageNameSize(void){
	return  (sqInt) strlen(getImageName());
}	

sqInt imageNameGetLength(sqInt sqImageNameIndex, sqInt length){
	[gDelegateApp.squeakApplication imageNameGet: pointerForOop((usqInt)sqImageNameIndex) length: length];
	return 0;
}

sqInt imageNamePutLength(sqInt sqImageNameIndex, sqInt length){
	if (length > 0 && (length < PATH_MAX)) {
		strncpy(imageName,pointerForOop((usqInt)sqImageNameIndex),(size_t) length); //This does not need to be strlcpy since the data is not null terminated
		imageName[length] = 0x00;		//Ensure we nil terminate the image name string
		[gDelegateApp.squeakApplication imageNamePut:imageName];

	}
	return 0;
}	

//getVMPath returns without a trailing '/', so increment by one

sqInt vmPathSize(void){
	return (sqInt) strlen([gDelegateApp.squeakApplication getVMPath]) + 1;
}	

sqInt vmPathGetLength(sqInt sqVMPathIndex, sqInt length){
	[gDelegateApp.squeakApplication vmPathGet: pointerForOop((usqInt)sqVMPathIndex) length: length];
	return 0;
}