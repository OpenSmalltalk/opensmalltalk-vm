StackToRegisterMappingCogit subclass: #ProfilingCogit
	instanceVariableNames: 'numCounters counters counterIndex oilTripLog ceOilDeoptTrampoline oilSelectors oilExtraSelectors'
	classVariableNames: 'OilCounterBytes OilInitialCounterValue OilTripBackJump OilTripBlockEntry OilTripBlockEntryMagic'
	poolDictionaries: 'VMSqueakClassIndices'
	category: 'VMMaker-JIT-Oil'!
!ProfilingCogit commentStamp: 'cb 10/25/2026 00:30' prior: 0!
A ProfilingCogit is the profiling tier of Oil, the optimizing JIT for the OpenSmalltalk VM.  It generates the same code as StackToRegisterMappingCogit plus lightweight trip counters that detect hot loops, and offers the inline cache queries the Oil optimizer needs when inlining.

Trip counters are placed only at two kinds of site: loop back jumps (genJumpBackTo:) and frameful full block entries (compileFullBlockMethodFrameBuild:).  Straight-line code, conditional branches and legacy vanilla blocks carry no profiling overhead, and methods without loops or blocks get no counters at all.  Each site has a 32-bit counter, initialized to OilInitialCounterValue (65535), held in a pinned object on the Spur heap allocated with objectRepresentation allocateCounters: and referenced from the counters field of the method's header (a SistaCogMethod).  At each site the counter is decremented; when it reaches zero, instead of a separate trampoline call, the site invokes ceCheckForInterruptTrampoline (back jump) or methodAbortTrampoline (block entry) with SendNumArgsReg set to indicate a trip.  The trampoline distinguishes counter trips from interrupts/stack overflows, calls CoInterpreter>>ceOilTrip:, which inspects the tripping frame to identify the method to optimize (walking a block's outer contexts up to its home context), and returns directly to machine code.  Nothing on the trip path allocates, collects garbage or changes the stack.

Instance Variables
	ceOilDeoptTrampoline:	<Integer>
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


!ProfilingCogit methodsFor: 'bytecode generator support' stamp: 'cb 10/25/2026 00:30'!
genJumpBackTo: targetBytecodePC
	"Count loop iterations at the back jump, sharing ceCheckForInterruptTrampoline."
	| counterAddress jumpTripped interruptCall |
	<var: #jumpTripped type: #'AbstractInstruction *'>
	<var: #interruptCall type: #'AbstractInstruction *'>
	self ssFlushTo: simStackPtr.
	(counters ~= 0 and: [counterIndex < numCounters])
		ifTrue:
			[counterAddress := counters + (OilCounterBytes * counterIndex).
			 counterIndex := counterIndex + 1.
			 self MoveA32: counterAddress R: TempReg.
			 self SubCq: 1 R: TempReg.
			 self MoveR: TempReg A32: counterAddress.
			 jumpTripped := self JumpZero: 0]
		ifFalse:
			[jumpTripped := nil].

	self MoveAw: coInterpreter stackLimitAddress R: TempReg.
	self CmpR: TempReg R: SPReg.
	self JumpAboveOrEqual: (self fixupAt: targetBytecodePC).

	self MoveCq: 0 R: SendNumArgsReg. "0 = normal interrupt check"
	interruptCall := self Label.
	self CallRT: ceCheckForInterruptTrampoline.
	self annotateBytecode: self Label.
	self Jump: (self fixupAt: targetBytecodePC).

	jumpTripped ifNotNil:
		[jumpTripped jmpTarget: self Label.
		 self MoveCq: 1 R: SendNumArgsReg. "1 = back jump counter trip"
		 self Jump: interruptCall].
	^0! !


!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/24/2026 10:00'!
compileCogFullBlockMethod: numCopied
	<option: #SistaV1BytecodeSet>
	counters := 0.
	^super compileCogFullBlockMethod: numCopied! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/24/2026 10:00'!
compileCogMethod: selector
	counters := 0.
	^super compileCogMethod: selector! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/25/2026 00:30'!
compileFullBlockMethodFrameBuild: numCopied
	"Count frameful full block activations once the frame is complete,
	 sharing the method abort / stack overflow trampoline."
	<option: #SistaV1BytecodeSet>
	| jumpTripped jumpOk counterAddress |
	<var: #jumpTripped type: #'AbstractInstruction *'>
	<var: #jumpOk type: #'AbstractInstruction *'>
	needsFrame ifFalse: [^self].
	super compileFullBlockMethodFrameBuild: numCopied.
	(counters ~= 0 and: [counterIndex < numCounters])
		ifTrue:
			[counterAddress := counters + (OilCounterBytes * counterIndex).
			 counterIndex := counterIndex + 1.
			 self MoveA32: counterAddress R: TempReg.
			 self SubCq: 1 R: TempReg.
			 self MoveR: TempReg A32: counterAddress.
			 jumpTripped := self JumpZero: 0]
		ifFalse:
			[jumpTripped := nil].

	jumpTripped ifNotNil:
		[jumpOk := self Jump: 0.
		 jumpTripped jmpTarget: self Label.
		 self MoveCq: 0 R: ReceiverResultReg. "0 = stack overflow / trip abort"
		 self MoveCq: OilTripBlockEntryMagic R: SendNumArgsReg. "OilTripBlockEntryMagic = block entry counter trip"
		 self Call: (self methodAbortTrampolineFor: methodOrBlockNumArgs).
		 jumpOk jmpTarget: self Label]! !

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

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/25/2026 00:30'!
scanMethod
	"Override to compute the number of trip counters: one per back jump, plus one for
	 the entry of a frameful full block method."
	| numBlocks |
	numBlocks := super scanMethod.
	numBlocks >= 0 ifTrue:
		[numCounters := self numberOfBackwardBranches.
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


!ProfilingCogit methodsFor: 'initialization' stamp: 'cb 10/25/2026 00:30'!
genCheckForInterruptsTrampoline
	| jumpInterrupt |
	<var: #jumpInterrupt type: #'AbstractInstruction *'>
	self zeroOpcodeIndex.
	self CmpCq: 0 R: SendNumArgsReg.
	jumpInterrupt := self JumpZero: 0.

	"SendNumArgsReg ~= 0 (1): Oil loop backjump counter trip"
	self genSmalltalkToCStackSwitch: true.
	self compileCallFor: #ceOilTrip:
		numArgs: 1
		arg: 0 "OilTripBackJump"
		arg: nil
		arg: nil
		arg: nil
		resultReg: NoReg
		regsToSave: self emptyRegisterMask.
	backEnd genLoadStackPointers.
	self MoveMw: FoxMFReceiver r: FPReg R: ReceiverResultReg.
	self genTrampolineReturn: true.

	jumpInterrupt jmpTarget: self Label.
	backEnd hasLinkRegister ifFalse:
		[self PopR: TempReg.
		 self MoveR: TempReg Aw: coInterpreter instructionPointerAddress].
	^ceCheckForInterruptTrampoline := self genTrampolineFor: #ceCheckForInterrupt
										called: 'ceCheckForInterruptTrampoline'
										numArgs: 0
										arg: nil
										arg: nil
										arg: nil
										arg: nil
										regsToSave: self emptyRegisterMask
										pushLinkReg: false
										resultReg: NoReg
										appendOpcodes: true! !

!ProfilingCogit methodsFor: 'initialization' stamp: 'cb 10/25/2026 00:30'!
genMethodAbortTrampolineFor: numArgs
	| jumpSICMiss jumpTrip |
	<var: #jumpSICMiss type: #'AbstractInstruction *'>
	<var: #jumpTrip type: #'AbstractInstruction *'>
	self zeroOpcodeIndex.
	self CmpCq: 0 R: ReceiverResultReg.
	jumpSICMiss := self JumpNonZero: 0.

	"ReceiverResultReg = 0: abort/stack overflow path.
	 Check if this is an Oil block entry counter trip (SendNumArgsReg = OilTripBlockEntryMagic)."
	self CmpCq: OilTripBlockEntryMagic R: SendNumArgsReg.
	jumpTrip := self JumpZero: 0.

	"Normal stack overflow: call ceStackOverflow:"
	backEnd hasLinkRegister ifTrue:
		[self MoveR: LinkReg Mw: 0 r: SPReg].
	self compileTrampolineFor: #ceStackOverflow:
		numArgs: 1
		arg: SendNumArgsReg
		arg: nil
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: false
		resultReg: NoReg.

	"Oil block entry trip path:"
	jumpTrip jmpTarget: self Label.
	self genSmalltalkToCStackSwitch: true.
	self compileCallFor: #ceOilTrip:
		numArgs: 1
		arg: 1 "OilTripBlockEntry"
		arg: nil
		arg: nil
		arg: nil
		resultReg: NoReg
		regsToSave: self emptyRegisterMask.
	backEnd genLoadStackPointers.
	self MoveMw: FoxMFReceiver r: FPReg R: ReceiverResultReg.
	self genTrampolineReturn: true.

	jumpSICMiss jmpTarget: self Label.
	backEnd genPushRegisterArgsForAbortMissNumArgs: numArgs.
	^self genTrampolineFor: #ceSICMiss:
		called: (self trampolineName: 'ceMethodAbort' numRegArgs: numArgs)
		numArgs: 1
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: false
		resultReg: NoReg
		appendOpcodes: true! !

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
	OilTripBlockEntry := 1.
	OilTripBlockEntryMagic := 16r54524950! !


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


!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-profiling' stamp: 'cb 10/25/2026 00:30'!
ceOilTrip: kind
	"Called from ceCheckForInterruptTrampoline (back jump, kind 0) or methodAbortTrampoline
	 (block entry, kind 1) when a ProfilingCogit trip counter reaches zero.  framePointer is the
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

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-profiling' stamp: 'cb 10/24/2026 10:00'!
oilClosureArgumentOf: theFP numArgs: numArgs
	"Answer the first argument of the frame that is a closure, or nil if none."
	<var: #theFP type: #'char *'>
	<essential: #ProfilingCogit>
	| arg |
	0 to: numArgs - 1 do:
		[:argIndex|
		arg := self temporary: argIndex in: theFP.
		(self oilIsClosure: arg) ifTrue:
			[^arg]].
	^objectMemory nilObject! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-profiling' stamp: 'cb 10/24/2026 10:00'!
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

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-profiling' stamp: 'cb 10/24/2026 10:00'!
oilIsClosure: oop
	<inline: true>
	<essential: #ProfilingCogit>
	^(objectMemory isNonImmediate: oop)
	  and: [(objectMemory classIndexOf: oop) = ClassFullBlockClosureCompactIndex
			or: [(objectMemory classIndexOf: oop) = ClassBlockClosureCompactIndex]]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-profiling' stamp: 'cb 10/24/2026 10:00'!
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

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-profiling' stamp: 'cb 10/24/2026 10:00'!
oilTripRecordSize
	<inline: true>
	<essential: #ProfilingCogit>
	^6! !


!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-profiling primitives' stamp: 'cb 10/24/2026 10:00'!
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


!VMMaker class methodsFor: '*VMMaker-JIT-Oil-configurations' stamp: 'cb 10/24/2026 10:00'!
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
