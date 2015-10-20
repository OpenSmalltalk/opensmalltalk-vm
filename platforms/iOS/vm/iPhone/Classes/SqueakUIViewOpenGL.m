//
//  SqueakUIViewOpenGL.m
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

#import "SqueakUIViewOpenGL.h"
#import "sq.h"

// A class extension to declare private methods
@interface SqueakUIViewOpenGL ()
@property (nonatomic, strong) EAGLContext *context;
@end

const GLfloat spriteTexcoords[] = {
	0.0f, 1.0f,
	1.0f, 1.0f,
	0.0f, 0.0f,
	1.0f, 0.0f,
};

@implementation SqueakUIViewOpenGL
@synthesize context;

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect) aFrame {
	self = [super initWithFrame: aFrame];
	clippyIsEmpty = YES;
	syncNeeded = NO;
 
    [self setContentScaleFactor: [[UIScreen mainScreen] scale]];
 
	// Get the layer
	CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
	eaglLayer.opaque = YES;
	eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @NO,
									kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
	
	//other choice is kEAGLColorFormatRGB565
	
	context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];        
	if (!context || ![EAGLContext setCurrentContext:context]) {
		return nil;
	}

	[self setupOpenGL];
	return self;
}

-(void)setupOpenGL {	
	// Create system framebuffer object. The backing will be allocated in -reshapeFramebuffer
	
	glGenFramebuffersOES(1, &viewFramebuffer);glCheckError();
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);glCheckError();
	glGenRenderbuffersOES(1, &viewRenderbuffer);glCheckError();
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);glCheckError();
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);glCheckError();
}

-(GLuint)createTextuerUsingWidth:(GLuint)w Height:(GLuint)h
{
	GLuint handle;

	glGenTextures(1, &handle);glCheckError();
	glBindTexture(GL_TEXTURE_2D, handle);glCheckError();
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);glCheckError();
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);glCheckError();
	
	// http://www.khronos.org/registry/gles/extensions/APPLE/APPLE_texture_2D_limited_npot.txt
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_BGRA, GL_UNSIGNED_BYTE, NULL);glCheckError();
	
	glDisable(GL_DEPTH_TEST);glCheckError();
	glDisableClientState(GL_COLOR_ARRAY);glCheckError();
	glEnable(GL_TEXTURE_2D);glCheckError();
	glEnableClientState(GL_VERTEX_ARRAY);glCheckError();
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);glCheckError();

	return handle;
}

- (void)dealloc {        
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
    self.context = nil;
    SUPERDEALLOC
}

- (void)layoutSubviews {
    // Allocate GL color buffer backing, matching the current layer size
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer]; glCheckError();
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);glCheckError();
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);glCheckError();
	rt_assert(GL_FRAMEBUFFER_COMPLETE_OES == glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
	if (textureId) {
		glDeleteTextures(1,&textureId);
		textureId = 0;
	}
}

- (void) drawImageUsingClip: (CGRect) clip {
	if (clippyIsEmpty){
		clippy = clip;
		clippyIsEmpty = NO;
	} else {
		clippy = CGRectUnion(clippy, clip);
	}
	syncNeeded = YES;
}

- (void) drawThelayers {
	if (syncNeeded) { 
		[self drawRect: clippy];
		syncNeeded = NO;
		clippyIsEmpty = YES;
//		glFlush();
		[EAGLContext setCurrentContext:context];
		[context presentRenderbuffer:GL_RENDERBUFFER_OES];
	}
}

- (void)loadTexturesFrom: (void*) lastBitsIndex subRectangle: (CGRect) subRectSqueak { 
	CGRect subRect = subRectSqueak;
	NSUInteger imageWidth = (NSUInteger)self.bounds.size.width*4;
	GLfloat spriteVertices[] =  {
		0.0f,0.0f,   
		self.bounds.size.width,0.0f,   
		0.0f,self.bounds.size.height, 
		self.bounds.size.width,self.bounds.size.height};

	subRect.origin.y = self.bounds.size.height-subRectSqueak.origin.y-subRectSqueak.size.height;
	void *span = lastBitsIndex+(NSUInteger)subRect.origin.y*imageWidth + (NSUInteger)subRect.origin.x* 4;
	
	if (!textureId) {
		textureId = [self createTextuerUsingWidth: backingWidth Height: backingHeight];
	} else {
		glBindTexture(GL_TEXTURE_2D, textureId);glCheckError();
	}
	
	for( GLint y = 0; y < (GLint) subRect.size.height; y++ ) {
		 void *row =  imageWidth*y + span;
		 glTexSubImage2D( GL_TEXTURE_2D, 0, (GLint)subRect.origin.x, (GLint)subRect.origin.y+y, 
						 (GLsizei)subRect.size.width, 1, GL_BGRA, GL_UNSIGNED_BYTE, row );glCheckError();
	 }
		
    glViewport( 0, 0, self.bounds.size.width, self.bounds.size.height);glCheckError();	
	glMatrixMode(GL_PROJECTION);glCheckError();
	glLoadIdentity();glCheckError();
    glMatrixMode(GL_MODELVIEW);glCheckError();
    glLoadIdentity();glCheckError();
	glVertexPointer(2, GL_FLOAT, 0, spriteVertices);glCheckError();
	glTexCoordPointer(2, GL_FLOAT, 0, spriteTexcoords);	glCheckError();
	glOrthof(0, (GLfloat) self.bounds.size.width, 0, (GLfloat) self.bounds.size.height, 0, 1);glCheckError();
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);glCheckError();
}


-(void)drawRect:(CGRect)rect {
	//	NSLog(@" drawRect %f %f %f %f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
	sqInt formObj = interpreterProxy->displayObject();
	sqInt formPtrOop = interpreterProxy->fetchPointerofObject(0, formObj);	
	void* dispBitsIndex = interpreterProxy->firstIndexableField(formPtrOop);
    if ( dispBitsIndex ) {
		[self loadTexturesFrom:dispBitsIndex subRectangle: rect];
	}
}

@end
