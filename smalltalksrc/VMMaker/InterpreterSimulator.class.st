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
		'traceOn',
		'myBitBlt',
		'displayForm',
		'filesOpen',
		'imageName',
		'pluginList',
		'mappedPluginEntries',
		'inputSem',
		'quitBlock'
	],
	#category : 'VMMaker-InterpreterSimulation'
}

{ #category : #'instance creation' }
InterpreterSimulator class >> new [
	^ self == InterpreterSimulator
		ifTrue: [Smalltalk endianness == #big
				ifTrue: [InterpreterSimulatorMSB new]
				ifFalse: [InterpreterSimulatorLSB new]]
		ifFalse: [super new]
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
InterpreterSimulator >> cCoerce: value to: cTypeString [
	"Type coercion for translation only; just return the value when running in Smalltalk."

	^value == nil
		ifTrue: [value]
		ifFalse: [value coerceTo: cTypeString sim: self]
]

{ #category : #'plugin support' }
InterpreterSimulator >> callExternalPrimitive: mapIndex [
	| entry |
	entry _ (mappedPluginEntries at: mapIndex).
	^(entry at: 1) perform: (entry at: 2).
]

{ #category : #'debug support' }
InterpreterSimulator >> charsOfLong: long [
	^self subclassResponsibility
]

{ #category : #'debug support' }
InterpreterSimulator >> classAndSelectorOfMethod: meth forReceiver: rcvr [
	| mClass dict length methodArray |
	mClass _ self fetchClassOf: rcvr.
	[dict _ self fetchPointer: MessageDictionaryIndex ofObject: mClass.
	length _ self fetchWordLengthOf: dict.
	methodArray _ self fetchPointer: MethodArrayIndex ofObject: dict.
	0 to: length-SelectorStart-1 do: 
		[:index | 
		meth = (self fetchPointer: index ofObject: methodArray) 
			ifTrue: [^ Array
				with: mClass
				with: (self fetchPointer: index + SelectorStart ofObject: dict)]].
	mClass _ self fetchPointer: SuperclassIndex ofObject: mClass.
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
	name _ self fetchPointer: 6 ofObject: aClass.
	(self isBytes: name) ifFalse:[^false].
	^ className = (self stringOf: name).

]

{ #category : #'I/O primitives' }
InterpreterSimulator >> clipboardRead: sz Into: actualAddress At: zeroBaseIndex [
	| str |
	str _ Clipboard clipboardText.
	1 to: sz do:
		[:i | self byteAt: actualAddress + zeroBaseIndex + i - 1 put: (str at: i) asciiValue]
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> clipboardSize [

	^ Clipboard clipboardText size
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> clipboardWrite: sz From: actualDataAddress At: ignored [

	Clipboard clipboardText: (self stringOf: actualDataAddress - BaseHeaderSize)
]

{ #category : #initialization }
InterpreterSimulator >> close [  "close any files that ST may have opened"
	filesOpen do: [:f | f close]
]

{ #category : #'debug support' }
InterpreterSimulator >> compactClassAt: ccIndex [
	"Index must be between 1 and compactClassArray size. (A zero compact class index in the base header indicate that the class is in the class header word.)"

	| classArray |
	classArray _ self fetchPointer: CompactClasses ofObject: specialObjectsOop.
	^ self fetchPointer: (ccIndex - 1) ofObject: classArray
]

{ #category : #'I/O primitives support' }
InterpreterSimulator >> copyBits [

	^ myBitBlt copyBits
]

{ #category : #'debug printing' }
InterpreterSimulator >> cr [

	traceOn ifTrue: [ Transcript cr; endEntry ].
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
		cc _ (hdr bitAnd: CompactClassMask) >> 12.
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

	^ self byteAt: (localIP _ localIP + 1).
]

{ #category : #'float primitives' }
InterpreterSimulator >> fetchFloatAt: floatBitsAddress into: aFloat [

	aFloat at: 1 put: (self longAt: floatBitsAddress).
	aFloat at: 2 put: (self longAt: floatBitsAddress+4).

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
		[cName _ (self sizeBitsOf: class) = 16r20
			ifTrue: ['class ' , (self nameOfClass: (self fetchPointer: 6 ofObject: class))]
			ifFalse: [(self nameOfClass: class)].
		self cr; print: cName , '>>' , (self stringOf: messageSelector)].
"

(self stringOf: messageSelector) = 'doesNotUnderstand:' ifTrue: [self halt].

	sendCount _ sendCount + 1.

"
	(sendCount > 1000 and: [sendCount\\10 = 0]) ifTrue:
		[Transcript print: sendCount; space.
		self validate].
"
"
	(sendCount > 100150) ifTrue:
		[self qvalidate.
		messageQueue == nil ifTrue: [messageQueue _ OrderedCollection new].
		messageQueue addLast: (self stringOf: messageSelector)].
"
	super findNewMethodInClass: class.
]

{ #category : #'plugin support' }
InterpreterSimulator >> flushExternalPrimitives [
	mappedPluginEntries _ #().
	super flushExternalPrimitives.
]

{ #category : #'debug support' }
InterpreterSimulator >> fullGC [
	Transcript cr; show:'<Running full GC ...'.
	super fullGC.
	Transcript show: ' done>'.
]

{ #category : #'memory access' }
InterpreterSimulator >> halfWordAt: byteAddress [
    "Return the half-word at byteAddress which must be even."
	^self subclassResponsibility
]

{ #category : #'memory access' }
InterpreterSimulator >> halfWordAt: byteAddress put: halfWord [
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
		byteSize _ 256.
		(self headerStart: oop) to: byteSize by: 4 do:
			[:a | val _ self longAt: oop+a.
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
		byteSize _ 256 min: (self sizeBitsOf: oop)-4.
		(self headerStart: oop) to: byteSize by: 4 do:
			[:a | val _ self longAt: oop+a.
			strm cr; nextPutAll: (a<16 ifTrue: [' ', a hex] ifFalse: [a hex]); 
				space; space; space; nextPutAll: val hex8;
				space; space.
			a=0
				ifTrue: [strm nextPutAll: (self dumpHeader: val)]
				ifFalse: [strm nextPutAll: (self charsOfLong: val)]]]
]

{ #category : #initialization }
InterpreterSimulator >> initialize [

	"Initialize the InterpreterSimulator when running the interpreter inside
	Smalltalk. The primary responsibility of this method is to allocate
	Smalltalk Arrays for variables that will be declared as statically-allocated
	global arrays in the translated code."

	"initialize class variables"
	ObjectMemory initialize.
	Interpreter initialize.

	methodCache _ Array new: MethodCacheSize.
	atCache _ Array new: AtCacheTotalSize.
	self flushMethodCache.
	rootTable _ Array new: RootTableSize.
	remapBuffer _ Array new: RemapBufferSize.
	semaphoresUseBufferA _ true.
	semaphoresToSignalA _ Array new: SemaphoresToSignalSize.
	semaphoresToSignalB _ Array new: SemaphoresToSignalSize.
	externalPrimitiveTable _ CArrayAccessor on: (Array new: MaxExternalPrimitiveTableSize).
	primitiveTable _ self class primitiveTable.
	obsoleteNamedPrimitiveTable _ 
		CArrayAccessor on: (self class obsoleteNamedPrimitiveTable copyWith: (Array new: 3)).
	obsoleteIndexedPrimitiveTable _ CArrayAccessor on: 
		(self class obsoleteIndexedPrimitiveTable collect:[:spec| 
			CArrayAccessor on:
				(spec ifNil:[Array new: 3] 
					  ifNotNil:[Array with: spec first with: spec second with: nil])]).
	pluginList _ #().
	mappedPluginEntries _ #().

	"initialize InterpreterSimulator variables used for debugging"
	byteCount _ 0.
	sendCount _ 0.
	quitBlock _ [^ self].
	traceOn _ true.
	myBitBlt _ BitBltSimulator new setInterpreter: self.
	displayForm _ nil.  "displayForm is created in response to primitiveBeDisplay"
	filesOpen _ OrderedCollection new.
	headerTypeBytes _ CArrayAccessor on: (Array with:  8 with: 4 with: 0 with: 0).
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
	pluginString _ String new: moduleLength.
	1 to: moduleLength do:[:i| pluginString byteAt: i put: (self byteAt: moduleName+i-1)].
	functionString _ String new: functionLength.
	1 to: functionLength do:[:i| functionString byteAt: i put: (self byteAt: functionName+i-1)].
	functionString _ functionString asSymbol.
	^self ioLoadFunction: functionString From: pluginString
]

{ #category : #'plugin support' }
InterpreterSimulator >> ioLoadFunction: functionString From: pluginString [
	"Load and return the requested function from a module"
	| plugin fnSymbol |
	fnSymbol _ functionString asSymbol.
	Transcript cr; show:'Looking for ', functionString, ' in '.
	pluginString isEmpty
		ifTrue:[Transcript show: 'vm']
		ifFalse:[Transcript show: pluginString].
	plugin _ pluginList 
				detect:[:any| any key = pluginString asString]
				ifNone:[self loadNewPlugin: pluginString].
	plugin ifNil:[
		"Transcript cr; show:'Failed ... no plugin found'." ^ 0].
	plugin _ plugin value.
	mappedPluginEntries doWithIndex:[:pluginAndName :index|
		((pluginAndName at: 1) == plugin 
			and:[(pluginAndName at: 2) == fnSymbol]) ifTrue:[
				"Transcript show:' ... okay'." ^ index]].
	(plugin respondsTo: fnSymbol) ifFalse:[
		"Transcript cr; show:'Failed ... primitive not in plugin'." ^ 0].
	mappedPluginEntries _ mappedPluginEntries copyWith: (Array with: plugin with: fnSymbol).
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

	^ Time millisecondClockValue
]

{ #category : #'I/O primitives support' }
InterpreterSimulator >> ioMicroMSecs [
	"Answer the value of the high-resolution millisecond clock."

	^ Time millisecondClockValue

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
	Transcript cr; show:'Looking for module ', pluginString.
	plugin _ simClass _ nil.
	InterpreterPlugin allSubclassesDo:[:plg|
		plg moduleName asString = pluginString asString ifTrue:[
			simClass _ plg simulatorClass.
			plugin ifNil:[plugin _ simClass]
				ifNotNil:[plugin == simClass ifFalse:[^self error:'This won''t work...']].
		].
	].
	plugin ifNil:[Transcript show: ' ... not found'. ^nil].
	plugin _ plugin new.
	plugin setInterpreter: self. "Ignore return value from setInterpreter"
	(plugin respondsTo: #initialiseModule) ifTrue:[
		plugin initialiseModule ifFalse:[Transcript show: ' ... initialiser failed'.^nil]. "module initialiser failed"
	].
	pluginList _ pluginList copyWith: (pluginString asString -> plugin).
	Transcript show:' ... loaded'.
	^pluginList last
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
		lastPtr _ 256 min: (self lastPointerOf: oop).
		hdrType _ self headerType: oop.
		hdrType = 2 ifTrue: [lastPtr _ 0].
		prevVal _ 0.
		(self headerStart: oop) to: lastPtr by: 4 do:
			[:a | val _ self longAt: oop+a.
			(a > 0 and: [(val = prevVal) & (a ~= lastPtr)])
			ifTrue:
			[prevVal = (self longAt: oop+a-8) ifFalse: [strm cr; nextPutAll: '        ...etc...']]
			ifFalse:
			[strm cr; nextPutAll: (a<16 ifTrue: [' ', a hex] ifFalse: [a hex]); 
				space; space; space; nextPutAll: val hex8; space; space.
			a=-8 ifTrue: [strm nextPutAll: 'size = ' , (val - hdrType) hex].
			a=-4 ifTrue: [strm nextPutAll: '<' , (self nameOfClass: (val - hdrType)) , '>'].
			a=0 ifTrue: [strm cr; tab; nextPutAll: (self dumpHeader: val)].
			a>0 ifTrue: [strm nextPutAll: (self shortPrint: val)].
			a=4 ifTrue: [(self fetchClassOf: oop) = (self splObj: ClassCompiledMethod) ifTrue:
							[strm cr; tab; nextPutAll: (self dumpMethodHeader: val)]]].
			prevVal _ val].
		lastLong _ 256 min: (self sizeBitsOf: oop) - 4.
		hdrType = 2
			ifTrue:
			["free" strm cr; nextPutAll: (oop+(self longAt: oop)-2) hex;
			space; space; nextPutAll: (oop+(self longAt: oop)-2) printString]
			ifFalse:
			[(self formatOf: oop) = 3
			ifTrue:
				[strm cr; tab; nextPutAll: '/ next 3 fields are above SP... /'.
				lastPtr+4 to: lastPtr+12 by: 4 do:
					[:a | val _ self longAt: oop+a.
					strm cr; nextPutAll: a hex; 
						space; space; space; nextPutAll: val hex8; space; space.
					(self validOop: val) ifTrue: [strm nextPutAll: (self shortPrint: val)]]]
			ifFalse:
			[lastPtr+4 to: lastLong by: 4 do:
				[:a | val _ self longAt: oop+a.
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
	self var: 'entryName' declareC: 'char *entryName'.

	"allocate storage for results, remapping newly allocated
	 oops in case GC happens during allocation"
	self pushRemappableOop:
		(self instantiateClass: (self splObj: ClassArray) indexableSize: 5).
	self pushRemappableOop:
		(self instantiateClass: (self splObj: ClassString) indexableSize: entryNameSize)..
	self pushRemappableOop: (self positive32BitIntegerFor: createDate).
	self pushRemappableOop: (self positive32BitIntegerFor: modifiedDate).

	modDateOop   _ self popRemappableOop.
	createDateOop _ self popRemappableOop.
	nameString    _ self popRemappableOop.
	results         _ self popRemappableOop.

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
	(self sizeBitsOf: classOop) = (Metaclass instSize +1*4) ifTrue:
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

{ #category : #testing }
InterpreterSimulator >> objectBefore: addr [
	| oop prev |
	oop _ self firstObject.
	[oop < endOfMemory] whileTrue: [
		prev _ oop.  "look here if debugging prev obj overlapping this one"
		oop _ self objectAfter: oop.
		oop >= addr ifTrue: [^ prev]
	]
]

{ #category : #initialization }
InterpreterSimulator >> openOn: fileName [
	"(InterpreterSimulator new openOn: 'clonex.image') test"

	self openOn: fileName extraMemory: 500000.
]

{ #category : #initialization }
InterpreterSimulator >> openOn: fileName extraMemory: extraBytes [
	"InterpreterSimulator new openOn: 'clone.im' extraMemory: 100000"

	| f version headerSize count oldBaseAddr bytesToShift swapBytes |
	"open image file and read the header"
[
	f _ FileStream readOnlyFileNamed: fileName.
	imageName _ f fullName.
	f binary.
	version _ self nextLongFrom: f.  "current version: 16r1966 (=6502)"
	(self readableFormat: version)
		ifTrue: [swapBytes _ false]
		ifFalse: [(version _ self byteSwapped: version) = self imageFormatVersion
					ifTrue: [swapBytes _ true]
					ifFalse: [self error: 'incomaptible image format']].
	headerSize _ self nextLongFrom: f swap: swapBytes.
	endOfMemory _ self nextLongFrom: f swap: swapBytes.  "first unused location in heap"
	oldBaseAddr _ self nextLongFrom: f swap: swapBytes.  "object memory base address of image"
	specialObjectsOop _ self nextLongFrom: f swap: swapBytes.
	lastHash _ self nextLongFrom: f swap: swapBytes.  "Should be loaded from, and saved to the image header"
	"savedWindowSize _ self nextLongFrom: f swap: swapBytes."
	lastHash = 0 ifTrue: [lastHash _ 999].

	savedWindowSize	_ self nextLongFrom: f swap: swapBytes.
	fullScreenFlag		_ self nextLongFrom: f swap: swapBytes.
	extraVMMemory		_ self nextLongFrom: f swap: swapBytes.

	"allocate interpreter memory"
	memoryLimit _ endOfMemory + extraBytes.

	"read in the image in bulk, then swap the bytes if necessary"
	f position: headerSize.
	memory _ Bitmap new: memoryLimit // 4.
	count _ f readInto: memory startingAt: 1 count: endOfMemory // 4.
	count ~= (endOfMemory // 4) ifTrue: [self halt].
	] ensure: [f close].
	swapBytes ifTrue: [Utilities informUser: 'Swapping bytes of foreign image...'
								during: [self reverseBytesInImage]].

	self initialize.
	bytesToShift _ 0 - oldBaseAddr.  "adjust pointers for zero base address"
	endOfMemory _ endOfMemory.
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
	indexInt _ self stackTop.
	(self isIntegerValue: indexInt) ifFalse: [^ self primitiveFail].
	index _ self integerValueOf: indexInt.
	baOop _ self stackValue: 1.
	bmOop _ self stackValue: 2.
	baSize _ self stSizeOf: baOop.
	bmSize _ self stSizeOf: bmOop.
	ba _ ByteArray new: baSize.
	bm _ Bitmap new: bmSize.

	"Copy the byteArray into ba"
	1 to: baSize do: [:i | ba at: i put: (self fetchByte: i-1 ofObject: baOop)].

	"Decompress ba into bm"
	bm decompress: bm fromByteArray: ba at: index.

	"Then copy bm into the Bitmap"
	1 to: bmSize do: [:i | self storeWord: i-1 ofObject: bmOop withValue: (bm at: i)].
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
	rcvr _ self stackTop.
	self success: ((self isPointers: rcvr) and: [(self lengthOf: rcvr) >= 4]).
	successFlag ifTrue: [
		destWidth _ self fetchInteger: 1 ofObject: rcvr.
		destHeight _ self fetchInteger: 2 ofObject: rcvr.
		destDepth _ self fetchInteger: 3 ofObject: rcvr.
	].
	successFlag ifTrue: [
		"create a scratch form the same size as Smalltalk displayObj"
		displayForm _ Form extent: destWidth @ destHeight
							depth: destDepth.
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
	index _ self stackIntegerValue: 0.
	pathName _ (self stringOf: (self stackValue: 1)).
	
	successFlag ifFalse: [
		^self primitiveFail.
	].

	array _ FileDirectory default primLookupEntryIn: pathName index: index.

	array == nil ifTrue: [
		self pop: 3.
		self push: nilObj.
		^array.
	].
	array == #badDirectoryPath ifTrue: [
		^self primitiveFail.
	].

	result _ self makeDirEntryName: (array at: 1) size: (array at: 1) size
				createDate: (array at: 2) modDate: (array at: 3)
				isDir: (array at: 4)  fileSize: (array at: 5).
	self pop: 3.
	self push: result.

]

{ #category : #'file primitives' }
InterpreterSimulator >> primitiveFileDelete [ 

	| namePointer |
	namePointer _ self stackTop.
	self success: (self isBytes: namePointer).
	self success: (StandardFileStream isAFileNamed: (self stringOf: namePointer)).
	successFlag ifTrue: [FileDirectory deleteFilePath: (self stringOf: namePointer)].
	successFlag ifTrue: [self pop: 1].  "pop fileName; leave rcvr on stack"

]

{ #category : #'file primitives' }
InterpreterSimulator >> primitiveFileOpen [
	| namePointer writeFlag fileName f |
	writeFlag _ self booleanValueOf: self stackTop.
	namePointer _ self stackValue: 1.
	self success: (self isBytes: namePointer).
	successFlag ifTrue:
		[fileName _ self stringOf: namePointer.
		filesOpen addLast: (writeFlag
			ifTrue: [f _ FileStream fileNamed: fileName.
					f ifNil: [^ self primitiveFail] ifNotNil: [f binary]]
			ifFalse: [(StandardFileStream isAFileNamed: fileName)
				ifTrue: [f _ (FileStream readOnlyFileNamed: fileName).
						f ifNil:[^self primitiveFail] ifNotNil:[f binary]]
				ifFalse: [^ self primitiveFail]]).
		self pop: 3.  "rcvr, name, write"
		self pushInteger: filesOpen size]
]

{ #category : #'file primitives' }
InterpreterSimulator >> primitiveFileRename [

	| oldNamePointer newNamePointer f |
	oldNamePointer _ self stackTop.
	newNamePointer _ self stackValue: 1.
	self success: (self isBytes: oldNamePointer).
	self success: (self isBytes: newNamePointer).
	self success: (StandardFileStream isAFileNamed: (self stringOf: oldNamePointer)).
	self success: (StandardFileStream isAFileNamed: (self stringOf: newNamePointer)) not.
	successFlag ifTrue: [
		f _ FileStream oldFileNamed: (self stringOf: oldNamePointer).
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
	attr _ self stackIntegerValue: 0.
	successFlag ifTrue: [
		attribute _ Smalltalk getSystemAttribute: attr.
		attribute ifNil: [ ^self primitiveFail ].
		s _ self instantiateClass: (self splObj: ClassString) indexableSize: attribute size.
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
	imageNameSize _ imageName size.
	result _ self instantiateClass: (self splObj: ClassString)
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
	buttons _ Sensor primMouseButtons.
	self pushInteger: buttons
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> primitiveMousePoint [

	| relPt |
	self pop: 1.
	displayForm == nil
		ifTrue: [self push: (self makePointwithxValue: 99 yValue: 66)]
		ifFalse: [relPt _ Sensor cursorPoint - (Display extent - displayForm extent - (10@10)).
				self push: (self makePointwithxValue: relPt x yValue: relPt y)]
]

{ #category : #'I/O primitives support' }
InterpreterSimulator >> primitiveRelinquishProcessor [
	"No-op in simulator"

	^ self pop: 1
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> primitiveScreenSize [  "Dummied for now"

	self pop: 1.
	self push: (self makePointwithxValue: 640 yValue: 480).
]

{ #category : #'debug printing' }
InterpreterSimulator >> print: s [

	traceOn ifTrue: [ Transcript show: s ]
]

{ #category : #'debug printing' }
InterpreterSimulator >> printChar: aByte [

	traceOn ifTrue: [ Transcript nextPut: aByte asCharacter ].
]

{ #category : #'debug printing' }
InterpreterSimulator >> printNum: anInteger [

	traceOn ifTrue: [ Transcript show: anInteger printString ].
]

{ #category : #'debug support' }
InterpreterSimulator >> printStack [
	| ctxt classAndSel home |
	ctxt _ activeContext.
	^ String streamContents:
		[:strm |
			[home _ (self fetchClassOf: ctxt) = (self splObj: ClassBlockContext)
				ifTrue: [self fetchPointer: HomeIndex ofObject: ctxt]
				ifFalse: [ctxt].
			classAndSel _ self
				classAndSelectorOfMethod: (self fetchPointer: MethodIndex ofObject: home)
				forReceiver: (self fetchPointer: ReceiverIndex ofObject: home).
			strm cr; nextPutAll: ctxt hex8.
			ctxt = home ifFalse: [strm nextPutAll: ' [] in'].
			strm space; nextPutAll: (self nameOfClass: classAndSel first).
			strm nextPutAll: '>>'; nextPutAll: (self shortPrint: classAndSel last).
			(ctxt _ (self fetchPointer: SenderIndex ofObject: ctxt)) = nilObj]
				whileFalse: [].
		]
]

{ #category : #testing }
InterpreterSimulator >> profile: nBytecodes [
	"(InterpreterSimulator new openOn: 'clonex.image') profile: 60000"
	Transcript clear.
	byteCount _ 0.
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
	wordAddr _ begin.
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

{ #category : #'debug support' }
InterpreterSimulator >> shortPrint: oop [
	| name classOop |
	(self isIntegerObject: oop) ifTrue: [^ '=' , (self integerValueOf: oop) printString , 
		' (' , (self integerValueOf: oop) hex , ')'].
	classOop _ self fetchClassOf: oop.
	(self sizeBitsOf: classOop) = (Metaclass instSize +1*4) ifTrue: [
		^ 'class ' , (self nameOfClass: oop)].
	name _ self nameOfClass: classOop.
	name size = 0 ifTrue: [name _ '??'].
	name = 'String' ifTrue: [^ (self stringOf: oop) printString].
	name = 'Symbol' ifTrue: [^ '#' , (self stringOf: oop)].
	name = 'Character' ifTrue: [^ '=' , (Character value: (self integerValueOf: 
				(self fetchPointer: 0 ofObject: oop))) printString].
	name = 'UndefinedObject' ifTrue: [^ 'nil'].
	name = 'False' ifTrue: [^ 'false'].
	name = 'True' ifTrue: [^ 'true'].
	name = 'Float' ifTrue: [^ '=' , (self floatValueOf: oop) printString].
	name = 'Association' ifTrue: [^ '(' ,
				(self shortPrint: (self longAt: oop + BaseHeaderSize)) ,
				' -> ' ,
				(self longAt: oop + BaseHeaderSize + 4) hex8 , ')'].
	('AEIOU' includes: name first)
		ifTrue: [^ 'an ' , name]
		ifFalse: [^ 'a ' , name]
]

{ #category : #'I/O primitives' }
InterpreterSimulator >> showDisplayBits: destBits w: w h: h d: d left: left right: right top: top bottom: bottom [
	| raster pixPerWord simDisp realDisp rect |
	pixPerWord _ 32 // d.
	raster _ displayForm width + (pixPerWord - 1) // pixPerWord.
	simDisp _ Form new hackBits: memory.
	realDisp _ Form new hackBits: displayForm bits.
	realDisp
		copy: (0 @ (top * raster) extent: 4 @ (bottom - top * raster))
		from: 0 @ (destBits // 4 + (top * raster))
		in: simDisp
		rule: Form over.
	rect _ 0 @ top corner: displayForm width @ bottom.
	Display
		copy: (rect translateBy: self displayLocation)
		from: rect topLeft
		in: displayForm
		rule: Form over
]

{ #category : #'I/O primitives support' }
InterpreterSimulator >> sizeof: var [

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
	Transcript show: 'grow memory from ', oldLimit printString, ' by ', delta printString; cr.
	memory _ memory copyGrownBy: delta // 4.
	^ memory size * 4
]

{ #category : #'memory access' }
InterpreterSimulator >> sqMemoryExtraBytesLeft: includingSwap [
	^0
]

{ #category : #'memory access' }
InterpreterSimulator >> sqShrinkMemory: oldLimit By: delta [
	Transcript show: 'shrink memory from ', oldLimit printString, ' by ', delta printString, ' remember it doesn''t actually shrink in simulation'; cr.

	^ oldLimit
]

{ #category : #testing }
InterpreterSimulator >> stackDepth [
	| ctxt n |
	ctxt _ activeContext.
	n _ 0.
	[(ctxt _ (self fetchPointer: SenderIndex ofObject: ctxt)) = nilObj]
		whileFalse: [n _ n+1].
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
	stats _ Bag new.
	oop _ self firstObject.

'Scanning the image...' displayProgressAt: Sensor cursorPoint
	from: oop to: endOfMemory
	during: [:bar |

	[oop < endOfMemory] whileTrue:
		[(self isFreeObject: oop) ifFalse:
			[stats add: #objects.
			fieldAddr _ oop + (self lastPointerOf: oop).
			[fieldAddr > oop] whileTrue:
				[fieldOop _ self longAt: fieldAddr.
				(self isIntegerObject: fieldOop)
					ifTrue: [v _ self integerValueOf: fieldOop.
							(v between: -16000 and: 16000)
								ifTrue: [stats add: #ints32k]
								ifFalse: [stats add: #intsOther]]
					ifFalse: [fieldOop = nilObj ifTrue: [stats add: #nil]
							ifFalse:
							[d _ fieldOop - oop.
							(d between: -16000 and: 16000)
								ifTrue: [stats add: #oops32k]
								ifFalse: [stats add: #oopsOther]]].
				fieldAddr _ fieldAddr - 4]].
		bar value: oop.
		last _ oop.
		last _ last.
		oop _ self objectAfter: oop]].
	^ stats sortedElements
]

{ #category : #'bytecode routines' }
InterpreterSimulator >> storeAndPopReceiverVariableBytecode [
	"Note: This code uses storePointerUnchecked:ofObject:withValue: and does the store check explicitely in order to help the translator produce better code."

	"Interpreter version has fetchNextBytecode out of order"
	| rcvr top |
	rcvr _ receiver.
	top _ self internalStackTop.
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

	self longAt: floatBitsAddress put: (aFloat at: 1).
	self longAt: floatBitsAddress+4 put: (aFloat at: 2).

]

{ #category : #'debug support' }
InterpreterSimulator >> stringOf: oop [
	| size long nLongs chars |
	^ String streamContents:
		[:strm |
		size _ 100 min: (self stSizeOf: oop).
		nLongs _ size-1//4+1.
		1 to: nLongs do:
			[:i | long _ self longAt: oop + BaseHeaderSize + (i-1*4).
			chars _ self charsOfLong: long.
			strm nextPutAll: (i=nLongs
							ifTrue: [chars copyFrom: 1 to: size-1\\4+1]
							ifFalse: [chars])]]
]

{ #category : #testing }
InterpreterSimulator >> test [
	Transcript clear.
	byteCount _ 0.
	quitBlock _ [^ self].
	self internalizeIPandSP.
	self fetchNextBytecode.
	[true] whileTrue:
		[self dispatchOn: currentBytecode in: BytecodeTable.
		byteCount _ byteCount + 1].
	self externalizeIPandSP.

]

{ #category : #testing }
InterpreterSimulator >> testBecome [
	"Become some young things.  AA testBecome    "
	| array list1 list2 p1 p2 p3 p4 |
	array _ self splObj: ClassArray.
	list1 _ self instantiateClass: array indexableSize: 2.
	list2 _ self instantiateClass: array indexableSize: 2.
	p1 _ self instantiateClass: (self splObj: ClassPoint) indexableSize: 0.
	self push: p1.
	self storePointer: 0 ofObject: list1 withValue: p1.
	p2 _ self instantiateClass: (self splObj: ClassPoint) indexableSize: 0.
	self push: p2.
	self storePointer: 1 ofObject: list1 withValue: p2.
	p3 _ self instantiateClass: (self splObj: ClassMessage) indexableSize: 0.
	self push: p3.
	self storePointer: 0 ofObject: list2 withValue: p3.
	p4 _ self instantiateClass: (self splObj: ClassMessage) indexableSize: 0.
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
	Transcript show: 'Validating...'.
	oop _ self firstObject.
	[oop < endOfMemory] whileTrue: [
		self validate: oop.
		prev _ oop.  "look here if debugging prev obj overlapping this one"
		oop _ self objectAfter: oop.
	].
	Transcript show: 'done.'; cr
]

{ #category : #testing }
InterpreterSimulator >> validate: oop [
	| header type cc sz fmt nextChunk | 
	header _ self longAt: oop.
	type _ header bitAnd: 3.
	type = 2 ifFalse: [type = (self rightType: header) ifFalse: [self halt]].
	sz _ (header >> 2) bitAnd: 16r3F.
	(self isFreeObject: oop)
		ifTrue: [ nextChunk _ oop + (self sizeOfFree: oop) ]
		ifFalse: [  nextChunk _ oop + (self sizeBitsOf: oop) ].
	nextChunk > endOfMemory
		ifTrue: [oop = endOfMemory ifFalse: [self halt]].
	(self headerType: nextChunk) = 0 ifTrue: [
		(self headerType: (nextChunk + 8)) = 0 ifFalse: [self halt]].
	(self headerType: nextChunk) = 1 ifTrue: [
		(self headerType: (nextChunk + 4)) = 1 ifFalse: [self halt]].
	type = 2 ifTrue:
		["free block" ^ self].
	fmt _ (header >> 8) bitAnd: 16rF.
	cc _ (header >> 12) bitAnd: 31.
	cc > 16 ifTrue: [self halt].	"up to 32 are legal, but not used"
	type = 0 ifTrue:
		["three-word header"
		((self longAt: oop-4) bitAnd: 3) = type ifFalse: [self halt].
		((self longAt: oop-8) bitAnd: 3) = type ifFalse: [self halt].
		((self longAt: oop-4) = type) ifTrue: [self halt].	"Class word is 0"
		sz = 0 ifFalse: [self halt]].
	type = 1 ifTrue:
		["two-word header"
		((self longAt: oop-4) bitAnd: 3) = type ifFalse: [self halt].
		cc > 0 ifTrue: [sz = 1 ifFalse: [self halt]].
		sz = 0 ifTrue: [self halt]].
	type = 3 ifTrue:
		["one-word header"
		cc = 0 ifTrue: [self halt]].
	fmt = 5 ifTrue: [self halt].
	fmt = 7 ifTrue: [self halt].
	fmt >= 12 ifTrue:
		["CompiledMethod -- check for integer header"
		(self isIntegerObject: (self longAt: oop + 4)) ifFalse: [self halt]].
]

{ #category : #testing }
InterpreterSimulator >> validateActiveContext [
	self validateOopsIn: activeContext.	"debug -- test if messed up"
]

{ #category : #testing }
InterpreterSimulator >> validateOopsIn: object [
	| fieldPtr limit former header | 
	"for each oop in me see if it is legal"
	fieldPtr _ object + BaseHeaderSize.	"first field"
	limit _ object + (self lastPointerOf: object).	"a good field"
	[fieldPtr > limit] whileFalse: [
		former _ self longAt: fieldPtr.
		(self validOop: former) ifFalse: [self halt].
		fieldPtr _ fieldPtr + 4].
	"class"
	header _ self baseHeader: object.
	(header bitAnd: CompactClassMask) = 0 ifTrue: [	
		former _ (self classHeader: object) bitAnd: AllButTypeMask.
		(self validOop: former) ifFalse: [self halt]].
]

{ #category : #'file primitives' }
InterpreterSimulator >> vmPathGet: stringBase Length: stringSize [
	| pathName stringOop |
	pathName _ Smalltalk vmPath.
	stringOop _ stringBase - BaseHeaderSize. "Due to C call in Interp"
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

	headerSize _ 64.

	[
		file _ (FileStream fileNamed: imageName) binary.
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
