//
//  SqueakUIViewOpenGL.h
//  SqueakPureObjc
//
//  Created by John M McIntosh on 10-09-09.
//  Copyright 2010 Corporate Smalltalk Consulting Ltd. All rights reserved.
/*
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

#import <UIKit/UIKit.h>
#import "SqueakUIView.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>
extern struct	VirtualMachine* interpreterProxy;

// Run-time assertion
#if 0
#define rt_assert(expression) assert(expression)
#else
#define rt_assert(expression)
#endif

// Catch run-time GL errors
#if 0
#define glCheckError() { \
GLenum err = glGetError(); \
if (err != GL_NO_ERROR) { \
fprintf(stderr, "glCheckError: %04x caught at %s:%u\n", err, __FILE__, __LINE__); \
rt_assert(0); \
} \
}
#else
#define glCheckError()
#endif


@interface SqueakUIViewOpenGL : SqueakUIView {
	// The pixel dimensions of the backbuffer
    GLint backingWidth;
    GLint backingHeight;
	GLuint textureId;
	BOOL clippyIsEmpty;
	BOOL	syncNeeded;
	CGRect clippy;
	// OpenGL names for the renderbuffer and framebuffer used to render to this view
    EAGLContext *context;
    GLuint viewRenderbuffer, viewFramebuffer;   
}
-(void)setupOpenGL;

@end


