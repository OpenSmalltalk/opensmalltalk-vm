Class {
	#name : #StackInterpreterPrimitives,
	#superclass : #StackInterpreter,
	#category : #'VMMaker-Interpreter'
}

{ #category : #'primitive support' }
StackInterpreterPrimitives >> cloneContext: aContext [ 
	| cloned spouseFP sp |
	<var: #spouseFP type: #'char *'>
	cloned := objectMemory clone: aContext.
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
				withValue: (self fetchPointer: i ofObject: aContext)].
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
						withValue: (self fetchPointer: i + CtxtTempFrameStart ofObject: aContext)]]].
	^cloned
]

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> primitiveClone [
	"Return a shallow copy of the receiver.
	 Special-case non-single contexts (because of context-to-stack mapping).
	 Can't fail for contexts cuz of image context instantiation code (sigh)."

	| receiver newCopy |
	receiver := self stackTop.
	(objectMemory isIntegerObject: receiver)
		ifTrue:
			[newCopy := receiver]
		ifFalse:
			[(self isContextNonInt: receiver)
				ifTrue:
					[newCopy := self cloneContext: receiver]
				ifFalse:
					[newCopy := objectMemory clone: receiver].
			newCopy = 0 ifTrue:
				[^self primitiveFailFor: PrimErrNoMemory]].
	self pop: 1 thenPush: newCopy
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
					instructionPointer: instructionPointer + 2 - (method+BaseHeaderSize)
					copiedValues: self stackTop.
	self pop: 3 thenPush: newClosure
]

{ #category : #'indexing primitives' }
StackInterpreterPrimitives >> primitiveContextAt [
	| index value aContext spouseFP hdr fmt totalLength fixedFields stSize |
	<var: #spouseFP type: #'char *'>
	index := self stackTop.
	(objectMemory isIntegerObject: index) ifFalse:
		[^self primitiveFail].
	index := objectMemory integerValueOf: index.
	aContext := self stackValue: 1.
	"Duplicating much of stObject:at:put: here allows stObject:at:put: to omit tests for contexts."
	hdr := objectMemory baseHeader: aContext.
	(objectMemory isContextHeader: hdr) ifFalse: "might be an instance of a subclass"
		[value := self stObject: aContext at: index.
		 ^self pop: 2 thenPush: value].
	self externalWriteBackHeadFramePointers.
	(self isStillMarriedContext: aContext) ifFalse:
		[fmt := objectMemory formatOfHeader: hdr.
		 totalLength := objectMemory lengthOf: aContext baseHeader: hdr format: fmt.
		 fixedFields := objectMemory fixedFieldsOf: aContext format: fmt length: totalLength.
		 stSize := self stackPointerForMaybeMarriedContext: aContext.
		 (index between: 1 and: stSize) ifFalse:
			[^self primitiveFail].			
		value := self subscript: aContext with: (index + fixedFields) format: fmt.
		^self pop: 2 thenPush: value].
	spouseFP := self frameOfMarriedContext: aContext.
	(index between: 1 and: (self stackPointerIndexForFrame: spouseFP)) ifFalse:
		[^self primitiveFail].
	value := self temporary: index - 1 in: spouseFP.
	self pop: 2 thenPush: value
]

{ #category : #'indexing primitives' }
StackInterpreterPrimitives >> primitiveContextAtPut [
	| index value aContext spouseFP hdr fmt totalLength fixedFields stSize |
	<var: #spouseFP type: #'char *'>
	value := self stackTop.
	index := self stackValue: 1.
	aContext := self stackValue: 2.
	(objectMemory isIntegerObject: index) ifFalse:
		[^self primitiveFail].
	"Duplicating much of stObject:at:put: here allows stObject:at:put: to omit tests for contexts."
	hdr := objectMemory baseHeader: aContext.
	index := objectMemory integerValueOf: index.
	(objectMemory isContextHeader: hdr) ifFalse: "might be an instance of a subclass"
		[self stObject: aContext at: index put: value.
		 ^self pop: 3 thenPush: value].
	self externalWriteBackHeadFramePointers.
	(self isStillMarriedContext: aContext) ifFalse:
		[fmt := objectMemory formatOfHeader: hdr.
		 totalLength := objectMemory lengthOf: aContext baseHeader: hdr format: fmt.
		 fixedFields := objectMemory fixedFieldsOf: aContext format: fmt length: totalLength.
		 stSize := self stackPointerForMaybeMarriedContext: aContext.
		 (index between: 1 and: stSize) ifFalse:
			[^self primitiveFail].			
		self subscript: aContext with: (index + fixedFields) storing: value format: fmt.
		^self pop: 3 thenPush: value].
	spouseFP := self frameOfMarriedContext: aContext.
	(index between: 1 and: (self stackPointerIndexForFrame: spouseFP)) ifFalse:
		[^self primitiveFail].
	self temporary: index - 1 in: spouseFP put: value.
	^self pop: 3 thenPush: value
]

{ #category : #'indexing primitives' }
StackInterpreterPrimitives >> primitiveContextSize [
	| rcvr sz hdr fmt totalLength fixedFields |
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
	self successful ifTrue:
		[self pop: 1 thenPush: (objectMemory integerObjectOf: sz)]
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

{ #category : #'object access primitives' }
StackInterpreterPrimitives >> primitiveCopyObject [
	"Primitive. Copy the state of the receiver from the argument. 
		Fail if receiver and argument are of a different class.
		Fail if the receiver or argument are non-pointer objects.
		Fail if the receiver or argument are contexts (because of context-to-stack mapping).
		Fail if receiver and argument have different lengths (for indexable objects).
	"
	| rcvr arg length |
	self methodArgumentCount = 1 ifFalse:
		[^self primitiveFail].
	arg := self stackObjectValue: 0.
	rcvr := self stackObjectValue: 1.

	self failed ifTrue:[^nil].
	(objectMemory isPointers: rcvr) ifFalse:
		[^self primitiveFail].
	((self isContextNonInt: rcvr)
	 or: [self isContextNonInt: arg]) ifTrue:
		[^self primitiveFail].
	(objectMemory fetchClassOfNonInt: rcvr) = (objectMemory fetchClassOfNonInt: arg) ifFalse:
		[^self primitiveFail].
	length := objectMemory lengthOf: rcvr.
	length = (objectMemory lengthOf: arg) ifFalse:
		[^self primitiveFail].
	
	"Now copy the elements"
	0 to: length-1 do:[:i|
		objectMemory storePointer: i ofObject: rcvr withValue: (objectMemory fetchPointer: i ofObject: arg)].

	"Note: The above could be faster for young receivers but I don't think it'll matter"
	self pop: 1. "pop arg; answer receiver"

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
		ifFalse: [flag = objectMemory falseObject
				ifTrue: [deferDisplayUpdates := false]
				ifFalse: [self primitiveFail]].
	self successful
		ifTrue: [self pop: 1]
]

{ #category : #'plugin primitives' }
StackInterpreterPrimitives >> primitiveDoNamedPrimitiveWithArgs [
	"Simulate an primitiveExternalCall invocation (e.g. for the Debugger).  Do not cache anything.
	 e.g. ContextPart>>tryNamedPrimitiveIn: aCompiledMethod for: aReceiver withArgs: arguments"
	| argumentArray arraySize methodArg methodHeader
	  moduleName functionName moduleLength functionLength
	  spec addr primRcvr ctxtRcvr |
	<var: #addr declareC: 'void (*addr)()'>
	argumentArray := self stackTop.
	(objectMemory isArray: argumentArray) ifFalse:
		[^self primitiveFailFor: -2]. "invalid args"
	arraySize := objectMemory fetchWordLengthOf: argumentArray.
	self success: (self roomToPushNArgs: arraySize).

	methodArg := self stackObjectValue: 2.
	self successful ifFalse:
		[^self primitiveFailFor: -2]. "invalid args"

	(objectMemory isOopCompiledMethod: methodArg) ifFalse:
		[^self primitiveFailFor: -2]. "invalid args"

	methodHeader := self headerOf: methodArg.

	(self literalCountOfHeader: methodHeader) > 2 ifFalse:
		[^self primitiveFailFor: -3]. "invalid methodArg state"
	(self assertClassOf: (spec := objectMemory fetchPointer: 1 "first literal" ofObject: methodArg)
		is: (objectMemory splObj: ClassArray) 
		compactClassIndex: ClassArrayCompactIndex).
	(self successful
	and: [(objectMemory lengthOf: spec) = 4
	and: [(self primitiveIndexOfMethodHeader: methodHeader) = 117]]) ifFalse:
		[^self primitiveFailFor: -3]. "invalid methodArg state"

	(self argumentCountOfMethodHeader: methodHeader) = arraySize ifFalse:
		[^self primitiveFailFor: -2]. "invalid args (Array args wrong size)"

	"The function has not been loaded yet. Fetch module and function name."
	moduleName := objectMemory fetchPointer: 0 ofObject: spec.
	moduleName = objectMemory nilObject
		ifTrue: [moduleLength := 0]
		ifFalse: [self success: (objectMemory isBytes: moduleName).
				moduleLength := objectMemory lengthOf: moduleName.
				self cCode: '' inSmalltalk:
					[ (#('FloatArrayPlugin' 'Matrix2x3Plugin') includes: (self stringOf: moduleName)) "??"
						ifTrue: [moduleLength := 0  "Cause all of these to fail"]]].
	functionName := objectMemory fetchPointer: 1 ofObject: spec.
	self success: (objectMemory isBytes: functionName).
	functionLength := objectMemory lengthOf: functionName.
	self successful ifFalse: [^self primitiveFailFor: -3]. "invalid methodArg state"

	addr := self ioLoadExternalFunction: functionName + BaseHeaderSize
				OfLength: functionLength
				FromModule: moduleName + BaseHeaderSize
				OfLength: moduleLength.
	addr = 0 ifTrue:
		[^self primitiveFailFor: -1]. "could not find function; answer generic failure (see below)"

	"Cannot fail this primitive from now on.  Can only fail the external primitive."
	objectMemory pushRemappableOop: (argumentArray := self popStack).
	objectMemory pushRemappableOop: (primRcvr := self popStack).
	objectMemory pushRemappableOop: self popStack. "the method"
	objectMemory pushRemappableOop: self popStack. "the context receiver"
	self push: primRcvr. "replace context receiver with actual receiver"
	argumentCount := arraySize.
	1 to: arraySize do:
		[:index| self push: (objectMemory fetchPointer: index - 1 ofObject: argumentArray)].
	"Run the primitive (sets primFailCode)"
	lkupClass := objectMemory nilObject.
	self callExternalPrimitive: addr.
	ctxtRcvr  := objectMemory popRemappableOop.
	methodArg := objectMemory popRemappableOop.
	primRcvr := objectMemory popRemappableOop.
	argumentArray := objectMemory popRemappableOop.
	self successful ifFalse: "If primitive failed, then restore state for failure code"
		[self pop: arraySize + 1.
		 self push: ctxtRcvr.
		 self push: methodArg.
		 self push: primRcvr.
		 self push: argumentArray.
		 argumentCount := 3.
		 "Hack.  A nil prim error code (primErrorCode = 1) is interpreted by the image
		  as meaning this primitive is not implemented.  So to pass back nil as an error
		  code we use -1 to indicate generic failure."
		 primFailCode = 1 ifTrue:
			[primFailCode := -1]]
]

{ #category : #'control primitives' }
StackInterpreterPrimitives >> primitiveDoPrimitiveWithArgs [
	| argumentArray arraySize index primIdx |
	argumentArray := self stackTop.
	(objectMemory isArray: argumentArray) ifFalse: [^self primitiveFail].
	arraySize := objectMemory fetchWordLengthOf: argumentArray.
	self success: (self roomToPushNArgs: arraySize).

	primIdx := self stackIntegerValue: 1.
	self successful ifFalse: [^self primitiveFail]. "invalid args"

	primitiveFunctionPointer := self functionPointerFor: primIdx inClass: nil.
	primitiveFunctionPointer = 0 ifTrue:
		[^self primitiveFail].

	"Pop primIndex and argArray, then push args in place..."
	self pop: 2.
	argumentCount := arraySize.
	index := 1.
	[index <= argumentCount] whileTrue:
		[self push: (objectMemory fetchPointer: index - 1 ofObject: argumentArray).
		 index := index + 1].

	self isPrimitiveFunctionPointerAnIndex ifTrue:
		[self externalQuickPrimitiveResponse.
		^nil].
	"We use tempOop instead of pushRemappableOop:/popRemappableOop here because in
	 the Cogit primitiveEnterCriticalSection, primitiveSignal, primitiveResume et al longjmp back
	 to either the interpreter or machine code, depending on the process activated.  So if we're
	 executing one of these primitives control won't actually return here and the matching
	 popRemappableOop: wouldn't occur, potentially overflowing the remap buffer.  While recursion
	 could occur (nil tryPrimitive: 118 withArgs: #(111 #())) it counts as shooting oneself in the foot."
	tempOop := argumentArray. "prim might alloc/gc"
	lkupClass := objectMemory nilObject.
	"Run the primitive (sets primFailCode)"
	self slowPrimitiveResponse.
	self successful ifFalse: "If primitive failed, then restore state for failure code"
		[self pop: arraySize.
		 self pushInteger: primIdx.
		 self push: tempOop.
		 argumentCount := 2].
	tempOop := 0
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
	"We set the messageSelector for executeMethod below since things
	 like the at cache read messageSelector and so it cannot be left stale."
	messageSelector := objectMemory nilObject.
	self executeNewMethod.
	"Recursive xeq affects primErrorCode"
	self initPrimCall
]

{ #category : #'control primitives' }
StackInterpreterPrimitives >> primitiveExecuteMethodArgsArray [
	"receiver, argsArray, then method are on top of stack.  Execute method against receiver and args.
	 Set primitiveFunctionPointer because no cache lookup has been done for the method, and
	 hence primitiveFunctionPointer is stale."
	| methodArgument argCnt argumentArray primitiveIndex |
	methodArgument := self stackTop.
	argumentArray := self stackValue: 1.
	((objectMemory isOopCompiledMethod: methodArgument)
	 and: [objectMemory isArray: argumentArray]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	argCnt := self argumentCountOf: methodArgument.
	argCnt = (objectMemory fetchWordLengthOf: argumentArray) ifFalse:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	self pop: 2.
	0 to: argCnt - 1 do:
		[:i|
		self push: (objectMemory fetchPointer: i ofObject: argumentArray)].
	newMethod := methodArgument.
	primitiveIndex := self primitiveIndexOf: newMethod.
	primitiveFunctionPointer := self functionPointerFor: primitiveIndex inClass: nil.
	argumentCount := argCnt.
	"We set the messageSelector for executeMethod below since things
	 like the at cache read messageSelector and so it cannot be left stale."
	messageSelector := objectMemory nilObject.
	self executeNewMethod.
	"Recursive xeq affects primErrorCode"
	self initPrimCall
]

{ #category : #'plugin primitives' }
StackInterpreterPrimitives >> primitiveExternalCall [
	"Call an external primitive. External primitive methods first literals are an array of
		* The module name (String | Symbol) 
		* The function name (String | Symbol) 
		* The session ID (SmallInteger) [OBSOLETE] 
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
	| lit addr moduleName functionName moduleLength functionLength index |
	<var: #addr declareC: 'void (*addr)()'>
	
	"Fetch the first literal of the method"
	(self literalCountOf: newMethod) > 0 ifFalse:
		[^self primitiveFailFor: PrimErrBadMethod].

	lit := self literal: 0 ofMethod: newMethod. 
	"Check if it's an array of length 4"
	((objectMemory isArray: lit) and: [(objectMemory lengthOf: lit) = 4]) ifFalse:
		[^self primitiveFailFor: PrimErrBadMethod].

	"Look at the function index in case it has been loaded before"
	index := objectMemory fetchPointer: 3 ofObject: lit.
	(objectMemory isIntegerObject: index) ifFalse:
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
			 self callExternalPrimitive: addr.
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

	addr := self ioLoadExternalFunction: functionName + BaseHeaderSize
				OfLength: functionLength
				FromModule: moduleName + BaseHeaderSize
				OfLength: moduleLength.
	addr = 0
		ifTrue: [index := -1]
		ifFalse: ["add the function to the external primitive table"
			index := self addToExternalPrimitiveTable: addr].

	"Store the index (or -1 if failure) back in the literal"
	objectMemory storePointerUnchecked: 3 ofObject: lit withValue: (objectMemory integerObjectOf: index).

	"If the function has been successfully loaded cache and call it"
	index >= 0
		ifTrue:
			[self rewriteMethodCacheEntryForExternalPrimitiveToFunction: (self cCode: [addr] inSmalltalk: [1000 + index]).
			self callExternalPrimitive: addr]
		ifFalse: ["Otherwise void the primitive function and fail"
			self rewriteMethodCacheEntryForExternalPrimitiveToFunction: 0.
			^self primitiveFailFor: PrimErrNotFound]
]

{ #category : #'system control primitives' }
StackInterpreterPrimitives >> primitiveFlushCacheByMethod [
	"The receiver is a compiledMethod.  Clear all entries in the method lookup cache that refer to this method, presumably because it has been redefined, overridden or removed."
	| probe oldMethod primIdx |
	oldMethod := self stackTop.
	probe := 0.
	1 to: MethodCacheEntries do:
		[:i |
		(methodCache at: probe + MethodCacheMethod) = oldMethod ifTrue:
			[methodCache at: probe + MethodCacheSelector put: 0].
		probe := probe + MethodCacheEntrySize].
	primIdx := self primitiveIndexOf: oldMethod.
	primIdx = PrimitiveExternalCallIndex ifTrue:
		["It's primitiveExternalCall"
		self flushExternalPrimitiveOf: oldMethod]
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
			[(objectMemory fetchClassOfNonInt: sema) = (objectMemory splObj: ClassSemaphore) ifFalse:
				[^self primitiveFail].
			 longRunningPrimitiveCheckSemaphore := sema].
	self voidLongRunningPrimitive: 'install'.
	self pop: 1
]

{ #category : #'control primitives' }
StackInterpreterPrimitives >> primitivePerform [
	<returnTypeC: #void>
	| performSelector newReceiver lookupClass performMethod |
	performSelector := messageSelector.
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
			longAt: stackPointer + (i * BytesPerWord)
			put: (stackPages longAt: stackPointer + ((i - 1) * BytesPerWord))].
	self pop: 1.
	lookupClass := objectMemory fetchClassOf: newReceiver.
	self sendBreak: messageSelector + BaseHeaderSize
		point: (objectMemory lengthOf: messageSelector)
		receiver: newReceiver.
	self findNewMethodInClass: lookupClass.

	"Only test CompiledMethods for argument count - other objects will have to take their chances"
	((objectMemory isOopCompiledMethod: newMethod)
	  and: [(self argumentCountOf: newMethod) = argumentCount]) ifFalse:
		["Slide the args back up (sigh) and re-insert the selector."
		self unPop: 1.
		1 to: argumentCount by: 1 do:
			[:i |
			stackPages longAt: stackPointer + ((i - 1) * BytesPerWord)
				put: (stackPages longAt: stackPointer + (i * BytesPerWord))].
		stackPages longAt: stackPointer + (argumentCount * BytesPerWord) put: messageSelector.
		argumentCount := argumentCount + 1.
		newMethod := performMethod.
		messageSelector := performSelector.
		^self primitiveFail].

	self executeNewMethod.
	"Recursive xeq affects primErrorCode"
	self initPrimCall
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
StackInterpreterPrimitives >> primitiveSignalAtMilliseconds [
	"Cause the time semaphore, if one has been registered, to be
	 signalled when the microsecond clock is greater than or equal to
	 the given tick value. A tick value of zero turns off timer interrupts."
	| msecsObj msecs deltaMsecs sema |
	<var: #msecs type: #usqInt>
	msecsObj := self stackTop.
	sema := self stackValue: 1.
	msecs := self positive32BitValueOf: msecsObj.
	(self failed
	 or: [objectMemory isIntegerObject: sema]) ifTrue:
		[self primitiveFail.
		 ^nil].
	(objectMemory fetchClassOfNonInt: sema) = (objectMemory splObj: ClassSemaphore)
		ifTrue:
			[objectMemory splObj: TheTimerSemaphore put: sema.
			deltaMsecs := msecs - (self ioMSecs bitAnd: MillisecondClockMask).
			deltaMsecs < 0 ifTrue:
				[deltaMsecs := deltaMsecs + MillisecondClockMask + 1].
			nextWakeupUsecs := self ioUTCMicroseconds + (deltaMsecs * 1000)]
		ifFalse:
			[objectMemory
				storePointer: TheTimerSemaphore
				ofObject: objectMemory specialObjectsOop
				withValue: objectMemory nilObject.
			nextWakeupUsecs := 0].
	self pop: 2
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
	(self failed
	 or: [objectMemory isIntegerObject: sema]) ifTrue:
		[self primitiveFail.
		 ^nil].
	(objectMemory fetchClassOfNonInt: sema) = (objectMemory splObj: ClassSemaphore)
		ifTrue:
			[objectMemory splObj: TheTimerSemaphore put: sema.
			nextWakeupUsecs := usecs]
		ifFalse:
			[objectMemory
				storePointer: TheTimerSemaphore
				ofObject: objectMemory specialObjectsOop
				withValue: objectMemory nilObject.
			nextWakeupUsecs := 0].
	self pop: 2
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
	 and: [newStackp between: 0 and: (objectMemory lengthOf: ctxt)]) ifFalse:
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
				[framePointer := stackPage headFP.
				 stackPointer := stackPage headSP]
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
	(aContextOrNil = objectMemory nilObject or: [self isContext: aContextOrNil]) ifFalse:
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
					 contextsIP := self frameCallerSavedIP: frameAbove.
					 newSP := self frameCallerSP: frameAbove.
					 newFP := newSP - stackedReceiverOffset - BytesPerWord.
					 theFP + stackedReceiverOffset
						to: stackPointer
						by: BytesPerWord negated
						do: [:source|
							newSP := newSP - BytesPerWord.
							stackPages longAt: newSP put: (stackPages longAt: source)].
					 stackPages longAt: newFP + FoxSavedFP put: contextsFP.
					 stackPages longAt: newFP + FoxCallerSavedIP put: contextsIP.
					 self assert: (self isContext: thisCtx).
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
			[self assert: (self isContext: currentCtx).
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
										[contextsSP := (self frameCallerSP: frameAbove) - BytesPerWord.
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
	self assert: stackPage = stackPages mostRecentlyUsedPage.
	^nil
]

{ #category : #'system control primitives' }
StackInterpreterPrimitives >> primitiveVMParameter [
	"Behaviour depends on argument count:
		0 args:	return an Array of VM parameter values;
		1 arg:	return the indicated VM parameter;
		2 args:	set the VM indicated parameter.
	VM parameters are numbered as follows:
		1	end of old-space (0-based, read-only)
		2	end of young-space (read-only)
		3	end of memory (read-only)
		4	nil (was allocationCount (read-only))
		5	nil (was allocations between GCs (read-write)
		6	survivor count tenuring threshold (read-write)
		7	full GCs since startup (read-only)
		8	total milliseconds in full GCs since startup (read-only)
		9	incremental GCs since startup (read-only)
		10	total milliseconds in incremental GCs since startup (read-only)
		11	tenures of surving objects since startup (read-only)
		12-20 specific to the translating VM
		21	root table size (read-only)
		22	root table overflows since startup (read-only)
		23	bytes of extra memory to reserve for VM buffers, plugins, etc.
		24	memory threshold above which shrinking object memory (rw)
		25	memory headroom when growing object memory (rw)
		26  interruptChecksEveryNms - force an ioProcessEvents every N milliseconds (rw)
		27	number of times mark loop iterated for current IGC/FGC (read-only) includes ALL marking
		28	number of times sweep loop iterated  for current IGC/FGC (read-only)
		29	number of times make forward loop iterated for current IGC/FGC (read-only)
		30	number of times compact move loop iterated for current IGC/FGC (read-only)
		31	number of grow memory requests (read-only)
		32	number of shrink memory requests (read-only)
		33	number of root table entries used for current IGC/FGC (read-only)
		34	number of allocations done before current IGC/FGC (read-only)
		35	number of survivor objects after current IGC/FGC (read-only)
		36  millisecond clock when current IGC/FGC completed (read-only)
		37  number of marked objects for Roots of the world, not including Root Table entries for current IGC/FGC (read-only)
		38  milliseconds taken by current IGC  (read-only)
		39  Number of finalization signals for Weak Objects pending when current IGC/FGC completed (read-only)
		40  BytesPerWord for this image
		41  imageFormatVersion for the VM
		42	number of stack pages in use
		43	desired number of stack pages (stored in image file header, max 65535)
		44	size of eden, in bytes
		45	desired size of eden, in bytes (stored in image file header)
		46	machine code zone size, in bytes (Cog only; otherwise nil)
		47	desired machine code zone size (Cog only; otherwise nil)
		48	various header flags.  See getCogVMFlags.
		49	max size the image promises to grow the external semaphore table to (0 sets to default, which is 256 as of writing)
		50-55 nil; reserved for VM parameters that persist in the image (such as eden above)
		56	number of process switches since startup (read-only)
		57	number of ioProcessEvents calls since startup (read-only)
		58	number of ForceInterruptCheck calls since startup (read-only)
		59	number of check event calls since startup (read-only)
		60	number of stack page overflows since startup (read-only)
		61	number of stack page divorces since startup (read-only)
		62	compiled code compactions since startup (read-only; Cog only; otherwise nil)
		63	total milliseconds in compiled code compactions since startup (read-only; Cog only; otherwise nil)
		64	the number of methods that currently have jitted machine-code
		
	Note: Thanks to Ian Piumarta for this primitive."

	| mem paramsArraySize result arg index |
	mem := objectMemory startOfMemory.
	paramsArraySize := 64.
	argumentCount = 0 ifTrue:
		[result := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: paramsArraySize.
		objectMemory storePointerUnchecked: 0	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory youngStart - mem).
		objectMemory storePointerUnchecked: 1	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory freeStart - mem).
		objectMemory storePointerUnchecked: 2	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory endOfMemory - mem).
		objectMemory storePointerUnchecked: 3	ofObject: result withValue: objectMemory nilObject "was allocationCount".
		objectMemory storePointerUnchecked: 4	ofObject: result withValue: objectMemory nilObject "allocationsBetweenGCs".
		objectMemory storePointerUnchecked: 5	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory tenuringThreshold).
		objectMemory storePointerUnchecked: 6	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statFullGCs).
		objectMemory storePointerUnchecked: 7	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statFullGCUsecs + 500 // 1000).
		objectMemory storePointerUnchecked: 8	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statIncrGCs).
		objectMemory storePointerUnchecked: 9	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statIncrGCUsecs + 500 // 1000).
		objectMemory storePointerUnchecked: 10	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statTenures).
		11 to: 19 do:
			[:i | objectMemory storePointerUnchecked: i ofObject: result withValue: ConstZero].
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
		objectMemory storePointerUnchecked: 33	ofObject: result withValue: objectMemory nilObject "was statAllocationCount".
		objectMemory storePointerUnchecked: 34	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statSurvivorCount).
		objectMemory storePointerUnchecked: 35	ofObject: result withValue: (objectMemory integerObjectOf: (self microsecondsToMilliseconds: objectMemory statGCEndUsecs)).
		objectMemory storePointerUnchecked: 36	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statSpecialMarkCount).
		objectMemory storePointerUnchecked: 37	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory statIGCDeltaUsecs + 500 // 1000).
		objectMemory storePointerUnchecked: 38	ofObject: result withValue: (objectMemory integerObjectOf: statPendingFinalizationSignals).
		objectMemory storePointerUnchecked: 39	ofObject: result withValue: (objectMemory integerObjectOf: BytesPerWord).
		objectMemory storePointerUnchecked: 40	ofObject: result withValue: (objectMemory integerObjectOf: self imageFormatVersion).
		objectMemory storePointerUnchecked: 41	ofObject: result withValue: (objectMemory integerObjectOf: numStackPages).
		objectMemory storePointerUnchecked: 42	ofObject: result withValue: (objectMemory integerObjectOf: desiredNumStackPages).
		objectMemory storePointerUnchecked: 43	ofObject: result withValue: (objectMemory integerObjectOf: objectMemory edenBytes).
		objectMemory storePointerUnchecked: 44	ofObject: result withValue: (objectMemory integerObjectOf: desiredEdenBytes).
		objectMemory storePointerUnchecked: 45	ofObject: result withValue: self getCogCodeSize.
		objectMemory storePointerUnchecked: 46	ofObject: result withValue: self getDesiredCogCodeSize.
		objectMemory storePointerUnchecked: 47	ofObject: result withValue: self getCogVMFlags.
		objectMemory storePointerUnchecked: 48	ofObject: result withValue: (objectMemory integerObjectOf: self ioGetMaxExtSemTableSize).
		49 to: 54 do:
			[:i | objectMemory storePointerUnchecked: i ofObject: result withValue: objectMemory nilObject].
		objectMemory storePointerUnchecked: 55	ofObject: result withValue: (objectMemory integerObjectOf: statProcessSwitch).
		objectMemory storePointerUnchecked: 56	ofObject: result withValue: (objectMemory integerObjectOf: statIOProcessEvents).
		objectMemory storePointerUnchecked: 57	ofObject: result withValue: (objectMemory integerObjectOf: statForceInterruptCheck).
		objectMemory storePointerUnchecked: 58	ofObject: result withValue: (objectMemory integerObjectOf: statCheckForEvents).
		objectMemory storePointerUnchecked: 59	ofObject: result withValue: (objectMemory integerObjectOf: statStackOverflow).
		objectMemory storePointerUnchecked: 60	ofObject: result withValue: (objectMemory integerObjectOf: statStackPageDivorce).
		objectMemory storePointerUnchecked: 61	ofObject: result withValue: self getCodeCompactionCount.
		objectMemory storePointerUnchecked: 62	ofObject: result withValue: self getCodeCompactionMSecs.
		objectMemory storePointerUnchecked: 63	ofObject: result withValue: self getCogMethodCount.
    
		self pop: 1 thenPush: result.
		^nil].

	arg := self stackTop.
	(objectMemory isIntegerObject: arg) ifFalse: [^self primitiveFailFor: PrimErrBadArgument].
	arg := objectMemory integerValueOf: arg.
	argumentCount = 1 ifTrue:	 "read VM parameter"
		[(arg < 1 or: [arg > paramsArraySize]) ifTrue: [^self primitiveFailFor: PrimErrBadIndex].
		result := objectMemory nilObject.
		arg = 1		ifTrue: [result := objectMemory integerObjectOf: objectMemory youngStart - mem].
		arg = 2		ifTrue: [result := objectMemory integerObjectOf: objectMemory freeStart - mem].
		arg = 3		ifTrue: [result := objectMemory integerObjectOf: objectMemory endOfMemory - mem].
		arg = 4		ifTrue: [result := objectMemory nilObject "was allocationCount"].
		arg = 5		ifTrue: [result := objectMemory nilObject "was allocationsBetweenGCs"].
		arg = 6		ifTrue: [result := objectMemory integerObjectOf: objectMemory tenuringThreshold].
		arg = 7		ifTrue: [result := objectMemory integerObjectOf: objectMemory statFullGCs].
		arg = 8		ifTrue: [result := objectMemory integerObjectOf: objectMemory statFullGCUsecs + 500 // 1000].
		arg = 9		ifTrue: [result := objectMemory integerObjectOf: objectMemory statIncrGCs].
		arg = 10	ifTrue: [result := objectMemory integerObjectOf: objectMemory statIncrGCUsecs + 500 // 1000].
		arg = 11	ifTrue: [result := objectMemory integerObjectOf: objectMemory statTenures].
		(arg between: 12 and: 20) ifTrue: [result := ConstZero].
		arg = 21	ifTrue: [result := objectMemory integerObjectOf: objectMemory rootTableCount].
		arg = 22	ifTrue: [result := objectMemory integerObjectOf: objectMemory statRootTableOverflows].
		arg = 23	ifTrue: [result := objectMemory integerObjectOf: extraVMMemory].
		arg = 24	ifTrue: [result := objectMemory integerObjectOf: objectMemory shrinkThreshold].
		arg = 25	ifTrue: [result := objectMemory integerObjectOf: objectMemory growHeadroom].
		arg = 26	ifTrue: [result := objectMemory integerObjectOf: self ioHeartbeatMilliseconds].
		arg = 27	ifTrue: [result := objectMemory integerObjectOf: objectMemory statMarkCount].
		arg = 28	ifTrue: [result := objectMemory integerObjectOf: objectMemory statSweepCount].
		arg = 29	ifTrue: [result := objectMemory integerObjectOf: objectMemory statMkFwdCount].
		arg = 30	ifTrue: [result := objectMemory integerObjectOf: objectMemory statCompMoveCount].
		arg = 31	ifTrue: [result := objectMemory integerObjectOf: objectMemory statGrowMemory].
		arg = 32	ifTrue: [result := objectMemory integerObjectOf: objectMemory statShrinkMemory].
		arg = 33	ifTrue: [result := objectMemory integerObjectOf: objectMemory statRootTableCount].
		arg = 34	ifTrue: [result := objectMemory nilObject "was statAllocationCount"].
		arg = 35	ifTrue: [result := objectMemory integerObjectOf: objectMemory statSurvivorCount].
		arg = 36  	ifTrue: [result := objectMemory integerObjectOf: (self microsecondsToMilliseconds: objectMemory statGCEndUsecs)].
		arg = 37  	ifTrue: [result := objectMemory integerObjectOf: objectMemory statSpecialMarkCount].
		arg = 38  	ifTrue: [result := objectMemory integerObjectOf: objectMemory statIGCDeltaUsecs + 500 // 1000].
		arg = 39  	ifTrue: [result := objectMemory integerObjectOf: statPendingFinalizationSignals].
		arg = 40  	ifTrue: [result := objectMemory integerObjectOf: BytesPerWord].
		arg = 41  	ifTrue: [result := objectMemory integerObjectOf: self imageFormatVersion].
		arg = 42  	ifTrue: [result := objectMemory integerObjectOf: numStackPages].
		arg = 43  	ifTrue: [result := objectMemory integerObjectOf: desiredNumStackPages].
		arg = 44  	ifTrue: [result := objectMemory integerObjectOf: objectMemory edenBytes].
		arg = 45  	ifTrue: [result := objectMemory integerObjectOf: desiredEdenBytes].
		arg = 46	ifTrue: [result := self getCogCodeSize].
		arg = 47	ifTrue: [result := self getDesiredCogCodeSize].
		arg = 48	ifTrue: [result := self getCogVMFlags].
		arg = 49	ifTrue: [result := objectMemory integerObjectOf: self ioGetMaxExtSemTableSize].
		(arg between: 50 and: 55) ifTrue: [result := objectMemory nilObject].
		arg = 56  	ifTrue: [result := objectMemory integerObjectOf: statProcessSwitch].
		arg = 57  	ifTrue: [result := objectMemory integerObjectOf: statIOProcessEvents].
		arg = 58  	ifTrue: [result := objectMemory integerObjectOf: statForceInterruptCheck].
		arg = 59  	ifTrue: [result := objectMemory integerObjectOf: statCheckForEvents].
		arg = 60  	ifTrue: [result := objectMemory integerObjectOf: statStackOverflow].
		arg = 61  	ifTrue: [result := objectMemory integerObjectOf: statStackPageDivorce].
		arg = 62	ifTrue: [result := self getCodeCompactionCount].
		arg = 63	ifTrue: [result := self getCodeCompactionMSecs].
		arg = 64	ifTrue: [result := self getCogMethodCount].
		
		self pop: 2 thenPush: result.
		^nil].

	"write a VM parameter"
	argumentCount = 2 ifFalse: [^self primitiveFailFor: PrimErrBadNumArgs].
	index := self stackValue: 1.
	(objectMemory isIntegerObject: index) ifFalse: [^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	(index <= 0 or: [index > 63]) ifTrue: [^self primitiveFailFor: PrimErrBadIndex].
	self success: false.
	index = 5 ifTrue: [
		"Was:
		result := allocationsBetweenGCs.
		allocationsBetweenGCs := arg."
		"Ignore for now, because old images won't start up otherwise.
		 See 44 & 45 for eden size setting."
		result := objectMemory nilObject.
		self initPrimCall].
	index = 6 ifTrue: [
		result := objectMemory tenuringThreshold.
		objectMemory tenuringThreshold: arg.
		self initPrimCall].
	index = 23 ifTrue: [
		result := extraVMMemory.
		extraVMMemory := arg.
		self initPrimCall].
	index = 24 ifTrue: [
		result := objectMemory shrinkThreshold.
		arg > 0 ifTrue:[
			objectMemory shrinkThreshold: arg.
			self initPrimCall]].
	index = 25 ifTrue: [
		result := objectMemory growHeadroom.
		arg > 0 ifTrue:[
			objectMemory growHeadroom: arg.
			self initPrimCall]].
	index = 26 ifTrue: [
		arg > 1 ifTrue:[
			result := self ioHeartbeatMilliseconds.
			self ioSetHeartbeatMilliseconds: arg.
			self initPrimCall]].
	index = 43 ifTrue: [
		(arg >= 0 and: [arg <= 65535]) ifTrue:[
			result := desiredNumStackPages.
			desiredNumStackPages := arg.
			self initPrimCall]].
	index = 45 ifTrue: [
		(arg >= 0) ifTrue:[
			result := desiredEdenBytes.
			desiredEdenBytes := arg.
			self initPrimCall]].
	(index = 47 and: [self isCog]) ifTrue: [
		(arg >= 0) ifTrue:[
			result := self getDesiredCogCodeSize.
			self setDesiredCogCodeSize: arg.
			self initPrimCall]].
	(index = 48 and: [self isCog]) ifTrue: [
		(arg >= 0) ifTrue:[
			result := self getCogVMFlags.
			self initPrimCall. "i.e. setCogVMFlags: can fail"
			self setCogVMFlags: arg]].
	index = 49 ifTrue:
		[(arg >= 0 and: [arg <= 65535]) ifTrue:
			[result := self ioGetMaxExtSemTableSize.
			self initPrimCall. "i.e. ioSetMaxExtSemTableSize: is allowed to fail"
			self setMaxExtSemSizeTo: arg]].

	self successful ifTrue:
		[self pop: 3 thenPush: (objectMemory integerObjectOf: result).  "return old value"
		^ nil].

	self primitiveFailFor: PrimErrInappropriate  "attempting to write a read-only or non-existent parameter"
]

{ #category : #'system control primitives' }
StackInterpreterPrimitives >> primitiveVoidReceiver [
	"Potentially crash the VM by voiding the receiver.  A subsequent inst var
	 access in the caller's frame should indirect through a null pointer."
	<export: true>
	stackPages longAt: (self frameReceiverOffset: framePointer) put: 0
]

{ #category : #'system control primitives' }
StackInterpreterPrimitives >> primitiveVoidVMState [
	"Void all internal VM state in the stack and machine code zones"
	| activeContext |
	self push: instructionPointer.
	activeContext := self voidVMStateForSnapshot.
	self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext
]
