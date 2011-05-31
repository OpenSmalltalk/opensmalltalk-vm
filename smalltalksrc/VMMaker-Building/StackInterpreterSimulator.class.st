"
This class defines basic memory access and primitive simulation so that the StackInterpreter can run simulated in the Squeak environment.  It also defines a number of handy object viewing methods to facilitate pawing around in the object memory.

To see the thing actually run, you could (after backing up this image and changes), execute

	(StackInterpreterSimulator new openOn: Smalltalk imageName) test

and be patient both to wait for things to happen, and to accept various things that may go wrong depending on how large or unusual your image may be.  We usually do this with a small and simple benchmark image. You will probably have more luck using InterpreteSimulatorLSB or InterpreterSimulatorMSB as befits your machine.
"
Class {
	#name : #StackInterpreterSimulator,
	#superclass : #StackInterpreterPrimitives,
	#instVars : [
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
		'startMicroseconds',
		'externalSemaphoreSignalRequests',
		'externalSemaphoreSignalResponses',
		'extSemTabSize',
		'atEachStepBlock',
		'disableBooleanCheat'
	],
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #'instance creation' }
StackInterpreterSimulator class >> new [
	^ self == StackInterpreterSimulator
		ifTrue: [SmalltalkImage current endianness == #big
				ifTrue: [self notYetImplemented"StackInterpreterSimulatorMSB new"]
				ifFalse: [StackInterpreterSimulatorLSB new]]
		ifFalse: [super new]
]

{ #category : #'debug support' }
StackInterpreterSimulator >> allObjectsDo: objBlock [

	| oop |
	oop := objectMemory firstObject.
	[oop < objectMemory endOfMemory] whileTrue:
			[(objectMemory isFreeObject: oop)
				ifFalse: [objBlock value: oop].
			oop := objectMemory objectAfter: oop].

]

{ #category : #'debug support' }
StackInterpreterSimulator >> allObjectsSelect: objBlock [
	"self allObjectsSelect: [:oop | (self baseHeader: oop) = 1234]"

	| oop selected |
	oop := objectMemory firstObject.
	selected := OrderedCollection new.
	[oop < objectMemory endOfMemory] whileTrue:
			[(objectMemory isFreeObject: oop)
				ifFalse: [(objBlock value: oop) ifTrue: [selected addLast: oop]].
			oop := objectMemory objectAfter: oop].
	^ selected
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> allocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOop h3: extendedSize doFill: doFill format: format [
	| newObj |
	newObj := super allocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOop h3: extendedSize doFill: doFill format: format.
	"newObj = 22186072 ifTrue: [self halt]."
	"byteCount < 600000 ifTrue: [^ newObj]."
	"(self baseHeader: newObj) =  16r0FCC0600 ifTrue: [self halt]."
	^newObj
]

{ #category : #testing }
StackInterpreterSimulator >> assertValidExecutionPointers [
	self assertValidExecutionPointe: localIP r: localFP s: localSP
]

{ #category : #'return bytecodes' }
StackInterpreterSimulator >> baseFrameReturn [
	| contextToReturnTo |
	contextToReturnTo := self frameCallerContext: localFP.
	((self isContext: contextToReturnTo)
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
	^self subclassResponsibility
]

{ #category : #'memory access' }
StackInterpreterSimulator >> byteAt: byteAddress put: byte [
	^self subclassResponsibility
]

{ #category : #'memory access' }
StackInterpreterSimulator >> byteAtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	pointer is a raw address, and byte is an 8-bit quantity."

	^ self byteAt: pointer
]

{ #category : #'memory access' }
StackInterpreterSimulator >> byteAtPointer: pointer put: byteValue [
	"This gets implemented by Macros in C, where its types will also be checked.
	pointer is a raw address, and byteValue is an 8-bit quantity."

	^ self byteAt: pointer  put: byteValue
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

{ #category : #initialization }
StackInterpreterSimulator >> close [  "close any files that ST may have opened"
	filesOpen do: [:f | f close]
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> commonSend [
	printSends ifTrue:
		[self print: byteCount; space; printStringOf: messageSelector; cr].
	^super commonSend
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

	"self halt: (self stringOf: messageSelector)."

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

{ #category : #'interpreter shell' }
StackInterpreterSimulator >> dispatchOn: anInteger in: selectorArray [
	"Simulate a case statement via selector table lookup.
	The given integer must be between 0 and selectorArray size-1, inclusive.
	For speed, no range test is done, since it is done by the at: operation.
	Note that, unlike many other arrays used in the Interpreter, this method expect NO CArrayAccessor wrapping - it would duplicate the +1. Maybe this would be better updated to make it all uniform"

	self perform: (selectorArray at: (anInteger + 1)).
]

{ #category : #'I/O primitives support' }
StackInterpreterSimulator >> displayLocation [

	^ Display extent - displayForm extent - (10@10)
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

{ #category : #'debugging traps' }
StackInterpreterSimulator >> eeAllocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOop h3: extendedSize doFill: doFill format: format [
	| newObj |
	newObj := super eeAllocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOop h3: extendedSize doFill: doFill format: format.
	"newObj = 22163268 ifTrue: [self halt]."
	"byteCount < 600000 ifTrue: [^ newObj]."
	"(self baseHeader: newObj) =  16r0FCC0600 ifTrue: [self halt]."
	^newObj
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
		(self isContext: anOop) ifTrue:
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

{ #category : #'float primitives' }
StackInterpreterSimulator >> fetchFloatAt: floatBitsAddress into: aFloat [

	aFloat at: 1 put: (self long32At: floatBitsAddress).
	aFloat at: 2 put: (self long32At: floatBitsAddress+4).

]

{ #category : #'file primitives' }
StackInterpreterSimulator >> fileValueOf: integerPointer [
	"Convert the (integer) fileID to the actual fileStream it uses"
	self success: (objectMemory isIntegerObject: integerPointer).
	self successful
		ifTrue: [^ filesOpen at: (objectMemory integerValueOf: integerPointer)]
		ifFalse: [^ nil]
]

{ #category : #testing }
StackInterpreterSimulator >> findNewMethodInClass: class [
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
	super findNewMethodInClass: class.
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
	mappedPluginEntries := #().
	super flushExternalPrimitives.
]

{ #category : #'frame access' }
StackInterpreterSimulator >> frameOfMarriedContext: aContext [ 
	| senderOop |
	senderOop := objectMemory fetchPointer: SenderIndex ofObject: aContext.
	self assert: (objectMemory isIntegerObject: senderOop).
	^self withoutSmallIntegerTags: senderOop
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

{ #category : #'debug support' }
StackInterpreterSimulator >> fullGC [
	transcript cr; show:'<Running full GC ...'.
	super fullGC.
	transcript show: ' done>'.
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

{ #category : #'interpreter shell' }
StackInterpreterSimulator >> incrementByteCount [
	(byteCount := byteCount + 1) = breakCount ifTrue:
		[self doOrDefer: [self changed: #byteCountText].
		 self halt].
	byteCount \\ 1000 = 0 ifTrue:
		[self doOrDefer: [self changed: #byteCountText].
		 self forceInterruptCheck.
		 byteCount \\ 10000 = 0 ifTrue: [self fullDisplayUpdate]]
]

{ #category : #'debug support' }
StackInterpreterSimulator >> incrementalGC [
	transcript cr; nextPutAll: 'incrementalGC ('; print: byteCount; nextPut: $); flush.
	^super incrementalGC
]

{ #category : #initialization }
StackInterpreterSimulator >> initialize [
	"Initialize the StackInterpreterSimulator when running the interpreter
	 inside Smalltalk. The primary responsibility of this method is to allocate
	 Smalltalk Arrays for variables that will be declared as statically-allocated
	 global arrays in the translated code."

	| objectMemoryClass |

	"initialize class variables"
	objectMemory ifNotNil:
		[^self halt].

	objectMemoryClass := self class objectMemoryClass.

	objectMemoryClass initBytesPerWord: objectMemoryClass bytesPerWord.
	objectMemoryClass initialize.
	StackInterpreter initialize.

	super initialize.
	objectMemory := objectMemoryClass simulatorClass new.
	objectMemory coInterpreter: self.

	"Note: we must initialize ConstMinusOne differently for simulation,
		due to the fact that the simulator works only with +ve 32-bit values"
	ConstMinusOne := objectMemory integerObjectOf: -1.

	methodCache := Array new: MethodCacheSize.
	atCache := Array new: AtCacheTotalSize.
	self flushMethodCache.
	self flushAtCache.
	gcSemaphoreIndex := 0.
	externalSemaphoreSignalRequests := externalSemaphoreSignalResponses := #().
	externalPrimitiveTable := CArrayAccessor on: (Array new: MaxExternalPrimitiveTableSize).
	externalPrimitiveTableFirstFreeIndex := 0.
	primitiveTable := self class primitiveTable copy.
	pluginList := #().
	mappedPluginEntries := #().
	desiredNumStackPages := desiredEdenBytes := 0.
	startMicroseconds := Time totalSeconds * 1000000.

	"initialize InterpreterSimulator variables used for debugging"
	byteCount := 0.
	sendCount := 0.
	quitBlock := [^ self].
	traceOn := true.
	printSends := printReturns := printFrameAtEachStep := printBytecodeAtEachStep := false.
	myBitBlt := BitBltSimulator new setInterpreter: self.
	filesOpen := OrderedCollection new.
	transcript := Transcript.
	displayForm := 'Display has not yet been installed' asDisplayText form.
	suppressHeartbeatFlag := false.
	extSemTabSize := 256.
	disableBooleanCheat := false
]

{ #category : #'frame access' }
StackInterpreterSimulator >> instVar: index ofContext: aMarriedContext put: anOop [
	| imMarried shesMarried result |
	index == SenderIndex ifTrue:
		[imMarried := self checkIsStillMarriedContext: aMarriedContext currentFP: localFP.
		(self isContext: anOop) ifTrue:
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

{ #category : #'memory access' }
StackInterpreterSimulator >> integerObjectOf: value [
	"The simulator works with strictly positive bit patterns"
	value < 0
		ifTrue: [^ ((16r80000000 + value) << 1) + 1]
		ifFalse: [^ (value << 1) + 1]
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
	super internalFindNewMethod
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> internalMustBeBoolean [
	self halt.
	^super internalMustBeBoolean
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

	self primitiveFail.

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
StackInterpreterSimulator >> ioLoadExternalFunction: functionName OfLength: functionLength FromModule: moduleName OfLength: moduleLength [
	"Load and return the requested function from a module"
	| pluginString functionString |
	pluginString := String new: moduleLength.
	1 to: moduleLength do:[:i| pluginString byteAt: i put: (self byteAt: moduleName+i-1)].
	functionString := String new: functionLength.
	1 to: functionLength do:[:i| functionString byteAt: i put: (self byteAt: functionName+i-1)].
	functionString := functionString asSymbol.
	^self ioLoadFunction: functionString From: pluginString
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

{ #category : #'interpreter shell' }
StackInterpreterSimulator >> isIntegerValue: valueWord [ 
	^ valueWord >= 16r-40000000 and: [valueWord <= 16r3FFFFFFF]
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

{ #category : #'plugin support' }
StackInterpreterSimulator >> loadNewPlugin: pluginString [
	| plugin plugins simulatorClasses |
	transcript cr; show: 'Looking for module ', pluginString.
	"but *why*??"
	(#('FloatArrayPlugin' 'Matrix2x3Plugin') includes: pluginString) ifTrue:
		[transcript show: ' ... defeated'. ^nil].
	plugins := InterpreterPlugin allSubclasses select: [:psc| psc moduleName asString = pluginString asString].
	simulatorClasses := (plugins
							select: [:psc| psc simulatorClass notNil]
							thenCollect: [:psc| psc simulatorClass]) asSet.
	simulatorClasses isEmpty ifTrue: [transcript show: ' ... not found'. ^nil].
	simulatorClasses size > 1 ifTrue: [^self error: 'This won''t work...'].
	plugins size > 1 ifTrue:
		[transcript show: '...multiple plugin classes; choosing ', plugins last name].
	plugin := simulatorClasses anyOne newFor: plugins last. "hopefully lowest in the hierarchy..."
	plugin setInterpreter: objectMemory. "Ignore return value from setInterpreter"
	(plugin respondsTo: #initialiseModule) ifTrue:
		[plugin initialiseModule ifFalse:
			[transcript show: ' ... initialiser failed'. ^nil]]. "module initialiser failed"
	pluginList := pluginList copyWith: (pluginString asString -> plugin).
	transcript show: ' ... loaded'.
	^pluginList last
]

{ #category : #testing }
StackInterpreterSimulator >> logOfBytesVerify: nBytes fromFileNamed: fileName fromStart: loggingStart [
	"Verify a questionable interpreter against a successful run"
	"self logOfBytesVerify: 10000 fromFileNamed: 'clone32Bytecodes.log' "
	
	| logFile rightByte prevCtxt |
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
			[rightByte := logFile next.
			 currentBytecode = rightByte ifFalse:
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
			[logFile nextPut: currentBytecode].
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
StackInterpreterSimulator >> long32At: byteAddress [
	"Return the 32-bit word at byteAddress which must be 0 mod 4."

	^ self longAt: byteAddress
]

{ #category : #'memory access' }
StackInterpreterSimulator >> long32At: byteAddress put: a32BitValue [
	"Store the 32-bit value at byteAddress which must be 0 mod 4."

	^ self longAt: byteAddress put: a32BitValue
]

{ #category : #'memory access' }
StackInterpreterSimulator >> longAt: byteAddress [
	"Note: Adjusted for Smalltalk's 1-based array indexing."

	^objectMemory memory at: (byteAddress // 4) + 1
]

{ #category : #'memory access' }
StackInterpreterSimulator >> longAt: byteAddress put: a32BitValue [
	"Note: Adjusted for Smalltalk's 1-based array indexing."

	^objectMemory memory at: (byteAddress // 4) + 1 put: a32BitValue
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> makeDirEntryName: entryName size: entryNameSize
	createDate: createDate modDate: modifiedDate
	isDir: dirFlag fileSize: fileSize [

	| modDateOop createDateOop nameString results |
	<var: 'entryName' type: 'char *'>

	results			:= objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 5.
	nameString		:= objectMemory instantiateClass: (objectMemory splObj: ClassString) indexableSize: entryNameSize.
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

{ #category : #'debugging traps' }
StackInterpreterSimulator >> moveFramesIn: thePage through: frameAbove toPage: newPage [
	"| thisPage |
	(self checkIsStillMarriedContext: 22189568 currentFP: framePointer) ifTrue:
		[thisPage := stackPages stackPageFor: (self frameOfMarriedContext: 22189568).
		 (thePage == thisPage or: [newPage == thisPage]) ifTrue:
			[self halt]]."
	^super moveFramesIn: thePage through: frameAbove toPage: newPage
]

{ #category : #'debug support' }
StackInterpreterSimulator >> nameOfClass: classOop [
	(objectMemory sizeBitsOf: classOop) = metaclassSizeBytes ifTrue:
		[^(self nameOfClass:
				(objectMemory fetchPointer: thisClassIndex ofObject: classOop)) , ' class'].
	^self stringOf: (objectMemory fetchPointer: classNameIndex ofObject: classOop)
]

{ #category : #initialization }
StackInterpreterSimulator >> nextLongFrom: aStream [
	"Read a 32-bit quantity from the given (binary) stream."
	^self subclassResponsibility
]

{ #category : #initialization }
StackInterpreterSimulator >> nextLongFrom: aStream swap: swapFlag [
	swapFlag 
		ifTrue: [^ objectMemory byteSwapped: (self nextLongFrom: aStream)]
		ifFalse: [^ self nextLongFrom: aStream]
]

{ #category : #initialization }
StackInterpreterSimulator >> nextShortFrom: aStream [
	"Read a 16-bit quantity from the given (binary) stream."
	^self subclassResponsibility
]

{ #category : #initialization }
StackInterpreterSimulator >> nextShortFrom: aStream swap: swapFlag [
	| aShort |
	aShort := self nextShortFrom: aStream.
	^swapFlag 
		ifTrue: [(aShort bitShift: -8) + ((aShort bitAnd: 16rFF) bitShift: 8)]
		ifFalse: [aShort]
]

{ #category : #testing }
StackInterpreterSimulator >> objectBefore: addr [
	| oop prev |
	oop := objectMemory firstObject.
	[oop < objectMemory endOfMemory] whileTrue:
		[prev := oop.  "look here if debugging prev obj overlapping this one"
		oop := objectMemory objectAfter: oop.
		oop >= addr ifTrue: [^ prev]].
	^0
]

{ #category : #UI }
StackInterpreterSimulator >> openAsMorph [
	"Open a morphic view on this simulation."
	| window localImageName |
	localImageName := FileDirectory default localNameFor: imageName.
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

	window openInWorldExtent: (self desiredDisplayExtent
								+ (2 * window borderWidth)
								+ (0@window labelHeight)
								* (1@(1/0.8))) rounded
]

{ #category : #UI }
StackInterpreterSimulator >> openAsMorphNoTranscript [
	"Open a morphic view on this simulation."
	| window localImageName |
	localImageName := FileDirectory default localNameFor: imageName.
	window := (SystemWindow labelled: 'Simulation of ' , localImageName) model: self.

	window addMorph: (displayView := ImageMorph new image: displayForm)
		frame: (0@0 corner: 1@0.95).

	window addMorph: (PluggableTextMorph on: self
						text: #byteCountText accept: nil) hideScrollBarsIndefinitely
		frame: (0@0.95 corner: 1@1).

	window openInWorldExtent: (self desiredDisplayExtent
								+ (2 * window borderWidth)
								+ (0@window labelHeight)
								* (1@(1/0.95))) rounded
]

{ #category : #initialization }
StackInterpreterSimulator >> openOn: fileName [
	"(InterpreterSimulator new openOn: 'clonex.image') test"

	self openOn: fileName extraMemory: 2500000.
]

{ #category : #initialization }
StackInterpreterSimulator >> openOn: fileName extraMemory: extraBytes [
	"InterpreterSimulator new openOn: 'clone.im' extraMemory: 100000"

	| f version headerSize count oldBaseAddr bytesToShift swapBytes
	  hdrNumStackPages hdrEdenBytes headerFlags |
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
	headerSize := self nextLongFrom: f swap: swapBytes.
	objectMemory setEndOfMemory: (self nextLongFrom: f swap: swapBytes).  "first unused location in heap"
	oldBaseAddr := self nextLongFrom: f swap: swapBytes.  "object memory base address of image"
	objectMemory specialObjectsOop: (self nextLongFrom: f swap: swapBytes).
	objectMemory lastHash: (self nextLongFrom: f swap: swapBytes).  "Should be loaded from, and saved to the image header"

	savedWindowSize	:= self nextLongFrom: f swap: swapBytes.
	headerFlags			:= self nextLongFrom: f swap: swapBytes.
	self setImageHeaderFlagsFrom: headerFlags.
	extraVMMemory		:= self nextLongFrom: f swap: swapBytes.
	hdrNumStackPages	:= self nextShortFrom: f swap: swapBytes.
	"4 stack pages is small.  Should be able to run with as few as
	 three. 4 should be comfortable but slow.  8 is a reasonable
	 default. Can be changed via vmParameterAt: 43 put: n"
	numStackPages := desiredNumStackPages ~= 0
						ifTrue: [desiredNumStackPages]
						ifFalse: [hdrNumStackPages = 0
									ifTrue: [self defaultNumStackPages]
									ifFalse: [hdrNumStackPages]].
	desiredNumStackPages := hdrNumStackPages.
	stackPages := self stackPagesClass new. "Temporary for computeStackZoneSize"
	"pad to word boundary.  This slot can be used for anything else that will fit in 16 bits.
	 Preserve it to be polite to images run on Cog."
	theUnknownShort	:= self getShortFromFile: f swap: swapBytes.
	hdrEdenBytes		:= self nextLongFrom: f swap: swapBytes.
	objectMemory edenBytes: (hdrEdenBytes = 0
							ifTrue: [objectMemory defaultEdenBytes]
							ifFalse: [hdrEdenBytes]).
	desiredEdenBytes := hdrEdenBytes.
	"allocate interpreter memory"
	objectMemory setMemoryLimit: objectMemory endOfMemory + extraBytes + objectMemory edenBytes + self interpreterAllocationReserveBytes.

	"read in the image in bulk, then swap the bytes if necessary"
	f position: headerSize.
	objectMemory memory: (Bitmap new: objectMemory memoryLimit // 4).
	count := f readInto: objectMemory memory startingAt: 1 count: objectMemory endOfMemory // 4.
	count ~= (objectMemory endOfMemory // 4) ifTrue: [self halt].
	]
		ensure: [f close].

	self ensureImageFormatIsUpToDate: swapBytes.

	objectMemory initialize.
	bytesToShift := objectMemory startOfMemory - oldBaseAddr.  "adjust pointers for zero base address"
	Utilities informUser: 'Relocating object pointers...'
				during: [self initializeInterpreter: bytesToShift].

]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> preGCAction: aBoolean [
	"self halt."
	^super preGCAction: aBoolean
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
	self halt.
	^super primitiveDoPrimitiveWithArgs
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> primitiveFailFor: reasonCode [
	"self halt."
	^super primitiveFailFor: reasonCode
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> primitiveFileDelete [ 

	| namePointer |
	namePointer := self stackTop.
	self success: (objectMemory isBytes: namePointer).
	self success: (StandardFileStream isAFileNamed: (self stringOf: namePointer)).
	self successful ifTrue: [FileDirectory deleteFilePath: (self stringOf: namePointer)].
	self successful ifTrue: [self pop: 1].  "pop fileName; leave rcvr on stack"
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> primitiveFileOpen [
	| namePointer writeFlag fileName f |
	writeFlag := self booleanValueOf: self stackTop.
	namePointer := self stackValue: 1.
	self success: (objectMemory isBytes: namePointer).
	self successful ifTrue:
		[fileName := self stringOf: namePointer.
		filesOpen addLast: (writeFlag
			ifTrue: [f := FileStream fileNamed: fileName.
					f ifNil: [^ self primitiveFail] ifNotNil: [f binary]]
			ifFalse: [(StandardFileStream isAFileNamed: fileName)
				ifTrue: [f := (FileStream readOnlyFileNamed: fileName).
						f ifNil:[^self primitiveFail] ifNotNil:[f binary]]
				ifFalse: [^ self primitiveFail]]).
		self pop: 3 thenPushInteger: filesOpen size]
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> primitiveFileRename [

	| oldNamePointer newNamePointer f |
	oldNamePointer := self stackTop.
	newNamePointer := self stackValue: 1.
	self success: (objectMemory isBytes: oldNamePointer).
	self success: (objectMemory isBytes: newNamePointer).
	self success: (StandardFileStream isAFileNamed: (self stringOf: oldNamePointer)).
	self success: (StandardFileStream isAFileNamed: (self stringOf: newNamePointer)) not.
	self successful ifTrue: [
		f := FileStream oldFileNamed: (self stringOf: oldNamePointer).
		f rename: (self stringOf: newNamePointer).
		f close.
	].
	self successful ifTrue: [
		self pop: 2.  "oldName, newName; leave rcvr on stack"
	]
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> primitiveFileStdioHandles [
	| result |
	result := objectMemory instantiateClass: objectMemory classArray indexableSize: 3.
	result = nil ifTrue:
		[^self primitiveFailFor: PrimErrNoMemory].
	Transcript clear.
	filesOpen addLast: (FakeStdinStream for: self). "stdin"
	objectMemory storePointerUnchecked: 0 ofObject: result withValue: (objectMemory integerObjectOf: filesOpen size).
	filesOpen addLast: Transcript. "stdout"
	objectMemory storePointerUnchecked: 1 ofObject: result withValue: (objectMemory integerObjectOf: filesOpen size).
	filesOpen addLast: Transcript. "stderr"
	objectMemory storePointerUnchecked: 2 ofObject: result withValue: (objectMemory integerObjectOf: filesOpen size).
	self pop: 1 thenPush: result
]

{ #category : #'other primitives' }
StackInterpreterSimulator >> primitiveGetAttribute [
	"Fetch the system attribute with the given integer ID. The result is a string, which will be empty if the attribute is not defined."

	| attr s attribute |
	attr := self stackIntegerValue: 0.
	self successful ifTrue: [
		attribute := Smalltalk getSystemAttribute: attr.
		attribute ifNil: [ ^self primitiveFail ].
		s := objectMemory instantiateClass: (objectMemory splObj: ClassString) indexableSize: attribute size.
		1 to: attribute size do: [ :i |
			objectMemory storeByte: i-1 ofObject: s withValue: (attribute at: i) asciiValue].
		self pop: 2.  "rcvr, attr"
		self push: s]
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> primitiveImageName [
	"Note: For now, this only implements getting, not setting, the image file name."
	| result imageNameSize |
	self pop: 1.
	imageNameSize := imageName size.
	result := objectMemory instantiateClass: (objectMemory splObj: ClassString)
				   indexableSize: imageNameSize.
	1 to: imageNameSize do:
		[:i | objectMemory storeByte: i-1 ofObject: result
			withValue: (imageName at: i) asciiValue].
	self push: result.
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

{ #category : #'I/O primitives support' }
StackInterpreterSimulator >> primitiveRelinquishProcessor [
	"No-op in simulator"

	^ self pop: 1
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> primitiveResume [
	"Catch errors before we start the whole morphic error process"

	"byteCount > 1000000 ifTrue: [self halt]."  "Ignore early process activity"
	^ super primitiveResume
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
StackInterpreterSimulator >> printCallStackOf: aContext [
	self printCallStackOf: aContext currentFP: localFP
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> printChar: aByte [

	traceOn ifTrue: [ transcript nextPut: aByte asCharacter ].
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> printCurrPageFrames [
	self printFrameAndCallers: localFP SP: localSP
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> printCurrentBytecodeOn: aStream [
	| code |
	code := currentBytecode radix: 16.
	aStream print: localIP - method - 3;
		tab;
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

{ #category : #UI }
StackInterpreterSimulator >> promptHex: string [
	| s |
	s := UIManager default request: string, ' (hex)'.
	^s notEmpty ifTrue:
		[(s size > 3 and: [s third = $r]) ifTrue:
			[s := s allButFirst: 3].
		Integer readFrom: s readStream base: 16]
]

{ #category : #'bytecode routines' }
StackInterpreterSimulator >> pushLiteralConstantBytecode [

	"Interpreter version has fetchNextBytecode out of order"
	self pushLiteralConstant: (currentBytecode bitAnd: 16r1F).
	self fetchNextBytecode.

]

{ #category : #'bytecode routines' }
StackInterpreterSimulator >> pushLiteralVariableBytecode [

	"Interpreter version has fetchNextBytecode out of order"
	self pushLiteralVariable: (currentBytecode bitAnd: 16r1F).
	self fetchNextBytecode.

]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> pushMaybeContextReceiverVariable: index [
	"(index = SenderIndex or: [index = ClosureIndex]) ifTrue: [self halt]."
	^super pushMaybeContextReceiverVariable: index
]

{ #category : #'bytecode routines' }
StackInterpreterSimulator >> pushReceiverVariableBytecode [

	"Interpreter version has fetchNextBytecode out of order"
	self pushReceiverVariable: (currentBytecode bitAnd: 16rF).
	self fetchNextBytecode.

]

{ #category : #'bytecode routines' }
StackInterpreterSimulator >> pushTemporaryVariableBytecode [

	"Interpreter version has fetchNextBytecode out of order"
	self pushTemporaryVariable: (currentBytecode bitAnd: 16rF).
	self fetchNextBytecode.

]

{ #category : #initialization }
StackInterpreterSimulator >> reverseBytesFrom: begin to: end [
	"Byte-swap the given range of memory (not inclusive!)."
	| wordAddr |
	wordAddr := begin.
	objectMemory memory swapBytesFrom: wordAddr // 4 + 1 to: end // 4
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
	quitBlock := [([transcript dependents anyOne outermostMorphThat: [:m| m isSystemWindow]]
					on: Error
					do: [:ex| nil])
						ifNotNil: [:window| (UIManager default confirm: 'close?') ifTrue: [window delete]].
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
	quitBlock := [(displayView notNil
				   and: [UIManager default confirm: 'close?']) ifTrue:
					[(displayView outermostMorphThat: [:m| m isSystemWindow]) ifNotNil:
						[:topWindow| topWindow delete]].
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

{ #category : #'debugging traps' }
StackInterpreterSimulator >> sendBreak: selectorString point: selectorLength receiver: receiverOrNil [
	"self shortPrintFrameAndCallers: localFP"
	| i |
	breakSelectorLength = selectorLength ifTrue:
		[i := breakSelectorLength.
		 [i > 0] whileTrue:
			[(self byteAt: selectorString + i - 1) = (breakSelector at: i) asInteger
				ifTrue: [(i := i - 1) = 0 ifTrue:
							[self halt: 'Send of '
									, breakSelector,
									(receiverOrNil
										ifNotNil: [' to ', (self shortPrint: receiverOrNil)]
										ifNil: [''])]]
				ifFalse: [i := 0]]]
]

{ #category : #'memory access' }
StackInterpreterSimulator >> shortAt: byteAddress [
    "Return the half-word at byteAddress which must be even."
	^self subclassResponsibility
]

{ #category : #'memory access' }
StackInterpreterSimulator >> shortAt: byteAddress put: a16BitValue [
	^ self subclassResponsibility
]

{ #category : #'debug support' }
StackInterpreterSimulator >> shortPrint: oop [
	| name classOop |
	(objectMemory isIntegerObject: oop) ifTrue: [^ '=' , (objectMemory integerValueOf: oop) printString , 
		' (' , (objectMemory integerValueOf: oop) hex , ')'].
	(oop between: objectMemory startOfMemory and: objectMemory freeStart) ifFalse:
		[^' is not on the heap'].
	(oop bitAnd: (BytesPerWord - 1)) ~= 0 ifTrue:
		[^' is misaligned'].
	classOop := objectMemory fetchClassOf: oop.
	(objectMemory sizeBitsOf: classOop) = metaclassSizeBytes ifTrue: [
		^ 'class ' , (self nameOfClass: oop)].
	name := self nameOfClass: classOop.
	name size = 0 ifTrue: [name := '??'].
	name = 'String' ifTrue: [^ (self stringOf: oop) printString].
	name = 'ByteString' ifTrue: [^ (self stringOf: oop) printString].
	name = 'Symbol' ifTrue: [^ '#' , (self stringOf: oop)].
	name = 'ByteSymbol' ifTrue: [^ '#' , (self stringOf: oop)].
	name = 'Character' ifTrue: [^ '=' , (Character value: (objectMemory integerValueOf: 
				(objectMemory fetchPointer: 0 ofObject: oop))) printString].
	name = 'UndefinedObject' ifTrue: [^ 'nil'].
	name = 'False' ifTrue: [^ 'false'].
	name = 'True' ifTrue: [^ 'true'].
	name = 'Float' ifTrue: [^ '=' , (self dbgFloatValueOf: oop) printString].
	name = 'Association' ifTrue: [^ '(' ,
				(self shortPrint: (self longAt: oop + BaseHeaderSize)) ,
				' -> ' ,
				(self longAt: oop + BaseHeaderSize + BytesPerWord) hex8 , ')'].
	('AEIOU' includes: name first)
		ifTrue: [^ 'an ' , name]
		ifFalse: [^ 'a ' , name]
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> shortPrintContext: aContext [
	transcript ensureCr.
	^super shortPrintContext: aContext
]

{ #category : #'debug support' }
StackInterpreterSimulator >> shortPrintRelative: oop [
	| name classOop |
	(objectMemory isIntegerObject: oop) ifTrue:
		[^'=' , (objectMemory integerValueOf: oop) printString , 
		' (' , (objectMemory integerValueOf: oop) hex , ')'].
	(oop between: objectMemory startOfMemory and: objectMemory freeStart) ifFalse:
		[^' is not on the heap'].
	(oop bitAnd: (BytesPerWord - 1)) ~= 0 ifTrue:
		[^' is misaligned'].
	classOop := objectMemory fetchClassOfNonInt: oop.
	(objectMemory sizeBitsOf: classOop) = metaclassSizeBytes ifTrue: [
		^'class ' , (self nameOfClass: oop)].
	name := self nameOfClass: classOop.
	name size = 0 ifTrue: [name := '??'].
	name = 'String' ifTrue: [^(self stringOf: oop) printString].
	name = 'ByteString' ifTrue: [^(self stringOf: oop) printString].
	name = 'Symbol' ifTrue: [^'#' , (self stringOf: oop)].
	name = 'ByteSymbol' ifTrue: [^'#' , (self stringOf: oop)].
	name = 'Character' ifTrue: [^'=' , (Character value: (objectMemory integerValueOf: 
				(objectMemory fetchPointer: 0 ofObject: oop))) printString].
	name = 'UndefinedObject' ifTrue: [^'nil'].
	name = 'False' ifTrue: [^'false'].
	name = 'True' ifTrue: [^'true'].
	name = 'Float' ifTrue: [^'=' , (self dbgFloatValueOf: oop) printString].
	name = 'Association' ifTrue:
		[| valOop |
		valOop := self longAt: oop + BaseHeaderSize + BytesPerWord.
		^'(' ,
			(self shortPrint: (self longAt: oop + BaseHeaderSize)) ,
			' -> ' ,
			((objectMemory isIntegerObject: valOop) ifTrue: [valOop] ifFalse: [valOop - objectMemory startOfMemory]) hex8 , ')'].
	^(('AEIOU' includes: name first)
		ifTrue: ['an ']
		ifFalse: ['a ']) , name
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

{ #category : #'debug printing' }
StackInterpreterSimulator >> space [

	traceOn ifTrue: [ transcript space ]
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> sqFile: file Read: count Into: byteArrayIndex At: startIndex [

	startIndex to: startIndex + count - 1 do:
		[ :i |
		file atEnd ifTrue: [^i - startIndex].
		self byteAt: byteArrayIndex + i put: file next asInteger].
	^count
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> sqFile: file SetPosition: newPosition [

	file position: newPosition.
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> sqFile: file Truncate: truncatePosition [

	file truncate: truncatePosition.
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> sqFile: file Write: count From: byteArrayIndex At: startIndex [

	file isBinary
		ifTrue:
			[startIndex to: startIndex + count - 1 do:
				[ :i | file nextPut: (self byteAt: byteArrayIndex + i)]]
		ifFalse:
			[startIndex to: startIndex + count - 1 do:
				[ :i | | byte |
				byte := self byteAt: byteArrayIndex + i.
				file nextPut: (Character value: (byte == 12 "lf" ifTrue: [15"cr"] ifFalse: [byte]))]].
	^count
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> sqFileAtEnd: file [

	^ file atEnd
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> sqFileClose: file [

	file close.
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> sqFileFlush: file [

	^ file flush
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> sqFileGetPosition: file [

	^ file position
]

{ #category : #'file primitives' }
StackInterpreterSimulator >> sqFileSize: file [

	^ file size
]

{ #category : #'plugin support' }
StackInterpreterSimulator >> sqGetInterpreterProxy [
	"I am basically my own proxy..."
	^self
]

{ #category : #'memory access' }
StackInterpreterSimulator >> sqGrowMemory: oldLimit By: delta [

	transcript show: 'grow memory from ', oldLimit printString, ' by ', delta printString; cr.
	objectMemory memory: objectMemory memory , (objectMemory memory class new: delta // 4).
	^ objectMemory memory size * 4
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

{ #category : #initialization }
StackInterpreterSimulator >> startOfMemory [
	"Return the start of object memory."

	^ 0
]

{ #category : #'bytecode routines' }
StackInterpreterSimulator >> storeAndPopTemporaryVariableBytecode [
	"Interpreter version has fetchNextBytecode out of order"
	self temporary: (currentBytecode bitAnd: 7) in: localFP put: self internalStackTop.
	self fetchNextBytecode.
	self internalPop: 1
]

{ #category : #'float primitives' }
StackInterpreterSimulator >> storeFloatAt: floatBitsAddress from: aFloat [

	self long32At: floatBitsAddress put: (aFloat at: 1).
	self long32At: floatBitsAddress+4 put: (aFloat at: 2).

]

{ #category : #'debug printing' }
StackInterpreterSimulator >> str: aString n: bString cmp: n [
	"implementation of strncmp(3)"
	bString isInteger ifFalse:
		[^(aString first: n) ~= (bString first: n)].
	1 to: n do:
		[:i| | v |
		v := (aString at: i) asInteger - (self byteAt: bString + i - 1).
		v ~= 0 ifTrue: [^v]].
	^0
]

{ #category : #'debug support' }
StackInterpreterSimulator >> stringOf: oop [
	| size long nLongs chars |
	^ String streamContents:
		[:strm |
		size := 100 min: (self stSizeOf: oop).
		nLongs := size-1//BytesPerWord+1.
		1 to: nLongs do:
			[:i | long := self longAt: oop + BaseHeaderSize + (i-1*BytesPerWord).
			chars := self charsOfLong: long.
			strm nextPutAll: (i=nLongs
							ifTrue: [chars copyFrom: 1 to: size-1\\BytesPerWord+1]
							ifFalse: [chars])]]
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> strlen: aString [
	^aString size
]

{ #category : #'debugging traps' }
StackInterpreterSimulator >> success: successBoolean [
	"successBoolean ifFalse:
		[self halt]."
	^super success: successBoolean
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> symbolic: byte at: ip inMethod: meth [
	"Print a bytecode in simple symbolic form"

	| type offset |
	type := byte // 16.  
	offset := byte \\ 16.  
	type=0 ifTrue: [^ 'pushRcvr ' , offset printString].
	type=1 ifTrue: [^ 'pushTemp ' , offset printString].
	type=2 ifTrue: [^ 'pushLit ' , offset printString].
	type=3 ifTrue: [^ 'pushLit ' , (offset+16) printString].
	type=4 ifTrue: [^ 'pushLitVar ' , offset printString].
	type=5 ifTrue: [^ 'pushLitVar ' , (offset+16) printString].
	type=6 ifTrue: [offset<8
					ifTrue: [^ 'storePopRcvr ' , offset printString]
					ifFalse: [^ 'storePopTemp ' , (offset-8) printString]].
	type=7 ifTrue: [offset=0 ifTrue: [^ 'pushRcvr'].
				offset<8 ifTrue: [^ 'pushConst ' , ( #(true false nil -1 0 1 2) at: offset) printString].
				offset=8 ifTrue: [^ 'returnSelf'].
				offset<12 ifTrue: [^ 'returnConst ' , ( #(true false nil -1 0 1 2) at: offset-8) printString].
				offset=12 ifTrue: [^ 'returnTop'].
				offset=13 ifTrue: [^ 'blockReturnTop'].
				offset>13 ifTrue: [^ 'unusedBytecode']].
	type=8 ifTrue: [^ self symbolicExtensions: offset at: ip inMethod: meth].
	type=9 ifTrue:  "short jumps"
			[offset<8 ifTrue: [^ 'jump ' , (offset+1) printString].
			^ 'jumpIfFalse ' , (offset-8+1) printString].
	type=10 ifTrue:  "long jumps"
			[offset<8 ifTrue: [^ 'extendedJump'].
			offset<12 ifTrue: [^ 'extendedJumpIfTrue'].
			true ifTrue: [^ 'extendedJumpIfFalse']].
	type=11 ifTrue: [^ 'sendSpl ' , (Smalltalk specialSelectorAt: offset+1)].
	type=12 ifTrue: [^ 'sendSpl ' , (Smalltalk specialSelectorAt: offset+17)].
	type>12 ifTrue: [^ 'send ' , (self stringOf: (self literal: offset ofMethod: meth))]
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> symbolicExtensions: offset at: ip inMethod: meth [
	| type offset2 byte2 byte3 byte4 |
	offset <=6 ifTrue: 
		["Extended op codes 128-134"
		byte2 := objectMemory fetchByte: ip+1 ofObject: meth.
		offset <= 2 ifTrue:
			["128-130:  extended pushes and pops"
			type := byte2 >> 6 bitAnd: 3.
			offset2 := byte2 bitAnd: 63.
			offset = 0 ifTrue: 
				[type = 0 ifTrue: [^ 'pushRcvr ' , offset2 printString].
				type = 1 ifTrue: [^ 'pushTemp ' , offset2 printString].
				type = 2  ifTrue: [^ 'pushLit ' , (offset2 + 1) printString].
				type = 3 ifTrue: [^ 'pushLitVar ' , (offset2 + 1) printString]].
			offset = 1 ifTrue: 
				[type = 0 ifTrue: [^ 'storeIntoRcvr ' , offset2 printString].
				type = 1 ifTrue: [^ 'storeIntoTemp ' , offset2 printString].
				type = 2 ifTrue: [^ 'illegalStore'].
				type = 3 ifTrue: [^ 'storeIntoLitVar ' , (offset2 + 1) printString]].
			offset = 2 ifTrue: 
				[type = 0 ifTrue: [^ 'storePopRcvr ' , offset2 printString].
				type = 1 ifTrue: [^ 'storePopTemp ' , offset2 printString].
				type = 2 ifTrue: [^ 'illegalStore'].
				type = 3  ifTrue: [^ 'storePopLitVar ' , (offset2 + 1) printString]]].
		"131-134: extended sends"
		offset = 3 ifTrue:  "Single extended send"
			[^ 'send ' , (self stringOf: (self literal: byte2 \\ 32 ofMethod: meth))].
		offset = 4 ifTrue:    "Double extended do-anything"
			[byte3 := objectMemory fetchByte: ip+2 ofObject: meth.
			type := byte2 // 32.
			type = 0 ifTrue: [^ 'send ' , (self stringOf: (self literal: byte3 ofMethod: meth))].
			type = 1 ifTrue: [^ 'superSend ' , (self stringOf: (self literal: byte3 ofMethod: meth))].
			type = 2 ifTrue: [^ 'pushRcvr ' , byte3 printString].
			type = 3 ifTrue: [^ 'pushLit ' , byte3 printString].
			type = 4 ifTrue: [^ 'pushLitVar ' , byte3 printString].
			type = 5 ifTrue: [^ 'storeIntoRcvr ' , byte3 printString].
			type = 6 ifTrue: [^ 'storePopRcvr ' , byte3 printString].
			type = 7 ifTrue: [^ 'storeIntoLitVar ' , byte3 printString]].
		offset = 5 ifTrue:  "Single extended send to super"
			[^ 'superSend ' , (self stringOf: (self literal: byte2 \\ 32 ofMethod: meth))].
		offset = 6 ifTrue:   "Second extended send"
			[^ 'send ' , (self stringOf: (self literal: byte2 \\ 64 ofMethod: meth))]].
	offset = 7 ifTrue: [^ 'doPop'].
	offset = 8 ifTrue: [^ 'doDup'].
	offset = 9 ifTrue: [^ 'pushActiveContext'].
	byte2 := objectMemory fetchByte: ip+1 ofObject: meth.
	offset = 10 ifTrue:
		[^byte2 < 128
			ifTrue: ['pushNewArrayOfSize: ', byte2 printString]
			ifFalse: ['pushConsArrayWithElements: ', (byte2 - 128) printString]].
	offset = 11 ifTrue: [^ 'unusedBytecode'].
	byte3 := objectMemory fetchByte: ip+2 ofObject: meth.
	offset = 12 ifTrue: [^'pushRemoteTemp: ', byte2 printString, ' inVectorAt: ', byte3 printString].
	offset = 13 ifTrue: [^'storeIntoRemoteTemp: ', byte2 printString, ' inVectorAt: ', byte3 printString].
	offset = 14 ifTrue: [^'popIntoRemoteTemp: ', byte2 printString, ' inVectorAt: ', byte3 printString].
	"offset = 15"
	byte4 := objectMemory fetchByte: ip+3 ofObject: meth.
	^'pushClosureCopyNumCopiedValues: ', (byte2 bitShift: -4) printString,
		' numArgs: ', (byte2 bitAnd: 16rF) printString,
		' blockSize: ', ((byte3 * 256) + byte4) printString
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> tab [

	traceOn ifTrue: [ transcript tab ].
]

{ #category : #'debug support' }
StackInterpreterSimulator >> tenuringIncrementalGC [
	transcript cr; nextPutAll: 'tenuringIncrementalGC ('; print: byteCount; nextPut: $); flush.
	^super tenuringIncrementalGC
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

{ #category : #'simulation only' }
StackInterpreterSimulator >> transcript [
	^transcript
]

{ #category : #'simulation only' }
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
		addLine;
		add: 'print ext head frame' action: #printExternalHeadFrame;
		add: 'print int head frame' action: #printHeadFrame;
		add: 'short print frame & callers' action: [self shortPrintFrameAndCallers: framePointer];
		add: 'long print frame & callers' action: [self printFrameAndCallers: framePointer SP: stackPointer];
		add: 'print frame...' target: self action: [(self promptHex: 'print frame') ifNotNil: [:fp| self printFrame: fp]];
		add: 'print call stack' action: #printCallStack;
		add: 'print oop...' action: [(self promptHex: 'print oop') ifNotNil: [:oop| self printOop: oop]];
		addLine;
		add: 'inspect object memory' target: objectMemory action: #inspect;
		add: 'inspect cointerpreter' action: #inspect;
		addLine;
		add: 'set break count...' action: #setBreakCount;
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
StackInterpreterSimulator >> writeImageFileIO: numberOfBytesToWrite [
	"Actually emit the first numberOfBytesToWrite object memory bytes onto the snapshot."

	| headerSize file |
	BytesPerWord = 4 ifFalse: [self error: 'Not rewritten for 64 bits yet'].
	headerSize := 64.

	[
		file := (FileStream fileNamed: imageName) binary.
		file == nil ifTrue: [^nil].
	
		{
			self imageFormatVersion.
			headerSize.
			numberOfBytesToWrite.
			objectMemory startOfMemory.
			(objectMemory specialObjectsOop).
			(objectMemory lastHash).
			self ioScreenSize.
			fullScreenFlag.
			extraVMMemory
		}
			do: [:long | self putLong: long toFile: file].

		{	desiredNumStackPages. 	self unknownShortOrCodeSizeInKs } do:
			[:short| self putShort: short toFile: file].

		self putLong: desiredEdenBytes toFile: file.

		{	maxExtSemTabSizeSet ifTrue: [self ioGetMaxExtSemTableSize] ifFalse: [0]. 0 } do:
			[:short| self putShort: short toFile: file].

		"Pad the rest of the header."
		4 timesRepeat: [self putLong: 0 toFile: file].
	
		"Position the file after the header."
		file position: headerSize.
	
		"Write the object memory."
		objectMemory startOfMemory // 4 + 1
			to: numberOfBytesToWrite // 4
			do: [:index |
				self
					putLong: (objectMemory memory at: index)
					toFile: file].
	
		self success: true
	]
		ensure: [file close]
]

{ #category : #'debug printing' }
StackInterpreterSimulator >> writeProtectMemory [
	objectMemory memory: (ReadOnlyArrayWrapper around: objectMemory memory)
]
