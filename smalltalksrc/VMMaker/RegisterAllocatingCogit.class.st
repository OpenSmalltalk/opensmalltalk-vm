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
		'scratchOptStatus',
		'ceSendMustBeBooleanAddTrueLongTrampoline',
		'ceSendMustBeBooleanAddFalseLongTrampoline',
		'recompileForLoopRegisterAssignments'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'C translation' }
RegisterAllocatingCogit class >> declareCVarsIn: aCodeGen [
	aCodeGen
		var: #scratchSimStack
			type: #'SimStackEntry *';
		var: #scratchOptStatus
			type: #CogSSOptStatus
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

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> assignToTempRegConflictingRegisterIn: conflictingRegisterMask [
	"Find the stackEntry in simStack whose liveRegister matches conflictingRegisterMask
	 and assign it to TempReg."
	self assert: (self isAPowerOfTwo: conflictingRegisterMask).
	0 to: simStackPtr do:
		[:i|
		 (self simStackAt: i) registerMaskOrNone = conflictingRegisterMask ifTrue:
			[(self simStackAt: i)
				storeToReg: TempReg;
				liveRegister: TempReg.
			 i+1 to: simStackPtr do:
				[:j|
				self deny: (self simStackAt: i) registerMaskOrNone = conflictingRegisterMask].
			 ^self]].
	self error: 'conflict entry not found'
]

{ #category : #'simulation only' }
RegisterAllocatingCogit >> bytecodeFixupClass [
	<doNotGenerate>
	^CogRASSBytecodeFixup
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> compileAbstractInstructionsFrom: start through: end [
	"Loop over bytecodes, dispatching to the generator for each bytecode, handling fixups in due course.
	 Override to provide a development-time only escape for failed merges due to partially implemented
	 parallel move.  Override to recompile after a loop requiring a merge is detected."
	^[| result initialOpcodeIndex initialCounterIndex initialIndexOfIRC |
	   compilationPass := 1.
	   initialOpcodeIndex := opcodeIndex.
	   initialCounterIndex := self maybeCounterIndex."for SistaCogit"
	   literalsManager saveForRecompile.
	   NewspeakVM ifTrue:
			[initialIndexOfIRC := indexOfIRC].
	   [recompileForLoopRegisterAssignments := false.
	    result := super compileAbstractInstructionsFrom: start through: end.
	    result = 0 and: [recompileForLoopRegisterAssignments]]
		whileTrue:
			[self assert: compilationPass <= 2.
			 self reinitializeAllButBackwardFixupsFrom: start through: end.
			 self resetSimStack: start.
			 self reinitializeOpcodesFrom: initialOpcodeIndex to: opcodeIndex - 1.
			 compilationPass := compilationPass + 1.
			 nextFixup := 0.
			 opcodeIndex := initialOpcodeIndex.
			 self maybeSetCounterIndex: initialCounterIndex. "For SistaCogit"
			 literalsManager resetForRecompile.
			 NewspeakVM ifTrue:
				[indexOfIRC := initialIndexOfIRC]].
	    result]
			on: Notification
			do: [:ex|
				ex tag == #failedMerge ifTrue:
					[coInterpreter transcript
						ensureCr; nextPutAll: 'FAILED MERGE IN ';
						nextPutAll: (coInterpreter nameOfClass: (coInterpreter methodClassOf: methodObj));
						nextPutAll: '>>#'; nextPutAll: (coInterpreter stringOf: (coInterpreter maybeSelectorOfMethod: methodObj));
						flush.
					 ^ShouldNotJIT].
				ex pass]
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
		mergeMask ~= currentMask ifTrue:
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
RegisterAllocatingCogit >> copySimStackToScratch: spillBase [
	<inline: true>
	self cCode: [self mem: scratchSimStack cp: simStack y: self simStackSlots * (self sizeof: CogSimStackEntry)]
		inSmalltalk: [0 to: simStackPtr do:
						[:i|
						scratchSimStack at: i put: (simStack at: i) copy]].
	scratchSpillBase := spillBase.
	scratchOptStatus := self cCode: [optStatus] inSmalltalk: [optStatus copy]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> deassignRegisterForTempVar: targetEntry in: mergeSimStack [
	"If merging a non-temp with a temp that has a live register we can assign
	 to the register, but must unassign the register from the temp, otherwise
	 the temp will acquire the merged value without an assignment.  The targetEntry
	 must also be transmogrified into an SSRegister entry, which is done in the caller."
	<var: #targetEntry type: #'SimStackEntry *'>
	<var: #duplicateEntry type: #'SimStackEntry *'>
	<var: #mergeSimStack type: #'SimStackEntry *'>
	<inline: true>
	| reg |
	reg := targetEntry liveRegister.
	self assert: (reg ~= NoReg and: [targetEntry type = SSConstant or: [targetEntry isFrameTempVar]]).
	targetEntry type = SSConstant
		ifTrue:
			[simStackPtr to: 0 by: -1 do:
				[:j| | duplicateEntry |
				 duplicateEntry := self simStack: mergeSimStack at: j.
				 (duplicateEntry registerOrNone = reg
				  and: [duplicateEntry type = SSBaseOffset or: [duplicateEntry type = SSSpill]]) ifTrue:
					[duplicateEntry liveRegister: NoReg]]]
		ifFalse:
			[simStackPtr to: 0 by: -1 do:
				[:j| | duplicateEntry |
				 duplicateEntry := self simStack: mergeSimStack at: j.
				 (targetEntry isSameEntryAs: duplicateEntry) ifTrue:
					[j < methodOrBlockNumTemps
						ifTrue: [duplicateEntry liveRegister: NoReg]
						ifFalse: [duplicateEntry type: SSRegister; register: reg]]]]
]

{ #category : #debugging }
RegisterAllocatingCogit >> duplicateRegisterAssignmentsInTemporaries [
	| liveRegisters |
	liveRegisters := 0.
	0 to: methodOrBlockNumTemps - 1 do:
		[:i| | liveRegister |
		liveRegister := (self simStackAt: i) liveRegister.
		liveRegister ~= NoReg ifTrue:
			[(self register: liveRegister isInMask: liveRegisters) ifTrue:
				[^true].
			 liveRegisters := liveRegisters bitOr: 1 << liveRegister]].
	^false
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> ensureFixupAt: targetPC [
	"Make sure there's a flagged fixup at the target pc in fixups.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction.
	 Override to enerate stack merging code if required."
	| fixup |	
	<var: #fixup type: #'BytecodeFixup *'>
	self assert: targetPC > bytecodePC.
	fixup := self fixupAt: targetPC.
	fixup needsFixup 
		ifTrue:
			[fixup mergeSimStack
				ifNil: [self setMergeSimStackOf: fixup]
				ifNotNil: [self mergeCurrentSimStackWith: fixup forwards: true]]
		ifFalse: 
			[self assert: (fixup mergeSimStack isNil or: [compilationPass = 2]).
			 self moveVolatileSimStackEntriesToRegisters.
			 fixup mergeSimStack
				ifNil: [self setMergeSimStackOf: fixup]
				ifNotNil: [self assert: (self simStack: simStack isIdenticalTo: fixup mergeSimStack)]].
	^super ensureFixupAt: targetPC
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> ensureNonMergeFixupAt: targetPC [
	"Make sure there's a flagged fixup at the target pc in fixups.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction.
	 Override to remember the simStack state at the target, if not already there."
	"self printSimStack; printSimStack: fixup mergeSimStack"
	| fixup |
	fixup := super ensureNonMergeFixupAt: targetPC.
	fixup mergeSimStack
		ifNil: [self setMergeSimStackOf: fixup]
		ifNotNil: [self assert: simStackPtr = fixup simStackPtr.
				self deny: (self mergeRequiredToTarget: fixup mergeSimStack)].
	optStatus isReceiverResultRegLive ifFalse:
		[fixup isReceiverResultRegSelf: false].
	^fixup
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> ensureReceiverResultRegContainsSelf [
	super ensureReceiverResultRegContainsSelf.
	methodOrBlockNumTemps to: simStackPtr do:
		[:i|
		((self addressOf: simSelf) isSameEntryAs: (self simStackAt: i))
			ifTrue: [(self simStackAt: i) liveRegister: ReceiverResultReg]
			ifFalse:
				[(self simStackAt: i) liveRegister = ReceiverResultReg ifTrue:
					[(self simStackAt: i) liveRegister: NoReg]]].
	simSelf liveRegister: ReceiverResultReg
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
		["self deny: (self mergeRequiredToTarget: target mergeSimStack)."
		 self assert: (target mergeSimStack isNil or: [self simStack: simStack isIdenticalTo: target mergeSimStack]).
		 ^self].
	(self mergeRequiredToTarget: target mergeSimStack) ifFalse:
		[^self].
	"Schedule a recompile and merge the end-of-loop assignments into the head of the loop,
	 giving priority to the assignments at this point, and preserving any other non-conflicting
	 assignments."
	recompileForLoopRegisterAssignments := true.
	conflictingRegsMask := self conflictingRegistersBetweenSimStackAnd: target mergeSimStack.
	self deny: (self register: FPReg isInMask: conflictingRegsMask).
	0 to: simStackPtr do:
		[:i| | currentEntry targetEntry |
		 currentEntry := self simStack: simStack at: i.
		 targetEntry := self simStack: target mergeSimStack at: i.
		 currentEntry liveRegister ~= NoReg
			ifTrue:
				[targetEntry liveRegister: currentEntry liveRegister]
			ifFalse:
				[(targetEntry registerMask anyMask: conflictingRegsMask) ifTrue:
					[targetEntry liveRegister: NoReg]]].
	optStatus isReceiverResultRegLive ifTrue:
		[target isReceiverResultRegSelf: true]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> existsInstVarRefBeforeSendOrReturn [
	"Answer if the current bytecode is followed by an inst var ref before the next full send."
	| pc nExts byte descriptor |
	pc := bytecodePC.
	nExts := 0.
	[pc <= endPC] whileTrue:
		[byte := (objectMemory fetchByte: pc ofObject: methodObj) + bytecodeSetOffset.
		 descriptor := self generatorAt: byte.
		 (descriptor isMapped
		  or: [descriptor isBranchTrue
		  or: [descriptor isBranchFalse
		  or: [descriptor spanFunction notNil]]]) ifTrue:
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
	self assert: simSelf type = SSBaseOffset.
	reg := simSelf liveRegister.
	(reg ~= NoReg and: [(self isCallerSavedReg: reg)]) ifTrue:
		[simSelf liveRegister: NoReg.
		 flushed := true].
	0 to: simStackPtr do:
		[:i|
		 self assert: (self simStackAt: i) type = (i < methodOrBlockNumTemps
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
	self assert: simSelf type = SSBaseOffset.
	simSelf liveRegister: NoReg.
	0 to: simStackPtr do:
		[:i|
		 self assert: ((self simStackAt: i) spilled
					 and: [(self simStackAt: i) type = SSConstant
						or: [((self simStackAt: i) type = SSBaseOffset
							or: [i >= methodOrBlockNumTemps
								and: [(self simStackAt: i) type = SSSpill]])
							 and: [(self simStackAt: i) register = FPReg
							 and: [(self simStackAt: i) offset = (self frameOffsetOfTemporary: i)]]]]).
		 (self simStackAt: i) liveRegister: NoReg]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> flushLiveRegistersForSuspensionPoint [
	"Flush any live registers for a C call at a suspension/resumption point, i.e.flush all registers.
	 Answer if any registers were flushed."
	<inline: true>
	| flushed |
	flushed := false.
	self assert: simSelf type = SSBaseOffset.
	simSelf liveRegister ~= NoReg ifTrue:
		[simSelf liveRegister: NoReg.
		 flushed := true].
	0 to: simStackPtr do:
		[:i|
		 self assert: (i < methodOrBlockNumTemps
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
	 Override so no assertion failure if no register can be allocated."
	<var: #desc type: #'CogSimStackEntry *'>
	| reg index |
	self assert: needsFrame.
	reg := NoReg.
	index := simSpillBase max: 0.
	[reg = NoReg and: [index < simStackPtr]] whileTrue: 
		[ | desc |
		 desc := self simStackAt: index.
		 desc type = SSRegister ifTrue:
			[(regMask anyMask: (self registerMaskFor: desc register)) ifFalse: 
				[reg := desc register]].
		 index := index + 1].
	reg ~= NoReg ifTrue:
		[self ssAllocateRequiredReg: reg].
	^reg
]

{ #category : #'trampoline support' }
RegisterAllocatingCogit >> genCallMustBeBooleanFor: boolean [
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

	retry := self Label.
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
				(any merge elided because register assignments copied to loop head in first pass)
				cmp stackLimit
				jumpAboveOrEqual target
				flush
				checkForInterrupts
				merge from flushed (N.B. If stack was flushed before loop we could conceivably jump to the pre-loop merge code)
				jmp target
	 self printSimStack; printSimStack: target mergeSimStack"
	self assert: targetPC < bytecodePC.
	target := self fixupAt: targetPC.
	self ensureRegisterAssignmentsAreAtHeadOfLoop: target.
	self MoveAw: coInterpreter stackLimitAddress R: TempReg.
	self CmpR: TempReg R: SPReg. "N.B. FLAGS := SPReg - TempReg"
	self JumpAboveOrEqual: target.

	self ssFlushTo: simStackPtr.
	self CallRT: ceCheckForInterruptTrampoline.
	self annotateBytecode: self Label.
	self flushLiveRegistersForSuspensionPoint.
	self mergeCurrentSimStackWith: target forwards: false.
	self Jump: target.
	deadCode := true. "can't fall through"
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> genJumpIf: boolean to: targetBytecodePC [
	<inline: false>
	| eventualTarget desc reg fixup ok mbb noMustBeBoolean |
	<var: #fixup type: #'BytecodeFixup *'>
	<var: #ok type: #'AbstractInstruction *'>
	<var: #desc type: #'CogSimStackEntry *'>
	<var: #mbb type: #'AbstractInstruction *'>
	eventualTarget := self eventualTargetOf: targetBytecodePC.
	desc := self ssTop.
	self ssPop: 1.

	noMustBeBoolean := self extASpecifiesNoMustBeBoolean.
	extA := 0.

	(desc type == SSConstant
	 and: [desc constant = objectMemory trueObject or: [desc constant = objectMemory falseObject]]) ifTrue:
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
			or: [(desc register = ReceiverResultReg and: [optStatus isReceiverResultRegLive])]])
				ifTrue: [TempReg]
				ifFalse: [desc register].
	desc popToReg: reg.
	"Cunning trick by LPD.  If true and false are contiguous subtract the smaller.
	 Correct result is either 0 or the distance between them.  If result is not 0 or
	 their distance send mustBeBoolean."
	self assert: (objectMemory objectAfter: objectMemory falseObject) = objectMemory trueObject.

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
			 noMustBeBoolean ifTrue: 
				[self JumpZero: (self ensureFixupAt: eventualTarget). "generates merge code"
				 ok jmpTarget: (self annotateBytecode: self lastOpcode).
				 ^0].
			 mbb := self JumpNonZero: 0.
			 self Jump: (self ensureFixupAt: eventualTarget). "generates merge code"
			 mbb jmpTarget: self Label]
		ifFalse:
			[self genSubConstant: boolean R: reg.
			 self JumpZero: (self ensureFixupAt: eventualTarget).
			 noMustBeBoolean ifTrue: 
				[self annotateBytecode: self lastOpcode.
				 ^0].
			 self CmpCq: (boolean = objectMemory falseObject
							ifTrue: [objectMemory trueObject - objectMemory falseObject]
							ifFalse: [objectMemory falseObject - objectMemory trueObject])
				R: reg.
			 ok := self JumpZero: 0].

	reg ~= TempReg ifTrue:
		[self MoveR: reg R: TempReg].
	self copySimStackToScratch: simSpillBase.
	self ssFlushTo: simStackPtr.
	self genCallMustBeBooleanFor: boolean.
	"NOTREACHED"
	ok jmpTarget: (self annotateBytecode: self Label).
	self restoreSimStackFromScratch.
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> genJumpTo: targetBytecodePC [
	"Overriden to avoid the flush because in this cogit stack state is merged at merge point."
	deadCode := true. "can't fall through"
	self Jump: (self ensureFixupAt: (self eventualTargetOf: targetBytecodePC)).
	^ 0
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
				or: [self mclassIsSmallInteger and: [(self ssValue: 1) isSameEntryAs: (self addressOf: simSelf)]].

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
								[self SubCq: argInt - ConstZero R: rcvrReg]]
						ifFalse:
							[objectRepresentation genRemoveSmallIntegerTagsInScratchReg: destReg.
							 self AddR: argReg R: destReg.
							 jumpContinue := self JumpNoOverflow: 0.
							"overflow; must undo the damage before doing send"
							 destReg = rcvrReg ifTrue:
								[(rcvrIsInt and: [rcvrIsConst])
									ifTrue: [self MoveCq: rcvrInt R: rcvrReg]
									ifFalse:
										[self SubR: argReg R: rcvrReg.
										 objectRepresentation genSetSmallIntegerTagsIn: rcvrReg]]]].
		[SubRR] -> [argIsInt
						ifTrue:
							[self SubCq: argInt - ConstZero R: destReg.
							 jumpContinue := self JumpNoOverflow: 0.
							 "overflow; must undo the damage before doing send"
							 rcvrReg = destReg ifTrue:
								[self AddCq: argInt - ConstZero R: rcvrReg]]
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
										[self AddR: argReg R: destReg].
									 objectRepresentation genSetSmallIntegerTagsIn: argReg]
								ifFalse:
									[objectRepresentation genRemoveSmallIntegerTagsInScratchReg: argReg.
									 self SubR: argReg R: destReg.
									 jumpContinue := self JumpNoOverflow: 0.
									 "overflow; must undo the damage before doing send"
									 ((rcvrIsInt and: [rcvrIsConst]) or: [destReg ~= rcvrReg]) ifFalse:
										[self AddR: argReg R: rcvrReg].
									 objectRepresentation genSetSmallIntegerTagsIn: argReg]]].
		[AndRR] -> [argIsInt
						ifTrue: [self AndCq: argInt R: destReg]
						ifFalse: [self AndR: argReg R: destReg].
					jumpContinue := self Jump: 0].
		[OrRR]	-> [argIsInt
						ifTrue: [self OrCq: argInt R: destReg]
						ifFalse: [self OrR: argReg R: destReg].
					jumpContinue := self Jump: 0] }.
	jumpNotSmallInts jmpTarget: self Label.
	self ssPushRegister: destReg.
	self copySimStackToScratch: (simSpillBase min: simStackPtr - 1).
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
				or: [self mclassIsSmallInteger and: [(self ssValue: 1) isSameEntryAs: (self addressOf: simSelf)]].

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
	| top srcRegOrNone destReg |
	self deny: self duplicateRegisterAssignmentsInTemporaries.
	self ssFlushUpThroughTemporaryVariable: tempIndex.
	"To avoid a stall writing through destReg, remember srcReg before the potential ssPop: 1 in ssStorePop:toReg:"
	top := self ssTop.
	srcRegOrNone := top registerOrNone.
	"ssStorePop:toPreferredReg: will allocate a register, and indeed may allocate ReceiverResultReg
	 if, for example, the ssEntry to be popped is already in ReceiverResultReg (as the result of a send).
	 ReceiverResultReg is not a good choice for a temporary variable; it has other uses.  So if the ssEntry
	 at top of stack has ReceiverResultReg as its live variable, try and allocate an alternative."
	destReg := (self simStackAt: tempIndex) liveRegister.
	destReg ~= NoReg
		ifTrue:
			[self ssStorePop: popBoolean toReg: destReg]
		ifFalse:
			[((top type = SSConstant
			    or: [srcRegOrNone = NoReg
			    or: [self register: srcRegOrNone isInMask: self registerMaskUndesirableForTempVars]])
			  and: [(destReg := self availableRegOrNoneNotConflictingWith: (self registerMaskUndesirableForTempVars bitOr: self liveRegisters)) ~= NoReg])
				ifTrue: [self ssStorePop: popBoolean toReg: destReg]
				ifFalse: [destReg := self ssStorePop: popBoolean toPreferredReg: TempReg].
			 "The ssStorePop: may end up assigning a register to ssTop, and if it is also a temp then a new
			  register must be found for the destination temp, sicne two temp vars can't share a register."
			 (top isFrameTempVar and: [top liveRegister = destReg]) ifTrue:
				[srcRegOrNone := destReg.
				 destReg := self availableRegOrNoneNotConflictingWith: (self registerMaskUndesirableForTempVars bitOr: self liveRegisters).
				 destReg ~= NoReg ifTrue:
					[self MoveR: srcRegOrNone R: destReg]].
			 (destReg ~= NoReg and: [destReg ~= TempReg]) ifTrue:
				[(self simStackAt: tempIndex) liveRegister: destReg.
				 self copyLiveRegisterToCopiesOf: (self simStackAt: tempIndex)]].
	self MoveR: (srcRegOrNone ~= NoReg ifTrue: [srcRegOrNone] ifFalse: [destReg])
		Mw: (self frameOffsetOfTemporary: tempIndex)
		r: FPReg.
	(self simStackAt: tempIndex) bcptr: bytecodePC. "for debugging"
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
	
	self genCmpArgIsConstant: argIsConstant rcvrIsConstant: rcvrIsConstant argReg: argReg rcvrReg: rcvrReg.
	self ssPop: 2.

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
	simSelf liveRegister: NoReg.
	0 to: simStackPtr do:
		[:i| (self simStackAt: i) liveRegister: NoReg]
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> initSimStackForFramelessBlock: startpc [
	super initSimStackForFramelessBlock: startpc.
	simSelf liveRegister: simSelf register.
	0 to: simStackPtr do:
		[:i| (self simStackAt: i) liveRegister: NoReg]
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> initSimStackForFramelessMethod: startpc [
	super initSimStackForFramelessMethod: startpc.
	simSelf liveRegister: NoReg.
	0 to: simStackPtr do:
		[:i| | desc |
		desc := self simStackAt: i.
		desc liveRegister: (desc type == SSRegister ifTrue: [desc register] ifFalse: [NoReg])]
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
	self assert: needsFrame.
	regsSet := 0.
	0 to: simStackPtr do:
		[:i|
		regsSet := regsSet bitOr: (self simStackAt: i) registerMask].
	LowcodeVM ifTrue:
		[(simNativeSpillBase max: 0) to: simNativeStackPtr do:
			[:i|
			regsSet := regsSet bitOr: (self simNativeStackAt: i) nativeRegisterMask]].
	^regsSet
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> liveRegistersExceptingTopNItems: n in: aSimStack [
	<var: 'aSimStack' type: #'SimStackEntry *'>
	| regsSet |
	regsSet := 0.
	0 to: simStackPtr - n do:
		[:i|
		regsSet := regsSet bitOr: (self simStack: aSimStack at: i) registerMask].
	LowcodeVM ifTrue:
		[self shouldBeImplemented.
		 (simNativeSpillBase max: 0) to: simNativeStackPtr - n do:
			[:i|
			regsSet := regsSet bitOr: (self simNativeStackAt: i) nativeRegisterMask]].
	^regsSet
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
RegisterAllocatingCogit >> mergeCurrentSimStackWith: fixup forwards: forwards [
	"At a merge point the cogit expects the stack to be in the same state as mergeSimStack.
	 mergeSimStack is the state as of some jump forward or backward to this point.  So make simStack agree
	 with mergeSimStack (it is, um, problematic to plant code at the jump).
	 Values may have to be assigned to registers.  Registers may have to be swapped.
	 The state of optStatus must agree.
	 Generate code to merge the current simStack with that of the target fixup,
	 the goal being to keep as many registers live as possible.  If the merge is forwards
	 registers can be deassigned (since registers are always written to temp vars).
	 But if backwards, nothing can be deassigned, and the state /must/ reflect the target."
	"self printSimStack; printSimStack: fixup mergeSimStack"
	"abstractOpcodes object copyFrom: startIndex to: opcodeIndex"
	<var: #fixup type: #'BytecodeFixup *'>
	| startIndex mergeSimStack currentEntry targetEntry writtenToRegisters |
	<var: #mergeSimStack type: #'SimStackEntry *'>
	<var: #targetEntry type: #'SimStackEntry *'>
	<var: #currentEntry type: #'SimStackEntry *'>
	(mergeSimStack := fixup mergeSimStack) ifNil: [^self].
	startIndex := opcodeIndex. "for debugging"
	"Assignments amongst the registers must be made in order to avoid overwriting.
	 If necessary exchange registers amongst simStack's entries to resolve any conflicts."
	self resolveRegisterOrderConflictsBetweenCurrentSimStackAnd: mergeSimStack.
	(self asserta: (self conflictsResolvedBetweenSimStackAnd: mergeSimStack)) ifFalse:
		[Notification new tag: #failedMerge; signal].
	"Compute written to registers.  Perhaps we should use 0 in place of methodOrBlockNumTemps
	 but Smalltalk does not assign to arguments."
	writtenToRegisters := 0.
	(self pushForMergeWith: mergeSimStack)
		ifTrue:
			[methodOrBlockNumTemps to: simStackPtr do:
				[:i|
				 currentEntry := self simStack: simStack at: i.
				 targetEntry := self simStack: mergeSimStack at: i.
				 writtenToRegisters := writtenToRegisters bitOr: targetEntry registerMask.
				 (currentEntry reconcileForwardsWith: targetEntry) ifTrue:
					[self assert: i >= methodOrBlockNumTemps.
					 self deassignRegisterForTempVar: targetEntry in: mergeSimStack.
					 targetEntry
						type: SSRegister;
						register: targetEntry liveRegister].
				 "Note, we could update the simStack and spillBase here but that is done in restoreSimStackAtMergePoint:
				 spilled ifFalse:
					[simSpillBase := i - 1].
				 simStack
					at: i
					put: (self
							cCode: [mergeSimStack at: i]
							inSmalltalk: [(mergeSimStack at: i) copy])"]]
		ifFalse:
			[simStackPtr to: methodOrBlockNumTemps by: -1 do:
				[:i|
				 currentEntry := self simStack: simStack at: i.
				 targetEntry := self simStack: mergeSimStack at: i.
				 writtenToRegisters := writtenToRegisters bitOr: targetEntry registerMask.
				 (currentEntry reconcileForwardsWith: targetEntry) ifTrue:
					[self assert: i >= methodOrBlockNumTemps.
					 self deassignRegisterForTempVar: targetEntry in: mergeSimStack.
					 targetEntry
						type: SSRegister;
						register: targetEntry liveRegister].
				 "Note, we could update the simStack and spillBase here but that is done in restoreSimStackAtMergePoint:
				 spilled ifFalse:
					[simSpillBase := i - 1].
				 simStack
					at: i
					put: (self
							cCode: [mergeSimStack at: i]
							inSmalltalk: [(mergeSimStack at: i) copy])"]].
	"Note that since we've deassigned any conflicts beyond the temps above we need only compare the temps here."
	methodOrBlockNumTemps - 1 to: 0 by: -1 do:
		[:i|
		 targetEntry := self simStack: mergeSimStack at: i.
		 (targetEntry registerMask noMask: writtenToRegisters) ifTrue:
			[currentEntry := self simStack: simStack at: i.
			 writtenToRegisters := writtenToRegisters bitOr: targetEntry registerMask.
			 (currentEntry reconcileForwardsWith: targetEntry) ifTrue:
				[self assert: i >= methodOrBlockNumArgs.
				 self deassignRegisterForTempVar: targetEntry in: mergeSimStack]]].
	optStatus isReceiverResultRegLive ifFalse:
		[forwards
			ifTrue: "a.k.a. fixup isReceiverResultRegSelf: (fixup isReceiverResultRegSelf and: [optStatus isReceiverResultRegLive])"
				[fixup isReceiverResultRegSelf: false]
			ifFalse:
				[fixup isReceiverResultRegSelf ifTrue:
					[self putSelfInReceiverResultReg]]]
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
	self assert: simStackPtr = fixup simStackPtr.
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
	self deny: self duplicateRegisterAssignmentsInTemporaries.

	"case 1"
	fixup notAFixup ifTrue: [^0].

	"case 2"
	fixup isNonMergeFixup ifTrue:
		[deadCode
			ifTrue:
				[self deny: fixup simStackPtr isNil.
				 simStackPtr := fixup simStackPtr.
				 self restoreSimStackAtMergePoint: fixup.
				 deadCode := false]
			ifFalse:
				[self flushRegistersOnlyLiveOnFallThrough: fixup].
		 ^0].

	"cases 3 and 4"
	self assert: fixup isMergeFixup.
	self traceMerge: fixup.
	deadCode 
		ifTrue: [simStackPtr := fixup simStackPtr] "case 3"
		ifFalse: [(fixup isBackwardBranchFixup and: [compilationPass > 1]) ifTrue:
					[fixup simStackPtr: simStackPtr].
				self mergeCurrentSimStackWith: fixup forwards: true]. "case 4"
	"cases 3 and 4"
	deadCode := false.
	fixup isBackwardBranchFixup ifTrue:
		[self assert: fixup mergeSimStack isNil == (compilationPass = 1).
		 fixup mergeSimStack ifNil:
			[self setMergeSimStackOf: fixup]].
	fixup targetInstruction: self Label.
	self assert: simStackPtr = fixup simStackPtr.
	self cCode: '' inSmalltalk:
		[self assert: fixup simStackPtr = (self debugStackPointerFor: bytecodePC)].
	self restoreSimStackAtMergePoint: fixup.
	
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> moveVolatileSimStackEntriesToRegisters [
	"When jumping forward to a merge point the stack must be reconcilable with the state that falls through to the merge point.
	 We cannot easily arrange that later we add code to the branch, e.g. to spill values.  Instead, any volatile contents must be
	 moved to registers.  [In fact, that's not exactly true, consider these two code sequences:
							self at: (expr ifTrue: [1] ifFalse: [2]) put: a
							self at: 1 put: (expr ifTrue: [a] ifFalse: [b])
						 The first one needs 1 saving to a register to reconcile with 2.
						 The second one has 1 on both paths, but we're not clever enough to spot this case yet.]
	 Volatile contents are anything not spilled to the stack, because as yet we can only merge registers."
	<inline: true>
	| allocatedRegs |
	<var: #desc type: #'SimStackEntry *'>
	allocatedRegs := self allocatedRegisters.
	(simSpillBase max: 0) to: simStackPtr do: 
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
	simStackPtr to: methodOrBlockNumTemps by: -1 do:
		[:i|
		 (self simStack: mergeSimStack at: i) spilled ~= (self simStack: simStack at: i) spilled ifTrue:
			[^(self simStack: mergeSimStack at: i) spilled]].
	^false
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> receiverRefOnScratchSimStack [
	simStackPtr to: (0 max: scratchSpillBase) by: -1 do:
		[:i|
		 ((self simStack: scratchSimStack at: i) register = ReceiverResultReg
		  and: [(self simStack: scratchSimStack at: i) type = SSBaseOffset]) ifTrue:
			[^true]].
	^false
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> reconcileRegisterStateForJoinAfterSpecialSelectorSend [
	"When the control flow from the inlined special selector code (e.g. add or comparison)
	 joins the control flow from the send, taken when the inlined code fails, we should decide
	 whether to reload any registers known to contain useful values or mark them as dead."
	 
	"If ReceiverResultReg is live along the inlined path, and is used before the next full send,
	 reload it on the uncommon path."
	scratchOptStatus isReceiverResultRegLive ifTrue:
		[(self existsInstVarRefBeforeSendOrReturn
		  or: [self receiverRefOnScratchSimStack])
			ifTrue:
				[optStatus isReceiverResultRegLive: true.
				 optStatus ssEntry storeToReg: ReceiverResultReg]
			ifFalse: [self voidReceiverOptStatus]].

	"Restore the simStack to that in scratchSimStack,
	 popping any spilled state back into allocated registers."
	simSpillBase := scratchSpillBase.
	simStackPtr to: 0 by: -1 do:
		[:i|
		 self assert: (i = simStackPtr
						ifTrue: [(self simStackAt: i) type = SSRegister]
						ifFalse: [(self simStackAt: i) spilled]).
		 (self simStackAt: i) reconcilePoppingWith: (self simStack: scratchSimStack at: i).
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
	<inline: true>
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
	simSpillBase := methodOrBlockNumTemps.
	simStackPtr := methodOrBlockNumTemps - 1.
	optStatus isReceiverResultRegLive: false.
	self flushLiveRegistersForSend.
	self cCode: '' inSmalltalk:
		[0 to: methodOrBlockNumTemps - 1 do:
			[:i|
			(self simStackAt: i) bcptr: startPC]]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> resolveRegisterOrderConflictsBetweenCurrentSimStackAnd: mergeSimStack [
	<var: #mergeSimStack type: #'SimStackEntry *'>
	"One simple algorithm is to spill everything if there are any conflicts and then pop back.
	 But this is terrible :-(  Can we do better? Yes... Consider the following two simStacks
		target:		0: | rA | __ | rB | rC | rD | <- sp
		current:	0: | __ | __ | rD | rA | rC | <- sp
	 If we were to assign in a naive order, 0 through sp rA would be overwritten before its value in current[3] is written to rC,
	 and rC would be overwritten before its value in current[4] is written to rD.  But if we swap the registers in current so that
	 they respect the reverse ordering in target we can assign directly:
		swap current[3] & current[4]
					0: | __ | __ | rD | rC | rA | <- sp
	 now do the assignment in the order target[0] := current[0],  target[1] := current[1], ...  target[4] := current[4],
	 i.e. rA := current[0]; rB := rD; (rC := rC); (rD := rD).

	 So find any conflicts, and if there are any, swap registers in the simStack to resolve them.
	 The trivial case of a single conflict is resolved by assigning that conflict to TempReg."
	| conflictingRegsMask |
	conflictingRegsMask := self conflictingRegistersBetweenSimStackAnd: mergeSimStack.
	conflictingRegsMask ~= 0 ifTrue:
		[(self isAPowerOfTwo: conflictingRegsMask) "Multiple conflicts mean we have to sort"
			ifFalse: [self swapCurrentRegistersInMask: conflictingRegsMask accordingToRegisterOrderIn: mergeSimStack]
			ifTrue: [self assignToTempRegConflictingRegisterIn: conflictingRegsMask]].
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> restoreSimStackAtMergePoint: fixup [
	<inline: true>
	"All the execution paths reaching a merge point expect everything to be spilled
	 on stack and the optStatus is unknown.  If the merge point follows a return, it
	 isn't a merge, but a skip past a return.  If it is a real merge point then throw
	 away all simStack and optStatus optimization state."
	simSelf liveRegister: ((optStatus isReceiverResultRegLive: fixup isReceiverResultRegSelf)
							ifTrue: [ReceiverResultReg]
							ifFalse: [NoReg]).
	fixup mergeSimStack ifNotNil:
		[simSpillBase := methodOrBlockNumTemps.
		 0 to: simStackPtr do:
			[:i|
			self cCode: [simStack at: i put: (fixup mergeSimStack at: i)]
				inSmalltalk: [(simStack at: i) copyFrom: (fixup mergeSimStack at: i)]]].
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> restoreSimStackFromScratch [
	<inline: true>
	self cCode: [self mem: simStack cp: scratchSimStack y: self simStackSlots * (self sizeof: CogSimStackEntry)]
		inSmalltalk: [0 to: simStackPtr do:
						[:i|
						simStack at: i put: (scratchSimStack at: i)]].
	simSpillBase := scratchSpillBase.
	optStatus := scratchOptStatus
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> setMergeSimStackOf: fixup [
	<var: #fixup type: #'BytecodeFixup *'>
	self moveVolatileSimStackEntriesToRegisters.
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
	fixup
		simStackPtr: simStackPtr;
		isReceiverResultRegSelf: optStatus isReceiverResultRegLive.
	self cCode: [self mem: fixup mergeSimStack cp: simStack y: self simStackSlots * (self sizeof: CogSimStackEntry)]
		inSmalltalk: [fixup mergeSimStack: self copySimStack]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> simSelfOnStackInReceiverResultReg [
	"For assert checking only."
	methodOrBlockNumTemps to: simStackPtr do:
		[:i|
		 (((self addressOf: simSelf) isSameEntryAs: (self simStackAt: i))
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

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssAllocateRequiredRegMask: requiredRegsMask upThrough: stackPtr upThroughNative: nativeStackPtr [
	"Override to void any required registers in temp vars."
	(requiredRegsMask anyMask: (self registerMaskFor: ReceiverResultReg)) ifTrue:
		[optStatus isReceiverResultRegLive: false.
		 optStatus ssEntry liveRegister: NoReg].
	0 to: methodOrBlockNumTemps - 1 do:
		[:i|
		((self simStackAt: i) registerMask anyMask: requiredRegsMask) ifTrue:
			[(self simStackAt: i) liveRegister: 0]].
	super ssAllocateRequiredRegMask: requiredRegsMask upThrough: stackPtr upThroughNative: nativeStackPtr
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssFlushFrom: start upThrough: unaryBlock [
	"Any occurrences on the stack of the value being stored (which is the top of stack)
	 must be flushed, and hence any values colder than them stack."
	<inline: true>
	start to: (simSpillBase max: 0) by: -1 do:
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

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> swapCurrentRegistersInMask: conflictingRegsMask accordingToRegisterOrderIn: mergeSimStack [
	<var: #mergeSimStack type: #'SimStackEntry *'>
	"Swap liveRegisters in simStack entries according to their order in mergeSimStack so as to avoid
	 overwriting live registers when merging simStack into mergeSimStack.  Consider the following two simStacks
		target:		0: | rA | __ | rB | rC | rD | <- sp
		current:	0: | __ | __ | rD | rA | rC | <- sp
	 If we were to assign in a naive order, 0 through sp rA would be overwritten before its value in current[3] is written to rC,
	 and rC would be overwritten before its value in current[4] is written to rD.  But if we swap the registers in current so that
	 they respect the reverse ordering in target we can assign directly:
		swap current[3] & current[4]
					0: | __ | __ | rD | rC | rA | <- sp
	 now do the assignment in the order target[0] := current[0],  target[1] := current[1], ...  target[4] := current[4],
	 i.e. rA := current[0]; rB := rD; (rC := rC); (rD := rD).

	 See https://hal.inria.fr/inria-00435844/file/article-hal.pdf
		Florent Bouchez, Quentin Colombet, Alain Darte, Christophe Guillon, Fabrice Rastello.
		Parallel Copy Motion. SCOPES, ACM, 2010, pp.0. <inria-00435844>

	 So find any conflicts, and if there are any, swap registers in the simStack to resolve them."

	"self printSimStack; printSimStack: mergeSimStack"

	"Some processors have a SwapRR but not all.  Write one-size-fits-all code that moves things through TempReg."
	| order n visitedMask ssEntry regA regB |
	<var: 'order' declareC: 'sqInt order[8*BytesPerWord]'>
	<var: 'ssEntry' type: #'SimStackEntry *'>
	self cCode: [self me: order ms: 0 et: (self sizeof: order)]
		inSmalltalk: [order := CArrayAccessor on: (Array new: 8*BytesPerWord withAll: 0)].
	n := 0.
	visitedMask := conflictingRegsMask.
	0 to: methodOrBlockNumTemps - 1 do:
		[:i|
		 ssEntry := self simStack: mergeSimStack at: i.
		(ssEntry registerMaskOrNone anyMask: visitedMask) ifTrue:
			[order at: ssEntry registerOrNone put: (n := n + 1).
			 visitedMask := visitedMask - ssEntry registerMaskOrNone]].
	self assert: n >= 1.
	n <= 2 ifTrue: "simple case; here to show me what I have to do in addition to the sort"
		[regA := conflictingRegsMask highBit - 1.
		 regB := (conflictingRegsMask - (1 << regA)) highBit - 1.
		 self SwapR: regA R: regB Scratch: TempReg.
		 0 to: simStackPtr do:
			[:i|
			 ssEntry := self simStack: simStack at: i.
			 (ssEntry registerMaskOrNone anyMask: conflictingRegsMask) ifTrue:
				[| reg |
				 reg := ssEntry registerOrNone = regA ifTrue: [regB] ifFalse: [regA].
				 ssEntry type = SSRegister ifTrue:
					[ssEntry register: reg].
				 ssEntry liveRegister: reg]].
		 ^self].

	self halt
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> voidReceiverOptStatus [
	"Used to mark ReceiverResultReg as dead or not containing simSelf.
	 Used when the simStack has already been flushed, e.g. for sends."
	<inline: true>
	super voidReceiverOptStatus.
	simSelf liveRegister: NoReg
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> voidReceiverResultRegContainsSelf [
	"Used when ReceiverResultReg is allocated for other than simSelf, and
	 there may be references to ReceiverResultReg which need to be spilled."
	self assert: (simSelf liveRegister = ReceiverResultReg) = optStatus isReceiverResultRegLive.
	optStatus isReceiverResultRegLive ifFalse:
		[self deny: self simSelfOnStackInReceiverResultReg.
		 ^self].
	optStatus isReceiverResultRegLive: false.
	methodOrBlockNumTemps to: simStackPtr do:
		[:i|
		((self addressOf: simSelf) isSameEntryAs: (self simStackAt: i)) ifTrue:
			[(self simStackAt: i) liveRegister: NoReg]].
	simSelf liveRegister: NoReg
]
