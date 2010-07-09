/* Automatically generated from Squeak on 8 July 2010 5:52:05 pm 
   by VMMaker 4.2.6
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <Foundation/Foundation.h>
 /* Default EXPORT macro that does nothing (see comment in sq.h): */
#define EXPORT(returnType) returnType

/* Do not include the entire sq.h file but just those parts needed. */
/*  The virtual machine proxy definition */
#include "sqVirtualMachine.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"

#define true 1
#define false 0
#define null 0  /* using 'null' because nil is predefined in Think C */
#ifdef SQUEAK_BUILTIN_PLUGIN
#undef EXPORT
// was #undef EXPORT(returnType) but screws NorCroft cc
#define EXPORT(returnType) static returnType
#endif

#include "sqMemoryAccess.h"


/*** Constants ***/

/*** Function Prototypes ***/
static VirtualMachine * getInterpreter(void);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static sqInt halt(void);
static sqInt initialiseModule(void);
static sqInt msg(char * s);
#pragma export on
EXPORT(sqInt) primitiveCallbackLeave(void);
EXPORT(sqInt) primitiveGetAddressFromEntryPointString(void);
EXPORT(sqInt) primitiveGetAutoReleasePool(void);
EXPORT(sqInt) primitiveGetClass(void);
EXPORT(sqInt) primitiveGetDescription(void);
EXPORT(sqInt) primitiveGetMethodSignatureForSelector(void);
EXPORT(sqInt) primitiveGetNSStringForString(void);
EXPORT(sqInt) primitiveGetObjCClassForString(void);
EXPORT(sqInt) primitiveGetSelectorForString(void);
EXPORT(sqInt) primitiveGetSuperClass(void);
EXPORT(sqInt) primitiveIsEqual(void);
EXPORT(sqInt) primitiveMethodSignatureGetArgumentType(void);
EXPORT(sqInt) primitiveMethodSignatureGetMethodReturnLength(void);
EXPORT(sqInt) primitiveMethodSignatureGetNumberOfArguments(void);
EXPORT(sqInt) primitiveMethodSignatureGetReturnType(void);
EXPORT(sqInt) primitiveNSInvocationCalloc(void);
EXPORT(sqInt) primitiveNSInvocationFree(void);
EXPORT(sqInt) primitiveNSInvocationGetArgument(void);
EXPORT(sqInt) primitiveNSInvocationGetCType(void);
EXPORT(sqInt) primitiveNSInvocationGetCharPointerType(void);
EXPORT(sqInt) primitiveNSInvocationGetClassType(void);
EXPORT(sqInt) primitiveNSInvocationGetDoubleType(void);
EXPORT(sqInt) primitiveNSInvocationGetFloatType(void);
EXPORT(sqInt) primitiveNSInvocationGetIntType(void);
EXPORT(sqInt) primitiveNSInvocationGetLongLongType(void);
EXPORT(sqInt) primitiveNSInvocationGetLongType(void);
EXPORT(sqInt) primitiveNSInvocationGetObjectType(void);
EXPORT(sqInt) primitiveNSInvocationGetReturnValue(void);
EXPORT(sqInt) primitiveNSInvocationGetSelectorType(void);
EXPORT(sqInt) primitiveNSInvocationGetShortType(void);
EXPORT(sqInt) primitiveNSInvocationGetStructureType(void);
EXPORT(sqInt) primitiveNSInvocationMalloc(void);
EXPORT(sqInt) primitiveNSInvocationSetCType(void);
EXPORT(sqInt) primitiveNSInvocationSetDoubleType(void);
EXPORT(sqInt) primitiveNSInvocationSetFloatType(void);
EXPORT(sqInt) primitiveNSInvocationSetIntType(void);
EXPORT(sqInt) primitiveNSInvocationSetLongLongType(void);
EXPORT(sqInt) primitiveNSInvocationSetLongType(void);
EXPORT(sqInt) primitiveNSInvocationSetPointerType(void);
EXPORT(sqInt) primitiveNSInvocationSetRetained(void);
EXPORT(sqInt) primitiveNSInvocationSetSelector(void);
EXPORT(sqInt) primitiveNSInvocationSetShortType(void);
EXPORT(sqInt) primitiveNSInvocationSetStringType(void);
EXPORT(sqInt) primitiveNSInvocationSetStructureType(void);
EXPORT(sqInt) primitiveNSInvocationSetVoidPointerType(void);
EXPORT(sqInt) primitiveNSInvocationWithMethodSignature(void);
EXPORT(sqInt) primitiveNSLog(void);
EXPORT(sqInt) primitiveNSStringToUTF8(void);
EXPORT(sqInt) primitivePerformSelector(void);
EXPORT(sqInt) primitivePerformSelectorOnMainThreadWithWaitTilDone(void);
EXPORT(sqInt) primitivePerformSelectorWith(void);
EXPORT(sqInt) primitivePerformSelectorWithWith(void);
EXPORT(sqInt) primitiveSELGetName(void);
EXPORT(sqInt) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off
static sqInt shutdownModule(void);
static sqInt sqAssert(sqInt aBool);
static sqInt stringFromCString(const char * aCString);
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"ObjectiveCPlugin 8 July 2010 (i)"
#else
	"ObjectiveCPlugin 8 July 2010 (e)"
#endif
;



/*	Note: This is coded so that plugins can be run from Squeak. */

static VirtualMachine * getInterpreter(void) {
	return interpreterProxy;
}


/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}

static sqInt halt(void) {
	;
}


/*	Initialise the module */

static sqInt initialiseModule(void) {
	return 1;
}

static sqInt msg(char * s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

EXPORT(sqInt) primitiveCallbackLeave(void) {
	sqInt aNumber;

	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (aNumber == 0) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->pop(1);
		return null;
	}
	interpreterProxy->callbackLeave(aNumber);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitiveGetAddressFromEntryPointString(void) {
	sqInt entryPointNameLength;
	void * fn;
	char entryPointName[256];
	char *aEntryPointName;
	sqInt _return_value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	aEntryPointName = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	entryPointNameLength = interpreterProxy->slotSizeOf((oopForPointer( aEntryPointName ) - BASE_HEADER_SIZE));
	if (entryPointNameLength > 255) {
		_return_value = interpreterProxy->positive64BitIntegerFor(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(2, _return_value);
		return null;
	}
	strlcpy(entryPointName, aEntryPointName, entryPointNameLength + 1);
	fn = dlsym(-2, entryPointName);
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) fn));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveGetAutoReleasePool(void) {
	NSAutoreleasePool * pool;
	sqInt _return_value;

	pool = null;
	    NS_DURING;
	pool = [NSAutoreleasePool new];
	    NS_HANDLER 
		pool = nil;;
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) pool));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}

EXPORT(sqInt) primitiveGetClass(void) {
	id classOrInstanceObject;
	Class classObject;
	sqInt aClassOrInstanceOop;
	sqInt _return_value;

	aClassOrInstanceOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	classOrInstanceObject = ((id) (interpreterProxy->positive64BitValueOf(aClassOrInstanceOop)));
	classObject = null;
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	;
	    NS_DURING;
	classObject = [classOrInstanceObject class];
	    NS_HANDLER 
		classObject = nil;;
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) classObject));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveGetDescription(void) {
	sqInt utf8StringOop;
	id classOrInstanceObject;
	const char * utf8String;
	NSString* nsStringObject;
	sqInt aClassOrInstanceOop;

	aClassOrInstanceOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	classOrInstanceObject = ((id) (interpreterProxy->positive64BitValueOf(aClassOrInstanceOop)));
	utf8String = null;
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	    NS_DURING;
	nsStringObject = [classOrInstanceObject description];
				utf8String = [nsStringObject UTF8String];
	    NS_HANDLER 
		utf8String = nil;;
	    NS_ENDHANDLER;
	if (!(utf8String)) {
		interpreterProxy->success(0);
		return null;
	}
	utf8StringOop = stringFromCString(utf8String);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, utf8StringOop);
	return null;
}

EXPORT(sqInt) primitiveGetMethodSignatureForSelector(void) {
	SEL selectorObject;
	NSMethodSignature * messageSignatureObject;
	id classOrInstanceObject;
	sqInt aSelectorOop;
	sqInt aClassOrInstanceOop;
	sqInt _return_value;

	aSelectorOop = interpreterProxy->stackValue(1);
	aClassOrInstanceOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	selectorObject = ((SEL) (interpreterProxy->positive64BitValueOf(aSelectorOop)));
	classOrInstanceObject = ((id) (interpreterProxy->positive64BitValueOf(aClassOrInstanceOop)));
	messageSignatureObject = null;
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	;
	    NS_DURING;
	messageSignatureObject = [classOrInstanceObject methodSignatureForSelector: selectorObject];
	    NS_HANDLER 
	messageSignatureObject = nil;;
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) messageSignatureObject));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(sqInt) primitiveGetNSStringForString(void) {
	NSString* aStringAsNSString;
	sqInt stringLength;
	NSUInteger encoding;
	char* aString;
	sqInt aStringOop;
	sqInt anEncoding;
	sqInt _return_value;

	aStringOop = interpreterProxy->stackValue(1);
	anEncoding = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	encoding = ((NSUInteger) (interpreterProxy->positive64BitValueOf(anEncoding)));
	aString = interpreterProxy->firstIndexableField(aStringOop);
	stringLength = interpreterProxy->byteSizeOf(aStringOop);
	;
	aStringAsNSString = 0;
	    NS_DURING;
	aStringAsNSString = [[NSString alloc] initWithBytes: aString length: stringLength encoding: encoding];
	    NS_HANDLER 
				aStringAsNSString = nil;;
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) aStringAsNSString));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(sqInt) primitiveGetObjCClassForString(void) {
	NSString* classNameNSString;
	sqInt classNameLength;
	Class classObject;
	char *aClassName;
	sqInt _return_value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	aClassName = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	classNameLength = interpreterProxy->slotSizeOf((oopForPointer( aClassName ) - BASE_HEADER_SIZE));
	;
	classNameNSString = [[NSString alloc] initWithBytes: aClassName length: classNameLength encoding: NSUTF8StringEncoding];
	    NS_DURING;
	classObject = NSClassFromString(classNameNSString);
	    NS_HANDLER 
	classObject = nil;;
	    NS_ENDHANDLER;
	[classNameNSString release];
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) classObject));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveGetSelectorForString(void) {
	SEL selectorObject;
	NSString * selectorNSString;
	sqInt selectorLength;
	char *aSelectorName;
	sqInt _return_value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	aSelectorName = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	selectorLength = interpreterProxy->slotSizeOf((oopForPointer( aSelectorName ) - BASE_HEADER_SIZE));
	;
	selectorNSString = [[NSString alloc] initWithBytes: aSelectorName length: selectorLength encoding: NSUTF8StringEncoding];
	    NS_DURING;
	selectorObject = NSSelectorFromString(selectorNSString);
	    NS_HANDLER 
	selectorObject = nil;;
	    NS_ENDHANDLER;
	[selectorNSString release];
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) selectorObject));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveGetSuperClass(void) {
	id classOrInstanceObject;
	Class classObject;
	sqInt aClassOrInstanceOop;
	sqInt _return_value;

	aClassOrInstanceOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	classOrInstanceObject = ((id) (interpreterProxy->positive64BitValueOf(aClassOrInstanceOop)));
	classObject = null;
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	;
	    NS_DURING;
	classObject = [classOrInstanceObject superclass];
	    NS_HANDLER 
		classObject = nil;;
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) classObject));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveIsEqual(void) {
	BOOL result;
	id oop2;
	id oop1;
	sqInt anOop1;
	sqInt anOop2;
	sqInt _return_value;

	anOop1 = interpreterProxy->stackValue(1);
	anOop2 = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	oop1 = ((id) (interpreterProxy->positive64BitValueOf(anOop1)));
	oop2 = ((id) (interpreterProxy->positive64BitValueOf(anOop2)));
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	;
	result = 0;
	    NS_DURING;
	result = [oop1 isEqual: oop2];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	_return_value = ((result == 1)) ? interpreterProxy->trueObject(): interpreterProxy->falseObject();
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(sqInt) primitiveMethodSignatureGetArgumentType(void) {
	NSMethodSignature* nsMethodSignatureObject;
	const char * string;
	sqInt stringOop;
	sqInt aMethodSignatureOop;
	sqInt aIndexNumber;

	aMethodSignatureOop = interpreterProxy->stackValue(1);
	aIndexNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	nsMethodSignatureObject = ((NSMethodSignature *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	string = null;
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	    NS_DURING;
	string = [nsMethodSignatureObject getArgumentTypeAtIndex: aIndexNumber];
	    NS_HANDLER 
		string = nil;;
	    NS_ENDHANDLER;
	if (!(string)) {
		interpreterProxy->success(0);
		return null;
	}
	stringOop = stringFromCString(string);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, stringOop);
	return null;
}

EXPORT(sqInt) primitiveMethodSignatureGetMethodReturnLength(void) {
	NSUInteger methodReturnLength;
	NSMethodSignature* nsMethodSignatureObject;
	sqInt aMethodSignatureOop;
	sqInt _return_value;

	aMethodSignatureOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	nsMethodSignatureObject = ((NSMethodSignature *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	methodReturnLength = 0;
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	    NS_DURING;
	methodReturnLength = [nsMethodSignatureObject methodReturnLength];
	    NS_HANDLER 
		methodReturnLength = 0xFFFFFFFF;
	    NS_ENDHANDLER;
	if (methodReturnLength == 4294967295U) {
		interpreterProxy->success(0);
		return null;
	}
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) methodReturnLength));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveMethodSignatureGetNumberOfArguments(void) {
	NSMethodSignature* nsMethodSignatureObject;
	NSUInteger numberOfArguments;
	sqInt aMethodSignatureOop;
	sqInt _return_value;

	aMethodSignatureOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	nsMethodSignatureObject = ((NSMethodSignature *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	numberOfArguments = 9999999;
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	    NS_DURING;
	numberOfArguments = [nsMethodSignatureObject numberOfArguments];
	    NS_HANDLER 
		numberOfArguments = 9999999;
	    NS_ENDHANDLER;
	if (numberOfArguments == 9999999) {
		interpreterProxy->success(0);
		return null;
	}
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) numberOfArguments));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveMethodSignatureGetReturnType(void) {
	NSMethodSignature* nsMethodSignatureObject;
	const char * string;
	sqInt stringOop;
	sqInt aMethodSignatureOop;

	aMethodSignatureOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	nsMethodSignatureObject = ((NSMethodSignature *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	string = null;
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	    NS_DURING;
	string = [nsMethodSignatureObject methodReturnType];
	    NS_HANDLER 
		string = nil;;
	    NS_ENDHANDLER;
	if (!(string)) {
		interpreterProxy->success(0);
		return null;
	}
	stringOop = stringFromCString(string);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, stringOop);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationCalloc(void) {
	void* pointer;
	sqInt size;
	sqInt _return_value;

	size = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	pointer = calloc(size,1);
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) pointer));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationFree(void) {
	void* pointerToFree;
	sqInt pointer;

	pointer = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	pointerToFree = ((void *) (interpreterProxy->positive64BitValueOf(pointer)));
	if (interpreterProxy->failed()) {
		return null;
	}
	free((void*)pointerToFree);
	;
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationGetArgument(void) {
	void * buffer;
	NSInvocation* nsInvocationInstance;
	sqInt aMethodSignatureOop;
	sqInt bufferOop;
	sqInt index;

	aMethodSignatureOop = interpreterProxy->stackValue(2);
	bufferOop = interpreterProxy->stackValue(1);
	index = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	nsInvocationInstance = ((NSInvocation *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	buffer = ((void *) (interpreterProxy->positive64BitValueOf(bufferOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	;
	    NS_DURING;
	[nsInvocationInstance getArgument: buffer atIndex: index];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(3);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationGetCType(void) {
	char * buffer;
	sqInt newCharacterOop;
	char targetOopData;
	sqInt bufferAddressOop;
	sqInt signedBoolean;

	bufferAddressOop = interpreterProxy->stackValue(1);
	signedBoolean = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	if (interpreterProxy->failed()) {
		return null;
	}
	buffer = ((char *) (interpreterProxy->positive64BitValueOf(bufferAddressOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	newCharacterOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classCharacter(), 1);
	targetOopData = 0;
	;
	if (signedBoolean) {
		targetOopData = *(char*) buffer;
		interpreterProxy->storeIntegerofObjectwithValue(0, newCharacterOop, ((sqInt) targetOopData));
	} else {
		targetOopData = *(char*) buffer;
		interpreterProxy->storeIntegerofObjectwithValue(0, newCharacterOop, ((usqInt) targetOopData));
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, newCharacterOop);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationGetCharPointerType(void) {
	char * buffer;
	char ** bufferPointer;
	sqInt stringOop;
	sqInt bufferAddressOop;

	bufferAddressOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	bufferPointer = ((char **) (interpreterProxy->positive64BitValueOf(bufferAddressOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	buffer = *bufferPointer;
	stringOop = stringFromCString(buffer);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, stringOop);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationGetClassType(void) {
	Class * buffer;
	Class data;
	sqInt bufferAddressOop;
	sqInt _return_value;

	bufferAddressOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	buffer = ((Class *) (interpreterProxy->positive64BitValueOf(bufferAddressOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	data = *buffer;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) data));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationGetDoubleType(void) {
	double * buffer;
	double data;
	sqInt bufferAddressOop;
	sqInt _return_value;

	bufferAddressOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	buffer = ((double *) (interpreterProxy->positive64BitValueOf(bufferAddressOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	data = *buffer;
	_return_value = interpreterProxy->floatObjectOf(data);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationGetFloatType(void) {
	float * buffer;
	float data;
	sqInt bufferAddressOop;
	sqInt _return_value;

	bufferAddressOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	buffer = ((float *) (interpreterProxy->positive64BitValueOf(bufferAddressOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	data = *buffer;
	_return_value = interpreterProxy->floatObjectOf(data);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationGetIntType(void) {
	int * buffer;
	int data;
	unsigned int unsignedData;
	sqInt bufferAddressOop;
	sqInt signedBoolean;
	sqInt _return_value;

	bufferAddressOop = interpreterProxy->stackValue(1);
	signedBoolean = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	if (interpreterProxy->failed()) {
		return null;
	}
	buffer = ((int *) (interpreterProxy->positive64BitValueOf(bufferAddressOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	unsignedData = data = 0;
	if (signedBoolean) {
		data = *buffer;
		_return_value = interpreterProxy->signed32BitIntegerFor(((sqInt) data));
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, _return_value);
		return null;
	} else {
		unsignedData = *(unsigned int *)buffer;
		_return_value = interpreterProxy->positive32BitIntegerFor(((usqInt) unsignedData));
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, _return_value);
		return null;
	}
}

EXPORT(sqInt) primitiveNSInvocationGetLongLongType(void) {
	long long * buffer;
	long long data;
	unsigned long long unsignedData;
	sqInt bufferAddressOop;
	sqInt signedBoolean;
	sqInt _return_value;

	bufferAddressOop = interpreterProxy->stackValue(1);
	signedBoolean = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	if (interpreterProxy->failed()) {
		return null;
	}
	buffer = ((long long *) (interpreterProxy->positive64BitValueOf(bufferAddressOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	unsignedData = data = 0;
	if (signedBoolean) {
		data = *buffer;
		_return_value = interpreterProxy->signed64BitIntegerFor(((long long) data));
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, _return_value);
		return null;
	} else {
		unsignedData = * (unsigned long long*) buffer;
		_return_value = interpreterProxy->positive64BitIntegerFor(((unsigned long long) unsignedData));
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, _return_value);
		return null;
	}
}

EXPORT(sqInt) primitiveNSInvocationGetLongType(void) {
	long * buffer;
	long data;
	unsigned long unsignedData;
	sqInt bufferAddressOop;
	sqInt signedBoolean;
	sqInt _return_value;

	bufferAddressOop = interpreterProxy->stackValue(1);
	signedBoolean = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	if (interpreterProxy->failed()) {
		return null;
	}
	buffer = ((long *) (interpreterProxy->positive64BitValueOf(bufferAddressOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	unsignedData = data = 0;
	if (signedBoolean) {
		data = *buffer;
		_return_value = interpreterProxy->signed64BitIntegerFor(((sqInt) data));
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, _return_value);
		return null;
	} else {
		unsignedData = *(unsigned long *) buffer;
		_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) unsignedData));
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, _return_value);
		return null;
	}
}

EXPORT(sqInt) primitiveNSInvocationGetObjectType(void) {
	id * buffer;
	id data;
	sqInt bufferAddressOop;
	sqInt _return_value;

	bufferAddressOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	buffer = ((id *) (interpreterProxy->positive64BitValueOf(bufferAddressOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	data = *buffer;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) data));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationGetReturnValue(void) {
	void * buffer;
	NSInvocation *nsInvoke;
	sqInt bufferAddressOop;
	sqInt aNSinvokeOops;

	bufferAddressOop = interpreterProxy->stackValue(1);
	aNSinvokeOops = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	buffer = ((void *) (interpreterProxy->positive64BitValueOf(bufferAddressOop)));
	nsInvoke = ((NSInvocation *) (interpreterProxy->positive64BitValueOf(aNSinvokeOops)));
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	    NS_DURING;
	[nsInvoke getReturnValue: buffer];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(2);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationGetSelectorType(void) {
	SEL * buffer;
	SEL data;
	sqInt bufferAddressOop;
	sqInt _return_value;

	bufferAddressOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	buffer = ((SEL *) (interpreterProxy->positive64BitValueOf(bufferAddressOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	data = *buffer;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) data));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationGetShortType(void) {
	short * buffer;
	short data;
	unsigned short unsignedData;
	sqInt bufferAddressOop;
	sqInt signedBoolean;
	sqInt _return_value;

	bufferAddressOop = interpreterProxy->stackValue(1);
	signedBoolean = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	if (interpreterProxy->failed()) {
		return null;
	}
	buffer = ((short *) (interpreterProxy->positive64BitValueOf(bufferAddressOop)));
	unsignedData = data = 0;
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	if (signedBoolean) {
		data = *buffer;
		_return_value = interpreterProxy->signed32BitIntegerFor(((sqInt) data));
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, _return_value);
		return null;
	} else {
		unsignedData = *(unsigned short *)buffer;
		_return_value = interpreterProxy->positive32BitIntegerFor(((usqInt) unsignedData));
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, _return_value);
		return null;
	}
}

EXPORT(sqInt) primitiveNSInvocationGetStructureType(void) {
	sqInt newByteArray;
	char ** bufferPointer;
	sqInt bufferAddressOop;
	sqInt length;

	bufferAddressOop = interpreterProxy->stackValue(1);
	length = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	bufferPointer = ((void *) (interpreterProxy->positive64BitValueOf(bufferAddressOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	newByteArray = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), length);
	memcpy(interpreterProxy->arrayValueOf(newByteArray), bufferPointer, length);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, newByteArray);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationMalloc(void) {
	void* pointer;
	sqInt size;
	sqInt _return_value;

	size = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	pointer = malloc(size);
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) pointer));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationSetCType(void) {
	void * buffer;
	unsigned char aUnsignedValue;
	char aValue;
	NSInvocation* nsInvocationInstance;
	sqInt aMethodSignatureOop;
	sqInt signedBoolean;
	sqInt index;
	sqInt newCharacterOop;
	sqInt _return_value;

	aMethodSignatureOop = interpreterProxy->stackValue(3);
	signedBoolean = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(2));
	index = interpreterProxy->stackIntegerValue(1);
	newCharacterOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	nsInvocationInstance = ((NSInvocation *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	aValue = interpreterProxy->fetchIntegerofObject(0, newCharacterOop);
	aUnsignedValue = interpreterProxy->fetchIntegerofObject(0, newCharacterOop);
	if (signedBoolean) {
		buffer = malloc(sizeof(char));
					*(char*) buffer = (char) aValue;
	} else {
		buffer = malloc(sizeof(unsigned char));
					*(unsigned char*)buffer = (unsigned char) aUnsignedValue;
	}
	;
	;
	    NS_DURING;
	[nsInvocationInstance setArgument: buffer atIndex: index];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) buffer));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(5, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationSetDoubleType(void) {
	void * buffer;
	NSInvocation* nsInvocationInstance;
	sqInt aMethodSignatureOop;
	sqInt index;
	double aValue;
	sqInt _return_value;

	aMethodSignatureOop = interpreterProxy->stackValue(2);
	index = interpreterProxy->stackIntegerValue(1);
	aValue = interpreterProxy->stackFloatValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	nsInvocationInstance = ((NSInvocation *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	buffer = malloc(sizeof(double));
				*(double*) buffer = (double) aValue;
	;
	;
	    NS_DURING;
	[nsInvocationInstance setArgument: buffer atIndex: index];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) buffer));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationSetFloatType(void) {
	void * buffer;
	NSInvocation* nsInvocationInstance;
	sqInt aMethodSignatureOop;
	sqInt index;
	double aValue;
	sqInt _return_value;

	aMethodSignatureOop = interpreterProxy->stackValue(2);
	index = interpreterProxy->stackIntegerValue(1);
	aValue = interpreterProxy->stackFloatValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	nsInvocationInstance = ((NSInvocation *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	buffer = malloc(sizeof(float));
				*(float*) buffer = (float) aValue;
	;
	;
	    NS_DURING;
	[nsInvocationInstance setArgument: buffer atIndex: index];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) buffer));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationSetIntType(void) {
	void * buffer;
	int aValue;
	NSInvocation* nsInvocationInstance;
	sqInt aMethodSignatureOop;
	sqInt signedBoolean;
	sqInt index;
	sqInt intValue;
	sqInt _return_value;

	aMethodSignatureOop = interpreterProxy->stackValue(3);
	signedBoolean = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(2));
	index = interpreterProxy->stackIntegerValue(1);
	intValue = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	nsInvocationInstance = ((NSInvocation *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	if (signedBoolean) {
		aValue = ((int) (interpreterProxy->signed64BitValueOf(intValue)));
		if (interpreterProxy->failed()) {
			return null;
		}
		buffer = malloc(sizeof(int));
						*(int*) buffer = (int) aValue;
	} else {
		aValue = ((unsigned int) (interpreterProxy->positive64BitValueOf(intValue)));
		if (interpreterProxy->failed()) {
			return null;
		}
		buffer = malloc(sizeof(unsigned int));
					*(unsigned int*)buffer = (unsigned int) aValue;
	}
	;
	;
	    NS_DURING;
	[nsInvocationInstance setArgument: buffer atIndex: index];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) buffer));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(5, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationSetLongLongType(void) {
	void * buffer;
	long long aValue;
	NSInvocation* nsInvocationInstance;
	sqInt aMethodSignatureOop;
	sqInt signedBoolean;
	sqInt index;
	sqInt intValue;
	sqInt _return_value;

	aMethodSignatureOop = interpreterProxy->stackValue(3);
	signedBoolean = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(2));
	index = interpreterProxy->stackIntegerValue(1);
	intValue = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	nsInvocationInstance = ((NSInvocation *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	if (signedBoolean) {
		aValue = ((long long) (interpreterProxy->signed64BitValueOf(intValue)));
		if (interpreterProxy->failed()) {
			return null;
		}
		buffer = malloc(sizeof(long long));
						*(long long*) buffer = (long long) aValue;
	} else {
		aValue = ((unsigned long long) (interpreterProxy->positive64BitValueOf(intValue)));
		if (interpreterProxy->failed()) {
			return null;
		}
		buffer = malloc(sizeof(unsigned long long));
					*(unsigned long long*)buffer = (unsigned long long) aValue;
	}
	;
	;
	    NS_DURING;
	[nsInvocationInstance setArgument: buffer atIndex: index];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) buffer));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(5, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationSetLongType(void) {
	void * buffer;
	long aValue;
	NSInvocation* nsInvocationInstance;
	sqInt aMethodSignatureOop;
	sqInt signedBoolean;
	sqInt index;
	sqInt intValue;
	sqInt _return_value;

	aMethodSignatureOop = interpreterProxy->stackValue(3);
	signedBoolean = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(2));
	index = interpreterProxy->stackIntegerValue(1);
	intValue = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	nsInvocationInstance = ((NSInvocation *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	if (signedBoolean) {
		aValue = ((long) (interpreterProxy->signed64BitValueOf(intValue)));
		if (interpreterProxy->failed()) {
			return null;
		}
		buffer = malloc(sizeof(long));
						*(long*) buffer = (long) aValue;
	} else {
		aValue = ((unsigned long) (interpreterProxy->positive64BitValueOf(intValue)));
		if (interpreterProxy->failed()) {
			return null;
		}
		buffer = malloc(sizeof(unsigned long));
					*(unsigned long*)buffer = (unsigned long) aValue;
	}
	;
	;
	    NS_DURING;
	[nsInvocationInstance setArgument: buffer atIndex: index];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) buffer));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(5, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationSetPointerType(void) {
	void ** buffer;
	void * aValue;
	NSInvocation* nsInvocationInstance;
	sqInt aMethodSignatureOop;
	sqInt index;
	sqInt pointerValue;
	sqInt _return_value;

	aMethodSignatureOop = interpreterProxy->stackValue(2);
	index = interpreterProxy->stackIntegerValue(1);
	pointerValue = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	nsInvocationInstance = ((NSInvocation *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	aValue = ((char *) (interpreterProxy->positive64BitValueOf(pointerValue)));
	if (interpreterProxy->failed()) {
		return null;
	}
	buffer = malloc(sizeof(void*));
		*buffer = aValue;
	;
	;
	    NS_DURING;
	[nsInvocationInstance setArgument: buffer atIndex: index];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) buffer));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationSetRetained(void) {
	NSInvocation* nsInvocationInstance;
	sqInt aMethodSignatureOop;

	aMethodSignatureOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	nsInvocationInstance = ((NSInvocation *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	    NS_DURING;
	[nsInvocationInstance retainArguments];
	    NS_HANDLER;
	interpreterProxy->success(0);
	    NS_ENDHANDLER;
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationSetSelector(void) {
	SEL selectorObject;
	id object1;
	NSInvocation *nsInvoke;
	sqInt aSelectorOop;
	sqInt object1Oops;
	sqInt aNSinvokeOops;

	aSelectorOop = interpreterProxy->stackValue(2);
	object1Oops = interpreterProxy->stackValue(1);
	aNSinvokeOops = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	selectorObject = ((SEL) (interpreterProxy->positive64BitValueOf(aSelectorOop)));
	object1 = ((id) (interpreterProxy->positive64BitValueOf(object1Oops)));
	nsInvoke = ((NSInvocation *) (interpreterProxy->positive64BitValueOf(aNSinvokeOops)));
	if (interpreterProxy->failed()) {
		return null;
	}
	    NS_DURING;
	[nsInvoke setSelector: selectorObject];
	[nsInvoke setTarget:  object1];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->pop(3);
		return null;
	}
	    NS_ENDHANDLER;
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(3);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationSetShortType(void) {
	void * buffer;
	short aValue;
	NSInvocation* nsInvocationInstance;
	sqInt aMethodSignatureOop;
	sqInt signedBoolean;
	sqInt index;
	sqInt intValue;
	sqInt _return_value;

	aMethodSignatureOop = interpreterProxy->stackValue(3);
	signedBoolean = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(2));
	index = interpreterProxy->stackIntegerValue(1);
	intValue = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	nsInvocationInstance = ((NSInvocation *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	if (signedBoolean) {
		aValue = ((short) (interpreterProxy->signed64BitValueOf(intValue)));
		if (interpreterProxy->failed()) {
			return null;
		}
		buffer = malloc(sizeof(short));
						*(short*) buffer = (short) aValue;
	} else {
		aValue = ((unsigned short) (interpreterProxy->positive64BitValueOf(intValue)));
		if (interpreterProxy->failed()) {
			return null;
		}
		buffer = malloc(sizeof(unsigned short));
					*(unsigned short*)buffer = (unsigned short) aValue;
	}
	;
	;
	    NS_DURING;
	[nsInvocationInstance setArgument: buffer atIndex: index];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) buffer));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(5, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationSetStringType(void) {
	char * buffer;
	sqInt stringSize;
	NSInvocation* nsInvocationInstance;
	sqInt aMethodSignatureOop;
	sqInt index;
	char *aValue;
	sqInt _return_value;

	aMethodSignatureOop = interpreterProxy->stackValue(2);
	index = interpreterProxy->stackIntegerValue(1);
	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	aValue = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	nsInvocationInstance = ((NSInvocation *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	stringSize = interpreterProxy->slotSizeOf((oopForPointer( aValue ) - BASE_HEADER_SIZE));
	buffer = malloc(stringSize + 1);
		memcpy(buffer,aValue,stringSize);
		buffer[stringSize] = 0x00;
	;
	;
	    NS_DURING;
	[nsInvocationInstance setArgument: &buffer atIndex: index];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) buffer));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationSetStructureType(void) {
	void * buffer;
	sqInt byteArraySize;
	NSInvocation* nsInvocationInstance;
	sqInt aMethodSignatureOop;
	sqInt index;
	char *aValue;
	sqInt _return_value;

	aMethodSignatureOop = interpreterProxy->stackValue(2);
	index = interpreterProxy->stackIntegerValue(1);
	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	aValue = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	nsInvocationInstance = ((NSInvocation *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	byteArraySize = interpreterProxy->slotSizeOf((oopForPointer( aValue ) - BASE_HEADER_SIZE));
	buffer = malloc(byteArraySize);
		memcpy(buffer,aValue,byteArraySize);
	;
	;
	;
	    NS_DURING;
	[nsInvocationInstance setArgument: buffer atIndex: index];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) buffer));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationSetVoidPointerType(void) {
	void * buffer;
	sqInt byteArraySize;
	NSInvocation* nsInvocationInstance;
	sqInt aMethodSignatureOop;
	sqInt index;
	char *aValue;
	sqInt _return_value;

	aMethodSignatureOop = interpreterProxy->stackValue(2);
	index = interpreterProxy->stackIntegerValue(1);
	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	aValue = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	nsInvocationInstance = ((NSInvocation *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	byteArraySize = interpreterProxy->slotSizeOf((oopForPointer( aValue ) - BASE_HEADER_SIZE));
	buffer = malloc(byteArraySize);
		memcpy(buffer,aValue,byteArraySize);
	;
	;
	;
	    NS_DURING;
	[nsInvocationInstance setArgument: &buffer atIndex: index];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) buffer));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSInvocationWithMethodSignature(void) {
	NSInvocation* nsInvocationOops;
	NSMethodSignature * methodSignatureOop;
	sqInt aMethodSignatureOop;
	sqInt _return_value;

	aMethodSignatureOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	methodSignatureOop = ((NSMethodSignature *) (interpreterProxy->positive64BitValueOf(aMethodSignatureOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	nsInvocationOops = 0;
	    NS_DURING;
	nsInvocationOops = [NSInvocation invocationWithMethodSignature: methodSignatureOop];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) nsInvocationOops));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveNSLog(void) {
	id oop1;
	sqInt aNSStringOOP;

	aNSStringOOP = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	oop1 = ((id) (interpreterProxy->positive64BitValueOf(aNSStringOOP)));
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	NSLog(oop1);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitiveNSStringToUTF8(void) {
	sqInt utf8StringOop;
	NSString* nsStringObject;
	const char * utf8String;
	sqInt aNSStringOop;

	aNSStringOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	nsStringObject = ((NSString *) (interpreterProxy->positive64BitValueOf(aNSStringOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	utf8String = null;
	;
	    NS_DURING;
	utf8String = [nsStringObject UTF8String];
	    NS_HANDLER 
		utf8String = nil;;
	    NS_ENDHANDLER;
	if (!(utf8String)) {
		interpreterProxy->success(0);
		return null;
	}
	utf8StringOop = stringFromCString(utf8String);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, utf8StringOop);
	return null;
}


/*	- (id)performSelector:(SEL)aSelector */

EXPORT(sqInt) primitivePerformSelector(void) {
	SEL selectorObject;
	id classOrInstanceObject;
	id returnValue;
	sqInt aSelectorOop;
	sqInt aClassOrInstanceOop;
	sqInt _return_value;

	aSelectorOop = interpreterProxy->stackValue(1);
	aClassOrInstanceOop = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	classOrInstanceObject = ((id) (interpreterProxy->positive64BitValueOf(aClassOrInstanceOop)));
	selectorObject = ((SEL) (interpreterProxy->positive64BitValueOf(aSelectorOop)));
	if (interpreterProxy->failed()) {
		return null;
	}
	returnValue = null;
	;
	;
	    NS_DURING;
	returnValue = [classOrInstanceObject performSelector: selectorObject];
	    NS_HANDLER 
		returnValue = nil;;
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) returnValue));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}


/*	- (id)performSelector:(SEL)aSelector */

EXPORT(sqInt) primitivePerformSelectorOnMainThreadWithWaitTilDone(void) {
	SEL selectorObject;
	id classOrInstanceObject;
	id object1;
	void *returnAddress;
	sqInt aSelectorOop;
	sqInt aClassOrInstanceOop;
	sqInt anObject1;
	sqInt aReturnValueAddress;
	sqInt doneFlag;

	aSelectorOop = interpreterProxy->stackValue(4);
	aClassOrInstanceOop = interpreterProxy->stackValue(3);
	anObject1 = interpreterProxy->stackValue(2);
	aReturnValueAddress = interpreterProxy->stackValue(1);
	doneFlag = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	if (interpreterProxy->failed()) {
		return null;
	}
	classOrInstanceObject = ((id) (interpreterProxy->positive64BitValueOf(aClassOrInstanceOop)));
	selectorObject = ((SEL) (interpreterProxy->positive64BitValueOf(aSelectorOop)));
	object1 = ((id) (interpreterProxy->positive64BitValueOf(anObject1)));
	returnAddress = ((void *) (interpreterProxy->positive64BitValueOf(aReturnValueAddress)));
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	;
	;
	;
	    NS_DURING;
	[classOrInstanceObject performSelectorOnMainThread: selectorObject withObject: object1 waitUntilDone: doneFlag  ];
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	    NS_DURING;
	if (returnAddress != 0) {
		[classOrInstanceObject getReturnValue: returnAddress];
	}
	    NS_HANDLER;
	interpreterProxy->success(0);
	if (1) {
		return null;
	}
	    NS_ENDHANDLER;
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(5);
	return null;
}


/*	- (id)performSelector:(SEL)aSelector */

EXPORT(sqInt) primitivePerformSelectorWith(void) {
	SEL selectorObject;
	id object1;
	id classOrInstanceObject;
	id returnValue;
	sqInt aSelectorOop;
	sqInt aClassOrInstanceOop;
	sqInt anObject1;
	sqInt _return_value;

	aSelectorOop = interpreterProxy->stackValue(2);
	aClassOrInstanceOop = interpreterProxy->stackValue(1);
	anObject1 = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	classOrInstanceObject = ((id) (interpreterProxy->positive64BitValueOf(aClassOrInstanceOop)));
	selectorObject = ((SEL) (interpreterProxy->positive64BitValueOf(aSelectorOop)));
	object1 = ((id) (interpreterProxy->positive64BitValueOf(anObject1)));
	if (interpreterProxy->failed()) {
		return null;
	}
	returnValue = null;
	;
	;
	;
	    NS_DURING;
	returnValue = [classOrInstanceObject performSelector: selectorObject withObject: object1];
	    NS_HANDLER 
		returnValue = nil;;
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) returnValue));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}


/*	- (id)performSelector:(SEL)aSelector */

EXPORT(sqInt) primitivePerformSelectorWithWith(void) {
	SEL selectorObject;
	id object1;
	id classOrInstanceObject;
	id returnValue;
	id object2;
	sqInt aSelectorOop;
	sqInt aClassOrInstanceOop;
	sqInt anObject1;
	sqInt anObject2;
	sqInt _return_value;

	aSelectorOop = interpreterProxy->stackValue(3);
	aClassOrInstanceOop = interpreterProxy->stackValue(2);
	anObject1 = interpreterProxy->stackValue(1);
	anObject2 = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	classOrInstanceObject = ((id) (interpreterProxy->positive64BitValueOf(aClassOrInstanceOop)));
	selectorObject = ((SEL) (interpreterProxy->positive64BitValueOf(aSelectorOop)));
	object1 = ((id) (interpreterProxy->positive64BitValueOf(anObject1)));
	object2 = ((id) (interpreterProxy->positive64BitValueOf(anObject2)));
	if (interpreterProxy->failed()) {
		return null;
	}
	returnValue = null;
	;
	;
	;
	;
	    NS_DURING;
	returnValue = [classOrInstanceObject performSelector: selectorObject withObject: object1 withObject: object2 ];
	    NS_HANDLER 
		returnValue = nil;;
	    NS_ENDHANDLER;
	_return_value = interpreterProxy->positive64BitIntegerFor(((usqInt) returnValue));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(5, _return_value);
	return null;
}

EXPORT(sqInt) primitiveSELGetName(void) {
	SEL bufferPointer;
	sqInt stringOop;
	sqInt aSEL;

	aSEL = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	#define selgetName sel_getName
;
	bufferPointer = ((SEL) (interpreterProxy->positive64BitValueOf(aSEL)));
	if (interpreterProxy->failed()) {
		return null;
	}
	stringOop = stringFromCString(selgetName(bufferPointer));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, stringOop);
	return null;
}


/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(sqInt) setInterpreter(struct VirtualMachine* anInterpreter) {
	sqInt ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
	return ok;
}

static sqInt shutdownModule(void) {
	return 1;
}

static sqInt sqAssert(sqInt aBool) {
	/* missing DebugCode */;
}


/*	Answer a new String copied from a null-terminated C string.
	Caution: This may invoke the garbage collector. */

static sqInt stringFromCString(const char * aCString) {
	sqInt len;
	sqInt newString;

	len = ((sqInt) (strlen(aCString)));
	newString = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), len);
	strncpy(interpreterProxy->arrayValueOf(newString), aCString, len);
	return newString;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* ObjectiveCPlugin_exports[][3] = {
	{"ObjectiveCPlugin", "primitiveNSInvocationSetSelector", (void*)primitiveNSInvocationSetSelector},
	{"ObjectiveCPlugin", "primitiveNSInvocationGetDoubleType", (void*)primitiveNSInvocationGetDoubleType},
	{"ObjectiveCPlugin", "primitiveGetAddressFromEntryPointString", (void*)primitiveGetAddressFromEntryPointString},
	{"ObjectiveCPlugin", "primitiveGetObjCClassForString", (void*)primitiveGetObjCClassForString},
	{"ObjectiveCPlugin", "primitiveNSInvocationSetRetained", (void*)primitiveNSInvocationSetRetained},
	{"ObjectiveCPlugin", "primitiveNSInvocationGetLongType", (void*)primitiveNSInvocationGetLongType},
	{"ObjectiveCPlugin", "primitiveNSInvocationGetCType", (void*)primitiveNSInvocationGetCType},
	{"ObjectiveCPlugin", "primitiveNSInvocationSetShortType", (void*)primitiveNSInvocationSetShortType},
	{"ObjectiveCPlugin", "primitiveNSInvocationGetFloatType", (void*)primitiveNSInvocationGetFloatType},
	{"ObjectiveCPlugin", "primitivePerformSelectorWithWith", (void*)primitivePerformSelectorWithWith},
	{"ObjectiveCPlugin", "primitiveNSInvocationMalloc", (void*)primitiveNSInvocationMalloc},
	{"ObjectiveCPlugin", "primitiveNSInvocationSetLongLongType", (void*)primitiveNSInvocationSetLongLongType},
	{"ObjectiveCPlugin", "primitiveMethodSignatureGetMethodReturnLength", (void*)primitiveMethodSignatureGetMethodReturnLength},
	{"ObjectiveCPlugin", "primitiveNSStringToUTF8", (void*)primitiveNSStringToUTF8},
	{"ObjectiveCPlugin", "getModuleName", (void*)getModuleName},
	{"ObjectiveCPlugin", "primitiveNSInvocationGetLongLongType", (void*)primitiveNSInvocationGetLongLongType},
	{"ObjectiveCPlugin", "primitiveMethodSignatureGetReturnType", (void*)primitiveMethodSignatureGetReturnType},
	{"ObjectiveCPlugin", "primitiveSELGetName", (void*)primitiveSELGetName},
	{"ObjectiveCPlugin", "primitivePerformSelectorOnMainThreadWithWaitTilDone", (void*)primitivePerformSelectorOnMainThreadWithWaitTilDone},
	{"ObjectiveCPlugin", "primitiveNSInvocationSetDoubleType", (void*)primitiveNSInvocationSetDoubleType},
	{"ObjectiveCPlugin", "primitiveCallbackLeave", (void*)primitiveCallbackLeave},
	{"ObjectiveCPlugin", "primitiveNSInvocationGetReturnValue", (void*)primitiveNSInvocationGetReturnValue},
	{"ObjectiveCPlugin", "primitiveNSInvocationGetShortType", (void*)primitiveNSInvocationGetShortType},
	{"ObjectiveCPlugin", "primitiveNSInvocationSetStringType", (void*)primitiveNSInvocationSetStringType},
	{"ObjectiveCPlugin", "primitiveNSInvocationSetPointerType", (void*)primitiveNSInvocationSetPointerType},
	{"ObjectiveCPlugin", "primitiveNSInvocationGetObjectType", (void*)primitiveNSInvocationGetObjectType},
	{"ObjectiveCPlugin", "primitiveMethodSignatureGetArgumentType", (void*)primitiveMethodSignatureGetArgumentType},
	{"ObjectiveCPlugin", "primitiveNSInvocationSetStructureType", (void*)primitiveNSInvocationSetStructureType},
	{"ObjectiveCPlugin", "primitiveNSInvocationGetArgument", (void*)primitiveNSInvocationGetArgument},
	{"ObjectiveCPlugin", "primitiveGetSelectorForString", (void*)primitiveGetSelectorForString},
	{"ObjectiveCPlugin", "primitiveNSInvocationSetIntType", (void*)primitiveNSInvocationSetIntType},
	{"ObjectiveCPlugin", "primitiveGetNSStringForString", (void*)primitiveGetNSStringForString},
	{"ObjectiveCPlugin", "primitiveNSInvocationGetClassType", (void*)primitiveNSInvocationGetClassType},
	{"ObjectiveCPlugin", "primitiveNSInvocationCalloc", (void*)primitiveNSInvocationCalloc},
	{"ObjectiveCPlugin", "primitivePerformSelectorWith", (void*)primitivePerformSelectorWith},
	{"ObjectiveCPlugin", "primitiveIsEqual", (void*)primitiveIsEqual},
	{"ObjectiveCPlugin", "primitiveNSInvocationGetIntType", (void*)primitiveNSInvocationGetIntType},
	{"ObjectiveCPlugin", "primitiveGetMethodSignatureForSelector", (void*)primitiveGetMethodSignatureForSelector},
	{"ObjectiveCPlugin", "primitiveGetClass", (void*)primitiveGetClass},
	{"ObjectiveCPlugin", "primitiveNSInvocationSetLongType", (void*)primitiveNSInvocationSetLongType},
	{"ObjectiveCPlugin", "primitiveNSInvocationSetVoidPointerType", (void*)primitiveNSInvocationSetVoidPointerType},
	{"ObjectiveCPlugin", "primitiveNSInvocationFree", (void*)primitiveNSInvocationFree},
	{"ObjectiveCPlugin", "setInterpreter", (void*)setInterpreter},
	{"ObjectiveCPlugin", "primitiveMethodSignatureGetNumberOfArguments", (void*)primitiveMethodSignatureGetNumberOfArguments},
	{"ObjectiveCPlugin", "primitiveNSInvocationGetSelectorType", (void*)primitiveNSInvocationGetSelectorType},
	{"ObjectiveCPlugin", "primitiveNSInvocationSetCType", (void*)primitiveNSInvocationSetCType},
	{"ObjectiveCPlugin", "primitivePerformSelector", (void*)primitivePerformSelector},
	{"ObjectiveCPlugin", "primitiveNSLog", (void*)primitiveNSLog},
	{"ObjectiveCPlugin", "primitiveNSInvocationWithMethodSignature", (void*)primitiveNSInvocationWithMethodSignature},
	{"ObjectiveCPlugin", "primitiveGetAutoReleasePool", (void*)primitiveGetAutoReleasePool},
	{"ObjectiveCPlugin", "primitiveGetDescription", (void*)primitiveGetDescription},
	{"ObjectiveCPlugin", "primitiveNSInvocationGetCharPointerType", (void*)primitiveNSInvocationGetCharPointerType},
	{"ObjectiveCPlugin", "primitiveGetSuperClass", (void*)primitiveGetSuperClass},
	{"ObjectiveCPlugin", "primitiveNSInvocationSetFloatType", (void*)primitiveNSInvocationSetFloatType},
	{"ObjectiveCPlugin", "primitiveNSInvocationGetStructureType", (void*)primitiveNSInvocationGetStructureType},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

