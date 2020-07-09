#ifndef __UTILS__
#define __UTILS__

#include "pharovm/pharo.h"

void setHandler(sqInt anExternalObject, void* value);
void writeAddress(sqInt anExternalAddress, void* value);
char *readString(sqInt aString);
void *getAddressFromExternalAddressOrByteArray(sqInt anExternalAddressOrByteArray);

// meta
sqInt getReceiver();
sqInt getAttributeOf(sqInt receiver, int index);
void *getHandlerOf(sqInt receiver, int index);
// arrays
sqInt arrayObjectAt(sqInt array, sqInt index);
sqInt arrayObjectAtPut(sqInt array, sqInt index, sqInt object);
sqInt arrayObjectSize(sqInt array);
// clean ending for a primitive
void primitiveEnd();
void primitiveEndReturn(sqInt ret);
void primitiveEndReturnInteger(sqInt ret);
// others
sqInt newExternalAddress(void *address);

#endif
