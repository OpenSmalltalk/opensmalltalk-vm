#include <assert.h>
#include <stdlib.h>
#include <time.h>
#include "sq.h"
#include "sqaio.h"
#include "sqMemoryAccess.h"
#include "sqWindow.h"

extern sqWindowSystem sqNullWindowSystem;

#ifdef SUPPORT_TRADITIONAL_DISPLAY
#   ifdef HAVE_SDL2
extern sqWindowSystem sqSDL2WindowSystem;
#   endif
#endif

sqWindowSystem *sqAllWindowSystems[] = {
    &sqNullWindowSystem,
#ifdef SUPPORT_TRADITIONAL_DISPLAY
#   ifdef HAVE_SDL2
    &sqSDL2WindowSystem,
#   endif
#endif

    NULL
};

static sqWindowSystem *currentWindowSystem = 0;
extern void ioAddInternalPluginPrimitives(void *primitiveList);
extern void vmIOProcessEvents(void);
void (*ioProcessEventsHandler) (void) = vmIOProcessEvents;

extern void setIoProcessEventsHandler(void * handler) {
    ioProcessEventsHandler = (void(*)()) handler;
}

void
vmIOProcessEvents(void)
{
}

void
ioSetWindowSystem(sqWindowSystem *windowSystem)
{
    if(!windowSystem)
        return;

    currentWindowSystem = windowSystem;
    ioAddInternalPluginPrimitives(windowSystem->primitives);
}

void
ioInitWindowSystem(sqInt headlessMode)
{
    /* Try to use a non-null window system.*/
    if(!currentWindowSystem && !headlessMode)
        ioSetWindowSystem(sqAllWindowSystems[1]);

    /* Make sure we are atleast using a null window system*/
    if(!currentWindowSystem)
        ioSetWindowSystem(&sqNullWindowSystem);
    currentWindowSystem->initialize();
}

void
ioShutdownWindowSystem(void)
{
    currentWindowSystem->shutdown();
    currentWindowSystem = 0;
}

const char *
ioWindowSystemName(void)
{
    return currentWindowSystem->name;
}

sqInt
ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY)
{
    return currentWindowSystem->setCursorARGB(cursorBitsIndex, extentX, extentY, offsetX, offsetY);
}

sqInt
ioForceDisplayUpdate(void)
{
    return currentWindowSystem->forceDisplayUpdate();
}

sqInt
ioFormPrint(sqInt bitsAddr, sqInt width, sqInt height, sqInt depth,
		  double hScale, double vScale, sqInt landscapeFlag)
{
    return currentWindowSystem->formPrint(bitsAddr, width, height, depth, hScale, vScale, landscapeFlag);
}

void
ioNoteDisplayChangedwidthheightdepth(void *b, int w, int h, int d)
{
    currentWindowSystem->noteDisplayChangedWidthHeightDepth(b, w, h, d);
}

sqInt
ioSetFullScreen(sqInt fullScreen)
{
    return currentWindowSystem->setFullScreen(fullScreen);
}

sqInt
ioSetCursor(sqInt cursorBitsIndex, sqInt offsetX, sqInt offsetY)
{
    return currentWindowSystem->setCursor(cursorBitsIndex, offsetX, offsetY);
}

sqInt
ioSetCursorWithMask(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY)
{
    return currentWindowSystem->setCursorWithMask(cursorBitsIndex, cursorMaskIndex, offsetX, offsetY);
}

sqInt
ioShowDisplay(sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth,
		    sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB)
{
    return currentWindowSystem->showDisplay(dispBitsIndex, width, height, depth,
        affectedL, affectedR, affectedT, affectedB);
}

sqInt
ioHasDisplayDepth(sqInt depth)
{
    return currentWindowSystem->hasDisplayDepth(depth);
}

sqInt
ioSetDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag)
{
    return currentWindowSystem->setDisplayMode(width, height, depth, fullscreenFlag);
}

char*
ioGetWindowLabel(void)
{
    return currentWindowSystem->getWindowLabel();
}

sqInt
ioSetWindowLabelOfSize(void *lblIndex, sqInt sz)
{
    return currentWindowSystem->setWindowLabelOfSize(lblIndex, sz);
}

sqInt
ioGetWindowWidth(void)
{
    return currentWindowSystem->getWindowWidth();
}

sqInt
ioGetWindowHeight(void)
{
    return currentWindowSystem->getWindowHeight();
}

sqInt
ioSetWindowWidthHeight(sqInt w, sqInt h)
{
    return currentWindowSystem->setWindowWidthHeight(w, h);
}

sqInt
ioIsWindowObscured(void)
{
    return currentWindowSystem->isWindowObscured();
}

sqInt
ioGetNextEvent(sqInputEvent *evt)
{
    return currentWindowSystem->getNextEvent(evt);
}

sqInt
ioGetButtonState(void)
{
    return currentWindowSystem->getButtonState();
}

sqInt
ioGetKeystroke(void)
{
    return currentWindowSystem->getKeystroke();
}

sqInt
ioMousePoint(void)
{
    return currentWindowSystem->mousePoint();
}

sqInt
ioPeekKeystroke(void)
{
    return currentWindowSystem->peekKeystroke();
}

sqInt
ioProcessEvents(void)
{
    if(ioProcessEventsHandler)
        ioProcessEventsHandler();
    sqInt res = currentWindowSystem->processEvents();
    aioPoll(0);
    return res;
}

double
ioScreenScaleFactor(void)
{
    return currentWindowSystem->screenScaleFactor();
}

sqInt
ioScreenSize(void)
{
    return currentWindowSystem->screenSize();
}

sqInt
ioScreenDepth(void)
{
    return currentWindowSystem->screenDepth();
}

sqInt
clipboardSize(void)
{
    return currentWindowSystem->clipboardSize();
}

sqInt
clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
    return currentWindowSystem->clipboardReadIntoAt(count, byteArrayIndex, startIndex);
}

sqInt
clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
    return currentWindowSystem->clipboardWriteFromAt(count, byteArrayIndex, startIndex);
}

sqInt
dropInit (void)
{
    return currentWindowSystem->dropInit();
}

sqInt
dropShutdown (void)
{
    return currentWindowSystem->dropShutdown();
}

char*
dropRequestFileName(sqInt dropIndex)
{
    return currentWindowSystem->dropRequestFileName(dropIndex);
}

/* *** TODO ***
 * provide support for URI */
char *
dropRequestURI(sqInt dropIndex)
{ return NULL; }

sqInt
dropRequestFileHandle(sqInt dropIndex)
{
    return currentWindowSystem->dropRequestFileHandle(dropIndex);
}

sqInt
sqSecFileAccessCallback(void *callback)
{
    return 0;
}

void
sqSetNumberOfDropFiles(sqInt numberOfFiles)
{
}

void
sqSetFileInformation(sqInt dropIndex, void *dropFile)
{
}
