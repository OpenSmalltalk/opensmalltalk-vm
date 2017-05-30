"
This subclass is for the System V x86-64 ABI.  The System V ABI uses 6 integer registers and 8 double-precision floating-point registers.  See http://www.x86-64.org/documentation/abi.pdf.  It seems that Mac OS X and linux use draft version 0.90, http://people.freebsd.org/~obrien/amd64-elf-abi.pdf.

Note that the System V x86-64 ABI decomposes structs of 2 eightbytes or smaller passed by value across available parameter registers.  double fields will be passed in an xmm register.
"
Class {
	#name : #ThreadedX64SysVFFIPlugin,
	#superclass : #ThreadedX64FFIPlugin,
	#category : #'VMMaker-Plugins-FFI'
}

{ #category : #translation }
ThreadedX64SysVFFIPlugin class >> ancilliaryClasses: options [
	^{ self calloutStateClass. ThreadedFFIX64SixteenByteReturn }
]

{ #category : #translation }
ThreadedX64SysVFFIPlugin class >> calloutStateClass [
	^ThreadedFFICalloutStateForX64SysV
]

{ #category : #translation }
ThreadedX64SysVFFIPlugin class >> excludingPredefinedMacros [
	"Answer the predefined macros that disqualify the platforms a subclass handles, if any.
	 This can be used to differentiate e.g. x64 Sys V from x64 Win64."
	^#('_WIN64')
]

{ #category : #translation }
ThreadedX64SysVFFIPlugin class >> identifyingPredefinedMacros [
	"Answer the predefined macros that identify the platforms a subclass handles, if any.
	 If the subclass isn't yet ready for production (a work in progress) simply answer nil."
	^#('x86_64' '__amd64' '__x86_64' '__amd64__' '__x86_64__')
]

{ #category : #'class initialization' }
ThreadedX64SysVFFIPlugin class >> initialize [
	WordSize := 8.
	NumIntRegArgs := 6.
	NumFloatRegArgs := 8
]

{ #category : #translation }
ThreadedX64SysVFFIPlugin class >> moduleName [
	^'X64SysVFFIPlugin'
]

{ #category : #accessing }
ThreadedX64SysVFFIPlugin class >> numFloatRegArgs [
	^NumFloatRegArgs
]

{ #category : #accessing }
ThreadedX64SysVFFIPlugin class >> numRegArgs [
	^NumIntRegArgs
]

{ #category : #'callout support' }
ThreadedX64SysVFFIPlugin >> ffiCalloutTo: procAddr SpecOnStack: specOnStack in: calloutState [
	<var: #procAddr type: #'void *'>
	<var: #calloutState type: #'CalloutState *'>
	<var: #loadFloatRegs declareC: 'extern void loadFloatRegs(double, double, double, double, double, double, double, double)'>
	"Go out, call this guy and create the return value.  This *must* be inlined because of
	 the alloca of the outgoing stack frame in ffiCall:WithFlags:NumArgs:Args:AndTypes:"
	| myThreadIndex atomicType floatRet intRet loadFloatRegs |
	<var: #floatRet type: #double>
	<var: #intRet type: #SixteenByteReturn>
	<inline: true>
	self cCode: '' inSmalltalk: [loadFloatRegs := #used. loadFloatRegs class].
	self maybeDisownVM: calloutState threadIndexInto: [:threadIndex| myThreadIndex := threadIndex].

	calloutState floatRegisterIndex > 0 ifTrue:
		[self 
			load: (calloutState floatRegisters at: 0)
			Flo: (calloutState floatRegisters at: 1)
			a: (calloutState floatRegisters at: 2)
			t: (calloutState floatRegisters at: 3)
			R: (calloutState floatRegisters at: 4)
			e: (calloutState floatRegisters at: 5)
			g: (calloutState floatRegisters at: 6)
			s: (calloutState floatRegisters at: 7)].

	(self allocaLiesSoSetSpBeforeCall or: [self mustAlignStack]) ifTrue:
		[self setsp: calloutState argVector].

	atomicType := self atomicTypeOf: calloutState ffiRetHeader.
	(atomicType >> 1) = (FFITypeSingleFloat >> 1) ifTrue:
		[atomicType = FFITypeSingleFloat
			ifTrue:
				[floatRet := self 
					dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'float (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)') 
					with: (calloutState integerRegisters at: 0)
					with: (calloutState integerRegisters at: 1)
					with: (calloutState integerRegisters at: 2)
					with: (calloutState integerRegisters at: 3)
					with: (calloutState integerRegisters at: 4)
					with: (calloutState integerRegisters at: 5)]
			ifFalse: "atomicType = FFITypeDoubleFloat"
				[floatRet := self 
					dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'double (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)') 
					with: (calloutState integerRegisters at: 0)
					with: (calloutState integerRegisters at: 1)
					with: (calloutState integerRegisters at: 2)
					with: (calloutState integerRegisters at: 3)
					with: (calloutState integerRegisters at: 4)
					with: (calloutState integerRegisters at: 5)].

		 self maybeOwnVM: calloutState threadIndex: myThreadIndex.

		 ^interpreterProxy floatObjectOf: floatRet].

	intRet := self 
				dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'SixteenByteReturn (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)') 
				with: (calloutState integerRegisters at: 0)
				with: (calloutState integerRegisters at: 1)
				with: (calloutState integerRegisters at: 2)
				with: (calloutState integerRegisters at: 3)
				with: (calloutState integerRegisters at: 4)
				with: (calloutState integerRegisters at: 5).

	self maybeOwnVM: calloutState threadIndex: myThreadIndex.

	(calloutState ffiRetHeader anyMask: FFIFlagPointer+FFIFlagStructure) ifTrue:
		["Note: Order is important here since FFIFlagPointer + FFIFlagStructure is used to represent
		 'typedef void* VoidPointer' and VoidPointer must be returned as pointer *not* as struct."
		 (calloutState ffiRetHeader anyMask: FFIFlagPointer) ifTrue:
			[^self ffiReturnPointer: intRet a ofType: (self ffiReturnType: specOnStack) in: calloutState].
		 ^self ffiReturnStruct: intRet ofType: (self ffiReturnType: specOnStack) in: calloutState].
	
	^self ffiCreateIntegralResultOop: intRet a ofAtomicType: atomicType in: calloutState
]

{ #category : #marshalling }
ThreadedX64SysVFFIPlugin >> ffiPushStructure: pointer ofSize: structSize typeSpec: argSpec ofLength: argSpecSize in: calloutState [
	<var: #pointer type: #'void *'>
	<var: #argSpec type: #'sqInt *'>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	| roundedSize doubleType floatType numDoubleRegisters numIntegerRegisters passField0InXmmReg passField1InXmmReg |
	structSize <= 16 ifTrue:
		["See sec 3.2.3 of http://people.freebsd.org/~obrien/amd64-elf-abi.pdf. (dravft version 0.90).
		  All of the folowing are passed in registers:
			typedef struct { long a; } s0;
			typedef struct { double a; } s1;
			typedef struct { long a; double b; } s2;
			typedef struct { int a; int b; double c; } s2a;
			typedef struct { short a; short b; short c; short d; double e; } s2b;
			typedef struct { long a; float b; } s2f;
			typedef struct { long a; float b; float c; } s2g;
		  but not ones like this:
			typedef struct { int a; float b; int c; float d; } s2h;"
		 doubleType := FFITypeDoubleFloat << FFIAtomicTypeShift + FFITypeDoubleFloat.
		 floatType := FFITypeDoubleFloat << FFIAtomicTypeShift + FFITypeSingleFloat.
		 passField0InXmmReg := doubleType = ((self cCoerce: argSpec to: #'int *') at: 1) "0th field is struct type and size"
								or: [floatType = ((self cCoerce: argSpec to: #'int *') at: 1)
									and: [floatType = ((self cCoerce: argSpec to: #'int *') at: 2)]].
		 structSize <= 8
			ifTrue:
				[numDoubleRegisters := passField0InXmmReg ifTrue: [1] ifFalse: [0].
				 numIntegerRegisters := 1 - numDoubleRegisters]
			ifFalse:
				[passField1InXmmReg := doubleType = ((self cCoerce: argSpec to: #'int *') at: argSpecSize - 1) "Nth field is last field of struct"
										or: [floatType = ((self cCoerce: argSpec to: #'int *') at: argSpecSize - 2)
											and: [floatType = ((self cCoerce: argSpec to: #'int *') at: argSpecSize - 1)]].
				 numDoubleRegisters := (passField0InXmmReg ifTrue: [1] ifFalse: [0]) + (passField1InXmmReg ifTrue: [1] ifFalse: [0]).
				 numIntegerRegisters := 2 - numDoubleRegisters].
		 (calloutState floatRegisterIndex + numDoubleRegisters <= NumFloatRegArgs
		  and: [calloutState integerRegisterIndex + numIntegerRegisters <= NumIntRegArgs]) ifTrue:
			[passField0InXmmReg
				ifTrue: [self ffiPushDoubleFloat: ((self cCoerceSimple: pointer to: #'double *') at: 0) in: calloutState]
				ifFalse: [self ffiPushSignedLongLong: ((self cCoerceSimple: pointer to: #'long long *') at: 0) in: calloutState].
			 structSize > 8 ifTrue:
				[passField1InXmmReg
					ifTrue: [self ffiPushDoubleFloat: ((self cCoerceSimple: pointer to: #'double *') at: 1) in: calloutState]
					ifFalse: [self ffiPushSignedLongLong: ((self cCoerceSimple: pointer to: #'long long *') at: 1) in: calloutState]].
			 ^0].

	roundedSize := structSize + 7 bitClear: 7.
	calloutState currentArg + roundedSize > calloutState limit ifTrue:
		 [^FFIErrorCallFrameTooBig].
	self mem: calloutState currentArg cp: (self cCoerceSimple: pointer to: 'char *') y: structSize.
	calloutState currentArg: calloutState currentArg + roundedSize].
	^0
]

{ #category : #'callout support' }
ThreadedX64SysVFFIPlugin >> ffiReturnStruct: sixteenByteRet ofType: ffiRetType in: calloutState [
	<var: #sixteenByteRet type: #SixteenByteReturn>
	<var: #calloutState type: #'CalloutState *'>
	"Create a structure return value from an external function call.  The value has been stored in
	 alloca'ed space pointed to by the calloutState or in the return value."
	| retOop retClass oop |
	<inline: true>
	retClass := interpreterProxy fetchPointer: 1 ofObject: ffiRetType.
	retOop := interpreterProxy instantiateClass: retClass indexableSize: 0.
	self remapOop: retOop
		in: [oop := interpreterProxy 
					instantiateClass: interpreterProxy classByteArray 
					indexableSize: calloutState structReturnSize].
	self mem: (interpreterProxy firstIndexableField: oop)
		cp: ((self returnStructInRegisters: calloutState structReturnSize)
				ifTrue: [(self addressOf: sixteenByteRet) asVoidPointer]
				ifFalse: [calloutState limit])
		 y: calloutState structReturnSize.
	interpreterProxy storePointer: 0 ofObject: retOop withValue: oop.
	^retOop
]

{ #category : #marshalling }
ThreadedX64SysVFFIPlugin >> returnStructInRegisters: returnStructSize [
	"Answer if a struct result of a given size is returned in memory or not."
	^returnStructSize <= (WordSize * 2)
]
