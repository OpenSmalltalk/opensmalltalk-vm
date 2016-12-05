"
RegisterAllocatingCogit is an optimizing code generator that is specialized in register allocation..

On the contrary to StackToRegisterMappingCogit, RegisterAllocatingCogit keeps at each control flow merge point the state of the simulated stack to merge into and not only an integer fixup. Each branch and jump record the current state of the simulated stack, and each fixup is responsible for merging this state into the saved simulated stack.

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
		'scratchOptStatus'
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
			 ^self]].
	self error: 'conflict entry not found'
]

{ #category : #'simulation only' }
RegisterAllocatingCogit >> bytecodeFixupClass [
	<doNotGenerate>
	^CogRASSBytecodeFixup
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
RegisterAllocatingCogit >> conflcitsResolvedBetweenSimStackAnd: mergeSimStack [ 
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
	 must also be transmogrified into an SSRegister entry."
	<var: #targetEntry type: #'SimStackEntry *'>
	<var: #mergeSimStack type: #'SimStackEntry *'>
	<inline: true>
	| reg |
	reg := targetEntry liveRegister.
	self assert: (targetEntry type = SSBaseOffset and: [targetEntry register = FPReg]).
	simStackPtr to: 0 by: -1 do:
		[:j| | duplicateEntry |
		 duplicateEntry := self simStack: mergeSimStack at: j.
		 (targetEntry isSameEntryAs: duplicateEntry) ifTrue:
			[duplicateEntry liveRegister: NoReg]].
	targetEntry
		type: SSRegister;
		register: reg
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> ensureFixupAt: targetIndex [
	| fixup |	
	<var: #fixup type: #'BytecodeFixup *'>
	fixup := self fixupAt: targetIndex.
	fixup needsFixup 
		ifTrue:
			[fixup mergeSimStack
				ifNil: [self setMergeSimStackOf: fixup]
				ifNotNil: [self mergeCurrentSimStackWith: fixup]]
		ifFalse: 
			[self assert: fixup mergeSimStack isNil.
			self moveVolatileSimStackEntriesToRegisters.
			self setMergeSimStackOf: fixup].
	^super ensureFixupAt: targetIndex
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> ensureNonMergeFixupAt: targetIndex [
	"Make sure there's a flagged fixup at the targetIndex (pc relative to first pc) in fixups.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction."
	| fixup |
	fixup := super ensureNonMergeFixupAt: targetIndex.
	fixup mergeSimStack ifNil: [self setMergeSimStackOf: fixup].
	^fixup
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> ensureReceiverResultRegContainsSelf [
	super ensureReceiverResultRegContainsSelf.
	methodOrBlockNumTemps to: simStackPtr do:
		[:i|
		(simSelf isSameEntryAs: (self simStackAt: i))
			ifTrue: [(self simStackAt: i) liveRegister: ReceiverResultReg]
			ifFalse:
				[(self simStackAt: i) liveRegister = ReceiverResultReg ifTrue:
					[(self simStackAt: i) liveRegister: NoReg]]].
	simSelf liveRegister: ReceiverResultReg
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
	<inline: true>
	| reg |
	self assert: simSelf type = SSBaseOffset.
	reg := simSelf liveRegister.
	(reg ~= NoReg and: [(self isCallerSavedReg: reg)]) ifTrue:
		[simSelf liveRegister: NoReg].
	0 to: simStackPtr do:
		[:i|
		 self assert: (self simStackAt: i) type = (i <= methodOrBlockNumTemps
													ifTrue: [SSBaseOffset]
													ifFalse: [SSSpill]).
		 reg := (self simStackAt: i) liveRegister.
		 (reg ~= NoReg and: [(self isCallerSavedReg: reg)]) ifTrue:
			[(self simStackAt: i) liveRegister: NoReg]]
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
								and: (self simStackAt: i) type = SSSpill])
							 and: [(self simStackAt: i) register = FPReg
							 and: [(self simStackAt: i) offset = (self frameOffsetOfTemporary: i)]]]]).
		 (self simStackAt: i) liveRegister: NoReg]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> frameOffsetOfLastTemp [
	^self frameOffsetOfTemporary: methodOrBlockNumTemps
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

{ #category : #'bytecode generators' }
RegisterAllocatingCogit >> genForwardersInlinedIdenticalOrNotIf: orNot [
	| nextPC branchDescriptor unforwardRcvr argReg targetBytecodePC
	unforwardArg  rcvrReg postBranchPC label fixup |
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	<var: #label type: #'AbstractInstruction *'>
	
	self extractMaybeBranchDescriptorInto: [ :descr :next :postBranch :target | 
		branchDescriptor := descr. nextPC := next. postBranchPC := postBranch. targetBytecodePC := target ].

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
		[^ self 
			genIdenticalNoBranchArgIsConstant: unforwardArg not
			rcvrIsConstant: unforwardRcvr not
			argReg: argReg 
			rcvrReg: rcvrReg 
			orNotIf: orNot].
	
	label := self Label.
	self genCmpArgIsConstant: unforwardArg not rcvrIsConstant: unforwardRcvr not argReg: argReg rcvrReg: rcvrReg.
	self ssPop: 2.

	"Further since there is a following conditional jump bytecode, define
	 non-merge fixups and leave the cond bytecode to set the mergeness."
	(self fixupAt: nextPC - initialPC) notAFixup
		ifTrue: "The next instruction is dead.  we can skip it."
			[deadCode := true.
		 	 self ensureFixupAt: targetBytecodePC - initialPC.
			 self ensureFixupAt: postBranchPC - initialPC]
		ifFalse:
			[self ssPushConstant: objectMemory trueObject]. "dummy value"

	self assert: (unforwardArg or: [unforwardRcvr]).
	"We could use (branchDescriptor isBranchTrue xor: orNot) to simplify this."
	orNot 
		ifFalse: [branchDescriptor isBranchTrue
					ifTrue: 
						[ fixup := (self ensureNonMergeFixupAt: postBranchPC - initialPC) asUnsignedInteger.
						self JumpZero:  (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger ]
					ifFalse: "branchDescriptor is branchFalse"
						[ fixup := (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger.
						self JumpZero: (self ensureNonMergeFixupAt: postBranchPC - initialPC) asUnsignedInteger ]]
		ifTrue: [branchDescriptor isBranchTrue
					ifFalse: "branchDescriptor is branchFalse"
						[ fixup := (self ensureNonMergeFixupAt: postBranchPC - initialPC) asUnsignedInteger.
						self JumpZero:  (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger ]
					ifTrue:
						[ fixup := (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger.
						self JumpZero: (self ensureNonMergeFixupAt: postBranchPC - initialPC) asUnsignedInteger ]].
		
	"The forwarders checks need to jump back to the comparison (label) if a forwarder is found, else 
	jump forward either to the next forwarder check or to the postBranch or branch target (fixup)."
	unforwardArg ifTrue: 
		[ unforwardRcvr
			ifTrue: [ objectRepresentation genEnsureOopInRegNotForwarded: argReg scratchReg: TempReg jumpBackTo: label ]
			ifFalse: [ objectRepresentation 
				genEnsureOopInRegNotForwarded: argReg 
				scratchReg: TempReg 
				ifForwarder: label
				ifNotForwarder: fixup ] ].
	unforwardRcvr ifTrue: 
		[ objectRepresentation 
			genEnsureOopInRegNotForwarded: rcvrReg 
			scratchReg: TempReg 
			ifForwarder: label
			ifNotForwarder: fixup ].
		
	"Not reached, execution flow have jumped to fixup"
	
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> genJumpBackTo: targetBytecodePC [
	| nothingToFlush label |
	<var: #label type: #'AbstractInstruction *'>
	"If there's nothing to flush then the stack state at this point is the same as that after
	 the check for interrups and we can avoid generating the register reload code twice."
	(nothingToFlush := simStackPtr < 0 or: [self ssTop spilled]) ifTrue:
		[label := self Label].
	self reconcileRegisterStateForBackwardJoin: (self fixupAt: targetBytecodePC - initialPC).
	self MoveAw: coInterpreter stackLimitAddress R: TempReg.
	self CmpR: TempReg R: SPReg. "N.B. FLAGS := SPReg - TempReg"
	self JumpAboveOrEqual: (self fixupAt: targetBytecodePC - initialPC).

	self ssFlushTo: simStackPtr.
	self CallRT: ceCheckForInterruptTrampoline.
	self annotateBytecode: self Label.
	nothingToFlush
		ifTrue:
			[self Jump: label]
		ifFalse:
			[self reconcileRegisterStateForBackwardJoin: (self fixupAt: targetBytecodePC - initialPC).
			 self Jump: (self fixupAt: targetBytecodePC - initialPC)].
	deadCode := true. "can't fall through"
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> genJumpTo: targetBytecodePC [
	"Overriden to avoid the flush because in this cogit stack state is merged at merge point."
	deadCode := true. "can't fall through"
	self Jump: (self ensureFixupAt: targetBytecodePC - initialPC).
	^ 0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> genMarshalledSend: selectorIndex numArgs: numArgs sendTable: sendTable [
	self flushLiveRegistersForSend.
	^super genMarshalledSend: selectorIndex numArgs: numArgs sendTable: sendTable
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
	rcvrIsInt := (rcvrIsConst := (self ssValue: 1) type = SSConstant)
				 and: [objectMemory isIntegerObject: (rcvrInt := (self ssValue: 1) constant)].

	(argIsInt and: [rcvrIsInt]) ifTrue:
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
			 self MoveR: rcvrReg R: TempReg.
			 regMask := self registerMaskFor: rcvrReg]
		ifFalse:
			[self allocateRegForStackTopTwoEntriesInto: [:rTop :rNext| argReg := rTop. rcvrReg := rNext].
			 self ssTop popToReg: argReg.
			 (self ssValue: 1) popToReg: rcvrReg.
			 self MoveR: argReg R: TempReg.
			 regMask := self registerMaskFor: rcvrReg and: argReg].

	"rcvrReg can be reused for the result iff the receiver is a constant or is an SSRegister that is not used elsewhere."
	destReg := (rcvrIsInt
				 or: [(self ssValue: 1) type = SSRegister
					 and: [(self anyReferencesToRegister: rcvrReg inAllButTopNItems: 2) not]])
					ifTrue: [rcvrReg]
					ifFalse: [self allocateRegNotConflictingWith: regMask].
	self ssPop: 2.
	jumpNotSmallInts := (argIsInt or: [rcvrIsInt])
							ifTrue: [objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg]
							ifFalse: [objectRepresentation genJumpNotSmallIntegersIn: rcvrReg andScratch: TempReg scratch: ClassReg].
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
								[rcvrIsInt
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
									 (rcvrIsInt or: [destReg ~= rcvrReg]) ifFalse:
										[self AddR: argReg R: destReg].
									 objectRepresentation genSetSmallIntegerTagsIn: argReg]
								ifFalse:
									[objectRepresentation genRemoveSmallIntegerTagsInScratchReg: argReg.
									 self SubR: argReg R: destReg.
									 jumpContinue := self JumpNoOverflow: 0.
									 "overflow; must undo the damage before doing send"
									 (rcvrIsInt or: [destReg ~= rcvrReg]) ifFalse:
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
	self deny: rcvrReg = Arg0Reg.
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
	| nextPC postBranchPC targetBytecodePC primDescriptor branchDescriptor
	  rcvrIsInt argIsInt argInt jumpNotSmallInts inlineCAB index rcvrReg argReg regMask |
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #branchDescriptor type: #'BytecodeDescriptor *'>
	<var: #jumpNotSmallInts type: #'AbstractInstruction *'>
	primDescriptor := self generatorAt: byte0.
	argIsInt := self ssTop type = SSConstant
				 and: [objectMemory isIntegerObject: (argInt := self ssTop constant)].
	rcvrIsInt := (self ssValue: 1) type = SSConstant
				 and: [objectMemory isIntegerObject: (self ssValue: 1) constant].

	(argIsInt and: [rcvrIsInt]) ifTrue:
		[^ self genStaticallyResolvedSpecialSelectorComparison].

	self extractMaybeBranchDescriptorInto: [ :descr :next :postBranch :target | 
		branchDescriptor := descr. nextPC := next. postBranchPC := postBranch. targetBytecodePC := target ].

	"Only interested in inlining if followed by a conditional branch."
	inlineCAB := branchDescriptor isBranchTrue or: [branchDescriptor isBranchFalse].
	"Further, only interested in inlining = and ~= if there's a SmallInteger constant involved.
	 The relational operators successfully statically predict SmallIntegers; the equality operators do not."
	(inlineCAB and: [primDescriptor opcode = JumpZero or: [primDescriptor opcode = JumpNonZero]]) ifTrue:
		[inlineCAB := argIsInt or: [rcvrIsInt]].
	inlineCAB ifFalse:
		[^self genSpecialSelectorSend].

	"In-line the comparison and the jump, but if the types are not SmallInteger then we will need
	 to do a send and fall through to the following conditional branch.  Since we're allocating values
	 in registers we would like to keep those registers live on the inlined path and reload registers
	 along the non-inlined send path.  The merge logic at the branch destinations handles this."
	argIsInt
		ifTrue:
			[rcvrReg := self allocateRegForStackEntryAt: 1.
			 (self ssValue: 1) popToReg: rcvrReg.
			 self MoveR: rcvrReg R: TempReg.
			 regMask := self registerMaskFor: rcvrReg]
		ifFalse:
			[self allocateRegForStackTopTwoEntriesInto: [:rTop :rNext| argReg := rTop. rcvrReg := rNext].
			 rcvrReg = Arg0Reg ifTrue:
				[rcvrReg := argReg. argReg := Arg0Reg].
			 self ssTop popToReg: argReg.
			 (self ssValue: 1) popToReg: rcvrReg.
			 self MoveR: argReg R: TempReg.
			 regMask := self registerMaskFor: rcvrReg and: argReg].
	self ssPop: 2.
	jumpNotSmallInts := (argIsInt or: [rcvrIsInt])
							ifTrue: [objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg]
							ifFalse: [objectRepresentation genJumpNotSmallIntegersIn: rcvrReg andScratch: TempReg scratch: ClassReg].
	argIsInt
		ifTrue: [self CmpCq: argInt R: rcvrReg]
		ifFalse: [self CmpR: argReg R: rcvrReg].
	"Cmp is weird/backwards so invert the comparison.  Further since there is a following conditional
	 jump bytecode define non-merge fixups and leave the cond bytecode to set the mergeness."
	self genConditionalBranch: (branchDescriptor isBranchTrue
				ifTrue: [primDescriptor opcode]
				ifFalse: [self inverseBranchFor: primDescriptor opcode])
		operand: (self ensureNonMergeFixupAt: targetBytecodePC - initialPC) asUnsignedInteger.
	self Jump: (self ensureNonMergeFixupAt: postBranchPC - initialPC).
	jumpNotSmallInts jmpTarget: self Label.
	self ssFlushTo: simStackPtr.
	self deny: rcvrReg = Arg0Reg.
	argIsInt
		ifTrue: [self MoveCq: argInt R: Arg0Reg]
		ifFalse: [argReg ~= Arg0Reg ifTrue: [self MoveR: argReg R: Arg0Reg]].
	rcvrReg ~= ReceiverResultReg ifTrue: [self MoveR: rcvrReg R: ReceiverResultReg].
	index := byte0 - self firstSpecialSelectorBytecodeOffset.
	self genMarshalledSend: index negated - 1 numArgs: 1 sendTable: ordinarySendTrampolines.
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> genStorePop: popBoolean TemporaryVariable: tempIndex [
	<inline: false>
	| srcRegOrNone destReg |
	self ssFlushUpThroughTemporaryVariable: tempIndex.
	"To avoid a stall writing through destReg, remember srcReg before the potential ssPop: 1 in ssStorePop:toReg:"
	srcRegOrNone := self ssTop registerOrNone.
	"ssStorePop:toPreferredReg: will allocate a register, and indeed may allocate ReceiverResultReg
	 if, for example, the ssEntry to be popped is already in ReceiverResultReg (as the result of a send).
	 ReceiverResultReg is not a good choice for a temporary variable; it has other uses.  So if the ssEntry
	 at top of stack has ReceiverResultReg as its live variable, try and allocate an alternative."
	((self ssTop registerMaskOrNone anyMask: self registerMaskUndesirableForTempVars)
	 and: [(destReg := self availableRegOrNoneNotConflictingWith: (self registerMaskUndesirableForTempVars bitOr: self liveRegisters)) ~= NoReg])
		ifTrue: [self ssStorePop: popBoolean toReg: destReg]
		ifFalse: [destReg := self ssStorePop: popBoolean toPreferredReg: TempReg].
	self MoveR: (srcRegOrNone ~= NoReg ifTrue: [srcRegOrNone] ifFalse: [destReg])
		Mw: (self frameOffsetOfTemporary: tempIndex)
		r: FPReg.
	destReg ~= TempReg ifTrue:
		[(self simStackAt: tempIndex) liveRegister: destReg.
		 self copyLiveRegisterToCopiesOf: (self simStackAt: tempIndex)].
	^0
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
		desc := self simStackAt: 1.
		desc liveRegister: desc registerOrNone]
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
RegisterAllocatingCogit >> mergeCurrentSimStackWith: fixup [
	<var: #fixup type: #'BytecodeFixup *'>
	| mergeSimStack currentEntry targetEntry |
	<var: #mergeSimStack type: #'SimStackEntry *'>
	"At a merge point the cogit expects the stack to be in the same state as mergeSimStack.
	 mergeSimStack is the state as of some jump forward to this point.  So make simStack agree
	 with mergeSimStack (it is, um, problematic to plant code at the jump).
	 Values may have to be assigned to registers.  Registers may have to be swapped.
	 The state of optStatus must agree."
	<var: #targetEntry type: #'SimStackEntry *'>
	<var: #currentEntry type: #'SimStackEntry *'>
	<var: #duplicateEntry type: #'SimStackEntry *'>
	(mergeSimStack := fixup mergeSimStack) ifNil: [^self].
	"Assignments amongst the registers must be made in order to avoid overwriting.
	 If necessary exchange registers amongst simStack's entries to resolve any conflicts."
	self resolveRegisterOrderConflictsBetweenCurrentSimStackAnd: mergeSimStack.
	self assert: (self conflcitsResolvedBetweenSimStackAnd: mergeSimStack).
	simStackPtr to: 0 by: -1 do:
		[:i|
		 currentEntry := self simStack: simStack at: i.
		 targetEntry := self simStack: mergeSimStack at: i.
		 (currentEntry reconcileForwardsWith: targetEntry) ifTrue:
			[self assert: i >= methodOrBlockNumArgs.
			 self deassignRegisterForTempVar: targetEntry in: mergeSimStack].
		 "Note, we could update the simStack and spillBase here but that is done in restoreSimStackAtMergePoint:
		 spilled ifFalse:
			[simSpillBase := i - 1].
		 simStack
			at: i
			put: (self
					cCode: [mergeSimStack at: i]
					inSmalltalk: [(mergeSimStack at: i) copy])"].

	"a.k.a. fixup isReceiverResultRegSelf: (fixup isReceiverResultRegSelf and: [optStatus isReceiverResultRegLive])"
	optStatus isReceiverResultRegLive ifFalse:
		[fixup isReceiverResultRegSelf: false]
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
			flushes the stack to the stack pointer so the fall through execution path simStack is 
				in the state the merge point expects it to be. 
			restores the simStack to the state the jumps to the merge point expects it to be.
			
	In addition, if this is a backjump merge point, we patch the fixup to hold the current simStackPtr 
	for later assertions."
	
	<var: #fixup type: #'BytecodeFixup *'>
	"case 1"
	fixup notAFixup ifTrue: [^ 0].

	"case 2"
	fixup isNonMergeFixup ifTrue: [deadCode := false. ^ 0 ].

	"cases 3 and 4"
	self assert: fixup isMergeFixup.
	self traceMerge: fixup.
	deadCode 
		ifTrue: [simStackPtr := fixup simStackPtr] "case 3"
		ifFalse: [self mergeCurrentSimStackWith: fixup]. "case 4"
	"cases 3 and 4"
	deadCode := false.
	fixup isBackwardBranchFixup ifTrue:
		[self assert: fixup mergeSimStack isNil.
		 self setMergeSimStackOf: fixup].
	fixup targetInstruction: self Label.
	self assert: simStackPtr = fixup simStackPtr.
	self cCode: '' inSmalltalk:
		[self assert: fixup simStackPtr = (self debugStackPointerFor: bytecodePC)].
	self restoreSimStackAtMergePoint: fixup.
	
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> moveVolatileSimStackEntriesToRegisters [
	"When jumping forward to a merge point the stack mst be reconcilable with the state that falls through to the merge point.
	 We cannot easily arrange that later we add code to the branch, e.g. to spill values.  Instead, any volatile contents must be
	 moved to registers.  [In fact, that's not exactly true, consider these two code sequences:
							self at: (expr ifTrue: [1] ifFalse: [2]) put: a
							self at: 1 put: (expr ifTrue: [a] ifFalse: [b])
						 The first one needs 1 saving to a register to reconcile with 2.
						 The second one has 1 on both paths, but we're not clever enough to spot this case yet.]
	 Volatile contents are anything not spilled to the stack, because as yet we can only merge registers."
	<inline: true>
	<var: #desc type: #'SimStackEntry *'>
	(simSpillBase max: 0) to: simStackPtr do: 
		[:i| | desc reg |
		 desc := self simStackAt: i.
		 desc spilled
			ifTrue: [simSpillBase := i]
			ifFalse:
				[desc registerOrNone = NoReg ifTrue:
					[reg := self allocateRegNotConflictingWith: 0.
					 reg = NoReg
						ifTrue: [self halt] "have to spill"
						ifFalse: [desc storeToReg: reg]]]]
]

{ #category : #accessing }
RegisterAllocatingCogit >> needsFrame [
	"for asserts"
	<cmacro: '() needsFrame'>
	^needsFrame
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
RegisterAllocatingCogit >> reconcileRegisterStateForBackwardJoin: fixup [ 
	<var: #fixup type: #'SSBytecodeFixup *'>
	| fixupSimStack |
	<var: #fixupSimStack type: #'SimStackEntry *'>
	self assert: (optStatus ssEntry isSameEntryAs: simSelf). 
	fixup isReceiverResultRegSelf ifTrue:
		[optStatus isReceiverResultRegLive ifFalse:
			[optStatus ssEntry storeToReg: ReceiverResultReg]].
	fixupSimStack := fixup mergeSimStack.
	simStackPtr to: 0 by: -1 do:
		[:i|
		 self assert: (self simStackAt: i) spilled.
		 (self simStackAt: i) reconcileBackwardsWith: (fixupSimStack at: i)]
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
	 The trivial case of a single conflict is resolved by assigning that conflict to TempReg.
	"
	| currentRegsMask mergeRegsMask potentialConflictRegMask conflictingRegsMask
	   currentRegMask mergeRegMask currentEntry targetEntry |
	<var: #currentEntry type: #'SimStackEntry *'>
	<var: #targetEntry type: #'SimStackEntry *'>
	currentRegsMask := mergeRegsMask := potentialConflictRegMask := 0.
	0 to: simStackPtr do:
		[:i|
		 currentRegMask := (currentEntry := self simStack: simStack at: i) registerMaskOrNone.
		 mergeRegMask := (targetEntry := self simStack: mergeSimStack at: i) registerMaskOrNone.
		 (currentRegMask ~= mergeRegMask
		  and: [currentRegMask ~= 0 or: [mergeRegMask ~= 0]]) ifTrue:
			[potentialConflictRegMask := potentialConflictRegMask bitOr: (currentRegMask bitOr: mergeRegMask)].
		 currentRegsMask := currentRegsMask bitOr: currentRegMask.
		 mergeRegsMask := mergeRegsMask bitOr: mergeRegMask].
	conflictingRegsMask := potentialConflictRegMask bitAnd: (currentRegsMask bitAnd: mergeRegsMask).
	conflictingRegsMask ~= 0 ifTrue:
		[(self isAPowerOfTwo: conflictingRegsMask) "Multiple conflicts mean we have to sort"
			ifFalse: [self swapCurrentRegistersInMask: currentRegsMask accordingToRegisterOrderIn: mergeSimStack]
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
				self assert: ((self simStackAt: i) isSameEntryAs: (fixup mergeSimStack at: i)).
				(self simStackAt: i) liveRegister ~= (fixup mergeSimStack at: i) liveRegister ifTrue:
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
	methodOrBlockNumArgs to: simStackPtr do:
		[:i|
		 ((simSelf isSameEntryAs: (self simStackAt: i))
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

{ #category : #initialization }
RegisterAllocatingCogit >> simStackEntryClass [
	<doNotGenerate>
	^CogRegisterAllocatingSimStackEntry
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
		(simSelf isSameEntryAs: (self simStackAt: i)) ifTrue:
			[(self simStackAt: i) liveRegister: NoReg]].
	simSelf liveRegister: NoReg
]
