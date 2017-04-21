"
This class defines basic memory access and primitive simulation so that the Interpreter can run simulated in the Squeak environment.  It also defines a number of handy object viewing methods to facilitate pawing around in the object memory.

To see the thing actually run, you could (after backing up this image and changes), execute

	(InterpreterSimulator new openOn: Smalltalk imageName) test

and be patient both to wait for things to happen, and to accept various things that may go wrong depending on how large or unusual your image may be.  We usually do this with a small and simple benchmark image. You will probably have more luck using InterpreteSimulatorLSB or InterpreterSimulatorMSB as befits your machine.
"
Class {
	#name : #InterpreterSimulator,
	#superclass : #Interpreter,
	#instVars : [
		'byteCount',
		'sendCount',
		'breakSelector',
		'traceOn',
		'myBitBlt',
		'displayForm',
		'imageName',
		'pluginList',
		'mappedPluginEntries',
		'quitBlock',
		'transcript',
		'displayView',
		'printSends'
	],
	#category : 'VMMaker-InterpreterSimulation'
}

{ #category : #'instance creation' }
InterpreterSimulator class >> new [
	^ self == InterpreterSimulator
		ifTrue: [SmalltalkImage current endianness == #big
				ifTrue: [InterpreterSimulatorMSB new]
				ifFalse: [InterpreterSimulatorLSB new]]
		ifFalse: [super new]
]

{ #category : #'debug support' }
InterpreterSimulator >> allObjectsSelect: objBlock [
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
InterpreterSimulator >> allocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOop h3: extendedSize doFill: doFill format: format [

	| newObj |
	newObj := super allocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOop h3: extendedSize doFill: doFill format: format.
	"byteCount < 600000 ifTrue: [^ newObj]."
	"(self baseHeader: newObj) =  16r0FCC0600 ifTrue: [self halt]."
	^ newObj
]

{ #category : #'interpreter shell' }
InterpreterSimulator >> browserPluginInitialiseIfNeeded [
"do nothing - its a macro in C code to support Mac browser plugin strangeness"
]

{ #category : #'interpreter shell' }
InterpreterSimulator >> browserPluginReturnIfNeeded [
"do nothing - its a macro in C code to support Mac browser plugin strangeness"
]

{ #category : #'memory access' }
InterpreterSimulator >> byteAt: byteAddress [
	^self subclassResponsibility
]

{ #category : #'memory access' }
InterpreterSimulator >> byteAt: byteAddress put: byte [
	^self subclassResponsibility
]

{ #category : #'memory access' }
InterpreterSimulator >> byteAtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	pointer is a raw address, and byte is an 8-bit quantity."

	^ self byteAt: pointer
]

{ #category : #'memory access' }
InterpreterSimulator >> byteAtPointer: pointer put: byteValue [
	"This gets implemented by Macros in C, where its types will also be checked.
	pointer is a raw address, and byteValue is an 8-bit quantity."

	^ self byteAt: pointer  put: byteValue
]

{ #category : #'debug support' }
InterpreterSimulator >> byteCount [
	"So you can call this from temp debug statements in, eg, Interpreter, such as
	self byteCount = 12661 ifTrue: [self halt].
	"

	^ byteCount
]

{ #category : #UI }
InterpreterSimulator >> byteCountText [
	^ byteCount printString asText
]

{ #category : #'plugin support' }
InterpreterSimulator >> callExternalPrimitive: mapIndex [
	| entry |
	entry := (mappedPluginEntries at: mapIndex).
	^(entry at: 1) perform: (entry at: 2).
]

{ #category : #'debug support' }
InterpreterSimulator >> charsOfLong: long [
	^self subclassResponsibility
]

{ #category : #'debug support' }
InterpreterSimulator >> checkForInterrupts [
	"Prevent interrupts so that traces are consistent during detailed debugging"

	"self halt."
	true ifTrue:
		[interruptCheckCounter := 1000.
		^self].
	^ super checkForInterrupts
]

{ #category : #'debug support' }
InterpreterSimulator >> classAndSelectorOfMethod: meth forReceiver: rcvr [
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
InterpreterSimulator >> classNameOf: aClass Is: className [
	"Check if aClass' name is className"
	| name |
	(self lengthOf: aClass) <= 6 ifTrue:[^false]. "Not a class but maybe behavior" 
	name := self fetchPointer: 6 ofObject: aClass.
	(self isBytes: name) ifFalse:[^false].
	^ className = (self stringOf: name).

]

{ #category : #'I/O primitives' }
InterpreterSimulator >> clipboardRead: sz Into: actualAddress At: zeroBaseIndex [
	| str |
	str := Clipboard clipboardText.
	1 to: sz do:
		[:i | self byteAt: actualAddress + zeroBaseIndex + i - 1 put: (str at: i) asciiValue]
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> clipboardSize [

	^ Clipboard clipboardText size
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> clipboardWrite: sz From: actualDataAddress At: ignored [

	Clipboard clipboardText: (self stringOf: actualDataAddress - self baseHeaderSize)
]

{ #category : #initialization }
InterpreterSimulator >> close [  "close any files that ST may have opened"
	(self loadNewPlugin: 'FilePlugin') ifNotNil:
		[:filePlugin| filePlugin close]
]

{ #category : #'debugging traps' }
InterpreterSimulator >> commonSend [
	| i |
	printSends ifTrue:
		[self print: byteCount; space; printStringOf: messageSelector; cr].
	(i := breakSelector basicSize) = (self lengthOf: messageSelector) ifTrue:
		[[i > 0] whileTrue:
			[(self fetchByte: i - 1 ofObject: messageSelector) = (breakSelector at: i) asInteger
				ifTrue: [(i := i - 1) = 0 ifTrue: [self halt: 'Send of ', breakSelector]]
				ifFalse: [i := 0]]].
	^super commonSend
]

{ #category : #'I/O primitives support' }
InterpreterSimulator >> copyBits [

	^ myBitBlt copyBits
]

{ #category : #'debug printing' }
InterpreterSimulator >> cr [

	traceOn ifTrue: [ transcript cr; endEntry ].
]

{ #category : #'interpreter shell' }
InterpreterSimulator >> dispatchFunctionPointer: selector [
"handle the primitive direct dispatch macro in simulation"
	^self perform: selector
]

{ #category : #'interpreter shell' }
InterpreterSimulator >> dispatchOn: anInteger in: selectorArray [
	"Simulate a case statement via selector table lookup.
	The given integer must be between 0 and selectorArray size-1, inclusive.
	For speed, no range test is done, since it is done by the at: operation.
	Note that, unlike many other arrays used in the Interpreter, this method expect NO CArrayAccessor wrapping - it would duplicate the +1. Maybe this would be better updated to make it all uniform"

	self perform: (selectorArray at: (anInteger + 1)).
]

{ #category : #'I/O primitives support' }
InterpreterSimulator >> displayLocation [

	^ Display extent - displayForm extent - (10@10)
]

{ #category : #'I/O primitives support' }
InterpreterSimulator >> drawLoopX: xDelta Y: yDelta [

	^ myBitBlt drawLoopX: xDelta Y: yDelta
]

{ #category : #'debug support' }
InterpreterSimulator >> dumpHeader: hdr [
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
InterpreterSimulator >> dumpMethodHeader: hdr [
	^ String streamContents:
		[:strm |
		strm nextPutAll: '<nArgs=', ((hdr >> 25) bitAnd: 16r1F) printString , '>'.
		strm nextPutAll: '<nTemps=', ((hdr >> 19) bitAnd: 16r3F) printString , '>'.
		strm nextPutAll: '<lgCtxt=', ((hdr >> 18) bitAnd: 16r1) printString , '>'.
		strm nextPutAll: '<nLits=', ((hdr >> 10) bitAnd: 16rFF) printString , '>'.
		strm nextPutAll: '<prim=', ((hdr >> 1) bitAnd: 16r1FF) printString , '>'.
		]
]

{ #category : #'interpreter shell' }
InterpreterSimulator >> fetchByte [

	^ self byteAt: (localIP := localIP + 1).
]

{ #category : #'float primitives' }
InterpreterSimulator >> fetchFloatAt: floatBitsAddress into: aFloat [

	aFloat at: 1 put: (self long32At: floatBitsAddress).
	aFloat at: 2 put: (self long32At: floatBitsAddress+4).

]

{ #category : #testing }
InterpreterSimulator >> findNewMethodInClass: class [
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
InterpreterSimulator >> firstIndexableField: oop [
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
InterpreterSimulator >> flushExternalPrimitives [
	mappedPluginEntries := #().
	super flushExternalPrimitives.
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> fullDisplay [
	| t |
	displayForm == nil ifTrue: [^ self].
	t := successFlag.  successFlag := true.
	self displayBitsOf: (self splObj: TheDisplay) Left: 0 Top: 0 Right: displayForm width Bottom: displayForm height.
	successFlag := t
]

{ #category : #'debug support' }
InterpreterSimulator >> fullDisplayUpdate [
	"Preserve successFlag when call asynchronously from Simulator"
	| s |
	s := successFlag.
	successFlag := true.
	super fullDisplayUpdate.
	successFlag := s
]

{ #category : #'debug support' }
InterpreterSimulator >> fullGC [
	transcript cr; show:'<Running full GC ...'.
	super fullGC.
	transcript show: ' done>'.
]

{ #category : #'interpreter shell' }
InterpreterSimulator >> functionPointerFor: primIndex inClass: lookupClass [
	"Override Interpreter to handle the external primitives caching.  See also 	internalExecuteNewMethod."

	^(primIndex between: 1 and: MaxPrimitiveIndex)
		ifTrue: [primitiveTable at: primIndex + 1]
]

{ #category : #'memory access' }
InterpreterSimulator >> halfWordHighInLong32: long32 [
	^self subclassResponsibility
]

{ #category : #'memory access' }
InterpreterSimulator >> halfWordLowInLong32: long32 [
	^self subclassResponsibility
]

{ #category : #'debug support' }
InterpreterSimulator >> headerStart: oop [

	^ (self extraHeaderBytes: oop) negated
]

{ #category : #'debug support' }
InterpreterSimulator >> hexDump100: oop [
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
InterpreterSimulator >> hexDump: oop [
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

{ #category : #'debug support' }
InterpreterSimulator >> incrementalGC [
	transcript cr; nextPutAll: 'incrementalGC ('; print: byteCount; nextPut: $); flush.
	^super incrementalGC
]

{ #category : #initialization }
InterpreterSimulator >> initialize [
	"Initialize the InterpreterSimulator when running the interpreter inside
	Smalltalk. The primary responsibility of this method is to allocate
	Smalltalk Arrays for variables that will be declared as statically-allocated
	global arrays in the translated code."

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
	semaphoresUseBufferA := true.
	semaphoresToSignalA := Array new: SemaphoresToSignalSize.
	semaphoresToSignalB := Array new: SemaphoresToSignalSize.
	externalPrimitiveTable := CArrayAccessor on: (Array new: MaxExternalPrimitiveTableSize).
	primitiveTable := self class primitiveTable.
	pluginList := {'' -> self }.
	mappedPluginEntries := #().

	"initialize InterpreterSimulator variables used for debugging"
	byteCount := 0.
	sendCount := 0.
	quitBlock := [^ self].
	traceOn := true.
	printSends := "printReturns := printBytecodeAtEachStep :=" false.
	myBitBlt := BitBltSimulator new setInterpreter: self.
	headerTypeBytes := CArrayAccessor on: HeaderTypeExtraBytes.
	transcript := Transcript.
	displayForm := 'Display has not yet been installed' asDisplayText form.
	
]

{ #category : #'interpreter shell' }
InterpreterSimulator >> insufficientMemoryAvailableError [
	self error: 'Failed to allocate memory for the heap'
]

{ #category : #'interpreter shell' }
InterpreterSimulator >> insufficientMemorySpecifiedError [
	self error: 'Insufficient memory for this image'
]

{ #category : #'interpreter shell' }
InterpreterSimulator >> internalExecuteNewMethod [
"Override the Interpreter version to trap cached external prims.
These have a 'prim index' of 1000 + the externalPrimitiveTableIndex normally used"
	primitiveIndex < 1000 ifTrue:[^super internalExecuteNewMethod].
	self externalizeIPandSP.
	self callExternalPrimitive: (externalPrimitiveTable at: primitiveIndex - 1001).
	self internalizeIPandSP
]

{ #category : #'interpreter shell' }
InterpreterSimulator >> interpreter [
	^self
]

{ #category : #'interpreter shell' }
InterpreterSimulator >> invalidCompactClassError: name [
	self error: 'Class ', name, ' does not have the required compact class index'
]

{ #category : #security }
InterpreterSimulator >> ioCanRenameImage [
	^true
]

{ #category : #security }
InterpreterSimulator >> ioCanWriteImage [
	^true
]

{ #category : #testing }
InterpreterSimulator >> ioExit [

	quitBlock value  "Cause return from #test"
]

{ #category : #'other primitives' }
InterpreterSimulator >> ioForceDisplayUpdate [
	"no-op"
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> ioGetNextEvent: evtBuf [

	self primitiveFail.

]

{ #category : #'I/O primitives' }
InterpreterSimulator >> ioHasDisplayDepth: depth [
	^Display supportsDisplayDepth: depth
]

{ #category : #'plugin support' }
InterpreterSimulator >> ioLoadExternalFunction: functionName OfLength: functionLength FromModule: moduleName OfLength: moduleLength [
	"Load and return the requested function from a module"
	| pluginString functionString |
	pluginString := String new: moduleLength.
	1 to: moduleLength do:[:i| pluginString byteAt: i put: (self byteAt: moduleName+i-1)].
	functionString := String new: functionLength.
	1 to: functionLength do:[:i| functionString byteAt: i put: (self byteAt: functionName+i-1)].
	^self ioLoadFunction: functionString From: pluginString
]

{ #category : #'plugin support' }
InterpreterSimulator >> ioLoadFunction: functionString From: pluginString [
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
InterpreterSimulator >> ioMSecs [
	"Return the value of the millisecond clock."
	"NOT.  Actually, we want something a lot slower and, for exact debugging,
	something more repeatable than real time.  IO have an idea: use the byteCount..."

	^ byteCount // 100
	
"At 20k bytecodes per second, this gives us aobut 200 ticks per second, or about 1/5 of what you'd expect for the real time clock.  This should still service events at one or two per second"
]

{ #category : #'I/O primitives support' }
InterpreterSimulator >> ioMicroMSecs [
	"Answer the value of the high-resolution millisecond clock."

	^ Time millisecondClockValue

]

{ #category : #'I/O primitives' }
InterpreterSimulator >> ioProcessEvents [
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> ioScreenDepth [
	^DisplayScreen actualScreenDepth.
]

{ #category : #'I/O primitives support' }
InterpreterSimulator >> ioScreenScaleFactor [
	^ 1.0
]

{ #category : #'I/O primitives support' }
InterpreterSimulator >> ioScreenSize [
	"Return the screen extent packed into 32 bits."

	^ (displayForm width << 16) + displayForm height
]

{ #category : #'I/O primitives support' }
InterpreterSimulator >> ioSeconds [
	"Return the value of the second clock."

	^ Time primSecondsClock
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> ioSetInputSemaphore: index [

	self primitiveFail
]

{ #category : #'plugin support' }
InterpreterSimulator >> loadNewPlugin: pluginString [
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
InterpreterSimulator >> logOfBytesVerify: nBytes fromFileNamed: fileName fromStart: loggingStart [
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
InterpreterSimulator >> logOfBytesWrite: nBytes toFileNamed: fileName fromStart: loggingStart [
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
InterpreterSimulator >> logOfSendsVerify: nSends fromFileNamed: fileName fromStart: loggingStart [
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
InterpreterSimulator >> logOfSendsWrite: nSends toFileNamed: fileName fromStart: loggingStart [
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
InterpreterSimulator >> long32At: byteAddress [
	"Return the 32-bit word at byteAddress which must be 0 mod 4."

	^ self longAt: byteAddress
]

{ #category : #'memory access' }
InterpreterSimulator >> long32At: byteAddress put: a32BitValue [
	"Store the 32-bit value at byteAddress which must be 0 mod 4."

	^ self longAt: byteAddress put: a32BitValue
]

{ #category : #'memory access' }
InterpreterSimulator >> longAt: byteAddress [
	"Note: Adjusted for Smalltalk's 1-based array indexing."

	^memory at: (byteAddress // 4) + 1
]

{ #category : #'memory access' }
InterpreterSimulator >> longAt: byteAddress put: a32BitValue [
	"Note: Adjusted for Smalltalk's 1-based array indexing."

	^memory at: (byteAddress // 4) + 1 put: a32BitValue
]

{ #category : #'debug support' }
InterpreterSimulator >> longPrint: oop [
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
InterpreterSimulator >> makeDirEntryName: entryName size: entryNameSize
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

{ #category : #'file primitives' }
InterpreterSimulator >> makeDirEntryName: entryName size: entryNameSize createDate: createDate modDate: modifiedDate isDir: dirFlag fileSize: posixPermissions posixPermissions: fileSize isSymlink: symlinkFlag [
	<option: #PharoVM>
	<var: 'entryName' type: 'char *'>

	| modDateOop createDateOop nameString results |

	"allocate storage for results, remapping newly allocated
	 oops in case GC happens during allocation"
	self pushRemappableOop:
		(self instantiateClass: (self splObj: ClassArray) indexableSize: 6).
	self pushRemappableOop:
		(self instantiateClass: (self splObj: ClassString) indexableSize: entryNameSize)..
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
	self storePointer: 4 
		ofObject: results
		withValue: (self integerObjectOf: fileSize).
	self storePointer: 5 
		ofObject: results
		withValue: (self integerObjectOf: posixPermissions).
	dirFlag
		ifTrue: [ self storePointer: 6 ofObject: results withValue: trueObj ]
		ifFalse: [ self storePointer: 6 ofObject: results withValue: falseObj ].

	^ results

]

{ #category : #'debug support' }
InterpreterSimulator >> nameOfClass: classOop [
	(self sizeBitsOf: classOop) = (Metaclass instSize +1*self wordSize) ifTrue:
		[^ (self nameOfClass:
				(self fetchPointer: 5 "thisClass" ofObject: classOop)) , ' class'].
	^ self stringOf: (self fetchPointer: 6 "name" ofObject: classOop)
]

{ #category : #initialization }
InterpreterSimulator >> nextLongFrom: aStream [
	"Read a 32-bit quantity from the given (binary) stream."
	^self subclassResponsibility
]

{ #category : #initialization }
InterpreterSimulator >> nextLongFrom: aStream swap: swapFlag [
	swapFlag 
		ifTrue: [^ self byteSwapped: (self nextLongFrom: aStream)]
		ifFalse: [^ self nextLongFrom: aStream]
]

{ #category : #'debugging traps' }
InterpreterSimulator >> normalSend [
	"Catch errors before we start the whole morphic error process"

	"(byteCount > 4000000 and: [(self stringOf: messageSelector) = 'sorts:before:'])
		ifTrue: [self halt]."
	^ super normalSend
]

{ #category : #UI }
InterpreterSimulator >> openAsMorph [
	"Open a morphic view on this simulation."
	| window localImageName |
	localImageName := imageName
							ifNotNil: [FileDirectory default localNameFor: imageName]
							ifNil: [' synthetic image'].
	window := (SystemWindow labelled: 'Simulation of ' , localImageName) model: self.

	window addMorph: (displayView := ImageMorph new image: displayForm)
		frame: (0@0 corner: 1@0.8).

	transcript := TranscriptStream on: (String new: 10000).
	window addMorph: (PluggableTextMorph on: transcript text: nil accept: nil
			readSelection: nil menu: #codePaneMenu:shifted:)
		frame: (0@0.8 corner: 0.7@1).

	window addMorph: (PluggableTextMorph on: self
						text: #byteCountText accept: nil) hideScrollBarsIndefinitely
		frame: (0.7@0.8 corner: 1@1).

	window openInWorld.
	^window
]

{ #category : #initialization }
InterpreterSimulator >> openOn: fileName [
	"(InterpreterSimulator new openOn: 'clonex.image') test"

	self openOn: fileName extraMemory: 2500000.
]

{ #category : #initialization }
InterpreterSimulator >> openOn: fileName extraMemory: extraBytes [
	"InterpreterSimulator new openOn: 'clone.im' extraMemory: 100000"

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
InterpreterSimulator >> primBitmapcompresstoByteArray [
	^ self primitiveFail
]

{ #category : #'other primitives' }
InterpreterSimulator >> primBitmapdecompressfromByteArrayat [
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
InterpreterSimulator >> primStringcomparewithcollated [
	^ self primitiveFail
]

{ #category : #'other primitives' }
InterpreterSimulator >> primStringfindSubstringinstartingAtmatchTable [
	^self primitiveFail
]

{ #category : #'other primitives' }
InterpreterSimulator >> primStringindexOfAsciiinStringstartingAt [
	^ self primitiveFail
]

{ #category : #'other primitives' }
InterpreterSimulator >> primStringtranslatefromtotable [
	^ self primitiveFail
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> primitiveBeDisplay [
	"Extended to create a scratch Form for use by showDisplayBits."

	| rcvr destWidth destHeight destDepth |
	rcvr := self stackTop.
	self success: ((self isPointers: rcvr) and: [(self lengthOf: rcvr) >= 4]).
	successFlag ifTrue: [
		destWidth := self fetchInteger: 1 ofObject: rcvr.
		destHeight := self fetchInteger: 2 ofObject: rcvr.
		destDepth := self fetchInteger: 3 ofObject: rcvr.
	].
	successFlag ifTrue: [
		"create a scratch form the same size as Smalltalk displayObj"
		displayForm := Form extent: destWidth @ destHeight
							depth: destDepth.
		displayView ifNotNil: [displayView image: displayForm].
	].
	super primitiveBeDisplay.
]

{ #category : #'other primitives' }
InterpreterSimulator >> primitiveBeep [

	Beeper beep.
]

{ #category : #'file primitives' }
InterpreterSimulator >> primitiveDirectoryEntry [
	| name pathName array result |
	name := self stringOf: self stackTop.
	pathName := self stringOf: (self stackValue: 1).
	
	successFlag ifFalse:
		[^self primitiveFail].

	array := FileDirectory default primLookupEntryIn: pathName name: name.
	array == nil ifTrue:
		[self pop: 3 thenPush: nilObj.
		^array].
	array == #badDirectoryPath ifTrue:
		[self halt.
		^self primitiveFail].

	PharoVM 
		ifTrue: [
			result := self makeDirEntryName: (array at: 1) size: (array at: 1) size 
				createDate: (array at: 2) modDate: (array at: 3)
				isDir: (array at: 4) fileSize: (array at: 5)
				posixPermissions: (array at: 6) isSymlink: (array at: 7) ]
		ifFalse: [ 
			result := self makeDirEntryName: (array at: 1) size: (array at: 1) size
				createDate: (array at: 2) modDate: (array at: 3)
				isDir: (array at: 4)  fileSize: (array at: 5) ].
	self pop: 3.
	self push: result
]

{ #category : #'file primitives' }
InterpreterSimulator >> primitiveDirectoryLookup [
	| index pathName array result |
	index := self stackIntegerValue: 0.
	pathName := (self stringOf: (self stackValue: 1)).
	
	successFlag ifFalse: [
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

	PharoVM
		ifTrue: [
			result := self makeDirEntryName: (array at: 1) size: (array at: 1) size
				createDate: (array at: 2) modDate: (array at: 3)
				isDir: (array at: 4) fileSize: (array at: 5)
				posixPermissions: (array at: 6) isSymlink: (array at: 7) ]
		ifFalse: [ 
			result := self makeDirEntryName: (array at: 1) size: (array at: 1) size
				createDate: (array at: 2) modDate: (array at: 3)
				isDir: (array at: 4)  fileSize: (array at: 5) ].
	self pop: 3.
	self push: result.

]

{ #category : #'other primitives' }
InterpreterSimulator >> primitiveGetAttribute [
	"Fetch the system attribute with the given integer ID. The result is a string, which will be empty if the attribute is not defined."

	| attr s attribute |
	attr := self stackIntegerValue: 0.
	successFlag ifTrue: [
		attribute := Smalltalk vm getSystemAttribute: attr.
		attribute ifNil: [ ^self primitiveFail ].
		s := self instantiateClass: (self splObj: ClassByteString) indexableSize: attribute size.
		1 to: attribute size do: [ :i |
			self storeByte: i-1 ofObject: s withValue: (attribute at: i) asciiValue].
		self pop: 2  "rcvr, attr" thenPush: s].

]

{ #category : #'file primitives' }
InterpreterSimulator >> primitiveImageName [
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
InterpreterSimulator >> primitiveKbdNext [

	self pop: 1.
	Sensor keyboardPressed
		ifTrue: [self pushInteger: Sensor primKbdNext]
		ifFalse: [self push: nilObj]
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> primitiveKbdPeek [

	self pop: 1.
	Sensor keyboardPressed
		ifTrue: [self pushInteger: Sensor primKbdPeek]
		ifFalse: [self push: nilObj]
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> primitiveMouseButtons [
	| buttons |
	self pop: 1.
	buttons := Sensor primMouseButtons.
	self pushInteger: buttons
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> primitiveMousePoint [

	| relPt |
	self pop: 1.
	displayForm == nil
		ifTrue: [self push: (self makePointwithxValue: 99 yValue: 66)]
		ifFalse: [relPt := Sensor cursorPoint - self displayLocation.
				self push: (self makePointwithxValue: relPt x yValue: relPt y)]
]

{ #category : #'I/O primitives support' }
InterpreterSimulator >> primitiveRelinquishProcessor [
	"No-op in simulator"

	^ self pop: 1
]

{ #category : #'debugging traps' }
InterpreterSimulator >> primitiveResume [
	"Catch errors before we start the whole morphic error process"

	byteCount > 1000000 ifTrue: [self halt].  "Ignore early process activity"
	^ super primitiveResume
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> primitiveScreenScaleFactor [ "Dummied for now"

	self pop: 1.
	self pushFloat: 1.0

]

{ #category : #'I/O primitives' }
InterpreterSimulator >> primitiveScreenSize [  "Dummied for now"

	self pop: 1.
	self push: (self makePointwithxValue: 640 yValue: 480).
]

{ #category : #'debugging traps' }
InterpreterSimulator >> primitiveSuspend [
	"Catch errors before we start the whole morphic error process"

	byteCount > 1000000 ifTrue: [self halt].  "Ignore early process activity"
	^ super primitiveSuspend
]

{ #category : #'debug printing' }
InterpreterSimulator >> print: s [

	traceOn ifTrue: [ transcript show: s ]
]

{ #category : #'debug printing' }
InterpreterSimulator >> printChar: aByte [

	traceOn ifTrue: [ transcript nextPut: aByte asCharacter ].
]

{ #category : #'debug printing' }
InterpreterSimulator >> printCurrentBytecodeOn: aStream [
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
InterpreterSimulator >> printHex: anInteger [

	traceOn ifTrue:
		[| it16 |
		 it16 := anInteger radix: 16.
		 transcript
			next: 8 - it16 size put: Character space;
			nextPutAll: (anInteger storeStringBase: 16)]
]

{ #category : #'debug printing' }
InterpreterSimulator >> printNum: anInteger [

	traceOn ifTrue: [ transcript show: anInteger printString ].
]

{ #category : #'debug support' }
InterpreterSimulator >> printStack [
	^ self printStack: false
]

{ #category : #'debug support' }
InterpreterSimulator >> printStack: includeTemps [
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
InterpreterSimulator >> printStackFrame: ctxt onStream: strm [
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
InterpreterSimulator >> printStackTemps: ctxt onStream: strm [
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
InterpreterSimulator >> printStackWithTemps [
	^ self printStack: true
]

{ #category : #'debug printing' }
InterpreterSimulator >> printStringForCurrentBytecode [
	^String streamContents: [:str| self printCurrentBytecodeOn: str]
]

{ #category : #'debug support' }
InterpreterSimulator >> printTop: n [
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
InterpreterSimulator >> profile: nBytecodes [
	"(InterpreterSimulator new openOn: 'clonex.image') profile: 60000"
	transcript clear.
	byteCount := 0.
	MessageTally spyOn: [self runForNBytes: nBytecodes].
	self close
]

{ #category : #testing }
InterpreterSimulator >> profileSends: nBytecodes [
	"(InterpreterSimulator new openOn: 'clonex.image') profileSends: 5000"
	MessageTally tallySendsTo: self
		inBlock: [self runForNBytes: nBytecodes]
		showTree: true.
	self close
]

{ #category : #testing }
InterpreterSimulator >> runAtEachStep: aBlock [
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
InterpreterSimulator >> runAtEachStep: aBlock breakCount: breakCount [
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
InterpreterSimulator >> runForNBytes: nBytecodes [ 
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
InterpreterSimulator >> runUntilDivergenceFromTrace: aSequence [
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
InterpreterSimulator >> runWithBreakCount: breakCount [
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

{ #category : #'memory access' }
InterpreterSimulator >> shortAt: byteAddress [
    "Return the half-word at byteAddress which must be even."
	^self subclassResponsibility
]

{ #category : #'memory access' }
InterpreterSimulator >> shortAt: byteAddress put: a16BitValue [
	^ self subclassResponsibility
]

{ #category : #'debug support' }
InterpreterSimulator >> shortPrint: oop [
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
	name = 'Float' ifTrue: [successFlag := true. ^ '=' , (self floatValueOf: oop) printString].
	name = 'Association' ifTrue: [^ '(' ,
				(self shortPrint: (self longAt: oop + self baseHeaderSize)) ,
				' -> ' ,
				(self longAt: oop + self baseHeaderSize + self wordSize) hex8 , ')'].
	('AEIOU' includes: name first)
		ifTrue: [^ 'an ' , name]
		ifFalse: [^ 'a ' , name]
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> showDisplayBits: destBits w: w h: h d: d left: left right: right top: top bottom: bottom [
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
InterpreterSimulator >> space [

	traceOn ifTrue: [ transcript space ]
]

{ #category : #'plugin support' }
InterpreterSimulator >> sqGetInterpreterProxy [
	"I am basically my own proxy..."
	^self
]

{ #category : #'memory access' }
InterpreterSimulator >> sqGrowMemory: oldLimit By: delta [

	transcript show: 'grow memory from ', oldLimit printString, ' by ', delta printString; cr.
	memory := memory , (memory class new: delta // 4).
	^ memory size * 4
]

{ #category : #'memory access' }
InterpreterSimulator >> sqMemoryExtraBytesLeft: includingSwap [
	^0
]

{ #category : #'memory access' }
InterpreterSimulator >> sqShrinkMemory: oldLimit By: delta [
	transcript show: 'shrink memory from ', oldLimit printString, ' by ', delta printString, ' remember it doesn''t actually shrink in simulation'; cr.

	^ oldLimit
]

{ #category : #testing }
InterpreterSimulator >> stackDepth [
	| ctxt n |
	ctxt := activeContext.
	n := 0.
	[(ctxt := (self fetchPointer: SenderIndex ofObject: ctxt)) = nilObj]
		whileFalse: [n := n+1].
	^ n
]

{ #category : #initialization }
InterpreterSimulator >> startOfMemory [
	"Return the start of object memory."

	^ 0
]

{ #category : #testing }
InterpreterSimulator >> stats [
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

{ #category : #'bytecode routines' }
InterpreterSimulator >> storeAndPopReceiverVariableBytecode [
	"Note: This code uses storePointerUnchecked:ofObject:withValue: and does the store check explicitely in order to help the translator produce better code."

	"Interpreter version has fetchNextBytecode out of order"
	| rcvr top |
	rcvr := receiver.
	top := self internalStackTop.
	(rcvr < youngStart) ifTrue: [
		self possibleRootStoreInto: rcvr value: top.
	].
	self storePointerUnchecked: (currentBytecode bitAnd: 7)
		ofObject: rcvr
		withValue: top.
	self internalPop: 1.
	self fetchNextBytecode.

]

{ #category : #'float primitives' }
InterpreterSimulator >> storeFloatAt: floatBitsAddress from: aFloat [

	self long32At: floatBitsAddress put: (aFloat at: 1).
	self long32At: floatBitsAddress+4 put: (aFloat at: 2).

]

{ #category : #'debug support' }
InterpreterSimulator >> stringOf: oop [
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
InterpreterSimulator >> tenuringIncrementalGC [
	transcript cr; nextPutAll: 'tenuringIncrementalGC ('; print: byteCount; nextPut: $); flush.
	^super tenuringIncrementalGC
]

{ #category : #testing }
InterpreterSimulator >> test [
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
InterpreterSimulator >> test1 [
	| breakCount printBytecodeAtEachStep |
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
InterpreterSimulator >> testBecome [
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

{ #category : #'interpreter shell' }
InterpreterSimulator >> unableToReadImageError [
	self error:  'Read failed or premature end of image file'
]

{ #category : #testing }
InterpreterSimulator >> validOop: oop [
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
InterpreterSimulator >> validateActiveContext [
	self validateOopsIn: activeContext.	"debug -- test if messed up"
]

{ #category : #testing }
InterpreterSimulator >> validateOopsIn: object [
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
InterpreterSimulator >> vmPathGet: stringBase Length: stringSize [
	| pathName stringOop |
	pathName := Smalltalk vmPath.
	stringOop := stringBase - self baseHeaderSize. "Due to C call in Interp"
	1 to: stringSize do:
		[:i | self storeByte: i-1 ofObject: stringOop
			withValue: (pathName at: i) asciiValue].

]

{ #category : #'file primitives' }
InterpreterSimulator >> vmPathSize [
	^ Smalltalk vmPath size
]

{ #category : #'debug support' }
InterpreterSimulator >> warning: aString [
	Transcript cr; nextPutAll: aString; flush
]

{ #category : #'I/O primitives support' }
InterpreterSimulator >> warpBits [

	^ myBitBlt warpBits
]

{ #category : #'image save/restore' }
InterpreterSimulator >> writeImageFileIO: numberOfBytesToWrite [
	"Actually emit the first numberOfBytesToWrite object memory bytes onto the snapshot."

	| headerSize file |
	self wordSize = 4 ifFalse: [self error: 'Not rewritten for 64 bits yet'].
	headerSize := 64.

	[
		file := (FileStream fileNamed: imageName) binary.
		file == nil ifTrue: [^nil].
	
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
		ensure: [file close]
]
