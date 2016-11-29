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
			type: #'CogSimStackEntry *';
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
	^self allocateRegForStackEntryAt: index notConflictingWith: (self registerMaskFor: FPReg and: SPReg and: TempReg)
]

{ #category : #'simulation only' }
RegisterAllocatingCogit >> bytecodeFixupClass [
	<doNotGenerate>
	^CogRASSBytecodeFixup
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> captureUnspilledSpillsForSpecialSelectorSend: liveRegisterMask [
	"Since we're allocating values in registers we would like to keep those registers live on the inlined path
	 and reload registers along the non-inlined send path.  But any values that would need to be spilled
	 along the non-inlined path must be captured before the split so that both paths can join.  If we don't
	 capture the values on the non-inlined path we could access stale values.  So for all stack entries that
	 would be spilled along the non-inlined path, assign them to registers, or spill if none are available."
	| i liveRegs reg |
	liveRegs := liveRegisterMask.
	optStatus isReceiverResultRegLive ifTrue:
		[liveRegs := liveRegs + (self registerMaskFor: ReceiverResultReg)].
	reg := TempReg. "Anything but NoReg"
	i := simStackPtr + 1. "We must spill a contiguous range at the hot top of stack, so we assign coldest first :-("
	[reg ~= NoReg and: [i > simSpillBase and: [i > 0]]] whileTrue:
		[i := i - 1.
		 self deny: ((self simStackAt: i) spilled and: [(self simStackAt: i) type = SSBaseOffset]).
		 ((self simStackAt: i) spilled not
		  and: [(self simStackAt: i) type = SSBaseOffset]) ifTrue:
			[reg := self allocateRegNotConflictingWith: liveRegs.
			 reg ~= NoReg ifTrue:
				[(self simStackAt: i) storeToReg: reg]]].
	reg = NoReg ifTrue:
		[self ssFlushTo: i]
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
RegisterAllocatingCogit >> ensureFixupAt: targetIndex [
	| fixup |	
	<var: #fixup type: #'BytecodeFixup *'>
	fixup := self fixupAt: targetIndex.
	fixup needsFixup 
		ifTrue:
			[fixup mergeSimStack
				ifNil: [self setMergeSimStackOf: fixup]
				ifNotNil: [self mergeCurrentSimStackWith: fixup mergeSimStack]]
		ifFalse: 
			[self assert: fixup mergeSimStack isNil.
			self moveSimStackConstantsToRegisters.
			self setMergeSimStackOf: fixup ].
	^super ensureFixupAt: targetIndex.

]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> ensureNonMergeFixupAt: targetIndex [
	"Make sure there's a flagged fixup at the targetIndex (pc relative to first pc) in fixups.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction."
	| fixup |
	fixup := super ensureNonMergeFixupAt: targetIndex.
	self setMergeSimStackOf: fixup.
	^fixup
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> ensureReceiverResultRegContainsSelf [
	super ensureReceiverResultRegContainsSelf.
	0 to: simStackPtr do:
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
	| pc nExts descriptor |
	pc := bytecodePC.
	nExts := 0.
	[pc <= endPC] whileTrue:
		[descriptor := self generatorAt: pc.
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
	| primDescriptor rcvrIsConst argIsConst rcvrIsInt argIsInt rcvrInt argInt result
	 jumpNotSmallInts jumpContinue index rcvrReg argReg regMask |
	<var: #jumpContinue type: #'AbstractInstruction *'>
	<var: #primDescriptor type: #'BytecodeDescriptor *'>
	<var: #jumpNotSmallInts type: #'AbstractInstruction *'>
	primDescriptor := self generatorAt: byte0.
	argIsInt := (argIsConst := self ssTop type = SSConstant)
				 and: [objectMemory isIntegerObject: (argInt := self ssTop constant)].
	rcvrIsInt := (rcvrIsConst := (self ssValue: 1) type = SSConstant)
				 and: [objectMemory isIntegerObject: (rcvrInt := (self ssValue: 1) constant)].

	(argIsInt and: [rcvrIsInt]) ifTrue:
		[rcvrInt := objectMemory integerValueOf: rcvrInt.
		 argInt := objectMemory integerValueOf: argInt.
		 primDescriptor opcode caseOf: {
			[AddRR]	-> [result := rcvrInt + argInt].
			[SubRR]	-> [result := rcvrInt - argInt].
			[AndRR]	-> [result := rcvrInt bitAnd: argInt].
			[OrRR]	-> [result := rcvrInt bitOr: argInt] }.
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
	 But if the other type is not SmallInteger or if the operation overflows then we will need to do a send.
	 Since we're allocating values in registers we would like to keep those registers live on the inlined path
	 and reload registers along the non-inlined send path.  But any values that would need to be spilled
	 along the non-inlined path must be captured before the split so that both paths can join.  If we don't
	 capture the values on the non-iblined path we could access stale values.  So for all stack entries that
	 would be spilled along the non-inlined path, assign them to registers, or spill if none are available."
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
	self ssPop: 2.
	self captureUnspilledSpillsForSpecialSelectorSend: regMask.
	jumpNotSmallInts := (argIsInt or: [rcvrIsInt])
							ifTrue: [objectRepresentation genJumpNotSmallIntegerInScratchReg: TempReg]
							ifFalse: [objectRepresentation genJumpNotSmallIntegersIn: rcvrReg andScratch: TempReg scratch: ClassReg].
	primDescriptor opcode caseOf: {
		[AddRR] -> [argIsInt
						ifTrue:
							[self AddCq: argInt - ConstZero R: rcvrReg.
							 jumpContinue := self JumpNoOverflow: 0.
							 "overflow; must undo the damage before continuing"
							 self SubCq: argInt - ConstZero R: rcvrReg]
						ifFalse:
							[objectRepresentation genRemoveSmallIntegerTagsInScratchReg: rcvrReg.
							 self AddR: argReg R: rcvrReg.
							jumpContinue := self JumpNoOverflow: 0.
							"overflow; must undo the damage before continuing"
							 rcvrIsInt
								ifTrue: [self MoveCq: rcvrInt R: rcvrReg]
								ifFalse:
									[self SubR: argReg R: rcvrReg.
									 objectRepresentation genSetSmallIntegerTagsIn: rcvrReg]]].
		[SubRR] -> [argIsInt
						ifTrue:
							[self SubCq: argInt - ConstZero R: rcvrReg.
							 jumpContinue := self JumpNoOverflow: 0.
							 "overflow; must undo the damage before continuing"
							 self AddCq: argInt - ConstZero R: rcvrReg]
						ifFalse:
							[objectRepresentation genRemoveSmallIntegerTagsInScratchReg: argReg.
							 self SubR: argReg R: rcvrReg.
							 jumpContinue := self JumpNoOverflow: 0.
							 "overflow; must undo the damage before continuing"
							 self AddR: argReg R: rcvrReg.
							 objectRepresentation genSetSmallIntegerTagsIn: argReg]].
		[AndRR] -> [argIsInt
						ifTrue: [self AndCq: argInt R: rcvrReg]
						ifFalse: [self AndR: argReg R: rcvrReg].
					jumpContinue := self Jump: 0].
		[OrRR]	-> [argIsInt
						ifTrue: [self OrCq: argInt R: rcvrReg]
						ifFalse: [self OrR: argReg R: rcvrReg].
					jumpContinue := self Jump: 0] }.
	jumpNotSmallInts jmpTarget: self Label.
	self ssPushRegister: rcvrReg.
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

	"In-line, but if the types are not SmallInteger then we will need to do a send.
	 Since we're allocating values in registers we would like to keep those registers live on the inlined path
	 and reload registers along the non-inlined send path.  But any values that would need to be spilled
	 along the non-inlined path must be captured before the split so that both paths can join.  If we don't
	 capture the values on the non-iblined path we could access stale values.  So for all stack entries that
	 would be spilled along the non-inlined path, assign them to registers, or spill if none are available."
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
	self captureUnspilledSpillsForSpecialSelectorSend: regMask.
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

{ #category : #'as yet unclassified' }
RegisterAllocatingCogit >> maybeCountFixup: descriptor [
	"Count needed fixups; descriptor is known to be a branch or a block creation."
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<inline: true>
	numFixups := numFixups + ((descriptor isBranchTrue or: [descriptor isBranchFalse])
									ifTrue:
										[(prevBCDescriptor generator == #genSpecialSelectorEqualsEquals
										   or: [prevBCDescriptor generator == #genSpecialSelectorComparison])
											ifTrue: [3]
											ifFalse: [2]]
									ifFalse:  [1])
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> maybeInitNumFixups [
	<inline: true>
	numFixups := 0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> mergeCurrentSimStackWith: mergeSimStack [
	<var: #mergeSimStack type: #'SimStackEntry *'>
	<var: #currentSSEntry type: #'SimStackEntry *'>
	<var: #expectedSSEntry type: #'SimStackEntry *'>
	"At merge point the cogit expects the stack to be in the same state as mergeSimStack.
	The logic is very naive, we align the existing state from the current stack to the merge stack
	from simStackPtr to methodOrBlockNumTemps, and if a conflict happen, we flush what remains
	to be merged."
	self flag: #TODO. "we could have a better algorithm with the current set of live registers to avoid flushing"
	simStackPtr to: methodOrBlockNumTemps by: -1 do:
		[:i|
			| currentSSEntry expectedSSEntry |
			currentSSEntry := self simStackAt: i.
			expectedSSEntry := self simStack: mergeSimStack at: i.
			expectedSSEntry type
				caseOf: {
					[SSBaseOffset]	-> [ self assert: (expectedSSEntry register = ReceiverResultReg or: [ expectedSSEntry register = FPReg ]).
										(expectedSSEntry register = ReceiverResultReg and: [needsFrame]) ifTrue: 
											[optStatus isReceiverResultRegLive ifFalse: 
												[self ssFlushFrom: i - 1 upThroughRegister: ReceiverResultReg.
											 	 self putSelfInReceiverResultReg ].
											 optStatus isReceiverResultRegLive: true].  ].
					[SSSpill]		-> [currentSSEntry ensureSpilledAt: (self frameOffsetOfTemporary: i) from: FPReg].
					[SSConstant]	-> [self assert: expectedSSEntry liveRegister notNil. 
										currentSSEntry storeToReg: expectedSSEntry liveRegister ].
					[SSRegister]	-> [(currentSSEntry type = SSRegister and: [currentSSEntry register = expectedSSEntry register])
											ifFalse: 
												[ self ssFlushFrom: i - 1 upThroughRegister: expectedSSEntry register.
												currentSSEntry storeToReg: expectedSSEntry register ] ]}.
			 ]
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
		ifFalse: [self mergeCurrentSimStackWith: fixup mergeSimStack]. "case 4"
	"cases 3 and 4"
	deadCode := false.
	fixup isBackwardBranchFixup ifTrue: [fixup simStackPtr: simStackPtr].
	fixup targetInstruction: self Label.
	self assert: simStackPtr = fixup simStackPtr.
	self cCode: '' inSmalltalk:
		[self assert: fixup simStackPtr = (self debugStackPointerFor: bytecodePC)].
	self restoreSimStackAtMergePoint: fixup.
	
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> moveSimStackConstantsToRegisters [
	<inline: true>
	(simSpillBase max: 0) to: simStackPtr do: 
		[:i|
			| desc |
			desc := self simStackAt: i.
			(desc type = SSConstant and: [desc liveRegister = NoReg])
				ifTrue: [ desc storeToReg: (self allocateRegNotConflictingWith: 0) ] ]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> receiverRefOnScratchSimStack [
	simStackPtr to: (0 max: scratchSpillBase) by: -1 do:
		[:i|
		 ((self addressOf: (scratchSimStack at: i)) register = ReceiverResultReg
		  and: [(self addressOf: (scratchSimStack at: i)) type = SSBaseOffset]) ifTrue:
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
			ifFalse: [optStatus isReceiverResultRegLive: false]].

	"Restore the simStack to that in scratchSimStack,
	 popping any spilled state back into allocated registers."
	simSpillBase := scratchSpillBase.
	simStackPtr to: 0 by: -1 do:
		[:i|
		 self assert: (i = simStackPtr
						ifTrue: [(self simStackAt: i) type = SSRegister]
						ifFalse: [(self simStackAt: i) spilled]).
		 (self addressOf: (scratchSimStack at: i)) spilled ifTrue:
			[self assert: ((scratchSimStack at: i) isSameEntryAs: (self simStackAt: i)).
			 ^self].
		 (self addressOf: (scratchSimStack at: i)) reconcileWith: (self simStackAt: i).
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

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> restoreSimStackAtMergePoint: fixup [
	<inline: true>
	"All the execution paths reaching a merge point expect everything to be spilled
	 on stack and the optStatus is unknown.  If the merge point follows a return, it
	 isn't a merge, but a sdkip past a return.  If it is a real merge point then throw
	 away all simStack and optStatus optimization state."
	fixup mergeSimStack ifNotNil:
		[simSpillBase := methodOrBlockNumTemps.
		 self flag: 'try and maintain this through the merge'.
		 optStatus isReceiverResultRegLive: false.
		 0 to: simStackPtr do:
			[:i|
			self cCode: [simStack at: i put: (fixup mergeSimStack at: i)]
				inSmalltalk: [(simStack at: i) copyFrom: (fixup mergeSimStack at: i)]]].
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> setMergeSimStackOf: fixup [
	<var: #fixup type: #'BytecodeFixup *'>
	self assert: nextFixup <= numFixups.
	self moveSimStackConstantsToRegisters.
	self cCode: [fixup mergeSimStack: mergeSimStacksBase + (nextFixup * self simStackSlots * (self sizeof: CogSimStackEntry))].
	fixup simStackPtr: simStackPtr.
	nextFixup := nextFixup + 1.
	self cCode: [self mem: fixup mergeSimStack cp: simStack y: self simStackSlots * (self sizeof: CogSimStackEntry)]
		inSmalltalk: [fixup mergeSimStack: self copySimStack]
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
	| actualReg |
	actualReg := preferredReg.
	self ssTop type = SSRegister ifTrue: 
		[self assert: (self ssTop liveRegister = NoReg
					  or: [self ssTop liveRegister = self ssTop register]).
		self assert: self ssTop spilled not.
		actualReg := self ssTop register].
	self ssTop liveRegister ~= NoReg ifTrue:
		[actualReg := self ssTop liveRegister].
	self ssStorePop: popBoolean toReg: actualReg. "generates nothing if ssTop is already in actualReg"
	^actualReg
]
