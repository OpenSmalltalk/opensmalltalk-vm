#include "SDL2DisplayPlugin.h"
#include <SDL2/SDL.h>
#include <stdio.h>

extern struct VirtualMachine* interpreterProxy;
extern void setIoProcessEventsHandler(void * handler);

static int inited = 0;
static int inputSemaphoreIndex = 0;

/**
 * Called by the VM heartbeat if installed, to check for the presence of events.
 */
static void ioCheckForEvents() {
    if (inited) {
        SDL_PumpEvents();
	    if (SDL_HasEvents(SDL_FIRSTEVENT, SDL_LASTEVENT)) {
		    interpreterProxy->signalSemaphoreWithIndex(inputSemaphoreIndex);
	    }
    }
}

void setSDL2InputSemaphoreIndex(int semaIndex) {
    inited = 1;
    inputSemaphoreIndex = semaIndex;
    setIoProcessEventsHandler(&ioCheckForEvents);
}

