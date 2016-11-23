#include <stdlib.h>
#include <time.h>
#include "sq.h"
#include "sqaio.h"
#include "sqMemoryAccess.h"
#include "config.h"

static sqInt currentDisplayWidth;
static sqInt currentDisplayHeight;
static sqInt currentDisplayDepth;
static sqInt currentDisplayFullscreenFlag;

static sqInt screenWidth = 1920;
static sqInt screenHeight = 1080;
static sqInt screenDepth = 32;

void ioInitWindowSystem(void)
{
}

void ioShutdownWindowSystem(void)
{
}

const char *ioWindowSystemName(void)
{
    return "null";
}

sqInt ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY)
{
    return false;
}

sqInt ioForceDisplayUpdate(void)
{
    return 0;
}

sqInt ioFormPrint(sqInt bitsAddr, sqInt width, sqInt height, sqInt depth,
		  double hScale, double vScale, sqInt landscapeFlag)
{
    return 0;
}

sqInt ioSetFullScreen(sqInt fullScreen)
{
    return 0;
}

sqInt ioSetCursor(sqInt cursorBitsIndex, sqInt offsetX, sqInt offsetY)
{
    return 0;
}

sqInt ioSetCursorWithMask(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY)
{
    return 0;
}

sqInt ioShowDisplay(sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth,
		    sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB)
{
    return 0;
}

sqInt ioHasDisplayDepth(sqInt depth)
{
    return true;
}

sqInt ioSetDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag)
{
    currentDisplayWidth = width;
    currentDisplayHeight = height;
    currentDisplayDepth = depth;
    currentDisplayFullscreenFlag = fullDisplayUpdate();

    return 0;
}

char* ioGetWindowLabel(void)
{
    return "";
}

sqInt ioSetWindowLabelOfSize(void *lblIndex, sqInt sz)
{
    return 0;
}

sqInt ioGetWindowWidth(void)
{
    return currentDisplayWidth;
}

sqInt ioGetWindowHeight(void)
{
    return currentDisplayHeight;
}

sqInt ioSetWindowWidthHeight(sqInt w, sqInt h)
{
    currentDisplayWidth = w;
    currentDisplayHeight = h;
    return 0;
}

sqInt ioIsWindowObscured(void)
{
    return false;
}

/* Events */
sqInt ioGetNextEvent(sqInputEvent *evt)
{
    evt->type = EventTypeNone;
    return 0;
}

sqInt ioGetButtonState(void)
{
    return 0;
}

sqInt ioGetKeystroke(void)
{
    return 0;
}

sqInt ioMousePoint(void)
{
    return 0;
}

sqInt ioPeekKeystroke(void)
{
    return 0;
}

sqInt ioProcessEvents(void)
{
    aioPoll(0);
    return 0;
}

double ioScreenScaleFactor(void)
{
    return (double)screenWidth / (double)screenHeight;
}

sqInt ioScreenSize(void)
{
    return screenWidth | (screenHeight << 16);
}

sqInt ioScreenDepth(void)
{
    return screenDepth;
}

/* Clipboard */
sqInt clipboardSize(void)
{
    return 0;
}

sqInt clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
    return 0;
}

sqInt clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
    return 0;
}
