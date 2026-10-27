"Pass 2 of Oil (OilLoopOptimizer), the streaming loop optimizer.  It reads the linear IR Pass 1 produced in Buffer 1
 (oilIRBuffer1) and writes the optimized IR into Buffer 2 (oilIRBuffer2), which Pass 3 then
 translates to machine code.  All its tables are static; it allocates nothing.  Author: cb."!

OilInliningCompiler subclass: #OilLoopOptimizer
	instanceVariableNames: 'oilUnrollHead oilUnrollBack oilUnrollCount oilUnrollIV oilUnrollValue oilUnrollWord2 oilNumUnrolls oilUnrollGrowth oilUnrollClones oilNumFullyUnrolled'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-Oil'!

!OilLoopOptimizer commentStamp: 'cb 10/24/2026 19:35' prior: 0!
I add Pass 2, the streaming loop optimizer, to OilInliningCompiler.  Given the linear IR Pass 1 produced in Buffer 1 (oilIRBuffer1), pipe (via loopOptimize) analyzes tagged SmallInteger registers, rotates innermost call-free loops, eliminates redundant bounds checks, class guards and overflow checks on induction variables, fully unrolls innermost leaf loops whose trip count is a small constant, and streams the optimized IR into Buffer 2 (oilIRBuffer2) for Pass 3.!

!OilLoopOptimizer class methodsFor: 'translation' stamp: 'cb 10/25/2026 21:00'!
declareCVarsIn: aCCodeGenerator
	self == OilLoopOptimizer ifFalse: [^self].
	#(oilUnrollHead oilUnrollBack oilUnrollCount oilUnrollIV oilUnrollValue oilUnrollWord2) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilMaxUnrolls]']! !

!OilLoopOptimizer methodsFor: 'initialization' stamp: 'cb 10/25/2026 21:00'!
setUpSimulationTables
	<doNotGenerate>
	super setUpSimulationTables.
	oilUnrollHead := self newTable: OilMaxUnrolls.
	oilUnrollBack := self newTable: OilMaxUnrolls.
	oilUnrollCount := self newTable: OilMaxUnrolls.
	oilUnrollIV := self newTable: OilMaxUnrolls.
	oilUnrollValue := self newTable: OilMaxUnrolls.
	oilUnrollWord2 := self newTable: OilMaxUnrolls.
	oilNumUnrolls := oilUnrollGrowth := oilUnrollClones := oilNumFullyUnrolled := 0! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/26/2026 23:20'!
pipe
	<inline: true>
	^self loopOptimize! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/26/2026 20:30'!
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
	 4. Unrolling of innermost leaf loops (unrollLoops).
	 5. Emission (streaming, one pass to lay out, one to emit), remapping branch targets and deopt sites.
	 If loops were fully unrolled, their copies are straight-line code: Buffer 2 is copied back into Buffer 1 and optimized
	 again (once), e.g. the checks a copy repeats are redundant (value numbering), and loops around them may now be innermost.
	 Answer OilOK or a failure code."
	| result |
	oilIRBuffer := oilIRBuffer1.
	oilPass1Words := irIndex.
	oilNumRotated := oilNumBoundsRemoved := oilNumSizesShared := oilNumNoCheck := oilNumGuardsRemoved := 0.
	oilUseProbe := -1.
	oilNumFullyUnrolled := 0.
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
	self foldSelectDiamonds.
	optimize ifTrue:
		[self analyzeTaggedRegisters.
		 irOffset := 0.
		 [irOffset < irIndex] whileTrue:
			[((self opcodeAt: irOffset) = OilJump and: [(self imm16At: irOffset) <= irOffset]) ifTrue:
				[self optimizeLoop: (self imm16At: irOffset) backJump: irOffset].
			 irOffset := irOffset + (self instructionLengthAt: irOffset)].
		 self valueNumber.
		 self unrollToByDoLoops].
	^self emitOptimizedIR! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/27/2026 12:55'!
foldSelectDiamonds
	"Fold a bimorphic nil-or-non-nil select diamond (OilCmpClass rcvr == C; BranchFalse Lother; Const64 dest := nil;
	 Jump Lmerge; Lother: dest := nonNil; Lmerge:) followed by a comparison of dest with nil (Const64 nilReg := nil;
	 CmpTagged ==/~~ dest, nilReg) into the class test OilCmpClass itself."
	| irOffset |
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[(self opcodeAt: irOffset) = OilCmpClass ifTrue:
			[self tryFoldSelectDiamondAt: irOffset].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)]! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/27/2026 12:55'!
tryFoldSelectDiamondAt: cmpOffset
	| bfOffset lFalse destReg lMerge falseOp nilReg cmpTagOffset cond irOffset |
	bfOffset := cmpOffset + 3.
	(bfOffset + 5 <= irIndex
	 and: [(self fieldAAt: cmpOffset) = OilCondIdentical
	 and: [(oilIRTarget at: bfOffset) = 0
	 and: [(self opcodeAt: bfOffset) = OilBranchFalse
	 and: [(self fieldAAt: bfOffset) = OilFlagsReg]]]]) ifFalse: [^self].
	lFalse := self imm16At: bfOffset.
	(lFalse = (cmpOffset + 8)
	 and: [(oilIRTarget at: cmpOffset + 4) = 0
	 and: [(self opcodeAt: cmpOffset + 4) = OilConst64
	 and: [(self word64At: cmpOffset + 5) = nilHandle
	 and: [(oilIRTarget at: cmpOffset + 7) = 0
	 and: [(self opcodeAt: cmpOffset + 7) = OilJump]]]]]) ifFalse: [^self].
	destReg := self fieldAAt: cmpOffset + 4.
	lMerge := self imm16At: cmpOffset + 7.
	lMerge = lFalse
		ifTrue:
			[(destReg = (self fieldBAt: cmpOffset) and: [(oilIRTarget at: lMerge) = 2]) ifFalse: [^self]]
		ifFalse:
			[(lMerge > lFalse
			  and: [lMerge < irIndex
			  and: [(oilIRTarget at: lFalse) = 1
			  and: [(oilIRTarget at: lMerge) = 1
			  and: [lMerge = (lFalse + (self instructionLengthAt: lFalse))
			  and: [(self fieldAAt: lFalse) = destReg]]]]]) ifFalse: [^self].
			 falseOp := self opcodeAt: lFalse.
			 (falseOp = OilMove or: [falseOp = OilConstTagged
			  or: [falseOp = OilConst64 and: [(self word64At: lFalse + 1) ~= nilHandle]]]) ifFalse: [^self]].
	cmpTagOffset := lMerge + 3.
	(cmpTagOffset < irIndex
	 and: [(self opcodeAt: lMerge) = OilConst64
	 and: [(self word64At: lMerge + 1) = nilHandle
	 and: [(oilIRTarget at: cmpTagOffset) = 0
	 and: [(self opcodeAt: cmpTagOffset) = OilCmpTagged]]]]) ifFalse: [^self].
	nilReg := self fieldAAt: lMerge.
	cond := self fieldAAt: cmpTagOffset.
	(nilReg = (destReg + 1)
	 and: [(cond = OilCondIdentical or: [cond = OilCondNotIdentical])
	 and: [((self fieldBAt: cmpTagOffset) = destReg and: [(self fieldCAt: cmpTagOffset) = nilReg])
			or: [(self fieldBAt: cmpTagOffset) = nilReg and: [(self fieldCAt: cmpTagOffset) = destReg]]]]) ifFalse: [^self].
	oilIRBuffer1 at: cmpOffset put: ((oilIRBuffer1 at: cmpOffset) bitAnd: 16rFF00FFFF) + (cond bitShift: 16).
	irOffset := bfOffset.
	[irOffset <= cmpTagOffset] whileTrue:
		[self mark: irOffset with: OilP2Delete.
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	oilIRTarget at: lFalse put: 0.
	oilIRTarget at: lMerge put: 0.
	oilVRegDefs at: destReg put: (oilVRegDefs at: destReg) - (lMerge = lFalse ifTrue: [1] ifFalse: [2]).
	oilVRegDefs at: nilReg put: (oilVRegDefs at: nilReg) - 1! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 02:00'!
valueNumber
	"Eliminate redundant loads and checks (OilFullCompiler)."
	<inline: true>
	^self! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/26/2026 20:30'!
isCall: opcode
	"(The byte scans fall back to sends, which may run any code.)"
	<inline: true>
	^self opcode: opcode has: OilOpCall! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/26/2026 20:30'!
isPureAt: irOffset
	"Does the instruction at irOffset only compute its destination (no side effect, no deopt, no control flow)?"
	| opcode |
	opcode := self opcodeAt: irOffset.
	^(self opcode: opcode has: OilOpPure)
	  or: [opcode = OilAddImmTagged and: [self flag: irOffset has: OilP2NoCheck]]! !

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

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/26/2026 20:30'!
optimizeLoop: loopHead backJump: backJump
	"Optimize the loop from loopHead to the Jump at backJump, if it is innermost, free of calls and only entered by
	 falling into loopHead, and its header is pure code then OilCmpTagged (or OilCmpImmTagged) and an OilBranchFalse that
	 leaves the loop: rotate it, and optimize it as a counted loop (optimizeCountedLoop:backJump:test:)."
	<inline: false>
	| irOffset opcode cmpOffset bfOffset exitOffset cond ivReg limitReg isImm |
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
		 (isImm
		  or: [(oilVRegDefs at: limitReg) = 1
				and: [(cmpOffset = (loopHead + 1) and: [(self opcodeAt: loopHead) = OilConstTagged and: [(self fieldAAt: loopHead) = limitReg]])
					or: [(self entryConstantOf: limitReg before: loopHead) ~= 0]]]) ifTrue:
			[self markUncheckedSteps: ivReg cond: cond after: bfOffset backJump: backJump]].
	isImm ifFalse: [self optimizeCountedLoop: loopHead backJump: backJump test: cmpOffset]! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/26/2026 20:30'!
optimizeCountedLoop: loopHead backJump: backJump test: cmpOffset
	"The loop from loopHead to the Jump at backJump (see optimizeLoop:backJump:) tests at cmpOffset the registers ivReg and limitReg.
	 A counted loop?  ivReg <= limitReg (or ivReg < limitReg), limitReg the size of an object arrayReg that is never assigned (the receiver or
	 an argument), limitReg assigned only once, before the loop; ivReg assigned a constant >= 1 before the loop and only
	 incremented in the loop.  Then 1 <= ivReg <= limitReg holds after the test, and the increments cannot overflow."
	<inline: false>
	| irOffset opcode cond ivReg limitReg limitDef arrayReg regionStart ivDefsInLoop ivInit ivInitValue sizeAlias |
	cond := self fieldAAt: cmpOffset.
	ivReg := self fieldBAt: cmpOffset.
	limitReg := self fieldCAt: cmpOffset.
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
	irOffset := cmpOffset + 2.
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

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/26/2026 20:30'!
isLiveSite: siteIndex
	"Is deopt site siteIndex still attached to an instruction that can deoptimize?"
	| irOffset |
	irOffset := siteIR at: siteIndex.
	^irOffset >= 0 and: [(self siteHasState: siteIndex) and: [self keepsSiteAt: irOffset]]! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/26/2026 20:30'!
liveStateAt: irOffset refersTo: vreg
	"Does the deopt state of the live site of the instruction at irOffset, if it has one, refer to register vreg?"
	| siteIndex |
	siteIndex := oilIRSite at: irOffset.
	^siteIndex >= 0 and: [(self isLiveSite: siteIndex) and: [self state: siteIndex refersTo: vreg]]! !

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
	 have a state, and there must be room for the clone (and one more, as a margin)."
	| siteIndex |
	siteIndex := oilIRSite at: cmpOffset.
	(limitReg < OilFlagsReg
	 and: [siteIndex >= 0
	 and: [(self siteHasState: siteIndex)
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
								ifFalse: [instrLen])]].
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
							ifFalse: [self emitInstructionAt: srcOffset at: dstOffset]]].
		 srcOffset := srcOffset + instrLen].
	self assert: dstOffset = (oilIRMap at: irIndex).
	0 to: numOriginalSites - 1 do:
		[:siteIndex|
		siteIROffset := siteIR at: siteIndex.
		siteIROffset >= 0 ifTrue:
			[siteIR at: siteIndex put: ((self keepsSiteAt: siteIROffset)
									ifTrue: [oilIRMap at: siteIROffset]
									ifFalse: [-2])]].
	oilIRBuffer := oilIRBuffer2.
	irIndex := dstOffset.
	^OilOK! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/27/2026 11:55'!
unrollToByDoLoops
	"Fully unroll the innermost canonical to:by:do: leaf loops whose number of iterations is a small constant (see
	 fullyUnrollToByDoLoop:backJump:).  Run after value numbering: the loops' instructions are final, the copies are made by
	 the emission (emitOptimizedIR), with clones of their deopt sites."
	| irOffset |
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[((self opcodeAt: irOffset) = OilJump and: [(self imm16At: irOffset) <= irOffset]) ifTrue:
			[self fullyUnrollToByDoLoop: (self imm16At: irOffset) backJump: irOffset].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)]! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/26/2026 21:40'!
unrollIndexOf: irOffset
	"The index of the fully unrolled loop whose header is at irOffset."
	0 to: oilNumUnrolls - 1 do:
		[:unrollIndex| (oilUnrollHead at: unrollIndex) = irOffset ifTrue: [^unrollIndex]].
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

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/27/2026 11:55'!
isUnrollableToByDoLoop: loopHead backJump: backJump
	"Is the loop from loopHead to the Jump at backJump a canonical to:by:do: leaf loop?  At loopHead: OilCmpImmTagged of the
	 induction variable and OilBranchFalse leaving the loop; at backJump - 1: the only assignment of the induction variable in
	 the loop, stepping it by an immediate; innermost, call-free, entered only by falling into loopHead, its branches forward
	 (not to backJump)."
	| irOffset opcode target ivReg |
	(oilNumUnrolls < OilMaxUnrolls
	 and: [loopHead + 2 < backJump
	 and: [(oilIRTarget at: loopHead) = 1
	 and: [(oilIRTarget at: backJump) = 0
	 and: [(self opcodeAt: loopHead) = OilCmpImmTagged
	 and: [(self opcodeAt: loopHead + 1) = OilBranchFalse
	 and: [(self fieldAAt: loopHead + 1) = OilFlagsReg
	 and: [(oilIRTarget at: loopHead + 1) = 0
	 and: [(self imm16At: loopHead + 1) > backJump
	 and: [self isStepAt: backJump - 1]]]]]]]]]) ifFalse: [^false].
	ivReg := self fieldBAt: loopHead.
	(ivReg < OilFlagsReg and: [(self fieldAAt: backJump - 1) = ivReg]) ifFalse: [^false].
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (irOffset >= loopHead and: [irOffset < backJump])
			ifTrue:
				[(self isCall: opcode) ifTrue: [^false].
				 (irOffset < (backJump - 1)
				  and: [(self opcodeHasDest: opcode) and: [(self fieldAAt: irOffset) = ivReg]]) ifTrue: [^false].
				 (self isBranch: opcode) ifTrue:
					[target := self imm16At: irOffset.
					 (target <= irOffset or: [target = backJump]) ifTrue: [^false]]]
			ifFalse:
				[(irOffset ~= backJump and: [self isBranch: opcode]) ifTrue:
					[target := self imm16At: irOffset.
					 (target > loopHead and: [target <= backJump]) ifTrue: [^false]]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^true! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/26/2026 20:30'!
copySitesFrom: startOffset to: endOffset
	"The number of deopt sites a copy of the instructions from startOffset to before endOffset clones."
	| irOffset numSitesInCopy |
	numSitesInCopy := 0.
	irOffset := startOffset.
	[irOffset < endOffset] whileTrue:
		[((oilIRSite at: irOffset) >= 0 and: [self keepsSiteAt: irOffset]) ifTrue:
			[numSitesInCopy := numSitesInCopy + 1].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^numSitesInCopy! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/25/2026 21:00'!
canGrowBy: numWords sites: numClones
	"Can the IR grow by numWords more words and numClones more deopt sites (margin left for the rotated loops)?"
	^irIndex + oilUnrollGrowth + numWords + 256 < OilBufferWords
	  and: [numSites + oilUnrollClones + numClones <= OilMaxSites]! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/27/2026 11:55'!
fullyUnrollToByDoLoop: loopHead backJump: backJump
	"If the canonical to:by:do: loop from loopHead to the Jump at backJump runs 1..OilUnrollMaxTrips iterations known now and
	 iterations * body size <= OilUnrollFullBudget, record it to be replaced by straight-line copies of its body."
	| cond ivReg limitValue step ivValue ivStart trips bodySize copyWords irOffset numCopySites |
	(self isUnrollableToByDoLoop: loopHead backJump: backJump) ifFalse: [^false].
	cond := self fieldAAt: loopHead.
	ivReg := self fieldBAt: loopHead.
	limitValue := self signed8: (self fieldCAt: loopHead).
	step := self signed8: (self fieldCAt: backJump - 1).
	((step > 0 and: [cond = OilCondLe]) or: [step < 0 and: [cond = OilCondGe]]) ifFalse: [^false].
	ivValue := self entryConstantOf: ivReg before: loopHead.
	ivValue = 0 ifTrue: [^false].
	ivStart := (ivValue - 1) bitShift: -3.
	trips := (limitValue - ivStart) // step + 1.
	(trips >= 1
	 and: [trips <= (oilUnrollMaxTripsValue > 0 ifTrue: [oilUnrollMaxTripsValue] ifFalse: [OilUnrollMaxTrips])
	 and: [ivStart abs <= 2048]]) ifFalse: [^false].
	bodySize := 0.
	copyWords := 1.
	irOffset := loopHead + 2.
	[irOffset < (backJump - 1)] whileTrue:
		[(self flag: irOffset has: OilP2Delete) ifFalse:
			[bodySize := bodySize + 1.
			 copyWords := copyWords + (self instructionLengthAt: irOffset)].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	numCopySites := self copySitesFrom: loopHead + 2 to: backJump - 1.
	(trips * bodySize <= (oilUnrollFullBudgetValue > 0 ifTrue: [oilUnrollFullBudgetValue] ifFalse: [OilUnrollFullBudget])
	 and: [self canGrowBy: (trips * copyWords) + 1 sites: (trips - 1) * numCopySites]) ifFalse: [^false].
	oilUnrollHead at: oilNumUnrolls put: loopHead.
	oilUnrollBack at: oilNumUnrolls put: backJump.
	oilUnrollCount at: oilNumUnrolls put: trips.
	oilUnrollIV at: oilNumUnrolls put: ivReg.
	oilUnrollValue at: oilNumUnrolls put: ivStart.
	oilUnrollWord2 at: oilNumUnrolls put: copyWords.
	oilNumUnrolls := oilNumUnrolls + 1.
	oilUnrollGrowth := oilUnrollGrowth + (trips * copyWords) + 1.
	oilUnrollClones := oilUnrollClones + ((trips - 1) * numCopySites).
	oilNumFullyUnrolled := oilNumFullyUnrolled + 1.
	self mark: loopHead with: OilP2Unroll + OilP2Delete.
	self mark: backJump - 1 with: OilP2Delete.
	^true! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/26/2026 20:30'!
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
	(shift ~= 0 and: [siteIndex >= 0 and: [self keepsSiteAt: srcOffset]]) ifTrue:
		[siteIndex := self cloneSite: siteIndex at: dstOffset.
		 (opcode = OilGuardClass or: [opcode = OilGuardClass2]) ifTrue:
			[oilIRBuffer2 at: dstOffset put: ((oilIRBuffer2 at: dstOffset) bitAnd: 16rFFFF0000) + siteIndex].
		 opcode = OilCheckBounds ifTrue:
			[oilIRBuffer2 at: dstOffset put: ((oilIRBuffer2 at: dstOffset) bitAnd: 16rFFFFFF00) + siteIndex]].
	^nextOffset! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/27/2026 11:55'!
layOutFullyUnrolledLoop: unrollIndex at: startOffset
	"Map the instructions of the fully unrolled loop unrollIndex to their first copy (its original deopt sites are those of
	 the first copy), and answer the index following the unrolled code."
	| loopHead backJump irOffset dstOffset |
	loopHead := oilUnrollHead at: unrollIndex.
	backJump := oilUnrollBack at: unrollIndex.
	dstOffset := startOffset.
	oilIRMap at: loopHead put: dstOffset.
	oilIRMap at: loopHead + 1 put: dstOffset.
	irOffset := loopHead + 2.
	[irOffset < backJump] whileTrue:
		[oilIRMap at: irOffset put: dstOffset.
		 (irOffset = (backJump - 1) or: [(self flag: irOffset has: OilP2Delete) not]) ifTrue:
			[dstOffset := dstOffset + (self instructionLengthAt: irOffset)].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	dstOffset := startOffset + ((oilUnrollCount at: unrollIndex) * (oilUnrollWord2 at: unrollIndex)).
	oilIRMap at: backJump put: dstOffset.
	(self imm16At: loopHead + 1) ~= (backJump + 1) ifTrue:
		[dstOffset := dstOffset + 1].
	^dstOffset! !

!OilLoopOptimizer methodsFor: 'loop unrolling' stamp: 'cb 10/27/2026 11:55'!
emitFullyUnrolledLoop: unrollIndex at: startOffset
	"Emit the fully unrolled loop unrollIndex: count copies of its body, with the step of the induction variable replaced by
	 an OilConstTagged of its next value, and a jump to the exit if it does not follow."
	| loopHead backJump ivReg ivValue step dstOffset irOffset exitOffset |
	loopHead := oilUnrollHead at: unrollIndex.
	backJump := oilUnrollBack at: unrollIndex.
	ivReg := oilUnrollIV at: unrollIndex.
	ivValue := oilUnrollValue at: unrollIndex.
	step := self signed8: (self fieldCAt: backJump - 1).
	dstOffset := startOffset.
	0 to: (oilUnrollCount at: unrollIndex) - 1 do:
		[:copyIndex|
		irOffset := loopHead + 2.
		[irOffset < (backJump - 1)] whileTrue:
			[(self flag: irOffset has: OilP2Delete) ifFalse:
				[dstOffset := self emitCopyOf: irOffset at: dstOffset shift: copyIndex * (oilUnrollWord2 at: unrollIndex) from: loopHead to: backJump].
			 irOffset := irOffset + (self instructionLengthAt: irOffset)].
		ivValue := ivValue + step.
		oilIRBuffer2 at: dstOffset put: (OilConstTagged << 24) + (ivReg << 16) + ((ivValue << 3) + 1 bitAnd: 16rFFFF).
		dstOffset := dstOffset + 1].
	exitOffset := self imm16At: loopHead + 1.
	exitOffset ~= (backJump + 1) ifTrue:
		[oilIRBuffer2 at: dstOffset put: (OilJump << 24) + (oilIRMap at: exitOffset).
		 dstOffset := dstOffset + 1].
	^dstOffset! !

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
pass2Statistics: index
	"0 loops rotated, 1 bounds checks removed, (2 0: dead code is no longer eliminated), 3 sizes shared, 4 unchecked increments,
	 5 Pass 1 IR words, 6 class guards removed, 7 in-place tagged add undos; 23 loops fully unrolled."
	index = 0 ifTrue: [^oilNumRotated].
	index = 1 ifTrue: [^oilNumBoundsRemoved].
	index = 3 ifTrue: [^oilNumSizesShared].
	index = 4 ifTrue: [^oilNumNoCheck].
	index = 5 ifTrue: [^oilPass1Words].
	index = 6 ifTrue: [^oilNumGuardsRemoved].
	index = 7 ifTrue: [^oilNumUndos].
	index = 23 ifTrue: [^oilNumFullyUnrolled].
	^0! !

OilLoopOptimizer subclass: #OilFullCompiler
	instanceVariableNames: 'oilFactKind oilFactA oilFactB oilFactDest oilFactAt oilNumFacts oilNumLoadsRemoved oilNumChecksRemoved oilNumUnboxed'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-Oil'!

!OilFullCompiler commentStamp: 'cb 10/25/2026 02:00' prior: 0!
I am the full optimizing compiler of Oil (OilBytecodeScanner -> OilInliningCompiler -> OilLoopOptimizer -> OilFullCompiler), for the 64-bit Spur Cog VM.  To Pass 1 (translation and inlining into the linear IR), Pass 2 (the streaming loop optimizer) and Pass 3 (native code generation) I add:
- dominator-scoped local value numbering (valueNumber, run by Pass 2 before unrolling): loads of fields and sizes already loaded, and bounds and class checks already done, on every path, are eliminated, without SSA or phis;
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

!OilFullCompiler methodsFor: 'optimization' stamp: 'cb 10/26/2026 20:30'!
pipe
	<inline: true>
	oilNumLoadsRemoved := oilNumChecksRemoved := oilNumUnboxed := 0.
	super pipe.
	failed ifTrue: [^failureCode].
	self fuseFloats.
	^OilOK! !

!OilFullCompiler methodsFor: 'optimization' stamp: 'cb 10/27/2026 14:05'!
pass2Statistics: index
	"8 loads removed, 9 bounds and class checks removed, 10 unboxed float results; see OilLoopOptimizer.
	 And of Pass 1 and 3: 11 scalar replaced objects, 12 of them materialized, 13 bimorphic sends inlined, 14 bimorphic
	 predicates (class tests), 17 bimorphic nil or object sends (collapsed into the class test when compared with nil)."
	index = 8 ifTrue: [^oilNumLoadsRemoved].
	index = 11 ifTrue: [^oilNumVirtualized].
	index = 12 ifTrue: [^oilNumMaterialized].
	index = 13 ifTrue: [^oilNumBimorphic].
	index = 14 ifTrue: [^oilNumPredicates].
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

!OilFullCompiler methodsFor: 'float fusion' stamp: 'cb 10/26/2026 20:30'!
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
		[irOffset := (self isFloatOpcode: (self opcodeAt: irOffset))
						ifTrue: [self fuseFloatChainAt: irOffset]
						ifFalse: [irOffset + (self instructionLengthAt: irOffset)]]! !

!OilFullCompiler methodsFor: 'float fusion' stamp: 'cb 10/26/2026 20:30'!
fuseFloatChainAt: start
	"Mark the float chain starting with the float instruction at start, if any.  Answer the index to continue at."
	<inline: false>
	| site runEnd chainEnd irOffset opcode destReg numOps numUnboxedRegs |
	site := oilIRSite at: start.
	(site >= 0 and: [self siteHasState: site]) ifFalse: [^start + 1].
	"The run: float instructions, and constants assigning no register of the site's state, up to a label."
	runEnd := start.
	[runEnd < irIndex
	 and: [(runEnd = start or: [(oilIRTarget at: runEnd) = 0])
	 and: [opcode := self opcodeAt: runEnd.
		   (self isFloatOpcode: opcode)
		   or: [(opcode = OilConstTagged or: [opcode = OilConst64])
				and: [(self state: site refersTo: (self fieldAAt: runEnd)) not]]]]] whileTrue:
		[runEnd := runEnd + (self instructionLengthAt: runEnd)].
	"The chain ends with the first float result that may be read after the run (or with the run)."
	chainEnd := -1.
	numOps := 0.
	irOffset := start.
	[chainEnd < 0 and: [irOffset < runEnd]] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (self isFloatOpcode: opcode) ifTrue:
			[numOps := numOps + 1.
			 (opcode = OilCmpFloat or: [self isEscaping: irOffset runEnd: runEnd]) ifTrue: [chainEnd := irOffset]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	chainEnd < 0 ifTrue:
		[irOffset := start.
		 [irOffset < runEnd] whileTrue:
			[(self isFloatOpcode: (self opcodeAt: irOffset)) ifTrue: [chainEnd := irOffset].
			 irOffset := irOffset + (self instructionLengthAt: irOffset)]].
	numOps < 2 ifTrue: [^chainEnd + 1].
	"The results before chainEnd must not be read after it, and must fit the XMM registers."
	numUnboxedRegs := 0.
	irOffset := start.
	[irOffset < chainEnd] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (self isFloatArith: opcode) ifTrue:
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
		 ((self isFloatArith: opcode)
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

!OilLoopOptimizer methodsFor: 'pass 2 optimization' stamp: 'cb 10/26/2026 20:30'!
isRead: vreg from: startOffset to: endOffset
	"Is register vreg read, by an instruction or the deopt state of a live site, from startOffset to before endOffset
	 (straight-line code), before being assigned?  The instructions deleted by Pass 2 do not count."
	| irOffset |
	irOffset := startOffset.
	[irOffset < endOffset] whileTrue:
		[(self flag: irOffset has: OilP2Delete) ifFalse:
			[((self instruction: irOffset reads: vreg) or: [self liveStateAt: irOffset refersTo: vreg]) ifTrue: [^true].
			 ((self opcodeHasDest: (self opcodeAt: irOffset)) and: [(self fieldAAt: irOffset) = vreg]) ifTrue: [^false]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^false! !

!OilFullCompiler methodsFor: 'float fusion' stamp: 'cb 10/27/2026 13:55'!
isLive: vreg from: startOffset
	"May register vreg be read at or after startOffset before being assigned?  The registers
	 the deopt metadata of the frames and virtual objects refers to are live."
	| irOffset opcode straight |
	(self isMetadataRegister: vreg) ifTrue: [^true].
	straight := true.
	irOffset := startOffset.
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (irOffset > startOffset and: [(oilIRTarget at: irOffset) ~= 0]) ifTrue: [straight := false].
		 ((self instruction: irOffset reads: vreg) or: [self liveStateAt: irOffset refersTo: vreg]) ifTrue: [^true].
		 straight ifTrue:
			[(((self opcodeHasDest: opcode) and: [(self fieldAAt: irOffset) = vreg])
			  or: [opcode = OilReturn or: [opcode = OilTrap]]) ifTrue: [^false]].
		 (self isBranch: opcode) ifTrue:
			[straight := false.
			 ((self imm16At: irOffset) < startOffset
			  and: [self isRead: vreg from: (self imm16At: irOffset) to: startOffset]) ifTrue: [^true]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^false! !

!OilFullCompiler methodsFor: 'float fusion' stamp: 'cb 10/26/2026 20:30'!
isMetadataRegister: vreg
	"Does the deoptimization metadata of an inlined frame (its receiver) or of a virtual object refer to register vreg?"
	| found |
	found := false.
	self metadataRegistersDo: [:reg| reg = vreg ifTrue: [found := true]] sites: false.
	^found! !

Smalltalk globals removeKey: #OilCompiler ifAbsent: [].
Smalltalk at: #OilCompiler put: OilFullCompiler!
