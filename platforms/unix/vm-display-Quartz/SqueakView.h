// -*- ObjC -*-

// Why QDView?  Well...
// 
//   1) we can trivially obtain a raw pointer to its backing store, so
//   2) no need to putz around with the lockFocus/DataProvider/ImageRep crap; plus
//   3) its buffer's coordinate system is already the right way up for Squeak, so
//   4) we avoid potential recopy (just to have CG recopy again); besides
//   5) QDFlushBuffer is _blindingly_ fast (even compared to drawing directly on
//      the framebuffer [go measure it if you don't believe me]); but most importantly
//   6) the QD API is completely free of ObjC and attendant inefficiencies.

@interface SqueakView : NSQuickDrawView <NSTextInput>
- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) isOpaque;
- (BOOL) isFlipped;
- (id)   initWithFrame: (NSRect)frame;
- (void) setFrame: (NSRect)rect;
- (void) drawRect: (NSRect)rect;
- (void) viewWillStartLiveResize;
- (void) viewDidEndLiveResize;
- (int)  draggingEntered: (id<NSDraggingInfo>)sender;
- (int)  draggingUpdated: (id<NSDraggingInfo>)sender;
- (void) draggingExited: (id<NSDraggingInfo>)sender;
- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender;
- (int) composeKeyDown: (NSEvent *)event;
- (int) composeKeyUp: (NSEvent *)event;
@end

