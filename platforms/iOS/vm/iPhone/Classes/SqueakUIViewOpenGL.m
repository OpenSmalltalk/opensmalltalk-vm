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
@property (nonatomic, retain) EAGLContext *context;
@end

@implementation SqueakUIViewOpenGL
@synthesize context;

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect) aFrame {
	self = [super initWithFrame: aFrame];
	clippyIsEmpty = YES;
	syncNeeded = NO;

	// Get the layer
	CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
	eaglLayer.opaque = YES;
	eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
									kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
									nil];
	
	//other choice is kEAGLColorFormatRGB565
	
	context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];        
	if (!context || ![EAGLContext setCurrentContext:context]) {
		[self release];
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
	int dataSize = w * h * 4;
	uint8_t* textureData = (uint8_t*)malloc(dataSize);
	if(textureData == NULL)
		return 0;
	memset(textureData, 128, dataSize);
	
	GLuint handle;
	glGenTextures(1, &handle);glCheckError();
	glBindTexture(GL_TEXTURE_2D, handle);glCheckError();
	glTexParameterf(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_BGRA, 
				 GL_UNSIGNED_BYTE, textureData);glCheckError();
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);glCheckError();
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);glCheckError();
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);glCheckError();
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);glCheckError();
	glDisable(GL_DEPTH_TEST);glCheckError();
	glDisableClientState(GL_COLOR_ARRAY);glCheckError();
	glEnable(GL_TEXTURE_2D);glCheckError();
	glEnableClientState(GL_VERTEX_ARRAY);glCheckError();
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);glCheckError();

	glBindTexture(GL_TEXTURE_2D, 0);glCheckError();
	free(textureData);
	
	return handle;
}

- (void)dealloc {        
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
    
    self.context = nil;
    [super dealloc];
}

- (void)layoutSubviews {
    // Allocate GL color buffer backing, matching the current layer size
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer]; glCheckError();
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);glCheckError();
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);glCheckError();
	rt_assert(GL_FRAMEBUFFER_COMPLETE_OES == glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
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
		glFlush();
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);glCheckError();
		[context presentRenderbuffer:GL_RENDERBUFFER_OES];
	}
}

GLfloat spriteTexcoords[] = {
	0.0f, 1.0f,
	1.0f, 1.0f,
	0.0f, 0.0f,
	1.0f, 0.0f,
};

- (void)loadTexturesFrom: (void*) lastBitsIndex subRectangle: (CGRect) subRect { 
	
	if (!textureId) {
		textureId = [self createTextuerUsingWidth: backingWidth Height: backingHeight];
	}
	
	glBindTexture(GL_TEXTURE_2D, textureId);glCheckError();
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 
					self.frame.size.width, self.frame.size.height, 
					GL_BGRA, GL_UNSIGNED_BYTE, lastBitsIndex);glCheckError();
 
	[EAGLContext setCurrentContext:context];
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);	

	GLfloat spriteVertices[] =  {
		0,0,   
		self.frame.size.width,0,   
		0,self.frame.size.height, 
		self.frame.size.width,self.frame.size.height};
	
	glMatrixMode(GL_PROJECTION);glCheckError();
	glLoadIdentity();glCheckError();
	
    glMatrixMode(GL_MODELVIEW);glCheckError();
    glLoadIdentity();glCheckError();
	
	glOrthof(0, self.frame.size.width, 0, self.frame.size.height, 0, 1);glCheckError();
	
	glVertexPointer(2, GL_FLOAT, 0, spriteVertices);glCheckError();
	glTexCoordPointer(2, GL_FLOAT, 0, spriteTexcoords);	glCheckError();
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

//	char *subimg = ((char*)lastBitsIndex) + (unsigned int)(subRect.origin.x + (r.size.height-subRect.origin.y-subRect.size.height)*r.size.width)*4;
//	glTexImage2D( GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, subRect.size.width, subRect.size.height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, subimg );
//	glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, subRect.size.width, subRect.size.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, NULL );
//glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, r.size.width, r.size.height, 
//				GL_RGBA, GL_UNSIGNED_BYTE, lastBitsIndex);
//	NSLog(@" loadTexturesFrom %f %f %f %f",subRect.origin.x,subRect.origin.y,subRect.size.width,subRect.size.height);	

/*for( NSInteger y = 0; y < subRect.size.height; y++ )
 {
 char *row = ((char*)lastBitsIndex) + ((y + (NSInteger)subRect.size.height)*(NSInteger)r.size.width + (NSInteger)subRect.size.width) * 4;
 glTexSubImage2D( GL_TEXTURE_2D, 0, 0, y, subRect.size.width, 1, GL_RGBA, GL_UNSIGNED_BYTE, row );
 glCheckError();
 } */

