"
A ThreadedARM64FFIPlugin is for the 64-bit ARM ABI.  It typically has 8 integer registers

Instance Variables

"
Class {
	#name : #ThreadedARM64FFIPlugin,
	#superclass : #ThreadedARM32FFIPlugin,
	#category : #'VMMaker-Plugins-FFI'
}

{ #category : #translation }
ThreadedARM64FFIPlugin class >> calloutStateClass [
	^ThreadedFFICalloutStateForARM64
]

{ #category : #translation }
ThreadedARM64FFIPlugin class >> identifyingPredefinedMacros [
	^#('__ARM_ARCH_ISA_A64' '__aarch64__' '__arm64__' 'ARM64' '_M_ARM64')
]

{ #category : #'class initialization' }
ThreadedARM64FFIPlugin class >> initialize [
	super initialize.
	NumIntRegArgs    := 8.
	NumFloatRegArgs := 8
]

{ #category : #translation }
ThreadedARM64FFIPlugin class >> moduleName [
	^'ARM64FFIPlugin'
]

{ #category : #'callout support' }
ThreadedARM64FFIPlugin >> ffiCall: externalFunction ArgArrayOrNil: argArrayOrNil NumArgs: nArgs [
	"Generic callout. Does the actual work.  If argArrayOrNil is nil it takes args from the stack
	 and the spec from the method.  If argArrayOrNil is not nil takes args from argArrayOrNil
	 and the spec from the receiver."
	| flags argTypeArray address argType oop argSpec argClass err theCalloutState calloutState requiredStackSize stackSize allocation result primNumArgs |
	<inline: true>
	<var: #theCalloutState type: #'CalloutState'>
	<var: #calloutState type: #'CalloutState *'>
	<var: #allocation type: #'char *'>

	primNumArgs := interpreterProxy methodArgumentCount.
	(interpreterProxy is: externalFunction KindOfClass: interpreterProxy classExternalFunction) ifFalse:
		[^self ffiFail: FFIErrorNotFunction].
	"Load and check the values in the externalFunction before we call out"
	flags := interpreterProxy fetchInteger: ExternalFunctionFlagsIndex ofObject: externalFunction.
	interpreterProxy failed ifTrue:
		[^self ffiFail: FFIErrorBadArgs].

	"This must come early for compatibility with the old FFIPlugin.  Image-level code
	 may assume the function pointer is loaded eagerly.  Thanks to Nicolas Cellier."
	address := self ffiLoadCalloutAddress: externalFunction.
	interpreterProxy failed ifTrue:
		[^0 "error code already set by ffiLoadCalloutAddress:"].
	
	argTypeArray := interpreterProxy fetchPointer: ExternalFunctionArgTypesIndex ofObject: externalFunction.
	"must be array of arg types"
	((interpreterProxy isArray: argTypeArray)
	and: [(interpreterProxy slotSizeOf: argTypeArray) = (nArgs + 1)]) ifFalse:
		[^self ffiFail: FFIErrorBadArgs].
	"check if the calling convention is supported"
	self cppIf: COGMTVM
		ifTrue:
			[(self ffiSupportsCallingConvention: (flags bitAnd: FFICallTypesMask)) ifFalse:
				[^self ffiFail: FFIErrorCallType]]
		ifFalse: "not masking causes threaded calls to fail, which is as they should if the plugin is not threaded."
			[(self ffiSupportsCallingConvention: flags) ifFalse:
				[^self ffiFail: FFIErrorCallType]].
		
	requiredStackSize := self externalFunctionHasStackSizeSlot
							ifTrue: [interpreterProxy
										fetchInteger: ExternalFunctionStackSizeIndex
										ofObject: externalFunction]
							ifFalse: [-1].
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: (argArrayOrNil isNil
												ifTrue: [PrimErrBadMethod]
												ifFalse: [PrimErrBadReceiver])].
	stackSize := requiredStackSize < 0 ifTrue: [DefaultMaxStackSize] ifFalse: [requiredStackSize].
	self cCode: [] inSmalltalk: [theCalloutState := self class calloutStateClass new].
	calloutState := self addressOf: theCalloutState.
	self cCode: [self me: calloutState ms: 0 et: (self sizeof: #CalloutState)].
	calloutState callFlags: flags.
	"Fetch return type and args"
	argType := interpreterProxy fetchPointer: 0 ofObject: argTypeArray.
	argSpec := interpreterProxy fetchPointer: 0 ofObject: argType.
	argClass := interpreterProxy fetchPointer: 1 ofObject: argType.
	(err := self ffiCheckReturn: argSpec With: argClass in: calloutState) ~= 0 ifTrue:
		[^self ffiFail: err]. "cannot return"
	"alloca the outgoing stack frame, leaving room for marshalling args, and including space for the return struct, if any.
	Additional space reserved for saving register args like mandated by Win64 X64 or PPC ABI, will be managed by the call itself"
	allocation := self alloca: stackSize + calloutState structReturnSize + self cStackAlignment.
	self mustAlignStack ifTrue:
		[allocation := self cCoerce: (allocation asUnsignedIntegerPtr bitClear: self cStackAlignment - 1) to: #'char *'].
	calloutState
		argVector: allocation;
		currentArg: allocation;
		limit: allocation + stackSize.
	1 to: nArgs do:
		[:i|
		argType := interpreterProxy fetchPointer: i ofObject: argTypeArray.
		argSpec := interpreterProxy fetchPointer: 0 ofObject: argType.
		argClass := interpreterProxy fetchPointer: 1 ofObject: argType.
		oop := argArrayOrNil isNil
				ifTrue: [interpreterProxy stackValue: nArgs - i]
				ifFalse: [interpreterProxy fetchPointer: i - 1 ofObject: argArrayOrNil].
		err := self ffiArgument: oop Spec: argSpec Class: argClass in: calloutState.
		err ~= 0 ifTrue:
			[self cleanupCalloutState: calloutState.
			 self cppIf: COGMTVM ifTrue:
			 [err = PrimErrObjectMayMove negated ifTrue:
				[^PrimErrObjectMayMove]]. "N.B. Do not fail if object may move because caller will GC and retry."
			 ^self ffiFail: err]]. "coercion failed or out of stack space"
	"Failures must be reported back from ffiArgument:Spec:Class:in:.
	 Should not fail from here on in."
	self assert: interpreterProxy failed not.
	self ffiLogCallout: externalFunction.
	(requiredStackSize < 0
	 and: [self externalFunctionHasStackSizeSlot]) ifTrue:
		[stackSize := calloutState currentArg - calloutState argVector.
		 interpreterProxy storeInteger: ExternalFunctionStackSizeIndex ofObject: externalFunction withValue: stackSize].
	"Go out and call this guy"
	result := self ffiCalloutTo: address SpecOnStack: argArrayOrNil notNil in: calloutState.
	self cleanupCalloutState: calloutState.
	"Can not safely use argumentCount (via e.g. methodReturnValue:) since it may have been changed by a callback."
	interpreterProxy pop: primNumArgs + 1 thenPush: result. 
	^result
]

{ #category : #'callout support' }
ThreadedARM64FFIPlugin >> ffiCalloutTo: procAddr SpecOnStack: specOnStack in: calloutState [
	<var: #procAddr type: #'void *'>
	<var: #calloutState type: #'CalloutState *'>
	<var: #loadFloatRegs declareC: 'extern void loadFloatRegs(double, double, double, double, double, double, double, double)'>
	"Go out, call this guy and create the return value.  This *must* be inlined because of
	 the alloca of the outgoing stack frame in ffiCall:WithFlags:NumArgs:Args:AndTypes:"
	| myThreadIndex atomicType floatRet intRet x1Ret |
	<var: #floatRet type: #double>
	<var: #intRet type: #usqLong>
	<var: #x1Ret type: #usqLong>
	<inline: true>
	myThreadIndex := interpreterProxy disownVM: (self disownFlagsFor: calloutState).
	
	calloutState floatRegisterIndex > 0 ifTrue:
		[self loadFloatRegs:
			   (calloutState floatRegisters at: 0)
			_: (calloutState floatRegisters at: 1)
			_: (calloutState floatRegisters at: 2)
			_: (calloutState floatRegisters at: 3)
			_: (calloutState floatRegisters at: 4)
			_: (calloutState floatRegisters at: 5)
			_: (calloutState floatRegisters at: 6)
			_: (calloutState floatRegisters at: 7)].

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

	"If struct address used for return value, call is special"
	(self mustReturnStructOnStack: calloutState structReturnSize) 
	ifTrue: [
		intRet := 0.
		self setReturnRegister: (self cCoerceSimple: calloutState limit to: 'sqLong') "stack alloca'd struct"
			 andCall: (self cCoerceSimple: procAddr to: 'sqLong')
			 withArgsArray: (self cCoerceSimple: (self addressOf: calloutState integerRegisters) to: 'sqLong').
	] ifFalse: [
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
	
	 x1Ret := self getX1register. "Capture x1 immediately. No problem if unused"
	].
	"If struct returned in registers, 
	 place register values into calloutState integerRegisters"
	(calloutState structReturnSize > 0
	 and: [self returnStructInRegisters: calloutState structReturnSize]) ifTrue: 
		["Only 2 regs used in ARMv8/Aarch64 current"
		 calloutState integerRegisters at: 0 put: intRet. "X0"
		 calloutState integerRegisters at: 1 put: x1Ret]. "X1"

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

	calloutState floatRegisterIndex < NumFloatRegArgs
		ifTrue:
			[calloutState floatRegisters
				at: calloutState floatRegisterIndex
				put: value.
			 calloutState floatRegisterIndex: calloutState floatRegisterIndex + 1]
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
		ifTrue: "Note: this is a 'memcopy', so size is preserved. Casting to #double changes the size"
			[(self cCoerceSimple: 
				(self addressOf: (calloutState floatRegisters at: calloutState floatRegisterIndex)) 
					 to: 'float*')
				at: 0
				put: value.
			 calloutState floatRegisterIndex: calloutState floatRegisterIndex + 1]
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
						"Round structSize up and divide by 8 ( NB: _not_ 4 !)"
					 calloutState integerRegisterIndex: calloutState integerRegisterIndex + (structSize + 3 bitShift: -3) ]
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

{ #category : #'callout support' }
ThreadedARM64FFIPlugin >> ffiReturnStruct: longLongRet ofType: ffiRetType in: calloutState [
	<var: #longLongRet type: #usqLong>
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
	self memcpy: (interpreterProxy firstIndexableField: oop)
		_: ((self returnStructInRegisters: calloutState structReturnSize)
				ifTrue: [self addressOf: calloutState integerRegisters]
				ifFalse: [calloutState limit])
		 _: calloutState structReturnSize.
	interpreterProxy storePointer: 0 ofObject: retOop withValue: oop.
	^retOop
]

{ #category : #'callout support' }
ThreadedARM64FFIPlugin >> getX1register [

	<inline: true>
	<var: #returnX1value declareC: 'extern sqLong returnX1value()'>

	^self returnX1value
]

{ #category : #marshalling }
ThreadedARM64FFIPlugin >> mustReturnStructOnStack: returnStructSize [
	"Answer if a struct result of a given size is unable to be returned in registers."
	^returnStructSize > (2 * self wordSize)
]

{ #category : #marshalling }
ThreadedARM64FFIPlugin >> nonRegisterStructReturnIsViaImplicitFirstArgument [
	"Answer if a struct returned in memory is returned to the
	 referent of a pointer passed as an implciit first argument.
	 It almost always is.  Subclasses can override if not."
	^false
]

{ #category : #primitives }
ThreadedARM64FFIPlugin >> primitiveCallout [

	^ self ffiFail: FFINoCalloutAvailable
]

{ #category : #primitives }
ThreadedARM64FFIPlugin >> primitiveCalloutWithArgs [

	^ self ffiFail: FFINoCalloutAvailable
]

{ #category : #marshalling }
ThreadedARM64FFIPlugin >> returnStructInRegisters: returnStructSize [
	"Answer if a struct result of a given size is able to be returned in registers.
	NB: this is a predicate! #returnStructInRegisters: does NOT return a struct in anything!"
	^returnStructSize <= (2 * self wordSize)
]

{ #category : #'callout support' }
ThreadedARM64FFIPlugin >> setReturnRegister: structAddr andCall: procAddr withArgsArray: arrayAddr [

	<inline: true>
	<var: #structAddr type: #'sqLong'>
	<var: #procAddr  type: #'sqLong'>
	<var: #arrayAddr type: #'sqLong'>
	<var: #callAndReturnWithStructAddr declareC: 'extern void callAndReturnWithStructAddr(sqLong structAddr,sqLong procAddr,sqLong arrayAddr)'>

	self callAndReturnWithStructAddr: structAddr _: procAddr _: arrayAddr
]

{ #category : #'simulation support' }
ThreadedARM64FFIPlugin >> wordSize [

	^ 8  "arm64/aarch64"
]
