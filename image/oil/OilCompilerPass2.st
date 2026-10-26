"Pass 2 of Oil (OilLoopOptimizer), the streaming loop optimizer.  It reads the linear IR Pass 1 produced in Buffer 1
 (oilIRBuffer1) and writes the optimized IR into Buffer 2 (oilIRBuffer2), which Pass 3 then
 translates to machine code.  All its tables are static; it allocates nothing.  Author: cb."!

OilInliningCompiler subclass: #OilLoopOptimizer
	instanceVariableNames: 'oilUnrollHead oilUnrollBack oilUnrollTest oilUnrollCount oilUnrollIV oilUnrollValue oilUnrollWord1 oilUnrollWord2 oilNumUnrolls oilUnrollGrowth oilUnrollClones oilUnrollFreeReg oilNumFullyUnrolled oilNumPartiallyUnrolled oilNumYoungStores oilUnrollMode oilUnrollTinyBody oilUnrollMaxBody oilUnrollBudget oilUnrollMaxTrips oilLoopAlignment oilCodeShift'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-Oil'!

!OilLoopOptimizer commentStamp: 'cb 10/24/2026 19:35' prior: 0!
I add Pass 2, the streaming loop optimizer, to OilInliningCompiler.  Given the linear IR Pass 1 produced in Buffer 1 (oilIRBuffer1), pipe (via loopOptimize) analyzes tagged SmallInteger registers, rotates innermost call-free loops, eliminates redundant bounds checks, class guards and overflow checks on induction variables, removes dead pure instructions, unrolls innermost leaf loops (fully when their trip count is a small constant, else 2 or 4 times with a remainder loop), and streams the optimized IR into Buffer 2 (oilIRBuffer2) for Pass 3.!

!OilLoopOptimizer class methodsFor: 'translation' stamp: 'cb 10/25/2026 21:00'!
declareCVarsIn: aCCodeGenerator
	self == OilLoopOptimizer ifFalse: [^self].
	#(oilUnrollHead oilUnrollBack oilUnrollTest oilUnrollCount oilUnrollIV oilUnrollValue oilUnrollWord1 oilUnrollWord2) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilMaxUnrolls]']! !

!OilLoopOptimizer methodsFor: 'initialization' stamp: 'cb 10/25/2026 21:00'!
setUpSimulationTables
	<doNotGenerate>
	super setUpSimulationTables.
	oilUnrollHead := self newTable: OilMaxUnrolls.
	oilUnrollBack := self newTable: OilMaxUnrolls.
	oilUnrollTest := self newTable: OilMaxUnrolls.
	oilUnrollCount := self newTable: OilMaxUnrolls.
	oilUnrollIV := self newTable: OilMaxUnrolls.
	oilUnrollValue := self newTable: OilMaxUnrolls.
	oilUnrollWord1 := self newTable: OilMaxUnrolls.
	oilUnrollWord2 := self newTable: OilMaxUnrolls.
	oilNumUnrolls := oilUnrollGrowth := oilUnrollClones := oilNumFullyUnrolled := oilNumPartiallyUnrolled := oilNumYoungStores := 0.
	oilUnrollFreeReg := -2.
	self oilResetUnrollParameters! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 19:35'!
pipe
	<inline: true>
	super pipe.
	^self runLoopOptimizationPhase!

runLoopOptimizationPhase
	<inline: true>
	^self loopOptimize! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
loopOptimize
	"Pass 2: optimize the IR of Buffer 1 into Buffer 2 and make Buffer 2 the current IR.
	 1. Analysis: the definitions of each virtual register, the branch targets, the registers that always hold
	    SmallIntegers (analyzeTaggedRegisters).
	 2. Loops (innermost, call free, entered only by falling into their header):
	    - rotation: a loop test that cannot fail (on SmallIntegers) is duplicated at the bottom of the loop,
	      where it branches back, so that an iteration executes one conditional branch and no jump;
	    - counted loops (index from a constant >= 1, only incremented, tested against the size of an object):
	      the increments cannot overflow (OilAddImmTaggedNC), the size of the object is the one loaded before
	      the loop, and the bounds checks of the index right after the loop test are redundant.
	 3. Redundant loads and checks (valueNumber: none here, see OilFullCompiler).
	 4. Dead code: pure instructions defining a register nothing reads (no instruction, no deopt state).
	 5. Unrolling of innermost leaf loops (unrollLoops).
	 6. Emission (streaming, one pass to lay out, one to emit), remapping branch targets and deopt sites.
	 If loops were fully unrolled, their copies are straight-line code: Buffer 2 is copied back into Buffer 1 and optimized
	 again (once), e.g. the checks a copy repeats are redundant (value numbering), and loops around them may now be innermost.
	 Answer OilOK or a failure code."
	| result |
	oilIRBuffer := oilIRBuffer1.
	oilPass1Words := irIndex.
	oilNumRotated := oilNumBoundsRemoved := oilNumDeadRemoved := oilNumSizesShared := oilNumNoCheck := oilNumGuardsRemoved := oilNumUndos := 0.
	oilUseProbe := -1.
	oilNumFullyUnrolled := oilNumPartiallyUnrolled := oilNumYoungStores := 0.
	result := self optimizeIR.
	(result = OilOK and: [oilNumFullyUnrolled > 0]) ifTrue:
		[0 to: irIndex - 1 do:
			[:irOffset| oilIRBuffer1 at: irOffset put: (oilIRBuffer2 at: irOffset)].
		 oilIRBuffer := oilIRBuffer1.
		 result := self optimizeIR].
	^result! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 21:00'!
optimizeIR
	"Optimize the IR of Buffer 1 into Buffer 2 and make Buffer 2 the current IR (see loopOptimize)."
	| irOffset opcode branchTarget optimize |
	oilNumUnrolls := oilUnrollGrowth := oilUnrollClones := 0.
	oilUnrollFreeReg := -2.
	self threadBooleanJumps.
	0 to: irIndex - 1 do:
		[:targetOffset|
		oilIRFlag at: targetOffset put: 0.
		oilIRAux at: targetOffset put: 0.
		oilIRTarget at: targetOffset put: 0].
	0 to: OilNumRegs - 1 do:
		[:vreg| oilVRegDefs at: vreg put: 0].
	optimize := true.
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (opcode = OilMakeClosure or: [opcode = OilNewArray]) ifTrue: [optimize := false].
		 (self opcodeHasDest: opcode) ifTrue:
			[oilVRegDefs at: (self fieldAAt: irOffset) put: (oilVRegDefs at: (self fieldAAt: irOffset)) + 1].
		 (self isBranch: opcode) ifTrue:
			[branchTarget := self imm16At: irOffset.
			 branchTarget >= irIndex ifTrue:
				[self abortCompilation: OilFailInternal.
				 ^failureCode].
			 oilIRTarget at: branchTarget put: ((oilIRTarget at: branchTarget) + 1 min: 255)].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	self computeIRSites.
	optimize ifTrue:
		[self analyzeTaggedRegisters.
		 irOffset := 0.
		 [irOffset < irIndex] whileTrue:
			[((self opcodeAt: irOffset) = OilJump and: [(self imm16At: irOffset) <= irOffset]) ifTrue:
				[self optimizeLoop: (self imm16At: irOffset) backJump: irOffset].
			 irOffset := irOffset + (self instructionLengthAt: irOffset)].
		 self valueNumber.
		 self eliminateDeadCode.
		 self unrollLoops].
	^self emitOptimizedIR! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 22:30'!
threadBooleanJumps
	"A Jump right after rX := true (or false), not itself a branch target, to a test of rX (OilBranchTrue or OilBranchFalse rX,
	 possibly through other jumps) goes straight where the test goes: its target, or the instruction after it.  rX is still
	 assigned.  That is the boolean of an and: or or: condition (e.g. [i < n and: [x < y]] whileTrue: [...]), so its test (two
	 comparisons and a mustBeBoolean check) is skipped on the hot path."
	| irOffset prevOffset opcode target hops taken newTarget |
	0 to: irIndex - 1 do: [:offset| oilIRTarget at: offset put: 0].
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (self isBranch: opcode) ifTrue:
			[(self imm16At: irOffset) < irIndex ifTrue: [oilIRTarget at: (self imm16At: irOffset) put: 1]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	prevOffset := -1.
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (opcode = OilJump
		  and: [prevOffset >= 0
		  and: [(oilIRTarget at: irOffset) = 0
		  and: [(self opcodeAt: prevOffset) = OilConst64
		  and: [((self word64At: prevOffset + 1) = trueHandle or: [(self word64At: prevOffset + 1) = falseHandle])
		  and: [(target := self imm16At: irOffset) > irOffset and: [target < irIndex]]]]]]) ifTrue:
			[hops := 0.
			 [(self opcodeAt: target) = OilJump and: [hops < 4 and: [(self imm16At: target) > target]]] whileTrue:
				[target := self imm16At: target.
				 hops := hops + 1].
			 (((self opcodeAt: target) = OilBranchTrue or: [(self opcodeAt: target) = OilBranchFalse])
			  and: [(self fieldAAt: target) = (self fieldAAt: prevOffset)]) ifTrue:
				[taken := (self word64At: prevOffset + 1) = trueHandle.
				 (self opcodeAt: target) = OilBranchFalse ifTrue: [taken := taken not].
				 newTarget := taken ifTrue: [self imm16At: target] ifFalse: [target + 1].
				 (newTarget > irOffset and: [newTarget < irIndex]) ifTrue:
					[oilIRBuffer at: irOffset put: ((oilIRBuffer at: irOffset) bitAnd: 16rFFFF0000) + newTarget]]].
		 prevOffset := irOffset.
		 irOffset := irOffset + (self instructionLengthAt: irOffset)]! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 02:00'!
valueNumber
	"Eliminate redundant loads and checks (OilFullCompiler)."
	<inline: true>
	^self! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
isCall: opcode
	"(The byte scans fall back to sends, which may run any code.)"
	<inline: true>
	^(self isSendOpcode: opcode)
	  or: [opcode = OilIndexOfByte or: [opcode = OilSkipSeparators or: [opcode = OilStringHash]]]! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
flag: irOffset has: mask
	<inline: true>
	^((oilIRFlag at: irOffset) bitAnd: mask) ~= 0! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
mark: irOffset with: mask
	<inline: true>
	oilIRFlag at: irOffset put: ((oilIRFlag at: irOffset) bitOr: mask)! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
isPureAt: irOffset
	"Does the instruction at irOffset only compute its destination (no side effect, no deopt, no control flow)?"
	| opcode |
	opcode := self opcodeAt: irOffset.
	^opcode = OilConstTagged or: [opcode = OilConst64 or: [opcode = OilMove or: [opcode = OilLoadSize or: [opcode = OilLoadByteSize or: [opcode = OilLoadField
		or: [opcode = OilAddImmTagged and: [self flag: irOffset has: OilP2NoCheck]]]]]]]! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
regionStartBefore: loopHead
	"Answer the start of the straight-line code that falls into loopHead: the instructions from there to loopHead
	 are entered only at their start (no branch target among them but the first) and contain no branch, so each
	 of them executes, in order, every time the loop is entered by falling into its header."
	| irOffset opcode startOffset |
	startOffset := 0.
	irOffset := 0.
	[irOffset < loopHead] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (oilIRTarget at: irOffset) ~= 0 ifTrue: [startOffset := irOffset].
		 ((self isBranch: opcode) or: [opcode = OilReturn]) ifTrue: [startOffset := irOffset + (self instructionLengthAt: irOffset)].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^startOffset! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
optimizeLoop: loopHead backJump: backJump
	"Optimize the loop from loopHead to the Jump at backJump, if it is innermost, free of calls and only entered by
	 falling into loopHead, and its header is pure code then OilCmpTagged (or OilCmpImmTagged) and an OilBranchFalse that
	 leaves the loop."
	<inline: false>
	| irOffset opcode cmpOffset bfOffset exitOffset cond ivReg limitReg limitDef arrayReg regionStart ivDefsInLoop ivInit ivInitValue sizeAlias isImm |
	(oilIRTarget at: loopHead) = 1 ifFalse: [^self]. "only the back jump branches to the loop head"
	irOffset := loopHead.
	[irOffset < backJump] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (self isCall: opcode) ifTrue: [^self].
		 ((self isBranch: opcode) and: [(self imm16At: irOffset) <= irOffset]) ifTrue: [^self].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	self removeInvariantChecksInLoop: loopHead backJump: backJump.
	"The header: pure instructions without deopt sites, nothing branching into them."
	irOffset := loopHead.
	[(irOffset = loopHead or: [(oilIRTarget at: irOffset) = 0])
	 and: [(self isPureAt: irOffset) and: [(oilIRSite at: irOffset) < 0]]] whileTrue:
		[irOffset := irOffset + (self instructionLengthAt: irOffset)].
	cmpOffset := irOffset.
	bfOffset := cmpOffset + 1.
	isImm := (self opcodeAt: cmpOffset) = OilCmpImmTagged.
	((isImm or: [(self opcodeAt: cmpOffset) = OilCmpTagged])
	 and: [bfOffset < backJump
	 and: [(cmpOffset = loopHead or: [(oilIRTarget at: cmpOffset) = 0])
	 and: [(self opcodeAt: bfOffset) = OilBranchFalse
	 and: [(self fieldAAt: bfOffset) = OilFlagsReg
	 and: [(oilIRTarget at: bfOffset) = 0]]]]]) ifFalse: [^self].
	exitOffset := self imm16At: bfOffset.
	(exitOffset > backJump or: [exitOffset < loopHead]) ifFalse: [^self].
	cond := self fieldAAt: cmpOffset.
	ivReg := self fieldBAt: cmpOffset.
	limitReg := self fieldCAt: cmpOffset.
	"Rotation: the test is duplicated at the bottom, without its deopt site, so it must not be able to fail; or, if the
	 limit may not be a SmallInteger but the loop does not assign it, with a clone of its deopt site (the bottom is the
	 header of the next iteration; see emitRotatedBackJump:at:)."
	(cond < OilCondIdentical
	 and: [(self isTagged: ivReg)
	 and: [isImm or: [(self isTagged: limitReg) or: [self canCheckLimit: limitReg test: cmpOffset loop: loopHead backJump: backJump]]]]) ifTrue:
		[self mark: backJump with: OilP2RotBack.
		 oilNumRotated := oilNumRotated + 1.
		 "a constant limit (at most 4095) bounds the induction variable at the test: its increments cannot overflow"
		 (isImm or: [(self constantLimit: limitReg test: cmpOffset loop: loopHead backJump: backJump) ~= 0]) ifTrue:
			[self markUncheckedSteps: ivReg cond: cond after: bfOffset backJump: backJump]].
	isImm ifTrue: [^self].
	"A counted loop?  ivReg <= limitReg (or ivReg < limitReg), limitReg the size of an object arrayReg that is never assigned (the receiver or
	 an argument), limitReg assigned only once, before the loop; ivReg assigned a constant >= 1 before the loop and only
	 incremented in the loop.  Then 1 <= ivReg <= limitReg holds after the test, and the increments cannot overflow."
	(cond = OilCondLe or: [cond = OilCondLt]) ifFalse: [^self].
	(ivReg ~= limitReg and: [ivReg < OilFlagsReg and: [limitReg < OilFlagsReg]]) ifFalse: [^self].
	(oilVRegDefs at: limitReg) = 1 ifFalse: [^self].
	regionStart := self regionStartBefore: loopHead.
	limitDef := -1.
	ivInit := -1.
	ivDefsInLoop := 0.
	irOffset := regionStart.
	[irOffset < backJump] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (irOffset < loopHead and: [self isCall: opcode]) ifTrue: [^self]. "(a call could become: arrayReg)"
		 (self opcodeHasDest: opcode) ifTrue:
			[(self fieldAAt: irOffset) = limitReg ifTrue: [limitDef := irOffset].
			 (self fieldAAt: irOffset) = ivReg ifTrue:
				[irOffset < loopHead
					ifTrue: [ivInit := irOffset]
					ifFalse:
						[(opcode = OilAddImmTagged
						  and: [(self fieldBAt: irOffset) = ivReg
						  and: [(self signed8: (self fieldCAt: irOffset)) > 0]]) ifFalse: [^self].
						 ivDefsInLoop := ivDefsInLoop + 1]]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	(limitDef >= 0 and: [limitDef < loopHead and: [(self opcodeAt: limitDef) = OilLoadSize or: [(self opcodeAt: limitDef) = OilLoadByteSize]]]) ifFalse: [^self].
	arrayReg := self fieldBAt: limitDef.
	(oilVRegDefs at: arrayReg) = 0 ifFalse: [^self].
	(ivInit >= 0 and: [(self opcodeAt: ivInit) = OilConstTagged]) ifFalse: [^self].
	ivInitValue := self signed16: (self imm16At: ivInit).
	((ivInitValue bitShift: -3) >= 1 "untagged (64-bit SmallIntegers have 3 tag bits)"
	 and: [(oilVRegDefs at: ivReg) = (1 + ivDefsInLoop)]) ifFalse: [^self].
	"The index increments cannot overflow: ivReg <= limitReg, a size, at the test, and each increment (by at most 127)
	 runs at most once per iteration."
	irOffset := loopHead.
	[irOffset < backJump] whileTrue:
		[((self opcodeHasDest: (self opcodeAt: irOffset)) and: [(self fieldAAt: irOffset) = ivReg]) ifTrue:
			[self mark: irOffset with: OilP2NoCheck.
			 oilNumNoCheck := oilNumNoCheck + 1].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	"After the test, in the straight-line code that follows it: size(arrayReg) is limitReg, and 1 <= ivReg <= limitReg (or a register
	 holding size(arrayReg)) needs no check."
	sizeAlias := -1.
	irOffset := bfOffset + 1.
	[irOffset < backJump and: [(oilIRTarget at: irOffset) = 0]] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 ((self isBranch: opcode) or: [opcode = OilReturn]) ifTrue: [^self].
		 (opcode = OilCheckBounds
		  and: [(self fieldAAt: irOffset) = ivReg
		  and: [(self fieldBAt: irOffset) = limitReg or: [(self fieldBAt: irOffset) = sizeAlias]]]) ifTrue:
			[self mark: irOffset with: OilP2Delete.
			 oilNumBoundsRemoved := oilNumBoundsRemoved + 1].
		 (self opcodeHasDest: opcode) ifTrue:
			[((self fieldAAt: irOffset) = ivReg or: [(self fieldAAt: irOffset) = limitReg]) ifTrue: [^self].
			 (self fieldAAt: irOffset) = sizeAlias ifTrue: [sizeAlias := -1].
			 (opcode = (self opcodeAt: limitDef) and: [(self fieldBAt: irOffset) = arrayReg]) ifTrue:
				[(self flag: irOffset has: OilP2ToMove) ifFalse:
					[oilNumSizesShared := oilNumSizesShared + 1].
				 self mark: irOffset with: OilP2ToMove.
				 oilIRAux at: irOffset put: limitReg.
				 sizeAlias := self fieldAAt: irOffset]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)]! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
removeInvariantChecksInLoop: loopHead backJump: backJump
	"In an innermost, call-free loop entered only by falling into loopHead: a class guard of a register that is never
	 assigned (the receiver or an argument) is redundant if the straight-line code falling into the loop, free of
	 calls (which could become: it), guards it already; and the size of such a register is the one that code loaded
	 into a register assigned only there."
	<inline: false>
	| regionStart irOffset opcode vreg sizeReg |
	regionStart := self regionStartBefore: loopHead.
	irOffset := regionStart.
	[irOffset < loopHead] whileTrue:
		[(self isCall: (self opcodeAt: irOffset)) ifTrue: [^self].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	irOffset := loopHead.
	[irOffset < backJump] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 vreg := opcode = OilGuardClass ifTrue: [self fieldAAt: irOffset] ifFalse: [self fieldBAt: irOffset].
		 (opcode = OilGuardClass
		  and: [(oilVRegDefs at: vreg) = 0
		  and: [self isGuarded: vreg class: (self word64At: irOffset + 1) from: regionStart to: loopHead]]) ifTrue:
			[self mark: irOffset with: OilP2Delete.
			 oilNumGuardsRemoved := oilNumGuardsRemoved + 1].
		 ((opcode = OilLoadSize or: [opcode = OilLoadByteSize])
		  and: [(oilVRegDefs at: vreg) = 0
		  and: [(sizeReg := self sizeRegisterOf: vreg op: opcode from: regionStart to: loopHead) >= 0]]) ifTrue:
			[self mark: irOffset with: OilP2ToMove.
			 oilIRAux at: irOffset put: sizeReg.
			 oilNumSizesShared := oilNumSizesShared + 1].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)]! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
isGuarded: vreg class: classOop from: startOffset to: endOffset
	"Is there an OilGuardClass of register vreg for classOop in the instructions from startOffset to endOffset?"
	| irOffset |
	irOffset := startOffset.
	[irOffset < endOffset] whileTrue:
		[((self opcodeAt: irOffset) = OilGuardClass
		  and: [(self fieldAAt: irOffset) = vreg
		  and: [(self word64At: irOffset + 1) = classOop
		  and: [(self flag: irOffset has: OilP2Delete) not]]]) ifTrue: [^true].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^false! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
sizeRegisterOf: objReg op: sizeOp from: startOffset to: endOffset
	"Answer a register assigned only once, by a sizeOp (OilLoadSize or OilLoadByteSize) of objReg in the instructions from
	 startOffset to endOffset, or -1."
	| irOffset |
	irOffset := startOffset.
	[irOffset < endOffset] whileTrue:
		[((self opcodeAt: irOffset) = sizeOp
		  and: [(self fieldBAt: irOffset) = objReg
		  and: [(oilVRegDefs at: (self fieldAAt: irOffset)) = 1
		  and: [(self flag: irOffset has: OilP2Delete + OilP2ToMove) not]]]) ifTrue: [^self fieldAAt: irOffset].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^-1! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
isLiveSite: siteIndex
	"Is deopt site siteIndex still attached to an instruction that can deoptimize?"
	| irOffset |
	irOffset := siteIR at: siteIndex.
	^irOffset >= 0 and: [(siteSnapBase at: siteIndex) >= 0 and: [(self flag: irOffset has: OilP2Delete + OilP2NoCheck) not]]! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
countMetadataUses
	"Count the registers the deoptimization metadata refers to: the states of the live deopt sites, the receivers
	 of the inlined frames and of the virtual objects, and the values the virtual objects captured."
	| snapBase stateSize |
	0 to: numSites - 1 do:
		[:siteIndex|
		(self isLiveSite: siteIndex) ifTrue:
			[snapBase := siteSnapBase at: siteIndex.
			 stateSize := self siteStateSize: siteIndex.
			 0 to: stateSize - 1 do:
				[:slotIndex| (sitePoolKind at: snapBase + slotIndex) = OilDescReg ifTrue:
					[self recordUse: (sitePoolValue at: snapBase + slotIndex)]]]].
	0 to: numFrames - 1 do:
		[:frameIndex| (frameSelfKind at: frameIndex) = OilDescReg ifTrue:
			[self recordUse: (frameSelfValue at: frameIndex)]].
	0 to: numVObjs - 1 do:
		[:vobjIndex|
		(vobjSelfKind at: vobjIndex) = OilDescReg ifTrue:
			[self recordUse: (vobjSelfValue at: vobjIndex)].
		0 to: (vobjNumCopied at: vobjIndex) - 1 do:
			[:slotIndex| (capturedKind at: (vobjCopiedBase at: vobjIndex) + slotIndex) = OilDescReg ifTrue:
				[self recordUse: (capturedValue at: (vobjCopiedBase at: vobjIndex) + slotIndex)]]]! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
eliminateDeadCode
	"Delete the pure instructions whose destination nothing reads (anywhere, or before it is assigned again in the
	 straight-line code that follows), until there are none."
	| changed irOffset |
	oilUseWeight := 1.
	changed := true.
	[changed] whileTrue:
		[changed := false.
		 0 to: OilNumRegs - 1 do:
			[:vreg| oilVRegUses at: vreg put: 0].
		 irOffset := 0.
		 [irOffset < irIndex] whileTrue:
			[(self flag: irOffset has: OilP2Delete) ifFalse:
				[(self flag: irOffset has: OilP2ToMove)
					ifTrue: [self recordUse: (oilIRAux at: irOffset)]
					ifFalse: [self countUsesAt: irOffset]].
			 irOffset := irOffset + (self instructionLengthAt: irOffset)].
		 self countMetadataUses.
		 irOffset := 0.
		 [irOffset < irIndex] whileTrue:
			[((self flag: irOffset has: OilP2Delete) not
			  and: [(self isPureAt: irOffset)
			  and: [(self fieldAAt: irOffset) < OilFlagsReg
			  and: [(oilVRegUses at: (self fieldAAt: irOffset)) = 0
					or: [self isOverwrittenBeforeUse: (self fieldAAt: irOffset) after: irOffset]]]]) ifTrue:
				[self mark: irOffset with: OilP2Delete.
				 oilNumDeadRemoved := oilNumDeadRemoved + 1.
				 changed := true].
			 irOffset := irOffset + (self instructionLengthAt: irOffset)]]! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
isOverwrittenBeforeUse: vreg after: defOffset
	"Is register vreg, assigned by the instruction at defOffset, assigned again before anything reads it?  Only the straight-line
	 code after defOffset is examined (up to a branch target, a branch, a return or a call, where vreg is assumed live).
	 Reads are instruction operands and the deopt states of the instructions' live sites."
	<inline: false>
	| irOffset opcode siteIndex |
	irOffset := defOffset + (self instructionLengthAt: defOffset).
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 ((oilIRTarget at: irOffset) ~= 0
		  or: [(self isBranch: opcode) or: [opcode = OilReturn or: [self isCall: opcode]]]) ifTrue: [^false].
		 (self flag: irOffset has: OilP2Delete) ifFalse:
			[oilUseProbe := vreg.
			 oilUseProbeHit := false.
			 (self flag: irOffset has: OilP2ToMove)
				ifTrue: [self recordUse: (oilIRAux at: irOffset)]
				ifFalse: [self countUsesAt: irOffset].
			 oilUseProbe := -1.
			 oilUseProbeHit ifTrue: [^false].
			 siteIndex := oilIRSite at: irOffset.
			 (siteIndex >= 0 and: [(self isLiveSite: siteIndex) and: [self state: siteIndex refersTo: vreg]]) ifTrue: [^false].
			 ((self opcodeHasDest: opcode) and: [(self fieldAAt: irOffset) = vreg]) ifTrue: [^true]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^false! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
state: siteIndex refersTo: vreg
	"Does the deopt state of site siteIndex refer to register vreg?"
	| snapBase stateSize |
	snapBase := siteSnapBase at: siteIndex.
	stateSize := self siteStateSize: siteIndex.
	0 to: stateSize - 1 do:
		[:slotIndex| ((sitePoolKind at: snapBase + slotIndex) = OilDescReg and: [(sitePoolValue at: snapBase + slotIndex) = vreg]) ifTrue: [^true]].
	^false! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
rotatedHeaderCompareOf: backJump
	"The OilCmpTagged of the header of the rotated loop closed by the Jump at backJump (see optimizeLoop:backJump:)."
	| irOffset |
	irOffset := self imm16At: backJump.
	[(self opcodeAt: irOffset) = OilCmpTagged or: [(self opcodeAt: irOffset) = OilCmpImmTagged]] whileFalse:
		[irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^irOffset! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 21:00'!
canCheckLimit: limitReg test: cmpOffset loop: loopHead backJump: backJump
	"Can the test at cmpOffset of the loop from loopHead to backJump, of a limit limitReg that may not be a SmallInteger, be
	 duplicated at the bottom of the loop with a clone of its deopt site?  The loop must not assign limitReg, the site must
	 have a state, and there must be room for the clone (and one more, see partiallyUnrollLoop:backJump:)."
	| siteIndex |
	siteIndex := oilIRSite at: cmpOffset.
	(limitReg < OilFlagsReg
	 and: [siteIndex >= 0
	 and: [(siteSnapBase at: siteIndex) >= 0
	 and: [numSites + oilUnrollClones + 2 <= OilMaxSites
	 and: [(self isAssigned: limitReg from: loopHead to: backJump - 1) not]]]]) ifFalse: [^false].
	oilUnrollClones := oilUnrollClones + 1.
	^true! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 21:00'!
emitTestCopy: cmpOffset at: dstOffset
	"Emit a copy of the loop test at cmpOffset: with a clone of its deopt site if its limit may not be a SmallInteger (see
	 canCheckLimit:test:loop:backJump:).  Answer the index following it in Buffer 2."
	((self opcodeAt: cmpOffset) = OilCmpTagged and: [(self isTagged: (self fieldCAt: cmpOffset)) not]) ifTrue:
		[self cloneSite: (oilIRSite at: cmpOffset) at: dstOffset].
	^self emitInstructionAt: cmpOffset at: dstOffset! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 21:00'!
markUncheckedSteps: ivReg cond: cond after: bfOffset backJump: backJump
	"The rotated loop ending with the Jump at backJump tests ivReg < or <= a constant (at most 4095) before the branch at bfOffset
	 that leaves it.  If the loop only increments ivReg (by at most 127 each time), and only after that test, the increments
	 cannot overflow: mark them unchecked (OilP2NoCheck)."
	| irOffset opcode |
	(cond = OilCondLe or: [cond = OilCondLt]) ifFalse: [^self].
	irOffset := self imm16At: backJump.
	[irOffset < backJump] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 ((self opcodeHasDest: opcode) and: [(self fieldAAt: irOffset) = ivReg]) ifTrue:
			[(irOffset > bfOffset
			  and: [opcode = OilAddImmTagged
			  and: [(self fieldBAt: irOffset) = ivReg
			  and: [(self signed8: (self fieldCAt: irOffset)) > 0]]]) ifFalse: [^self]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	irOffset := bfOffset.
	[irOffset < backJump] whileTrue:
		[((self opcodeHasDest: (self opcodeAt: irOffset)) and: [(self fieldAAt: irOffset) = ivReg]) ifTrue:
			[self mark: irOffset with: OilP2NoCheck.
			 oilNumNoCheck := oilNumNoCheck + 1].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)]! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
sizeOfRotatedBackJump: backJump
	"The size of what replaces the back jump of a rotated loop: a copy of the header (its live instructions) and of
	 its test, a branch back if the test holds, and a jump to the exit if the exit does not follow the loop."
	| irOffset cmpOffset totalWords |
	cmpOffset := self rotatedHeaderCompareOf: backJump.
	totalWords := 2.
	irOffset := self imm16At: backJump.
	[irOffset < cmpOffset] whileTrue:
		[(self flag: irOffset has: OilP2Delete) ifFalse:
			[totalWords := totalWords + (self instructionLengthAt: irOffset)].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	(self imm16At: cmpOffset + 1) ~= (backJump + (self instructionLengthAt: backJump)) ifTrue:
		[totalWords := totalWords + 1].
	^totalWords! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
emitInstructionAt: srcOffset at: dstOffset
	"Copy the instruction at srcOffset of Buffer 1 to dstOffset in Buffer 2, applying its Pass 2 rewrites and remapping its branch
	 target.  Answer the index following it in Buffer 2."
	| opcode word instrLen |
	opcode := self opcodeAt: srcOffset.
	instrLen := self instructionLengthAt: srcOffset.
	word := oilIRBuffer1 at: srcOffset.
	(self flag: srcOffset has: OilP2ToMove) ifTrue:
		[word := (OilMove bitShift: 24) + ((self fieldAAt: srcOffset) bitShift: 16) + ((oilIRAux at: srcOffset) bitShift: 8)].
	(self flag: srcOffset has: OilP2NoCheck) ifTrue:
		[word := (word bitAnd: 16rFFFFFF) + (OilAddImmTaggedNC bitShift: 24)].
	(self isBranch: opcode) ifTrue:
		[word := (word bitAnd: 16rFFFF0000) + (oilIRMap at: (self imm16At: srcOffset))].
	oilIRBuffer2 at: dstOffset put: word.
	1 to: instrLen - 1 do:
		[:k| oilIRBuffer2 at: dstOffset + k put: (oilIRBuffer1 at: srcOffset + k)].
	^dstOffset + instrLen! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
emitRotatedBackJump: backJump at: startOffset
	"The bottom of a rotated loop: the header and its test again, then branch back to the first instruction after the
	 header's test if it holds, else go to the exit."
	| irOffset cmpOffset dstOffset exitTarget |
	cmpOffset := self rotatedHeaderCompareOf: backJump.
	dstOffset := startOffset.
	irOffset := self imm16At: backJump.
	[irOffset < cmpOffset] whileTrue:
		[(self flag: irOffset has: OilP2Delete) ifFalse:
			[dstOffset := self emitInstructionAt: irOffset at: dstOffset].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	dstOffset := self emitTestCopy: cmpOffset at: dstOffset.
	oilIRBuffer2 at: dstOffset put: (OilBranchTrue bitShift: 24) + (OilFlagsReg bitShift: 16) + (oilIRMap at: cmpOffset + 2).
	dstOffset := dstOffset + 1.
	exitTarget := self imm16At: cmpOffset + 1.
	exitTarget ~= (backJump + (self instructionLengthAt: backJump)) ifTrue:
		[oilIRBuffer2 at: dstOffset put: (OilJump bitShift: 24) + (oilIRMap at: exitTarget).
		 dstOffset := dstOffset + 1].
	^dstOffset! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
emitOptimizedIR
	"Stream Buffer 1 into Buffer 2: lay out (the index in Buffer 2 of every instruction of Buffer 1, in oilIRMap),
	 then emit, then remap the deopt sites, whose instructions were deleted or no longer deoptimize (dead, -2) or moved.
	 Buffer 2 becomes the current IR."
	| srcOffset dstOffset instrLen siteIROffset numOriginalSites |
	dstOffset := 0.
	srcOffset := 0.
	[srcOffset < irIndex] whileTrue:
		[instrLen := self instructionLengthAt: srcOffset.
		 oilIRMap at: srcOffset put: dstOffset.
		 (self flag: srcOffset has: OilP2Unroll)
			ifTrue: "a fully unrolled loop, to its back jump"
				[dstOffset := self layOutFullyUnrolledLoop: (self unrollIndexOf: srcOffset) at: dstOffset.
				 instrLen := (oilUnrollBack at: (self unrollIndexOf: srcOffset)) + 1 - srcOffset]
			ifFalse:
				[(self flag: srcOffset has: OilP2Delete) ifFalse:
					[dstOffset := dstOffset + ((self flag: srcOffset has: OilP2RotBack)
								ifTrue: [self sizeOfRotatedBackJump: srcOffset]
								ifFalse: [instrLen]).
					 (self flag: srcOffset has: OilP2UnrollPartial) ifTrue:
						[dstOffset := dstOffset + (self sizeOfPartiallyUnrolledLoop: (self unrollIndexOf: srcOffset))]]].
		 srcOffset := srcOffset + instrLen].
	oilIRMap at: irIndex put: dstOffset.
	dstOffset > OilBufferWords ifTrue:
		[self abortCompilation: OilFailBufferFull.
		 ^failureCode].
	"Copies of instructions get clones of their deopt sites, at their index in Buffer 2 (see emitCopyOf:at:shift:from:to:)."
	numOriginalSites := numSites.
	dstOffset := 0.
	srcOffset := 0.
	[srcOffset < irIndex] whileTrue:
		[instrLen := self instructionLengthAt: srcOffset.
		 (self flag: srcOffset has: OilP2Unroll)
			ifTrue:
				[dstOffset := self emitFullyUnrolledLoop: (self unrollIndexOf: srcOffset) at: dstOffset.
				 instrLen := (oilUnrollBack at: (self unrollIndexOf: srcOffset)) + 1 - srcOffset]
			ifFalse:
				[(self flag: srcOffset has: OilP2Delete) ifFalse:
					[dstOffset := (self flag: srcOffset has: OilP2RotBack)
							ifTrue: [self emitRotatedBackJump: srcOffset at: dstOffset]
							ifFalse: [self emitInstructionAt: srcOffset at: dstOffset].
					 (self flag: srcOffset has: OilP2UnrollPartial) ifTrue:
						[dstOffset := self emitPartiallyUnrolledLoop: (self unrollIndexOf: srcOffset) at: dstOffset]]].
		 srcOffset := srcOffset + instrLen].
	self assert: dstOffset = (oilIRMap at: irIndex).
	0 to: numOriginalSites - 1 do:
		[:siteIndex|
		siteIROffset := siteIR at: siteIndex.
		siteIROffset >= 0 ifTrue:
			[siteIR at: siteIndex put: ((self flag: siteIROffset has: OilP2Delete + OilP2NoCheck)
									ifTrue: [-2]
									ifFalse: [oilIRMap at: siteIROffset])]].
	oilIRBuffer := oilIRBuffer2.
	irIndex := dstOffset.
	^OilOK! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
unrollLoops
	"Unroll the innermost leaf loops (no sends) whose iterations are counted: fully if their number is a small
	 constant (fullyUnrollLoop:backJump:), else 2 or 4 times, with the rotated loop as the remainder
	 (partiallyUnrollLoop:backJump:).  Run after dead code elimination: the loops' instructions are final, the copies
	 are made by the emission (emitOptimizedIR), with clones of their deopt sites."
	| irOffset |
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[((self opcodeAt: irOffset) = OilJump and: [(self imm16At: irOffset) <= irOffset]) ifTrue:
			[(self fullyUnrollLoop: (self imm16At: irOffset) backJump: irOffset) ifFalse:
				[self partiallyUnrollLoop: (self imm16At: irOffset) backJump: irOffset]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)]! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
oilResetUnrollParameters
	"Use the default unrolling thresholds (OilUnrollMaxTrips, OilUnrollFullBudget, OilUnrollTinyBody, OilUnrollMaxBody)."
	oilUnrollMode := oilUnrollTinyBody := oilUnrollMaxBody := oilUnrollBudget := oilUnrollMaxTrips := oilLoopAlignment := oilCodeShift := 0! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
codeShift
	"A measurement aid (parameter 18 of primitiveOilSetParameter, default 0): the number of one byte nops before the method body,
	 which moves its code by that many bytes, so that benchmarks can average over the placements of its loops."
	^oilCodeShift max: 0! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
loopAlignment
	"The alignment (in bytes, at most 16) of the loop headers (OilLoopAlignment, or parameter 17 of primitiveOilSetParameter; 1 for
	 none): the fall-through into the loop runs the padding (nops).  How the instructions of a loop fall on 16 and 32 byte
	 boundaries changes its speed a lot (up to 1.5 times) from one compilation to another; aligning the headers to 16 bytes
	 makes it faster on average and less erratic."
	^(self unrollParameter: oilLoopAlignment default: OilLoopAlignment) min: 16 "(see genLoopAlignment)"! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
oilUnrollParameter: kind value: value
	"Set a loop unrolling parameter (parameters 12 to 18 of primitiveOilSetParameter): 12 the mode, whose
	 bits disable full unrolling (1), partial unrolling (2), the store check elimination of young objects (4) and the float
	 loop registers (16), and allow partial unrolling of bodies with branches (8); 13 the
	 largest body unrolled 4 times; 14 the largest body unrolled twice; 15 the budget of full unrolling (iterations * body
	 size); 16 the most iterations fully unrolled; 17 the alignment of loop headers (see loopAlignment); 18 the code shift
	 (see codeShift).  0 (or less) means the default."
	kind = 12 ifTrue: [oilUnrollMode := value].
	kind = 13 ifTrue: [oilUnrollTinyBody := value].
	kind = 14 ifTrue: [oilUnrollMaxBody := value].
	kind = 15 ifTrue: [oilUnrollBudget := value].
	kind = 16 ifTrue: [oilUnrollMaxTrips := value].
	kind = 17 ifTrue: [oilLoopAlignment := value].
	kind = 18 ifTrue: [oilCodeShift := value min: 64]! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
unrollParameter: value default: defaultValue
	<inline: true>
	^value > 0 ifTrue: [value] ifFalse: [defaultValue]! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
unrollIndexOf: irOffset
	"The index of the unrolled loop whose header (fully unrolled) or exit branch (partially unrolled) is at irOffset."
	0 to: oilNumUnrolls - 1 do:
		[:unrollIndex|
		(((oilUnrollHead at: unrollIndex) = irOffset and: [self flag: irOffset has: OilP2Unroll])
		 or: [(oilUnrollTest at: unrollIndex) + 1 = irOffset and: [self flag: irOffset has: OilP2UnrollPartial]]) ifTrue:
			[^unrollIndex]].
	self abortCompilation: OilFailInternal.
	^0! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
isStepAt: irOffset
	"Is the instruction at irOffset r := r + c, an AddImmTagged (checked or not) of a register to itself?"
	| opcode |
	opcode := self opcodeAt: irOffset.
	^(opcode = OilAddImmTagged or: [opcode = OilAddImmTaggedNC])
	  and: [(self fieldAAt: irOffset) = (self fieldBAt: irOffset)]! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
condition: cond holdsFor: leftValue and: rightValue
	"Does leftValue cond rightValue hold (cond one of OilCondLt .. OilCondNe)?"
	cond = OilCondLt ifTrue: [^leftValue < rightValue].
	cond = OilCondGt ifTrue: [^leftValue > rightValue].
	cond = OilCondLe ifTrue: [^leftValue <= rightValue].
	cond = OilCondGe ifTrue: [^leftValue >= rightValue].
	cond = OilCondEq ifTrue: [^leftValue = rightValue].
	^leftValue ~= rightValue! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
stepOf: ivReg from: startOffset before: backJump
	"The index of the step ivReg := ivReg + c in the loop body from startOffset to before the back jump at backJump, if it is
	 the only assignment of ivReg there and runs every iteration (no branch nor branch target follows it: it is in the
	 straight-line code ending with the back jump).  Else -1."
	| irOffset opcode stepOffset |
	stepOffset := -1.
	irOffset := startOffset.
	[irOffset < backJump] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (stepOffset >= 0
		  and: [(oilIRTarget at: irOffset) ~= 0 or: [(self isBranch: opcode) or: [opcode = OilReturn]]]) ifTrue: [^-1].
		 ((self flag: irOffset has: OilP2Delete) not
		  and: [(self opcodeHasDest: opcode) and: [(self fieldAAt: irOffset) = ivReg]]) ifTrue:
			[(stepOffset < 0 and: [self isStepAt: irOffset]) ifFalse: [^-1].
			 stepOffset := irOffset].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^stepOffset! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
entryConstantOf: vreg before: loopHead
	"The tagged constant register vreg holds when the loop at loopHead is entered by falling into it: the last
	 assignment of vreg in the straight-line code before loopHead is an OilConstTagged.  Answer 0 (no SmallInteger) if
	 it is not known."
	| irOffset defOffset |
	defOffset := -1.
	irOffset := self regionStartBefore: loopHead.
	[irOffset < loopHead] whileTrue:
		[((self flag: irOffset has: OilP2Delete) not
		  and: [(self opcodeHasDest: (self opcodeAt: irOffset)) and: [(self fieldAAt: irOffset) = vreg]]) ifTrue:
			[defOffset := irOffset].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	(defOffset >= 0 and: [(self opcodeAt: defOffset) = OilConstTagged]) ifFalse: [^0].
	^self signed16: (self imm16At: defOffset)! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
isUnrollableLoop: loopHead backJump: backJump
	"Can the loop from loopHead to the Jump at backJump be copied?  It must be innermost and a leaf (no send, nor
	 intrinsic falling back to one), entered only by falling into loopHead (no branch from outside into it), its branches
	 forward, either inside it (but not to the back jump, so that what precedes the back jump runs every iteration) or out of
	 it, and room must be left for another unrolled loop."
	| irOffset opcode target |
	(oilNumUnrolls < OilMaxUnrolls
	 and: [(oilIRTarget at: loopHead) = 1
	 and: [(oilIRTarget at: backJump) = 0]]) ifFalse: [^false].
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (irOffset >= loopHead and: [irOffset < backJump])
			ifTrue:
				[(self isCall: opcode) ifTrue: [^false].
				 (self isBranch: opcode) ifTrue:
					[target := self imm16At: irOffset.
					 (target <= irOffset or: [target = backJump]) ifTrue: [^false]]]
			ifFalse:
				[(irOffset ~= backJump and: [self isBranch: opcode]) ifTrue:
					[target := self imm16At: irOffset.
					 (target > loopHead and: [target <= backJump]) ifTrue: [^false]]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^true! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
copySitesFrom: startOffset to: endOffset
	"The number of deopt sites a copy of the instructions from startOffset to before endOffset clones."
	| irOffset numSitesInCopy |
	numSitesInCopy := 0.
	irOffset := startOffset.
	[irOffset < endOffset] whileTrue:
		[((oilIRSite at: irOffset) >= 0 and: [(self flag: irOffset has: OilP2Delete + OilP2NoCheck) not]) ifTrue:
			[numSitesInCopy := numSitesInCopy + 1].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^numSitesInCopy! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
canGrowBy: numWords sites: numClones
	"Can the IR grow by numWords more words and numClones more deopt sites (margin left for the rotated loops)?"
	^irIndex + oilUnrollGrowth + numWords + 256 < OilBufferWords
	  and: [numSites + oilUnrollClones + numClones <= OilMaxSites]! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
fullyUnrollLoop: loopHead backJump: backJump
	"If the loop from loopHead to the Jump at backJump runs a number of iterations known now, at most OilUnrollMaxTrips,
	 and iterations * body size (its instructions but the test and the induction steps) is at most OilUnrollFullBudget,
	 record it to be replaced by that many copies of its body, without test, branch or back jump (see
	 emitFullyUnrolledLoop:at:), and answer true.
	 The loop: a header of pure instructions without deopt sites and steps (r := r + c) of the induction variable, an
	 OilCmpTagged (or OilCmpImmTagged) of the induction variable with a limit and an OilBranchFalse leaving the loop, the
	 body, possibly with a step of the induction variable in its last straight-line code.  Nothing else assigns the induction variable in the loop,
	 its value is a constant when the loop is entered, and the limit is a constant (an immediate, or a register assigned
	 a constant before the loop or by the header).  The copies assign the induction variable its values (OilConstTagged)
	 instead of stepping it, and the tests, known to hold, go."
	| irOffset opcode cmpOffset bfOffset tailOffset cond ivReg limitValue ivValue headerStep tailStep stepMagnitude trips bodySize copyWords headerWords |
	((oilUnrollMode bitAnd: 1) = 0
	 and: [self isUnrollableLoop: loopHead backJump: backJump]) ifFalse: [^false].
	"The header, then the test."
	irOffset := loopHead.
	[opcode := self opcodeAt: irOffset.
	 opcode ~= OilCmpTagged and: [opcode ~= OilCmpImmTagged]] whileTrue:
		[((irOffset = loopHead or: [(oilIRTarget at: irOffset) = 0])
		  and: [(self flag: irOffset has: OilP2Delete)
				or: [(self isStepAt: irOffset)
				or: [(self isPureAt: irOffset) and: [(oilIRSite at: irOffset) < 0]]]]) ifFalse: [^false].
		 irOffset := irOffset + (self instructionLengthAt: irOffset).
		 irOffset >= backJump ifTrue: [^false]].
	cmpOffset := irOffset.
	bfOffset := cmpOffset + 1.
	((cmpOffset = loopHead or: [(oilIRTarget at: cmpOffset) = 0])
	 and: [bfOffset < backJump
	 and: [(self opcodeAt: bfOffset) = OilBranchFalse
	 and: [(self fieldAAt: bfOffset) = OilFlagsReg
	 and: [(oilIRTarget at: bfOffset) = 0
	 and: [(self imm16At: bfOffset) > backJump]]]]]) ifFalse: [^false].
	cond := self fieldAAt: cmpOffset.
	ivReg := self fieldBAt: cmpOffset.
	(cond < OilCondIdentical and: [ivReg < OilFlagsReg]) ifFalse: [^false].
	"The limit."
	(self opcodeAt: cmpOffset) = OilCmpImmTagged
		ifTrue: [limitValue := self signed8: (self fieldCAt: cmpOffset)]
		ifFalse:
			[(self fieldCAt: cmpOffset) = ivReg ifTrue: [^false].
			 limitValue := self constantLimit: (self fieldCAt: cmpOffset) test: cmpOffset loop: loopHead backJump: backJump.
			 limitValue = 0 ifTrue: [^false].
			 limitValue := (limitValue - 1) bitShift: -3].
	"The induction variable: the steps of the header, and a step of the body that runs every iteration."
	ivValue := self entryConstantOf: ivReg before: loopHead.
	ivValue = 0 ifTrue: [^false].
	ivValue := (ivValue - 1) bitShift: -3.
	tailOffset := self stepOf: ivReg from: bfOffset + 1 before: backJump.
	headerStep := tailStep := stepMagnitude := 0.
	irOffset := loopHead.
	[irOffset < backJump] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 ((self opcodeHasDest: opcode) and: [(self fieldAAt: irOffset) = ivReg]) ifTrue:
			[((self isStepAt: irOffset)
			  and: [(self flag: irOffset has: OilP2Delete) not
			  and: [irOffset < cmpOffset or: [irOffset = tailOffset]]]) ifFalse: [^false].
			 stepMagnitude := stepMagnitude + (self signed8: (self fieldCAt: irOffset)) abs.
			 irOffset < cmpOffset
				ifTrue: [headerStep := headerStep + (self signed8: (self fieldCAt: irOffset))]
				ifFalse: [tailStep := self signed8: (self fieldCAt: irOffset)]].
		 "a step of another register in the header would need its deopt site"
		 (irOffset < cmpOffset
		  and: [(self isStepAt: irOffset)
		  and: [(self fieldAAt: irOffset) ~= ivReg
		  and: [(self flag: irOffset has: OilP2Delete + OilP2NoCheck) not]]]) ifTrue: [^false].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	"Count the iterations."
	(ivValue abs <= 2048 and: [stepMagnitude <= 255]) ifFalse: [^false]. "(the values fit OilConstTagged)"
	trips := 0.
	[ivValue := ivValue + headerStep.
	 self condition: cond holdsFor: ivValue and: limitValue] whileTrue:
		[trips := trips + 1.
		 trips > (self unrollParameter: oilUnrollMaxTrips default: OilUnrollMaxTrips) ifTrue: [^false].
		 ivValue := ivValue + tailStep].
	trips = 0 ifTrue: [^false].
	"The budget, the room."
	bodySize := headerWords := copyWords := 0.
	irOffset := loopHead.
	[irOffset < backJump] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (irOffset ~= cmpOffset and: [irOffset ~= bfOffset]) ifTrue:
			[((self opcodeHasDest: opcode) and: [(self fieldAAt: irOffset) = ivReg])
				ifTrue: [copyWords := copyWords + 1]
				ifFalse:
					[(self flag: irOffset has: OilP2Delete) ifFalse:
						[bodySize := bodySize + 1.
						 copyWords := copyWords + (self instructionLengthAt: irOffset)]]].
		 irOffset = cmpOffset ifTrue: [headerWords := copyWords].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	(trips * bodySize <= (self unrollParameter: oilUnrollBudget default: OilUnrollFullBudget)
	 and: [self canGrowBy: (trips * copyWords) + headerWords + 1
			sites: (trips - 1) * (self copySitesFrom: bfOffset + 1 to: backJump)]) ifFalse: [^false].
	"Record it.  The test and the steps go, with their deopt sites."
	oilUnrollHead at: oilNumUnrolls put: loopHead.
	oilUnrollBack at: oilNumUnrolls put: backJump.
	oilUnrollTest at: oilNumUnrolls put: cmpOffset.
	oilUnrollCount at: oilNumUnrolls put: trips.
	oilUnrollIV at: oilNumUnrolls put: ivReg.
	oilUnrollValue at: oilNumUnrolls put: (self entryConstantOf: ivReg before: loopHead) - 1 >> 3.
	oilUnrollWord1 at: oilNumUnrolls put: headerWords.
	oilUnrollWord2 at: oilNumUnrolls put: copyWords.
	oilNumUnrolls := oilNumUnrolls + 1.
	oilUnrollGrowth := oilUnrollGrowth + (trips * copyWords) + headerWords + 1.
	oilUnrollClones := oilUnrollClones + ((trips - 1) * (self copySitesFrom: bfOffset + 1 to: backJump)).
	oilNumFullyUnrolled := oilNumFullyUnrolled + 1.
	self mark: loopHead with: OilP2Unroll.
	self mark: cmpOffset with: OilP2Delete.
	irOffset := loopHead.
	[irOffset < backJump] whileTrue:
		[((self opcodeHasDest: (self opcodeAt: irOffset)) and: [(self fieldAAt: irOffset) = ivReg]) ifTrue:
			[self mark: irOffset with: OilP2Delete].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^true! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
constantLimit: limitReg test: cmpOffset loop: loopHead backJump: backJump
	"The tagged constant register limitReg holds at the test at cmpOffset of the loop from loopHead to backJump: the header
	 assigns it a constant, or nothing in the loop assigns it and it holds a constant when the loop is entered.  Answer 0 if
	 it is not known."
	| irOffset value |
	limitReg >= OilFlagsReg ifTrue: [^0].
	value := 0.
	irOffset := loopHead.
	[irOffset < backJump] whileTrue:
		[((self opcodeHasDest: (self opcodeAt: irOffset)) and: [(self fieldAAt: irOffset) = limitReg]) ifTrue:
			[((self opcodeAt: irOffset) = OilConstTagged
			  and: [irOffset < cmpOffset
			  and: [(self flag: irOffset has: OilP2Delete) not
			  and: [value = 0 or: [value = (self signed16: (self imm16At: irOffset))]]]]) ifFalse: [^0].
			 value := self signed16: (self imm16At: irOffset)].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	value ~= 0 ifTrue: [^value].
	^self entryConstantOf: limitReg before: loopHead! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
unrollFreeRegister
	"A virtual register that no instruction assigns or reads and that no deopt state, inlined frame or virtual object refers
	 to, to hold the limit of partially unrolled loops (dead outside them).  Answer -1 if there is none."
	| numArgs |
	oilUnrollFreeReg >= -1 ifTrue: [^oilUnrollFreeReg].
	oilUnrollFreeReg := -1.
	numArgs := self numArgsOf: oilHomeMethod.
	numArgs + 1 to: highRegTop - 1 do:
		[:vreg|
		(oilUnrollFreeReg < 0
		 and: [(oilVRegDefs at: vreg) = 0
		 and: [(oilVRegUses at: vreg) = 0
		 and: [(self isVirtualObjectSlot: vreg) not]]]) ifTrue:
			[oilUnrollFreeReg := vreg]].
	^oilUnrollFreeReg! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
isVirtualObjectSlot: vreg
	"Does register vreg hold a slot of a virtual temp vector or object (which the deopt metadata refers to)?"
	0 to: numVObjs - 1 do:
		[:vobjIndex|
		((vobjKind at: vobjIndex) ~= OilDescBlock
		 and: [vreg >= (vobjSlotBase at: vobjIndex)
		 and: [vreg < ((vobjSlotBase at: vobjIndex) + (vobjSize at: vobjIndex))]]) ifTrue: [^true]].
	^false! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
partiallyUnrollLoop: loopHead backJump: backJump
	"If the loop from loopHead to the Jump at backJump is a rotated (see optimizeLoop:backJump:) leaf loop counting up,
	 ivReg < or <= limit (an immediate, or a register the loop does not assign), whose body has one step of the induction
	 variable ivReg := ivReg + c (c > 0), running every iteration, and assigns it nowhere else, record it to be unrolled k times (k = 4 if its body has at most
	 OilUnrollTinyBody instructions but the step, else k = 2 if at most OilUnrollMaxBody), see
	 emitPartiallyUnrolledLoop:at:.  After the header's test:
		[limit2 := limit - ((k - 1) * c)]	(unless the limit is an immediate, or k * c = 2 and the test is <=: ivReg < limit)
		ivReg cond limit2, else go to R		(k iterations left?)
	 U:	body ... body (k copies, each ending with its step)
		ivReg cond limit2, if so go to U
		ivReg cond limit, else exit
	 R:	the rotated loop (the remainder, at most k - 1 iterations).
	 The copies of the body run with ivReg <= limit, as the original does, so its bounds check eliminations and unchecked
	 increments (see optimizeLoop:backJump:) hold for them.  limit2 cannot overflow: limit >= ivReg >= its constant
	 initial value after the header's test."
	| cmpOffset bfOffset irOffset opcode cond ivReg limitReg isImm tailOffset step bodySize bodyWords factor reach immValue cmpWord limitWord limit2Reg numClones |
	((oilUnrollMode bitAnd: 2) = 0
	 and: [(self flag: backJump has: OilP2RotBack)
	 and: [self isUnrollableLoop: loopHead backJump: backJump]]) ifFalse: [^false].
	cmpOffset := self rotatedHeaderCompareOf: backJump.
	bfOffset := cmpOffset + 1.
	cond := self fieldAAt: cmpOffset.
	ivReg := self fieldBAt: cmpOffset.
	isImm := (self opcodeAt: cmpOffset) = OilCmpImmTagged.
	limitReg := self fieldCAt: cmpOffset.
	(cond = OilCondLe or: [cond = OilCondLt]) ifFalse: [^false].
	"The header (it runs only before the tests of the remainder): constants assigning registers the body does not assign."
	irOffset := loopHead.
	[irOffset < cmpOffset] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 ((self flag: irOffset has: OilP2Delete)
		  or: [(opcode = OilConstTagged or: [opcode = OilConst64])
			   and: [(self isAssigned: (self fieldAAt: irOffset) from: bfOffset + 1 to: backJump - 1) not]]) ifFalse: [^false].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	(isImm or: [(self isAssigned: limitReg from: bfOffset + 1 to: backJump - 1) not]) ifFalse: [^false].
	"The step."
	tailOffset := self stepOf: ivReg from: bfOffset + 1 before: backJump.
	(tailOffset >= 0
	 and: [(step := self signed8: (self fieldCAt: tailOffset)) > 0
	 and: [(self isAssigned: ivReg from: loopHead to: cmpOffset) not]]) ifFalse: [^false].
	"The factor.  A body with branches (but deopts) is not unrolled (unless mode bit 8): measured, its copies are not
	 faster, the branches cost as much as the loop's.  Nor one with float arithmetic: its variables get XMM registers instead
	 (Pass 3, prepareFloatLoops), and its additions are a chain of dependent instructions anyway."
	bodySize := bodyWords := 0.
	irOffset := bfOffset + 1.
	[irOffset < backJump] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (self flag: irOffset has: OilP2Delete) ifFalse:
			[((oilUnrollMode bitAnd: 8) = 0
			  and: [(self isBranch: opcode) or: [opcode = OilReturn]]) ifTrue: [^false].
			 ((opcode between: OilAddFloat and: OilCmpFloat) and: [self floatLoopsEnabled]) ifTrue: [^false]. "(see prepareFloatLoops)"
			 irOffset ~= tailOffset ifTrue: [bodySize := bodySize + 1].
			 bodyWords := bodyWords + (self instructionLengthAt: irOffset)].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	bodySize <= (self unrollParameter: oilUnrollTinyBody default: OilUnrollTinyBody)
		ifTrue: [factor := 4]
		ifFalse:
			[bodySize <= (self unrollParameter: oilUnrollMaxBody default: OilUnrollMaxBody)
				ifTrue: [factor := 2]
				ifFalse: [^false]].
	"The test of the unrolled loop."
	reach := factor - 1 * step.
	limitWord := 0.
	isImm
		ifTrue:
			[immValue := (self signed8: limitReg) - reach.
			 immValue < -128 ifTrue: [^false].
			 cmpWord := (OilCmpImmTagged << 24) + (cond << 16) + (ivReg << 8) + (immValue bitAnd: 255)]
		ifFalse:
			[(reach = 1 and: [cond = OilCondLe and: [self isTagged: limitReg]])
				ifTrue: [cmpWord := (OilCmpTagged << 24) + (OilCondLt << 16) + (ivReg << 8) + limitReg]
				ifFalse:
					[(reach <= 128
					  and: [(self entryConstantOf: ivReg before: loopHead) ~= 0
					  and: [(limit2Reg := self unrollFreeRegister) >= 0]]) ifFalse: [^false].
					 limitWord := (OilAddImmTaggedNC << 24) + (limit2Reg << 16) + (limitReg << 8) + (reach negated bitAnd: 255).
					 cmpWord := (OilCmpTagged << 24) + (cond << 16) + (ivReg << 8) + limit2Reg]].
	numClones := factor * (self copySitesFrom: bfOffset + 1 to: backJump) + 1.
	(self canGrowBy: (factor * bodyWords) + 7 sites: numClones) ifFalse: [^false].
	"Record it."
	oilUnrollHead at: oilNumUnrolls put: loopHead.
	oilUnrollBack at: oilNumUnrolls put: backJump.
	oilUnrollTest at: oilNumUnrolls put: cmpOffset.
	oilUnrollCount at: oilNumUnrolls put: factor.
	oilUnrollIV at: oilNumUnrolls put: ivReg.
	oilUnrollValue at: oilNumUnrolls put: bodyWords.
	oilUnrollWord1 at: oilNumUnrolls put: limitWord.
	oilUnrollWord2 at: oilNumUnrolls put: cmpWord.
	oilNumUnrolls := oilNumUnrolls + 1.
	oilUnrollGrowth := oilUnrollGrowth + (factor * bodyWords) + 7.
	oilUnrollClones := oilUnrollClones + numClones.
	oilNumPartiallyUnrolled := oilNumPartiallyUnrolled + 1.
	self mark: bfOffset with: OilP2UnrollPartial.
	^true! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
emitCopyOf: srcOffset at: dstOffset shift: shift from: firstOffset to: lastOffset
	"Emit a copy of the instruction at srcOffset of a loop from firstOffset to lastOffset whose instructions are laid out
	 (oilIRMap) shift words before this copy of them: its branches into the loop go to this copy, and if it can deoptimize
	 (and is not laid out there itself, shift = 0) it gets a clone of its deopt site (the one OilGuardClass, OilGuardClass2 and
	 OilCheckBounds also hold).  Answer the index following it in Buffer 2."
	| nextOffset opcode target siteIndex |
	nextOffset := self emitInstructionAt: srcOffset at: dstOffset.
	opcode := self opcodeAt: srcOffset.
	(self isBranch: opcode) ifTrue:
		[target := self imm16At: srcOffset.
		 (target >= firstOffset and: [target <= lastOffset]) ifTrue:
			[oilIRBuffer2 at: dstOffset put: ((oilIRBuffer2 at: dstOffset) bitAnd: 16rFFFF0000) + ((oilIRMap at: target) + shift)]].
	siteIndex := oilIRSite at: srcOffset.
	(shift ~= 0 and: [siteIndex >= 0 and: [(self flag: srcOffset has: OilP2Delete + OilP2NoCheck) not]]) ifTrue:
		[siteIndex := self cloneSite: siteIndex at: dstOffset.
		 (opcode = OilGuardClass or: [opcode = OilGuardClass2]) ifTrue:
			[oilIRBuffer2 at: dstOffset put: ((oilIRBuffer2 at: dstOffset) bitAnd: 16rFFFF0000) + siteIndex].
		 opcode = OilCheckBounds ifTrue:
			[oilIRBuffer2 at: dstOffset put: ((oilIRBuffer2 at: dstOffset) bitAnd: 16rFFFFFF00) + siteIndex]].
	^nextOffset! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
isCopiedInFullUnroll: irOffset index: unrollIndex
	"Is the instruction at irOffset of the fully unrolled loop unrollIndex in its copies (as itself, or as an OilConstTagged
	 for a step of the induction variable)?  The test and its branch are not."
	(irOffset = (oilUnrollTest at: unrollIndex) or: [irOffset = ((oilUnrollTest at: unrollIndex) + 1)]) ifTrue: [^false].
	^(self flag: irOffset has: OilP2Delete) not
	  or: [(self opcodeHasDest: (self opcodeAt: irOffset)) and: [(self fieldAAt: irOffset) = (oilUnrollIV at: unrollIndex)]]! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
layOutFullyUnrolledLoop: unrollIndex at: startOffset
	"Map the instructions of the fully unrolled loop unrollIndex to their first copy (its original deopt sites are those of
	 the first copy), and answer the index following the unrolled code: count copies of the header and the body, a last copy
	 of the header (the exit), and a jump to the exit if it does not follow."
	| irOffset dstOffset backJump |
	backJump := oilUnrollBack at: unrollIndex.
	dstOffset := startOffset.
	irOffset := oilUnrollHead at: unrollIndex.
	[irOffset < backJump] whileTrue:
		[oilIRMap at: irOffset put: dstOffset.
		 (self isCopiedInFullUnroll: irOffset index: unrollIndex) ifTrue:
			[dstOffset := dstOffset + (self instructionLengthAt: irOffset)].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	dstOffset := startOffset + ((oilUnrollCount at: unrollIndex) * (oilUnrollWord2 at: unrollIndex)).
	oilIRMap at: backJump put: dstOffset.
	dstOffset := dstOffset + (oilUnrollWord1 at: unrollIndex).
	(self imm16At: (oilUnrollTest at: unrollIndex) + 1) ~= (backJump + 1) ifTrue:
		[dstOffset := dstOffset + 1].
	^dstOffset! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
emitFullyUnrolledLoop: unrollIndex at: startOffset
	"Emit the fully unrolled loop unrollIndex (see layOutFullyUnrolledLoop:at:): count copies of its header and body, with
	 the steps of the induction variable replaced by assignments of its values, then the header again, and a jump to the
	 exit if it does not follow.  Answer the index following it in Buffer 2."
	| loopHead backJump cmpOffset ivReg ivValue dstOffset endOffset irOffset exitOffset |
	loopHead := oilUnrollHead at: unrollIndex.
	backJump := oilUnrollBack at: unrollIndex.
	cmpOffset := oilUnrollTest at: unrollIndex.
	ivReg := oilUnrollIV at: unrollIndex.
	ivValue := oilUnrollValue at: unrollIndex.
	dstOffset := startOffset.
	0 to: (oilUnrollCount at: unrollIndex) do:
		[:copyIndex|
		endOffset := copyIndex < (oilUnrollCount at: unrollIndex) ifTrue: [backJump] ifFalse: [cmpOffset].
		irOffset := loopHead.
		[irOffset < endOffset] whileTrue:
			[(self isCopiedInFullUnroll: irOffset index: unrollIndex) ifTrue:
				[((self opcodeHasDest: (self opcodeAt: irOffset)) and: [(self fieldAAt: irOffset) = ivReg])
					ifTrue:
						[ivValue := ivValue + (self signed8: (self fieldCAt: irOffset)).
						 oilIRBuffer2 at: dstOffset put: (OilConstTagged << 24) + (ivReg << 16) + ((ivValue << 3) + 1 bitAnd: 16rFFFF).
						 dstOffset := dstOffset + 1]
					ifFalse:
						[dstOffset := self emitCopyOf: irOffset at: dstOffset shift: copyIndex * (oilUnrollWord2 at: unrollIndex) from: loopHead to: backJump]].
			 irOffset := irOffset + (self instructionLengthAt: irOffset)]].
	exitOffset := self imm16At: cmpOffset + 1.
	exitOffset ~= (backJump + 1) ifTrue:
		[oilIRBuffer2 at: dstOffset put: (OilJump << 24) + (oilIRMap at: exitOffset).
		 dstOffset := dstOffset + 1].
	^dstOffset! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
sizeOfPartiallyUnrolledLoop: unrollIndex
	"The size of the unrolled loop that follows the exit branch of the header of the partially unrolled loop unrollIndex
	 (see emitPartiallyUnrolledLoop:at:)."
	^((oilUnrollWord1 at: unrollIndex) = 0 ifTrue: [0] ifFalse: [1])
	  + ((oilUnrollCount at: unrollIndex) * (oilUnrollValue at: unrollIndex)) + 6! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
emitPartiallyUnrolledLoop: unrollIndex at: startOffset
	"Emit the unrolled loop of the partially unrolled loop unrollIndex after the exit branch of its header (see
	 partiallyUnrollLoop:backJump:): the limit of the unrolled loop if needed, its test (else go to the remainder, the rotated
	 loop laid out as usual), the copies of the body, its test again, branching back, then the test of the remainder.
	 Answer the index following it in Buffer 2."
	| backJump cmpOffset remainderOffset dstOffset unrolledOffset irOffset |
	backJump := oilUnrollBack at: unrollIndex.
	cmpOffset := oilUnrollTest at: unrollIndex.
	remainderOffset := oilIRMap at: cmpOffset + 2.
	dstOffset := startOffset.
	(oilUnrollWord1 at: unrollIndex) ~= 0 ifTrue:
		[oilIRBuffer2 at: dstOffset put: (oilUnrollWord1 at: unrollIndex).
		 dstOffset := dstOffset + 1].
	oilIRBuffer2 at: dstOffset put: (oilUnrollWord2 at: unrollIndex).
	oilIRBuffer2 at: dstOffset + 1 put: (OilBranchFalse << 24) + (OilFlagsReg << 16) + remainderOffset.
	dstOffset := dstOffset + 2.
	unrolledOffset := dstOffset.
	1 to: (oilUnrollCount at: unrollIndex) do:
		[:copyIndex| | shift |
		shift := dstOffset - remainderOffset.
		irOffset := cmpOffset + 2.
		[irOffset < backJump] whileTrue:
			[(self flag: irOffset has: OilP2Delete) ifFalse:
				[dstOffset := self emitCopyOf: irOffset at: dstOffset shift: shift from: (oilUnrollHead at: unrollIndex) to: backJump].
			 irOffset := irOffset + (self instructionLengthAt: irOffset)]].
	oilIRBuffer2 at: dstOffset put: (oilUnrollWord2 at: unrollIndex).
	oilIRBuffer2 at: dstOffset + 1 put: (OilBranchTrue << 24) + (OilFlagsReg << 16) + unrolledOffset.
	dstOffset := self emitTestCopy: cmpOffset at: dstOffset + 2.
	oilIRBuffer2 at: dstOffset put: (OilBranchFalse << 24) + (OilFlagsReg << 16) + (oilIRMap at: (self imm16At: cmpOffset + 1)).
	^dstOffset + 1! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
storeNeedsCheck: objReg
	"Does the store into the object in register objReg by the instruction being translated (at oilFailIndex) need the store
	 check?  Not if the object is young: it was allocated in eden (OilNewArray, OilNewObject) in the straight-line code that
	 leads to the store (no branch target between them), into objReg or into a register objReg is a move (or a move of a
	 move...) of, and nothing between them may run the garbage collector.  Oil allocations deoptimize rather than scavenge and
	 Oil code has no interrupt checks, so only calls may: sends, and intrinsics falling back to sends."
	| storeOffset allocOffset irOffset opcode vreg defOffset useOffset hops |
	(oilUnrollMode bitAnd: 4) = 0 ifFalse: [^true].
	storeOffset := oilFailIndex.
	vreg := objReg.
	useOffset := storeOffset.
	allocOffset := -1.
	hops := 0.
	[allocOffset < 0] whileTrue:
		[defOffset := -1.
		 irOffset := 0.
		 [irOffset < useOffset] whileTrue:
			[((self opcodeHasDest: (self opcodeAt: irOffset)) and: [(self fieldAAt: irOffset) = vreg]) ifTrue:
				[defOffset := irOffset].
			 irOffset := irOffset + (self instructionLengthAt: irOffset)].
		 defOffset < 0 ifTrue: [^true].
		 opcode := self opcodeAt: defOffset.
		 (opcode = OilNewArray or: [opcode = OilNewObject])
			ifTrue: [allocOffset := defOffset]
			ifFalse:
				[(opcode = OilMove and: [(hops := hops + 1) <= 4]) ifFalse: [^true].
				 vreg := self fieldBAt: defOffset.
				 useOffset := defOffset]].
	irOffset := allocOffset + (self instructionLengthAt: allocOffset).
	[irOffset <= storeOffset] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 ((oilIRTarget at: irOffset) ~= 0
		  or: [irOffset < storeOffset
			  and: [(self isCall: opcode) or: [opcode = OilStreamNext or: [opcode = OilStreamNextPut
					or: [opcode = OilCompareBytes or: [opcode = OilIdentityHash]]]]]]) ifTrue: [^true].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	oilNumYoungStores := oilNumYoungStores + 1.
	^false! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
pass2Statistics: index
	"0 loops rotated, 1 bounds checks removed, 2 dead instructions removed, 3 sizes shared, 4 unchecked increments,
	 5 Pass 1 IR words, 6 class guards removed, 7 in-place tagged add undos; 23 loops fully unrolled, 24 loops partially
	 unrolled, 25 stores into young objects without store check (Pass 3), 26 loops with float registers (Pass 3)."
	index = 0 ifTrue: [^oilNumRotated].
	index = 1 ifTrue: [^oilNumBoundsRemoved].
	index = 2 ifTrue: [^oilNumDeadRemoved].
	index = 3 ifTrue: [^oilNumSizesShared].
	index = 4 ifTrue: [^oilNumNoCheck].
	index = 5 ifTrue: [^oilPass1Words].
	index = 6 ifTrue: [^oilNumGuardsRemoved].
	index = 7 ifTrue: [^oilNumUndos].
	index = 23 ifTrue: [^oilNumFullyUnrolled].
	index = 24 ifTrue: [^oilNumPartiallyUnrolled].
	index = 25 ifTrue: [^oilNumYoungStores].
	index = 26 ifTrue: [^oilNumFloatLoops].
	^0! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 22:30'!
floatLoopsEnabled
	"Mode bit 16 (parameter 12 of primitiveOilSetParameter) disables the float loop registers (M10, see prepareFloatLoops)."
	^(oilUnrollMode bitAnd: 16) = 0! !

(Smalltalk hasClassNamed: #OilNumericCompiler) ifTrue: [(Smalltalk at: #OilNumericCompiler) removeFromSystem].!

OilLoopOptimizer subclass: #OilFullCompiler
	instanceVariableNames: 'oilFactKind oilFactA oilFactB oilFactDest oilFactAt oilNumFacts oilNumLoadsRemoved oilNumChecksRemoved oilNumUnboxed'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-Oil'!

!OilFullCompiler commentStamp: 'cb 10/25/2026 02:00' prior: 0!
I am the full optimizing compiler of Oil (OilBytecodeScanner -> OilInliningCompiler -> OilLoopOptimizer -> OilFullCompiler), for the 64-bit Spur Cog VM.  To Pass 1 (translation and inlining into the linear IR), Pass 2 (the streaming loop optimizer) and Pass 3 (native code generation) I add:
- dominator-scoped local value numbering (valueNumber, run by Pass 2 before dead code elimination): loads of fields and sizes already loaded, and bounds and class checks already done, on every path, are eliminated, without SSA or phis;
- float fusion (fuseFloats, on Pass 2's IR): the intermediate results of a chain of Float arithmetic stay unboxed in XMM registers.
All my tables are static too.!

!OilFullCompiler class methodsFor: 'translation' stamp: 'cb 10/25/2026 02:00'!
declareCVarsIn: aCCodeGenerator
	self == OilFullCompiler ifFalse: [^self].
	#(oilFactKind oilFactA oilFactB oilFactDest oilFactAt) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilMaxFacts]']! !

!OilFullCompiler methodsFor: 'initialization' stamp: 'cb 10/25/2026 02:00'!
setUpSimulationTables
	<doNotGenerate>
	super setUpSimulationTables.
	oilFactKind := self newTable: OilMaxFacts.
	oilFactA := self newTable: OilMaxFacts.
	oilFactB := self newTable: OilMaxFacts.
	oilFactDest := self newTable: OilMaxFacts.
	oilFactAt := self newTable: OilMaxFacts.
	oilNumLoadsRemoved := oilNumChecksRemoved := oilNumUnboxed := 0! !

!OilFullCompiler methodsFor: 'optimization' stamp: 'cb 10/25/2026 02:00'!
pipe
	<inline: true>
	oilNumLoadsRemoved := oilNumChecksRemoved := oilNumUnboxed := 0.
	super pipe.
	failed ifTrue: [^failureCode].
	self runDataflowOptimizationPhase.
	^OilOK!

runDataflowOptimizationPhase
	<inline: true>
	self fuseFloats! !

!OilFullCompiler methodsFor: 'optimization' stamp: 'cb 10/25/2026 02:00'!
pass2Statistics: index
	"8 loads removed, 9 bounds and class checks removed, 10 unboxed float results; see OilLoopOptimizer.
	 And of Pass 1 and 3: 11 scalar replaced objects, 12 of them materialized, 13 bimorphic sends inlined, 14 bimorphic
	 predicates (class tests), 15 allocation sites materialized when created, 16 allocations sharing a threshold check,
	 17 bimorphic nil or object sends (collapsed into the class test when compared with nil)."
	index = 8 ifTrue: [^oilNumLoadsRemoved].
	index = 11 ifTrue: [^oilNumVirtualized].
	index = 12 ifTrue: [^oilNumMaterialized].
	index = 13 ifTrue: [^oilNumBimorphic].
	index = 14 ifTrue: [^oilNumPredicates].
	index = 15 ifTrue: [^oilNumEagerSites].
	index = 16 ifTrue: [^oilNumAllocsCombined].
	index = 17 ifTrue: [^oilNumSelects].
	index = 18 ifTrue: [^oilEagerPC].
	index = 19 ifTrue: [^oilEagerDepth].
	index = 20 ifTrue: [^oilRefusePC].
	index = 21 ifTrue: [^oilRefuseDepth].
	index = 22 ifTrue: [^oilNumNoInline].
	index = 9 ifTrue: [^oilNumChecksRemoved].
	index = 10 ifTrue: [^oilNumUnboxed].
	^super pass2Statistics: index! !

!OilFullCompiler methodsFor: 'value numbering' stamp: 'cb 10/25/2026 02:00'!
valueNumber
	"Dominator-scoped local value numbering, on Pass 2's input (Buffer 1, after the loop optimizations).  Walking the IR
	 in order, remember facts: the field or the size of an object loaded into a register, an index within the bounds of
	 a size, the class of an object.  A fact established at an instruction d still holds at a later p if d dominates p
	 and none of its registers is assigned in between.  Branches go forward but for loops, so d dominates p unless a
	 branch from before d targets a label between them: a label forgets the facts established after the earliest
	 branch to it (a loop header, target of a back edge, forgets them all).  Assigning a register forgets the facts
	 about it (anywhere after, conservatively).  A load already done becomes a move (OilP2ToMove) and a check already
	 done is deleted (OilP2Delete).  A store forgets the loaded fields it may alias and is forwarded to later loads of
	 the same field; calls (the GC may run, objects may change), allocations and other stores forget more."
	| irOffset opcode branchTarget |
	"oilIRMap (free until emission): the earliest branch to each label, 0 if a back edge targets it"
	0 to: irIndex - 1 do: [:offset| oilIRMap at: offset put: 16rFFFF].
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (self isBranch: opcode) ifTrue:
			[branchTarget := self imm16At: irOffset.
			 oilIRMap at: branchTarget put: (branchTarget <= irOffset ifTrue: [0] ifFalse: [(oilIRMap at: branchTarget) min: irOffset])].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	oilNumFacts := 0.
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[(oilIRTarget at: irOffset) ~= 0 ifTrue:
			[self forgetFactsSince: (oilIRMap at: irOffset)].
		 (self flag: irOffset has: OilP2Delete + OilP2ToMove)
			ifTrue: [(self flag: irOffset has: OilP2ToMove) ifTrue: [self forgetFactsAbout: (self fieldAAt: irOffset)]]
			ifFalse: [self valueNumberAt: irOffset].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)]! !

!OilFullCompiler methodsFor: 'value numbering' stamp: 'cb 10/25/2026 02:00'!
valueNumberAt: irOffset
	"Fact kinds: 1 field (A object, B slot), 2 size (A object, B opcode), 3 bounds (A index, B limit), 4 class (A object, B class)."
	| opcode regA regB kind key fact |
	opcode := self opcodeAt: irOffset.
	regA := self fieldAAt: irOffset.
	regB := self fieldBAt: irOffset.
	(opcode = OilLoadField or: [opcode = OilLoadSize or: [opcode = OilLoadByteSize]]) ifTrue:
		[kind := opcode = OilLoadField ifTrue: [1] ifFalse: [2].
		 key := opcode = OilLoadField ifTrue: [self fieldCAt: irOffset] ifFalse: [opcode].
		 fact := self factIndex: kind a: regB b: key.
		 fact >= 0 ifTrue:
			[oilNumLoadsRemoved := oilNumLoadsRemoved + 1.
			 (oilFactDest at: fact) = regA ifTrue: "regA still holds it"
				[^self mark: irOffset with: OilP2Delete].
			 self mark: irOffset with: OilP2ToMove.
			 oilIRAux at: irOffset put: (oilFactDest at: fact)].
		 self forgetFactsAbout: regA.
		 regA ~= regB ifTrue: [self addFact: kind a: regB b: key dest: regA at: irOffset].
		 ^self].
	(opcode = OilCheckBounds or: [opcode = OilGuardClass]) ifTrue:
		[kind := opcode = OilCheckBounds ifTrue: [3] ifFalse: [4].
		 key := opcode = OilCheckBounds ifTrue: [regB] ifFalse: [self word64At: irOffset + 1].
		 ((self factIndex: kind a: regA b: key) >= 0
		  or: [kind = 3 and: [self isBoundedBySameSize: regA limit: regB]])
			ifTrue:
				[self mark: irOffset with: OilP2Delete.
				 oilNumChecksRemoved := oilNumChecksRemoved + 1]
			ifFalse: [self addFact: kind a: regA b: key dest: -1 at: irOffset].
		 ^self].
	opcode = OilStoreField ifTrue:
		[self forgetFieldFacts: (self fieldCAt: irOffset).
		 self addFact: 1 a: regB b: (self fieldCAt: irOffset) dest: regA at: irOffset.
		 ^self].
	((self isCall: opcode) or: [opcode = OilStreamNext or: [opcode = OilStreamNextPut
	 or: [opcode = OilMakeClosure or: [opcode = OilNewArray]]]]) ifTrue:
		[oilNumFacts := 0].
	(opcode = OilStoreElement or: [opcode = OilStoreByte or: [opcode = OilStoreChar]]) ifTrue:
		[self forgetFieldFacts: -1].
	(self opcodeHasDest: opcode) ifTrue:
		[self forgetFactsAbout: regA]! !

!OilFullCompiler methodsFor: 'value numbering' stamp: 'cb 10/25/2026 02:00'!
factIndex: kind a: regA b: key
	0 to: oilNumFacts - 1 do:
		[:fact|
		((oilFactKind at: fact) = kind and: [(oilFactA at: fact) = regA and: [(oilFactB at: fact) = key]]) ifTrue: [^fact]].
	^-1! !

!OilFullCompiler methodsFor: 'value numbering' stamp: 'cb 10/25/2026 02:00'!
isBoundedBySameSize: indexReg limit: limitReg
	"Is indexReg known to be within a limit that is the same size (of the same object) as limitReg?"
	| sizeFact |
	sizeFact := -1.
	0 to: oilNumFacts - 1 do:
		[:fact| ((oilFactKind at: fact) = 2 and: [(oilFactDest at: fact) = limitReg]) ifTrue: [sizeFact := fact]].
	sizeFact < 0 ifTrue: [^false].
	0 to: oilNumFacts - 1 do:
		[:fact|
		((oilFactKind at: fact) = 2
		 and: [(oilFactA at: fact) = (oilFactA at: sizeFact)
		 and: [(oilFactB at: fact) = (oilFactB at: sizeFact)
		 and: [(self factIndex: 3 a: indexReg b: (oilFactDest at: fact)) >= 0]]]) ifTrue: [^true]].
	^false! !

!OilFullCompiler methodsFor: 'value numbering' stamp: 'cb 10/25/2026 02:00'!
addFact: kind a: regA b: key dest: destReg at: irOffset
	oilNumFacts >= OilMaxFacts ifTrue: [^self].
	oilFactKind at: oilNumFacts put: kind.
	oilFactA at: oilNumFacts put: regA.
	oilFactB at: oilNumFacts put: key.
	oilFactDest at: oilNumFacts put: destReg.
	oilFactAt at: oilNumFacts put: irOffset.
	oilNumFacts := oilNumFacts + 1! !

!OilFullCompiler methodsFor: 'value numbering' stamp: 'cb 10/25/2026 02:00'!
forgetFactsAbout: vreg
	"Register vreg is assigned: forget the facts about its value (as an object, index, limit or result)."
	oilNumFacts - 1 to: 0 by: -1 do:
		[:fact|
		((oilFactA at: fact) = vreg
		 or: [(oilFactDest at: fact) = vreg
		 or: [(oilFactKind at: fact) = 3 and: [(oilFactB at: fact) = vreg]]]) ifTrue:
			[self removeFact: fact]]! !

!OilFullCompiler methodsFor: 'value numbering' stamp: 'cb 10/25/2026 02:00'!
forgetFactsSince: irOffset
	"Forget the facts established at irOffset or later."
	oilNumFacts - 1 to: 0 by: -1 do:
		[:fact| (oilFactAt at: fact) >= irOffset ifTrue: [self removeFact: fact]]! !

!OilFullCompiler methodsFor: 'value numbering' stamp: 'cb 10/25/2026 02:00'!
forgetFieldFacts: slotIndex
	"Forget the loaded fields of index slotIndex (of any object, which may be aliased), or all of them if slotIndex < 0."
	oilNumFacts - 1 to: 0 by: -1 do:
		[:fact|
		((oilFactKind at: fact) = 1 and: [slotIndex < 0 or: [(oilFactB at: fact) = slotIndex]]) ifTrue:
			[self removeFact: fact]]! !

!OilFullCompiler methodsFor: 'value numbering' stamp: 'cb 10/25/2026 02:00'!
removeFact: fact
	"Replace fact by the last one."
	oilNumFacts := oilNumFacts - 1.
	oilFactKind at: fact put: (oilFactKind at: oilNumFacts).
	oilFactA at: fact put: (oilFactA at: oilNumFacts).
	oilFactB at: fact put: (oilFactB at: oilNumFacts).
	oilFactDest at: fact put: (oilFactDest at: oilNumFacts).
	oilFactAt at: fact put: (oilFactAt at: oilNumFacts)! !

!OilFullCompiler methodsFor: 'float fusion' stamp: 'cb 10/25/2026 02:00'!
fuseFloats
	"Float fusion, on the final IR.  A float chain is a straight-line run of float instructions (OilAddFloat..OilCmpFloat,
	 and the constants they use) whose results, but the last, are only read in the chain by its float instructions:
	 they stay unboxed in XMM registers (OilFloatUnboxed), only the last result, if any, is boxed, and the checks of
	 the inputs are done once per chain.  The chain has no side effect and assigns no register before its last
	 instruction (unboxed results stay in XMM registers) but those of its constants, which the deopt state of its
	 first instruction does not refer to.  So all its deopts go to that site (OilFloatChained, oilIRAux), and the
	 interpreter then redoes the whole chain."
	| irOffset opcode branchTarget |
	0 to: irIndex - 1 do:
		[:offset|
		oilIRFlag at: offset put: 0.
		oilIRTarget at: offset put: 0].
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (self isBranch: opcode) ifTrue:
			[branchTarget := self imm16At: irOffset.
			 oilIRTarget at: branchTarget put: ((oilIRTarget at: branchTarget) + 1 min: 255)].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	self computeIRSites.
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[irOffset := ((self opcodeAt: irOffset) between: OilAddFloat and: OilCmpFloat)
						ifTrue: [self fuseFloatChainAt: irOffset]
						ifFalse: [irOffset + (self instructionLengthAt: irOffset)]]! !

!OilFullCompiler methodsFor: 'float fusion' stamp: 'cb 10/25/2026 02:00'!
fuseFloatChainAt: start
	"Mark the float chain starting with the float instruction at start, if any.  Answer the index to continue at."
	<inline: false>
	| site runEnd chainEnd irOffset opcode destReg numOps numUnboxedRegs |
	site := oilIRSite at: start.
	(site >= 0 and: [(siteSnapBase at: site) >= 0]) ifFalse: [^start + 1].
	"The run: float instructions, and constants assigning no register of the site's state, up to a label."
	runEnd := start.
	[runEnd < irIndex
	 and: [(runEnd = start or: [(oilIRTarget at: runEnd) = 0])
	 and: [opcode := self opcodeAt: runEnd.
		   (opcode between: OilAddFloat and: OilCmpFloat)
		   or: [(opcode = OilConstTagged or: [opcode = OilConst64])
				and: [(self state: site refersTo: (self fieldAAt: runEnd)) not]]]]] whileTrue:
		[runEnd := runEnd + (self instructionLengthAt: runEnd)].
	"The chain ends with the first float result that may be read after the run (or with the run)."
	chainEnd := -1.
	numOps := 0.
	irOffset := start.
	[chainEnd < 0 and: [irOffset < runEnd]] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (opcode between: OilAddFloat and: OilCmpFloat) ifTrue:
			[numOps := numOps + 1.
			 (opcode = OilCmpFloat or: [self isEscaping: irOffset runEnd: runEnd]) ifTrue: [chainEnd := irOffset]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	chainEnd < 0 ifTrue:
		[irOffset := start.
		 [irOffset < runEnd] whileTrue:
			[((self opcodeAt: irOffset) between: OilAddFloat and: OilCmpFloat) ifTrue: [chainEnd := irOffset].
			 irOffset := irOffset + (self instructionLengthAt: irOffset)]].
	numOps < 2 ifTrue: [^chainEnd + 1].
	"The results before chainEnd must not be read after it, and must fit the XMM registers."
	numUnboxedRegs := 0.
	irOffset := start.
	[irOffset < chainEnd] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (opcode between: OilAddFloat and: OilDivFloat) ifTrue:
			[destReg := self fieldAAt: irOffset.
			 ((self isAssigned: destReg from: irOffset + 1 to: chainEnd) not
			  and: [self isRead: destReg from: chainEnd + 1 to: runEnd]) ifTrue: [^start + 1].
			 (self isAssigned: destReg from: start to: irOffset - 1) ifFalse:
				[numUnboxedRegs := numUnboxedRegs + 1]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	numUnboxedRegs > (OilNumXmms - 3) ifTrue: [^start + 1].
	"Mark it."
	irOffset := start.
	[irOffset <= chainEnd] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 self mark: irOffset with: OilFloatChained.
		 oilIRAux at: irOffset put: site.
		 (irOffset > start and: [(oilIRSite at: irOffset) >= 0]) ifTrue:
			[siteIR at: (oilIRSite at: irOffset) put: -2].
		 ((opcode between: OilAddFloat and: OilDivFloat)
		  and: [irOffset < chainEnd or: [(self isEscaping: irOffset runEnd: runEnd) not]]) ifTrue:
			[self mark: irOffset with: OilFloatUnboxed.
			 oilNumUnboxed := oilNumUnboxed + 1].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^chainEnd + 1! !

!OilFullCompiler methodsFor: 'float fusion' stamp: 'cb 10/25/2026 02:00'!
isEscaping: irOffset runEnd: runEnd
	"May the result of the float arithmetic at irOffset be read after the run ending at runEnd (it is not assigned
	 again in the run, and live there)?"
	| destReg |
	destReg := self fieldAAt: irOffset.
	^(self isAssigned: destReg from: irOffset + 1 to: runEnd - 1) not
	  and: [self isLive: destReg from: runEnd]! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 02:00'!
isAssigned: vreg from: startOffset to: endOffset
	"Is register vreg assigned by an instruction from startOffset to endOffset (inclusive), not deleted (by Pass 2)?"
	| irOffset |
	irOffset := startOffset.
	[irOffset <= endOffset] whileTrue:
		[((self opcodeHasDest: (self opcodeAt: irOffset))
		  and: [(self fieldAAt: irOffset) = vreg
		  and: [(self flag: irOffset has: OilP2Delete) not]]) ifTrue: [^true].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^false! !

!OilFullCompiler methodsFor: 'float fusion' stamp: 'cb 10/25/2026 02:00'!
isRead: vreg from: startOffset to: endOffset
	"Is register vreg read, by an instruction or the deopt state of a live site, from startOffset to before endOffset
	 (straight-line code), before being assigned?"
	| irOffset siteIndex |
	irOffset := startOffset.
	[irOffset < endOffset] whileTrue:
		[oilUseProbe := vreg.
		 oilUseProbeHit := false.
		 self countUsesAt: irOffset.
		 oilUseProbe := -1.
		 oilUseProbeHit ifTrue: [^true].
		 siteIndex := oilIRSite at: irOffset.
		 (siteIndex >= 0 and: [(self isLiveSite: siteIndex) and: [self state: siteIndex refersTo: vreg]]) ifTrue: [^true].
		 ((self opcodeHasDest: (self opcodeAt: irOffset)) and: [(self fieldAAt: irOffset) = vreg]) ifTrue: [^false].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^false! !

!OilFullCompiler methodsFor: 'float fusion' stamp: 'cb 10/25/2026 02:00'!
isLive: vreg from: startOffset
	"May register vreg be read at or after startOffset before being assigned?  Follows the control flow (both ways at
	 conditional branches) for at most 256 instructions, answering true beyond.  Reads are the operands and the deopt
	 states of live sites; the registers the deopt metadata of the frames and virtual objects refers to are live."
	<inline: false>
	| stack sp irOffset opcode budget siteIndex |
	<var: #stack declareC: 'sqInt stack[16]'>
	self cCode: [] inSmalltalk: [stack := CArrayAccessor on: (Array new: 16)].
	(self isMetadataRegister: vreg) ifTrue: [^true].
	stack at: 0 put: startOffset.
	sp := 1.
	budget := 256.
	[sp > 0] whileTrue:
		[sp := sp - 1.
		 irOffset := stack at: sp.
		 [irOffset < irIndex] whileTrue:
			[(budget := budget - 1) < 0 ifTrue: [^true].
			 opcode := self opcodeAt: irOffset.
			 oilUseProbe := vreg.
			 oilUseProbeHit := false.
			 self countUsesAt: irOffset.
			 oilUseProbe := -1.
			 oilUseProbeHit ifTrue: [^true].
			 siteIndex := oilIRSite at: irOffset.
			 (siteIndex >= 0 and: [(self isLiveSite: siteIndex) and: [self state: siteIndex refersTo: vreg]]) ifTrue: [^true].
			 ((opcode = OilReturn or: [opcode = OilTrap])
			  or: [(self opcodeHasDest: opcode) and: [(self fieldAAt: irOffset) = vreg]])
				ifTrue: [irOffset := irIndex] "the path ends"
				ifFalse:
					[(opcode = OilBranchTrue or: [opcode = OilBranchFalse]) ifTrue:
						[sp >= 16 ifTrue: [^true].
						 stack at: sp put: (self imm16At: irOffset).
						 sp := sp + 1].
					 irOffset := opcode = OilJump
									ifTrue: [self imm16At: irOffset]
									ifFalse: [irOffset + (self instructionLengthAt: irOffset)]]]].
	^false! !

!OilFullCompiler methodsFor: 'float fusion' stamp: 'cb 10/25/2026 02:00'!
isMetadataRegister: vreg
	"Does the deoptimization metadata of an inlined frame (its receiver) or of a virtual object refer to register vreg?"
	0 to: numFrames - 1 do:
		[:frameIndex|
		((frameSelfKind at: frameIndex) = OilDescReg and: [(frameSelfValue at: frameIndex) = vreg]) ifTrue: [^true]].
	0 to: numVObjs - 1 do:
		[:vobjIndex|
		((vobjSelfKind at: vobjIndex) = OilDescReg and: [(vobjSelfValue at: vobjIndex) = vreg]) ifTrue: [^true].
		0 to: (vobjNumCopied at: vobjIndex) - 1 do:
			[:slotIndex|
			((capturedKind at: (vobjCopiedBase at: vobjIndex) + slotIndex) = OilDescReg
			 and: [(capturedValue at: (vobjCopiedBase at: vobjIndex) + slotIndex) = vreg]) ifTrue: [^true]]].
	^false! !

Smalltalk globals removeKey: #OilCompiler ifAbsent: [].
Smalltalk at: #OilCompiler put: OilFullCompiler!
