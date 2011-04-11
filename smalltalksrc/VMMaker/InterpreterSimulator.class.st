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
		'bytesPerWord',
		'byteCount',
		'sendCount',
		'traceOn',
		'myBitBlt',
		'displayForm',
		'filesOpen',
		'imageName',
		'pluginList',
		'mappedPluginEntries',
		'inputSem',
		'quitBlock',
		'transcript',
		'displayView',
		'logging'
	],
	#category : #'VMMaker-InterpreterSimulation'
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
InterpreterSimulator >> allObjectsDo: objBlock [

	| oop |
	oop := self firstObject.
	[oop < endOfMemory] whileTrue:
			[(self isFreeObject: oop)
				ifFalse: [objBlock value: oop].
			oop := self objectAfter: oop].

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
InterpreterSimulator >> allocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOop h3: extendedSize doFill: doFill with: fillWord [ 

	| newObj |
	newObj := super allocate: byteSize headerSize: hdrSize h1: baseHeader h2: classOop h3: extendedSize doFill: doFill with: fillWord.
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

{ #category : #'memory access' }
InterpreterSimulator >> bytesPerWord [
	"BytesPerWord was a class variable in ObjectMemory, permitting each object
	memory to have its own word size."

	^ bytesPerWord ifNil: [bytesPerWord := 4]
]

{ #category : #'memory access' }
InterpreterSimulator >> bytesPerWord: fourOrEight [
	"BytesPerWord was a class variable in ObjectMemory, permitting each object
	memory to have its own word size."

	bytesPerWord := fourOrEight
]

{ #category : #'memory access' }
InterpreterSimulator >> cCoerce: value to: cTypeString [
	"Type coercion for translation only; just return the value when running in Smalltalk."

	^value == nil
		ifTrue: [value]
		ifFalse: [value coerceTo: cTypeString sim: self]
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

	true ifTrue: [^ self].
	^ super checkForInterrupts
]

{ #category : #'debug support' }
InterpreterSimulator >> classAndSelectorOfMethod: meth forReceiver: rcvr [
	| mClass dict length methodArray |
	mClass := self fetchClassOf: rcvr.
	[dict := self fetchPointer: MessageDictionaryIndex ofObject: mClass.
	length := self fetchWordLengthOf: dict.
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
	filesOpen do: [:f | f close]
]

{ #category : #'debug support' }
InterpreterSimulator >> compactClassAt: ccIndex [
	"Index must be between 1 and compactClassArray size. (A zero compact class index in the base header indicate that the class is in the class header word.)"

	| classArray |
	classArray := self fetchPointer: CompactClasses ofObject: specialObjectsOop.
	^ self fetchPointer: (ccIndex - 1) ofObject: classArray
]

{ #category : #initialization }
InterpreterSimulator >> convertToArray [
	"I dont believe it -- this *just works*"
	
	memory := memory as: Array
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
InterpreterSimulator >> dispatchFunctionPointerOn: index in: table [
"handle the primitive table dispatch macro in simulation"
	^self dispatchOn: index in: table
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
		strm nextPutAll: '<sz=', (hdr bitAnd: self sizeMask) hex , '>'.
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

{ #category : #'file primitives' }
InterpreterSimulator >> fileValueOf: integerPointer [
	"Convert the (integer) fileID to the actual fileStream it uses"
	self success: (self isIntegerObject: integerPointer).
	successFlag
		ifTrue: [^ filesOpen at: (self integerValueOf: integerPointer)]
		ifFalse: [^ nil]
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
	"NOTE: overridden from Interpreter to add coercion to CArray"

	| hdr fmt totalLength fixedFields |
	self returnTypeC: 'void *'.
	hdr := self baseHeader: oop.
	fmt := (hdr >> 8) bitAnd: 16rF.
	totalLength := self lengthOf: oop baseHeader: hdr format: fmt.
	fixedFields := self fixedFieldsOf: oop format: fmt length: totalLength.
	fmt < 8 ifTrue:
		[fmt = 6 ifTrue:
			["32 bit field objects"
			^ self cCoerce: (self pointerForOop: oop + self baseHeaderSize + (fixedFields << 2)) to: 'int *'].
		"full word objects (pointer or bits)"
		^ self cCoerce: (self pointerForOop: oop + self baseHeaderSize + (fixedFields << self shiftForWord)) to: 'oop *']
		ifFalse:
		["Byte objects"
		^ self cCoerce: (self pointerForOop: oop + self baseHeaderSize + fixedFields) to: 'char *']
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

{ #category : #initialization }
InterpreterSimulator >> imageFormatVersion [
	"The imageFormatVersionNumber variable is initialized in Interpreter class>>declareCVarsIn:
	so provide the value here for simulation."

	^ imageFormatVersionNumber
		ifNil: [imageFormatVersionNumber := self bytesPerWord == 4
						ifTrue: [6502]
						ifFalse: [68000]]
]

{ #category : #initialization }
InterpreterSimulator >> initialize [

	"Initialize the InterpreterSimulator when running the interpreter inside
	Smalltalk. The primary responsibility of this method is to allocate
	Smalltalk Arrays for variables that will be declared as statically-allocated
	global arrays in the translated code."

	"initialize class variables"
	ObjectMemory initializeConstants.
	Interpreter initialize.

	"Note: we must initialize ConstMinusOne differently for simulation,
		due to the fact that the simulator works only with +ve 32-bit values"
	ConstMinusOne := self integerObjectOf: -1.

	methodCache := Array new: MethodCacheSize.
	atCache := Array new: AtCacheTotalSize.
	self flushMethodCache.
	rootTable := Array new: RootTableSize.
	weakRoots := Array new: RootTableSize + RemapBufferSize + 100.
	remapBuffer := Array new: RemapBufferSize.
	semaphoresUseBufferA := true.
	semaphoresToSignalA := Array new: SemaphoresToSignalSize.
	semaphoresToSignalB := Array new: SemaphoresToSignalSize.
	externalPrimitiveTable := CArrayAccessor on: (Array new: MaxExternalPrimitiveTableSize).
	primitiveTable := self class primitiveTable.
	pluginList := #().
	mappedPluginEntries := #().

	"initialize InterpreterSimulator variables used for debugging"
	byteCount := 0.
	sendCount := 0.
	quitBlock := [^ self].
	traceOn := true.
	myBitBlt := BitBltSimulator new setInterpreter: self.
	filesOpen := OrderedCollection new.
	headerTypeBytes := CArrayAccessor on: (Array with: self bytesPerWord * 2 with: self bytesPerWord with: 0 with: 0).
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

{ #category : #'memory access' }
InterpreterSimulator >> integerAt: byteAddress [
	"Note: Adjusted for Smalltalk's 1-based array indexing."

	^memory integerAt: (byteAddress // 4) + 1
]

{ #category : #'memory access' }
InterpreterSimulator >> integerAt: byteAddress put: a32BitValue [
	"Note: Adjusted for Smalltalk's 1-based array indexing."

	^memory integerAt: (byteAddress // 4) + 1 put: a32BitValue
]

{ #category : #'memory access' }
InterpreterSimulator >> integerObjectOf: value [
	"The simulator works with strictly positive bit patterns"
	value < 0
		ifTrue: [^ ((16r80000000 + value) << 1) + 1]
		ifFalse: [^ (value << 1) + 1]
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
	functionString := functionString asSymbol.
	^self ioLoadFunction: functionString From: pluginString
]

{ #category : #'plugin support' }
InterpreterSimulator >> ioLoadFunction: functionString From: pluginString [
	"Load and return the requested function from a module"
	| plugin fnSymbol |
	fnSymbol := functionString asSymbol.
	Transcript cr; show:'Looking for ', functionString, ' in '.
	pluginString isEmpty
		ifTrue:[Transcript show: 'vm']
		ifFalse:[Transcript show: pluginString].
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

{ #category : #'I/O primitives' }
InterpreterSimulator >> ioLowResMSecs [
	^ Time millisecondClockValue
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

{ #category : #'I/O primitives support' }
InterpreterSimulator >> ioMicroSecondClock [
	"Answer the value of the high-resolution millisecond clock."

	^ self ioMicroMSecs * 1000

]

{ #category : #'I/O primitives' }
InterpreterSimulator >> ioProcessEvents [
]

{ #category : #'I/O primitives support' }
InterpreterSimulator >> ioProcessEventsEveryMSecs: mSecs [
	"Noop during simulation."
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> ioScreenDepth [
	^DisplayScreen actualScreenDepth.
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

{ #category : #testing }
InterpreterSimulator >> isBigEnder [
	"Answer true (non-zero) if running on a big endian machine."
	^ self vmEndianness = 1

]

{ #category : #'interpreter shell' }
InterpreterSimulator >> isIntegerValue: valueWord [ 
	^ valueWord >= 16r-40000000 and: [valueWord <= 16r3FFFFFFF]
]

{ #category : #testing }
InterpreterSimulator >> isInterpreterProxy [
	"Return false since I am a real Interpreter simulation"
	^false
]

{ #category : #'plugin support' }
InterpreterSimulator >> loadNewPlugin: pluginString [
	| plugin simClass |
	transcript cr; show:'Looking for module ', pluginString.
	(#('FloatArrayPlugin' 'Matrix2x3Plugin')
		includes: pluginString) ifTrue:
		[transcript show: ' ... defeated'. ^ nil].
	plugin := simClass := nil.
	InterpreterPlugin allSubclassesDo:[:plg|
		plg moduleName asString = pluginString asString ifTrue:[
			simClass := plg simulatorClass.
			plugin ifNil:[plugin := simClass]
				ifNotNil:[plugin == simClass ifFalse:[^self error:'This won''t work...']].
		].
	].
	plugin ifNil:[transcript show: ' ... not found'. ^nil].
	plugin := plugin new.
	plugin setInterpreter: self. "Ignore return value from setInterpreter"
	(plugin respondsTo: #initialiseModule) ifTrue:[
		plugin initialiseModule ifFalse:[transcript show: ' ... initialiser failed'.^nil]. "module initialiser failed"
	].
	pluginList := pluginList copyWith: (pluginString asString -> plugin).
	transcript show:' ... loaded'.
	^pluginList last
]

{ #category : #testing }
InterpreterSimulator >> logOfBytesVerify: nBytes fromFileNamed: fileName fromStart: loggingStart [
	"Verify a questionable interpreter against a successful run"
	"self logOfBytesVerify: 10000 fromFileNamed: 'clone32Bytecodes.log' "
	
	| logFile rightByte prevCtxt |
	logFile := (FileStream readOnlyFileNamed: fileName) binary.
	logging := loggingStart.
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
		logging ifTrue: [rightByte := logFile next.
						currentBytecode = rightByte ifFalse: [self halt]].
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
	logging := loggingStart.
	transcript clear.
	byteCount := 0.
	quitBlock := [^ self].
	self internalizeIPandSP.
	self fetchNextBytecode.
	[logging not or: [byteCount < nBytes]] whileTrue:
		[logging ifTrue: [logFile nextPut: currentBytecode].
		self dispatchOn: currentBytecode in: BytecodeTable.
		byteCount := byteCount + 1.
		byteCount \\ 10000 = 0 ifTrue: [self fullDisplayUpdate]].
	self externalizeIPandSP.
	logFile close.

]

{ #category : #testing }
InterpreterSimulator >> logOfSendsVerify: nSends fromFileNamed: fileName fromStart: loggingStart [
	"Write a log file for testing a flaky interpreter on the same image"
	"self logOfSendsWrite: 10000 toFileNamed: 'clone32Messages.log' "
	
	| logFile priorContext rightSelector prevCtxt |
	logFile := FileStream readOnlyFileNamed: fileName.
	logging := loggingStart.
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
			logging ifTrue: [rightSelector := logFile nextLine.
							(self stringOf: messageSelector) = rightSelector ifFalse: [self halt]].
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
	logging := loggingStart.
	transcript clear.
	byteCount := 0.
	sendCount := 0.
	priorContext := activeContext.
	quitBlock := [^ self].
	self internalizeIPandSP.
	self fetchNextBytecode.
	[logging not or: [sendCount < nSends]] whileTrue:
		[self dispatchOn: currentBytecode in: BytecodeTable.
		activeContext == priorContext ifFalse:
			[logging ifTrue: [sendCount := sendCount + 1.
							logFile nextPutAll: (self stringOf: messageSelector); cr].
			priorContext := activeContext].
		byteCount := byteCount + 1.
		byteCount \\ 10000 = 0 ifTrue: [self fullDisplayUpdate]].
	self externalizeIPandSP.
	logFile close.

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

{ #category : #'memory access' }
InterpreterSimulator >> longAtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	pointer is a raw address, and the result is the width of a machine word."

	^ self longAt: pointer
]

{ #category : #'memory access' }
InterpreterSimulator >> longAtPointer: pointer put: longValue [
	"This gets implemented by Macros in C, where its types will also be checked.
	pointer is a raw address, and longValue is the width of a machine word."

	^ self longAt: pointer put: longValue
]

{ #category : #'debug support' }
InterpreterSimulator >> longPrint: oop [
	| lastPtr val lastLong hdrType prevVal |
	(self isIntegerObject: oop) ifTrue: [^ self shortPrint: oop].
	^ String streamContents:
		[:strm |
		lastPtr := 64 * self bytesPerWord min: (self lastPointerOf: oop).
		hdrType := self headerType: oop.
		hdrType = 2 ifTrue: [lastPtr := 0].
		prevVal := 0.
		(self headerStart: oop) to: lastPtr by: self bytesPerWord do:
			[:a | val := self longAt: oop+a.
			(a > 0 and: [(val = prevVal) & (a ~= lastPtr)])
			ifTrue:
			[prevVal = (self longAt: oop + a - (self bytesPerWord * 2)) ifFalse: [strm cr; nextPutAll: '        ...etc...']]
			ifFalse:
			[strm cr; nextPutAll: (a<16 ifTrue: [' ', a hex] ifFalse: [a hex]); 
				space; space; space; nextPutAll: val hex8; space; space.
			a = (self bytesPerWord * 2) negated ifTrue:
				[strm nextPutAll: 'size = ' , (val - hdrType) hex].
			a = self bytesPerWord negated ifTrue:
				[strm nextPutAll: '<' , (self nameOfClass: (val - hdrType)) , '>'].
			a = 0 ifTrue: [strm cr; tab; nextPutAll: (self dumpHeader: val)].
			a > 0 ifTrue: [strm nextPutAll: (self shortPrint: val)].
			a = self bytesPerWord ifTrue:
				[(self fetchClassOf: oop) = (self splObj: ClassCompiledMethod) ifTrue:
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
				lastPtr + self bytesPerWord to: lastPtr+(3 * self bytesPerWord) by: self bytesPerWord do:
					[:a | val := self longAt: oop+a.
					strm cr; nextPutAll: a hex; 
						space; space; space; nextPutAll: val hex8; space; space.
					(self validOop: val) ifTrue: [strm nextPutAll: (self shortPrint: val)]]]
			ifFalse:
			[lastPtr + self bytesPerWord to: lastLong by: self bytesPerWord do:
				[:a | val := self longAt: oop+a.
				strm cr; nextPutAll: (a<16 ifTrue: [' ', a hex] ifFalse: [a hex]); 
					space; space; space.
				strm nextPutAll: val hex8; space; space;
						nextPutAll: (self charsOfLong: val)]]].
	]
]

{ #category : #'debug support' }
InterpreterSimulator >> lookupMethodInClass: class [
	| currentClass dictionary found rclass |

	"This method overrides the interp, causing a halt on MNU."
	"true ifTrue: [^ super lookupMethodInClass: class]."    "Defeat debug support"

	currentClass := class.
	[currentClass ~= nilObj]
		whileTrue:
		[dictionary := self fetchPointer: MessageDictionaryIndex ofObject: currentClass.
		dictionary = nilObj ifTrue:
			["MethodDict pointer is nil (hopefully due a swapped out stub)
				-- raise exception #cannotInterpret:."
			self pushRemappableOop: currentClass.  "may cause GC!"
			self createActualMessageTo: class.
			currentClass := self popRemappableOop.
			messageSelector := self splObj: SelectorCannotInterpret.
			^ self lookupMethodInClass: (self superclassOf: currentClass)].

		found := self lookupMethodInDictionary: dictionary.
		found ifTrue: [^ methodClass := currentClass].
		currentClass := self superclassOf: currentClass].

	"Could not find #doesNotUnderstand: -- unrecoverable error."
	messageSelector = (self splObj: SelectorDoesNotUnderstand) ifTrue:
		[self error: 'Recursive not understood error encountered'].

self halt: (self stringOf: messageSelector).

	"Cound not find a normal message -- raise exception #doesNotUnderstand:"
	self pushRemappableOop: class.  "may cause GC!"
	self createActualMessageTo: class.
	rclass := self popRemappableOop.
	messageSelector := self splObj: SelectorDoesNotUnderstand.
	^ self lookupMethodInClass: rclass
]

{ #category : #'file primitives' }
InterpreterSimulator >> makeDirEntryName: entryName size: entryNameSize
	createDate: createDate modDate: modifiedDate
	isDir: dirFlag fileSize: fileSize [

	| modDateOop createDateOop nameString results |
	self var: 'entryName' type: 'char *'.

	"allocate storage for results, remapping newly allocated
	 oops in case GC happens during allocation"
	self pushRemappableOop:
		(self instantiateClass: (self splObj: ClassArray) indexableSize: 5).
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
	self storePointer: 4 ofObject: results
		withValue: (self integerObjectOf: fileSize).
	^ results

]

{ #category : #'debug support' }
InterpreterSimulator >> nameOfClass: classOop [
	(self sizeBitsOf: classOop) = (Metaclass instSize + 1 * self bytesPerWord) ifTrue:
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

{ #category : #testing }
InterpreterSimulator >> objectBefore: addr [
	| oop prev |
	oop := self firstObject.
	[oop < endOfMemory] whileTrue: [
		prev := oop.  "look here if debugging prev obj overlapping this one"
		oop := self objectAfter: oop.
		oop >= addr ifTrue: [^ prev]
	]
]

{ #category : #'memory access' }
InterpreterSimulator >> oopForPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	oop is the width of a machine word, and pointer is a raw address."

	^ pointer
]

{ #category : #UI }
InterpreterSimulator >> openAsMorph [
	"Open a morphic view on this simulation."
	| window localImageName |
	localImageName := FileDirectory default localNameFor: imageName.
	window := (SystemWindow labelled: 'Simulation of ' , localImageName) model: self.

	window addMorph: (displayView := ImageMorph new image: displayForm)
		frame: (0@0 corner: 1@0.8).

	transcript := TranscriptStream on: (String new: 10000).
	window addMorph: (PluggableTextMorph on: transcript text: nil accept: nil
			readSelection: nil menu: #codePaneMenu:shifted:)
		frame: (0@0.8 corner: 0.7@1).

	window addMorph: (PluggableTextMorph on: self
						text: #byteCountText accept: nil) hideScrollBarIndefinitely
		frame: (0.7@0.8 corner: 1@1).

	window openInWorld
]

{ #category : #initialization }
InterpreterSimulator >> openOn: fileName [
	"(InterpreterSimulator new openOn: 'clonex.image') test"

	self openOn: fileName extraMemory: 2500000.
]

{ #category : #initialization }
InterpreterSimulator >> openOn: fileName extraMemory: extraBytes [
	"InterpreterSimulator new openOn: 'clone.im' extraMemory: 100000"

	| f version headerSize count oldBaseAddr bytesToShift swapBytes hasPlatformFloatOrdering versionToRun |
	"open image file and read the header"

	["begin ensure block..."
	f := FileStream readOnlyFileNamed: fileName.
	imageName := f fullName.
	f binary.
	version := self nextLongFrom: f.  "current version: 16r1966 (=6502)"
	versionToRun := version bitAnd: -2. "permit loading images with platform float ordering"
	hasPlatformFloatOrdering := version ~= (version bitAnd: -2). "is low order bit set?"
	(self readableFormat: versionToRun) "permit loading images with platform float ordering"
		ifTrue: [swapBytes := false]
		ifFalse: [(versionToRun := self byteSwapped: version) = self imageFormatVersion
					ifTrue: [swapBytes := true]
					ifFalse: [self error: 'incompatible image format']].
	headerSize := self nextLongFrom: f swap: swapBytes.
	endOfMemory := self nextLongFrom: f swap: swapBytes.  "first unused location in heap"
	oldBaseAddr := self nextLongFrom: f swap: swapBytes.  "object memory base address of image"
	specialObjectsOop := self nextLongFrom: f swap: swapBytes.
	lastHash := self nextLongFrom: f swap: swapBytes.  "Should be loaded from, and saved to the image header"
	lastHash = 0 ifTrue: [lastHash := 999].

	savedWindowSize	:= self nextLongFrom: f swap: swapBytes.
	fullScreenFlag		:= self oldFormatFullScreenFlag: (self nextLongFrom: f swap: swapBytes).
	extraVMMemory		:= self nextLongFrom: f swap: swapBytes.

	"allocate interpreter memory"
	memoryLimit := endOfMemory + extraBytes.

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
	bytesToShift := 0 - oldBaseAddr.  "adjust pointers for zero base address"
	endOfMemory := endOfMemory.
	Utilities informUser: 'Relocating object pointers...'
				during: [self initializeInterpreter: bytesToShift].
	hasPlatformFloatOrdering ifTrue: [Utilities informUser: 'Swapping words in float objects...'
								during: [self normalizeFloatOrderingInImage]].

]

{ #category : #'memory access' }
InterpreterSimulator >> pointerForOop: oop [
	"This gets implemented by Macros in C, where its types will also be checked.
	oop is the width of a machine word, and pointer is a raw address."

	^ oop
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

	result := self makeDirEntryName: (array at: 1) size: (array at: 1) size
				createDate: (array at: 2) modDate: (array at: 3)
				isDir: (array at: 4)  fileSize: (array at: 5).
	self pop: 3.
	self push: result.

]

{ #category : #'debugging traps' }
InterpreterSimulator >> primitiveFail [

"(primitiveIndex = 61 and: [byteCount > 210000]) ifTrue: [self halt]."
	successFlag := false.
]

{ #category : #'file primitives' }
InterpreterSimulator >> primitiveFileDelete [ 

	| namePointer |
	namePointer := self stackTop.
	self success: (self isBytes: namePointer).
	self success: (StandardFileStream isAFileNamed: (self stringOf: namePointer)).
	successFlag ifTrue: [FileDirectory deleteFilePath: (self stringOf: namePointer)].
	successFlag ifTrue: [self pop: 1].  "pop fileName; leave rcvr on stack"

]

{ #category : #'file primitives' }
InterpreterSimulator >> primitiveFileOpen [
	| namePointer writeFlag fileName f |
	writeFlag := self booleanValueOf: self stackTop.
	namePointer := self stackValue: 1.
	self success: (self isBytes: namePointer).
	successFlag ifTrue:
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
InterpreterSimulator >> primitiveFileRename [

	| oldNamePointer newNamePointer f |
	oldNamePointer := self stackTop.
	newNamePointer := self stackValue: 1.
	self success: (self isBytes: oldNamePointer).
	self success: (self isBytes: newNamePointer).
	self success: (StandardFileStream isAFileNamed: (self stringOf: oldNamePointer)).
	self success: (StandardFileStream isAFileNamed: (self stringOf: newNamePointer)) not.
	successFlag ifTrue: [
		f := FileStream oldFileNamed: (self stringOf: oldNamePointer).
		f rename: (self stringOf: newNamePointer).
		f close.
	].
	successFlag ifTrue: [
		self pop: 2.  "oldName, newName; leave rcvr on stack"
	].
]

{ #category : #'other primitives' }
InterpreterSimulator >> primitiveGetAttribute [
	"Fetch the system attribute with the given integer ID. The result is a string, which will be empty if the attribute is not defined."

	| attr s attribute |
	attr := self stackIntegerValue: 0.
	successFlag ifTrue: [
		attribute := Smalltalk getSystemAttribute: attr.
		attribute ifNil: [ ^self primitiveFail ].
		s := self instantiateClass: (self splObj: ClassString) indexableSize: attribute size.
		1 to: attribute size do: [ :i |
			self storeByte: i-1 ofObject: s withValue: (attribute at: i) asciiValue].
		self pop: 2.  "rcvr, attr"
		self push: s].

]

{ #category : #'file primitives' }
InterpreterSimulator >> primitiveImageName [
	"Note: For now, this only implements getting, not setting, the image file name."
	| result imageNameSize |
	self pop: 1.
	imageNameSize := imageName size.
	result := self instantiateClass: (self splObj: ClassString)
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
	nTemps + 1 to: (self lastPointerOf: ctxt)//self bytesPerWord - TempFrameStart do:
		[:i | oop := self fetchPointer: TempFrameStart + i-1 ofObject: ctxt.
			strm nextPutAll: oop hex; space].
	
]

{ #category : #'debug support' }
InterpreterSimulator >> printStackWithTemps [
	^ self printStack: true
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

{ #category : #'bytecode routines' }
InterpreterSimulator >> pushLiteralConstantBytecode [

	"Interpreter version has fetchNextBytecode out of order"
	self pushLiteralConstant: (currentBytecode bitAnd: 16r1F).
	self fetchNextBytecode.

]

{ #category : #'bytecode routines' }
InterpreterSimulator >> pushLiteralVariableBytecode [

	"Interpreter version has fetchNextBytecode out of order"
	self pushLiteralVariable: (currentBytecode bitAnd: 16r1F).
	self fetchNextBytecode.

]

{ #category : #'bytecode routines' }
InterpreterSimulator >> pushReceiverVariableBytecode [

	"Interpreter version has fetchNextBytecode out of order"
	self pushReceiverVariable: (currentBytecode bitAnd: 16rF).
	self fetchNextBytecode.

]

{ #category : #'bytecode routines' }
InterpreterSimulator >> pushTemporaryVariableBytecode [

	"Interpreter version has fetchNextBytecode out of order"
	self pushTemporaryVariable: (currentBytecode bitAnd: 16rF).
	self fetchNextBytecode.

]

{ #category : #initialization }
InterpreterSimulator >> reverseBytesFrom: begin to: end [
	"Byte-swap the given range of memory (not inclusive!)."
	| wordAddr |
	wordAddr := begin.
	memory swapBytesFrom: wordAddr // 4 + 1 to: end // 4
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
	(self sizeBitsOf: classOop) = (Metaclass instSize + 1 * self bytesPerWord) ifTrue: [
		^ 'class ' , (self nameOfClass: oop)].
	name := self nameOfClass: classOop.
	name size = 0 ifTrue: [name := '??'].
	name = 'String' ifTrue: [^ (self stringOf: oop) printString].
	name = 'Symbol' ifTrue: [^ '#' , (self stringOf: oop)].
	name = 'Character' ifTrue: [^ '=' , (Character value: (self integerValueOf: 
				(self fetchPointer: 0 ofObject: oop))) printString].
	name = 'UndefinedObject' ifTrue: [^ 'nil'].
	name = 'False' ifTrue: [^ 'false'].
	name = 'True' ifTrue: [^ 'true'].
	name = 'Float' ifTrue: [successFlag := true. ^ '=' , (self floatValueOf: oop) printString].
	name = 'Association' ifTrue: [^ '(' ,
				(self shortPrint: (self longAt: oop + self baseHeaderSize)) ,
				' -> ' ,
				(self longAt: oop + self baseHeaderSize + self bytesPerWord) hex8 , ')'].
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

{ #category : #'memory access' }
InterpreterSimulator >> signalSemaphoreWithIndex: index [
	"Record the given semaphore index in the double buffer semaphores array to be signaled at the next convenient moment. Force a real interrupt check as soon as possible."

	^ index ifNotNil: [super signalSemaphoreWithIndex: index]
]

{ #category : #'I/O primitives support' }
InterpreterSimulator >> sizeof: var [

	self flag: #Dan.
	^ 4
]

{ #category : #'file primitives' }
InterpreterSimulator >> sqFile: file Read: count Into: byteArrayIndex At: startIndex [

	startIndex to: (startIndex + count - 1) do: [ :i |
		file atEnd ifTrue: [ ^ i - startIndex ].
		self byteAt: byteArrayIndex + i put: file next.
	].
	^ count
]

{ #category : #'file primitives' }
InterpreterSimulator >> sqFile: file SetPosition: newPosition [

	file position: newPosition.
]

{ #category : #'file primitives' }
InterpreterSimulator >> sqFile: file Truncate: truncatePosition [

	file truncate: truncatePosition.
]

{ #category : #'file primitives' }
InterpreterSimulator >> sqFile: file Write: count From: byteArrayIndex At: startIndex [

	startIndex to: (startIndex + count - 1) do: [ :i |
		file nextPut: (self byteAt: byteArrayIndex + i).
	].
	^ count
]

{ #category : #'file primitives' }
InterpreterSimulator >> sqFileAtEnd: file [

	^ file atEnd
]

{ #category : #'file primitives' }
InterpreterSimulator >> sqFileClose: file [

	file close.
]

{ #category : #'file primitives' }
InterpreterSimulator >> sqFileFlush: file [

	^ file flush
]

{ #category : #'file primitives' }
InterpreterSimulator >> sqFileGetPosition: file [

	^ file position
]

{ #category : #'file primitives' }
InterpreterSimulator >> sqFileSize: file [

	^ file size
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
				fieldAddr := fieldAddr - self bytesPerWord]].
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

{ #category : #'bytecode routines' }
InterpreterSimulator >> storeAndPopTemporaryVariableBytecode [

	"Interpreter version has fetchNextBytecode out of order"
	self storePointerUnchecked: (currentBytecode bitAnd: 7) + TempFrameStart
		ofObject: localHomeContext
		withValue: self internalStackTop.
	self internalPop: 1.
	self fetchNextBytecode.

]

{ #category : #'float primitives' }
InterpreterSimulator >> storeFloatAt: floatBitsAddress from: aFloat. [

	self long32At: floatBitsAddress put: (aFloat at: 1).
	self long32At: floatBitsAddress+4 put: (aFloat at: 2).

]

{ #category : #'debug support' }
InterpreterSimulator >> stringOf: oop [
	| size long nLongs chars |
	^ String streamContents:
		[:strm |
		size := 100 min: (self stSizeOf: oop).
		nLongs := size - 1 // self bytesPerWord + 1.
		1 to: nLongs do:
			[:i | long := self longAt: oop + self baseHeaderSize + (i - 1 * self bytesPerWord).
			chars := self charsOfLong: long.
			strm nextPutAll: (i=nLongs
							ifTrue: [chars copyFrom: 1 to: size - 1 \\ self bytesPerWord + 1]
							ifFalse: [chars])]]
]

{ #category : #'debug printing' }
InterpreterSimulator >> symbolic: byte at: ip inMethod: meth [
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
	type>12 ifTrue: [^ 'send ' , (self stringOf: (self literal: offset))]
]

{ #category : #'debug printing' }
InterpreterSimulator >> symbolicExtensions: offset at: ip inMethod: meth [
	| type offset2 byte2 byte3 |
	offset <=6 ifTrue: 
		["Extended op codes 128-134"
		byte2 := self byteAt: ip+1.
		offset <= 2 ifTrue:
			["128-130:  extended pushes and pops"
			type := byte2 // 64.
			offset2 := byte2 \\ 64.
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
			[^ 'send ' , (self stringOf: (self literal: byte2 \\ 32))].
		offset = 4 ifTrue:    "Double extended do-anything"
			[byte3 := self byteAt: ip+2.
			type := byte2 // 32.
			type = 0 ifTrue: [^ 'send ' , (self stringOf: (self literal: byte3))].
			type = 1 ifTrue: [^ 'superSend ' , (self stringOf: (self literal: byte3))].
			type = 2 ifTrue: [^ 'pushRcvr ' , byte3 printString].
			type = 3 ifTrue: [^ 'pushLit ' , byte3 printString].
			type = 4 ifTrue: [^ 'pushLitVar ' , byte3 printString].
			type = 5 ifTrue: [^ 'storeIntoRcvr ' , byte3 printString].
			type = 6 ifTrue: [^ 'storePopRcvr ' , byte3 printString].
			type = 7 ifTrue: [^ 'storeIntoLitVar ' , byte3 printString]].
		offset = 5 ifTrue:  "Single extended send to super"
			[^ 'superSend ' , (self stringOf: (self literal: byte2 \\ 32))].
		offset = 6 ifTrue:   "Second extended send"
			[^ 'send ' , (self stringOf: (self literal: byte2 \\ 64))]].
	offset = 7 ifTrue: [^ 'doPop'].
	offset = 8 ifTrue: [^ 'doDup'].
	offset = 9 ifTrue: [^ 'pushActiveContext'].
	^ 'unusedBytecode'
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
InterpreterSimulator >> validate [
	| oop prev |
	transcript show: 'Validating...'.
	oop := self firstObject.
	[oop < endOfMemory] whileTrue: [
		self validate: oop.
		prev := oop.  "look here if debugging prev obj overlapping this one"
		oop := self objectAfter: oop.
	].
	prev := prev.  "Don't offer to delete this please"
	transcript show: 'done.'; cr
]

{ #category : #testing }
InterpreterSimulator >> validate: oop [
	| header type cc sz fmt nextChunk | 
	header := self longAt: oop.
	type := header bitAnd: 3.
	type = 2 ifFalse: [type = (self rightType: header) ifFalse: [self halt]].
	sz := (header bitAnd: self sizeMask) >> 2.
	(self isFreeObject: oop)
		ifTrue: [ nextChunk := oop + (self sizeOfFree: oop) ]
		ifFalse: [  nextChunk := oop + (self sizeBitsOf: oop) ].
	nextChunk > endOfMemory
		ifTrue: [oop = endOfMemory ifFalse: [self halt]].
	(self headerType: nextChunk) = 0 ifTrue: [
		(self headerType: (nextChunk + (self bytesPerWord * 2))) = 0 ifFalse: [self halt]].
	(self headerType: nextChunk) = 1 ifTrue: [
		(self headerType: (nextChunk + self bytesPerWord)) = 1 ifFalse: [self halt]].
	type = 2 ifTrue:
		["free block" ^ self].
	fmt := (header >> 8) bitAnd: 16rF.
	cc := (header >> 12) bitAnd: 31.
	cc > 16 ifTrue: [self halt].	"up to 32 are legal, but not used"
	type = 0 ifTrue:
		["three-word header"
		((self longAt: oop - self bytesPerWord) bitAnd: 3) = type ifFalse: [self halt].
		((self longAt: oop-(self bytesPerWord * 2)) bitAnd: 3) = type ifFalse: [self halt].
		((self longAt: oop - self bytesPerWord) = type) ifTrue: [self halt].	"Class word is 0"
		sz = 0 ifFalse: [self halt]].
	type = 1 ifTrue:
		["two-word header"
		((self longAt: oop - self bytesPerWord) bitAnd: 3) = type ifFalse: [self halt].
		cc > 0 ifTrue: [sz = 1 ifFalse: [self halt]].
		sz = 0 ifTrue: [self halt]].
	type = 3 ifTrue:
		["one-word header"
		cc = 0 ifTrue: [self halt]].
	fmt = 5 ifTrue: [self halt].
	fmt = 7 ifTrue: [self halt].
	fmt >= 12 ifTrue:
		["CompiledMethod -- check for integer header"
		(self isIntegerObject: (self longAt: oop + self bytesPerWord)) ifFalse: [self halt]].
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
		fieldPtr := fieldPtr + self bytesPerWord].
	"class"
	header := self baseHeader: object.
	(header bitAnd: CompactClassMask) = 0 ifTrue: [	
		former := (self classHeader: object) bitAnd: self allButTypeMask.
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

{ #category : #'I/O primitives support' }
InterpreterSimulator >> warpBits [

	^ myBitBlt warpBits
]

{ #category : #'image save/restore' }
InterpreterSimulator >> writeImageFileIO: numberOfBytesToWrite [
	"Actually emit the first numberOfBytesToWrite object memory bytes onto the snapshot."

	| headerSize file |
	self bytesPerWord = 4 ifFalse: [self error: 'Not rewritten for 64 bits yet'].
	headerSize := 16 * self bytesPerWord.

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
