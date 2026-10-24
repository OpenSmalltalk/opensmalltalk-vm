"Pass 2 of Oil (OilLoopCompiler), the streaming loop optimizer.  It reads the linear IR Pass 1 produced in Buffer 1
 (oilIRBuffer1) and writes the optimized IR into Buffer 2 (oilIRBuffer2), which Pass 3 (OilCompilerBackend.st) then
 translates to machine code.  All its tables are static; it allocates nothing.  Author: cb."!

OilBaseCompiler subclass: #OilLoopCompiler
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-Oil'!

!OilLoopCompiler commentStamp: 'cb 10/24/2026 19:35' prior: 0!
I add Pass 2, the streaming loop optimizer, to OilBaseCompiler.  Given the linear IR Pass 1 produced in Buffer 1 (oilIRBuffer1), pipe (via pass2Optimize) analyzes tagged SmallInteger registers, rotates innermost call-free loops, eliminates redundant bounds checks, class guards and overflow checks on induction variables, removes dead pure instructions, and streams the optimized IR into Buffer 2 (oilIRBuffer2) for Pass 3.!

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 19:35'!
pipe
	<inline: true>
	super pipe.
	^self pass2Optimize! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
pass2Optimize
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
	| i op t optimize |
	oilIRBuffer := oilIRBuffer1.
	oilPass1Words := irIndex.
	oilNumRotated := oilNumBoundsRemoved := oilNumDeadRemoved := oilNumSizesShared := oilNumNoCheck := oilNumGuardsRemoved := oilNumUndos := 0.
	oilUseProbe := -1.
	0 to: irIndex - 1 do:
		[:j|
		oilIRFlag at: j put: 0.
		oilIRAux at: j put: 0.
		oilIRTarget at: j put: 0].
	0 to: OilNumRegs - 1 do:
		[:r| oilVRegDefs at: r put: 0].
	optimize := true.
	i := 0.
	[i < irIndex] whileTrue:
		[op := self opcodeAt: i.
		 (op = OilMakeClosure or: [op = OilNewArray]) ifTrue: [optimize := false].
		 (self opcodeHasDest: op) ifTrue:
			[oilVRegDefs at: (self fieldAAt: i) put: (oilVRegDefs at: (self fieldAAt: i)) + 1].
		 (self isBranch: op) ifTrue:
			[t := self imm16At: i.
			 t >= irIndex ifTrue:
				[self abortCompilation: OilFailInternal.
				 ^failureCode].
			 oilIRTarget at: t put: ((oilIRTarget at: t) + 1 min: 255)].
		 i := i + (self instructionLengthAt: i)].
	self computeIRSites.
	optimize ifTrue:
		[self analyzeTaggedRegisters.
		 i := 0.
		 [i < irIndex] whileTrue:
			[((self opcodeAt: i) = OilJump and: [(self imm16At: i) <= i]) ifTrue:
				[self p2OptimizeLoop: (self imm16At: i) backJump: i].
			 i := i + (self instructionLengthAt: i)].
		 self p2EliminateDeadCode].
	^self p2Emit! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
p2IsCall: op
	<inline: true>
	^op = OilCall0 or: [op = OilCall1 or: [op = OilCallN or: [op = OilCallSuper]]]! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
p2Flag: i has: mask
	<inline: true>
	^((oilIRFlag at: i) bitAnd: mask) ~= 0! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
p2Mark: i with: mask
	<inline: true>
	oilIRFlag at: i put: ((oilIRFlag at: i) bitOr: mask)! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
p2IsPureAt: i
	"Does the instruction at i only compute its destination (no side effect, no bailout, no control flow)?"
	| op |
	op := self opcodeAt: i.
	^op = OilConstTagged or: [op = OilConst64 or: [op = OilMove or: [op = OilLoadSize or: [op = OilLoadByteSize or: [op = OilLoadField
		or: [op = OilAddImmTagged and: [self p2Flag: i has: OilP2NoCheck]]]]]]]! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
p2RegionStartBefore: loopHead
	"Answer the start of the straight-line code that falls into loopHead: the instructions from there to loopHead
	 are entered only at their start (no branch target among them but the first) and contain no branch, so each
	 of them executes, in order, every time the loop is entered by falling into its header."
	| i op start |
	start := 0.
	i := 0.
	[i < loopHead] whileTrue:
		[op := self opcodeAt: i.
		 (oilIRTarget at: i) ~= 0 ifTrue: [start := i].
		 ((self isBranch: op) or: [op = OilReturn]) ifTrue: [start := i + (self instructionLengthAt: i)].
		 i := i + (self instructionLengthAt: i)].
	^start! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
p2OptimizeLoop: loopHead backJump: backJump
	"Optimize the loop from loopHead to the Jump at backJump, if it is innermost, free of calls and only entered by
	 falling into loopHead, and its header is pure code then OilCmpTagged and an OilBranchFalse that leaves the loop."
	<inline: false>
	| i op cmp bf exit cond iv lim limDef x regionStart ivDefsInLoop ivInit ivInitValue sizeAlias |
	(oilIRTarget at: loopHead) = 1 ifFalse: [^self]. "only the back jump branches to the loop head"
	i := loopHead.
	[i < backJump] whileTrue:
		[op := self opcodeAt: i.
		 (self p2IsCall: op) ifTrue: [^self].
		 ((self isBranch: op) and: [(self imm16At: i) <= i]) ifTrue: [^self].
		 i := i + (self instructionLengthAt: i)].
	self p2RemoveInvariantChecksInLoop: loopHead backJump: backJump.
	"The header: pure instructions without deopt sites, nothing branching into them."
	i := loopHead.
	[(i = loopHead or: [(oilIRTarget at: i) = 0])
	 and: [(self p2IsPureAt: i) and: [(oilIRSite at: i) < 0]]] whileTrue:
		[i := i + (self instructionLengthAt: i)].
	cmp := i.
	bf := cmp + 1.
	((self opcodeAt: cmp) = OilCmpTagged
	 and: [bf < backJump
	 and: [(cmp = loopHead or: [(oilIRTarget at: cmp) = 0])
	 and: [(self opcodeAt: bf) = OilBranchFalse
	 and: [(self fieldAAt: bf) = OilFlagsReg
	 and: [(oilIRTarget at: bf) = 0]]]]]) ifFalse: [^self].
	exit := self imm16At: bf.
	(exit > backJump or: [exit < loopHead]) ifFalse: [^self].
	cond := self fieldAAt: cmp.
	iv := self fieldBAt: cmp.
	lim := self fieldCAt: cmp.
	"Rotation: the test is duplicated at the bottom, without its deopt site, so it must not be able to fail."
	(cond < OilCondIdentical and: [(self isTagged: iv) and: [self isTagged: lim]]) ifTrue:
		[self p2Mark: backJump with: OilP2RotBack.
		 oilNumRotated := oilNumRotated + 1].
	"A counted loop?  iv <= lim (or iv < lim), lim the size of an object x that is never assigned (the receiver or
	 an argument), lim assigned only once, before the loop; iv assigned a constant >= 1 before the loop and only
	 incremented in the loop.  Then 1 <= iv <= lim holds after the test, and the increments cannot overflow."
	(cond = OilCondLe or: [cond = OilCondLt]) ifFalse: [^self].
	(iv ~= lim and: [iv < OilFlagsReg and: [lim < OilFlagsReg]]) ifFalse: [^self].
	(oilVRegDefs at: lim) = 1 ifFalse: [^self].
	regionStart := self p2RegionStartBefore: loopHead.
	limDef := -1.
	ivInit := -1.
	ivDefsInLoop := 0.
	i := regionStart.
	[i < backJump] whileTrue:
		[op := self opcodeAt: i.
		 (i < loopHead and: [self p2IsCall: op]) ifTrue: [^self]. "(a call could become: x)"
		 (self opcodeHasDest: op) ifTrue:
			[(self fieldAAt: i) = lim ifTrue: [limDef := i].
			 (self fieldAAt: i) = iv ifTrue:
				[i < loopHead
					ifTrue: [ivInit := i]
					ifFalse:
						[(op = OilAddImmTagged
						  and: [(self fieldBAt: i) = iv
						  and: [(self signed8: (self fieldCAt: i)) > 0]]) ifFalse: [^self].
						 ivDefsInLoop := ivDefsInLoop + 1]]].
		 i := i + (self instructionLengthAt: i)].
	(limDef >= 0 and: [limDef < loopHead and: [(self opcodeAt: limDef) = OilLoadSize or: [(self opcodeAt: limDef) = OilLoadByteSize]]]) ifFalse: [^self].
	x := self fieldBAt: limDef.
	(oilVRegDefs at: x) = 0 ifFalse: [^self].
	(ivInit >= 0 and: [(self opcodeAt: ivInit) = OilConstTagged]) ifFalse: [^self].
	ivInitValue := self signed16: (self imm16At: ivInit).
	((ivInitValue bitShift: -3) >= 1 "untagged (64-bit SmallIntegers have 3 tag bits)"
	 and: [(oilVRegDefs at: iv) = (1 + ivDefsInLoop)]) ifFalse: [^self].
	"The index increments cannot overflow: iv <= lim, a size, at the test, and each increment (by at most 127)
	 runs at most once per iteration."
	i := loopHead.
	[i < backJump] whileTrue:
		[((self opcodeHasDest: (self opcodeAt: i)) and: [(self fieldAAt: i) = iv]) ifTrue:
			[self p2Mark: i with: OilP2NoCheck.
			 oilNumNoCheck := oilNumNoCheck + 1].
		 i := i + (self instructionLengthAt: i)].
	"After the test, in the straight-line code that follows it: size(x) is lim, and 1 <= iv <= lim (or a register
	 holding size(x)) needs no check."
	sizeAlias := -1.
	i := bf + 1.
	[i < backJump and: [(oilIRTarget at: i) = 0]] whileTrue:
		[op := self opcodeAt: i.
		 ((self isBranch: op) or: [op = OilReturn]) ifTrue: [^self].
		 (op = OilCheckBounds
		  and: [(self fieldAAt: i) = iv
		  and: [(self fieldBAt: i) = lim or: [(self fieldBAt: i) = sizeAlias]]]) ifTrue:
			[self p2Mark: i with: OilP2Delete.
			 oilNumBoundsRemoved := oilNumBoundsRemoved + 1].
		 (self opcodeHasDest: op) ifTrue:
			[((self fieldAAt: i) = iv or: [(self fieldAAt: i) = lim]) ifTrue: [^self].
			 (self fieldAAt: i) = sizeAlias ifTrue: [sizeAlias := -1].
			 (op = (self opcodeAt: limDef) and: [(self fieldBAt: i) = x]) ifTrue:
				[(self p2Flag: i has: OilP2ToMove) ifFalse:
					[oilNumSizesShared := oilNumSizesShared + 1].
				 self p2Mark: i with: OilP2ToMove.
				 oilIRAux at: i put: lim.
				 sizeAlias := self fieldAAt: i]].
		 i := i + (self instructionLengthAt: i)]! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 17:00'!
p2RemoveInvariantChecksInLoop: loopHead backJump: backJump
	"In an innermost, call-free loop entered only by falling into loopHead: a class guard of a register that is never
	 assigned (the receiver or an argument) is redundant if the straight-line code falling into the loop, free of
	 calls (which could become: it), guards it already; and the size of such a register is the one that code loaded
	 into a register assigned only there."
	<inline: false>
	| regionStart i op r k |
	regionStart := self p2RegionStartBefore: loopHead.
	i := regionStart.
	[i < loopHead] whileTrue:
		[(self p2IsCall: (self opcodeAt: i)) ifTrue: [^self].
		 i := i + (self instructionLengthAt: i)].
	i := loopHead.
	[i < backJump] whileTrue:
		[op := self opcodeAt: i.
		 r := op = OilGuardClass ifTrue: [self fieldAAt: i] ifFalse: [self fieldBAt: i].
		 (op = OilGuardClass
		  and: [(oilVRegDefs at: r) = 0
		  and: [self p2IsGuarded: r class: (self word64At: i + 1) from: regionStart to: loopHead]]) ifTrue:
			[self p2Mark: i with: OilP2Delete.
			 oilNumGuardsRemoved := oilNumGuardsRemoved + 1].
		 ((op = OilLoadSize or: [op = OilLoadByteSize])
		  and: [(oilVRegDefs at: r) = 0
		  and: [(k := self p2SizeRegisterOf: r op: op from: regionStart to: loopHead) >= 0]]) ifTrue:
			[self p2Mark: i with: OilP2ToMove.
			 oilIRAux at: i put: k.
			 oilNumSizesShared := oilNumSizesShared + 1].
		 i := i + (self instructionLengthAt: i)]! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 17:00'!
p2IsGuarded: r class: classHandle from: start to: end
	"Is there an OilGuardClass of register r for classHandle in the instructions from start to end?"
	| i |
	i := start.
	[i < end] whileTrue:
		[((self opcodeAt: i) = OilGuardClass
		  and: [(self fieldAAt: i) = r
		  and: [(self word64At: i + 1) = classHandle
		  and: [(self p2Flag: i has: OilP2Delete) not]]]) ifTrue: [^true].
		 i := i + (self instructionLengthAt: i)].
	^false! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 17:00'!
p2SizeRegisterOf: x op: sizeOp from: start to: end
	"Answer a register assigned only once, by a sizeOp (OilLoadSize or OilLoadByteSize) of x in the instructions from
	 start to end, or -1."
	| i |
	i := start.
	[i < end] whileTrue:
		[((self opcodeAt: i) = sizeOp
		  and: [(self fieldBAt: i) = x
		  and: [(oilVRegDefs at: (self fieldAAt: i)) = 1
		  and: [(self p2Flag: i has: OilP2Delete + OilP2ToMove) not]]]) ifTrue: [^self fieldAAt: i].
		 i := i + (self instructionLengthAt: i)].
	^-1! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
p2IsLiveSite: s
	"Is deopt site s still attached to an instruction that can bail out?"
	| i |
	i := siteIR at: s.
	^i >= 0 and: [(siteSnapBase at: s) >= 0 and: [(self p2Flag: i has: OilP2Delete + OilP2NoCheck) not]]! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 19:20'!
p2CountMetadataUses
	"Count the registers the deoptimization metadata refers to: the states of the live deopt sites, the receivers
	 of the inlined frames and of the virtual objects, and the values the virtual objects captured."
	| base n |
	0 to: numSites - 1 do:
		[:s|
		(self p2IsLiveSite: s) ifTrue:
			[base := siteSnapBase at: s.
			 n := self siteStateSize: s.
			 0 to: n - 1 do:
				[:j| (sitePoolKind at: base + j) = OilDescReg ifTrue:
					[self p2Use: (sitePoolValue at: base + j)]]]].
	0 to: numFrames - 1 do:
		[:f| (frameSelfKind at: f) = OilDescReg ifTrue:
			[self p2Use: (frameSelfValue at: f)]].
	0 to: numVObjs - 1 do:
		[:v|
		(vobjSelfKind at: v) = OilDescReg ifTrue:
			[self p2Use: (vobjSelfValue at: v)].
		0 to: (vobjNumCopied at: v) - 1 do:
			[:j| (capturedKind at: (vobjCopiedBase at: v) + j) = OilDescReg ifTrue:
				[self p2Use: (capturedValue at: (vobjCopiedBase at: v) + j)]]]! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 19:20'!
p2EliminateDeadCode
	"Delete the pure instructions whose destination nothing reads (anywhere, or before it is assigned again in the
	 straight-line code that follows), until there are none."
	| changed i |
	oilUseWeight := 1.
	changed := true.
	[changed] whileTrue:
		[changed := false.
		 0 to: OilNumRegs - 1 do:
			[:r| oilVRegUses at: r put: 0].
		 i := 0.
		 [i < irIndex] whileTrue:
			[(self p2Flag: i has: OilP2Delete) ifFalse:
				[(self p2Flag: i has: OilP2ToMove)
					ifTrue: [self p2Use: (oilIRAux at: i)]
					ifFalse: [self p2CountUsesAt: i]].
			 i := i + (self instructionLengthAt: i)].
		 self p2CountMetadataUses.
		 i := 0.
		 [i < irIndex] whileTrue:
			[((self p2Flag: i has: OilP2Delete) not
			  and: [(self p2IsPureAt: i)
			  and: [(self fieldAAt: i) < OilFlagsReg
			  and: [(oilVRegUses at: (self fieldAAt: i)) = 0
					or: [self p2IsOverwrittenBeforeUse: (self fieldAAt: i) after: i]]]]) ifTrue:
				[self p2Mark: i with: OilP2Delete.
				 oilNumDeadRemoved := oilNumDeadRemoved + 1.
				 changed := true].
			 i := i + (self instructionLengthAt: i)]]! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 19:20'!
p2IsOverwrittenBeforeUse: r after: def
	"Is register r, assigned by the instruction at def, assigned again before anything reads it?  Only the straight-line
	 code after def is examined (up to a branch target, a branch, a return or a call, where r is assumed live).
	 Reads are instruction operands and the deopt states of the instructions' live sites."
	<inline: false>
	| i op s |
	i := def + (self instructionLengthAt: def).
	[i < irIndex] whileTrue:
		[op := self opcodeAt: i.
		 ((oilIRTarget at: i) ~= 0
		  or: [(self isBranch: op) or: [op = OilReturn or: [self p2IsCall: op]]]) ifTrue: [^false].
		 (self p2Flag: i has: OilP2Delete) ifFalse:
			[oilUseProbe := r.
			 oilUseProbeHit := false.
			 (self p2Flag: i has: OilP2ToMove)
				ifTrue: [self p2Use: (oilIRAux at: i)]
				ifFalse: [self p2CountUsesAt: i].
			 oilUseProbe := -1.
			 oilUseProbeHit ifTrue: [^false].
			 s := oilIRSite at: i.
			 (s >= 0 and: [(self p2IsLiveSite: s) and: [self p2State: s refersTo: r]]) ifTrue: [^false].
			 ((self opcodeHasDest: op) and: [(self fieldAAt: i) = r]) ifTrue: [^true]].
		 i := i + (self instructionLengthAt: i)].
	^false! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 19:20'!
p2State: s refersTo: r
	"Does the deopt state of site s refer to register r?"
	| base n |
	base := siteSnapBase at: s.
	n := self siteStateSize: s.
	0 to: n - 1 do:
		[:j| ((sitePoolKind at: base + j) = OilDescReg and: [(sitePoolValue at: base + j) = r]) ifTrue: [^true]].
	^false! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
p2RotatedHeaderCompareOf: backJump
	"The OilCmpTagged of the header of the rotated loop closed by the Jump at backJump (see p2OptimizeLoop:backJump:)."
	| i |
	i := self imm16At: backJump.
	[(self opcodeAt: i) = OilCmpTagged] whileFalse:
		[i := i + (self instructionLengthAt: i)].
	^i! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
p2SizeOfRotatedBackJump: backJump
	"The size of what replaces the back jump of a rotated loop: a copy of the header (its live instructions) and of
	 its test, a branch back if the test holds, and a jump to the exit if the exit does not follow the loop."
	| i cmp n |
	cmp := self p2RotatedHeaderCompareOf: backJump.
	n := 2.
	i := self imm16At: backJump.
	[i < cmp] whileTrue:
		[(self p2Flag: i has: OilP2Delete) ifFalse:
			[n := n + (self instructionLengthAt: i)].
		 i := i + (self instructionLengthAt: i)].
	(self imm16At: cmp + 1) ~= (backJump + (self instructionLengthAt: backJump)) ifTrue:
		[n := n + 1].
	^n! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
p2EmitInstructionAt: i at: n
	"Copy the instruction at i of Buffer 1 to n in Buffer 2, applying its Pass 2 rewrites and remapping its branch
	 target.  Answer the index following it in Buffer 2."
	| op word len |
	op := self opcodeAt: i.
	len := self instructionLengthAt: i.
	word := oilIRBuffer1 at: i.
	(self p2Flag: i has: OilP2ToMove) ifTrue:
		[word := (OilMove bitShift: 24) + ((self fieldAAt: i) bitShift: 16) + ((oilIRAux at: i) bitShift: 8)].
	(self p2Flag: i has: OilP2NoCheck) ifTrue:
		[word := (word bitAnd: 16rFFFFFF) + (OilAddImmTaggedNC bitShift: 24)].
	(self isBranch: op) ifTrue:
		[word := (word bitAnd: 16rFFFF0000) + (oilIRMap at: (self imm16At: i))].
	oilIRBuffer2 at: n put: word.
	1 to: len - 1 do:
		[:k| oilIRBuffer2 at: n + k put: (oilIRBuffer1 at: i + k)].
	^n + len! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
p2EmitRotatedBackJump: backJump at: start
	"The bottom of a rotated loop: the header and its test again, then branch back to the first instruction after the
	 header's test if it holds, else go to the exit."
	| i cmp n exit |
	cmp := self p2RotatedHeaderCompareOf: backJump.
	n := start.
	i := self imm16At: backJump.
	[i < cmp] whileTrue:
		[(self p2Flag: i has: OilP2Delete) ifFalse:
			[n := self p2EmitInstructionAt: i at: n].
		 i := i + (self instructionLengthAt: i)].
	n := self p2EmitInstructionAt: cmp at: n.
	oilIRBuffer2 at: n put: (OilBranchTrue bitShift: 24) + (OilFlagsReg bitShift: 16) + (oilIRMap at: cmp + 2).
	n := n + 1.
	exit := self imm16At: cmp + 1.
	exit ~= (backJump + (self instructionLengthAt: backJump)) ifTrue:
		[oilIRBuffer2 at: n put: (OilJump bitShift: 24) + (oilIRMap at: exit).
		 n := n + 1].
	^n! !

!OilLoopCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 16:00'!
p2Emit
	"Stream Buffer 1 into Buffer 2: lay out (the index in Buffer 2 of every instruction of Buffer 1, in oilIRMap),
	 then emit, then remap the deopt sites, whose instructions were deleted or no longer bail out (dead, -2) or moved.
	 Buffer 2 becomes the current IR."
	| i n len si |
	n := 0.
	i := 0.
	[i < irIndex] whileTrue:
		[len := self instructionLengthAt: i.
		 oilIRMap at: i put: n.
		 (self p2Flag: i has: OilP2Delete) ifFalse:
			[n := n + ((self p2Flag: i has: OilP2RotBack)
						ifTrue: [self p2SizeOfRotatedBackJump: i]
						ifFalse: [len])].
		 i := i + len].
	oilIRMap at: irIndex put: n.
	n > OilBufferWords ifTrue:
		[self abortCompilation: OilFailBufferFull.
		 ^failureCode].
	n := 0.
	i := 0.
	[i < irIndex] whileTrue:
		[len := self instructionLengthAt: i.
		 (self p2Flag: i has: OilP2Delete) ifFalse:
			[n := (self p2Flag: i has: OilP2RotBack)
					ifTrue: [self p2EmitRotatedBackJump: i at: n]
					ifFalse: [self p2EmitInstructionAt: i at: n]].
		 i := i + len].
	self assert: n = (oilIRMap at: irIndex).
	0 to: numSites - 1 do:
		[:s|
		si := siteIR at: s.
		si >= 0 ifTrue:
			[siteIR at: s put: ((self p2Flag: si has: OilP2Delete + OilP2NoCheck)
									ifTrue: [-2]
									ifFalse: [oilIRMap at: si])]].
	oilIRBuffer := oilIRBuffer2.
	irIndex := n.
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

(Smalltalk hasClassNamed: #OilNumericCompiler) ifTrue: [(Smalltalk at: #OilNumericCompiler) removeFromSystem].!OilLoopCompiler subclass: #OilFullCompiler
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-Oil'!

!OilFullCompiler commentStamp: 'cb 10/24/2026 19:35' prior: 0!
I am the leaf class of the Oil optimizing compiler hierarchy (OilBytecodeScanner -> OilBaseCompiler -> OilLoopCompiler -> OilFullCompiler).!

!OilFullCompiler methodsFor: 'pass 2 optimization' stamp: 'cb 10/24/2026 19:35'!
pipe
	<inline: true>
	^super pipe! !

Smalltalk globals removeKey: #OilCompiler ifAbsent: [].
Smalltalk at: #OilCompiler put: OilFullCompiler!
