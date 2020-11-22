#include "pThreadedFFI.h"


void writeAddress(sqInt anExternalAddress, void* value){
	if(!isKindOfClass(anExternalAddress, classExternalAddress())){
		primitiveFail();
		return;
	}

	*((void**)firstIndexableField(anExternalAddress)) = value;
}

sqInt getAttributeOf(sqInt receiver, int index) {
    return fetchPointerofObject(index, receiver);
}

void *getHandlerOf(sqInt receiver, int index) {
    return readAddress(getAttributeOf(receiver, index));
}

void setHandler(sqInt anExternalObject, void* value){
	if(!(isPointers(anExternalObject) && slotSizeOf(anExternalObject) >= 1)) {
		primitiveFail();
		return;
	}
	writeAddress(fetchPointerofObject(0, anExternalObject), value);
}


void* getAddressFromExternalAddressOrByteArray(sqInt anExternalAddressOrByteArray){
	if(isKindOfClass(anExternalAddressOrByteArray, classExternalAddress())){
		return readAddress(anExternalAddressOrByteArray);
	}

	if(isKindOfClass(anExternalAddressOrByteArray, classByteArray())){
		return firstIndexableField(anExternalAddressOrByteArray);
	}

	primitiveFail();
	return NULL;
}

char *readString(sqInt aString) {
    if(!isKindOfClass(aString, classString())){
        primitiveFail();
        return NULL;
    }
    
    return (char *)firstIndexableField(aString);
}

// Extras

inline sqInt newExternalAddress(void *address) {
    sqInt externalAddress = instantiateClassindexableSize(classExternalAddress(), sizeof(void*));
    writeAddress(externalAddress, address);
    return externalAddress;
}

// Array

inline sqInt arrayObjectAt(sqInt array, sqInt index) {
    return stObjectat(array, index + 1);
}

inline sqInt arrayObjectAtPut(sqInt array, sqInt index, sqInt object) {
    return stObjectatput(array, index + 1, object);
}

inline sqInt arrayObjectSize(sqInt array) {
    return stSizeOf(array);
}
