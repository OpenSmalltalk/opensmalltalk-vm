Class {
	#name : #StackMTInterpreterSimulator,
	#superclass : #StackInterpreterMT,
	#instVars : [
		'parent',
		'bootstrapping',
		'byteCount',
		'breakCount',
		'sendCount',
		'lookupCount',
		'printSends',
		'printReturns',
		'traceOn',
		'myBitBlt',
		'displayForm',
		'fakeForm',
		'filesOpen',
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
		'startMicroseconds',
		'lastYieldMicroseconds',
		'externalSemaphoreSignalRequests',
		'externalSemaphoreSignalResponses',
		'extSemTabSize',
		'atEachStepBlock',
		'disableBooleanCheat',
		'performFilters',
		'eventQueue',
		'assertVEPAES',
		'primTraceLog'
	],
	#category : #'VMMaker-Multithreading'
}

{ #category : #'class initialization' }
StackMTInterpreterSimulator class >> initializeWithOptions: optionsDictionaryOrArray objectMemoryClass: objectMemoryClassOrNil [
	"The relevant ObjectMemory and Interpreter classes must be initialized in order.
	 This happens notionally every time we start the simulator,
	 but in fact happens when ever we instantiate a simulator."
	InitializationOptions := optionsDictionaryOrArray isArray
							ifTrue: [Dictionary newFromPairs: optionsDictionaryOrArray]
							ifFalse: [optionsDictionaryOrArray].

	(objectMemoryClassOrNil ifNil: [self objectMemoryClass])
		initializeWithOptions: InitializationOptions.

	self initializeWithOptions: InitializationOptions
]

{ #category : #'instance creation' }
StackMTInterpreterSimulator class >> new [
	^self onObjectMemory: nil options: #()
]

{ #category : #'instance creation' }
StackMTInterpreterSimulator class >> newWithOptions: optionsDictionaryOrArray [
	^self onObjectMemory: nil options: optionsDictionaryOrArray
]

{ #category : #'instance creation' }
StackMTInterpreterSimulator class >> onObjectMemory: anObjectMemory [
	^self onObjectMemory: anObjectMemory options: #()
]

{ #category : #'instance creation' }
StackMTInterpreterSimulator class >> onObjectMemory: anObjectMemory options: optionsDictionaryOrArray [

	| interpreter |
	self
		initializeWithOptions: optionsDictionaryOrArray
		objectMemoryClass: (anObjectMemory ifNotNil: [anObjectMemory class]).
	^ (interpreter := self basicNew)
		threadManager: (CogThreadManager new
			setInterpreter: interpreter
			cogit: nil);
		objectMemory: anObjectMemory;
		initialize
]

{ #category : #accessing }
StackMTInterpreterSimulator >> activeProcessAffined: aBoolean [
	<doNotGenerate>
	activeProcessAffined := aBoolean
]

{ #category : #'debug support' }
StackMTInterpreterSimulator >> allObjectsSelect: objBlock [
	"self allObjectsSelect: [:oop | (self baseHeader: oop) = 1234]"

	| selected |
	selected := OrderedCollection new.
	objectMemory allObjectsDo:
		[:obj|
		(objBlock value: obj) ifTrue: [selected addLast: obj]].
	^selected
]

{ #category : #'spur bootstrap' }
StackMTInterpreterSimulator >> argumentCount: n [
	argumentCount := n
]

{ #category : #'debug support' }
StackMTInterpreterSimulator >> assertValidExecutionPointers [
	assertVEPAES ifTrue:
		[super assertValidExecutionPointers]
]

{ #category : #accessing }
StackMTInterpreterSimulator >> assertValidExecutionPointersAtEachStep [
	^assertVEPAES
]

{ #category : #accessing }
StackMTInterpreterSimulator >> assertValidExecutionPointersAtEachStep: aBoolean [
	assertVEPAES := aBoolean
]

{ #category : #testing }
StackMTInterpreterSimulator >> atEachStepBlock: aBlock [
	atEachStepBlock := aBlock
]

{ #category : #'return bytecodes' }
StackMTInterpreterSimulator >> baseFrameReturn [
	| contextToReturnTo |
	contextToReturnTo := self frameCallerContext: localFP.
	((objectMemory isContext: contextToReturnTo)
	 and: [self isMarriedOrWidowedContext: contextToReturnTo]) ifTrue:
		[(self checkIsStillMarriedContext: contextToReturnTo currentFP: nil) ifFalse:
			[self halt]].
	^super baseFrameReturn
]

{ #category : #utilities }
StackMTInterpreterSimulator >> booleanCheat: cond [
	disableBooleanCheat
		ifTrue: [self internalPop: 2
					thenPush: (cond
								ifTrue: [objectMemory trueObject]
								ifFalse: [objectMemory falseObject]).
				self fetchNextBytecode]
		ifFalse: [super booleanCheat: cond]
]

{ #category : #'spur bootstrap' }
StackMTInterpreterSimulator >> bootstrapping [
	^bootstrapping
]

{ #category : #'spur bootstrap' }
StackMTInterpreterSimulator >> bootstrapping: aBoolean [
	bootstrapping := aBoolean.
	objectMemory ifNotNil:
		[objectMemory bootstrapping: aBoolean]
]

{ #category : #accessing }
StackMTInterpreterSimulator >> breakCount [
	^breakCount
]

{ #category : #'interpreter shell' }
StackMTInterpreterSimulator >> browserPluginInitialiseIfNeeded [
"do nothing - its a macro in C code to support Mac browser plugin strangeness"
]

{ #category : #'interpreter shell' }
StackMTInterpreterSimulator >> browserPluginReturnIfNeeded [
"do nothing - its a macro in C code to support Mac browser plugin strangeness"
]

{ #category : #'memory access' }
StackMTInterpreterSimulator >> byteAt: byteAddress [
	"This is really only for the C library simulations memcpy:_:_: et al in VMClass.
	 Use objectMemory byteAt: directly where possible."
	^objectMemory byteAt: byteAddress
]

{ #category : #'memory access' }
StackMTInterpreterSimulator >> byteAt: byteAddress put: byte [
	self deprecated.
	^objectMemory byteAt: byteAddress put: byte
]

{ #category : #'debug support' }
StackMTInterpreterSimulator >> byteCount [
	"So you can call this from temp debug statements in, eg, Interpreter, such as
	self byteCount = 12661 ifTrue: [self halt].
	"

	^ byteCount
]

{ #category : #UI }
StackMTInterpreterSimulator >> byteCountText [
	^ byteCount asStringWithCommas asText
]

{ #category : #'indexing primitives' }
StackMTInterpreterSimulator >> bytecodePrimAtPut [
	"self halt."
	^super bytecodePrimAtPut
]

{ #category : #'translation support' }
StackMTInterpreterSimulator >> cCoerceSimple: value to: cTypeString [
	"Type coercion for translation only; just return the value when running in Smalltalk."

	^value
]

{ #category : #'plugin support' }
StackMTInterpreterSimulator >> callExternalPrimitive: mapIndex [
	| entry |
	entry := self pluginEntryFor: mapIndex.
	"Spur needs the primitiveFunctionPointer to be set correctly
	 for accurate following of forwarders on primitive failure."
	objectMemory hasSpurMemoryManagerAPI ifTrue:
		[primitiveFunctionPointer := entry at: 2].
	^(entry at: 1) perform: (entry at: 2)
]

{ #category : #'object memory support' }
StackMTInterpreterSimulator >> checkStackIntegrity [
	"Override to deal with incomplete initialization."
	stackPages ifNil: [^true].
	^super checkStackIntegrity
]

{ #category : #'debug support' }
StackMTInterpreterSimulator >> classAndSelectorOfMethod: meth forReceiver: rcvr [
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
	mClass := self superclassOf: mClass.
	mClass = objectMemory nilObject]
		whileFalse.
	^ Array
		with: (objectMemory fetchClassOf: rcvr)
		with: (objectMemory splObj: SelectorDoesNotUnderstand)
]

{ #category : #'plugin support' }
StackMTInterpreterSimulator >> classNameOf: aClass Is: className [
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
StackMTInterpreterSimulator >> clipboardRead: sz Into: actualAddress At: zeroBaseIndex [
	| str |
	str := Clipboard clipboardText.
	1 to: sz do:
		[:i | objectMemory byteAt: actualAddress + zeroBaseIndex + i - 1 put: (str at: i) asciiValue]
]

{ #category : #'I/O primitives' }
StackMTInterpreterSimulator >> clipboardSize [

	^ Clipboard clipboardText size
]

{ #category : #'I/O primitives' }
StackMTInterpreterSimulator >> clipboardWrite: sz From: actualDataAddress At: ignored [

	Clipboard clipboardText: (self stringOf: actualDataAddress - objectMemory baseHeaderSize)
]

{ #category : #'debug support' }
StackMTInterpreterSimulator >> cloneSimulation [
	| savedAtEachStepBlock savedDisplayView savedDisplayForm savedQuitBlock savedTranscript |
	savedAtEachStepBlock := atEachStepBlock. atEachStepBlock := nil.
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
			[atEachStepBlock := savedAtEachStepBlock.
			 displayView := savedDisplayView.
			 displayForm = savedDisplayForm.
			 quitBlock := savedQuitBlock.
			 transcript := savedTranscript]
]

{ #category : #'debug support' }
StackMTInterpreterSimulator >> cloneSimulationWindow [
	| label |
	label := 'Clone of ', (displayView containingWindow label allButFirst: 'Simulation of ' size).
	^self cloneSimulation openAsMorph
		setLabel: label;
		yourself
]

{ #category : #initialization }
StackMTInterpreterSimulator >> close [  "close any files that ST may have opened, etc"
	pluginList do: [:assoc| | plugin | plugin := assoc value. plugin ~~ self ifTrue: [plugin close]]
]

{ #category : #'simulation only' }
StackMTInterpreterSimulator >> cogit [
	"We don't have a cogit; try and get by on our own devices."
	^self
]

{ #category : #'I/O primitives support' }
StackMTInterpreterSimulator >> copyBits [

	^ myBitBlt copyBits
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> cr [

	traceOn ifTrue: [ transcript cr; flush ].
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> createActualMessageTo: class [
	objectMemory bootstrapping ifTrue:
		[self halt].
	"false
		ifTrue:
			[(self stringOf: messageSelector) = 'run:with:in:' ifTrue:
				[self halt]]
		ifFalse:
			[self halt: (self stringOf: messageSelector)]."

	^super createActualMessageTo: class
]

{ #category : #UI }
StackMTInterpreterSimulator >> desiredDisplayExtent [
	^(savedWindowSize
		ifNil: [640@480]
		ifNotNil: [savedWindowSize >> 16 @ (savedWindowSize bitAnd: 16rFFFF)])
			min: Display extent * 2 // 3
]

{ #category : #initialization }
StackMTInterpreterSimulator >> desiredEdenBytes: anInteger [
	desiredEdenBytes := anInteger
]

{ #category : #initialization }
StackMTInterpreterSimulator >> desiredNumStackPages: anInteger [
	desiredNumStackPages := anInteger
]

{ #category : #testing }
StackMTInterpreterSimulator >> disableBooleanCheat: aBoolean [
	disableBooleanCheat := aBoolean
]

{ #category : #'plugin primitive support' }
StackMTInterpreterSimulator >> dispatchMappedPluginEntry: n [ 
	^(mappedPluginEntries at: n) first
		perform: (mappedPluginEntries at: n) second
]

{ #category : #'interpreter shell' }
StackMTInterpreterSimulator >> dispatchOn: anInteger in: selectorArray [
	"Simulate a case statement via selector table lookup.
	The given integer must be between 0 and selectorArray size-1, inclusive.
	For speed, no range test is done, since it is done by the at: operation.
	Note that, unlike many other arrays used in the Interpreter, this method expect NO CArrayAccessor wrapping - it would duplicate the +1. Maybe this would be better updated to make it all uniform"
	self perform: (selectorArray at: (anInteger + 1)).
]

{ #category : #accessing }
StackMTInterpreterSimulator >> displayForm [
	"The VM SImulator draws directly on an imageMorph named displayView
	  displayView is housed on a Form named displayForm
	  displayForm is initialized in my initialize method. 
	  it 'needs' to be initialized there to support Eliot's legacy openAsMorph functionality
	"
	^displayForm
]

{ #category : #'I/O primitives support' }
StackMTInterpreterSimulator >> displayLocation [

	^ Display extent - displayForm extent - (10@10)
]

{ #category : #accessing }
StackMTInterpreterSimulator >> displayView [
	"The VM SImulator draws directly on an imageMorph named displayView
	  displayView is housed on a Form named displayForm
	  Since this is housed directly on the Morph, I have this tight compling from here->model->morph. 
	"
	self flag: 'tty'.	
	^displayView
]

{ #category : #accessing }
StackMTInterpreterSimulator >> displayView: anImageMorph [
	"The VM SImulator draws directly on an imageMorph named displayView
	  displayView is housed on a Form named displayForm
	  Since this is housed directly on the Morph, I have this tight compling from here->model->morph. 
	"
	self flag: 'tty'.
	displayView := anImageMorph
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> divorceFramesIn: aStackPage [
	"| thisPage |
	(self checkIsStillMarriedContext: 22189568 currentFP: framePointer) ifTrue:
		[thisPage := stackPages stackPageFor: (self frameOfMarriedContext: 22189568).
		 aStackPage == thisPage ifTrue:
			[self halt]]."
	^super divorceFramesIn: aStackPage
]

{ #category : #'process primitive support' }
StackMTInterpreterSimulator >> doSignalExternalSemaphores: minTableSize [
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
StackMTInterpreterSimulator >> doesNotUnderstand: aMessage [
	"If this is a doit and the objectMemory understands, pass it on."
	(thisContext findContextSuchThat: [:ctxt| ctxt selector == #evaluate:in:to:notifying:ifFail:logged:]) ifNotNil:
		[(objectMemory class whichClassIncludesSelector: aMessage selector) ifNotNil:
			[:implementingClass|
			(implementingClass inheritsFrom: Object) ifTrue: "i.e. VMClass and below"
				[thisContext sender selector ~~ #DoIt ifTrue:
					[Transcript nextPutAll: 'warning: redirecting ', aMessage selector, ' in ', thisContext sender printString, ' to objectMemory'; cr; flush].
				 aMessage lookupClass: nil.
				^aMessage sentTo: objectMemory]]].
	^super doesNotUnderstand: aMessage
]

{ #category : #'I/O primitives support' }
StackMTInterpreterSimulator >> drawLoopX: xDelta Y: yDelta [

	^ myBitBlt drawLoopX: xDelta Y: yDelta
]

{ #category : #'debug support' }
StackMTInterpreterSimulator >> dumpMethodHeader: hdr [
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
StackMTInterpreterSimulator >> elementsPerPrintOopLine [
	^4
]

{ #category : #'compiled methods' }
StackMTInterpreterSimulator >> endPCOf: aMethod [
	"Determine the endPC of a method in the heap using interpretation that looks for returns and uses branches to skip intervening bytecodes."
	| pc end farthestContinuation prim encoderClass inst is |
	(prim := self primitiveIndexOf: aMethod) > 0 ifTrue:
		[(self isQuickPrimitiveIndex: prim) ifTrue:
			[^(self startPCOfMethod: aMethod) - 1]].
	encoderClass := self encoderClassForHeader: (objectMemory methodHeaderOf: aMethod).
	is := (InstructionStream
			on: (VMCompiledMethodProxy new
					for: aMethod
					coInterpreter: self
					objectMemory: objectMemory)).
	pc := farthestContinuation := self startPCOfMethod: aMethod.
	end := objectMemory numBytesOf: aMethod.
	is pc: pc + 1.
	[pc <= end] whileTrue:
		[inst := encoderClass interpretNextInstructionFor: MessageCatcher new in: is.
		 inst selector
			caseOf: {
				 [#pushClosureCopyNumCopiedValues:numArgs:blockSize:]	
											->	[is pc: is pc + inst arguments last.
												 farthestContinuation := farthestContinuation max: pc].
				 [#jump:]					->	[farthestContinuation := farthestContinuation max: pc + inst arguments first].
				 [#jump:if:]					->	[farthestContinuation := farthestContinuation max: pc + inst arguments first].
				 [#methodReturnConstant:]	->	[pc >= farthestContinuation ifTrue: [end := pc]].
				 [#methodReturnReceiver]	->	[pc >= farthestContinuation ifTrue: [end := pc]].
				 [#methodReturnTop]		->	[pc >= farthestContinuation ifTrue: [end := pc]].
				"This is for CompiledBlock/FullBlockClosure.  Since the response to pushClosure... above
				 skips over all block bytecoes, we will only see a blockReturnTop if it is at the top level,
				 and so it must be a blockReturnTop in a CompiledBlock for a FullBlockClosure."
				 [#blockReturnTop]			->	[pc >= farthestContinuation ifTrue: [end := pc]].
				 [#branchIfInstanceOf:distance:]
											->	[farthestContinuation := farthestContinuation max: pc + inst arguments last].
				 [#branchIfNotInstanceOf:distance:]
											->	[farthestContinuation := farthestContinuation max: pc + inst arguments last] }
			otherwise: [].
		 pc := is pc - 1].
	^end
]

{ #category : #testing }
StackMTInterpreterSimulator >> ensureDebugAtEachStepBlock [
	atEachStepBlock := [printFrameAtEachStep ifTrue:
							[self printFrame: localFP WithSP: localSP].
						 printBytecodeAtEachStep ifTrue:
							[self printCurrentBytecodeOn: transcript.
							 transcript cr; flush].
						 byteCount = breakCount ifTrue:
							["printFrameAtEachStep :=" printBytecodeAtEachStep := true]]
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> externalDivorceFrame: theFP andContext: ctxt [
	"(theFP = -208 or: [ctxt = 22189568]) ifTrue:
		[self halt]."
	^super externalDivorceFrame: theFP andContext: ctxt
]

{ #category : #'frame access' }
StackMTInterpreterSimulator >> externalInstVar: index ofContext: aMarriedContext put: anOop [
	| imMarried shesMarried result |
	index == SenderIndex ifTrue:
		[imMarried := self checkIsStillMarriedContext: aMarriedContext currentFP: localFP.
		(objectMemory isContext: anOop) ifTrue:
			[shesMarried := self checkIsStillMarriedContext: anOop currentFP: localFP.
			 "self shortPrintContext: aMarriedContext.
			  self shortPrintContext: anOop"]].
	result := super externalInstVar: index ofContext: aMarriedContext put: anOop.
	imMarried ifNotNil:
		[self assert: imMarried == (self checkIsStillMarriedContext: aMarriedContext currentFP: nil).
		 shesMarried ifNotNil:
			[self assert: shesMarried == (self checkIsStillMarriedContext: anOop currentFP: nil)]].
	^result
]

{ #category : #'interpreter shell' }
StackMTInterpreterSimulator >> fetchByte [
	^objectMemory byteAt: (localIP := localIP + 1).
]

{ #category : #'control primitives' }
StackMTInterpreterSimulator >> filterPerformOf: selector to: receiver [
	"This is to allow simulator to filter start-up items to avoid as-yet unsimulatable plugins."
	performFilters ifNil: [^false].
	(performFilters at: (self shortPrint: receiver) ifAbsent: []) ifNotNil:
		[:messages|
		^messages includes: (self stringOf: selector)].
	^false
]

{ #category : #testing }
StackMTInterpreterSimulator >> findNewMethodInClassTag: classTag [
"
	| cName |
	traceOn ifTrue:
		[cName := (self sizeBitsOf: class) = 16r20
			ifTrue: ['class ' , (self nameOfClass: (self fetchPointer: 6 ofObject: class))]
			ifFalse: [(self nameOfClass: class)].
		self cr; print: cName , '>>' , (self stringOf: messageSelector)].
"
	messageSelector = (objectMemory splObj: SelectorDoesNotUnderstand) ifTrue: [self halt].

	sendCount := sendCount + 1.

	(printSends or: [printBytecodeAtEachStep]) ifTrue:
		[self cr; print: byteCount; space; printStringOf: messageSelector; cr].
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
StackMTInterpreterSimulator >> firstIndexableField: oop [
	"This is in ObjectMemory and overridden in the obj mem simulators"
	self shouldNotImplement
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> flush [
	traceOn ifTrue: [transcript flush]
]

{ #category : #'plugin support' }
StackMTInterpreterSimulator >> flushExternalPrimitives [
	self initializePluginEntries.
	super flushExternalPrimitives
]

{ #category : #'control primitives' }
StackMTInterpreterSimulator >> forShortPrintString: shortPrintString filterPerformMessages: aCollection [
	performFilters ifNil:
		[performFilters := Dictionary new].
	performFilters at: shortPrintString put: aCollection
]

{ #category : #'frame access' }
StackMTInterpreterSimulator >> frameOfMarriedContext: aContext [ 
	| senderOop |
	senderOop := objectMemory fetchPointer: SenderIndex ofObject: aContext.
	self assert: (objectMemory isIntegerObject: senderOop).
	^self withoutSmallIntegerTags: senderOop
]

{ #category : #'spur bootstrap' }
StackMTInterpreterSimulator >> framePointer [
	^framePointer
]

{ #category : #'I/O primitives' }
StackMTInterpreterSimulator >> fullDisplay [
	| primFailCodeValue |
	displayForm ifNil: [^self].
	primFailCodeValue := primFailCode.
	self initPrimCall.
	self updateDisplayLeft: 0 Top: 0 Right: displayWidth Bottom: displayHeight.
	primFailCode := primFailCodeValue
]

{ #category : #'debug support' }
StackMTInterpreterSimulator >> fullDisplayUpdate [
	"Preserve self successful when call asynchronously from Simulator"
	| primFailCodeValue |
	primFailCodeValue := primFailCode.
	self initPrimCall.
	super fullDisplayUpdate.
	primFailCode := primFailCodeValue
]

{ #category : #'interpreter shell' }
StackMTInterpreterSimulator >> functionPointerFor: primIndex inClass: lookupClass [
	"Override Interpreter to handle the external primitives caching.  See also
	 internalExecuteNewMethod."

	^(primIndex between: 1 and: MaxPrimitiveIndex)
		ifTrue: [primitiveTable at: primIndex + 1]
		ifFalse: [0]
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> getErrorObjectFromPrimFailCode [
	^super getErrorObjectFromPrimFailCode
]

{ #category : #'image save/restore' }
StackMTInterpreterSimulator >> getShortFromFile: aFile swap: swapFlag [
	| aShort |
	aShort := self nextShortFrom: aFile.
	^swapFlag 
		ifTrue: [(aShort bitShift: -8) + ((aShort bitAnd: 16rFF) bitShift: 8)]
		ifFalse: [aShort]
]

{ #category : #'memory access' }
StackMTInterpreterSimulator >> halfWordHighInLong32: long32 [
	^self subclassResponsibility
]

{ #category : #'memory access' }
StackMTInterpreterSimulator >> halfWordLowInLong32: long32 [
	^self subclassResponsibility
]

{ #category : #'I/O primitives support' }
StackMTInterpreterSimulator >> handleListenEvent: aMorphicEvent [
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

{ #category : #'debug support' }
StackMTInterpreterSimulator >> headerStart: oop [

	^ (objectMemory extraHeaderBytes: oop) negated
]

{ #category : #'image save/restore' }
StackMTInterpreterSimulator >> imageName [
	^imageName
]

{ #category : #'spur bootstrap' }
StackMTInterpreterSimulator >> imageName: aString [
	imageName := aString
]

{ #category : #'file primitives' }
StackMTInterpreterSimulator >> imageNameGet: p Length: sz [
	1 to: sz  do:
		[:i |
		objectMemory
			byteAt:  p + i - 1
			put: (imageName at: i) asInteger]
]

{ #category : #'file primitives' }
StackMTInterpreterSimulator >> imageNamePut: p Length: sz [
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
StackMTInterpreterSimulator >> imageNameSize [
	^imageName size
]

{ #category : #'interpreter shell' }
StackMTInterpreterSimulator >> incrementByteCount [
	(byteCount := byteCount + 1) = breakCount ifTrue:
		[self doOrDefer: [self changed: #byteCountText].
		 self halt: 'breakCount reached'].
	byteCount \\ 1000 = 0 ifTrue:
		[self doOrDefer: [self changed: #byteCountText].
		 self forceInterruptCheck]
]

{ #category : #initialization }
StackMTInterpreterSimulator >> initialize [
	"Initialize the StackInterpreterSimulator when running the interpreter
	 inside Smalltalk. The primary responsibility of this method is to allocate
	 Smalltalk Arrays for variables that will be declared as statically-allocated
	 global arrays in the translated code."
	super initialize.

	bootstrapping := false.
	transcript := Transcript.

	objectMemory ifNil:
		[objectMemory := self class objectMemoryClass simulatorClass new].
	objectMemory coInterpreter: self.

	self assert: ConstMinusOne = (objectMemory integerObjectOf: -1).

	methodCache := Array new: MethodCacheSize.
	atCache := Array new: AtCacheTotalSize.
	self flushMethodCache.
	gcSemaphoreIndex := 0.
	externalSemaphoreSignalRequests := externalSemaphoreSignalResponses := #().
	externalPrimitiveTable := CArrayAccessor on: (Array
		new: MaxExternalPrimitiveTableSize
		withAll: 0).
	externalPrimitiveTableFirstFreeIndex := 0.
	primitiveTable := self class primitiveTable copy.
	self initializePluginEntries.
	desiredNumStackPages := desiredEdenBytes := 0.
	"This is initialized on loading the image, but convenient for testing stack page values..."
	numStackPages := self defaultNumStackPages. 
	startMicroseconds := lastYieldMicroseconds := self ioUTCStartMicroseconds.

	"initialize InterpreterSimulator variables used for debugging"
	byteCount := sendCount := lookupCount := 0.
	quitBlock := [^self close].
	traceOn := true.
	printSends := printReturns := printFrameAtEachStep := printBytecodeAtEachStep := false.
	myBitBlt := BitBltSimulator new setInterpreter: self.
	displayForm := fakeForm := 'Display has not yet been installed' asDisplayText form.
	eventQueue := SharedQueue new.
	suppressHeartbeatFlag := false.
	systemAttributes := Dictionary new.
	extSemTabSize := 256.
	disableBooleanCheat := false.
	assertVEPAES := false. "a flag so the assertValidExecutionPointers can be disabled for simulation speed and enabled when necessary."
]

{ #category : #'plugin support' }
StackMTInterpreterSimulator >> initializePluginEntries [
	mappedPluginEntries := OrderedCollection new.
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[primitiveAccessorDepthTable := Array new: primitiveTable size.
			 pluginList := {}.
			 self loadNewPlugin: '']
		ifFalse:
			[pluginList := {'' -> self }]
]

{ #category : #'frame access' }
StackMTInterpreterSimulator >> instVar: index ofContext: aMarriedContext put: anOop [
	| imMarried shesMarried result |
	index == SenderIndex ifTrue:
		[imMarried := self checkIsStillMarriedContext: aMarriedContext currentFP: localFP.
		(objectMemory isContext: anOop) ifTrue:
			[shesMarried := self checkIsStillMarriedContext: anOop currentFP: localFP.
			"self cr.
			self shortPrintContext: aMarriedContext.
			self shortPrintContext: anOop.
			(#('yield:' 'nextPut:') includesAnyOf: {self stringOf: (self selectorOfContext: aMarriedContext). self stringOf: (self selectorOfContext: anOop)}) ifTrue:
				[self halt]"]].
	result := super instVar: index ofContext: aMarriedContext put: anOop.
	imMarried ifNotNil:
		[self assert: imMarried == (self checkIsStillMarriedContext: aMarriedContext currentFP: nil).
		 shesMarried ifNotNil:
			[self assert: shesMarried == (self checkIsStillMarriedContext: anOop currentFP: nil)]].
	^result
]

{ #category : #'interpreter shell' }
StackMTInterpreterSimulator >> insufficientMemoryAvailableError [
	self error: 'Failed to allocate memory for the heap'
]

{ #category : #'interpreter shell' }
StackMTInterpreterSimulator >> insufficientMemorySpecifiedError [
	self error: 'Insufficient memory for this image'
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> internalCannotReturn: resultOop [
	self halt.
	^super internalCannotReturn: resultOop
]

{ #category : #testing }
StackMTInterpreterSimulator >> internalFindNewMethodOrdinary [
	sendCount := sendCount + 1.
	super internalFindNewMethodOrdinary
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> internalMustBeBoolean [
	self halt.
	^super internalMustBeBoolean
]

{ #category : #'interpreter shell' }
StackMTInterpreterSimulator >> interpret [
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
StackMTInterpreterSimulator >> interpreterAllocationReserveBytes [
	^bootstrapping
		ifTrue: [0]
		ifFalse: [super interpreterAllocationReserveBytes]
]

{ #category : #'interpreter shell' }
StackMTInterpreterSimulator >> invalidCompactClassError: name [
	self error: 'Class ', name, ' does not have the required compact class index'
]

{ #category : #'I/O primitives' }
StackMTInterpreterSimulator >> ioBeDisplay: bitsOrHandleCArray width: width height: height depth: depth [
	"The real platform may want to note the location of the display and respond to the fact of
	 its installation.  Here merely create a scratch form the same size as Smalltalk displayObj"
	super ioBeDisplay: bitsOrHandleCArray asInteger width: width height: height depth: depth.
	displayForm := Form extent: width @ height depth: depth.
	displayView ifNotNil: [displayView image: displayForm]
]

{ #category : #security }
StackMTInterpreterSimulator >> ioCanRenameImage [
	^true
]

{ #category : #security }
StackMTInterpreterSimulator >> ioCanWriteImage [
	^true
]

{ #category : #'primitive support' }
StackMTInterpreterSimulator >> ioExit [

	quitBlock value  "Cause return from #test"
]

{ #category : #'primitive support' }
StackMTInterpreterSimulator >> ioExitWithErrorCode: ec [

	quitBlock value  "Cause return from #test"
]

{ #category : #'process primitive support' }
StackMTInterpreterSimulator >> ioGetMaxExtSemTableSize [
	^extSemTabSize
]

{ #category : #'I/O primitives' }
StackMTInterpreterSimulator >> ioGetNextEvent: evtBuf [
	| evt |
	"SimulatorMorphicModel browse"
	eventQueue ifNil:
		[^self primitiveFail].
	eventQueue isEmpty ifFalse:
		[evt :=  eventQueue next.
		 1 to: evtBuf size do:
			[:i| (evt at: i) ifNotNil: [:val| evtBuf at: (i - 1) put: val asInteger]]]
]

{ #category : #'I/O primitives' }
StackMTInterpreterSimulator >> ioHasDisplayDepth: depth [
	^Display supportsDisplayDepth: depth
]

{ #category : #'I/O primitives support' }
StackMTInterpreterSimulator >> ioHeartbeatMilliseconds [
	^1
]

{ #category : #initialization }
StackMTInterpreterSimulator >> ioInitHeartbeat [
	"No-op in the simulator.  We cause a poll every 1000 bytecodes instead."
]

{ #category : #'plugin support' }
StackMTInterpreterSimulator >> ioLoadFunction: functionString From: pluginString [
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
	mappedPluginEntries addLast: { plugin. fnSymbol }.
	transcript show: ' ... okay'.
	^mappedPluginEntries size
]

{ #category : #'plugin support' }
StackMTInterpreterSimulator >> ioLoadFunction: functionString From: pluginString AccessorDepthInto: accessorDepthPtr [
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
		[firstTime ifTrue: [transcript show: '... FAILED; no plugin found'].
		 ^0].
	plugin := plugin value.
	mappedPluginEntries withIndexDo:
		[:pluginAndName :index|
		 ((pluginAndName at: 1) == plugin 
		  and:[(pluginAndName at: 2) == fnSymbol]) ifTrue:
			[firstTime ifTrue: [transcript show: ' ... okay'].
			 accessorDepthPtr at: 0 put: (pluginAndName at: 4).
			 ^index]].
	firstTime ifTrue: [transcript show: '... FAILED; primitive not in plugin'].
	^0
]

{ #category : #'I/O primitives support' }
StackMTInterpreterSimulator >> ioMSecs [
	"Return the value of the millisecond clock."
	"NOT.  Actually, we want something a lot slower and, for exact debugging,
	something more repeatable than real time.  I have an idea: use the byteCount... (di 7/1/2004 13:55)"

	^self microsecondsToMilliseconds: self ioUTCMicroseconds
	
"At 20k bytecodes per second, this gives us about 200 ticks per second, or about 1/5 of what you'd expect for the real time clock.  This should still service events at one or two per second"
]

{ #category : #'I/O primitives support' }
StackMTInterpreterSimulator >> ioMicroMSecs [
	"Answer the value of the high-resolution millisecond clock."

	^ Time millisecondClockValue

]

{ #category : #'I/O primitives' }
StackMTInterpreterSimulator >> ioMousePoint [
	| relPt |
	^displayForm
		ifNil: [99 << 16 + 66]
		ifNotNil: [relPt := Sensor cursorPoint - self displayLocation.
				relPt x << 16 + relPt y]
]

{ #category : #'I/O primitives' }
StackMTInterpreterSimulator >> ioProcessEvents [
]

{ #category : #'I/O primitives support' }
StackMTInterpreterSimulator >> ioRelinquishProcessorForMicroseconds: microseconds [
	"In the simulator give an indication that we're idling and check for input."
	Display reverse: ((displayView
						ifNil: [0@0]
						ifNotNil: [displayView bounds origin]) extent: 16@16).
	Sensor peekEvent ifNotNil:
		[self forceInterruptCheck].
	Processor activeProcess == UIManager default uiProcess ifTrue:
		[World doOneCycle].
	microseconds >= 1000
		ifTrue: [(Delay forMilliseconds: microseconds + 999 // 1000) wait]
		ifFalse: [Processor yield].
	"And increase the byteCount form which the microsecond clock is derived..."
	byteCount := byteCount + microseconds - 1.
	self incrementByteCount
]

{ #category : #'I/O primitives' }
StackMTInterpreterSimulator >> ioScreenDepth [
	^DisplayScreen actualScreenDepth.
]

{ #category : #'I/O primitives support' }
StackMTInterpreterSimulator >> ioScreenScaleFactor [
	^ 1.0
]

{ #category : #'I/O primitives support' }
StackMTInterpreterSimulator >> ioScreenSize [
	"Answer the screen extent packed into 32 bits.  In the simulator,
	 displayForm gets initialized with a fake form; don't be deceived."
	| extent |
	extent := (displayForm notNil and: [displayForm ~~ fakeForm])
				ifTrue: [displayForm extent]
				ifFalse: [self desiredDisplayExtent].
	^extent x << 16 + extent y
]

{ #category : #'I/O primitives' }
StackMTInterpreterSimulator >> ioSetInputSemaphore: index [

	self primitiveFail
]

{ #category : #'process primitive support' }
StackMTInterpreterSimulator >> ioSetMaxExtSemTableSize: anInteger [
	"Inform the VM of the maximum size the image will grow the exernal semaphore table (specialObjectsArray at: 39) to.
	 This allows the VM to allocate storage such that external semaphores can be signalled without locking."
	extSemTabSize := anInteger
]

{ #category : #'I/O primitives' }
StackMTInterpreterSimulator >> ioShow: destBits D: w i: h s: d p: left l: right a: top y: bottom [
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
StackMTInterpreterSimulator >> ioSynchronousCheckForEvents [
	"Hook allowing the platform to do anything it needs to do synchronously."
]

{ #category : #'I/O primitives support' }
StackMTInterpreterSimulator >> ioUTCMicroseconds [
	"Return the value of the microsecond clock."
	"NOT.  Actually, we want something a lot slower and, for exact debugging,
	something more repeatable than real time.  Dan had an idea: use the byteCount..."

	^(byteCount // 50) + startMicroseconds
]

{ #category : #'I/O primitives support' }
StackMTInterpreterSimulator >> ioUTCStartMicroseconds [
	"Answer the value of the microsecond clock at startup."

	^startMicroseconds ifNil:
		[self class initializationOptions
			at: #startMicroseconds
			ifAbsent: [[Time utcMicrosecondClock] on: Error do: [Time totalSeconds * 1000000]]]
]

{ #category : #'primitive support' }
StackMTInterpreterSimulator >> isPrimitiveFunctionPointerAnIndex [
	"We save slots in the method cache by using the primitiveFunctionPointer
	 to hold either a function pointer or the index of a quick primitive. Since
	 quick primitive indices are small they can't be confused with function
	 addresses.  But since we use 1001 and up for external primitives that
	 would be functions in the C VM but are indices under simulation we treat
	 values above 1000 as if they were pointers (actually indices into the
	 externalPrimitiveTable)"

	^primitiveFunctionPointer isInteger
	  and: [primitiveFunctionPointer ~= 0
	  and: [primitiveFunctionPointer <= MaxQuickPrimitiveIndex]]
]

{ #category : #testing }
StackMTInterpreterSimulator >> isThreadedVM [
	^false
]

{ #category : #'frame access' }
StackMTInterpreterSimulator >> isWidowedContext: aOnceMarriedContext [
	"See if the argument is connected with a live frame or not.
	 If it is not, turn it into a bereaved single context."
	(stackPages isFree: stackPage) ifFalse: "in baseReturn the active page has been freed."
		[((stackPages somePageHasHeadFrameFP: framePointer)
		  or: [(stackPages somePageHasHeadFrameFP: localFP)
		  or: [stackPages allPagesFree]]) ifFalse:
			[thisContext sender sender method = (StackInterpreter >> #baseFrameReturn) ifFalse:
				["self halt: 'currentFP may not be written back to stack page'"]]].
	^super isWidowedContext: aOnceMarriedContext
]

{ #category : #'compiled methods' }
StackMTInterpreterSimulator >> literal: offset [
	"trap pushes of forwarded literals to help debug following forwarded primitive args.
	 it is not an error to push a forwarded literal, but we'd like to step through any resulting
	 primtive failure code"
	| lit |
	lit := super literal: offset.
	(objectMemory isOopForwarded: lit) ifTrue:
		[self halt: 'forwarded literal in ', thisContext selector].
	^lit
]

{ #category : #'plugin support' }
StackMTInterpreterSimulator >> loadNewPlugin: pluginString [
	breakSelector ifNotNil:
		[(self strncmp: pluginString _: breakSelector _: pluginString size) = 0 ifTrue:
			[self halt: pluginString]].
	^(self tryLoadNewPlugin: pluginString pluginEntries: mappedPluginEntries) ifNotNil:
		[:entry|
		 pluginList := pluginList copyWith: entry.
		 entry]
]

{ #category : #'spur bootstrap' }
StackMTInterpreterSimulator >> localFP [
	^localFP
]

{ #category : #'spur bootstrap' }
StackMTInterpreterSimulator >> localIP [
	^localIP
]

{ #category : #'spur bootstrap' }
StackMTInterpreterSimulator >> localIP: pc [
	localIP := pc
]

{ #category : #'spur bootstrap' }
StackMTInterpreterSimulator >> localSP [
	^localSP
]

{ #category : #testing }
StackMTInterpreterSimulator >> logOfBytesVerify: nBytes fromFileNamed: fileName fromStart: loggingStart [
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
StackMTInterpreterSimulator >> logOfBytesWrite: nBytes toFileNamed: fileName fromStart: loggingStart [
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
StackMTInterpreterSimulator >> logOfSendsVerify: nSends fromFileNamed: fileName fromStart: loggingStart [
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
StackMTInterpreterSimulator >> logOfSendsWrite: nSends toFileNamed: fileName fromStart: loggingStart [
	"Write a log file for testing a flaky interpreter on the same image"
	"self logOfSendsWrite: 10000 toFileNamed: 'clone32Messages.log' "
	
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
		localFP = priorFrame ifFalse:
			[sendCount >= loggingStart ifTrue:
				[sendCount := sendCount + 1.
				logFile nextPutAll: (self stringOf: messageSelector); cr].
			priorFrame := localFP].
		self incrementByteCount].
	self externalizeIPandSP.
	logFile close
]

{ #category : #'memory access' }
StackMTInterpreterSimulator >> longAt: byteAddress [
	self deprecated.
	^objectMemory longAt: byteAddress
]

{ #category : #'memory access' }
StackMTInterpreterSimulator >> longAt: byteAddress put: a32BitValue [
	self deprecated.
	^objectMemory longAt: byteAddress put: a32BitValue
]

{ #category : #'message sending' }
StackMTInterpreterSimulator >> lookupMethodInClass: class [
	lookupCount := lookupCount + 1.
	^super lookupMethodInClass: class
]

{ #category : #'callback support' }
StackMTInterpreterSimulator >> lookupOrdinaryNoMNUEtcInClass: class [
	lookupCount := lookupCount + 1.
	^super lookupOrdinaryNoMNUEtcInClass: class
]

{ #category : #'plugin support' }
StackMTInterpreterSimulator >> mappedPluginEntries [
	^mappedPluginEntries
]

{ #category : #'frame access' }
StackMTInterpreterSimulator >> markContextAsDead: oop [
	"(self withoutSmallIntegerTags: (objectMemory fetchPointer: SenderIndex ofObject: oop)) = -16r26824 ifTrue:
		[self halt]."
	^super markContextAsDead: oop
]

{ #category : #'spur bootstrap' }
StackMTInterpreterSimulator >> messageSelector: s [
	"For e.g. SpurBootstrap"
	messageSelector := s
]

{ #category : #'simulation only' }
StackMTInterpreterSimulator >> methodForContext: aContextOop [
	self assert: (objectMemory isContext: aContextOop).
	^objectMemory fetchPointer: MethodIndex ofObject: aContextOop
]

{ #category : #'debug support' }
StackMTInterpreterSimulator >> nameOfClass: classOop [
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
StackMTInterpreterSimulator >> nextShortFrom: aStream [
	"Read a 16-bit quantity from the given (binary) stream."
	^self subclassResponsibility
]

{ #category : #accessing }
StackMTInterpreterSimulator >> noThreadingOfGUIThread: aBoolean [
	<doNotGenerate>
	
	noThreadingOfGUIThread := aBoolean
]

{ #category : #UI }
StackMTInterpreterSimulator >> openAsMorph [
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
								+ (2 * borderWidth@borderWidth)
								+ (0@window labelHeight)
								* (1@(1/0.8))) rounded.
	^window
]

{ #category : #UI }
StackMTInterpreterSimulator >> openAsMorphNoTranscript [
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

{ #category : #UI }
StackMTInterpreterSimulator >> openAsSimulatorMorph [
	"Open a morphic view on this simulation. ala Bert Freudenberg's
	SqueakJS http://lively-web.org/users/bert/squeak.html	"
	| localImageName borderWidth window |
	localImageName := imageName
							ifNil: [' synthetic image']
							ifNotNil: [self localNameFor: imageName].

	transcript := TranscriptStream on: (String new: 10000).

	window := SimulatorMorph	
					withVMSimulator: self 
					title: 'Simulation of ' , localImageName, ' (beta)'
					transcript: transcript.				

	borderWidth := [SimulatorMorph borderWidth] "Squeak 4.1"
						on: MessageNotUnderstood
						do: [:ex | 0].
	"3.8"
	borderWidth := borderWidth + window borderWidth.
	window openInWorldExtent: (self desiredDisplayExtent + (2 * borderWidth) + (0 @ window labelHeight) * (1 @ (1 / 0.8))) rounded.
	^window
]

{ #category : #initialization }
StackMTInterpreterSimulator >> openOn: fileName extraMemory: extraBytes [
	"StackInterpreterSimulator new openOn: 'clone.im' extraMemory: 100000"

	| f version headerSize dataSize count oldBaseAddr bytesToShift swapBytes
	  headerFlags heapBase firstSegSize heapSize
	  hdrNumStackPages hdrEdenBytes hdrMaxExtSemTabSize allocationReserve |
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
		ifFalse: [(version := objectMemory byteSwapped: version) = self imageFormatVersion
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
	"pad to word boundary.  This slot can be used for anything else that will fit in 16 bits.
	 It is used for the cog code size in Cog.  Preserve it to be polite to other VMs."
	theUnknownShort	:= self getShortFromFile: f swap: swapBytes.
	self assert: f position = (objectMemory wordSize = 4 ifTrue: [40] ifFalse: [64]).
	hdrEdenBytes		:= self getWord32FromFile: f swap: swapBytes.
	objectMemory edenBytes: (hdrEdenBytes = 0
							ifTrue: [objectMemory defaultEdenBytes]
							ifFalse: [hdrEdenBytes]).
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
	"allocate interpreter memory"
	heapBase := objectMemory startOfMemory.
	objectMemory
		setHeapBase: heapBase
		memoryLimit: heapBase + heapSize
		endOfMemory: heapBase + dataSize. "bogus for Spur"
	objectMemory allocateMemoryOfSize: objectMemory memoryLimit.
	"read in the image in bulk, then swap the bytes if necessary"
	f position: headerSize.
	count := objectMemory readHeapFromImageFile: f dataBytes: dataSize.
	count ~= dataSize ifTrue: [self halt]]
		ensure: [f close].

	self ensureImageFormatIsUpToDate: swapBytes.

	bytesToShift := objectMemory memoryBaseForImageRead - oldBaseAddr.  "adjust pointers for zero base address"
	UIManager default
		informUser: 'Relocating object pointers...'
		during: [self initializeInterpreter: bytesToShift]
]

{ #category : #accessing }
StackMTInterpreterSimulator >> parent [

	^ parent
]

{ #category : #accessing }
StackMTInterpreterSimulator >> parent: anObject [

	parent := anObject
]

{ #category : #'plugin support' }
StackMTInterpreterSimulator >> pluginEntryFor: mapIndex [
	^mappedPluginEntries at: (mapIndex > 1000
								ifTrue: [externalPrimitiveTable at: mapIndex - 1001]
								ifFalse: [mapIndex])
]

{ #category : #'object memory support' }
StackMTInterpreterSimulator >> preBecomeAction [
	"((objectMemory instVarNamed: 'becomeEffectsFlags') anyMask: BecameCompiledMethodFlag) ifTrue:
		[self halt]."
	super preBecomeAction
]

{ #category : #'other primitives' }
StackMTInterpreterSimulator >> primStringcomparewithcollated [
	^ self primitiveFail
]

{ #category : #'other primitives' }
StackMTInterpreterSimulator >> primStringfindSubstringinstartingAtmatchTable [
	^self primitiveFail
]

{ #category : #'other primitives' }
StackMTInterpreterSimulator >> primStringindexOfAsciiinStringstartingAt [
	^ self primitiveFail
]

{ #category : #'other primitives' }
StackMTInterpreterSimulator >> primStringtranslatefromtotable [
	^ self primitiveFail
]

{ #category : #'indexing primitives' }
StackMTInterpreterSimulator >> primitiveAtPut [
	"16r1510B8 = (self stackValue: 2) ifTrue:
		[self halt]."
	^super primitiveAtPut
]

{ #category : #'other primitives' }
StackMTInterpreterSimulator >> primitiveBeep [

	Beeper beep.
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> primitiveContextAt [
	"self halt."
	^super primitiveContextAt
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> primitiveDoPrimitiveWithArgs [
	self halt.
	^super primitiveDoPrimitiveWithArgs
]

{ #category : #'control primitives' }
StackMTInterpreterSimulator >> primitiveExecuteMethod [
	self halt: thisContext selector.
	^super primitiveExecuteMethod
]

{ #category : #'control primitives' }
StackMTInterpreterSimulator >> primitiveExecuteMethodArgsArray [
	self halt: thisContext selector.
	"(objectMemory isOopCompiledMethod: self stackTop) ifFalse:
		[self halt]."
	^super primitiveExecuteMethodArgsArray
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> primitiveFailFor: reasonCode [
	"self halt."
	^super primitiveFailFor: reasonCode
]

{ #category : #'other primitives' }
StackMTInterpreterSimulator >> primitiveGetAttribute [
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

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> primitiveIdentityHash [
	"| oop |
	oop := self stackTop.
	((objectMemory isBytes: oop)
	and: [(objectMemory lengthOf: oop) = 'smallSelect' size
	and: [(self stringOf: oop) = 'smallSelect']]) ifTrue:
		[self halt]."
	^super primitiveIdentityHash
]

{ #category : #'I/O primitives' }
StackMTInterpreterSimulator >> primitiveKbdNext [

	self pop: 1.
	Sensor keyboardPressed
		ifTrue: [self pushInteger: Sensor primKbdNext]
		ifFalse: [self push: objectMemory nilObject]
]

{ #category : #'I/O primitives' }
StackMTInterpreterSimulator >> primitiveKbdPeek [

	self pop: 1.
	Sensor keyboardPressed
		ifTrue: [self pushInteger: Sensor primKbdPeek]
		ifFalse: [self push: objectMemory nilObject]
]

{ #category : #'I/O primitives' }
StackMTInterpreterSimulator >> primitiveMouseButtons [
	| buttons |
	self pop: 1.
	buttons := Sensor primMouseButtons.
	self pushInteger: buttons
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> primitiveNewWithArg [
	"(objectMemory hasSpurMemoryManagerAPI
	 and: [self classNameOf: (self stackValue: 1) Is: 'MethodDictionary']) ifTrue:
		[self halt]."
	"| hash |
	hash := objectMemory rawHashBitsOf: (self stackValue: 1)."
	"| format |
	format := objectMemory instSpecOfClass: (self stackValue: 1)."
	"(objectMemory numSlotsOf: (self stackValue: 1)) = 3 ifTrue:
		[self halt]."
	super primitiveNewWithArg.
	"self successful ifTrue:
		[(Smalltalk at: #Counts ifAbsentPut: [Bag new]) add: format]."
	"(self successful and: [objectMemory hasSpurMemoryManagerAPI]) ifTrue:
		[(Smalltalk at: #Counts ifAbsentPut: [Bag new]) add: hash]"
	"Smalltalk removeKey: #Counts"
	"Counts sortedCounts collect: [:assoc|
		assoc key -> ((SpurMemoryManager organization listAtCategoryNamed: #'header formats') detect:
										[:f| (SpurMemoryManager basicNew perform: f) = assoc value])]
		{3251->#arrayFormat.
		 1685->#firstByteFormat.
		 1533->#firstLongFormat.
		 110->#weakArrayFormat.
		 35->#indexablePointersFormat.
		 5->#nonIndexablePointerFormat}"
	"Counts sortedCounts collect: [:assoc|
		assoc value = 0
			ifTrue: [assoc]
			ifFalse: [assoc key -> {(self nameOfClass: (objectMemory classAtIndex: assoc value)).
									(SpurMemoryManager organization listAtCategoryNamed: #'header formats') detect:
										[:f| (objectMemory perform: f)
											= (objectMemory instSpecOfClass: (objectMemory classAtIndex: assoc value))]}]]
	{1062->#('Array' #arrayFormat).
	 777->#('Bitmap' #firstLongFormat).
	 395->#('Float' #firstLongFormat).
	 345->#('ByteString' #firstByteFormat).
	 237->#('MatrixTransform2x3' #firstLongFormat).
	 233->#('LargePositiveInteger' #firstByteFormat).
	 103->#('WordArray' #firstLongFormat).
	 58->#('WeakArray' #weakArrayFormat).
	 52->#('WeakMessageSend' #weakArrayFormat).
	 9->#('MethodContext' #indexablePointersFormat).
	 4->#('DirectoryEntry' #nonIndexablePointerFormat).
	 3->#('BalloonBuffer' #firstLongFormat).
	 1->#('ByteArray' #firstByteFormat).
	 1->0}"
]

{ #category : #'control primitives' }
StackMTInterpreterSimulator >> primitiveObject: actualReceiver perform: selector withArguments: argumentArray lookedUpIn: lookupClass [
	"Override to allow simulator to filter start-up items to avoid as-yet unsimulatable plugins."

	(self filterPerformOf: selector to: actualReceiver) ifTrue:
		[^self pop: argumentCount + 1 thenPush: actualReceiver].
	^super primitiveObject: actualReceiver perform: selector withArguments: argumentArray lookedUpIn: lookupClass
]

{ #category : #'object access primitives' }
StackMTInterpreterSimulator >> primitiveObjectPointsTo [
	"self halt."
	^super primitiveObjectPointsTo
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> primitivePerform [
	| selector |
	selector := self stackValue: argumentCount - 1.
	self sendBreakpoint: selector receiver: (self stackValue: argumentCount).
	(self filterPerformOf: selector to: (self stackValue: argumentCount)) ifTrue:
		[^self pop: argumentCount].
	^super primitivePerform
]

{ #category : #'object access primitives' }
StackMTInterpreterSimulator >> primitiveStoreStackp [
	"self printContext: (self stackValue: 1).
	self halt."
	super primitiveStoreStackp.
	"self printContext: self stackTop"
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> primitiveSuspend [
	"Catch errors before we start the whole morphic error process"

	"byteCount > 1000000 ifTrue: [self halt]."  "Ignore early process activity"
	^ super primitiveSuspend
]

{ #category : #'system control primitives' }
StackMTInterpreterSimulator >> primitiveVMParameter [
	(self stackTop = (objectMemory integerObjectOf: 9)
	 or: [self stackTop = (objectMemory integerObjectOf: 52)]) ifTrue:
		[self halt].
	^super primitiveVMParameter
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> print: it [

	traceOn ifTrue:
		[it isString ifTrue: [transcript nextPutAll: it] ifFalse: [it printOn: transcript]]
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> printChar: aByte [

	traceOn ifTrue: [ transcript nextPut: aByte asCharacter ].
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> printCurrentBytecodeOn: aStream [
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
StackMTInterpreterSimulator >> printECS [
	self printCallStackFP: framePointer
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> printFrameFlagsForFP: theFP [
	| address it |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #address type: #'char *'>
	address := theFP + FoxFrameFlags.
	it := stackPages longAt: address.
	self printHex: address;
		printChar: $/;
		printNum: (stackPages memIndexFor: address);
		print: ':       flags: ';
		printHex: it.
	it ~= 0 ifTrue:
		[self printChar: $=; printNum: it].
	self print: '  numArgs: '; printNum: (self frameNumArgs: theFP);
		print: '  hasContext: '; printNum: (self frameHasContext: theFP);
		print: '  isBlock: '; printNum: (self frameIsBlockActivation: theFP);
		cr
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> printFrameOop: name at: address [
	| it |
	<inline: false>
	<var: #name type: #'char *'>
	<var: #address type: #'char *'>
	it := stackPages longAt: address.
	self printHex: address;
		printChar: $/;
		printNum: (stackPages memIndexFor: address);
		printChar: $:.
	1 to: 12 - (self strlen: name) do: [:i| self printChar: $ ].
	self print: name;
		print: ': ';
		printHex: it.
	self tab;
		print: (self shortPrint: it);
		cr
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> printFrameThing: name andFrame: theFP at: address [
	<var: #theFP type: #'char *'>
	| it |
	<inline: false>
	<var: #name type: #'char *'>
	<var: #address type: #'char *'>
	it := stackPages longAt: address.
	self printHex: address;
		printChar: $/;
		printNum: (stackPages memIndexFor: address);
		printChar: $:.
	1 to: 12 - (self strlen: name) do: [:i| self printChar: $ ].
	self print: name;
		print: ': ';
		printHex: it.
	it ~= 0 ifTrue:
		[self printChar: $=; printNum: it].
	self print: ' frame: '; printHex: theFP; cr
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> printFrameThing: name at: address [
	| it |
	<inline: false>
	<var: #name type: #'char *'>
	<var: #address type: #'char *'>
	it := stackPages longAt: address.
	self printHex: address;
		printChar: $/;
		printNum: (stackPages memIndexFor: address);
		printChar: $:.
	1 to: 12 - (self strlen: name) do: [:i| self printChar: $ ].
	self print: name;
		print: ': ';
		printHex: it.
	it ~= 0 ifTrue:
		[self printChar: $=; printNum: it].
	self cr
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> printHex: anInteger [

	traceOn ifTrue:
		[| it16 |
		 it16 := anInteger radix: 16.
		 transcript
			next: 8 - it16 size put: Character space;
			nextPutAll: (anInteger storeStringBase: 16)]
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> printHexnp: anInteger [

	traceOn ifTrue:
		[transcript nextPutAll: ((anInteger ifNil: [0]) storeStringBase: 16)]
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> printHexnpnp: anInteger [
	"Print n in hex, in the form '1234', unpadded"
	traceOn ifTrue:
		[transcript nextPutAll: ((anInteger ifNil: [0]) printStringBase: 16)]
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> printLCS [
	self printCallStackFP: localFP
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> printNum: anInteger [

	traceOn ifTrue: [ transcript print: anInteger ].
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> printSends [
	^printSends or: [printBytecodeAtEachStep]
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> printSends: aBoolean [
	printSends := aBoolean
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> printStringForCurrentBytecode [
	^String streamContents: [:str| self printCurrentBytecodeOn: str]
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> printStringOf: oop [

	super printStringOf: oop.
	traceOn ifTrue: [transcript flush]
]

{ #category : #accessing }
StackMTInterpreterSimulator >> processHasThreadId: aBoolean [
	<doNotGenerate>
	processHasThreadId := aBoolean
]

{ #category : #testing }
StackMTInterpreterSimulator >> profile: nBytecodes [
	"(InterpreterSimulator new openOn: 'clonex.image') profile: 60000"
	transcript clear.
	byteCount := 0.
	MessageTally spyOn: [self runForNBytes: nBytecodes].
	self close
]

{ #category : #testing }
StackMTInterpreterSimulator >> profileSends: nBytecodes [
	"(InterpreterSimulator new openOn: 'clonex.image') profileSends: 5000"
	MessageTally tallySendsTo: self
		inBlock: [self runForNBytes: nBytecodes]
		showTree: true.
	self close
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> pushMaybeContextReceiverVariable: index [
	"(index = SenderIndex or: [index = ClosureIndex]) ifTrue: [self halt]."
	^super pushMaybeContextReceiverVariable: index
]

{ #category : #'I/O primitives support' }
StackMTInterpreterSimulator >> queueForwardedEvent: event [
	eventQueue ifNil:
		[eventQueue := SharedQueue new].
	eventQueue nextPut: event
]

{ #category : #'debug support' }
StackMTInterpreterSimulator >> redirectTranscriptToHost [
	"Sometimes you need the capability to see the transcript output of the image into the 
	 local transcript (for debugging when bootstrapping, for example). "
	transcript := Transcript
]

{ #category : #'image save/restore' }
StackMTInterpreterSimulator >> reverseBytesInImage [
	UIManager default
		informUser: 'Swapping bytes of foreign image...'
		during: [super reverseBytesInImage]
]

{ #category : #'method lookup cache' }
StackMTInterpreterSimulator >> rewriteMethodCacheEntryForExternalPrimitiveToFunction: localPrimAddress [
	self assert: (localPrimAddress isSymbol
			or: [localPrimAddress isInteger
				and: [localPrimAddress = 0
					or: [(localPrimAddress between: 256 and: 519)
					or: [localPrimAddress > 1000]]]]).
	^super rewriteMethodCacheEntryForExternalPrimitiveToFunction: localPrimAddress
]

{ #category : #testing }
StackMTInterpreterSimulator >> run [
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
	self initialEnterSmalltalkExecutive.
	localIP := localIP - 1.
	"undo the pre-increment of IP before returning"
	self externalizeIPandSP
]

{ #category : #testing }
StackMTInterpreterSimulator >> runAtEachStep: aBlock [
	self initStackPages.
	self loadInitialContext.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue:
		[self assertValidExecutionPointers.
		 aBlock value: currentBytecode.
		 self dispatchOn: currentBytecode in: BytecodeTable.
		 self incrementByteCount].
	localIP := localIP - 1.
	"undo the pre-increment of IP before returning"
	self externalizeIPandSP
]

{ #category : #testing }
StackMTInterpreterSimulator >> runAtEachStep: aBlock breakCount: breakCount [
	self initStackPages.
	self loadInitialContext.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue:
		[self assertValidExecutionPointers.
		 aBlock value: currentBytecode.
		 self dispatchOn: currentBytecode in: BytecodeTable.
		 self incrementByteCount.
		 byteCount = breakCount ifTrue:
			[self halt]].
	localIP := localIP - 1.
	"undo the pre-increment of IP before returning"
	self externalizeIPandSP
]

{ #category : #testing }
StackMTInterpreterSimulator >> runForNBytes: nBytecodes [ 
	"Do nByteCodes more bytecode dispatches.
	Keep byteCount up to date.
	This can be run repeatedly."
	| endCount |
	self initStackPages.
	self loadInitialContext.
	endCount := byteCount + nBytecodes.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[byteCount < endCount] whileTrue:
		[self dispatchOn: currentBytecode in: BytecodeTable.
		 self incrementByteCount].
	localIP := localIP - 1.
	"undo the pre-increment of IP before returning"
	self externalizeIPandSP
]

{ #category : #'I/O primitives' }
StackMTInterpreterSimulator >> savedWindowSize [
	^savedWindowSize ifNil: [0]
]

{ #category : #accessing }
StackMTInterpreterSimulator >> setBreakCount: anInteger [
	breakCount := anInteger
]

{ #category : #UI }
StackMTInterpreterSimulator >> setClickStepBreakBlock [
	"Set the break block to present a confirmer, breaking if true, and restoring the previous break block.
	 If an open debugger on the receiver can be found, proceed it."
	<doNotGenerate>
	| previousAtEachStepBlock |
	(atEachStepBlock isNil or: [atEachStepBlock method ~~ thisContext method]) ifTrue:
		[previousAtEachStepBlock := atEachStepBlock.
		 atEachStepBlock :=
							[previousAtEachStepBlock value.
							 self changed: #byteCountText.
							 (UIManager confirm: 'step?') ifFalse:
								[atEachStepBlock := previousAtEachStepBlock.
								 self halt]]].
	(World submorphs
		detect:
			[:m|
			 m model class == Debugger
			 and: [(m model interruptedProcess suspendedContext findContextSuchThat:
					[:ctxt|
					 ctxt receiver == self
					 and: [ctxt selector == #run]]) notNil]]
		ifNone: []) ifNotNil:
			[:debuggerWindow|
			 WorldState addDeferredUIMessage:
				[debuggerWindow model proceed]]
]

{ #category : #'spur bootstrap' }
StackMTInterpreterSimulator >> setDisplayForm: aForm [
	displayForm := aForm
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> shortPrintContext: aContext [
	transcript ensureCr.
	^super shortPrintContext: aContext
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> shortPrintFrame: theFP [
	self transcript ensureCr.
	^super shortPrintFrame: theFP
]

{ #category : #'process primitive support' }
StackMTInterpreterSimulator >> signalSemaphoreWithIndex: index [
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

{ #category : #testing }
StackMTInterpreterSimulator >> singleStep [

	self dispatchOn: currentBytecode in: BytecodeTable
]

{ #category : #'primitive support' }
StackMTInterpreterSimulator >> slowPrimitiveResponse [
	primTraceLog ifNotNil:
		[primTraceLog size > 127 ifTrue:
			[primTraceLog removeFirst].
		 primTraceLog addLast: primitiveFunctionPointer].
	^super slowPrimitiveResponse
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> space [

	traceOn ifTrue: [ transcript space ]
]

{ #category : #'plugin support' }
StackMTInterpreterSimulator >> sqGetInterpreterProxy [
	"I am basically my own proxy..."
	^self
]

{ #category : #'memory access' }
StackMTInterpreterSimulator >> sqMemoryExtraBytesLeft: includingSwap [
	^0
]

{ #category : #'memory access' }
StackMTInterpreterSimulator >> sqShrinkMemory: oldLimit By: delta [
	transcript show: 'shrink memory from ', oldLimit printString, ' by ', delta printString, ' remember it doesn''t actually shrink in simulation'; cr.

	^ oldLimit
]

{ #category : #'spur bootstrap' }
StackMTInterpreterSimulator >> stackPage [
	^stackPage
]

{ #category : #'simulation only' }
StackMTInterpreterSimulator >> stackPages [
	^stackPages
]

{ #category : #'simulation only' }
StackMTInterpreterSimulator >> startInContextSuchThat: aBlock [
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
		[self error: 'no context found'].
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

{ #category : #'simulation only' }
StackMTInterpreterSimulator >> startInSender [
	"Change the active process's suspendedContext to its sender, which short-cuts the
	 initialization of the system.  This can be a short-cut to running code, e.g. when doing
		Smalltalk saveAs.
		Compiler recompileAll"
	
	| activeContext activeProc senderContext |
	activeProc := self activeProcess.
	activeContext := objectMemory fetchPointer: SuspendedContextIndex ofObject: activeProc.
	senderContext := objectMemory fetchPointer: SenderIndex ofObject: activeContext.
	objectMemory storePointer: SuspendedContextIndex ofObject: activeProc withValue: senderContext.
	"Now push a dummy return value."
	objectMemory
		storePointer: (self fetchStackPointerOf: senderContext) + CtxtTempFrameStart
		ofObject: senderContext
		withValue: objectMemory nilObject.
	self storeInteger: StackPointerIndex
		ofObject: senderContext
		withValue: (self fetchStackPointerOf: senderContext) + 1
]

{ #category : #initialization }
StackMTInterpreterSimulator >> startOfMemory [
	self shouldNotImplement
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> success: successBoolean [
	"successBoolean ifFalse:
		[self halt]."
	^super success: successBoolean
]

{ #category : #'simulation only' }
StackMTInterpreterSimulator >> systemAttributes [
	^systemAttributes
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> tab [

	traceOn ifTrue: [ transcript tab ].
]

{ #category : #testing }
StackMTInterpreterSimulator >> test [
	self initStackPages.
	self loadInitialContext.
	transcript clear.
	byteCount := 0.
	breakCount := -1.
	quitBlock := [^self close].
	printSends := printReturns := true.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue:
		[self assertValidExecutionPointers.
		 printFrameAtEachStep ifTrue:
			[self printFrame: localFP WithSP: localSP].
		 printBytecodeAtEachStep ifTrue:
			[self printCurrentBytecodeOn: Transcript.
			 Transcript cr; flush].
		 self dispatchOn: currentBytecode in: BytecodeTable.
		 self incrementByteCount.
		 byteCount = breakCount ifTrue:
			["printFrameAtEachStep :=" printBytecodeAtEachStep := true.
			 self halt: 'hit breakCount break-point']].
	self externalizeIPandSP
]

{ #category : #testing }
StackMTInterpreterSimulator >> test1 [
	self initStackPages.
	self loadInitialContext.
	transcript clear.
	byteCount := 0.
	breakCount := -1.
	self setBreakSelector: #blockCopy:.
	quitBlock := [^self close].
	printSends := printReturns := true.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue:
		[self assertValidExecutionPointers.
		 "byteCount >= 22283 ifTrue:
			[(self checkIsStillMarriedContext: 22186072 currentFP: localFP) ifFalse:
				[self halt]]."
		 (printBytecodeAtEachStep
		  "and: [self isMarriedOrWidowedContext: 22189568]") ifTrue:
			["| thePage |
			 thePage := stackPages stackPageFor: (self frameOfMarriedContext: 22189568).
			 thePage == stackPage
				ifTrue: [self shortPrintFrameAndCallers: localFP SP: localSP]
				ifFalse: [self shortPrintFrameAndCallers: thePage headFrameFP SP: thePage headFrameSP]."
			 self printCurrentBytecodeOn: Transcript.
			 Transcript cr; flush].

		 self dispatchOn: currentBytecode in: BytecodeTable.
		 self incrementByteCount.
		 byteCount = breakCount ifTrue:
			["printFrameAtEachStep := true."
			 printSends := printBytecodeAtEachStep := true.
			 self halt: 'hit breakCount break-point']].
	self externalizeIPandSP
]

{ #category : #testing }
StackMTInterpreterSimulator >> testBecome [
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
StackMTInterpreterSimulator >> testBreakCount: breakCount printSends: shouldPrintSends printFrames: shouldPrintFrames printBytecodes: shouldPrintBytecodes [
	self initStackPages.
	self loadInitialContext.
	transcript clear.
	byteCount := 0.
	quitBlock := [^self close].
	printSends := true & shouldPrintSends. "true & foo allows evaluating printFoo := true in the debugger"
	printFrameAtEachStep := true & shouldPrintFrames.
	printBytecodeAtEachStep := true & shouldPrintBytecodes.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue:
		[self assertValidExecutionPointers.
		 printFrameAtEachStep ifTrue:
			[self printFrame: localFP WithSP: localSP].
		 printBytecodeAtEachStep ifTrue:
			[self printCurrentBytecodeOn: Transcript.
			 Transcript cr; flush].
		 self dispatchOn: currentBytecode in: BytecodeTable.
		 self incrementByteCount.
		 byteCount = breakCount ifTrue:
			["printFrameAtEachStep :=" printBytecodeAtEachStep := true.
			 self halt: 'hit breakCount break-point']].
	self externalizeIPandSP
]

{ #category : #testing }
StackMTInterpreterSimulator >> testWithFramePrint [
	printFrameAtEachStep := printBytecodeAtEachStep := true.
	self test
]

{ #category : #UI }
StackMTInterpreterSimulator >> toggleTranscript [
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

{ #category : #UI }
StackMTInterpreterSimulator >> toggleTranscriptForSimulatorMorph: aTranscriptStreamOrTranscript [
	"tty think this through when not so tired"
	self flag: 'tty'.
	transcript ifNil: [transcript := Transcript. ^self].
	displayView ifNil: [^self changed: #flash].
	transcript := transcript = Transcript
					ifTrue: [aTranscriptStreamOrTranscript]
					ifFalse: [Transcript]
]

{ #category : #accessing }
StackMTInterpreterSimulator >> transcript [
	^transcript
]

{ #category : #accessing }
StackMTInterpreterSimulator >> transcript: aTranscript [
	transcript := aTranscript
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> transferTo: aProc [
	self halt.
	^super transferTo: aProc
]

{ #category : #accessing }
StackMTInterpreterSimulator >> turnOnPrimTraceLog [
	primTraceLog ifNil:
		[primTraceLog := OrderedCollection new: 512]
]

{ #category : #'interpreter shell' }
StackMTInterpreterSimulator >> unableToReadImageError [
	self error:  'Read failed or premature end of image file'
]

{ #category : #'debugging traps' }
StackMTInterpreterSimulator >> updateStateOfSpouseContextForFrame: theFP WithSP: theSP [
	"(self frameContext: theFP) = 22163268 ifTrue:
		[self halt]."
	^super updateStateOfSpouseContextForFrame: theFP WithSP: theSP
]

{ #category : #UI }
StackMTInterpreterSimulator >> utilitiesMenu: aMenuMorph [
	aMenuMorph
		add: 'toggle transcript' action: #toggleTranscript;
		add: 'clone VM' action: #cloneSimulationWindow;
		addLine;
		add: 'print ext head frame' action: #printExternalHeadFrame;
		add: 'print int head frame' action: #printHeadFrame;
		add: 'short print ext frame & callers' action: [self shortPrintFrameAndCallers: framePointer];
		add: 'short print int frame & callers' action: [self shortPrintFrameAndCallers: localFP];
		add: 'long print ext frame & callers' action: [self printFrameAndCallers: framePointer SP: stackPointer];
		add: 'long print int frame & callers' action: [self printFrameAndCallers: localFP SP: localSP];
		add: 'print frame...' action: [(self promptHex: 'print frame') ifNotNil: [:fp| self printFrame: fp]];
		add: 'print call stack' action: #printCallStack;
		add: 'print stack call stack' action: #printStackCallStack;
		add: 'print stack call stack of...' action: [(self promptHex: 'frame') ifNotNil: [:fp| self printStackCallStackOf: fp]];
		add: 'print call stack of...' action: [(self promptHex: 'context or process oop') ifNotNil: [:obj| self printCallStackOf: obj]];
		add: 'print call stack of frame...' action: [(self promptHex: 'frame') ifNotNil: [:fp| self printCallStackFP: fp]];
		add: 'print all stacks' action: #printAllStacks;
		add: 'write back local ptrs' action: [stackPointer := localSP. framePointer := localFP. instructionPointer := localIP.
											self writeBackHeadFramePointers];
		add: 'print prim trace log' action: #dumpPrimTraceLog;
		addLine;
		add: 'print oop...' action: [(self promptHex: 'print oop') ifNotNil: [:oop| self printOop: oop]];
		add: 'long print oop...' action: [(self promptHex: 'print oop') ifNotNil: [:oop| self longPrintOop: oop]];
		add: 'print context...' action: [(self promptHex: 'print context') ifNotNil: [:oop| self printContext: oop]];
		addLine;
		add: 'inspect object memory' target: objectMemory action: #inspect;
		add: 'run leak checker' action: [Cursor execute showWhile: [self runLeakChecker]];
		add: 'inspect interpreter' action: #inspect;
		addLine;
		add: 'set break count...' action: [|s| s := UIManager default request: 'break count (dec)'.
											s notEmpty ifTrue: [breakCount := Integer readFrom: s readStream]];
		add: 'set break selector...' action: [|s| s := UIManager default request: 'break selector (MNU:foo for MNU)'.
											s notEmpty ifTrue:
												[(s size > 4 and: [s beginsWith: 'MNU:'])
													ifTrue: [self setBreakMNUSelector: (s allButFirst: 4)]
													ifFalse: [self setBreakSelector: s]]];
		add: 'turn valid exec ptrs assert o', (assertVEPAES ifTrue: ['ff'] ifFalse: ['n']) action: [assertVEPAES := assertVEPAES not];
		add: 'click step' action: [self setClickStepBreakBlock];
		add: (printSends
				ifTrue: ['no print sends']
				ifFalse: ['print sends'])
			action: [self ensureDebugAtEachStepBlock.
					printSends := printSends not];
		"currently printReturns does nothing"
		"add: (printReturns
				ifTrue: ['no print returns']
				ifFalse: ['print returns'])
			action: [self ensureDebugAtEachStepBlock.
					printReturns := printReturns not];"
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
StackMTInterpreterSimulator >> veryDeepCopyWith: deepCopier [
	"Override to short-circuit the copying of any VMPluginCodeGenerators referenced from mappedPluginEntries.
	 These can in turn hold onto Monticello state, resulting in a huge ammount of unnecessary copying."
	self objectMemory hasSpurMemoryManagerAPI ifTrue: 
		[deepCopier references
			at: mappedPluginEntries ifAbsentPut: [mappedPluginEntries].
		mappedPluginEntries do:
			[:tuple| | block |
			block := tuple third.
			deepCopier references at: block ifAbsentPut: [block]]].
	^super veryDeepCopyWith: deepCopier
]

{ #category : #'file primitives' }
StackMTInterpreterSimulator >> vmPathGet: stringBase Length: stringSize [
	| pathName stringOop |
	pathName := self vmPath.
	stringOop := stringBase - objectMemory baseHeaderSize. "Due to C call in Interp"
	1 to: stringSize do:
		[:i | objectMemory storeByte: i-1 ofObject: stringOop
			withValue: (pathName at: i) asciiValue].

]

{ #category : #'debug support' }
StackMTInterpreterSimulator >> warning: aString [
	transcript cr; nextPutAll: aString; flush
]

{ #category : #'I/O primitives support' }
StackMTInterpreterSimulator >> warpBits [

	^ myBitBlt warpBits
]

{ #category : #UI }
StackMTInterpreterSimulator >> windowColorToUse [
	^Color lightBlue
]

{ #category : #'primitive support' }
StackMTInterpreterSimulator >> windowIsClosing [
	quitBlock ifNotNil:
		[:effectiveQuitBlock|
		quitBlock := nil. "stop recursion on explicit window close."
		[effectiveQuitBlock value]
			on: BlockCannotReturn
			do: [:ex|]]	"Cause return from #test, et al"
]

{ #category : #'debug printing' }
StackMTInterpreterSimulator >> withMemoryProtectionDo: aBlock [
	objectMemory writeProtectMemory.
	stackPages writeProtectMemory.
	^aBlock ensure:
		[objectMemory writeEnableMemory.
		 stackPages writeEnableMemory]
]

{ #category : #'frame access' }
StackMTInterpreterSimulator >> withoutSmallIntegerTags: anInteger [
	| signBit |
	self assert: (anInteger >= 0 and: [anInteger highBit <= (objectMemory wordSize * 8)]).
	signBit := 1 << (objectMemory wordSize * 8 - 1).
	^(anInteger bitAnd: signBit) ~= 0
		ifTrue: ["negative"
				(anInteger bitClear: signBit + 1) - signBit]
		ifFalse: ["positive"
				anInteger - 1]
]
