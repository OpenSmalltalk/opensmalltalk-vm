#include "pharovm/pharo.h"
#include <windows.h>

/****************************************************************************/
/*                      Synchronization functions                           */
/****************************************************************************/

/* NOTE: Why do we need this? When running multi-threaded code such as in
         the networking code and in midi primitives
         we will signal the interpreter several semaphores.
 	 (Predates the internal synchronization of signalSemaphoreWithIndex ()) */

extern VirtualMachine* interpreterProxy;

int synchronizedSignalSemaphoreWithIndex(int semaIndex)
{
  int result;

  /* Do our job - this is now synchronized in signalSemaphoreWithIndex */
  result = interpreterProxy->signalSemaphoreWithIndex(semaIndex);
  /* wake up interpret() if sleeping */
//  SetEvent(vmWakeUpEvent);
  return result;
}
