#include "sq.h"

/*** event handling ***/
static sqInt inputEventSemaIndex= 0;

/* set asynchronous input event semaphore  */
sqInt ioSetInputSemaphore(sqInt semaIndex)
{
    if (semaIndex == 0)
        success(false);
    else
        inputEventSemaIndex= semaIndex;
    return true;
}

void ioSignalInputEvent(void)
{
  if (inputEventSemaIndex > 0)
    signalSemaphoreWithIndex(inputEventSemaIndex);
}
