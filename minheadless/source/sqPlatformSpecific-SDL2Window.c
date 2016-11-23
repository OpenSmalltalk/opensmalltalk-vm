#include <SDL.h>
#include <stdlib.h>
#include <time.h>
#include "sq.h"
#include "sqaio.h"
#include "sqMemoryAccess.h"
#include "sqEventCommon.h"
#include "config.h"

extern int getSavedWindowSize();

static SDL_Window *window;
static SDL_Renderer *windowRenderer;
static SDL_Texture *windowTexture;
static int windowTextureWidth;
static int windowTextureHeight;

void ioInitWindowSystem(void)
{
    printf("Init window system SDL2\n");
    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_NOPARACHUTE);
}

void ioShutdownWindowSystem(void)
{
    SDL_Quit();
}

const char *ioWindowSystemName(void)
{
    return "sdl2";
}

static void createWindow(sqInt width, sqInt height, sqInt fullscreenFlag)
{
    if(window)
        return;

    window = SDL_CreateWindow("", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, SDL_WINDOW_SHOWN);
    windowRenderer = SDL_CreateRenderer(window, 0, 0);
}

static void ensureTextureOfSize(sqInt width, sqInt height)
{
    if(windowTexture && windowTextureWidth == width && windowTextureHeight == height)
        return;

    if(windowTexture)
        SDL_DestroyTexture(windowTexture);

    windowTexture = SDL_CreateTexture(windowRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, width, height);
    windowTextureWidth = width;
    windowTextureHeight = height;
}

static void presentWindow()
{
    if(!window || !windowRenderer)
        return;

    SDL_SetRenderDrawColor(windowRenderer, 0, 0, 0, 0);
    SDL_RenderClear(windowRenderer);

    if(windowTexture)
        SDL_RenderCopy(windowRenderer, windowTexture, NULL, NULL);

    SDL_RenderPresent(windowRenderer);
}

static void handleKeyDown(const SDL_KeyboardEvent *event)
{
}

static void handleKeyUp(const SDL_KeyboardEvent *event)
{
}

static void handleMouseButtonDown(const SDL_MouseButtonEvent *event)
{
}

static void handleMouseButtonUp(const SDL_MouseButtonEvent *event)
{
}

static void handleMouseMotion(const SDL_MouseMotionEvent *event)
{
}

static void handleEvent(const SDL_Event *event)
{
    switch(event->type)
    {
    case SDL_KEYDOWN:
        handleKeyDown(&event->key);
        break;
    case SDL_KEYUP:
        handleKeyUp(&event->key);
        break;
    case SDL_MOUSEBUTTONDOWN:
        handleMouseButtonDown(&event->button);
        break;
    case SDL_MOUSEBUTTONUP:
        handleMouseButtonUp(&event->button);
        break;
    case SDL_MOUSEMOTION:
        handleMouseMotion(&event->motion);
        break;
    case SDL_QUIT:
        ioExit();
        break;
    }
}

static void handleEvents()
{
    SDL_Event event;
    while(SDL_PollEvent(&event))
    {
        handleEvent(&event);
    }
}

sqInt ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY)
{
    return false;
}

sqInt ioForceDisplayUpdate(void)
{
    presentWindow();
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
    if(!window)
        createWindow(width, height, 0);
    ensureTextureOfSize(width, height);
    if(!windowTexture)
        return 0;

    uint32_t *pixels;
    int pitch;
    if(SDL_LockTexture(windowTexture, NULL, (void**)&pixels, &pitch))
        return 0;

    int sourcePitch = windowTextureWidth*4;
    const char *dispBits= (const char*)pointerForOop(dispBitsIndex);
    if(sourcePitch == pitch)
    {
        memcpy(pixels, dispBits, pitch*height);
    }
    else
    {
        // TODO: Copy row by row.
    }

    SDL_UnlockTexture(windowTexture);

    presentWindow();
    return 0;
}

sqInt ioHasDisplayDepth(sqInt depth)
{
    return depth == 32;
}

sqInt ioSetDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag)
{
    if(window)
    {
        ioSetWindowWidthHeight(width, height);
        ioSetFullScreen(fullscreenFlag);
        return 0;
    }

    createWindow(width, height, fullscreenFlag);
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
    int width = 0;
    int height = 0;
    if(window)
        SDL_GetWindowSize(window, &width, &height);
    return width;
}

sqInt ioGetWindowHeight(void)
{
    int width = 0;
    int height = 0;
    if(window)
        SDL_GetWindowSize(window, &width, &height);
    return height;
}

sqInt ioSetWindowWidthHeight(sqInt w, sqInt h)
{
    if(window)
        SDL_SetWindowSize(window, w, h);
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
    handleEvents();
    aioPoll(0);
    return 0;
}

double ioScreenScaleFactor(void)
{
    SDL_Rect bounds;
    if(SDL_GetDisplayBounds(0, &bounds) != 0)
    {
        return 1.0;
    }

    return (double)bounds.w / (double)bounds.h;
}

sqInt ioScreenSize(void)
{
    int winSize = getSavedWindowSize();
    return winSize;
}

sqInt ioScreenDepth(void)
{
    return 32;
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
