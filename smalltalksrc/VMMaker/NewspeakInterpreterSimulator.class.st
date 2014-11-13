"
This class defines basic memory access and primitive simulation so that the Interpreter can run simulated in the Squeak environment.  It also defines a number of handy object viewing methods to facilitate pawing around in the object memory.

To see the thing actually run, you could (after backing up this image and changes), execute

	(NewspeakInterpreterSimulator new openOn: Smalltalk imageName) test

and be patient both to wait for things to happen, and to accept various things that may go wrong depending on how large or unusual your image may be.  We usually do this with a small and simple benchmark image. You will probably have more luck using InterpreteSimulatorLSB or NewspeakInterpreterSimulatorMSB as befits your machine.
"
Class {
	#name : #NewspeakInterpreterSimulator,
	#superclass : #NewspeakInterpreter,
	#instVars : [
		'byteCount',
		'sendCount',
		'traceOn',
		'myBitBlt',
		'displayForm',
		'imageName',
		'pluginList',
		'mappedPluginEntries',
		'quitBlock',
		'transcript',
		'displayView',
		'printSends',
		'printBytecodeAtEachStep',
		'atEachStepBlock',
		'printContextAtEachStep',
		'breakCount'
	],
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #'instance creation' }
NewspeakInterpreterSimulator class >> new [
	^ self == NewspeakInterpreterSimulator
		ifTrue: [SmalltalkImage current endianness == #big
				ifTrue: [NewspeakInterpreterSimulatorMSB new]
				ifFalse: [NewspeakInterpreterSimulatorLSB new]]
		ifFalse: [super new]
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> allObjectsSelect: objBlock [
	"self allObjectsSelect: [:oop | (self baseHeader: oop) = 1234]"

	| oop selected |
	oop := self firstObject.
	selected := OrderedCollection new.
	[oop < endOfMemory] whileTrue:
			[(self isFreeObject: oop)
				ifFalse: [(objBlock value: oop) ifTrue: [selected addLast: oop]].
			oop := self objectAfter: oop].
	^ selected
]

{ #category : #'debugging traps' }
NewspeakInterpreterSimulator >> allocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOop h3: extendedSize doFill: doFill format: format [

	| newObj |
	newObj := super allocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOop h3: extendedSize doFill: doFill format: format.
	"byteCount < 600000 ifTrue: [^ newObj]."
	"(self baseHeader: newObj) =  16r0FCC0600 ifTrue: [self halt]."
	^ newObj
]

{ #category : #'as yet unclassified' }
NewspeakInterpreterSimulator >> assertValidExecutionPointers [
	| spidx |
	self assert: (self validInstructionPointer: localIP inMethod: method).
	spidx := self stackPointerIndexFor: localSP context: activeContext.
	self assert: (spidx >= -1 and: [spidx < (self lengthOf: activeContext)])
]

{ #category : #'interpreter shell' }
NewspeakInterpreterSimulator >> browserPluginInitialiseIfNeeded [
"do nothing - its a macro in C code to support Mac browser plugin strangeness"
]

{ #category : #'interpreter shell' }
NewspeakInterpreterSimulator >> browserPluginReturnIfNeeded [
"do nothing - its a macro in C code to support Mac browser plugin strangeness"
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> byteAt: byteAddress [
	^self subclassResponsibility
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> byteAt: byteAddress put: byte [
	^self subclassResponsibility
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> byteAtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	pointer is a raw address, and byte is an 8-bit quantity."

	^ self byteAt: pointer
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> byteAtPointer: pointer put: byteValue [
	"This gets implemented by Macros in C, where its types will also be checked.
	pointer is a raw address, and byteValue is an 8-bit quantity."

	^ self byteAt: pointer  put: byteValue
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> byteCount [
	"So you can call this from temp debug statements in, eg, Interpreter, such as
	self byteCount = 12661 ifTrue: [self halt].
	"

	^ byteCount
]

{ #category : #UI }
NewspeakInterpreterSimulator >> byteCountText [
	^ byteCount printString asText
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> cCoerce: value to: cTypeString [
	"Type coercion for translation only; just return the value when running in Smalltalk."

	^value == nil
		ifTrue: [value]
		ifFalse: [value coerceTo: cTypeString sim: self]
]

{ #category : #'translation support' }
NewspeakInterpreterSimulator >> cCoerceSimple: value to: cTypeString [
	"Type coercion for translation only; just return the value when running in Smalltalk."

	^value
]

{ #category : #'plugin support' }
NewspeakInterpreterSimulator >> callExternalPrimitive: mapIndex [
	| entry |
	entry := (mappedPluginEntries at: mapIndex).
	^(entry at: 1) perform: (entry at: 2).
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> charsOfLong: long [
	^self subclassResponsibility
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> checkForInterrupts [
	"Prevent interrupts so that traces are consistent during detailed debugging"

	"self halt."
	true ifTrue:
		[interruptCheckCounter := 1000.
		^self].
	^ super checkForInterrupts
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> classAndSelectorOfMethod: meth forReceiver: rcvr [
	| mClass dict length methodArray |
	mClass := self fetchClassOf: rcvr.
	[dict := self fetchPointer: MethodDictionaryIndex ofObject: mClass.
	length := self numSlotsOf: dict.
	methodArray := self fetchPointer: MethodArrayIndex ofObject: dict.
	0 to: length-SelectorStart-1 do: 
		[:index | 
		meth = (self fetchPointer: index ofObject: methodArray) 
			ifTrue: [^ Array
				with: mClass
				with: (self fetchPointer: index + SelectorStart ofObject: dict)]].
	mClass := self fetchPointer: SuperclassIndex ofObject: mClass.
	mClass = nilObj]
		whileFalse: [].
	^ Array
		with: (self fetchClassOf: rcvr)
		with: (self splObj: SelectorDoesNotUnderstand)
]

{ #category : #'plugin support' }
NewspeakInterpreterSimulator >> classNameOf: aClass Is: className [
	"Check if aClass' name is className"
	| name |
	(self lengthOf: aClass) <= 6 ifTrue:[^false]. "Not a class but maybe behavior" 
	name := self fetchPointer: 6 ofObject: aClass.
	(self isBytes: name) ifFalse:[^false].
	^ className = (self stringOf: name).

]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> clipboardRead: sz Into: actualAddress At: zeroBaseIndex [
	| str |
	str := Clipboard clipboardText.
	1 to: sz do:
		[:i | self byteAt: actualAddress + zeroBaseIndex + i - 1 put: (str at: i) asciiValue]
]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> clipboardSize [

	^ Clipboard clipboardText size
]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> clipboardWrite: sz From: actualDataAddress At: ignored [

	Clipboard clipboardText: (self stringOf: actualDataAddress - self baseHeaderSize)
]

{ #category : #initialization }
NewspeakInterpreterSimulator >> close [  "close any files that ST may have opened"
	(self loadNewPlugin: 'FilePlugin') ifNotNil:
		[:filePlugin| filePlugin close]
]

{ #category : #'debugging traps' }
NewspeakInterpreterSimulator >> commonSend [
	printSends ifTrue:
		[self print: byteCount; space; printStringOf: messageSelector; cr].
	^super commonSend
]

{ #category : #initialization }
NewspeakInterpreterSimulator >> convertToArray [
	"I dont believe it -- this *just works*"
	
	memory := memory as: Array
]

{ #category : #'I/O primitives support' }
NewspeakInterpreterSimulator >> copyBits [

	^ myBitBlt copyBits
]

{ #category : #'debug printing' }
NewspeakInterpreterSimulator >> cr [

	traceOn ifTrue: [ transcript cr; endEntry ].
]

{ #category : #UI }
NewspeakInterpreterSimulator >> desiredDisplayExtent [
	^(savedWindowSize
		ifNil: [640@480]
		ifNotNil: [savedWindowSize >> 16 @ (savedWindowSize bitAnd: 16rFFFF)])
			min: Display extent * 2 // 3
]

{ #category : #'interpreter shell' }
NewspeakInterpreterSimulator >> dispatchFunctionPointer: selector [
"handle the primitive direct dispatch macro in simulation"
	^self perform: selector
]

{ #category : #'interpreter shell' }
NewspeakInterpreterSimulator >> dispatchOn: anInteger in: selectorArray [
	"Simulate a case statement via selector table lookup.
	The given integer must be between 0 and selectorArray size-1, inclusive.
	For speed, no range test is done, since it is done by the at: operation.
	Note that, unlike many other arrays used in the Interpreter, this method expect NO CArrayAccessor wrapping - it would duplicate the +1. Maybe this would be better updated to make it all uniform"

	self perform: (selectorArray at: (anInteger + 1)).
]

{ #category : #'I/O primitives support' }
NewspeakInterpreterSimulator >> displayLocation [

	^ Display extent - displayForm extent - (10@10)
]

{ #category : #'I/O primitives support' }
NewspeakInterpreterSimulator >> drawLoopX: xDelta Y: yDelta [

	^ myBitBlt drawLoopX: xDelta Y: yDelta
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> dumpHeader: hdr [
	| cc |
	^ String streamContents: [:strm |
		cc := (hdr bitAnd: CompactClassMask) >> 12.
		strm nextPutAll: '<cc=', cc hex.
		cc > 0 ifTrue:
			[strm nextPutAll: ':' , (self nameOfClass: (self compactClassAt: cc))].
		strm nextPutAll: '>'.
		strm nextPutAll: '<ft=', ((hdr bitShift: -8) bitAnd: 16rF) hex , '>'.
		strm nextPutAll: '<sz=', (hdr bitAnd: SizeMask) hex , '>'.
		strm nextPutAll: '<hdr=', (#(big class gcMark short) at: (hdr bitAnd: 3) +1) , '>']

]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> dumpMethodHeader: hdr [
	^ String streamContents:
		[:strm |
		strm nextPutAll: '<nArgs=', ((hdr >> 25) bitAnd: 16r1F) printString , '>'.
		strm nextPutAll: '<nTemps=', ((hdr >> 19) bitAnd: 16r3F) printString , '>'.
		strm nextPutAll: '<lgCtxt=', ((hdr >> 18) bitAnd: 16r1) printString , '>'.
		strm nextPutAll: '<nLits=', ((hdr >> 10) bitAnd: 16rFF) printString , '>'.
		strm nextPutAll: '<prim=', ((hdr >> 1) bitAnd: 16r1FF) printString , '>'.
		]
]

{ #category : #testing }
NewspeakInterpreterSimulator >> ensureDebugAtEachStepBlock [
	atEachStepBlock := [printContextAtEachStep ifTrue:
							[self printContext: activeContext WithSP: localSP].
						 printBytecodeAtEachStep ifTrue:
							[self printCurrentBytecodeOn: transcript.
							 transcript cr; flush].
						 byteCount = breakCount ifTrue:
							["printContextAtEachStep :=" printBytecodeAtEachStep := true]]
]

{ #category : #'interpreter shell' }
NewspeakInterpreterSimulator >> fetchByte [

	^ self byteAt: (localIP := localIP + 1).
]

{ #category : #'float primitives' }
NewspeakInterpreterSimulator >> fetchFloatAt: floatBitsAddress into: aFloat [

	aFloat at: 1 put: (self long32At: floatBitsAddress).
	aFloat at: 2 put: (self long32At: floatBitsAddress+4).

]

{ #category : #testing }
NewspeakInterpreterSimulator >> findNewMethodInClass: class [
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
NewspeakInterpreterSimulator >> firstIndexableField: oop [
	"NOTE: overridden from ObjectMemory to add coercion to CArray, so please duplicate any changes"
	| hdr fmt totalLength fixedFields |
	<returnTypeC: #'void *'>
	hdr := self baseHeader: oop.
	fmt := self formatOfHeader: hdr.
	fmt <= 4 ifTrue: "<= 4 pointer"
		["pointer; may need to delve into the class format word"
		totalLength := self lengthOf: oop baseHeader: hdr format: fmt.
		fixedFields := self fixedFieldsOf: oop format: fmt length: totalLength.
		^self cCoerce: (self pointerForOop: oop + self baseHeaderSize + (fixedFields << self shiftForWord)) to: 'oop *'].
	^self
		cCoerce: (self pointerForOop: oop + self baseHeaderSize)
		to: (fmt < 8
				ifTrue: [fmt = 6
						ifTrue: ["32 bit field objects" 'int *']
						ifFalse: ["full word objects (bits)" 'oop *']]
				ifFalse: ["byte objects (including CompiledMethod" 'char *'])
]

{ #category : #'plugin support' }
NewspeakInterpreterSimulator >> flushExternalPrimitives [
	mappedPluginEntries := #().
	super flushExternalPrimitives.
]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> fullDisplay [
	| t |
	displayForm == nil ifTrue: [^ self].
	t := primFailCode.  primFailCode := 0.
	self displayBitsOf: (self splObj: TheDisplay) Left: 0 Top: 0 Right: displayForm width Bottom: displayForm height.
	primFailCode := t
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> fullDisplayUpdate [
	"Preserve successFlag when call asynchronously from Simulator"
	| s |
	s := primFailCode.
	primFailCode := true.
	super fullDisplayUpdate.
	primFailCode := s
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> fullGC [
	transcript cr; show:'<Running full GC ...'.
	super fullGC.
	transcript show: ' done>'.
]

{ #category : #'interpreter shell' }
NewspeakInterpreterSimulator >> functionPointerFor: primIndex inClass: lookupClass [
	"Override Interpreter to handle the external primitives caching.  See also
	 internalExecuteNewMethod."

	^(primIndex between: 1 and: MaxPrimitiveIndex)
		ifTrue: [primitiveTable at: primIndex + 1]
		ifFalse: [0]
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> halfWordHighInLong32: long32 [
	^self subclassResponsibility
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> halfWordLowInLong32: long32 [
	^self subclassResponsibility
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> headerStart: oop [

	^ (self extraHeaderBytes: oop) negated
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> hexDump100: oop [
	| byteSize val |
	^ String streamContents:
		[:strm |
		byteSize := 256.
		(self headerStart: oop) to: byteSize by: 4 do:
			[:a | val := self longAt: oop+a.
			strm cr; nextPutAll: (oop+a) hex8; space; space; 
				nextPutAll: (a<16 ifTrue: [' ', a hex] ifFalse: [a hex]); 
				space; space; space; nextPutAll: val hex8;
				space; space.
			strm nextPutAll: (self charsOfLong: val).
			strm space; space; nextPutAll: (oop+a) printString]]
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> hexDump: oop [
	| byteSize val |
	(self isIntegerObject: oop) ifTrue: [^ self shortPrint: oop].
	^ String streamContents:
		[:strm |
		byteSize := 256 min: (self sizeBitsOf: oop)-4.
		(self headerStart: oop) to: byteSize by: 4 do:
			[:a | val := self longAt: oop+a.
			strm cr; nextPutAll: (a<16 ifTrue: [' ', a hex] ifFalse: [a hex]); 
				space; space; space; nextPutAll: val hex8;
				space; space.
			a=0
				ifTrue: [strm nextPutAll: (self dumpHeader: val)]
				ifFalse: [strm nextPutAll: (self charsOfLong: val)]]]
]

{ #category : #'interpreter shell' }
NewspeakInterpreterSimulator >> incrementByteCount [
	(byteCount := byteCount + 1) = breakCount ifTrue:
		[self doOrDefer: [self changed: #byteCountText].
		 self halt].
	byteCount \\ 1000 = 0 ifTrue:
		[self doOrDefer: [self changed: #byteCountText].
		 self forceInterruptCheck]
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> incrementalGC [
	transcript cr; nextPutAll: 'incrementalGC ('; print: byteCount; nextPut: $); flush.
	^super incrementalGC
]

{ #category : #initialization }
NewspeakInterpreterSimulator >> initialize [

	"Initialize the NewspeakInterpreterSimulator when running the interpreter inside
	Smalltalk. The primary responsibility of this method is to allocate
	Smalltalk Arrays for variables that will be declared as statically-allocated
	global arrays in the translated code."

	"initialize class variables"
	ObjectMemory initBytesPerWord: self wordSize.
	ObjectMemory initialize.
	NewspeakInterpreter initialize.
	super initialize.

	"Note: we must initialize ConstMinusOne differently for simulation,
		due to the fact that the simulator works only with +ve 32-bit values"
	ConstMinusOne := self integerObjectOf: -1.

	methodCache := Array new: MethodCacheSize.
	atCache := Array new: AtCacheTotalSize.
	self flushMethodCache.
	rootTable := Array new: RootTableSize.
	weakRoots := Array new: RootTableSize + RemapBufferSize + 100.
	remapBuffer := Array new: RemapBufferSize.
	gcSemaphoreIndex := 0.
	externalPrimitiveTable := CArrayAccessor on: (Array new: MaxExternalPrimitiveTableSize).
	primitiveTable := self class primitiveTable.
	pluginList := {'' -> self }.
	mappedPluginEntries := #().
	primTraceLog := CArrayAccessor on: (Array new: 256 withAll: 0).
	sendTraceLog := CArrayAccessor on: (Array new: 256 withAll: 0).

	"initialize NewspeakInterpreterSimulator variables used for debugging"
	byteCount := 0.
	sendCount := 0.
	quitBlock := [^ self].
	traceOn := true.
	printSends := "printReturns := " printBytecodeAtEachStep := printContextAtEachStep := false.
	myBitBlt := BitBltSimulator new setInterpreter: self.
	headerTypeBytes := CArrayAccessor on: HeaderTypeExtraBytes.
	transcript := Transcript.
	displayForm := 'Display has not yet been installed' asDisplayText form.
	
]

{ #category : #'interpreter shell' }
NewspeakInterpreterSimulator >> insufficientMemoryAvailableError [
	self error: 'Failed to allocate memory for the heap'
]

{ #category : #'interpreter shell' }
NewspeakInterpreterSimulator >> insufficientMemorySpecifiedError [
	self error: 'Insufficient memory for this image'
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> integerAt: byteAddress [
	"Note: Adjusted for Smalltalk's 1-based array indexing."

	^memory integerAt: (byteAddress // 4) + 1
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> integerAt: byteAddress put: a32BitValue [
	"Note: Adjusted for Smalltalk's 1-based array indexing."

	^memory integerAt: (byteAddress // 4) + 1 put: a32BitValue
]

{ #category : #'interpreter shell' }
NewspeakInterpreterSimulator >> interpreter [
	^self
]

{ #category : #'interpreter shell' }
NewspeakInterpreterSimulator >> invalidCompactClassError: name [
	self error: 'Class ', name, ' does not have the required compact class index'
]

{ #category : #security }
NewspeakInterpreterSimulator >> ioCanRenameImage [
	^true
]

{ #category : #security }
NewspeakInterpreterSimulator >> ioCanWriteImage [
	^true
]

{ #category : #testing }
NewspeakInterpreterSimulator >> ioExit [

	quitBlock value  "Cause return from #test"
]

{ #category : #'other primitives' }
NewspeakInterpreterSimulator >> ioForceDisplayUpdate [
	"no-op"
]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> ioGetNextEvent: evtBuf [

	self primitiveFail.

]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> ioHasDisplayDepth: depth [
	^Display supportsDisplayDepth: depth
]

{ #category : #'plugin support' }
NewspeakInterpreterSimulator >> ioLoadExternalFunction: functionName OfLength: functionLength FromModule: moduleName OfLength: moduleLength [
	"Load and return the requested function from a module"
	| pluginString functionString |
	pluginString := String new: moduleLength.
	1 to: moduleLength do:[:i| pluginString byteAt: i put: (self byteAt: moduleName+i-1)].
	functionString := String new: functionLength.
	1 to: functionLength do:[:i| functionString byteAt: i put: (self byteAt: functionName+i-1)].
	^self ioLoadFunction: functionString From: pluginString
]

{ #category : #'plugin support' }
NewspeakInterpreterSimulator >> ioLoadFunction: functionString From: pluginString [
	"Load and return the requested function from a module"
	| plugin fnSymbol |
	fnSymbol := functionString asSymbol.
	transcript cr; show:'Looking for ', functionString, ' in '.
	pluginString isEmpty
		ifTrue:[transcript show: 'vm']
		ifFalse:[transcript show: pluginString].
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
NewspeakInterpreterSimulator >> ioMSecs [
	"Return the value of the millisecond clock."
	"NOT.  Actually, we want something a lot slower and, for exact debugging,
	something more repeatable than real time.  IO have an idea: use the byteCount..."

	^ byteCount // 100
	
"At 20k bytecodes per second, this gives us aobut 200 ticks per second, or about 1/5 of what you'd expect for the real time clock.  This should still service events at one or two per second"
]

{ #category : #'I/O primitives support' }
NewspeakInterpreterSimulator >> ioMicroMSecs [
	"Answer the value of the high-resolution millisecond clock."

	^ Time millisecondClockValue

]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> ioProcessEvents [
]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> ioScreenDepth [
	^DisplayScreen actualScreenDepth.
]

{ #category : #'I/O primitives support' }
NewspeakInterpreterSimulator >> ioScreenSize [
	"Return the screen extent packed into 32 bits."

	^ (displayForm width << 16) + displayForm height
]

{ #category : #'I/O primitives support' }
NewspeakInterpreterSimulator >> ioSeconds [
	"Return the value of the second clock."

	^ Time primSecondsClock
]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> ioSetInputSemaphore: index [

	self primitiveFail
]

{ #category : #'primitive support' }
NewspeakInterpreterSimulator >> isPrimitiveFunctionPointerAnIndex [
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

{ #category : #'plugin support' }
NewspeakInterpreterSimulator >> loadNewPlugin: pluginString [
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
	plugin setInterpreter: self. "Ignore return value from setInterpreter"
	(plugin respondsTo: #initialiseModule) ifTrue:
		[plugin initialiseModule ifFalse:
			[transcript show: ' ... initialiser failed'. ^nil]]. "module initialiser failed"
	pluginList := pluginList copyWith: (pluginString asString -> plugin).
	transcript show: ' ... loaded'.
	^pluginList last
]

{ #category : #testing }
NewspeakInterpreterSimulator >> logOfBytesVerify: nBytes fromFileNamed: fileName fromStart: loggingStart [
	"Verify a questionable interpreter against a successful run"
	"self logOfBytesVerify: 10000 fromFileNamed: 'clone32Bytecodes.log' "
	
	| logFile rightByte prevCtxt |
	logFile := (FileStream readOnlyFileNamed: fileName) binary.
	transcript clear.
	byteCount := 0.
	quitBlock := [^ self].
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
		byteCount := byteCount + 1.
		byteCount \\ 10000 = 0 ifTrue: [self fullDisplayUpdate]].
	self externalizeIPandSP.
	logFile close.
	self inform: nBytes printString , ' bytecodes verfied.'
]

{ #category : #testing }
NewspeakInterpreterSimulator >> logOfBytesWrite: nBytes toFileNamed: fileName fromStart: loggingStart [
	"Write a log file for testing a flaky interpreter on the same image"
	"self logOfBytesWrite: 10000 toFileNamed: 'clone32Bytecodes.log' "
	
	| logFile |
	logFile := (FileStream newFileNamed: fileName) binary.
	transcript clear.
	byteCount := 0.
	quitBlock := [^ self].
	self internalizeIPandSP.
	self fetchNextBytecode.
	[byteCount < nBytes] whileTrue:
		[byteCount >= loggingStart ifTrue:
			[logFile nextPut: currentBytecode].
		self dispatchOn: currentBytecode in: BytecodeTable.
		byteCount := byteCount + 1.
		byteCount \\ 10000 = 0 ifTrue: [self fullDisplayUpdate]].
	self externalizeIPandSP.
	logFile close
]

{ #category : #testing }
NewspeakInterpreterSimulator >> logOfSendsVerify: nSends fromFileNamed: fileName fromStart: loggingStart [
	"Write a log file for testing a flaky interpreter on the same image"
	"self logOfSendsWrite: 10000 toFileNamed: 'clone32Messages.log' "
	
	| logFile priorContext rightSelector prevCtxt |
	logFile := FileStream readOnlyFileNamed: fileName.
	transcript clear.
	byteCount := 0.
	sendCount := 0.
	priorContext := activeContext.
	quitBlock := [^ self].
	self internalizeIPandSP.
	self fetchNextBytecode.
	prevCtxt := 0.  prevCtxt := prevCtxt.
	[sendCount < nSends] whileTrue:
		[
"
byteCount>500 ifTrue:
[byteCount>550 ifTrue: [self halt].
self externalizeIPandSP.
prevCtxt = activeContext ifFalse:
 [prevCtxt := activeContext.
 transcript cr; nextPutAll: (self printTop: 2); endEntry].
transcript cr; print: byteCount; nextPutAll: ': ' , (activeContext hex); space;
 print: (instructionPointer - method - (BaseHeaderSize - 2));
 nextPutAll: ': <' , (self byteAt: localIP) hex , '>'; space;
 nextPutAll: (self symbolic: currentBytecode at: localIP inMethod: method); space;
 print: (self stackPointerIndex - TempFrameStart + 1); endEntry.
].
"
		self dispatchOn: currentBytecode in: BytecodeTable.
		activeContext == priorContext ifFalse:
			[sendCount := sendCount + 1.
			 loggingStart >= sendCount ifTrue:
				[rightSelector := logFile nextLine.
				 (self stringOf: messageSelector) = rightSelector ifFalse:
					[self halt: 'halt at ', sendCount printString]].
			priorContext := activeContext].
		byteCount := byteCount + 1.
		byteCount \\ 10000 = 0 ifTrue: [self fullDisplayUpdate]].
	self externalizeIPandSP.
	logFile close.
	self inform: nSends printString , ' sends verfied.'
]

{ #category : #testing }
NewspeakInterpreterSimulator >> logOfSendsWrite: nSends toFileNamed: fileName fromStart: loggingStart [
	"Write a log file for testing a flaky interpreter on the same image"
	"self logOfSendsWrite: 10000 toFileNamed: 'clone32Messages.log' "
	
	| logFile priorContext |
	logFile := FileStream newFileNamed: fileName.
	transcript clear.
	byteCount := 0.
	sendCount := 0.
	priorContext := activeContext.
	quitBlock := [^ self].
	self internalizeIPandSP.
	self fetchNextBytecode.
	[sendCount < nSends] whileTrue:
		[self dispatchOn: currentBytecode in: BytecodeTable.
		activeContext == priorContext ifFalse:
			[sendCount >= loggingStart ifTrue:
				[sendCount := sendCount + 1.
				 logFile nextPutAll: (self stringOf: messageSelector); cr].
			priorContext := activeContext].
		byteCount := byteCount + 1.
		byteCount \\ 10000 = 0 ifTrue: [self fullDisplayUpdate]].
	self externalizeIPandSP.
	logFile close
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> long32At: byteAddress [
	"Return the 32-bit word at byteAddress which must be 0 mod 4."

	^ self longAt: byteAddress
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> long32At: byteAddress put: a32BitValue [
	"Store the 32-bit value at byteAddress which must be 0 mod 4."

	^ self longAt: byteAddress put: a32BitValue
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> longAt: byteAddress [
	"Note: Adjusted for Smalltalk's 1-based array indexing."

	^memory at: (byteAddress // 4) + 1
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> longAt: byteAddress put: a32BitValue [
	"Note: Adjusted for Smalltalk's 1-based array indexing."

	^memory at: (byteAddress // 4) + 1 put: a32BitValue
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> longPrint: oop [
	| lastPtr val lastLong hdrType prevVal |
	(self isIntegerObject: oop) ifTrue: [^ self shortPrint: oop].
	^ String streamContents:
		[:strm |
		lastPtr := 64*self wordSize min: (self lastPointerOf: oop).
		hdrType := self headerType: oop.
		hdrType = 2 ifTrue: [lastPtr := 0].
		prevVal := 0.
		(self headerStart: oop) to: lastPtr by: self wordSize do:
			[:a | val := self longAt: oop+a.
			(a > 0 and: [(val = prevVal) & (a ~= lastPtr)])
			ifTrue:
			[prevVal = (self longAt: oop+a-(self wordSize*2)) ifFalse: [strm cr; nextPutAll: '        ...etc...']]
			ifFalse:
			[strm cr; nextPutAll: (a<16 ifTrue: [' ', a hex] ifFalse: [a hex]); 
				space; space; space; nextPutAll: val hex8; space; space.
			a = (self wordSize*2) negated ifTrue:
				[strm nextPutAll: 'size = ' , (val - hdrType) hex].
			a = self wordSize negated ifTrue:
				[strm nextPutAll: '<' , (self nameOfClass: (val - hdrType)) , '>'].
			a = 0 ifTrue: [strm cr; tab; nextPutAll: (self dumpHeader: val)].
			a > 0 ifTrue: [strm nextPutAll: (self shortPrint: val)].
			a = self wordSize ifTrue:
				[(self isCompiledMethod: oop) ifTrue:
					[strm cr; tab; nextPutAll: (self dumpMethodHeader: val)]]].
			prevVal := val].
		lastLong := 256 min: (self sizeBitsOf: oop) - self baseHeaderSize.
		hdrType = 2
			ifTrue:
			["free" strm cr; nextPutAll: (oop+(self longAt: oop)-2) hex;
			space; space; nextPutAll: (oop+(self longAt: oop)-2) printString]
			ifFalse:
			[(self formatOf: oop) = 3
			ifTrue:
				[strm cr; tab; nextPutAll: '/ next 3 fields are above SP... /'.
				lastPtr+self wordSize to: lastPtr+(3*self wordSize) by: self wordSize do:
					[:a | val := self longAt: oop+a.
					strm cr; nextPutAll: a hex; 
						space; space; space; nextPutAll: val hex8; space; space.
					(self validOop: val) ifTrue: [strm nextPutAll: (self shortPrint: val)]]]
			ifFalse:
			[lastPtr+self wordSize to: lastLong by: self wordSize do:
				[:a | val := self longAt: oop+a.
				strm cr; nextPutAll: (a<16 ifTrue: [' ', a hex] ifFalse: [a hex]); 
					space; space; space.
				strm nextPutAll: val hex8; space; space;
						nextPutAll: (self charsOfLong: val)]]].
	]
]

{ #category : #'file primitives' }
NewspeakInterpreterSimulator >> makeDirEntryName: entryName size: entryNameSize
	createDate: createDate modDate: modifiedDate
	isDir: dirFlag fileSize: fileSize [

	| modDateOop createDateOop nameString results |
	<var: 'entryName' type: 'char *'>

	"allocate storage for results, remapping newly allocated
	 oops in case GC happens during allocation"
	self pushRemappableOop:
		(self instantiateClass: (self splObj: ClassArray) indexableSize: 5).
	self pushRemappableOop:
		(self instantiateClass: (self splObj: ClassByteString) indexableSize: entryNameSize).
	self pushRemappableOop: (self positive32BitIntegerFor: createDate).
	self pushRemappableOop: (self positive32BitIntegerFor: modifiedDate).

	modDateOop   := self popRemappableOop.
	createDateOop := self popRemappableOop.
	nameString    := self popRemappableOop.
	results         := self popRemappableOop.

	1 to: entryNameSize do: [ :i |
		self storeByte: i-1 ofObject: nameString withValue: (entryName at: i) asciiValue.
	].

	self storePointer: 0 ofObject: results withValue: nameString.
	self storePointer: 1 ofObject: results withValue: createDateOop.
	self storePointer: 2 ofObject: results withValue: modDateOop.
	dirFlag
		ifTrue: [ self storePointer: 3 ofObject: results withValue: trueObj ]
		ifFalse: [ self storePointer: 3 ofObject: results withValue: falseObj ].
	self storePointer: 4 ofObject: results
		withValue: (self integerObjectOf: fileSize).
	^ results

]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> nameOfClass: classOop [
	(self sizeBitsOf: classOop) = (Metaclass instSize +1*self wordSize) ifTrue:
		[^ (self nameOfClass:
				(self fetchPointer: 5 "thisClass" ofObject: classOop)) , ' class'].
	^ self stringOf: (self fetchPointer: 6 "name" ofObject: classOop)
]

{ #category : #initialization }
NewspeakInterpreterSimulator >> nextLongFrom: aStream [
	"Read a 32-bit quantity from the given (binary) stream."
	^self subclassResponsibility
]

{ #category : #initialization }
NewspeakInterpreterSimulator >> nextLongFrom: aStream swap: swapFlag [
	swapFlag 
		ifTrue: [^ self byteSwapped: (self nextLongFrom: aStream)]
		ifFalse: [^ self nextLongFrom: aStream]
]

{ #category : #UI }
NewspeakInterpreterSimulator >> openAsMorph [
	"Open a morphic view on this simulation."
	| window localImageName |
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

	window openInWorldExtent: (self desiredDisplayExtent
								+ (2 * window borderWidth)
								+ (0@window labelHeight)
								* (1@(1/0.8))) rounded.
	^window
]

{ #category : #UI }
NewspeakInterpreterSimulator >> openAsMorphNoTranscript [
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
NewspeakInterpreterSimulator >> openOn: fileName [
	"(NewspeakInterpreterSimulator new openOn: 'clonex.image') test"

	self openOn: fileName extraMemory: 2500000.
]

{ #category : #initialization }
NewspeakInterpreterSimulator >> openOn: fileName extraMemory: extraBytes [
	"NewspeakInterpreterSimulator new openOn: 'clone.im' extraMemory: 100000"

	| f version headerSize count oldBaseAddr bytesToShift swapBytes |
	"open image file and read the header"

	["begin ensure block..."
	f := FileStream readOnlyFileNamed: fileName.
	imageName := f fullName.
	f binary.
	version := self nextLongFrom: f.  "current version: 16r1968 (=6504) vive la revolucion!"
	(self readableFormat: version)
		ifTrue: [swapBytes := false]
		ifFalse: [(version := self byteSwapped: version) = self imageFormatVersion
					ifTrue: [swapBytes := true]
					ifFalse: [self error: 'incomaptible image format']].
	headerSize := self nextLongFrom: f swap: swapBytes.
	self setEndOfMemory: (self nextLongFrom: f swap: swapBytes).  "first unused location in heap"
	oldBaseAddr := self nextLongFrom: f swap: swapBytes.  "object memory base address of image"
	specialObjectsOop := self nextLongFrom: f swap: swapBytes.
	lastHash := self nextLongFrom: f swap: swapBytes.  "Should be loaded from, and saved to the image header"
	lastHash = 0 ifTrue: [lastHash := 999].

	savedWindowSize	:= self nextLongFrom: f swap: swapBytes.
	fullScreenFlag		:= self nextLongFrom: f swap: swapBytes.
	extraVMMemory		:= self nextLongFrom: f swap: swapBytes.

	"allocate interpreter memory"
	self setMemoryLimit: endOfMemory + extraBytes.

	"read in the image in bulk, then swap the bytes if necessary"
	f position: headerSize.
	memory := Bitmap new: memoryLimit // 4.
	count := f readInto: memory startingAt: 1 count: endOfMemory // 4.
	count ~= (endOfMemory // 4) ifTrue: [self halt].
	]
		ensure: [f close].

	swapBytes ifTrue: [Utilities informUser: 'Swapping bytes of foreign image...'
								during: [self reverseBytesInImage]].

	self initialize.
	bytesToShift := self startOfMemory - oldBaseAddr.  "adjust pointers for zero base address"
	Utilities informUser: 'Relocating object pointers...'
				during: [self initializeInterpreter: bytesToShift].

]

{ #category : #'other primitives' }
NewspeakInterpreterSimulator >> primBitmapcompresstoByteArray [
	^ self primitiveFail
]

{ #category : #'other primitives' }
NewspeakInterpreterSimulator >> primBitmapdecompressfromByteArrayat [
	| indexInt index baOop bmOop baSize bmSize ba bm |
	indexInt := self stackTop.
	(self isIntegerValue: indexInt) ifFalse: [^ self primitiveFail].
	index := self integerValueOf: indexInt.
	baOop := self stackValue: 1.
	bmOop := self stackValue: 2.
	baSize := self stSizeOf: baOop.
	bmSize := self stSizeOf: bmOop.
	ba := ByteArray new: baSize.
	bm := Bitmap new: bmSize.

	"Copy the byteArray into ba"
	1 to: baSize do: [:i | ba at: i put: (self fetchByte: i-1 ofObject: baOop)].

	"Decompress ba into bm"
	bm decompress: bm fromByteArray: ba at: index.

	"Then copy bm into the Bitmap"
	1 to: bmSize do: [:i | self storeLong32: i-1 ofObject: bmOop withValue: (bm at: i)].
	self pop: 3
]

{ #category : #'other primitives' }
NewspeakInterpreterSimulator >> primStringcomparewithcollated [
	^ self primitiveFail
]

{ #category : #'other primitives' }
NewspeakInterpreterSimulator >> primStringfindSubstringinstartingAtmatchTable [
	^self primitiveFail
]

{ #category : #'other primitives' }
NewspeakInterpreterSimulator >> primStringindexOfAsciiinStringstartingAt [
	^ self primitiveFail
]

{ #category : #'other primitives' }
NewspeakInterpreterSimulator >> primStringtranslatefromtotable [
	^ self primitiveFail
]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> primitiveBeDisplay [
	"Extended to create a scratch Form for use by showDisplayBits."

	| rcvr destWidth destHeight destDepth |
	rcvr := self stackTop.
	self success: ((self isPointers: rcvr) and: [(self lengthOf: rcvr) >= 4]).
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
	super primitiveBeDisplay.
]

{ #category : #'other primitives' }
NewspeakInterpreterSimulator >> primitiveBeep [

	Beeper beep.
]

{ #category : #'file primitives' }
NewspeakInterpreterSimulator >> primitiveDirectoryEntry [
	| name pathName array result |
	name := self stringOf: self stackTop.
	pathName := self stringOf: (self stackValue: 1).
	
	self successful ifFalse:
		[^self primitiveFail].

	array := FileDirectory default primLookupEntryIn: pathName name: name.
	array == nil ifTrue:
		[self pop: 3 thenPush: nilObj.
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
NewspeakInterpreterSimulator >> primitiveDirectoryLookup [
	| index pathName array result |
	index := self stackIntegerValue: 0.
	pathName := (self stringOf: (self stackValue: 1)).
	
	self successful ifFalse: [
		^self primitiveFail.
	].

	array := FileDirectory default primLookupEntryIn: pathName index: index.

	array == nil ifTrue: [
		self pop: 3.
		self push: nilObj.
		^array.
	].
	array == #badDirectoryPath ifTrue: [self halt.
		^self primitiveFail.
	].

	result := self makeDirEntryName: (array at: 1) size: (array at: 1) size
				createDate: (array at: 2) modDate: (array at: 3)
				isDir: (array at: 4)  fileSize: (array at: 5).
	self pop: 3.
	self push: result.

]

{ #category : #'other primitives' }
NewspeakInterpreterSimulator >> primitiveGetAttribute [
	"Fetch the system attribute with the given integer ID. The result is a string, which will be empty if the attribute is not defined."

	| attr s attribute |
	attr := self stackIntegerValue: 0.
	self successful ifTrue: [
		attribute := Smalltalk vm getSystemAttribute: attr.
		attribute ifNil: [ ^self primitiveFail ].
		s := self instantiateClass: (self splObj: ClassByteString) indexableSize: attribute size.
		1 to: attribute size do: [ :i |
			self storeByte: i-1 ofObject: s withValue: (attribute at: i) asciiValue].
		self pop: 2  "rcvr, attr" thenPush: s].

]

{ #category : #'file primitives' }
NewspeakInterpreterSimulator >> primitiveImageName [
	"Note: For now, this only implements getting, not setting, the image file name."
	| result imageNameSize |
	self pop: 1.
	imageNameSize := imageName size.
	result := self instantiateClass: (self splObj: ClassByteString)
				   indexableSize: imageNameSize.
	1 to: imageNameSize do:
		[:i | self storeByte: i-1 ofObject: result
			withValue: (imageName at: i) asciiValue].
	self push: result.
]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> primitiveKbdNext [

	self pop: 1.
	Sensor keyboardPressed
		ifTrue: [self pushInteger: Sensor primKbdNext]
		ifFalse: [self push: nilObj]
]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> primitiveKbdPeek [

	self pop: 1.
	Sensor keyboardPressed
		ifTrue: [self pushInteger: Sensor primKbdPeek]
		ifFalse: [self push: nilObj]
]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> primitiveMouseButtons [
	| buttons |
	self pop: 1.
	buttons := Sensor primMouseButtons.
	self pushInteger: buttons
]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> primitiveMousePoint [

	| relPt |
	self pop: 1.
	displayForm == nil
		ifTrue: [self push: (self makePointwithxValue: 99 yValue: 66)]
		ifFalse: [relPt := Sensor cursorPoint - self displayLocation.
				self push: (self makePointwithxValue: relPt x yValue: relPt y)]
]

{ #category : #'I/O primitives support' }
NewspeakInterpreterSimulator >> primitiveRelinquishProcessor [
	"No-op in simulator"

	^ self pop: 1
]

{ #category : #'debugging traps' }
NewspeakInterpreterSimulator >> primitiveResume [
	"Catch errors before we start the whole morphic error process"

	byteCount > 1000000 ifTrue: [self halt].  "Ignore early process activity"
	^ super primitiveResume
]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> primitiveScreenSize [  "Dummied for now"

	self pop: 1.
	self push: (self makePointwithxValue: 640 yValue: 480).
]

{ #category : #'debugging traps' }
NewspeakInterpreterSimulator >> primitiveSuspend [
	"Catch errors before we start the whole morphic error process"

	byteCount > 1000000 ifTrue: [self halt].  "Ignore early process activity"
	^ super primitiveSuspend
]

{ #category : #'debug printing' }
NewspeakInterpreterSimulator >> print: s [

	traceOn ifTrue: [ transcript show: s ]
]

{ #category : #'debug printing' }
NewspeakInterpreterSimulator >> printChar: aByte [

	traceOn ifTrue: [ transcript nextPut: aByte asCharacter ].
]

{ #category : #'debug printing' }
NewspeakInterpreterSimulator >> printCurrentBytecodeOn: aStream [
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
		nextPut: $(; print: byteCount; nextPut: $)
]

{ #category : #'debug printing' }
NewspeakInterpreterSimulator >> printHex: anInteger [

	traceOn ifTrue:
		[| it16 |
		 it16 := anInteger radix: 16.
		 transcript
			next: 8 - it16 size put: Character space;
			nextPutAll: (anInteger storeStringBase: 16)]
]

{ #category : #'debug printing' }
NewspeakInterpreterSimulator >> printNum: anInteger [

	traceOn ifTrue: [ transcript show: anInteger printString ].
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> printStack [
	^ self printStack: false
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> printStack: includeTemps [
	| ctxt |
	ctxt := activeContext.
	^ String streamContents:
		[:strm |
		[self printStackFrame: ctxt onStream: strm.
		includeTemps ifTrue: [self printStackTemps: ctxt onStream: strm].
		(ctxt := (self fetchPointer: SenderIndex ofObject: ctxt)) = nilObj]
				whileFalse: [].
		]
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> printStackFrame: ctxt onStream: strm [
	| classAndSel home |
	home := (self fetchClassOf: ctxt) = (self splObj: ClassBlockContext)
		ifTrue: [self fetchPointer: HomeIndex ofObject: ctxt]
		ifFalse: [ctxt].
	classAndSel := self
		classAndSelectorOfMethod: (self fetchPointer: MethodIndex ofObject: home)
		forReceiver: (self fetchPointer: ReceiverIndex ofObject: home).
	strm cr; nextPutAll: ctxt hex8.
	ctxt = home ifFalse: [strm nextPutAll: ' [] in'].
	strm space; nextPutAll: (self nameOfClass: classAndSel first).
	strm nextPutAll: '>>'; nextPutAll: (self shortPrint: classAndSel last).

]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> printStackTemps: ctxt onStream: strm [
	| home cMethod nArgs nTemps oop |
	home := (self fetchClassOf: ctxt) = (self splObj: ClassBlockContext)
		ifTrue: [self fetchPointer: HomeIndex ofObject: ctxt]
		ifFalse: [ctxt].
	cMethod := self fetchPointer: MethodIndex ofObject: home.
	nArgs := nTemps := 0.

	home = ctxt ifTrue:
		[strm cr; tab; nextPutAll: 'args: '.
		nArgs := self argumentCountOf: cMethod.
		1 to: nArgs do:
			[:i | oop := self fetchPointer: TempFrameStart + i-1 ofObject: ctxt.
			strm nextPutAll: oop hex; space].

		strm cr; tab; nextPutAll: 'temps: '.
		nTemps := self tempCountOf: cMethod.
		nArgs+1 to: nTemps do:
			[:i | oop := self fetchPointer: TempFrameStart + i-1 ofObject: ctxt.
			strm nextPutAll: oop hex; space]].
	
	strm cr; tab; nextPutAll: 'stack: '.
	nTemps + 1 to: (self lastPointerOf: ctxt)//self wordSize - TempFrameStart do:
		[:i | oop := self fetchPointer: TempFrameStart + i-1 ofObject: ctxt.
			strm nextPutAll: oop hex; space].
	
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> printStackWithTemps [
	^ self printStack: true
]

{ #category : #'debug printing' }
NewspeakInterpreterSimulator >> printStringForCurrentBytecode [
	^String streamContents: [:str| self printCurrentBytecodeOn: str]
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> printTop: n [
	"Print important fields of the top n contexts"
	| ctxt classAndSel home top ip sp |
	ctxt := activeContext.
	^ String streamContents:
		[:strm | 1 to: n do:
			[:i |
			home := (self fetchClassOf: ctxt) = (self splObj: ClassBlockContext)
				ifTrue: [self fetchPointer: HomeIndex ofObject: ctxt]
				ifFalse: [ctxt].
			classAndSel := self
				classAndSelectorOfMethod: (self fetchPointer: MethodIndex ofObject: home)
				forReceiver: (self fetchPointer: ReceiverIndex ofObject: home).
			strm cr; nextPutAll: ctxt hex8.
			ctxt = home ifFalse: [strm nextPutAll: ' [] in'].
			strm space; nextPutAll: (self nameOfClass: classAndSel first).
			strm nextPutAll: '>>'; nextPutAll: (self shortPrint: classAndSel last).
			ctxt = activeContext
				ifTrue: [ip := instructionPointer - method - (self baseHeaderSize - 2).
						sp := self stackPointerIndex - TempFrameStart + 1.
						top := self stackTop]
				ifFalse: [ip := self integerValueOf:
							(self fetchPointer: InstructionPointerIndex ofObject: ctxt).
						sp := self integerValueOf:
							(self fetchPointer: StackPointerIndex ofObject: ctxt).
						top := self longAt: ctxt + (self lastPointerOf: ctxt)].
			strm cr; tab; nextPutAll: 'ip = '; print: ip.
			strm cr; tab; nextPutAll: 'sp = '; print: sp.
			strm cr; tab; nextPutAll: 'top = '; nextPutAll: (self shortPrint: top).
			(ctxt := (self fetchPointer: SenderIndex ofObject: ctxt)) = nilObj
				ifTrue: [^strm contents].
			].
		]
]

{ #category : #testing }
NewspeakInterpreterSimulator >> profile: nBytecodes [
	"(NewspeakInterpreterSimulator new openOn: 'clonex.image') profile: 60000"
	transcript clear.
	byteCount := 0.
	MessageTally spyOn: [self runForNBytes: nBytecodes].
	self close
]

{ #category : #testing }
NewspeakInterpreterSimulator >> profileSends: nBytecodes [
	"(NewspeakInterpreterSimulator new openOn: 'clonex.image') profileSends: 5000"
	MessageTally tallySendsTo: self
		inBlock: [self runForNBytes: nBytecodes]
		showTree: true.
	self close
]

{ #category : #testing }
NewspeakInterpreterSimulator >> run [
	"Just run"
	quitBlock := [([transcript dependents anyOne outermostMorphThat: [:m| m isSystemWindow]]
					on: Error
					do: [:ex| nil])
						ifNotNil: [:window| (UIManager default confirm: 'close?') ifTrue: [window delete]].
				  ^self].
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
NewspeakInterpreterSimulator >> runAtEachStep: aBlock [
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue:
		[aBlock value: currentBytecode.
		 self dispatchOn: currentBytecode in: BytecodeTable.
		 byteCount := byteCount + 1].
	localIP := localIP - 1.
	"undo the pre-increment of IP before returning"
	self externalizeIPandSP
]

{ #category : #testing }
NewspeakInterpreterSimulator >> runAtEachStep: aBlock breakCount: breakCount [
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue:
		[aBlock value: currentBytecode.
		 self dispatchOn: currentBytecode in: BytecodeTable.
		 (byteCount := byteCount + 1) = breakCount ifTrue:
			[self halt]].
	localIP := localIP - 1.
	"undo the pre-increment of IP before returning"
	self externalizeIPandSP
]

{ #category : #testing }
NewspeakInterpreterSimulator >> runForNBytes: nBytecodes [ 
	"Do nByteCodes more bytecode dispatches.
	Keep byteCount up to date.
	This can be run repeatedly."
	| endCount |
	endCount := byteCount + nBytecodes.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[byteCount < endCount]
		whileTrue: [self dispatchOn: currentBytecode in: BytecodeTable.
			byteCount := byteCount + 1].
	localIP := localIP - 1.
	"undo the pre-increment of IP before returning"
	self externalizeIPandSP
]

{ #category : #testing }
NewspeakInterpreterSimulator >> runUntilDivergenceFromTrace: aSequence [
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue:
		[(aSequence at: byteCount + 1) ~~ (BytecodeTable at: currentBytecode + 1) ifTrue:
			[self halt: byteCount printString, ' ', (aSequence at: byteCount + 1), ' ~~ ', (BytecodeTable at: currentBytecode + 1)].
		 self dispatchOn: currentBytecode in: BytecodeTable.
		 byteCount := byteCount + 1].
	localIP := localIP - 1.
	"undo the pre-increment of IP before returning"
	self externalizeIPandSP
]

{ #category : #testing }
NewspeakInterpreterSimulator >> runWithBreakCount: breakCount [
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue:
		[self dispatchOn: currentBytecode in: BytecodeTable.
		 (byteCount := byteCount + 1) = breakCount ifTrue:
			[self halt]].
	localIP := localIP - 1.
	"undo the pre-increment of IP before returning"
	self externalizeIPandSP
]

{ #category : #'debugging traps' }
NewspeakInterpreterSimulator >> sendBreak: selectorString point: selectorLength receiver: receiverOrNil [
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
NewspeakInterpreterSimulator >> shortAt: byteAddress [
    "Return the half-word at byteAddress which must be even."
	^self subclassResponsibility
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> shortAt: byteAddress put: a16BitValue [
	^ self subclassResponsibility
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> shortPrint: oop [
	| name classOop |
	(self isIntegerObject: oop) ifTrue: [^ '=' , (self integerValueOf: oop) printString , 
		' (' , (self integerValueOf: oop) hex , ')'].
	classOop := self fetchClassOf: oop.
	(self sizeBitsOf: classOop) = (Metaclass instSize +1*self wordSize) ifTrue: [
		^ 'class ' , (self nameOfClass: oop)].
	name := self nameOfClass: classOop.
	name size = 0 ifTrue: [name := '??'].
	name = 'String' ifTrue: [^ (self stringOf: oop) printString].
	name = 'ByteString' ifTrue: [^ (self stringOf: oop) printString].
	name = 'Symbol' ifTrue: [^ '#' , (self stringOf: oop)].
	name = 'ByteSymbol' ifTrue: [^ '#' , (self stringOf: oop)].
	name = 'Character' ifTrue: [^ '=' , (Character value: (self integerValueOf: 
				(self fetchPointer: 0 ofObject: oop))) printString].
	name = 'UndefinedObject' ifTrue: [^ 'nil'].
	name = 'False' ifTrue: [^ 'false'].
	name = 'True' ifTrue: [^ 'true'].
	name = 'Float' ifTrue: [^ '=' , (self dbgFloatValueOf: oop) printString].
	name = 'Association' ifTrue: [^ '(' ,
				(self shortPrint: (self longAt: oop + self baseHeaderSize)) ,
				' -> ' ,
				(self longAt: oop + self baseHeaderSize + self wordSize) hex8 , ')'].
	^('AEIOU' includes: name first)
		ifTrue: ['an ' , name]
		ifFalse: ['a ' , name]
]

{ #category : #'I/O primitives' }
NewspeakInterpreterSimulator >> showDisplayBits: destBits w: w h: h d: d left: left right: right top: top bottom: bottom [
	| raster pixPerWord simDisp realDisp rect |
	pixPerWord := 32 // d.
	raster := displayForm width + (pixPerWord - 1) // pixPerWord.
	simDisp := Form new hackBits: memory.
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

{ #category : #'debug printing' }
NewspeakInterpreterSimulator >> space [

	traceOn ifTrue: [ transcript space ]
]

{ #category : #'plugin support' }
NewspeakInterpreterSimulator >> sqGetInterpreterProxy [
	"I am basically my own proxy..."
	^self
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> sqGrowMemory: oldLimit By: delta [

	transcript show: 'grow memory from ', oldLimit printString, ' by ', delta printString; cr.
	memory := memory , (memory class new: delta // 4).
	^ memory size * 4
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> sqMemoryExtraBytesLeft: includingSwap [
	^0
]

{ #category : #'memory access' }
NewspeakInterpreterSimulator >> sqShrinkMemory: oldLimit By: delta [
	transcript show: 'shrink memory from ', oldLimit printString, ' by ', delta printString, ' remember it doesn''t actually shrink in simulation'; cr.

	^ oldLimit
]

{ #category : #testing }
NewspeakInterpreterSimulator >> stackDepth [
	| ctxt n |
	ctxt := activeContext.
	n := 0.
	[(ctxt := (self fetchPointer: SenderIndex ofObject: ctxt)) = nilObj]
		whileFalse: [n := n+1].
	^ n
]

{ #category : #initialization }
NewspeakInterpreterSimulator >> startOfMemory [
	"Return the start of object memory."

	^ 0
]

{ #category : #testing }
NewspeakInterpreterSimulator >> stats [
	| oop fieldAddr fieldOop last stats v d |
	stats := Bag new.
	oop := self firstObject.

'Scanning the image...' displayProgressAt: Sensor cursorPoint
	from: oop to: endOfMemory
	during: [:bar |

	[oop < endOfMemory] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[stats add: #objects.
			fieldAddr := oop + (self lastPointerOf: oop).
			[fieldAddr > oop] whileTrue:
				[fieldOop := self longAt: fieldAddr.
				(self isIntegerObject: fieldOop)
					ifTrue: [v := self integerValueOf: fieldOop.
							(v between: -16000 and: 16000)
								ifTrue: [stats add: #ints32k]
								ifFalse: [stats add: #intsOther]]
					ifFalse: [fieldOop = nilObj ifTrue: [stats add: #nil]
							ifFalse:
							[d := fieldOop - oop.
							(d between: -16000 and: 16000)
								ifTrue: [stats add: #oops32k]
								ifFalse: [stats add: #oopsOther]]].
				fieldAddr := fieldAddr - self wordSize]].
		bar value: oop.
		last := oop.
		last := last.
		oop := self objectAfter: oop]].
	^ stats sortedElements
]

{ #category : #'float primitives' }
NewspeakInterpreterSimulator >> storeFloatAt: floatBitsAddress from: aFloat [

	self long32At: floatBitsAddress put: (aFloat at: 1).
	self long32At: floatBitsAddress+4 put: (aFloat at: 2).

]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> stringOf: oop [
	| size long nLongs chars |
	^ String streamContents:
		[:strm |
		size := 100 min: (self stSizeOf: oop).
		nLongs := size-1//self wordSize+1.
		1 to: nLongs do:
			[:i | long := self longAt: oop + self baseHeaderSize + (i-1*self wordSize).
			chars := self charsOfLong: long.
			strm nextPutAll: (i=nLongs
							ifTrue: [chars copyFrom: 1 to: size-1\\self wordSize+1]
							ifFalse: [chars])]]
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> tenuringIncrementalGC [
	transcript cr; nextPutAll: 'tenuringIncrementalGC ('; print: byteCount; nextPut: $); flush.
	^super tenuringIncrementalGC
]

{ #category : #testing }
NewspeakInterpreterSimulator >> test [
	transcript clear.
	byteCount := 0.
	quitBlock := [^ self].
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue:
		[self dispatchOn: currentBytecode in: BytecodeTable.
		byteCount := byteCount + 1.
		byteCount \\ 10000 = 0 ifTrue: [self fullDisplay]].
	self externalizeIPandSP.

]

{ #category : #testing }
NewspeakInterpreterSimulator >> test1 [
	transcript clear.
	byteCount := 0.
	breakCount := -1.
	breakSelector := #openOn:context:label:contents:fullView:.
	quitBlock := [^self].
	printSends := true.
	printBytecodeAtEachStep := false.
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue:
		[printBytecodeAtEachStep ifTrue:
			[self printCurrentBytecodeOn: Transcript.
			 Transcript cr; flush].

		 self dispatchOn: currentBytecode in: BytecodeTable.

		 byteCount := byteCount + 1.
		 byteCount = breakCount ifTrue:
			["printFrameAtEachStep :=" printBytecodeAtEachStep := true.
			 self halt: 'hit breakCount break-point'].
		 byteCount \\ 10000 = 0 ifTrue: [self fullDisplay]].
	self externalizeIPandSP
]

{ #category : #testing }
NewspeakInterpreterSimulator >> testBecome [
	"Become some young things.  AA testBecome    "
	| array list1 list2 p1 p2 p3 p4 |
	array := self splObj: ClassArray.
	list1 := self instantiateClass: array indexableSize: 2.
	list2 := self instantiateClass: array indexableSize: 2.
	p1 := self instantiateClass: (self splObj: ClassPoint) indexableSize: 0.
	self push: p1.
	self storePointer: 0 ofObject: list1 withValue: p1.
	p2 := self instantiateClass: (self splObj: ClassPoint) indexableSize: 0.
	self push: p2.
	self storePointer: 1 ofObject: list1 withValue: p2.
	p3 := self instantiateClass: (self splObj: ClassMessage) indexableSize: 0.
	self push: p3.
	self storePointer: 0 ofObject: list2 withValue: p3.
	p4 := self instantiateClass: (self splObj: ClassMessage) indexableSize: 0.
	self push: p4.
	self storePointer: 1 ofObject: list2 withValue: p4.
	(self become: list1 with: list2 twoWay: true copyHash: true) ifFalse: [self error: 'failed'].
	self popStack = p2 ifFalse: [self halt].
	self popStack = p1 ifFalse: [self halt].
	self popStack = p4 ifFalse: [self halt].
	self popStack = p3 ifFalse: [self halt].
	(self fetchPointer: 0 ofObject: list1) = p3 ifFalse: [self halt].
	(self fetchPointer: 1 ofObject: list1) = p4 ifFalse: [self halt].
	(self fetchPointer: 0 ofObject: list2) = p1 ifFalse: [self halt].
	(self fetchPointer: 1 ofObject: list2) = p2 ifFalse: [self halt].
]

{ #category : #UI }
NewspeakInterpreterSimulator >> toggleTranscript [
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

{ #category : #'interpreter shell' }
NewspeakInterpreterSimulator >> unableToReadImageError [
	self error:  'Read failed or premature end of image file'
]

{ #category : #UI }
NewspeakInterpreterSimulator >> utilitiesMenu: aMenuMorph [
	aMenuMorph
		add: 'toggle transcript' action: #toggleTranscript;
		addLine;
		add: 'print active context' action: [self printContext: activeContext WithSP: localSP];
		add: 'print int head frame' action: #printHeadFrame;
		add: 'print call stack' action: #printCallStack;
		add: 'print oop...' action: [(self promptHex: 'print oop') ifNotNil: [:oop| self printOop: oop]];
		addLine;
		add: 'inspect interpreter' action: #inspect;
		addLine;
		add: 'set break count...' action: [|s| s := UIManager default request: 'break count (dec)'.
											s notEmpty ifTrue: [breakCount := Integer readFrom: s readStream]];
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
		add: (printContextAtEachStep
				ifTrue: ['no print context each bytecode']
				ifFalse: ['print context each bytecode'])
			action: [self ensureDebugAtEachStepBlock.
					printContextAtEachStep := printBytecodeAtEachStep not].
	^aMenuMorph
]

{ #category : #testing }
NewspeakInterpreterSimulator >> validOop: oop [
	" Return true if oop appears to be valid "
	(oop bitAnd: 1) = 1 ifTrue: [^ true].  "Integer"
	(oop bitAnd: 3) = 0 ifFalse: [^ false].  "Uneven address"
	oop >= endOfMemory ifTrue: [^ false].  "Out of range"
	"could test if within the first large freeblock"
	(self longAt: oop) = 4 ifTrue: [^ false].
	(self headerType: oop) = 2 ifTrue: [^ false].	"Free object"
	^ true
]

{ #category : #testing }
NewspeakInterpreterSimulator >> validateActiveContext [
	self validateOopsIn: activeContext.	"debug -- test if messed up"
]

{ #category : #testing }
NewspeakInterpreterSimulator >> validateOopsIn: object [
	| fieldPtr limit former header | 
	"for each oop in me see if it is legal"
	fieldPtr := object + self baseHeaderSize.	"first field"
	limit := object + (self lastPointerOf: object).	"a good field"
	[fieldPtr > limit] whileFalse: [
		former := self longAt: fieldPtr.
		(self validOop: former) ifFalse: [self error: 'invalid oop in pointers object'].
		fieldPtr := fieldPtr + self wordSize].
	"class"
	header := self baseHeader: object.
	(header bitAnd: CompactClassMask) = 0 ifTrue: [	
		former := (self classHeader: object) bitAnd: AllButTypeMask.
		(self validOop: former) ifFalse: [self halt]].
]

{ #category : #'file primitives' }
NewspeakInterpreterSimulator >> vmPathGet: stringBase Length: stringSize [
	| pathName stringOop |
	pathName := Smalltalk vmPath.
	stringOop := stringBase - self baseHeaderSize. "Due to C call in Interp"
	1 to: stringSize do:
		[:i | self storeByte: i-1 ofObject: stringOop
			withValue: (pathName at: i) asciiValue].

]

{ #category : #'file primitives' }
NewspeakInterpreterSimulator >> vmPathSize [
	^ Smalltalk vmPath size
]

{ #category : #'debug support' }
NewspeakInterpreterSimulator >> warning: aString [
	Transcript cr; nextPutAll: aString; flush
]

{ #category : #'I/O primitives support' }
NewspeakInterpreterSimulator >> warpBits [

	^ myBitBlt warpBits
]

{ #category : #'image save/restore' }
NewspeakInterpreterSimulator >> writeImageFileIO: numberOfBytesToWrite [
	"Actually emit the first numberOfBytesToWrite object memory bytes onto the snapshot."

	| headerSize file |
	self wordSize = 4 ifFalse: [self error: 'Not rewritten for 64 bits yet'].
	headerSize := 64.

	[
		file := FileStream fileNamed: imageName.
		file == nil ifTrue:
			[self primitiveFail.
			 ^nil].
		file binary.
	
		{
			self imageFormatVersion.
			headerSize.
			numberOfBytesToWrite.
			self startOfMemory.
			specialObjectsOop.
			lastHash.
			self ioScreenSize.
			fullScreenFlag.
			extraVMMemory
		}
			do: [:long | self putLong: long toFile: file].
	
		"Pad the rest of the header."
		7 timesRepeat: [self putLong: 0 toFile: file].
	
		"Position the file after the header."
		file position: headerSize.
	
		"Write the object memory."
		1
			to: numberOfBytesToWrite // 4
			do: [:index |
				self
					putLong: (memory at: index)
					toFile: file].
	
		self success: true
	]
		ensure: [file ifNotNil: [file close]]
]
