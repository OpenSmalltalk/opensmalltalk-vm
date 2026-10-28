StackToRegisterMappingCogit subclass: #ProfilingCogit
	instanceVariableNames: 'oilTripCounters oilNextCounterIndex ceOilTripTrampoline ceOilDeoptTrampoline oilColdSelectors oilExtraSelectors oilCompileMicroseconds oilNoAutoCompile oilDispatcherPrototype oilDispatcherFirstCaseOffset oilDispatcherCaseSize oilDispatcherEndOfCodeOffset oilDispatcherSize'
	classVariableNames: 'OilCounterBytes OilInitialCounterValue OilNumTripCounters OilTripBackJump OilTripBackOffCount OilTripRetryCount'
	poolDictionaries: 'VMSqueakClassIndices'
	category: 'VMMaker-JIT-Oil'!
!ProfilingCogit commentStamp: 'cb 10/27/2026 22:55' prior: 0!
A ProfilingCogit is the profiling tier of Oil, the optimizing JIT for the OpenSmalltalk VM.  It generates the same code as StackToRegisterMappingCogit plus lightweight trip counters that detect hot loops, and offers the inline cache queries the Oil optimizer needs when inlining.

Trip counters are placed only at loop back jumps (genJumpBackTo:).  Straight-line code, conditional branches and block entries carry no profiling overhead, and methods without loops get no counters at all (a hot block is found through the loop that evaluates it, see CoInterpreter>>ceOilTrip:).  Each site has a 32-bit counter, initialized to OilInitialCounterValue (8191), taken from a 4 KB ring buffer in the VM's static data (oilTripCounters, see oilAllocateTripCounter; once OilNumTripCounters sites have been compiled, sites share counters, which can only make a site trip early) and embedded in the machine code: no heap object.  The counters field of the header of a baseline method (a SistaCogMethod) is 0; that of an Oil method refers to its deoptimization metadata.  At each site the counter is decremented; when it reaches zero, the site invokes ceOilTripTrampoline with SendNumArgsReg set to the kind of site (OilTripBackJump, the only kind).  The dedicated trampoline preserves ReceiverResultReg, switches to the C stack and calls CoInterpreter>>ceOilTrip:, which inspects the tripping frame to identify the method to optimize (walking a block's outer contexts up to its home context), compiles it with Oil and installs the Oil code for its next activations (see CoInterpreter>>oilAutoCompile:receiver:), and returns directly to machine code.  Nothing on the trip path collects garbage or changes the stack: the running activations keep running the baseline code.  The site then restarts its counter from the count ceOilTrip: answers: OilInitialCounterValue while the home method may still get an Oil specialization for another receiver class (the baseline code stays behind the method's Dispatcher), OilTripRetryCount after a transient failure (a full code zone), and OilTripBackOffCount (about 2^30) when Oil cannot or need not compile it (disqualified, all specializations taken, a clean block...), so that such a loop does not keep calling ceOilTrip:.

Instance Variables
	ceOilDeoptTrampoline:	<Integer>
	ceOilTripTrampoline:	<Integer>
	oilNextCounterIndex:	<Integer>
	oilTripCounters:		<CArray of unsigned int>
	oilCompileMicroseconds:	<Integer>
	oilExtraSelectors:		<Integer oop>
	oilColdSelectors:		<Integer oop>
	oilNoAutoCompile:		<Boolean>
!

!ProfilingCogit methodsFor: 'accessing' stamp: 'cb 10/27/2026 22:55'!
estimateOfAbstractOpcodesPerBytecodes
	"Due to the trip counter code at back jumps the estimate is higher."
	<inline: true>
	^11! !

!ProfilingCogit methodsFor: 'accessing' stamp: 'cb 10/26/2026 22:20'!
oilAutoCompileEnabled
	"Does a trip compile the hot method with Oil (the default; see primitiveOilSetAutonomousCompilation)?"
	<api>
	^oilNoAutoCompile not! !

!ProfilingCogit methodsFor: 'accessing' stamp: 'cb 10/26/2026 22:20'!
oilSetAutoCompileEnabled: aBoolean
	"See primitiveOilSetAutonomousCompilation."
	<api>
	oilNoAutoCompile := aBoolean not! !

!ProfilingCogit methodsFor: 'bytecode generator support' stamp: 'cb 10/25/2026 01:50'!
genJumpBackTo: targetBytecodePC
	"Count loop iterations at the back jump, before the usual interrupt check."
	self ssFlushTo: simStackPtr.
	self genOilTripCounter: OilTripBackJump.
	^super genJumpBackTo: targetBytecodePC! !

!ProfilingCogit methodsFor: 'bytecode generator support' stamp: 'cb 10/28/2026 05:10'!
genOilTripCounter: kind
	"Generate the code for a trip counter site of the given kind:
		counter := counter - 1. counter = 0 ifTrue: [counter := ceOilTripTrampoline(kind)]
	 The counter is decremented in TempReg and written back before the test; neither
	 the store nor the address materialization changes the flags on x64 or ARMv8.
	 ceOilTrip: answers in TempReg the count to restart from (see the class comment), so that baseline code
	 retained behind a Dispatcher can trip again for other receiver classes, while a loop whose home method
	 Oil cannot compile backs off.
	 The kind is passed in SendNumArgsReg, which is dead at a back jump.
	 The trampoline preserves ReceiverResultReg, so no register state is lost.
	 The call is not annotated as a bytecode pc since ceOilTrip: does not need to map
	 the frame's pc (it neither allocates, collects garbage nor changes the stack)."
	| counterAddress notTripped |
	<var: #notTripped type: #'AbstractInstruction *'>
	counterAddress := self oilAllocateTripCounter.
	self MoveA32: counterAddress R: TempReg.
	self SubCq: 1 R: TempReg.
	self MoveR: TempReg A32: counterAddress.
	notTripped := self JumpNonZero: 0.
	self MoveCq: kind R: SendNumArgsReg.
	self CallRT: ceOilTripTrampoline.
	self MoveR: TempReg A32: counterAddress.
	notTripped jmpTarget: self Label.
	^0! !


!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/26/2026 10:40'!
oilAllocateTripCounter
	"Answer the address of a trip counter for a site being compiled, initialized to OilInitialCounterValue: the next one of
	 the ring buffer oilTripCounters, in the VM's static data.  Once OilNumTripCounters sites have been compiled, sites share
	 counters, which can only make a site trip early."
	<returnTypeC: #usqInt>
	oilNextCounterIndex := (oilNextCounterIndex + 1) bitAnd: OilNumTripCounters - 1.
	oilTripCounters at: oilNextCounterIndex put: OilInitialCounterValue.
	^self
		cCode: [(self addressOf: (oilTripCounters at: oilNextCounterIndex)) asUnsignedInteger]
		inSmalltalk: [oilNextCounterIndex * OilCounterBytes]! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/27/2026 13:20'!
oilDecayTripCounters
	"Age the loop trip counters on each scavenge so that cold loops do not slowly accumulate trips (leaving alone the
	 counters that back off, above OilInitialCounterValue, see ceOilTrip:)."
	<api>
	| val |
	0 to: OilNumTripCounters - 1 do:
		[:i|
		val := oilTripCounters at: i.
		(val > 0 and: [val < OilInitialCounterValue]) ifTrue:
			[val := val + 512.
			 val > OilInitialCounterValue ifTrue: [val := OilInitialCounterValue].
			 oilTripCounters at: i put: val]]! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/28/2026 05:10'!
oilTripRestartCount
	"The count a trip counter restarts from after a trip whose home method may still get a specialization (see ceOilTrip:)."
	<api>
	<inline: false>
	^OilInitialCounterValue! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/28/2026 05:10'!
oilTripRetryCount
	"The count a trip counter restarts from after a transient failure to compile its home method (see ceOilTrip:)."
	<api>
	<inline: false>
	^OilTripRetryCount! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/28/2026 05:10'!
oilTripBackOffCount
	"The count a trip counter restarts from when Oil cannot or need not compile its home method (see ceOilTrip:)."
	<api>
	<inline: false>
	^OilTripBackOffCount! !


!ProfilingCogit methodsFor: 'generate machine code' stamp: 'cb 10/24/2026 10:00'!
fillInCPICHeader: pic numArgs: numArgs numCases: numCases hasMNUCase: hasMNUCase selector: selector
	pic counters: 0.
	super fillInCPICHeader: pic numArgs: numArgs numCases: numCases hasMNUCase: hasMNUCase selector: selector! !

!ProfilingCogit methodsFor: 'generate machine code' stamp: 'cb 10/27/2026 23:30'!
fillInMethodHeader: method size: size selector: selector
	super fillInMethodHeader: method size: size selector: selector.
	method counters: 0. "(the trip counters are in the ring buffer, see oilAllocateTripCounter)"
	method cmUnusedFlag: false! !

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
	"Each counter is a 32-bit word, of a ring buffer of 1024 (4 KB, see oilAllocateTripCounter)."
	OilCounterBytes := 4.
	OilNumTripCounters := 1024.
	"Trip after 2^13 - 1 executions of a site (8k)."
	OilInitialCounterValue := (1 << 13) - 1.
	"After a trip, a site whose home method had a transient failure (a full code zone) trips again after 2^20 - 1 executions,
	 one whose home method Oil cannot or need not compile after 2^30 - 1 (see ceOilTrip:)."
	OilTripRetryCount := (1 << 20) - 1.
	OilTripBackOffCount := (1 << 30) - 1.
	"The kind of trip site, passed to CoInterpreter>>ceOilTrip:: a loop back jump (the only kind)."
	OilTripBackJump := 0.! !


!ProfilingCogit class methodsFor: 'translation' stamp: 'cb 10/24/2026 10:00'!
additionalHeadersDo: aBinaryBlock
	"Evaluate aBinaryBlock with the names and contents of
	 any additional header files that need to be generated.
	 ProfilingCogit uses the counters field of SistaCogMethod."
	aBinaryBlock
		value: 'cogmethod.h'
		value: SistaCogMethod cogMethodHeader! !

!ProfilingCogit class methodsFor: 'translation' stamp: 'cb 10/28/2026 00:15'!
declareCVarsIn: aCodeGen
	aCodeGen var: #oilTripCounters declareC: 'static int oilTripCounters[OilNumTripCounters]'.
	aCodeGen var: #oilNextCounterIndex declareC: 'static usqInt oilNextCounterIndex = 0'.
	aCodeGen var: #oilDispatcherPrototype type: #'CogMethod *'! !


!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-profiling' stamp: 'cb 10/28/2026 05:10'!
ceOilTrip: kind
	"Called from ceOilTripTrampoline when a ProfilingCogit trip counter reaches zero, at a
	 loop back jump (kind 0, the only kind).  framePointer is the
	 tripping machine code frame and the top of stack is the return address into its code.
	 Identify the method that should be the root of an Oil compilation:
	 - in a block activation, the home method of the block, found by walking the closure's
	   outer contexts up to its home context, i.e. the outer method framing the loop;
	 - at a back jump in a method one of whose arguments is a closure (e.g. the to:do: loop
	   in OrderedCollection>>do:), the home method of that closure, since compiling the
	   iterator alone is useless without knowing the block it evaluates;
	 - otherwise the method itself.
	 Compile it with Oil, for the class of its receiver, and install the Oil code for its next activations (see
	 oilAutoCompile:receiver:); not for a clean block, whose home has no receiver.
	 This must not collect garbage or change the stack, since it returns directly to machine code.
	 Answer the count the site restarts its trip counter from (see ProfilingCogit's class comment)."
	<api>
	<essential: #ProfilingCogit>
	| theFP numArgs closure homeContext homeMethod receiver |
	<var: #theFP type: #'char *'>
	theFP := framePointer.
	self assert: (self isMachineCodeFrame: theFP).
	cogit oilAutoCompileEnabled ifFalse: [^cogit oilTripRestartCount].
	numArgs := self frameNumArgs: theFP.
	closure := (self frameIsBlockActivation: theFP)
				ifTrue: [self frameStackedReceiver: theFP numArgs: numArgs]
				ifFalse: [self oilClosureArgumentOf: theFP numArgs: numArgs].
	homeMethod := self frameMethodObject: theFP.
	receiver := self frameReceiver: theFP.
	closure ~= objectMemory nilObject ifTrue:
		[homeContext := self oilHomeContextOfClosure: closure.
		 homeContext = objectMemory nilObject ifTrue: "a clean block"
			[^cogit oilTripBackOffCount].
		 homeMethod := objectMemory followMaybeForwarded: (objectMemory fetchPointer: MethodIndex ofObject: homeContext).
		 receiver := objectMemory followMaybeForwarded: (objectMemory fetchPointer: ReceiverIndex ofObject: homeContext)].
	^self oilAutoCompile: homeMethod receiver: receiver! !

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

!SpurMemoryManager methodsFor: '*VMMaker-JIT-Oil-profiling' stamp: 'cb 10/27/2026 13:08'!
doScavenge: tenuringCriterion
	"SpurMemoryManager's main entry point for scavenging:
	 - account for the space allocated since the last collection
	 - run the scavenger and age the Oil loop trip counters
	 - reset freeStart and accounting."
	self doAllocationAccountingForScavenge.
	gcPhaseInProgress := ScavengeInProgress.
	pastSpaceStart := scavenger scavenge: tenuringCriterion.
	self assert: (self
					oop: pastSpaceStart
					isGreaterThanOrEqualTo: scavenger pastSpace start
					andLessThanOrEqualTo: scavenger pastSpace limit).
	self cCode: [self oilDecayTripCounters] inSmalltalk: [coInterpreter cogit oilDecayTripCounters].
	freeStart := scavenger eden start.
	gcPhaseInProgress := 0.
	self resetAllocationAccountingAfterGC! !

!CoInterpreter class methodsFor: '*VMMaker-JIT-Oil-translation' stamp: 'cb 10/26/2026 20:20'!
writeVMHeaderTo: aStream bytesPerWord: bytesPerWord generator: aCCodeGenerator
	super writeVMHeaderTo: aStream bytesPerWord: bytesPerWord generator: aCCodeGenerator.
	aCCodeGenerator
		putDefineOf: #COGVM as: 1 on: aStream;
		putConditionalDefineOf: #COGMTVM as: 0 comment: nil on: aStream.
	(aCCodeGenerator options at: #Oil ifAbsent: [false]) ifTrue:
		[aCCodeGenerator
			putConditionalDefineOf: #Oil
			as: 1
			comment: nil
			on: aStream].
	aStream cr! !

!VMMaker class methodsFor: '*VMMaker-JIT-Oil-configurations' stamp: 'cb 10/26/2026 20:20'!
generateSqueakSpurCogOil64VM
	"The 64-bit Cog Spur VM with the ProfilingCogit, the profiling tier of the Oil optimizing JIT."
	^VMMaker
		generate: CoInterpreter
		and: ProfilingCogit
		with: #(Oil true
				ProfilingCogit true
				ObjectMemory Spur64BitCoMemoryManager
				MULTIPLEBYTECODESETS true
				bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid)
		to: (self srcDirectory fullNameFor: 'spur64.oil')
		platformDir: self sourceTree, '/platforms'
		including:#()! !
