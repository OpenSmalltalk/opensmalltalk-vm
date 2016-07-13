//
//  sqSqueakNullScreenAndWindow.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 2016-05-14.
/*
 Copyright (c) 2016 Corporate Smalltalk Consulting Ltd. All rights reserved.
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
//

#import "sqSqueakNullScreenAndWindow.h"

@implementation sqSqueakNullScreenAndWindow
@synthesize windowIndex,forceUpdateFlush;

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (id) getMainViewOnWindow {
    return NULL;
}

- (void) mainViewOnWindow: (id) aView {
}

- (id) getMainView {
    return NULL;
}

- (void)  ioSetFullScreen: (sqInt) fullScreen {
}

- (double) ioSceenScaleFactor {
    return 1.0;
}

- (sqInt) ioScreenSize {
    return (10 << 16) | (10 & 0xFFFF);  /* w is high 16 bits; h is low 16 bits */
}

- (sqInt) ioScreenDepth {
    return 32;
}

- (sqInt) ioHasDisplayDepth: (sqInt) depth {
    if (depth == 2 || depth ==  4 || depth == 8 || depth == 16 || depth == 32 ||
        depth == -2 || depth ==  -4 || depth == -8 || depth == -16 || depth == -32) {
        return true;
    } else {
        return false;
    }
}

- (void) ioForceDisplayUpdate {
}

- (void) ioForceDisplayUpdateFlush: (NSTimer*)theTimer {

}

- (int)   ioShowDisplayOnWindow: (unsigned char*) dispBitsIndex
                          width: (int) width
                         height: (int) height
                          depth: (int) depth
                      affectedL: (int) affectedL
                      affectedR: (int) affectedR
                      affectedT: (int) affectedT
                      affectedB: (int) affectedB
                    windowIndex: (int) passedWindowIndex {
    return 0;
}

@end
