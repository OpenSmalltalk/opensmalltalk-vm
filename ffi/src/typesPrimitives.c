#include "pThreadedFFI.h"
#include "pharovm/macros.h"

int getTypeByteSize(void* aType);
void fillBasicType(sqInt aOop);

/**
 * This primitive takes the receiver that should be a TFBasicType
 * Then it initialize the object with a pointer to the corresponding libFFI type.
 */
Primitive(primitiveFillBasicType){
	fillBasicType(getReceiver());
}

/**
 * This primitive assumes the receiver is a TFBasicType.
 * It extract the size of the corresponding libFFI type.
 */
PrimitiveWithDepth(primitiveTypeByteSize, 1){
    void* handler;
    sqInt receiver;
    sqInt size;

	receiver = getReceiver();

	handler = getHandler(receiver);
	checkFailed();

	size = getTypeByteSize(handler);
	checkFailed();

	methodReturnInteger(size);
}

/**
 * This primitive frees the struct type ffi_type memory and the array used to hold the members.
 */
PrimitiveWithDepth(primitiveFreeStruct, 1){
	sqInt receiver;
	ffi_type* structType;

	receiver = getReceiver();
	checkFailed();

	structType = (ffi_type *)getHandler(receiver);
	checkFailed();

	if(!structType){
		primitiveFail();
		return;
	}

	free(structType->elements);
	free(structType);

	setHandler(receiver, NULL);

    //primitiveEnd(); //No need to call it
}

/**
 * This primitive returns the size of the struct type.
 */
PrimitiveWithDepth(primitiveStructByteSize, 1){
	sqInt receiver;
	ffi_type* structType;

	receiver = stackValue(0);
	checkFailed();

	structType = (ffi_type*)getHandler(receiver);
	checkFailed();

	if(!structType){
		primitiveFail();
		return;
	}

    primitiveEndReturnInteger(structType->size);
}


/**
 * This primitive initialize a struct type.
 * It assumes that the struct type is an external object.
 * It should have as slots:
 *
 * 1) An External Address (it should be a external object)
 * 2) An array with the members of the struct. Each member should be a valid type.
 * 3) An array with the same size of members that will receive the offsets of the members
 *
 * This primitive will allocate the required structs and fails if it cannot be allocated
 * or the parameters are no good.
 *
 * Also it calculates the offsets of the struct.
 *
 */
PrimitiveWithDepth(primitiveInitializeStructType, 2){
	sqInt receiver;
	sqInt arrayOfMembers;
	sqInt arrayOfOffsets;
	sqInt membersSize;
	ffi_type* structType;
	ffi_type** memberTypes;
	size_t* offsets;

	receiver = getReceiver();
	checkFailed();

    // Verify we have a valid handle
	getHandler(receiver);
	checkFailed();

	arrayOfMembers = getAttributeOf(receiver, 1);
	checkFailed();

	arrayOfOffsets = getAttributeOf(receiver, 2);
	checkFailed();

	//Validating that they are arrays.
	checkIsArray(arrayOfMembers);
	checkIsArray(arrayOfOffsets);

	membersSize = stSizeOf(arrayOfMembers);
	if(membersSize < 1){
		primitiveFail();
		return;
	}

	if(membersSize != stSizeOf(arrayOfOffsets)){
		primitiveFail();
		return;
	}

	//Validating that the members are of valid size
	for(int i=0; i < membersSize; i++){
		checkIsPointerSize(stObjectat(arrayOfMembers, i + 1), 1);
	}

	// Allocating the structure type
	structType = malloc(sizeof(ffi_type));
	if(!structType){
		primitiveFail();
		return;
	}

	memberTypes = malloc(sizeof(ffi_type*) * (membersSize+1));
	if(!memberTypes){
		free(structType);
		primitiveFail();
		return;
	}

	offsets = malloc(sizeof(size_t) * (membersSize));
	if(!offsets){
		free(memberTypes);
		free(structType);
		primitiveFail();
		return;
	}

	//The members list is ended by a NULL
	memberTypes[membersSize] = NULL;

	structType->alignment = 0;
	structType->size = 0;
	structType->type = FFI_TYPE_STRUCT;
	structType->elements = memberTypes;

	for(int i=0; i < membersSize; i++){
		memberTypes[i] = getHandler(stObjectat(arrayOfMembers, i + 1));
	}

	setHandler(receiver, structType);
	if(failed()){
		free(memberTypes);
		free(structType);
		free(offsets);
		return;
	}

	if(ffi_get_struct_offsets(FFI_DEFAULT_ABI, structType, offsets)!=FFI_OK){
		free(memberTypes);
		free(structType);
		free(offsets);
		primitiveFail();
		return;
	}

	for(int i=0; i < membersSize; i++){
		stObjectatput(arrayOfOffsets, i+1, integerObjectOf(offsets[i]));
	}

	free(offsets);

    //primitiveEnd(); // No need to call it
}
