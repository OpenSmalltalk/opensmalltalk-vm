/* Automatically generated from Squeak on 22 December 2012 4:28:37 pm 
   by VMMaker 4.10.5
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Default EXPORT macro that does nothing (see comment in sq.h): */
#define EXPORT(returnType) returnType

/* Do not include the entire sq.h file but just those parts needed. */
/*  The virtual machine proxy definition */
#include "sqVirtualMachine.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"

#define true 1
#define false 0
#define null 0  /* using 'null' because nil is predefined in Think C */
#ifdef SQUEAK_BUILTIN_PLUGIN
#undef EXPORT
// was #undef EXPORT(returnType) but screws NorCroft cc
#define EXPORT(returnType) static returnType
#endif
#include <cairo.h>
#include <cairo-ft.h>
#include <pango/pangocairo.h>
#include "SurfacePlugin.h"
#define NUM_OF(array) (sizeof (array) / sizeof *(array))
#define lastIndex(array) (NUM_OF(array) - 1)
#define degrees(a) (a * 3.141592653589793 / 180.0)

#define log(msg) fprintf(stderr, "Squeak-Rome: " msg "\n")
#define logwith(msg, a) fprintf(stderr, "Squeak-Rome: " msg "\n", a)
#define logwithwith(msg, a, b) fprintf(stderr, "Squeak-Rome: " msg "\n", a, b)
#define logwithwithwith(msg, a, b, c) fprintf(stderr, "Squeak-Rome: " msg "\n", a, b, c)
#define logwithwithwithwith(msg, a, b, c, d) fprintf(stderr, "Squeak-Rome: " msg "\n", a, b, c, d)
#define logwithwithwithwithwith(msg, a, b, c, d, e) fprintf(stderr, "Squeak-Rome: " msg "\n", a, b, c, d, e)

#define primFail interpreterProxy->primitiveFail()
#define fail(msg) log(msg "!"); primFail
#define failwith(msg, a) logwith(msg "!", a); primFail
#define failwithwith(msg, a, b) logwithwith(msg "!", a, b); primFail


#include "sqMemoryAccess.h"


/*** Constants ***/
#define CairoExtendRepeat CAIRO_EXTEND_REPEAT
#define CairoOperatorSource CAIRO_OPERATOR_SOURCE
#define CanvasFlagFill 256
#define CanvasFlagStroke 255
#define CanvasFlagsIndex 2
#define CanvasHandleIndex 0
#define CanvasInstSize 8
#define CanvasStrokeColorIndex 3
#define CanvasTargetIndex 1
#define FormBitsIndex 0
#define FormDepthIndex 3
#define FormHeightIndex 2
#define FormInstSize 5
#define FormWidthIndex 1
#define PluginVersion 39
#define TextLineBottomIndex 3
#define TextLineEndIndex 5
#define TextLineInternalSpaceIndex 6
#define TextLineLeftIndex 0
#define TextLinePaddingWidthIndex 7
#define TextLineRightIndex 1
#define TextLineStartIndex 4
#define TextLineTopIndex 2

/*** Function Prototypes ***/
static sqInt addAlignmentinto(sqInt attrArrayOop, PangoAttrList *pangoAttrList);
static sqInt addColorinto(sqInt attrArrayOop, PangoAttrList *pangoAttrList);
static void addColorStopTooffsetrgbalpha(cairo_pattern_t*pattern, sqInt intOffset, sqInt rgb, sqInt alpha);
static sqInt addDefaultInto(PangoAttrList *pangoAttrList);
static sqInt addEmphasisinto(sqInt attrArrayOop, PangoAttrList *pangoAttrList);
static sqInt addFontinto(sqInt attrArrayOop, PangoAttrList *pangoAttrList);
static sqInt addLanguageinto(sqInt attrArrayOop, PangoAttrList *pangoAttrList);
static sqInt addSelectionAtpixelwith(PangoRectangle *rect, unsigned int c, cairo_t*context);
static sqInt addSelectionFromtopixelinto(sqInt start, sqInt end, unsigned int c, PangoAttrList *pangoAttrList);
static cairo_t* contextFrom(sqInt canvasOop);
static sqInt createContextFor(sqInt canvasOop);
static sqInt createSurfaceFor(sqInt formOop);
static sqInt destroyContextFor(sqInt canvasOop);
static sqInt destroySurface(sqInt surfaceID);
static void fillOrStrokefrom(cairo_t*context, sqInt canvasOop);
static cairo_surface_t* findSurface(sqInt surfaceID);
static VirtualMachine * getInterpreter(void);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static sqInt getSurfaceFormatgetWgetHgetDgetMsb(cairo_surface_t *surfaceHandle, int*wReturn, int*hReturn, int*dReturn, int*mReturn);
static sqInt halt(void);
#pragma export on
EXPORT(sqInt) initialiseModule(void);
#pragma export off
static sqInt leadingCharOf(unsigned int value);
static sqInt loadSurfacePlugin(void);
static unsigned char* lockSurfacegetPitchxywh(cairo_surface_t*surfaceHandle, int*pitchReturn, sqInt x, sqInt y, sqInt w, sqInt h);
#pragma export on
EXPORT(sqInt) moduleUnloaded(char *aModuleName);
#pragma export off
static sqInt msg(char *s);
static void polyPathfrom(cairo_t*context, sqInt pointsOop);
#pragma export on
EXPORT(sqInt) primitivePangoBlockAtIndex(void);
EXPORT(sqInt) primitiveClear(void);
EXPORT(sqInt) primitiveClipRectangleLeftRightTopBottom(void);
EXPORT(sqInt) primitiveClose(void);
EXPORT(sqInt) primitivePangoComposeString(void);
EXPORT(sqInt) primitivePangoComposeString2(void);
EXPORT(sqInt) primitiveCreateFormHandle(void);
EXPORT(sqInt) primitiveDestroyFormHandle(void);
EXPORT(sqInt) primitiveDrawArcRadiusXYFromTo(void);
EXPORT(sqInt) primitiveDrawCurveFromXYviaXYandXYtoXY(void);
EXPORT(sqInt) primitiveDrawCurveFromXYviaXYtoXY(void);
EXPORT(sqInt) primitiveDrawGeneralBezierShape(void);
EXPORT(sqInt) primitiveDrawImageSrcLRTBDestLRTB(void);
EXPORT(sqInt) primitiveDrawLineFromXYtoXY(void);
EXPORT(sqInt) primitiveDrawOvalLeftRightTopBottom(void);
EXPORT(sqInt) primitiveDrawPolygon(void);
EXPORT(sqInt) primitiveDrawPolyline(void);
EXPORT(sqInt) primitiveDrawRectangleLeftRightTopBottom(void);
EXPORT(sqInt) primitiveDrawRoundRectLeftRightTopBottomRadiusCorner(void);
EXPORT(sqInt) primitiveDrawZeroTerminatedUtf8StringXY(void);
EXPORT(sqInt) primitiveFillBitmapOriginXYdirectionXYnormalXYRepeatImage(void);
EXPORT(sqInt) primitiveFillColorAlpha(void);
EXPORT(sqInt) primitiveFillLinearOriginXYdirectionXYcolorStops(void);
EXPORT(sqInt) primitiveFillRadialOriginXYdirectionXYnormalXYcolorStops(void);
EXPORT(sqInt) primitiveFontFace(void);
EXPORT(sqInt) primitiveFontSize(void);
EXPORT(sqInt) primitiveGetLineWidth(void);
EXPORT(sqInt) primitivePangoFontDescriptionIndex(void);
EXPORT(sqInt) primitiveGetTransform(void);
EXPORT(sqInt) primitivePangoIndexAtPoint(void);
EXPORT(sqInt) primitiveLanguageAttributes(void);
EXPORT(sqInt) primitiveOpen(void);
EXPORT(sqInt) primitivePangoIsAvailable(void);
EXPORT(sqInt) primitivePluginVersion(void);
EXPORT(sqInt) primitiveRestoreState(void);
EXPORT(sqInt) primitiveRotateBy(void);
EXPORT(sqInt) primitiveSaveState(void);
EXPORT(sqInt) primitiveScaleBy(void);
EXPORT(sqInt) primitiveSetLineWidth(void);
EXPORT(sqInt) primitiveSetTransform(void);
EXPORT(sqInt) primitivePangoShowString(void);
EXPORT(sqInt) primitiveShowZeroTerminatedUtf8StringXY(void);
EXPORT(sqInt) primitiveStencilImageSrcLRTBDestLRTB(void);
EXPORT(sqInt) primitiveTransformBy(void);
EXPORT(sqInt) primitiveTranslateBy(void);
EXPORT(sqInt) primitiveUTF8StringWith2Indexes(void);
EXPORT(sqInt) primitiveUTF8StringWithIndex(void);
#pragma export off
static sqInt putCharintoat(sqInt c, unsigned char*utf8String, sqInt utf8Index);
static sqInt registerSurface(cairo_surface_t*surfaceHandle);
#pragma export on
EXPORT(sqInt) setInterpreter(struct VirtualMachine*anInterpreter);
#pragma export off
static void setSourcergbalpha(cairo_t*context, sqInt rgb, sqInt alpha);
static sqInt showSurfacexywh(cairo_surface_t *surfaceHandle, sqInt x, sqInt y, sqInt w, sqInt h);
#pragma export on
EXPORT(sqInt) shutdownModule(void);
#pragma export off
static sqInt sqAssert(sqInt aBool);
static sqInt sqCharCountInfromto(unsigned char* aString, sqInt from, sqInt to);
static void strokefrom(cairo_t*context, sqInt canvasOop);
static cairo_surface_t* surfaceFrom(sqInt formOop);
static sqInt translateSqAttrsToPangoAttrsinto(sqInt sqAttrsArrayOop, PangoAttrList *pangoAttrList);
static sqInt unlockSurfacexywh(cairo_surface_t*surfaceHandle, sqInt x, sqInt y, sqInt w, sqInt h);
static sqInt unregisterSurface(sqInt surfaceID);
static sqInt utf8CountFor(unsigned int value);
/*** Variables ***/
static cairo_t* contexts[64];
static PangoFontDescription *defaultFontDescription;
static fn_ioFindSurface findSurfaceFn;
static PangoFontDescription *fontDescriptions[256];
static int formatToDepth[] = {
32, 32, 8, 1, 16};

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static sqInt maxSurfaceID;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"RomePlugin yo.39 22 December 2012 (i)"
#else
	"RomePlugin yo.39 22 December 2012 (e)"
#endif
;
static fn_ioRegisterSurface registerSurfaceFn;
static sqSurfaceDispatch surfaceDispatch = {
  1,
  0,
  (fn_getSurfaceFormat) getSurfaceFormatgetWgetHgetDgetMsb,
  (fn_lockSurface) lockSurfacegetPitchxywh,
  (fn_unlockSurface) unlockSurfacexywh,
  (fn_showSurface) showSurfacexywh
};
static fn_ioUnregisterSurface unregisterSurfaceFn;
static int utf8Headers[] = {
0, 192, 224, 240, 248, 252, 254, 255};


static sqInt addAlignmentinto(sqInt attrArrayOop, PangoAttrList *pangoAttrList) {
	sqInt start;
	sqInt alignment;
	int pangoAlignment;
	sqInt end;
	sqInt *attrArray;

	attrArray = interpreterProxy->firstIndexableField(attrArrayOop);
	start = ((attrArray[1]) >> 1);
	end = ((attrArray[2]) >> 1);
	alignment = ((attrArray[3]) >> 1);
	if (alignment == 0) {
		pangoAlignment = PANGO_ALIGN_LEFT;
	}
	if (alignment == 1) {
		pangoAlignment = PANGO_ALIGN_RIGHT;
	}
	if (alignment == 2) {
		pangoAlignment = PANGO_ALIGN_CENTER;
	}
	if (alignment == 3) {
		null;
	}
}

static sqInt addColorinto(sqInt attrArrayOop, PangoAttrList *pangoAttrList) {
	sqInt start;
	sqInt r;
	sqInt b;
	PangoAttribute *pangoAttr;
	sqInt end;
	sqInt g;
	sqInt alpha;
	sqInt *attrArray;
	unsigned int c;

	attrArray = interpreterProxy->firstIndexableField(attrArrayOop);
	start = ((attrArray[1]) >> 1);
	end = ((attrArray[2]) >> 1);

	/* self log: 'color: %u' with: c. */

	c = interpreterProxy->positive32BitValueOf(attrArray[3]);
	alpha = ((usqInt) (c && 4278190080U)) >> 24;
	r = ((usqInt) (c & 16711680)) >> 16;
	g = ((usqInt) (c & 65280)) >> 8;
	b = c & 255;
	if (!(r == 0)) {
		r = r * 257;
	}
	if (!(g == 0)) {
		g = g * 257;
	}
	if (!(b == 0)) {
		b = b * 257;
	}
	pangoAttr = pango_attr_foreground_new(r, g, b);
	pangoAttr->start_index = start;
	pangoAttr->end_index = end;
	pango_attr_list_change(pangoAttrList, pangoAttr);
}

static void addColorStopTooffsetrgbalpha(cairo_pattern_t*pattern, sqInt intOffset, sqInt rgb, sqInt alpha) {
	sqInt b;
	sqInt r;
	sqInt g;

	r = (((usqInt) rgb) >> 20) & 1023;
	g = (((usqInt) rgb) >> 10) & 1023;
	b = (((usqInt) rgb) >> 0) & 1023;
	if (alpha == 255) {
		cairo_pattern_add_color_stop_rgb(pattern, intOffset / 65536.0, r / 1023.0, g / 1023.0, b / 1023.0);
	} else {
		cairo_pattern_add_color_stop_rgba(pattern, intOffset / 65536.0, r / 1023.0, g / 1023.0, b / 1023.0, alpha / 255.0);
	}
}

static sqInt addDefaultInto(PangoAttrList *pangoAttrList) {
	PangoAttribute *pangoAttr;
	PangoLanguage *lang;

	pangoAttr = pango_attr_foreground_new(0, 0, 1);
	pangoAttr->start_index = 0;
	pangoAttr->end_index = 0x7fffffff;
	pango_attr_list_insert(pangoAttrList, pangoAttr);
	pangoAttr = pango_attr_font_desc_new(defaultFontDescription);
	pangoAttr->start_index = 0;
	pangoAttr->end_index = 0x7fffffff;
	pango_attr_list_insert(pangoAttrList, pangoAttr);
	lang = pango_language_from_string("en-US");
	pangoAttr = pango_attr_language_new(lang);
	pangoAttr->start_index = 0;
	pangoAttr->end_index = 0x7fffffff;
	pango_attr_list_insert(pangoAttrList, pangoAttr);
}

static sqInt addEmphasisinto(sqInt attrArrayOop, PangoAttrList *pangoAttrList) {
	sqInt start;
	PangoAttribute *pangoAttr;
	sqInt end;
	sqInt *attrArray;
	sqInt c;

	attrArray = interpreterProxy->firstIndexableField(attrArrayOop);
	start = ((attrArray[1]) >> 1);
	end = ((attrArray[2]) >> 1);
	c = ((attrArray[3]) >> 1);
	if (c & 1) {
		pangoAttr = pango_attr_weight_new(PANGO_WEIGHT_BOLD);
		pangoAttr->start_index = start;
		pangoAttr->end_index = end;
		pango_attr_list_change(pangoAttrList, pangoAttr);
	}
	if (c & 2) {
		pangoAttr = pango_attr_style_new(PANGO_STYLE_OBLIQUE);
		pangoAttr->start_index = start;
		pangoAttr->end_index = end;
		pango_attr_list_change(pangoAttrList, pangoAttr);
	}
	if (c & 4) {
		pangoAttr = pango_attr_underline_new(PANGO_UNDERLINE_SINGLE);
		pangoAttr->start_index = start;
		pangoAttr->end_index = end;
		pango_attr_list_change(pangoAttrList, pangoAttr);
	}
	if (c & 8) {
		pangoAttr = pango_attr_stretch_new(PANGO_STRETCH_CONDENSED);
		pangoAttr->start_index = start;
		pangoAttr->end_index = end;
		pango_attr_list_change(pangoAttrList, pangoAttr);
	}
	if (c & 16) {
		pangoAttr = pango_attr_strikethrough_new(1);
		pangoAttr->start_index = start;
		pangoAttr->end_index = end;
		pango_attr_list_change(pangoAttrList, pangoAttr);
	}
}

static sqInt addFontinto(sqInt attrArrayOop, PangoAttrList *pangoAttrList) {
	sqInt start;
	PangoFontDescription *desc;
	sqInt fontDescIndex;
	PangoAttribute *pangoAttr;
	sqInt end;
	sqInt *attrArray;

	attrArray = interpreterProxy->firstIndexableField(attrArrayOop);
	start = ((attrArray[1]) >> 1);
	end = ((attrArray[2]) >> 1);
	fontDescIndex = interpreterProxy->fetchIntegerofObject(5, attrArray[4]);
	if (fontDescIndex < 0) {
		return null;
	}
	if (fontDescIndex > 255) {
		return null;
	}
	desc = fontDescriptions[fontDescIndex];
	if (desc == null) {
		return null;
	}
	pangoAttr = pango_attr_font_desc_new(desc);
	pangoAttr->start_index = start;
	pangoAttr->end_index = end;
	pango_attr_list_change(pangoAttrList, pangoAttr);
}

static sqInt addLanguageinto(sqInt attrArrayOop, PangoAttrList *pangoAttrList) {
	sqInt start;
	PangoAttribute *pangoAttr;
	sqInt end;
	sqInt lang;
	char *cLang;
	sqInt *attrArray;
	PangoLanguage *pangoLang;

	attrArray = interpreterProxy->firstIndexableField(attrArrayOop);
	start = ((attrArray[1]) >> 1);
	end = ((attrArray[2]) >> 1);
	lang = ((attrArray[3]) >> 1);
	if (lang == 0) {
		cLang = "en-US";
	}
	if (lang == 5) {
		cLang = "ja-JP";
	}
	if (lang == 6) {
		cLang = "zh-CN";
	}
	if (lang == 7) {
		cLang = "ko-KR";
	}
	if (lang == 9) {
		cLang = "zh-TW";
	}
	if (lang == 13) {
		cLang = "el-EL";
	}
	if (lang == 15) {
		cLang = "ne-NP";
	}
	pangoLang = pango_language_from_string(cLang);
	pangoAttr = pango_attr_language_new(pangoLang);
	pangoAttr->start_index = start;
	pangoAttr->end_index = end;
	pango_attr_list_change(pangoAttrList, pangoAttr);
}

static sqInt addSelectionAtpixelwith(PangoRectangle *rect, unsigned int c, cairo_t*context) {
	sqInt a;
	sqInt r;
	sqInt b;
	sqInt g;

	a = ((usqInt) (c & 4278190080U)) >> 24;
	if (a == 0) {
		return null;
	}
	r = ((usqInt) (c & 16711680)) >> 16;
	g = ((usqInt) (c & 65280)) >> 8;
	b = c & 255;
	cairo_save(context);
	cairo_set_source_rgba(context, r / 255.0, g / 255.0, b / 255.0, a / 255.0);
	cairo_new_path(context);
	cairo_move_to(context, PANGO_PIXELS(rect->x) + 1, PANGO_PIXELS(rect->y));
	cairo_line_to(context, PANGO_PIXELS(rect->x) + 1, PANGO_PIXELS(rect->y+rect->height));
	cairo_stroke(context);
	cairo_restore(context);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
}

static sqInt addSelectionFromtopixelinto(sqInt start, sqInt end, unsigned int c, PangoAttrList *pangoAttrList) {
	sqInt r;
	sqInt b;
	PangoAttribute *pangoAttr;
	sqInt g;
	sqInt alpha;

	alpha = ((usqInt) (c && 4278190080U)) >> 24;
	r = ((usqInt) (c & 16711680)) >> 16;
	g = ((usqInt) (c & 65280)) >> 8;
	b = c & 255;
	if ((alpha == 0) && ((r == 0) && ((g == 0) && (b == 0)))) {
		return null;
	}
	if (!(r == 0)) {
		r = r * 257;
	}
	if (!(g == 0)) {
		g = g * 257;
	}
	if (!(b == 0)) {
		b = b * 257;
	}
	pangoAttr = pango_attr_background_new(r, g, b);
	pangoAttr->start_index = start;
	pangoAttr->end_index = end;
	pango_attr_list_change(pangoAttrList, pangoAttr);
}


/*	Get contexts[canvasOop's handle] */

static cairo_t* contextFrom(sqInt canvasOop) {
	cairo_t*context;
	sqInt contextIndex;
	sqInt targetOop;

	if ((interpreterProxy->slotSizeOf(canvasOop)) < CanvasInstSize) {
		fail("canvas oop invalid");
		return null;
	}
	contextIndex = interpreterProxy->fetchIntegerofObject(CanvasHandleIndex, canvasOop);
	if (interpreterProxy->failed()) {
		contextIndex = interpreterProxy->fetchPointerofObject(CanvasHandleIndex, canvasOop);
		if (!(contextIndex == (interpreterProxy->nilObject()))) {
			fail("canvas handle not an integer");
		}
		return null;
	}
	if ((contextIndex < 0) || (contextIndex > (lastIndex(contexts)))) {
		failwith("canvas handle %i out of bounds", contextIndex);
		return null;
	}
	context = contexts[contextIndex];
	if (context == null) {
		failwith("canvas handle %i invalid", contextIndex);
		return null;
	}
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	targetOop = interpreterProxy->fetchPointerofObject(CanvasTargetIndex, canvasOop);
	if (!((surfaceFrom(targetOop)) == (cairo_get_target(context)))) {
		failwith("canvas handle %i does not match target", contextIndex);
		return null;
	}
	return context;
}

static sqInt createContextFor(sqInt canvasOop) {
	sqInt i;
	cairo_surface_t*targetSurface;
	cairo_t*context;
	sqInt targetID;
	sqInt contextIndex;
	sqInt targetOop;

	if ((interpreterProxy->slotSizeOf(canvasOop)) < CanvasInstSize) {
		fail("canvas oop invalid");
		return null;
	}
	targetOop = interpreterProxy->fetchPointerofObject(CanvasTargetIndex, canvasOop);
	if ((interpreterProxy->slotSizeOf(targetOop)) <= FormBitsIndex) {
		fail("target oop invalid");
		return null;
	}
	targetID = interpreterProxy->fetchIntegerofObject(FormBitsIndex, targetOop);
	if (interpreterProxy->failed()) {
		fail("target handle not an integer");
		return null;
	}
	targetSurface = findSurface(targetID);
	if (!((targetSurface != null) && ((cairo_surface_status(targetSurface)) == 0))) {
		fail("target surface invalid");
		return null;
	}
	contextIndex = -1;
	i = 0;
	while (i <= (lastIndex(contexts))) {
		if ((contexts[i]) == null) {
			contextIndex = i;
			i = lastIndex(contexts);
		}
		i += 1;
	}
	if (contextIndex < 0) {
		fail("too many canvases");
		return null;
	}
	context = cairo_create(targetSurface);
	contexts[contextIndex] = context;
	/* missing DebugCode */;
	return contextIndex;
}


/*	create a surface, register it in SurfacePlugin and answer its surface plugin ID */

static sqInt createSurfaceFor(sqInt formOop) {
	cairo_format_t format;
	sqInt bits;
	sqInt width;
	sqInt status;
	cairo_surface_t*surface;
	sqInt height;
	sqInt depth;

	if ((interpreterProxy->slotSizeOf(formOop)) < FormInstSize) {
		fail("form oop invalid");
		return -1;
	}
	width = interpreterProxy->fetchIntegerofObject(FormWidthIndex, formOop);
	height = interpreterProxy->fetchIntegerofObject(FormHeightIndex, formOop);
	depth = interpreterProxy->fetchIntegerofObject(FormDepthIndex, formOop);
	if (interpreterProxy->failed()) {
		fail("form fields are not integers");
		return -1;
	}
	switch(depth) {
		case 32: format = CAIRO_FORMAT_ARGB32; break;
		case 24: format = CAIRO_FORMAT_RGB24; break;
		case 16: format = CAIRO_FORMAT_RGB16_565; break;
		case  8: format = CAIRO_FORMAT_A8; break;
		case  1: format = CAIRO_FORMAT_A1; break;
		default: format = -1;
	}
	if ((width <= 0) || ((height <= 0) || (format < 0))) {
		fail("form fields out of range");
		return -1;
	}
	bits = interpreterProxy->fetchPointerofObject(FormBitsIndex, formOop);
	if (!(bits == (interpreterProxy->nilObject()))) {
		fail("form handle not nil");
		return -1;
	}
	surface = cairo_image_surface_create(format, width, height);
	status = cairo_surface_status(surface);
	if (!(status == 0)) {
		failwith("failed to create surface - %s", cairo_status_to_string(status));
		cairo_surface_destroy(surface);
		return -1;
	}
	return registerSurface(surface);
}

static sqInt destroyContextFor(sqInt canvasOop) {
	cairo_t*context;
	sqInt contextIndex;

	if ((interpreterProxy->slotSizeOf(canvasOop)) < CanvasInstSize) {
		fail("canvas oop invalid");
		return null;
	}
	contextIndex = interpreterProxy->fetchIntegerofObject(CanvasHandleIndex, canvasOop);
	if (interpreterProxy->failed()) {
		fail("canvas handle not an integer");
		return null;
	}
	if ((contextIndex < 0) || (contextIndex > (lastIndex(contexts)))) {
		failwith("canvas handle %i out of bounds", contextIndex);
		return null;
	}
	context = contexts[contextIndex];
	if (context == null) {
		failwith("canvas handle %i invalid", contextIndex);
		return null;
	}
	/* missing DebugCode */;
	cairo_destroy(context);
	contexts[contextIndex] = null;
	return null;
}


/*	fetch surface from surfaceID, destroy it and unregister from SurfacePlugin */

static sqInt destroySurface(sqInt surfaceID) {
	cairo_surface_t*surface;

	surface = findSurface(surfaceID);
	if (surface == null) {
		failwith("could not find surface %i", surfaceID);
		return null;
	}
	cairo_surface_destroy(surface);
	unregisterSurface(surfaceID);
	return null;
}


/*	fill or stroke depending on canvasOop's flags */

static void fillOrStrokefrom(cairo_t*context, sqInt canvasOop) {
	sqInt stroke;
	sqInt canvasFlags;
	sqInt fill;
	sqInt rgb;

	canvasFlags = interpreterProxy->fetchIntegerofObject(CanvasFlagsIndex, canvasOop);
	if (interpreterProxy->failed()) {
		fail("canvas flags not an integer");
	} else {
		fill = canvasFlags & CanvasFlagFill;
		stroke = canvasFlags & CanvasFlagStroke;
		if (fill != 0) {
			if (stroke != 0) {
				cairo_fill_preserve(context);
			} else {
				cairo_fill(context);
			}
		}
		if (stroke != 0) {
			rgb = interpreterProxy->fetchIntegerofObject(CanvasStrokeColorIndex, canvasOop);
			cairo_save(context);
			setSourcergbalpha(context, rgb, stroke);
			cairo_stroke(context);
			cairo_restore(context);
		}
	}
}


/*	Answer surface handle for surfaceID */

static cairo_surface_t* findSurface(sqInt surfaceID) {
	sqInt surfaceHandle;

	if (findSurfaceFn == null) {
		if (!(loadSurfacePlugin())) {
			return null;
		}
	}
	if (!((*findSurfaceFn)(surfaceID, &surfaceDispatch, &surfaceHandle))) {
		return null;
	}
	return ((cairo_surface_t*) surfaceHandle);
}


/*	Note: This is coded so that plugins can be run from Squeak. */

static VirtualMachine * getInterpreter(void) {
	return interpreterProxy;
}


/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}

static sqInt getSurfaceFormatgetWgetHgetDgetMsb(cairo_surface_t *surfaceHandle, int*wReturn, int*hReturn, int*dReturn, int*mReturn) {
	sqInt msb;
	sqInt width;
	sqInt depth;
	sqInt height;

	/* missing DebugCode */;
	width = cairo_image_surface_get_width(surfaceHandle);
	height = cairo_image_surface_get_height(surfaceHandle);
	depth = formatToDepth[cairo_image_surface_get_format(surfaceHandle)];
	msb = 1;
	*wReturn = width;
	*hReturn = height;
	*dReturn = depth;
	*mReturn = msb;
	return 1;
}

static sqInt halt(void) {
	;
}

EXPORT(sqInt) initialiseModule(void) {
	sqInt i;

	for (i = 0; i <= (lastIndex(contexts)); i += 1) {
		contexts[i] = null;
	}
	for (i = 0; i <= (lastIndex(fontDescriptions)); i += 1) {
		fontDescriptions[i] = null;
	}
	defaultFontDescription = pango_font_description_from_string("Times New Roman 10");
	registerSurfaceFn = null;
	unregisterSurfaceFn = null;
	findSurfaceFn = null;
	return 1;
}

static sqInt leadingCharOf(unsigned int value) {
	return ((usqInt) (value & 1069547520) >> 22);
}


/*	Load the surface support plugin */

static sqInt loadSurfacePlugin(void) {
	sqInt found;

	registerSurfaceFn = ((fn_ioRegisterSurface) (interpreterProxy->ioLoadFunctionFrom("ioRegisterSurface", "SurfacePlugin")));
	unregisterSurfaceFn = ((fn_ioUnregisterSurface) (interpreterProxy->ioLoadFunctionFrom("ioUnregisterSurface", "SurfacePlugin")));
	findSurfaceFn = ((fn_ioFindSurface) (interpreterProxy->ioLoadFunctionFrom("ioFindSurface", "SurfacePlugin")));
	found = (registerSurfaceFn != null) && ((unregisterSurfaceFn != null) && (findSurfaceFn != null));
	if (!(found)) {
		fail("could not load SurfacePlugin");
	}
	maxSurfaceID = -1;
	return found;
}

static unsigned char* lockSurfacegetPitchxywh(cairo_surface_t*surfaceHandle, int*pitchReturn, sqInt x, sqInt y, sqInt w, sqInt h) {
	sqInt pitch;
	unsigned char*data;

	/* missing DebugCode */;
	cairo_surface_flush(surfaceHandle);
	data = cairo_image_surface_get_data(surfaceHandle);
	pitch = cairo_image_surface_get_stride(surfaceHandle);
	*pitchReturn = pitch;
	return data;
}


/*	The module with the given name was just unloaded.
	Make sure we have no dangling references. */

EXPORT(sqInt) moduleUnloaded(char *aModuleName) {
	if ((strcmp(aModuleName, "SurfacePlugin")) == 0) {
		registerSurfaceFn = null;
		unregisterSurfaceFn = null;
		findSurfaceFn = null;
	}
	return 1;
}

static sqInt msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

static void polyPathfrom(cairo_t*context, sqInt pointsOop) {
	float*points;
	sqInt i;
	sqInt pointsCount;

	points = interpreterProxy->arrayValueOf(pointsOop);
	pointsCount = interpreterProxy->slotSizeOf(pointsOop);
	if (!(interpreterProxy->failed())) {
		if (pointsCount >= 2) {
			cairo_move_to(context, points[0], points[1]);
			for (i = 2; i <= (pointsCount - 1); i += 2) {
				cairo_line_to(context, points[i], points[i + 1]);
			}
		}
	}
}

EXPORT(sqInt) primitivePangoBlockAtIndex(void) {
	sqInt index;
	cairo_t*context;
	sqInt origin;
	unsigned char*aString;
	sqInt trailing;
	sqInt aStringOop;
	sqInt stringLength;
	PangoAttrList*attrList;
	sqInt atEnd;
	PangoLayout*layout;
	sqInt canvasOop;
	sqInt corner;
	sqInt charData;
	PangoRectangle pos;
	sqInt inStringOop;
	sqInt utf8Index;
	sqInt x;
	sqInt y;
	sqInt sqAttrArray;
	sqInt w;
	sqInt h;
	sqInt withWrap;
	sqInt cData;
	sqInt _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(8), "Object"));
	inStringOop = interpreterProxy->stackValue(8);
	utf8Index = interpreterProxy->stackIntegerValue(7);
	x = interpreterProxy->stackIntegerValue(6);
	y = interpreterProxy->stackIntegerValue(5);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(4), "Object"));
	sqAttrArray = interpreterProxy->stackValue(4);
	w = interpreterProxy->stackIntegerValue(3);
	h = interpreterProxy->stackIntegerValue(2);
	withWrap = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(1));
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Object"));
	cData = interpreterProxy->stackValue(0);
	;
	canvasOop = interpreterProxy->stackValue(9);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	aStringOop = inStringOop;
	aString = interpreterProxy->firstIndexableField(aStringOop);
	layout = pango_cairo_create_layout(context);
	attrList = pango_attr_list_new();
	translateSqAttrsToPangoAttrsinto(sqAttrArray, attrList);
	pango_layout_set_text(layout, aString, strlen(aString));
	pango_layout_set_attributes(layout, attrList);
	pango_layout_set_width(layout, w * (PANGO_SCALE));
	if (withWrap) {
		pango_layout_set_wrap(layout, PANGO_WRAP_WORD_CHAR);
	}
	cairo_translate(context, x, y);
	pango_cairo_update_layout(context, layout);
	stringLength = strlen(aString);
	if (utf8Index == (stringLength + 1)) {
		atEnd = 1;
		pango_layout_index_to_pos(layout, ((((((utf8Index - 1) < 0) ? 0 : (utf8Index - 1))) < stringLength) ? ((((utf8Index - 1) < 0) ? 0 : (utf8Index - 1))) : stringLength), &pos);
		pos.x = pos.x + pos.width;
	} else {
		atEnd = 0;
		pango_layout_index_to_pos(layout, (((((utf8Index < 0) ? 0 : utf8Index)) < stringLength) ? (((utf8Index < 0) ? 0 : utf8Index)) : stringLength), &pos);
	}
	pango_attr_list_unref(attrList);
	g_object_unref(layout);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	interpreterProxy->pushRemappableOop(aStringOop);
	interpreterProxy->pushRemappableOop(cData);
	origin = interpreterProxy->makePointwithxValueyValue((PANGO_PIXELS(pos.x)) + x, (PANGO_PIXELS(pos.y)) + y);
	interpreterProxy->pushRemappableOop(origin);
	corner = interpreterProxy->makePointwithxValueyValue((PANGO_PIXELS(pos.x+pos.width)) + x, (PANGO_PIXELS(pos.y+pos.height)) + y);
	origin = interpreterProxy->popRemappableOop();
	charData = interpreterProxy->popRemappableOop();
	aStringOop = interpreterProxy->popRemappableOop();
	aString = interpreterProxy->firstIndexableField(aStringOop);
	interpreterProxy->storePointerofObjectwithValue(0, charData, origin);
	interpreterProxy->storePointerofObjectwithValue(1, charData, corner);
	index = sqCharCountInfromto(aString, 0, utf8Index);
	if (!(atEnd)) {
		index += 1;
	}
	interpreterProxy->storePointerofObjectwithValue(2, charData, ((index << 1) | 1));
	_return_value = interpreterProxy->integerObjectOf(index);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(10, _return_value);
	return null;
}

EXPORT(sqInt) primitiveClear(void) {
	sqInt op;
	sqInt canvasFlags;
	sqInt fill;
	cairo_t*context;
	sqInt canvasOop;

	canvasOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	canvasFlags = interpreterProxy->fetchIntegerofObject(CanvasFlagsIndex, canvasOop);
	if (interpreterProxy->failed()) {
		fail("canvas flags not an integer");
		return null;
	}
	fill = canvasFlags & CanvasFlagFill;
	if (!(fill)) {
		cairo_set_source_rgba(context, 0.0, 0.0, 0.0, 0.0);
	}
	op = cairo_get_operator(context);
	cairo_set_operator(context, CairoOperatorSource);
	cairo_paint(context);
	cairo_set_operator(context, op);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	return null;
}

EXPORT(sqInt) primitiveClipRectangleLeftRightTopBottom(void) {
	cairo_t*context;
	sqInt canvasOop;
	double left;
	double right;
	double top;
	double bottom;

	left = interpreterProxy->stackFloatValue(3);
	right = interpreterProxy->stackFloatValue(2);
	top = interpreterProxy->stackFloatValue(1);
	bottom = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(4);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_new_path(context);
	cairo_rectangle(context, left, top, right - left, bottom - top);
	cairo_clip(context);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(4);
	return null;
}

EXPORT(sqInt) primitiveClose(void) {
	sqInt canvasOop;

	canvasOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	destroyContextFor(canvasOop);
	if (!(interpreterProxy->failed())) {
		interpreterProxy->storePointerofObjectwithValue(CanvasHandleIndex, canvasOop, interpreterProxy->nilObject());
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	return null;
}

EXPORT(sqInt) primitivePangoComposeString(void) {
	cairo_t*context;
	sqInt linesSize;
	sqInt newW;
	sqInt sqStart;
	sqInt lineCount;
	PangoRectangle ink;
	sqInt start;
	sqInt lineIndex;
	PangoAttrList*attrList;
	sqInt sqEnd;
	sqInt baseline;
	PangoLayoutLine*line;
	PangoRectangle logical;
	sqInt totalY;
	sqInt prevBaseline;
	PangoLayout*layout;
	sqInt lastLine;
	sqInt canvasOop;
	sqInt addition;
	PangoLayoutIter*lineIter;
	sqInt next;
	char *aString;
	sqInt x;
	sqInt y;
	sqInt sqAttrArray;
	sqInt w;
	sqInt h;
	sqInt withWrap;
	sqInt lines;
	sqInt _return_value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(7)));
	aString = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(7))));
	x = interpreterProxy->stackIntegerValue(6);
	y = interpreterProxy->stackIntegerValue(5);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(4), "Object"));
	sqAttrArray = interpreterProxy->stackValue(4);
	w = interpreterProxy->stackIntegerValue(3);
	h = interpreterProxy->stackIntegerValue(2);
	withWrap = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(1));
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Object"));
	lines = interpreterProxy->stackValue(0);
	;
	canvasOop = interpreterProxy->stackValue(8);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	layout = pango_cairo_create_layout(context);
	attrList = pango_attr_list_new();
	translateSqAttrsToPangoAttrsinto(sqAttrArray, attrList);
	pango_layout_set_text(layout, aString, strlen(aString));
	pango_layout_set_attributes(layout, attrList);
	pango_layout_set_width(layout, w * (PANGO_SCALE));
	if (withWrap) {
		pango_layout_set_wrap(layout, PANGO_WRAP_WORD_CHAR);
	}
	cairo_translate(context, x, y);
	pango_cairo_update_layout(context, layout);
	lineCount = pango_layout_get_line_count(layout);
	lineIter = pango_layout_get_iter(layout);
	baseline = pango_layout_iter_get_baseline(lineIter);
	prevBaseline = 0;
	cairo_translate(context, 0, PANGO_PIXELS(baseline));
	sqEnd = 0;
	totalY = 0;
	linesSize = interpreterProxy->stSizeOf(lines);
	lastLine = (((lineCount < linesSize) ? lineCount : linesSize)) - 1;
	for (lineIndex = 0; lineIndex <= lastLine; lineIndex += 1) {
		line = pango_layout_iter_get_line_readonly(lineIter);
		pango_layout_line_get_extents(line, &ink, &logical);
		sqStart = sqEnd + 1;
		start = line->start_index;

		/* self log: 'sqStart, sqEnd: %d %d' with: sqStart with: sqEnd. */

		sqEnd = (sqStart + (sqCharCountInfromto(aString, start, start + (line->length)))) - 1;
		if (((start + (line->length)) < (interpreterProxy->stSizeOf(((int) aString)))) && ((aString[start + (line->length)]) == 13)) {
			sqEnd += 1;
		}
		interpreterProxy->storeIntegerofObjectwithValue(TextLineStartIndex, interpreterProxy->fetchPointerofObject(lineIndex, lines), sqStart);
		interpreterProxy->storeIntegerofObjectwithValue(TextLineEndIndex, interpreterProxy->fetchPointerofObject(lineIndex, lines), sqEnd);
		interpreterProxy->storeIntegerofObjectwithValue(TextLineLeftIndex, interpreterProxy->fetchPointerofObject(lineIndex, lines), (PANGO_PIXELS(logical.x)) + x);
		interpreterProxy->storeIntegerofObjectwithValue(TextLineRightIndex, interpreterProxy->fetchPointerofObject(lineIndex, lines), (PANGO_PIXELS(logical.x+logical.width)) + x);
		interpreterProxy->storeIntegerofObjectwithValue(TextLineTopIndex, interpreterProxy->fetchPointerofObject(lineIndex, lines), totalY + y);
		interpreterProxy->storeIntegerofObjectwithValue(TextLineInternalSpaceIndex, interpreterProxy->fetchPointerofObject(lineIndex, lines), ((0 << 1) | 1));
		interpreterProxy->storeIntegerofObjectwithValue(TextLinePaddingWidthIndex, interpreterProxy->fetchPointerofObject(lineIndex, lines), ((0 << 1) | 1));
		next = pango_layout_iter_next_line(lineIter);
		if (next) {
			addition = (logical.height) + (pango_layout_get_spacing(layout));
		} else {
			addition = logical.height;
		}
		totalY += PANGO_PIXELS(addition);
		interpreterProxy->storeIntegerofObjectwithValue(TextLineBottomIndex, interpreterProxy->fetchPointerofObject(lineIndex, lines), totalY + y);
	}
	pango_layout_get_extents(layout, &ink, &logical);
	newW = PANGO_PIXELS(logical.width);
	pango_layout_iter_free(lineIter);
	pango_attr_list_unref(attrList);
	g_object_unref(layout);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	_return_value = interpreterProxy->integerObjectOf(newW);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(9, _return_value);
	return null;
}

EXPORT(sqInt) primitivePangoComposeString2(void) {
	cairo_t*context;
	sqInt newW;
	sqInt sqStart;
	sqInt lineCount;
	PangoRectangle ink;
	unsigned char*aString;
	unsigned char*inString;
	sqInt start;
	sqInt lineIndex;
	PangoAttrList*attrList;
	sqInt sqEnd;
	sqInt baseline;
	PangoLayoutLine*line;
	PangoRectangle logical;
	sqInt totalY;
	sqInt prevBaseline;
	sqInt arrayOop;
	sqInt retArrayOop;
	sqInt textLine;
	sqInt i;
	PangoLayout*layout;
	sqInt lastLine;
	sqInt canvasOop;
	sqInt addition;
	sqInt textLineClass;
	sqInt inStringSize;
	PangoLayoutIter*lineIter;
	sqInt next;
	sqInt inStringOop;
	sqInt x;
	sqInt y;
	sqInt sqAttrArray;
	sqInt w;
	sqInt h;
	sqInt withWrap;
	sqInt inTextLineClass;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(7), "Object"));
	inStringOop = interpreterProxy->stackValue(7);
	x = interpreterProxy->stackIntegerValue(6);
	y = interpreterProxy->stackIntegerValue(5);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(4), "Object"));
	sqAttrArray = interpreterProxy->stackValue(4);
	w = interpreterProxy->stackIntegerValue(3);
	h = interpreterProxy->stackIntegerValue(2);
	withWrap = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(1));
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Object"));
	inTextLineClass = interpreterProxy->stackValue(0);
	;
	canvasOop = interpreterProxy->stackValue(8);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	inStringSize = interpreterProxy->stSizeOf(inStringOop);
	if (inStringSize == 0) {
		primitiveFail();
		return null;
	}
	aString = alloca(inStringSize);
	inString = interpreterProxy->firstIndexableField(inStringOop);
	strncpy(aString, inString, inStringSize);
	textLineClass = inTextLineClass;
	layout = pango_cairo_create_layout(context);
	attrList = pango_attr_list_new();
	translateSqAttrsToPangoAttrsinto(sqAttrArray, attrList);
	pango_layout_set_text(layout, aString, strlen(aString));
	pango_layout_set_attributes(layout, attrList);
	pango_layout_set_width(layout, w * (PANGO_SCALE));
	if (withWrap) {
		pango_layout_set_wrap(layout, PANGO_WRAP_WORD_CHAR);
	}
	cairo_translate(context, x, y);
	pango_cairo_update_layout(context, layout);
	lineCount = pango_layout_get_line_count(layout);
	lineIter = pango_layout_get_iter(layout);
	baseline = pango_layout_iter_get_baseline(lineIter);
	prevBaseline = 0;
	cairo_translate(context, 0, PANGO_PIXELS(baseline));
	sqEnd = 0;
	totalY = 0;
	interpreterProxy->pushRemappableOop(textLineClass);
	arrayOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), lineCount);
	textLineClass = interpreterProxy->popRemappableOop();
	for (i = 0; i <= (lineCount - 1); i += 1) {
		interpreterProxy->pushRemappableOop(textLineClass);
		interpreterProxy->pushRemappableOop(arrayOop);
		textLine = interpreterProxy->instantiateClassindexableSize(textLineClass, 0);
		arrayOop = interpreterProxy->popRemappableOop();
		textLineClass = interpreterProxy->popRemappableOop();
		interpreterProxy->storePointerofObjectwithValue(i, arrayOop, textLine);
	}
	lastLine = lineCount - 1;
	for (lineIndex = 0; lineIndex <= lastLine; lineIndex += 1) {
		line = pango_layout_iter_get_line_readonly(lineIter);
		pango_layout_line_get_extents(line, &ink, &logical);
		sqStart = sqEnd + 1;
		start = line->start_index;

		/* self log: 'sqStart, sqEnd: %d %d' with: sqStart with: sqEnd. */

		sqEnd = (sqStart + (sqCharCountInfromto(aString, start, start + (line->length)))) - 1;
		if (((start + (line->length)) < (interpreterProxy->stSizeOf(((int) aString)))) && ((aString[start + (line->length)]) == 13)) {
			sqEnd += 1;
		}
		interpreterProxy->storeIntegerofObjectwithValue(TextLineStartIndex, interpreterProxy->fetchPointerofObject(lineIndex, arrayOop), sqStart);
		interpreterProxy->storeIntegerofObjectwithValue(TextLineEndIndex, interpreterProxy->fetchPointerofObject(lineIndex, arrayOop), sqEnd);
		interpreterProxy->storeIntegerofObjectwithValue(TextLineLeftIndex, interpreterProxy->fetchPointerofObject(lineIndex, arrayOop), (PANGO_PIXELS(logical.x)) + x);
		interpreterProxy->storeIntegerofObjectwithValue(TextLineRightIndex, interpreterProxy->fetchPointerofObject(lineIndex, arrayOop), (PANGO_PIXELS(logical.x+logical.width)) + x);
		interpreterProxy->storeIntegerofObjectwithValue(TextLineTopIndex, interpreterProxy->fetchPointerofObject(lineIndex, arrayOop), totalY + y);
		interpreterProxy->storeIntegerofObjectwithValue(TextLineInternalSpaceIndex, interpreterProxy->fetchPointerofObject(lineIndex, arrayOop), ((0 << 1) | 1));
		interpreterProxy->storeIntegerofObjectwithValue(TextLinePaddingWidthIndex, interpreterProxy->fetchPointerofObject(lineIndex, arrayOop), ((0 << 1) | 1));
		next = pango_layout_iter_next_line(lineIter);
		if (next) {
			addition = (logical.height) + (pango_layout_get_spacing(layout));
		} else {
			addition = logical.height;
		}
		totalY += PANGO_PIXELS(addition);
		interpreterProxy->storeIntegerofObjectwithValue(TextLineBottomIndex, interpreterProxy->fetchPointerofObject(lineIndex, arrayOop), totalY + y);
	}
	pango_layout_get_extents(layout, &ink, &logical);
	newW = PANGO_PIXELS(logical.width);
	pango_layout_iter_free(lineIter);
	pango_attr_list_unref(attrList);
	g_object_unref(layout);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	interpreterProxy->pushRemappableOop(arrayOop);
	retArrayOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 2);
	arrayOop = interpreterProxy->popRemappableOop();
	interpreterProxy->storeIntegerofObjectwithValue(0, retArrayOop, newW);
	interpreterProxy->storePointerofObjectwithValue(1, retArrayOop, arrayOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(9, retArrayOop);
	return null;
}

EXPORT(sqInt) primitiveCreateFormHandle(void) {
	sqInt formOop;
	sqInt surfaceID;
	sqInt _return_value;

	formOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	surfaceID = createSurfaceFor(formOop);
	if (surfaceID < 0) {
		interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->failed())) {
		_return_value = interpreterProxy->integerObjectOf(surfaceID);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(1, _return_value);
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	return null;
}

EXPORT(sqInt) primitiveDestroyFormHandle(void) {
	sqInt surfaceID;

	surfaceID = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(interpreterProxy->failed())) {
		destroySurface(surfaceID);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitiveDrawArcRadiusXYFromTo(void) {
	cairo_t*context;
	sqInt canvasOop;
	double radius;
	double x;
	double y;
	double angle1;
	double angle2;

	radius = interpreterProxy->stackFloatValue(4);
	x = interpreterProxy->stackFloatValue(3);
	y = interpreterProxy->stackFloatValue(2);
	angle1 = interpreterProxy->stackFloatValue(1);
	angle2 = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(5);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_new_path(context);
	if (radius > 0.0) {
		cairo_arc(context, x, y, radius, angle1, angle2);
	} else {
		cairo_arc_negative(context, x, y, -1.0 * radius, angle1, angle2);
	}
	fillOrStrokefrom(context, canvasOop);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(5);
	return null;
}

EXPORT(sqInt) primitiveDrawCurveFromXYviaXYandXYtoXY(void) {
	cairo_t*context;
	sqInt canvasOop;
	double x0;
	double y0;
	double x1;
	double y1;
	double x2;
	double y2;
	double x3;
	double y3;

	x0 = interpreterProxy->stackFloatValue(7);
	y0 = interpreterProxy->stackFloatValue(6);
	x1 = interpreterProxy->stackFloatValue(5);
	y1 = interpreterProxy->stackFloatValue(4);
	x2 = interpreterProxy->stackFloatValue(3);
	y2 = interpreterProxy->stackFloatValue(2);
	x3 = interpreterProxy->stackFloatValue(1);
	y3 = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(8);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_new_path(context);
	cairo_move_to(context, x0, y0);
	cairo_curve_to(context, x1, y1, x2, y2, x3, y3);
	fillOrStrokefrom(context, canvasOop);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(8);
	return null;
}

EXPORT(sqInt) primitiveDrawCurveFromXYviaXYtoXY(void) {
	cairo_t*context;
	sqInt canvasOop;
	double x0;
	double y0;
	double x1;
	double y1;
	double x2;
	double y2;

	x0 = interpreterProxy->stackFloatValue(5);
	y0 = interpreterProxy->stackFloatValue(4);
	x1 = interpreterProxy->stackFloatValue(3);
	y1 = interpreterProxy->stackFloatValue(2);
	x2 = interpreterProxy->stackFloatValue(1);
	y2 = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(6);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_new_path(context);
	cairo_move_to(context, x0, y0);
	cairo_curve_to(context, ((2.0 * x1) + x0) / 3.0, ((2.0 * y1) + y0) / 3.0, ((2.0 * x1) + x2) / 3.0, ((2.0 * y1) + y2) / 3.0, x2, y2);
	fillOrStrokefrom(context, canvasOop);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(6);
	return null;
}

EXPORT(sqInt) primitiveDrawGeneralBezierShape(void) {
	cairo_t*context;
	sqInt shapeCount;
	sqInt segmentCount;
	short*seg;
	sqInt j;
	sqInt yVia;
	sqInt i;
	sqInt xFrom;
	sqInt contourOop;
	sqInt canvasOop;
	sqInt xTo;
	sqInt yTo;
	sqInt xVia;
	sqInt yFrom;
	sqInt shapeOop;

	shapeOop = interpreterProxy->stackValue(0);
	canvasOop = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	shapeCount = interpreterProxy->slotSizeOf(shapeOop);
	cairo_new_path(context);
	for (i = 0; i <= (shapeCount - 1); i += 1) {
		contourOop = interpreterProxy->fetchPointerofObject(i, shapeOop);
		if (!(interpreterProxy->isMemberOf(contourOop, "ShortPointArray"))) {
			failwith("bezier contour %i is no ShortPointArray", i + 1);
			return null;
		}
		segmentCount = (interpreterProxy->slotSizeOf(contourOop)) / 3;
		seg = interpreterProxy->arrayValueOf(contourOop);
		for (j = 0; j <= (segmentCount - 1); j += 1) {
			xFrom = seg[0];
			yFrom = seg[1];
			xVia = seg[2];
			yVia = seg[3];
			xTo = seg[4];
			yTo = seg[5];
			if (j == 0) {
				cairo_move_to(context, xFrom, yFrom);
			}
			if ((xFrom == xVia) && (yFrom == yVia)) {
				cairo_line_to(context, xTo, yTo);
			} else {
				cairo_curve_to(context, (xFrom + (2.0 * xVia)) / 3.0, (yFrom + (2.0 * yVia)) / 3.0, ((2.0 * xVia) + xTo) / 3.0, ((2.0 * yVia) + yTo) / 3.0, xTo, yTo);
			}
			seg += 6;
		}
		cairo_close_path(context);
	}
	fillOrStrokefrom(context, canvasOop);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitiveDrawImageSrcLRTBDestLRTB(void) {
	cairo_surface_t*srcSurface;
	cairo_t*context;
	sqInt canvasOop;
	sqInt formOop;
	double dstL;
	double dstR;
	double dstT;
	double dstB;
	double srcL;
	double srcR;
	double srcT;
	double srcB;

	formOop = interpreterProxy->stackValue(8);
	dstL = interpreterProxy->stackFloatValue(7);
	dstR = interpreterProxy->stackFloatValue(6);
	dstT = interpreterProxy->stackFloatValue(5);
	dstB = interpreterProxy->stackFloatValue(4);
	srcL = interpreterProxy->stackFloatValue(3);
	srcR = interpreterProxy->stackFloatValue(2);
	srcT = interpreterProxy->stackFloatValue(1);
	srcB = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(9);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	srcSurface = surfaceFrom(formOop);
	if (!((srcSurface != null) && ((cairo_surface_status(srcSurface)) == 0))) {
		fail("source surface invalid");
		return null;
	}
	if ((srcR != srcL) && (srcT != srcB)) {
		cairo_save(context);
		cairo_translate(context, dstL, dstT);
		cairo_scale(context, (dstR - dstL) / (srcR - srcL), (dstB - dstT) / (srcB - srcT));
		cairo_new_path(context);
		cairo_rectangle(context, 0.0, 0.0, srcR - srcL, srcB - srcT);
		cairo_set_source_surface(context, srcSurface, 0.0 - srcL, 0.0 - srcT);
		cairo_fill(context);
		cairo_restore(context);
	}
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(9);
	return null;
}

EXPORT(sqInt) primitiveDrawLineFromXYtoXY(void) {
	cairo_t*context;
	sqInt canvasOop;
	double fromX;
	double fromY;
	double toX;
	double toY;

	fromX = interpreterProxy->stackFloatValue(3);
	fromY = interpreterProxy->stackFloatValue(2);
	toX = interpreterProxy->stackFloatValue(1);
	toY = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(4);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_new_path(context);
	cairo_move_to(context, fromX, fromY);
	cairo_line_to(context, toX, toY);
	strokefrom(context, canvasOop);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(4);
	return null;
}

EXPORT(sqInt) primitiveDrawOvalLeftRightTopBottom(void) {
	cairo_t*context;
	sqInt canvasOop;
	double left;
	double right;
	double top;
	double bottom;

	left = interpreterProxy->stackFloatValue(3);
	right = interpreterProxy->stackFloatValue(2);
	top = interpreterProxy->stackFloatValue(1);
	bottom = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(4);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((right != left) && (top != bottom)) {
		cairo_save(context);
		cairo_new_path(context);
		cairo_translate(context, (left + right) / 2.0, (top + bottom) / 2.0);
		cairo_scale(context, (right - left) / 2.0, (bottom - top) / 2.0);
		cairo_arc(context, 0.0, 0.0, 1.0, 0.0, degrees(360.0));
		cairo_restore(context);
		fillOrStrokefrom(context, canvasOop);
	}
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(4);
	return null;
}

EXPORT(sqInt) primitiveDrawPolygon(void) {
	cairo_t*context;
	sqInt canvasOop;
	sqInt pointsOop;

	pointsOop = interpreterProxy->stackValue(0);
	canvasOop = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_new_path(context);
	polyPathfrom(context, pointsOop);
	cairo_close_path(context);
	fillOrStrokefrom(context, canvasOop);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitiveDrawPolyline(void) {
	cairo_t*context;
	sqInt canvasOop;
	sqInt pointsOop;

	pointsOop = interpreterProxy->stackValue(0);
	canvasOop = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_new_path(context);
	polyPathfrom(context, pointsOop);
	fillOrStrokefrom(context, canvasOop);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitiveDrawRectangleLeftRightTopBottom(void) {
	cairo_t*context;
	sqInt canvasOop;
	double left;
	double right;
	double top;
	double bottom;

	left = interpreterProxy->stackFloatValue(3);
	right = interpreterProxy->stackFloatValue(2);
	top = interpreterProxy->stackFloatValue(1);
	bottom = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(4);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_new_path(context);
	cairo_rectangle(context, left, top, right - left, bottom - top);
	fillOrStrokefrom(context, canvasOop);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(4);
	return null;
}


/*		x1	x2		x3	x4
	y1	+	/	-	\	+
	y2	/	.		.	\
		|				|
	y3	\	.		.	/
	y4	+	\	-	/	+ */

EXPORT(sqInt) primitiveDrawRoundRectLeftRightTopBottomRadiusCorner(void) {
	cairo_t*context;
	double y3;
	double y2;
	double x3;
	double x2;
	sqInt canvasOop;
	double ry;
	double rx;
	double r;
	double x1;
	double x4;
	double y1;
	double y4;
	double radius;
	sqInt cornerFlags;

	x1 = interpreterProxy->stackFloatValue(5);
	x4 = interpreterProxy->stackFloatValue(4);
	y1 = interpreterProxy->stackFloatValue(3);
	y4 = interpreterProxy->stackFloatValue(2);
	radius = interpreterProxy->stackFloatValue(1);
	cornerFlags = interpreterProxy->stackIntegerValue(0);
	canvasOop = interpreterProxy->stackValue(6);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	rx = (x4 - x1) / 2.0;
	ry = (y4 - y1) / 2.0;
	r = (((((radius < rx) ? radius : rx)) < ry) ? (((radius < rx) ? radius : rx)) : ry);
	x2 = x1 + r;
	x3 = x4 - r;
	y2 = y1 + r;
	y3 = y4 - r;
	cairo_new_path(context);
	if (cornerFlags & 1) {
		cairo_arc(context, x2, y2, r, degrees(180), degrees(270));
	} else {
		cairo_move_to(context, x1, y1);
	}
	if (cornerFlags & 8) {
		cairo_arc(context, x3, y2, r, degrees(270), degrees(360));
	} else {
		cairo_line_to(context, x4, y1);
	}
	if (cornerFlags & 4) {
		cairo_arc(context, x3, y3, r, degrees(0), degrees(90));
	} else {
		cairo_line_to(context, x4, y4);
	}
	if (cornerFlags & 2) {
		cairo_arc(context, x2, y3, r, degrees(90), degrees(180));
	} else {
		cairo_line_to(context, x1, y4);
	}
	cairo_close_path(context);
	fillOrStrokefrom(context, canvasOop);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(6);
	return null;
}


/*	draw a string including its outline if selected */

EXPORT(sqInt) primitiveDrawZeroTerminatedUtf8StringXY(void) {
	cairo_t*context;
	sqInt canvasOop;
	char *aString;
	double x;
	double y;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(2)));
	aString = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(2))));
	x = interpreterProxy->stackFloatValue(1);
	y = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(3);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_move_to(context, x, y);
	cairo_text_path(context, aString);
	fillOrStrokefrom(context, canvasOop);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(3);
	return null;
}

EXPORT(sqInt) primitiveFillBitmapOriginXYdirectionXYnormalXYRepeatImage(void) {
	cairo_pattern_t*pattern;
	cairo_t*context;
	sqInt canvasOop;
	cairo_matrix_t*m;
	cairo_matrix_t mdata;
	cairo_surface_t*surface;
	double ox;
	double oy;
	double dx;
	double dy;
	double nx;
	double ny;
	sqInt aBoolean;
	sqInt formOop;

	ox = interpreterProxy->stackFloatValue(7);
	oy = interpreterProxy->stackFloatValue(6);
	dx = interpreterProxy->stackFloatValue(5);
	dy = interpreterProxy->stackFloatValue(4);
	nx = interpreterProxy->stackFloatValue(3);
	ny = interpreterProxy->stackFloatValue(2);
	aBoolean = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(1));
	formOop = interpreterProxy->stackValue(0);
	m = &mdata;
	canvasOop = interpreterProxy->stackValue(8);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	surface = surfaceFrom(formOop);
	if (!((surface != null) && ((cairo_surface_status(surface)) == 0))) {
		fail("surface invalid");
		return null;
	}
	pattern = cairo_pattern_create_for_surface(surface);
	cairo_matrix_init(m, dx, dy, nx, ny, ox, oy);
	cairo_matrix_invert(m);
	cairo_pattern_set_matrix(pattern, m);
	if (aBoolean) {
		cairo_pattern_set_extend(pattern, CairoExtendRepeat);
	}
	if (cairo_pattern_status(pattern)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_pattern_status(pattern)));
		return null;
	}
	cairo_set_source(context, pattern);
	cairo_pattern_destroy(pattern);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(8);
	return null;
}

EXPORT(sqInt) primitiveFillColorAlpha(void) {
	cairo_t*context;
	sqInt canvasOop;
	sqInt rgb;
	sqInt alpha;

	rgb = interpreterProxy->stackIntegerValue(1);
	alpha = interpreterProxy->stackIntegerValue(0);
	canvasOop = interpreterProxy->stackValue(2);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	setSourcergbalpha(context, rgb, alpha);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(2);
	return null;
}

EXPORT(sqInt) primitiveFillLinearOriginXYdirectionXYcolorStops(void) {
	cairo_pattern_t*pattern;
	int*colorStops;
	sqInt i;
	sqInt colorStopsCount;
	cairo_t*context;
	sqInt canvasOop;
	double ox;
	double oy;
	double dx;
	double dy;
	sqInt colorStopsOop;

	ox = interpreterProxy->stackFloatValue(4);
	oy = interpreterProxy->stackFloatValue(3);
	dx = interpreterProxy->stackFloatValue(2);
	dy = interpreterProxy->stackFloatValue(1);
	colorStopsOop = interpreterProxy->stackValue(0);
	canvasOop = interpreterProxy->stackValue(5);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	colorStops = interpreterProxy->arrayValueOf(colorStopsOop);
	colorStopsCount = interpreterProxy->slotSizeOf(colorStopsOop);
	if (interpreterProxy->failed()) {
		fail("bad colorStops array");
		return null;
	}
	pattern = cairo_pattern_create_linear(ox, oy, ox + dx, oy + dy);
	if (cairo_pattern_status(pattern)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_pattern_status(pattern)));
		return null;
	}
	for (i = 0; i <= (colorStopsCount - 1); i += 3) {
		addColorStopTooffsetrgbalpha(pattern, colorStops[i], colorStops[i + 1], colorStops[i + 2]);
	}
	cairo_set_source(context, pattern);
	cairo_pattern_destroy(pattern);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(5);
	return null;
}

EXPORT(sqInt) primitiveFillRadialOriginXYdirectionXYnormalXYcolorStops(void) {
	int*colorStops;
	cairo_t*context;
	sqInt colorStopsCount;
	cairo_matrix_t*m;
	cairo_matrix_t mdata;
	sqInt i;
	sqInt canvasOop;
	cairo_pattern_t*pattern;
	double ox;
	double oy;
	double dx;
	double dy;
	double nx;
	double ny;
	sqInt colorStopsOop;

	ox = interpreterProxy->stackFloatValue(6);
	oy = interpreterProxy->stackFloatValue(5);
	dx = interpreterProxy->stackFloatValue(4);
	dy = interpreterProxy->stackFloatValue(3);
	nx = interpreterProxy->stackFloatValue(2);
	ny = interpreterProxy->stackFloatValue(1);
	colorStopsOop = interpreterProxy->stackValue(0);
	m = &mdata;
	canvasOop = interpreterProxy->stackValue(7);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	colorStops = interpreterProxy->arrayValueOf(colorStopsOop);
	colorStopsCount = interpreterProxy->slotSizeOf(colorStopsOop);
	if (interpreterProxy->failed()) {
		fail("bad colorStops array");
		return null;
	}
	pattern = cairo_pattern_create_radial(0.0, 0.0, 0.0, 0.0, 0.0, 1.0);
	cairo_matrix_init(m, dx, dy, nx, ny, ox, oy);
	cairo_matrix_invert(m);
	cairo_pattern_set_matrix(pattern, m);
	if (cairo_pattern_status(pattern)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_pattern_status(pattern)));
		return null;
	}
	for (i = 0; i <= (colorStopsCount - 1); i += 3) {
		addColorStopTooffsetrgbalpha(pattern, colorStops[i], colorStops[i + 1], colorStops[i + 2]);
	}
	cairo_set_source(context, pattern);
	cairo_pattern_destroy(pattern);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(7);
	return null;
}

EXPORT(sqInt) primitiveFontFace(void) {
	cairo_font_face_t*crFace;
	FT_Face ftFace;
	cairo_t*context;
	sqInt canvasOop;
	char *faceHandle;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	faceHandle = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	canvasOop = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	ftFace = *(void**)faceHandle;
	crFace = cairo_ft_font_face_create_for_ft_face(ftFace, FT_LOAD_NO_HINTING);
	cairo_set_font_face(context, crFace);
	cairo_font_face_destroy(crFace);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitiveFontSize(void) {
	cairo_t*context;
	sqInt canvasOop;
	double size;

	size = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_set_font_size(context, size);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitiveGetLineWidth(void) {
	double width;
	cairo_t*context;
	sqInt canvasOop;
	sqInt _return_value;

	canvasOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	width = cairo_get_line_width(context);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	_return_value = interpreterProxy->floatObjectOf(width);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}

EXPORT(sqInt) primitivePangoFontDescriptionIndex(void) {
	sqInt familyNameSize;
	sqInt newInd;
	PangoFontDescription *desc;
	sqInt i;
	sqInt ind;
	char cFamilyName[128];
	sqInt size;
	sqInt pangoStyle;
	char *familyName;
	sqInt isAbsolute;
	sqInt familyNameOop;
	sqInt ptSize;
	sqInt _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Object"));
	familyNameOop = interpreterProxy->stackValue(1);
	ptSize = interpreterProxy->stackIntegerValue(0);
	;
	if (interpreterProxy->failed()) {
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	familyNameSize = interpreterProxy->stSizeOf(familyNameOop);
	if (familyNameSize > 127) {
		return null;
	}
	if ((ptSize < 0) || (ptSize > 1000000)) {
		_return_value = ((-1 << 1) | 1);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, _return_value);
		return null;
	}
	familyName = interpreterProxy->firstIndexableField(familyNameOop);
	for (i = 0; i <= (familyNameSize - 1); i += 1) {
		cFamilyName[i] = (familyName[i]);
	}
	cFamilyName[familyNameSize] = 0;
	newInd = -1;
	ind = 0;
	desc = null;
	while (newInd == -1) {
		desc = fontDescriptions[ind];
		if (desc == null) {
			newInd = ind;
		} else {
			isAbsolute = pango_font_description_get_size_is_absolute(desc);
			size = pango_font_description_get_size(desc);
			if (isAbsolute) {
				size = size;
			}
			if (((strcmp(cFamilyName, pango_font_description_get_family(desc))) == 0) && (size == (ptSize * (PANGO_SCALE)))) {
				newInd = ind;
			}
		}
		ind += 1;
		if (ind > 255) {
			newInd = 256;
		}
	}
	if (newInd == 256) {
		_return_value = ((-1 << 1) | 1);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, _return_value);
		return null;
	}
	if (desc == null) {
		null;
	} else {
		_return_value = ((newInd << 1) | 1);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, _return_value);
		return null;
	}
	desc = pango_font_description_new();
	pango_font_description_set_family(desc, cFamilyName);
	pangoStyle = PANGO_STYLE_NORMAL;
	pango_font_description_set_style(desc, pangoStyle);
	pango_font_description_set_size(desc, ptSize * (PANGO_SCALE));
	fontDescriptions[newInd] = desc;
	_return_value = ((newInd << 1) | 1);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(sqInt) primitiveGetTransform(void) {
	cairo_t*context;
	sqInt canvasOop;
	cairo_matrix_t m;
	float *aTransform;

	aTransform = ((float *) (interpreterProxy->arrayValueOf(interpreterProxy->stackValue(0))));
	canvasOop = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_get_matrix(context, &m);
	aTransform[0] = (m.xx);
	aTransform[1] = (m.xy);
	aTransform[2] = (m.x0);
	aTransform[3] = (m.yx);
	aTransform[4] = (m.yy);
	aTransform[5] = (m.y0);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitivePangoIndexAtPoint(void) {
	sqInt index;
	cairo_t*context;
	sqInt origin;
	unsigned char*aString;
	sqInt trailing;
	sqInt aStringOop;
	sqInt lineIndex;
	sqInt inside;
	PangoAttrList*attrList;
	PangoLayoutLine*line;
	sqInt xPos;
	PangoLayout*layout;
	sqInt canvasOop;
	sqInt corner;
	sqInt charData;
	PangoRectangle pos;
	sqInt inStringOop;
	sqInt x;
	sqInt y;
	sqInt sqAttrArray;
	sqInt w;
	sqInt h;
	sqInt withWrap;
	sqInt cData;
	sqInt _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(7), "Object"));
	inStringOop = interpreterProxy->stackValue(7);
	x = interpreterProxy->stackIntegerValue(6);
	y = interpreterProxy->stackIntegerValue(5);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(4), "Object"));
	sqAttrArray = interpreterProxy->stackValue(4);
	w = interpreterProxy->stackIntegerValue(3);
	h = interpreterProxy->stackIntegerValue(2);
	withWrap = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(1));
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Object"));
	cData = interpreterProxy->stackValue(0);
	;
	canvasOop = interpreterProxy->stackValue(8);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	aStringOop = inStringOop;
	aString = interpreterProxy->firstIndexableField(aStringOop);
	layout = pango_cairo_create_layout(context);
	attrList = pango_attr_list_new();
	translateSqAttrsToPangoAttrsinto(sqAttrArray, attrList);
	pango_layout_set_text(layout, aString, strlen(aString));
	pango_layout_set_attributes(layout, attrList);
	pango_layout_set_width(layout, w * (PANGO_SCALE));
	if (withWrap) {
		pango_layout_set_wrap(layout, PANGO_WRAP_WORD_CHAR);
	}
	cairo_translate(context, x, y);
	pango_cairo_update_layout(context, layout);
	inside = pango_layout_xy_to_index(layout, x * (PANGO_SCALE), y * (PANGO_SCALE), &index, &trailing);
	pango_layout_index_to_pos(layout, index, &pos);
	line = null;
	if (!(inside)) {
		pango_layout_index_to_line_x(layout, index, trailing, &lineIndex, &xPos);

		/* self log: 'lineIndex %x' with: line. */

		line = pango_layout_get_line_readonly(layout, ((lineIndex < 0) ? 0 : lineIndex));
		if (line == null) {
			index = strlen(aString);
		} else {
			pango_layout_line_ref(line);

			/* self log: 'line->length %d' with: (self cCode: 'line->length'). */

			index = line->start_index;
			index += line->length;
			if (trailing > 0) {
				trailing = 1;
			}
		}
	}
	pango_attr_list_unref(attrList);
	g_object_unref(layout);
	if (!(line == null)) {
		pango_layout_line_unref(line);
	}
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	interpreterProxy->pushRemappableOop(aStringOop);
	interpreterProxy->pushRemappableOop(cData);
	origin = interpreterProxy->makePointwithxValueyValue(PANGO_PIXELS(pos.x), PANGO_PIXELS(pos.y));
	interpreterProxy->pushRemappableOop(origin);
	corner = interpreterProxy->makePointwithxValueyValue(PANGO_PIXELS(pos.x+pos.width), PANGO_PIXELS(pos.y+pos.height));
	origin = interpreterProxy->popRemappableOop();
	charData = interpreterProxy->popRemappableOop();
	aStringOop = interpreterProxy->popRemappableOop();
	aString = interpreterProxy->firstIndexableField(aStringOop);
	interpreterProxy->storePointerofObjectwithValue(0, charData, origin);
	interpreterProxy->storePointerofObjectwithValue(1, charData, corner);
	index = sqCharCountInfromto(aString, 0, (((index + trailing) < (1 + (strlen(aString)))) ? (index + trailing) : (1 + (strlen(aString)))));
	if (inside || (xPos <= 0)) {
		index += 1;
	}
	interpreterProxy->storePointerofObjectwithValue(2, charData, ((index << 1) | 1));
	_return_value = interpreterProxy->integerObjectOf(index);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(9, _return_value);
	return null;
}

EXPORT(sqInt) primitiveLanguageAttributes(void) {
	sqInt arraySize;
	sqInt array4Oop;
	sqInt lOop;
	sqInt currentStart;
	sqInt ws;
	sqInt stringOop;
	int *array;
	int *array4;
	unsigned int *string;
	sqInt currentTag;
	sqInt leadingChar;
	sqInt arrayOop;
	sqInt i;
	sqInt arrayIndex;
	sqInt stringSize;
	sqInt currentEnd;
	sqInt oStringOop;
	sqInt oLOop;
	sqInt oArrayOop;
	sqInt _return_value;
	sqInt v;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(2), "Object"));
	oStringOop = interpreterProxy->stackValue(2);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Object"));
	oLOop = interpreterProxy->stackValue(1);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Object"));
	oArrayOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	lOop = oLOop;
	arrayOop = oArrayOop;
	stringOop = oStringOop;
	if (interpreterProxy->isBytes(stringOop)) {
		_return_value = interpreterProxy->integerObjectOf(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(4, _return_value);
		return null;
	}
	if (!(interpreterProxy->isWords(stringOop))) {
		primitiveFail();
		return null;
	}
	arraySize = interpreterProxy->stSizeOf(arrayOop);
	if (arraySize <= 0) {
		primitiveFail();
		return null;
	}
	stringSize = interpreterProxy->stSizeOf(stringOop);
	if (stringSize == 0) {
		_return_value = interpreterProxy->integerObjectOf(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(4, _return_value);
		return null;
	}
	string = interpreterProxy->firstIndexableField(stringOop);
	array = interpreterProxy->firstIndexableField(arrayOop);
	ws = string[0];
	currentTag = ((usqInt) (ws & 1069547520) >> 22);
	leadingChar = -1;
	currentStart = 0;
	/* begin utf8CountFor: */
	v = ws & 2097151;
	if ((0 <= v) && (v <= 127)) {
		currentEnd = 1;
		goto l1;
	}
	if ((128 <= v) && (v <= 2047)) {
		currentEnd = 2;
		goto l1;
	}
	if ((2048 <= v) && (v <= 55295)) {
		currentEnd = 3;
		goto l1;
	}
	if ((57344 <= v) && (v <= 65535)) {
		currentEnd = 3;
		goto l1;
	}
	if ((65536 <= v) && (v <= 1114111)) {
		currentEnd = 4;
		goto l1;
	}
	currentEnd = 0;
l1:	/* end utf8CountFor: */;
	arrayIndex = 0;
	for (i = 1; i <= (stringSize - 1); i += 1) {
		ws = string[i];
		leadingChar = ((usqInt) (ws & 1069547520) >> 22);
		if (leadingChar != currentTag) {
			interpreterProxy->pushRemappableOop(stringOop);
			interpreterProxy->pushRemappableOop(arrayOop);
			interpreterProxy->pushRemappableOop(lOop);
			array4Oop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 4);
			lOop = interpreterProxy->popRemappableOop();
			arrayOop = interpreterProxy->popRemappableOop();
			stringOop = interpreterProxy->popRemappableOop();
			array = interpreterProxy->firstIndexableField(arrayOop);
			string = interpreterProxy->firstIndexableField(stringOop);
			array4 = interpreterProxy->firstIndexableField(array4Oop);
			array4[0] = lOop;
			array4[1] = (((currentStart << 1) | 1));
			array4[2] = (((currentEnd << 1) | 1));
			array4[3] = (((currentTag << 1) | 1));
			array[arrayIndex] = array4Oop;
			arrayIndex += 1;
			if (arrayIndex >= arraySize) {
				primitiveFail();
				return null;
			}
			currentTag = leadingChar;
			currentStart = currentEnd;
		}
		currentEnd += utf8CountFor(ws);
	}
	interpreterProxy->pushRemappableOop(stringOop);
	interpreterProxy->pushRemappableOop(arrayOop);
	interpreterProxy->pushRemappableOop(lOop);
	array4Oop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 4);
	lOop = interpreterProxy->popRemappableOop();
	arrayOop = interpreterProxy->popRemappableOop();
	stringOop = interpreterProxy->popRemappableOop();
	interpreterProxy->storePointerofObjectwithValue(0, array4Oop, lOop);
	interpreterProxy->storeIntegerofObjectwithValue(1, array4Oop, currentStart);
	interpreterProxy->storeIntegerofObjectwithValue(2, array4Oop, currentEnd);
	interpreterProxy->storeIntegerofObjectwithValue(3, array4Oop, currentTag);
	interpreterProxy->storePointerofObjectwithValue(arrayIndex, arrayOop, array4Oop);
	arrayIndex += 1;
	_return_value = interpreterProxy->integerObjectOf(arrayIndex);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}

EXPORT(sqInt) primitiveOpen(void) {
	sqInt handleOop;
	sqInt contextIndex;
	sqInt canvasOop;

	canvasOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	contextIndex = createContextFor(canvasOop);
	if (!(interpreterProxy->failed())) {
		handleOop = interpreterProxy->integerObjectOf(contextIndex);
		interpreterProxy->storePointerofObjectwithValue(CanvasHandleIndex, canvasOop, handleOop);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	return null;
}

EXPORT(sqInt) primitivePangoIsAvailable(void) {
	PangoLayout*layout;
	cairo_t*context;
	sqInt canvasOop;
	sqInt _return_value;

	canvasOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	layout = pango_cairo_create_layout(context);
	if (layout == null) {
		_return_value = interpreterProxy->integerObjectOf(2);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(1, _return_value);
		return null;
	}
	g_object_unref(layout);
	_return_value = (1? interpreterProxy->trueObject(): interpreterProxy->falseObject());
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}

EXPORT(sqInt) primitivePluginVersion(void) {
	sqInt _return_value;

	_return_value = interpreterProxy->integerObjectOf(PluginVersion);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}

EXPORT(sqInt) primitiveRestoreState(void) {
	cairo_t*context;
	sqInt canvasOop;

	canvasOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_restore(context);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	return null;
}

EXPORT(sqInt) primitiveRotateBy(void) {
	cairo_t*context;
	sqInt canvasOop;
	double angle;

	angle = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_rotate(context, angle);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitiveSaveState(void) {
	cairo_t*context;
	sqInt canvasOop;

	canvasOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_save(context);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	return null;
}

EXPORT(sqInt) primitiveScaleBy(void) {
	cairo_t*context;
	sqInt canvasOop;
	double x;
	double y;

	x = interpreterProxy->stackFloatValue(1);
	y = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(2);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_scale(context, x, y);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(2);
	return null;
}

EXPORT(sqInt) primitiveSetLineWidth(void) {
	cairo_t*context;
	sqInt canvasOop;
	double width;

	width = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_set_line_width(context, width);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitiveSetTransform(void) {
	cairo_t*context;
	sqInt canvasOop;
	cairo_matrix_t m;
	float *aTransform;

	aTransform = ((float *) (interpreterProxy->arrayValueOf(interpreterProxy->stackValue(0))));
	canvasOop = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_matrix_init(&m, aTransform[0], aTransform[3], aTransform[1], aTransform[4], aTransform[2], aTransform[5]);
	cairo_set_matrix(context, &m);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitivePangoShowString(void) {
	cairo_t*context;
	sqInt newW;
	sqInt lineCount;
	PangoRectangle ink;
	unsigned int cursorColor;
	PangoAttrList*attrList;
	PangoLayoutLine*line;
	PangoRectangle logical;
	sqInt prevBaseline;
	PangoLayout*layout;
	PangoRectangle startRect;
	sqInt canvasOop;
	PangoLayoutIter*lineIter;
	sqInt indexToX;
	char *aString;
	sqInt x;
	sqInt y;
	sqInt sqAttrArray;
	sqInt w;
	sqInt h;
	sqInt withWrap;
	sqInt selStart;
	sqInt selEnd;
	sqInt cPixel;
	sqInt _return_value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(9)));
	aString = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(9))));
	x = interpreterProxy->stackIntegerValue(8);
	y = interpreterProxy->stackIntegerValue(7);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(6), "Object"));
	sqAttrArray = interpreterProxy->stackValue(6);
	w = interpreterProxy->stackIntegerValue(5);
	h = interpreterProxy->stackIntegerValue(4);
	withWrap = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(3));
	selStart = interpreterProxy->stackIntegerValue(2);
	selEnd = interpreterProxy->stackIntegerValue(1);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Object"));
	cPixel = interpreterProxy->stackValue(0);
	;
	canvasOop = interpreterProxy->stackValue(10);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	cursorColor = interpreterProxy->positive32BitValueOf(cPixel);
	if (interpreterProxy->failed()) {
		return null;
	}
	layout = pango_cairo_create_layout(context);
	attrList = pango_attr_list_new();
	translateSqAttrsToPangoAttrsinto(sqAttrArray, attrList);
	if (!(selStart == selEnd)) {
		if ((selStart >= 0) && (selEnd >= 0)) {
			addSelectionFromtopixelinto(selStart, selEnd, cursorColor, attrList);
		}
	}
	pango_layout_set_text(layout, aString, strlen(aString));
	pango_layout_set_attributes(layout, attrList);
	pango_layout_set_width(layout, w * (PANGO_SCALE));
	if (withWrap) {
		pango_layout_set_wrap(layout, PANGO_WRAP_WORD_CHAR);
	}
	cairo_translate(context, x, y);
	pango_cairo_update_layout(context, layout);

	/* 	lineIter := self pangoLayoutGetIter: layout.
	baseline := self pangoLayoutIterGetBaseline: lineIter.
	prevBaseline := 0.
 */

	lineCount = pango_layout_get_line_count(layout);
	if (1) {
		pango_cairo_show_layout(context, layout);
	} else {
		null;
	}
	if (selStart == selEnd) {
		if ((selStart >= 0) && (selEnd >= 0)) {
			pango_layout_index_to_pos(layout, selStart, &startRect);
			addSelectionAtpixelwith(&startRect, cursorColor, context);
		}
	}
	pango_layout_get_extents(layout, &ink, &logical);

	/* self pangoLayoutIterFree: lineIter. */

	newW = PANGO_PIXELS(logical.width);
	pango_attr_list_unref(attrList);
	g_object_unref(layout);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	_return_value = interpreterProxy->integerObjectOf(newW);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(11, _return_value);
	return null;
}


/*	Show a string - ignores outline (use drawString primitive for outlines) */

EXPORT(sqInt) primitiveShowZeroTerminatedUtf8StringXY(void) {
	cairo_t*context;
	sqInt canvasOop;
	char *aString;
	double x;
	double y;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(2)));
	aString = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(2))));
	x = interpreterProxy->stackFloatValue(1);
	y = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(3);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_move_to(context, x, y);
	cairo_show_text(context, aString);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(3);
	return null;
}

EXPORT(sqInt) primitiveStencilImageSrcLRTBDestLRTB(void) {
	cairo_surface_t*srcSurface;
	cairo_t*context;
	sqInt canvasOop;
	sqInt formOop;
	double dstL;
	double dstR;
	double dstT;
	double dstB;
	double srcL;
	double srcR;
	double srcT;
	double srcB;

	formOop = interpreterProxy->stackValue(8);
	dstL = interpreterProxy->stackFloatValue(7);
	dstR = interpreterProxy->stackFloatValue(6);
	dstT = interpreterProxy->stackFloatValue(5);
	dstB = interpreterProxy->stackFloatValue(4);
	srcL = interpreterProxy->stackFloatValue(3);
	srcR = interpreterProxy->stackFloatValue(2);
	srcT = interpreterProxy->stackFloatValue(1);
	srcB = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(9);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	srcSurface = surfaceFrom(formOop);
	if (!((srcSurface != null) && ((cairo_surface_status(srcSurface)) == 0))) {
		fail("source surface invalid");
		return null;
	}
	if ((srcR != srcL) && (srcT != srcB)) {
		cairo_save(context);
		cairo_translate(context, dstL, dstT);
		cairo_scale(context, (dstR - dstL) / (srcR - srcL), (dstB - dstT) / (srcB - srcT));
		cairo_new_path(context);
		cairo_rectangle(context, 0.0, 0.0, srcR - srcL, srcB - srcT);
		cairo_clip(context);
		cairo_mask_surface(context, srcSurface, 0.0 - srcL, 0.0 - srcT);
		cairo_restore(context);
	}
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(9);
	return null;
}

EXPORT(sqInt) primitiveTransformBy(void) {
	cairo_t*context;
	sqInt canvasOop;
	cairo_matrix_t m;
	float *aTransform;

	aTransform = ((float *) (interpreterProxy->arrayValueOf(interpreterProxy->stackValue(0))));
	canvasOop = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_matrix_init(&m, aTransform[0], aTransform[3], aTransform[1], aTransform[4], aTransform[2], aTransform[5]);
	cairo_transform(context, &m);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitiveTranslateBy(void) {
	cairo_t*context;
	sqInt canvasOop;
	double x;
	double y;

	x = interpreterProxy->stackFloatValue(1);
	y = interpreterProxy->stackFloatValue(0);
	canvasOop = interpreterProxy->stackValue(2);
	if (interpreterProxy->failed()) {
		return null;
	}
	context = contextFrom(canvasOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	cairo_translate(context, x, y);
	if (cairo_status(context)) {
		failwith("cairo error: %s", cairo_status_to_string(cairo_status(context)));
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(2);
	return null;
}

EXPORT(sqInt) primitiveUTF8StringWith2Indexes(void) {
	sqInt utf8StringOop;
	sqInt size;
	sqInt bytes;
	sqInt mult;
	unsigned char *byteString;
	sqInt stringOop;
	sqInt utf8Index;
	sqInt arrayOop;
	sqInt i;
	sqInt newIndex2;
	sqInt realutf8StringOop;
	sqInt newIndex1;
	unsigned int *wideString;
	unsigned char *realutf8String;
	sqInt val;
	unsigned int c;
	unsigned char *utf8String;
	sqInt oStringOop;
	sqInt sqIndex1;
	sqInt sqIndex2;
	sqInt oArrayOop;
	sqInt nullFlag;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(4), "Object"));
	oStringOop = interpreterProxy->stackValue(4);
	sqIndex1 = interpreterProxy->stackIntegerValue(3);
	sqIndex2 = interpreterProxy->stackIntegerValue(2);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Object"));
	oArrayOop = interpreterProxy->stackValue(1);
	nullFlag = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	if (interpreterProxy->failed()) {
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	arrayOop = oArrayOop;
	stringOop = oStringOop;
	if (interpreterProxy->isPointers(stringOop)) {
		primitiveFail();
		return null;
	}
	bytes = interpreterProxy->isBytes(stringOop);
	size = interpreterProxy->stSizeOf(stringOop);
	if (bytes) {
		mult = 2;
	} else {
		mult = 4;
	}
	interpreterProxy->pushRemappableOop(stringOop);
	interpreterProxy->pushRemappableOop(arrayOop);
	utf8StringOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), (size * mult) + 1);
	arrayOop = interpreterProxy->popRemappableOop();
	stringOop = interpreterProxy->popRemappableOop();
	if (bytes) {
		byteString = interpreterProxy->firstIndexableField(stringOop);
	} else {
		wideString = interpreterProxy->firstIndexableField(stringOop);
	}
	utf8Index = 0;
	newIndex1 = -1;
	newIndex2 = -1;
	utf8String = interpreterProxy->firstIndexableField(utf8StringOop);
	if (bytes) {
		for (i = 0; i <= (size - 1); i += 1) {
			c = byteString[i];
			if ((i + 1) == sqIndex1) {
				newIndex1 = utf8Index;
			}
			if ((i + 1) == sqIndex2) {
				newIndex2 = utf8Index;
			}
			utf8Index = putCharintoat(c, utf8String, utf8Index);
		}
	} else {
		for (i = 0; i <= (size - 1); i += 1) {
			c = wideString[i];
			if ((i + 1) == sqIndex1) {
				newIndex1 = utf8Index;
			}
			if ((i + 1) == sqIndex2) {
				newIndex2 = utf8Index;
			}
			utf8Index = putCharintoat(c, utf8String, utf8Index);
		}
	}
	if (nullFlag) {
		utf8String[utf8Index] = 0;
		utf8Index += 1;
	}
	interpreterProxy->pushRemappableOop(utf8StringOop);
	interpreterProxy->pushRemappableOop(arrayOop);
	realutf8StringOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), utf8Index);
	arrayOop = interpreterProxy->popRemappableOop();
	utf8StringOop = interpreterProxy->popRemappableOop();
	utf8String = interpreterProxy->firstIndexableField(utf8StringOop);
	realutf8String = interpreterProxy->firstIndexableField(realutf8StringOop);
	memcpy(realutf8String, utf8String, utf8Index);
	interpreterProxy->storePointerofObjectwithValue(0, arrayOop, realutf8StringOop);
	if (newIndex1 == -1) {
		if (sqIndex1 == -1) {
			val = -1;
		} else {
			val = utf8Index;
		}
	} else {
		val = newIndex1;
	}
	interpreterProxy->storeIntegerofObjectwithValue(1, arrayOop, val);
	if (newIndex2 == -1) {
		if (sqIndex2 == -1) {
			val = -1;
		} else {
			val = utf8Index;
		}
	} else {
		val = newIndex2;
	}
	interpreterProxy->storeIntegerofObjectwithValue(2, arrayOop, val);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(6, arrayOop);
	return null;
}

EXPORT(sqInt) primitiveUTF8StringWithIndex(void) {
	sqInt utf8StringOop;
	sqInt size;
	sqInt bytes;
	sqInt mult;
	unsigned char *byteString;
	sqInt stringOop;
	sqInt utf8Index;
	sqInt arrayOop;
	sqInt i;
	sqInt realutf8StringOop;
	unsigned int *wideString;
	unsigned char *realutf8String;
	sqInt val;
	unsigned int c;
	sqInt newIndex;
	unsigned char *utf8String;
	sqInt oStringOop;
	sqInt sqIndex;
	sqInt oArrayOop;
	sqInt nullFlag;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(3), "Object"));
	oStringOop = interpreterProxy->stackValue(3);
	sqIndex = interpreterProxy->stackIntegerValue(2);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Object"));
	oArrayOop = interpreterProxy->stackValue(1);
	nullFlag = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	if (interpreterProxy->failed()) {
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	arrayOop = oArrayOop;
	stringOop = oStringOop;
	if (interpreterProxy->isPointers(stringOop)) {
		primitiveFail();
		return null;
	}
	bytes = interpreterProxy->isBytes(stringOop);
	size = interpreterProxy->stSizeOf(stringOop);
	if (bytes) {
		mult = 2;
	} else {
		mult = 4;
	}
	interpreterProxy->pushRemappableOop(stringOop);
	interpreterProxy->pushRemappableOop(arrayOop);
	utf8StringOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), (size * mult) + 1);
	arrayOop = interpreterProxy->popRemappableOop();
	stringOop = interpreterProxy->popRemappableOop();
	if (bytes) {
		byteString = interpreterProxy->firstIndexableField(stringOop);
	} else {
		wideString = interpreterProxy->firstIndexableField(stringOop);
	}
	utf8Index = 0;
	newIndex = -1;
	utf8String = interpreterProxy->firstIndexableField(utf8StringOop);
	if (bytes) {
		for (i = 0; i <= (size - 1); i += 1) {
			c = byteString[i];
			if ((i + 1) == sqIndex) {
				newIndex = utf8Index;
			}
			utf8Index = putCharintoat(c, utf8String, utf8Index);
		}
	} else {
		for (i = 0; i <= (size - 1); i += 1) {
			c = wideString[i];
			if ((i + 1) == sqIndex) {
				newIndex = utf8Index;
			}
			utf8Index = putCharintoat(c, utf8String, utf8Index);
		}
	}
	if (nullFlag) {
		utf8String[utf8Index] = 0;
		utf8Index += 1;
	}
	interpreterProxy->pushRemappableOop(utf8StringOop);
	interpreterProxy->pushRemappableOop(arrayOop);
	realutf8StringOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), utf8Index);
	arrayOop = interpreterProxy->popRemappableOop();
	utf8StringOop = interpreterProxy->popRemappableOop();
	utf8String = interpreterProxy->firstIndexableField(utf8StringOop);
	realutf8String = interpreterProxy->firstIndexableField(realutf8StringOop);
	memcpy(realutf8String, utf8String, utf8Index);
	interpreterProxy->storePointerofObjectwithValue(0, arrayOop, realutf8StringOop);
	if (newIndex == -1) {
		if (sqIndex == -1) {
			val = -1;
		} else {
			val = utf8Index;
		}
	} else {
		val = newIndex;
	}
	interpreterProxy->storeIntegerofObjectwithValue(1, arrayOop, val);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(5, arrayOop);
	return null;
}

static sqInt putCharintoat(sqInt c, unsigned char*utf8String, sqInt utf8Index) {
	unsigned int val;
	sqInt nBytes;
	sqInt mask;
	sqInt i;
	sqInt index;
	sqInt shift;
	sqInt v;

	val = c & 2097151;
	index = utf8Index;
	if ((0 <= val) && (val <= 127)) {
		utf8String[index] = val;
		return utf8Index + 1;
	}
	/* begin utf8CountFor: */
	v = c & 2097151;
	if ((0 <= v) && (v <= 127)) {
		nBytes = 1;
		goto l1;
	}
	if ((128 <= v) && (v <= 2047)) {
		nBytes = 2;
		goto l1;
	}
	if ((2048 <= v) && (v <= 55295)) {
		nBytes = 3;
		goto l1;
	}
	if ((57344 <= v) && (v <= 65535)) {
		nBytes = 3;
		goto l1;
	}
	if ((65536 <= v) && (v <= 1114111)) {
		nBytes = 4;
		goto l1;
	}
	nBytes = 0;
l1:	/* end utf8CountFor: */;
	mask = utf8Headers[nBytes - 1];
	shift = (nBytes - 1) * -6;
	utf8String[index] = ((((shift < 0) ? ((usqInt) val >> -shift) : ((usqInt) val << shift))) | mask);
	index += 1;
	for (i = 2; i <= nBytes; i += 1) {
		shift += 6;
		utf8String[index] = (((((shift < 0) ? ((usqInt) val >> -shift) : ((usqInt) val << shift))) & 63) + 128);
		index += 1;
	}
	return utf8Index + nBytes;
}


/*	Register the given surface, answer an ID or -1 on failure */

static sqInt registerSurface(cairo_surface_t*surfaceHandle) {
	sqInt surfaceID;

	if (registerSurfaceFn == null) {
		if (!(loadSurfacePlugin())) {
			return -1;
		}
	}
	if (!((*registerSurfaceFn)((int)surfaceHandle, &surfaceDispatch, &surfaceID))) {
		fail("could not register surface");
		return -1;
	}
	/* missing DebugCode */;
	if (surfaceID > maxSurfaceID) {
		maxSurfaceID = surfaceID;
	}
	return surfaceID;
}


/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(sqInt) setInterpreter(struct VirtualMachine*anInterpreter) {
	sqInt ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
	return ok;
}

static void setSourcergbalpha(cairo_t*context, sqInt rgb, sqInt alpha) {
	sqInt b;
	sqInt r;
	sqInt g;

	r = (((usqInt) rgb) >> 20) & 1023;
	g = (((usqInt) rgb) >> 10) & 1023;
	b = (((usqInt) rgb) >> 0) & 1023;
	if (alpha == 255) {
		cairo_set_source_rgb(context, r / 1023.0, g / 1023.0, b / 1023.0);
	} else {
		cairo_set_source_rgba(context, r / 1023.0, g / 1023.0, b / 1023.0, alpha / 255.0);
	}
}

static sqInt showSurfacexywh(cairo_surface_t *surfaceHandle, sqInt x, sqInt y, sqInt w, sqInt h) {
	return 0;
}

EXPORT(sqInt) shutdownModule(void) {
	PangoFontDescription*desc;
	sqInt i;
	sqInt id;
	cairo_surface_t*surface;

	for (i = 0; i <= (lastIndex(contexts)); i += 1) {
		if (!((contexts[i]) == null)) {
			logwith("context %i still active when unloading module!", i);
			cairo_destroy(contexts[i]);
			contexts[i] = null;
		}
	}
	for (id = 0; id <= maxSurfaceID; id += 1) {
		surface = findSurface(id);
		if (surface != null) {
			logwith("surface %i still active when unloading module!", id);
			destroySurface(id);
		}
	}
	for (i = 0; i <= 255; i += 1) {
		desc = fontDescriptions[i];
		if (desc != null) {
			pango_font_description_free(desc);
			fontDescriptions[i] = null;
		}
	}
	if (defaultFontDescription != null) {
		pango_font_description_free(defaultFontDescription);
		defaultFontDescription = null;
	}
	return 1;
}

static sqInt sqAssert(sqInt aBool) {
	/* missing DebugCode */;
}

static sqInt sqCharCountInfromto(unsigned char* aString, sqInt from, sqInt to) {
	sqInt sqCount;
	sqInt aChar;
	sqInt index;

	index = from;
	sqCount = 0;
	while (index < to) {
		aChar = aString[index];
		if (aChar < 128) {
			index += 1;
		} else {
			if (aChar < 224) {
				index += 2;
			} else {
				if (aChar < 240) {
					index += 3;
				} else {
					if (aChar < 248) {
						index += 4;
					} else {
						if (aChar < 252) {
							index += 5;
						} else {
							if (aChar >= 252) {
								index += 6;
							}
						}
					}
				}
			}
		}
		sqCount += 1;
	}
	return sqCount;
}


/*	stroke depending on canvasOop's stroke flag */

static void strokefrom(cairo_t*context, sqInt canvasOop) {
	sqInt stroke;
	sqInt canvasFlags;
	sqInt rgb;

	canvasFlags = interpreterProxy->fetchIntegerofObject(CanvasFlagsIndex, canvasOop);
	if (interpreterProxy->failed()) {
		fail("canvas flags not an integer");
	} else {
		stroke = canvasFlags & CanvasFlagStroke;
		if (stroke != 0) {
			rgb = interpreterProxy->fetchIntegerofObject(CanvasStrokeColorIndex, canvasOop);
			cairo_save(context);
			setSourcergbalpha(context, rgb, stroke);
			cairo_stroke(context);
			cairo_restore(context);
		}
	}
}


/*	answer a surface by looking up its surface plugin ID stored as bits in formOop */

static cairo_surface_t* surfaceFrom(sqInt formOop) {
	sqInt surfaceID;

	if ((interpreterProxy->slotSizeOf(formOop)) < FormInstSize) {
		fail("form oop invalid");
		return null;
	}
	surfaceID = interpreterProxy->fetchIntegerofObject(FormBitsIndex, formOop);
	if (interpreterProxy->failed()) {
		fail("form handle not an integer");
		return null;
	}
	return findSurface(surfaceID);
}

static sqInt translateSqAttrsToPangoAttrsinto(sqInt sqAttrsArrayOop, PangoAttrList *pangoAttrList) {
	sqInt ind;
	sqInt symbolOop;
	sqInt *sqAttrsArray;
	char *symbol;
	sqInt sqAttrsSize;
	sqInt attrArray;

	sqAttrsSize = interpreterProxy->stSizeOf(sqAttrsArrayOop);
	sqAttrsArray = interpreterProxy->firstIndexableField(sqAttrsArrayOop);
	addDefaultInto(pangoAttrList);
	for (ind = 0; ind <= (sqAttrsSize - 1); ind += 1) {
		attrArray = sqAttrsArray[ind];
		symbolOop = interpreterProxy->fetchPointerofObject(0, attrArray);
		symbol = interpreterProxy->firstIndexableField(symbolOop);
		if ((symbol[0]) == 65) {
			addAlignmentinto(attrArray, pangoAttrList);
		}
		if ((symbol[0]) == 67) {
			addColorinto(attrArray, pangoAttrList);
		}
		if ((symbol[0]) == 69) {
			addEmphasisinto(attrArray, pangoAttrList);
		}
		if ((symbol[0]) == 70) {
			addFontinto(attrArray, pangoAttrList);
		}
		if ((symbol[0]) == 76) {
			addLanguageinto(attrArray, pangoAttrList);
		}
	}
	return 1;
}

static sqInt unlockSurfacexywh(cairo_surface_t*surfaceHandle, sqInt x, sqInt y, sqInt w, sqInt h) {
	/* missing DebugCode */;
	if ((w > 0) && (h > 0)) {
		cairo_surface_mark_dirty_rectangle(surfaceHandle, x, y, w, h);
	}
	return 1;
}


/*	Unregister the surface, answer true if successful */

static sqInt unregisterSurface(sqInt surfaceID) {
	if (unregisterSurfaceFn == null) {
		if (!(loadSurfacePlugin())) {
			return 0;
		}
	}
	/* missing DebugCode */;
	if (!((*unregisterSurfaceFn)(surfaceID))) {
		failwith("could not unregister surface %i", surfaceID);
		return 0;
	}
	return 1;
}

static sqInt utf8CountFor(unsigned int value) {
	sqInt v;

	v = value & 2097151;
	if ((0 <= v) && (v <= 127)) {
		return 1;
	}
	if ((128 <= v) && (v <= 2047)) {
		return 2;
	}
	if ((2048 <= v) && (v <= 55295)) {
		return 3;
	}
	if ((57344 <= v) && (v <= 65535)) {
		return 3;
	}
	if ((65536 <= v) && (v <= 1114111)) {
		return 4;
	}
	return 0;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* RomePlugin_exports[][3] = {
	{"RomePlugin", "primitivePangoBlockAtIndex", (void*)primitivePangoBlockAtIndex},
	{"RomePlugin", "primitiveDrawImageSrcLRTBDestLRTB", (void*)primitiveDrawImageSrcLRTBDestLRTB},
	{"RomePlugin", "primitiveDrawGeneralBezierShape", (void*)primitiveDrawGeneralBezierShape},
	{"RomePlugin", "initialiseModule", (void*)initialiseModule},
	{"RomePlugin", "primitiveFillRadialOriginXYdirectionXYnormalXYcolorStops", (void*)primitiveFillRadialOriginXYdirectionXYnormalXYcolorStops},
	{"RomePlugin", "primitiveFillColorAlpha", (void*)primitiveFillColorAlpha},
	{"RomePlugin", "primitiveFillLinearOriginXYdirectionXYcolorStops", (void*)primitiveFillLinearOriginXYdirectionXYcolorStops},
	{"RomePlugin", "primitiveDestroyFormHandle", (void*)primitiveDestroyFormHandle},
	{"RomePlugin", "primitiveClear", (void*)primitiveClear},
	{"RomePlugin", "primitiveTransformBy", (void*)primitiveTransformBy},
	{"RomePlugin", "primitiveDrawOvalLeftRightTopBottom", (void*)primitiveDrawOvalLeftRightTopBottom},
	{"RomePlugin", "primitiveDrawPolygon", (void*)primitiveDrawPolygon},
	{"RomePlugin", "primitivePluginVersion", (void*)primitivePluginVersion},
	{"RomePlugin", "primitiveShowZeroTerminatedUtf8StringXY", (void*)primitiveShowZeroTerminatedUtf8StringXY},
	{"RomePlugin", "primitiveFontFace", (void*)primitiveFontFace},
	{"RomePlugin", "primitiveClipRectangleLeftRightTopBottom", (void*)primitiveClipRectangleLeftRightTopBottom},
	{"RomePlugin", "getModuleName", (void*)getModuleName},
	{"RomePlugin", "primitiveFontSize", (void*)primitiveFontSize},
	{"RomePlugin", "primitivePangoIndexAtPoint", (void*)primitivePangoIndexAtPoint},
	{"RomePlugin", "primitiveDrawPolyline", (void*)primitiveDrawPolyline},
	{"RomePlugin", "primitiveDrawCurveFromXYviaXYandXYtoXY", (void*)primitiveDrawCurveFromXYviaXYandXYtoXY},
	{"RomePlugin", "primitiveRotateBy", (void*)primitiveRotateBy},
	{"RomePlugin", "primitiveDrawRoundRectLeftRightTopBottomRadiusCorner", (void*)primitiveDrawRoundRectLeftRightTopBottomRadiusCorner},
	{"RomePlugin", "moduleUnloaded", (void*)moduleUnloaded},
	{"RomePlugin", "primitiveDrawLineFromXYtoXY", (void*)primitiveDrawLineFromXYtoXY},
	{"RomePlugin", "primitivePangoShowString", (void*)primitivePangoShowString},
	{"RomePlugin", "primitiveDrawArcRadiusXYFromTo", (void*)primitiveDrawArcRadiusXYFromTo},
	{"RomePlugin", "primitiveDrawZeroTerminatedUtf8StringXY", (void*)primitiveDrawZeroTerminatedUtf8StringXY},
	{"RomePlugin", "primitiveSetLineWidth", (void*)primitiveSetLineWidth},
	{"RomePlugin", "primitivePangoComposeString", (void*)primitivePangoComposeString},
	{"RomePlugin", "primitiveUTF8StringWithIndex", (void*)primitiveUTF8StringWithIndex},
	{"RomePlugin", "primitiveStencilImageSrcLRTBDestLRTB", (void*)primitiveStencilImageSrcLRTBDestLRTB},
	{"RomePlugin", "setInterpreter", (void*)setInterpreter},
	{"RomePlugin", "primitiveRestoreState", (void*)primitiveRestoreState},
	{"RomePlugin", "primitiveScaleBy", (void*)primitiveScaleBy},
	{"RomePlugin", "primitivePangoComposeString2", (void*)primitivePangoComposeString2},
	{"RomePlugin", "primitiveDrawRectangleLeftRightTopBottom", (void*)primitiveDrawRectangleLeftRightTopBottom},
	{"RomePlugin", "primitiveFillBitmapOriginXYdirectionXYnormalXYRepeatImage", (void*)primitiveFillBitmapOriginXYdirectionXYnormalXYRepeatImage},
	{"RomePlugin", "primitiveSetTransform", (void*)primitiveSetTransform},
	{"RomePlugin", "primitiveSaveState", (void*)primitiveSaveState},
	{"RomePlugin", "primitiveLanguageAttributes", (void*)primitiveLanguageAttributes},
	{"RomePlugin", "primitiveGetTransform", (void*)primitiveGetTransform},
	{"RomePlugin", "primitivePangoFontDescriptionIndex", (void*)primitivePangoFontDescriptionIndex},
	{"RomePlugin", "primitiveUTF8StringWith2Indexes", (void*)primitiveUTF8StringWith2Indexes},
	{"RomePlugin", "primitiveCreateFormHandle", (void*)primitiveCreateFormHandle},
	{"RomePlugin", "primitivePangoIsAvailable", (void*)primitivePangoIsAvailable},
	{"RomePlugin", "primitiveClose", (void*)primitiveClose},
	{"RomePlugin", "primitiveOpen", (void*)primitiveOpen},
	{"RomePlugin", "primitiveDrawCurveFromXYviaXYtoXY", (void*)primitiveDrawCurveFromXYviaXYtoXY},
	{"RomePlugin", "primitiveGetLineWidth", (void*)primitiveGetLineWidth},
	{"RomePlugin", "shutdownModule", (void*)shutdownModule},
	{"RomePlugin", "primitiveTranslateBy", (void*)primitiveTranslateBy},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

