Class {
	#name : #StackInterpreterPrimitives,
	#superclass : #StackInterpreter,
	#pools : [
		'LibFFIConstants',
		'VMBasicConstants'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> allocateParameters: anInteger using: allocationBlock [
	<inline: #always>

	anInteger = 0 ifTrue: [ ^ nil ].

	^ self
		cCode: [ allocationBlock value: anInteger ]
		inSmalltalk: [ | ptr | 
			ptr := allocationBlock value: anInteger.
			ptr setObject: (Array new: anInteger).
			ptr]
]

{ #category : #'primitive support' }
StackInterpreterPrimitives >> cloneContext: aContext [ 
	| sz cloned spouseFP sp |
	<var: #spouseFP type: #'char *'>
	sz := objectMemory numSlotsOf: aContext.
	cloned := objectMemory eeInstantiateMethodContextSlots: sz.
	cloned ~= 0 ifTrue:
		[0 to: StackPointerIndex do:
			[:i|
			objectMemory
				storePointerUnchecked: i
				ofObject: cloned
				withValue: (self externalInstVar: i ofContext: aContext)].
		MethodIndex to: ReceiverIndex do:
			[:i|
			objectMemory
				storePointerUnchecked: i
				ofObject: cloned
				withValue: (objectMemory fetchPointer: i ofObject: aContext)].
		(self isStillMarriedContext: aContext)
			ifTrue:
				[spouseFP := self frameOfMarriedContext: aContext.
				 sp := (self stackPointerIndexForFrame: spouseFP) - 1.
				 0 to: sp do:
					[:i|
					objectMemory
						storePointerUnchecked: i + CtxtTempFrameStart
						ofObject: cloned
						withValue: (self temporary: i in: spouseFP)]]
			ifFalse:
				[sp := (self fetchStackPointerOf: aContext) - 1.
				 0 to: sp do:
					[:i|
					objectMemory
						storePointerUnchecked: i + CtxtTempFrameStart
						ofObject: cloned
						withValue: (objectMemory fetchPointer: i + CtxtTempFrameStart ofObject: aContext)]]].
	^cloned
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> ffi_call: aCif _: externalFunctionAddress _: returnHolder _: parameters [

	<doNotGenerate>
	libFFI ffiCall: aCif _: externalFunctionAddress _: returnHolder _: parameters
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> field: index ofFrame: theFP [
	"Arrange to answer naked frame pointers for unmarried
	 senders to avoid reifying contexts in the search."
	<var: #theFP type: #'char *'>
	<inline: false>
	| callerFP |
	<var: #callerFP type: #'char *'>
	^index caseOf:
		{[SenderIndex] ->	[callerFP := self frameCallerFP: theFP.
							 callerFP = 0
								ifTrue: [self frameCallerContext: theFP]
								ifFalse: [(self frameHasContext: callerFP)
											ifTrue: [self assert: (self checkIsStillMarriedContext: (self frameContext: callerFP) currentFP: nil).
													self frameContext: callerFP]
											ifFalse: [callerFP asInteger]]].
		[StackPointerIndex]			->	[ConstZero].
		[InstructionPointerIndex]	->	[ConstZero].
		[MethodIndex]				->	[self frameMethodObject: theFP].
		[ClosureIndex]				->	[(self frameIsBlockActivation: theFP)
											ifTrue: [self frameStackedReceiver: theFP
														numArgs: (self frameNumArgs: theFP)]
											ifFalse: [objectMemory nilObject]].
		[ReceiverIndex]				->	[self frameReceiver: theFP] }
		otherwise:
			[self assert: (index - CtxtTempFrameStart between: 0 and: (self stackPointerIndexForFrame: theFP)).
			 self temporary: index - CtxtTempFrameStart in: theFP]
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> fieldOrSenderFP: index ofContext: contextObj [
	"Arrange to answer naked frame pointers for unmarried
	 senders to avoid reifying contexts in the search."
	<inline: false>
	| tempIndex spouseFP |
	<var: #spouseFP type: #'char *'>
	tempIndex := index - CtxtTempFrameStart.
	(self isStillMarriedContext: contextObj) ifFalse:
		[^tempIndex >= (self fetchStackPointerOf: contextObj)
			ifTrue: [objectMemory nilObject]
			ifFalse: [self fetchPointer: index ofObject: contextObj]].
	spouseFP := self frameOfMarriedContext: contextObj.
	tempIndex >= (self stackPointerIndexForFrame: spouseFP) ifTrue:
		[^objectMemory nilObject].
	^self field: index ofFrame: spouseFP
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> fieldsInFrame: theFP [
	<var: #theFP type: #'char *'>
	^CtxtTempFrameStart + (self stackPointerIndexForFrame: theFP)
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> frameIsMarked: theFPInt [
	^((stackPages longAt: theFPInt + FoxFrameFlags) bitAnd: 2) ~= 0
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> freeArgumentsArray: arguments count: count [

	0 to: count - 1 do: [ :i |  
		(arguments at: i) ifNotNil: [ :aPtr | 
			arguments at: i put: nil.
			self free: aPtr ]].
	
	self free: arguments.
	
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> getHandler: anOop [ 

	<api>
	<returnTypeC: #'void *'>

	((objectMemory isPointers: anOop) not or: [ (objectMemory slotSizeOf: anOop) < 1 ])
		ifTrue: [ self primitiveFail. ^ nil ].
		
	^ self readAddress: (objectMemory fetchPointer: 0 ofObject: anOop)

]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> getHandlerAsCif: anOop [

	^ self
		cCode: [ self cCoerce: (self getHandler: anOop) to: 'ffi_cif *' ]
		inSmalltalk: [ libFFI cifAtAddress: (self getHandler: anOop)]
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> getTaskFromAddress: anInteger [

	^ self
		  cCode: [ self cCoerce: anInteger to: #'WorkerTask *' ]
		  inSmalltalk: [ libFFI testWorker tasks detect: [ :e | e asInteger = anInteger ] ]
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> getWorkerFromAddress: anInteger [

	^ self
		  cCode: [ self cCoerce: anInteger to: #'Worker *' ]
		  inSmalltalk: [ 
			self assert: anInteger = libFFI testWorker asInteger.
			libFFI testWorker ]
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> ioLoadModule: moduleNameString OfLength: moduleNameStringSize [

	<doNotGenerate>
	^0
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> ioLoadSymbol: functionNameIndex OfLength: functionLength FromModule: moduleHandle [

	<doNotGenerate>
	^0
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> isAppropriateForCopyObject: oop [
	(objectMemory isPointersNonImm: oop) ifFalse:
		[^false].
	(objectMemory isContext: oop) ifTrue:
		[^(self isStillMarriedContext: oop) not].
	"Note there is no version in CoInterpreterPrimtiives such as
		(objectMemory isCompiledMethod: oop) ifTrue:
			[^(self methodHasCogMethod: oop) not].
	 because isPointersNonImm: excludes compiled methods and the
	 copy loop in primitiveCopyObject cannot handle compiled methods."
	^true
]

{ #category : #ffi }
StackInterpreterPrimitives >> loadModuleByName: moduleNameOop [

	<returnTypeC: #'void*'>
	<var: #moduleNameString type: #'char*'>
	| moduleNameString moduleNameStringSize |
	
	moduleNameString := objectMemory firstIndexableField: moduleNameOop.
	moduleNameStringSize := objectMemory byteSizeOf: moduleNameOop.
		
	^ self ioLoadModule: moduleNameString OfLength: moduleNameStringSize
]

{ #category : #logging }
StackInterpreterPrimitives >> logDebug: aString [

	<doNotGenerate>

	aString traceCr.
]

{ #category : #logging }
StackInterpreterPrimitives >> logDebug: aFormat _: aParameter [

	<doNotGenerate>

	(aFormat printf: { aParameter }) traceCr
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> markFrame: theFPInt [
	stackPages
		longAt: theFPInt + FoxFrameFlags
		put: ((stackPages longAt: theFPInt + FoxFrameFlags) bitOr: 2)
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> marshallAndPushReturnValueFrom: returnHolder ofType: ffiType poping: argumentsAndReceiverCount [

	<var: #ffiType type: #'ffi_type *'>

	[ ffiType type ]
		caseOf: {
			[ FFI_TYPE_SINT8 ] 	-> [ self pop: argumentsAndReceiverCount thenPushInteger: (objectMemory readSINT8AtPointer: returnHolder) ].
			[ FFI_TYPE_SINT16 ] 	-> [ self pop: argumentsAndReceiverCount thenPushInteger: (objectMemory readSINT16AtPointer: returnHolder) ].
			[ FFI_TYPE_SINT32 ] 	-> [ self pop: argumentsAndReceiverCount thenPushInteger: (objectMemory readSINT32AtPointer: returnHolder) ].
			[ FFI_TYPE_SINT64 ] 	-> [ self pop: argumentsAndReceiverCount thenPushInteger: (objectMemory readSINT64AtPointer: returnHolder) ].

			[ FFI_TYPE_UINT8 ] 	-> [ self pop: argumentsAndReceiverCount thenPushInteger: (objectMemory readUINT8AtPointer: returnHolder) ].
			[ FFI_TYPE_UINT16 ] 	-> [ self pop: argumentsAndReceiverCount thenPushInteger: (objectMemory readUINT16AtPointer: returnHolder) ].
			[ FFI_TYPE_UINT32 ] 	-> [ self pop: argumentsAndReceiverCount thenPushInteger: (objectMemory readUINT32AtPointer: returnHolder) ].
			[ FFI_TYPE_UINT64 ] 	-> [ self pop: argumentsAndReceiverCount thenPushInteger: (objectMemory readUINT64AtPointer: returnHolder) ].

			[ FFI_TYPE_POINTER ] 	-> [ self pop: argumentsAndReceiverCount thenPush: (objectMemory newExternalAddressWithValue: (objectMemory readPointerAtPointer: returnHolder)) ].

			[ FFI_TYPE_STRUCT ] 	-> [ self pop: argumentsAndReceiverCount thenPush: (self newByteArrayWithStructContent: returnHolder size: ffiType size) ].

			[ FFI_TYPE_FLOAT ] 	-> [ self pop: argumentsAndReceiverCount thenPushFloat: (objectMemory readFloat32AtPointer: returnHolder) ].
			[ FFI_TYPE_DOUBLE ] 	-> [ self pop: argumentsAndReceiverCount thenPushFloat: (objectMemory readFloat64AtPointer: returnHolder) ].
			[ FFI_TYPE_VOID ] 		-> [ self pop: argumentsAndReceiverCount - 1 "Pop the arguments leaving the receiver" ]}
			otherwise: [ self primitiveFailFor: PrimErrBadArgument ]

]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> marshallArgumentFrom: argumentsArrayOop atIndex: i into: argHolder ofType: argType withSize: argTypeSize [

	[ argType ]
		caseOf:
			{([ FFI_TYPE_POINTER ]
				-> [ self marshallPointerFrom: argumentsArrayOop at: i into: argHolder ]).
			([ FFI_TYPE_STRUCT ]
				-> [ self marshallStructFrom: argumentsArrayOop at: i into: argHolder withSize: argTypeSize ]).
			([ FFI_TYPE_FLOAT ]
				-> [ self marshallFloatFrom: argumentsArrayOop at: i into: argHolder ]).
			([ FFI_TYPE_DOUBLE ]
				-> [ self marshallDoubleFrom: argumentsArrayOop at: i into: argHolder ]).
			([ FFI_TYPE_SINT8 ]
				-> [ self marshallSInt8From: argumentsArrayOop at: i into: argHolder ]).
			([ FFI_TYPE_UINT8 ]
				-> [ self marshallUInt8From: argumentsArrayOop at: i into: argHolder ]).
			([ FFI_TYPE_SINT16 ]
				-> [ self marshallSInt16From: argumentsArrayOop at: i into: argHolder ]).
			([ FFI_TYPE_UINT16 ]
				-> [ self marshallUInt16From: argumentsArrayOop at: i into: argHolder ]).
			([ FFI_TYPE_SINT32 ]
				-> [ self marshallSInt32From: argumentsArrayOop at: i into: argHolder ]).
			([ FFI_TYPE_UINT32 ]
				-> [ self marshallUInt32From: argumentsArrayOop at: i into: argHolder ]).
			([ FFI_TYPE_SINT64 ]
				-> [ self marshallSInt64From: argumentsArrayOop at: i into: argHolder ]).
			([ FFI_TYPE_UINT64 ]
				-> [ self marshallUInt64From: argumentsArrayOop at: i into: argHolder ])}
		otherwise: [ self primitiveFailFor: PrimErrBadArgument ]
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> marshallDoubleFrom: argumentArrayOop at: index into: holder [ 

	| doubleHolder |
	doubleHolder := self cCoerce: holder to: #'double *'.
	
	doubleHolder at: 0 put: (self fetchFloat: index ofObject: argumentArrayOop ).

]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> marshallFloatFrom: argumentArrayOop at: index into: holder [ 
	
	| floatHolder |
	floatHolder := self cCoerce: holder to: #'float *'.
	
	floatHolder at: 0 put: (self fetchFloat: index ofObject: argumentArrayOop ).
	
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> marshallPointerFrom: argumentArrayOop at: index into: holder [ 
	
	| pointerHolder externalAddress |
	pointerHolder := self cCoerce: holder to: #'void **'.
	externalAddress := objectMemory fetchPointer: index ofObject: argumentArrayOop.
	pointerHolder at: 0 put: (self readAddress: externalAddress).
	
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> marshallSInt16From: argumentArrayOop at: index into: holder [

	| intHolder value |

	value := self fetchInteger: index ofObject: argumentArrayOop.	
	value > INT16_MAX ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	value < INT16_MIN ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	intHolder := self cCoerce: holder to: #'int16_t *'.
	intHolder at: 0 put: value.
		
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> marshallSInt32From: argumentArrayOop at: index into: holder [

	| intHolder value |

	value := self fetchInteger: index ofObject: argumentArrayOop.	
	value > INT32_MAX ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	value < INT32_MIN ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	intHolder := self cCoerce: holder to: #'int32_t *'.
	intHolder at: 0 put: (self fetchInteger: index ofObject: argumentArrayOop ).
		
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> marshallSInt64From: argumentArrayOop at: index into: holder [

	| intHolder |
	intHolder := self cCoerce: holder to: #'int64_t *'.
	intHolder at: 0 put: (self fetchInteger: index ofObject: argumentArrayOop ).
		
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> marshallSInt8From: argumentArrayOop at: index into: holder [

	| intHolder value |

	value := self fetchInteger: index ofObject: argumentArrayOop.	
	value > INT8_MAX ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	value < INT8_MIN ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	intHolder := self cCoerce: holder to: #'int8_t *'.
	intHolder at: 0 put: (self fetchInteger: index ofObject: argumentArrayOop ).
		
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> marshallStructFrom: argumentsArrayOop at: index into: holder withSize: typeSize [ 


	| address srcPtr oop |

	oop := objectMemory fetchPointer: index ofObject: argumentsArrayOop.
	
	(objectMemory fetchClassOf: oop) = objectMemory classExternalAddress
		ifTrue: [
				address := self readAddress: oop.
				address = 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ]]
		ifFalse: [  
			(objectMemory fetchClassOf: oop) = objectMemory classByteArray 
				ifFalse: [ ^ self primitiveFailFor: PrimErrBadArgument  ].
				address := objectMemory firstIndexableField: oop ].
	
	srcPtr := objectMemory cCoerce: address to: 'void *'.
	
	self 
		cCode:  [ objectMemory memcpy: holder _:  srcPtr _: typeSize ]
		inSmalltalk: [ 
			holder object 
				replaceFrom: 1 to: typeSize 
				with: (objectMemory cCoerce: srcPtr to: 'char *') startingAt: 0]
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> marshallUInt16From: argumentArrayOop at: index into: holder [

	| intHolder value |
	
	value := self fetchInteger: index ofObject: argumentArrayOop.
	value < 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	value > UINT16_MAX ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
		
	intHolder := self cCoerce: holder to: #'uint16_t *'.
	intHolder at: 0 put: value.
		
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> marshallUInt32From: argumentArrayOop at: index into: holder [

	| intHolder value |
	
	value := self fetchInteger: index ofObject: argumentArrayOop.
	value < 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	value > UINT32_MAX ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
		
	intHolder := self cCoerce: holder to: #'uint32_t *'.
	intHolder at: 0 put: value.
		
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> marshallUInt64From: argumentArrayOop at: index into: holder [

	| intHolder value |
	
	value := self fetchInteger: index ofObject: argumentArrayOop.
	value < 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
		
	intHolder := self cCoerce: holder to: #'uint64_t *'.
	intHolder at: 0 put: value.
		
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> marshallUInt8From: argumentArrayOop at: index into: holder [

	| intHolder value oop |
	
	oop := objectMemory fetchPointer: index ofObject: argumentArrayOop.
	value := (objectMemory isCharacterObject: oop) 
		ifTrue: [ objectMemory characterValueOf: oop ]	
		ifFalse: [ objectMemory integerValueOf: oop ].
	
	value < 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	value > UINT8_MAX ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
		
	intHolder := self cCoerce: holder to: #'uint8_t *'.
	intHolder at: 0 put: value.
		
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> maybeExternalAddressOf: rcvr startingAt: byteOffset size: byteSize [

"Return an int of the address of the byteSize slot (byte, short, int, whatever) at byteOffset in rcvr.
If the rcvr is an ExternalAddress the initial address is its contents. If the receiver is a byte array, the address is inside the byte array"

	| rcvrClass rcvrSize addr |

	(objectMemory isBytes: rcvr) ifFalse:[^self primitiveFail].
	(byteOffset > 0) ifFalse:[^ self primitiveFail].
	
	rcvrClass := objectMemory fetchClassOf: rcvr.
	rcvrSize := objectMemory byteSizeOf: rcvr.
	
	rcvrClass = objectMemory classExternalAddress ifTrue:[
		rcvrSize = BytesPerWord ifFalse:[^self primitiveFail].
		
		addr := objectMemory fetchPointer: 0 ofObject: rcvr.
		addr = 0 ifTrue: [ ^ 0 ].
	] ifFalse:[
		(byteOffset+byteSize-1 <= rcvrSize)
			ifFalse:[ ^ 0].
		addr := self cCoerce: (objectMemory firstIndexableField: rcvr) to: #'sqIntptr_t'.
	].
	addr := addr + byteOffset - 1.
	^ addr
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> newByteArrayWithStructContent: aPointer size: sizeToCopy [ 
	
	| oop targetPointer |
	oop := objectMemory instantiateClass: objectMemory classByteArray indexableSize: sizeToCopy.
	targetPointer := objectMemory firstIndexableField: oop.
	self memcpy: targetPointer _: aPointer _: sizeToCopy.
	^ oop
]

{ #category : #'primitive support' }
StackInterpreterPrimitives >> noInlineLoadFloatOrIntFrom: floatOrInt [
	<inline: #never>
	^objectMemory loadFloatOrIntFrom: floatOrInt
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> pathTo: goal using: stack followWeak: followWeak [
	"Trace objects and frames from the root, marking visited objects, pushing the current path on stack, until goal is found.
	 If found, unmark, leaving path in stack, and answer 0.  Otherwise answer an error:
		PrimErrBadArgument if stack is not an Array
		PrimErrBadIndex if search overflows stack
		PrimErrNotFound if goal cannot be found"
	<var: #index type: #sqInt> "beware, must be signed"
	| current index next stackSize stackp freeStartAtStart |
	(objectMemory isArray: stack) ifFalse:
		[^PrimErrBadArgument].
	self assert: objectMemory allObjectsUnmarked.
	freeStartAtStart := objectMemory freeStart. "check no allocations during search"
	objectMemory beRootIfOld: stack. "so no store checks are necessary on stack"
	stackSize := objectMemory lengthOf: stack.
	objectMemory mark: stack.
	"no need. the current context is not reachable from the active process (suspendedContext is nil)"
	"objectMemory mark: self activeProcess."
	current := objectMemory specialObjectsOop.
	objectMemory mark: current.
	index := objectMemory lengthOf: current.
	stackp := 0.
	[[(index := index - 1) >= -1] whileTrue:
		[(stackPages couldBeFramePointer: current)
			ifTrue:
				[next := index >= 0
							ifTrue: [self field: index ofFrame: (self cCoerceSimple: current to: #'char *')]
							ifFalse: [objectMemory nilObject]]
			ifFalse:
				[index >= 0
					ifTrue:
						[next := (objectMemory isContextNonImm: current)
									ifTrue: [self fieldOrSenderFP: index ofContext: current]
									ifFalse: [objectMemory fetchPointer: index ofObject: current]]
					ifFalse:
						[next := objectMemory fetchClassOfNonImm: current]].
		 (stackPages couldBeFramePointer: next)
			ifTrue: [self assert: (self isFrame: (self cCoerceSimple: next to: #'char *')
									onPage: (stackPages stackPageFor: (self cCoerceSimple: next to: #'char *')))]
			ifFalse: [self assert: (self checkOkayOop: next)].
		 next = goal ifTrue:
			[self assert: freeStartAtStart = objectMemory freeStart.
			 self unmarkAfterPathTo.
			 objectMemory storePointer: stackp ofObject: stack withValue: current.
			 self pruneStack: stack stackp: stackp.
			 ^0].
		 ((objectMemory isNonIntegerObject: next)
		  and: [(stackPages couldBeFramePointer: next)
				ifTrue: [(self frameIsMarked: next) not]
				ifFalse:
					[(objectMemory isMarked: next) not
					  and: [((objectMemory isPointers: next) or: [objectMemory isCompiledMethod: next])
					  and: [followWeak or: [(objectMemory isWeakNonImm: next) not]]]]])
			ifTrue:
				[stackp + 2 > stackSize ifTrue:
					[self assert: freeStartAtStart = objectMemory freeStart.
					 self unmarkAfterPathTo.
					 objectMemory nilFieldsOf: stack.
					 ^PrimErrBadIndex]. "PrimErrNoMemory ?"
				 objectMemory
					storePointerUnchecked: stackp ofObject: stack withValue: current;
					storePointerUnchecked: stackp + 1 ofObject: stack withValue: (objectMemory integerObjectOf: index).
				 stackp := stackp + 2.
				 (stackPages couldBeFramePointer: (self cCoerceSimple: next to: #'char *'))
					ifTrue:
						[self markFrame: next.
						index := self fieldsInFrame: (self cCoerceSimple: next to: #'char *')]
					ifFalse:
						[objectMemory mark: next.
						 (objectMemory isCompiledMethod: next)
							ifTrue: [index := (objectMemory literalCountOf: next) + LiteralStart]
							ifFalse: [index := objectMemory lengthOf: next]].
				 current := next]].
		 current = objectMemory specialObjectsOop ifTrue:
			[self assert: freeStartAtStart = objectMemory freeStart.
			 self unmarkAfterPathTo.
			 objectMemory nilFieldsOf: stack.
			^PrimErrNotFound].
		 index := objectMemory integerValueOf: (objectMemory fetchPointer: stackp - 1 ofObject: stack).
		 current := objectMemory fetchPointer: stackp - 2 ofObject: stack.
		 stackp := stackp - 2] repeat
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> popSameThreadCalloutSuspendedProcess [
	
	| aProcess |
	aProcess := objectMemory splObj: SuspendedProcessInCallout.
	
	aProcess = objectMemory nilObject
		ifTrue: [ self error: 'SameThreadCalloutSuspendedProcessStack is empty' ].	
	
	objectMemory 
		splObj: SuspendedProcessInCallout 
		put: (objectMemory fetchPointer: NextLinkIndex ofObject: aProcess).
	
	objectMemory storePointer: NextLinkIndex ofObject: aProcess withValue: objectMemory nilObject.
	
	^ aProcess
]

{ #category : #'system control primitives' }
StackInterpreterPrimitives >> primitiveAllVMParameters: paramsArraySize [
	"See primitiveVMParameter method comment"

	| result |
	result := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: paramsArraySize.
	objectMemory storePointerUnchecked: 0	ofObject: result withValue: (self positiveMachineIntegerFor: objectMemory oldSpaceSize).
	objectMemory storePointerUnchecked: 1	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory newSpaceSize).
	objectMemory storePointerUnchecked: 2	ofObject: result withValue: (self positiveMachineIntegerFor: objectMemory totalMemorySize).
	"objectMemory storePointerUnchecked: 3	ofObject: result withValue: objectMemory nilObject was allocationCount".
	"objectMemory storePointerUnchecked: 4	ofObject: result withValue: objectMemory nilObject allocationsBetweenGCs".
	objectMemory storePointerUnchecked: 5	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory tenuringThreshold).
	objectMemory storePointerUnchecked: 6	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statFullGCs).
	objectMemory storePointerUnchecked: 7	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statFullGCUsecs + 500 // 1000).
	objectMemory
		storePointerUnchecked: 8
		ofObject: result
		withValue: (objectMemory integerObjectOf: (objectMemory hasSpurMemoryManagerAPI
														ifTrue: [objectMemory statScavenges]
														ifFalse: [objectMemory statIncrGCs])).
	objectMemory
		storePointerUnchecked: 9
		ofObject: result
		withValue: (objectMemory integerObjectOf: (objectMemory hasSpurMemoryManagerAPI
														ifTrue: [objectMemory statScavengeGCUsecs]
														ifFalse: [objectMemory statIncrGCUsecs]) + 500 // 1000).
	objectMemory storePointerUnchecked: 10	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statTenures).
	"JITTER VM info unused; 11 - 14/12 - 15 available for reuse"
	11 to: 18 do:
		[:i | objectMemory storePointerUnchecked: i ofObject: result withValue: ConstZero].
	objectMemory storePointerUnchecked: 15 ofObject: result withValue: (objectMemory positive64BitIntegerFor: statIdleUsecs).
	(SistaVM and: [self isCog]) ifTrue:
		[objectMemory storePointerUnchecked: 16 ofObject: result withValue: (objectMemory floatObjectOf: self getCogCodeZoneThreshold)].
	objectMemory hasSpurMemoryManagerAPI ifTrue:
		[objectMemory
			storePointerUnchecked: 17	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statCompactionUsecs + 500 // 1000);
			storePointerUnchecked: 18	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory scavengeThresholdAsExtent)].
	objectMemory storePointerUnchecked: 19	ofObject: result withValue: (objectMemory positive64BitIntegerFor: self ioUTCStartMicroseconds).
	objectMemory storePointerUnchecked: 20	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory rootTableCount).
	objectMemory storePointerUnchecked: 21	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statRootTableOverflows).
	objectMemory storePointerUnchecked: 22	ofObject: result withValue: (objectMemory integerObjectOf: extraVMMemory).
	objectMemory storePointerUnchecked: 23	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory shrinkThreshold).
	objectMemory storePointerUnchecked: 24	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory growHeadroom).
	objectMemory storePointerUnchecked: 25	ofObject: result withValue: (objectMemory integerObjectOf: self ioHeartbeatMilliseconds).
	objectMemory storePointerUnchecked: 26	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statMarkCount).
	objectMemory storePointerUnchecked: 27	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statSweepCount).
	objectMemory storePointerUnchecked: 28	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statMkFwdCount).
	objectMemory storePointerUnchecked: 29	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statCompMoveCount).
	objectMemory storePointerUnchecked: 30	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statGrowMemory).
	objectMemory storePointerUnchecked: 31	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statShrinkMemory).
	objectMemory storePointerUnchecked: 32	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statRootTableCount).
	objectMemory hasSpurMemoryManagerAPI ifTrue: "was statAllocationCount"
		[objectMemory storePointerUnchecked: 33	ofObject: result withValue: (objectMemory positive64BitIntegerFor: objectMemory currentAllocatedBytes)].
	objectMemory storePointerUnchecked: 34	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statSurvivorCount).
	objectMemory storePointerUnchecked: 35	ofObject: result withValue: (objectMemory integerObjectOf: (self microsecondsToMilliseconds: objectMemory statGCEndUsecs)).
	objectMemory storePointerUnchecked: 36	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statSpecialMarkCount).
	objectMemory storePointerUnchecked: 37	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statIGCDeltaUsecs + 500 // 1000).
	objectMemory storePointerUnchecked: 38	ofObject: result withValue: (objectMemory integerObjectOf: statPendingFinalizationSignals).
	objectMemory storePointerUnchecked: 39	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory wordSize).
	objectMemory storePointerUnchecked: 40	ofObject: result withValue: (objectMemory integerObjectOf: self imageFormatVersion).
	objectMemory storePointerUnchecked: 41	ofObject: result withValue: (objectMemory integerObjectOf: numStackPages).
	objectMemory storePointerUnchecked: 42	ofObject: result withValue: (objectMemory integerObjectOf: desiredNumStackPages).
	objectMemory storePointerUnchecked: 43	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory edenBytes).
	objectMemory storePointerUnchecked: 44	ofObject: result withValue: (objectMemory integerObjectOf: desiredEdenBytes).
	objectMemory storePointerUnchecked: 45	ofObject: result withValue: self getCogCodeSize.
	objectMemory storePointerUnchecked: 46	ofObject: result withValue: self getDesiredCogCodeSize.
	objectMemory storePointerUnchecked: 47	ofObject: result withValue: self getCogVMFlags.
	objectMemory storePointerUnchecked: 48	ofObject: result withValue: (objectMemory integerObjectOf: self ioGetMaxExtSemTableSize).
	"50 & 51 (49 & 50) reserved for parameters that persist in the image"
	objectMemory storePointerUnchecked: 51	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory rootTableCapacity).
	objectMemory hasSpurMemoryManagerAPI ifTrue:
		[objectMemory
			storePointerUnchecked: 52 ofObject: result withValue: (objectMemory integerObjectOf: objectMemory numSegments);
			storePointerUnchecked: 53 ofObject: result withValue: (objectMemory integerObjectOf: objectMemory freeSize);
			storePointerUnchecked: 54 ofObject: result withValue: (objectMemory floatObjectOf: objectMemory getHeapGrowthToSizeGCRatio)].
	objectMemory storePointerUnchecked: 55	ofObject: result withValue: (self positive64BitIntegerFor: statProcessSwitch).
	objectMemory storePointerUnchecked: 56	ofObject: result withValue: (self positive64BitIntegerFor: statIOProcessEvents).
	objectMemory storePointerUnchecked: 57	ofObject: result withValue: (self positive64BitIntegerFor: statForceInterruptCheck).
	objectMemory storePointerUnchecked: 58	ofObject: result withValue: (self positive64BitIntegerFor: statCheckForEvents).
	objectMemory storePointerUnchecked: 59	ofObject: result withValue: (self positive64BitIntegerFor: statStackOverflow).
	objectMemory storePointerUnchecked: 60	ofObject: result withValue: (self positive64BitIntegerFor: statStackPageDivorce).
	objectMemory storePointerUnchecked: 61	ofObject: result withValue: self getCodeCompactionCount.
	objectMemory storePointerUnchecked: 62	ofObject: result withValue: self getCodeCompactionMSecs.
	objectMemory storePointerUnchecked: 63	ofObject: result withValue: self getCogMethodCount.
	objectMemory storePointerUnchecked: 64	ofObject: result withValue: self getCogVMFeatureFlags.
	objectMemory storePointerUnchecked: 65	ofObject: result withValue: (objectMemory integerObjectOf: self stackPageByteSize).
	objectMemory hasSpurMemoryManagerAPI ifTrue:
		[objectMemory
			storePointerUnchecked: 66 ofObject: result withValue: (objectMemory integerObjectOf: objectMemory maxOldSpaceSize)].
	objectMemory storePointerUnchecked: 67 ofObject: result withValue: (objectMemory floatObjectOf: stackPages statAverageLivePagesWhenMapping).
	objectMemory storePointerUnchecked: 68 ofObject: result withValue: (objectMemory integerObjectOf: stackPages statMaxPageCountWhenMapping).
	objectMemory
		storePointerUnchecked: 69
		ofObject: result
		withValue: (objectMemory integerObjectOf: (self cCode: 'VM_PROXY_MAJOR' inSmalltalk: [self class vmProxyMajorVersion])).
	objectMemory
		storePointerUnchecked: 70
		ofObject: result
		withValue: (objectMemory integerObjectOf: (self cCode: 'VM_PROXY_MINOR' inSmalltalk: [self class vmProxyMinorVersion])).	
	objectMemory storePointerUnchecked: 71	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statMarkUsecs + 500 // 1000).
	objectMemory storePointerUnchecked: 72	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statSweepUsecs + 500 // 1000).
	objectMemory hasSpurMemoryManagerAPI ifTrue:
		[objectMemory
			storePointerUnchecked: 73	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statMaxAllocSegmentTime + 500 // 1000)].

	objectMemory beRootIfOld: result.
	self methodReturnValue: result
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> primitiveClone [
	"Return a shallow copy of the receiver.
	 Special-case non-single contexts (because of context-to-stack mapping).
	 Can't fail for contexts cuz of image context instantiation code (sigh)."

	| rcvr newCopy |
	rcvr := self stackTop.
	(objectMemory isImmediate: rcvr)
		ifTrue:
			[newCopy := rcvr]
		ifFalse:
			[(objectMemory isContextNonImm: rcvr)
				ifTrue:
					[newCopy := self cloneContext: rcvr]
				ifFalse:
					[(argumentCount = 0
					  or: [(objectMemory isForwarded: rcvr) not])
						ifTrue: [newCopy := objectMemory clone: rcvr]
						ifFalse: [newCopy := 0]].
			newCopy = 0 ifTrue:
				[^self primitiveFailFor: PrimErrNoMemory]].
	self pop: argumentCount + 1 thenPush: newCopy
]

{ #category : #'control primitives' }
StackInterpreterPrimitives >> primitiveClosureCopyWithCopiedValues [
	| newClosure numArgs |
	numArgs := self stackIntegerValue: 1.
	self successful ifFalse:
		[^self primitiveFail].

	newClosure := self
					closureIn: (self stackValue: 2)
					numArgs: numArgs
							"greater by 1 due to preIncrement of localIP"
					instructionPointer: instructionPointer + 2 - (method+objectMemory baseHeaderSize)
					copiedValues: self stackTop.
	self pop: 3 thenPush: newClosure
]

{ #category : #'indexing primitives' }
StackInterpreterPrimitives >> primitiveContextAt [
	"Special version of primitiveAt for accessing contexts.
	 Written to be varargs for use from mirror primitives."
	| index value aContext spouseFP hdr fmt totalLength fixedFields stSize |
	<inline: false>
	<var: #spouseFP type: #'char *'>
	index := self stackTop.
	(objectMemory isIntegerObject: index) ifFalse:
		[self primitiveFailFor: PrimErrBadArgument.
		 ^self].
	index := objectMemory integerValueOf: index.
	aContext := self stackValue: 1.
	"Duplicating much of stObject:at:put: here allows stObject:at:put: to omit tests for contexts."
	hdr := objectMemory baseHeader: aContext.
	(objectMemory isContextHeader: hdr) ifFalse: "might be an instance of a subclass"
		[value := self stObject: aContext at: index.
		 self successful ifTrue:
			[self pop: argumentCount + 1 thenPush: value].
		 ^self].
	self externalWriteBackHeadFramePointers.
	(self isStillMarriedContext: aContext) ifFalse:
		[fmt := objectMemory formatOfHeader: hdr.
		 totalLength := objectMemory lengthOf: aContext baseHeader: hdr format: fmt.
		 fixedFields := objectMemory fixedFieldsOf: aContext format: fmt length: totalLength.
		 stSize := self fetchStackPointerOf: aContext.
		 (index between: 1 and: stSize) ifFalse:
			[self primitiveFailFor: PrimErrBadIndex.
			 ^self].			
		value := self subscript: aContext with: (index + fixedFields) format: fmt.
		self pop: argumentCount + 1 thenPush: value.
		^self].
	spouseFP := self frameOfMarriedContext: aContext.
	(index between: 1 and: (self stackPointerIndexForFrame: spouseFP)) ifFalse:
		[self primitiveFailFor: PrimErrBadIndex.
		 ^self].
	value := self temporary: index - 1 in: spouseFP.
	self pop: argumentCount + 1 thenPush: value
]

{ #category : #'indexing primitives' }
StackInterpreterPrimitives >> primitiveContextAtPut [
	"Special version of primitiveAtPut for accessing contexts.
	 Written to be varargs for use from mirror primitives."
	| index value aContext spouseFP hdr fmt totalLength fixedFields stSize |
	<inline: false>
	<var: #spouseFP type: #'char *'>
	value := self stackTop.
	index := self stackValue: 1.
	aContext := self stackValue: 2.
	(objectMemory isIntegerObject: index) ifFalse:
		[self primitiveFailFor: PrimErrBadArgument.
		 ^self].
	"Duplicating much of stObject:at:put: here allows stObject:at:put: to omit tests for contexts."
	hdr := objectMemory baseHeader: aContext.
	index := objectMemory integerValueOf: index.
	(objectMemory isContextHeader: hdr) ifFalse: "might be an instance of a subclass"
		[self stObject: aContext at: index put: value.
		 self successful ifTrue:
			[self pop: argumentCount + 1 thenPush: value].
		 ^self].
	self externalWriteBackHeadFramePointers.
	(self isStillMarriedContext: aContext) ifFalse:
		[fmt := objectMemory formatOfHeader: hdr.
		 totalLength := objectMemory lengthOf: aContext baseHeader: hdr format: fmt.
		 fixedFields := objectMemory fixedFieldsOf: aContext format: fmt length: totalLength.
		 stSize := self fetchStackPointerOf: aContext.
		 (index between: 1 and: stSize) ifFalse:
			[self primitiveFailFor: PrimErrBadIndex.
			 ^self].
		self subscript: aContext with: (index + fixedFields) storing: value format: fmt.
		self pop: argumentCount + 1 thenPush: value.
		^self].
	spouseFP := self frameOfMarriedContext: aContext.
	(index between: 1 and: (self stackPointerIndexForFrame: spouseFP)) ifFalse:
		[self primitiveFailFor: PrimErrBadIndex.
		 ^self].
	self temporary: index - 1 in: spouseFP put: value.
	self pop: argumentCount + 1 thenPush: value
]

{ #category : #'indexing primitives' }
StackInterpreterPrimitives >> primitiveContextSize [
	"Special version of primitiveSize for accessing contexts.
	 Written to be varargs for use from mirror primitives."
	| rcvr sz hdr fmt totalLength fixedFields |
	<inline: false>
	rcvr := self stackTop.
	hdr := objectMemory baseHeader: rcvr.
	fmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := objectMemory fixedFieldsOf: rcvr format: fmt length: totalLength.
	(objectMemory isContextHeader: hdr)
		ifTrue:
			[self externalWriteBackHeadFramePointers.
			sz := self stackPointerForMaybeMarriedContext: rcvr]
		ifFalse: [sz := totalLength - fixedFields].
	self pop: argumentCount + 1 thenPush: (objectMemory integerObjectOf: sz)
]

{ #category : #'indexing primitives' }
StackInterpreterPrimitives >> primitiveContextXray [
	"Lift the veil from a context and answer an integer describing its interior state.
	 Used for e.g. VM tests so they can verify they're testing what they think they're testing.
	 0 implies a vanilla heap context.
	 Bit 0 = is or was married to a frame
	 Bit 1 = is still married to a frame
	 Bit 2 = frame is executing machine code
	 Bit 3 = has machine code pc (as opposed to nil or a bytecode pc)
	 Bit 4 = method is currently compiled to machine code"
	| context flags |
	context := self stackTop.
	(self isMarriedOrWidowedContext: context)
		ifTrue:
			[(self checkIsStillMarriedContext: context currentFP: framePointer)
				ifTrue: [flags := 3]
				ifFalse: [flags := 1]]
		ifFalse:
			[flags := 0].
	self pop: 1 thenPush: (objectMemory integerObjectOf: flags)
]

{ #category : #'I/O primitives' }
StackInterpreterPrimitives >> primitiveDeferDisplayUpdates [
	"Set or clear the flag that controls whether modifications of 
	 the Display object are propagated to the underlying 
	 platform's screen."
	| flag |
	flag := self stackTop.
	flag = objectMemory trueObject
		ifTrue: [deferDisplayUpdates := true]
		ifFalse:
			[flag = objectMemory falseObject
				ifTrue: [deferDisplayUpdates := false]
				ifFalse: [^self primitiveFail]].
	self cCode: [] inSmalltalk: [self fullDisplayUpdate].
	self pop: 1
]

{ #category : #'plugin primitives' }
StackInterpreterPrimitives >> primitiveDoNamedPrimitiveWithArgs [
	"Simulate an primitiveExternalCall invocation (e.g. for the Debugger).  Do not cache anything.
	 e.g. ContextPart>>tryNamedPrimitiveIn: aCompiledMethod for: aReceiver withArgs: arguments"
	| argumentArray arraySize methodArg methodHeader
	  moduleName functionName moduleLength functionLength
	  spec addr primRcvr isArray |
	<var: #addr declareC: 'void (*addr)()'>
	objectMemory hasSpurMemoryManagerAPI ifTrue: "See checkForAndFollowForwardedPrimitiveState"
		[metaAccessorDepth := -2].
	argumentArray := self stackTop.
	methodArg := self stackValue: 2.
	((objectMemory isArray: argumentArray)
	 and: [objectMemory isOopCompiledMethod: methodArg]) ifFalse:
		[^self primitiveFailFor: -2]. "invalid args"
	arraySize := objectMemory numSlotsOf: argumentArray.
	(self roomToPushNArgs: arraySize) ifFalse:
		[^self primitiveFailFor: -2]. "invalid args"

	methodHeader := objectMemory methodHeaderOf: methodArg.
	(objectMemory literalCountOfMethodHeader: methodHeader) > 2 ifFalse:
		[^self primitiveFailFor: -3]. "invalid methodArg state"
	spec := objectMemory fetchPointer: 1 "first literal" ofObject: methodArg.
	isArray := self isInstanceOfClassArray: spec.
	(isArray
	and: [(objectMemory numSlotsOf: spec) = 4
	and: [(self primitiveIndexOfMethod: methodArg header: methodHeader) = PrimNumberExternalCall]]) ifFalse:
		[^self primitiveFailFor: -3]. "invalid methodArg state"

	(self argumentCountOfMethodHeader: methodHeader) = arraySize ifFalse:
		[^self primitiveFailFor: -2]. "invalid args (Array args wrong size)"

	"The function has not been loaded yet. Fetch module and function name."
	moduleName := objectMemory fetchPointer: 0 ofObject: spec.
	moduleName = objectMemory nilObject
		ifTrue: [moduleLength := 0]
		ifFalse: [self success: (objectMemory isBytes: moduleName).
				moduleLength := objectMemory lengthOf: moduleName].
	functionName := objectMemory fetchPointer: 1 ofObject: spec.
	self success: (objectMemory isBytes: functionName).
	functionLength := objectMemory lengthOf: functionName.
	self successful ifFalse: [^self primitiveFailFor: -3]. "invalid methodArg state"

	"Spur needs to know the primitive's accessorDepth."
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[addr := self ioLoadExternalFunction: functionName + objectMemory baseHeaderSize
						OfLength: functionLength
						FromModule: moduleName + objectMemory baseHeaderSize
						OfLength: moduleLength
						AccessorDepthInto: (self addressOf: metaAccessorDepth
												 put: [:val| metaAccessorDepth := val]).
			 addr = 0 ifTrue:
				[metaAccessorDepth := -2]]
		ifFalse:
			[addr := self ioLoadExternalFunction: functionName + objectMemory baseHeaderSize
						OfLength: functionLength
						FromModule: moduleName + objectMemory baseHeaderSize
						OfLength: moduleLength].
	addr = 0 ifTrue:
		[^self primitiveFailFor: -1]. "could not find function; answer generic failure (see below)"

	"Cannot fail this primitive from now on.  Can only fail the external primitive."
	tempOop := objectMemory
						eeInstantiateClassIndex: ClassArrayCompactIndex
						format: objectMemory arrayFormat
						numSlots: 4.
	objectMemory
		storePointerUnchecked: 0 ofObject: tempOop withValue: (argumentArray := self popStack);
		storePointerUnchecked: 1 ofObject: tempOop withValue: (primRcvr := self popStack);
		storePointerUnchecked: 2 ofObject: tempOop withValue: self popStack; "the method"
		storePointerUnchecked: 3 ofObject: tempOop withValue: self popStack. "the context receiver"
	self push: primRcvr. "replace context receiver with actual receiver"
	argumentCount := arraySize.
	1 to: arraySize do:
		[:index| self push: (objectMemory fetchPointer: index - 1 ofObject: argumentArray)].
	self callExternalPrimitive: addr.
	self successful ifFalse: "If primitive failed, then restore state for failure code"
		[self pop: arraySize + 1.
		 self push: (objectMemory fetchPointer: 3 ofObject: tempOop).
		 self push: (objectMemory fetchPointer: 2 ofObject: tempOop).
		 self push: (objectMemory fetchPointer: 1 ofObject: tempOop).
		 self push: (objectMemory fetchPointer: 0 ofObject: tempOop).
		 argumentCount := 3.
		 "Must reset primitiveFunctionPointer for checkForAndFollowForwardedPrimitiveState"
		 objectMemory hasSpurMemoryManagerAPI ifTrue:
			[primitiveFunctionPointer := #primitiveDoNamedPrimitiveWithArgs].
		 "Hack.  A nil prim error code (primErrorCode = 1) is interpreted by the image
		  as meaning this primitive is not implemented.  So to pass back nil as an error
		  code we use -1 to indicate generic failure."
		 primFailCode = 1 ifTrue:
			[primFailCode := -1]]
]

{ #category : #'control primitives' }
StackInterpreterPrimitives >> primitiveDoPrimitiveWithArgs [
	"Implement either ProtoObject>>tryPrimitive: primIndex withArgs: argArray
	 or Context>>receiver: anObject tryPrimitive: primIndex withArgs: argArray.
	 If this primitive fails, arrange that its error code is a negative integer, to
	 distinguish between this failing and the primitive it invokes failing."
	| argumentArray arraySize index primIdx savedNumArgs rcvr |
	objectMemory hasSpurMemoryManagerAPI ifTrue: "See checkForAndFollowForwardedPrimitiveState"
		[metaAccessorDepth := -2].
	(argumentCount between: 2 and: 3) ifFalse:
		[^self primitiveFailFor: PrimErrUnsupported negated].
	argumentArray := self stackTop.
	primIdx := self stackValue: 1.
	((objectMemory isArray: argumentArray)
	 and: [objectMemory isIntegerObject: primIdx]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument negated].
	arraySize := objectMemory numSlotsOf: argumentArray.
	(self roomToPushNArgs: arraySize) ifFalse:
		[^self primitiveFailFor: PrimErrLimitExceeded negated].

	primIdx := objectMemory integerValueOf: primIdx.
	primitiveFunctionPointer := self functionPointerFor: primIdx inClass: nil.
	primitiveFunctionPointer = 0 ifTrue:
		[primitiveFunctionPointer := #primitiveDoPrimitiveWithArgs.
		 ^self primitiveFailFor: PrimErrBadIndex negated].

	"Pop primIndex and argArray, then push args in place..."
	(savedNumArgs := argumentCount) = 3
		ifTrue: "...and receiver if the three arg form"
			[tempOop2 := self stackValue: 4. "actual receiver"
			 rcvr := self stackValue: 3. "receiver for primitive"
			 (objectMemory isOopForwarded: rcvr) ifTrue:
				[rcvr := objectMemory followForwarded: rcvr].
			 self pop: 4; push: rcvr] "use first arg as receiver"
		ifFalse:
			[self pop: 2].
	argumentCount := arraySize.
	index := 1.
	[index <= arraySize] whileTrue:
		[self push: (objectMemory fetchPointer: index - 1 ofObject: argumentArray).
		 index := index + 1].

	self isPrimitiveFunctionPointerAnIndex ifTrue:
		[self externalQuickPrimitiveResponse.
		 tempOop2 := 0.
		^nil].
	"We use tempOop instead of pushRemappableOop:/popRemappableOop here because in
	 the Cogit primitiveEnterCriticalSection, primitiveSignal, primitiveResume et al longjmp back
	 to either the interpreter or machine code, depending on the process activated.  So if we're
	 executing one of these primitives, control won't actually return here and the matching
	 popRemappableOop: wouldn't occur, potentially overflowing the remap buffer.
	 Note that while recursion could occur (nil tryPrimitive: 118 withArgs: #(118 #(110 #())))
	 it counts as shooting oneself in the foot."
	tempOop := argumentArray. "prim might alloc/gc"

	"Run the primitive (sets primFailCode)"
	objectMemory hasSpurMemoryManagerAPI ifTrue: "See checkForAndFollowForwardedPrimitiveState"
		[metaAccessorDepth := primitiveAccessorDepthTable at: primIdx].
	self slowPrimitiveResponse.

	self successful ifFalse: "If primitive failed, then restore state for failure code"
		[self pop: arraySize.
		 savedNumArgs = 3 ifTrue:
			[rcvr := self stackTop.
			 self stackTopPut: tempOop2.
			 self push: rcvr].
		 self pushInteger: primIdx.
		 self push: tempOop.
		 primitiveFunctionPointer := #primitiveDoPrimitiveWithArgs.
		 argumentCount := savedNumArgs].
	tempOop := tempOop2 := 0
]

{ #category : #'control primitives' }
StackInterpreterPrimitives >> primitiveExecuteMethod [
	"receiver, args, then method are on top of stack. Execute method against receiver and args.
	 Set primitiveFunctionPointer because no cache lookup has been done for the method, and
	 hence primitiveFunctionPointer is stale."
	| methodArgument primitiveIndex |
	methodArgument := self stackTop.
	(objectMemory isOopCompiledMethod: methodArgument) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	argumentCount - 1 = (self argumentCountOf: methodArgument) ifFalse:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	newMethod := self popStack.
	primitiveIndex := self primitiveIndexOf: newMethod.
	primitiveFunctionPointer := self functionPointerFor: primitiveIndex inClass: nil.
	argumentCount := argumentCount - 1.
	self executeNewMethod.
	"Recursive xeq affects primErrorCode"
	self initPrimCall
]

{ #category : #'control primitives' }
StackInterpreterPrimitives >> primitiveExecuteMethodArgsArray [
	"receiver, argsArray, then method are on top of stack.  Execute method against
	 receiver and args.  Allow for up to two extra arguments (e.g. for mirror primitives).
	 Set primitiveFunctionPointer because no cache lookup has been done for the
	 method, and hence primitiveFunctionPointer is stale."
	| methodArgument argCnt rcvr argumentArray primitiveIndex |
	methodArgument := self stackTop.
	argumentArray := self stackValue: 1.
	((objectMemory isOopCompiledMethod: methodArgument)
	 and: [objectMemory isArray: argumentArray]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	argCnt := self argumentCountOf: methodArgument.
	argCnt = (objectMemory numSlotsOf: argumentArray) ifFalse:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	argumentCount > 2 ifTrue: "CompiledMethod class>>receiver:withArguments:executeMethod:
								SqueakObjectPrimitives class>>receiver:withArguments:apply:
								VMMirror>>ifFail:object:with:executeMethod: et al"
		[rcvr := self stackValue: 2.
		 (argumentCount > 4
		  or: [objectMemory isOopForwarded: rcvr]) ifTrue:
			[^self primitiveFailFor: PrimErrUnsupported].
		self stackValue: argumentCount put: rcvr]. "replace actual receiver with desired receiver"
	"and push the actual arguments"
	self pop: argumentCount.
	0 to: argCnt - 1 do:
		[:i|
		self push: (objectMemory fetchPointer: i ofObject: argumentArray)].
	newMethod := methodArgument.
	primitiveIndex := self primitiveIndexOf: newMethod.
	primitiveFunctionPointer := self functionPointerFor: primitiveIndex inClass: nil.
	argumentCount := argCnt.
	self executeNewMethod.
	"Recursive xeq affects primErrorCode"
	self initPrimCall
]

{ #category : #'plugin primitives' }
StackInterpreterPrimitives >> primitiveExternalCall [
	"Call an external primitive. External primitive methods first literals are an array of
		* The module name (String | Symbol)
		* The function name (String | Symbol)
		* The session ID (SmallInteger) [OBSOLETE], or in Spur, the accessorDepth (Integer)
		* The function index (Integer) in the externalPrimitiveTable
	For fast interpreter dispatch in subsequent invocations the primitiveFunctionPointer
	in the method cache is rewritten, either to the function itself, or to zero if the external
	function is not found.   This allows for fast responses as long as the method stays in
	the cache. The cache rewrite relies on lastMethodCacheProbeWrite which is set in
	addNewMethodToCache:.
	Now that the VM flushes function addresses from its tables, the session ID is obsolete,
	but it is kept for backward compatibility. Also, a failed lookup is reported specially. If a
	method has been  looked up and not been found, the function address is stored as -1
	(i.e., the SmallInteger -1 to distinguish from 16rFFFFFFFF which may be returned from
	lookup), and the primitive fails with PrimErrNotFound."
	| lit addr moduleName functionName moduleLength functionLength accessorDepth index |
	<var: #addr declareC: 'void (*addr)()'>
		
	"Check for it being a method for primitiveDoPrimitiveWithArgs.
	 Fetch the first literal of the method; check its an Array of length 4.
	 Look at the function index in case it has been loaded before"
	((objectMemory isOopCompiledMethod: newMethod)
	 and: [(objectMemory literalCountOf: newMethod) > 0
	 and: [lit := self literal: 0 ofMethod: newMethod.
		(objectMemory isArray: lit)
	 and: [(objectMemory numSlotsOf: lit) = 4
	 and: [index := objectMemory fetchPointer: 3 ofObject: lit.
		objectMemory isIntegerObject: index]]]]) ifFalse:
		[^self primitiveFailFor: PrimErrBadMethod].

	index := objectMemory integerValueOf: index.
	"Check if we have already looked up the function and failed."
		
	index < 0 ifTrue:
		["Function address was not found in this session, 
		  Void the primitive function."
		 self rewriteMethodCacheEntryForExternalPrimitiveToFunction: 0.
		 ^self primitiveFailFor: PrimErrNotFound].

	"Try to call the function directly"
	(index > 0 and: [index <= MaxExternalPrimitiveTableSize]) ifTrue:
		[addr := externalPrimitiveTable at: index - 1.
		 addr ~= 0 ifTrue:
			[self rewriteMethodCacheEntryForExternalPrimitiveToFunction: (self cCode: 'addr' inSmalltalk: [1000 + index]).
			 self callExternalPrimitive: addr. "On Spur, sets primitiveFunctionPointer"
			 self maybeRetryPrimitiveOnFailure.
			 ^nil].
		"if we get here, then an index to the external prim was 
		kept on the ST side although the underlying prim 
		table was already flushed"
		^self primitiveFailFor: PrimErrNamedInternal].

	"Clean up session id and external primitive index"
	objectMemory storePointerUnchecked: 2 ofObject: lit withValue: ConstZero.
	objectMemory storePointerUnchecked: 3 ofObject: lit withValue: ConstZero.

	"The function has not been loaded yet. Fetch module and function name."
	moduleName := objectMemory fetchPointer: 0 ofObject: lit.
	moduleName = objectMemory nilObject
		ifTrue: [moduleLength := 0]
		ifFalse: [(objectMemory isBytes: moduleName) ifFalse:
					[self primitiveFailFor: PrimErrBadMethod].
				moduleLength := objectMemory lengthOf: moduleName].
	functionName := objectMemory fetchPointer: 1 ofObject: lit.
	(objectMemory isBytes: functionName) ifFalse:
		[self primitiveFailFor: PrimErrBadMethod].
	functionLength := objectMemory lengthOf: functionName.

	"Spur needs to know the primitive's accessorDepth which is stored in the third slot of the first literal."
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[addr := self ioLoadExternalFunction: functionName + objectMemory baseHeaderSize
						OfLength: functionLength
						FromModule: moduleName + objectMemory baseHeaderSize
						OfLength: moduleLength
						AccessorDepthInto: (self addressOf: accessorDepth
												 put: [:val| accessorDepth := val]).
			 addr = 0
				ifTrue: [index := -1]
				ifFalse: "add the function to the external primitive table"
					[index := self addToExternalPrimitiveTable: addr.
					 objectMemory
						storePointerUnchecked: 2
						ofObject: lit
						withValue: (objectMemory integerObjectOf: accessorDepth)]]
		ifFalse:
			[addr := self ioLoadExternalFunction: functionName + objectMemory baseHeaderSize
						OfLength: functionLength
						FromModule: moduleName + objectMemory baseHeaderSize
						OfLength: moduleLength.
			 addr = 0
				ifTrue: [index := -1]
				ifFalse: "add the function to the external primitive table"
					[index := self addToExternalPrimitiveTable: addr]].

	"Store the index (or -1 if failure) back in the literal"
	objectMemory storePointerUnchecked: 3 ofObject: lit withValue: (objectMemory integerObjectOf: index).

	"If the function has been successfully loaded cache and call it"
	index >= 0
		ifTrue:
			[self rewriteMethodCacheEntryForExternalPrimitiveToFunction: (self cCode: [addr] inSmalltalk: [1000 + index]).
			 self callExternalPrimitive: addr.
			 self maybeRetryPrimitiveOnFailure]
		ifFalse: "Otherwise void the primitive function and fail"
			[self rewriteMethodCacheEntryForExternalPrimitiveToFunction: 0.
			 self assert: (objectMemory fetchPointer: 2 ofObject: lit) = ConstZero.
			 self primitiveFailFor: PrimErrNotFound]
]

{ #category : #ffi }
StackInterpreterPrimitives >> primitiveFFIAllocate [
	"Primitive. Allocate an object on the external heap."
	| byteSize addr oop |

	<api>
	<inline: false>
	<var: #ptr type: #'sqIntptr_t *'>

	byteSize := self stackIntegerValue: 0.
	self failed ifTrue: [ ^ self ].
	
	addr := self malloc: byteSize.
	addr = 0 ifTrue: [^ self primitiveFail].
	
	oop := objectMemory newExternalAddressWithValue: addr.
	
	^ self methodReturnValue: oop
]

{ #category : #ffi }
StackInterpreterPrimitives >> primitiveFFIFree [
	"Primitive. Free the object pointed to on the external heap."
	| addr oop |

	<export: true>
	<inline: false>
	<var: #ptr type: #'sqIntptr_t *'>

	oop  := self stackObjectValue: 0.
	addr := self readAddress: oop.
	self failed ifTrue: [ ^ self].

	(addr = 0
	 or: [(addr asUnsignedIntegerPtr bitAnd: (self sizeof: #'sqIntptr_t') - 1) ~= 0
	 or: [objectMemory isInMemory: addr]]) ifTrue:
		[^ self primitiveFail].
	
	self free: addr.
	
	self writeAddress: oop to: 0.
	^ self methodReturnValue: oop
]

{ #category : #ffi }
StackInterpreterPrimitives >> primitiveFFIIntegerAt [
	"Answer a (signed or unsigned) n byte integer from the given byte offset
	 in the receiver, using the platform's endianness."
	
	| isSigned byteSize byteOffset rcvr addr value mask valueOop |
	
	<var: 'value' type: #usqLong>
	<var: 'mask' type: #usqLong>
	<api>
	<inline: false>
	
	isSigned := self booleanValueOf: (self stackValue: 0).
	byteSize := self stackIntegerValue: 1.
	byteOffset := self stackIntegerValue: 2.
	rcvr := self stackObjectValue: 3.
	self failed ifTrue:[ ^self ].
		
	(byteOffset > 0
	 and: [(byteSize between: 1 and: 8)
	 and: [(byteSize bitAnd: byteSize - 1) = 0 "a.k.a. isPowerOfTwo"]]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	
	addr := self maybeExternalAddressOf: rcvr startingAt: byteOffset size: byteSize.
	addr = 0 ifTrue: [^self primitiveFailFor: PrimErrBadArgument].
	
	byteSize <= 2
		ifTrue:
			[byteSize = 1
				ifTrue: [value := self cCoerce: (objectMemory byteAt: addr) to: #'unsigned char']
				ifFalse: [value := self cCoerce: (objectMemory unalignedShortAt: addr) to: #'unsigned short']]
		ifFalse:
			[byteSize = 4
				ifTrue: [value := self cCoerce: (objectMemory unalignedLong32At: addr) to: #'unsigned int']
				ifFalse: [value := objectMemory unalignedLong64At: addr]].

	byteSize < BytesPerWord
		ifTrue:
			[isSigned ifTrue: "sign extend value"
				[mask := 1 asUnsignedLongLong << (byteSize * 8 - 1).
				value := (value bitAnd: mask-1) - (value bitAnd: mask)].
			 "note: byte/short (&long if BytesPerWord=8) never exceed SmallInteger range"
			 valueOop := objectMemory integerObjectOf: value]
		ifFalse: "general 64 bit integer; note these never fail"
			[isSigned
				ifTrue:
					[byteSize < 8 ifTrue: "sign extend value"
						[mask := 1 asUnsignedLongLong << (byteSize * 8 - 1).
						value := (value bitAnd: mask-1) - (value bitAnd: mask)].
					 self cCode: [] inSmalltalk:
						[(byteSize = 8 and: [(value bitShift: -56) >= 128]) ifTrue:
							[value := value - (1 bitShift: 64)]].
					 valueOop := objectMemory signed64BitIntegerFor: value]
				ifFalse:[valueOop := objectMemory positive64BitIntegerFor: value]].

	^ objectMemory methodReturnValue: valueOop
]

{ #category : #ffi }
StackInterpreterPrimitives >> primitiveFFIIntegerAtPut [
	"Store a (signed or unsigned) n byte integer at the given byte offset
	 in the receiver, using the platform's endianness."
	
	| isSigned byteSize byteOffset rcvr addr value max valueOop |
	
	<var: 'value' type: #sqLong>
	<var: 'max' type: #sqLong>
	<api>
	<inline: false>
	
	isSigned := self booleanValueOf: (self stackValue: 0).
	byteSize := self stackIntegerValue: 1.
	valueOop := self stackValue: 2.
	byteOffset := self stackIntegerValue: 3.
	rcvr := self stackObjectValue: 4.
	self failed ifTrue:[^ self ].

	(byteOffset > 0 and: [(byteSize between: 1 and: 8) 
		and: [(byteSize bitAnd: byteSize - 1) = 0 "a.k.a. isPowerOfTwo"]]) 
			ifFalse: [^self primitiveFailFor: PrimErrBadArgument ].
		
	addr := self maybeExternalAddressOf: rcvr startingAt: byteOffset size: byteSize.
	addr = 0 ifTrue: [^self primitiveFailFor: PrimErrBadArgument].
	
	value := isSigned 
		ifTrue:[objectMemory signed64BitValueOf: valueOop]
		ifFalse:[objectMemory positive64BitValueOf: valueOop].
	
	self failed ifTrue:[ ^ self].

	byteSize < 8 ifTrue:
		[isSigned
			ifTrue:
				[max := 1 asUnsignedLongLong << (8 * byteSize - 1).
				(value >= (0 - max) and: [value < max]) ifFalse: [^self primitiveFailFor: PrimErrBadArgument]]
			ifFalse:
				[value asUnsignedLongLong < (1 asUnsignedLongLong << (8 * byteSize)) ifFalse: [^self primitiveFailFor: PrimErrBadArgument]]].
	byteSize <= 2
		ifTrue:
			[byteSize = 1
				ifTrue: [objectMemory byteAt: addr put: value]
				ifFalse: [objectMemory unalignedShortAt: addr put: value]]
		ifFalse:
			[byteSize = 4
				ifTrue: [objectMemory unalignedLong32At: addr put: value]
				ifFalse: [objectMemory unalignedLong64At: addr put: value]].
	
	^ self methodReturnValue: valueOop
]

{ #category : #'control primitives' }
StackInterpreterPrimitives >> primitiveFindHandlerContext [
	"Primitive. Search up the context stack for the next method context marked
	 for exception handling starting at the receiver. Return nil if none found"
	| handlerOrNilOrZero |
	self externalWriteBackHeadFramePointers.
	handlerOrNilOrZero := self
							findMethodWithPrimitive: 199
							FromContext: self stackTop
							UpToContext: objectMemory nilObject.
	handlerOrNilOrZero = 0 ifTrue:
		[handlerOrNilOrZero := objectMemory nilObject].
	self pop: 1 thenPush: handlerOrNilOrZero
]

{ #category : #'control primitives' }
StackInterpreterPrimitives >> primitiveFindNextUnwindContext [
	"Primitive. Search up the context stack for the next method context marked for unwind
	 handling from the receiver up to but not including the argument. Return nil if none found."
	| stopContext calleeContext handlerOrNilOrZero |
	<var: #theFP type: #'char *'>
	stopContext := self stackTop.
	calleeContext := self stackValue: 1.
	(stopContext = objectMemory nilObject or: [objectMemory isContext: stopContext]) ifFalse:
		[^self primitiveFail].
	"The following should never be true, but developing full blocks, early in September
	 2016 we were seeing invalid invocations of this primitive..  Hence the assert:"
	self assert: stopContext ~= calleeContext.
	self externalWriteBackHeadFramePointers.
	(self isStillMarriedContext: calleeContext)
		ifTrue:
			[| theFP |
			 theFP := self frameOfMarriedContext: calleeContext.
			 (self isBaseFrame: theFP)
				ifTrue:
					[handlerOrNilOrZero := self findMethodWithPrimitive: 198
												FromContext: (self frameCallerContext: theFP)
												UpToContext: stopContext]
				ifFalse:
					[handlerOrNilOrZero :=  self findMethodWithPrimitive: 198
												FromFP: (self frameCallerFP: theFP)
												UpToContext: stopContext]]
		ifFalse:
			[| startContext |
			 startContext := objectMemory fetchPointer: SenderIndex ofObject: calleeContext.
			 (objectMemory isContext: startContext)
				ifTrue:
					[handlerOrNilOrZero := self findMethodWithPrimitive: 198
												FromContext: startContext
												UpToContext: stopContext]
				ifFalse:
					[handlerOrNilOrZero := 0]].
	handlerOrNilOrZero = 0 ifTrue:
		[handlerOrNilOrZero := objectMemory nilObject].
	self pop: 2 thenPush: handlerOrNilOrZero
]

{ #category : #'system control primitives' }
StackInterpreterPrimitives >> primitiveFlushCacheByMethod [
	"The receiver is a compiledMethod.  Clear all entries in the method lookup cache that refer to this method, presumably because it has been redefined, overridden or removed."
	self flushMethodCacheForMethod: self stackTop
]

{ #category : #'system control primitives' }
StackInterpreterPrimitives >> primitiveFlushCacheBySelector [
	"The receiver is a message selector.  Clear all entries in the method lookup cache
	 with this selector, presumably because an associated method has been redefined."
	| selector probe |
	selector := self stackTop.
	probe := 0.
	1 to: MethodCacheEntries do:
		[:i | (methodCache at: probe + MethodCacheSelector) = selector ifTrue:
			[methodCache at: probe + MethodCacheSelector put: 0].
		probe := probe + MethodCacheEntrySize].
	(selector = (self specialSelector: 16) "at:"
	 or: [selector = (self specialSelector: 17) "at:put:"]) ifTrue:
		[self flushAtCache]
]

{ #category : #'memory space primitives' }
StackInterpreterPrimitives >> primitiveFullGC [
	"Do a full garbage collection.  In SqueakV3ObjectMemory, answer the number
	 of bytes available (including swap space if dynamic memory management is
	 supported).  In Spur, answer the size of the largest free chunk."

	self externalWriteBackHeadFramePointers.
	super primitiveFullGC
]

{ #category : #'I/O primitives' }
StackInterpreterPrimitives >> primitiveGetCurrentWorkingDirectory [
	
	<export: true>
	<var: #aCString type: #'char *'>
	
	| aCString |
	
	aCString := self cCoerce: (self alloca: 255 + 1) to: #'char *'.

	(self ioGetCurrentWorkingDirectory: aCString maxLength: 255 + 1) = -1 
		ifTrue: [ ^ self primitiveFail ].

	self pop: argumentCount+1 thenPush: (objectMemory stringForCString: aCString).
]

{ #category : #'system control primitives' }
StackInterpreterPrimitives >> primitiveGetVMParameter: arg [ 
	"See primitiveVMParameter method comment.
	 N.B. written as a returning case to avoid branch limits in the V3 bytecode set."
	arg caseOf: {
			[1]  ->	[^self positiveMachineIntegerFor: objectMemory oldSpaceSize].
			[2]  ->	[^objectMemory integerObjectOf: objectMemory newSpaceSize].
			[3]  ->	[^self positiveMachineIntegerFor: objectMemory totalMemorySize].
			[6]  ->	[^objectMemory integerObjectOf: objectMemory tenuringThreshold].
			[7]  ->	[^objectMemory integerObjectOf: objectMemory statFullGCs].
			[8]  ->	[^objectMemory integerObjectOf: objectMemory statFullGCUsecs + 500 // 1000].
			[9]  ->	[^objectMemory integerObjectOf: (objectMemory hasSpurMemoryManagerAPI
														ifTrue: [objectMemory statScavenges]
														ifFalse: [objectMemory statIncrGCs])].
			[10] ->	[^objectMemory integerObjectOf: (objectMemory hasSpurMemoryManagerAPI
														ifTrue: [objectMemory statScavengeGCUsecs]
														ifFalse: [objectMemory statIncrGCUsecs]) + 500 // 1000].
			[11] ->	[^objectMemory integerObjectOf: objectMemory statTenures].
			[12] ->	[^ConstZero]. "Was JITTER VM info"
			[13] ->	[^ConstZero]. "Was JITTER VM info"
			[14] ->	[^ConstZero]. "Was JITTER VM info"
			[15] ->	[^ConstZero]. "Was JITTER VM info"
			[16] ->	[^self positive64BitIntegerFor: statIdleUsecs].
			[17] ->	[^(SistaVM and: [self isCog])
						ifTrue: [objectMemory floatObjectOf: self getCogCodeZoneThreshold]
						ifFalse: [ConstZero]].
			[18] ->	[^objectMemory hasSpurMemoryManagerAPI
						ifTrue: [objectMemory integerObjectOf: objectMemory statCompactionUsecs + 500 // 1000]
						ifFalse: [ConstZero]].
			[19] ->	[^objectMemory hasSpurMemoryManagerAPI
						ifTrue: [objectMemory integerObjectOf: objectMemory scavengeThresholdAsExtent]
						ifFalse: [ConstZero]].
			[20] ->	[^objectMemory positive64BitIntegerFor: self ioUTCStartMicroseconds].
			[21] ->	[^objectMemory integerObjectOf: objectMemory rootTableCount].
			[22] ->	[^objectMemory integerObjectOf: objectMemory statRootTableOverflows].
			[23] ->	[^objectMemory integerObjectOf: extraVMMemory].
			[24] ->	[^objectMemory integerObjectOf: objectMemory shrinkThreshold].
			[25] ->	[^objectMemory integerObjectOf: objectMemory growHeadroom].
			[26] ->	[^objectMemory integerObjectOf: self ioHeartbeatMilliseconds].
			[27] ->	[^objectMemory integerObjectOf: objectMemory statMarkCount].
			[28] ->	[^objectMemory integerObjectOf: objectMemory statSweepCount].
			[29] ->	[^objectMemory integerObjectOf: objectMemory statMkFwdCount].
			[30] ->	[^objectMemory integerObjectOf: objectMemory statCompMoveCount].
			[31] ->	[^objectMemory integerObjectOf: objectMemory statGrowMemory].
			[32] ->	[^objectMemory integerObjectOf: objectMemory statShrinkMemory].
			[33] ->	[^objectMemory integerObjectOf: objectMemory statRootTableCount].
			[34] ->	[^objectMemory hasSpurMemoryManagerAPI ifTrue:"was statAllocationCount"
						[objectMemory positive64BitIntegerFor: objectMemory currentAllocatedBytes]].
			[35] ->	[^objectMemory integerObjectOf: objectMemory statSurvivorCount].
			[36] ->	[^objectMemory integerObjectOf: (self microsecondsToMilliseconds: objectMemory statGCEndUsecs)].
			[37] ->	[^objectMemory integerObjectOf: objectMemory statSpecialMarkCount].
			[38] ->	[^objectMemory integerObjectOf: objectMemory statIGCDeltaUsecs + 500 // 1000].
			[39] ->	[^objectMemory integerObjectOf: statPendingFinalizationSignals].
			[40] ->	[^objectMemory integerObjectOf: objectMemory wordSize].
			[41] ->	[^objectMemory integerObjectOf: self imageFormatVersion].
			[42] ->	[^objectMemory integerObjectOf: numStackPages].
			[43] ->	[^objectMemory integerObjectOf: desiredNumStackPages].
			[44] ->	[^objectMemory integerObjectOf: objectMemory edenBytes].
			[45] ->	[^objectMemory integerObjectOf: desiredEdenBytes].
			[46] ->	[^self getCogCodeSize].
			[47] ->	[^self getDesiredCogCodeSize].
			[48] ->	[^self getCogVMFlags].
			[49] ->	[^objectMemory integerObjectOf: self ioGetMaxExtSemTableSize].
			[52] ->	[^objectMemory integerObjectOf: objectMemory rootTableCapacity].
			[53] ->	[^objectMemory hasSpurMemoryManagerAPI ifTrue:
						[objectMemory integerObjectOf: objectMemory numSegments]].
			[54] ->	[^objectMemory hasSpurMemoryManagerAPI ifTrue:
						[objectMemory integerObjectOf: objectMemory freeSize]].
			[55] ->	[^objectMemory hasSpurMemoryManagerAPI ifTrue:
						[objectMemory floatObjectOf: objectMemory getHeapGrowthToSizeGCRatio]].
			[56] ->	[^self positive64BitIntegerFor: statProcessSwitch].
			[57] ->	[^self positive64BitIntegerFor: statIOProcessEvents].
			[58] ->	[^self positive64BitIntegerFor: statForceInterruptCheck].
			[59] ->	[^self positive64BitIntegerFor: statCheckForEvents].
			[60] ->	[^self positive64BitIntegerFor: statStackOverflow].
			[61] ->	[^self positive64BitIntegerFor: statStackPageDivorce].
			[62] ->	[^self getCodeCompactionCount].
			[63] ->	[^self getCodeCompactionMSecs].
			[64] ->	[^self getCogMethodCount].
			[65] ->	[^self getCogVMFeatureFlags].
			[66] ->	[^objectMemory integerObjectOf: self stackPageByteSize].
			[67] ->	[^objectMemory hasSpurMemoryManagerAPI ifTrue:
						[objectMemory integerObjectOf: objectMemory maxOldSpaceSize]].
			[68] ->	[^objectMemory floatObjectOf: stackPages statAverageLivePagesWhenMapping].
			[69] ->	[^objectMemory integerObjectOf: stackPages statMaxPageCountWhenMapping].
			[70] ->	[^self integerObjectOf: (self cCode: 'VM_PROXY_MAJOR' inSmalltalk: [self class vmProxyMajorVersion])].
			[71] ->	[^self integerObjectOf: (self cCode: 'VM_PROXY_MINOR' inSmalltalk: [self class vmProxyMinorVersion])].
			[72] ->	[^objectMemory integerObjectOf: objectMemory statMarkUsecs + 500 // 1000].
			[73] ->	[^objectMemory integerObjectOf: objectMemory statSweepUsecs + 500 // 1000].
			[74] ->	[^objectMemory hasSpurMemoryManagerAPI ifTrue:
						[objectMemory integerObjectOf: objectMemory statMaxAllocSegmentTime + 500 // 1000]] }
		otherwise: [^nil]
]

{ #category : #'memory space primitives' }
StackInterpreterPrimitives >> primitiveIncrementalGC [
	"Do a quick, incremental garbage collection and return the number of bytes immediately available.
	 (Note: more space may be made available by doing a full garbage collection."

	self externalWriteBackHeadFramePointers.
	super primitiveIncrementalGC
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> primitiveInstVarAt [
	| index rcvr hdr fmt totalLength fixedFields value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1 "e.g. object:instVarAt:"
		and: [objectMemory isOopForwarded: rcvr]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	(objectMemory isImmediate: rcvr) ifTrue: [^self primitiveFailFor: PrimErrInappropriate].
	index := objectMemory integerValueOf: index.
	hdr := objectMemory baseHeader: rcvr.
	fmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := objectMemory fixedFieldsOf: rcvr format: fmt length: totalLength.
	(index >= 1 and: [index <= fixedFields]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	(fmt = objectMemory indexablePointersFormat
	 and: [objectMemory isContextHeader: hdr])
		ifTrue: [value := self externalInstVar: index - 1 ofContext: rcvr]
		ifFalse: [value := self subscript: rcvr with: index format: fmt].
	self pop: argumentCount + 1 thenPush: value
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> primitiveInstVarAtPut [
	| newValue index rcvr hdr fmt totalLength fixedFields |
	newValue := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 2 "e.g. object:instVarAt:put:"
		and: [objectMemory isOopForwarded: rcvr]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	(objectMemory isImmediate: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].
	(objectMemory isObjImmutable: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	index := objectMemory integerValueOf: index.
	hdr := objectMemory baseHeader: rcvr.
	fmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: rcvr baseHeader: hdr format: fmt.
	fixedFields := objectMemory fixedFieldsOf: rcvr format: fmt length: totalLength.
	(index >= 1 and: [index <= fixedFields]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	(fmt = objectMemory indexablePointersFormat
	 and: [objectMemory isContextHeader: hdr])
		ifTrue: [self externalInstVar: index - 1 ofContext: rcvr put: newValue]
		ifFalse: [self subscript: rcvr with: index storing: newValue format: fmt].
	self pop: argumentCount + 1 thenPush: newValue
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadBoolean8FromBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value byteSize |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= byteSize]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	value := self uint8AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory booleanObjectOf: value ~= 0)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadBoolean8FromExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	value := self uint8AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory booleanObjectOf: value ~= 0)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadChar16FromBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value byteSize |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 1) or: [byteSize < 2]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	value := self uint16AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory characterObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadChar16FromExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	value := self uint16AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory characterObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadChar32FromBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value byteSize |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 3) or: [byteSize < 4]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	value := self uint32AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory characterObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadChar32FromExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	value := self uint32AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory characterObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadChar8FromBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value byteSize |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= byteSize]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	value := self uint8AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory characterObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadChar8FromExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	value := self uint8AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory characterObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadFloat32FromBytes [
	<var: #bytes type: #'char*' >
	<var: #value type: #float >
	
	| index rcvr bytes value byteSize |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 3) or: [byteSize < 4]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	value := self singleFloatAtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory floatObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadFloat32FromExternalAddress [
	<var: #bytes type: #'char*' >
	<var: #value type: #float >
	
	| index rcvr bytes value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	value := self singleFloatAtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory floatObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadFloat64FromBytes [
	<var: #bytes type: #'char*' >
	<var: #value type: #double >
	
	| index rcvr bytes value byteSize |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 7) or: [byteSize < 8]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	value := self floatAtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory floatObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadFloat64FromExternalAddress [
	<var: #bytes type: #'char*' >
	<var: #value type: #double >
	
	| index rcvr bytes value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	value := self floatAtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory floatObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadInt16FromBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value byteSize |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 1) or: [byteSize < 2]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	value := self int16AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory integerObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadInt16FromExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	value := self int16AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory integerObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadInt32FromBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value byteSize |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 3) or: [byteSize < 4]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	value := self int32AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory signed32BitIntegerFor: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadInt32FromExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	value := self int32AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory signed32BitIntegerFor: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadInt64FromBytes [
	<var: #bytes type: #'char*' >
	<var: #value type: #sqLong >
	
	| index rcvr bytes value byteSize |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 7) or: [byteSize < 8]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	value := self int64AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory signed64BitIntegerFor: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadInt64FromExternalAddress [
	<var: #bytes type: #'char*' >
	<var: #value type: #sqLong >
	
	| index rcvr bytes value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	value := self int64AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory signed64BitIntegerFor: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadInt8FromBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value byteSize |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= byteSize]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	value := self int8AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory integerObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadInt8FromExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	value := self int8AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory integerObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadPointerFromBytes [
	<var: #bytes type: #'char*' >
	<var: #value type: #'char*' >
	
	| index rcvr bytes value byteSize object |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - (BytesPerWord  - 1)) or: [byteSize < BytesPerWord]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	value := self pointerAtPointer: bytes + index.
	object := objectMemory instantiateClass: objectMemory classExternalAddress indexableSize: BytesPerWord.
	self pointerAtPointer: (objectMemory firstIndexableField: object) put: value.
	
	self pop: argumentCount + 1 thenPush: object
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadPointerFromExternalAddress [
	<var: #bytes type: #'char*' >
	<var: #value type: #'char*' >
	
	| index rcvr bytes value object |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	value := self pointerAtPointer: bytes + index.
	object := objectMemory instantiateClass: objectMemory classExternalAddress indexableSize: BytesPerWord.
	self pointerAtPointer: (objectMemory firstIndexableField: object) put: value.
	
	self pop: argumentCount + 1 thenPush: object
]

{ #category : #ffi }
StackInterpreterPrimitives >> primitiveLoadSymbolFromModule [
	"Attempt to find the address of a symbol in a loaded library."

	| symbol module moduleHandle address oop symbolString symbolStringSize |

	<api>
	<var: #address type: #'void *'>
	<var: #ptr type: #'void **'>
	<var: #symbolString type: #'char *'>
	
	self methodArgumentCount = 2 ifFalse:
		[^self primitiveFailFor: PrimErrBadNumArgs].	

	module := self stackValue: 0.
	symbol := self stackValue: 1.

	(objectMemory isBytes: symbol)
		ifFalse: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	(objectMemory nilObject = module)
		ifFalse: [ (objectMemory nilObject = module or: [objectMemory isBytes: module])
							ifFalse: [ ^ self primitiveFailFor: PrimErrBadArgument ].
					
						moduleHandle := self loadModuleByName: module.
						self failed ifTrue:[ ^self ]].


	symbolString := objectMemory firstIndexableField: symbol.
	symbolStringSize := objectMemory byteSizeOf: symbol.

	address := self
					ioLoadSymbol: symbolString
					OfLength: symbolStringSize
					FromModule: moduleHandle.
	
	address = 0 ifTrue:
		[^self primitiveFailFor: PrimErrNotFound].
	
	oop := self newExternalAddressWithValue: address.
	
	^self methodReturnValue: oop
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadUInt16FromBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value byteSize |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 1) or: [byteSize < 2]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	value := self uint16AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory integerObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadUInt16FromExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	value := self uint16AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory integerObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadUInt32FromBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value byteSize |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 3) or: [byteSize < 4]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	value := self uint32AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory positive32BitIntegerFor: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadUInt32FromExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	value := self uint32AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory positive32BitIntegerFor: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadUInt64FromBytes [
	<var: #bytes type: #'char*' >
	<var: #value type: #usqLong >
	
	| index rcvr bytes value byteSize |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 7) or: [byteSize < 8]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	value := self uint64AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory positive64BitIntegerFor: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadUInt64FromExternalAddress [
	<var: #bytes type: #'char*' >
	<var: #value type: #usqLong >
	
	| index rcvr bytes value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	value := self uint64AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory positive64BitIntegerFor: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadUInt8FromBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value byteSize |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= byteSize]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	value := self uint8AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory integerObjectOf: value)
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveLoadUInt8FromExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value |
	index := self stackTop.
	rcvr := self stackValue: 1.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	value := self uint8AtPointer: bytes + index.
	self pop: argumentCount + 1 thenPush: (objectMemory integerObjectOf: value)
	
]

{ #category : #'process primitives' }
StackInterpreterPrimitives >> primitiveLongRunningPrimitive [
	"Primitive. Answer an Array with the current long-running primitive method identified by
	 the heartbeat, the minimum number of milliseconds it was active for, and the milliseconds
	 of GC activity there-in, or nil if none.  Since the longRunningPrimitiveCheckMethod is
	 sampled at interrupt time be careful to validate it before returning it."
	<export: true>
	| lrpcm result primms gcms |
	self methodArgumentCount = 0 ifFalse:
		[^self primitiveFail].
	self sqLowLevelMFence.
	(longRunningPrimitiveStopUsecs > longRunningPrimitiveStartUsecs "a hit"
	 and: [(lrpcm := longRunningPrimitiveCheckMethod) ~= nil			"there is a method"
	 and: [(self addressCouldBeObj: lrpcm)								"method looks valid"
	 and: [(self isFreeObject: lrpcm) not
	 and: [(self isCompiledMethod: lrpcm)]]]])
		ifTrue: [result := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 3.
				primms := (longRunningPrimitiveStopUsecs - longRunningPrimitiveStartUsecs) + 500 // 1000.
				
				gcms := longRunningPrimitiveGCUsecs + 500 // 1000.
				objectMemory storePointer: 0 ofObject: result withValue: lrpcm.
				objectMemory storePointerUnchecked: 1 ofObject: result withValue: (objectMemory integerObjectOf: primms).
				objectMemory storePointerUnchecked: 2 ofObject: result withValue: (objectMemory integerObjectOf: gcms)]
		ifFalse: [result := objectMemory nilObject].
	self pop: 1 thenPush: result.
	self voidLongRunningPrimitive: 'get'
]

{ #category : #'process primitives' }
StackInterpreterPrimitives >> primitiveLongRunningPrimitiveSemaphore [
	"Primitive. Install the semaphore to be used for collecting long-running primitives, 
	 or nil if no semaphore should be used."
	| sema |
	<export: true>
	sema := self stackValue: 0.
	((objectMemory isIntegerObject: sema)
	or: [self methodArgumentCount ~= 1]) ifTrue:
		[^self primitiveFail].
	sema = objectMemory nilObject
		ifTrue:
			[longRunningPrimitiveCheckSemaphore := nil]
		ifFalse:
			[(objectMemory isSemaphoreOop: sema) ifFalse:
				[^self primitiveFail].
			 longRunningPrimitiveCheckSemaphore := sema].
	self voidLongRunningPrimitive: 'install'.
	self pop: 1
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> primitiveObjectPointsTo [
	"This primitive is assumed to be fast (see e.g. MethodDictionary>>includesKey:) so make it so.
	 N.B.  Works forrectly for cogged methods too."
	| rcvr thang header fmt numSlots methodHeader |
	thang := self stackTop.
	rcvr := self stackValue: 1.
	(objectMemory isImmediate: rcvr) ifTrue:
		[^self pop: 2 thenPushBool: false].

	"Inlined version of lastPointerOf: for speed in determining if rcvr is a context."
	header := objectMemory baseHeader: rcvr.
	fmt := objectMemory formatOfHeader: header.
	(objectMemory isPointersFormat: fmt)
		ifTrue:
			[(fmt = objectMemory indexablePointersFormat
			  and: [objectMemory isContextHeader: header]) 
				ifTrue:
	 				[(self isMarriedOrWidowedContext: rcvr) ifTrue:
						[self externalWriteBackHeadFramePointers.
						 (self isStillMarriedContext: rcvr) ifTrue:
							[^self pop: 2
									thenPushBool: (self marriedContext: rcvr
														pointsTo: thang
														stackDeltaForCurrentFrame: 2)]].
					"contexts end at the stack pointer"
					numSlots := CtxtTempFrameStart + (self fetchStackPointerOf: rcvr)]
				ifFalse:
					[numSlots := objectMemory numSlotsOf: rcvr]]
		ifFalse:
			[fmt < objectMemory firstCompiledMethodFormat "no pointers" ifTrue:
				[^self pop: 2 thenPushBool: false].
			"CompiledMethod: contains both pointers and bytes:"
			methodHeader := objectMemory methodHeaderOf: rcvr.
			methodHeader = thang ifTrue: [^self pop: 2 thenPushBool: true].
			numSlots := (objectMemory literalCountOfMethodHeader: methodHeader) + LiteralStart].

	self assert: numSlots - 1 * objectMemory bytesPerOop + objectMemory baseHeaderSize = (objectMemory lastPointerOf: rcvr).
	objectMemory baseHeaderSize
		to: numSlots - 1 * objectMemory bytesPerOop + objectMemory baseHeaderSize
		by: objectMemory bytesPerOop
		do: [:i|
			(objectMemory longAt: rcvr + i) = thang ifTrue:
				[^self pop: 2 thenPushBool: true]].
	self pop: 2 thenPushBool: false
]

{ #category : #'control primitives' }
StackInterpreterPrimitives >> primitivePerform [
	<returnTypeC: #void>
	| newReceiver lookupClassTag performMethod |
	performMethod := newMethod.
	messageSelector := self stackValue: argumentCount - 1.
	newReceiver := self stackValue: argumentCount.

	"NOTE: the following lookup may fail and be converted to #doesNotUnderstand:,
	 so we must adjust argumentCount and slide args now, so that will work."

	"Slide arguments down over selector"
	argumentCount := argumentCount - 1.
	argumentCount to: 1 by: -1 do:
		[:i|
		stackPages
			longAt: stackPointer + (i * objectMemory wordSize)
			put: (stackPages longAt: stackPointer + ((i - 1) * objectMemory wordSize))].
	self pop: 1.
	lookupClassTag := objectMemory fetchClassTagOf: newReceiver.
	self sendBreakpoint: messageSelector receiver: newReceiver.
	self printSends ifTrue:
		[self printActivationNameForSelector: messageSelector
			startClass: (objectMemory classForClassTag: lookupClassTag); cr].
	self findNewMethodInClassTag: lookupClassTag.

	"Only test CompiledMethods for argument count - other objects will have to take their chances"
	((objectMemory isOopCompiledMethod: newMethod)
	  and: [(self argumentCountOf: newMethod) = argumentCount]) ifFalse:
		["Slide the args back up (sigh) and re-insert the selector."
		self unPop: 1.
		1 to: argumentCount by: 1 do:
			[:i |
			stackPages longAt: stackPointer + ((i - 1) * objectMemory wordSize)
				put: (stackPages longAt: stackPointer + (i * objectMemory wordSize))].
		stackPages longAt: stackPointer + (argumentCount * objectMemory wordSize) put: messageSelector.
		argumentCount := argumentCount + 1.
		newMethod := performMethod.
		 "Must reset primitiveFunctionPointer for checkForAndFollowForwardedPrimitiveState"
		 objectMemory hasSpurMemoryManagerAPI ifTrue:
			[primitiveFunctionPointer := #primitivePerform].
		^self primitiveFailFor: PrimErrBadNumArgs].

	self executeNewMethod.
	"Recursive xeq affects primErrorCode"
	self initPrimCall
]

{ #category : #'memory space primitives' }
StackInterpreterPrimitives >> primitivePin [
	"Pin or unpin the receiver, i.e. make it immobile or mobile, based on the argument.
	 Answer whether the object was already pinned. N.B. pinning does *not* prevent
	 an object from being garbage collected."
	| obj boolean wasPinned |
	objectMemory hasSpurMemoryManagerAPI ifFalse:
		[^self primitiveFailFor: PrimErrUnsupported].

	obj := self stackValue: 1.
	((objectMemory isImmediate: obj)
	 or: [objectMemory isForwarded: obj]) ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].

	boolean := self stackTop.
	(boolean = objectMemory falseObject
	 or: [boolean = objectMemory trueObject]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].

	(objectMemory isPinned: obj)
		ifTrue:
			[wasPinned := objectMemory trueObject.
			 boolean ~= wasPinned ifTrue:
				[objectMemory setIsPinnedOf: obj to: false]]
		ifFalse:
			[wasPinned := objectMemory falseObject.
			 boolean = objectMemory trueObject ifTrue:
				[((objectMemory isContext: obj)
				  and: [self isStillMarriedContext: obj]) ifTrue:
					[^self primitiveFailFor: PrimErrBadReceiver].
				 (objectMemory pinObject: obj) = 0 ifTrue:
					[^self primitiveFailFor: PrimErrNoMemory]]].
	
	self pop: argumentCount + 1 thenPush: wasPinned
]

{ #category : #ffi }
StackInterpreterPrimitives >> primitiveSameThreadCallout [
	<export: true>
	| externalFunction cif PARAM_EXTERNALFUNCTION PARAM_ARGUMENTS argumentsArrayOop argumentSize parameters returnHolder |
	<var: #parameters type: #'void **'>
	<var: #returnHolder type: #'void *'>
	<var: #externalFunction type: #'void *'>

	PARAM_EXTERNALFUNCTION := 1.
	PARAM_ARGUMENTS := 0.

	"1. Obtain externalFunction and extract the CIF"
	externalFunction := self getHandler: (self stackValue: PARAM_EXTERNALFUNCTION).
	self failed 
		ifTrue: [ 
			self logDebug: 'Invalid External Function Argument'.
			^ self primitiveFailFor: PrimErrBadArgument ].

	cif := self getHandlerAsCif:(objectMemory
				fetchPointer: 1
				ofObject: (self stackValue: PARAM_EXTERNALFUNCTION)).

	self failed
		ifTrue: [ 
			self logDebug: 'Invalid CIF in ExternalFunction'.
			^ self primitiveFailFor: PrimErrBadArgument ].

	" 2. Prepare Arguments:
	- Verify Arguments is an Array
	- Allocate space for all the arguments in the stack and a holder for the return, and the parameters' pointer C array
	- Marshall arguments and store in the parameter array."
	argumentsArrayOop := self stackValue: PARAM_ARGUMENTS.

	(objectMemory isArray: argumentsArrayOop)
		ifFalse: [ 
			self logDebug: 'Argument Array is not an Array'.
			^ self primitiveFailFor: PrimErrBadArgument ].

	argumentSize := cif numberArguments.

	(objectMemory slotSizeOf: argumentsArrayOop) = argumentSize
		ifFalse: [ 
			self logDebug: 'Argument Array size mismatch'.
			^ self primitiveFailFor: PrimErrBadArgument ].
		
	parameters := self allocateParameters: argumentSize 
		using: [:aSize | self alloca: (self sizeof: #'void*') * aSize ].

	0 to: argumentSize - 1 do: [ :i | 
		| argType argHolder |
		argType := cif argTypeAt: i.

		argHolder := self alloca: argType size.
		parameters at: i put: argHolder.
	
		self marshallArgumentFrom: argumentsArrayOop atIndex: i into: argHolder ofType: argType type withSize: argType size. 
				
		self failed 
				ifTrue: [ 
					self logDebug: 'Could not convert argument index: %d' _: i + 1.
					^ self primitiveFailFor: PrimErrBadArgument ]].
	
	returnHolder := self alloca: cif returnType size.

	" 3. Call and then return
	- Call
	- Marshall Argument and push it to the stack
	- Return"
	self
		ffi_call: cif
		_: externalFunction
		_: returnHolder
		_: parameters.

	self marshallAndPushReturnValueFrom: returnHolder ofType: cif returnType poping: 3.	

]

{ #category : #'memory space primitives' }
StackInterpreterPrimitives >> primitiveSetGCSemaphore [
	"Primitive. Indicate the semaphore to be signalled for upon garbage collection"
	| index |
	<export: true>
	index := self stackIntegerValue: 0.
	self successful ifTrue:[
		gcSemaphoreIndex := index.
		self pop: argumentCount.
	]
]

{ #category : #'system control primitives' }
StackInterpreterPrimitives >> primitiveSetVMParameter: index arg: argOop [
	"See primitiveVMParameter method comment"
	| arg result |

	"argOop read & checks; in most cases this is an integer parameter.  In some it is either an integer or a Float"
	(index = 17 or: [index = 55 or: [index = 68]])
		ifTrue:
			[((objectMemory isFloatInstance: argOop)
			  or: [objectMemory isIntegerObject: argOop]) ifFalse:
				[^self primitiveFailFor: PrimErrBadArgument]]
		ifFalse:
			[(objectMemory isIntegerObject: argOop) ifFalse:
				[^self primitiveFailFor: PrimErrBadArgument].
			 arg := objectMemory integerValueOf: argOop].

	"assume failure, then set success for handled indices"
	self primitiveFailFor: PrimErrBadArgument.
	index caseOf: {
		[5] ->	[objectMemory hasSpurMemoryManagerAPI ifFalse:
					["Was:
							result := allocationsBetweenGCs.
							allocationsBetweenGCs := arg."
						"Ignore for now, because old images won't start up otherwise.
						 See 45 for eden size setting."
					 result := objectMemory nilObject.
					 self initPrimCall]].
		[6] ->	[result := objectMemory integerObjectOf: objectMemory tenuringThreshold.
				 primFailCode := objectMemory tenuringThreshold: arg].
		[11] ->	[arg >= 0 ifTrue:
					[result := objectMemory integerObjectOf: objectMemory statTenures.
					 objectMemory statTenures: arg.
					 self initPrimCall]].
		[17] ->	[(SistaVM and: [self isCog]) ifTrue:
					[result := objectMemory floatObjectOf: self getCogCodeZoneThreshold.
					 primFailCode := self setCogCodeZoneThreshold: (self noInlineLoadFloatOrIntFrom: argOop)]].
		[23] ->	[result := objectMemory integerObjectOf: extraVMMemory.
				 extraVMMemory := arg.
				 self initPrimCall].
		[24] ->	[arg > 0 ifTrue:
					[result := objectMemory integerObjectOf: objectMemory shrinkThreshold.
					 objectMemory shrinkThreshold: arg.
					 self initPrimCall]].
		[25] ->	[arg > 0 ifTrue:
					[result := objectMemory integerObjectOf: objectMemory growHeadroom.
					 objectMemory growHeadroom: arg.
					 self initPrimCall]].
		[26] ->	[arg >= 0 ifTrue: "0 turns off the heartbeat"
					[result := objectMemory integerObjectOf: self ioHeartbeatMilliseconds.
					 self ioSetHeartbeatMilliseconds: arg.
					 self initPrimCall]].
		[34] ->	[(objectMemory hasSpurMemoryManagerAPI "was statAllocationCount; now statAllocatedBytes"
				  and: [arg >= 0]) ifTrue:
					[result := objectMemory positive64BitIntegerFor: objectMemory currentAllocatedBytes.
					 objectMemory setCurrentAllocatedBytesTo: arg.
					 self initPrimCall]].
		[43] ->	[(arg between: 0 and: 65535) ifTrue:
					[result := objectMemory integerObjectOf: desiredNumStackPages.
					 desiredNumStackPages := arg.
					 self initPrimCall]].
		[45] ->	[arg >= 0 ifTrue:
					[result := objectMemory integerObjectOf: desiredEdenBytes.
					 desiredEdenBytes := arg.
					 self initPrimCall]].
		[47] ->	[(self isCog
				  and: [arg between: 0 and: self maxCogCodeSize]) ifTrue:
					[result := objectMemory integerObjectOf: self getDesiredCogCodeSize.
					 self setDesiredCogCodeSize: arg.
					 self initPrimCall]].
		[48] ->	[arg >= 0 ifTrue:
					[result := objectMemory integerObjectOf: self getCogVMFlags.
					 self initPrimCall. "i.e. setCogVMFlags: can fail"
					 self setCogVMFlags: arg]].
		[49] ->	[(arg between: 0 and: 65535) ifTrue:
					[result := objectMemory integerObjectOf: self ioGetMaxExtSemTableSize.
					 self initPrimCall. "i.e. ioSetMaxExtSemTableSize: is allowed to fail"
					 self setMaxExtSemSizeTo: arg]].
		[55] ->	[objectMemory hasSpurMemoryManagerAPI ifTrue:
					[result := objectMemory floatObjectOf: objectMemory getHeapGrowthToSizeGCRatio.
					 primFailCode := objectMemory setHeapGrowthToSizeGCRatio: (self noInlineLoadFloatOrIntFrom: argOop)]].
		[67] ->	[(arg >= 0
				  and: [objectMemory hasSpurMemoryManagerAPI]) ifTrue:
					[result := objectMemory integerObjectOf: objectMemory maxOldSpaceSize.
					 primFailCode := objectMemory setMaxOldSpaceSize: arg]].
		[68] ->	[result := objectMemory floatObjectOf: stackPages statAverageLivePagesWhenMapping.
				 self initPrimCall. "i.e. statAverageLivePagesWhenMapping: is allowed to fail"
				 stackPages statAverageLivePagesWhenMapping: (self noInlineLoadFloatOrIntFrom: argOop)].
		[69] ->	[arg >= 0 ifTrue:
					[result := objectMemory integerObjectOf: stackPages statMaxPageCountWhenMapping.
					 stackPages statMaxPageCountWhenMapping: arg.
					 self initPrimCall]].
		[74] ->	[(arg >= 0
				  and: [objectMemory hasSpurMemoryManagerAPI]) ifTrue:
					[result := objectMemory integerObjectOf: objectMemory statMaxAllocSegmentTime + 500 // 1000.
					 stackPages statMaxAllocSegmentTime: arg. "usually 0"
					 self initPrimCall]] }
		otherwise: [].

	self successful
		ifTrue: [self methodReturnValue: result]  "return old value"
		ifFalse: [self primitiveFailFor: PrimErrInappropriate] "attempting to write a read-only or non-existent parameter"
]

{ #category : #'system control primitives' }
StackInterpreterPrimitives >> primitiveSignalAtMilliseconds [
	"Cause the time semaphore, if one has been registered, to be
	 signalled when the microsecond clock is greater than or equal to
	 the given tick value. A tick value of zero turns off timer interrupts."
	| msecsObj msecs deltaMsecs sema |
	<var: #msecs type: #usqInt>
	<var: #deltaMsecs type: #sqLong>
	msecsObj := self stackTop.
	sema := self stackValue: 1.
	msecs := self positive32BitValueOf: msecsObj.
	
	self successful ifTrue:
		[(objectMemory isSemaphoreOop: sema) ifTrue:
			[objectMemory splObj: TheTimerSemaphore put: sema.
			 deltaMsecs := msecs - (self ioMSecs bitAnd: MillisecondClockMask).
			 deltaMsecs < 0 ifTrue:
				[deltaMsecs := deltaMsecs + MillisecondClockMask + 1].
			 nextWakeupUsecs := self ioUTCMicroseconds + (deltaMsecs * 1000).
			 ^self pop: 2].
		 sema = objectMemory nilObject ifTrue:
			[objectMemory
				storePointer: TheTimerSemaphore
				ofObject: objectMemory specialObjectsOop
				withValue: objectMemory nilObject.
			 nextWakeupUsecs := 0.
			 ^self pop: 2]].
	self primitiveFailFor: PrimErrBadArgument
]

{ #category : #'system control primitives' }
StackInterpreterPrimitives >> primitiveSignalAtUTCMicroseconds [
	"Cause the time semaphore, if one has been registered, to be
	 signalled when the microsecond clock is greater than or equal to
	 the given tick value. A tick value of zero turns off timer interrupts."
	| usecsObj sema usecs |
	<var: #usecs type: #usqLong>
	usecsObj := self stackTop.
	sema := self stackValue: 1.
	usecs := self positive64BitValueOf: usecsObj.
	self successful ifTrue:
		[(objectMemory isSemaphoreOop: sema) ifTrue:
			[objectMemory splObj: TheTimerSemaphore put: sema.
			 nextWakeupUsecs := usecs.
			 ^self pop: 2].
		 sema = objectMemory nilObject ifTrue:
			[objectMemory
				storePointer: TheTimerSemaphore
				ofObject: objectMemory specialObjectsOop
				withValue: objectMemory nilObject.
			 nextWakeupUsecs := 0.
			 ^self pop: 2]].
	self primitiveFailFor: PrimErrBadArgument
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> primitiveSlotAt [
	"Answer a slot in an object.  This numbers all slots from 1, ignoring the distinction between
	 named and indexed inst vars.  In objects with both named and indexed inst vars, the named
	 inst vars precede the indexed ones.  In non-object indexed objects (objects that contain
	 bits, not object references) this primitive answers the raw integral value at each slot. 
	 e.g. for Strings it answers the character code, not the Character object at each slot."
	| index rcvr fmt numSlots |
	index := self stackTop.
	rcvr := self stackValue: 1.
	(objectMemory isIntegerObject: index) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	(objectMemory isImmediate: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].
	fmt := objectMemory formatOf: rcvr.
	index := (objectMemory integerValueOf: index) - 1.

	fmt <= objectMemory lastPointerFormat ifTrue:
		[numSlots := objectMemory numSlotsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[| value numLiveSlots |
			 (objectMemory isContextNonImm: rcvr)
				ifTrue:
					[self externalWriteBackHeadFramePointers.
					 numLiveSlots := (self stackPointerForMaybeMarriedContext: rcvr) + CtxtTempFrameStart.
					 value := (self asUnsigned: index) < numLiveSlots
								ifTrue: [self externalInstVar: index ofContext: rcvr]
								ifFalse: [objectMemory nilObject]]
				ifFalse:
					[value := objectMemory fetchPointer: index ofObject: rcvr].
			 self pop: argumentCount + 1 thenPush: value.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	fmt >= objectMemory firstByteFormat ifTrue:
		[fmt >= objectMemory firstCompiledMethodFormat ifTrue:
			[^self primitiveFailFor: PrimErrUnsupported].
		 numSlots := objectMemory numBytesOfBytes: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[self pop: argumentCount + 1 thenPushInteger: (objectMemory fetchByte: index ofObject: rcvr).
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	(objectMemory hasSpurMemoryManagerAPI
	 and: [fmt >= objectMemory firstShortFormat]) ifTrue:
		[numSlots := objectMemory num16BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[self pop: argumentCount + 1 thenPushInteger: (objectMemory fetchUnsignedShort16: index ofObject: rcvr).
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	fmt = objectMemory sixtyFourBitIndexableFormat ifTrue:
		[numSlots := objectMemory num64BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[self pop: argumentCount + 1
				thenPush: (self positive64BitIntegerFor: (objectMemory fetchLong64: index ofObject: rcvr)).
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	fmt >= objectMemory firstLongFormat ifTrue:
		[numSlots := objectMemory num32BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[self pop: argumentCount + 1
				thenPush: (self positive32BitIntegerFor: (objectMemory fetchLong32: index ofObject: rcvr)).
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	^self primitiveFailFor: PrimErrBadReceiver
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> primitiveSlotAtPut [
	"Assign a slot in an object.  This numbers all slots from 1, ignoring the distinction between
	 named and indexed inst vars.  In objects with both named and indexed inst vars, the named
	 inst vars precede the indexed ones.  In non-object indexed objects (objects that contain
	 bits, not object references) this primitive assigns a raw integral value at each slot."
	| newValue index rcvr fmt numSlots value |
	newValue := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	(objectMemory isIntegerObject: index) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	(objectMemory isImmediate: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].
	(objectMemory isObjImmutable: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].

	fmt := objectMemory formatOf: rcvr.
	index := (objectMemory integerValueOf: index) - 1.

	fmt <= objectMemory lastPointerFormat ifTrue:
		[numSlots := objectMemory numSlotsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[(objectMemory isContextNonImm: rcvr)
				ifTrue: [self externalInstVar: index ofContext: rcvr put: newValue]
				ifFalse: [objectMemory storePointer: index ofObject: rcvr withValue: newValue].
			 self pop: argumentCount + 1 thenPush: newValue.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	value := self positiveMachineIntegerValueOf: newValue.
	self failed ifTrue:
		[primFailCode := PrimErrBadArgument.
		^0].

	fmt >= objectMemory firstByteFormat ifTrue:
		[fmt >= objectMemory firstCompiledMethodFormat ifTrue:
			[^self primitiveFailFor: PrimErrUnsupported].
		 (self asUnsigned: value) > 16rFF ifTrue:
			[^self primitiveFailFor: PrimErrBadArgument].
		 numSlots := objectMemory numBytesOfBytes: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[objectMemory storeByte: index ofObject: rcvr withValue: value.
			 self pop: argumentCount + 1 thenPush: newValue.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	(objectMemory hasSpurMemoryManagerAPI
	 and: [fmt >= objectMemory firstShortFormat]) ifTrue:
		[(self asUnsigned: value) > 16rFFFF ifTrue:
			[^self primitiveFailFor: PrimErrBadArgument].
		 numSlots := objectMemory num16BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[objectMemory storeShort16: index ofObject: rcvr withValue: value.
			 self pop: argumentCount + 1 thenPush: newValue.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	(objectMemory bytesPerOop = 8
	 and: [fmt = objectMemory sixtyFourBitIndexableFormat]) ifTrue:
		[numSlots := objectMemory num64BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[objectMemory storeLong64: index ofObject: rcvr withValue: value.
			 self pop: argumentCount + 1 thenPush: newValue.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	fmt >= objectMemory firstLongFormat ifTrue:
		[(objectMemory wordSize > 4
		  and: [(self asUnsigned: value) > 16rFFFFFFFF]) ifTrue:
			[^self primitiveFailFor: PrimErrBadArgument].
		 numSlots := objectMemory num32BitUnitsOf: rcvr.
		 (self asUnsigned: index) < numSlots ifTrue:
			[objectMemory storeLong32: index ofObject: rcvr withValue: value.
			 self pop: argumentCount + 1 thenPush: newValue.
			 ^0].
		 ^self primitiveFailFor: PrimErrBadIndex].

	^self primitiveFailFor: PrimErrBadReceiver
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreBoolean8IntoBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject byteSize |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 2 ]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	valueObject = objectMemory trueObject ifTrue: [
		value := 1
	] ifFalse: [
		valueObject = objectMemory falseObject
			ifTrue: [ value := 0 ]
			ifFalse: [ ^ self primitiveFailFor: PrimErrBadArgument ]
	].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= byteSize]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	self uint8AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreBoolean8IntoExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 2 ]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	valueObject = objectMemory trueObject ifTrue: [
		value := 1
	] ifFalse: [
		valueObject = objectMemory falseObject
			ifTrue: [ value := 0 ]
			ifFalse: [ ^ self primitiveFailFor: PrimErrBadArgument ]
	].
	
	self uint8AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreChar16IntoBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject byteSize |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isCharacterObject: valueObject) not or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory characterValueOf: valueObject.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 1) or: [byteSize < 2]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	self uint16AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreChar16IntoExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isCharacterObject: valueObject) not or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory characterValueOf: valueObject.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	self uint16AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreChar32IntoBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject byteSize |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isCharacterObject: valueObject) not or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := self characterValueOf: valueObject.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 3) or: [byteSize < 4]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	self uint32AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreChar32IntoExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isCharacterObject: valueObject) not or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := self characterValueOf: valueObject.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	self uint32AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreChar8IntoBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject byteSize |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isCharacterObject: valueObject) not or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory characterValueOf: valueObject.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= byteSize]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	self uint8AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreChar8IntoExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isCharacterObject: valueObject) not or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory characterValueOf: valueObject.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	self uint8AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreFloat32IntoBytes [
	<var: #bytes type: #'char*' >
	<var: #value type: #double >
	
	| index rcvr bytes value valueObject byteSize |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isFloatObject: valueObject) not or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory floatValueOf: valueObject.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 3) or: [byteSize < 4]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	self singleFloatAtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreFloat32IntoExternalAddress [
	<var: #bytes type: #'char*' >
	<var: #value type: #double >
	
	| index rcvr bytes value valueObject |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isFloatObject: valueObject) not or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory floatValueOf: valueObject.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	self singleFloatAtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreFloat64IntoBytes [
	<var: #bytes type: #'char*' >
	<var: #value type: #double >
	
	| index rcvr bytes value valueObject byteSize |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isFloatObject: valueObject) not or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory floatValueOf: valueObject.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 7) or: [byteSize < 8]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	self floatAtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreFloat64IntoExternalAddress [
	<var: #bytes type: #'char*' >
	<var: #value type: #double >
	
	| index rcvr bytes value valueObject |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isFloatObject: valueObject) not or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory floatValueOf: valueObject.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	self floatAtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreInt16IntoBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject byteSize |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory integerValueOf: valueObject.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 1) or: [byteSize < 2]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	self int16AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreInt16IntoExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory integerValueOf: valueObject.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	self int16AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreInt32IntoBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject byteSize |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := self signed32BitValueOf: valueObject.
	self failed ifTrue: [ ^ nil ].

	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 3) or: [byteSize < 4]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	self int32AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreInt32IntoExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := self signed32BitValueOf: valueObject.
	self failed ifTrue: [ ^ nil ].
	
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	self int32AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreInt64IntoBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject byteSize |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := self signed64BitValueOf: valueObject.
	self failed ifTrue: [ ^ nil ].
	
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 7) or: [byteSize < 8]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	self int64AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreInt64IntoExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := self signed64BitValueOf: valueObject.
	self failed ifTrue: [ ^ nil ].
	
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	self int64AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreInt8IntoBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject byteSize |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory integerValueOf: valueObject.
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= byteSize]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	self int8AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreInt8IntoExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory integerValueOf: valueObject.
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	self int8AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStorePointerIntoBytes [
	<var: #bytes type: #'char*' >
	<var: #valueBytes type: #'char*' >
	
	| index rcvr bytes valueBytes valueObject byteSize |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 argumentCount > 2 ]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	valueBytes := objectMemory firstBytePointerOfDataObject: valueObject.
	valueBytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - (BytesPerWord  - 1)) or: [byteSize < BytesPerWord]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	self pointerAtPointer: bytes + index put: (self pointerAtPointer: valueBytes).
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStorePointerIntoExternalAddress [
	<var: #bytes type: #'char*' >
	<var: #valueBytes type: #'char*' >
	
	| index rcvr bytes valueBytes valueObject |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 argumentCount > 2 ]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	valueBytes := objectMemory firstBytePointerOfDataObject: valueObject.
	valueBytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	self pointerAtPointer: bytes + index put: (self pointerAtPointer: valueBytes).
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> primitiveStoreStackp [
	"Atomic store into context stackPointer. 
	Also ensures that any newly accessible cells are initialized to nil "
	| ctxt newStackp theFP thePage onCurrentPage stackp |
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	ctxt := self stackValue: 1.
	newStackp := self stackIntegerValue: 0.
	(self successful
	 and: [newStackp between: 0 and: (objectMemory numSlotsOf: ctxt) - CtxtTempFrameStart]) ifFalse:
		[^self primitiveFail].
	self externalWriteBackHeadFramePointers.
	(self isStillMarriedContext: ctxt) ifTrue:
		[theFP := self frameOfMarriedContext: ctxt.
		 thePage := stackPages stackPageFor: theFP.
		 ((onCurrentPage := thePage = stackPage)
		 and: [theFP = framePointer]) ifTrue:
			[^self primitiveFail]. "Probably easy to do this right here right now (just move stackPointer).  But fail for now."
		 self externalDivorceFrame: theFP andContext: ctxt.
		 onCurrentPage
			ifTrue:
				[self setStackPointersFromPage: stackPage]
			ifFalse:
				[self assert: stackPage = (stackPages stackPageFor: framePointer).
				 stackPages markStackPageMostRecentlyUsed: stackPage]].
	stackp := self fetchStackPointerOf: ctxt.
	"Nil any newly accessible cells"
	stackp + 1 to: newStackp do:
		[:i | objectMemory storePointerUnchecked: i + CtxtTempFrameStart - 1 ofObject: ctxt withValue: objectMemory nilObject].
	self storeStackPointerValue: newStackp inContext: ctxt.
	self ensureContextIsExecutionSafeAfterAssignToStackPointer: ctxt.
	self pop: 1
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreUInt16IntoBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject byteSize |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory integerValueOf: valueObject.
	value < 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 1) or: [byteSize < 2]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	self uint16AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreUInt16IntoExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory integerValueOf: valueObject.
	value < 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	self uint16AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreUInt32IntoBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject byteSize |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := self positive32BitValueOf: valueObject.
	self failed ifTrue: [ ^ nil ].
	
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 3) or: [byteSize < 4]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	self uint32AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreUInt32IntoExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := self positive32BitValueOf: valueObject.
	self failed ifTrue: [ ^ nil ].
	
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	self uint32AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreUInt64IntoBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject byteSize |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := self positive64BitValueOf: valueObject.
	self failed ifTrue: [ ^ nil ].
	
	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= (byteSize - 7) or: [byteSize < 8]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	self uint64AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreUInt64IntoExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := self positive64BitValueOf: valueObject.
	self failed ifTrue: [ ^ nil ].
	
	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	self uint64AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreUInt8IntoBytes [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject byteSize |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory integerValueOf: valueObject.
	value < 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	bytes := objectMemory firstBytePointerOfDataObject: rcvr.
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	byteSize := objectMemory numBytesOf: rcvr.
	(index < 0 or: [index >= byteSize]) ifTrue:
		[^self primitiveFailFor: PrimErrBadIndex].
	
	self uint8AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'ffi - memory accessor primitives' }
StackInterpreterPrimitives >> primitiveStoreUInt8IntoExternalAddress [
	<var: #bytes type: #'char*' >
	
	| index rcvr bytes value valueObject |
	valueObject := self stackTop.
	index := self stackValue: 1.
	rcvr := self stackValue: 2.
	((objectMemory isNonIntegerObject: index) or: [
	 (objectMemory isNonIntegerObject: valueObject) or: [
	 argumentCount > 2 ]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	value := objectMemory integerValueOf: valueObject.
	value < 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	bytes := self pointerAtPointer: (objectMemory firstBytePointerOfDataObject: rcvr).
	bytes == 0 ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].
	
	self uint8AtPointer: bytes + index put: value.
	self pop: argumentCount + 1 thenPush: valueObject
	
]

{ #category : #'control primitives' }
StackInterpreterPrimitives >> primitiveTerminateTo [
	"Primitive. Terminate up the context stack from the receiver up to but not including
	 the argument, if previousContext is on my Context stack. Make previousContext my
	 sender. This prim has to shadow the code in ContextPart>terminateTo: to be correct."
	| thisCtx currentCtx aContextOrNil contextsFP contextsSP contextsIP nextCntx stackedReceiverOffset 
	  theFP newFP newSP pageToStopOn thePage frameAbove |
	<var: #contextsFP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #newFP type: #'char *'>
	<var: #newSP type: #'char *'>
	<var: #contextsIP type: #usqInt>
	<var: #frameAbove type: #'char *'>
	<var: #contextsSP type: #'char *'>
	<var: #source type: #'char *'>
	<var: #pageToStopOn type: #'StackPage *'>
	<var: #thePage type: #'StackPage *'>

	aContextOrNil := self stackTop.
	(aContextOrNil = objectMemory nilObject or: [objectMemory isContext: aContextOrNil]) ifFalse:
		[^self primitiveFail].
	thisCtx := self stackValue: 1.
	thisCtx = aContextOrNil ifTrue:
		[^self primitiveFail].		

	"All stackPages need to have current head pointers to avoid confusion."
	self externalWriteBackHeadFramePointers.

	"If we're searching for aContextOrNil it might be on a stack page.  Helps to know
	 if we can free a whole page or not, or if we can short-cut the termination."
	(aContextOrNil ~= objectMemory nilObject and: [self isStillMarriedContext: aContextOrNil])
		ifTrue: [contextsFP := self frameOfMarriedContext: aContextOrNil.
				pageToStopOn := stackPages stackPageFor: contextsFP]
		ifFalse: [pageToStopOn := 0].

	"if thisCtx is married ensure it is a base frame.  Then we can assign its sender."
	(self isStillMarriedContext: thisCtx)
		ifTrue:
			[theFP := self frameOfMarriedContext: thisCtx.
			 "Optimize terminating thisContext.  Move its frame down to be next to
			  aContextOrNil's frame. Common in the exception system and so helps to be fast."
			 (theFP = framePointer
			  and: [pageToStopOn = stackPage]) ifTrue:
				[(self frameCallerFP: theFP) ~= contextsFP ifTrue:
					[stackedReceiverOffset := self frameStackedReceiverOffset: theFP.
					 frameAbove := self findFrameAbove: contextsFP inPage: pageToStopOn.
					 contextsIP := (self frameCallerSavedIP: frameAbove) asUnsignedInteger.
					 newSP := self frameCallerSP: frameAbove.
					 newFP := newSP - stackedReceiverOffset - objectMemory wordSize.
					 theFP + stackedReceiverOffset
						to: stackPointer
						by: objectMemory wordSize negated
						do: [:source|
							newSP := newSP - objectMemory wordSize.
							stackPages longAt: newSP put: (stackPages longAt: source)].
					 stackPages longAt: newFP + FoxSavedFP put: contextsFP.
					 stackPages longAt: newFP + FoxCallerSavedIP put: contextsIP.
					 self assert: (objectMemory isContext: thisCtx).
					 objectMemory storePointerUnchecked: SenderIndex
						ofObject: thisCtx
						withValue: (self withSmallIntegerTags: newFP).
					 objectMemory storePointerUnchecked: InstructionPointerIndex
						ofObject: thisCtx
						withValue: (self withSmallIntegerTags: contextsFP).
					 framePointer := newFP.
					 stackPointer := newSP].
				self pop: 1.
				self assert: stackPage = stackPages mostRecentlyUsedPage.
				^nil].
			 theFP := self externalEnsureIsBaseFrame: theFP. "May cause a GC!!"
			 currentCtx := self frameCallerContext: theFP.
			 "May also reclaim aContextOrNil's page, hence..."
			 (aContextOrNil ~= objectMemory nilObject and: [self isStillMarriedContext: aContextOrNil])
				ifTrue: [contextsFP := self frameOfMarriedContext: aContextOrNil.
						pageToStopOn := stackPages stackPageFor: contextsFP]
				ifFalse: [pageToStopOn := 0]]
		ifFalse:
			[currentCtx := objectMemory fetchPointer: SenderIndex ofObject: thisCtx].

	(self context: thisCtx hasSender: aContextOrNil) ifTrue:
		["Need to walk the stack freeing stack pages and nilling contexts."
		[currentCtx = aContextOrNil
		 or: [currentCtx = objectMemory nilObject]] whileFalse:
			[self assert: (objectMemory isContext: currentCtx).
			 (self isMarriedOrWidowedContext: currentCtx)
				ifTrue:
					[theFP := self frameOfMarriedContext: currentCtx.
					thePage := stackPages stackPageFor: theFP.
					"If externalEnsureIsBaseFrame: above has moved thisContext to its own stack
					 then we will always terminate to a frame on a different page.  But if we are
					 terminating some other context to a context somewhere on the current page
					 we must save the active frames above that context.  Things will look e.g. like this:
		thisCtx			499383332 s MethodContext(ContextPart)>resume:
						499380484 s BlockClosure>ensure:
						499377320 s MethodContext(ContextPart)>handleSignal:
						499373760 s MethodContext(ContextPart)>handleSignal:
						499372772 s MessageNotUnderstood(Exception)>signal
						499369068 s CodeSimulationTests(Object)>doesNotUnderstand: absentMethod
						499368708 s [] in CodeSimulationTests>testDNU
							(sender is 0xbffc2480 I CodeSimulationTests>runSimulated:)
						------------
		framePointer	0xbffc234c M MethodContext(ContextPart)>doPrimitive:method:receiver:args:
						0xbffc2378 M MethodContext(ContextPart)>tryPrimitiveFor:receiver:args:
						0xbffc23ac M MethodContext(ContextPart)>send:to:with:super:
						0xbffc23e4 M MethodContext(ContextPart)>send:super:numArgs:
						0xbffc2418 M MethodContext(InstructionStream)>interpretNextInstructionFor:
						0xbffc2434 M MethodContext(ContextPart)>step
						0xbffc2458 I MethodContext(ContextPart)>runSimulated:contextAtEachStep:
						------------
(499368708's sender)	0xbffc2480 I CodeSimulationTests>runSimulated:
						0xbffc249c M CodeSimulationTests>testDNU
						0xbffc24bc I CodeSimulationTests(TestCase)>performTest
						0xbffc24dc I [] in CodeSimulationTests(TestCase)>runCase
		aContextOrNil	0xbffc24fc M BlockClosure>ensure:
						0xbffc2520 I CodeSimulationTests(TestCase)>runCase
						0xbffc253c M [] in TestResult>runCase:
					When we find this case we move the frames above to a new page by making the
					frame above currentCtx a base frame, i.e. making 0xbffc2458 in the above example
					a base frame.  But in this iteration of the loop we don't move down a frame i.e. currentCtx
					doesn't change on this iteration."
					thePage = stackPage
						ifTrue:
							[frameAbove := self findFrameAbove: theFP inPage: thePage.
							self assert: frameAbove ~= 0.
							frameAbove := self externalEnsureIsBaseFrame: frameAbove. "May cause a GC!! May also reclaim aContextOrNil's page, hence..."
							(aContextOrNil ~= objectMemory nilObject and: [self isStillMarriedContext: aContextOrNil])
								ifTrue: [contextsFP := self frameOfMarriedContext: aContextOrNil.
										pageToStopOn := stackPages stackPageFor: contextsFP]
								ifFalse: [pageToStopOn := 0]]
						ifFalse:
							[thePage = pageToStopOn
								ifTrue:
									["We're here.  Cut back the stack to aContextOrNil's frame,
									  push its instructionPointer if it's not already a head frame,
									  and we're done."
									 frameAbove := self findFrameAbove: contextsFP inPage: thePage.
									 frameAbove ~= 0 ifTrue:
										[contextsSP := (self frameCallerSP: frameAbove) - objectMemory wordSize.
										 stackPages longAt: contextsSP put: (self frameCallerSavedIP: frameAbove).
										 self setHeadFP: contextsFP andSP: contextsSP inPage: thePage].
									 currentCtx := aContextOrNil]
								ifFalse:
									["We can free the entire page without further ado."
									 currentCtx := self frameCallerContext: thePage baseFP.
									 "for a short time invariant is violated; assert follows"
									 stackPages freeStackPageNoAssert: thePage]]]
				ifFalse:
					[nextCntx := objectMemory fetchPointer: SenderIndex ofObject: currentCtx.
					 self markContextAsDead: currentCtx.
					 currentCtx := nextCntx]]].
	self assert: stackPages pageListIsWellFormed.
	(self isMarriedOrWidowedContext: thisCtx)
		ifTrue:
			[self assert: (self checkIsStillMarriedContext: thisCtx currentFP: framePointer).
			 self assert: (self isBaseFrame: (self frameOfMarriedContext: thisCtx)).
			 theFP := self frameOfMarriedContext: thisCtx.
			 self frameCallerContext: theFP put: aContextOrNil]
		ifFalse: [objectMemory storePointer: SenderIndex ofObject: thisCtx withValue: aContextOrNil].
	self pop: 1.
	self assert: stackPage = stackPages mostRecentlyUsedPage
]

{ #category : #'system control primitives' }
StackInterpreterPrimitives >> primitiveVMParameter [
	"Behaviour depends on argument count:
		0 args:	return an Array of VM parameter values;
		1 arg:	return the indicated VM parameter;
		2 args:	set the VM indicated parameter.
	VM parameters are numbered as follows:
		1	end (v3)/size(Spur) of old-space (0-based, read-only)
		2	end (v3)/size(Spur) of young/new-space (read-only)
		3	end (v3)/size(Spur) of heap (read-only)
		4	nil (was allocationCount (read-only))
		5	nil (was allocations between GCs (read-write)
		6	survivor count tenuring threshold (read-write)
		7	full GCs since startup (read-only)
		8	total milliseconds in full GCs since startup (read-only)
		9	incremental GCs (SqueakV3) or scavenges (Spur) since startup (read-only)
		10	total milliseconds in incremental GCs (SqueakV3) or scavenges (Spur) since startup (read-only)
		11	tenures of surving objects since startup or reset (read-write)
		12-20 were specific to ikp's JITTER VM, now 12-15 are open for use
		16	total microseconds at idle since start-up (if non-zero)
		17	fraction of the code zone to use (Sista only; used to control code zone use to preserve sendAndBranchData on counter tripped callback)
		18	total milliseconds in compaction phase of full GC since start-up (Spur only)
		19	scavenge threshold, the effective size of eden.  When eden fills to the threshold a scavenge is scheduled. Newer Spur VMs only.
		20	utc microseconds at VM start-up (actually at time initialization, which precedes image load).
		21	root/remembered table size (occupancy) (read-only)
		22	root table overflows since startup (read-only)
		23	bytes of extra memory to reserve for VM buffers, plugins, etc (stored in image file header).
		24	memory threshold above which shrinking object memory (rw)
		25	memory headroom when growing object memory (rw)
		26	interruptChecksEveryNms - force an ioProcessEvents every N milliseconds (rw)
		27	number of times mark loop iterated for current IGC/FGC (read-only) includes ALL marking
		28	number of times sweep loop iterated for current IGC/FGC (read-only)
		29	number of times make forward loop iterated for current IGC/FGC (read-only)
		30	number of times compact move loop iterated for current IGC/FGC (read-only)
		31	number of grow memory requests (read-only)
		32	number of shrink memory requests (read-only)
		33	number of root table entries used for current IGC/FGC (read-only)
		34	Spur: bytes allocated in total since start-up or reset (read-write) (Used to be number of allocations done before current IGC/FGC (read-only))
		35	number of survivor objects after current IGC/FGC (read-only)
		36	millisecond clock when current IGC/FGC completed (read-only)
		37	number of marked objects for Roots of the world, not including Root Table entries for current IGC/FGC (read-only)
		38	milliseconds taken by current IGC (read-only)
		39	Number of finalization signals for Weak Objects pending when current IGC/FGC completed (read-only)
		40	BytesPerOop for this image
		41	imageFormatVersion for the VM
		42	number of stack pages in use
		43	desired number of stack pages (stored in image file header, max 65535)
		44	size of eden, in bytes
		45	desired size of eden, in bytes (stored in image file header)
		46	machine code zone size, in bytes (Cog only; otherwise nil)
		47	desired machine code zone size (stored in image file header; Cog only; otherwise nil)
		48	various header flags.  See getCogVMFlags.
		49	max size the image promises to grow the external semaphore table to (0 sets to default, which is 256 as of writing)
		50-51 nil; reserved for VM parameters that persist in the image (such as eden above)
		52	root/remembered table capacity
		53	number of segments (Spur only; otherwise nil)
		54	total size of free old space (Spur only, otherwise nil)
		55	ratio of growth and image size at or above which a GC will be performed post scavenge
		56	number of process switches since startup (read-only)
		57	number of ioProcessEvents calls since startup (read-only)
		58	number of ForceInterruptCheck calls since startup (read-only)
		59	number of check event calls since startup (read-only)
		60	number of stack page overflows since startup (read-only)
		61	number of stack page divorces since startup (read-only)
		62	compiled code compactions since startup (read-only; Cog only; otherwise nil)
		63	total milliseconds in compiled code compactions since startup (read-only; Cog only; otherwise nil)
		64	the number of methods that currently have jitted machine-code
		65	whether the VM supports a certain feature, MULTIPLE_BYTECODE_SETS is bit 0, IMMUTABILITY is bit 1
		66	the byte size of a stack page
		67	the max allowed size of old space (Spur only; nil otherwise; 0 implies no limit except that of the underlying platform)
		68	the average number of live stack pages when scanned by GC (at scavenge/gc/become et al) (read-write)
		69	the maximum number of live stack pages when scanned by GC (at scavenge/gc/become et al) (read-write)
		70	the vmProxyMajorVersion (the interpreterProxy VM_MAJOR_VERSION)
		71	the vmProxyMinorVersion (the interpreterProxy VM_MINOR_VERSION)
		72 total milliseconds in full GCs Mark phase since startup (read-only)
		73 total milliseconds in full GCs Sweep phase since startup (read-only, can be 0 depending on compactors)
		74 maximum pause time due to segment allocation
		
	Note: Thanks to Ian Piumarta for this primitive."

	| paramsArraySize index |
	paramsArraySize := 74.
	argumentCount = 0 ifTrue: [^self primitiveAllVMParameters: paramsArraySize].
	argumentCount > 2 ifTrue: [^self primitiveFailFor: PrimErrBadNumArgs].
	
	"index read & checks"
	index := self stackValue: (argumentCount = 1 ifTrue: [0] ifFalse: [1]).
	(objectMemory isIntegerObject: index) ifFalse: [^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	(index < 1 or: [index > paramsArraySize]) ifTrue: [^self primitiveFailFor: PrimErrBadIndex].
	
	argumentCount = 1 ifTrue:	 "read VM parameter; written this way to avoid branch limits in V3 bytecode set"
		[| result |
		 result := self primitiveGetVMParameter: index.
		 ^self methodReturnValue: (result ifNil: [objectMemory nilObject])].

	"write a VM parameter"
	self primitiveSetVMParameter: index arg: self stackTop
]

{ #category : #'system control primitives' }
StackInterpreterPrimitives >> primitiveVoidReceiver [
	"Potentially crash the VM by voiding the receiver.  A subsequent inst var
	 access in the caller's frame should indirect through a null pointer."
	<export: true>
	stackPages longAtPointer: (self frameReceiverLocation: framePointer) put: 0
]

{ #category : #'system control primitives' }
StackInterpreterPrimitives >> primitiveVoidVMState [
	"Void all internal VM state in the stack and machine code zones"
	| activeContext |
	self push: instructionPointer.
	activeContext := self voidVMStateForSnapshotFlushingExternalPrimitivesIf: false.
	self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext
]

{ #category : #ffi }
StackInterpreterPrimitives >> primitiveWorkerCallout [
	<export: true>
	| externalFunction cif PARAM_EXTERNALFUNCTION PARAM_ARGUMENTS PARAM_SEMAPHORE_INDEX PARAM_RECEIVER argumentsArrayOop argumentSize parameters returnHolder receiver worker semaphoreIndex task |
	<var: #parameters type: #'void **'>
	<var: #returnHolder type: #'void *'>
	<var: #task type: #'WorkerTask *'>
	<var: #externalFunction type: #'void *'>

	PARAM_RECEIVER 				:= 3.
	PARAM_EXTERNALFUNCTION 	:= 2.
	PARAM_ARGUMENTS 			:= 1.
	PARAM_SEMAPHORE_INDEX 	:= 0.

	"1. Obtain externalFunction and extract the CIF"
	externalFunction := self getHandler: (self stackValue: PARAM_EXTERNALFUNCTION).
	self failed 
		ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	cif := self getHandlerAsCif:(objectMemory
				fetchPointer: 1
				ofObject: (self stackValue: PARAM_EXTERNALFUNCTION)).

	self failed
		ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	" 2. Obtain the semaphore index"
	semaphoreIndex := self stackIntegerValue: PARAM_SEMAPHORE_INDEX.
	self failed
		ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	" 3. Obtain the receiver and extract the worker "
	receiver := self stackValue: PARAM_RECEIVER.
	worker := self getWorkerFromAddress: (self getHandler: receiver).

	self failed
		ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	" 4. Prepare Arguments:
	- Verify Arguments is an Array
	- Allocate space for all the arguments in the stack and a holder for the return, and the parameters' pointer C array
	- Marshall arguments and store in the parameter array."
	argumentsArrayOop := self stackValue: PARAM_ARGUMENTS.

	(objectMemory isArray: argumentsArrayOop)
		ifFalse: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	argumentSize := cif numberArguments.

	(objectMemory slotSizeOf: argumentsArrayOop) = argumentSize
		ifFalse: [ ^ self primitiveFailFor: PrimErrBadArgument ].
		
	parameters := self allocateParameters: argumentSize using: [ :aSize | 
		self calloc: aSize _: (self sizeof: #'void*')].

	0 to: argumentSize - 1 do: [ :i | 
		| argType argHolder |
		argType := cif argTypeAt: i.

		argHolder := self malloc: argType size.
		parameters at: i put: argHolder.
	
		self marshallArgumentFrom: argumentsArrayOop atIndex: i into: argHolder ofType: argType type withSize: argType size.
				
		self failed 
				ifTrue: [ 
					self freeArgumentsArray: parameters count: argumentSize.
					^ self primitiveFailFor: PrimErrBadArgument ]].
	
	cif returnType size > 0 
		ifTrue: [returnHolder := self malloc: cif returnType size]
		ifFalse: [returnHolder := nil].

	" 5. Create the worker task and enqueue it"

	task := self worker_task_new: externalFunction _: cif _: parameters _: returnHolder _: semaphoreIndex.

	self worker_dispatch_callout: worker _: task.

	self pop: 4 thenPush: (objectMemory newExternalAddressWithValue: (self cCoerce: task asInteger to: 'void*'))
]

{ #category : #ffi }
StackInterpreterPrimitives >> primitiveWorkerExtractReturnValue [
	<export: true>
	| returnHolder task PARAM_RECEIVER PARAM_TASK_ADDRESS  worker taskAddress receiver |
	<var: #returnHolder type: #'void *'>
	<var: #task type: #'WorkerTask *'>
	<var: #worker type: #'Worker *'>
	<var: #externalFunction type: #'void *'>

	PARAM_RECEIVER 				:= 1.
	PARAM_TASK_ADDRESS			:= 0.

	"1. Extract Task address and worker"
	taskAddress := self readAddress: (self stackValue: PARAM_TASK_ADDRESS).
	receiver := self stackValue: PARAM_RECEIVER.
	worker := self getWorkerFromAddress: (self getHandler: receiver).

	self failed
		ifTrue: [ ^ self primitiveFailFor: PrimErrBadArgument ].

	"2. Get the returnHolder from the task"
	task := self getTaskFromAddress: taskAddress.
	returnHolder := task returnHolderAddress.
	
	"3. Marshall the return value and push it in the stack"
	self 
		marshallAndPushReturnValueFrom: returnHolder 
		ofType: task cif returnType 
		poping: 2.

	"4. Free the task."	
	task freeTask.
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> pruneStack: stack stackp: stackp [
	"Prune the stack to contain only the path, removing stacked indices
	 and mapping frame pointers to contexts  The  issue here is that a
	 GC can occur during ensureFrameIsMarried:SP:, but frame pointers
	 are not valid objects.  So first prune back to objects and framePointers
	 as integers, and then replace frame pointers as integers by contexts."
	
	<inline: false>
	| objOrFP theStack finger |
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #theFPAbove type: #'char *'>
	finger := 1.
	2 to: stackp - 1 by: 2 do:
		[:i|
		objOrFP := objectMemory fetchPointer: i ofObject: stack.
		(stackPages couldBeFramePointer: (self cCoerceSimple: objOrFP to: #'char *')) ifTrue:
			[objOrFP := self withSmallIntegerTags: objOrFP].
		objectMemory
			storePointerUnchecked: finger
			ofObject: stack
			withValue: objOrFP.
		finger := finger + 1].
	finger to: (objectMemory lengthOf: stack) - 1 do:
		[:i|
		objectMemory
			storePointerUnchecked: i
			ofObject: stack
			withValue: objectMemory nilObject].
	objectMemory pushRemappableOop: (theStack := stack).
	1 to: finger - 1 do:
		[:i| | thePage theFP theFPAbove |
		objOrFP := objectMemory fetchPointer: i ofObject: theStack.
		(self isIntegerObject: objOrFP) ifTrue:
			[theFP := self withoutSmallIntegerTags: objOrFP.
			 thePage := stackPages stackPageFor: theFP.
			 theFPAbove := self findFrameAbove: theFP inPage: thePage.
			 objOrFP := self ensureFrameIsMarried: theFP SP: (self frameCallerSP: theFPAbove).
			 theStack := objectMemory topRemappableOop.
			 objectMemory "after a GC stack may no longer be a root."
				storePointer: finger
				ofObject: theStack
				withValue: objOrFP]].
	objectMemory popRemappableOop
]

{ #category : #ffi }
StackInterpreterPrimitives >> ptEnterInterpreterFromCallback: aPointer [

	" Enter the interpreter from a callback in the VM thread.
	The VM is suspended in a callout or primitive, which are not safe suspension points. 
	The callback has been put in a queue for further processing from the image.
	We first put the VM in a runnable state by putting it in a safe suspension point first
	   => we suspend the active process and store it for further resuming
	Then we enter the interpreter."
	<api>
	<var: #aPointer type: #'void *'>
	<var: #vmCallbackContext type: #'VMCallbackContext *'>

	| vmCallbackContext suspendedProcess |
	
	vmCallbackContext := self 
		cCode: [self cCoerce: aPointer to: #'VMCallbackContext *'] 
		inSmalltalk: [aPointer].

	"I am the entry point when arriving for a callback"
	
	vmCallbackContext savedPrimFunctionPointer: primitiveFunctionPointer.	
	self saveCStackStateForCallbackContext: vmCallbackContext.		
	
	"We need to preserve newMethod explicitly since it is not activated yet
	and therefore no context has been created for it. If the caller primitive
	for any reason decides to fail we need to make sure we execute the correct
	method and not the one 'last used' in the call back"	
	self push: newMethod.
	
	suspendedProcess := self supendActiveProcess.
	self pushSameThreadCalloutSuspendedProcess: suspendedProcess. 
	
	self enterSmalltalkExecutive.	
	
	"NEVER REACHED"
	^ 1
]

{ #category : #ffi }
StackInterpreterPrimitives >> ptExitInterpreterToCallback: aPointer [
	<api>
	<var: #aPointer type: #'void *'>
	<var: #vmCallbackContext type: #'VMCallbackContext *'>

	| vmCallbackContext suspendedProcess |

	vmCallbackContext := self 
		cCode: [self cCoerce: aPointer to: #'VMCallbackContext *']
		inSmalltalk: [ aPointer ].
	
	suspendedProcess := self popSameThreadCalloutSuspendedProcess.
	self putToSleep: self activeProcess yieldingIf: preemptionYields.
	self transferTo: suspendedProcess.
	
	newMethod := self popStack.
	
	self restoreCStackStateForCallbackContext: vmCallbackContext.			
	primitiveFunctionPointer := vmCallbackContext savedPrimFunctionPointer.
	
	self siglong: vmCallbackContext trampoline jmp: 1.

	"NEVER REACHED"	
	^ 1

]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> pushSameThreadCalloutSuspendedProcess: aSuspendedProcess [

	objectMemory
		storePointer: NextLinkIndex
		ofObject: aSuspendedProcess
		withValue: (objectMemory splObj: SuspendedProcessInCallout).

	objectMemory splObj: SuspendedProcessInCallout put: aSuspendedProcess
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> readAddress: anOop [ 

	<api>
	<returnTypeC: #'void *'>

	(objectMemory is: anOop KindOfClass: objectMemory classExternalAddress)
		ifFalse: [ self primitiveFail. ^ nil ].

	^ objectMemory fetchPointer: 0 ofObject: anOop.
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> unmarkAfterPathTo [
	<inline: false>
	self unmarkAllFrames.
	objectMemory unmarkAllObjects
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> unmarkAllFrames [
	| thePage theFP flags |
	<var: #thePage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<inline: false>
	0 to: numStackPages - 1 do:
		[:i|
		thePage := stackPages stackPageAt: i.
		(stackPages isFree: thePage) ifFalse:
			[theFP := thePage  headFP.
			 [flags := objectMemory longAt: theFP + FoxFrameFlags.
			  (flags bitAnd: 2) ~= 0 ifTrue:
				[objectMemory longAt: theFP + FoxFrameFlags put: flags - 2].
			  (theFP := self frameCallerFP: theFP) ~= 0] whileTrue]]
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> worker_dispatch_callout: worker _: task [ 
	
	<doNotGenerate>
	worker dispatchCallout: task.

]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> worker_task_new: externalFunction _: cif _: parameters _: returnHolder _: semaphoreIndex [
	<doNotGenerate>
	
	<returnTypeC: #sqInt>
	
	^ LibFFIWorkerTask new
			anExternalFunction: externalFunction;
			cif: cif;
			parametersAddress: parameters;
			returnHolderAddress: returnHolder;
			semaphoreIndex: semaphoreIndex;
			yourself
	
]

{ #category : #'ffi - helpers' }
StackInterpreterPrimitives >> writeAddress: anOop to: aValue [

	<api>
	<var: #aValue type: #'void *'>

	(objectMemory is: anOop KindOfClass: objectMemory classExternalAddress)
		ifFalse: [ self primitiveFail. ^ nil ].

	^ objectMemory storePointer: 0 ofObject: anOop withValue: (self cCoerce: aValue to: #sqInt).
]
