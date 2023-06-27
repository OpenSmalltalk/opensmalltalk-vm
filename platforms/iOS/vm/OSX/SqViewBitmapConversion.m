/* SqViewBitmapConversion.m created by marcel on Fri 04-Dec-1998 */
//  CocoaSqueak
//
// John Notes: Waste not want not. 

/*
 From: Marcel Weiher <marcel.weiher@gmail.com>
 To: johnmci@smalltalkconsulting.com
 Subject: Re: [squeak-dev] Squeak and the iPhone
 Reply-To: Marcel Weiher <marcel.weiher@gmail.com>,
 The general-purpose Squeak developers list <squeak-dev@lists.squeakfoundation.org>
 Date: Wed, 18 Jun 2008 12:00:05 -0700
 Cc: The general-purpose Squeak developers list <squeak-dev@lists.squeakfoundation.org>
 
 The source code has been made available again at
 
 http://www.metaobject.com/downloads/Squeak/
 ...
 In the meantime, you have my express  
 permission to use it under an MIT license.
 
 */
#import "SqViewBitmapConversion.h"

#ifdef USE_METAL
#  import "sqSqueakOSXMetalView.h"
#  define ContentViewClass sqSqueakOSXMetalView
#  include "SqViewBitmapConversion.m.inc"
#  undef ContentViewClass
#endif

#ifdef USE_CORE_GRAPHICS
#  import "sqSqueakOSXCGView.h"
#  define ContentViewClass sqSqueakOSXCGView
#  include "SqViewBitmapConversion.m.inc"
#  undef ContentViewClass
#endif

#ifdef USE_OPENGL
#  import "sqSqueakOSXOpenGLView.h"
#  define ContentViewClass sqSqueakOSXOpenGLView
#  include "SqViewBitmapConversion.m.inc"
#  undef ContentViewClass
#endif

// Headless view
#import "sqSqueakOSXHeadlessView.h"
#define ContentViewClass sqSqueakOSXHeadlessView
#include "SqViewBitmapConversion.m.inc"
#undef ContentViewClass
