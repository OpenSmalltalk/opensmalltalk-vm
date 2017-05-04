"
This subclass is for the Win64 x86-64 ABI.  The Win64 ABI uses 4 integer registers or 4 double-precision floating-point registers or a mix of the two.  See w.g. https://msdn.microsoft.com/en-us/library/ms235286.aspx, or google for ""Overview of x64 Calling Conventions - MSDN - Microsoft"".

Note that unlike the System V x86-64 ABI, the Win64 ABI does /not/ decompose structs passed by value across available parameter registers.
"
Class {
	#name : #ThreadedX64Win64FFIPlugin,
	#superclass : #ThreadedX64FFIPlugin,
	#category : 'VMMaker-Plugins-FFI'
}

{ #category : #translation }
ThreadedX64Win64FFIPlugin class >> calloutStateClass [
	^ThreadedFFICalloutStateForX64Win64
]

{ #category : #translation }
ThreadedX64Win64FFIPlugin class >> identifyingPredefinedMacros [
	"Answer the predefined macros that identify the platforms a subclass handles, if any.
	 If the subclass isn't yet ready for production (a work in progress) simply answer nil."
	^#('x86_64' '__amd64' '__x86_64' '__amd64__' '__x86_64__' '_M_AMD64' '_M_X64')
]

{ #category : #translation }
ThreadedX64Win64FFIPlugin class >> includingPredefinedMacros [
	"Answer the predefined macros that qualify the platforms a subclass handles, if any.
	 These are anded together and with excludingPredefinedMacros, whereas
	 identifyingPredefinedMacros are ored together.
	 This can be used to differentiate e.g. x64 Sys V from x64 Win64."
	^#('WIN64')
]

{ #category : #'class initialization' }
ThreadedX64Win64FFIPlugin class >> initialize [
	WordSize := 8.
	NumIntRegArgs := 4.
	NumFloatRegArgs := 4
]

{ #category : #translation }
ThreadedX64Win64FFIPlugin class >> moduleName [
	^'X64Win64FFIPlugin'
]

{ #category : #accessing }
ThreadedX64Win64FFIPlugin class >> numFloatRegArgs [
	^NumFloatRegArgs
]

{ #category : #accessing }
ThreadedX64Win64FFIPlugin class >> numRegArgs [
	^NumIntRegArgs
]

{ #category : #'callout support' }
ThreadedX64Win64FFIPlugin >> ffiCalloutTo: procAddr SpecOnStack: specOnStack in: calloutState [
	<var: #procAddr type: #'void *'>
	<var: #calloutState type: #'CalloutState *'>
	<var: #loadFloatRegs declareC: 'extern void loadFloatRegs(double, double, double, double)'>
	"Go out, call this guy and create the return value.  This *must* be inlined because of
	 the alloca of the outgoing stack frame in ffiCall:WithFlags:NumArgs:Args:AndTypes:"
	| myThreadIndex atomicType floatRet intRet loadFloatRegs |
	<var: #floatRet type: #double>
	<var: #intRet type: #usqLong>
	<inline: true>
	self cCode: '' inSmalltalk: [loadFloatRegs := #used. loadFloatRegs class].
	self maybeDisownVM: calloutState threadIndexInto: [:threadIndex| myThreadIndex := threadIndex].

	calloutState floatRegisterSignature > 0 ifTrue:
		[self 
			load: (calloutState floatRegisters at: 0)
			Flo: (calloutState floatRegisters at: 1)
			at: (calloutState floatRegisters at: 2)
			Re: (calloutState floatRegisters at: 3)
			gs: (calloutState floatRegisters at: 4)].

	(self allocaLiesSoSetSpBeforeCall or: [self mustAlignStack]) ifTrue:
		[self setsp: calloutState argVector].

	atomicType := self atomicTypeOf: calloutState ffiRetHeader.
	(atomicType >> 1) = (FFITypeSingleFloat >> 1) ifTrue:
		[atomicType = FFITypeSingleFloat
			ifTrue:
				[floatRet := self 
					dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'float (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)') 
					with: (calloutState integerRegisters at: 0)
					with: (calloutState integerRegisters at: 1)
					with: (calloutState integerRegisters at: 2)
					with: (calloutState integerRegisters at: 3)]
			ifFalse: "atomicType = FFITypeDoubleFloat"
				[floatRet := self 
					dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'double (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)') 
					with: (calloutState integerRegisters at: 0)
					with: (calloutState integerRegisters at: 1)
					with: (calloutState integerRegisters at: 2)
					with: (calloutState integerRegisters at: 3)].

		 "undo any callee argument pops because it may confuse stack management with the alloca."
		 (self isCalleePopsConvention: calloutState callFlags) ifTrue:
			[self setsp: calloutState argVector].
		 self maybeOwnVM: calloutState threadIndex: myThreadIndex.

		 ^interpreterProxy floatObjectOf: floatRet].

	intRet := self 
				dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'usqIntptr_t (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)') 
				with: (calloutState integerRegisters at: 0)
				with: (calloutState integerRegisters at: 1)
				with: (calloutState integerRegisters at: 2)
				with: (calloutState integerRegisters at: 3).

	"undo any callee argument pops because it may confuse stack management with the alloca."
	(self isCalleePopsConvention: calloutState callFlags) ifTrue:
		[self setsp: calloutState argVector].
	self maybeOwnVM: calloutState threadIndex: myThreadIndex.

	(calloutState ffiRetHeader anyMask: FFIFlagPointer+FFIFlagStructure) ifTrue:
		["Note: Order is important here since FFIFlagPointer + FFIFlagStructure is used to represent
		 'typedef void* VoidPointer' and VoidPointer must be returned as pointer *not* as struct."
		 (calloutState ffiRetHeader anyMask: FFIFlagPointer) ifTrue:
			[^self ffiReturnPointer: intRet ofType: (self ffiReturnType: specOnStack) in: calloutState].
		 ^self ffiReturnStruct: intRet ofType: (self ffiReturnType: specOnStack) in: calloutState].
	
	^self ffiCreateIntegralResultOop: intRet ofAtomicType: atomicType in: calloutState
]

{ #category : #marshalling }
ThreadedX64Win64FFIPlugin >> ffiPushStructure: pointer ofSize: structSize typeSpec: argSpec ofLength: argSpecSize in: calloutState [
	<var: #pointer type: #'void *'>
	<var: #argSpec type: #'sqInt *'>
	<var: #calloutState type: #'CalloutState *'>
	<var: #arg type: #usqLong>
	<inline: true>
	structSize <= 0 ifTrue:
		[^FFIErrorStructSize].
	(structSize <= WordSize
	 and: [(structSize bitAnd: structSize - 1) = 0 "a.k.a. structSize isPowerOfTwo"]) ifTrue:
		[| arg |
		self mem: (self addressOf: arg) cp: pointer y: structSize.
		^self ffiPushUnsignedLongLong: arg in: calloutState].

	"For now just push the pointer; we should copy the struct to the outgoing stack frame!!"
	self flag: 'quick hack'.
	^self ffiPushPointer: pointer in: calloutState
]

{ #category : #'callout support' }
ThreadedX64Win64FFIPlugin >> ffiReturnStruct: intRet ofType: ffiRetType in: calloutState [
	<var: #intRet type: #usqLong>
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
				ifTrue: [self addressOf: intRet]
				ifFalse: [calloutState limit])
		 y: calloutState structReturnSize.
	interpreterProxy storePointer: 0 ofObject: retOop withValue: oop.
	^retOop
]

{ #category : #marshalling }
ThreadedX64Win64FFIPlugin >> returnStructInRegisters: returnStructSize [
	"Answer if a struct result of a given size is returned in memory or not."
	^returnStructSize <= WordSize and: ["returnStructSize isPowerOfTwo" (returnStructSize bitAnd: returnStructSize-1) = 0]
]
