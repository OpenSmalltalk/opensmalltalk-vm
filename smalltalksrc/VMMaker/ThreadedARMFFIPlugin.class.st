"
This subclass is for the 32-bit ARM ABI.  It typically has 4 integer registers.
"
Class {
	#name : #ThreadedARMFFIPlugin,
	#superclass : #ThreadedFFIPlugin,
	#classVars : [
		'NumFloatRegArgs',
		'NumIntRegArgs'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
ThreadedARMFFIPlugin class >> calloutStateClass [
	^ThreadedFFICalloutStateForARM
]

{ #category : #'class initialization' }
ThreadedARMFFIPlugin class >> initialize [
	NumIntRegArgs := 4.
	NumFloatRegArgs := 16
]

{ #category : #accessing }
ThreadedARMFFIPlugin class >> numFloatRegArgs [
	^NumFloatRegArgs
]

{ #category : #accessing }
ThreadedARMFFIPlugin class >> numIntRegArgs [
	^NumIntRegArgs
]

{ #category : #accessing }
ThreadedARMFFIPlugin class >> numRegArgs [
	^NumRegArgs
]

{ #category : #'callout support' }
ThreadedARMFFIPlugin >> dispatchFunctionPointer: aFunctionPointer with: int1 with: int2 with: int3 with: int4 [
	"In C aFunctionPointer is void (*aFunctionPointer)(int, int, int, int)"
	<cmacro: '(aFunctionPointer, int1, int2, int3, int4) (aFunctionPointer)(int1, int2, int3, int4)'>
	^self perform: aFunctionPointer
]

{ #category : #'callout support' }
ThreadedARMFFIPlugin >> dummyFloatFunction: d1 with: d2 with: d3 with: d4 with: d5 with: d6 with: d7 with: d8 [
	<var: #d1 type: #'double'>
	<var: #d2 type: #'double'>
	<var: #d3 type: #'double'>
	<var: #d4 type: #'double'>
	<var: #d5 type: #'double'>
	<var: #d6 type: #'double'>
	<var: #d7 type: #'double'>
	<var: #d8 type: #'double'>
	<returnTypeC: 'void'>
	<inline: false>


]

{ #category : #'callout support' }
ThreadedARMFFIPlugin >> ffiCalloutTo: procAddr SpecOnStack: specOnStack in: calloutState [
	<var: #procAddr type: #'void *'>
	<var: #calloutState type: #'CalloutState *'>
	"Go out, call this guy and create the return value.  This *must* be inlined because of
	 the alloca of the outgoing stack frame in ffiCall:WithFlags:NumArgs:Args:AndTypes:"
	| myThreadIndex atomicType floatRet intRet |
	<var: #floatRet type: #double>
	<var: #intRet type: #usqLong>
	<inline: true>
	self cppIf: COGMTVM ifTrue:
	[(calloutState callFlags anyMask: FFICallFlagThreaded) ifTrue:
		[myThreadIndex := interpreterProxy disownVM: 0]].

	self msg: 'calling out to C function'.

	self registerArgsSlop + self cStackAlignment > 0 ifTrue:
		[self setsp: calloutState argVector].

	calloutState floatRegisterIndex > 0
		ifTrue:
			[self 
				dummyFloatFunction: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 0)) to: 'double *') at: 0)
				with: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 2)) to: 'double *') at: 0)
				with: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 4)) to: 'double *') at: 0)
				with: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 6)) to: 'double *') at: 0)
				with: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 8)) to: 'double *') at: 0)
				with: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 10)) to: 'double *') at: 0)
				with: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 12)) to: 'double *') at: 0)
				with: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 14)) to: 'double *') at: 0)
			].

	atomicType := self atomicTypeOf: calloutState ffiRetHeader.
	atomicType = FFITypeSingleFloat
		ifTrue:
			[floatRet := self 
				dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'float (*)(int, int, int, int)') 
				with: (calloutState integerRegisters at: 0)
				with: (calloutState integerRegisters at: 1)
				with: (calloutState integerRegisters at: 2)
				with: (calloutState integerRegisters at: 3)].
	 atomicType = FFITypeDoubleFloat
		ifTrue:
			[floatRet := self 
				dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'double (*)(int, int, int, int)') 
				with: (calloutState integerRegisters at: 0)
				with: (calloutState integerRegisters at: 1)
				with: (calloutState integerRegisters at: 2)
				with: (calloutState integerRegisters at: 3)]
		ifFalse:
			[intRet := self 
				dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'usqLong (*)(int, int, int, int)') 
				with: (calloutState integerRegisters at: 0)
				with: (calloutState integerRegisters at: 1)
				with: (calloutState integerRegisters at: 2)
				with: (calloutState integerRegisters at: 3)].
	"undo any callee argument pops because it may confuse stack management with the alloca."
	(self isCalleePopsConvention: calloutState callFlags) ifTrue:
		[self setsp: calloutState argVector].

	self cppIf: COGMTVM ifTrue:
	[(calloutState callFlags anyMask: FFICallFlagThreaded) ifTrue:
		[interpreterProxy ownVM: myThreadIndex]].

	"Note: Order is important here since FFIFlagPointer + FFIFlagStructure is used to represent
	 'typedef void* VoidPointer' and VoidPointer must be returned as pointer *not* as struct."
	(calloutState ffiRetHeader anyMask: FFIFlagPointer) ifTrue:
		[^self ffiReturnPointer: intRet ofType: (self ffiReturnType: specOnStack) in: calloutState].

	(calloutState ffiRetHeader anyMask: FFIFlagStructure) ifTrue:
		[^self ffiReturnStruct: intRet ofType: (self ffiReturnType: specOnStack) in: calloutState].
	
	(atomicType = FFITypeSingleFloat
	 or: [atomicType = FFITypeDoubleFloat]) ifTrue:
		[^interpreterProxy methodReturnValue: (interpreterProxy floatObjectOf: floatRet)].

	^interpreterProxy methodReturnValue: (self ffiCreateIntegralResultOop: intRet
												ofAtomicType: atomicType
												in: calloutState)
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushDoubleFloat: value in: calloutState [
	<var: #value type: #double>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>

	calloutState floatRegisterIndex < (NumFloatRegArgs - 1)
		ifTrue:
			[(calloutState floatRegisterIndex bitAnd: 1) = 1
				ifTrue: 
					[calloutState backfillFloatRegisterIndex: calloutState floatRegisterIndex.
					 calloutState floatRegisterIndex: (calloutState floatRegisterIndex + 1)].
		  	 (self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: calloutState floatRegisterIndex)) 
				 	to: 'double*')
						at: 0
						put: value.
			 calloutState floatRegisterIndex: calloutState floatRegisterIndex + 2]
		ifFalse:
			[calloutState currentArg + 8 > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 calloutState floatRegisterIndex: NumFloatRegArgs.
			 interpreterProxy storeFloatAtPointer: calloutState currentArg from: value.
			 calloutState currentArg: calloutState currentArg + 8].
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushPointer: pointer in: calloutState [
	<var: #pointer type: #'void *'>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: pointer.
			 calloutState integerRegisterIndex: calloutState integerRegisterIndex + 1]
		ifFalse:
			[calloutState currentArg + 4 > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: pointer.
			 calloutState currentArg: calloutState currentArg + 4].
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushSignedByte: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: (self cCoerceSimple: value to: #'signed char').
			 calloutState integerRegisterIndex: calloutState integerRegisterIndex + 1]
		ifFalse:
			[calloutState currentArg + 4 > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: (self cCoerceSimple: value to: #'signed char').
			 calloutState currentArg: calloutState currentArg + 4].
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushSignedChar: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: (self cCoerceSimple: value to: #'signed char').
			 calloutState integerRegisterIndex: calloutState integerRegisterIndex + 1]
		ifFalse:
			[calloutState currentArg + 4 > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: (self cCoerceSimple: value to: #'signed char').
			 calloutState currentArg: calloutState currentArg + 4].
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushSignedInt: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: value.
			 calloutState integerRegisterIndex: calloutState integerRegisterIndex + 1]
		ifFalse:
			[calloutState currentArg + 4 > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: value.
			 calloutState currentArg: calloutState currentArg + 4].
	^0

]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushSignedLongLong: value in: calloutState [
	<var: #value type: #sqLong>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < (NumIntRegArgs - 1)
		ifTrue:
			[calloutState integerRegisterIndex: (calloutState integerRegisterIndex + 1 bitClear: 1).
			 calloutState integerRegisters at: calloutState integerRegisterIndex put: (self cCoerceSimple: value to: #usqInt).
			 calloutState integerRegisters at: calloutState integerRegisterIndex + 1 put: (self cCoerceSimple: value >> 32 to: #usqInt).
			 calloutState integerRegisterIndex: calloutState integerRegisterIndex + 2]
		ifFalse:
			[calloutState currentArg + 8 > calloutState limit ifTrue: [^FFIErrorCallFrameTooBig].
			 calloutState integerRegisterIndex: NumIntRegArgs.
			 interpreterProxy
				longAt: calloutState currentArg put: (self cCoerceSimple: value to: #usqInt);
				longAt: calloutState currentArg + 4 put: (self cCoerceSimple: value >> 32 to: #usqInt).
			 calloutState currentArg: calloutState currentArg + 8].
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushSignedShort: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: (self cCoerceSimple: value to: #'signed short').
			 calloutState integerRegisterIndex: calloutState integerRegisterIndex + 1]
		ifFalse:
			[calloutState currentArg + 4 > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: (self cCoerceSimple: value to: #'signed short').
			 calloutState currentArg: calloutState currentArg + 4].
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushSingleFloat: value in: calloutState [
	<var: #value type: #float>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState floatRegisterIndex < NumFloatRegArgs
		ifTrue: 
			[calloutState backfillFloatRegisterIndex > 0
				ifTrue: 
					[calloutState floatRegisters at: calloutState backfillFloatRegisterIndex  put: value.
					 calloutState backfillFloatRegisterIndex: 0]
				ifFalse: 
					[calloutState floatRegisters at: calloutState floatRegisterIndex  put: value.
					 calloutState floatRegisterIndex: calloutState floatRegisterIndex + 1]]
		ifFalse:
			[calloutState currentArg + 4 > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy storeSingleFloatAtPointer: calloutState currentArg from: value.
			 calloutState currentArg: calloutState currentArg + 4].
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushStructure: pointer ofSize: structSize typeSpec: argSpec ofLength: argSpecSize in: calloutState [
	<var: #pointer type: #'void *'>
	<var: #argSpec type: #'sqInt *'>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushUnsignedByte: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: (self cCoerceSimple: value to: #'unsigned char').
			 calloutState integerRegisterIndex: calloutState integerRegisterIndex + 1]
		ifFalse:
			[calloutState currentArg + 4 > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: (self cCoerceSimple: value to: #'unsigned char').
			 calloutState currentArg: calloutState currentArg + 4].
	^0

]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushUnsignedChar: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: (self cCoerceSimple: value to: #'unsigned char').
			 calloutState integerRegisterIndex: calloutState integerRegisterIndex + 1]
		ifFalse:
			[calloutState currentArg + 4 > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: (self cCoerceSimple: value to: #'unsigned char').
			 calloutState currentArg: calloutState currentArg + 4].
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushUnsignedInt: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: value.
			 calloutState integerRegisterIndex: calloutState integerRegisterIndex + 1]
		ifFalse:
			[calloutState currentArg + 4 > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: value.
			 calloutState currentArg: calloutState currentArg + 4].
	^0


]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushUnsignedLong: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushUnsignedLongLong: value in: calloutState [
	<var: #value type: #usqLong>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < (NumIntRegArgs - 1)
		ifTrue:
			[calloutState integerRegisterIndex: (calloutState integerRegisterIndex + 1 bitClear: 1).
			 calloutState integerRegisters at: calloutState integerRegisterIndex put: (self cCoerceSimple: value to: #usqInt).
			 calloutState integerRegisters at: calloutState integerRegisterIndex + 1 put: (self cCoerceSimple: value >> 32 to: #usqInt).
			 calloutState integerRegisterIndex: calloutState integerRegisterIndex + 2]
		ifFalse:
			[calloutState currentArg + 8 > calloutState limit ifTrue: [^FFIErrorCallFrameTooBig].
			 calloutState integerRegisterIndex: NumIntRegArgs.
			 interpreterProxy
				longAt: calloutState currentArg put: (self cCoerceSimple: value to: #usqInt);
				longAt: calloutState currentArg + 4 put: (self cCoerceSimple: value >> 32 to: #usqInt).
			 calloutState currentArg: calloutState currentArg + 8].
	^0

]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushUnsignedShort: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: (self cCoerceSimple: value to: #'unsigned short').
			 calloutState integerRegisterIndex: calloutState integerRegisterIndex + 1]
		ifFalse:
			[calloutState currentArg + 4 > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: (self cCoerceSimple: value to: #'unsigned short').
			 calloutState currentArg: calloutState currentArg + 4].
	^0
]

{ #category : #'callout support' }
ThreadedARMFFIPlugin >> ffiReturnStruct: longLongRet ofType: ffiRetType in: calloutState [
	<var: #longLongRet type: #usqLong>
	<var: #calloutState type: #'CalloutState *'>
	"Create a structure return value from an external function call.  The value as been stored in
	 alloca'ed space pointed to by the calloutState."
	| retOop retClass oop |
	<inline: true>
	retClass := interpreterProxy fetchPointer: 1 ofObject: ffiRetType.
	retOop := interpreterProxy instantiateClass: retClass indexableSize: 0.
	interpreterProxy pushRemappableOop: retOop.
	oop := interpreterProxy 
			instantiateClass: interpreterProxy classByteArray 
			indexableSize: calloutState structReturnSize.
	(self returnStructInRegisters: calloutState structReturnSize)
		ifTrue:
			[self mem: (interpreterProxy firstIndexableField: oop) cp: (self addressOf: longLongRet) y: calloutState structReturnSize]
		ifFalse:
			[self mem: (interpreterProxy firstIndexableField: oop) cp: calloutState limit y: calloutState structReturnSize].
	retOop := interpreterProxy popRemappableOop.
	interpreterProxy storePointer: 0 ofObject: retOop withValue: oop.
	^interpreterProxy methodReturnValue: retOop
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> registerArgsSlop [
	"Answer any space needed to prevent the alloca'ed outgoing arguments marshalling area from
	 being overwritten by any register arguments during calls during marshalling.  On ARM we
	 believe this is zero."
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> returnStructInRegisters: returnStructSize [
	"Answer if a struct result of a given size is returned in memory or not."
	^false
]
