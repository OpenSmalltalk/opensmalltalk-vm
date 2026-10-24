StackToRegisterMappingCogit subclass: #ProfilingCogit
	instanceVariableNames: 'numCounters counters counterIndex initialCounterValue ceOilTripTrampoline oilTripLog'
	classVariableNames: 'OilCounterBytes OilInitialCounterValue OilTripBackJump OilTripBlockEntry'
	poolDictionaries: 'VMSqueakClassIndices'
	category: 'VMMaker-JIT'!
!ProfilingCogit commentStamp: 'cb 10/24/2026 10:00' prior: 0!
A ProfilingCogit is the profiling tier of Oil, the optimizing JIT for the OpenSmalltalk VM.  It generates the same code as StackToRegisterMappingCogit plus lightweight trip counters that detect hot loops, and offers the inline cache queries the Oil optimizer needs when inlining.

Trip counters are placed only at two kinds of site: loop back jumps (genJumpBackTo:) and frameful block entries (compileBlockFrameBuild: and compileFullBlockMethodFrameBuild:).  Straight-line code and conditional branches carry no profiling overhead, and methods without loops or blocks get no counters at all.  Each site has a 32-bit counter, initialized to OilInitialCounterValue (65535), held in a pinned object on the Spur heap allocated with objectRepresentation allocateCounters: and referenced from the counters field of the method's header (a SistaCogMethod).  The site code is
	counter := counter - 1. counter = 0 ifTrue: [ceOilTripTrampoline]
so a site trips exactly once, when its counter reaches zero; afterwards the counter wraps to 16rFFFFFFFF and effectively never trips again.  The trampoline calls CoInterpreter>>ceOilTrip:, which inspects the tripping frame to identify the method to optimize (walking a block's outer contexts up to its home context) and samples a live element at the loop's current position.  Nothing on the trip path allocates, collects garbage or changes the stack.

Instance Variables
	ceOilTripTrampoline:	<Integer>
	counterIndex:			<Integer>
	counters:				<Integer>
	initialCounterValue:	<Integer>
	numCounters:			<Integer>
	oilTripLog:				<Integer oop>

ceOilTripTrampoline
	- the address of the trampoline called when a trip counter reaches zero

counterIndex
	- the index of the next counter to be assigned while compiling a method

counters
	- the address of the first counter of the method being compiled, or 0 if it has none

initialCounterValue
	- the value each counter starts from

numCounters
	- the number of counters allocated for the method being compiled (an upper bound on the number of sites)

oilTripLog
	- an Array supplied by the image through primitiveOilTripLog into which CoInterpreter>>ceOilTrip: records trips, or 0 if none has ever been supplied.  Registered as an extra GC root once set.
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


!ProfilingCogit methodsFor: 'compaction' stamp: 'cb 10/24/2026 10:00'!
maybeFreeCountersOf: aCogMethod
	"Free the pinned object holding the method's trip counters, if any."
	<var: #aCogMethod type: #'CogMethod *'>
	<inline: true>
	self freeOilCounters: aCogMethod counters! !


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
freeOilCounters: theCounters
	<var: #theCounters type: #usqInt>
	<inline: true>
	theCounters ~= 0 ifTrue:
		[objectMemory freeObject: theCounters - objectMemory baseHeaderSize]! !

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


!ProfilingCogit methodsFor: 'garbage collection & become' stamp: 'cb 10/24/2026 10:00'!
maybeMarkCountersIn: cogMethod
	"The trip counters are held in pinned objects on the heap which must be marked to
	 avoid them being collected."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	cogMethod counters ~= 0 ifTrue:
		[objectMemory markAndTrace: cogMethod counters - objectMemory baseHeaderSize]! !


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
			objectMemory long32At: address put: initialCounterValue]! !

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
linkedMonomorphicSendAt: bcpc in: cogMethod
	"Answer the return address (mcpc) of the ordinary send at the 0-relative bytecode pc
	 bcpc in cogMethod if that send is linked to a method (i.e. its inline cache is
	 monomorphic), or 0 if it is unlinked, linked to a PIC, or not found.  Only sends in
	 the method's own code are found, not those in embedded vanilla blocks."
	<var: #cogMethod type: #'CogMethod *'>
	<returnTypeC: #usqInt>
	| mcpc entryPoint targetMethod |
	<var: #targetMethod type: #'CogMethod *'>
	cogMethod stackCheckOffset = 0 ifTrue: "frameless methods contain no sends"
		[^0].
	mcpc := self
				mapFor: (self cCoerceSimple: cogMethod to: #'CogBlockMethod *')
				bcpc: (coInterpreter startPCOfMethodHeader: cogMethod methodHeader)
				performUntil: #oilFindSendAt:Annotation:Mcpc:Bcpc:Method:
				arg: (self cCoerceSimple: bcpc to: #'void *').
	mcpc = 0 ifTrue:
		[^0].
	entryPoint := backEnd callTargetFromReturnAddress: mcpc.
	entryPoint <= methodZoneBase ifTrue: "unlinked"
		[^0].
	self targetMethodAndSendTableFor: entryPoint
		annotation: IsSendCall
		into: [:target :sendTable| targetMethod := target].
	^targetMethod isCMMethodEtAl
		ifTrue: [mcpc]
		ifFalse: [0]! !

!ProfilingCogit methodsFor: 'in-line cacheing' stamp: 'cb 10/24/2026 10:00'!
monomorphicClassFor: bcpc in: cogMethod
	"Answer the receiver class cached in the monomorphic inline cache of the ordinary send at
	 the 0-relative bytecode pc bcpc in cogMethod, or nil if that send is not monomorphic."
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	| mcpc |
	mcpc := self linkedMonomorphicSendAt: bcpc in: cogMethod.
	mcpc = 0 ifTrue:
		[^objectMemory nilObject].
	^objectRepresentation classForInlineCacheTag: (backEnd inlineCacheTagAt: mcpc)! !

!ProfilingCogit methodsFor: 'in-line cacheing' stamp: 'cb 10/24/2026 10:00'!
monomorphicTargetFor: bcpc in: cogMethod
	"Answer the CogMethod the ordinary send at the 0-relative bytecode pc bcpc in cogMethod
	 is linked to if its inline cache is monomorphic, or nil if the send is unlinked or
	 linked to a closed or open PIC.  This is the query the Oil optimizer uses to decide
	 which sends to inline."
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	<returnTypeC: #'CogMethod *'>
	| mcpc entryPoint targetMethod |
	<var: #targetMethod type: #'CogMethod *'>
	mcpc := self linkedMonomorphicSendAt: bcpc in: cogMethod.
	mcpc = 0 ifTrue:
		[^nil].
	entryPoint := backEnd callTargetFromReturnAddress: mcpc.
	self targetMethodAndSendTableFor: entryPoint
		annotation: IsSendCall
		into: [:target :sendTable| targetMethod := target].
	^targetMethod! !

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


!ProfilingCogit methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:00'!
generateRunTimeTrampolines
	"Add the trampoline called when a trip counter reaches zero.  It passes the kind of
	 site (OilTripBackJump or OilTripBlockEntry) in SendNumArgsReg to ceOilTrip:, and
	 preserves ReceiverResultReg, which may hold self."
	super generateRunTimeTrampolines.
	ceOilTripTrampoline := self genTrampolineFor: #ceOilTrip:
								called: 'ceOilTripTrampoline'
								arg: SendNumArgsReg
								regsToSave: (self registerMaskFor: ReceiverResultReg)! !

!ProfilingCogit methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:00'!
initialize
	super initialize.
	oilTripLog := 0.
	cogMethodSurrogateClass := (objectMemory ifNil: [self class objectMemoryClass]) wordSize = 4
										ifTrue: [CogSistaMethodSurrogate32]
										ifFalse: [CogSistaMethodSurrogate64]! !

!ProfilingCogit methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:00'!
initializeCodeZoneFrom: startAddress upTo: endAddress
	initialCounterValue := OilInitialCounterValue.
	super initializeCodeZoneFrom: startAddress upTo: endAddress! !

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


!ProfilingCogit class methodsFor: 'trampoline support' stamp: 'cb 10/24/2026 10:00'!
numTrampolines
	^super numTrampolines + 1 "ceOilTripTrampoline"! !


!ProfilingCogit class methodsFor: 'translation' stamp: 'cb 10/24/2026 10:00'!
additionalHeadersDo: aBinaryBlock
	"Evaluate aBinaryBlock with the names and contents of
	 any additional header files that need to be generated.
	 ProfilingCogit uses the counters field of SistaCogMethod."
	aBinaryBlock
		value: 'cogmethod.h'
		value: SistaCogMethod cogMethodHeader! !

!ProfilingCogit class methodsFor: 'translation' stamp: 'cb 10/24/2026 10:00'!
ancilliaryClasses
	"Answer any extra classes to be included in the translation."
	^super ancilliaryClasses copyWith: SistaCogMethod! !

!ProfilingCogit class methodsFor: 'translation' stamp: 'cb 10/24/2026 10:00'!
declareCVarsIn: aCodeGen
	aCodeGen var: 'counters' type: #usqInt! !


!CoInterpreter methodsFor: 'oil profiling' stamp: 'cb 10/24/2026 10:00'!
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
	 Also sample a live element at the loop's current position.  This must not allocate,
	 collect garbage, or change the stack, since it returns directly to machine code."
	<api>
	<essential: #ProfilingCogit>
	| theFP numArgs trippedMethod closure homeContext homeMethod sample |
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
			ifTrue: [homeMethod := self oilFollowed: (objectMemory fetchPointer: MethodIndex ofObject: homeContext)]
			ifFalse:
				[(objectMemory classIndexOf: closure) = ClassFullBlockClosureCompactIndex ifTrue: "a clean block; use the static outer code chain"
					[homeMethod := self homeMethodOf: (self oilFollowed: (objectMemory fetchPointer: FullClosureCompiledBlockIndex ofObject: closure))]]].
	sample := self oilSampleAt: theFP numArgs: numArgs isBlock: (self frameIsBlockActivation: theFP).
	self oilRecordTrip: kind method: trippedMethod home: homeMethod context: homeContext sample: sample.
	^0! !

!CoInterpreter methodsFor: 'oil profiling' stamp: 'cb 10/24/2026 10:00'!
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

!CoInterpreter methodsFor: 'oil profiling' stamp: 'cb 10/24/2026 10:00'!
oilElementAt: index in: rcvr
	"Answer the non-nil element at the 1-relative index of rcvr if it is an Array, or else of
	 the first Array inst var of rcvr (e.g. the array of an OrderedCollection) in which index
	 is in bounds.  Answer nil if there is no such element."
	<essential: #ProfilingCogit>
	| ivar element |
	(index < 1
	 or: [objectMemory isImmediate: rcvr]) ifTrue:
		[^objectMemory nilObject].
	(objectMemory isArrayNonImm: rcvr) ifTrue:
		[^index <= (objectMemory numSlotsOf: rcvr)
			ifTrue: [self oilFollowed: (objectMemory fetchPointer: index - 1 ofObject: rcvr)]
			ifFalse: [objectMemory nilObject]].
	(objectMemory formatOf: rcvr) = objectMemory nonIndexablePointerFormat ifFalse:
		[^objectMemory nilObject].
	0 to: ((objectMemory numSlotsOf: rcvr) min: 32) - 1 do:
		[:i|
		ivar := self oilFollowed: (objectMemory fetchPointer: i ofObject: rcvr).
		((objectMemory isNonImmediate: ivar)
		 and: [(objectMemory isArrayNonImm: ivar)
		 and: [index <= (objectMemory numSlotsOf: ivar)]]) ifTrue:
			[element := self oilFollowed: (objectMemory fetchPointer: index - 1 ofObject: ivar).
			 element ~= objectMemory nilObject ifTrue:
				[^element]]].
	^objectMemory nilObject! !

!CoInterpreter methodsFor: 'oil profiling' stamp: 'cb 10/24/2026 10:00'!
oilFollowed: oop
	<inline: true>
	<essential: #ProfilingCogit>
	^((objectMemory isNonImmediate: oop)
	   and: [objectMemory isForwarded: oop])
		ifTrue: [objectMemory followForwarded: oop]
		ifFalse: [oop]! !

!CoInterpreter methodsFor: 'oil profiling' stamp: 'cb 10/24/2026 10:00'!
oilHomeContextOfClosure: closure
	"Answer the home context of closure, found by walking the chain of outer contexts
	 (through the closureOrNil of each block context) up to a method context, or nil if
	 the chain is broken, e.g. for a clean block with no outer context.  Married contexts
	 are fine since their method, closureOrNil and receiver fields are valid."
	<essential: #ProfilingCogit>
	| context outerClosure depth |
	context := self oilFollowed: (objectMemory fetchPointer: ClosureOuterContextIndex ofObject: closure).
	depth := 0.
	[(objectMemory isNonImmediate: context)
	 and: [objectMemory isContextNonImm: context]] whileTrue:
		[outerClosure := self oilFollowed: (objectMemory fetchPointer: ClosureIndex ofObject: context).
		 ((self oilIsClosure: outerClosure) not
		  or: [(depth := depth + 1) > 64]) ifTrue:
			[^context].
		 context := self oilFollowed: (objectMemory fetchPointer: ClosureOuterContextIndex ofObject: outerClosure)].
	^objectMemory nilObject! !

!CoInterpreter methodsFor: 'oil profiling' stamp: 'cb 10/24/2026 10:00'!
oilIsClosure: oop
	<inline: true>
	<essential: #ProfilingCogit>
	^(objectMemory isNonImmediate: oop)
	  and: [(objectMemory classIndexOf: oop) = ClassFullBlockClosureCompactIndex
			or: [(objectMemory classIndexOf: oop) = ClassBlockClosureCompactIndex]]! !

!CoInterpreter methodsFor: 'oil profiling' stamp: 'cb 10/24/2026 10:00'!
oilRecordTrip: kind method: trippedMethod home: homeMethod context: homeContext sample: sample
	"If the image has supplied a trip log (see primitiveOilTripLog) record the trip in it.
	 The log's first slot holds the number of trips recorded so far; the remaining slots
	 are a ring of records, each of oilTripRecordSize slots:
		kind (0 back jump, 1 block entry), tripped method (CompiledMethod or CompiledBlock),
		home method to optimize, home context or nil, sampled element, class of sample."
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
		storePointer: base + 4 ofObject: log withValue: sample;
		storePointer: base + 5 ofObject: log withValue: (objectMemory fetchClassOf: sample);
		storePointer: 0 ofObject: log withValue: (objectMemory integerObjectOf: count + 1).
	^nil! !

!CoInterpreter methodsFor: 'oil profiling' stamp: 'cb 10/24/2026 10:00'!
oilSampleAt: theFP numArgs: numArgs isBlock: isBlock
	"Sample a live element at the current position of the loop that tripped.
	 In a block with arguments that is the first argument, i.e. the element the
	 caller (e.g. do:) is iterating over.  Otherwise look for currentPosition, a
	 SmallInteger in the frame's temps or stack used as an index into the receiver
	 (array at: index), which, since the loop is running, designates a live element.
	 Answer nil if none can be found."
	<var: #theFP type: #'char *'>
	<essential: #ProfilingCogit>
	| rcvr slot value sample |
	<var: #slot type: #'char *'>
	(isBlock and: [numArgs > 0]) ifTrue:
		[^self temporary: 0 in: theFP].
	rcvr := self frameReceiver: theFP.
	slot := theFP + FoxMFReceiver - objectMemory wordSize.
	[slot > stackPointer] whileTrue: "stackPointer points at the return address into the method"
		[value := stackPages longAt: slot.
		 (objectMemory isIntegerObject: value) ifTrue:
			[sample := self oilElementAt: (objectMemory integerValueOf: value) in: rcvr.
			 sample ~= objectMemory nilObject ifTrue:
				[^sample]].
		 slot := slot - objectMemory wordSize].
	^objectMemory nilObject! !

!CoInterpreter methodsFor: 'oil profiling' stamp: 'cb 10/24/2026 10:00'!
oilTripRecordSize
	<inline: true>
	<essential: #ProfilingCogit>
	^6! !


!CoInterpreterPrimitives methodsFor: 'oil profiling primitives' stamp: 'cb 10/24/2026 10:00'!
primitiveOilMonomorphicTarget
	"Receiver: a CompiledMethod or CompiledBlock; argument: the 1-relative pc of a send in it.
	 If the method is jitted and the send is an ordinary send whose inline cache is linked
	 monomorphically answer { cached receiver class. target method }, otherwise answer nil."
	<export: true>
	<essential: #ProfilingCogit>
	| pc bcpc methodObj cogMethod targetMethod result |
	<var: #cogMethod type: #'CogMethod *'>
	<var: #targetMethod type: #'CogMethod *'>
	argumentCount ~= 1 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	pc := self stackTop.
	methodObj := self stackValue: 1.
	((objectMemory isIntegerObject: pc)
	 and: [(objectMemory isNonImmediate: methodObj)
	 and: [objectMemory isCompiledMethod: methodObj]]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	bcpc := (objectMemory integerValueOf: pc) - 1.
	result := objectMemory nilObject.
	(self methodHasCogMethod: methodObj) ifTrue:
		[cogMethod := self cogMethodOf: methodObj.
		 targetMethod := cogit monomorphicTargetFor: bcpc in: cogMethod.
		 targetMethod notNil ifTrue:
			[result := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 2.
			 result ifNil:
				[^self primitiveFailFor: PrimErrNoMemory].
			 "Allocation neither moves objects nor frees machine code, but query after it anyway."
			 targetMethod := cogit monomorphicTargetFor: bcpc in: cogMethod.
			 objectMemory
				storePointer: 0 ofObject: result withValue: (cogit monomorphicClassFor: bcpc in: cogMethod);
				storePointer: 1 ofObject: result withValue: targetMethod methodObject]].
	self pop: 2 thenPush: result! !

!CoInterpreterPrimitives methodsFor: 'oil profiling primitives' stamp: 'cb 10/24/2026 10:00'!
primitiveOilTripLog
	"With no argument answer the trip log, or nil if none.  With one argument, an Array or nil,
	 make it the trip log, answering the previous one.  ceOilTrip: records each trip in the log;
	 see oilRecordTrip:method:home:context:sample: for its format.  The log variable is
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


!VMMaker class methodsFor: 'configurations' stamp: 'cb 10/24/2026 10:00'!
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
