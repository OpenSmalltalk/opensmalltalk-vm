"
This class defines basic memory access and primitive simulation so that the CoInterpreter can run simulated in the Squeak environment.  It also defines a number of handy object viewing methods to facilitate pawing around in the object memory.  Remember that you can test the Cogit using its class-side in-image compilation facilities.

To see the thing actually run, you could (after backing up this image and changes), execute

	(CogVMSimulator new openOn: Smalltalk imageName) test

and be patient both to wait for things to happen, and to accept various things that may go wrong depending on how large or unusual your image may be.  We usually do this with a small and simple benchmark image.

Here's an example to launch the simulator in a window.  The bottom-right window has a menu packed with useful stuff:

(CogVMSimulator newWithOptions: #(Cogit StackToRegisterMappingCogit))
	desiredNumStackPages: 8;
	openOn: '/Users/eliot/Cog/startreader.image';
	openAsMorph;
	run

Here's a hairier example that I (Eliot) actually use in daily development with some of the breakpoint facilities commented out.

| cos proc opts |
CoInterpreter initializeWithOptions: (opts := Dictionary newFromPairs: #(Cogit StackToRegisterMappingCogit)).
CogVMSimulator chooseAndInitCogitClassWithOpts: opts.
cos := CogVMSimulator new.
""cos initializeThreadSupport."" ""to test the multi-threaded VM""
cos desiredNumStackPages: 8. ""to set the size of the stack zone""
""cos desiredCogCodeSize: 8 * 1024 * 1024."" ""to set the size of the Cogit's code zone""
cos openOn: '/Users/eliot/Squeak/Squeak4.4/trunk44.image'. ""choose your favourite image""
""cos setBreakSelector: 'r:degrees:'."" ""set a breakpoint at a specific selector""
proc := cos cogit processor.
""cos cogit sendTrace: 7."" ""turn on tracing""
""set a complex breakpoint at a specific point in machine code""
""cos cogit singleStep: true; breakPC: 16r56af; breakBlock: [:cg|  cos framePointer > 16r101F3C and: [(cos longAt: cos framePointer - 4) = 16r2479A and: [(cos longAt: 16r101F30) = (cos longAt: 16r101F3C) or: [(cos longAt: 16r101F2C) = (cos longAt: 16r101F3C)]]]]; sendTrace: 1"".
""[cos cogit compilationTrace: -1] on: MessageNotUnderstood do: [:ex|]."" ""turn on compilation tracing in the StackToRegisterMappingCogit""
""cos cogit setBreakMethod: 16rB38880.""
cos
	openAsMorph;
	""toggleTranscript;"" ""toggleTranscript will send output to the Transcript instead of the morph's rather small window""
	halt;
	run
"
Class {
	#name : #CogVMSimulator,
	#superclass : #CoInterpreterMT,
	#instVars : [
		'parent',
		'enableCog',
		'byteCount',
		'lastPollCount',
		'lastExtPC',
		'sendCount',
		'lookupCount',
		'printSends',
		'traceOn',
		'myBitBlt',
		'displayForm',
		'fakeForm',
		'imageName',
		'pluginList',
		'mappedPluginEntries',
		'quitBlock',
		'transcript',
		'displayView',
		'eventTransformer',
		'printFrameAtEachStep',
		'printBytecodeAtEachStep',
		'systemAttributes',
		'uniqueIndices',
		'uniqueIndex',
		'breakCount',
		'atEachStepBlock',
		'startMicroseconds',
		'lastYieldMicroseconds',
		'externalSemaphoreSignalRequests',
		'externalSemaphoreSignalResponses',
		'extSemTabSize',
		'debugStackDepthDictionary',
		'performFilters',
		'eventQueue',
		'expectedSends',
		'expecting',
		'bootstrapping',
		'primitiveFailCount'
	],
	#classVars : [
		'ByteCountsPerMicrosecond',
		'ExpectedSends'
	],
	#category : #'VMMaker-JITSimulation'
}

{ #category : #'debug support' }
CogVMSimulator class >> expectedSends [
	^ExpectedSends
]

{ #category : #initialization }
CogVMSimulator class >> initializeWithOptions: optionsDictionary [
	super initializeWithOptions: optionsDictionary.

	ByteCountsPerMicrosecond := InitializationOptions
										at: #ByteCountsPerMicrosecond
										ifAbsent: [100]
]

{ #category : #'class initialization' }
CogVMSimulator class >> initializeWithOptions: optionsDictionaryOrArray objectMemoryClass: objectMemoryClassOrNil [
	"The relevant ObjectMemory, Interpreter and Cogit classes must be initialized in order.
	 This happens notionally every time we start the simulator,
	 but in fact happens when ever we instantiate a simulator."
	InitializationOptions := optionsDictionaryOrArray isArray
							ifTrue: [Dictionary newFromPairs: optionsDictionaryOrArray]
							ifFalse: [optionsDictionaryOrArray].

	(objectMemoryClassOrNil ifNil: [self objectMemoryClass])
		initializeWithOptions: InitializationOptions.

	self initializeWithOptions: InitializationOptions.

	(self cogitClass withAllSuperclasses copyUpTo: Cogit) reverseDo:
		[:c| c initializeWithOptions: InitializationOptions]
]

{ #category : #'instance creation' }
CogVMSimulator class >> new [
	^self onObjectMemory: nil cogit: nil options: #()
]

{ #category : #'instance creation' }
CogVMSimulator class >> newWithOptions: optionsDictionaryOrArray [
	^self onObjectMemory: nil cogit: nil options: optionsDictionaryOrArray
]

{ #category : #'instance creation' }
CogVMSimulator class >> onObjectMemory: anObjectMemory [
	^self onObjectMemory: anObjectMemory cogit: nil options: #()
]

{ #category : #'instance creation' }
CogVMSimulator class >> onObjectMemory: anObjectMemory cogit: aCogit [
	^self onObjectMemory: anObjectMemory cogit: aCogit options: #()
]

{ #category : #'instance creation' }
CogVMSimulator class >> onObjectMemory: anObjectMemory cogit: aCogit options: optionsDictionaryOrArray [
	| simulatorClass |
	^self == CogVMSimulator
		ifTrue:
			[simulatorClass := SmalltalkImage current endianness == #big
				ifTrue: [self notYetImplemented]
				ifFalse: [CogVMSimulatorLSB].
			simulatorClass
				initializeWithOptions: optionsDictionaryOrArray
				objectMemoryClass: (anObjectMemory ifNotNil: [anObjectMemory class]).
			 simulatorClass
				onObjectMemory: (anObjectMemory ifNil:
										[self objectMemoryClass simulatorClass new])
				cogit: aCogit
				options: optionsDictionaryOrArray]
		ifFalse:
			[| sim |
			sim := self basicNew.
			sim objectMemory: anObjectMemory.
			sim cogit: aCogit.
			sim initialize.
			COGMTVM ifTrue: "Set via options"
				[sim initializeThreadSupport; initialize].
			sim]
]

{ #category : #'debug support' }
CogVMSimulator >> allObjectsSelect: objBlock [
	"self allObjectsSelect: [:oop | (self baseHeader: oop) = 1234]"

	| selected |
	selected := OrderedCollection new.
	objectMemory allObjectsDo:
		[:oop| (objBlock value: oop) ifTrue: [selected addLast: oop]].
	^ selected
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> assertCStackPointersBelongToCurrentThread [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #assertCStackPointersBelongToCurrentThread
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> assertCStackPointersBelongToCurrentVMOwner [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #assertCStackPointersBelongToCurrentVMOwner
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> assertSaneThreadAndProcess [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #assertSaneThreadAndProcess
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #accessing }
CogVMSimulator >> atEachStepBlock [
	^atEachStepBlock
]

{ #category : #accessing }
CogVMSimulator >> atEachStepBlock: aBlock [
	atEachStepBlock := aBlock
]

{ #category : #'jump bytecodes' }
CogVMSimulator >> attemptToSwitchToMachineCode: bcpc [
	"method = 16r96A294 ifTrue: [self halt]."
	^super attemptToSwitchToMachineCode: bcpc
]

{ #category : #'return bytecodes' }
CogVMSimulator >> baseFrameReturn [
	"| contextToReturnTo |
	contextToReturnTo := self frameCallerContext: localFP.
	(self stringOf: (self penultimateLiteralOf: (self fetchPointer: MethodIndex ofObject: contextToReturnTo))) = #indexOf:startingAt:ifAbsent: ifTrue:
		[self halt]."
	^super baseFrameReturn
]

{ #category : #initialization }
CogVMSimulator >> basicInitialize [
	"Initialize the CogVMSimulator when running the interpreter inside Smalltalk.  The
	 primary responsibility of this method is to allocate Smalltalk Arrays for variables
	 that will be declared as statically-allocated global arrays in the translated code."
	super initialize.

	transcript := Transcript.
	bootstrapping := false.

	objectMemory ifNil:
		[objectMemory := self class objectMemoryClass simulatorClass new].
	cogit ifNil:
		[cogit := self class cogitClass new setInterpreter: self].
	objectMemory coInterpreter: self cogit: cogit.

	(cogit numRegArgs > 0
	 and: [VMClass initializationOptions at: #CheckStackDepth ifAbsent: [true]]) ifTrue:
		[debugStackDepthDictionary := Dictionary new].

	cogThreadManager ifNotNil:
		[super initialize].

	self assert: ConstMinusOne = (objectMemory integerObjectOf: -1).

	cogMethodZone := cogit methodZone. "Because Slang can't remove intermediate implicit receivers (cogit methodZone foo doesn't reduce to foo())"
	enableCog := true.

	methodCache := Array new: MethodCacheSize.
	atCache := nil.
	self flushMethodCache.
	cogCompiledCodeCompactionCalledFor := false.
	gcSemaphoreIndex := 0.
	externalSemaphoreSignalRequests := externalSemaphoreSignalResponses := #().
	externalPrimitiveTable := CArrayAccessor on: (Array
		new: MaxExternalPrimitiveTableSize
		withAll: 0).
	externalPrimitiveTableFirstFreeIndex := 0.
	primitiveTable := self class primitiveTable copy.

	desiredNumStackPages := desiredEdenBytes := desiredCogCodeSize := 0.
	"This is initialized on loading the image, but convenient for testing stack page values..."
	numStackPages := self defaultNumStackPages. 
	startMicroseconds := lastYieldMicroseconds := self ioUTCStartMicroseconds.
	maxLiteralCountForCompile := MaxLiteralCountForCompile.
	minBackwardJumpCountForCompile := MinBackwardJumpCountForCompile.
	flagInterpretedMethods := false.

	"initialize InterpreterSimulator variables used for debugging"
	byteCount := lastPollCount := sendCount := lookupCount := 0.
	quitBlock := [^self close].
	traceOn := true.
	printSends := printFrameAtEachStep := printBytecodeAtEachStep := false.
	myBitBlt := BitBltSimulator new setInterpreter: self.
	displayForm := fakeForm := 'Display has not yet been installed' asDisplayText form.
	eventQueue := SharedQueue new.
	suppressHeartbeatFlag := deferSmash := deferredSmash := false.
	systemAttributes := Dictionary new.
	primTraceLog := CArrayAccessor on: (Array new: 256 withAll: 0).
	primTraceLogIndex := 0.
	traceLog := CArrayAccessor on: (Array new: TraceBufferSize withAll: 0).
	traceLogIndex := 0.
	traceSources := TraceSources.
	statCodeCompactionCount := 0.
	statCodeCompactionUsecs := 0.
	extSemTabSize := 256.
	
	"This will be overriden when calling initializePluginEntries"
	mappedPluginEntries := OrderedCollection new.
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> bindProcess: aProcess toId: newId [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #bindProcess:toId:
		withArguments: {aProcess. newId}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #accessing }
CogVMSimulator >> bootstrapping: aBoolean [
	bootstrapping := aBoolean.
	objectMemory ifNotNil:
		[objectMemory bootstrapping: aBoolean]
]

{ #category : #accessing }
CogVMSimulator >> breakCount [
	^breakCount
]

{ #category : #'interpreter shell' }
CogVMSimulator >> browserPluginInitialiseIfNeeded [
"do nothing - its a macro in C code to support Mac browser plugin strangeness"
]

{ #category : #'interpreter shell' }
CogVMSimulator >> browserPluginReturnIfNeeded [
"do nothing - its a macro in C code to support Mac browser plugin strangeness"
]

{ #category : #'memory access' }
CogVMSimulator >> byteAt: byteAddress [
	"This is really only for the C library simulations memcpy:_:_: et al in VMClass.
	 Use objectMemory byteAt: directly where possible."
	^objectMemory byteAt: byteAddress
]

{ #category : #'memory access' }
CogVMSimulator >> byteAt: byteAddress put: byte [
	^objectMemory byteAt: byteAddress put: byte
]

{ #category : #'debug support' }
CogVMSimulator >> byteCount [
	"So you can call this from temp debug statements in, eg, Interpreter, such as
	self byteCount = 12661 ifTrue: [self halt].
	"

	^ byteCount
]

{ #category : #UI }
CogVMSimulator >> byteCountText [
	^(String streamContents: [:s| s nextPutAll: byteCount asStringWithCommas; nextPut: $/; nextPutAll: sendCount asStringWithCommas]) asText
]

{ #category : #'translation support' }
CogVMSimulator >> cCoerceSimple: value to: cTypeString [
	"Type coercion for translation and simulation.
	 For simulation answer a suitable surrogate for the struct types"
	^cTypeString
		caseOf:
		   {	[#'CogMethod *']		->	[cogit cogMethodSurrogateAt: value asUnsignedInteger].
			[#'CogBlockMethod *']	->	[cogit cogBlockMethodSurrogateAt: value asUnsignedInteger] }
		otherwise: [value]
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> cStackRangeForCurrentThread [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #cStackRangeForCurrentThread
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> cStackRangeForCurrentVMOwner [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #cStackRangeForCurrentVMOwner
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> cStackRangeForThreadIndex: threadIndex [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #cStackRangeForThreadIndex:
		withArguments: {threadIndex}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'plugin support' }
CogVMSimulator >> callExternalPrimitive: mapIndex [
	| entry |
	entry := self pluginEntryFor: mapIndex.
	"Spur needs the primitiveFunctionPointer to be set correctly
	 for accurate following of forwarders on primitive failure."
	objectMemory hasSpurMemoryManagerAPI ifTrue:
		[primitiveFunctionPointer := entry at: 2].
	^(entry at: 1) perform: (entry at: 2)
]

{ #category : #enilopmarts }
CogVMSimulator >> ceActivateFailingPrimitiveMethod: aPrimitiveMethod [
	"self halt."
	^super ceActivateFailingPrimitiveMethod: aPrimitiveMethod
]

{ #category : #trampolines }
CogVMSimulator >> ceBaseFrameReturn: returnValue [
	"self printCallStackOf: (stackPages longAt: stackPage baseAddress) currentFP: stackPage baseFP.
	Transcript print: byteCount; tab; print: thisContext; cr.
	(self confirm: 'continue?') ifFalse: [self returnValue hex]."
	"returnValue = 16r01934F78 ifTrue: [self halt]."
	"| contextToReturnTo |
	contextToReturnTo := stackPages longAt: stackPage baseAddress.
	(self stringOf: (self penultimateLiteralOf: (self fetchPointer: MethodIndex ofObject: contextToReturnTo))) = #indexOf:startingAt:ifAbsent: ifTrue:
		[self halt]."
	^super ceBaseFrameReturn: returnValue
]

{ #category : #trampolines }
CogVMSimulator >> ceContext: aOnceMarriedContext instVar: slotIndex [
	cogit assertCStackWellAligned.
	^super ceContext: aOnceMarriedContext instVar: slotIndex
]

{ #category : #trampolines }
CogVMSimulator >> ceContext: aOnceMarriedContext instVar: slotIndex value: anOop [
	"aOnceMarriedContext = 26431360 ifTrue:
		[transcript cr; cr.
		 self printContext: aOnceMarriedContext.
		 transcript cr.
		 (self isContext: anOop)
			ifTrue: [self printContext: anOop]
			ifFalse: [self printOop: anOop].
		 self halt]."
	cogit assertCStackWellAligned.
	^super ceContext: aOnceMarriedContext instVar: slotIndex value: anOop
]

{ #category : #'cog jit support' }
CogVMSimulator >> ceCounterTripped: condition [
	| counterTrippedSelector |
	self transcript cr; nextPutAll: 'counter tripped in '.
	self shortPrintFrame: framePointer.
	counterTrippedSelector := objectMemory maybeSplObj: SelectorCounterTripped.
	(counterTrippedSelector isNil
	or: [counterTrippedSelector = objectMemory nilObject]) ifFalse:
		[self halt: 'counter tripped'].
	^super ceCounterTripped: condition
]

{ #category : #trampolines }
CogVMSimulator >> ceMNUFromPICMNUMethod: aMethodObj receiver: rcvr [
	| cPIC |
	cPIC := self cCoerceSimple: self stackTop - cogit mnuOffset to: #'CogMethod *'.
	self assert: (cPIC cmType = CMClosedPIC or: [cPIC cmType = CMOpenPIC]).
	self mnuBreakpoint: cPIC selector receiver: nil.
	^super ceMNUFromPICMNUMethod: aMethodObj receiver: rcvr
]

{ #category : #'debug support' }
CogVMSimulator >> ceNonLocalReturn: returnValue [
	"self halt."
	^super ceNonLocalReturn: returnValue
]

{ #category : #trampolines }
CogVMSimulator >> ceReapAndResetErrorCodeFor: cogMethod [
	"Override to map the address into a CogMethodSurrogate"
	| surrogate |
	surrogate := cogMethod isInteger
					ifTrue: [cogit cogMethodSurrogateAt: cogMethod]
					ifFalse: [cogMethod].
	^super ceReapAndResetErrorCodeFor: surrogate
]

{ #category : #trampolines }
CogVMSimulator >> ceSend: selector super: superNormalBar to: rcvr numArgs: numArgs [
	"self stringOf: selector"
	"self printOop: rcvr"
	"(superNormalBar ~= 0 and: [(self stringOf: selector) = #bitShift:]) ifTrue:
		[self halt]."
	self logSend: selector.
	cogit assertCStackWellAligned.
	self maybeCheckStackDepth: numArgs + 1 sp: stackPointer pc: (stackPages longAt: stackPointer).
	^super ceSend: selector super: superNormalBar to: rcvr numArgs: numArgs
]

{ #category : #trampolines }
CogVMSimulator >> ceSendAbort: selector to: rcvr numArgs: numArgs [
	"self stringOf: selector"
	"self printOop: rcvr"
	self logSend: selector.
	cogit assertCStackWellAligned.
	self maybeCheckStackDepth: numArgs + 1
		sp: stackPointer
		pc: (stackPages longAt: stackPointer).
	^super ceSendAbort: selector to: rcvr numArgs: numArgs
]

{ #category : #trampolines }
CogVMSimulator >> ceSendFromInLineCacheMiss: oPIC [
	"Override to map the address into a CogMethodSurrogate"
	| surrogate |
	surrogate := oPIC isInteger
					ifTrue: [cogit cogMethodSurrogateAt: oPIC]
					ifFalse: [oPIC].
	self logSend: surrogate selector.
	(surrogate cmNumArgs = 0
	 and: [(self stackValue: 1) = 16r8169D0
	 and: [self stackTop = 16r53EA7]]) ifTrue:
		[self halt].
	^super ceSendFromInLineCacheMiss: surrogate
]

{ #category : #trampolines }
CogVMSimulator >> ceSendMustBeBoolean: anObject [
	self halt.
	^super ceSendMustBeBoolean: anObject
]

{ #category : #trampolines }
CogVMSimulator >> ceStackOverflow: contextSwitchIfNotNil [
	"Override to bump up the byteCount from which the microsecond clock is derived."
	byteCount := byteCount + 1000.
	self doOrDefer: [self changed: #byteCountText; changed: #composeAll].
	^super ceStackOverflow: contextSwitchIfNotNil
]

{ #category : #'debug support' }
CogVMSimulator >> ceTraceBlockActivation [
	cogit printOnTrace ifTrue:
		[transcript print: byteCount; nextPut: $/; print: (sendCount := sendCount + 1); space].
	cogit assertCStackWellAligned.
	super ceTraceBlockActivation.
	^#continue
]

{ #category : #'debug support' }
CogVMSimulator >> ceTraceLinkedSend: theReceiver [
	(sendCount := sendCount + 1) \\ 500 = 0 ifTrue:
		[self changed: #byteCountText].
	cogit printOnTrace ifTrue:
		[transcript print: byteCount; nextPut: $/; print: sendCount; space].
	cogit assertCStackWellAligned.
	super ceTraceLinkedSend: theReceiver.
	^#continue
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> cedeToHigherPriorityThreads [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #cedeToHigherPriorityThreads
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> checkForEventsMayContextSwitch: mayContextSwitch [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #checkForEventsMayContextSwitch:
		withArguments: {mayContextSwitch}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'object memory support' }
CogVMSimulator >> checkStackIntegrity [
	"Override to deal with incomplete initialization."
	stackPages ifNil: [^true].
	stackPages pages ifNil: [^true].
	^super checkStackIntegrity
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> checkVMOwnershipFromHeartbeat [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #checkVMOwnershipFromHeartbeat
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'debug support' }
CogVMSimulator >> classAndSelectorOfMethod: meth forReceiver: rcvr [
	| mClass dict length methodArray |
	mClass := objectMemory fetchClassOf: rcvr.
	[dict := objectMemory fetchPointer: MethodDictionaryIndex ofObject: mClass.
	length := objectMemory numSlotsOf: dict.
	methodArray := objectMemory fetchPointer: MethodArrayIndex ofObject: dict.
	0 to: length-SelectorStart-1 do: 
		[:index | 
		meth = (objectMemory fetchPointer: index ofObject: methodArray) 
			ifTrue: [^ Array
				with: mClass
				with: (objectMemory fetchPointer: index + SelectorStart ofObject: dict)]].
	mClass := objectMemory fetchPointer: SuperclassIndex ofObject: mClass.
	mClass = objectMemory nilObject]
		whileFalse: [].
	^ Array
		with: (objectMemory fetchClassOf: rcvr)
		with: (objectMemory splObj: SelectorDoesNotUnderstand)
]

{ #category : #'plugin support' }
CogVMSimulator >> classNameOf: aClass Is: className [
	"Check if aClass' name is className"
	| name |
	(objectMemory lengthOf: aClass) <= classNameIndex ifTrue:
		[^false]. "Not a class but maybe behavior" 
	name := objectMemory fetchPointer: classNameIndex ofObject: aClass.
	(objectMemory isBytes: name) ifFalse:
		[^false].
	^ className = (self stringOf: name)
]

{ #category : #'I/O primitives' }
CogVMSimulator >> clipboardRead: sz Into: actualAddress At: zeroBaseIndex [
	| str |
	str := Clipboard clipboardText.
	1 to: sz do:
		[:i | objectMemory byteAt: actualAddress + zeroBaseIndex + i - 1 put: (str at: i) asciiValue]
]

{ #category : #'I/O primitives' }
CogVMSimulator >> clipboardSize [

	^ Clipboard clipboardText size
]

{ #category : #'I/O primitives' }
CogVMSimulator >> clipboardWrite: sz From: actualDataAddress At: ignored [

	Clipboard clipboardText: (self stringOf: actualDataAddress - objectMemory baseHeaderSize)
]

{ #category : #'debug support' }
CogVMSimulator >> cloneSimulation [
	| savedDisplayView savedDisplayForm savedQuitBlock savedTranscript |
	savedDisplayView := displayView. displayView := nil.
	savedDisplayForm := displayForm. displayForm = nil.
	savedQuitBlock := quitBlock. quitBlock := nil.
	savedTranscript := transcript. transcript := nil.

	^[| theClone |
	 Smalltalk garbageCollect.
	 theClone := self veryDeepCopy.
	 theClone parent: self; transcript: Transcript.
	 theClone objectMemory parent: objectMemory.
	 theClone]
		ensure:
			[displayView := savedDisplayView.
			 displayForm = savedDisplayForm.
			 quitBlock := savedQuitBlock.
			 transcript := savedTranscript]
]

{ #category : #'debug support' }
CogVMSimulator >> cloneSimulationWindow [
	| label |
	label := 'Clone of ', (displayView containingWindow label allButFirst: 'Simulation of ' size).
	^self cloneSimulation openAsMorph
		setLabel: label;
		yourself
]

{ #category : #initialization }
CogVMSimulator >> close [  "close any files that ST may have opened, etc"
	pluginList do: [:assoc| | plugin | plugin := assoc value. plugin ~~ self ifTrue: [plugin close]]
]

{ #category : #'primitive support' }
CogVMSimulator >> codeGeneratorToComputeAccessorDepth [

	^ codeGeneratorToComputeAccessorDepth ifNil: [
		(VMMaker new
			buildCodeGeneratorForInterpreter: CoInterpreterPrimitives
			includeAPIMethods: false
			initializeClasses: false)
				logger: self transcript;
				yourself]
]

{ #category : #'as yet unclassified' }
CogVMSimulator >> codeGeneratorToComputeAccessorDepth: aCCodeGenerator [ 

	codeGeneratorToComputeAccessorDepth := aCCodeGenerator
]

{ #category : #'simulation only' }
CogVMSimulator >> cogit [
	^cogit
]

{ #category : #'debug support' }
CogVMSimulator >> collectSends [
	expectedSends := WriteStream on: (Array new: 65536).
	expecting := false
]

{ #category : #'cog jit support' }
CogVMSimulator >> commenceCogCompiledCodeCompaction [
	"self halt."
	^super commenceCogCompiledCodeCompaction
]

{ #category : #'frame access' }
CogVMSimulator >> convertToMachineCodeFrame: cogHomeMethod bcpc: bcpc [
	"bytecodeSetSelector ~= 0 ifTrue: [self halt]".
	^super convertToMachineCodeFrame: cogHomeMethod bcpc: bcpc
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> copyBits [

	^ myBitBlt copyBits
]

{ #category : #'debug printing' }
CogVMSimulator >> cr [

	traceOn ifTrue: [ transcript cr; flush ].
]

{ #category : #'debugging traps' }
CogVMSimulator >> createActualMessageTo: class [

	class = objectMemory nilObject ifTrue: [self halt].

	^super createActualMessageTo: class
]

{ #category : #'debug support' }
CogVMSimulator >> debugStackPointersFor: aMethod [
	^CArrayAccessor on:
		(StackDepthFinder on: (VMCompiledMethodProxy new
									for: aMethod
									coInterpreter: self
									objectMemory: objectMemory))
			stackPointers
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> deferStackLimitSmashAround: functionSymbol [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #deferStackLimitSmashAround:
		withArguments: {functionSymbol}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> deferStackLimitSmashAround: functionSymbol with: arg [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #deferStackLimitSmashAround:with:
		withArguments: {functionSymbol. arg}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #initialization }
CogVMSimulator >> desiredCogCodeSize: anInteger [
	desiredCogCodeSize := anInteger
]

{ #category : #UI }
CogVMSimulator >> desiredDisplayExtent [
	^(savedWindowSize
		ifNil: [640@480]
		ifNotNil: [savedWindowSize >> 16 @ (savedWindowSize bitAnd: 16rFFFF)])
			min: Display extent * 2 // 3
]

{ #category : #initialization }
CogVMSimulator >> desiredEdenBytes: anInteger [
	desiredEdenBytes := anInteger
]

{ #category : #initialization }
CogVMSimulator >> desiredNumStackPages: anInteger [
	desiredNumStackPages := anInteger
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> disownVM: flags [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #disownVM:
		withArguments: {flags}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'plugin primitive support' }
CogVMSimulator >> dispatchMappedPluginEntry: n [ 
	^(mappedPluginEntries at: n) first
		perform: (mappedPluginEntries at: n) second
]

{ #category : #'interpreter shell' }
CogVMSimulator >> dispatchOn: anInteger in: selectorArray [
	"Simulate a case statement via selector table lookup.
	The given integer must be between 0 and selectorArray size-1, inclusive.
	For speed, no range test is done, since it is done by the at: operation.
	Note that, unlike many other arrays used in the Interpreter, this method expect NO CArrayAccessor wrapping - it would duplicate the +1. Maybe this would be better updated to make it all uniform"
	cogit breakPC ifNil:
		[cogit breakBlock ifNotNil:
			[:bb| (bb value: cogit) ifTrue: [self halt: 'breakpoint reached']]].
	self perform: (selectorArray at: (anInteger + 1)).
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> displayLocation [

	^ Display extent - displayForm extent - (10@10)
]

{ #category : #accessing }
CogVMSimulator >> displayView [
	"The VM SImulator draws directly on an imageMorph named displayView
	  displayView is housed on a Form named displayForm
	  Since this is housed directly on the Morph, I have this tight compling from here->model->morph. 
	"
	self flag: 'tty'.	
	^displayView
]

{ #category : #'process primitive support' }
CogVMSimulator >> doSignalExternalSemaphores: minTableSize [
	"This is a non-thread-safe simulation.  See platforms/Cross/vm/sqExternalSemaphores.c
	 for the real code.  For the benefit of the SocketPluginSimulator, do a yield every 100
	 virtual microseconds."
	| now switched |
	now := self ioUTCMicroseconds.
	now - lastYieldMicroseconds >= 100 ifTrue:
		[lastYieldMicroseconds := now.
		 Processor yield].

	switched := false.
	1 to: (minTableSize min: externalSemaphoreSignalRequests size) do:
		[:i| | responses |
		responses := externalSemaphoreSignalResponses at: i.
		[responses < (externalSemaphoreSignalRequests at: i)] whileTrue:
			[(self doSignalSemaphoreWithIndex: i) ifTrue:
				[switched := true].
			 externalSemaphoreSignalResponses at: i put: (responses := responses + 1)]].
	^switched
]

{ #category : #'error handling' }
CogVMSimulator >> doesNotUnderstand: aMessage [
	"If this is a doit and the objectMemory understands, pass it on."
	(thisContext findContextSuchThat: [:ctxt| ctxt selector == #evaluate:in:to:notifying:ifFail:logged:]) ifNotNil:
		[(objectMemory class whichClassIncludesSelector: aMessage selector) ifNotNil:
			[:implementingClass|
			(implementingClass inheritsFrom: Object) ifTrue: "i.e. VMClass and below"
				[thisContext sender selector ~~ #DoIt ifTrue:
					[Transcript nextPutAll: 'warning: redirecting ', aMessage selector, ' in ', thisContext sender printString, ' to objectMemory'; cr; flush].
				 aMessage lookupClass: nil.
				^aMessage sentTo: objectMemory]].
		(cogit class whichClassIncludesSelector: aMessage selector) ifNotNil:
			[:implementingClass|
			(implementingClass inheritsFrom: Object) ifTrue: "i.e. VMClass and below"
				[thisContext sender selector ~~ #DoIt ifTrue:
					[Transcript nextPutAll: 'warning: redirecting ', aMessage selector, ' in ', thisContext sender printString, ' to cogit'; cr; flush].
				 aMessage lookupClass: nil.
				^aMessage sentTo: cogit]]].
	^super doesNotUnderstand: aMessage
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> drawLoopX: xDelta Y: yDelta [

	^ myBitBlt drawLoopX: xDelta Y: yDelta
]

{ #category : #'debug support' }
CogVMSimulator >> dumpMethodHeader: hdr [
	^ String streamContents:
		[:strm |
		strm nextPutAll: '<nArgs=', ((hdr >> 25) bitAnd: 16r1F) printString , '>'.
		strm nextPutAll: '<nTemps=', ((hdr >> 19) bitAnd: 16r3F) printString , '>'.
		strm nextPutAll: '<lgCtxt=', ((hdr >> 18) bitAnd: 16r1) printString , '>'.
		strm nextPutAll: '<nLits=', ((hdr >> 10) bitAnd: 16rFF) printString , '>'.
		strm nextPutAll: '<prim=', ((hdr >> 1) bitAnd: 16r1FF) printString , '>'.
		]
]

{ #category : #'debug printing' }
CogVMSimulator >> elementsPerPrintOopLine [
	^4
]

{ #category : #'debugging traps' }
CogVMSimulator >> enableCog: aBoolean [
	enableCog := aBoolean
]

{ #category : #'frame access' }
CogVMSimulator >> ensureContextIsExecutionSafeAfterAssignToStackPointer: aContext [
	"16r1934F80 = aContext ifTrue:
		[self halt]."
	^super ensureContextIsExecutionSafeAfterAssignToStackPointer: aContext
]

{ #category : #testing }
CogVMSimulator >> ensureDebugAtEachStepBlock [
	atEachStepBlock := [printFrameAtEachStep ifTrue:
							[self printFrame: localFP WithSP: localSP].
						 printBytecodeAtEachStep ifTrue:
							[self printCurrentBytecodeOn: transcript.
							 transcript cr; flush].
						 byteCount = breakCount ifTrue:
							["printFrameAtEachStep :=" printBytecodeAtEachStep := true]]
]

{ #category : #'frame access' }
CogVMSimulator >> ensureMethodIsCogged: methodObj maybeClosure: maybeClosure [
	"Uncomment this to compact frequently and hence test if clients are ready for the shock."
	"[self commenceCogCompiledCodeCompaction]
		on: Halt
		do: [:ex| ex resume: nil]."
	^super ensureMethodIsCogged: methodObj maybeClosure: maybeClosure
]

{ #category : #initialization }
CogVMSimulator >> ensureMultiThreadingOverridesAreUpToDate [
	"Make sure the CoInterpreterMT switch methods are implemented.  These methods select
	 between CoInterpreterMT's implementation or CoInterpreter's implementation depending
	 on cogThreadManager being non-nil or nil respectively.  i.e. they allow us to use this one
	 simulator class to simulate for both CoInterpreterMT and CoInterpreter."
	| thisClass me mtInterpreterClass |
	self cppIf: COGMTVM ifTrue: [  ] ifFalse: [ ^self ].
	thisClass := thisContext methodClass.
	mtInterpreterClass := thisClass superclass.
	me := thisClass name, '>>', thisContext method selector.
	"We want override switches for everything implemented by CoInterpreter
	 and CoInterpreterMT that is either not implemented by CogVMSimulator
	 or already implemented by CogVMSimulator as an override switch."
	(mtInterpreterClass selectors select:
		[:sel|
		(mtInterpreterClass superclass whichClassIncludesSelector: sel) notNil
		and: [(thisClass organization categoryOfElement: sel)
				ifNil: [true]
				ifNotNil: [:cat| cat == #'multi-threading simulation switch']]])
		do: [:sel| | argNames desiredSource |
			argNames := Parser new
							initPattern: (mtInterpreterClass sourceCodeAt: sel)
							return: [:pattern| pattern second].
			desiredSource := String streamContents:
								[:str|
								argNames isEmpty
									ifTrue: [str nextPutAll: sel]
									ifFalse:
										[sel keywords with: argNames do:
											[:kw :arg| str nextPutAll: kw; space; nextPutAll: arg; space].
										 str skip: -1].
								str
									crtab;
									nextPutAll: '"This method includes or excludes ', mtInterpreterClass name, ' methods as required.';
									crtab;
									nextPutAll: ' Auto-generated by ', me, '"';
									cr;
									crtab;
									nextPutAll: '^self perform: ';
									store: sel;
									crtab: 2;
									nextPutAll: 'withArguments: {'.
								argNames
									do: [:arg| str nextPutAll: arg]
									separatedBy: [str nextPut: $.; space].
								str
									nextPut: $};
									crtab: 2;
									nextPutAll: 'inSuperclass: (cogThreadManager ifNil: [';
									print: mtInterpreterClass superclass;
									nextPutAll: '] ifNotNil: [';
									print: mtInterpreterClass;
									nextPutAll: '])'].
			desiredSource ~= (thisClass sourceCodeAt: sel ifAbsent: ['']) asString ifTrue:
				[((thisClass includesSelector: sel)
				  and: [(thisClass compiledMethodAt: sel) messages includesAnyOf: #(halt halt:)])
					ifTrue: [self transcript cr; nextPutAll: 'WARNING, because of halts, not generating '; nextPutAll: desiredSource; cr; flush]
					ifFalse: [thisClass compile: desiredSource classified: #'multi-threading simulation switch']]].
	"Make sure obsolete CoInterpreterMT switch methods are deleted."
	((thisContext methodClass organization listAtCategoryNamed: #'multi-threading simulation switch') select:
		[:sel| (mtInterpreterClass whichClassIncludesSelector: sel) isNil]) do:
			[:sel| thisClass removeSelector: sel]
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> enterSmalltalkExecutive [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #enterSmalltalkExecutive
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> enterSmalltalkExecutiveFromCallback [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #enterSmalltalkExecutiveFromCallback
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> enterSmalltalkExecutiveImplementation [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #enterSmalltalkExecutiveImplementation
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #enilopmarts }
CogVMSimulator >> executeCogBlock: cogMethod closure: closure mayContextSwitch: mayContextSwitch [
	"self shortPrintFrameAndCallers: framePointer"
	"(#(16r56E90 16r133D0) includes: cogMethod asInteger)  ifTrue: [self halt]."
	"self halt."
	^super executeCogBlock: cogMethod closure: closure mayContextSwitch: mayContextSwitch
]

{ #category : #'debug support' }
CogVMSimulator >> expectSends: anArray [
	expectedSends := ReadStream on: anArray.
	expecting := true
]

{ #category : #'miscellaneous bytecodes' }
CogVMSimulator >> extABytecode [
	"224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)"
	(extA = 0 and: [extB = 0]) ifTrue:
		[lastExtPC := localIP].
	^super extABytecode
]

{ #category : #'miscellaneous bytecodes' }
CogVMSimulator >> extBBytecode [
	"225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)"
	(extA = 0 and: [extB = 0]) ifTrue:
		[lastExtPC := localIP].
	^super extBBytecode
]

{ #category : #'jump bytecodes' }
CogVMSimulator >> extUnconditionalJump [
	"242		11110010	i i i i i i i i	Jump i i i i i i i i (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	"| byte offset |
	byte := objectMemory byteAt: localIP + 1.
	offset := byte + (extB << 8).
	(offset < 0 and: [(self iframeBackwardBranchByte: localFP) - 2 = 1]) ifTrue: [self halt]."
	^super extUnconditionalJump
]

{ #category : #'debugging traps' }
CogVMSimulator >> externalCannotReturn: resultOop from: aContext [
	self halt.
	^super externalCannotReturn: resultOop from: aContext
]

{ #category : #'debugging traps' }
CogVMSimulator >> externalDivorceFrame: theFP andContext: ctxt [
	"((#(16r100570 16r101BC8) includes: theFP) or: [#(16r17159A4 16r1715948) includes: ctxt]) ifTrue:
		[self halt]."
	^super externalDivorceFrame: theFP andContext: ctxt
]

{ #category : #'debugging traps' }
CogVMSimulator >> externalInstVar: offset ofContext: aContext [

	"offset = InstructionPointerIndex ifTrue:
		[transcript nextPutAll: '==================='; cr.
		 self printContext: 16r1715630.
		 self printCallStackOf: aContext currentFP: framePointer.
		 transcript nextPutAll: '==================='; cr.
		 self halt]."

	| result |
	"self shortPrintFrameAndCallers: framePointer.
	transcript print: byteCount; tab; print: thisContext; cr.
	self print: offset; cr.
	self printContext: aContext.
	(self confirm: 'continue?') ifFalse: [self halt]."
	result := super externalInstVar: offset ofContext: aContext.
	"(offset = InstructionPointerIndex
	and: [(self stringOf: (self penultimateLiteralOf: (self fetchPointer: MethodIndex ofObject: aContext))) = #indexOf:startingAt:ifAbsent:]) ifTrue:
		[transcript space; nextPutAll: '^pc '; nextPutAll: result hex.
		 (objectMemory isIntegerObject: result) ifTrue:
			[transcript space; print: (objectMemory integerValueOf: result)].
		 transcript tab.
		 self shortPrintContext: aContext]."
	"offset = StackPointerIndex ifTrue:
		[transcript nextPutAll: '^stackp ', (self integerValueOf: result) printString; tab.
		 self shortPrintContext: aContext.
		 (#(24205456 24205732) includes: aContext) ifTrue:
		 	[(self checkIsStillMarriedContext: aContext currentFP: framePointer)
				ifTrue: [self printFrame: (self frameOfMarriedContext: aContext) WithSP: (self frameOfMarriedContext: aContext) - 48]
				ifFalse: [self printContext: aContext]]]."
	^result
]

{ #category : #'frame access' }
CogVMSimulator >> externalInstVar: index ofContext: aContext put: anOop [
	"self shortPrintFrameAndCallers: framePointer.
	Transcript print: byteCount; tab; print: thisContext; cr.
	self print: index; cr.
	self printContext: aContext.
	self shortPrintOop: anOop.
	(self confirm: 'continue?') ifFalse: [self halt]."
	"(self stringOf: (self penultimateLiteralOf: (self fetchPointer: MethodIndex ofObject: aContext))) = #indexOf:startingAt:ifAbsent: ifTrue:
		[self halt]."
	^super externalInstVar: index ofContext: aContext put: anOop
]

{ #category : #'frame access' }
CogVMSimulator >> externalSetStackPageAndPointersForSuspendedContextOfProcess: aProcess [
	"Override to check stack depth (hence in the simulator only)."
	super externalSetStackPageAndPointersForSuspendedContextOfProcess:  aProcess.
	(self isMachineCodeFrame: framePointer) ifTrue:
		[self maybeCheckStackDepth: 0
			sp: stackPointer
			pc: instructionPointer]
]

{ #category : #'interpreter shell' }
CogVMSimulator >> fetchByte [
	^objectMemory byteAt: (localIP := localIP + 1)
]

{ #category : #'interpreter access' }
CogVMSimulator >> fetchPointer: fieldIndex ofObject: oop [
	"index by word size, and return a pointer as long as the word size"
	self assert: (objectMemory cheapIsInMemory: oop).
	^objectMemory fetchPointer: fieldIndex ofObject: oop
]

{ #category : #'control primitives' }
CogVMSimulator >> filterPerformOf: selector to: receiver [
	"This is to allow simulator to filter start-up items to avoid as-yet unsimulatable plugins."
	performFilters ifNil: [^false].
	(performFilters at: (self shortPrint: receiver) ifAbsent: []) ifNotNil:
		[:messages|
		^messages includes: (self stringOf: selector)].
	^false
]

{ #category : #testing }
CogVMSimulator >> findNewMethodInClassTag: classTag [
"
	| cName |
	traceOn ifTrue:
		[cName := (self sizeBitsOf: class) = 16r20
			ifTrue: ['class ' , (self nameOfClass: (self fetchPointer: 6 ofObject: class))]
			ifFalse: [(self nameOfClass: class)].
		self cr; print: cName , '>>' , (self stringOf: messageSelector)].
"
	messageSelector = (objectMemory splObj: SelectorDoesNotUnderstand) ifTrue: [self halt].

	self logSend: messageSelector.
"
	(sendCount > 1000 and: [sendCount\\10 = 0]) ifTrue:
		[Transcript print: sendCount; space.
		self validate].
"
"
	(sendCount > 100150) ifTrue:
		[self qvalidate.
		messageQueue == nil ifTrue: [messageQueue := OrderedCollection new].
		messageQueue addLast: (self stringOf: messageSelector)].
"
	^super findNewMethodInClassTag: classTag
]

{ #category : #'memory access' }
CogVMSimulator >> firstIndexableField: oop [
	"This is in ObjectMemory and overridden in the obj mem simulators"
	self shouldNotImplement
]

{ #category : #'debug printing' }
CogVMSimulator >> flush [
	<cmacro: '() fflush(stdout)'>
	traceOn ifTrue: [transcript flush]
]

{ #category : #'plugin support' }
CogVMSimulator >> flushExternalPrimitives [
	self initializePluginEntries.
	super flushExternalPrimitives
]

{ #category : #'control primitives' }
CogVMSimulator >> forShortPrintString: shortPrintString filterPerformMessages: aCollection [
	performFilters ifNil:
		[performFilters := Dictionary new].
	performFilters at: shortPrintString put: aCollection
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> forceInterruptCheckFromHeartbeat [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #forceInterruptCheckFromHeartbeat
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'frame access' }
CogVMSimulator >> frameCallerContext: theFP [
	"In the StackInterpreter the saved ip field of a base frame holds the base
	 frame's caller context. But in the Cog VM the first word on the stack holds
	 the base frame's caller context, which is immediately above the stacked
	 receiver.  The asserts using frameStackedReceiverOffset: are simulation
	 only since they depend on being able to access numArgs and frameContext
	 from the frame's method and in a base return the frame state, being below
	 the stack pointer, may have already been smashed by an interrupt."
	| thePage |
	self assert: (self isBaseFrame: theFP).
	thePage := stackPages stackPageFor: theFP.
	self assert: theFP + (self frameStackedReceiverOffset: theFP) + (2 * objectMemory wordSize) = thePage baseAddress.
	self assert: (stackPages longAt: thePage baseAddress - objectMemory wordSize) = (self frameContext: theFP).
	^super frameCallerContext: theFP
]

{ #category : #'frame access' }
CogVMSimulator >> frameOfMarriedContext: aContext [ 
	| senderOop |
	senderOop := objectMemory fetchPointer: SenderIndex ofObject: aContext.
	self assert: (objectMemory isIntegerObject: senderOop).
	^self withoutSmallIntegerTags: senderOop
]

{ #category : #'debug support' }
CogVMSimulator >> framePointer [
	^framePointer
]

{ #category : #'I/O primitives' }
CogVMSimulator >> fullDisplay [
	| primFailCodeValue |
	displayForm ifNil: [^self].
	primFailCodeValue := primFailCode.
	self initPrimCall.
	self updateDisplayLeft: 0 Top: 0 Right: displayWidth Bottom: displayHeight.
	primFailCode := primFailCodeValue
]

{ #category : #'debug support' }
CogVMSimulator >> fullDisplayUpdate [
	"Preserve self successful when call asynchronously from Simulator"
	| primFailCodeValue |
	primFailCodeValue := primFailCode.
	self initPrimCall.
	super fullDisplayUpdate.
	primFailCode := primFailCodeValue
]

{ #category : #'plugin primitives' }
CogVMSimulator >> functionForPrimitiveExternalCall: methodObj [
	"Override to jump through the plugin simulation hoops."
	| symbolOrIndex |
	symbolOrIndex := super functionForPrimitiveExternalCall: methodObj.
	^symbolOrIndex isSymbol
		ifTrue: [symbolOrIndex]
		ifFalse: [(self pluginEntryFor: symbolOrIndex) at: 3]
]

{ #category : #'interpreter shell' }
CogVMSimulator >> functionPointerFor: primIndex inClass: lookupClass [
	"Override Interpreter to handle the external primitives caching.  See also
	 internalExecuteNewMethod."

	^(primIndex between: 1 and: MaxPrimitiveIndex)
		ifTrue: [primitiveTable at: primIndex + 1]
		ifFalse: [0]
]

{ #category : #'cog jit support' }
CogVMSimulator >> functionPointerForCompiledMethod: methodObj primitiveIndex: primIndex [
	^self mapFunctionToAddress: (super functionPointerForCompiledMethod: methodObj primitiveIndex: primIndex)
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> getCogVMFlags [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #getCogVMFlags
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> getImageHeaderFlags [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #getImageHeaderFlags
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> getMaxWaitingPriority [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #getMaxWaitingPriority
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'image save/restore' }
CogVMSimulator >> getShortFromFile: aFile swap: swapFlag [
	| aShort |
	aShort := self nextShortFrom: aFile.
	^swapFlag 
		ifTrue: [(aShort bitShift: -8) + ((aShort bitAnd: 16rFF) bitShift: 8)]
		ifFalse: [aShort]
]

{ #category : #'memory access' }
CogVMSimulator >> halfWordHighInLong32: long32 [
	^self subclassResponsibility
]

{ #category : #'memory access' }
CogVMSimulator >> halfWordLowInLong32: long32 [
	^self subclassResponsibility
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> handleListenEvent: aMorphicEvent [
	"openAsMorph[NoTranscript] registered me for listen events via HandMorph>>addEventListener.
	Transform the listen event and add it to my event queue.  ALso check if the displayForm shoudl resize."
	(displayForm ~~ fakeForm and: [displayForm extent ~= displayView extent]) ifTrue:
		[| newForm |
		newForm := Form
						extent: displayView extent
						depth: displayForm depth.
		 displayForm displayOn: newForm.
		 displayForm := newForm].
	((aMorphicEvent isMouse or: [aMorphicEvent isKeyboard])
	 and: [displayView bounds containsPoint: aMorphicEvent position]) ifTrue:
		[eventTransformer degenerateEvent: aMorphicEvent for: self]
]

{ #category : #'message sending' }
CogVMSimulator >> handleMNU: selectorIndex InMachineCodeTo: rcvr classForMessage: classForMessage [
	selectorIndex = SelectorCannotInterpret ifTrue:
		[self halt].
	^super handleMNU: selectorIndex InMachineCodeTo: rcvr classForMessage: classForMessage
]

{ #category : #'debug support' }
CogVMSimulator >> headerStart: oop [

	^ (objectMemory extraHeaderBytes: oop) negated
]

{ #category : #'debug support' }
CogVMSimulator >> heapMapAtWord: address Put: aBit [
	^objectMemory heapMap heapMapAtWord: address asUnsignedInteger Put: aBit
]

{ #category : #'debugging traps' }
CogVMSimulator >> ifAppropriateCompileToNativeCode: aMethodObject selector: selector [
	enableCog ifTrue:
		[super ifAppropriateCompileToNativeCode: aMethodObject selector: selector]
]

{ #category : #'frame access' }
CogVMSimulator >> iframeIsBlockActivation: theFP [
	self assert: (self isMachineCodeFrame: theFP) not.
	^super iframeIsBlockActivation: theFP
]

{ #category : #'frame access' }
CogVMSimulator >> iframeMethod: theFP [
	self assert: (self isMachineCodeFrame: theFP) not.
	^super iframeMethod: theFP
]

{ #category : #'frame access' }
CogVMSimulator >> iframeNumArgs: theFP [
	self assert: (self isMachineCodeFrame: theFP) not.
	^super iframeNumArgs: theFP
]

{ #category : #'frame access' }
CogVMSimulator >> iframeSavedIP: theFP [
	self assert: (self isMachineCodeFrame: theFP) not.
	^super iframeSavedIP: theFP
]

{ #category : #'image save/restore' }
CogVMSimulator >> imageName [
	^imageName
]

{ #category : #'spur bootstrap' }
CogVMSimulator >> imageName: aString [
	imageName := aString
]

{ #category : #'file primitives' }
CogVMSimulator >> imageNameGet: p Length: sz [
	1 to: sz  do:
		[:i |
		objectMemory
			byteAt:  p + i - 1
			put: (imageName at: i) asInteger]
]

{ #category : #'file primitives' }
CogVMSimulator >> imageNamePut: p Length: sz [
	| newName window |
	newName := ByteString new: sz.
	1 to: sz  do:
		[:i |
		newName
			at: i
			put: (Character value: (objectMemory byteAt: p + i - 1))].
	imageName := newName.
	(displayView notNil
	 and: [(window := displayView containingWindow) notNil]) ifTrue:
		[window setLabel: (window label
							copyReplaceFrom: (window label lastIndexOf: Character space) + 1
							to: window label size
							with: (self localNameFor: imageName))]
]

{ #category : #'file primitives' }
CogVMSimulator >> imageNameSize [
	^imageName size
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> inGUIThread [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #inGUIThread
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'rump c stack' }
CogVMSimulator >> inMemoryCFramePointerAddress [
	^self rumpCStackAddress - 16
]

{ #category : #initialization }
CogVMSimulator >> inMemoryCStackPointerAddress [
	^self rumpCStackAddress - 8
]

{ #category : #'rump c stack' }
CogVMSimulator >> inMemoryStackLimitAddress [
	^self rumpCStackAddress - 24
]

{ #category : #'rump c stack' }
CogVMSimulator >> inMemoryVMOwnerLockAddress [
	^self rumpCStackAddress - 48
]

{ #category : #'interpreter shell' }
CogVMSimulator >> incrementByteCount [
	(byteCount := byteCount + 1) = breakCount ifTrue:
		[self doOrDefer: [self changed: #byteCountText; changed: #composeAll].
		 self halt: 'breakCount reached'].
	byteCount \\ 1000 = 0 ifTrue:
		[self doOrDefer: [self changed: #byteCountText; changed: #composeAll].
		 self forceInterruptCheck]
]

{ #category : #'test support' }
CogVMSimulator >> initStackPagesForTests [
	numStackPages := 8.
	stackPages := self stackPagesClass new setInterpreter: self.
	objectMemory allocateMemoryOfSize: 1024 * 1024.
	cogCodeSize := 0.
	heapBase := self methodCacheSize
				+ self primTraceLogSize
				+ self rumpCStackSize
				+ self computeStackZoneSize.
	self initStackPages
]

{ #category : #initialization }
CogVMSimulator >> initialEnterSmalltalkExecutive [
	"Main entry-point into the interpreter at system start-up.
	 Override to choose between the threaded and non-threaded versions and if threaded
	 to ensure that the switch method overrides are up-to-date."
	self ensureMultiThreadingOverridesAreUpToDate.
	^self perform: #initialEnterSmalltalkExecutive
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #initialization }
CogVMSimulator >> initialize [
	"Initialize the CogVMSimulator when running the interpreter inside Smalltalk.  The
	 primary responsibility of this method is to allocate Smalltalk Arrays for variables
	 that will be declared as statically-allocated global arrays in the translated code."
	
	self basicInitialize.
	self initializePluginEntries.
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> initializeInterpreter: bytesToShift [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #initializeInterpreter:
		withArguments: {bytesToShift}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'plugin support' }
CogVMSimulator >> initializePluginEntries [
	mappedPluginEntries := OrderedCollection new.
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[primitiveAccessorDepthTable := Array new: primitiveTable size.
			 pluginList := {}.
			 self loadNewPlugin: '']
		ifFalse:
			[pluginList := {'' -> self }]
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> initializeProcessorForThreadIndex: threadIndex [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #initializeProcessorForThreadIndex:
		withArguments: {threadIndex}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #initialization }
CogVMSimulator >> initializeThreadSupport [
	"Do this post new if you want to simulate with thread support."
	cogThreadManager := CogThreadManager new setInterpreter: self cogit: cogit.
	cogit setThreadManager: cogThreadManager
]

{ #category : #'debugging traps' }
CogVMSimulator >> instVar: offset ofContext: aContext [

	"offset = InstructionPointerIndex ifTrue:
		[Transcript nextPutAll: '==================='; cr.
		  self printContext: 16r1715630.
		 self printCallStackOf: aContext currentFP: framePointer.
		 Transcript nextPutAll: '==================='; cr.
		 self halt]."

	| result |
	"self shortPrintFrameAndCallers: localFP.
	Transcript print: byteCount; tab; print: thisContext; cr.
	self print: offset; cr.
	self printContext: aContext.
	(self confirm: 'continue?') ifFalse: [self halt]."
	result := super instVar: offset ofContext: aContext.
	"(offset = InstructionPointerIndex
	and: [(self stringOf: (self penultimateLiteralOf: (self fetchPointer: MethodIndex ofObject: aContext))) = #indexOf:startingAt:ifAbsent:]) ifTrue:
		[transcript space; nextPutAll: '^pc '; nextPutAll: result hex.
		 (objectMemory isIntegerObject: result) ifTrue:
			[transcript space; print: (objectMemory integerValueOf: result)].
		 transcript tab.
		 self shortPrintContext: aContext]."
	"offset = StackPointerIndex ifTrue:
		[Transcript nextPutAll: '^stackp ', (self integerValueOf: result) printString; tab.
		 self shortPrintContext: aContext.
		 (#(24205456 24205732) includes: aContext) ifTrue:
		 	[(self checkIsStillMarriedContext: aContext currentFP: localFP)
				ifTrue: [self printFrame: (self frameOfMarriedContext: aContext) WithSP: (self frameOfMarriedContext: aContext) - 48]
				ifFalse: [self printContext: aContext]]]."
	^result
]

{ #category : #'frame access' }
CogVMSimulator >> instVar: index ofContext: aMarriedContext put: anOop [
	"self shortPrintFrameAndCallers: localFP.
	Transcript print: byteCount; tab; print: thisContext; cr.
	self print: index; cr.
	self printContext: aMarriedContext.
	self shortPrintOop: anOop.
	(self confirm: 'continue?') ifFalse: [self halt]."
	"(self stringOf: (self penultimateLiteralOf: (self fetchPointer: MethodIndex ofObject: aMarriedContext))) = #indexOf:startingAt:ifAbsent: ifTrue:
		[self halt]."
	^super instVar: index ofContext: aMarriedContext put: anOop
]

{ #category : #'interpreter shell' }
CogVMSimulator >> insufficientMemoryAvailableError [
	self error: 'Failed to allocate memory for the heap'
]

{ #category : #'interpreter shell' }
CogVMSimulator >> insufficientMemorySpecifiedError [
	self error: 'Insufficient memory for this image'
]

{ #category : #'debugging traps' }
CogVMSimulator >> internalCannotReturn: resultOop [
	self halt.
	^super internalCannotReturn: resultOop
]

{ #category : #testing }
CogVMSimulator >> internalFindNewMethodOrdinary [
"
	| cName |
	traceOn ifTrue:
		[cName := (self sizeBitsOf: class) = 16r20
			ifTrue: ['class ' , (self nameOfClass: (self fetchPointer: 6 ofObject: class))]
			ifFalse: [(self nameOfClass: class)].
		self cr; print: cName , '>>' , (self stringOf: messageSelector)].
"
	messageSelector = (objectMemory splObj: SelectorDoesNotUnderstand) ifTrue: [self halt].

	self logSend: messageSelector.
"
	(sendCount > 1000 and: [sendCount\\10 = 0]) ifTrue:
		[Transcript print: sendCount; space.
		self validate].
"
"
	(sendCount > 100150) ifTrue:
		[self qvalidate.
		messageQueue == nil ifTrue: [messageQueue := OrderedCollection new].
		messageQueue addLast: (self stringOf: messageSelector)].
"
	^super internalFindNewMethodOrdinary
]

{ #category : #'debugging traps' }
CogVMSimulator >> internalMustBeBoolean [
	self halt.
	^super internalMustBeBoolean
]

{ #category : #'interpreter shell' }
CogVMSimulator >> interpret [
	"This is the main interpreter loop. It normally loops forever, fetching and executing bytecodes.
	 When running in the context of a web browser plugin VM, however, it must return control to the
	 web browser periodically. This should done only when the state of the currently running Squeak
	 thread is safely stored in the object heap. Since this is the case at the moment that a check for
	 interrupts is performed, that is when we return to the browser if it is time to do so.  Interrupt
	 checks happen quite frequently.

	Override for simulation to insert bytecode breakpoint support."

	<inline: false>
	"If stacklimit is zero then the stack pages have not been initialized."
	stackLimit = 0 ifTrue:
		[^self initStackPagesAndInterpret].
	"record entry time when running as a browser plug-in"
	self browserPluginInitialiseIfNeeded.
	self internalizeIPandSP.
	self initExtensions.
	self fetchNextBytecode.
	[true] whileTrue:
		[self assertValidExecutionPointers.
		 atEachStepBlock value. "N.B. may be nil"
		 self dispatchOn: currentBytecode in: BytecodeTable.
		 self incrementByteCount].
	localIP := localIP - 1.  "undo the pre-increment of IP before returning"
	self externalizeIPandSP.
	^nil

]

{ #category : #'stack pages' }
CogVMSimulator >> interpreterAllocationReserveBytes [

	^ bootstrapping
		ifTrue: [ 0 ]
		ifFalse: [ super interpreterAllocationReserveBytes ]
]

{ #category : #'interpreter shell' }
CogVMSimulator >> invalidCompactClassError: name [
	self error: 'Class ', name, ' does not have the required compact class index'
]

{ #category : #'I/O primitives' }
CogVMSimulator >> ioBeDisplay: bitsOrHandleCArray width: width height: height depth: depth [
	"The real platform may want to note the location of the display and respond to the fact of
	 its installation.  Here merely create a scratch form the same size as Smalltalk displayObj"
	super ioBeDisplay: bitsOrHandleCArray asInteger width: width height: height depth: depth.
	displayForm := Form extent: width @ height depth: depth.
	displayView ifNotNil: [displayView image: displayForm]
]

{ #category : #security }
CogVMSimulator >> ioCanRenameImage [
	^true
]

{ #category : #security }
CogVMSimulator >> ioCanWriteImage [
	^true
]

{ #category : #'primitive support' }
CogVMSimulator >> ioExit [
	self threadManager ifNotNil:
		[:threadManager|
		threadManager guiProcess ~= Processor activeProcess ifTrue:
			[threadManager guiProcess
				signalException:
					(Notification new tag: #evaluateQuit; yourself).
			Processor terminateActive]].
	quitBlock value  "Cause return from #test"
]

{ #category : #'primitive support' }
CogVMSimulator >> ioExitWithErrorCode: ec [
	self ioExit
]

{ #category : #'process primitive support' }
CogVMSimulator >> ioGetMaxExtSemTableSize [
	^extSemTabSize
]

{ #category : #'I/O primitives' }
CogVMSimulator >> ioGetNextEvent: evtBuf [
	| evt |
	"SimulatorMorphicModel browse"
	eventQueue ifNil:
		[^self primitiveFail].
	eventQueue isEmpty ifFalse:
		[evt :=  eventQueue next.
		 1 to: evt size do:
			[:i| (evt at: i) ifNotNil: [:val| evtBuf at: (i - 1) put: val]]]
]

{ #category : #'I/O primitives' }
CogVMSimulator >> ioHasDisplayDepth: depth [
	^Display supportsDisplayDepth: depth
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> ioHeartbeatMilliseconds [
	^1
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> ioHighResClock [
	^self ioUTCMicroseconds
]

{ #category : #initialization }
CogVMSimulator >> ioInitHeartbeat [
	"No-op in the simulator.  We cause a poll every 1000 bytecodes instead."
]

{ #category : #'plugin support' }
CogVMSimulator >> ioLoadFunction: functionString From: pluginString [
	"Load and return the requested function from a module"
	| firstTime plugin fnSymbol |
	firstTime := false.
	fnSymbol := functionString asSymbol.
	transcript
		cr;
		show: '(', byteCount printString, ') Looking for ', functionString, ' in ',
				(pluginString isEmpty ifTrue: ['vm'] ifFalse: [pluginString]).
	(breakSelector notNil
	 and: [(pluginString size = breakSelector size
			and: [(self strncmp: pluginString _: breakSelector _: pluginString size) = 0])
		or: [functionString size = breakSelector size
			and: [(self strncmp: functionString _: breakSelector _: functionString size) = 0]]]) ifTrue:
		[self halt: pluginString, '>>', functionString].
	plugin := pluginList 
				detect: [:any| any key = pluginString asString]
				ifNone:
					[firstTime := true.
					 self loadNewPlugin: pluginString].
	plugin ifNil:
		[firstTime ifTrue: [transcript cr; show: '... FAILED; no plugin found'].
		 ^0].
	plugin := plugin value.
	mappedPluginEntries withIndexDo:
		[:pluginAndName :index|
		((pluginAndName at: 1) == plugin 
		and:[(pluginAndName at: 2) == fnSymbol]) ifTrue:
			[^index]].
	(plugin respondsTo: fnSymbol) ifFalse:
		[firstTime ifTrue: [transcript cr; show: '... FAILED; primitive not in plugin'].
		 ^0].
	mappedPluginEntries addLast: { plugin. fnSymbol. [plugin perform: fnSymbol. self]}.
	transcript show: ' ... okay'.
	^mappedPluginEntries size
]

{ #category : #'plugin support' }
CogVMSimulator >> ioLoadFunction: functionString From: pluginString AccessorDepthInto: accessorDepthPtr [
	"Load and return the requested function from a module.
	 Assign the accessor depth through accessorDepthPtr.
	 N.B. The actual code lives in platforms/Cross/vm/sqNamedPrims.h"
	| firstTime plugin fnSymbol |
	firstTime := false.
	fnSymbol := functionString asSymbol.
	transcript
		cr;
		show: '(', byteCount printString, ') Looking for ', functionString, ' in ',
				(pluginString isEmpty ifTrue: ['vm'] ifFalse: [pluginString]).
	(breakSelector notNil
	 and: [(pluginString size = breakSelector size
			and: [(self strncmp: pluginString _: breakSelector _: pluginString size) = 0])
		or: [functionString size = breakSelector size
			and: [(self strncmp: functionString _: breakSelector _: functionString size) = 0]]]) ifTrue:
		[self halt: pluginString, '>>', functionString].
	plugin := pluginList 
				detect: [:any| any key = pluginString asString]
				ifNone:
					[firstTime := true.
					 self loadNewPlugin: pluginString].
	plugin ifNil:
		[firstTime ifTrue: [transcript cr; show: '... FAILED; primitive not in plugin'].
		 ^0].
	plugin := plugin value.
	mappedPluginEntries withIndexDo:
		[:pluginAndName :index|
		 ((pluginAndName at: 1) == plugin 
		  and:[(pluginAndName at: 2) == fnSymbol]) ifTrue:
			[firstTime ifTrue: [transcript show: ' ... okay'].
			 accessorDepthPtr at: 0 put: (pluginAndName at: 4).
			 ^index]].
	firstTime ifTrue: [transcript cr; show: '... FAILED; primitive not in plugin'].
	^0
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> ioMSecs [
	"Return the value of the millisecond clock."
	"NOT.  Actually, we want something a lot slower and, for exact debugging,
	something more repeatable than real time.  I have an idea: use the byteCount... (di 7/1/2004 13:55)"

	^self microsecondsToMilliseconds: self ioUTCMicroseconds
	
"At 20k bytecodes per second, this gives us about 200 ticks per second, or about 1/5 of what you'd expect for the real time clock.  This should still service events at one or two per second"
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> ioMicroMSecs [
	"Answer the value of the high-resolution millisecond clock."

	^ Time millisecondClockValue

]

{ #category : #'I/O primitives' }
CogVMSimulator >> ioMousePoint [
	| relPt |
	^displayForm
		ifNil: [99 << 16 + 66]
		ifNotNil: [relPt := Sensor cursorPoint - self displayLocation.
				relPt x << 16 + relPt y]
]

{ #category : #'I/O primitives' }
CogVMSimulator >> ioProcessEvents [
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> ioRelinquishProcessorForMicroseconds: microseconds [
	"In the simulator give an indication that we're idling and check for input.
	 If called from machine code then increment the byte count since the clock
	 is derived from it and the clock will not advance otherwise.
	 If we're simulating threading we're in difficulties.  We need a UI process
	 (to run activities such as fill-in-the-blanks) but we also need an independent
	 thread of control to run this VM thread.  So we need to fork a new UI process."
	Display reverse: ((displayView
						ifNil: [0@0]
						ifNotNil: [displayView bounds origin]) extent: 16@16).
	Sensor peekEvent ifNotNil:
		[self forceInterruptCheck].
	Processor activeProcess == UIManager default uiProcess ifTrue:
		[World doOneCycle].
	microseconds >= 1000
		ifTrue: [self isThreadedVM ifTrue:
					[self forceInterruptCheckFromHeartbeat].
				(Delay forMilliseconds: microseconds + 999 // 1000) wait]
		ifFalse: [Processor yield].
	byteCount := byteCount + (microseconds * ByteCountsPerMicrosecond) - 1.
	self incrementByteCount
]

{ #category : #'I/O primitives' }
CogVMSimulator >> ioScreenDepth [
	^DisplayScreen actualScreenDepth.
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> ioScreenScaleFactor [
	^ 1.0
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> ioScreenSize [
	"Answer the screen extent packed into 32 bits.  In the simulator,
	 displayForm gets initialized with a fake form; don't be deceived."
	| extent |
	extent := (displayForm notNil and: [displayForm ~~ fakeForm])
				ifTrue: [displayForm extent]
				ifFalse: [self desiredDisplayExtent].
	^extent x << 16 + extent y
]

{ #category : #'I/O primitives' }
CogVMSimulator >> ioSetInputSemaphore: index [

	self primitiveFail
]

{ #category : #'process primitive support' }
CogVMSimulator >> ioSetMaxExtSemTableSize: anInteger [
	"Inform the VM of the maximum size the image will grow the exernal semaphore table (specialObjectsArray at: 39) to.
	 This allows the VM to allocate storage such that external semaphores can be signalled without locking."
	extSemTabSize := anInteger
]

{ #category : #'I/O primitives' }
CogVMSimulator >> ioShow: destBits D: w i: h s: d p: left l: right a: top y: bottom [
	"This is the simulator's implementation of ioShowDisplay."
	| raster pixPerWord simDisp realDisp rect |
	displayForm ifNil: [^self].
	displayBits = 0 ifTrue: [^self].
	pixPerWord := 32 // d.
	raster := displayForm width + (pixPerWord - 1) // pixPerWord.
	simDisp := Form new hackBits: objectMemory memory.
	displayForm unhibernate.
	realDisp := Form new hackBits: displayForm bits.
	realDisp
		copy: (0 @ (top * raster) extent: 4 @ (bottom - top * raster))
		from: 0 @ (destBits // 4 + (top * raster))
		in: simDisp
		rule: Form over.
	displayView ifNotNil: [^displayView changed].
	
	"If running without a view, just blat the bits onto the screen..."
	rect := 0 @ top corner: displayForm width @ bottom.
	Display
		copy: (rect translateBy: self displayLocation)
		from: rect topLeft
		in: displayForm
		rule: Form over
]

{ #category : #'process primitive support' }
CogVMSimulator >> ioSynchronousCheckForEvents [
	"Hook allowing the platform to do anything it needs to do synchronously."
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> ioUTCMicroseconds [
	"Return the value of the microsecond clock."
	"NOT.  Actually, we want something a lot slower and, for exact debugging,
	 something more repeatable than real time.  Dan had an idea: use the byteCount...
	 We increment byteCount in stackLimitFromMachineCode and a real machine
	 can easily run e.g. nfib at 6e7 / second, which this would be 1 usec ~= 60 byteCounts.
	 Use 10 byteCounts per usec by default; see CogVMSimulator class>>initializeWithOptions:objectMemoryClass:"

	^byteCount // ByteCountsPerMicrosecond + startMicroseconds
	
	"Dan:
	 At 20k bytecodes per second, this gives us about 200 ticks per second, or about 1/5
	 of what you'd expect for the real time clock.  This should still service events at one or
	 two per second"
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> ioUTCStartMicroseconds [
	"Answer the value of the microsecond clock at startup."

	^startMicroseconds ifNil:
		[self class initializationOptions
			at: #startMicroseconds
			ifAbsent: [[Time utcMicrosecondClock] on: Error do: [Time totalSeconds * 1000000]]]
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> isAffinedProcess: aProcess [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #isAffinedProcess:
		withArguments: {aProcess}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> isAffinedThreadId: threadId [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #isAffinedThreadId:
		withArguments: {threadId}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> isBoundProcess: aProcess [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #isBoundProcess:
		withArguments: {aProcess}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> isBoundThreadId: threadId [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #isBoundThreadId:
		withArguments: {threadId}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'rump c stack' }
CogVMSimulator >> isOnRumpCStack: address [
	^address between: heapBase - self rumpCStackSize and: heapBase - objectMemory wordSize
]

{ #category : #'primitive support' }
CogVMSimulator >> isPrimitiveFunctionPointerAnIndex [
	"We save slots in the method cache by using the primitiveFunctionPointer
	 to hold either a function pointer or the index of a quick primitive. Since
	 quick primitive indices are small they can't be confused with function
	 addresses.  But since we use 1001 and up for external primitives that
	 would be functions in the C VM but are indices under simulation we treat
	 values above 1000 as if they were pointers (actually indices into the
	 externalPrimitiveTable)"

	^primitiveFunctionPointer isInteger
	  and: [primitiveFunctionPointer >= 0
	  and: [primitiveFunctionPointer <= MaxQuickPrimitiveIndex]]
]

{ #category : #testing }
CogVMSimulator >> isThreadedVM [
	^self threadManager notNil
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> isUnboundThreadId: threadId [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #isUnboundThreadId:
		withArguments: {threadId}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'frame access' }
CogVMSimulator >> isWidowedContext: aOnceMarriedContext [
	"See if the argument is connected with a live frame or not.
	 If it is not, turn it into a bereaved single context."
	(stackPages isFree: stackPage) ifFalse: "in baseReturn the active page has been freed."
		[((stackPages somePageHasHeadFrameFP: framePointer)
		  or: [(stackPages somePageHasHeadFrameFP: localFP)
		  or: [stackPages allPagesFree]]) ifFalse:
			[(thisContext sender sender method = (CoInterpreter >> #baseFrameReturn)
			  or: [thisContext sender sender method = (CoInterpreter >> #ceBaseFrameReturn:)]) ifFalse:
				[self halt: 'currentFP may not be written back to stack page']]].
	^super isWidowedContext: aOnceMarriedContext
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> loadInitialContext [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #loadInitialContext
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'plugin support' }
CogVMSimulator >> loadNewPlugin: pluginString [
	(breakSelector notNil
	 and: [(self strncmp: pluginString _: breakSelector _: pluginString size) = 0]) ifTrue:
		[self halt: pluginString].
	^(self tryLoadNewPlugin: pluginString pluginEntries: mappedPluginEntries) ifNotNil:
		[:entry|
		 pluginList := pluginList copyWith: entry.
		 entry]
]

{ #category : #accessing }
CogVMSimulator >> localIP [
	^localIP
]

{ #category : #testing }
CogVMSimulator >> logOfBytesVerify: nBytes fromFileNamed: fileName fromStart: loggingStart [
	"Verify a questionable interpreter against a successful run"
	"self logOfBytesVerify: 10000 fromFileNamed: 'clone32Bytecodes.log' "
	
	| logFile rightWord prevCtxt |
	logFile := (FileStream readOnlyFileNamed: fileName) binary.
	transcript clear.
	byteCount := 0.
	quitBlock := [^self close].
	self initStackPages.
	self loadInitialContext.
	self internalizeIPandSP.
	self fetchNextBytecode.
	prevCtxt := 0.  prevCtxt := prevCtxt.
	[byteCount < nBytes] whileTrue:
		[
"
byteCount > 14560 ifTrue:
[self externalizeIPandSP.
prevCtxt = activeContext ifFalse:
 [prevCtxt := activeContext.
 transcript cr; nextPutAll: (self printTop: 2); endEntry].
transcript cr; print: byteCount; nextPutAll: ': ' , (activeContext hex); space;
 print: (instructionPointer - method - (BaseHeaderSize - 2));
 nextPutAll: ': <' , (self byteAt: localIP) hex , '>'; space;
 nextPutAll: (self symbolic: currentBytecode at: localIP inMethod: method); space;
 print: (self stackPointerIndex - TempFrameStart + 1); endEntry.
byteCount = 14590 ifTrue: [self halt]].
"
		loggingStart >= byteCount ifTrue:
			[rightWord := logFile nextWord.
			 currentBytecode = rightWord ifFalse:
				[self halt: 'halt at ', byteCount printString]].
		self dispatchOn: currentBytecode in: BytecodeTable.
		self incrementByteCount].
	self externalizeIPandSP.
	logFile close.
	self inform: nBytes printString , ' bytecodes verfied.'
]

{ #category : #testing }
CogVMSimulator >> logOfBytesWrite: nBytes toFileNamed: fileName fromStart: loggingStart [
	"Write a log file for testing a flaky interpreter on the same image"
	"self logOfBytesWrite: 10000 toFileNamed: 'clone32Bytecodes.log' "
	
	| logFile |
	logFile := (FileStream newFileNamed: fileName) binary.
	transcript clear.
	byteCount := 0.
	quitBlock := [^self close].
	self initStackPages.
	self loadInitialContext.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[byteCount < nBytes] whileTrue:
		[byteCount >= loggingStart ifTrue:
			[logFile nextWordPut: currentBytecode].
		self dispatchOn: currentBytecode in: BytecodeTable.
		self incrementByteCount].
	self externalizeIPandSP.
	logFile close
]

{ #category : #testing }
CogVMSimulator >> logOfSendsVerify: nSends fromFileNamed: fileName fromStart: loggingStart [
	"Write a log file for testing a flaky interpreter on the same image"
	"self logOfSendsWrite: 10000 toFileNamed: 'clone32Messages.log' "
	
	| logFile priorFrame rightSelector prevCtxt |
	logFile := FileStream readOnlyFileNamed: fileName.
	transcript clear.
	byteCount := 0.
	sendCount := 0.
	priorFrame := localFP.
	quitBlock := [^self close].
	self initStackPages.
	self loadInitialContext.
	self internalizeIPandSP.
	self fetchNextBytecode.
	prevCtxt := 0.  prevCtxt := prevCtxt.
	[sendCount < nSends] whileTrue:
		[
"
byteCount>500 ifTrue:
[byteCount>550 ifTrue: [self halt].
self externalizeIPandSP.
prevCtxt = localFP ifFalse:
 [prevCtxt := localFP.
 transcript cr; nextPutAll: (self printTop: 2); endEntry].
transcript cr; print: byteCount; nextPutAll: ': ' , (localFP hex); space;
 print: (instructionPointer - method - (BaseHeaderSize - 2));
 nextPutAll: ': <' , (self byteAt: localIP) hex , '>'; space;
 nextPutAll: (self symbolic: currentBytecode at: localIP inMethod: method); space;
 print: (self stackPointerIndex - TempFrameStart + 1); endEntry.
].
"
		self dispatchOn: currentBytecode in: BytecodeTable.
		localFP = priorFrame ifFalse:
			[sendCount := sendCount + 1.
			 loggingStart >= sendCount ifTrue:
				[rightSelector := logFile nextLine.
				 (self stringOf: messageSelector) = rightSelector ifFalse:
					[self halt: 'halt at ', sendCount printString]].
			priorFrame := localFP].
		self incrementByteCount].
	self externalizeIPandSP.
	logFile close.
	self inform: nSends printString , ' sends verfied.'
]

{ #category : #testing }
CogVMSimulator >> logOfSendsWrite: nSends toFileNamed: fileName fromStart: loggingStart [
	"Write a log file for testing a flaky interpreter on the same image"
	"self logOfSendsWrite: 10000 toFileNamed: 'clone32Messages.log' fromStart: 2500"
	
	| logFile priorFrame |
	logFile := FileStream newFileNamed: fileName.
	transcript clear.
	byteCount := 0.
	sendCount := 0.
	priorFrame := localFP.
	quitBlock := [^self close].
	self initStackPages.
	self loadInitialContext.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[sendCount < nSends] whileTrue:
		[self dispatchOn: currentBytecode in: BytecodeTable.
		localFP == priorFrame ifFalse:
			[sendCount >= loggingStart ifTrue:
				[sendCount := sendCount + 1.
				 logFile nextPutAll: (self stringOf: messageSelector); cr].
			priorFrame := localFP].
		self incrementByteCount].
	self externalizeIPandSP.
	logFile close
]

{ #category : #'debugging traps' }
CogVMSimulator >> logSend: oop [
	sendCount := sendCount + 1.
	(printSends or: [printBytecodeAtEachStep]) ifTrue:
		[transcript print: byteCount; nextPut: $/; print: sendCount; space.
		 self printStringOf: oop.
		 transcript cr; flush]
]

{ #category : #'memory access' }
CogVMSimulator >> long32At: byteAddress [
	"Return the 32-bit word at byteAddress which must be 0 mod 4."
	^objectMemory long32At: byteAddress
]

{ #category : #'memory access' }
CogVMSimulator >> longAt: byteAddress [
	^objectMemory longAt: byteAddress
]

{ #category : #'memory access' }
CogVMSimulator >> longAt: byteAddress put: a32BitValue [
	^objectMemory longAt: byteAddress put: a32BitValue
]

{ #category : #'message sending' }
CogVMSimulator >> lookupMethodInClass: class [
	lookupCount := lookupCount + 1.
	^super lookupMethodInClass: class
]

{ #category : #'callback support' }
CogVMSimulator >> lookupOrdinaryNoMNUEtcInClass: class [
	lookupCount := lookupCount + 1.
	^super lookupOrdinaryNoMNUEtcInClass: class
]

{ #category : #'frame access' }
CogVMSimulator >> makeBaseFrameFor: aContext [ "<Integer>"
	"aContext =  26431360 ifTrue: [self halt]."
	"(objectMemory fetchPointer: MethodIndex ofObject: aContext) = 16rD4C178 ifTrue:
		[self halt]."
	^super makeBaseFrameFor: aContext
]

{ #category : #'cog jit support' }
CogVMSimulator >> mapFunctionToAddress: aSymbolOrIndexOrBlock [
	"Hackery to deal with the plugin primitive simulation hoops.
	 aSymbolOrIndex is either a Symbol (#primitiveExternalCall) or an
	 index above 1001 (an index + 1000 into the externalPrimitiveTable)."
	| sobui symbolOrBlock |

	aSymbolOrIndexOrBlock = 0 ifTrue: [^0].
	self assert: (aSymbolOrIndexOrBlock isSymbol
				or: [aSymbolOrIndexOrBlock isBlock
				or: [aSymbolOrIndexOrBlock isInteger
					and: [aSymbolOrIndexOrBlock between: 1001 and: 2000]]]).
	symbolOrBlock := aSymbolOrIndexOrBlock isInteger
						ifTrue: [(self pluginEntryFor: aSymbolOrIndexOrBlock) at: 3]
						ifFalse: [aSymbolOrIndexOrBlock].
	uniqueIndices ifNil:
		[uniqueIndices := Dictionary new.
		 uniqueIndex := 65535].
	sobui := uniqueIndices at: symbolOrBlock ifAbsentPut: [uniqueIndex := uniqueIndex + 1].
	^cogit
		mapPrimitive: symbolOrBlock
		withIndexToUniqueAddress: sobui
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> mapInterpreterOops [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #mapInterpreterOops
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'plugin support' }
CogVMSimulator >> mappedPluginEntries [
	^mappedPluginEntries
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> markAndTraceInterpreterOops: fullGCFlag [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #markAndTraceInterpreterOops:
		withArguments: {fullGCFlag}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'debug support' }
CogVMSimulator >> maybeCheckStackDepth: delta sp: sp pc: mcpc [
	| asp bcpc startbcpc cogHomeMethod cogBlockMethod csp debugStackPointers |
	debugStackDepthDictionary ifNil: [^self].
	(self isMachineCodeFrame: framePointer) ifFalse: [^self].
	cogBlockMethod := self mframeCogMethod: framePointer.
	cogHomeMethod := self asCogHomeMethod: cogBlockMethod.
	debugStackPointers := debugStackDepthDictionary
								at: cogHomeMethod methodObject
								ifAbsentPut: [self debugStackPointersFor: cogHomeMethod methodObject].
	startbcpc := cogHomeMethod = cogBlockMethod
					ifTrue: [self startPCOfMethod: cogHomeMethod methodObject]
					ifFalse: [self startPCOfClosure: (self pushedReceiverOrClosureOfFrame: framePointer)].
	bcpc := cogit bytecodePCFor: mcpc startBcpc: startbcpc in: cogBlockMethod.
	self assert: bcpc ~= 0.
	((cogBlockMethod ~= cogHomeMethod or: [cogBlockMethod cmIsFullBlock])
	 and: [cogit isNonLocalReturnPC: mcpc]) ifTrue:
		[| lastbcpc |
		 "Method returns within a block (within an unwind-protect) must check the stack depth at the
		  return, not the bytecode following, but the pc mapping maps to the bytecode following the
		  return. lastBytecodePCForBlockAt:in: catches method returns at the end of a block, modifying
		  the bcpc to that of the return.  isNonLocalReturnPC: catches method returns not at the end.
		  Assumes method return bytecodes are 1 bytecode long;a  dodgy assumption, but good enough."
		 lastbcpc := cogBlockMethod cmIsFullBlock
						ifTrue: [cogit endPCOf: cogHomeMethod methodObject]
						ifFalse: [cogit lastBytecodePCForBlockAt: startbcpc in: cogHomeMethod methodObject].
		 bcpc > lastbcpc ifTrue: [bcpc := lastbcpc]].
	asp := self stackPointerIndexForFrame: framePointer WithSP: sp + objectMemory wordSize.
	csp := debugStackPointers at: bcpc ifAbsent: [-1].
	"Compensate for some edge cases"
	asp - delta = csp ifTrue:
		["Compensate for the implicit context receiver push in a trap bytecode with the absence of a contnuation.
		  Assumes trap bytecodes are 1 byte bytecodes."
		 (SistaVM
		  and: [cogit isTrapAt: mcpc]) ifTrue:
			[csp := csp + 1] ].
	self assert: asp - delta + 1 = csp
]

{ #category : #'primitive support' }
CogVMSimulator >> maybeMapPrimitiveFunctionPointerBackToSomethingEvaluable [
	"In the real VM primitiveFunctionPointer is either an index (for quick primitives)
	 or a proper function pointer to a primitive.  In the simulator it may be a small
	 index (corresponding to a quick primitive index), a symbol (corresponding to
	 a function pointer) or an index into the externalPrimitiveTable, or an invalid
	 address that references an evaluable in the simulatedTrampolines dictionary
	 of the Cogit.  The simulator expects dispatchFunctionPointer to be called with
	 primitiveFunctionPointer being a symbol only for internal primitives.  External
	 primitives must have their funciton pointer mapped back to an index.  This
	 method does the mapping back from fake addresses."
	<doNotGenerate>
	(primitiveFunctionPointer isInteger
	 and: [self isExternalPrimitiveCall: newMethod]) ifTrue: "External prims must be evaluated by the right plugin..."
		[(cogit simulatedTrampolines at: primitiveFunctionPointer ifAbsent: nil) ifNotNil:
			[:evaluable| | pfp index externalIndex |
						"primitiveFunctionPointer := pfp"
						"(1 to: self mappedPluginEntries size) select: [:index| (self mappedPluginEntries at: index) third == evaluable]"
			 pfp := primitiveFunctionPointer.
			 index := self mappedPluginEntries findFirst: [:entry| entry third == evaluable].
			 self assert: index ~= 0.
			 externalIndex := 1000 + (externalPrimitiveTable object
										indexOf: index
										ifAbsent: [self error: 'entry not found']).
			 self assert: ((self pluginEntryFor: externalIndex) notNil
						   and: [(self pluginEntryFor: externalIndex) third == evaluable]).
			 primitiveFunctionPointer := externalIndex.
			 ^self]].
	
	(primitiveFunctionPointer isInteger and: [ 
		cogit simulatedTrampolines includesKey: primitiveFunctionPointer ])
		ifTrue: [ primitiveFunctionPointer := (cogit simulatedTrampolines at: primitiveFunctionPointer) selector  ].
	
	^super maybeMapPrimitiveFunctionPointerBackToSomethingEvaluable
]

{ #category : #'cog jit support' }
CogVMSimulator >> mcprimFunctionForPrimitiveIndex: primIndex [
	^self mapFunctionToAddress: (super mcprimFunctionForPrimitiveIndex: primIndex)
]

{ #category : #accessing }
CogVMSimulator >> memory [
	^objectMemory memory
]

{ #category : #'spur bootstrap' }
CogVMSimulator >> methodCache [
	^methodCache
]

{ #category : #'simulation only' }
CogVMSimulator >> methodCacheSize [
	^MethodCacheSize * objectMemory wordSize
]

{ #category : #'simulation only' }
CogVMSimulator >> methodForContext: aContextOop [
	self assert: (objectMemory isContext: aContextOop).
	^objectMemory fetchPointer: MethodIndex ofObject: aContextOop
]

{ #category : #'simulation only' }
CogVMSimulator >> minBackwardJumpCountForCompile [
	<doNotGenerate>
	^minBackwardJumpCountForCompile
]

{ #category : #'simulation only' }
CogVMSimulator >> minBackwardJumpCountForCompile: n [
	<doNotGenerate>
	minBackwardJumpCountForCompile := n
]

{ #category : #initialization }
CogVMSimulator >> moveMethodCacheToMemoryAt: address [
	| oldMethodCache |
	oldMethodCache := methodCache.
	"In the VM the methodCache is written as a normal array with 1-relative addressing.
	 In C this works by allocating an extra element in the methodCache array (see
	 class-side declareCVarsIn:).  In simulation simply position the start of the methodCache
	 one word lower, achieving the same effect.  -1 because CArrayAccessor is 0-relative
	 and adds 1 on accesses itself."
	methodCache := CMethodCacheAccessor new
						objectMemory: objectMemory
						at: address
						array: oldMethodCache
						functionPointerIndex: MethodCachePrimFunction
						entrySize: MethodCacheEntrySize.
	self assert: address - objectMemory wordSize = self methodCacheAddress.
	1 to: MethodCacheSize do:
		[:i|
		self assert: (methodCache at: i) = 0].
	methodCache at: 1 put: 16rC4EC4.
	self assert: (objectMemory longAt: address) = 16rC4EC4.
	1 to: MethodCacheSize do:
		[:i|
		methodCache at: i put: (oldMethodCache at: i)]
]

{ #category : #initialization }
CogVMSimulator >> movePrimTraceLogToMemoryAt: address [
	| oldTraceLog |
	oldTraceLog := primTraceLog.
	primTraceLog := CArrayOfLongsAccessor new
						objectMemory: objectMemory at: address.
	self assert: address = self primTraceLogAddress.
	0 to: PrimTraceLogSize - 1 do:
		[:i|
		self assert: (primTraceLog at: i) = 0].
	primTraceLog at: 0 put: 16rC4EC4.
	self assert: (objectMemory longAt: address) = 16rC4EC4.
	0 to: PrimTraceLogSize - 1 do:
		[:i|
		primTraceLog at: i put: (oldTraceLog at: i)]
]

{ #category : #'debug support' }
CogVMSimulator >> nameOfClass: classOop [
	| numSlots maybeThisClassOop maybeNameOop name |
	classNameIndex ifNil: [^'??nil cnidx??'].
	numSlots := objectMemory numSlotsOf: classOop.
	numSlots = metaclassNumSlots ifTrue:
		[maybeThisClassOop := objectMemory fetchPointer: thisClassIndex ofObject: classOop.
		(self addressCouldBeClassObj: maybeThisClassOop) ifTrue:
			[name := self nameOfClass: maybeThisClassOop.
			 (name beginsWith: 'bad ') ifFalse:
				[^name, ' class']].
		 ^'bad class'].
	(numSlots > classNameIndex
	 and: [maybeNameOop := objectMemory fetchPointer: classNameIndex ofObject: classOop.
		objectMemory isBytes: maybeNameOop]) ifFalse:
		[^'bad class'].
	^self stringOf: maybeNameOop
]

{ #category : #initialization }
CogVMSimulator >> nextShortFrom: aStream [
	"Read a 16-bit quantity from the given (binary) stream."
	^self subclassResponsibility
]

{ #category : #'test support' }
CogVMSimulator >> numStackPages [
	^numStackPages
]

{ #category : #UI }
CogVMSimulator >> openAsMorph [
	"Open a morphic view on this simulation."
	| localImageName borderWidth window |
	localImageName := imageName
							ifNotNil: [self localNameFor: imageName]
							ifNil: [' synthetic image'].
	window := (SystemWindow labelled: 'Simulation of ', localImageName) model: self.
	window paneColor: self windowColorToUse.

	window addMorph: (displayView := SimulatorImageMorph new image: displayForm)
			frame: (0@0 corner: 1@0.8).
	displayView activeHand addEventListener: self.
	eventTransformer := SimulatorEventTransformer new.

	transcript := TranscriptStream on: (String new: 10000).
	window addMorph: (PluggableTextMorph
							on: transcript text: nil accept: nil
							readSelection: nil menu: #codePaneMenu:shifted:)
			frame: (0@0.8 corner: 0.7@1).
	window addMorph: (PluggableTextMorph on: self
						text: #byteCountText accept: nil
						readSelection: nil menu: #utilitiesMenu:) hideScrollBarsIndefinitely
			frame: (0.7@0.8 corner: 1@1).

	borderWidth := [SystemWindow borderWidth] "Squeak 4.1"
						on: MessageNotUnderstood
						do: [:ex| 0]. "3.8"
	borderWidth := borderWidth + window borderWidth.
	window openInWorldExtent: (self desiredDisplayExtent
								+ (2 * borderWidth @ borderWidth)
								+ (0@window labelHeight)
								* (1@(1/0.8))) rounded.
	^window
]

{ #category : #UI }
CogVMSimulator >> openAsMorphNoTranscript [
	"Open a morphic view on this simulation."
	| localImageName borderWidth window |
	localImageName := imageName
							ifNotNil: [self localNameFor: imageName]
							ifNil: [' synthetic image'].
	window := (SystemWindow labelled: 'Simulation of ', localImageName) model: self.
	window paneColor: self windowColorToUse.

	window addMorph: (displayView := SimulatorImageMorph new image: displayForm)
			frame: (0@0 corner: 1@0.95).
	displayView activeHand addEventListener: self.
	eventTransformer := SimulatorEventTransformer new.

	window addMorph: (PluggableTextMorph on: self
						text: #byteCountText accept: nil
						readSelection: nil menu: #utilitiesMenu:) hideScrollBarsIndefinitely
		frame: (0@0.95 corner: 1@1).

	borderWidth := [SystemWindow borderWidth] "Squeak 4.1"
						on: MessageNotUnderstood
						do: [:ex| 0]. "3.8"
	borderWidth := borderWidth + window borderWidth.
	window openInWorldExtent: (self desiredDisplayExtent
								+ (2 * borderWidth@borderWidth)
								+ (0@window labelHeight)
								* (1@(1/0.95))) rounded
]

{ #category : #initialization }
CogVMSimulator >> openOn: fileName extraMemory: extraBytes [
	"CogVMSimulator new openOn: 'clone.im' extraMemory: 100000"

	| f version headerSize dataSize count oldBaseAddr bytesToShift swapBytes
	  headerFlags firstSegSize heapSize
	  hdrNumStackPages hdrEdenBytes hdrMaxExtSemTabSize
	  hdrCogCodeSize stackZoneSize methodCacheSize primTraceLogSize allocationReserve vmRequiredMemorySize |
	"open image file and read the header"

	(f := self openImageFileNamed: fileName) ifNil: [^self].

	"Set the image name and the first argument; there are
	 no arguments during simulation unless set explicitly."
	systemAttributes at: 1 put: fileName; at: 2 put: nil.

	["begin ensure block..."
	imageName := f fullName.
	f binary.

	version := self getWord32FromFile: f swap: false.  "current version: 16r1968 (=6504) vive la revolucion!"
	(self readableFormat: version)
		ifTrue: [swapBytes := false]
		ifFalse: [(version := version byteSwap32) = self imageFormatVersion
					ifTrue: [swapBytes := true]
					ifFalse: [self error: 'incomaptible image format']].
	headerSize := self getWord32FromFile: f swap: swapBytes.
	dataSize := self getLongFromFile: f swap: swapBytes.  "length of heap in file"
	oldBaseAddr := self getLongFromFile: f swap: swapBytes.  "object memory base address of image"
	objectMemory specialObjectsOop: (self getLongFromFile: f swap: swapBytes).
	objectMemory lastHash: (self getLongFromFile: f swap: swapBytes).  "Should be loaded from, and saved to the image header"

	savedWindowSize	:= self getLongFromFile: f swap: swapBytes.
	headerFlags		:= self getLongFromFile: f swap: swapBytes.
	self setImageHeaderFlagsFrom: headerFlags.
	extraVMMemory	:= self getWord32FromFile: f swap: swapBytes.
	hdrNumStackPages	:= self getShortFromFile: f swap: swapBytes.
	"4 stack pages is small.  Should be able to run with as few as
	 three. 4 should be comfortable but slow.  8 is a reasonable
	 default. Can be changed via vmParameterAt: 43 put: n"
	numStackPages := desiredNumStackPages ~= 0
						ifTrue: [desiredNumStackPages]
						ifFalse: [hdrNumStackPages = 0
									ifTrue: [self defaultNumStackPages]
									ifFalse: [hdrNumStackPages]].
	desiredNumStackPages := hdrNumStackPages.
	stackZoneSize := self computeStackZoneSize.
	"This slot holds the size of the native method zone in 1k units. (pad to word boundary)."
	hdrCogCodeSize := (self getShortFromFile: f swap: swapBytes) * 1024.
	cogCodeSize := desiredCogCodeSize ~= 0
						ifTrue: [desiredCogCodeSize]
						ifFalse:
							[hdrCogCodeSize = 0
									ifTrue: [cogit defaultCogCodeSize]
									ifFalse: [hdrCogCodeSize]].
	desiredCogCodeSize := hdrCogCodeSize.
	self assert: f position = (objectMemory wordSize = 4 ifTrue: [40] ifFalse: [64]).
	hdrEdenBytes	:= self getWord32FromFile: f swap: swapBytes.
	objectMemory edenBytes: (desiredEdenBytes ~= 0
						ifTrue: [desiredEdenBytes]
						ifFalse:
							[hdrEdenBytes = 0
									ifTrue: [objectMemory defaultEdenBytes]
									ifFalse: [hdrEdenBytes]]).
	desiredEdenBytes := hdrEdenBytes.
	hdrMaxExtSemTabSize := self getShortFromFile: f swap: swapBytes.
	hdrMaxExtSemTabSize ~= 0 ifTrue:
		[self setMaxExtSemSizeTo: hdrMaxExtSemTabSize].
	"pad to word boundary.  This slot can be used for anything else that will fit in 16 bits.
	 Preserve it to be polite to other VMs."
	the2ndUnknownShort	:= self getShortFromFile: f swap: swapBytes.
	self assert: f position = (objectMemory wordSize = 4 ifTrue: [48] ifFalse: [72]).
	firstSegSize := self getLongFromFile: f swap: swapBytes.
	objectMemory firstSegmentSize: firstSegSize.
	"For Open PICs to be able to probe the method cache during
	 simulation the methodCache must be relocated to memory."
	methodCacheSize := methodCache size * objectMemory wordSize.
	primTraceLogSize := primTraceLog size * objectMemory wordSize.

	"allocate interpreter memory. This list is in address order, low to high.
	 In the actual VM the stack zone exists on the C stack."
	vmRequiredMemorySize := (Cogit guardPageSize
				+ cogCodeSize
				+ stackZoneSize
				+ methodCacheSize
				+ primTraceLogSize
				+ self rumpCStackSize) roundUpTo: objectMemory allocationUnit.

	"compare memory requirements with availability"
	allocationReserve := self interpreterAllocationReserveBytes.
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[| freeOldSpaceInImage headroom |
			 freeOldSpaceInImage := self getLongFromFile: f swap: swapBytes.
			 headroom := objectMemory
							initialHeadroom: extraVMMemory
							givenFreeOldSpaceInImage: freeOldSpaceInImage.
			 heapSize := objectMemory roundUpHeapSize:
						   dataSize
						+ headroom
						+ objectMemory newSpaceBytes
						+ (headroom > allocationReserve
							ifTrue: [0]
							ifFalse: [allocationReserve])]
		ifFalse:
			[heapSize :=  dataSize
						+ extraBytes
						+ objectMemory newSpaceBytes
						+ (extraBytes > allocationReserve
							ifTrue: [0]
							ifFalse: [allocationReserve])].

	objectMemory allocateMemoryOfSize: vmRequiredMemorySize + heapSize.	
	
	heapBase := objectMemory
					setHeapBase: objectMemory memory initialAddress + vmRequiredMemorySize
					memoryLimit:  objectMemory memory initialAddress + vmRequiredMemorySize + heapSize
					endOfMemory: objectMemory memory initialAddress + vmRequiredMemorySize + dataSize.

	self assert: cogCodeSize \\ 4 = 0.
	self assert: objectMemory memoryLimit \\ 4 = 0.
	self assert: self rumpCStackSize \\ 4 = 0.
	"read in the image in bulk, then swap the bytes if necessary"
	f position: headerSize.
	count := objectMemory readHeapFromImageFile: f dataBytes: dataSize.
	count ~= dataSize ifTrue: [self halt]]
		ensure: [f close].
	self moveMethodCacheToMemoryAt: objectMemory cogCodeBase + cogCodeSize + stackZoneSize.
	self movePrimTraceLogToMemoryAt: objectMemory cogCodeBase + cogCodeSize + stackZoneSize + methodCacheSize.

	self ensureImageFormatIsUpToDate: swapBytes.

	bytesToShift := objectMemory memoryBaseForImageRead - oldBaseAddr.  "adjust pointers for zero base address"
	UIManager default
		informUser: 'Relocating object pointers...'
		during: [self initializeInterpreter: bytesToShift].
	self initializeCodeGenerator
]

{ #category : #'stack pages' }
CogVMSimulator >> osCogStackPageHeadroom [
	"Notional headroom for the simulator.  The platform provides this in the real VM."
	^1024
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> ownVM: threadIndexAndFlags [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #ownVM:
		withArguments: {threadIndexAndFlags}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> ownVMFromUnidentifiedThread [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #ownVMFromUnidentifiedThread
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> ownerIndexOfProcess: aProcess [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #ownerIndexOfProcess:
		withArguments: {aProcess}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> ownerIndexOfThreadId: threadId [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #ownerIndexOfThreadId:
		withArguments: {threadId}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #accessing }
CogVMSimulator >> parent [
	^ parent
]

{ #category : #accessing }
CogVMSimulator >> parent: anObject [

	parent := anObject
]

{ #category : #'plugin support' }
CogVMSimulator >> pluginEntryFor: mapIndex [
	^mappedPluginEntries at: (mapIndex > 1000
								ifTrue: [externalPrimitiveTable at: mapIndex - 1001]
								ifFalse: [mapIndex])
]

{ #category : #'as yet unclassified' }
CogVMSimulator >> pluginList: aCollection [ 

	pluginList := aCollection
]

{ #category : #'object memory support' }
CogVMSimulator >> preGCAction: gcModeArg [
	"Override to void debugStackPointers on any GC/remap"
	debugStackDepthDictionary ifNotNil:
		[debugStackDepthDictionary := Dictionary new].
	^super preGCAction: gcModeArg
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> preemptDisowningThread [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #preemptDisowningThread
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'other primitives' }
CogVMSimulator >> primStringcomparewithcollated [
	^ self primitiveFail
]

{ #category : #'other primitives' }
CogVMSimulator >> primStringfindSubstringinstartingAtmatchTable [
	^self primitiveFail
]

{ #category : #'other primitives' }
CogVMSimulator >> primStringindexOfAsciiinStringstartingAt [
	^ self primitiveFail
]

{ #category : #'other primitives' }
CogVMSimulator >> primStringtranslatefromtotable [
	^ self primitiveFail
]

{ #category : #'simulation only' }
CogVMSimulator >> primTraceLogSize [
	^PrimTraceLogSize * objectMemory wordSize
]

{ #category : #'other primitives' }
CogVMSimulator >> primitiveBeep [

	Beeper beep.
]

{ #category : #'debugging traps' }
CogVMSimulator >> primitiveClosureValueWithArgs [
	"Transcript clear.
	 self shortPrintFrameAndCallers: framePointer.
	 self halt."
	^super primitiveClosureValueWithArgs
]

{ #category : #'debugging traps' }
CogVMSimulator >> primitiveContextAtPut [
	"| aContext |
	aContext := self stackValue: 2.
	(#(24205456 24205732) includes: aContext) ifTrue:
		[(self checkIsStillMarriedContext: aContext currentFP: framePointer)
			ifTrue: [self printFrame: (self frameOfMarriedContext: aContext)
						WithSP: (self frameOfMarriedContext: aContext) - 48]
			ifFalse: [self printContext: aContext]]."
	^super primitiveContextAtPut
]

{ #category : #'debugging traps' }
CogVMSimulator >> primitiveDoPrimitiveWithArgs [
	| primIndex |
	primIndex := objectMemory integerValueOf: (self stackValue: 1).
	transcript nextPutAll: 'DO PRIMITIVE: '; print: (self functionPointerFor: primIndex inClass: nil); cr; flush.
	(#(76 "primitiveStoreStackp" 188 189 "eval method") includes: primIndex) ifTrue:
		[self halt].
	^super primitiveDoPrimitiveWithArgs
]

{ #category : #'debugging traps' }
CogVMSimulator >> primitiveExecuteMethod [
	self halt: thisContext selector.
	^super primitiveExecuteMethod
]

{ #category : #'as yet unclassified' }
CogVMSimulator >> primitiveFailCount [
	^ primitiveFailCount
]

{ #category : #'as yet unclassified' }
CogVMSimulator >> primitiveFailCount: anInteger [ 

	primitiveFailCount := anInteger
]

{ #category : #'as yet unclassified' }
CogVMSimulator >> primitiveFailCounting [

	"This primitive always fails, but it counts the number of calls. Useful for tests"

	primitiveFailCount := primitiveFailCount + 1.
	self primitiveFail.
	
]

{ #category : #'as yet unclassified' }
CogVMSimulator >> primitiveForceMachineCodeCompaction [
	
	self commenceCogCompiledCodeCompaction.
	self pop: 2 thenPushBool: true.

]

{ #category : #'other primitives' }
CogVMSimulator >> primitiveGetAttribute [
	"Fetch the system attribute with the given integer ID. The result is a string, which will be empty if the attribute is not defined."

	| index s attribute |
	index := self stackIntegerValue: 0.
	self successful ifTrue: [
		attribute := systemAttributes at: index ifAbsent: [Smalltalk vm getSystemAttribute: index].
		attribute ifNil: [ ^self primitiveFail ].
		s := objectMemory instantiateClass: (objectMemory splObj: ClassByteString) indexableSize: attribute size.
		1 to: attribute size do: [ :i |
			objectMemory storeByte: i-1 ofObject: s withValue: (attribute at: i) asciiValue].
		self pop: 2 "rcvr, attr" thenPush: s]
]

{ #category : #'I/O primitives' }
CogVMSimulator >> primitiveKbdNext [

	self pop: 1.
	Sensor keyboardPressed
		ifTrue: [self pushInteger: Sensor primKbdNext]
		ifFalse: [self push: objectMemory nilObject]
]

{ #category : #'I/O primitives' }
CogVMSimulator >> primitiveKbdPeek [

	self pop: 1.
	Sensor keyboardPressed
		ifTrue: [self pushInteger: Sensor primKbdPeek]
		ifFalse: [self push: objectMemory nilObject]
]

{ #category : #'I/O primitives' }
CogVMSimulator >> primitiveMouseButtons [
	| buttons |
	self pop: 1.
	buttons := Sensor primMouseButtons.
	self pushInteger: buttons
]

{ #category : #'debugging traps' }
CogVMSimulator >> primitiveNewWithArg [
	"(objectMemory hasSpurMemoryManagerAPI
	 and: [self classNameOf: (self stackValue: 1) Is: 'Bitmap']) ifTrue:
		[self printExternalHeadFrame.
		 self halt]."
	^super primitiveNewWithArg
]

{ #category : #'control primitives' }
CogVMSimulator >> primitiveObject: actualReceiver perform: selector withArguments: argumentArray lookedUpIn: lookupClass [
	"Override to allow simulator to filter start-up items to avoid as-yet unsimulatable plugins."

	(self filterPerformOf: selector to: actualReceiver) ifTrue:
		[^self pop: argumentCount + 1 thenPush: actualReceiver].
	^super primitiveObject: actualReceiver perform: selector withArguments: argumentArray lookedUpIn: lookupClass
]

{ #category : #'object access primitives' }
CogVMSimulator >> primitiveObjectAt [
	"self transcript
		nextPutAll: (self nameOfClass: (self methodClassOf: (self stackValue: 1)));
		nextPutAll: '>>#';
		nextPutAll: (self stringOf: (self maybeSelectorOfMethod: (self stackValue: 1)));
		nextPutAll: ' objectAt: '; print: (objectMemory integerValueOf: self stackTop); cr; flush.
	self halt."
	^super primitiveObjectAt
]

{ #category : #'object access primitives' }
CogVMSimulator >> primitiveObjectAtPut [
	| newValue |
	newValue := self stackValue: 0.
	((self stackValue: 1) = ConstOne
	 and: [(objectMemory isIntegerObject: newValue) not
		   or: [MULTIPLEBYTECODESETS not
			and: [(objectMemory integerValueOf: newValue) < 0]]]) ifTrue:
		[self halt].
	^super primitiveObjectAtPut
]

{ #category : #'debugging traps' }
CogVMSimulator >> primitiveObjectPointsTo [
	"self halt."
	^super primitiveObjectPointsTo
]

{ #category : #'debugging traps' }
CogVMSimulator >> primitivePerform [
	| receiver selector |
	"If called from the machine code perform primitive, it should not have been found,
	 except that the cacheing for V3 has a mismatch between that used ror the first-level
	 method cache and inline caches."
	receiver := (self stackValue: argumentCount).
	selector := self stackValue: argumentCount - 1.
	((self methodHasCogMethod: newMethod)
	 and: [(objectMemory isCompactInstance: receiver) not]) ifTrue:
		[self deny: (self newMethodInLookupCacheAt: selector and: (objectMemory fetchClassTagOf: receiver))].
	self sendBreakpoint: selector receiver: receiver.
	(self filterPerformOf: selector to: receiver) ifTrue:
		[^self pop: argumentCount].
	^super primitivePerform
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> primitiveProcessBindToThreadId [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #primitiveProcessBindToThreadId
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> primitiveProcessBoundThreadId [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #primitiveProcessBoundThreadId
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> primitiveRelinquishProcessor [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #primitiveRelinquishProcessor
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'system control primitives' }
CogVMSimulator >> primitiveSignalAtMilliseconds [
	super primitiveSignalAtMilliseconds.
	"self successful ifTrue:
		[Transcript
			cr; nextPutAll: thisContext selector;
			nextPutAll: ' now '; nextPutAll: self ioUTCMicroseconds hex;
			nextPutAll: ' wakeup '; nextPutAll: nextWakeupUsecs hex;
			nextPutAll: ' wakeup - now '; print: nextWakeupUsecs - self ioUTCMicroseconds; flush]"
]

{ #category : #'debugging traps' }
CogVMSimulator >> primitiveStoreStackp [
	"self printContext: (self stackValue: 1).
	self halt."
	"(self stackValue: 1) = 16r1934F80 ifTrue: [self halt]."
	super primitiveStoreStackp
]

{ #category : #'plugin support' }
CogVMSimulator >> primitiveThatDoNothingWithOneArgument [
	
	| arg recvr |

	arg := self stackTop.
	recvr := self stackValue: 1.
	
	recvr = objectMemory nilObject 
		ifTrue: [ ^ self primitiveFail ].
	
	^ self pop: 2 thenPush: arg.
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> primitiveVMCurrentThreadId [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #primitiveVMCurrentThreadId
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'system control primitives' }
CogVMSimulator >> primitiveVMParameter [
	(argumentCount = 2
	 and: [(self stackValue: 1) = (objectMemory integerObjectOf: 34)]) ifTrue:
		[self halt].
	^super primitiveVMParameter
]

{ #category : #'system control primitives' }
CogVMSimulator >> primitiveVoidVMState [
	self halt.
	^super primitiveVoidVMState
]

{ #category : #'debug printing' }
CogVMSimulator >> print: it [

	traceOn ifTrue:
		[it isString ifTrue: [transcript nextPutAll: it] ifFalse: [it printOn: transcript]]
]

{ #category : #'debug printing' }
CogVMSimulator >> printActivationNameForSelector: aSelector startClass: startClass [
	super printActivationNameForSelector: aSelector startClass: startClass.
	"(self transcript dependents detect: [:d| d isTextView] ifNone: []) ifNotNil:
		[:textView| | text size |
		text := textView text asString.
		((size := text size) >= 30
		and: [(text copyFrom: size - 29 to: size) = 'Object(ProtoObject)>initialize']) ifTrue:
			[self doOrDefer: [self changed: #byteCountText; changed: #composeAll].
			 self halt]"
]

{ #category : #'debug printing' }
CogVMSimulator >> printChar: aByte [

	traceOn ifTrue: [ transcript nextPut: aByte asCharacter ].
]

{ #category : #'debug printing' }
CogVMSimulator >> printCurrentBytecodeOn: aStream [
	| code |
	code := currentBytecode radix: 16.
	aStream ensureCr; print: localIP - method - 3; tab.
	bytecodeSetSelector > 0 ifTrue:
		[aStream nextPutAll: 'ALT '].
	aStream
		nextPut: (code size < 2
					ifTrue: [$0]
					ifFalse: [code at: 1]);
		nextPut: code last; space;
		nextPutAll: (BytecodeTable at: currentBytecode + 1);
		space;
		nextPut: $(; print: byteCount + 1; nextPut: $)
]

{ #category : #'debug printing' }
CogVMSimulator >> printECS [
	self printCallStackFP: framePointer
]

{ #category : #'debug printing' }
CogVMSimulator >> printFloat: f [

	traceOn ifTrue: [ transcript print: f ]
]

{ #category : #testing }
CogVMSimulator >> printFrameAtEachStep [
	^printFrameAtEachStep
]

{ #category : #'debug printing' }
CogVMSimulator >> printFrameOop: name at: address [
	<inline: false>
	self printFrameOop: name obj: (stackPages longAt: address) at: address
]

{ #category : #'debug printing' }
CogVMSimulator >> printFrameOop: name obj: obj at: address [
	| it len |
	<inline: false>
	<var: #name type: #'char *'>
	<var: #address type: #'char *'>
	it := stackPages longAt: address.
	self printHex: address;
		printChar: $:.
	len := self strlen: name.
	1 to: 12 - len do: [:i| self printChar: $ ].
	self print: name;
		print: ': ';
		printHex: it.
	self tab.
	it = obj
		ifTrue: [self tab]
		ifFalse: [self printHex: obj; space].
	self
		print: (self shortPrint: obj);
		cr
]

{ #category : #'debug printing' }
CogVMSimulator >> printFrameThing: name andFrame: theFP at: address [
	<var: #theFP type: #'char *'>
	| it |
	<inline: false>
	<var: #name type: #'char *'>
	<var: #address type: #'char *'>
	it := stackPages longAt: address.
	self printHex: address;
		printChar: $:.
	1 to: 12 - (self strlen: name) do: [:i| self printChar: $ ].
	self print: name;
		print: ': ';
		printHex: it.
	it ~= 0 ifTrue:
		[self printChar: $=; printNum: it.
		 (objectMemory isInMemory: it) ifFalse:
			[(cogit lookupAddress: it) ifNotNil:
				[:label| self space; printChar: $(; print: label; printChar: $)]]].
	self print: ' frame: '; printHex: theFP; cr
]

{ #category : #'debug printing' }
CogVMSimulator >> printFrameThing: name at: address [
	| it |
	<inline: false>
	<var: #name type: #'char *'>
	<var: #address type: #'char *'>
	it := stackPages longAt: address.
	self printHex: address;
		printChar: $:.
	1 to: 12 - (self strlen: name) do: [:i| self printChar: $ ].
	self print: name;
		print: ': ';
		printHex: it.
	it ~= 0 ifTrue:
		[self printChar: $=; printNum: it.
		 (objectMemory isInMemory: it) ifFalse:
			[(cogit lookupAddress: it) ifNotNil:
				[:label| self space; printChar: $(; print: label; printChar: $)]]].
	self cr
]

{ #category : #'debug printing' }
CogVMSimulator >> printHex: anInteger [

	traceOn ifTrue:
		[| it16 |
		 it16 := anInteger radix: 16.
		 transcript
			next: 8 - it16 size put: Character space;
			nextPutAll: (anInteger storeStringBase: 16)]
]

{ #category : #'debug printing' }
CogVMSimulator >> printHexnp: anInteger [

	traceOn ifTrue:
		[transcript nextPutAll: ((anInteger ifNil: [0]) asInteger storeStringBase: 16)]
]

{ #category : #'debug printing' }
CogVMSimulator >> printHexnpnp: anInteger [
	"Print n in hex, in the form '1234', unpadded"
	traceOn ifTrue:
		[transcript nextPutAll: ((anInteger ifNil: [0]) printStringBase: 16)]
]

{ #category : #'debug printing' }
CogVMSimulator >> printLCS [
	self printCallStackFP: localFP
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> printLogEntryAt: i [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #printLogEntryAt:
		withArguments: {i}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'debug printing' }
CogVMSimulator >> printNum: anInteger [

	traceOn ifTrue: [ transcript print: anInteger ].
]

{ #category : #'rump c stack' }
CogVMSimulator >> printRumpCStackTo: address [
	self assert: (self isOnRumpCStack: address).
	heapBase - objectMemory wordSize
		to: address
		by: objectMemory wordSize negated
		do:
			[:addr|
			self printHex: addr.
			addr = cogit processor sp
				ifTrue: [self print: ' sp->']
				ifFalse:
					[addr = cogit processor fp
						ifTrue: [self print: ' fp->']
						ifFalse: [self tab]].
			self tab; printHex: (objectMemory longAt: addr); cr]
]

{ #category : #'debug printing' }
CogVMSimulator >> printStringForCurrentBytecode [
	^String streamContents: [:str| self printCurrentBytecodeOn: str]
]

{ #category : #'debug printing' }
CogVMSimulator >> printStringOf: oop [

	super printStringOf: oop.
	traceOn ifTrue: [transcript flush]
]

{ #category : #'debug printing' }
CogVMSimulator >> printStringOf: oop on: aStream [
	| fmt cnt i |
	(objectMemory isIntegerObject: oop) ifTrue:
		[^nil].
	(oop between: objectMemory startOfMemory and: objectMemory freeStart) ifFalse:
		[^nil].
	(oop bitAnd: (objectMemory wordSize - 1)) ~= 0 ifTrue:
		[^nil].
	fmt := objectMemory formatOf: oop.
	fmt < 8 ifTrue: [ ^nil ].

	cnt := 100 min: (objectMemory lengthOf: oop).
	i := 0.
	[i < cnt] whileTrue: [
		aStream nextPut: (Character value: (objectMemory fetchByte: i ofObject: oop)).
		i := i + 1.
	].
	aStream flush
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> queueForwardedEvent: event [
	eventQueue ifNil:
		[eventQueue := SharedQueue new].
	eventQueue nextPut: event
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> recordThreadSwitchTo: ownerIndex source: sourceCode [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #recordThreadSwitchTo:source:
		withArguments: {ownerIndex. sourceCode}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'debug support' }
CogVMSimulator >> recordTrace: classOrInteger thing: selector source: source [
	"This method includes or excludes CoInterpreterMT methods as required.
	 It used to be auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate.
	 Now checks for or collects expectedSends."
	(expectedSends == nil
	 or: [objectMemory isIntegerObject: classOrInteger]) ifFalse:
		[expecting
			ifTrue:
				[expectedSends peek ~~ selector ifTrue: [self halt].
				 expectedSends next]
			ifFalse:
				[expectedSends nextPut: selector]].
	
	^self perform: #recordTrace:thing:source:
		withArguments: {classOrInteger. selector. source}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> returnToSchedulingLoopAndReleaseVMOrWakeThread: vmThread source: source [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #returnToSchedulingLoopAndReleaseVMOrWakeThread:source:
		withArguments: {vmThread. source}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'image save/restore' }
CogVMSimulator >> reverseBytesInImage [
	UIManager default
		informUser: 'Swapping bytes of foreign image...'
		during: [super reverseBytesInImage]
]

{ #category : #'method lookup cache' }
CogVMSimulator >> rewriteMethodCacheEntryForExternalPrimitiveToFunction: localPrimAddress [
	super rewriteMethodCacheEntryForExternalPrimitiveToFunction:
				(self mapFunctionToAddress: (localPrimAddress = 0
												ifTrue: [#primitiveFail]
												ifFalse: [localPrimAddress])).
	"Hack; the super call will rewrite the entry to the address of the function.
	 So (when simulating) undo the damage and put back the functionPointer"
	(methodCache at: lastMethodCacheProbeWrite + MethodCacheMethod) = newMethod ifTrue:
		[methodCache
			at: lastMethodCacheProbeWrite + MethodCachePrimFunction
			put: (self cCoerce: localPrimAddress to: #'sqIntptr_t')]
]

{ #category : #'rump c stack' }
CogVMSimulator >> rumpCStackAddress [
	| alignment alignedHeapBase |
	alignment := 64. "byte alignment for stack frames; IA32 requires 16 bytes."
	alignedHeapBase := heapBase bitAnd: alignment negated.
	^alignedHeapBase = heapBase
		ifTrue: [heapBase - alignment]
		ifFalse: [alignedHeapBase]
]

{ #category : #'rump c stack' }
CogVMSimulator >> rumpCStackSize [
	"Allocate a rump C stack for simulation.  This stack is used for C calls, i.e. calls
	 made into the simulated C run-time, typically of routines in CoInterpreter.
	 We also use it to hold in-memory copies of the cStackPointer and cFramePointer
	 variables for simulation speed.  Alas we don't use an in-memory copy of stackLimit,
	 because we need some activity to count in order to implement the ioMSecs
	 routine and the stackLimit check is the ideal one."
	^self threadManager
		ifNil: [RumpCStackSize]
		ifNotNil: [:threadManager| RumpCStackSize * (threadManager maxNumThreads + 1)]
]

{ #category : #testing }
CogVMSimulator >> run [
	"Just run"
	quitBlock := [displayView ifNotNil:
				   [displayView containingWindow ifNotNil:
					[:topWindow|
					((World submorphs includes: topWindow)
					 and: [UIManager default confirm: 'close?']) ifTrue:
						[topWindow delete]]].
				  ^self close].
	self initStackPages.
	self loadInitialContext.
	self initialEnterSmalltalkExecutive
]

{ #category : #'primitive support' }
CogVMSimulator >> saneFunctionPointerForFailureOfPrimIndex: primIndex [
	"For simulation override to do the check specially when the
	 primitiveFunctionPointer is an invalid address proxy for a primitive."
	| basePrimitive |
	(instructionPointer < objectMemory nilObject asUnsignedInteger
	and: [primitiveFunctionPointer isInteger
	and: [self isPrimitiveFunctionPointerAnIndex not
	and: [primIndex ~= PrimNumberExternalCall
	and: [(self isMetaPrimitiveIndex: primIndex) not]]]]) ifTrue:
		[basePrimitive := self functionPointerFor: primIndex inClass: objectMemory nilObject.
		 ^(cogit lookupAddress: primitiveFunctionPointer) endsWith: basePrimitive].

	^super saneFunctionPointerForFailureOfPrimIndex: primIndex
]

{ #category : #'I/O primitives' }
CogVMSimulator >> savedWindowSize [
	^savedWindowSize ifNil: [0]
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> sendInvokeCallbackContext: vmCallbackContext [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #sendInvokeCallbackContext:
		withArguments: {vmCallbackContext}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #UI }
CogVMSimulator >> setBreakBlockFromString: aString [
	| bString block |
	bString := aString withBlanksTrimmed.
	bString first ~= $[ ifTrue:
		[bString := '[:ct|', bString, ']'].
	block := [Compiler evaluate: bString for: self logged: false]
				on: Error
				do: [:ex|
					UIManager default warn: ex messageText.
					^self].
	cogit breakBlock: block
]

{ #category : #accessing }
CogVMSimulator >> setBreakCount: anInteger [
	breakCount := anInteger
]

{ #category : #accessing }
CogVMSimulator >> setBreakSelectorLength: anInteger [ 
	
	breakSelectorLength := anInteger
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> setCogVMFlags: flags [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #setCogVMFlags:
		withArguments: {flags}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> setImageHeaderFlagsFrom: headerFlags [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #setImageHeaderFlagsFrom:
		withArguments: {headerFlags}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> setMaxWaitingPriorityTo: minPriority [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #setMaxWaitingPriorityTo:
		withArguments: {minPriority}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> setOwnerIndexOfProcess: aProcess to: anIndex bind: bind [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #setOwnerIndexOfProcess:to:bind:
		withArguments: {aProcess. anIndex. bind}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'debug printing' }
CogVMSimulator >> shortPrintContext: aContext [
	transcript ensureCr.
	^super shortPrintContext: aContext
]

{ #category : #'debug printing' }
CogVMSimulator >> shortPrintFrame: theFP [
	self transcript ensureCr.
	^super shortPrintFrame: theFP
]

{ #category : #'process primitive support' }
CogVMSimulator >> signalSemaphoreWithIndex: index [
	"This is a simulation.  See platforms/Cross/vm/sqExternalSemaphores.c for the real code.
	 Thanks to Levente Uzoni for making this version almost thread-safe (in Smalltalk)"
	<doNotGenerate>
	| originalResponses newRequests newResponses |
	index <= 0 ifTrue: [^false].
	index > externalSemaphoreSignalRequests size ifTrue:
		[newRequests := Array new: 1 << index highBit withAll: 0.
		 newResponses := newRequests shallowCopy].
	"This is a lock-free thread-safe grow...; thanks Levente"
	originalResponses := externalSemaphoreSignalResponses.
	[index > externalSemaphoreSignalRequests size] whileTrue:
		[newRequests
			replaceFrom: 1
			to: externalSemaphoreSignalRequests size
			with: externalSemaphoreSignalRequests
			startingAt: 1.
		 newResponses
			replaceFrom: 1
			to: externalSemaphoreSignalResponses size
			with: externalSemaphoreSignalResponses
			startingAt: 1.
		 externalSemaphoreSignalResponses == originalResponses "This should always be true."
			ifTrue:
				[externalSemaphoreSignalRequests := newRequests.
				 externalSemaphoreSignalResponses := newResponses]
			ifFalse:
				[originalResponses := externalSemaphoreSignalResponses]].
	"This is not thread-safe however..."
	externalSemaphoreSignalRequests
		at: index
		put: (externalSemaphoreSignalRequests at: index) + 1.
	^true
]

{ #category : #'debug printing' }
CogVMSimulator >> space [

	traceOn ifTrue: [ transcript space ]
]

{ #category : #'plugin support' }
CogVMSimulator >> sqGetInterpreterProxy [
	"I am basically my own proxy..."
	^self
]

{ #category : #'simulation only' }
CogVMSimulator >> sqMakeMemoryNotExecutableFrom: baseAddress To: limitAdress [ 
	^self
]

{ #category : #'memory access' }
CogVMSimulator >> sqMemoryExtraBytesLeft: includingSwap [
	^0
]

{ #category : #'memory access' }
CogVMSimulator >> sqShrinkMemory: oldLimit By: delta [
	transcript show: 'shrink memory from ', oldLimit printString, ' by ', delta printString, ' remember it doesn''t actually shrink in simulation'; cr.

	^ oldLimit
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> stackLimitFromMachineCode [
	"Intercept accesses to the stackLimit from machine code to increment byteCount so that
	 ioMSecs/ioMicroseconds does something reasonable when we're purely in machine code.
	 Force an interrupt check every 2 ms in simulated time (2ms = the default heartbeat), or if
	 the profile tick has expired.."

	(byteCount := byteCount + 1) - lastPollCount >= (2000 * ByteCountsPerMicrosecond) ifTrue:
		[lastPollCount := byteCount.
		 self doOrDefer: [self changed: #byteCountText; changed: #composeAll]].
	(lastPollCount = byteCount
	 or: [nextProfileTick > 0 and: [nextProfileTick <= self ioUTCMicroseconds]]) ifTrue:
		[suppressHeartbeatFlag "gets set by selector breakpoints"
			ifTrue: [self forceInterruptCheck]
			ifFalse: [self forceInterruptCheckFromHeartbeat]].
	^stackLimit
]

{ #category : #'stack pages' }
CogVMSimulator >> stackPage [
	^stackPage
]

{ #category : #accessing }
CogVMSimulator >> stackPages [
	^stackPages
]

{ #category : #'stack pages' }
CogVMSimulator >> stackZoneBase [
	"In the simulator the stack zone starts immediately after the code zone."
	^cogit cogCodeBase + cogCodeSize
]

{ #category : #'simulation only' }
CogVMSimulator >> startInContextSuchThat: aBlock [
	"Change the active process's suspendedContext to its sender, which short-cuts the
	 initialization of the system.  This can be a short-cut to running code, e.g. when doing
		Smalltalk saveAs.
		Compiler recompileAll
	 via e.g.
		vm startInContextSuchThat: [:ctxt| (vm stringOf: (vm penultimateLiteralOf: (vm methodForContext: ctxt))) = 'DoIt']"
	<doNotGenerate>
	| context activeProc |
	activeProc := self activeProcess.
	context := objectMemory fetchPointer: SuspendedContextIndex ofObject: activeProc.
	[context = objectMemory nilObject ifTrue:
		[^self error: 'no context found'].
	 aBlock value: context] whileFalse:
		[context := objectMemory fetchPointer: SenderIndex ofObject: context].
	objectMemory storePointer: SuspendedContextIndex ofObject: activeProc withValue: context.
	"Now push a dummy return value."
	objectMemory
		storePointer: (self fetchStackPointerOf: context) + CtxtTempFrameStart
		ofObject: context
		withValue: objectMemory nilObject.
	self storeInteger: StackPointerIndex
		ofObject: context
		withValue: (self fetchStackPointerOf: context) + 1
]

{ #category : #'debugging traps' }
CogVMSimulator >> startOfMemory [
	self shouldNotImplement
]

{ #category : #'simulation only' }
CogVMSimulator >> systemAttributes [
	^systemAttributes
]

{ #category : #'debug printing' }
CogVMSimulator >> tab [

	traceOn ifTrue: [ transcript tab ].
]

{ #category : #'return bytecodes' }
CogVMSimulator >> tearDownAndRebuildFrameForCannotReturnBaseFrameReturnFrom: contextToReturnFrom to: contextToReturnTo returnValue: returnValue [
	self halt.
	^super tearDownAndRebuildFrameForCannotReturnBaseFrameReturnFrom: contextToReturnFrom to: contextToReturnTo returnValue: returnValue
]

{ #category : #testing }
CogVMSimulator >> test [
	self testBreakCount: -1 printSends: true printFrames: false printBytecodes: false
]

{ #category : #testing }
CogVMSimulator >> testBecome [
	"Become some young things.  AA testBecome    "
	| array list1 list2 p1 p2 p3 p4 |
	array := objectMemory splObj: ClassArray.
	list1 := objectMemory instantiateClass: array indexableSize: 2.
	list2 := objectMemory instantiateClass: array indexableSize: 2.
	p1 := objectMemory instantiateClass: (objectMemory splObj: ClassPoint) indexableSize: 0.
	self push: p1.
	objectMemory storePointer: 0 ofObject: list1 withValue: p1.
	p2 := objectMemory instantiateClass: (objectMemory splObj: ClassPoint) indexableSize: 0.
	self push: p2.
	objectMemory storePointer: 1 ofObject: list1 withValue: p2.
	p3 := objectMemory instantiateClass: (objectMemory splObj: ClassMessage) indexableSize: 0.
	self push: p3.
	objectMemory storePointer: 0 ofObject: list2 withValue: p3.
	p4 := objectMemory instantiateClass: (objectMemory splObj: ClassMessage) indexableSize: 0.
	self push: p4.
	objectMemory storePointer: 1 ofObject: list2 withValue: p4.
	(objectMemory become: list1 with: list2 twoWay: true copyHash: true) ifFalse: [self error: 'failed'].
	self popStack = p2 ifFalse: [self halt].
	self popStack = p1 ifFalse: [self halt].
	self popStack = p4 ifFalse: [self halt].
	self popStack = p3 ifFalse: [self halt].
	(objectMemory fetchPointer: 0 ofObject: list1) = p3 ifFalse: [self halt].
	(objectMemory fetchPointer: 1 ofObject: list1) = p4 ifFalse: [self halt].
	(objectMemory fetchPointer: 0 ofObject: list2) = p1 ifFalse: [self halt].
	(objectMemory fetchPointer: 1 ofObject: list2) = p2 ifFalse: [self halt].
]

{ #category : #testing }
CogVMSimulator >> testBreakCount: breakCount printSends: shouldPrintSends printFrames: shouldPrintFrames printBytecodes: shouldPrintBytecodes [
	self initStackPages.
	self loadInitialContext.
	transcript clear.
	quitBlock := [^self close].
	printSends := true & shouldPrintSends. "true & foo allows evaluating printFoo := true in the debugger"
	printFrameAtEachStep := true & shouldPrintFrames.
	printBytecodeAtEachStep := true & shouldPrintBytecodes.
	self ensureDebugAtEachStepBlock.
	self initialEnterSmalltalkExecutive
]

{ #category : #testing }
CogVMSimulator >> testPCMapping [
	objectMemory allObjectsDo:
		[:o|
		((objectMemory isCompiledMethod: o)
		 and: [self methodShouldBeCogged: o]) ifTrue:
			[(self methodHasCogMethod: o) ifFalse:
				[[([cogit cog: o selector: objectMemory nilObject]
					on: Error
					do: [:ex|
						ex messageText = 'This won''t work...' ifTrue:
							[ex resumeUnchecked: nil].
						ex pass]) isNil
				   and: [cogCompiledCodeCompactionCalledFor]] whileTrue:
					[cogMethodZone clearCogCompiledCode.
					 cogCompiledCodeCompactionCalledFor := false]].
			 (self methodHasCogMethod: o)
				ifTrue:
					[transcript nextPut: $.; flush.
					 cogit testMcToBcPcMappingForMethod: (self cogMethodOf: o)]
				ifFalse:
					[transcript nextPutAll: 'failed to compile method '; print: o; cr; flush]]]
]

{ #category : #testing }
CogVMSimulator >> testWithBytecodePrint [
	self testBreakCount: -1 printSends: true printFrames: false printBytecodes: true
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> threadIdFieldOf: aProcess [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #threadIdFieldOf:
		withArguments: {aProcess}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> threadManager [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #threadManager
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> threadSchedulingLoop: vmThread [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #threadSchedulingLoop:
		withArguments: {vmThread}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> threadSwitchIfNecessary: newProc from: sourceCode [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #threadSwitchIfNecessary:from:
		withArguments: {newProc. sourceCode}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #UI }
CogVMSimulator >> toggleTranscript [
	| transcriptPane |
	transcript ifNil: [transcript := Transcript. ^self].
	displayView ifNil: [^self changed: #flash].
	transcriptPane := (displayView outermostMorphThat: [:m| m isSystemWindow])
							submorphThat: [:m| m model isStream]
							ifNone: [^self changed: #flash].
	transcript := transcript = Transcript
					ifTrue: [transcriptPane model]
					ifFalse: [Transcript]
]

{ #category : #'simulation only' }
CogVMSimulator >> transcript [
	^transcript
]

{ #category : #'simulation only' }
CogVMSimulator >> transcript: aTranscript [
	transcript := aTranscript
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> transferTo: newProc from: sourceCode [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #transferTo:from:
		withArguments: {newProc. sourceCode}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> tryToExecuteSmalltalk: vmThread [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #tryToExecuteSmalltalk:
		withArguments: {vmThread}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'interpreter shell' }
CogVMSimulator >> unableToReadImageError [
	self error:  'Read failed or premature end of image file'
]

{ #category : #'frame access' }
CogVMSimulator >> updateStateOfSpouseContextForFrame: theFP WithSP: theSP [
	 "26431360 = (self frameContext: theFP) ifTrue:
		[self halt]."
	"((self stringOf: (self penultimateLiteralOf: (self frameMethodObject: theFP))) = #indexOf:startingAt:ifAbsent:) ifTrue:
		[self halt]."
	^super updateStateOfSpouseContextForFrame: theFP WithSP: theSP
]

{ #category : #UI }
CogVMSimulator >> utilitiesMenu: aMenuMorph [
	aMenuMorph
		add: 'toggle transcript' action: #toggleTranscript;
		add: 'clone VM' action: #cloneSimulationWindow;
		addLine;
		add: 'print ext head frame' action: #printExternalHeadFrame;
		add: 'print int head frame' action: #printHeadFrame;
		add: 'print mc/cog head frame' action: [self printFrame: cogit processor fp WithSP: cogit processor sp];
		add: 'short print ext head frame & callers' action: [self shortPrintFrameAndCallers: framePointer];
		add: 'short print int head frame & callers' action: [self shortPrintFrameAndCallers: localFP];
		add: 'short print mc/cog head frame & callers' action: [self shortPrintFrameAndCallers: cogit processor fp];
		add: 'long print ext head frame & callers' action: [self printFrameAndCallers: framePointer SP: stackPointer];
		add: 'long print int head frame & callers' action: [self printFrameAndCallers: localFP SP: localSP];
		add: 'long print mc/cog head frame & callers' action: [self printFrameAndCallers: cogit processor fp SP: cogit processor sp];
		add: 'print frame...' action: [(self promptHex: 'print frame') ifNotNil: [:fp| self printFrame: fp]];
		add: 'print call stack' action: #printCallStack;
		add: 'print stack call stack' action: #printStackCallStack;
		add: 'print stack call stack of...' action: [(self promptHex: 'frame') ifNotNil: [:fp| self printStackCallStackOf: fp]];
		add: 'print call stack of...' action: [(self promptHex: 'context or process oop') ifNotNil: [:obj| self printCallStackOf: obj]];
		add: 'print call stack of frame...' action: [(self promptHex: 'frame') ifNotNil: [:fp| self printCallStackFP: fp]];
		add: 'print all stacks' action: #printAllStacks;
		add: 'write back local ptrs' action: [stackPointer := localSP. framePointer := localFP. instructionPointer := localIP.
											self writeBackHeadFramePointers];
		add: 'write back mc ptrs' action: [stackPointer := cogit processor sp. framePointer := cogit processor fp. instructionPointer := cogit processor pc.
											self externalWriteBackHeadFramePointers];
		addLine;
		add: 'print rump C stack' action: [objectMemory printMemoryFrom: cogit processor sp to: cogit getCStackPointer];
		add: 'print registers' action: [cogit processor printRegistersOn: transcript];
		add: 'print register map' action: [cogit printRegisterMapOn: transcript];
		add: 'disassemble method/trampoline...' action: [(self promptHex: 'pc') ifNotNil: [:pc| cogit disassembleCodeAt: pc]];
		add: 'disassemble method/trampoline at pc' action:
			[cogit disassembleCodeAt: (((cogit codeEntryFor: cogit processor pc) isNil
										  and: [(cogit methodZone methodFor: cogit processor pc) = 0])
											ifTrue: [instructionPointer]
											ifFalse: [cogit processor pc])];
		add: 'disassemble ext head frame method' action: [cogit disassembleMethod: (self frameMethod: framePointer)];
		add: 'print oop...' action: [(self promptHex: 'print oop') ifNotNil: [:oop| self printOop: oop]];
		add: 'long print oop...' action: [(self promptHex: 'print oop') ifNotNil: [:oop| self longPrintOop: oop]];
		add: 'print context...' action: [(self promptHex: 'print context') ifNotNil: [:oop| self printContext: oop]];
		add: 'symbolic method...' action: [(self promptHex: 'method bytecodes') ifNotNil: [:oop| self symbolicMethod: oop]];
		addLine;
		add: 'inspect object memory' target: objectMemory action: #inspect;
		add: 'run leak checker' action: [Cursor execute showWhile: [self runLeakChecker]];
		add: 'inspect cointerpreter' action: #inspect;
		add: 'inspect cogit' target: cogit action: #inspect;
		add: 'inspect method zone' target: cogit methodZone action: #inspect.
	self isThreadedVM ifTrue:
		[aMenuMorph add: 'inspect thread manager' target: self threadManager action: #inspect].
	aMenuMorph
		addLine;
		add: 'print cog methods' target: cogMethodZone action: #printCogMethods;
		add: 'print cog methods with prim...' action:
			[(self promptNum: 'prim index') ifNotNil: [:pix| cogMethodZone printCogMethodsWithPrimitive: pix]];
		add: 'print cog methods with selector...' action:
			[|s| s := UIManager default request: 'selector'.
			s notEmpty ifTrue:
				[s = 'nil' ifTrue: [s := nil].
				 cogMethodZone methodsDo:
					[:m|
					(s ifNil: [m selector = objectMemory nilObject]
					 ifNotNil: [(objectMemory numBytesOf: m selector) = s size
							and: [(self strncmp: s
											_: (m selector + objectMemory baseHeaderSize)
											_: (objectMemory numBytesOf: m selector)) = 0]]) ifTrue:
						[cogit printCogMethod: m]]]];
		add: 'print cog methods with method...' action:
			[(self promptHex: 'method') ifNotNil: [:methodOop| cogMethodZone printCogMethodsWithMethod: methodOop]];
		add: 'print cog method for...' action: [(self promptHex: 'pc') ifNotNil: [:pc| cogit printCogMethodFor: pc]];
		add: 'print cog method header for...' action: [(self promptHex: 'pc') ifNotNil: [:pc| cogit printCogMethodHeaderFor: pc]];
		add: 'print trampoline table' target: cogit action: #printTrampolineTable;
		add: 'print prim trace log' action: #dumpPrimTraceLog;
		add: 'report recent instructions' target: cogit action: #reportLastNInstructions;
		add: (cogit printRegisters
				ifTrue: ['no print registers each instruction']
				ifFalse: ['print registers each instruction'])
			action: [cogit printRegisters: cogit printRegisters not];
		add: (cogit printInstructions
				ifTrue: ['no print instructions each instruction']
				ifFalse: ['print instructions each instruction'])
			action: [cogit printInstructions: cogit printInstructions not];
		addLine;
		add: (cogit singleStep
				ifTrue: ['no single step']
				ifFalse: ['single step'])
			action: [cogit singleStep: cogit singleStep not];
		add: 'click step' action: [cogit setClickStepBreakBlock];
		add: 'set break pc', cogit breakPC menuPrompt, '...-ve to disable or remove' action: [cogit promptForBreakPC];
		add: 'set break count...' action: [|s| s := UIManager default request: 'break count (dec)'.
											s notEmpty ifTrue: [breakCount := Integer readFrom: s readStream]];
		add: 'set break selector...' action: [|s| s := UIManager default request: 'break selector (MNU:foo for MNU)'.
											s notEmpty ifTrue:
												[(s size > 4 and: [s beginsWith: 'MNU:'])
													ifTrue: [self setBreakMNUSelector: (s allButFirst: 4)]
													ifFalse: [self setBreakSelector: s]]];
		add: 'set break block...' action: [|s| s := UIManager default request: 'break block' initialAnswer: '[:theCogit| false]'.
											s notEmpty ifTrue: [self setBreakBlockFromString: s]];
		add: 'set cogit break method...' action: [(self promptHex: 'cogit breakMethod') ifNotNil: [:bm| cogit setBreakMethod: bm]];
		add: (printBytecodeAtEachStep
				ifTrue: ['no print bytecode each bytecode']
				ifFalse: ['print bytecode each bytecode'])
			action: [self ensureDebugAtEachStepBlock.
					printBytecodeAtEachStep := printBytecodeAtEachStep not];
		add: (printFrameAtEachStep
				ifTrue: ['no print frame each bytecode']
				ifFalse: ['print frame each bytecode'])
			action: [self ensureDebugAtEachStepBlock.
					printFrameAtEachStep := printFrameAtEachStep not].
	^aMenuMorph
]

{ #category : #'debug support' }
CogVMSimulator >> veryDeepCopyWith: deepCopier [
	"Override to short-circuit the copying of any VMPluginCodeGenerators referenced from mappedPluginEntries and
	 uniqueIndices. These can in turn hold onto Monticello state, resulting in a huge ammount of unnecessary copying."
	deepCopier references
		at: mappedPluginEntries ifAbsentPut: [mappedPluginEntries];
		at: uniqueIndices ifAbsentPut: [uniqueIndices].
	mappedPluginEntries do:
		[:tuple| | block |
		block := tuple third.
		deepCopier references at: block ifAbsentPut: [block]].
	uniqueIndices keysDo:
		[:block|
		deepCopier references at: block ifAbsentPut: [block]].
	^super veryDeepCopyWith: deepCopier
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> vmOwnerLockAddress [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #vmOwnerLockAddress
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'file primitives' }
CogVMSimulator >> vmPathGet: stringBase Length: stringSize [
	| pathName stringOop |
	pathName := self vmPath.
	stringOop := stringBase - objectMemory baseHeaderSize. "Due to C call in Interp"
	1 to: stringSize do:
		[:i | objectMemory storeByte: i-1 ofObject: stringOop
			withValue: (pathName at: i) asciiValue].

]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> waitingPriorityIsAtLeast: minPriority [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #waitingPriorityIsAtLeast:
		withArguments: {minPriority}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> wakeHighestPriority [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #wakeHighestPriority
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> warpBits [

	^ myBitBlt warpBits
]

{ #category : #'debug printing' }
CogVMSimulator >> whereIs: anOop [
	(self isOnRumpCStack: anOop) ifTrue: [^'is on rump C stack'].
	^super whereIs: anOop
]

{ #category : #UI }
CogVMSimulator >> windowColorToUse [
	^Color lightBlue
]

{ #category : #'primitive support' }
CogVMSimulator >> windowIsClosing [
	self threadManager ifNotNil:
		[:threadManager|
		threadManager guiProcess ~= Processor activeProcess ifTrue:
			[threadManager guiProcess
				signalException:
					(Notification new tag: #evaluateQuit; yourself).
			Processor terminateActive]].
	quitBlock ifNotNil:
		[:effectiveQuitBlock|
		quitBlock := nil. "stop recursion on explicit window close."
		[effectiveQuitBlock value]
			on: BlockCannotReturn
			do: [:ex|]]	"Cause return from #test, et al"
]

{ #category : #'debug printing' }
CogVMSimulator >> withMemoryProtectionDo: aBlock [
	objectMemory writeProtectMemory.
	stackPages writeProtectMemory.
	^aBlock ensure:
		[objectMemory writeEnableMemory.
		 stackPages writeEnableMemory]
]

{ #category : #'frame access' }
CogVMSimulator >> withoutSmallIntegerTags: anInteger [
	self assert: (anInteger >= 0 and: [anInteger highBit <= 32]).
	^(anInteger bitAnd: 16r80000000) ~= 0
		ifTrue: ["negative"
				(anInteger bitAnd: 16r7FFFFFFE) - 16r80000000]
		ifFalse: ["positive"
				anInteger - 1]
]
