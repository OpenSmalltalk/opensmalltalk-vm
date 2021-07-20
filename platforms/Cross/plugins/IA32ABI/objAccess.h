// Access to Aliens, SmallIntegers etc while marshalling.

#include "interp.h"
#include "sqMemoryAccess.h"
#include "sqVirtualMachine.h"

#define objIsAlien(oop) (interpreterProxy->includesBehaviorThatOf\
	(interpreterProxy->fetchClassOf(oop), interpreterProxy->classAlien()))

#define objIsUnsafeAlien(oop) (interpreterProxy->includesBehaviorThatOf\
	(interpreterProxy->fetchClassOf(oop), interpreterProxy->classUnsafeAlien()))

#define sizeField(alien) (*(sqInt *)pointerForOop((sqInt)(alien) + BaseHeaderSize))
#define dataPtr(alien) pointerForOop((sqInt)(alien) + BaseHeaderSize + BytesPerOop)
#define isIndirect(alien) (sizeField(alien) < 0)
#define startOfParameterData(alien) (isIndirect(alien)	\
									? *(void **)dataPtr(alien)	\
									:  (void  *)dataPtr(alien))
#define isIndirectSize(size) ((size) < 0)
#define startOfDataWithSize(alien,size) (isIndirectSize(size)	\
								? *(void **)dataPtr(alien)		\
								:  (void  *)dataPtr(alien))

#define TagMask ((1 << NumSmallIntegerTagBits) - 1)
#define isSmallInt(oop) (((oop) & TagMask) == 1)
#define intVal(oop) ((sqInt)(oop) >> NumSmallIntegerTagBits)
