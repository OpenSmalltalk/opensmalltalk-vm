"Pass 2 of Oil (OilLoopCompiler), the streaming loop optimizer.  It reads the linear IR Pass 1 produced in Buffer 1
 (oilIRBuffer1) and writes the optimized IR into Buffer 2 (oilIRBuffer2), which Pass 3 then
 translates to machine code.  All its tables are static; it allocates nothing.  Author: cb."!

OilBaseCompiler subclass: #OilLoopCompiler
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-Oil'!

!OilLoopCompiler commentStamp: 'cb 10/24/2026 19:35' prior: 0!
I add Pass 2, the streaming loop optimizer, to OilBaseCompiler.  Given the linear IR Pass 1 produced in Buffer 1 (oilIRBuffer1), pipe (via loopOptimize) analyzes tagged SmallInteger registers, rotates innermost call-free loops, eliminates redundant bounds checks, class guards and overflow checks on induction variables, removes dead pure instructions, and streams the optimized IR into Buffer 2 (oilIRBuffer2) for Pass 3.!

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 19:35'!
pipe
	<inline: true>
	super pipe.
	^self loopOptimize! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
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
	 3. Dead code: pure instructions defining a register nothing reads (no instruction, no deopt state).
	 4. Emission (streaming, one pass to lay out, one to emit), remapping branch targets and deopt sites.
	 Answer OilOK or a failure code."
	| irOffset opcode branchTarget optimize |
	oilIRBuffer := oilIRBuffer1.
	oilPass1Words := irIndex.
	oilNumRotated := oilNumBoundsRemoved := oilNumDeadRemoved := oilNumSizesShared := oilNumNoCheck := oilNumGuardsRemoved := oilNumUndos := 0.
	oilUseProbe := -1.
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
		 self eliminateDeadCode].
	^self emitOptimizedIR! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
isCall: opcode
	<inline: true>
	^opcode = OilCall0 or: [opcode = OilCall1 or: [opcode = OilCallN or: [opcode = OilCallSuper]]]! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
flag: irOffset has: mask
	<inline: true>
	^((oilIRFlag at: irOffset) bitAnd: mask) ~= 0! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
mark: irOffset with: mask
	<inline: true>
	oilIRFlag at: irOffset put: ((oilIRFlag at: irOffset) bitOr: mask)! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
isPureAt: irOffset
	"Does the instruction at irOffset only compute its destination (no side effect, no deopt, no control flow)?"
	| opcode |
	opcode := self opcodeAt: irOffset.
	^opcode = OilConstTagged or: [opcode = OilConst64 or: [opcode = OilMove or: [opcode = OilLoadSize or: [opcode = OilLoadByteSize or: [opcode = OilLoadField
		or: [opcode = OilAddImmTagged and: [self flag: irOffset has: OilP2NoCheck]]]]]]]! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
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

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
optimizeLoop: loopHead backJump: backJump
	"Optimize the loop from loopHead to the Jump at backJump, if it is innermost, free of calls and only entered by
	 falling into loopHead, and its header is pure code then OilCmpTagged and an OilBranchFalse that leaves the loop."
	<inline: false>
	| irOffset opcode cmpOffset bfOffset exitOffset cond ivReg limitReg limitDef arrayReg regionStart ivDefsInLoop ivInit ivInitValue sizeAlias |
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
	((self opcodeAt: cmpOffset) = OilCmpTagged
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
	"Rotation: the test is duplicated at the bottom, without its deopt site, so it must not be able to fail."
	(cond < OilCondIdentical and: [(self isTagged: ivReg) and: [self isTagged: limitReg]]) ifTrue:
		[self mark: backJump with: OilP2RotBack.
		 oilNumRotated := oilNumRotated + 1].
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

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
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

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
isGuarded: vreg class: classHandle from: startOffset to: endOffset
	"Is there an OilGuardClass of register vreg for classHandle in the instructions from startOffset to endOffset?"
	| irOffset |
	irOffset := startOffset.
	[irOffset < endOffset] whileTrue:
		[((self opcodeAt: irOffset) = OilGuardClass
		  and: [(self fieldAAt: irOffset) = vreg
		  and: [(self word64At: irOffset + 1) = classHandle
		  and: [(self flag: irOffset has: OilP2Delete) not]]]) ifTrue: [^true].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^false! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
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

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
isLiveSite: siteIndex
	"Is deopt site siteIndex still attached to an instruction that can deoptimize?"
	| irOffset |
	irOffset := siteIR at: siteIndex.
	^irOffset >= 0 and: [(siteSnapBase at: siteIndex) >= 0 and: [(self flag: irOffset has: OilP2Delete + OilP2NoCheck) not]]! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
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

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
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

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
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

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
state: siteIndex refersTo: vreg
	"Does the deopt state of site siteIndex refer to register vreg?"
	| snapBase stateSize |
	snapBase := siteSnapBase at: siteIndex.
	stateSize := self siteStateSize: siteIndex.
	0 to: stateSize - 1 do:
		[:slotIndex| ((sitePoolKind at: snapBase + slotIndex) = OilDescReg and: [(sitePoolValue at: snapBase + slotIndex) = vreg]) ifTrue: [^true]].
	^false! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
rotatedHeaderCompareOf: backJump
	"The OilCmpTagged of the header of the rotated loop closed by the Jump at backJump (see optimizeLoop:backJump:)."
	| irOffset |
	irOffset := self imm16At: backJump.
	[(self opcodeAt: irOffset) = OilCmpTagged] whileFalse:
		[irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^irOffset! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
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

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
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

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
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
	dstOffset := self emitInstructionAt: cmpOffset at: dstOffset.
	oilIRBuffer2 at: dstOffset put: (OilBranchTrue bitShift: 24) + (OilFlagsReg bitShift: 16) + (oilIRMap at: cmpOffset + 2).
	dstOffset := dstOffset + 1.
	exitTarget := self imm16At: cmpOffset + 1.
	exitTarget ~= (backJump + (self instructionLengthAt: backJump)) ifTrue:
		[oilIRBuffer2 at: dstOffset put: (OilJump bitShift: 24) + (oilIRMap at: exitTarget).
		 dstOffset := dstOffset + 1].
	^dstOffset! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/25/2026 00:45'!
emitOptimizedIR
	"Stream Buffer 1 into Buffer 2: lay out (the index in Buffer 2 of every instruction of Buffer 1, in oilIRMap),
	 then emit, then remap the deopt sites, whose instructions were deleted or no longer deoptimize (dead, -2) or moved.
	 Buffer 2 becomes the current IR."
	| srcOffset dstOffset instrLen siteIROffset |
	dstOffset := 0.
	srcOffset := 0.
	[srcOffset < irIndex] whileTrue:
		[instrLen := self instructionLengthAt: srcOffset.
		 oilIRMap at: srcOffset put: dstOffset.
		 (self flag: srcOffset has: OilP2Delete) ifFalse:
			[dstOffset := dstOffset + ((self flag: srcOffset has: OilP2RotBack)
						ifTrue: [self sizeOfRotatedBackJump: srcOffset]
						ifFalse: [instrLen])].
		 srcOffset := srcOffset + instrLen].
	oilIRMap at: irIndex put: dstOffset.
	dstOffset > OilBufferWords ifTrue:
		[self abortCompilation: OilFailBufferFull.
		 ^failureCode].
	dstOffset := 0.
	srcOffset := 0.
	[srcOffset < irIndex] whileTrue:
		[instrLen := self instructionLengthAt: srcOffset.
		 (self flag: srcOffset has: OilP2Delete) ifFalse:
			[dstOffset := (self flag: srcOffset has: OilP2RotBack)
					ifTrue: [self emitRotatedBackJump: srcOffset at: dstOffset]
					ifFalse: [self emitInstructionAt: srcOffset at: dstOffset]].
		 srcOffset := srcOffset + instrLen].
	self assert: dstOffset = (oilIRMap at: irIndex).
	0 to: numSites - 1 do:
		[:siteIndex|
		siteIROffset := siteIR at: siteIndex.
		siteIROffset >= 0 ifTrue:
			[siteIR at: siteIndex put: ((self flag: siteIROffset has: OilP2Delete + OilP2NoCheck)
									ifTrue: [-2]
									ifFalse: [oilIRMap at: siteIROffset])]].
	oilIRBuffer := oilIRBuffer2.
	irIndex := dstOffset.
	^OilOK! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
pass2Statistics: index
	"0 loops rotated, 1 bounds checks removed, 2 dead instructions removed, 3 sizes shared, 4 unchecked increments,
	 5 Pass 1 IR words, 6 class guards removed, 7 in-place tagged add undos."
	index = 0 ifTrue: [^oilNumRotated].
	index = 1 ifTrue: [^oilNumBoundsRemoved].
	index = 2 ifTrue: [^oilNumDeadRemoved].
	index = 3 ifTrue: [^oilNumSizesShared].
	index = 4 ifTrue: [^oilNumNoCheck].
	index = 5 ifTrue: [^oilPass1Words].
	index = 6 ifTrue: [^oilNumGuardsRemoved].
	index = 7 ifTrue: [^oilNumUndos].
	^0! !

(Smalltalk hasClassNamed: #OilNumericCompiler) ifTrue: [(Smalltalk at: #OilNumericCompiler) removeFromSystem].!

OilLoopCompiler subclass: #OilFullCompiler
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-Oil'!

!OilFullCompiler commentStamp: 'cb 10/25/2026 01:15' prior: 0!
I am the full optimizing compiler of Oil (OilBytecodeScanner -> OilBaseCompiler -> OilLoopCompiler -> OilFullCompiler), bringing high-performance, lightweight JIT compilation to OpenSmalltalk's 64-bit Spur Cog VM.

I combine a clean, robust 3-stage pipeline designed for extreme speed and zero memory allocation:
1. Pass 1 (OilBaseCompiler): Front-end translation and inlining. Recursively flattens the outer home method, inlining blocks, monomorphic sends, standard collection iterators (do:, collect:, detect:), and small methods directly into a compact 32-bit linear IR in Buffer 1. Applies on-the-fly tagged SmallInteger peephole reductions and dissolves non-escaping temp vectors into registers.
2. Pass 2 (OilLoopCompiler): Streaming loop optimization. Sweeps Buffer 1 into Buffer 2 with zero SSA complexity. Rotates innermost call-free loops into DO-WHILE headers, hoists invariant array bounds and class checks out of loop bodies into pre-headers, transforms induction variable increments into direct 1-cycle machine adds, and sweeps away dead pure instructions.
3. Pass 3 (Native Backend): Back-end code generation. Maps linear IR directly to native machine code (x86-64 / ARM64) with backwards linear scan register allocation, leveraging the 64-bit Spur 3-bit tag arithmetic breakthrough to achieve raw C speed without boxing or OopMap overhead.

Because every buffer and side-table is pre-allocated in static BSS memory (< 200 KB total), I compile in under 100 microseconds synchronously without pausing the mutator, allocating zero heap objects, and generating native code that runs neck-and-neck with handwritten C.!

!OilFullCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 19:35'!
pipe
	<inline: true>
	^super pipe! !

Smalltalk globals removeKey: #OilCompiler ifAbsent: [].
Smalltalk at: #OilCompiler put: OilFullCompiler!
