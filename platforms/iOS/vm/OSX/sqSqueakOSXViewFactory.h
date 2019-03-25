#import <Cocoa/Cocoa.h>
#include <ApplicationServices/ApplicationServices.h>
#import "keyBoardStrokeDetails.h"
#import "sqSqueakOSXView.h"
#import	"SqViewClut.h"

typedef enum {
    SQ_OSX_REQUESTED_VIEW_TYPE_ANY = 0,
    SQ_OSX_REQUESTED_VIEW_TYPE_NONE,
    SQ_OSX_REQUESTED_VIEW_TYPE_CORE_GRAPHICS,
    SQ_OSX_REQUESTED_VIEW_TYPE_OPENGL,
    SQ_OSX_REQUESTED_VIEW_TYPE_METAL,
} sqOSXRequestedViewType;

extern sqOSXRequestedViewType sqCurrentOSXRequestedViewType;

@class sqSqueakOSXScreenAndWindow;
#import "sq.h"

@interface sqSqueakOSXViewFactory : NSView {
}
@end
