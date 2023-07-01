//
//  sqSqueakOSXOpenGLView.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 09-11-14.
//  Some code sqUnixQuartz.m -- display via native windows on Mac OS X	-*- ObjC -*-
//  Author: Ian Piumarta <ian.piumarta@squeakland.org>
// Changes: 2017-05-13 Ronie Salgado. Refactored to remove the fixed function pipeline.
// Implemented a layering system to be used in cooperation by the B3DAccelerationPlugin.
// Fixing some graphical glitches that appeared when enabling the double buffering.
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

#ifdef USE_OPENGL
#import <QuartzCore/QuartzCore.h>

#import "sqSqueakOSXOpenGLView.h"
#import "sqSqueakOSXScreenAndWindow.h"
#import "SqueakOSXAppDelegate.h"
#import "sqSqueakOSXApplication+events.h"
#import "sqSqueakOSXInfoPlistInterface.h"
#import "sq.h"

#import <OpenGL/gl.h>
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
# import <OpenGL/OpenGL.h>
#else
# import <OpenGL/Opengl.h>
#endif

extern SqueakOSXAppDelegate *gDelegateApp;

struct Vertex2D {
	float x, y;
	float u, v;
};

static struct Vertex2D screenQuadVertices[] = {
	{-1.0f, 1.0f, 0.0f, 0.0f}, // Top left
	{1.0f, 1.0f, 1.0f, 0.0f}, // Top right
	{-1.0f, -1.0f, 0.0f, 1.0f}, // Bottom left
	{1.0f, -1.0f, 1.0f, 1.0f}, // Bottom right
};

static const char *vertexShaderSource = "\
#version 120\n\
uniform vec2 screenSize;\n\
\n\
attribute vec2 vPosition;\n\
attribute vec2 vTexcoord;\n\
\n\
varying vec2 fTexcoord;\n\
\n\
void main() {\n\
	fTexcoord = vTexcoord*screenSize;\n\
	gl_Position = vec4(vPosition, 0.0, 1.0);\n\
}\n";

static const char *flippedVertexShaderSource = "\
#version 120\n\
uniform vec4 layerScaleAndTranslation;\n\
\n\
attribute vec2 vPosition;\n\
attribute vec2 vTexcoord;\n\
\n\
varying vec2 fTexcoord;\n\
\n\
void main() {\n\
	fTexcoord = vec2(vTexcoord.x, 1.0 - vTexcoord.y);\n\
	gl_Position = vec4(vPosition*layerScaleAndTranslation.xy + layerScaleAndTranslation.zw, 0.0, 1.0);\n\
}\n";

static const char *textureFragmentShaderSource = "\
#version 120\n\
uniform sampler2D screen;\n\
varying vec2 fTexcoord;\n\
\n\
void main() {\n\
	gl_FragColor = texture2D(screen, fTexcoord);\n\
}\n";

static const char *rectangleTextureFragmentShaderSource = "\
#version 120\n\
uniform sampler2DRect screen;\n\
varying vec2 fTexcoord;\n\
\n\
void main() {\n\
	gl_FragColor = texture2DRect(screen, fTexcoord);\n\
}\n";

#define MAX_NUMBER_OF_EXTRA_LAYERS 16

typedef struct ExtraLayer
{
	GLuint texture;
	int x, y;
	int w, h;
} ExtraLayer;

static NSOpenGLContext *mainOpenGLContext;
static sqSqueakOSXOpenGLView *mainOpenGLView;
static ExtraLayer extraLayers[MAX_NUMBER_OF_EXTRA_LAYERS];
static unsigned int allocatedExtraLayers = 0;

@interface sqSqueakOSXOpenGLView ()

-(void)drawRect:(NSRect)rect flush:(BOOL)flush;

@property (nonatomic,assign) NSRect lastFrameSize;
@property (nonatomic,assign) BOOL fullScreenInProgress;
@property (nonatomic,assign) void* fullScreendispBitsIndex;

@end

@implementation sqSqueakOSXOpenGLView
@synthesize fullScreenInProgress,fullScreendispBitsIndex;

#include "SqSqueakOSXView.m.inc"

+ (NSOpenGLPixelFormat *)defaultPixelFormat {
	NSOpenGLPixelFormatAttribute attrs[] =
    {
		// NSOpenGLPFAOpenGLProfile,
		// 	NSAppKitVersionNumber < NSAppKitVersionNumber10_9 ? NSOpenGLProfileVersionLegacy : NSOpenGLProfileVersion3_2Core,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFABackingStore,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAAllowOfflineRenderers, // Enables automatic graphics card switching
		NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)0,
		NSOpenGLPFAStencilSize, (NSOpenGLPixelFormatAttribute)0,
		0
	};
	return AUTORELEASEOBJ([[NSOpenGLPixelFormat alloc] initWithAttributes:attrs]);
}

#pragma mark Initialization / Release

- (id)initWithFrame:(NSRect)frameRect {
    self = [self initWithFrame:frameRect pixelFormat:[[self class] defaultPixelFormat]];
    [self initialize];
    return self;
}

- (void)awakeFromNib {
    [self initialize];
}

- (void)initialize {
	[self setWantsBestResolutionOpenGLSurface:YES];
       [self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
       [self setAutoresizesSubviews:YES];

	inputMark = NSMakeRange(NSNotFound, 0);
	inputSelection = NSMakeRange(0, 0);
    [self registerForDraggedTypes: [NSArray arrayWithObjects: NSPasteboardTypeFileURL, nil]];
	//NSLog(@"registerForDraggedTypes %@",self);
	openglInitialized = NO;
	dragInProgress = NO;
	dragCount = 0;
	clippyIsEmpty = YES;
    fullScreenInProgress = NO;
	currentDisplayStorage = NULL;
	textureProgram = 0;
	rectangleTextureProgram = 0;
	screenSizeUniformLocation = -1;
	screenQuadVertexBuffer = 0;
	displayTexture = 0;
	displayTextureWidth = 0;
	displayTextureHeight = 0;
	
	colorspace = CGColorSpaceCreateDeviceRGB();
	[self initializeSqueakColorMap];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(didEnterFullScreen:) name:@"NSWindowDidEnterFullScreenNotification" object:nil];

    // macOS 10.5 introduced NSTrackingArea for mouse tracking
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect: [self frame]
    	options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingInVisibleRect)
    	owner: self userInfo: nil];
    [self addTrackingArea: trackingArea];
}

- (void) didEnterFullScreen: (NSNotification*) aNotification {
    //NSLog(@"Notification didEnterFullScreen");
    [self setupFullScreendispBitsIndex];
    self.fullScreenInProgress = NO;
}

- (void) initializeVariables {
}

- (void) preDrawThelayers {
}

- (void) dealloc {
	free(colorMap32);
	CGColorSpaceRelease(colorspace);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SUPERDEALLOC
}

#pragma mark Testing

- (BOOL) acceptsFirstResponder {
	return YES;
}

- (BOOL)isFlipped {
	return  YES;
}

- (BOOL)isOpaque {
	return YES;
}

- (NSRect) sqScreenSize {
  return [self convertRectToBacking: [self bounds]];
}


- (NSPoint) sqMousePosition: (NSEvent*)theEvent {
	/* Our client expects the mouse coordinates in Squeak's coordinates,
	 * but theEvent's location is in "user" coords. so we have to convert. */
	NSPoint local_pt = [self convertPoint: [theEvent locationInWindow] fromView:nil];
	NSPoint converted = [self convertPointToBacking: local_pt];
	// Squeak is upside down
	return NSMakePoint(converted.x, -converted.y);
}

- (NSPoint) sqDragPosition: (NSPoint)draggingLocation {
	// TODO: Reuse conversion from sqMousePosition:.
	NSPoint local_pt = [self convertPoint: draggingLocation fromView: nil];
	NSPoint converted = [self convertPointToBacking: local_pt];
	return NSMakePoint(converted.x, -converted.y);
}


#pragma mark Updating callbacks

- (void) viewWillStartLiveResize {
    //NSLog(@"viewWillStartLiveResize");
    self.fullScreenInProgress = YES;
	[[NSCursor arrowCursor] set];
}

- (void) viewDidEndLiveResize {
    //NSLog(@"viewDidEndLiveResize");
    dispatch_async(dispatch_get_main_queue(), ^{
        [((sqSqueakOSXApplication*) gDelegateApp.squeakApplication).squeakCursor  set];
     });

}

#pragma mark Drawing


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
		[self drawRect: NSRectFromCGRect(clippy) flush: NO];
		syncNeeded = NO;
		clippyIsEmpty = YES;
//		CGL_MACRO_DECLARE_VARIABLES();
		NSOpenGLContext *oldContext = [NSOpenGLContext currentContext];
		[[self openGLContext] makeCurrentContext];
		glFlush();
		[[self openGLContext] flushBuffer];
		if (oldContext != nil) {
			[oldContext makeCurrentContext];
		} else {
			[NSOpenGLContext clearCurrentContext];
		}
	}
	if (!firstDrawCompleted) {
		firstDrawCompleted = YES;
        extern sqInt getFullScreenFlag(void);
		if (getFullScreenFlag() == 0) {
			[self.window makeKeyAndOrderFront: self];
        }
	}
}

-(void)setupOpenGL {
	if(openglInitialized)
		return;
	openglInitialized = YES;
	
//	CGL_MACRO_DECLARE_VARIABLES();
// Enable the multithreading
    //NSLog(@"setupOpenGL runs");
	
	// Store the OpenGL context for creating a shared context with the B3D plugin.
	mainOpenGLContext = [self openGLContext];
	mainOpenGLView = self;
	
	CGLContextObj ctx = [[self openGLContext] CGLContextObj];
	CGLEnable( ctx, kCGLCEMPEngine);
	// from gl3.h
#ifndef GL_MAJOR_VERSION
#define GL_MAJOR_VERSION 0x821B
#endif
	GLint maj = 0;
	glGetIntegerv(GL_MAJOR_VERSION, &maj);
	if (maj > 3) {
		hasVertexArrayObject = YES;
	} else {
		const char* oldExtensions = (const char*)glGetString(GL_EXTENSIONS);
		hasVertexArrayObject = oldExtensions && (strstr(oldExtensions, "GL_APPLE_vertex_array_object") != NULL);
	}
	
	// printf("Opengl version: %s\n", glGetString(GL_VERSION));
	// printf("Opengl extensions: %s\n", glGetString(GL_EXTENSIONS));
	
	[self buildGPUPrograms];
	[self buildScreenQuad];
	
	glClearColor(1, 1, 1, 1);

	GLint newSwapInterval = 0; // vsync on (1) or off (0)
	CGLSetParameter(ctx, kCGLCPSwapInterval, &newSwapInterval);
	/*glDisable(GL_DITHER);
	glDisable(GL_ALPHA_TEST);
	glDisable(GL_BLEND);
	glDisable(GL_STENCIL_TEST);
	glDisable(GL_FOG);
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_DEPTH_TEST);
	glDisable(GL_SCISSOR_TEST);
    glDisable(GL_CULL_FACE);
	glStencilMask(0);
	glPixelZoom(1.0,1.0);

	glEnable(GL_TEXTURE_RECTANGLE_ARB);
 	glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_PRIORITY, 0.0);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
 	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_SHARED_APPLE);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glPixelStorei( GL_UNPACK_ROW_LENGTH, r.size.width );
	GLuint dt = 1;
	glDeleteTextures(1, &dt);
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 1);
	*/
	syncNeeded = NO;
}

- (GLuint) compileShader: (const char*)shaderSource type: (GLenum) type {
	GLint status;
	GLuint handle;
	
	handle = glCreateShader(type);
	glShaderSource(handle, 1, &shaderSource, NULL);
	glCompileShader(handle);
	
	// This should never fail.
	glGetShaderiv(handle, GL_COMPILE_STATUS, &status);
	if(status != GL_TRUE) {
		GLint logSize = 0;
		glGetShaderiv(handle, GL_INFO_LOG_LENGTH, &logSize);
		char errorLog[logSize];
		glGetShaderInfoLog(handle, logSize, &logSize, &errorLog[0]);
		
		fprintf(stderr, "Failed to compile shader with source: \n%s\nError: %s", shaderSource, errorLog);
		return NULL;
	}
	
	return handle;
}

- (GLuint) buildProgramVertexShader: (const char *)vertexShaderSource  fragmentShader: (const char *)fragmentShaderSource {
	GLint status;
	GLuint program;
	
	// Create the shaders.
	GLuint vertexShader = [self compileShader: vertexShaderSource type: GL_VERTEX_SHADER];
	GLuint fragmentShader = [self compileShader: fragmentShaderSource type: GL_FRAGMENT_SHADER];
	
	// Create the GPU program.
	program = glCreateProgram();
	glAttachShader(program, vertexShader);
	glAttachShader(program, fragmentShader);	
	glBindAttribLocation(program, 0, "vPosition");
	glBindAttribLocation(program, 1, "vTexcoord");
	glLinkProgram(program);
	
	// This should never fail.
	glGetProgramiv(program, GL_LINK_STATUS, &status);
	if(status != GL_TRUE) {
		GLint logSize = 0;
		glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logSize);
		char errorLog[logSize];
		glGetProgramInfoLog(program, logSize, &logSize, &errorLog[0]);
		fprintf(stderr, "Failed to link the screen quad shader.\nError: %s", errorLog);

		return NULL;
	}
	
	// Bind the screen texture to the first texture binding point.
	glUseProgram(program);
	glUniform1i(glGetUniformLocation(program, "screen"), 0);
	
	return program;
}

- (void) buildGPUPrograms {
	textureProgram = [self buildProgramVertexShader: flippedVertexShaderSource  fragmentShader: textureFragmentShaderSource];
	layerScaleAndTranslationUniformLocation = glGetUniformLocation(textureProgram, "layerScaleAndTranslation");
	rectangleTextureProgram = [self buildProgramVertexShader: vertexShaderSource  fragmentShader: rectangleTextureFragmentShaderSource];
	screenSizeUniformLocation = glGetUniformLocation(rectangleTextureProgram, "screenSize");
}

- (void) bindScreenQuadBuffer {
	glBindBuffer(GL_ARRAY_BUFFER, screenQuadVertexBuffer);
	glEnableVertexAttribArray(0);
	glEnableVertexAttribArray(1);
	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(struct Vertex2D), (const GLvoid*)offsetof(struct Vertex2D, x));
	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(struct Vertex2D), (const GLvoid*)offsetof(struct Vertex2D, u));
}

- (void) buildScreenQuad {
	glGenBuffers(1, &screenQuadVertexBuffer);
	glBindBuffer(GL_ARRAY_BUFFER, screenQuadVertexBuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(screenQuadVertices), screenQuadVertices, GL_STATIC_DRAW);
	
	// Try to use a vertex array object, if available.
	if(hasVertexArrayObject) {
		glGenVertexArraysAPPLE(1, &screenQuadVertexArray);
		glBindVertexArrayAPPLE(screenQuadVertexArray);
		[self bindScreenQuadBuffer];
		glBindVertexArrayAPPLE(0);
	}
}

- (void) drawScreenQuad {
	if(hasVertexArrayObject) {
		glBindVertexArrayAPPLE(screenQuadVertexArray);
	} else {
		[self bindScreenQuadBuffer];
	}
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void) drawDisplayTexture {
	glUseProgram(rectangleTextureProgram);
	glUniform2f(screenSizeUniformLocation, (int)displayTextureWidth, (int)displayTextureHeight);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, displayTexture);
	[self drawScreenQuad];
}

-(void) updateDisplayTextureStorage {
    NSRect rectangle = [self convertRectToBacking: [self frame]];
	displayTextureWidth = rectangle.size.width;
	displayTextureHeight = rectangle.size.height;

	glActiveTexture(GL_TEXTURE0);
	if(!displayTexture) {
		glGenTextures(1, &displayTexture);

		// We use GL_TEXTURE_RECTANGLE_ARB to avoid some temporary buffer copies
		// according to the following document: https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/opengl_texturedata/opengl_texturedata.html
		glBindTexture(GL_TEXTURE_RECTANGLE_ARB, displayTexture);
		//glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_SHARED_APPLE);
		
		// Prefer copying into VRAM. Shared storage introduce some graphics
		// glitches. They could be removed calling glFinish instead of glFlush,
		// however glFinish stalls the CPU and kills the asynchronous rendering
		// with the GPU.
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_PRIVATE_APPLE);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	} else {
		glBindTexture(GL_TEXTURE_RECTANGLE_ARB, displayTexture);		
	}
	
	//printf("updateDisplayTextureStorage %d %d %p\n", displayTextureWidth, displayTextureHeight, currentDisplayStorage);
	glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_ARB, displayTextureWidth*displayTextureHeight*4, currentDisplayStorage);
	
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
 	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, displayTextureWidth);
	glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, displayTextureWidth, displayTextureHeight, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, currentDisplayStorage);
}

- (void)loadTexturesFrom: (void*) displayStorage subRectangle: (NSRect) subRect {
//	CGL_MACRO_DECLARE_VARIABLES();
    NSRect r = [self convertRectToBacking: [self frame]];
    if (!NSEqualRects(lastFrameSize,r) || !displayTexture ||
		currentDisplayStorage != displayStorage) {
		//NSLog(@"old %f %f %f %f new %f %f %f %f",lastFrameSize.origin.x,lastFrameSize.origin.y,lastFrameSize.size.width,lastFrameSize.size.height,self.frame.origin.x,r.origin.y,r.size.width,r.size.height);
        lastFrameSize = r;
		currentDisplayStorage = displayStorage;
		[self updateDisplayTextureStorage];
        [[self openGLContext] update];
    }

	char *subimg = ((char*)displayStorage) + (unsigned int)(subRect.origin.x + (displayTextureHeight-subRect.origin.y-subRect.size.height)*displayTextureWidth)*4;

	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, displayTexture);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
 	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, displayTextureWidth);
	glTexSubImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, subRect.origin.x, displayTextureHeight - subRect.origin.y - subRect.size.height, subRect.size.width, subRect.size.height, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, subimg);
	//NSLog(@" glTexImage2D %f %f %f %f",subRect.origin.x,subRect.origin.y,subRect.size.width,subRect.size.height);
}

- (void) setupFullScreendispBitsIndex {
    self.fullScreendispBitsIndex = displayBits;
}

-(void)drawRect:(NSRect)rect
{
	// TODO: Figure out who calls this to convert rect there.
	// It is rather dangerous to have such different semantics
	// between drawRect: and drawRect:flush:. We assume that
	// only the OS calls this, not any image primitive.
	NSPoint priorOrigin = rect.origin;
	rect = [self convertRectToBacking: rect];
	rect.origin = priorOrigin;

	// Called by Cocoa. We need to flush.
	[self drawRect: rect flush: YES];
}

-(void)drawRect:(NSRect)rect flush:(BOOL)flush
{
    if (self.fullScreenInProgress && openglInitialized) {
        if (self.fullScreendispBitsIndex == displayBits) {
            [self clearScreen];
            //NSLog(@"drawRect but fullScreenInProgress %f %f %f %f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
            return;
        }
        self.fullScreenInProgress = NO;
    }

	//NSLog(@" draw %f %f %f %f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
	NSOpenGLContext *oldContext = [NSOpenGLContext currentContext];
	[[self openGLContext] makeCurrentContext];

	[self setupOpenGL];
    [self setupFullScreendispBitsIndex];

    if ( fullScreendispBitsIndex ) {
		[self loadTexturesFrom:fullScreendispBitsIndex subRectangle: rect];
	}

	[self drawScreenRect: rect];

	if(flush) {
		glFlush();
		[[self openGLContext] flushBuffer];
	}
	
    if (oldContext != nil) {
        [oldContext makeCurrentContext];
    } else {
		[NSOpenGLContext clearCurrentContext];
	}
}

-(void)drawScreenRect:(NSRect)rect
{	
	unsigned int drawnExtraLayerMask;
	unsigned int i;
	
	glEnable(GL_SCISSOR_TEST);
	
	glViewport(0, 0, displayTextureWidth, displayTextureHeight);
	glScissor(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	if(!displayTexture) {
		glClearColor(1, 1, 1, 1);
		glClear(GL_COLOR_BUFFER_BIT);
	}
	
	[self drawDisplayTexture];
	
	drawnExtraLayerMask = 0;
	for(i = 0; i < MAX_NUMBER_OF_EXTRA_LAYERS && drawnExtraLayerMask != allocatedExtraLayers; ++i) {
		if(allocatedExtraLayers & (1 << i)) {
			[self drawExtraLayer: i];
			drawnExtraLayerMask |= 1 << i;
		}
	}
	
	if(hasVertexArrayObject) {
		glBindVertexArrayAPPLE(0);
	}
	
	//[self dumpDisplayTexture];
}

- (void) drawExtraLayer: (unsigned int) extraLayerIndex {
	ExtraLayer *layer = &extraLayers[extraLayerIndex];
	if(!layer->texture)
		return;
		
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, layer->texture);
	glUseProgram(textureProgram);
	
    NSRect screenRect = [self convertRectToBacking: [self frame]];
	float scaleX = (float)layer->w / screenRect.size.width;
	float scaleY = (float)layer->h / screenRect.size.height;
 	float offsetX = (2.0f*layer->x + layer->w) / screenRect.size.width - 1.0f;
	float offsetY = 1.0f - (2.0f*layer->y + layer->h) / screenRect.size.height;
	
	glUniform4f(layerScaleAndTranslationUniformLocation, scaleX, scaleY, offsetX, offsetY);
	[self drawScreenQuad];
}

// Function for debugging purposes.
-(void)dumpDisplayTexture
{
	static int dumpCount = 0;
	static char *dumpBuffer = NULL;
	char dumpName[64];
	
	struct __attribute__((packed)) TGAHeader
	{
		char idLength;
		char colorMapType;
		char imageType;
		char colorMapSpec[5];
		short xOrigin;
		short yOrigin;
		short width;
		short height;
		char depth;
		char descriptor;
	};
	
	if(!displayTexture)
		return;
		
	sprintf(dumpName, "frame_%04d.tga", dumpCount++);
	
	struct TGAHeader header;
	memset(&header, 0, sizeof(header));
	header.imageType = 2;
	header.depth = 32;
	header.width = displayTextureWidth;
	header.height = displayTextureHeight;
	
	dumpBuffer = malloc(displayTextureWidth*displayTextureHeight*4);
	
	glPixelStorei(GL_PACK_ALIGNMENT, 1);
	glPixelStorei(GL_PACK_ROW_LENGTH, displayTextureWidth);
	//glBindTexture(GL_TEXTURE_RECTANGLE_ARB, displayTexture);
	//glGetTexImage(GL_TEXTURE_RECTANGLE_ARB, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, dumpBuffer);
	//glReadPixels(0, 0, displayTextureWidth, displayTextureHeight, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, dumpBuffer);
	
	FILE *f = fopen(dumpName, "wb");
	fwrite(&header, sizeof(header), 1, f);
	fwrite(dumpBuffer, displayTextureWidth*displayTextureHeight*4, 1, f);
	fclose(f);
	
	free(dumpBuffer);
}


#pragma mark Fullscreen

- (void) clearScreen {
    NSOpenGLContext *oldContext = [NSOpenGLContext currentContext];
    [self.openGLContext makeCurrentContext];
    
	glDisable( GL_SCISSOR_TEST);
	glClear( GL_COLOR_BUFFER_BIT);
	
	[self drawScreenRect: [self convertRectToBacking: [self frame]]];
    glFlush();
	[self.openGLContext flushBuffer];
    if (oldContext != nil) {
        [oldContext makeCurrentContext];
    } else {
		[NSOpenGLContext clearCurrentContext];
	}
}

- (void) ioSetFullScreen: (sqInt) fullScreen {
	if ((self.window.styleMask & NSFullScreenWindowMask) != (fullScreen == 1)) {
		self.fullScreenInProgress = YES;
        [self.window toggleFullScreen: nil];
	}
}

@end

NSOpenGLContext *
getMainWindowOpenGLContext(void) {
	return mainOpenGLContext;
}

unsigned int
createOpenGLTextureLayerHandle(void) {
	unsigned int i;
	unsigned int bit;
	for(i = 0; i < MAX_NUMBER_OF_EXTRA_LAYERS; ++i) {
		bit = 1<<i;
		if(!(allocatedExtraLayers & bit)) {
			allocatedExtraLayers |= bit;
			return i + 1;
		}
	}
	return 0;
}

void
destroyOpenGLTextureLayerHandle(unsigned int handle) {
	unsigned int bit = 1 << (handle - 1);
	if(allocatedExtraLayers & bit) {
		extraLayers[handle - 1].texture = 0;
		allocatedExtraLayers &= ~bit;
		
		// Redraw the screen.
		if(mainOpenGLView)
			[mainOpenGLView clearScreen];
	}
}

void
setOpenGLTextureLayerContent(unsigned int handle, GLuint texture, int x, int y, int w, int h) {
	unsigned int bit = 1 << (handle - 1);
	if(allocatedExtraLayers & bit) {
		ExtraLayer *layer = &extraLayers[handle - 1];
		layer->texture = texture;
		layer->x = x;
		layer->y = y;
		layer->w = w;
		layer->h = h;
		
		// Swap the buffers
		if(mainOpenGLView)
			[mainOpenGLView clearScreen];
	}
}

#endif // USE_OPENGL
