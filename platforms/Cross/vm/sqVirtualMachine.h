#ifndef _SqueakVM_H
#define _SqueakVM_H

/* Increment the following number if you change the order of
   functions listed or if you remove functions */
#define VM_PROXY_MAJOR 1

/* Note: You can define a different VM_PROXY_MINOR if the plugin
   should work with older VMs. */
#ifndef VM_PROXY_MINOR
/* Increment the following number if you add functions at the end */
#define VM_PROXY_MINOR 6
#endif

typedef int (*CompilerHook)();

struct VirtualMachine* sqGetInterpreterProxy(void);

typedef struct VirtualMachine {
	int (*minorVersion) (void);
	int (*majorVersion) (void);


	/* InterpreterProxy methodsFor: 'stack access' */

	int (*pop)(int nItems);
	int (*popthenPush)(int nItems, int oop);
	int (*push)(int object);
	int (*pushBool)(int trueOrFalse);
	int (*pushFloat)(double f);
	int (*pushInteger)(int integerValue);
	double (*stackFloatValue)(int offset);
	int (*stackIntegerValue)(int offset);
	int (*stackObjectValue)(int offset);
	int (*stackValue)(int offset);
	

	/* InterpreterProxy methodsFor: 'object access' */

	int (*argumentCountOf)(int methodPointer);
	void * (*arrayValueOf)(int oop);
	int (*byteSizeOf)(int oop);
	void * (*fetchArrayofObject)(int fieldIndex, int objectPointer);
	int (*fetchClassOf)(int oop);
	double (*fetchFloatofObject)(int fieldIndex, int objectPointer);
	int (*fetchIntegerofObject)(int fieldIndex, int objectPointer);
	int (*fetchPointerofObject)(int index, int oop);
	int (*fetchWordofObject)(int fieldIndex, int oop);
	void * (*firstFixedField)(int oop);
	void * (*firstIndexableField)(int oop);
	int (*literalofMethod)(int offset, int methodPointer);
	int (*literalCountOf)(int methodPointer);
	int (*methodArgumentCount)(void);
	int (*methodPrimitiveIndex)(void);
	int (*primitiveIndexOf)(int methodPointer);
	int (*sizeOfSTArrayFromCPrimitive)(void *cPtr);
	int (*slotSizeOf)(int oop);
	int (*stObjectat)(int array, int index);
	int (*stObjectatput)(int array, int index, int value);
	int (*stSizeOf)(int oop);
	int (*storeIntegerofObjectwithValue)(int index, int oop, int integer);
	int (*storePointerofObjectwithValue)(int index, int oop, int valuePointer);
	

	/* InterpreterProxy methodsFor: 'testing' */

	int (*isKindOf)(int oop, char *aString);
	int (*isMemberOf)(int oop, char *aString);
	int (*isBytes)(int oop);
	int (*isFloatObject)(int oop);
	int (*isIndexable)(int oop);
	int (*isIntegerObject)(int objectPointer);
	int (*isIntegerValue)(int intValue);
	int (*isPointers)(int oop);
	int (*isWeak)(int oop);
	int (*isWords)(int oop);
	int (*isWordsOrBytes)(int oop);
	

	/* InterpreterProxy methodsFor: 'converting' */

	int (*booleanValueOf)(int obj);
	int (*checkedIntegerValueOf)(int intOop);
	int (*floatObjectOf)(double aFloat);
	double (*floatValueOf)(int oop);
	int (*integerObjectOf)(int value);
	int (*integerValueOf)(int oop);
	int (*positive32BitIntegerFor)(int integerValue);
	int (*positive32BitValueOf)(int oop);
	

	/* InterpreterProxy methodsFor: 'special objects' */

	int (*characterTable)(void);
	int (*displayObject)(void);
	int (*falseObject)(void);
	int (*nilObject)(void);
	int (*trueObject)(void);
	

	/* InterpreterProxy methodsFor: 'special classes' */

	int (*classArray)(void);
	int (*classBitmap)(void);
	int (*classByteArray)(void);
	int (*classCharacter)(void);
	int (*classFloat)(void);
	int (*classLargePositiveInteger)(void);
	int (*classPoint)(void);
	int (*classSemaphore)(void);
	int (*classSmallInteger)(void);
	int (*classString)(void);
	

	/* InterpreterProxy methodsFor: 'instance creation' */

	int (*clone)(int oop);
	int (*instantiateClassindexableSize)(int classPointer, int size);
	int (*makePointwithxValueyValue)(int xValue, int yValue);
	int (*popRemappableOop)(void);
	int (*pushRemappableOop)(int oop);
	

	/* InterpreterProxy methodsFor: 'other' */

	int (*becomewith)(int array1, int array2);
	int (*byteSwapped)(int w);
	int (*failed)(void);
	int (*fullDisplayUpdate)(void);
	int (*fullGC)(void);
	int (*incrementalGC)(void);
	int (*primitiveFail)(void);
	int (*showDisplayBitsLeftTopRightBottom)(int aForm, int l, int t, int r, int b);
	int (*signalSemaphoreWithIndex)(int semaIndex);
	int (*success)(int aBoolean);
	int (*superclassOf)(int classPointer);

	/* InterpreterProxy methodsFor: 'compiler' */
	CompilerHook *(*compilerHookVector)(void);
	int (*setCompilerInitialized)(int initFlag);

#if VM_PROXY_MINOR > 1
	/* new for proxy 1.2 */
	/* InterpreterProxy methodsFor: 'BitBlt support' */
	int (*loadBitBltFrom)(int bbOop);
	int (*copyBits)(void);
	int (*copyBitsFromtoat)(int leftX, int rightX, int yValue);
#endif

#if VM_PROXY_MINOR > 2
	/* New for proxy version 1.3 */
	int (*classLargeNegativeInteger)(void);
	int (*signed32BitIntegerFor)(int integerValue);
	int (*signed32BitValueOf)(int oop);
	int (*includesBehaviorThatOf)(int aClass, int aSuperClass);
	int (*primitiveMethod) (void);

	/* InterpreterProxy methodsFor: 'FFI support' */
	int (*classExternalAddress)(void);
	int (*classExternalData)(void);
	int (*classExternalFunction)(void);
	int (*classExternalLibrary)(void);
	int (*classExternalStructure)(void);
	int (*ioLoadModuleOfLength)(int modIndex, int modLength);
	int (*ioLoadSymbolOfLengthFromModule)(int fnIndex, int fnLength, int handle);
	int (*isInMemory)(int address);
#endif

#if VM_PROXY_MINOR > 3
	/* New for proxy 1.4 */
	int (*ioLoadFunctionFrom)(char *fnName, char *modName);
	int (*ioMicroMSecs)(void);
#endif

#if VM_PROXY_MINOR > 4
	/* New for proxy 1.5 */
/* This is clearly a sub-optimal way to check for the ability to handle 64 bit
 * long long types but it suffices for the moment
 */
#ifdef  _MSC_VER
        #define squeakInt64 __int64
#else
        #define squeakInt64 long long
#endif
	int (*positive64BitIntegerFor)(squeakInt64 integerValue);
	squeakInt64 (*positive64BitValueOf)(int oop);
	int (*signed64BitIntegerFor)(squeakInt64 integerValue);
	squeakInt64 (*signed64BitValueOf)(int oop);
#endif

#if VM_PROXY_MINOR > 5
	/* new for 1.6 */
	int (*isArray)(int oop);
	int (*forceInterruptCheck)(void);
#endif

} VirtualMachine;

#endif /* _SqueakVM_H */

