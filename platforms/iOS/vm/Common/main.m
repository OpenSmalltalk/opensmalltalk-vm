//
//  main.m
//
//  Created by John M McIntosh on 5/15/08.
//  11/01/09 Altered for os-x version
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

#ifdef BUILD_FOR_OSX
#import <Cocoa/Cocoa.h>
#import "sqSqueakOSXViewFactory.h"
#include <string.h>

int main(int argc, char **argv, char **envp)
{	
	extern int argCnt;
	extern char **argVec;
	extern char **envVec;
	
	argCnt = argc;
	argVec = argv;
	envVec = envp;
	
	// HACK: Command line arguments are being parsed after creating the UI!!!
	// This is a hack for selecting the proper view class by only looking at
	// the first argument.
	if(argc >= 2)
	{
#ifdef USE_METAL
		if(!strcmp(argv[1], "-metal"))
			sqCurrentOSXRequestedViewType = SQ_OSX_REQUESTED_VIEW_TYPE_METAL;
#endif
#ifdef USE_CORE_GRAPHICS
		if(!strcmp(argv[1], "-core-graphics"))
			sqCurrentOSXRequestedViewType = SQ_OSX_REQUESTED_VIEW_TYPE_CORE_GRAPHICS;
#endif
#ifdef USE_OPENGL
		if(!strcmp(argv[1], "-opengl"))
			sqCurrentOSXRequestedViewType = SQ_OSX_REQUESTED_VIEW_TYPE_OPENGL;
#endif
		if(!strcmp(argv[1], "-headless"))
			sqCurrentOSXRequestedViewType = SQ_OSX_REQUESTED_VIEW_TYPE_NONE;
	}
    return NSApplicationMain(argc,  (const char **) argv);
}
#else
#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
	
	@autoreleasepool {
		int retVal = UIApplicationMain(argc, argv, nil, nil);
		return retVal;
	}
}
#endif 
