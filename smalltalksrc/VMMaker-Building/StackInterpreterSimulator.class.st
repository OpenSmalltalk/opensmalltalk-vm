"
This class defines basic memory access and primitive simulation so that the StackInterpreter can run simulated in the Squeak environment.  It also defines a number of handy object viewing methods to facilitate pawing around in the object memory.

To see the thing actually run, you could (after backing up this image and changes), execute

	(StackInterpreterSimulator new openOn: Smalltalk imageName) test

	((StackInterpreterSimulator newWithOptions: #(NewspeakVM true MULTIPLEBYTECODESETS true))
		openOn: 'ns101.image') test

and be patient both to wait for things to happen, and to accept various things that may go wrong depending on how large or unusual your image may be.  We usually do this with a small and simple benchmark image.

Here's an example of what Eliot uses to launch the simulator in a window.  The bottom-right window has a menu packed with useful stuff:

| vm |
vm := StackInterpreterSimulator newWithOptions: #().
vm openOn: '/Users/eliot/Squeak/Squeak4.4/trunk44.image'.
vm setBreakSelector: #&.
vm openAsMorph; run
"
Class {
	#name : #StackInterpreterSimulator,
	#superclass : #StackInterpreterPrimitives,
	#instVars : [
		'bootstrapping',
		'byteCount',
		'breakCount',
		'sendCount',
		'printSends',
		'printReturns',
		'traceOn',
		'myBitBlt',
		'displayForm',
		'filesOpen',
		'imageName',
		'pluginList',
		'mappedPluginEntries',
		'quitBlock',
		'transcript',
		'displayView',
		'printFrameAtEachStep',
		'printBytecodeAtEachStep',
		'systemAttributes',
		'startMicroseconds',
		'externalSemaphoreSignalRequests',
		'externalSemaphoreSignalResponses',
		'extSemTabSize',
		'atEachStepBlock',
		'disableBooleanCheat',
		'performFilters',
		'eventQueue'
	],
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #'class initialization' }
StackInterpreterSimulator class >> initializeWithOptions: optionsDictionaryOrArray objectMemoryClass: objectMemoryClassOrNil [
	"The relevant ObjectMemory and Interpreter classes must be initialized in order.
	 This happens notionally every time we start the simulator,
	 but in fact happens when ever we instantiate a simulator."
	initializationOptions := optionsDictionaryOrArray isArray
							ifTrue: [Dictionary newFromPairs: optionsDictionaryOrArray]
							ifFalse: [optionsDictionaryOrArray].
	(objectMemoryClassOrNil ifNil: [self objectMemoryClass])
		initializeWithOptions: initializationOptions.

	self initializeWithOptions: initializationOptions
]

{ #category : #'instance creation' }
StackInterpreterSimulator class >> new [
	^self onObjectMemory: nil options: #()
]

{ #category : #'instance creation' }
StackInterpreterSimulator class >> newWithOptions: optionsDictionaryOrArray [
	^self onObjectMemory: nil options: optionsDictionaryOrArray
]

{ #category : #'instance creation' }
StackInterpreterSimulator class >> onObjectMemory: anObjectMemory [
	^self onObjectMemory: anObjectMemory options: #()
]

{ #category : #'instance creation' }
StackInterpreterSimulator class >> onObjectMemory: anObjectMemory options: optionsDictionaryOrArray [
	| simulatorClass |
	^self == StackInterpreterSimulator
		ifTrue:
			[simulatorClass := SmalltalkImage current endianness == #big
								ifTrue: [self notYetImplemented"StackInterpreterSimulatorMSB"]
								ifFalse: [StackInterpreterSimulatorLSB].
			simulatorClass initializeWithOptions: optionsDictionaryOrArray
				objectMemoryClass: (anObjectMemory ifNotNil: [anObjectMemory class]).
			 simulatorClass
				onObjectMemory: (anObjectMemory ifNil:
										[self objectMemoryClass simulatorClass new])
				options: optionsDictionaryOrArray]
		ifFalse: [super basicNew objectMemory: anObjectMemory; initialize]
]

{ #category : #'debug support' }
StackInterpreterSimulator >> allObjectsSelect: objBlock [
	"self allObjectsSelect: [:oop | (self baseHeader: oop) = 1234]"

	| selected |
	selected := OrderedCollection new.
	objectMemory allObjectsDoSafely:
		[:obj|
		(objBlock value: obj) ifTrue: [selected addLast: obj]].
	^selected
]

{ #category : #'spur bootstrap' }
StackInterpreterSimulator >> argumentCount: n [
	argumentCount := n
]

{ #category : #'return bytecodes' }
StackInterpreterSimulator >> baseFrameReturn [
	| contextToReturnTo |
	contextToReturnTo := self frameCallerContext: localFP.
	((objectMemory isContext: contextToReturnTo)
	 and: [self isMarriedOrWidowedContext: contextToReturnTo]) ifTrue:
		[(self checkIsStillMarriedContext: contextToReturnTo currentFP: nil) ifFalse:
			[self halt]].
	^super baseFrameReturn
]

{ #category : #utilities }
StackInterpreterSimulator >> booleanCheat: cond [
	disableBooleanCheat
		ifTrue: [self internalPop: 2
					thenPush: (cond
								ifTrue: [objectMemory trueObject]
								ifFalse: [objectMemory falseObject]).
				self fetchNextBytecode]
		ifFalse: [super booleanCheat: cond]
]

{ #category : #'spur bootstrap' }
StackInterpreterSimulator >> bootstrapping [
	^bootstrapping
]

{ #category : #'spur bootstrap' }
StackInterpreterSimulator >> bootstrapping: aBoolean [
	bootstrapping := aBoolean.
	objectMemory ifNotNil:
		[objectMemory bootstrapping: aBoolean]
]

{ #category : #'interpreter shell' }
StackInterpreterSimulator >> browserPluginInitialiseIfNeeded [
"do nothing - its a macro in C code to support Mac browser plugin strangeness"
]

{ #category : #'interpreter shell' }
StackInterpreterSimulator >> browserPluginReturnIfNeeded [
"do nothing - its a macro in C code to support Mac browser plugin strangeness"
]

{ #category : #'memory access' }
StackInterpreterSimulator >> byteAt: byteAddress [
	^objectMemory byteAt: byteAddress
]

{ #category : #'memory access' }
StackInterpreterSimulator >> byteAt: byteAddress put: byte [
	^objectMemory byteAt: byteAddress put: byte
]

{ #category : #'debug support' }
StackInterpreterSimulator >> byteCount [
	"So you can call this from temp debug statements in, eg, Interpreter, such as
	self byteCount = 12661 ifTrue: [self halt].
	"

	^ byteCount
]

{ #category : #UI }
StackInterpreterSimulator >> byteCountText [
	^ byteCount printString asText
]

{ #category : #'indexing primitives' }
StackInterpreterSimulator >> bytecodePrimAtPut [
	"self halt."
	^super bytecodePrimAtPut
]

{ #category : #'memory access' }
StackInterpreterSimulator >> cCoerce: value to: cTypeString [
	"Type coercion for translation only; just return the value when running in Smalltalk."

	^value == nil
		ifTrue: [value]
		ifFalse: [value coerceTo: cTypeString sim: self]
]

{ #category : #'translation support' }
StackInterpreterSimulator >> cCoerceSimple: value to: cTypeString [
	"Type coercion for translation only; just return the value when running in Smalltalk."

	^value
]

{ #category : #'plugin support' }
StackInterpreterSimulator >> callExternalPrimitive: mapIndex [
	| entry |
	entry := mappedPluginEntries at: (mapIndex > 1000
										ifTrue: [externalPrimitiveTable at: mapIndex - 1001]
										ifFalse: [mapIndex]).
	^(entry at: 1) perform: (entry at: 2).
]

{ #category : #'debug support' }
StackInterpreterSimulator >> charsOfLong: long [
	^self subclassResponsibility
]

{ #category : #'object memory support' }
StackInterpreterSimulator >> checkStackIntegrity [
	"Override to deal with incomplete initialization."
	stackPages ifNil: [^true].
	^super checkStackIntegrity
]

{ #category : #'debug support' }
StackInterpreterSimulator >> classAndSelectorOfMethod: meth forReceiver: rcvr [
	| mClass dict length methodArray |
	mClass := objectMemory fetchClassOf: rcvr.
	[dict := objectMemory fetchPointer: MethodDictionaryIndex ofObject: mClass.
	length := objectMemory fetchWordLengthOf: dict.
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
StackInterpreterSimulator >> classNameOf: aClass Is: className [
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
StackInterpreterSimulator >> clipboardRead: sz Into: actualAddress At: zeroBaseIndex [
	| str |
	str := Clipboard clipboardText.
	1 to: sz do:
		[:i | self byteAt: actualAddress + zeroBaseIndex + i - 1 put: (str at: i) asciiValue]
]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> clipboardSize [

	^ Clipboard clipboardText size
]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> clipboardWrite: sz From: actualDataAddress At: ignored [

	Clipboard clipboardText: (self stringOf: actualDataAddress - BaseHeaderSize)
]

{ #category : #'debug support' }
StackInterpreterSimulator >> cloneSimulation [
	| savedDisplayView savedDisplayForm savedQuitBlock savedTranscript |
	savedDisplayView := displayView. displayView := nil.
	savedDisplayForm := displayForm. displayForm = nil.
	savedQuitBlock := quitBlock. quitBlock := nil.
	savedTranscript := transcript. transcript := nil.

	[| clone window |
	 clone := self veryDeepCopy.
	 window := clone openAsMorph.
	 window setLabel: 'Clone of ', (savedDisplayView containingWindow label allButFirst: 'Simulation of ' size)]
		ensure:
			[displayView := savedDisplayView.
			 displayForm = savedDisplayForm.
			 quitBlock := savedQuitBlock.
			 transcript := savedTranscript]
]

{ #category : #initialization }
StackInterpreterSimulator >> close [  "close any files that ST may have opened"
	(self loadNewPlugin: 'FilePlugin') ifNotNil:
		[:filePlugin| filePlugin close]
]

{ #category : #initialization }
StackInterpreterSimulator >> convertToArray [
	"I dont believe it -- this *just works*"

	objectMemory memory: (objectMemory memory as: Array)
]

{ #category : #'I/O primitives support' }
StackInterpreterSimulator >> copyBits [

	^ myBitBlt copyBits
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> cr [

	traceOn ifTrue: [ transcript cr; flush ].
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> createActualMessageTo: class [

	"false
		ifTrue:
			[(self stringOf: messageSelector) = 'run:with:in:' ifTrue:
				[self halt]]
		ifFalse:
			[self halt: (self stringOf: messageSelector)]."

	^super createActualMessageTo: class
]

{ #category : #UI }
StackInterpreterSimulator >> desiredDisplayExtent [
	^(savedWindowSize
		ifNil: [640@480]
		ifNotNil: [savedWindowSize >> 16 @ (savedWindowSize bitAnd: 16rFFFF)])
			min: Display extent * 2 // 3
]

{ #category : #initialization }
StackInterpreterSimulator >> desiredEdenBytes: anInteger [
	desiredEdenBytes := anInteger
]

{ #category : #initialization }
StackInterpreterSimulator >> desiredNumStackPages: anInteger [
	desiredNumStackPages := anInteger
]

{ #category : #testing }
StackInterpreterSimulator >> disableBooleanCheat: aBoolean [
	disableBooleanCheat := aBoolean
]

{ #category : #'plugin primitive support' }
StackInterpreterSimulator >> dispatchMappedPluginEntry: n [ 
	^(mappedPluginEntries at: n) first
		perform: (mappedPluginEntries at: n) second
]

{ #category : #'interpreter shell' }
StackInterpreterSimulator >> dispatchOn: anInteger in: selectorArray [
	"Simulate a case statement via selector table lookup.
	The given integer must be between 0 and selectorArray size-1, inclusive.
	For speed, no range test is done, since it is done by the at: operation.
	Note that, unlike many other arrays used in the Interpreter, this method expect NO CArrayAccessor wrapping - it would duplicate the +1. Maybe this would be better updated to make it all uniform"
	selectorArray == BytecodeTable ifTrue:
		[self assert: (anInteger between: bytecodeSetSelector and: bytecodeSetSelector + 255)].
	self perform: (selectorArray at: (anInteger + 1)).
]

{ #category : #accessing }
StackInterpreterSimulator >> displayForm [
	"The VM SImulator draws directly on an imageMorph named displayView
	  displayView is housed on a Form named displayForm
	  displayForm is initialized in my initialize method. 
	  it 'needs' to be initialized there to support Eliot's legacy openAsMorph functionality
	"
	^displayForm
]

{ #category : #'I/O primitives support' }
StackInterpreterSimulator >> displayLocation [

	^ Display extent - displayForm extent - (10@10)
]

{ #category : #accessing }
StackInterpreterSimulator >> displayView [
	"The VM SImulator draws directly on an imageMorph named displayView
	  displayView is housed on a Form named displayForm
	  Since this is housed directly on the Morph, I have this tight compling from here->model->morph. 
	"
	self flag: 'tty'.	
	^displayView
]

{ #category : #accessing }
StackInterpreterSimulator >> displayView: anImageMorph [
	"The VM SImulator draws directly on an imageMorph named displayView
	  displayView is housed on a Form named displayForm
	  Since this is housed directly on the Morph, I have this tight compling from here->model->morph. 
	"
	self flag: 'tty'.
	displayView := anImageMorph
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> divorceFramesIn: aStackPage [
	"| thisPage |
	(self checkIsStillMarriedContext: 22189568 currentFP: framePointer) ifTrue:
		[thisPage := stackPages stackPageFor: (self frameOfMarriedContext: 22189568).
		 aStackPage == thisPage ifTrue:
			[self halt]]."
	^super divorceFramesIn: aStackPage
]

{ #category : #'process primitive support' }
StackInterpreterSimulator >> doSignalExternalSemaphores: minTableSize [
	"This is a non-thread-safe simulation.  See platforms/Cross/vm/sqExternalSemaphores.c
	 for the real code."
	| switched |
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
StackInterpreterSimulator >> doesNotUnderstand: aMessage [
	"If this is a doit and the objectMemory understands, pass it on."
	(thisContext findContextSuchThat: [:ctxt| ctxt selector == #evaluate:in:to:notifying:ifFail:logged:]) ifNotNil:
		[(objectMemory class whichClassIncludesSelector: aMessage selector) ifNotNil:
			[:implementingClass|
			(implementingClass inheritsFrom: Object) ifTrue: "i.e. VMClass and below"
				[Transcript nextPutAll: 'warning: redirecting ', aMessage selector, ' in ', thisContext sender printString, ' to objectMemory'; cr; flush.
				 aMessage lookupClass: nil.
				^aMessage sentTo: objectMemory]]].
	^super doesNotUnderstand: aMessage
]

{ #category : #'I/O primitives support' }
StackInterpreterSimulator >> drawLoopX: xDelta Y: yDelta [

	^ myBitBlt drawLoopX: xDelta Y: yDelta
]

{ #category : #'debug support' }
StackInterpreterSimulator >> dumpMethodHeader: hdr [
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
StackInterpreterSimulator >> elementsPerPrintOopLine [
	^4
]

{ #category : #testing }
StackInterpreterSimulator >> ensureDebugAtEachStepBlock [
	atEachStepBlock := [printFrameAtEachStep ifTrue:
							[self printFrame: localFP WithSP: localSP].
						 printBytecodeAtEachStep ifTrue:
							[self printCurrentBytecodeOn: transcript.
							 transcript cr; flush].
						 byteCount = breakCount ifTrue:
							["printFrameAtEachStep :=" printBytecodeAtEachStep := true]]
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> externalDivorceFrame: theFP andContext: ctxt [
	"(theFP = -208 or: [ctxt = 22189568]) ifTrue:
		[self halt]."
	^super externalDivorceFrame: theFP andContext: ctxt
]

{ #category : #'frame access' }
StackInterpreterSimulator >> externalInstVar: index ofContext: aMarriedContext put: anOop [
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

{ #category : #'stack pages' }
StackInterpreterSimulator >> externalWriteBackHeadFramePointers [
	self assert: (localFP = framePointer
				or: [localFP = (self frameCallerFP: framePointer)]).
	super externalWriteBackHeadFramePointers
]

{ #category : #'interpreter shell' }
StackInterpreterSimulator >> fetchByte [

	^ self byteAt: (localIP := localIP + 1).
]

{ #category : #'control primitives' }
StackInterpreterSimulator >> filterPerformOf: selector to: receiver [
	"This is to allow simulator to filter start-up items to avoid as-yet unsimulatable plugins."
	performFilters ifNil: [^false].
	(performFilters at: (self shortPrint: receiver) ifAbsent: []) ifNotNil:
		[:messages|
		^messages includes: (self stringOf: selector)].
	^false
]

{ #category : #testing }
StackInterpreterSimulator >> findNewMethodInClassTag: classTag [
"
	| cName |
	traceOn ifTrue:
		[cName := (self sizeBitsOf: class) = 16r20
			ifTrue: ['class ' , (self nameOfClass: (self fetchPointer: 6 ofObject: class))]
			ifFalse: [(self nameOfClass: class)].
		self cr; print: cName , '>>' , (self stringOf: messageSelector)].
"
	(self stringOf: messageSelector) = 'doesNotUnderstand:' ifTrue: [self halt].

	sendCount := sendCount + 1.

	printSends ifTrue:
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
StackInterpreterSimulator >> firstIndexableField: oop [
	"This is in ObjectMemory and overridden in the obj mem simulators"
	self shouldNotImplement
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> flush [
	traceOn ifTrue: [transcript flush]
]

{ #category : #'plugin support' }
StackInterpreterSimulator >> flushExternalPrimitives [
	mappedPluginEntries := OrderedCollection new.
	super flushExternalPrimitives
]

{ #category : #'control primitives' }
StackInterpreterSimulator >> forShortPrintString: shortPrintString filterPerformMessages: aCollection [
	performFilters ifNil:
		[performFilters := Dictionary new].
	performFilters at: shortPrintString put: aCollection
]

{ #category : #'frame access' }
StackInterpreterSimulator >> frameOfMarriedContext: aContext [ 
	| senderOop |
	senderOop := objectMemory fetchPointer: SenderIndex ofObject: aContext.
	self assert: (objectMemory isIntegerObject: senderOop).
	^self withoutSmallIntegerTags: senderOop
]

{ #category : #'spur bootstrap' }
StackInterpreterSimulator >> framePointer [
	^framePointer
]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> fullDisplay [
	| primFailCodeValue |
	displayForm == nil ifTrue: [^ self].
	primFailCodeValue := primFailCode.
	self initPrimCall.
	self displayBitsOf: (objectMemory splObj: TheDisplay) Left: 0 Top: 0 Right: displayForm width Bottom: displayForm height.
	primFailCode := primFailCodeValue
]

{ #category : #'debug support' }
StackInterpreterSimulator >> fullDisplayUpdate [
	"Preserve self successful when call asynchronously from Simulator"
	| primFailCodeValue |
	primFailCodeValue := primFailCode.
	self initPrimCall.
	super fullDisplayUpdate.
	primFailCode := primFailCodeValue
]

{ #category : #'interpreter shell' }
StackInterpreterSimulator >> functionPointerFor: primIndex inClass: lookupClass [
	"Override Interpreter to handle the external primitives caching.  See also
	 internalExecuteNewMethod."

	^(primIndex between: 1 and: MaxPrimitiveIndex)
		ifTrue: [primitiveTable at: primIndex + 1]
		ifFalse: [0]
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> getErrorObjectFromPrimFailCode [
	primFailCode > 1 ifTrue: [self halt].
	^super getErrorObjectFromPrimFailCode
]

{ #category : #initialization }
StackInterpreterSimulator >> getLongFromFile: aStream swap: swapFlag [
	^swapFlag 
		ifTrue: [objectMemory byteSwapped: (self nextLongFrom: aStream)]
		ifFalse: [self nextLongFrom: aStream]
]

{ #category : #'image save/restore' }
StackInterpreterSimulator >> getShortFromFile: aFile swap: swapFlag [
	| aShort |
	aShort := self nextShortFrom: aFile.
	^swapFlag 
		ifTrue: [(aShort bitShift: -8) + ((aShort bitAnd: 16rFF) bitShift: 8)]
		ifFalse: [aShort]
]

{ #category : #'memory access' }
StackInterpreterSimulator >> halfWordHighInLong32: long32 [
	^self subclassResponsibility
]

{ #category : #'memory access' }
StackInterpreterSimulator >> halfWordLowInLong32: long32 [
	^self subclassResponsibility
]

{ #category : #'debug support' }
StackInterpreterSimulator >> headerStart: oop [

	^ (objectMemory extraHeaderBytes: oop) negated
]

{ #category : #'debug support' }
StackInterpreterSimulator >> heapMapAtWord: address [
	^objectMemory heapMap heapMapAtWord: address
]

{ #category : #'spur bootstrap' }
StackInterpreterSimulator >> imageName [
	^imageName
]

{ #category : #'spur bootstrap' }
StackInterpreterSimulator >> imageName: aString [
	imageName := aString
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> imageNameGet: p Length: sz [
	1 to: sz  do:
		[:i |
		objectMemory
			byteAt:  p + i - 1
			put: (imageName at: i) asInteger]
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> imageNamePut: p Length: sz [
	| newName |
	newName := ByteString new: sz.
	1 to: sz  do:
		[:i |
		newName
			at: i
			put: (Character value: (objectMemory byteAt: p + i - 1))].
	imageName := newName
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> imageNameSize [
	^imageName size
]

{ #category : #'interpreter shell' }
StackInterpreterSimulator >> incrementByteCount [
	(byteCount := byteCount + 1) = breakCount ifTrue:
		[self doOrDefer: [self changed: #byteCountText].
		 self halt].
	byteCount \\ 1000 = 0 ifTrue:
		[self doOrDefer: [self changed: #byteCountText].
		 self forceInterruptCheck.
		 byteCount \\ 1000 = 0 ifTrue: [self fullDisplayUpdate]] "tty. denominator was 10000 before event forwarding. Refactor me."
]

{ #category : #initialization }
StackInterpreterSimulator >> initialize [
	"Initialize the StackInterpreterSimulator when running the interpreter
	 inside Smalltalk. The primary responsibility of this method is to allocate
	 Smalltalk Arrays for variables that will be declared as statically-allocated
	 global arrays in the translated code."

	bootstrapping := false.
	transcript := Transcript.

	objectMemory ifNil:
		[objectMemory := self class objectMemoryClass simulatorClass new].
	objectMemory coInterpreter: self.

	"Note: we must initialize ConstMinusOne differently for simulation,
		due to the fact that the simulator works only with +ve 32-bit values"
	ConstMinusOne := objectMemory integerObjectOf: -1.

	methodCache := Array new: MethodCacheSize.
	atCache := Array new: AtCacheTotalSize.
	self flushMethodCache.
	gcSemaphoreIndex := 0.
	externalSemaphoreSignalRequests := externalSemaphoreSignalResponses := #().
	externalPrimitiveTable := CArrayAccessor on: (Array new: MaxExternalPrimitiveTableSize).
	externalPrimitiveTableFirstFreeIndex := 0.
	primitiveTable := self class primitiveTable copy.
	mappedPluginEntries := OrderedCollection new.
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[primitiveAccessorDepthTable := Array new: primitiveTable size.
			 pluginList := {}.
			 self loadNewPlugin: '']
		ifFalse:
			[pluginList := {'' -> self }].
	desiredNumStackPages := desiredEdenBytes := 0.
	"This is initialized on loading the image, but convenient for testing stack page values..."
	numStackPages := self defaultNumStackPages. 
	startMicroseconds := Time totalSeconds * 1000000.

	"initialize InterpreterSimulator variables used for debugging"
	byteCount := 0.
	sendCount := 0.
	quitBlock := [^ self].
	traceOn := true.
	printSends := printReturns := printFrameAtEachStep := printBytecodeAtEachStep := false.
	myBitBlt := BitBltSimulator new setInterpreter: self.
	displayForm := 'Display has not yet been installed' asDisplayText form.
	eventQueue := SharedQueue new.
	suppressHeartbeatFlag := false.
	systemAttributes := Dictionary new.
	extSemTabSize := 256.
	disableBooleanCheat := false
]

{ #category : #'frame access' }
StackInterpreterSimulator >> instVar: index ofContext: aMarriedContext put: anOop [
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
StackInterpreterSimulator >> insufficientMemoryAvailableError [
	self error: 'Failed to allocate memory for the heap'
]

{ #category : #'interpreter shell' }
StackInterpreterSimulator >> insufficientMemorySpecifiedError [
	self error: 'Insufficient memory for this image'
]

{ #category : #'memory access' }
StackInterpreterSimulator >> integerAt: byteAddress [
	"Note: Adjusted for Smalltalk's 1-based array indexing."

	^objectMemory memory integerAt: (byteAddress // 4) + 1
]

{ #category : #'memory access' }
StackInterpreterSimulator >> integerAt: byteAddress put: a32BitValue [
	"Note: Adjusted for Smalltalk's 1-based array indexing."

	^objectMemory memory integerAt: (byteAddress // 4) + 1 put: a32BitValue
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> internalCannotReturn: resultOop [
	self halt.
	^super internalCannotReturn: resultOop
]

{ #category : #testing }
StackInterpreterSimulator >> internalFindNewMethod [
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

	printSends ifTrue:
		[self cr; print: byteCount; space; printStringOf: messageSelector].
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
	super internalFindNewMethod
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> internalMustBeBoolean [
	self halt.
	^super internalMustBeBoolean
]

{ #category : #'stack pages' }
StackInterpreterSimulator >> interpreterAllocationReserveBytes [
	^bootstrapping
		ifTrue: [0]
		ifFalse: [super interpreterAllocationReserveBytes]
]

{ #category : #'interpreter shell' }
StackInterpreterSimulator >> invalidCompactClassError: name [
	self error: 'Class ', name, ' does not have the required compact class index'
]

{ #category : #security }
StackInterpreterSimulator >> ioCanRenameImage [
	^true
]

{ #category : #security }
StackInterpreterSimulator >> ioCanWriteImage [
	^true
]

{ #category : #'primitive support' }
StackInterpreterSimulator >> ioExit [

	quitBlock value  "Cause return from #test"
]

{ #category : #'primitive support' }
StackInterpreterSimulator >> ioExitWithErrorCode: ec [

	quitBlock value  "Cause return from #test"
]

{ #category : #'other primitives' }
StackInterpreterSimulator >> ioForceDisplayUpdate [
	"no-op"
]

{ #category : #'process primitive support' }
StackInterpreterSimulator >> ioGetMaxExtSemTableSize [
	^extSemTabSize
]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> ioGetNextEvent: evtBuf [
	| evt  |
	"StackInterpreterSimulatorMorphicModel browse"
	eventQueue isNil ifTrue: 
		[^self primitiveFail].
	eventQueue isEmpty
		ifFalse:
			[	evt :=  eventQueue next.
			      1 to: (evt size) do: [:i | ((evt at: i) isNil) ifFalse: [evtBuf at: (i - 1) put: (evt at: i)]]].
	 self success: true.

]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> ioHasDisplayDepth: depth [
	^Display supportsDisplayDepth: depth
]

{ #category : #'I/O primitives support' }
StackInterpreterSimulator >> ioHeartbeatMilliseconds [
	^1
]

{ #category : #initialization }
StackInterpreterSimulator >> ioInitHeartbeat [
	"No-op in the simulator.  We cause a poll every 1000 bytecodes instead."
]

{ #category : #'plugin support' }
StackInterpreterSimulator >> ioLoadFunction: functionString From: pluginString [
	"Load and return the requested function from a module"
	| plugin fnSymbol |
	fnSymbol := functionString asSymbol.
	transcript
		cr;
		show: '(', byteCount printString, ') Looking for ', functionString, ' in ',
				(pluginString isEmpty ifTrue:['vm'] ifFalse:[pluginString]).
	plugin := pluginList 
				detect:[:any| any key = pluginString asString]
				ifNone:[self loadNewPlugin: pluginString].
	plugin ifNil:[
		"Transcript cr; show:'Failed ... no plugin found'." ^ 0].
	plugin := plugin value.
	mappedPluginEntries doWithIndex:[:pluginAndName :index|
		((pluginAndName at: 1) == plugin 
			and:[(pluginAndName at: 2) == fnSymbol]) ifTrue:[
				"Transcript show:' ... okay'." ^ index]].
	(plugin respondsTo: fnSymbol) ifFalse:[
		"Transcript cr; show:'Failed ... primitive not in plugin'." ^ 0].
	mappedPluginEntries := mappedPluginEntries copyWith: (Array with: plugin with: fnSymbol).
	"Transcript show:' ... okay'."
	^ mappedPluginEntries size
]

{ #category : #'plugin support' }
StackInterpreterSimulator >> ioLoadFunction: functionString From: pluginString AccessorDepthInto: accessorDepthPtr [
	"Load and return the requested function from a module.
	 Assign the accessor depth through accessorDepthPtr.
	 N.B. The actual code lives in platforms/Cross/vm/sqNamedPrims.h"
	| firstTime plugin fnSymbol |
	firstTime := false.
	fnSymbol := functionString asSymbol.
	transcript
		cr;
		show: '(', byteCount printString, ') Looking for ', functionString, ' in ',
				(pluginString isEmpty ifTrue:['vm'] ifFalse:[pluginString]).
	functionString = breakSelector ifTrue: [self halt: breakSelector].
	plugin := pluginList 
				detect: [:any| any key = pluginString asString]
				ifNone:
					[firstTime := true.
					 self loadNewPlugin: pluginString].
	plugin ifNil:
		[firstTime ifTrue: [transcript cr; show: 'Failed ... primitive not in plugin'].
		 ^0].
	plugin := plugin value.
	mappedPluginEntries doWithIndex:
		[:pluginAndName :index|
		 ((pluginAndName at: 1) == plugin 
		  and:[(pluginAndName at: 2) == fnSymbol]) ifTrue:
			[firstTime ifTrue: [transcript show: ' ... okay'; cr].
			 accessorDepthPtr at: 0 put: (pluginAndName at: 4).
			 ^index]].
	firstTime ifTrue: [transcript cr; show: 'Failed ... primitive not in plugin'].
	^0
]

{ #category : #'I/O primitives support' }
StackInterpreterSimulator >> ioLocalSecondsOffset [
	^DateAndTime localOffset asSeconds
]

{ #category : #'I/O primitives support' }
StackInterpreterSimulator >> ioMSecs [
	"Return the value of the millisecond clock."
	"NOT.  Actually, we want something a lot slower and, for exact debugging,
	something more repeatable than real time.  I have an idea: use the byteCount... (di 7/1/2004 13:55)"

	^self microsecondsToMilliseconds: self ioUTCMicroseconds
	
"At 20k bytecodes per second, this gives us about 200 ticks per second, or about 1/5 of what you'd expect for the real time clock.  This should still service events at one or two per second"
]

{ #category : #'I/O primitives support' }
StackInterpreterSimulator >> ioMicroMSecs [
	"Answer the value of the high-resolution millisecond clock."

	^ Time millisecondClockValue

]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> ioProcessEvents [
]

{ #category : #'I/O primitive support' }
StackInterpreterSimulator >> ioRelinquishProcessorForMicroseconds: microseconds [
	"In the simulator give an indication that we're idling and check for input."
	Display reverse: (0@0 extent: 16@16).
	Sensor peekEvent ifNotNil:
		[self forceInterruptCheck].
	Processor activeProcess == Project uiProcess ifTrue:
		[World doOneCycle].
	microseconds >= 1000
		ifTrue: [(Delay forMilliseconds: microseconds + 999 // 1000) wait]
		ifFalse: [Processor yield]
]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> ioScreenDepth [
	^DisplayScreen actualScreenDepth.
]

{ #category : #'I/O primitives support' }
StackInterpreterSimulator >> ioScreenSize [
	"Return the screen extent packed into 32 bits."

	^ (displayForm width << 16) + displayForm height
]

{ #category : #'I/O primitives support' }
StackInterpreterSimulator >> ioSeconds [
	"Return the value of the second clock."

	^ Time primSecondsClock
]

{ #category : #'I/O primitives support' }
StackInterpreterSimulator >> ioSetHeartbeatMilliseconds: ignored [
]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> ioSetInputSemaphore: index [

	self primitiveFail
]

{ #category : #'process primitive support' }
StackInterpreterSimulator >> ioSetMaxExtSemTableSize: anInteger [
	"Inform the VM of the maximum size the image will grow the exernal semaphore table (specialObjectsArray at: 39) to.
	 This allows the VM to allocate storage such that external semaphores can be signalled without locking."
	extSemTabSize := anInteger
]

{ #category : #'process primitive support' }
StackInterpreterSimulator >> ioSynchronousCheckForEvents [
	"Hook allowing the platform to do anything it needs to do synchronously."
]

{ #category : #'I/O primitives support' }
StackInterpreterSimulator >> ioUTCMicroseconds [
	"Return the value of the microsecond clock."
	"NOT.  Actually, we want something a lot slower and, for exact debugging,
	something more repeatable than real time.  Dan had an idea: use the byteCount..."

	^byteCount + startMicroseconds
	
"At 20k bytecodes per second, this gives us aobut 200 ticks per second, or about 1/5 of what you'd expect for the real time clock.  This should still service events at one or two per second"
]

{ #category : #'I/O primitives support' }
StackInterpreterSimulator >> ioUTCMicrosecondsNow [
	^self ioUTCMicroseconds
]

{ #category : #'primitive support' }
StackInterpreterSimulator >> isPrimitiveFunctionPointerAnIndex [
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
StackInterpreterSimulator >> isThreadedVM [
	^false
]

{ #category : #'frame access' }
StackInterpreterSimulator >> isWidowedContext: aOnceMarriedContext [
	"See if the argument is connected with a live frame or not.
	 If it is not, turn it into a bereaved single context."
	(stackPages isFree: stackPage) ifFalse: "in baseReturn the active page has been freed."
		[((stackPages somePageHasHeadFrameFP: framePointer)
		  or: [(stackPages somePageHasHeadFrameFP: localFP)
		  or: [stackPages allPagesFree]]) ifFalse:
			[thisContext sender sender method = (StackInterpreter >> #baseFrameReturn) ifFalse:
				[self halt: 'currentFP may not be written back to stack page']]].
	^super isWidowedContext: aOnceMarriedContext
]

{ #category : #'compiled methods' }
StackInterpreterSimulator >> literal: offset [
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
StackInterpreterSimulator >> loadNewPlugin: pluginString [
	^(self tryLoadNewPlugin: pluginString pluginEntries: mappedPluginEntries) ifNotNil:
		[:entry|
		 pluginList := pluginList copyWith: entry.
		 entry]
]

{ #category : #'spur bootstrap' }
StackInterpreterSimulator >> localFP [
	^localFP
]

{ #category : #'spur bootstrap' }
StackInterpreterSimulator >> localIP [
	^localIP
]

{ #category : #'spur bootstrap' }
StackInterpreterSimulator >> localIP: pc [
	localIP := pc
]

{ #category : #'spur bootstrap' }
StackInterpreterSimulator >> localSP [
	^localSP
]

{ #category : #testing }
StackInterpreterSimulator >> logOfBytesVerify: nBytes fromFileNamed: fileName fromStart: loggingStart [
	"Verify a questionable interpreter against a successful run"
	"self logOfBytesVerify: 10000 fromFileNamed: 'clone32Bytecodes.log' "
	
	| logFile rightWord prevCtxt |
	logFile := (FileStream readOnlyFileNamed: fileName) binary.
	transcript clear.
	byteCount := 0.
	quitBlock := [^ self].
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
StackInterpreterSimulator >> logOfBytesWrite: nBytes toFileNamed: fileName fromStart: loggingStart [
	"Write a log file for testing a flaky interpreter on the same image"
	"self logOfBytesWrite: 10000 toFileNamed: 'clone32Bytecodes.log' "
	
	| logFile |
	logFile := (FileStream newFileNamed: fileName) binary.
	transcript clear.
	byteCount := 0.
	quitBlock := [^ self].
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
StackInterpreterSimulator >> logOfSendsVerify: nSends fromFileNamed: fileName fromStart: loggingStart [
	"Write a log file for testing a flaky interpreter on the same image"
	"self logOfSendsWrite: 10000 toFileNamed: 'clone32Messages.log' "
	
	| logFile priorFrame rightSelector prevCtxt |
	logFile := FileStream readOnlyFileNamed: fileName.
	transcript clear.
	byteCount := 0.
	sendCount := 0.
	priorFrame := localFP.
	quitBlock := [^ self].
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
StackInterpreterSimulator >> logOfSendsWrite: nSends toFileNamed: fileName fromStart: loggingStart [
	"Write a log file for testing a flaky interpreter on the same image"
	"self logOfSendsWrite: 10000 toFileNamed: 'clone32Messages.log' "
	
	| logFile priorFrame |
	logFile := FileStream newFileNamed: fileName.
	transcript clear.
	byteCount := 0.
	sendCount := 0.
	priorFrame := localFP.
	quitBlock := [^ self].
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
StackInterpreterSimulator >> longAt: byteAddress [
	^objectMemory longAt: byteAddress
]

{ #category : #'memory access' }
StackInterpreterSimulator >> longAt: byteAddress put: a32BitValue [
	^objectMemory longAt: byteAddress put: a32BitValue
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> makeDirEntryName: entryName size: entryNameSize
	createDate: createDate modDate: modifiedDate
	isDir: dirFlag fileSize: fileSize [

	| modDateOop createDateOop nameString results |
	<var: 'entryName' type: 'char *'>

	results			:= objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 5.
	nameString		:= objectMemory instantiateClass: (objectMemory splObj: ClassByteString) indexableSize: entryNameSize.
	createDateOop	:= self positive32BitIntegerFor: createDate.
	modDateOop	:= self positive32BitIntegerFor: modifiedDate.

	1 to: entryNameSize do:
		[ :i |
		objectMemory storeByte: i-1 ofObject: nameString withValue: (entryName at: i) asciiValue].

	objectMemory storePointerUnchecked: 0 ofObject: results withValue: nameString.
	objectMemory storePointerUnchecked: 1 ofObject: results withValue: createDateOop.
	objectMemory storePointerUnchecked: 2 ofObject: results withValue: modDateOop.
	dirFlag
		ifTrue: [ objectMemory storePointerUnchecked: 3 ofObject: results withValue: objectMemory trueObject ]
		ifFalse: [ objectMemory storePointerUnchecked: 3 ofObject: results withValue: objectMemory falseObject ].
	objectMemory storePointerUnchecked: 4 ofObject: results withValue: (objectMemory integerObjectOf: fileSize).
	^ results
]

{ #category : #'frame access' }
StackInterpreterSimulator >> markContextAsDead: oop [
	"(self withoutSmallIntegerTags: (objectMemory fetchPointer: SenderIndex ofObject: oop)) = -16r26824 ifTrue:
		[self halt]."
	^super markContextAsDead: oop
]

{ #category : #'spur bootstrap' }
StackInterpreterSimulator >> messageSelector: s [
	"For e.g. SpurBootstrap"
	messageSelector := s
]

{ #category : #'simulation only' }
StackInterpreterSimulator >> methodForContext: aContextOop [
	self assert: (objectMemory isContext: aContextOop).
	^objectMemory fetchPointer: MethodIndex ofObject: aContextOop
]

{ #category : #'debug support' }
StackInterpreterSimulator >> nameOfClass: classOop [
	| numSlots |
	classNameIndex ifNil: [^'??nil cnidx??'].
	numSlots := objectMemory numSlotsOf: classOop.
	numSlots = metaclassNumSlots ifTrue:
		[^(self nameOfClass:
				(objectMemory fetchPointer: thisClassIndex ofObject: classOop)) , ' class'].
	numSlots <= classNameIndex ifTrue:
		[^'bad class'].
	^self stringOf: (objectMemory fetchPointer: classNameIndex ofObject: classOop)
]

{ #category : #initialization }
StackInterpreterSimulator >> nextLongFrom: aStream [
	"Read a 32-bit quantity from the given (binary) stream."
	^self subclassResponsibility
]

{ #category : #initialization }
StackInterpreterSimulator >> nextShortFrom: aStream [
	"Read a 16-bit quantity from the given (binary) stream."
	^self subclassResponsibility
]

{ #category : #UI }
StackInterpreterSimulator >> openAsMorph [
	"Open a morphic view on this simulation."
	| localImageName borderWidth window |
	localImageName := imageName
							ifNotNil: [FileDirectory default localNameFor: imageName]
							ifNil: [' synthetic image'].
	window := (SystemWindow labelled: 'Simulation of ', localImageName) model: self.

	window addMorph: (displayView := ImageMorph new image: displayForm)
		frame: (0@0 corner: 1@0.8).

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
								+ (2 * borderWidth)
								+ (0@window labelHeight)
								* (1@(1/0.8))) rounded.
	^window
]

{ #category : #UI }
StackInterpreterSimulator >> openAsMorphNoTranscript [
	"Open a morphic view on this simulation."
	| localImageName borderWidth window |
	localImageName := FileDirectory default localNameFor: imageName.
	window := (SystemWindow labelled: 'Simulation of ' , localImageName) model: self.

	window addMorph: (displayView := ImageMorph new image: displayForm)
		frame: (0@0 corner: 1@0.95).

	window addMorph: (PluggableTextMorph on: self
						text: #byteCountText accept: nil
						readSelection: nil menu: #utilitiesMenu:) hideScrollBarsIndefinitely
		frame: (0@0.95 corner: 1@1).

	borderWidth := [SystemWindow borderWidth] "Squeak 4.1"
						on: MessageNotUnderstood
						do: [:ex| 0]. "3.8"
	borderWidth := borderWidth + window borderWidth.
	window openInWorldExtent: (self desiredDisplayExtent
								+ (2 * borderWidth)
								+ (0@window labelHeight)
								* (1@(1/0.95))) rounded
]

{ #category : #UI }
StackInterpreterSimulator >> openAsStackInterpreterSimulatorMorph [
	"Open a morphic view on this simulation. ala Bert Freudenberg's
	SqueakJS http://lively-web.org/users/bert/squeak.html	"
	| localImageName borderWidth window |
	localImageName := imageName
				ifNil: [' synthetic image']
				ifNotNil: [FileDirectory default localNameFor: imageName].

	transcript := TranscriptStream
				on: (String new: 10000).

	window := StackInterpreterSimulatorMorph	
					withVMSimulator: self 
					title: 'Simulation of ' , localImageName, ' (beta)'
					transcript: transcript.				

	borderWidth := [StackInterpreterSimulatorMorph borderWidth
			"Squeak 4.1"]
				on: MessageNotUnderstood
				do: [:ex | 0].
	"3.8"
	borderWidth := borderWidth + window borderWidth.
	window openInWorldExtent: (self desiredDisplayExtent + (2 * borderWidth) + (0 @ window labelHeight) * (1 @ (1 / 0.8))) rounded.
	^ window
]

{ #category : #initialization }
StackInterpreterSimulator >> openOn: fileName extraMemory: extraBytes [
	"StackInterpreterSimulator new openOn: 'clone.im' extraMemory: 100000"

	| f version headerSize dataSize count oldBaseAddr bytesToShift swapBytes
	  headerFlags heapBase firstSegSize heapSize
	  hdrNumStackPages hdrEdenBytes hdrMaxExtSemTabSize |
	"open image file and read the header"

	["begin ensure block..."
	f := FileStream readOnlyFileNamed: fileName.
	imageName := f fullName.
	f binary.
	version := self nextLongFrom: f.  "current version: 16r1968 (=6504) vive la revolucion!"
	(self readableFormat: version)
		ifTrue: [swapBytes := false]
		ifFalse: [(version := objectMemory byteSwapped: version) = self imageFormatVersion
					ifTrue: [swapBytes := true]
					ifFalse: [self error: 'incomaptible image format']].
	headerSize := self getLongFromFile: f swap: swapBytes.
	dataSize := self getLongFromFile: f swap: swapBytes.  "length of heap in file"
	oldBaseAddr := self getLongFromFile: f swap: swapBytes.  "object memory base address of image"
	objectMemory specialObjectsOop: (self getLongFromFile: f swap: swapBytes).
	objectMemory lastHash: (self getLongFromFile: f swap: swapBytes).  "Should be loaded from, and saved to the image header"

	savedWindowSize	:= self getLongFromFile: f swap: swapBytes.
	headerFlags		:= self getLongFromFile: f swap: swapBytes.
	self setImageHeaderFlagsFrom: headerFlags.
	extraVMMemory	:= self getLongFromFile: f swap: swapBytes.
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
	self assert: f position = 40.
	hdrEdenBytes		:= self getLongFromFile: f swap: swapBytes.
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
	self assert: f position = 48.
	firstSegSize := self getLongFromFile: f swap: swapBytes.
	objectMemory firstSegmentSize: firstSegSize.
	"allocate interpreter memory"
	heapBase := objectMemory startOfMemory.
	heapSize := dataSize
				+ extraBytes
				+ objectMemory newSpaceBytes
				+ self interpreterAllocationReserveBytes
				+ (objectMemory hasSpurMemoryManagerAPI
					ifTrue: [headerSize]
					ifFalse: [0]).
	objectMemory
		setHeapBase: heapBase
		memoryLimit: heapBase + heapSize
		endOfMemory: heapBase + dataSize. "bogus for Spur"
	objectMemory memory: (Bitmap new: objectMemory memoryLimit // 4).

	"read in the image in bulk, then swap the bytes if necessary"
	f position: headerSize.
	count := objectMemory readHeapFromImageFile: f dataBytes: dataSize.
	count ~= dataSize ifTrue: [self halt].
	]
		ensure: [f close].

	self ensureImageFormatIsUpToDate: swapBytes.

	bytesToShift := objectMemory memoryBaseForImageRead - oldBaseAddr.  "adjust pointers for zero base address"
	Utilities informUser: 'Relocating object pointers...'
				during: [self initializeInterpreter: bytesToShift].

]

{ #category : #'object memory support' }
StackInterpreterSimulator >> preBecomeAction [
	"((objectMemory instVarNamed: 'becomeEffectsFlags') anyMask: BecameCompiledMethodFlag) ifTrue:
		[self halt]."
	super preBecomeAction
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> preGCAction: gcMode [
	"self halt."
	^super preGCAction: gcMode
]

{ #category : #'other primitives' }
StackInterpreterSimulator >> primBitmapcompresstoByteArray [
	^ self primitiveFail
]

{ #category : #'other primitives' }
StackInterpreterSimulator >> primBitmapdecompressfromByteArrayat [
	| indexInt index baOop bmOop baSize bmSize ba bm |
	indexInt := self stackTop.
	(objectMemory isIntegerValue: indexInt) ifFalse: [^ self primitiveFail].
	index := objectMemory integerValueOf: indexInt.
	baOop := self stackValue: 1.
	bmOop := self stackValue: 2.
	baSize := self stSizeOf: baOop.
	bmSize := self stSizeOf: bmOop.
	ba := ByteArray new: baSize.
	bm := Bitmap new: bmSize.

	"Copy the byteArray into ba"
	1 to: baSize do: [:i | ba at: i put: (objectMemory fetchByte: i-1 ofObject: baOop)].

	"Decompress ba into bm"
	bm decompress: bm fromByteArray: ba at: index.

	"Then copy bm into the Bitmap"
	1 to: bmSize do: [:i | objectMemory storeLong32: i-1 ofObject: bmOop withValue: (bm at: i)].
	self pop: 3
]

{ #category : #'other primitives' }
StackInterpreterSimulator >> primStringcomparewithcollated [
	^ self primitiveFail
]

{ #category : #'other primitives' }
StackInterpreterSimulator >> primStringfindSubstringinstartingAtmatchTable [
	^self primitiveFail
]

{ #category : #'other primitives' }
StackInterpreterSimulator >> primStringindexOfAsciiinStringstartingAt [
	^ self primitiveFail
]

{ #category : #'other primitives' }
StackInterpreterSimulator >> primStringtranslatefromtotable [
	^ self primitiveFail
]

{ #category : #'indexing primitives' }
StackInterpreterSimulator >> primitiveAtPut [
	"16r1510B8 = (self stackValue: 2) ifTrue:
		[self halt]."
	^super primitiveAtPut
]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> primitiveBeDisplay [
	"Extended to create a scratch Form for use by showDisplayBits."

	| rcvr destWidth destHeight destDepth |
	rcvr := self stackTop.
	self success: ((objectMemory isPointers: rcvr) and: [(objectMemory lengthOf: rcvr) >= 4]).
	self successful ifTrue: [
		destWidth := self fetchInteger: 1 ofObject: rcvr.
		destHeight := self fetchInteger: 2 ofObject: rcvr.
		destDepth := self fetchInteger: 3 ofObject: rcvr.
	].
	self successful ifTrue: [
		"create a scratch form the same size as Smalltalk displayObj"
		displayForm := Form extent: destWidth @ destHeight
							depth: destDepth.
		displayView ifNotNil: [displayView image: displayForm].
	].
	super primitiveBeDisplay
]

{ #category : #'other primitives' }
StackInterpreterSimulator >> primitiveBeep [

	Beeper beep.
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> primitiveContextAt [
	"self halt."
	^super primitiveContextAt
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> primitiveDirectoryEntry [
	| name pathName array result |
	name := self stringOf: self stackTop.
	pathName := self stringOf: (self stackValue: 1).
	
	self successful ifFalse:
		[^self primitiveFail].

	array := FileDirectory default primLookupEntryIn: pathName name: name.
	array == nil ifTrue:
		[self pop: 3 thenPush: objectMemory nilObject.
		^array].
	array == #badDirectoryPath ifTrue:
		[self halt.
		^self primitiveFail].

	result := self makeDirEntryName: (array at: 1) size: (array at: 1) size
				createDate: (array at: 2) modDate: (array at: 3)
				isDir: (array at: 4)  fileSize: (array at: 5).
	self pop: 3.
	self push: result
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> primitiveDirectoryLookup [
	| index pathName array result |
	index := self stackIntegerValue: 0.
	pathName := (self stringOf: (self stackValue: 1)).
	
	self successful ifFalse:
		[^self primitiveFail].

	array := FileDirectory default primLookupEntryIn: pathName index: index.

	array == nil ifTrue:
		[self pop: 3 thenPush: objectMemory nilObject.
		^array].
	array == #badDirectoryPath ifTrue:
		["self halt."
		^self primitiveFail].

	result := self makeDirEntryName: (array at: 1) size: (array at: 1) size
				createDate: (array at: 2) modDate: (array at: 3)
				isDir: (array at: 4)  fileSize: (array at: 5).
	self pop: 3 thenPush: result
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> primitiveDoPrimitiveWithArgs [
	NewspeakVM ifFalse: [self halt].
	^super primitiveDoPrimitiveWithArgs
]

{ #category : #'control primitives' }
StackInterpreterSimulator >> primitiveExecuteMethod [
	self halt: thisContext selector.
	^super primitiveExecuteMethod
]

{ #category : #'control primitives' }
StackInterpreterSimulator >> primitiveExecuteMethodArgsArray [
	"self halt: thisContext selector."
	(objectMemory isOopCompiledMethod: self stackTop) ifFalse:
		[self halt].
	^super primitiveExecuteMethodArgsArray
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> primitiveFailFor: reasonCode [
	"self halt."
	^super primitiveFailFor: reasonCode
]

{ #category : #'other primitives' }
StackInterpreterSimulator >> primitiveGetAttribute [
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
StackInterpreterSimulator >> primitiveIdentityHash [
	"| oop |
	oop := self stackTop.
	((objectMemory isBytes: oop)
	and: [(objectMemory lengthOf: oop) = 'smallSelect' size
	and: [(self stringOf: oop) = 'smallSelect']]) ifTrue:
		[self halt]."
	^super primitiveIdentityHash
]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> primitiveKbdNext [

	self pop: 1.
	Sensor keyboardPressed
		ifTrue: [self pushInteger: Sensor primKbdNext]
		ifFalse: [self push: objectMemory nilObject]
]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> primitiveKbdPeek [

	self pop: 1.
	Sensor keyboardPressed
		ifTrue: [self pushInteger: Sensor primKbdPeek]
		ifFalse: [self push: objectMemory nilObject]
]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> primitiveMouseButtons [
	| buttons |
	self pop: 1.
	buttons := Sensor primMouseButtons.
	self pushInteger: buttons
]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> primitiveMousePoint [

	| relPt |
	self pop: 1.
	displayForm == nil
		ifTrue: [self push: (self makePointwithxValue: 99 yValue: 66)]
		ifFalse: [relPt := Sensor cursorPoint - self displayLocation.
				self push: (self makePointwithxValue: relPt x yValue: relPt y)]
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> primitiveNewWithArg [
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
StackInterpreterSimulator >> primitiveObject: actualReceiver perform: selector withArguments: argumentArray lookedUpIn: lookupClass [
	"Override to allow simulator to filter start-up items to avoid as-yet unsimulatable plugins."

	(self filterPerformOf: selector to: actualReceiver) ifTrue:
		[^self pop: argumentCount + 1 thenPush: actualReceiver].
	^super primitiveObject: actualReceiver perform: selector withArguments: argumentArray lookedUpIn: lookupClass
]

{ #category : #'object access primitives' }
StackInterpreterSimulator >> primitiveObjectPointsTo [
	"self halt."
	^super primitiveObjectPointsTo
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> primitivePerform [
	| selector |
	selector := self stackValue: argumentCount - 1.
	self sendBreakpoint: selector receiver: (self stackValue: argumentCount).
	(self filterPerformOf: selector to: (self stackValue: argumentCount)) ifTrue:
		[^self pop: argumentCount].
	^super primitivePerform
]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> primitiveScreenSize [
	| size |
	size := self desiredDisplayExtent min: 800@640.
	self pop: 1 thenPush: (self makePointwithxValue: size x yValue: size y)
]

{ #category : #'object access primitives' }
StackInterpreterSimulator >> primitiveStoreStackp [
	"self printContext: (self stackValue: 1).
	self halt."
	super primitiveStoreStackp.
	"self printContext: self stackTop"
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> primitiveSuspend [
	"Catch errors before we start the whole morphic error process"

	"byteCount > 1000000 ifTrue: [self halt]."  "Ignore early process activity"
	^ super primitiveSuspend
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> primitiveWait [
	"Catch errors before we start the whole morphic error process"

	"byteCount > 1000000 ifTrue: [self halt]."  "Ignore early process activity"
	^ super primitiveWait
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> print: it [

	traceOn ifTrue:
		[it isString ifTrue: [transcript nextPutAll: it] ifFalse: [it printOn: transcript]]
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> printChar: aByte [

	traceOn ifTrue: [ transcript nextPut: aByte asCharacter ].
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> printCurrentBytecodeOn: aStream [
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
StackInterpreterSimulator >> printECS [
	self printCallStackFP: framePointer
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> printFrameFlagsForFP: theFP [
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
StackInterpreterSimulator >> printFrameOop: name at: address [
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
StackInterpreterSimulator >> printFrameThing: name andFrame: theFP at: address [
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
StackInterpreterSimulator >> printFrameThing: name at: address [
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
StackInterpreterSimulator >> printHex: anInteger [

	traceOn ifTrue:
		[| it16 |
		 it16 := anInteger radix: 16.
		 transcript
			next: 8 - it16 size put: Character space;
			nextPutAll: (anInteger storeStringBase: 16)]
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> printHexnp: anInteger [

	traceOn ifTrue:
		[transcript nextPutAll: (anInteger storeStringBase: 16)]
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> printLCS [
	self printCallStackFP: localFP
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> printNum: anInteger [

	traceOn ifTrue: [ transcript print: anInteger ].
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> printStringForCurrentBytecode [
	^String streamContents: [:str| self printCurrentBytecodeOn: str]
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> printStringOf: oop [

	super printStringOf: oop.
	traceOn ifTrue: [transcript flush]
]

{ #category : #testing }
StackInterpreterSimulator >> profile: nBytecodes [
	"(InterpreterSimulator new openOn: 'clonex.image') profile: 60000"
	transcript clear.
	byteCount := 0.
	MessageTally spyOn: [self runForNBytes: nBytecodes].
	self close
]

{ #category : #testing }
StackInterpreterSimulator >> profileSends: nBytecodes [
	"(InterpreterSimulator new openOn: 'clonex.image') profileSends: 5000"
	MessageTally tallySendsTo: self
		inBlock: [self runForNBytes: nBytecodes]
		showTree: true.
	self close
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> pushMaybeContextReceiverVariable: index [
	"(index = SenderIndex or: [index = ClosureIndex]) ifTrue: [self halt]."
	^super pushMaybeContextReceiverVariable: index
]

{ #category : #'event forwarding' }
StackInterpreterSimulator >> queueForwardedEvent:evt [
	eventQueue isNil
		ifTrue:[eventQueue := SharedQueue new].
	eventQueue nextPut: evt.
]

{ #category : #'image save/restore' }
StackInterpreterSimulator >> reverseBytesInImage [
	Utilities
		informUser: 'Swapping bytes of foreign image...'
		during: [super reverseBytesInImage]
]

{ #category : #'method lookup cache' }
StackInterpreterSimulator >> rewriteMethodCacheEntryForExternalPrimitiveToFunction: localPrimAddress [
	self assert: (localPrimAddress isSymbol
			or: [localPrimAddress isInteger
				and: [localPrimAddress = 0
					or: [(localPrimAddress between: 256 and: 519)
					or: [localPrimAddress > 1000]]]]).
	^super rewriteMethodCacheEntryForExternalPrimitiveToFunction: localPrimAddress
]

{ #category : #testing }
StackInterpreterSimulator >> run [
	"Just run"
	quitBlock := [displayView ifNotNil:
				   [displayView containingWindow ifNotNil:
					[:topWindow|
					((World submorphs includes: topWindow)
					 and: [UIManager default confirm: 'close?']) ifTrue:
						[topWindow delete]]].
				  ^self].
	self initStackPages.
	self loadInitialContext.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue:
		[self assertValidExecutionPointers.
		 atEachStepBlock value. "N.B. may be nil"
		 self dispatchOn: currentBytecode in: BytecodeTable.
		 self incrementByteCount].
	localIP := localIP - 1.
	"undo the pre-increment of IP before returning"
	self externalizeIPandSP
]

{ #category : #testing }
StackInterpreterSimulator >> runAtEachStep: aBlock [
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
StackInterpreterSimulator >> runAtEachStep: aBlock breakCount: breakCount [
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
StackInterpreterSimulator >> runForNBytes: nBytecodes [ 
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

{ #category : #testing }
StackInterpreterSimulator >> runWithBreakCount: theBreakCount [
	"Just run, halting when byteCount is reached"
	quitBlock := [displayView ifNotNil:
				   [displayView containingWindow ifNotNil:
					[:topWindow|
					((World submorphs includes: topWindow)
					 and: [UIManager default confirm: 'close?']) ifTrue:
						[topWindow delete]]].
				  ^self].
	breakCount := theBreakCount.
	self initStackPages.
	self loadInitialContext.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue:
		[self assertValidExecutionPointers.
		 self dispatchOn: currentBytecode in: BytecodeTable.
		 self incrementByteCount].
	localIP := localIP - 1.
	"undo the pre-increment of IP before returning"
	self externalizeIPandSP
]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> savedWindowSize [
	^savedWindowSize ifNil: [0]
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> sendBreak: selectorString point: selectorLength receiver: receiverOrNil [
	"self shortPrintFrameAndCallers: localFP"
	| i |
	breakSelectorLength = selectorLength ifTrue:
		[i := breakSelectorLength.
		 [i > 0] whileTrue:
			[(objectMemory byteAt: selectorString + i - 1) = (breakSelector at: i) asInteger
				ifTrue: [(i := i - 1) = 0 ifTrue:
							[self halt: 'Send of '
									, breakSelector,
									(receiverOrNil
										ifNotNil: [' to ', (self shortPrint: receiverOrNil)]
										ifNil: [''])]]
				ifFalse: [i := 0]]]
]

{ #category : #'spur bootstrap' }
StackInterpreterSimulator >> setDisplayForm: aForm [
	displayForm := aForm
]

{ #category : #'debug support' }
StackInterpreterSimulator >> shortPrint: oop [
	| name classOop |
	(objectMemory isImmediate: oop) ifTrue:
		[(objectMemory isImmediateCharacter: oop) ifTrue:
			[^(objectMemory characterValueOf: oop) < 256
				ifTrue:
					['=$' , (objectMemory characterValueOf: oop) printString , 
					' (' , (String with: (Character value: (objectMemory characterValueOf: oop))) , ')']
				ifFalse:
					['=$' , (objectMemory characterValueOf: oop) printString, '(???)']].
		(objectMemory isIntegerObject: oop) ifTrue:
			[^ '=' , (objectMemory integerValueOf: oop) printString , 
			' (' , (objectMemory integerValueOf: oop) hex , ')'].
		^'= UNKNOWN IMMEDIATE', ' (' , (objectMemory integerValueOf: oop) hex , ')'].
	(objectMemory addressCouldBeObj: oop) ifFalse:
		[^(oop bitAnd: objectMemory allocationUnit - 1) ~= 0
			ifTrue: [' is misaligned']
			ifFalse: [' is not on the heap']].
	(objectMemory isFreeObject: oop) ifTrue:
		[^' is a free chunk of size ', (objectMemory sizeOfFree: oop) printString].
	(objectMemory isForwarded: oop) ifTrue:
		[^' is a forwarded object to ', (objectMemory followForwarded: oop) hex,
			' of slot size ', (objectMemory numSlotsOfAny: oop) printString].
	classOop := objectMemory fetchClassOfNonImm: oop.
	classOop ifNil: [^' has a nil class!!'].
	(objectMemory numSlotsOf: classOop) = metaclassNumSlots ifTrue:
		[^'class ' , (self nameOfClass: oop)].
	name := self nameOfClass: classOop.
	name size = 0 ifTrue: [name := '??'].
	name = 'String' ifTrue: [^ (self stringOf: oop) printString].
	name = 'ByteString' ifTrue: [^ (self stringOf: oop) printString].
	name = 'Symbol' ifTrue: [^ '#' , (self stringOf: oop)].
	name = 'ByteSymbol' ifTrue: [^ '#' , (self stringOf: oop)].
	name = 'Character' ifTrue: "SpurMemoryManager has immediate Characters; ObjectMemory does not"
		[^ '=' , (Character value: (objectMemory integerValueOf: 
				(objectMemory fetchPointer: 0 ofObject: oop))) printString].
	name = 'UndefinedObject' ifTrue: [^ 'nil'].
	name = 'False' ifTrue: [^ 'false'].
	name = 'True' ifTrue: [^ 'true'].
	name = 'Float' ifTrue: [^ '=' , (self dbgFloatValueOf: oop) printString].
	(#('Association' 'ReadOnlyVariableBinding' 'VariableBinding') includes: name) ifTrue:
		[^ '(' ,
		(self shortPrint: (self longAt: oop + BaseHeaderSize)) ,
		' -> ' ,
		(self longAt: oop + BaseHeaderSize + BytesPerWord) hex8 , ')'].
	^(('AEIOU' includes: name first) ifTrue: ['an '] ifFalse: ['a ']), name
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> shortPrintContext: aContext [
	transcript ensureCr.
	^super shortPrintContext: aContext
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> shortPrintFrame: theFP [
	self transcript ensureCr.
	^super shortPrintFrame: theFP
]

{ #category : #'I/O primitives' }
StackInterpreterSimulator >> showDisplayBits: destBits w: w h: h d: d left: left right: right top: top bottom: bottom [
	| raster pixPerWord simDisp realDisp rect |
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
	displayView ifNotNil: [^ displayView changed].
	
	"If running without a view, just blat the bits onto the screen..."
	rect := 0 @ top corner: displayForm width @ bottom.
	Display
		copy: (rect translateBy: self displayLocation)
		from: rect topLeft
		in: displayForm
		rule: Form over
]

{ #category : #'process primitive support' }
StackInterpreterSimulator >> signalSemaphoreWithIndex: index [
	"This is a non-thread-safe simulation.  See platforms/Cross/vm/sqExternalSemaphores.c
	 for the real code."
	index <= 0 ifTrue: [^false].
	index > externalSemaphoreSignalRequests size ifTrue:
		[| newRequests newResponses |
		newRequests := Array new: 1 << index highBit withAll: 0.
		newResponses := newRequests copy.
		newRequests
			replaceFrom: 1
			to: externalSemaphoreSignalRequests size
			with: externalSemaphoreSignalRequests
			startingAt: 1.
		newResponses
			replaceFrom: 1
			to: externalSemaphoreSignalResponses size
			with: externalSemaphoreSignalResponses
			startingAt: 1].
	externalSemaphoreSignalRequests
		at: index
		put: (externalSemaphoreSignalRequests at: index) + 1.
	^true
]

{ #category : #testing }
StackInterpreterSimulator >> singleStep [
	self assertValidExecutionPointers.
	atEachStepBlock value. "N.B. may be nil"
	self dispatchOn: currentBytecode in: BytecodeTable.
	self incrementByteCount
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> space [

	traceOn ifTrue: [ transcript space ]
]

{ #category : #'plugin support' }
StackInterpreterSimulator >> sqGetInterpreterProxy [
	"I am basically my own proxy..."
	^self
]

{ #category : #'memory access' }
StackInterpreterSimulator >> sqMemoryExtraBytesLeft: includingSwap [
	^0
]

{ #category : #'memory access' }
StackInterpreterSimulator >> sqShrinkMemory: oldLimit By: delta [
	transcript show: 'shrink memory from ', oldLimit printString, ' by ', delta printString, ' remember it doesn''t actually shrink in simulation'; cr.

	^ oldLimit
]

{ #category : #'spur bootstrap' }
StackInterpreterSimulator >> stackPage [
	^stackPage
]

{ #category : #'simulation only' }
StackInterpreterSimulator >> stackPages [
	^stackPages
]

{ #category : #'simulation only' }
StackInterpreterSimulator >> startInContextSuchThat: aBlock [
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
StackInterpreterSimulator >> startInSender [
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
StackInterpreterSimulator >> startOfMemory [
	self shouldNotImplement
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> success: successBoolean [
	"successBoolean ifFalse:
		[self halt]."
	^super success: successBoolean
]

{ #category : #'simulation only' }
StackInterpreterSimulator >> systemAttributes [
	^systemAttributes
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> tab [

	traceOn ifTrue: [ transcript tab ].
]

{ #category : #testing }
StackInterpreterSimulator >> test [
	self initStackPages.
	self loadInitialContext.
	transcript clear.
	byteCount := 0.
	breakCount := -1.
	quitBlock := [^self].
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
StackInterpreterSimulator >> test1 [
	self initStackPages.
	self loadInitialContext.
	transcript clear.
	byteCount := 0.
	breakCount := -1.
	self setBreakSelector: #blockCopy:.
	quitBlock := [^self].
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
StackInterpreterSimulator >> testBecome [
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
StackInterpreterSimulator >> testBreakCount: breakCount printSends: shouldPrintSends printFrames: shouldPrintFrames printBytecodes: shouldPrintBytecodes [
	self initStackPages.
	self loadInitialContext.
	transcript clear.
	byteCount := 0.
	quitBlock := [^self].
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
StackInterpreterSimulator >> testWithFramePrint [
	printFrameAtEachStep := printBytecodeAtEachStep := true.
	self test
]

{ #category : #UI }
StackInterpreterSimulator >> toggleTranscript [
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
StackInterpreterSimulator >> toggleTranscriptForSimulatorMorph: aTranscriptStreamOrTranscript [
	"tty think this through when not so tired"
	self flag: 'tty'.
	transcript ifNil: [transcript := Transcript. ^self].
	displayView ifNil: [^self changed: #flash].
	transcript := transcript = Transcript
					ifTrue: [aTranscriptStreamOrTranscript]
					ifFalse: [Transcript]
]

{ #category : #accessing }
StackInterpreterSimulator >> transcript [
	^transcript
]

{ #category : #accessing }
StackInterpreterSimulator >> transcript: aTranscript [
	transcript := aTranscript
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> transferTo: aProc [
	"self halt."
	^super transferTo: aProc
]

{ #category : #'interpreter shell' }
StackInterpreterSimulator >> unableToReadImageError [
	self error:  'Read failed or premature end of image file'
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> updateStateOfSpouseContextForFrame: theFP WithSP: theSP [
	"(self frameContext: theFP) = 22163268 ifTrue:
		[self halt]."
	^super updateStateOfSpouseContextForFrame: theFP WithSP: theSP
]

{ #category : #UI }
StackInterpreterSimulator >> utilitiesMenu: aMenuMorph [
	aMenuMorph
		add: 'toggle transcript' action: #toggleTranscript;
		add: 'clone VM' action: #cloneSimulation;
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
		add: 'print call stack of...' action: [(self promptHex: 'context or process oop') ifNotNil: [:obj| self printCallStackOf: obj]];
		add: 'print call stack of frame...' action: [(self promptHex: 'frame') ifNotNil: [:fp| self printCallStackFP: fp]];
		add: 'print all stacks' action: #printAllStacks;
		add: 'write back local ptrs' action: [stackPointer := localSP. framePointer := localFP. instructionPointer := localIP.
											self writeBackHeadFramePointers];
		add: 'print prim trace log' action: #dumpPrimTraceLog;
		addLine;
		add: 'print oop...' action: [(self promptHex: 'print oop') ifNotNil: [:oop| self printOop: oop]];
		add: 'long print oop...' action: [(self promptHex: 'print oop') ifNotNil: [:oop| self longPrintOop: oop]];
		addLine;
		add: 'inspect object memory' target: objectMemory action: #inspect;
		add: 'inspect interpreter' action: #inspect;
		addLine;
		add: 'set break count...' action: [|s| s := UIManager default request: 'break count (dec)'.
											s notEmpty ifTrue: [breakCount := Integer readFrom: s readStream]];
		add: 'set break selector...' action: [|s| s := UIManager default request: 'break selector'.
											s notEmpty ifTrue: [self setBreakSelector: s]];
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

{ #category : #testing }
StackInterpreterSimulator >> validOop: oop [
	" Return true if oop appears to be valid "
	(oop bitAnd: 1) = 1 ifTrue: [^ true].  "Integer"
	(oop bitAnd: 3) = 0 ifFalse: [^ false].  "Uneven address"
	oop >= objectMemory endOfMemory ifTrue: [^ false].  "Out of range"
	"could test if within the first large freeblock"
	(self longAt: oop) = 4 ifTrue: [^ false].
	(objectMemory headerType: oop) = 2 ifTrue: [^ false].	"Free object"
	^ true
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> vmPathGet: stringBase Length: stringSize [
	| pathName stringOop |
	pathName := Smalltalk vmPath.
	stringOop := stringBase - BaseHeaderSize. "Due to C call in Interp"
	1 to: stringSize do:
		[:i | objectMemory storeByte: i-1 ofObject: stringOop
			withValue: (pathName at: i) asciiValue].

]

{ #category : #'file primitives' }
StackInterpreterSimulator >> vmPathSize [
	^ Smalltalk vmPath size
]

{ #category : #'debug support' }
StackInterpreterSimulator >> warning: aString [
	transcript cr; nextPutAll: aString; flush
]

{ #category : #'I/O primitives support' }
StackInterpreterSimulator >> warpBits [

	^ myBitBlt warpBits
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> withMemoryProtectionDo: aBlock [
	self writeProtectMemory.
	stackPages writeProtectMemory.
	^aBlock ensure:
		[self writeEnableMemory.
		 stackPages writeEnableMemory]
]

{ #category : #'frame access' }
StackInterpreterSimulator >> withSmallIntegerTags: value [
	"The simulator works with strictly positive bit patterns"
	^value < 0
		ifTrue: [(value bitAnd: 16rFFFFFFFF) + 1]
		ifFalse: [value + 1]
]

{ #category : #'frame access' }
StackInterpreterSimulator >> withoutSmallIntegerTags: anInteger [
	self assert: (anInteger >= 0 and: [anInteger highBit <= 32]).
	^(anInteger bitAnd: 16r80000000) ~= 0
		ifTrue: ["negative"
				(anInteger bitAnd: 16r7FFFFFFE) - 16r80000000]
		ifFalse: ["positive"
				anInteger - 1]
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> writeEnableMemory [
	objectMemory memory: objectMemory memory array
]

{ #category : #'image save/restore' }
StackInterpreterSimulator >> writeImageFileIO [
	"Write the image to a file as an image snapshot."

	| headerSize file |
	BytesPerWord = 4 ifFalse: [self error: 'Not rewritten for 64 bits yet'].
	headerSize := 64.

	(file := FileStream fileNamed: imageName) ifNil:
		[self primitiveFail.
		 ^nil].
	[
		file binary.

		{
			self imageFormatVersion.
			headerSize.
			objectMemory imageSizeToWrite.
			objectMemory baseAddressOfImage.
			objectMemory specialObjectsOop.
			objectMemory lastHash.
			self ioScreenSize.
			self getImageHeaderFlags.
			extraVMMemory ifNil: [0]
		}
			do: [:long | self putLong: long toFile: file].

		{	desiredNumStackPages. self unknownShortOrCodeSizeInKs } do:
			[:short| self putShort: short toFile: file].

		self putLong: desiredEdenBytes toFile: file.

		{	maxExtSemTabSizeSet ifTrue: [self ioGetMaxExtSemTableSize] ifFalse: [0]. 0 } do:
			[:short| self putShort: short toFile: file].

		objectMemory hasSpurMemoryManagerAPI
			ifTrue:
				[| bytesWritten |
				 self putLong: objectMemory firstSegmentBytes toFile: file."Pad the rest of the header."
				 3 timesRepeat: [self putLong: 0 toFile: file].

				"Position the file after the header."
				file position: headerSize.
				bytesWritten := objectMemory segmentManager writeImageToFile: file.
				self assert: bytesWritten = objectMemory imageSizeToWrite]
			ifFalse:
				["Pad the rest of the header."
				4 timesRepeat: [self putLong: 0 toFile: file].

				"Position the file after the header."
				file position: headerSize.

				"Write the object memory."
				objectMemory baseAddressOfImage // 4 + 1
					to: objectMemory baseAddressOfImage + objectMemory imageSizeToWrite // 4
					do: [:index |
						self
							putLong: (objectMemory memory at: index)
							toFile: file]].
	
		self success: true
	]
		ensure: [file ifNotNil: [file close]]
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> writeProtectMemory [
	objectMemory memory: (ReadOnlyArrayWrapper around: objectMemory memory)
]
