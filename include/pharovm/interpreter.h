#ifndef INCLUDE_INTERPRETER_H_
#define INCLUDE_INTERPRETER_H_

#include "cogmethod.h"
#include "cointerp.h"

sqInt stSizeOf(sqInt oop);
sqInt stObjectat(sqInt array, sqInt index);
sqInt stObjectatput(sqInt array, sqInt index, sqInt value);

sqInt stackIntegerValue(sqInt offset);
sqInt stackObjectValue(sqInt offset);

sqInt integerObjectOf(sqInt value);
sqInt integerValueOf(sqInt oop);

sqInt methodReturnInteger(sqInt integer);

sqInt isPinned(sqInt objOop);
sqInt isPointers(sqInt oop);

sqInt stSizeOf(sqInt oop);
sqInt slotSizeOf(sqInt oop);

sqInt classExternalAddress(void);
void * firstIndexableField(sqInt objOop);


sqInt classByteArray(void);
sqInt classString(void);
sqInt classExternalAddress(void);
sqInt classFloat(void);

sqInt methodArgumentCount(void);
void pushFloat(double f);
sqInt pushInteger(sqInt integerValue);
void push(sqInt object);

sqInt failed(void);

sqInt forceInterruptCheck(void);
sqInt doSignalSemaphoreWithIndex(sqInt semaIndex);
sqInt getExternalSemaphoreWithIndex(sqInt index);
void doWaitSemaphore(sqInt sema);
void doWaitSemaphorereEnterInterpreter(sqInt sema, sqInt hasToReenter);


#endif /* INCLUDE_INTERPRETER_H_ */
