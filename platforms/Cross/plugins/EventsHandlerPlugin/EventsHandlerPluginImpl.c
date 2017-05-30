#include "sqVirtualMachine.h"
#include <stdio.h>

extern void setIoProcessEventsHandler(void * handler);
extern void vmIOProcessEvents(void);
extern void *ioProcessEventsHandler;

void *getEventsHandler() { return ioProcessEventsHandler; }

void setEventsHandler(void *handle) { setIoProcessEventsHandler(handle); }

void setDefaultEventsHandler() { setIoProcessEventsHandler(&vmIOProcessEvents); }

