#import "sqSqueakOSXViewFactory.h"
#import "SqueakOSXAppDelegate.h"
#import "sq.h"
#import "sqVirtualMachine.h"

#ifdef USE_METAL
#import "sqSqueakOSXMetalView.h"
#endif

#ifdef USE_CORE_GRAPHICS
#import "sqSqueakOSXCGView.h"
#endif

#ifdef USE_OPENGL
#import "sqSqueakOSXOpenGLView.h"
#endif

#import "sqSqueakOSXHeadlessView.h"

extern SqueakOSXAppDelegate *gDelegateApp;
extern struct	VirtualMachine* interpreterProxy;

sqOSXRequestedViewType sqCurrentOSXRequestedViewType = SQ_OSX_REQUESTED_VIEW_TYPE_ANY;

@implementation sqSqueakOSXViewFactory

#pragma mark Initialization / Release

+ (id) getRequestedViewClass {
    // Try to use the Metal view
#ifdef USE_METAL
    if(sqCurrentOSXRequestedViewType == SQ_OSX_REQUESTED_VIEW_TYPE_ANY ||
       sqCurrentOSXRequestedViewType == SQ_OSX_REQUESTED_VIEW_TYPE_METAL) {
        if([sqSqueakOSXMetalView isMetalViewSupported])
        {
            return [sqSqueakOSXMetalView class];
        }
    }
#endif

#ifdef USE_CORE_GRAPHICS
    // Try to use the Core graphics view, only if it is requested.
    if(sqCurrentOSXRequestedViewType == SQ_OSX_REQUESTED_VIEW_TYPE_CORE_GRAPHICS) {
        return [sqSqueakOSXCGView class];
    }
#endif
    
#ifdef USE_OPENGL
    // Try with the OpenGL view.
    if(sqCurrentOSXRequestedViewType == SQ_OSX_REQUESTED_VIEW_TYPE_ANY ||
       sqCurrentOSXRequestedViewType == SQ_OSX_REQUESTED_VIEW_TYPE_OPENGL) {
        return [sqSqueakOSXOpenGLView class];
    }
#endif
        
    // Fallback to the headless view.
    return [sqSqueakOSXHeadlessView class];
}

+ (id) allocWithZone: (struct _NSZone *)zone {
    return [[self getRequestedViewClass] allocWithZone: zone];
}

+ (id) alloc {
    return [[self getRequestedViewClass] alloc];
}

+ (id) new {
    return [[self getRequestedViewClass] new];
}

@end
