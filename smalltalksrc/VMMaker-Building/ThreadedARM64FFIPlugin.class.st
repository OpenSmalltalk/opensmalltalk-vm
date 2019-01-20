"
A ThreadedARM64FFIPlugin is for the 64-bit ARM ABI.  It typically has 8 integer registers

Instance Variables

"
Class {
	#name : #ThreadedARM64FFIPlugin,
	#superclass : #ThreadedARMFFIPlugin,
	#category : #'VMMaker-Plugins-FFI'
}

{ #category : #translation }
ThreadedARM64FFIPlugin class >> calloutStateClass [
	^ThreadedFFICalloutStateForARM64
]

{ #category : #translation }
ThreadedARM64FFIPlugin class >> identifyingPredefinedMacros [
	^#('__ARM_ARCH_ISA_A64' '__aarch64__' '__arm64__' 'ARM64')
]

{ #category : #'class initialization' }
ThreadedARM64FFIPlugin class >> initialize [
	super initialize.
	NumIntRegArgs     := 8.
	NumFloatRegArgs := 16
]

{ #category : #translation }
ThreadedARM64FFIPlugin class >> moduleName [
	^'ARM64FFIPlugin'
]

{ #category : #'callout support' }
ThreadedARM64FFIPlugin >> ffiCalloutTo: procAddr SpecOnStack: specOnStack in: calloutState [
	<var: #procAddr type: #'void *'>
	<var: #calloutState type: #'CalloutState *'>
	<var: #loadFloatRegs declareC: 'extern void loadFloatRegs(double, double, double, double, double, double, double, double)'>
	"Go out, call this guy and create the return value.  This *must* be inlined because of
	 the alloca of the outgoing stack frame in ffiCall:WithFlags:NumArgs:Args:AndTypes:"
	| myThreadIndex atomicType floatRet intRet |
	<var: #floatRet type: #double>
	<var: #intRet type: #usqLong>
	<inline: true>
	myThreadIndex := interpreterProxy disownVM: (self disownFlagsFor: calloutState).

	calloutState floatRegisterIndex > 0 ifTrue:
		[self loadFloatRegs:
			   ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 0)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 2)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 4)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 6)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 8)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 10)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 12)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 14)) to: #'double *') at: 0)].

	(self allocaLiesSoSetSpBeforeCall or: [self mustAlignStack]) ifTrue:
		[self setsp: calloutState argVector].

	atomicType := self atomicTypeOf: calloutState ffiRetHeader.
	(atomicType >> 1) = (FFITypeSingleFloat >> 1) ifTrue:
		[atomicType = FFITypeSingleFloat
			ifTrue:
				[floatRet := self 
					dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'float (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)')
					with: (calloutState integerRegisters at: 0)
					with: (calloutState integerRegisters at: 1)
					with: (calloutState integerRegisters at: 2)
					with: (calloutState integerRegisters at: 3)
					with: (calloutState integerRegisters at: 4)
					with: (calloutState integerRegisters at: 5)
					with: (calloutState integerRegisters at: 6)
					with: (calloutState integerRegisters at: 7)]
			ifFalse: "atomicType = FFITypeDoubleFloat"
				[floatRet := self 
					dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'double (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)')
					with: (calloutState integerRegisters at: 0)
					with: (calloutState integerRegisters at: 1)
					with: (calloutState integerRegisters at: 2)
					with: (calloutState integerRegisters at: 3)
					with: (calloutState integerRegisters at: 4)
					with: (calloutState integerRegisters at: 5)
					with: (calloutState integerRegisters at: 6)
					with: (calloutState integerRegisters at: 7)].

		 "undo any callee argument pops because it may confuse stack management with the alloca."
		 (self isCalleePopsConvention: calloutState callFlags) ifTrue:
			[self setsp: calloutState argVector].
		 interpreterProxy ownVM: myThreadIndex.

		 ^interpreterProxy floatObjectOf: floatRet].

	intRet := self 
				dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'usqIntptr_t (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)')
				with: (calloutState integerRegisters at: 0)
				with: (calloutState integerRegisters at: 1)
				with: (calloutState integerRegisters at: 2)
				with: (calloutState integerRegisters at: 3)
				with: (calloutState integerRegisters at: 4)
				with: (calloutState integerRegisters at: 5)
				with: (calloutState integerRegisters at: 6)
				with: (calloutState integerRegisters at: 7).

	"undo any callee argument pops because it may confuse stack management with the alloca."
	(self isCalleePopsConvention: calloutState callFlags) ifTrue:
		[self setsp: calloutState argVector].
	interpreterProxy ownVM: myThreadIndex.

	(calloutState ffiRetHeader anyMask: FFIFlagPointer+FFIFlagStructure) ifTrue:
		["Note: Order is important here since FFIFlagPointer + FFIFlagStructure is used to represent
		 'typedef void* VoidPointer' and VoidPointer must be returned as pointer *not* as struct."
		 (calloutState ffiRetHeader anyMask: FFIFlagPointer) ifTrue:
			[^self ffiReturnPointer: intRet ofType: (self ffiReturnType: specOnStack) in: calloutState].
		 ^self ffiReturnStruct: intRet ofType: (self ffiReturnType: specOnStack) in: calloutState].
	
	^self ffiCreateIntegralResultOop: intRet ofAtomicType: atomicType in: calloutState
]

{ #category : #marshalling }
ThreadedARM64FFIPlugin >> ffiPushDoubleFloat: value in: calloutState [
	<var: #value type: #double>
	<var: #calloutState type: #'CalloutState *'>
	<inline: #always>

	calloutState floatRegisterIndex < (NumFloatRegArgs - 1)
		ifTrue:
			[(self cCoerceSimple: 
				(self addressOf: (calloutState floatRegisters at: calloutState floatRegisterIndex)) 
					 to: 'double*')
				at: 0
				put: value.
			 calloutState floatRegisterIndex: calloutState floatRegisterIndex + 2]
		ifFalse:
			[calloutState currentArg + self wordSize > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 calloutState floatRegisterIndex: NumFloatRegArgs.
			 interpreterProxy storeFloatAtPointer: calloutState currentArg from: value.
			 calloutState currentArg: calloutState currentArg + self wordSize].
	^0
]

{ #category : #marshalling }
ThreadedARM64FFIPlugin >> ffiPushSignedInt: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters 
				at: calloutState integerRegisterIndex 
				put: (self cCoerceSimple: value to: #sqLong).
			 calloutState integerRegisterIndex: calloutState integerRegisterIndex + 1]
		ifFalse:
			[calloutState currentArg + self wordSize > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: value.
			 calloutState currentArg: calloutState currentArg + self wordSize].
	^0

]

{ #category : #marshalling }
ThreadedARM64FFIPlugin >> ffiPushSignedLongLong: value in: calloutState [
	<var: #value type: #sqLong>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters 
				at: calloutState integerRegisterIndex 
				put: (self cCoerceSimple: value to: #sqLong).
			 calloutState integerRegisterIndex: calloutState integerRegisterIndex + 1]
		ifFalse:
			[calloutState currentArg + self wordSize > calloutState limit ifTrue: [^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: value.
			 calloutState currentArg: calloutState currentArg + self wordSize].
	^0
]

{ #category : #marshalling }
ThreadedARM64FFIPlugin >> ffiPushSingleFloat: value in: calloutState [
	<var: #value type: #float>
	<var: #calloutState type: #'CalloutState *'>
	<inline: #always>
	calloutState floatRegisterIndex < NumFloatRegArgs
		ifTrue: 
			[calloutState floatRegisters 
				at: calloutState floatRegisterIndex 
				put: (self cCoerceSimple: value to: #double).
			 calloutState floatRegisterIndex: calloutState floatRegisterIndex + 2]
		ifFalse:
			[calloutState currentArg + self wordSize > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy storeSingleFloatAtPointer: calloutState currentArg from: value.
			 calloutState currentArg: calloutState currentArg + self wordSize].
	^0
]

{ #category : #marshalling }
ThreadedARM64FFIPlugin >> ffiPushStructure: pointer ofSize: structSize typeSpec: argSpec ofLength: argSpecSize in: calloutState [
	<var: #pointer type: #'void *'>
	<var: #argSpec type: #'sqInt *'>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	| availableRegisterSpace stackPartSize roundedSize |

	availableRegisterSpace := (NumIntRegArgs - calloutState integerRegisterIndex) * self wordSize.
	stackPartSize := structSize.
	availableRegisterSpace > 0
		ifTrue: 
			[structSize <= availableRegisterSpace
				ifTrue:
					["all in registers"
					 stackPartSize := 0.
					 self 
						memcpy: (self cCoerceSimple: (self addressOf: (calloutState integerRegisters at: calloutState integerRegisterIndex)) to: 'void *') 
						_: pointer 
						_: structSize.
					 calloutState integerRegisterIndex: calloutState integerRegisterIndex + (structSize + 3 bitShift: -2) ]
				ifFalse:
					["If no previous co-processor candidate arg has already been pushed on the stack, then split the struct between registers and stack.
					  Otherwise push entire struct on stack."
					 calloutState currentArg = calloutState argVector
						ifTrue: 
					 		[stackPartSize := structSize - availableRegisterSpace.
					 		self 
								memcpy: (self cCoerceSimple: (self addressOf: (calloutState integerRegisters at: calloutState integerRegisterIndex)) to: 'void *') 
								_: pointer 
								_: availableRegisterSpace]
						ifFalse:
							[availableRegisterSpace := 0].
					calloutState integerRegisterIndex: NumIntRegArgs]].

	stackPartSize > 0
		ifTrue: 
			[roundedSize := stackPartSize + 3 bitClear: 3.
			 calloutState currentArg + roundedSize > calloutState limit ifTrue:
				 [^FFIErrorCallFrameTooBig].
			 self memcpy: calloutState currentArg _: (self addressOf: ((self cCoerceSimple: pointer to: 'char *') at: availableRegisterSpace)) _: stackPartSize.
			 calloutState currentArg: calloutState currentArg + roundedSize].
	^0
]

{ #category : #marshalling }
ThreadedARM64FFIPlugin >> ffiPushUnsignedInt: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters 
				at: calloutState integerRegisterIndex 
				put:  (self cCoerceSimple: value to: #usqLong).
			 calloutState integerRegisterIndex: calloutState integerRegisterIndex + 1]
		ifFalse:
			[calloutState currentArg + self wordSize > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: value.
			 calloutState currentArg: calloutState currentArg + self wordSize].
	^0


]

{ #category : #marshalling }
ThreadedARM64FFIPlugin >> ffiPushUnsignedLongLong: value in: calloutState [
	<var: #value type: #usqLong>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters 
				at: calloutState integerRegisterIndex 
				put:(self cCoerceSimple: value to: #usqLong).
			 calloutState integerRegisterIndex: calloutState integerRegisterIndex + 1]
		ifFalse:
			[calloutState currentArg + self wordSize > calloutState limit ifTrue: [^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: value.
			 calloutState currentArg: calloutState currentArg + self wordSize].
	^0

]

{ #category : #'simulation support' }
ThreadedARM64FFIPlugin >> wordSize [

	^ 8  "arm64/aarch64"
]
