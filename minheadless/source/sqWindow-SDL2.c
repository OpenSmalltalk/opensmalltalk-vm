#include <SDL.h>
#include <stdlib.h>
#include <time.h>
#include "sq.h"
#include "sqaio.h"
#include "sqMemoryAccess.h"
#include "sqEventCommon.h"
#include "config.h"

extern int getSavedWindowSize();

typedef struct sqSDLEventQueue
{
    sqCircularQueueInfo info;
    SDL_Event elements[SQ_EVENT_QUEUE_SIZE];
} sqSDLEventQueue;

#define sqSDLEventQueueIsEmpty(queue) sqQueueIsEmpty(queue, SQ_EVENT_QUEUE_SIZE)
#define sqSDLEventQueueIsFull(queue) sqQueueIsFull(queue, SQ_EVENT_QUEUE_SIZE)
#define sqSDLEventQueuePush(queue, value) sqQueuePush(queue, SQ_EVENT_QUEUE_SIZE, value)
#define sqSDLEventQueuePopInto(queue, result) sqQueuePopInto(queue, SQ_EVENT_QUEUE_SIZE, result)

static sqEventQueue eventQueue;
static sqSDLEventQueue sdlEventQueue;

static SDL_Window *window;
static Uint32 windowID;
static SDL_Renderer *windowRenderer;
static SDL_Texture *windowTexture;
static SDL_Cursor *currentCursor;
static int windowTextureWidth;
static int windowTextureHeight;

static int buttonState = 0;
static int modifiersState = 0;

static int newSDLEvent = 0;
static int newDisplayEvent = 0;

static int mousePositionX = 0;
static int mousePositionY = 0;

static sqInt sdl2InputEventSemaIndex = 0;
static sqInt setSDL2InputSemaphoreIndex(sqInt semaIndex)
{
    if (semaIndex == 0)
        success(false);
    else
        sdl2InputEventSemaIndex = semaIndex;
    return true;
}

void sdl2SignalInputEvent(void)
{
    if (sdl2InputEventSemaIndex > 0)
        signalSemaphoreWithIndex(sdl2InputEventSemaIndex);
}

static int convertButton(int button)
{
    switch(button)
    {
    case SDL_BUTTON_LEFT: return RedButtonBit;
    case SDL_BUTTON_MIDDLE: return BlueButtonBit;
    case SDL_BUTTON_RIGHT: return YellowButtonBit;
    default: return 0;
    }

    return 0;
}

static int convertModifiers(int state)
{
    int result = 0;
    if(state & KMOD_SHIFT)
        result |= ShiftKeyBit;
    if(state & KMOD_CTRL)
        result |= CtrlKeyBit;
    if(state & KMOD_ALT)
        result |= OptionKeyBit;
    if(state & KMOD_GUI)
        result |= CommandKeyBit;
    return result;
}

static int convertSpecialKeySymToCharacter(int symbol)
{
    switch(symbol)
    {
    case SDLK_RETURN: return '\r';
    case SDLK_BACKSPACE: return 8;
    case SDLK_TAB: return '\t';
    case SDLK_HOME: return 1;
    case SDLK_LEFT: return 28;
    case SDLK_UP: return 30;
    case SDLK_RIGHT: return 29;
    case SDLK_DOWN: return 31;
    case SDLK_END: return 4;
    case SDLK_INSERT: return 5;
    case SDLK_PAGEUP: return 11;
    case SDLK_PAGEDOWN: return 12;
    case SDLK_DELETE: return 127;
    default:
        return 0;
    }

}

static int convertKeySymToCharacter(int symbol)
{
    if(symbol >= 0x400000)
        return 0;
    else
        return symbol;
}

void ioInitWindowSystem(void)
{
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
    int flags;
    int actualWindowX, actualWindowY;
    int actualWindowWidth, actualWindowHeight;
    SDL_Rect displayBounds;
        
    if(window)
        return;

    flags = SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI;
    if(fullscreenFlag)
        flags |= SDL_WINDOW_FULLSCREEN_DESKTOP;

    modifiersState = convertModifiers(SDL_GetModState());
    window = SDL_CreateWindow("", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, flags);
    if(!window)
        return;
        
    if(!fullscreenFlag)
    {
        SDL_GetWindowPosition(window, &actualWindowX, &actualWindowY);
        SDL_GetWindowSize(window, &actualWindowWidth, &actualWindowHeight);
        SDL_GetDisplayUsableBounds(0, &displayBounds);
        if(actualWindowWidth + actualWindowX >= displayBounds.w || actualWindowHeight + actualWindowY >= displayBounds.h)
            SDL_MaximizeWindow(window);
    }
    
    windowID = SDL_GetWindowID(window);
    windowRenderer = SDL_CreateRenderer(window, 0, 0);
}

static int ensureTextureOfSize(sqInt width, sqInt height)
{
    if(windowTexture && windowTextureWidth == width && windowTextureHeight == height)
        return 0;

    if(windowTexture)
        SDL_DestroyTexture(windowTexture);

    windowTexture = SDL_CreateTexture(windowRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, width, height);
    windowTextureWidth = width;
    windowTextureHeight = height;
    return 1;
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

static void recordSDLEvent(const SDL_Event *rawEvent)
{
    newSDLEvent = 1;
    sqSDLEventQueuePush(sdlEventQueue, *rawEvent);
}

static void recordEvent(sqEventUnion *event)
{
    newDisplayEvent = 1;
    sqEventQueuePush(eventQueue, *event);
}

static void recordLowImportanceEvent(sqEventUnion *event)
{
    if(sqEventQueueIsFull(eventQueue))
        return;

    recordEvent(event);
}

static void recordMouseWheel(int keyCode)
{
    int modifiers = modifiersState ^ CtrlKeyBit;

    {
        sqEventUnion event;
        memset(&event, 0, sizeof(event));
        event.key.type = EventTypeKeyboard;
        event.key.pressCode = EventKeyDown;
        event.key.charCode = keyCode;
        event.key.utf32Code = keyCode;
        event.key.modifiers = modifiers;
        recordEvent(&event);
    }

    {
        sqEventUnion event;
        memset(&event, 0, sizeof(event));
        event.key.type = EventTypeKeyboard;
        event.key.pressCode = EventKeyChar;
        event.key.charCode = keyCode;
        event.key.utf32Code = keyCode;
        event.key.modifiers = modifiers;
        recordEvent(&event);
    }

    {
        sqEventUnion event;
        memset(&event, 0, sizeof(event));
        event.key.type = EventTypeKeyboard;
        event.key.pressCode = EventKeyUp;
        event.key.charCode = keyCode;
        event.key.utf32Code = keyCode;
        event.key.modifiers = modifiers;
        recordEvent(&event);
    }
}

static void handleMouseWheel(const SDL_Event *rawEvent)
{
    if(rawEvent->wheel.windowID != windowID)
    {
        recordSDLEvent(rawEvent);
        return;
    }

    if(rawEvent->wheel.x < 0)
    {
        recordMouseWheel(28);
    }
    else if(rawEvent->wheel.x > 0)
    {
        recordMouseWheel(29);
    }

    if(rawEvent->wheel.y > 0)
    {
        recordMouseWheel(30);
    }
    else if(rawEvent->wheel.y < 0)
    {
        recordMouseWheel(31);
    }
}
static void handleKeyDown(const SDL_Event *rawEvent)
{
    int character;
    int isSpecial;

    modifiersState = convertModifiers(rawEvent->key.keysym.mod);
    if(rawEvent->key.windowID != windowID)
    {
        recordSDLEvent(rawEvent);
        return;
    }

    character = convertSpecialKeySymToCharacter(rawEvent->key.keysym.sym);
    isSpecial = character != 0;
    if(!character)
        character = convertKeySymToCharacter(rawEvent->key.keysym.sym);

    {
        sqEventUnion event;
        memset(&event, 0, sizeof(event));
        event.key.type = EventTypeKeyboard;
        event.key.pressCode = EventKeyDown;
        event.key.charCode = rawEvent->key.keysym.sym;
        event.key.utf32Code = character;
        event.key.modifiers = modifiersState;
        recordEvent(&event);
    }

    /* We need to send a key stroke for some special circumstances. */
    if(!isSpecial && (!modifiersState || modifiersState == ShiftKeyBit))
        return;

    if(character && character != 27)
    {
        sqEventUnion event;
        memset(&event, 0, sizeof(event));
        event.key.type = EventTypeKeyboard;
        event.key.pressCode = EventKeyChar;
        event.key.charCode = character;
        event.key.utf32Code = character;
        event.key.modifiers = modifiersState;
        recordEvent(&event);
    }
}

static void handleKeyUp(const SDL_Event *rawEvent)
{
    modifiersState = convertModifiers(rawEvent->key.keysym.mod);
    if(rawEvent->key.windowID != windowID)
    {
        recordSDLEvent(rawEvent);
        return;
    }

    sqEventUnion event;
    memset(&event, 0, sizeof(event));
    event.key.type = EventTypeKeyboard;
    event.key.pressCode = EventKeyUp;
    event.key.charCode = convertKeySymToCharacter(rawEvent->key.keysym.sym);
    event.key.utf32Code = convertKeySymToCharacter(rawEvent->key.keysym.sym);
    event.key.modifiers = modifiersState;
    recordEvent(&event);
}

static void handleTextInput(const SDL_Event *rawEvent)
{
    int utf32;
    const char *position;

    if(rawEvent->text.windowID != windowID)
    {
        recordSDLEvent(rawEvent);
        return;
    }

    sqEventUnion event;
    memset(&event, 0, sizeof(event));
    event.key.type = EventTypeKeyboard;
    event.key.pressCode = EventKeyChar;
    event.key.modifiers = modifiersState;

    position = rawEvent->text.text;
    while(*position)
    {
        position = sqUTF8ToUTF32Iterate(position, &utf32);
        if(!utf32)
            break;

        event.key.charCode = utf32;
        event.key.utf32Code = utf32;
        recordEvent(&event);
    }
}

static void handleMouseButtonDown(const SDL_Event *rawEvent)
{
    if(rawEvent->button.windowID != windowID)
    {
        recordSDLEvent(rawEvent);
        return;
    }

    buttonState |= convertButton(rawEvent->button.button);

    sqEventUnion event;
    memset(&event, 0, sizeof(event));
    event.mouse.type = EventTypeMouse;
    event.mouse.x = mousePositionX = rawEvent->button.x;
    event.mouse.y = mousePositionY = rawEvent->button.y;
    event.mouse.buttons = buttonState;
    event.mouse.modifiers = modifiersState;
    event.mouse.nrClicks = rawEvent->button.clicks;
    recordEvent(&event);
}

static void handleMouseButtonUp(const SDL_Event *rawEvent)
{
    if(rawEvent->button.windowID != windowID)
    {
        recordSDLEvent(rawEvent);
        return;
    }

    buttonState &= ~convertButton(rawEvent->button.button);

    sqEventUnion event;
    memset(&event, 0, sizeof(event));
    event.mouse.type = EventTypeMouse;
    event.mouse.x = mousePositionX = rawEvent->button.x;
    event.mouse.y = mousePositionY = rawEvent->button.y;
    event.mouse.buttons = buttonState;
    event.mouse.modifiers = modifiersState;
    event.mouse.nrClicks = rawEvent->button.clicks;
    recordEvent(&event);
}

static void handleMouseMotion(const SDL_Event *rawEvent)
{
    if(rawEvent->motion.windowID != windowID)
    {
        recordSDLEvent(rawEvent);
        return;
    }

    sqEventUnion event;
    memset(&event, 0, sizeof(event));
    event.mouse.type = EventTypeMouse;
    event.mouse.x = mousePositionX = rawEvent->motion.x;
    event.mouse.y = mousePositionY = rawEvent->motion.y;
    event.mouse.buttons = buttonState;
    event.mouse.modifiers = modifiersState;
    recordLowImportanceEvent(&event);
}

static void handleEvent(const SDL_Event *event)
{
    switch(event->type)
    {
    case SDL_KEYDOWN:
        handleKeyDown(event);
        break;
    case SDL_KEYUP:
        handleKeyUp(event);
        break;
    case SDL_TEXTINPUT:
        handleTextInput(event);
        break;
    case SDL_MOUSEBUTTONDOWN:
        handleMouseButtonDown(event);
        break;
    case SDL_MOUSEBUTTONUP:
        handleMouseButtonUp(event);
        break;
    case SDL_MOUSEMOTION:
        handleMouseMotion(event);
        break;
    case SDL_MOUSEWHEEL:
        handleMouseWheel(event);
        break;
    case SDL_QUIT:
        ioExit();
        break;
    default:
        /* Record the unhandled SDL events for the image. */
        recordSDLEvent(event);
        break;
    }
}

static void handleEvents()
{
    SDL_Event event;
    while(SDL_PollEvent(&event))
        handleEvent(&event);

    if(newDisplayEvent)
        ioSignalInputEvent();
    if(newSDLEvent)
        sdl2SignalInputEvent();

    newDisplayEvent = 0;
    newSDLEvent = 0;
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
    SDL_Cursor *newCursor;
    Uint8 convertedCursorBits[32];
    Uint8 convertedCursorMask[32];
    int i;

    unsigned int *cursorBits = (unsigned int*)pointerForOop(cursorBitsIndex);
    unsigned int *cursorMask = (unsigned int*)pointerForOop(cursorMaskIndex);

    if (cursorMaskIndex == null)
        cursorMask = cursorBits;

    /* Remove the extra padding */
    for(i = 0; i < 16; ++i)
    {
        convertedCursorBits[i*2 + 0]= (cursorBits[i] >> 24) & 0xFF;
        convertedCursorBits[i*2 + 1]= (cursorBits[i] >> 16) & 0xFF;
        convertedCursorMask[i*2 + 0]= (cursorMask[i] >> 24) & 0xFF;
        convertedCursorMask[i*2 + 1]= (cursorMask[i] >> 16) & 0xFF;
    }

    /* Create and set the new cursor. */
    newCursor = SDL_CreateCursor(convertedCursorBits, convertedCursorMask, 16, 16, -offsetX, -offsetY);
    if(newCursor)
    {
        SDL_SetCursor(newCursor);
        if(currentCursor)
            SDL_FreeCursor(currentCursor);
        currentCursor = newCursor;
    }

    return 0;
}

static void blitRect32(
    int surfaceWidth, int surfaceHeight,
    uint8_t *sourcePixels, int sourcePitch,
    uint8_t *destPixels, int destPitch,
    int copyX, int copyY, int width, int height)
{
    int y;
    
    if(sourcePitch == destPitch &&
        surfaceWidth == width && surfaceHeight == height && copyX == 0 && copyY == 0)
    {
        memcpy(destPixels, sourcePixels, destPitch*height);
    }
    else if(sourcePitch == destPitch)
    {
        destPixels += copyY*destPitch;
        sourcePixels += copyY*sourcePitch;
        memcpy(destPixels, sourcePixels, destPitch*height);
    }
    else
    {
        int copyPitch = destPitch;
        if(sourcePitch < copyPitch)
            copyPitch = sourcePitch;

        destPixels += copyY*destPitch;
        sourcePixels += copyY*sourcePitch;

        for(y = 0; y < height; ++y)
        {
            memcpy(destPixels, sourcePixels, copyPitch);
            destPixels += destPitch;
            sourcePixels += sourcePitch;
        }
    }
}

sqInt ioShowDisplay(sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth,
		    sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB)
{
    if(!window)
        createWindow(width, height, 0);

    SDL_Rect modifiedRect;
    modifiedRect.x = affectedL;
    modifiedRect.y = affectedT;
    modifiedRect.w = affectedR - affectedL;
    modifiedRect.h = affectedB - affectedT;

    /* Make sure the texture has the correct extent. */
    if(ensureTextureOfSize(width, height))
    {
        /*If the texture was recreated, we have to upload the whole texture*/
        modifiedRect.x = 0;
        modifiedRect.y = 0;
        modifiedRect.w = width;
        modifiedRect.h = height;
    }

    if(!windowTexture)
        return 0;

    uint8_t *pixels;
    int pitch;
    if(SDL_LockTexture(windowTexture, NULL, (void**)&pixels, &pitch))
        return 0;

    int sourcePitch = windowTextureWidth*4;
    blitRect32(windowTextureWidth, windowTextureHeight,
        (uint8_t*)pointerForOop(dispBitsIndex), sourcePitch,
        pixels, pitch,
        modifiedRect.x, modifiedRect.y, modifiedRect.w, modifiedRect.h
    );

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
    if(sqEventQueueIsEmpty(eventQueue))
    {
        evt->type = EventTypeNone;
    }
    else
    {
        sqEventQueuePopInto(eventQueue, (sqEventUnion*)evt);
    }

    return 0;
}

sqInt ioGetNextSDL2Event(void *buffer, size_t bufferSize)
{
    SDL_Event event;
    size_t copySize;

    /* Retrieve the event from the queue. */
    if(sqSDLEventQueueIsEmpty(sdlEventQueue))
        return false;

    sqSDLEventQueuePopInto(sdlEventQueue, &event);

    /* Copy the event data into the buffer. */
    copySize = sizeof(SDL_Event);
    if(bufferSize < copySize)
        copySize = bufferSize;
    memcpy(buffer, &event, copySize);

    return true;
}

sqInt ioGetButtonState(void)
{
    ioProcessEvents();
    return buttonState | (modifiersState << 3);
}

sqInt ioGetKeystroke(void)
{
    return 0;
}

sqInt ioMousePoint(void)
{
    ioProcessEvents();
    return (mousePositionX<<16) | mousePositionY;
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

/* SDL2 primitives*/
extern sqInt argumentCountOf(sqInt methodPointer);
extern sqInt failed(void);
extern sqInt pop(sqInt nItems);
extern sqInt popthenPush(sqInt nItems, sqInt oop);
extern sqInt primitiveMethod(void);
extern sqInt stackIntegerValue(sqInt offset);
extern sqInt stackValue(sqInt offset);
extern sqInt trueObject(void);
extern sqInt falseObject(void);
extern void *firstIndexableField(sqInt oop);

sqInt primitiveIsVMDisplayUsingSDL2()
{
    popthenPush(1 + (argumentCountOf(primitiveMethod())), trueObject());
    return 0;
}

sqInt primitivePollVMSDL2Event()
{
    sqInt bufferOop;
    sqInt size;
    sqInt result;

    bufferOop = stackValue(1);
    size = stackIntegerValue(0);

    result = ioGetNextSDL2Event(firstIndexableField(bufferOop), size);
    popthenPush(1 + (argumentCountOf(primitiveMethod())), result ? trueObject() : falseObject());

    return 0;
}

sqInt primitiveSetVMSDL2Input()
{
    sqInt sema;

    sema = stackIntegerValue(0);
    setSDL2InputSemaphoreIndex(sema);
    if (!(failed())) {
        pop(argumentCountOf(primitiveMethod()));
    }

    return 0;
}

#define XFN(export) {"", #export, (void*)export},
#define XFND(export,depth) {"", #export "\000" depth, (void*)export},

void *winsys_exports[][3]=
{
    XFND(primitiveIsVMDisplayUsingSDL2, "\001")
    XFND(primitivePollVMSDL2Event, "\001")
    XFND(primitiveSetVMSDL2Input, "\001")
    { 0, 0, 0 }
};
