#include <stdlib.h>
#include <time.h>
#include "sq.h"
#include "sqaio.h"
#include "sqMemoryAccess.h"
#include "sqWindow.h"
#include "config.h"

static sqInt currentDisplayWidth;
static sqInt currentDisplayHeight;
static sqInt currentDisplayDepth;
static sqInt currentDisplayFullscreenFlag;

static sqInt screenWidth = 1920;
static sqInt screenHeight = 1080;
static sqInt screenDepth = 32;

static void
sqNull_initialize(void)
{
}

static void
sqNull_shutdown(void)
{
}

static sqInt
sqNull_setCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY)
{
    return false;
}

static sqInt
sqNull_forceDisplayUpdate(void)
{
    return 0;
}

static sqInt
sqNull_formPrint(sqInt bitsAddr, sqInt width, sqInt height, sqInt depth,
		  double hScale, double vScale, sqInt landscapeFlag)
{
    return 0;
}

static void
sqNull_noteDisplayChangedWidthHeightDepth(void *b, int w, int h, int d)
{
}

static sqInt
sqNull_setFullScreen(sqInt fullScreen)
{
    return 0;
}

static sqInt
sqNull_setCursor(sqInt cursorBitsIndex, sqInt offsetX, sqInt offsetY)
{
    return 0;
}

static sqInt
sqNull_setCursorWithMask(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY)
{
    return 0;
}

static sqInt
sqNull_showDisplay(sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth,
		    sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB)
{
    return 0;
}

static sqInt
sqNull_hasDisplayDepth(sqInt depth)
{
    return true;
}

static sqInt
sqNull_setDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag)
{
    currentDisplayWidth = width;
    currentDisplayHeight = height;
    currentDisplayDepth = depth;
    currentDisplayFullscreenFlag = fullDisplayUpdate();

    return 0;
}

static char*
sqNull_getWindowLabel(void)
{
    return "";
}

static sqInt
sqNull_setWindowLabelOfSize(void *lblIndex, sqInt sz)
{
    return 0;
}

static sqInt
sqNull_getWindowWidth(void)
{
    return currentDisplayWidth;
}

static sqInt
sqNull_getWindowHeight(void)
{
    return currentDisplayHeight;
}

static sqInt
sqNull_setWindowWidthHeight(sqInt w, sqInt h)
{
    currentDisplayWidth = w;
    currentDisplayHeight = h;
    return 0;
}

static sqInt
sqNull_isWindowObscured(void)
{
    return false;
}

/* Events */
static sqInt
sqNull_getNextEvent(sqInputEvent *evt)
{
    evt->type = EventTypeNone;
    return 0;
}

static sqInt
sqNull_processEvents(void)
{
    return 0;
}

static double
sqNull_screenScaleFactor(void)
{
    return (double)screenWidth / (double)screenHeight;
}

static sqInt
sqNull_screenSize(void)
{
    return screenWidth | (screenHeight << 16);
}

static sqInt
sqNull_screenDepth(void)
{
    return screenDepth;
}

/* Clipboard */
static sqInt
sqNull_clipboardSize(void)
{
    return 0;
}

static sqInt
sqNull_clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
    return 0;
}

static sqInt
sqNull_clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
    return 0;
}

/* Drag/Drop*/
extern sqInt nilObject(void);

static sqInt
sqNull_dropInit (void)
{
    return 1;
}

static sqInt
sqNull_dropShutdown (void)
{
    return 1;
}

static char*
sqNull_dropRequestFileName(sqInt dropIndex)
{
    return 0;
}

static char *
sqNull_dropRequestURI(sqInt dropIndex)
{ return NULL; }

static sqInt
sqNull_dropRequestFileHandle(sqInt dropIndex)
{
    return nilObject();
}

sqWindowSystem sqNullWindowSystem = {
    .name = "null",

    .initialize = sqNull_initialize,
    .shutdown = sqNull_shutdown,
    .setCursorARGB = sqNull_setCursorARGB,
    .forceDisplayUpdate = sqNull_forceDisplayUpdate,
    .formPrint = sqNull_formPrint,
    .noteDisplayChangedWidthHeightDepth = sqNull_noteDisplayChangedWidthHeightDepth,
    .setFullScreen = sqNull_setFullScreen,
    .setCursor = sqNull_setCursor,
    .setCursorWithMask = sqNull_setCursorWithMask,
    .showDisplay = sqNull_showDisplay,
    .hasDisplayDepth = sqNull_hasDisplayDepth,
    .setDisplayMode = sqNull_setDisplayMode,
    .getWindowLabel = sqNull_getWindowLabel,
    .setWindowLabelOfSize = sqNull_setWindowLabelOfSize,
    .getWindowWidth = sqNull_getWindowWidth,
    .getWindowHeight = sqNull_getWindowHeight,
    .setWindowWidthHeight = sqNull_setWindowWidthHeight,
    .isWindowObscured = sqNull_isWindowObscured,
    .getNextEvent = sqNull_getNextEvent,
    .getButtonState = sqNull_getButtonState,
    .getKeystroke = sqNull_getKeystroke,
    .mousePoint = sqNull_mousePoint,
    .peekKeystroke = sqNull_peekKeystroke,
    .processEvents = sqNull_processEvents,
    .screenScaleFactor = sqNull_screenScaleFactor,
    .screenSize = sqNull_screenSize,
    .screenDepth = sqNull_screenDepth,
    .clipboardSize = sqNull_clipboardSize,
    .clipboardReadIntoAt = sqNull_clipboardReadIntoAt,
    .clipboardWriteFromAt = sqNull_clipboardWriteFromAt,
    .dropInit = sqNull_dropInit,
    .dropShutdown = sqNull_dropShutdown,
    .dropRequestFileName = sqNull_dropRequestFileName,
    .dropRequestURI = sqNull_dropRequestURI,
    .dropRequestFileHandle = sqNull_dropRequestFileHandle,
};
