//
//  sqSqueakOSXScreenAndWindow.h
//  SqueakPureObjc
//
//  Created by John M McIntosh on 09-11-14.
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



#if !FOR_OS_EXPORTS

#import "sqSqueakScreenAndWindow.h"
#import "sqSqueakOSXView.h"


@interface sqSqueakOSXScreenAndWindow : sqSqueakScreenAndWindow  <NSWindowDelegate>{
    NSView <sqSqueakOSXView>	*mainViewOnWindow;
}

- (NSView <sqSqueakOSXView> *) getMainViewOnWindow;
- (void) mainViewOnWindow: (NSView <sqSqueakOSXView> *) aView;

@end

#if MAC_OS_X_VERSION_MAX_ALLOWED < 101200
enum {
    NSEventTypeKeyDown        = NSKeyDown,
    NSEventTypeKeyUp          = NSKeyUp,
    NSEventTypeFlagsChanged   = NSFlagsChanged,
    NSEventTypeLeftMouseDown  = NSLeftMouseDown, 
    NSEventTypeLeftMouseUp    = NSLeftMouseUp,
    NSEventTypeRightMouseDown = NSRightMouseDown,
    NSEventTypeRightMouseUp   = NSRightMouseUp,
    NSEventTypeMouseMoved     = NSMouseMoved,
    NSEventTypeScrollWheel    = NSScrollWheel,
    NSEventTypeOtherMouseDown = NSOtherMouseDown,
    NSEventTypeOtherMouseUp   = NSOtherMouseUp
};
enum {
    NSEventModifierFlagCapsLock = NSAlphaShiftKeyMask,
    NSEventModifierFlagShift    = NSShiftKeyMask,
    NSEventModifierFlagControl  = NSControlKeyMask,
    NSEventModifierFlagOption   = NSAlternateKeyMask,
    NSEventModifierFlagCommand  = NSCommandKeyMask,
    NSEventModifierFlagFunction = NSFunctionKeyMask,
    NSEventModifierFlagDeviceIndependentFlagsMask = NSDeviceIndependentModifierFlagsMask,
    NSEventMaskAny              = NSAnyEventMask
};
#endif
#if MAC_OS_X_VERSION_MAX_ALLOWED < 101000
typedef NSUInteger NSEventModifierFlags;
#endif


#endif /* FOR_OS_EXPORTS */

void *getSTWindow(void);

/* A "chain" of windowChangedHooks, using the Unix signal convention; it is the
 * responsibility of the caller to remember any previous hook and chain it from
 * their own windowChangedHook.  Hence setWindowChangedHook answers the previous
 * windowChangedHook.
 */
typedef void (*windowChangedHook)();
extern windowChangedHook getWindowChangedHook(void);
extern windowChangedHook setWindowChangedHook(windowChangedHook hook);
