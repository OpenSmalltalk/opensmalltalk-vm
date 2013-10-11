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
		'enableCog',
		'byteCount',
		'lastPollCount',
		'lastExtPC',
		'sendCount',
		'printSends',
		'traceOn',
		'myBitBlt',
		'displayForm',
		'imageName',
		'pluginList',
		'mappedPluginEntries',
		'quitBlock',
		'transcript',
		'displayView',
		'printFrameAtEachStep',
		'printBytecodeAtEachStep',
		'systemAttributes',
		'uniqueIndices',
		'uniqueIndex',
		'breakCount',
		'atEachStepBlock',
		'startMicroseconds',
		'externalSemaphoreSignalRequests',
		'externalSemaphoreSignalResponses',
		'extSemTabSize',
		'debugStackDepthDictionary',
		'performFilters'
	],
	#category : #'VMMaker-JITSimulation'
}

{ #category : #'instance creation' }
CogVMSimulator class >> chooseAndInitCogitClassWithOpts: opts [
	| classOrSymbol |
	classOrSymbol := opts at: #Cogit ifAbsent: [Cogit chooseCogitClass].
	classOrSymbol isSymbol ifTrue:
		[classOrSymbol := Smalltalk classNamed: classOrSymbol].
	(CoInterpreter classPool at: #CogitClass put: (classOrSymbol)) initializeWithOptions: opts
]

{ #category : #'class initialization' }
CogVMSimulator class >> initializeWithOptions: optionsDictionaryOrArray objectMemoryClass: objectMemoryClassOrNil [
	"The relevant ObjectMemory, Interpreter and Cogit classes must be initialized in order.
	 This happens notionally every time we start the simulator,
	 but in fact happens when ever we instantiate a simulator."
	| cogitClassOrName |
	initializationOptions := optionsDictionaryOrArray isArray
							ifTrue: [Dictionary newFromPairs: optionsDictionaryOrArray]
							ifFalse: [optionsDictionaryOrArray].
	(objectMemoryClassOrNil ifNil: [self objectMemoryClass])
		initializeWithOptions: initializationOptions.

	((initializationOptions at: #COGMTVM ifAbsent: [false])
			ifTrue: [CoInterpreterMT]
			ifFalse: [CoInterpreter])
		initializeWithOptions: initializationOptions.

	(initializationOptions includesKey: #Cogit) ifTrue:
		[cogitClassOrName := initializationOptions at: #Cogit.
		 cogitClassOrName isSymbol ifTrue:
			[cogitClassOrName := Smalltalk classNamed: cogitClassOrName].
		CoInterpreter classPool at: #CogitClass put: cogitClassOrName].

	(self cogitClass withAllSuperclasses copyUpTo: Cogit) reverseDo:
		[:c| c initializeWithOptions: initializationOptions]
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
	^self == CogVMSimulator
		ifTrue:
			[self initializeWithOptions: optionsDictionaryOrArray
				objectMemoryClass: (anObjectMemory ifNotNil: [anObjectMemory class]).
			 SmalltalkImage current endianness == #big
				ifTrue: [self notYetImplemented]
				ifFalse: [CogVMSimulatorLSB onObjectMemory: anObjectMemory cogit: aCogit options: optionsDictionaryOrArray]]
		ifFalse:
			[| sim |
			self initializeWithOptions: optionsDictionaryOrArray.
			sim := self basicNew.
			sim objectMemory: anObjectMemory.
			sim cogit: aCogit.
			sim initialize.
			COGMTVM ifTrue: "Set via options"
				[sim initializeThreadSupport; initialize].
			sim]
]

{ #category : #'debug support' }
CogVMSimulator >> CFramePointer [
	^self longAt: self inMemoryCFramePointerAddress
]

{ #category : #'debug support' }
CogVMSimulator >> CStackPointer [
	^self longAt: self inMemoryCStackPointerAddress
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

{ #category : #'jump bytecodes' }
CogVMSimulator >> attemptToSwitchToMachineCode: bcpc [
	"method = 16r96A294 ifTrue: [self halt]."
	^super attemptToSwitchToMachineCode: bcpc
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> bindProcess: aProcess toId: newId [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #bindProcess:toId:
		withArguments: {aProcess. newId}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
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
	^(String streamContents: [:s| s print: byteCount; nextPut: $/; print: sendCount]) asText
]

{ #category : #'memory access' }
CogVMSimulator >> cCoerce: value to: cTypeString [
	"Type coercion for translation only; just return the value when running in Smalltalk."

	^value == nil
		ifTrue: [value]
		ifFalse: [value coerceTo: cTypeString sim: self]
]

{ #category : #'translation support' }
CogVMSimulator >> cCoerceSimple: value to: cTypeString [
	"Type coercion for translation and simulation.
	 For simulation answer a suitable surrogate for the struct types"
	^cTypeString caseOf:
	   {	[#'char *']				->	[value].
		[#'void *']				->	[value].
		[#sqInt]					->	[value].
		[#'void (*)()']			->	[value].
		[#'void (*)(void)']		->	[value].
		[#'CogMethod *']		->	[cogit cogMethodSurrogateAt: value asUnsignedInteger].
		[#'CogBlockMethod *']	->	[cogit cogBlockMethodSurrogateAt: value asUnsignedInteger] }
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
	^super ceBaseFrameReturn: returnValue
]

{ #category : #trampolines }
CogVMSimulator >> ceContext: aOnceMarriedContext instVar: slotIndex [
	"aOnceMarriedContext = 26431360 ifTrue: [self halt]."
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

{ #category : #trampolines }
CogVMSimulator >> ceMNUFromPICMNUMethod: aMethodObj receiver: rcvr [
	"self halt."
	^super ceMNUFromPICMNUMethod: aMethodObj receiver: rcvr
]

{ #category : #'debug support' }
CogVMSimulator >> ceNonLocalReturn: returnValue [
	"self halt."
	^super ceNonLocalReturn: returnValue
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
	self maybeCheckStackDepth: 0 sp: stackPointer pc: (stackPages longAt: stackPointer).
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
	^super ceSendFromInLineCacheMiss: surrogate
]

{ #category : #trampolines }
CogVMSimulator >> ceSendMustBeBoolean: anObject [
	self halt.
	^super ceSendMustBeBoolean: anObject
]

{ #category : #'debug support' }
CogVMSimulator >> ceTraceBlockActivation [
	<var: #theFP type: #'char *'>
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

{ #category : #'debug support' }
CogVMSimulator >> charsOfLong: long [
	^self subclassResponsibility
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
	length := objectMemory fetchWordLengthOf: dict.
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
		[:i | self byteAt: actualAddress + zeroBaseIndex + i - 1 put: (str at: i) asciiValue]
]

{ #category : #'I/O primitives' }
CogVMSimulator >> clipboardSize [

	^ Clipboard clipboardText size
]

{ #category : #'I/O primitives' }
CogVMSimulator >> clipboardWrite: sz From: actualDataAddress At: ignored [

	Clipboard clipboardText: (self stringOf: actualDataAddress - BaseHeaderSize)
]

{ #category : #initialization }
CogVMSimulator >> close [  "close any files that ST may have opened"
	(self loadNewPlugin: 'FilePlugin') ifNotNil:
		[:filePlugin| filePlugin close]
]

{ #category : #'simulation only' }
CogVMSimulator >> cogit [
	^cogit
]

{ #category : #'process primitive support' }
CogVMSimulator >> commenceCogCompiledCodeCompaction [
	self halt.
	^super commenceCogCompiledCodeCompaction
]

{ #category : #initialization }
CogVMSimulator >> convertToArray [
	"This won't work for the Cog VM because the processor simulators need raw bytes for the memory."
	
	self shouldNotImplement
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

	class == objectMemory nilObject ifTrue: [self halt].

	^super createActualMessageTo: class
]

{ #category : #'debug support' }
CogVMSimulator >> debugStackPointersFor: aMethod [
	^CArrayAccessor on:
		(((NewspeakVM
			ifTrue: [NewspeakStackDepthFinder]
			ifFalse: [StackDepthFinder]) on: (VMCompiledMethodProxy new
									for: aMethod
									coInterpreter: self
									objectMemory: objectMemory))
			stackPointers)
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

	self perform: (selectorArray at: (anInteger + 1)).
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> displayLocation [

	^ Display extent - displayForm extent - (10@10)
]

{ #category : #'process primitive support' }
CogVMSimulator >> doSignalExternalSemaphores: minTableSize [
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
CogVMSimulator >> doesNotUnderstand: aMessage [
	"If this is a doit and the objectMemory understands, pass it on."
	(thisContext findContextSuchThat: [:ctxt| ctxt selector == #evaluate:in:to:notifying:ifFail:logged:]) ifNotNil:
		[(objectMemory class whichClassIncludesSelector: aMessage selector) ifNotNil:
			[:implementingClass|
			(implementingClass inheritsFrom: Object) ifTrue: "i.e. VMClass and below"
				[Transcript nextPutAll: 'warning: redirecting ', aMessage selector, ' in ', thisContext sender printString, ' to objectMemory'; cr; flush.
				 aMessage lookupClass: nil.
				^aMessage sentTo: objectMemory]].
		(cogit class whichClassIncludesSelector: aMessage selector) ifNotNil:
			[:implementingClass|
			(implementingClass inheritsFrom: Object) ifTrue: "i.e. VMClass and below"
				[Transcript nextPutAll: 'warning: redirecting ', aMessage selector, ' in ', thisContext sender printString, ' to cogit'; cr; flush.
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
CogVMSimulator >> ensureMethodIsCogged: methodObj [
	"Uncomment this to compact frequently and hence test if clients are ready for the shock."
	"[self commenceCogCompiledCodeCompaction]
		on: Halt
		do: [:ex| ex resume: nil]."
	^super ensureMethodIsCogged: methodObj
]

{ #category : #initialization }
CogVMSimulator >> ensureMultiThreadingOverridesAreUpToDate [
	"Make sure the CoInterpreterMT switch methods are implemented.  These methods select
	 between CoInterpreterMT's implementation or CoInterpreter's implementation depending
	 on cogThreadManager being non-nil or nil respectively.  i.e. they allow us to use this one
	 simulator class to simulate for both CoInterpreterMT and CoInterpreter."
	| thisClass me mtInterpreterClass |
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
							notifying: nil
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
CogVMSimulator >> externalInstVar: offset ofContext: aOnceMarriedContext [

	"offset = InstructionPointerIndex ifTrue:
		[Transcript nextPutAll: '==================='; cr.
		  self printContext: 16r1715630.
		 self printCallStackOf: aOnceMarriedContext currentFP: framePointer.
		 Transcript nextPutAll: '==================='; cr.
		 self halt]."

	| result |
	"self shortPrintFrameAndCallers: framePointer.
	Transcript print: byteCount; tab; print: thisContext; cr.
	self print: offset; cr.
	self printContext: aOnceMarriedContext.
	(self confirm: 'continue?') ifFalse: [self halt]."
	result := super externalInstVar: offset ofContext: aOnceMarriedContext.
	"offset = StackPointerIndex ifTrue:
		[Transcript nextPutAll: '^stackp ', (self integerValueOf: result) printString; tab.
		 self shortPrintContext: aOnceMarriedContext.
		 (#(24205456 24205732) includes: aOnceMarriedContext) ifTrue:
		 	[(self checkIsStillMarriedContext: aOnceMarriedContext currentFP: framePointer)
				ifTrue: [self printFrame: (self frameOfMarriedContext: aOnceMarriedContext) WithSP: (self frameOfMarriedContext: aOnceMarriedContext) - 48]
				ifFalse: [self printContext: aOnceMarriedContext]]]."
	^result
]

{ #category : #'frame access' }
CogVMSimulator >> externalInstVar: index ofContext: maybeMarriedContext put: anOop [
	"self shortPrintFrameAndCallers: framePointer.
	Transcript print: byteCount; tab; print: thisContext; cr.
	self print: index; cr.
	self printContext: maybeMarriedContext.
	self shortPrintOop: anOop.
	(self confirm: 'continue?') ifFalse: [self halt]."
	^super externalInstVar: index ofContext: maybeMarriedContext put: anOop
]

{ #category : #'interpreter shell' }
CogVMSimulator >> fetchByte [
	^objectMemory byteAt: (localIP := localIP + 1)
]

{ #category : #'interpreter access' }
CogVMSimulator >> fetchPointer: fieldIndex ofObject: oop [
	"index by word size, and return a pointer as long as the word size"
	self assert: oop >= objectMemory startOfMemory.
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
	mappedPluginEntries := OrderedCollection new.
	super flushExternalPrimitives.
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
	self assert: theFP + (self frameStackedReceiverOffset: theFP) + (2 * BytesPerWord) = thePage baseAddress.
	self assert: (stackPages longAt: thePage baseAddress - BytesPerWord) = (self frameContext: theFP).
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
	displayForm == nil ifTrue: [^ self].
	primFailCodeValue := primFailCode.
	self initPrimCall.
	self displayBitsOf: (objectMemory splObj: TheDisplay) Left: 0 Top: 0 Right: displayForm width Bottom: displayForm height.
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

{ #category : #initialization }
CogVMSimulator >> getLongFromFile: aStream swap: swapFlag [
	^swapFlag 
		ifTrue: [objectMemory byteSwapped: (self nextLongFrom: aStream)]
		ifFalse: [self nextLongFrom: aStream]
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
CogVMSimulator >> heapMapAtWord: address [
	^objectMemory heapMap heapMapAtWord: address asUnsignedInteger
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
		 self halt].
	byteCount \\ 1000 = 0 ifTrue:
		[self doOrDefer: [self changed: #byteCountText; changed: #composeAll].
		 self forceInterruptCheck.
		 byteCount \\ 10000 = 0 ifTrue: [self fullDisplayUpdate]]
]

{ #category : #'test support' }
CogVMSimulator >> initStackPagesForTests [
	numStackPages := 8.
	stackPages := self stackPagesClass new.
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

	objectMemory ifNil:
		[objectMemory := self class objectMemoryClass simulatorClass new].
	cogit ifNil:
		[cogit := self class cogitClass new setInterpreter: self].
	objectMemory coInterpreter: self cogit: cogit.

	cogit numRegArgs > 0 ifTrue:
		[debugStackDepthDictionary := Dictionary new].

	cogThreadManager ifNotNil:
		[super initialize].

	"Note: we must initialize ConstMinusOne & HasBeenReturnedFromMCPC differently
	 for simulation, due to the fact that the simulator works only with +ve 32-bit values"
	ConstMinusOne := objectMemory integerObjectOf: -1.
	HasBeenReturnedFromMCPC := objectMemory integerObjectOf: -1.
	cogMethodZone := cogit methodZone. "Because Slang can't remove intermediate implicit receivers (cogit methodZone foo doesn't reduce to foo())"
	enableCog := true.

	methodCache := Array new: MethodCacheSize.
	atCache := Array new: AtCacheTotalSize.
	self flushMethodCache.
	self flushAtCache.
	cogCompiledCodeCompactionCalledFor := false.
	gcSemaphoreIndex := 0.
	externalSemaphoreSignalRequests := externalSemaphoreSignalResponses := #().
	externalPrimitiveTable := CArrayAccessor on: (Array new: MaxExternalPrimitiveTableSize).
	externalPrimitiveTableFirstFreeIndex := 0.
	primitiveTable := self class primitiveTable copy.
	pluginList := {'' -> self }.
	mappedPluginEntries := OrderedCollection new.
	desiredNumStackPages := desiredEdenBytes := desiredCogCodeSize := 0.
	"This is initialized on loading the image, but convenient for testing stack page values..."
	numStackPages := self defaultNumStackPages. 
	startMicroseconds := Time totalSeconds * 1000000.
	maxLiteralCountForCompile := MaxLiteralCountForCompile.
	minBackwardJumpCountForCompile := MinBackwardJumpCountForCompile.
	flagInterpretedMethods := false.

	"initialize InterpreterSimulator variables used for debugging"
	byteCount := lastPollCount := sendCount := 0.
	quitBlock := [^ self].
	traceOn := true.
	printSends := printFrameAtEachStep := printBytecodeAtEachStep := false.
	myBitBlt := BitBltSimulator new setInterpreter: self.
	transcript := Transcript.
	displayForm := 'Display has not yet been installed' asDisplayText form.
	suppressHeartbeatFlag := deferSmash := deferredSmash := false.
	systemAttributes := Dictionary new.
	primTraceLog := CArrayAccessor on: (Array new: 256 withAll: 0).
	primTraceLogIndex := 0.
	traceLog := CArrayAccessor on: (Array new: TraceBufferSize withAll: 0).
	traceLogIndex := 0.
	traceSources := TraceSources.
	statCodeCompactionCount := 0.
	statCodeCompactionUsecs := 0.
	extSemTabSize := 256
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> initializeInterpreter: bytesToShift [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #initializeInterpreter:
		withArguments: {bytesToShift}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
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
CogVMSimulator >> instVar: offset ofContext: aOnceMarriedContext [

	"offset = InstructionPointerIndex ifTrue:
		[Transcript nextPutAll: '==================='; cr.
		  self printContext: 16r1715630.
		 self printCallStackOf: aOnceMarriedContext currentFP: framePointer.
		 Transcript nextPutAll: '==================='; cr.
		 self halt]."

	| result |
	"self shortPrintFrameAndCallers: localFP.
	Transcript print: byteCount; tab; print: thisContext; cr.
	self print: offset; cr.
	self printContext: aOnceMarriedContext.
	(self confirm: 'continue?') ifFalse: [self halt]."
	result := super instVar: offset ofContext: aOnceMarriedContext.
	"offset = StackPointerIndex ifTrue:
		[Transcript nextPutAll: '^stackp ', (self integerValueOf: result) printString; tab.
		 self shortPrintContext: aOnceMarriedContext.
		 (#(24205456 24205732) includes: aOnceMarriedContext) ifTrue:
		 	[(self checkIsStillMarriedContext: aOnceMarriedContext currentFP: localFP)
				ifTrue: [self printFrame: (self frameOfMarriedContext: aOnceMarriedContext) WithSP: (self frameOfMarriedContext: aOnceMarriedContext) - 48]
				ifFalse: [self printContext: aOnceMarriedContext]]]."
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
CogVMSimulator >> internalFindNewMethod [
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
	^super internalFindNewMethod
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
	self fetchNextBytecode.
	self initExtensions.
	[true] whileTrue:
		[self assertValidExecutionPointers.
		 atEachStepBlock value. "N.B. may be nil"
		 self dispatchOn: currentBytecode in: BytecodeTable.
		 self incrementByteCount].
	localIP := localIP - 1.  "undo the pre-increment of IP before returning"
	self externalizeIPandSP.
	^nil

]

{ #category : #'interpreter shell' }
CogVMSimulator >> invalidCompactClassError: name [
	self error: 'Class ', name, ' does not have the required compact class index'
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

{ #category : #'other primitives' }
CogVMSimulator >> ioForceDisplayUpdate [
	"no-op"
]

{ #category : #'process primitive support' }
CogVMSimulator >> ioGetMaxExtSemTableSize [
	^extSemTabSize
]

{ #category : #'I/O primitives' }
CogVMSimulator >> ioGetNextEvent: evtBuf [

	self primitiveFail.

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
CogVMSimulator >> ioLoadExternalFunction: functionName OfLength: functionLength FromModule: moduleName OfLength: moduleLength [
	"Load and return the requested function from a module"
	| pluginString functionString |
	pluginString := String new: moduleLength.
	1 to: moduleLength do:[:i| pluginString byteAt: i put: (objectMemory byteAt: moduleName+i-1)].
	functionString := String new: functionLength.
	1 to: functionLength do:[:i| functionString byteAt: i put: (objectMemory byteAt: functionName+i-1)].
	^self ioLoadFunction: functionString From: pluginString
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
				(pluginString isEmpty ifTrue:['vm'] ifFalse:[pluginString]).
	functionString = breakSelector ifTrue: [self halt: breakSelector].
	plugin := pluginList 
				detect:[:any| any key = pluginString asString]
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
			[^index]].
	(plugin respondsTo: fnSymbol) ifFalse:
		[firstTime ifTrue: [transcript cr; show: 'Failed ... primitive not in plugin'].
		 ^0].
	mappedPluginEntries addLast: (Array
									with: plugin
									with: fnSymbol
									with: [plugin perform: fnSymbol. self]).
	"Transcript show: ' ... okay'."
	^ mappedPluginEntries size
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> ioLocalSecondsOffset [
	^DateAndTime localOffset asSeconds
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
	Display reverse: (0@0 extent: 16@16).
	instructionPointer >= objectMemory startOfMemory ifFalse:
		[byteCount := byteCount + microseconds - 1.
		 self incrementByteCount].
	Sensor peekEvent ifNotNil:
		[self forceInterruptCheck].
	Processor activeProcess == Project uiProcess ifTrue:
		[World doOneCycle].
	microseconds >= 1000
		ifTrue: [self isThreadedVM ifTrue:
					[self forceInterruptCheckFromHeartbeat].
				(Delay forMilliseconds: microseconds + 999 // 1000) wait]
		ifFalse: [Processor yield]
]

{ #category : #'I/O primitives' }
CogVMSimulator >> ioScreenDepth [
	^DisplayScreen actualScreenDepth.
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> ioScreenSize [
	"Return the screen extent packed into 32 bits."

	^ (displayForm width << 16) + displayForm height
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> ioSeconds [
	"Return the value of the second clock."

	^ Time primSecondsClock
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> ioSetHeartbeatMilliseconds: ignored [
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

{ #category : #'process primitive support' }
CogVMSimulator >> ioSynchronousCheckForEvents [
	"Hook allowing the platform to do anything it needs to do synchronously."
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> ioUTCMicroseconds [
	"Return the value of the microsecond clock."
	"NOT.  Actually, we want something a lot slower and, for exact debugging,
	something more repeatable than real time.  Dan had an idea: use the byteCount..."

	^byteCount + startMicroseconds
	
"At 20k bytecodes per second, this gives us aobut 200 ticks per second, or about 1/5 of what you'd expect for the real time clock.  This should still service events at one or two per second"
]

{ #category : #'I/O primitives support' }
CogVMSimulator >> ioUTCMicrosecondsNow [
	^self ioUTCMicroseconds
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
	^address between: heapBase - self rumpCStackSize and: heapBase - BytesPerWord
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
	| plugin plugins simulatorClasses |
	transcript cr; show: 'Looking for module ', pluginString.
	"but *why*??"
	(#('FloatArrayPlugin' 'Matrix2x3Plugin') includes: pluginString) ifTrue:
		[transcript show: ' ... defeated'. ^nil].
	pluginString isEmpty
		ifTrue:
			[plugin := self]
		ifFalse:
			[plugins := InterpreterPlugin allSubclasses select: [:psc| psc moduleName asString = pluginString asString].
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
					[transcript show: ' ... initialiser failed'. ^nil]]]. "module initialiser failed"
	pluginList := pluginList copyWith: (pluginString asString -> plugin).
	transcript show: ' ... loaded'.
	^pluginList last
]

{ #category : #testing }
CogVMSimulator >> logOfBytesVerify: nBytes fromFileNamed: fileName fromStart: loggingStart [
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
CogVMSimulator >> logOfBytesWrite: nBytes toFileNamed: fileName fromStart: loggingStart [
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
CogVMSimulator >> logOfSendsVerify: nSends fromFileNamed: fileName fromStart: loggingStart [
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
CogVMSimulator >> logOfSendsWrite: nSends toFileNamed: fileName fromStart: loggingStart [
	"Write a log file for testing a flaky interpreter on the same image"
	"self logOfSendsWrite: 10000 toFileNamed: 'clone32Messages.log' fromStart: 2500"
	
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
	printSends ifTrue:
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

{ #category : #'frame access' }
CogVMSimulator >> makeBaseFrameFor: aContext [ "<Integer>"
	"aContext =  26431360 ifTrue: [self halt]."
	^super makeBaseFrameFor: aContext
]

{ #category : #'file primitives' }
CogVMSimulator >> makeDirEntryName: entryName size: entryNameSize
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
	uniqueIndices isNil ifTrue:
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
	| asp bcpc cogHomeMethod cogBlockMethod csp debugStackPointers |
	debugStackDepthDictionary ifNil: [^self].
	(self isMachineCodeFrame: framePointer) ifFalse: [^self].
	cogBlockMethod := self mframeCogMethod: framePointer.
	cogHomeMethod := self asCogHomeMethod: cogBlockMethod.
	debugStackPointers := debugStackDepthDictionary
								at: cogHomeMethod methodObject
								ifAbsentPut: [self debugStackPointersFor: cogHomeMethod methodObject].
	bcpc := cogit
				bytecodePCFor: mcpc
				startBcpc: (cogHomeMethod = cogBlockMethod
								ifTrue: [self startPCOfMethod: cogHomeMethod methodObject]
								ifFalse: [self startPCOfClosure: (self pushedReceiverOrClosureOfFrame: framePointer)])
				in: cogBlockMethod.
	self assert: bcpc ~= 0.
	asp := self stackPointerIndexForFrame: framePointer WithSP: sp + BytesPerWord.
	csp := debugStackPointers at: bcpc.
	"Compensate lazily for absent receiver sends."
	(NewspeakVM
	 and: [asp - delta = csp
	 and: [cogit isAbsentReceiverSendAt: mcpc in: cogHomeMethod]]) ifTrue:
		[csp := debugStackPointers at: bcpc put: csp + 1].
	self assert: asp - delta + 1 = csp
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
	^MethodCacheSize * BytesPerWord
]

{ #category : #'simulation only' }
CogVMSimulator >> methodForContext: aContextOop [
	self assert: (objectMemory isContext: aContextOop).
	^objectMemory fetchPointer: MethodIndex ofObject: aContextOop
]

{ #category : #initialization }
CogVMSimulator >> moveMethodCacheToMemoryAt: address [
	| oldMethodCache |
	oldMethodCache := methodCache.
	self flag: 'broken for 64-bit VM because Bitmap access unit is 32-bits'.
	"In the VM the methodCache is written as a normal array with 1-relative addressing.
	 In C this works by allocating an extra element in the methodCache array (see
	 class-side declareCVarsIn:).  In simulation simply position the start of the methodCache
	 one word lower, achieving the same effect.  -1 because CArrayAccessor is 0-relative
	 and adds 1 on accesses itself."
	methodCache := CMethodCacheAccessor new
						memory: objectMemory memory
						offset: address / BytesPerWord
						array: oldMethodCache
						functionPointerIndex: MethodCachePrimFunction
						entrySize: MethodCacheEntrySize.
	1 to: MethodCacheSize do:
		[:i|
		self assert: (methodCache at: i) = 0].
	methodCache at: 1 put: 16rC4EC4.
	self assert: (self longAt: address) = 16rC4EC4.
	1 to: MethodCacheSize do:
		[:i|
		methodCache at: i put: (oldMethodCache at: i)]
]

{ #category : #initialization }
CogVMSimulator >> movePrimTraceLogToMemoryAt: address [
	| oldTraceLog |
	oldTraceLog := primTraceLog.
	self flag: 'broken for 64-bit VM because Bitmap access unit is 32-bits'.
	primTraceLog := CObjectAccessor new
						memory: objectMemory memory
						offset: address / BytesPerWord.
	0 to: PrimTraceLogSize - 1 do:
		[:i|
		self assert: (primTraceLog at: i) = 0].
	primTraceLog at: 0 put: 16rC4EC4.
	self assert: (self longAt: address) = 16rC4EC4.
	0 to: PrimTraceLogSize - 1 do:
		[:i|
		primTraceLog at: i put: (oldTraceLog at: i)]
]

{ #category : #'debug support' }
CogVMSimulator >> nameOfClass: classOop [
	(objectMemory sizeBitsOf: classOop) = metaclassSizeBits ifTrue:
		[^(self nameOfClass:
				(objectMemory fetchPointer: thisClassIndex ofObject: classOop)) , ' class'].
	^self stringOf: (objectMemory fetchPointer: classNameIndex ofObject: classOop)
]

{ #category : #initialization }
CogVMSimulator >> nextLongFrom: aStream [
	"Read a 32-bit quantity from the given (binary) stream."
	^self subclassResponsibility
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

{ #category : #testing }
CogVMSimulator >> objectBefore: addr [
	| prev |
	objectMemory allObjectsDo:
		[:oop|
		"look here if debugging prev obj overlapping this one"
		oop >= addr ifTrue: [^prev].
		prev := oop].
	^0
]

{ #category : #UI }
CogVMSimulator >> openAsMorph [
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
CogVMSimulator >> openAsMorphNoTranscript [
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

{ #category : #initialization }
CogVMSimulator >> openOn: fileName [
	"(InterpreterSimulator new openOn: 'clonex.image') test"

	self openOn: fileName extraMemory: 2500000.
]

{ #category : #initialization }
CogVMSimulator >> openOn: fileName extraMemory: extraBytes [
	"CogVMSimulator new openOn: 'clone.im' extraMemory: 100000"

	| f version headerSize count heapSize oldBaseAddr bytesToShift swapBytes hdrNumStackPages
	 hdrEdenBytes hdrCogCodeSize stackZoneSize methodCacheSize headerFlags primTraceLogSize firstSegSize hdrMaxExtSemTabSize |
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
	heapSize := self getLongFromFile: f swap: swapBytes.  "length of heap in file"
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
	stackZoneSize := self computeStackZoneSize.
	"This slot holds the size of the native method zone in 1k units. (pad to word boundary)."
	hdrCogCodeSize := (self getShortFromFile: f swap: swapBytes) * 1024.
	cogCodeSize := desiredCogCodeSize ~= 0
						ifTrue: [desiredCogCodeSize]
						ifFalse:
							[hdrCogCodeSize = 0
									ifTrue: [self defaultCogCodeSize]
									ifFalse: [hdrCogCodeSize]].
	desiredCogCodeSize := hdrCogCodeSize.
	self assert: f position = 40.
	hdrEdenBytes	:= self getLongFromFile: f swap: swapBytes.
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
	self assert: f position = 48.
	firstSegSize := self getLongFromFile: f swap: swapBytes.
	objectMemory firstSegmentSize: firstSegSize.
	"For Open PICs to be able to probe the method cache during
	 simulation the methodCache must be relocated to memory."
	methodCacheSize := methodCache size * BytesPerWord.
	primTraceLogSize := primTraceLog size * BytesPerWord.
	"allocate interpreter memory. This list is in address order, low to high.
	 In the actual VM the stack zone exists on the C stack."
	heapBase := cogCodeSize
				+ stackZoneSize
				+ methodCacheSize
				+ primTraceLogSize
				+ self rumpCStackSize.
	objectMemory
		setHeapBase: heapBase
		memoryLimit:  heapBase
						+ heapSize
						+ objectMemory newSpaceBytes
						+ self interpreterAllocationReserveBytes
						+ extraBytes
		endOfMemory: heapBase + heapSize.

	objectMemory initialize.
	self assert: cogCodeSize \\ 4 = 0.
	self assert: objectMemory memoryLimit \\ 4 = 0.
	self assert: self rumpCStackSize \\ 4 = 0.
	"read in the image in bulk, then swap the bytes if necessary"
	f position: headerSize.
	objectMemory memory: ((cogit processor endianness == #little
					ifTrue: [LittleEndianBitmap]
					ifFalse: [Bitmap]) new: objectMemory memoryLimit // 4).
	count := objectMemory readHeapFromImageFile: f dataBytes: heapSize.
	count ~= heapSize ifTrue: [self halt].
	]
		ensure: [f close].
	self moveMethodCacheToMemoryAt: cogCodeSize + stackZoneSize.
	self movePrimTraceLogToMemoryAt: cogCodeSize + stackZoneSize + methodCacheSize.

	self ensureImageFormatIsUpToDate: swapBytes.

	bytesToShift := objectMemory memoryBaseForImageRead - oldBaseAddr.  "adjust pointers for zero base address"
	Utilities
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

{ #category : #'simulation only' }
CogVMSimulator >> penultimateLiteralOf: aMethodOop [
	self assert: (objectMemory isOopCompiledMethod: aMethodOop).
	^self literal: (self literalCountOf: aMethodOop) - 2 ofMethod: aMethodOop
]

{ #category : #'plugin support' }
CogVMSimulator >> pluginEntryFor: mapIndex [
	^mappedPluginEntries at: (mapIndex > 1000
								ifTrue: [externalPrimitiveTable at: mapIndex - 1001]
								ifFalse: [mapIndex])
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
CogVMSimulator >> primBitmapcompresstoByteArray [
	^ self primitiveFail
]

{ #category : #'other primitives' }
CogVMSimulator >> primBitmapdecompressfromByteArrayat [
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
	^PrimTraceLogSize * BytesPerWord
]

{ #category : #'I/O primitives' }
CogVMSimulator >> primitiveBeDisplay [
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

{ #category : #'I/O primitives' }
CogVMSimulator >> primitiveDeferDisplayUpdates [
	| oldDeferDisplayUpdates |
	oldDeferDisplayUpdates := deferDisplayUpdates.
	super primitiveDeferDisplayUpdates.
	oldDeferDisplayUpdates ~= deferDisplayUpdates ifTrue:
		[self fullDisplayUpdate]
]

{ #category : #'file primitives' }
CogVMSimulator >> primitiveDirectoryEntry [
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
CogVMSimulator >> primitiveDirectoryLookup [
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
CogVMSimulator >> primitiveDoPrimitiveWithArgs [
	| primIndex |
	primIndex := objectMemory integerValueOf: (self stackValue: 1).
	NewspeakVM ifFalse:
		[transcript nextPutAll: 'DO PRIMITIVE: '; print: (self functionPointerFor: primIndex inClass: nil); cr; flush].
	primIndex = 76 ifTrue:
		[self halt].
	^super primitiveDoPrimitiveWithArgs
]

{ #category : #'debugging traps' }
CogVMSimulator >> primitiveExecuteMethod [
	self halt: thisContext selector.
	^super primitiveExecuteMethod
]

{ #category : #'control primitives' }
CogVMSimulator >> primitiveExecuteMethodArgsArray [
	self halt: thisContext selector.
	^super primitiveExecuteMethodArgsArray
]

{ #category : #'other primitives' }
CogVMSimulator >> primitiveGetAttribute [
	"Fetch the system attribute with the given integer ID. The result is a string, which will be empty if the attribute is not defined."

	| index s attribute |
	index := self stackIntegerValue: 0.
	self successful ifTrue: [
		attribute := systemAttributes at: index ifAbsent: [Smalltalk getSystemAttribute: index].
		attribute ifNil: [ ^self primitiveFail ].
		s := objectMemory instantiateClass: (objectMemory splObj: ClassByteString) indexableSize: attribute size.
		1 to: attribute size do: [ :i |
			objectMemory storeByte: i-1 ofObject: s withValue: (attribute at: i) asciiValue].
		self pop: 2.  "rcvr, attr"
		self push: s]
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

{ #category : #'I/O primitives' }
CogVMSimulator >> primitiveMousePoint [

	| relPt |
	self pop: 1.
	displayForm == nil
		ifTrue: [self push: (self makePointwithxValue: 99 yValue: 66)]
		ifFalse: [relPt := Sensor cursorPoint - self displayLocation.
				self push: (self makePointwithxValue: relPt x yValue: relPt y)]
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
	| selector |
	selector := self stackValue: argumentCount - 1.
	self sendBreakpoint: selector receiver: (self stackValue: argumentCount).
	(self filterPerformOf: selector to: (self stackValue: argumentCount)) ifTrue:
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

{ #category : #'I/O primitives' }
CogVMSimulator >> primitiveScreenSize [
	| size |
	size := self desiredDisplayExtent min: 800@640.
	self pop: 1 thenPush: (self makePointwithxValue: size x yValue: size y)
]

{ #category : #'system control primitives' }
CogVMSimulator >> primitiveSignalAtMilliseconds [
	super primitiveSignalAtMilliseconds.
	self successful ifTrue:
		[Transcript
			cr; nextPutAll: thisContext selector;
			nextPutAll: ' now '; nextPutAll: self ioUTCMicroseconds hex;
			nextPutAll: ' wakeup '; nextPutAll: nextWakeupUsecs hex;
			nextPutAll: ' wakeup - now '; print: self ioUTCMicroseconds - nextWakeupUsecs; flush]
]

{ #category : #'debugging traps' }
CogVMSimulator >> primitiveStoreStackp [
	"self printContext: (self stackValue: 1).
	self halt."
	"(self stackValue: 1) = 16r1934F80 ifTrue: [self halt]."
	super primitiveStoreStackp
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> primitiveVMCurrentThreadId [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #primitiveVMCurrentThreadId
		withArguments: {}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'debug printing' }
CogVMSimulator >> print: it [

	traceOn ifTrue:
		[it isString ifTrue: [transcript nextPutAll: it] ifFalse: [it printOn: transcript]]
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
		 (it between: objectMemory startOfMemory and: objectMemory endOfMemory) ifFalse:
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
		[transcript nextPutAll: (anInteger storeStringBase: 16)]
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
	heapBase - BytesPerWord
		to: address
		by: BytesPerWord negated
		do:
			[:addr|
			self printHex: addr; tab; printHex: (self longAt: addr); cr]
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
	(oop bitAnd: (BytesPerWord - 1)) ~= 0 ifTrue:
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

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> recordThreadSwitchTo: ownerIndex source: sourceCode [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #recordThreadSwitchTo:source:
		withArguments: {ownerIndex. sourceCode}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> recordTrace: classOrInteger thing: selector source: source [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #recordTrace:thing:source:
		withArguments: {classOrInteger. selector. source}
		inSuperclass: (cogThreadManager ifNil: [CoInterpreterPrimitives] ifNotNil: [CoInterpreterMT])
]

{ #category : #'multi-threading simulation switch' }
CogVMSimulator >> removeLink: aLink fromList: aLinkedList [
	"This method includes or excludes CoInterpreterMT methods as required.
	 Auto-generated by CogVMSimulator>>ensureMultiThreadingOverridesAreUpToDate"

	^self perform: #removeLink:fromList:
		withArguments: {aLink. aLinkedList}
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
	Utilities
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
			put: (self cCoerce: localPrimAddress to: #long)]
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
				  ^self].
	self initStackPages.
	self loadInitialContext.
	self initialEnterSmalltalkExecutive
]

{ #category : #testing }
CogVMSimulator >> runWithBreakCount: theBreakCount [
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
	self initialEnterSmalltalkExecutive
]

{ #category : #'I/O primitives' }
CogVMSimulator >> savedWindowSize [
	^savedWindowSize ifNil: [0]
]

{ #category : #'debugging traps' }
CogVMSimulator >> sendBreak: selectorString point: selectorLength receiver: receiverOrNil [
	"self shortPrintFrameAndCallers: localFP"
	| i |
	breakSelectorLength = selectorLength ifTrue:
		[i := breakSelectorLength.
		 [i > 0] whileTrue:
			[(objectMemory byteAt: selectorString + i - 1) = (breakSelector at: i) asInteger
				ifTrue: [(i := i - 1) = 0 ifTrue:
							[self changed: #byteCountText.
							 self halt: 'Send of '
									, breakSelector,
									(receiverOrNil
										ifNotNil: [' to ', (self shortPrint: receiverOrNil)]
										ifNil: [''])]]
				ifFalse: [i := 0]]]
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

{ #category : #'debug support' }
CogVMSimulator >> shortPrint: oop [
	| name classOop |
	(objectMemory isImmediate: oop) ifTrue:
		[(objectMemory isImmediateCharacter: oop) ifTrue:
			[^ '=$' , (objectMemory characterValueOf: oop) printString , 
			' (' , (String with: (Character value: (objectMemory characterValueOf: oop))) , ')'].
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
	(objectMemory sizeBitsOf: classOop) = metaclassSizeBits ifTrue:
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
CogVMSimulator >> shortPrintContext: aContext [
	transcript ensureCr.
	^super shortPrintContext: aContext
]

{ #category : #'debug printing' }
CogVMSimulator >> shortPrintFrame: theFP [
	self transcript ensureCr.
	^super shortPrintFrame: theFP
]

{ #category : #'I/O primitives' }
CogVMSimulator >> showDisplayBits: destBits w: w h: h d: d left: left right: right top: top bottom: bottom [
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
CogVMSimulator >> signalSemaphoreWithIndex: index [
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
	"Intercept accesses to the stackLimit from machine code to
	 increment byteCount so that ioMSecs/ioMicroseconds does
	 somethng reasonable when we're purely in machine code."
	(byteCount := byteCount + 1) - lastPollCount >= 100 ifTrue:
		[lastPollCount := byteCount.
		 byteCount \\ 500 = 0 ifTrue:
			[self fullDisplayUpdate].
		 (Sensor peekEvent notNil
		  or: [nextProfileTick > 0
			  and: [nextProfileTick <= self ioUTCMicroseconds]]) ifTrue:
			[suppressHeartbeatFlag "gets set by selector breakpoints"
				ifTrue: [self forceInterruptCheck]
				ifFalse: [self forceInterruptCheckFromHeartbeat]]].
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

{ #category : #'debug support' }
CogVMSimulator >> stackPointer [
	^stackPointer
]

{ #category : #'stack pages' }
CogVMSimulator >> stackZoneBase [
	"In the simulator the stack zone starts immediately after the code zone."
	^cogCodeSize
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

{ #category : #'debug support' }
CogVMSimulator >> stringOf: oop [
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
	quitBlock := [^self].
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
	^super updateStateOfSpouseContextForFrame: theFP WithSP: theSP
]

{ #category : #UI }
CogVMSimulator >> utilitiesMenu: aMenuMorph [
	aMenuMorph
		add: 'toggle transcript' action: #toggleTranscript;
		addLine;
		add: 'print ext head frame' action: #printExternalHeadFrame;
		add: 'print int head frame' action: #printHeadFrame;
		add: 'print mc/cog frame' action: [self printFrame: cogit processor fp WithSP: cogit processor sp];
		add: 'short print ext frame & callers' action: [self shortPrintFrameAndCallers: framePointer];
		add: 'short print int frame & callers' action: [self shortPrintFrameAndCallers: localFP];
		add: 'short print mc/cog frame & callers' action: [self shortPrintFrameAndCallers: cogit processor fp];
		add: 'long print ext frame & callers' action: [self printFrameAndCallers: framePointer SP: stackPointer];
		add: 'long print int frame & callers' action: [self printFrameAndCallers: localFP SP: localSP];
		add: 'long print mc/cog frame & callers' action: [self printFrameAndCallers: cogit processor fp SP: cogit processor sp];
		add: 'print frame...' action: [(self promptHex: 'print frame') ifNotNil: [:fp| self printFrame: fp]];
		add: 'print call stack' action: #printCallStack;
		add: 'print stack call stack' action: #printStackCallStack;
		add: 'print call stack of...' action: [(self promptHex: 'context or process oop') ifNotNil: [:obj| self printCallStackOf: obj]];
		add: 'print all stacks' action: #printAllStacks;
		add: 'write back local ptrs' action: [stackPointer := localSP. framePointer := localFP. instructionPointer := localIP.
											self writeBackHeadFramePointers];
		add: 'write back mc ptrs' action: [stackPointer := cogit processor sp. framePointer := cogit processor fp. instructionPointer := cogit processor eip.
											self writeBackHeadFramePointers];
		addLine;
		add: 'print registers' action: [cogit processor printRegistersOn: transcript];
		add: 'disassemble method/trampoline...' action: [(self promptHex: 'pc') ifNotNil: [:pc| cogit disassembleCodeAt: pc]];
		add: 'disassemble method/trampoline at pc' action: [cogit disassembleCodeAt: cogit processor pc];
		add: 'disassemble ext head frame method' action: [cogit disassembleMethod: (self frameMethod: framePointer)];
		add: 'print oop...' action: [(self promptHex: 'print oop') ifNotNil: [:oop| self printOop: oop]];
		add: 'long print oop...' action: [(self promptHex: 'print oop') ifNotNil: [:oop| self longPrintOop: oop]];
		addLine;
		add: 'inspect object memory' target: objectMemory action: #inspect;
		add: 'inspect cointerpreter' action: #inspect;
		add: 'inspect cogit' target: cogit action: #inspect;
		add: 'inspect method zone' target: cogit methodZone action: #inspect.
	self isThreadedVM ifTrue:
		[aMenuMorph add: 'inspect thread manager' target: self threadManager action: #inspect].
	aMenuMorph
		addLine;
		add: 'print cog methods' target: cogMethodZone action: #printCogMethods;
		add: 'print trampoline table' target: cogit action: #printTrampolineTable;
		add: 'print prim trace log' action: #dumpPrimTraceLog;
		add: 'report recent instructions' target: cogit action: #reportLastNInstructions;
		add: 'set break pc...' action: [(self promptHex: 'break pc') ifNotNil: [:bpc| cogit breakPC: bpc]];
		add: (cogit singleStep
				ifTrue: ['no single step']
				ifFalse: ['single step'])
			action: [cogit singleStep: cogit singleStep not];
		add: (cogit printRegisters
				ifTrue: ['no print registers each instruction']
				ifFalse: ['print registers each instruction'])
			action: [cogit printRegisters: cogit printRegisters not];
		add: (cogit printInstructions
				ifTrue: ['no print instructions each instruction']
				ifFalse: ['print instructions each instruction'])
			action: [cogit printInstructions: cogit printInstructions not];
		addLine;
		add: 'set break count...' action: [|s| s := UIManager default request: 'break count (dec)'.
											s notEmpty ifTrue: [breakCount := Integer readFrom: s readStream]];
		add: 'set break selector...' action: [|s| s := UIManager default request: 'break selector'.
											s notEmpty ifTrue: [self setBreakSelector: s]];
		add: 'set break block...' action: [|s| s := UIManager default request: 'break selector'.
											s notEmpty ifTrue: [self setBreakBlockFromString: s]];
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
CogVMSimulator >> validOop: oop [
	" Return true if oop appears to be valid "
	(oop bitAnd: 1) = 1 ifTrue: [^ true].  "Integer"
	(oop bitAnd: 3) = 0 ifFalse: [^ false].  "Uneven address"
	oop >= objectMemory endOfMemory ifTrue: [^ false].  "Out of range"
	"could test if within the first large freeblock"
	(self longAt: oop) = 4 ifTrue: [^ false].
	(objectMemory headerType: oop) = 2 ifTrue: [^ false].	"Free object"
	^ true
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
	pathName := Smalltalk vmPath.
	stringOop := stringBase - BaseHeaderSize. "Due to C call in Interp"
	1 to: stringSize do:
		[:i | objectMemory storeByte: i-1 ofObject: stringOop
			withValue: (pathName at: i) asciiValue].

]

{ #category : #'file primitives' }
CogVMSimulator >> vmPathSize [
	^ Smalltalk vmPath size
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
	self writeProtectMemory.
	stackPages writeProtectMemory.
	^aBlock ensure:
		[self writeEnableMemory.
		 stackPages writeEnableMemory]
]

{ #category : #'frame access' }
CogVMSimulator >> withSmallIntegerTags: aValueOrSurrogate [
	"The simulator works with strictly positive bit patterns"
	| value |
	value := aValueOrSurrogate asInteger.
	^value < 0
		ifTrue: [(value bitAnd: 16rFFFFFFFF) + 1]
		ifFalse: [value + 1]
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

{ #category : #'image save/restore' }
CogVMSimulator >> writeImageFileIO [
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
			extraVMMemory
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
