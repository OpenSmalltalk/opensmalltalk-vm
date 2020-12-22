"
RegisterAllocatingCogit is an optimizing code generator that is specialized for register allocation.

On the contrary to StackToRegisterMappingCogit, RegisterAllocatingCogit keeps at each control flow merge point the state of the simulated stack to merge into and not only an integer fixup. Each branch and jump record the current state of the simulated stack, and each fixup is responsible for merging this state into the saved simulated stack.

Instance Variables
	ceSendMustBeBooleanAddFalseLongTrampoline:		<Integer>
	ceSendMustBeBooleanAddTrueLongTrampoline:		<Integer>
	mergeSimStacksBase:									<Integer>
	nextFixup:												<Integer>
	numFixups:												<Integer>
	scratchOptStatus:										<CogSSOptStatus>
	scratchSimStack:										<Array of CogRegisterAllocatingSimStackEntry>
	scratchSpillBase:										<Integer>

ceSendMustBeBooleanAddFalseLongTrampoline
	- the must-be-boolean trampoline for long jump false bytecodes (the existing ceSendMustBeBooleanAddFalseTrampoline is used for short branches)

ceSendMustBeBooleanAddTrueLongTrampoline
	- the must-be-boolean trampoline for long jump true bytecodes (the existing ceSendMustBeBooleanAddTrueTrampoline is used for short branches)

mergeSimStacksBase
	- the base address of the alloca'ed memory for merge fixups

nextFixup
	- the index into mergeSimStacksBase from which the next needed mergeSimStack will be allocated

numFixups
	- a conservative (over) estimate of the number of merge fixups needed in a method

scratchOptStatus
	- a scratch variable to hold the state of optStatus while merge code is generated

scratchSimStack
	- a scratch variable to hold the state of simStack while merge code is generated

scratchSpillBase
	- a scratch variable to hold the state of spillBase while merge code is generated
"
Class {
	#name : #RegisterAllocatingCogit,
	#superclass : #StackToRegisterMappingCogit,
	#instVars : [
		'numFixups',
		'mergeSimStacksBase',
		'nextFixup',
		'scratchSimStack',
		'scratchSpillBase',
		'ceSendMustBeBooleanAddTrueLongTrampoline',
		'ceSendMustBeBooleanAddFalseLongTrampoline',
		'recompileForLoopRegisterAssignments',
		'scratchBytecodePC'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'C translation' }
RegisterAllocatingCogit class >> declareCVarsIn: aCodeGen [
	aCodeGen
		var: #scratchSimStack
			type: #'SimStackEntry *';
		var: #scratchSimSelf
			type: #SimStackEntry
]

{ #category : #accessing }
RegisterAllocatingCogit class >> numTrampolines [
	^super numTrampolines + 2 "includes long sendMustBeBoolean trampolines"

	"Cogit withAllSubclasses, CogObjectRepresentation withAllSubclasses collect:
		[:c| {c. (c instVarNames select: [:ea| ea beginsWith: 'ce']) size}]"
	"self allInstVarNames select: [:ea| ea beginsWith: 'ce']"
	"self instVarNames select: [:ea| ea beginsWith: 'ce']"
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> allocateMergeFixups [
	"Allocate the various arrays needed to allocate the merge fixups, failing if the size
	 needed is considered too high.

	 This *must* be inlined since the arrays are alloca'ed (stack allocated)
	 so that they are freed when compilation is done.

	 N.B. We do one single alloca to save embarrassing C optimizers that
	 generate incorrect code as both gcc and the intel compiler do on x86."
	<inline: true>
	| mergeSimStackBytes |
	mergeSimStackBytes := numFixups * self simStackSlots * (self sizeof: CogSimStackEntry).
	nextFixup := 0.
	self cCode:
		[mergeSimStacksBase := self alloca: mergeSimStackBytes.
		 self b: mergeSimStacksBase zero: mergeSimStackBytes]
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> allocateRegForStackEntryAt: index [
	"If the stack entry is already in a register, answers it,
	else allocate a new register for it"
	<inline: true>
	| reg |
	(reg := (self ssValue: index) registerOrNone) ~= NoReg ifTrue:
		[^reg].
	^self allocateRegForStackEntryAt: index notConflictingWith: (self liveRegisters bitOr: (self registerMaskFor: FPReg and: SPReg and: TempReg))
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> allocatedRegisters [
	| regsSet |
	self assert: needsFrame.
	regsSet := 0.
	0 to: methodOrBlockNumTemps do:
		[:i|
		regsSet := regsSet bitOr: (self simStackAt: i) registerMask].
	^regsSet
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> assertCorrectSimStackPtr [
	<inline: true> "generates nothing anyway" "self simStackPrintString"
	 self cCode: '' inSmalltalk:
		[deadCode ifFalse:
			[self assert: simStackPtr + (needsFrame ifTrue: [0] ifFalse: [1])
						= (self debugStackPointerFor: bytecodePC).
			 self assert: (simSpillBase >= methodOrBlockNumTemps
						or: [self maybeCompilingFirstPassOfBlockWithInitialPushNil and: [simSpillBase > methodOrBlockNumArgs]]).
			 (needsFrame and: [simSpillBase > 0]) ifTrue:
				[self assert: (self simStackAt: simSpillBase - 1) spilled == true.
				 self assert: (simSpillBase >= simStackPtr or: [(self simStackAt: simSpillBase) spilled == false])]].
		 self deny: self duplicateRegisterAssignmentsInTemporaries]
]

{ #category : #'simulation only' }
RegisterAllocatingCogit >> bytecodeFixupClass [
	<doNotGenerate>
	^CogRASSBytecodeFixup
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> compileAbstractInstructionsFrom: start through: end [
	"Loop over bytecodes, dispatching to the generator for each bytecode, handling fixups in due course.
	 Override to recompile after a loop requiring a merge is detected."
	scratchBytecodePC := nil.
	^super compileAbstractInstructionsFrom: start through: end
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> compileBlockBodies [
	<inline: false>
	| result compiledBlocksCount blockStart savedNeedsFrame savedNumArgs savedNumTemps
	  initialStackPtr initialOpcodeIndex initialIndexOfIRC initialCounterIndex |
	<var: #blockStart type: #'BlockStart *'>
	self assert: blockCount > 0.
	"scanBlock: in compileBlockEntry: sets both of these appropriately for each block."
	savedNeedsFrame := needsFrame.
	savedNumArgs := methodOrBlockNumArgs.
	savedNumTemps := methodOrBlockNumTemps.
	inBlock := InVanillaBlock.
	compiledBlocksCount := 0.
	[compiledBlocksCount < blockCount] whileTrue:
		[blockStart := self blockStartAt: compiledBlocksCount.
		 (result := self scanBlock: blockStart) < 0 ifTrue: [^result].
		 compilationPass := 1.
		 scratchBytecodePC := nil.
		 initialOpcodeIndex := opcodeIndex.
		 initialCounterIndex := self maybeCounterIndex."for SistaCogit"
		 literalsManager saveForRecompile.
		 [recompileForLoopRegisterAssignments := false.
		  self compileBlockEntry: blockStart.
		  initialStackPtr := simStackPtr.
		  (result := self compileAbstractInstructionsFrom: blockStart startpc + (self pushNilSize: methodObj numInitialNils: blockStart numInitialNils)
						through: blockStart startpc + blockStart span - 1) < 0 ifTrue:
			[^result].
		  "If the final simStackPtr is less than the initial simStackPtr then scanBlock: over-
		   estimated the number of initial nils (because it assumed one or more pushNils to
		   produce an operand were pushNils to initialize temps.  This is very rare, so
		   compensate by checking, adjusting numInitialNils and recompiling the block body.
		   N.B.  No need to reinitialize the literalsManager because it answers existing literals."
		  initialStackPtr ~= simStackPtr or: [recompileForLoopRegisterAssignments]]
			whileTrue:
				[self assert: (initialStackPtr > simStackPtr or: [deadCode]).
				 self assert: compilationPass = 1.
				 compilationPass := compilationPass + 1. "for asserts"
				 blockStart numInitialNils: blockStart numInitialNils + simStackPtr - initialStackPtr.
				 blockStart fakeHeader dependent: nil.
				 self reinitializeAllButBackwardFixupsFrom: blockStart startpc + blockStart numInitialNils through: blockStart startpc + blockStart span - 1.
				 nextFixup := 0.
				 self resetSimStack: blockStart startpc.
				 self reinitializeOpcodesFrom: initialOpcodeIndex to: opcodeIndex - 1.
				 opcodeIndex := initialOpcodeIndex.
				 self maybeSetCounterIndex: initialCounterIndex. "For SistaCogit"
				 literalsManager resetForRecompile ].
		compiledBlocksCount := compiledBlocksCount + 1].
	needsFrame := savedNeedsFrame.
	methodOrBlockNumArgs := savedNumArgs.
	methodOrBlockNumTemps := savedNumTemps.
	^0
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> compileEntireFullBlockMethod: numCopied [
	"Compile the abstract instructions for the entire full block method."
	self allocateMergeFixups.
	^super compileEntireFullBlockMethod: numCopied
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> compileEntireMethod [
	"Compile the abstract instructions for the entire method, including blocks."
	self allocateMergeFixups.
	^super compileEntireMethod
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> compileMethodBody [
	"Compile the top-level method body."
	<inline: true>
	| result initialOpcodeIndex initialCounterIndex initialIndexOfIRC start |
	endPC < initialPC ifTrue: [^0]. "quick primitives"
	"When compiling, skip any initial CallPrimitive and optional StorePrimErrCode bytecodes.
	 These are dealt with in compileFrameBuild."
	compilationPass := 1.
	scratchBytecodePC := nil.
	initialOpcodeIndex := opcodeIndex.
	initialCounterIndex := self maybeCounterIndex."for SistaCogit"
	literalsManager saveForRecompile.
	[recompileForLoopRegisterAssignments := false.
	 start := initialPC + (self deltaToSkipPrimAndErrorStoreIn: methodObj header: methodHeader).
	 result := self compileAbstractInstructionsFrom: start through: endPC.
	 result = 0
	 and: [recompileForLoopRegisterAssignments]]
		whileTrue:
			[self assert: compilationPass <= 2.
			 self reinitializeAllButBackwardFixupsFrom: start through: endPC.
			 self resetSimStack: start.
			 self reinitializeOpcodesFrom: initialOpcodeIndex to: opcodeIndex - 1.
			 compilationPass := compilationPass + 1.
			 nextFixup := 0.
			 opcodeIndex := initialOpcodeIndex.
			 self maybeSetCounterIndex: initialCounterIndex. "For SistaCogit"
			 literalsManager resetForRecompile ].
	^result
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> conflictingRegistersBetweenSimStackAnd: mergeSimStack [
	<var: #mergeSimStack type: #'SimStackEntry *'>
	| currentRegsMask mergeRegsMask potentialConflictRegMask |
	<var: #currentEntry type: #'SimStackEntry *'>
	<var: #targetEntry type: #'SimStackEntry *'>
	currentRegsMask := mergeRegsMask := potentialConflictRegMask := 0.
	0 to: simStackPtr do:
		[:i| | currentEntry targetEntry currentRegMask mergeRegMask |
		 currentRegMask := (currentEntry := self simStack: simStack at: i) registerMaskOrNone.
		 mergeRegMask := (targetEntry := self simStack: mergeSimStack at: i) registerMaskOrNone.
		 (currentRegMask ~= mergeRegMask
		  and: [currentRegMask ~= 0 or: [mergeRegMask ~= 0]]) ifTrue:
			[potentialConflictRegMask := potentialConflictRegMask bitOr: (currentRegMask bitOr: mergeRegMask)].
		 currentRegsMask := currentRegsMask bitOr: currentRegMask.
		 mergeRegsMask := mergeRegsMask bitOr: mergeRegMask].
	^potentialConflictRegMask bitAnd: (currentRegsMask bitAnd: mergeRegsMask)
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> conflictsResolvedBetweenSimStackAnd: mergeSimStack [ 
	"There are no register conflicts between simStack and mergeSimStack if
	 traversing both stacks from hot end (simStackPtr) to cold end (0) no register
	 exists in simStack that has previously existed in mergeSimStack.  This is because
	 the resolution assigns values from simStack to registers in mergeSimStack and so
	 must not assign to a register yet to be read."
	 | regsWrittenToMask |
	regsWrittenToMask := 0.
	simStackPtr to: 0 by: -1 do:
		[:i| | mergeMask currentMask |
		mergeMask := (self simStack: mergeSimStack at: i) registerMaskOrNone.
		currentMask := (self simStack: simStack at: i) registerMaskOrNone.
		"Ignore targets with no registers.  Current's register can be deassigned and so there's no conflict."
		(mergeMask ~= 0 and: [mergeMask ~= currentMask]) ifTrue:
			[(currentMask anyMask: regsWrittenToMask) ifTrue:
				[^false]].
		regsWrittenToMask := regsWrittenToMask bitOr: mergeMask].
	^true
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> copyLiveRegisterToCopiesOf: simStackEntry [
	"Copy the liveRegister in simStackEntry into all corresponding stack entries."
	<var: #simStackEntry type: #'SimStackEntry *'>
	simStackPtr to: 0 by: -1 do:
		[:i|
		(self simStackAt: i) copyLiveRegisterIfSameAs: simStackEntry]
]

{ #category : #'simulation only' }
RegisterAllocatingCogit >> copySimStack [
	<doNotGenerate>
	^CArrayAccessor on: (simStack object collect: [:stackEntry| stackEntry copy])
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> copySimStackToFixup: fixup [
	<var: #fixup type: #'BytecodeFixup *'>
	<inline: true>
	self cCode: [self memcpy: fixup mergeSimStack _: simStack _: simStackPtr + 1 * (self sizeof: CogSimStackEntry)]
		inSmalltalk: [0 to: simStackPtr do:
						[:i|
						fixup mergeSimStack at: i put: (simStack at: i) copy]]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> copySimStackToScratch: spillBase [
	<inline: true>
	self assert: (spillBase > methodOrBlockNumTemps
				or: [self maybeCompilingFirstPassOfBlockWithInitialPushNil and: [spillBase > methodOrBlockNumArgs]]).
	scratchBytecodePC = bytecodePC ifTrue:
		[^self].
	scratchBytecodePC := bytecodePC.
	self cCode: [self memcpy: scratchSimStack _: simStack _: self simStackSlots * (self sizeof: CogSimStackEntry)]
		inSmalltalk: [0 to: simStackPtr do:
						[:i|
						scratchSimStack at: i put: (simStack at: i) copy]].
	scratchSpillBase := spillBase
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> deassignRegister: register in: aSimStack [
	"When a merge has assigned a register to a volatile stack entry
	 deassign that register from any temporaries."
	self assert: register ~= NoReg.
	0 to: methodOrBlockNumTemps do:
		[:i|
		(self simStack: aSimStack at: i) liveRegister = register ifTrue:
			[(self simStack: aSimStack at: i) liveRegister: NoReg]]
]

{ #category : #debugging }
RegisterAllocatingCogit >> duplicateRegisterAssignmentsInTemporaries [
	| liveRegisters |
	liveRegisters := 0.
	0 to: (methodOrBlockNumTemps min: (simStackPtr min: simSpillBase - 1)) do: "The min:s are for the initial push nil hack"
		[:i| | current liveRegister |
		liveRegister := (current := self simStackAt: i) liveRegister.
		liveRegister ~= NoReg ifTrue:
			[(self register: liveRegister isInMask: liveRegisters) ifTrue:
				["Filter out pushed temps in first-pass vanilla blocks"
				 (self maybeCompilingFirstPassOfBlockWithInitialPushNil
				  and: [current type = SSBaseOffset
				  and: [current offset ~= (self frameOffsetOfTemporary: i - 1)]]) ifFalse:
					[^true]].
			 liveRegisters := liveRegisters bitOr: (self registerMaskFor: liveRegister)]].
	^false
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> ensureFixupAt: targetPC [
	"Make sure there's a flagged fixup at the target pc in fixups.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction.
	 Override to generate stack merging code if required."
	| fixup |	
	<var: #fixup type: #'BytecodeFixup *'>
	self assert: targetPC > bytecodePC.
	self cCode: '' inSmalltalk:
		[self assert: simStackPtr + (needsFrame ifTrue: [0] ifFalse: [1])
					= (self debugStackPointerFor: targetPC)].
	fixup := self fixupAt: targetPC.
	"If a non-merge fixup has already been defined then where-ever that was done didn't
	 realise there needed to be a merge and forgot to save the stack state for that merge."
	self deny: fixup isNonMergeFixup.
	fixup needsFixup 
		ifTrue:
			[fixup mergeSimStack
				ifNil: [self setMergeSimStackOf: fixup]
				ifNotNil:
					[self copySimStackToScratch: simSpillBase.
					 self mergeCurrentSimStackWith: fixup.
					 self restoreSimStackFromScratch]]
		ifFalse: 
			[self assert: (fixup mergeSimStack isNil or: [compilationPass = 2]).
			 fixup mergeSimStack
				ifNil: [self setMergeSimStackOf: fixup]
				ifNotNil:
					[self assert: (self simStack: simStack isIdenticalTo: fixup mergeSimStack)]].
	^super ensureFixupAt: targetPC
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> ensureNonMergeFixupAt: targetPC [
	"RegisterAllocatingCogit insists on merging."
	self shouldNotImplement
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> ensureReceiverResultRegContainsSelf [
	"First ensure that ReceiverResultReg is allocated to self,
	 which may cause spills, etc.  Then copy the register into
	 any instances of simSelf on the stack."

	| freeReg live ssEntry |
	needsFrame
		ifTrue:
			[self receiverIsInReceiverResultReg ifFalse: "Avoid spilling if possible"
				[live := self liveRegisters.
				 ssEntry := self ssEntrySuchThat: [:e| e registerOrNone = ReceiverResultReg].
				 (ssEntry notNil
				  and: [(freeReg := backEnd availableRegisterOrNoneFor: live) ~= NoReg])
					ifTrue: "ReceiverResultReg is being used, but we have a free register.  So avoid spill by assigining."
						[ssEntry storeToRegNoAssign: freeReg.
						 self ssEntriesDo:
							[:e|
							 e registerOrNone = ReceiverResultReg ifTrue:
								[e type = SSRegister
									ifTrue: [e register: freeReg]
									ifFalse: [e liveRegister: freeReg]]]]
					ifFalse:
						[self ssAllocateRequiredReg: ReceiverResultReg].
				 self putSelfInReceiverResultReg.
				 self simSelf liveRegister: ReceiverResultReg]]
		ifFalse:
			[self assert: (self simSelf type = SSRegister
						  and: [self simSelf register = ReceiverResultReg
						  and: [self receiverIsInReceiverResultReg]])].
	"the storeToReg: in putSelfInReceiverResultReg in
	 ensureReceiverResultRegContainsSelf copies the register to all copies.
	 So simply check that the stack agrees with this."
	self assert: self receiverResultRegIsAssignedToSelfAndNothingElse
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> ensureRegisterAssignmentsAreAtHeadOfLoop: target [
	"Compiling a loop body will compute a set of live registers.  The backward branch must merge
	 with the head of the loop.  So it is preferrable to make the register assignments at the end of
	 the loop available at the head.  To do this, simply copy the register assignments to the loop
	 head's fixup in the first compilation pass and schedule a second compilation pass.  On the
	 second pass the merge will occur when encountering the fixup for the loop head, using
	 exactly the same code as for a merge at the end of an if."
	| conflictingRegsMask |
	compilationPass > 1 ifTrue:
		[self assert: (target mergeSimStack notNil).
		 ^self].
	(self mergeRequiredToTarget: target mergeSimStack) ifFalse:
		[^self].
	"Schedule a recompile and merge the end-of-loop assignments into the head of the loop,
	 replacing any and all register assignments with the state as of the back jump.  Because
	 typically the back jump will be taken much more often than the loop entered, favouring
	 the assignments here is more efficient than trying to merge."
	recompileForLoopRegisterAssignments := true.
	conflictingRegsMask := self conflictingRegistersBetweenSimStackAnd: target mergeSimStack.
	self deny: (self register: FPReg isInMask: conflictingRegsMask).
	0 to: simStackPtr do:
		[:i| | currentEntry targetEntry |
		 currentEntry := self simStack: simStack at: i.
		 targetEntry := self simStack: target mergeSimStack at: i.
		 targetEntry liveRegister: currentEntry liveRegister]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> existsInstVarRefBeforeSendOrReturn [
	"Answer if the current bytecode is followed by an inst var ref before the next full send."
	| pc nExts descriptor |
	pc := bytecodePC.
	nExts := 0.
	[pc <= endPC] whileTrue:
		[descriptor := self generatorForPC: pc.
		 (descriptor isMapped
		  or: [descriptor isConditionalBranch
		  or: [descriptor spanFunction notNil]]) ifTrue:
			[^false].
		 descriptor isInstVarRef ifTrue:
			[^true].
		 nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0].
		 pc := self nextBytecodePCFor: descriptor at: pc exts: nExts in: methodObj].
	^false
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> flushLiveRegistersForCRunTimeCall [
	"Flush any live registers for a C call, i.e. don't flush caller-saved registers.
	 Answer if any registers were flushed."
	<inline: true>
	| flushed reg |
	flushed := false.
	0 to: simStackPtr do:
		[:i|
		 self assert: (self simStackAt: i) type = (i <= methodOrBlockNumTemps
													ifTrue: [SSBaseOffset]
													ifFalse: [SSSpill]).
		 reg := (self simStackAt: i) liveRegister.
		 (reg ~= NoReg and: [(self isCallerSavedReg: reg)]) ifTrue:
			[(self simStackAt: i) liveRegister: NoReg.
			 flushed := true]].
	^flushed
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> flushLiveRegistersForSend [
	<inline: true>
	0 to: simStackPtr do:
		[:i|
		 self assert: ((self simStackAt: i) spilled
					 and: [(self simStackAt: i) type = SSConstant
						or: [((self simStackAt: i) type = SSBaseOffset
							or: [i > methodOrBlockNumTemps
								and: [(self simStackAt: i) type = SSSpill]])
							 and: [(self simStackAt: i) register = FPReg
							 and: [i = 0
								or: [(self simStackAt: i) offset = (self frameOffsetOfTemporary: i - 1)]]]]]).
		 (self simStackAt: i) liveRegister: NoReg]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> flushLiveRegistersForSuspensionPoint [
	"Flush any live registers for a C call at a suspension/resumption point, i.e.flush all registers.
	 Answer if any registers were flushed."
	<inline: true>
	| flushed |
	flushed := false.
	0 to: simStackPtr do:
		[:i|
		 self assert: (i <= methodOrBlockNumTemps
						ifTrue: [(self simStackAt: i) type = SSBaseOffset]
						ifFalse: [(self simStackAt: i)  spilled]).
		 (self simStackAt: i) liveRegister ~= NoReg ifTrue:
			[(self simStackAt: i) liveRegister: NoReg.
			 flushed := true]].
	^flushed
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> flushRegistersOnlyLiveOnFallThrough: fixup [
	"Forward jumps won't generate merge code if the source has a register that is live but the destination does not.
	 For example in
			| v | v := expr1. self expr2 ifTrue: [v := expr3]. ^v
	 v will be assigned to a register in v := expr1 and [v := expr3], but the send of expr2 will flush it along the jumpFalse across [v := expr3].
	 So v will not be in a register if reached from the jump.  Hence at the join at the end of [v := expr3] v must be marked as not being in a register."
	| targetSimStack |
	targetSimStack := fixup mergeSimStack.
	0 to: simStackPtr do:
		[:i| | fallThrough target |
		 fallThrough := self simStack: simStack at: i.
		 target := self simStack: targetSimStack at: i.
		 self assert: (fallThrough liveRegister = target liveRegister or: [target liveRegister = NoReg or: [fallThrough liveRegister = NoReg]]).
		 target liveRegister = NoReg ifTrue:
			[fallThrough liveRegister: NoReg]]
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> freeAnyRegNotConflictingWith: regMask [
	"Spill the closest register on stack not conflicting with regMask. 
	 Override to unassign assigned temp regs if necessary."
	<var: #desc type: #'CogSimStackEntry *'>
	| index desc |
	self assert: needsFrame.
	self assert: simSpillBase >= 0.
	index := simSpillBase.
	[index < simStackPtr] whileTrue: 
		[desc := self simStackAt: index.
		 desc type = SSRegister ifTrue:
			[(regMask anyMask: (self registerMaskFor: desc register)) ifFalse: 
				[self ssAllocateRequiredReg: desc register.
				 ^desc register]].
		 index := index + 1].
	1 to: methodOrBlockNumTemps do:
		[:i|
		 desc := self simStackAt: i.
		 (desc liveRegister = NoReg
		  or: [self register: desc liveRegister isInMask: regMask]) ifFalse:
			[self ssAllocateRequiredReg: desc liveRegister.
			 ^desc liveRegister]].
	(self simSelf liveRegister = NoReg
	 or: [self register: self simSelf liveRegister isInMask: regMask]) ifFalse:
		[self ssAllocateRequiredReg: self simSelf liveRegister.
		 ^self simSelf liveRegister].
	^NoReg
]

{ #category : #'trampoline support' }
RegisterAllocatingCogit >> genCallMustBeBooleanFor: boolean [
	"Call ceSendMustBeBooleanTo:interpretingAtDelta: via the relevant trampoline."
	self assert: ((self generatorAt: byte0) numBytes between: 1 and: 2).
	^self CallRT: ((self generatorAt: byte0) numBytes = 1
					ifTrue:
						[boolean = objectMemory falseObject
							ifTrue: [ceSendMustBeBooleanAddFalseTrampoline]
							ifFalse: [ceSendMustBeBooleanAddTrueTrampoline]]
					ifFalse:
						[boolean = objectMemory falseObject
							ifTrue: [ceSendMustBeBooleanAddFalseLongTrampoline]
							ifFalse: [ceSendMustBeBooleanAddTrueLongTrampoline]])
]

{ #category : #'bytecode generators' }
RegisterAllocatingCogit >> genForwardersInlinedIdenticalOrNotIf: orNot [
	| nextPC branchDescriptor unforwardRcvr argReg targetPC
	  unforwardArg  rcvrReg postBranchPC retry fixup
	  comparison
	  needMergeToTarget needMergeToContinue |
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	<var: #toContinueLabel type: #'AbstractInstruction *'>
	<var: #toTargetLabel type: #'AbstractInstruction *'>
	<var: #comparison type: #'AbstractInstruction *'>
	<var: #retry type: #'AbstractInstruction *'>
	
	self extractMaybeBranchDescriptorInto: [ :descr :next :postBranch :target | 
		branchDescriptor := descr. nextPC := next. postBranchPC := postBranch. targetPC := target ].

	"If an operand is an annotable constant, it may be forwarded, so we need to store it into a 
	register so the forwarder check can jump back to the comparison after unforwarding the constant.
	However, if one of the operand is an unnanotable constant, does not allocate a register for it 
	(machine code will use operations on constants) and does not generate forwarder checks."
	unforwardRcvr := (objectRepresentation isUnannotatableConstant: (self ssValue: 1)) not.
	unforwardArg := (objectRepresentation isUnannotatableConstant: self ssTop) not.

	self 
		allocateEqualsEqualsRegistersArgNeedsReg: unforwardArg 
		rcvrNeedsReg: unforwardRcvr 
		into: [ :rcvr :arg | rcvrReg:= rcvr. argReg := arg ].

	"If not followed by a branch, resolve to true or false."
	(branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse]) ifFalse:
		[^self 
			genIdenticalNoBranchArgIsConstant: unforwardArg not
			rcvrIsConstant: unforwardRcvr not
			argReg: argReg 
			rcvrReg: rcvrReg 
			orNotIf: orNot].
	
	self assert: (unforwardArg or: [unforwardRcvr]).
	self ssPop: 2. "If we had moveAllButTop: 2 volatileSimStackEntriesToRegistersPreserving: we could avoid the extra ssPop:s"
	self moveVolatileSimStackEntriesToRegistersPreserving:
		(self allocatedRegisters bitOr: (argReg = NoReg
										ifTrue: [self registerMaskFor: rcvrReg]
										ifFalse:
											[rcvrReg = NoReg
												ifTrue: [self registerMaskFor: argReg]
												ifFalse: [self registerMaskFor: rcvrReg and: argReg]])).
	retry := self Label.
	self ssPop: -2.
	self genCmpArgIsConstant: unforwardArg not rcvrIsConstant: unforwardRcvr not argReg: argReg rcvrReg: rcvrReg.
	self ssPop: 2.

	(self fixupAt: nextPC) notAFixup "The next instruction is dead.  we can skip it."
		ifTrue:  [deadCode := true]
		ifFalse: [self deny: deadCode]. "push dummy value below"

	"self printSimStack; printSimStack: (self fixupAt: postBranchPC) mergeSimStack"
	"If there are merges to be performed on the forward branches we have to execute
	 the merge code only along the path requiring that merge, and exactly once."
	needMergeToTarget := self mergeRequiredForJumpTo: targetPC.
	needMergeToContinue := self mergeRequiredForJumpTo: postBranchPC.
	orNot == branchDescriptor isBranchTrue
		ifFalse: "a == b ifTrue: ... or a ~~ b ifFalse: ... jump on equal to target pc"
			[fixup := needMergeToContinue
						ifTrue: [0] "jumps will fall-through to to-continue merge code"
						ifFalse: [self ensureFixupAt: postBranchPC].
			 comparison := self JumpZero: (needMergeToTarget
												ifTrue: [0] "comparison will be fixed up to to-target merge code"
												ifFalse: [self ensureFixupAt: targetPC])]
		ifTrue: "a == b ifFalse: ... or a ~~ b ifTrue: ... jump on equal to post-branch pc"
			[fixup := needMergeToTarget
						ifTrue: [0] "jumps will fall-through to to-target merge code"
						ifFalse: [self ensureFixupAt: targetPC].
			 comparison := self JumpZero: (needMergeToContinue
												ifTrue: [0] "comparison will be fixed up to to-continue merge code"
												ifFalse: [self ensureFixupAt: postBranchPC])].

	"The forwarders check(s) need(s) to jump back to the comparison (retry) if a forwarder is found,
	 else jump forward either to the next forwarder check or to the postBranch or branch target (fixup).
	 But if there is merge code along a path, the jump must be to the merge code."
	(unforwardArg and: [unforwardRcvr]) ifTrue:
		[objectRepresentation genEnsureOopInRegNotForwarded: argReg scratchReg: TempReg jumpBackTo: retry].
	objectRepresentation 
		genEnsureOopInRegNotForwarded: (unforwardRcvr ifTrue: [rcvrReg] ifFalse: [argReg]) 
		scratchReg: TempReg 
		ifForwarder: retry
		ifNotForwarder: fixup.
	"If fixup is zero then the ifNotForwarder path falls through to a Label which is interpreted
	 as either to-continue or to-target, depending on orNot == branchDescriptor isBranchTrue."
	orNot == branchDescriptor isBranchTrue
		ifFalse: "a == b ifTrue: ... or a ~~ b ifFalse: ... jump on equal to target pc"
			[needMergeToContinue ifTrue: "fall-through to to-continue merge code"
				[self Jump: (self ensureFixupAt: postBranchPC)].
			 needMergeToTarget ifTrue: "fixup comparison to to-target merge code"
				[comparison jmpTarget: self Label.
				 self Jump: (self ensureFixupAt: targetPC)]]
		ifTrue: "a == b ifFalse: ... or a ~~ b ifTrue: ... jump on equal to post-branch pc"
			[needMergeToTarget ifTrue: "fall-through to to-target merge code"
				[self Jump: (self ensureFixupAt: targetPC)].
			 needMergeToContinue ifTrue: "fixup comparison to to-continue merge code"
				[comparison jmpTarget: self Label.
				 self Jump: (self ensureFixupAt: postBranchPC)]].

	deadCode ifFalse: "duplicate the merge fixup's top of stack so as to avoid a false confict."
		[self ssPushDesc: ((self fixupAt: nextPC) mergeSimStack at: simStackPtr + 1)].
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> genJumpBackTo: targetPC [
	| target |
	"On first pass install register allocations (if any) as of the end of the loop and back up to recompile.
	 One the second pass generate
				(any merge other than self elided because register assignments copied to loop head in first pass)
				cmp stackLimit
				maybe reload self
				jumpAboveOrEqual target
				flush
				checkForInterrupts
				merge from flushed (N.B. If stack was flushed before loop we could conceivably jump to the pre-loop merge code)
				jmp target
	 self printSimStack; printSimStack: target mergeSimStack"
	self assert: targetPC < bytecodePC.
	target := self fixupAt: targetPC.
	self ensureRegisterAssignmentsAreAtHeadOfLoop: target.
	self copySimStackToScratch: simSpillBase.
	self mergeCurrentSimStackWith: target.
	self MoveAw: coInterpreter stackLimitAddress R: TempReg.
	self CmpR: TempReg R: SPReg. "N.B. FLAGS := SPReg - TempReg"
	self JumpAboveOrEqual: target.

	self ssFlushTo: simStackPtr.
	self CallRT: ceCheckForInterruptTrampoline.
	self annotateBytecode: self Label.
	self restoreSimStackFromScratch.
	self flushLiveRegistersForSuspensionPoint.
	self mergeCurrentSimStackWith: target.
	self Jump: target.
	deadCode := true. "can't fall through"
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> genJumpIf: boolean to: targetBytecodePC [
	<inline: false>
	| eventualTarget desc reg fixup ok mbb |
	<var: #fixup type: #'BytecodeFixup *'>
	<var: #ok type: #'AbstractInstruction *'>
	<var: #desc type: #'CogSimStackEntry *'>
	<var: #mbb type: #'AbstractInstruction *'>
	eventualTarget := self eventualTargetOf: targetBytecodePC.
	desc := self ssTop.
	self ssPop: 1.

	extA := 0.

	self moveVolatileSimStackEntriesToRegisters.

	(self stackEntryIsBoolean: desc) ifTrue:
		["Must annotate the bytecode for correct pc mapping."
		 desc constant = boolean
			ifTrue:
				[deadCode := true. "Can't fall through."
				 fixup := self ensureFixupAt: eventualTarget.
				 self annotateBytecode: (self Jump: fixup)]
		 	ifFalse:
				[self annotateBytecode: (self prevInstIsPCAnnotated
												ifTrue: [self Nop]
												ifFalse: [self Label])].
		 ^0].

	"try and use the top entry's register if any, but only if it can be destroyed."
	reg := (desc type ~= SSRegister
			or: [(self anyReferencesToRegister: desc register inAllButTopNItems: 0)
			or: [(desc register = ReceiverResultReg and: [self receiverIsInReceiverResultReg])]])
				ifTrue: [TempReg]
				ifFalse: [desc register].
	desc popToReg: reg.
	"Cunning trick by LPD.  If true and false are contiguous subtract the smaller.
	 Correct result is either 0 or the distance between them.  If result is not 0 or
	 their distance send mustBeBoolean."
	self assert: (objectMemory objectAfter: objectMemory falseObject) = objectMemory trueObject.

	"Copy simStack before any branching.  If no branch then the stack is as it is here, not after the merge for eventualTarget."
	self copySimStackToScratch: simSpillBase.
	"Merge required; must not generate merge code along untaken branch, so flip the order."
	(self mergeRequiredForJumpTo: eventualTarget)
		ifTrue:
			[self genSubConstant: (boolean = objectMemory trueObject
										ifTrue: [objectMemory falseObject]
										ifFalse: [objectMemory trueObject])
				R: reg.
			 ok := self JumpZero: 0.
			 self CmpCq: (boolean = objectMemory trueObject
							ifTrue: [objectMemory trueObject - objectMemory falseObject]
							ifFalse: [objectMemory falseObject - objectMemory trueObject])
				R: reg.
			 mbb := self JumpNonZero: 0.
			 self Jump: (self ensureFixupAt: eventualTarget). "generates merge code"
			 mbb jmpTarget: self Label]
		ifFalse:
			[self genSubConstant: boolean R: reg.
			 self JumpZero: (self ensureFixupAt: eventualTarget).
			 self CmpCq: (boolean = objectMemory falseObject
							ifTrue: [objectMemory trueObject - objectMemory falseObject]
							ifFalse: [objectMemory falseObject - objectMemory trueObject])
				R: reg.
			 ok := self JumpZero: 0].
	"Restore simStack after the merges in ensureFixupAt: above."
	self restoreSimStackFromScratch.
	reg ~= TempReg ifTrue:
		[self MoveR: reg R: TempReg].
	self ssFlushTo: simStackPtr.
	"In the RegisterAllocatingCogit we map to an interpreter frame in ceSendMustBeBooleanTo:interpretingAtDelta:"
	self genCallMustBeBooleanFor: boolean.
	"NOTREACHED"
	ok jmpTarget: (self annotateBytecode: self Label).
	self restoreSimStackFromScratch.
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> genJumpTo: targetBytecodePC [
	"Overriden to avoid the flush because in this cogit stack state is merged at merge point."
	| eventualTarget generator fixup |
	self moveVolatileSimStackEntriesToRegisters.
	eventualTarget := self eventualTargetOf: targetBytecodePC.
	(eventualTarget > bytecodePC
	 and: [self stackTopIsBoolean
	 and: [(generator := self generatorForPC: eventualTarget) isConditionalBranch]])
		ifTrue:
			[eventualTarget := eventualTarget
							  + generator numBytes
							  + (generator isBranchTrue == (self ssTop constant = objectMemory trueObject)
									ifTrue: [self spanFor: generator at: eventualTarget exts: 0 in: methodObj]
									ifFalse: [0]).
			self ssPop: 1.
			fixup := self ensureFixupAt: eventualTarget.
			self ssPop: -1]
		ifFalse:
			[fixup := self ensureFixupAt: eventualTarget].
	deadCode := true. "can't fall through"
	self Jump: fixup.
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> genMarshalledSend: selectorIndex numArgs: numArgs sendTable: sendTable [
	self flushLiveRegistersForSend.
	^super genMarshalledSend: selectorIndex numArgs: numArgs sendTable: sendTable
]

{ #category : #initialization }
RegisterAllocatingCogit >> genMustBeBooleanLongTrampolineFor: boolean called: trampolineName [
	<inline: true>
	^self genMustBeBooleanTrampolineFor: boolean branchBytes: 2 called: trampolineName
]

{ #category : #initialization }
RegisterAllocatingCogit >> genMustBeBooleanTrampolineFor: boolean branchBytes: branchBytes called: trampolineName [
	<var: #trampolineName type: #'char *'>
	"For RegisterAllocatingCogit we want the address following a conditional branch not to be reachable, so we
	 don't have to generate code to reload registers.  Instead simply convert to an interpreter frame."
	<inline: false>
	self zeroOpcodeIndex.
	"If the objectRepresentation does want true & false to be mobile then we need to record these addresses."
	self assert: (objectRepresentation shouldAnnotateObjectReference: boolean) not.
	self AddCq: boolean R: TempReg.
	^self genTrampolineFor: #ceSendMustBeBooleanTo:interpretingAtDelta:
		called: trampolineName
		numArgs: 2
		arg: TempReg
		arg: (self trampolineArgConstant: branchBytes)
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: true
		resultReg: NoReg
		appendOpcodes: true
]

{ #category : #initialization }
RegisterAllocatingCogit >> genMustBeBooleanTrampolineFor: boolean called: trampolineName [
	<inline: true>
	^self genMustBeBooleanTrampolineFor: boolean branchBytes: 1 called: trampolineName
]

{ #category : #'bytecode generators' }
RegisterAllocatingCogit >> genPushReceiverBytecode [
	^self ssPushDesc: self ssSelfDescriptor
]

{ #category : #'bytecode generators' }
RegisterAllocatingCogit >> genSpecialSelectorArithmetic [
	| primDescriptor rcvrIsConst argIsConst rcvrIsInt argIsInt rcvrInt argInt destReg
	 jumpNotSmallInts jumpContinue jumpOverflow index rcvrReg argReg regMask |
	<var: #jumpOverflow type: #'AbstractInstruction *'>
	<var: #jumpContinue type: #'AbstractInstruction *'>
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #jumpNotSmallInts type: #'AbstractInstruction *'>
	primDescriptor := self generatorAt: byte0.
	argIsInt := (argIsConst := self ssTop type = SSConstant)
				 and: [objectMemory isIntegerObject: (argInt := self ssTop constant)].
	rcvrIsInt := ((rcvrIsConst := (self ssValue: 1) type = SSConstant)
				  and: [objectMemory isIntegerObject: (rcvrInt := (self ssValue: 1) constant)])
				or: [self mclassIsSmallInteger and: [(self ssValue: 1) isSameEntryAs: self simSelf]].

	(argIsInt and: [rcvrIsInt and: [rcvrIsConst]]) ifTrue:
		[| result |
		 rcvrInt := objectMemory integerValueOf: rcvrInt.
		 argInt := objectMemory integerValueOf: argInt.
		 primDescriptor opcode caseOf: {
			[AddRR]	-> [result := rcvrInt + argInt].
			[SubRR]	-> [result := rcvrInt - argInt].
			[AndRR]	-> [result := rcvrInt bitAnd: argInt].
			[OrRR]		-> [result := rcvrInt bitOr: argInt] }.
		(objectMemory isIntegerValue: result) ifTrue:
			["Must annotate the bytecode for correct pc mapping."
			^self ssPop: 2; ssPushAnnotatedConstant: (objectMemory integerObjectOf: result)].
		^self genSpecialSelectorSend].

	"If there's any constant involved other than a SmallInteger don't attempt to inline."
	((rcvrIsConst and: [rcvrIsInt not])
	 or: [argIsConst and: [argIsInt not]]) ifTrue:
		[^self genSpecialSelectorSend].

	"If we know nothing about the types then better not to inline as the inline cache and
	 primitive code is not terribly slow so wasting time on duplicating tag tests is pointless."
	(argIsInt or: [rcvrIsInt]) ifFalse:
		[^self genSpecialSelectorSend].

	"Since one or other of the arguments is an integer we can very likely profit from inlining.
	 But if the other type is not SmallInteger or if the operation overflows then we will need
	 to do a send.  Since we're allocating values in registers we would like to keep those
	 registers live on the inlined path and reload registers along the non-inlined send path.
	 See reconcileRegisterStateForJoinAfterSpecialSelectorSend below."
	argIsInt
		ifTrue:
			[rcvrReg := self allocateRegForStackEntryAt: 1.
			 (self ssValue: 1) popToReg: rcvrReg.
			 regMask := self registerMaskFor: rcvrReg]
		ifFalse:
			[self allocateRegForStackTopTwoEntriesInto: [:rTop :rNext| argReg := rTop. rcvrReg := rNext].
			 self ssTop popToReg: argReg.
			 (self ssValue: 1) popToReg: rcvrReg.
			 regMask := self registerMaskFor: rcvrReg and: argReg].

	"rcvrReg can be reused for the result iff the receiver is a constant or is an SSRegister that is not used elsewhere."
	destReg := ((rcvrIsInt and: [rcvrIsConst])
				 or: [(self ssValue: 1) type = SSRegister
					 and: [(self anyReferencesToRegister: rcvrReg inAllButTopNItems: 2) not]])
					ifTrue: [rcvrReg]
					ifFalse: [self allocateRegNotConflictingWith: regMask].
	self ssPop: 2.
	jumpNotSmallInts := (rcvrIsInt and: [argIsInt]) ifFalse:
							[argIsInt
								ifTrue: [objectRepresentation genJumpNotSmallInteger: rcvrReg]
								ifFalse:
									[rcvrIsInt
										ifTrue: [objectRepresentation genJumpNotSmallInteger: argReg]
										ifFalse: [objectRepresentation genJumpNotSmallIntegersIn: rcvrReg and: argReg scratch: TempReg]]].
	rcvrReg ~= destReg ifTrue:
		[self MoveR: rcvrReg R: destReg].
	primDescriptor opcode caseOf: {
		[AddRR] -> [argIsInt
						ifTrue:
							[self AddCq: argInt - ConstZero R: destReg.
							 jumpContinue := self JumpNoOverflow: 0.
							 "overflow; must undo the damage before doing send"
							 rcvrReg = destReg ifTrue:
								[self SubbCq: argInt - ConstZero R: rcvrReg]]
						ifFalse:
							[objectRepresentation genRemoveSmallIntegerTagsInScratchReg: destReg.
							 self AddR: argReg R: destReg.
							 jumpContinue := self JumpNoOverflow: 0.
							"overflow; must undo the damage before doing send"
							 destReg = rcvrReg ifTrue:
								[(rcvrIsInt and: [rcvrIsConst])
									ifTrue: [self MoveCq: rcvrInt R: rcvrReg]
									ifFalse:
										[self SubbR: argReg R: rcvrReg.
										 objectRepresentation genSetSmallIntegerTagsIn: rcvrReg]]]].
		[SubRR] -> [argIsInt
						ifTrue:
							[self SubCq: argInt - ConstZero R: destReg.
							 jumpContinue := self JumpNoOverflow: 0.
							 "overflow; must undo the damage before doing send"
							 rcvrReg = destReg ifTrue:
								[self AddcCq: argInt - ConstZero R: rcvrReg]]
						ifFalse:
							[(self anyReferencesToRegister: argReg inAllButTopNItems: 0)
								ifTrue: "argReg is live; cannot strip tags and continue on no overflow without restoring tags"
									[objectRepresentation genRemoveSmallIntegerTagsInScratchReg: argReg.
									 self SubR: argReg R: destReg.
									 jumpOverflow := self JumpOverflow: 0.
									 "no overflow; must undo the damage before continuing"
									 objectRepresentation genSetSmallIntegerTagsIn: argReg.
									 jumpContinue := self Jump: 0.
									 jumpOverflow jmpTarget: self Label.
									 "overflow; must undo the damage before doing send"
									 ((rcvrIsInt and: [rcvrIsConst]) or: [destReg ~= rcvrReg]) ifFalse:
										[self AddcR: argReg R: destReg].
									 objectRepresentation genSetSmallIntegerTagsIn: argReg]
								ifFalse:
									[objectRepresentation genRemoveSmallIntegerTagsInScratchReg: argReg.
									 self SubR: argReg R: destReg.
									 jumpContinue := self JumpNoOverflow: 0.
									 "overflow; must undo the damage before doing send"
									 ((rcvrIsInt and: [rcvrIsConst]) or: [destReg ~= rcvrReg]) ifFalse:
										[self AddcR: argReg R: rcvrReg].
									 objectRepresentation genSetSmallIntegerTagsIn: argReg]]].
		[AndRR] -> [argIsInt
						ifTrue: [self AndCq: argInt R: destReg]
						ifFalse: [self AndR: argReg R: destReg].
					jumpContinue := jumpNotSmallInts ifNotNil: [self Jump: 0]].
		[OrRR]	-> [argIsInt
						ifTrue: [self OrCq: argInt R: destReg]
						ifFalse: [self OrR: argReg R: destReg].
					jumpContinue := jumpNotSmallInts ifNotNil: [self Jump: 0]] }.
	jumpNotSmallInts
		ifNil: [jumpContinue ifNil: "overflow cannot happen"
				[self annotateInstructionForBytecode.
				 self ssPushRegister: destReg.
				 ^0]]
		ifNotNil:
			[jumpNotSmallInts jmpTarget: self Label].
	self ssPushRegister: destReg.
	self copySimStackToScratch: simSpillBase.
	self ssPop: 1.
	self ssFlushTo: simStackPtr.
	rcvrReg = Arg0Reg
		ifTrue:
			[argReg = ReceiverResultReg
				ifTrue: [self SwapR: Arg0Reg R: Arg0Reg Scratch: TempReg. argReg := Arg0Reg]
				ifFalse: [self MoveR: rcvrReg R: ReceiverResultReg].
			 rcvrReg := ReceiverResultReg].
	argIsInt
		ifTrue: [self MoveCq: argInt R: Arg0Reg]
		ifFalse: [argReg ~= Arg0Reg ifTrue: [self MoveR: argReg R: Arg0Reg]].
	rcvrReg ~= ReceiverResultReg ifTrue: [self MoveR: rcvrReg R: ReceiverResultReg].
	index := byte0 - self firstSpecialSelectorBytecodeOffset.
	self genMarshalledSend: index negated - 1 numArgs: 1 sendTable: ordinarySendTrampolines.
	self reconcileRegisterStateForJoinAfterSpecialSelectorSend.
	jumpContinue jmpTarget: self Label.
	^0
]

{ #category : #'bytecode generators' }
RegisterAllocatingCogit >> genSpecialSelectorClass [
	| topReg destReg scratchReg |
	topReg := self allocateRegForStackEntryAt: 0.
	destReg := self allocateRegNotConflictingWith: (self registerMaskFor: topReg).
	scratchReg := self allocateRegNotConflictingWith: (self registerMaskFor: topReg and: destReg).
	self ssTop popToReg: topReg.
	self asserta: (objectRepresentation
					genGetClassObjectOf: topReg
					into: destReg
					scratchReg: scratchReg
					instRegIsReceiver: false) ~= BadRegisterSet.
	self ssPop: 1; ssPushRegister: destReg.
	^0
]

{ #category : #'bytecode generators' }
RegisterAllocatingCogit >> genSpecialSelectorComparison [
	| nextPC postBranchPC targetPC primDescriptor branchDescriptor
	  rcvrIsInt rcvrIsConst argIsIntConst argInt jumpNotSmallInts inlineCAB index rcvrReg argReg branchToTarget needMergeToContinue needMergeToTarget |
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	<var: #jumpNotSmallInts type: #'AbstractInstruction *'>
	primDescriptor := self generatorAt: byte0.
	argIsIntConst := self ssTop type = SSConstant
				 and: [objectMemory isIntegerObject: (argInt := self ssTop constant)].
	rcvrIsInt := ((rcvrIsConst := (self ssValue: 1) type = SSConstant)
				  and: [objectMemory isIntegerObject: (self ssValue: 1) constant])
				or: [self mclassIsSmallInteger and: [(self ssValue: 1) isSameEntryAs: self simSelf]].

	(argIsIntConst and: [rcvrIsInt and: [rcvrIsConst]]) ifTrue:
		[^self genStaticallyResolvedSpecialSelectorComparison].

	self extractMaybeBranchDescriptorInto: [ :descr :next :postBranch :target | 
		branchDescriptor := descr. nextPC := next. postBranchPC := postBranch. targetPC := target ].

	"Only interested in inlining if followed by a conditional branch."
	inlineCAB := branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse].
	"Further, only interested in inlining = and ~= if there's a SmallInteger constant involved.
	 The relational operators successfully statically predict SmallIntegers; the equality operators do not."
	(inlineCAB and: [primDescriptor opcode = JumpZero or: [primDescriptor opcode = JumpNonZero]]) ifTrue:
		[inlineCAB := argIsIntConst or: [rcvrIsInt]].
	inlineCAB ifFalse:
		[^self genSpecialSelectorSend].

	"In-line the comparison and the jump, but if the types are not SmallInteger then we will need
	 to do a send and fall through to the following conditional branch.  Since we're allocating values
	 in registers we would like to keep those registers live on the inlined path and reload registers
	 along the non-inlined send path.  The merge logic at the branch destinations handles this."
	argIsIntConst
		ifTrue:
			[rcvrReg := self allocateRegForStackEntryAt: 1.
			 (self ssValue: 1) popToReg: rcvrReg.
			 argReg := NoReg]
		ifFalse:
			[self allocateRegForStackTopTwoEntriesInto: [:rTop :rNext| argReg := rTop. rcvrReg := rNext].
			 self ssTop popToReg: argReg.
			 (self ssValue: 1) popToReg: rcvrReg].
	self ssPop: 2.
	self moveVolatileSimStackEntriesToRegistersPreserving:
		(self allocatedRegisters bitOr: (argReg = NoReg
										ifTrue: [self registerMaskFor: rcvrReg]
										ifFalse: [self registerMaskFor: rcvrReg and: argReg])).

	jumpNotSmallInts := (rcvrIsInt and: [argIsIntConst]) ifFalse:
							[argIsIntConst
								ifTrue: [objectRepresentation genJumpNotSmallInteger: rcvrReg]
								ifFalse:
									[rcvrIsInt
										ifTrue: [objectRepresentation genJumpNotSmallInteger: argReg]
										ifFalse: [objectRepresentation genJumpNotSmallIntegersIn: rcvrReg and: argReg scratch: TempReg]]].
	argIsIntConst
		ifTrue: [self CmpCq: argInt R: rcvrReg]
		ifFalse: [self CmpR: argReg R: rcvrReg].

	"self printSimStack; printSimStack: (self fixupAt: postBranchPC) mergeSimStack; printSimStack: (self fixupAt: targetPC) mergeSimStack"
	"If there are merges to be performed on the forward branches we have to execute
	 the merge code only along the path requiring that merge, and exactly once."
	needMergeToTarget := self mergeRequiredForJumpTo: targetPC.
	needMergeToContinue := self mergeRequiredForJumpTo: postBranchPC.
	"Cmp is weird/backwards so invert the comparison."
	(needMergeToTarget and: [needMergeToContinue]) ifTrue:
		[branchToTarget := self genConditionalBranch: (branchDescriptor isBranchTrue
										ifTrue: [primDescriptor opcode]
										ifFalse: [self inverseBranchFor: primDescriptor opcode])
								operand: 0.
		 self Jump: (self ensureFixupAt: postBranchPC).
		 branchToTarget jmpTarget: self Label.
		 self Jump: (self ensureFixupAt: targetPC)].
	(needMergeToTarget and: [needMergeToContinue not]) ifTrue:
		[self genConditionalBranch: (branchDescriptor isBranchFalse
										ifTrue: [primDescriptor opcode]
										ifFalse: [self inverseBranchFor: primDescriptor opcode])
			operand: (self ensureFixupAt: postBranchPC) asUnsignedInteger.
		 self Jump: (self ensureFixupAt: targetPC)].
	(needMergeToTarget not and: [needMergeToContinue]) ifTrue:
		[self genConditionalBranch: (branchDescriptor isBranchTrue
										ifTrue: [primDescriptor opcode]
										ifFalse: [self inverseBranchFor: primDescriptor opcode])
			operand: (self ensureFixupAt: targetPC) asUnsignedInteger.
		 self Jump: (self ensureFixupAt: postBranchPC)].
	(needMergeToTarget or: [needMergeToContinue]) ifFalse:
		[self genConditionalBranch: (branchDescriptor isBranchTrue
										ifTrue: [primDescriptor opcode]
										ifFalse: [self inverseBranchFor: primDescriptor opcode])
			operand: (self ensureFixupAt: targetPC) asUnsignedInteger.
		 self Jump: (self ensureFixupAt: postBranchPC)].
	jumpNotSmallInts ifNil:
		[self annotateInstructionForBytecode.
		 deadCode := true.
		 ^0].
	jumpNotSmallInts jmpTarget: self Label.
	self ssFlushTo: simStackPtr.
	rcvrReg = Arg0Reg
		ifTrue:
			[argReg = ReceiverResultReg
				ifTrue: [self SwapR: Arg0Reg R: Arg0Reg Scratch: TempReg. argReg := Arg0Reg]
				ifFalse: [self MoveR: rcvrReg R: ReceiverResultReg].
			 rcvrReg := ReceiverResultReg].
	argIsIntConst
		ifTrue: [self MoveCq: argInt R: Arg0Reg]
		ifFalse: [argReg ~= Arg0Reg ifTrue: [self MoveR: argReg R: Arg0Reg]].
	rcvrReg ~= ReceiverResultReg ifTrue: [self MoveR: rcvrReg R: ReceiverResultReg].
	index := byte0 - self firstSpecialSelectorBytecodeOffset.
	^self genMarshalledSend: index negated - 1 numArgs: 1 sendTable: ordinarySendTrampolines
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> genStorePop: popBoolean TemporaryVariable: tempIndex [
	<inline: false>
	| top targetTemp srcRegOrNone destReg |
	self deny: self duplicateRegisterAssignmentsInTemporaries.
	self ssFlushUpThroughTemporaryVariable: tempIndex.
	"To avoid a stall writing through destReg, remember srcReg before the potential ssPop: 1 in ssStorePop:toReg:"
	top := self ssTop.
	targetTemp := self simStackAt: tempIndex + 1.
	srcRegOrNone := top registerOrNone.
	"Take care to avoid duplicating registers in different temps and/or self."
	destReg := targetTemp liveRegister.
	destReg = NoReg ifTrue:
		[destReg := self availableRegOrNoneNotConflictingWith: (self registerMaskUndesirableForTempVars bitOr: self liveRegisters)].
	destReg = NoReg ifTrue:
		[destReg := TempReg].
	self deny: srcRegOrNone = destReg.
	srcRegOrNone = NoReg
		ifTrue: "Avoid duplicating destReg into top; this would only be ok if top
				is the same entry as the target, which is not worth optimizing."
			[self ssStorePopNoAssign: popBoolean toReg: destReg]
		ifFalse:
			[self ssStorePop: popBoolean toReg: destReg].
	(destReg ~= TempReg and: [targetTemp liveRegister = NoReg]) ifTrue:
		[targetTemp liveRegister: destReg.
		 self copyLiveRegisterToCopiesOf: targetTemp].
	self MoveR: (srcRegOrNone ~= NoReg ifTrue: [srcRegOrNone] ifFalse: [destReg])
		Mw: (self frameOffsetOfTemporary: tempIndex)
		r: FPReg.
	targetTemp bcptr: bytecodePC. "for debugging"
	self deny: self duplicateRegisterAssignmentsInTemporaries.
	^0
]

{ #category : #'bytecode generators' }
RegisterAllocatingCogit >> genVanillaInlinedIdenticalOrNotIf: orNot [
	| nextPC postBranchPC targetBytecodePC branchDescriptor
	  rcvrReg argReg argIsConstant rcvrIsConstant  |
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	
	self extractMaybeBranchDescriptorInto: [ :descr :next :postBranch :target | 
		branchDescriptor := descr. nextPC := next. postBranchPC := postBranch. targetBytecodePC := target ].
	
	argIsConstant := self ssTop type = SSConstant.
	"They can't be both constants to use correct machine opcodes.
	 However annotable constants can't be resolved statically, hence we need to careful."
	rcvrIsConstant := argIsConstant not and: [(self ssValue: 1) type = SSConstant].
	
	self 
		allocateEqualsEqualsRegistersArgNeedsReg: argIsConstant not 
		rcvrNeedsReg: rcvrIsConstant not 
		into: [ :rcvr :arg | rcvrReg:= rcvr. argReg := arg ].
	
	"If not followed by a branch, resolve to true or false."
	(branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse]) ifFalse:
		[^ self 
			genIdenticalNoBranchArgIsConstant: argIsConstant 
			rcvrIsConstant: rcvrIsConstant 
			argReg: argReg 
			rcvrReg: rcvrReg 
			orNotIf: orNot].
	
	self ssPop: 2.
	self moveVolatileSimStackEntriesToRegistersPreserving:
		(self allocatedRegisters bitOr: (argReg = NoReg
										ifTrue: [self registerMaskFor: rcvrReg]
										ifFalse: [self registerMaskFor: rcvrReg and: argReg])).

	self genCmpArgIsConstant: argIsConstant rcvrIsConstant: rcvrIsConstant argReg: argReg rcvrReg: rcvrReg.

	"For now just deny we're in the situation we have yet to implement ;-)"
	self deny: (self mergeRequiredForJumpTo: targetBytecodePC).
	self deny: (self mergeRequiredForJumpTo: postBranchPC).

	"Further since there is a following conditional jump bytecode, define
	 non-merge fixups and leave the cond bytecode to set the mergeness."
	(self fixupAt: nextPC) notAFixup
		ifTrue: "The next instruction is dead.  we can skip it."
			[deadCode := true.
		 	 self ensureFixupAt: targetBytecodePC.
			 self ensureFixupAt: postBranchPC]
		ifFalse:
			[self deny: deadCode]. "push dummy value below"
		
	self genConditionalBranch: (orNot == branchDescriptor isBranchTrue ifTrue: [JumpNonZero] ifFalse: [JumpZero])
		operand: (self ensureNonMergeFixupAt: targetBytecodePC) asUnsignedInteger.

	"If the branch is dead, then we can just fall through postBranchPC (only a nop in-between), else 
	we need to jump over the code of the branch"
	deadCode ifFalse:
		[self Jump: (self ensureNonMergeFixupAt: postBranchPC).
		 "duplicate the merge fixup's top of stack so as to avoid a false confict."
		 self ssPushDesc: ((self fixupAt: nextPC) mergeSimStack at: simStackPtr + 1)].

	^0
]

{ #category : #initialization }
RegisterAllocatingCogit >> generateRunTimeTrampolines [
	"Generate the run-time entries at the base of the native code zone and update the base."
	
	ceSendMustBeBooleanAddFalseLongTrampoline := self genMustBeBooleanLongTrampolineFor: objectMemory falseObject
														called: 'ceSendMustBeBooleanAddFalseTrampoline'.
	ceSendMustBeBooleanAddTrueLongTrampoline := self genMustBeBooleanLongTrampolineFor: objectMemory trueObject
														called: 'ceSendMustBeBooleanAddTrueTrampoline'.
	super generateRunTimeTrampolines
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> initSimStackForFramefulMethod: startpc [
	super initSimStackForFramefulMethod: startpc.
	0 to: simStackPtr do:
		[:i| (self simStackAt: i) liveRegister: NoReg]
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> initSimStackForFramelessBlock: startpc [
	super initSimStackForFramelessBlock: startpc.
	self simSelf liveRegister: ReceiverResultReg.
	1 to: simStackPtr do:
		[:i| (self simStackAt: i) liveRegister: NoReg]
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> initSimStackForFramelessMethod: startpc [
	super initSimStackForFramelessMethod: startpc.
	0 to: simStackPtr do:
		[:i| | desc |
		desc := self simStackAt: i.
		desc liveRegister: (desc type = SSRegister ifTrue: [desc register] ifFalse: [NoReg])]
]

{ #category : #initialization }
RegisterAllocatingCogit >> initializeCodeZoneFrom: startAddress upTo: endAddress [
	scratchSimStack := self cCode: [self malloc: self simStackSlots * (self sizeof: CogSimStackEntry)]
							inSmalltalk: [CArrayAccessor on: ((1 to: self simStackSlots) collect: [:ign| CogRegisterAllocatingSimStackEntry new])].
	super initializeCodeZoneFrom: startAddress upTo: endAddress
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> isAPowerOfTwo: anInteger [ 
	<inline: true>
	^(anInteger bitAnd: anInteger - 1) = 0
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> liveRegisters [
	| regsSet |
	needsFrame
		ifTrue: [regsSet := 0]
		ifFalse:
			[regsSet := (methodOrBlockNumArgs > self numRegArgs
						  or: [methodOrBlockNumArgs = 0])
							ifTrue:
								[self registerMaskFor: ReceiverResultReg]
							ifFalse:
								[(self numRegArgs > 1 and: [methodOrBlockNumArgs > 1])
									ifFalse: [self registerMaskFor: ReceiverResultReg and: Arg0Reg]
									ifTrue: [self registerMaskFor: ReceiverResultReg and: Arg0Reg and: Arg1Reg]]].
	0 to: simStackPtr do:
		[:i|
		regsSet := regsSet bitOr: (self simStackAt: i) registerMask].
	^regsSet
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> liveRegistersExceptingTopNItems: n in: aSimStack [
	<var: 'aSimStack' type: #'SimStackEntry *'>
	^self liveRegistersFrom: 0 to: simStackPtr - n in: aSimStack
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> liveRegistersFrom: low to: high in: aSimStack [
	<var: 'aSimStack' type: #'SimStackEntry *'>
	<inline: true>
	| regsSet |
	regsSet := 0.
	low to: high do:
		[:i|
		regsSet := regsSet bitOr: (self simStack: aSimStack at: i) registerMask].
	^regsSet
]

{ #category : #debugging }
RegisterAllocatingCogit >> liveRegistersInSelfAndTemps [
	^self liveRegistersFrom: 0 to: methodOrBlockNumTemps in: simStack
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> maybeCountFixup: descriptor [
	"Count needed fixups; descriptor is known to be a branch or a block creation."
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<inline: true>
	numFixups := numFixups + ((descriptor isBranchTrue or: [descriptor isBranchFalse])
									ifTrue: [2]
									ifFalse: [1])
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> maybeInitNumFixups [
	<inline: true>
	numFixups := 0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> mergeCurrentSimStackWith: fixup [
	"At a merge point the cogit expects the stack to be in the same state as fixup's mergeSimStack.
	 mergeSimStack is the state as of some jump forward or backward to this point.  So make
	 simStack agree with mergeSimStack (it is, um, problematic to plant code at the jump). Values
	 may have to be assigned to registers.  Registers may have to be swapped.
	 Generate code to merge the current simStack with that of the target fixup, the goal being to
	 keep as many registers live as possible."
	"self printSimStack; printSimStack: fixup mergeSimStack"
	"self simStackPrintString-> fixup simStackPrintString"
	"abstractOpcodes object copyFrom: startIndex to: opcodeIndex"
	<var: #fixup type: #'BytecodeFixup *'>
	| currentRegisters targetRegisters mergeSimStack current target spillOffset them |
	(mergeSimStack := fixup mergeSimStack) ifNil: [^self].
	self cCode: '' inSmalltalk: [them := {self simStackPrintString. fixup simStackPrintString}].
	self assert: simStackPtr = fixup simStackPtr.
	currentRegisters := self liveRegistersFrom: 0 to: simStackPtr in: simStack.
	targetRegisters := self liveRegistersFrom: 0 to: simStackPtr in: mergeSimStack.
	self resolveConflicts: (currentRegisters bitAnd: targetRegisters) with: fixup mergeSimStack to: fixup simStackPtr.
	self assert: (self conflictsResolvedBetweenSimStackAnd: mergeSimStack).
	(self pushForMergeWith: mergeSimStack)
		ifTrue:
			[0 to: simStackPtr do:
				[:i|
				 spillOffset := i > methodOrBlockNumTemps
									ifTrue: [self frameOffsetOfTemporary: i - 1]
									ifFalse: [0].
				 ((current := self simStack: simStack at: i)
					reconcileWith: (target := self simStack: mergeSimStack at: i)
					spillOffset: spillOffset
					onSpillOrUnspill:
						[:targetReg|
						 self deny: current spilled.
						 self assert: spillOffset ~= 0.
						 current ensureSpilledAt: spillOffset from: FPReg.
						 simSpillBase <= i ifTrue:
							[simSpillBase := i + 1]]) ifTrue:
					[| targetReg |
					 (i > methodOrBlockNumTemps and: [(targetReg := target registerOrNone) ~= NoReg]) ifTrue:
						[self deassignRegister: targetReg in: simStack.
						 self deassignRegister: targetReg in: mergeSimStack.
						 self deny: (self register: targetReg isInMask: self liveRegistersInSelfAndTemps)]]]]
		ifFalse:
			[simStackPtr to: 0 by: -1 do:
				[:i|
				 spillOffset := i > methodOrBlockNumTemps
									ifTrue: [self frameOffsetOfTemporary: i - 1]
									ifFalse: [0].
				 ((current := self simStack: simStack at: i)
					reconcileWith: (target := self simStack: mergeSimStack at: i)
					spillOffset: spillOffset
					onSpillOrUnspill:
						[:targetReg|
						 self assert: current spilled.
						 self assert: spillOffset ~= 0.
						 targetReg  ~= NoReg
							ifTrue: [self PopR: targetReg]
							ifFalse: [self AddCq: objectRepresentation wordSize R: SPReg].
						 current spilled: false.
						 simSpillBase > i ifTrue:
							[simSpillBase := i]]) ifTrue:
					[| targetReg |
					 (i > methodOrBlockNumTemps and: [(targetReg := target registerOrNone) ~= NoReg]) ifTrue:
						[self deassignRegister: targetReg in: simStack.
						 self deassignRegister: targetReg in: mergeSimStack.
						 self deny: (self register: targetReg isInMask: self liveRegistersInSelfAndTemps)]]]].
	self updateSimSpillBase
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> mergeRequiredForJumpTo: targetPC [
	"While this is a multi-pass compiler, no intermediate control-flow graph is built from bytecode and
	 there is a monotonically increasing one-to-one relationship between bytecode pcs and machine
	 code pcs that map to one another.  Therefore, when jumping forward, any required code to merge
	 the state of the current simStack with that at the target must be generated before the jump
	 (because at the target the simStack state will be whatever falls through). If only one forward jump
	 to the target exists then that jump can simply install its simStack as the required simStack at the
	 target and the merge code wil be generated just before the target as control falls through.  But if
	 there are two or more forward jumps to the target, a situation that occurs given that the
	 StackToRegisterMappingCogit follows jump chains, then jumps other than the first must generate
	 merge code before jumping.  This poses a problem for conditional branches.  The merge code must
	 only be generated along the path that takes the jump  Therefore this must *not* be generated:

			... merge code ...
			jump cond Ltarget

	 which incorrectly executes the merge code along both the taken and untaken paths.  Instead
	 this must be generated so that the merge code is only executed if the branch is taken.

			jump not cond Lcontinue
			... merge code ...
			jump Ltarget
		Lcontinue:

	 Note that no merge code is required for code such as self at: (expr ifTrue: [1] ifFalse: [2])
		17 <70> self
		18 <71> pushConstant: true
		19 <99> jumpFalse: 22
		20 <76> pushConstant: 1
		21 <90> jumpTo: 23
		22 <77> pushConstant: 2
		23 <C0> send: at:
	 provided that 1 and 2 are assigned to the same target register."
	| fixup |
	(fixup := self fixupAt: targetPC) hasMergeSimStack ifFalse:
		[^false].
	self assert: (simStackPtr = fixup simStackPtr or: [fixup isBackwardBranchFixup]).
	^self mergeRequiredToTarget: fixup mergeSimStack
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> mergeRequiredToTarget: targetSimStack [
	<var: 'targetSimStack' type: #'SimStackEntry *'>
	<inline: true>
	<var: 'here' type: #'SimStackEntry *'>
	<var: 'there' type: #'SimStackEntry *'>
	simStackPtr to: 0 by: -1 do:
		[:i| | here there |
		 here := self simStack: simStack at: i.
		 there := self simStack: targetSimStack at: i.
		 (here isMergedWithTargetEntry: there) ifFalse:
			[^true]].
	^false
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> mergeWithFixupIfRequired: fixup [
	"If this bytecode has a fixup, some kind of merge needs to be done. There are 4 cases:
		1) the bytecode has no fixup (fixup isNotAFixup)
			do nothing
		2) the bytecode has a non merge fixup
			the fixup has needsNonMergeFixup.
			The code generating non merge fixup (currently only special selector code) is responsible
				for the merge so no need to do it.
			We set deadCode to false as the instruction can be reached from jumps.
		3) the bytecode has a merge fixup, but execution flow *cannot* fall through to the merge point.
			the fixup has needsMergeFixup and deadCode = true.
			ignores the current simStack as it does not mean anything 
			restores the simStack to the state the jumps to the merge point expects it to be.
		4) the bytecode has a merge fixup and execution flow *can* fall through to the merge point.
			the fixup has needsMergeFixup and deadCode = false.
			Merge the state into the fixup's state via mergeCurrentSimStackWith:forwards:.
			
	In addition, if this is a backjump merge point, we patch the fixup to hold the current simStackPtr 
	for later assertions. self printSimStack: fixup mergeSimStack"

	<var: #fixup type: #'BytecodeFixup *'>
	deadCode ifFalse:
		[self assertCorrectSimStackPtr].

	"case 1"
	fixup notAFixup ifTrue:
		[^0].

	"case 2"
	fixup isNonMergeFixup ifTrue:
		[deadCode
			ifTrue:
				[self deny: fixup simStackPtr isNil.
				 simStackPtr := fixup simStackPtr.
				 self restoreSimStackAtMergePoint: fixup.
				 deadCode := false.
				 self assertCorrectSimStackPtr]
			ifFalse:
				[self flushRegistersOnlyLiveOnFallThrough: fixup].
		 ^0].

	"cases 3 and 4"
	self assert: fixup isMergeFixup.
	self traceMerge: fixup.
	deadCode 
		ifTrue: "case 3"
			[(fixup isBackwardBranchFixup and: [fixup mergeSimStack isNil]) "e.g. a loop within false ifTrue: []"
				ifTrue: [self assert: fixup simStackPtr isNil]
				ifFalse:
					[simStackPtr := fixup simStackPtr.
					 self restoreSimStackAtMergePoint: fixup.
					 deadCode := false]]
		ifFalse: "case 4"
			[(fixup isBackwardBranchFixup and: [compilationPass > 1])
				ifTrue:
					[fixup simStackPtr: simStackPtr.
					 self mergeCurrentSimStackWith: fixup.
					 self copySimStackToFixup: fixup]
				ifFalse:
					[self mergeCurrentSimStackWith: fixup]].
	"cases 3 and 4"
	fixup isBackwardBranchFixup ifTrue:
		[fixup mergeSimStack ifNil:
			[self assert: compilationPass = 1.
			 self setMergeSimStackOf: fixup]].
	fixup targetInstruction: self Label.
	self assertCorrectSimStackPtr.
	self assert: (self simStackMergeCompatibleWith: fixup).
	"self simStackPrintString, fixup simStackPrintString"
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> moveVolatileSimStackEntriesToRegisters [
	<inline: true>
	self moveVolatileSimStackEntriesToRegistersPreserving: self allocatedRegisters
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> moveVolatileSimStackEntriesToRegistersPreserving: registerSet [
	"When jumping forward to a merge point the stack must be reconcilable with the state that falls through to the merge point.
	 We cannot easily arrange that later we add code to the branch, e.g. to spill values.  Instead, any volatile contents must be
	 moved to registers.
		[In fact, that's not exactly true, consider these two code sequences:
							self at: (expr ifTrue: [1] ifFalse: [2]) put: a
							self at: 1 put: (expr ifTrue: [a] ifFalse: [b])
						 The first one needs 1 saving to a register to reconcile with 2.
						 The second one has 1 on both paths, but we're not clever enough to spot this case yet.
		 First of all, if the constant requires an annotation then it is difficult to deal with.  But if the constant
		 does not require an annotation one way would be for a SimStackEntry for an SSConstant to refer to
		 the loading instruction and then at the merge simply change the loading instruction to a Label if the
		 constant is the same on both branches].
	 Volatile contents are anything not spilled to the stack, because as yet we can only merge registers."
	<inline: true>
	| allocatedRegs |
	<var: #desc type: #'SimStackEntry *'>
	allocatedRegs := registerSet.
	self assert: simSpillBase >= 0.
	simSpillBase to: simStackPtr do: 
		[:i| | desc reg |
		 desc := self simStackAt: i.
		 desc spilled
			ifTrue: [simSpillBase := i]
			ifFalse:
				[desc registerOrNone = NoReg ifTrue:
					[reg := self allocateRegNotConflictingWith: allocatedRegs.
					 reg = NoReg
						ifTrue: [self halt] "have to spill"
						ifFalse:
							[desc storeToReg: reg.
							 allocatedRegs := allocatedRegs bitOr: (self registerMaskFor: reg)]]]].
	self deny: self duplicateRegisterAssignmentsInTemporaries
]

{ #category : #accessing }
RegisterAllocatingCogit >> needsFrame [
	"for asserts"
	<cmacro: '() needsFrame'>
	^needsFrame
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> pushForMergeWith: mergeSimStack [
	"Answer if values must be pushed from simStack to merge with mergeSimStack, otherwise < 0 (the default)."
	<var: #mergeSimStack type: #'SimStackEntry *'>
	<inline: true>
	simStackPtr to: methodOrBlockNumTemps + 1 by: -1 do:
		[:i|
		 (self simStack: mergeSimStack at: i) spilled ~= (self simStack: simStack at: i) spilled ifTrue:
			[^(self simStack: mergeSimStack at: i) spilled]].
	^false
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> putSelfInReceiverResultReg [
	"Override to force copying the register to duplicates on stack."
	<inline: true>
	| simSelfHasRegister |
	simSelfHasRegister := self simSelf liveRegister ~= NoReg.
	super putSelfInReceiverResultReg.
	simSelfHasRegister ifTrue:
		[self simSelf liveRegister: ReceiverResultReg.
		 self copyLiveRegisterToCopiesOf: self simSelf]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> receiverRefOnScratchSimStack [

	self assert: scratchSpillBase >= 0.
	simStackPtr to: scratchSpillBase by: -1 do:
		[:i|
		 ((self simStack: scratchSimStack at: i) register = ReceiverResultReg
		  and: [(self simStack: scratchSimStack at: i) type = SSBaseOffset]) ifTrue:
			[^true]].
	^false
]

{ #category : #testing }
RegisterAllocatingCogit >> receiverResultRegIsAssignedToSelfAndNothingElse [
	| culprit |
	0 to: simStackPtr do:
		[:i|
		 (self simSelf isSameEntryAs: (self simStackAt: i))
		 ~= ((self simStackAt: i) liveRegister = ReceiverResultReg) ifTrue:
			[culprit := i.
			 ^false]].
	^true
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> reconcileRegisterStateForJoinAfterSpecialSelectorSend [
	"When the control flow from the inlined special selector code (e.g. add or comparison)
	 joins the control flow from the send, taken when the inlined code fails, we should decide
	 whether to reload any registers known to contain useful values or mark them as dead."
	 
	"Restore the simStack to that in scratchSimStack,
	 popping any spilled state back into allocated registers."
	| current spillOffset target |
	simSpillBase := scratchSpillBase.
	simStackPtr to: 0 by: -1 do:
		[:i|
		 spillOffset := i > methodOrBlockNumTemps
							ifTrue: [self frameOffsetOfTemporary: i - 1]
							ifFalse: [0].
		 (current := self simStack: simStack at: i)
			reconcileWith: (target := self simStack: scratchSimStack at: i)
			spillOffset: spillOffset
			onSpillOrUnspill:
				[:targetReg|
				 self assert: current spilled.
				 self assert: spillOffset ~= 0.
				 targetReg  ~= NoReg
					ifTrue: [self PopR: targetReg]
					ifFalse: [self AddCq: objectRepresentation wordSize R: SPReg]].
		 simStack
			at: i
			put: (self
					cCode: [scratchSimStack at: i]
					inSmalltalk: [(scratchSimStack at: i) copy])]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> registerMaskUndesirableForTempVars [
	"Answer the mask containing registers to avoid for temporary variables."
	<inline: true>
	^self registerMaskFor: ReceiverResultReg and: ClassReg and: SendNumArgsReg and: TempReg
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> reinitializeAllButBackwardFixupsFrom: start through: end [
	"When a method must be recompiled due to moving a loop's register
	 assignments to the head of a loop, backward fixups must be marked
	 as such, and all but backward fixups must be reinitialized."
	| descriptor nExts pc distance targetPC |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	pc := start.
	nExts := 0.
	[pc <= end] whileTrue:
		[byte0 := (objectMemory fetchByte: pc ofObject: methodObj) + bytecodeSetOffset.
		 descriptor := self generatorAt: byte0.
		 (descriptor isBranch
		  and: [self isBackwardBranch: descriptor at: pc exts: nExts in: methodObj]) ifTrue:
			[distance := self spanFor: descriptor at: pc exts: nExts in: methodObj.
			 targetPC := pc + descriptor numBytes + distance.
			 self initializeFixupAt: targetPC].
		 descriptor isBlockCreation
			ifTrue:
				[distance := self spanFor: descriptor at: pc exts: nExts in: methodObj.
				 pc := pc + descriptor numBytes + distance]
			ifFalse: [pc := pc + descriptor numBytes].
		 nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0]].
	start to: end do:
		[:i| | fixup |
		 fixup := self fixupAt: i.
		 (fixup notAFixup or: [fixup isBackwardBranchFixup]) ifFalse:
			[fixup reinitialize]]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> reinitializeOpcodesFrom: start to: end [
	<inline: true>
	start to: end do:
		[:i|
		(self abstractInstructionAt: i) reinitializeOpcode]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> resetSimStack: startPC [
	<inline: true>
	simSpillBase := methodOrBlockNumTemps + 1.
	simStackPtr := methodOrBlockNumTemps.
	0 to: simStackPtr do:
		[:i|
		(self simStackAt: i) liveRegister: NoReg.
		self cCode: '' inSmalltalk: [(self simStackAt: i) bcptr: startPC]]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> resolveConflicts: registersInCommon with: mergeSimStack to: simStackPtr [
	"registersInCommon is the register mask of registers in use in both the current
	 simStack and the target mergeSimStack. Swap any and all conflicting register uses
	 in registersInCommon, until register uses in simStack agree with mergeSimStack."
	| registerExchanges registerLocations agreements visited initialIndex initialStack |
	"registerLocations records where a register has moved to
	 during an exchange. This allows a single pass of the stack
	 to rename registers, instead of 1/2 N^2; max stack ~ 56"
	<var: 'registerExchanges' declareC: 'int registerExchanges[NumRegisters]'>
	<var: 'registerLocations' declareC: 'int registerLocations[NumRegisters]'>
	self deny: self duplicateRegisterAssignmentsInTemporaries.
	registersInCommon = (self registerMaskFor: FPReg) ifTrue:
		[self assert: (self conflictsResolvedBetweenSimStackAnd: mergeSimStack).
		 ^self].
	self cCode: '' inSmalltalk:
		[registerExchanges := CArrayAccessor on: (Array new: NumRegisters).
		 registerLocations := CArrayAccessor on: (Array new: NumRegisters)].
	0 to: NumRegisters - 1 do:
		[:i| registerExchanges at: i put: i].
	self cCode: '' inSmalltalk:
		[initialIndex := opcodeIndex. initialStack := self simStackPrintString]. "for debugging"
	agreements := visited := 0.
	0 to: simStackPtr do:
		[:i| | currentReg targetReg |
		currentReg := (self simStackAt: i) registerOrNone.
		targetReg := (self simStack: mergeSimStack at: i) registerOrNone.
		(currentReg ~= NoReg
		 and: [targetReg ~= NoReg]) ifTrue:
			[currentReg := registerExchanges at: currentReg.
			 currentReg = targetReg
				ifTrue:
					[(self register: currentReg isInMask: visited) ifFalse:
						[visited := visited bitOr: (self registerMaskFor: currentReg).
						 agreements := agreements bitOr: (self registerMaskFor: currentReg)]]
				ifFalse:
					[((self register: currentReg isInMask: registersInCommon)
					  and: [self register: currentReg isNotInMask: (visited bitOr: agreements)]) ifTrue:
						[| this that |
						 visited := visited bitOr: (self registerMaskFor: currentReg and: targetReg).
						 self SwapR: targetReg R: currentReg Scratch: RISCTempReg.
						 this := registerExchanges at: currentReg.
						 that := registerExchanges at: targetReg.
						 registerExchanges
							at: currentReg put: that;
							at: targetReg put: this]]]].
	(visited := visited bitClear: agreements) = 0 ifTrue:
		[self assert: (self conflictsResolvedBetweenSimStackAnd: mergeSimStack).
		 ^self].
	0 to: NumRegisters - 1 do:
		[:i| registerLocations at: (registerExchanges at: i) put: i].
	0 to: simStackPtr do:
		[:i| | ssEntry reg |
		ssEntry := self simStackAt: i.
		reg := ssEntry registerOrNone.
		(reg ~= NoReg
		 and: [(self register: reg isInMask: registersInCommon)
		 and: [reg ~= (self simStack: mergeSimStack at: i) registerOrNone]]) ifTrue:
			[ssEntry type = SSRegister
				ifTrue: [ssEntry register: (registerLocations at: reg)]
				ifFalse: [ssEntry liveRegister: (registerLocations at: reg)]]].
	self deny: self duplicateRegisterAssignmentsInTemporaries.
	self assert: (self conflictsResolvedBetweenSimStackAnd: mergeSimStack)
	"(initialIndex to: opcodeIndex - 1) collect: [:x| abstractOpcodes at: x]"
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> restoreSimStackAtMergePoint: fixup [
	<inline: true>
	"All the execution paths reaching a merge point expect everything to be spilled
	 on stack and the optStatus is unknown.  If the merge point follows a return, it
	 isn't a merge, but a skip past a return.  If it is a real merge point then throw
	 away all simStack optimization state."

	fixup mergeSimStack ifNotNil:
		[simSpillBase := methodOrBlockNumTemps + 1.
		 0 to: simStackPtr do:
			[:i|
			self cCode: [simStack at: i put: (fixup mergeSimStack at: i)]
				inSmalltalk: [(simStack at: i) copyFrom: (fixup mergeSimStack at: i)]].
		 self updateSimSpillBase].
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> restoreSimStackFromScratch [
	<inline: true>
	self cCode: [self memcpy: simStack _: scratchSimStack _: self simStackSlots * (self sizeof: CogSimStackEntry)]
		inSmalltalk: [0 to: simStackPtr do:
						[:i|
						simStack at: i put: (scratchSimStack at: i) copy]].
	simSpillBase := scratchSpillBase
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> setMergeSimStackOf: fixup [
	<var: #fixup type: #'BytecodeFixup *'>
	fixup mergeSimStack
		ifNil:
			[self assert: nextFixup <= numFixups.
			 self cCode: [fixup mergeSimStack: mergeSimStacksBase + (nextFixup * self simStackSlots * (self sizeof: CogSimStackEntry))].
			 nextFixup := nextFixup + 1]
		ifNotNil:
			[self assert: fixup simStackPtr = simStackPtr.
			 0 to: simStackPtr do:
				[:i|
				self assert: ((self simStackAt: i) isSameEntryAs: (self addressOf: (fixup mergeSimStack at: i))).
				(self simStackAt: i) liveRegister ~= (self addressOf: (fixup mergeSimStack at: i)) liveRegister ifTrue:
					[(self simStackAt: i) liveRegister: NoReg]]].
	fixup simStackPtr: simStackPtr.
	self cCode: [self memcpy: fixup mergeSimStack _: simStack _: self simStackSlots * (self sizeof: CogSimStackEntry)]
		inSmalltalk: [fixup mergeSimStack: self copySimStack]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> simSelfOnStackInReceiverResultReg [
	"For assert checking only."
	methodOrBlockNumTemps + 1 to: simStackPtr do:
		[:i|
		 ((self simSelf isSameEntryAs: (self simStackAt: i))
		  and: [(self simStackAt: i) registerOrNone = ReceiverResultReg]) ifTrue:
			[^true]].
	^false
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> simStack: stack at: index [
	<cmacro: '(stack,index) ((stack) + (index))'>
	<returnTypeC: #'SimStackEntry *'>
	^self addressOf: (stack at: index)
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> simStack: aSimStack isIdenticalTo: bSimStack [
	<var: 'aSimStack' type: #'SimStackEntry *'>
	<var: 'bSimStack' type: #'SimStackEntry *'>
	0 to: simStackPtr do:
		[:i|
		((self simStack: aSimStack at: i) isIdenticalEntryAs: (self simStack: bSimStack at: i)) ifFalse:
			[^false]].
	^true
]

{ #category : #initialization }
RegisterAllocatingCogit >> simStackEntryClass [
	<doNotGenerate>
	^CogRegisterAllocatingSimStackEntry
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> simStackMergeCompatibleWith: fixup [
	simStackPtr = fixup simStackPtr ifFalse:
		[^false].
	simStackPtr to: 0 by: -1 do:
		[:i| | target current |
		target := self simStack: fixup mergeSimStack at: i.
		current := self simStack: simStack at: i.
		(target isSameEntryAs: current) ifFalse:
			[^current type caseOf: {
				[SSBaseOffset]	-> [(current offset = (self frameOffsetOfTemporary: i - 1)
									and: [current register = FPReg])
										ifTrue: [true] "current has been spilled virtually"
										ifFalse:
											[target type caseOf: {
												[SSBaseOffset]	-> [false].
												[SSSpill]		-> [false].
												[SSConstant]	-> [false].
												[SSRegister]	-> [false] }]].
				[SSSpill]		-> [target type caseOf: {
										[SSBaseOffset]	-> [true].
										[SSSpill]		-> [true].
										[SSConstant]	-> [true].
										[SSRegister]	-> [true] }].
				[SSConstant]	-> [target type caseOf: {
										[SSBaseOffset]	-> [false].
										[SSSpill]		-> [false].
										[SSConstant]	-> [current constant = target constant].
										[SSRegister]	-> [false] }].
				[SSRegister]	-> [target type caseOf: {
										[SSBaseOffset]	-> [current register = target liveRegister].
										[SSSpill]		-> [current register = target liveRegister].
										[SSConstant]	-> [current register = target liveRegister].
										[SSRegister]	-> [current register = target register] }] }]].
	^true
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> simStackSameAs: fixup [ 
	"There are no register conflicts between simStack and mergeSimStack if
	 traversing both stacks from hot end (simStackPtr) to cold end (0) no register
	 exists in simStack that has previously existed in mergeSimStack.  This is because
	 the resolution assigns values from simStack to registers in mergeSimStack and so
	 must not assign to a register yet to be read."
	 | |
	simStackPtr = fixup simStackPtr ifFalse:
		[^false].
	simStackPtr to: 0 by: -1 do:
		[:i| | target |
		target := self simStack: fixup mergeSimStack at: i.
		(target isSameEntryAs: (self simStack: simStack at: i)) ifFalse:
			[^false]].
	^true
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssAllocateRequiredRegMask: requiredRegsMask upThrough: stackPtr [
	"Override to void any required registers in temp vars."
	0 to: methodOrBlockNumTemps do:
		[:i|
		((self simStackAt: i) registerMask anyMask: requiredRegsMask) ifTrue:
			[(self simStackAt: i) liveRegister: NoReg]].
	super ssAllocateRequiredRegMask: requiredRegsMask upThrough: stackPtr
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssEntriesDo: aBlock [
	"Evaluate aBlock with all simStackEntries"
	<inline: true>
	0 to: simStackPtr do:
		[:i| aBlock value: (self simStackAt: i)]
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssEntrySuchThat: aBlock [
	"Answer the SimStackEntry for which aBlock answers true, or nil if none."
	<inline: true>
	0 to: simStackPtr do:
		[:i|
		(aBlock value: (self simStackAt: i)) ifTrue:
			[^self simStackAt: i]].
	^nil
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssFlushFrom: start upThrough: unaryBlock [
	"Any occurrences on the stack of the value being stored (which is the top of stack)
	 must be flushed, and hence any values colder than them stack."
	<inline: true>
	self assert: simSpillBase >= 0.
	start to: simSpillBase by: -1 do:
		[ :index |
		(unaryBlock value: (self simStackAt: index)) ifTrue: [ ^ self ssFlushTo: index ] ]
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssFlushFrom: start upThroughRegister: reg [
	"Any occurrences on the stack of the register must be
	 flushed, and hence any values colder than them stack."
	<var: #desc type: #'SimStackEntry *'>
	self ssFlushFrom: start upThrough: [ :desc | desc type = SSRegister and: [ desc register = reg ] ]
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssPushAnnotatedConstant: literal [
	super ssPushAnnotatedConstant: literal.
	self ssTop liveRegister: NoReg.
	^0
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssPushBase: reg offset: offset [
	super ssPushBase: reg offset: offset.
	self ssTop liveRegister: NoReg.
	^0
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssPushConstant: literal [
	super ssPushConstant: literal.
	self ssTop liveRegister: NoReg.
	^0
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssPushRegister: reg [
	super ssPushRegister: reg.
	self ssTop liveRegister: NoReg.
	^0
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssStorePop: popBoolean toPreferredReg: preferredReg [
	"Store or pop the top simulated stack entry to a register.
	 Use preferredReg if the entry is not itself a register.
	 Answer the actual register the result ends up in."
	| actualReg liveRegisters |
	actualReg := preferredReg.
	self ssTop type = SSRegister ifTrue: 
		[self assert: (self ssTop liveRegister = NoReg
					  or: [self ssTop liveRegister = self ssTop register]).
		self assert: self ssTop spilled not.
		actualReg := self ssTop register].
	self ssTop liveRegister ~= NoReg ifTrue:
		[actualReg := self ssTop liveRegister].
	liveRegisters := self liveRegistersExceptingTopNItems: 1 in: simStack.
	(self register: actualReg isInMask: liveRegisters) ifTrue:
		[actualReg := self allocateRegNotConflictingWith: (self registerMaskFor: preferredReg).
		 actualReg = NoReg ifTrue:
			[actualReg := preferredReg]].
	self deny: (self register: actualReg isInMask: liveRegisters).
	self ssStorePop: popBoolean toReg: actualReg. "generates nothing if ssTop is already in actualReg"
	^actualReg
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssStorePopNoAssign: popBoolean toReg: reg [
	"Store or pop the top simulated stack entry to a register.
	 Do /not/ assign reg to ssTop.
	N.B.: popToReg: and storeToReg: does not generate anything if 
	it moves a register to the same register."	
	popBoolean
		ifTrue: [self ssTop popToRegNoAssign: reg.
				self ssPop: 1]
		ifFalse: [self ssTop storeToRegNoAssign: reg].
]

{ #category : #'simulation only' }
RegisterAllocatingCogit >> traceSimStack [
	<cmacro: '() 0'>
	(compilationTrace anyMask: 4) ifTrue:
		[self printSimStack]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> voidReceiverResultRegContainsSelf [
	"Used when ReceiverResultReg is allocated for other than simSelf, and
	 there may be references to ReceiverResultReg which need to be spilled."
	self receiverIsInReceiverResultReg ifFalse:
		[self deny: self simSelfOnStackInReceiverResultReg.
		 ^self].
	1 to: methodOrBlockNumTemps do:
		[:i|
		self deny: (self simStackAt: i) liveRegister = ReceiverResultReg].
	methodOrBlockNumTemps + 1 to: simStackPtr do:
		[:i|
		(self simSelf isSameEntryAs: (self simStackAt: i)) ifTrue:
			[(self simStackAt: i) liveRegister: NoReg]].
	self simSelf liveRegister: NoReg
]
