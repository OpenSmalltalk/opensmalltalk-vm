/* SqViewClut.m created by marcel on Sat 23-Dec-2000 */

#import "SqViewClut.h"

// Metal
#ifdef USE_METAL
#  import "sqSqueakOSXMetalView.h"
#  define ContentViewClass sqSqueakOSXMetalView
#  include "SqViewClut.m.inc"
#  undef ContentViewClass
#endif

// Core graphics
#ifdef USE_CORE_GRAPHICS
#  import "sqSqueakOSXCGView.h"
#  define ContentViewClass sqSqueakOSXCGView
#  include "SqViewClut.m.inc"
#  undef ContentViewClass
#endif

// OpenGL
#ifdef USE_OPENGL
#  import "sqSqueakOSXOpenGLView.h"
#  define ContentViewClass sqSqueakOSXOpenGLView
#  include "SqViewClut.m.inc"
#  undef ContentViewClass
#endif

// Headless view
#import "sqSqueakOSXHeadlessView.h"
#define ContentViewClass sqSqueakOSXHeadlessView
#include "SqViewClut.m.inc"
#undef ContentViewClass
