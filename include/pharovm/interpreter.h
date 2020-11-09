#ifndef INCLUDE_INTERPRETER_H_
#define INCLUDE_INTERPRETER_H_

//#include "cogmethod.h"
#include "interp.h"

sqInt stSizeOf(sqInt oop);
sqInt stObjectat(sqInt array, sqInt index);
sqInt stObjectatput(sqInt array, sqInt index, sqInt value);

sqInt stackIntegerValue(sqInt offset);
sqInt stackObjectValue(sqInt offset);
sqInt stackValue(sqInt offset);

sqInt integerObjectOf(sqInt value);
sqInt integerValueOf(sqInt oop);

sqInt methodReturnInteger(sqInt integer);

sqInt isPinned(sqInt objOop);
sqInt isPointers(sqInt oop);

sqInt stSizeOf(sqInt oop);
sqInt slotSizeOf(sqInt oop);

sqInt isKindOfClass(sqInt, sqInt);
sqInt instantiateClassindexableSize(sqInt, sqInt);

sqInt classExternalAddress(void);
void * firstIndexableField(sqInt objOop);

sqInt classArray(void);
sqInt classByteArray(void);
sqInt classString(void);
sqInt classExternalAddress(void);
sqInt classFloat(void);

sqInt trueObject(void);
sqInt falseObject(void);

sqInt methodArgumentCount(void);
void pushFloat(double f);
sqInt pushInteger(sqInt integerValue);
void push(sqInt object);

sqInt failed(void);
sqInt primitiveFailFor(sqInt);

sqInt forceInterruptCheck(void);
sqInt doSignalSemaphoreWithIndex(sqInt semaIndex);
sqInt getExternalSemaphoreWithIndex(sqInt index);
void  doWaitSemaphore(sqInt sema);
void  doWaitSemaphorereEnterInterpreter(sqInt sema, sqInt hasToReenter);

sqInt fetchPointerofObject(sqInt, sqInt);

sqInt stringForCString(const char*);

sqInt ptEnterInterpreterFromCallback(void*);
sqInt ptExitInterpreterToCallback(void*);

int osCogStackPageHeadroom();

sqInt isForwarded(sqInt oop);

#endif /* INCLUDE_INTERPRETER_H_ */
