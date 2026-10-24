StackToRegisterMappingCogit subclass: #ProfilingCogit
	instanceVariableNames: 'numCounters counters counterIndex ceOilTripTrampoline oilTripLog ceOilBailoutTrampoline oilSelectors oilExtraSelectors'
	classVariableNames: 'OilCounterBytes OilInitialCounterValue OilTripBackJump OilTripBlockEntry'
	poolDictionaries: 'VMSqueakClassIndices'
	category: 'Cogit-Oil'!
!ProfilingCogit commentStamp: 'cb 10/24/2026 10:00' prior: 0!
A ProfilingCogit is the profiling tier of Oil, the optimizing JIT for the OpenSmalltalk VM.  It generates the same code as StackToRegisterMappingCogit plus lightweight trip counters that detect hot loops, and offers the inline cache queries the Oil optimizer needs when inlining.

Trip counters are placed only at two kinds of site: loop back jumps (genJumpBackTo:) and frameful block entries (compileBlockFrameBuild: and compileFullBlockMethodFrameBuild:).  Straight-line code and conditional branches carry no profiling overhead, and methods without loops or blocks get no counters at all.  Each site has a 32-bit counter, initialized to OilInitialCounterValue (65535), held in a pinned object on the Spur heap allocated with objectRepresentation allocateCounters: and referenced from the counters field of the method's header (a SistaCogMethod).  The site code is
	counter := counter - 1. counter = 0 ifTrue: [ceOilTripTrampoline]
so a site trips exactly once, when its counter reaches zero; afterwards the counter wraps to 16rFFFFFFFF and effectively never trips again.  The trampoline calls CoInterpreter>>ceOilTrip:, which inspects the tripping frame to identify the method to optimize (walking a block's outer contexts up to its home context).  Nothing on the trip path allocates, collects garbage or changes the stack.

Instance Variables
	ceOilBailoutTrampoline:	<Integer>
	ceOilTripTrampoline:	<Integer>
	counterIndex:			<Integer>
	counters:				<Integer>
	numCounters:			<Integer>
	oilExtraSelectors:		<Integer oop>
	oilSelectors:			<Integer oop>
	oilTripLog:				<Integer oop>
!

!ProfilingCogit methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:00'!
estimateOfAbstractOpcodesPerBytecodes
	"Due to the trip counter code at back jumps and block entries the estimate is higher."
	<inline: true>
	^11! !

!ProfilingCogit methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:00'!
getOilTripLog
	"Answer the trip log Array, nil, or 0 if no log has ever been set."
	<api>
	^oilTripLog! !

!ProfilingCogit methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:00'!
oilTripLogAddress
	"Answer the address of the oilTripLog variable, for registering it as a GC root."
	<api>
	<returnTypeC: #'sqInt *'>
	^self addressOf: oilTripLog put: [:value| oilTripLog := value]! !

!ProfilingCogit methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:00'!
setOilTripLog: anArrayOrNil
	<api>
	oilTripLog := anArrayOrNil! !


!ProfilingCogit methodsFor: 'bytecode generator support' stamp: 'cb 10/24/2026 10:00'!
genJumpBackTo: targetBytecodePC
	"Count loop iterations at the back jump, before the usual interrupt check."
	self ssFlushTo: simStackPtr.
	self genOilTripCounter: OilTripBackJump.
	^super genJumpBackTo: targetBytecodePC! !

!ProfilingCogit methodsFor: 'bytecode generator support' stamp: 'cb 10/24/2026 10:00'!
genOilTripCounter: kind
	"Generate the code for a trip counter site of the given kind:
		counter := counter - 1. counter = 0 ifTrue: [ceOilTripTrampoline(kind)]
	 The counter is decremented in TempReg and written back before the test; neither
	 the store nor the address materialization changes the flags on x64 or ARMv8.
	 The kind is passed in SendNumArgsReg, which is dead at both kinds of site.
	 The trampoline preserves ReceiverResultReg, so no register state is lost.
	 The call is not annotated as a bytecode pc since ceOilTrip: does not need to map
	 the frame's pc (it neither allocates, collects garbage nor changes the stack)."
	| counterAddress notTripped |
	<var: #notTripped type: #'AbstractInstruction *'>
	(counters = 0
	 or: [counterIndex >= numCounters]) ifTrue:
		[^0].
	counterAddress := counters + (OilCounterBytes * counterIndex).
	counterIndex := counterIndex + 1.
	self MoveA32: counterAddress R: TempReg.
	self SubCq: 1 R: TempReg.
	self MoveR: TempReg A32: counterAddress.
	notTripped := self JumpNonZero: 0.
	self MoveCq: kind R: SendNumArgsReg.
	self CallRT: ceOilTripTrampoline.
	notTripped jmpTarget: self Label.
	^0! !


!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/24/2026 10:00'!
compileBlockFrameBuild: blockStart
	"Count frameful (vanilla) block activations once the frame is complete."
	<var: #blockStart type: #'BlockStart *'>
	super compileBlockFrameBuild: blockStart.
	self genOilTripCounter: OilTripBlockEntry! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/24/2026 10:00'!
compileCogFullBlockMethod: numCopied
	<option: #SistaV1BytecodeSet>
	counters := 0.
	^super compileCogFullBlockMethod: numCopied! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/24/2026 10:00'!
compileCogMethod: selector
	counters := 0.
	^super compileCogMethod: selector! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/24/2026 10:00'!
compileFullBlockMethodFrameBuild: numCopied
	"Count frameful full block activations once the frame is complete."
	<option: #SistaV1BytecodeSet>
	super compileFullBlockMethodFrameBuild: numCopied.
	needsFrame ifTrue:
		[self genOilTripCounter: OilTripBlockEntry]! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/24/2026 10:00'!
maybeAllocAndInitCounters
	<inline: true>
	self assert: counters = 0.
	counterIndex := 0.
	numCounters = 0 ifTrue:
		[^true].
	counters := objectRepresentation allocateCounters: numCounters.
	^counters ~= 0! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/24/2026 10:00'!
maybeCounterIndex
	<inline: true>
	^counterIndex! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/24/2026 10:00'!
maybeFreeCounters
	<inline: true>
	self freeOilCounters: counters! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/24/2026 10:00'!
maybeInitNumCounters
	<inline: true>
	numCounters := 0! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/24/2026 10:00'!
maybeSetCounterIndex: value
	<inline: true>
	counterIndex := value! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/24/2026 10:00'!
numberOfBackwardBranches
	"Answer the number of backward branches between initialPC and endPC, which
	 includes those of any embedded (vanilla) blocks.  Mirrors the scan in scanMethod."
	| pc nExts descriptor count |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	pc := initialPC.
	count := nExts := extA := numExtB := extB := 0.
	[pc <= endPC] whileTrue:
		[descriptor := self loadBytesAndGetDescriptor: pc.
		 descriptor isExtension ifTrue:
			[self perform: descriptor generator].
		 (descriptor isBranch
		  and: [self isBackwardBranch: descriptor at: pc exts: nExts in: methodObj]) ifTrue:
			[count := count + 1].
		 pc := pc + descriptor numBytes.
		 nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [extA := numExtB := extB := 0]].
	^count! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/24/2026 10:00'!
scanMethod
	"Override to compute the number of trip counters: one per back jump and one per
	 block (an upper bound on the number of frameful vanilla blocks), plus one for
	 the entry of a frameful full block method."
	| numBlocks |
	numBlocks := super scanMethod.
	numBlocks >= 0 ifTrue:
		[numCounters := self numberOfBackwardBranches + numBlocks.
		 (inBlock = InFullBlock and: [needsFrame]) ifTrue:
			[numCounters := numCounters + 1]].
	^numBlocks! !


!ProfilingCogit methodsFor: 'generate machine code' stamp: 'cb 10/24/2026 10:00'!
fillInCPICHeader: pic numArgs: numArgs numCases: numCases hasMNUCase: hasMNUCase selector: selector
	pic counters: 0.
	super fillInCPICHeader: pic numArgs: numArgs numCases: numCases hasMNUCase: hasMNUCase selector: selector! !

!ProfilingCogit methodsFor: 'generate machine code' stamp: 'cb 10/24/2026 10:00'!
fillInCounters: nCounters atStartAddress: startAddress
	startAddress
		to: startAddress + (nCounters - 1 * OilCounterBytes)
		by: OilCounterBytes
		do: [:address|
			objectMemory long32At: address put: OilInitialCounterValue]! !

!ProfilingCogit methodsFor: 'generate machine code' stamp: 'cb 10/24/2026 10:00'!
fillInMethodHeader: method size: size selector: selector
	super fillInMethodHeader: method size: size selector: selector.
	counters ~= 0 ifTrue:
		[self fillInCounters: numCounters atStartAddress: counters].
	method counters: counters! !

!ProfilingCogit methodsFor: 'generate machine code' stamp: 'cb 10/24/2026 10:00'!
fillInOPICHeader: pic numArgs: numArgs selector: selector
	pic counters: 0.
	super fillInOPICHeader: pic numArgs: numArgs selector: selector! !


!ProfilingCogit methodsFor: 'in-line cacheing' stamp: 'cb 10/24/2026 10:00'!
oilFindSendAt: descriptor Annotation: isBackwardBranchAndAnnotation Mcpc: mcpc Bcpc: bcpc Method: targetBcpc
	"mapFor:bcpc:performUntil:arg: function answering the mcpc of the ordinary send at targetBcpc."
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #mcpc type: #'char *'>
	<var: #targetBcpc type: #'void *'>
	descriptor ifNil:
		[^0].
	(bcpc = (self cCoerceSimple: targetBcpc to: #sqInt)
	 and: [isBackwardBranchAndAnnotation >> 1 = IsSendCall]) ifFalse:
		[^0].
	^mcpc asUnsignedInteger! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ProfilingCogit class
	instanceVariableNames: ''!

!ProfilingCogit class methodsFor: 'class initialization' stamp: 'cb 10/24/2026 10:00'!
initializeWithOptions: optionsDictionary
	super initializeWithOptions: optionsDictionary.
	"Each counter is a 32-bit word, two to a 64-bit slot (see allocateCounters:)."
	OilCounterBytes := 4.
	"Trip after 2^16 - 1 executions of a site."
	OilInitialCounterValue := (1 << 16) - 1.
	"The kinds of trip site, passed to CoInterpreter>>ceOilTrip:."
	OilTripBackJump := 0.
	OilTripBlockEntry := 1! !


!ProfilingCogit class methodsFor: 'translation' stamp: 'cb 10/24/2026 10:00'!
additionalHeadersDo: aBinaryBlock
	"Evaluate aBinaryBlock with the names and contents of
	 any additional header files that need to be generated.
	 ProfilingCogit uses the counters field of SistaCogMethod."
	aBinaryBlock
		value: 'cogmethod.h'
		value: SistaCogMethod cogMethodHeader! !

!ProfilingCogit class methodsFor: 'translation' stamp: 'cb 10/24/2026 10:00'!
declareCVarsIn: aCodeGen
	aCodeGen var: 'counters' type: #usqInt! !


!CoInterpreter methodsFor: '*Cogit-Oil-profiling' stamp: 'cb 10/24/2026 10:00'!
ceOilTrip: kind
	"Called from ceOilTripTrampoline when a ProfilingCogit trip counter reaches zero, at a
	 loop back jump (kind 0) or a frameful block entry (kind 1).  framePointer is the
	 tripping machine code frame and the top of stack is the return address into its code.
	 Identify the method that should be the root of an Oil compilation:
	 - in a block activation, the home method of the block, found by walking the closure's
	   outer contexts up to its home context, i.e. the outer method framing the loop;
	 - at a back jump in a method one of whose arguments is a closure (e.g. the to:do: loop
	   in OrderedCollection>>do:), the home method of that closure, since compiling the
	   iterator alone is useless without knowing the block it evaluates;
	 - otherwise the method itself.
	 This must not allocate, collect garbage, or change the stack, since it returns directly to machine code."
	<api>
	<essential: #ProfilingCogit>
	| theFP numArgs trippedMethod closure homeContext homeMethod |
	<var: #theFP type: #'char *'>
	theFP := framePointer.
	self assert: (self isMachineCodeFrame: theFP).
	trippedMethod := self frameMethodObject: theFP.
	numArgs := self frameNumArgs: theFP.
	closure := (self frameIsBlockActivation: theFP)
				ifTrue: [self frameStackedReceiver: theFP numArgs: numArgs]
				ifFalse: [self oilClosureArgumentOf: theFP numArgs: numArgs].
	homeContext := objectMemory nilObject.
	homeMethod := trippedMethod.
	closure ~= objectMemory nilObject ifTrue:
		[homeContext := self oilHomeContextOfClosure: closure.
		 homeContext ~= objectMemory nilObject
			ifTrue: [homeMethod := objectMemory followMaybeForwarded: (objectMemory fetchPointer: MethodIndex ofObject: homeContext)]
			ifFalse:
				[(objectMemory classIndexOf: closure) = ClassFullBlockClosureCompactIndex ifTrue: "a clean block; use the static outer code chain"
					[homeMethod := self homeMethodOf: (objectMemory followMaybeForwarded: (objectMemory fetchPointer: FullClosureCompiledBlockIndex ofObject: closure))]]].
	self oilRecordTrip: kind method: trippedMethod home: homeMethod context: homeContext.
	^0! !

!CoInterpreter methodsFor: '*Cogit-Oil-profiling' stamp: 'cb 10/24/2026 10:00'!
oilClosureArgumentOf: theFP numArgs: numArgs
	"Answer the first argument of the frame that is a closure, or nil if none."
	<var: #theFP type: #'char *'>
	<essential: #ProfilingCogit>
	| arg |
	0 to: numArgs - 1 do:
		[:i|
		arg := self temporary: i in: theFP.
		(self oilIsClosure: arg) ifTrue:
			[^arg]].
	^objectMemory nilObject! !

!CoInterpreter methodsFor: '*Cogit-Oil-profiling' stamp: 'cb 10/24/2026 10:00'!
oilHomeContextOfClosure: closure
	"Answer the home context of closure, found by walking the chain of outer contexts
	 (through the closureOrNil of each block context) up to a method context, or nil if
	 the chain is broken, e.g. for a clean block with no outer context.  Married contexts
	 are fine since their method, closureOrNil and receiver fields are valid."
	<essential: #ProfilingCogit>
	| context outerClosure depth |
	context := objectMemory followMaybeForwarded: (objectMemory fetchPointer: ClosureOuterContextIndex ofObject: closure).
	depth := 0.
	[(objectMemory isNonImmediate: context)
	 and: [objectMemory isContextNonImm: context]] whileTrue:
		[outerClosure := objectMemory followMaybeForwarded: (objectMemory fetchPointer: ClosureIndex ofObject: context).
		 ((self oilIsClosure: outerClosure) not
		  or: [(depth := depth + 1) > 64]) ifTrue:
			[^context].
		 context := objectMemory followMaybeForwarded: (objectMemory fetchPointer: ClosureOuterContextIndex ofObject: outerClosure)].
	^objectMemory nilObject! !

!CoInterpreter methodsFor: '*Cogit-Oil-profiling' stamp: 'cb 10/24/2026 10:00'!
oilIsClosure: oop
	<inline: true>
	<essential: #ProfilingCogit>
	^(objectMemory isNonImmediate: oop)
	  and: [(objectMemory classIndexOf: oop) = ClassFullBlockClosureCompactIndex
			or: [(objectMemory classIndexOf: oop) = ClassBlockClosureCompactIndex]]! !

!CoInterpreter methodsFor: '*Cogit-Oil-profiling' stamp: 'cb 10/24/2026 10:00'!
oilRecordTrip: kind method: trippedMethod home: homeMethod context: homeContext
	"If the image has supplied a trip log (see primitiveOilTripLog) record the trip in it.
	 The log's first slot holds the number of trips recorded so far; the remaining slots
	 are a ring of records, each of oilTripRecordSize slots:
		kind (0 back jump, 1 block entry), tripped method (CompiledMethod or CompiledBlock),
		home method to optimize, home context or nil (slots 4 and 5 unused)."
	<essential: #ProfilingCogit>
	| log numRecords count base |
	log := cogit getOilTripLog.
	(log = 0
	 or: [log = objectMemory nilObject]) ifTrue:
		[^nil].
	(objectMemory isForwarded: log) ifTrue:
		[log := objectMemory followForwarded: log.
		 cogit setOilTripLog: log].
	(objectMemory isArrayNonImm: log) ifFalse:
		[^nil].
	numRecords := (objectMemory numSlotsOf: log) - 1 // self oilTripRecordSize.
	numRecords < 1 ifTrue:
		[^nil].
	count := objectMemory fetchPointer: 0 ofObject: log.
	count := (objectMemory isIntegerObject: count)
				ifTrue: [objectMemory integerValueOf: count]
				ifFalse: [0].
	base := count \\ numRecords * self oilTripRecordSize + 1.
	objectMemory
		storePointer: base ofObject: log withValue: (objectMemory integerObjectOf: kind);
		storePointer: base + 1 ofObject: log withValue: trippedMethod;
		storePointer: base + 2 ofObject: log withValue: homeMethod;
		storePointer: base + 3 ofObject: log withValue: homeContext;
		storePointer: 0 ofObject: log withValue: (objectMemory integerObjectOf: count + 1).
	^nil! !

!CoInterpreter methodsFor: '*Cogit-Oil-profiling' stamp: 'cb 10/24/2026 10:00'!
oilTripRecordSize
	<inline: true>
	<essential: #ProfilingCogit>
	^6! !


!CoInterpreterPrimitives methodsFor: '*Cogit-Oil-profiling primitives' stamp: 'cb 10/24/2026 10:00'!
primitiveOilTripLog
	"With no argument answer the trip log, or nil if none.  With one argument, an Array or nil,
	 make it the trip log, answering the previous one.  ceOilTrip: records each trip in the log;
	 see oilRecordTrip:method:home:context: for its format.  The log variable is
	 registered as an extra GC root the first time it is set."
	<export: true>
	<essential: #ProfilingCogit>
	| previous log |
	argumentCount > 1 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	previous := cogit getOilTripLog.
	argumentCount = 0 ifTrue:
		[^self pop: 1 thenPush: (previous = 0 ifTrue: [objectMemory nilObject] ifFalse: [previous])].
	log := self stackTop.
	(log = objectMemory nilObject
	 or: [(objectMemory isNonImmediate: log)
		and: [(objectMemory isArrayNonImm: log)
		and: [(objectMemory numSlotsOf: log) > self oilTripRecordSize]]]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	cogit setOilTripLog: log.
	previous = 0 ifTrue:
		[(objectMemory addGCRoot: cogit oilTripLogAddress) ifFalse:
			[cogit setOilTripLog: 0.
			 ^self primitiveFailFor: PrimErrNoMemory].
		 previous := objectMemory nilObject].
	self pop: 2 thenPush: previous! !


!VMMaker class methodsFor: '*Cogit-Oil-configurations' stamp: 'cb 10/24/2026 10:00'!
generateSqueakSpurCogOil64VM
	"The 64-bit Cog Spur VM with the ProfilingCogit, the profiling tier of the Oil optimizing JIT."
	^VMMaker
		generate: CoInterpreter
		and: ProfilingCogit
		with: #(ProfilingCogit true
				ObjectMemory Spur64BitCoMemoryManager
				MULTIPLEBYTECODESETS true
				bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid)
		to: (self srcDirectory fullNameFor: 'spur64.oil')
		platformDir: self sourceTree, '/platforms'
		including:#()! !
