"Pass 3 of Oil (OilInliningCompiler), the native back end.  It translates the linear IR in oilIRBuffer
 into the Cogit's abstract instructions (CogAbstractInstruction), which the Cogit then assembles into a CogMethod.
 See ProfilingCogit>>oilGenerate: for the driver.  Author: cb."!

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
prepareNativeCode
	"Pass 3, step 1.  Analyse the IR: branch targets, loop nesting, the deopt site of each instruction.
	 Weigh every virtual register by its uses, ten times more per loop nesting level, give the heaviest ones
	 machine registers and every live virtual register a spill slot in the frame (where it is spilled around
	 calls and deopts; the GC scans it, so it always holds an object).  Answer OilOK or a failure code."
	| irOffset opcode branchTarget regsAllocated bestVReg bestWeight spillBase |
	oilFailIndex := -2.
	"Machine registers available to virtual registers.  TempReg, ClassReg and SendNumArgsReg are the back
	 end's scratch registers, VarBaseReg (if any), FPReg and SPReg are reserved."
	oilAllocRegs at: 0 put: Extra2Reg.
	oilAllocRegs at: 1 put: Extra3Reg.
	oilAllocRegs at: 2 put: Extra4Reg.
	oilAllocRegs at: 3 put: Extra5Reg.
	oilAllocRegs at: 4 put: Extra0Reg.
	oilAllocRegs at: 5 put: Extra1Reg.
	oilAllocRegs at: 6 put: Arg0Reg.
	oilAllocRegs at: 7 put: Arg1Reg.
	oilAllocRegs at: 8 put: ReceiverResultReg.
	oilNumAllocRegs := 9.
	"The XMM registers (DPFPReg0 to DPFPReg15 are consecutive): the first OilNumXmms for float chains (see
	 genFloatArith:at:site:), the others pinned to the float variables of a loop (see prepareFloatLoops)."
	0 to: OilNumXmms + OilMaxPinnedXmms - 1 do:
		[:xmmIndex| oilXmmRegs at: xmmIndex put: DPFPReg0 + xmmIndex].
	0 to: OilNumRegs - 1 do:
		[:vreg|
		oilVRegUses at: vreg put: 0.
		oilVRegReg at: vreg put: NoReg.
		oilVRegSpillTemp at: vreg put: 0].
	0 to: irIndex - 1 do:
		[:targetOffset|
		oilIRTarget at: targetOffset put: 0.
		oilLoopDepth at: targetOffset put: 0.
		oilIRLabel at: targetOffset put: nil].
	0 to: OilMaxSites - 1 do:
		[:siteIndex| oilSiteUsed at: siteIndex put: 0].
	oilNumFixups := oilNumStubJumps := oilNumUndos := 0.
	self computeIRSites.
	"Branch targets, loops (a backward branch closes a loop) and supported opcodes."
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (self isBranch: opcode) ifTrue:
			[branchTarget := self imm16At: irOffset.
			 branchTarget >= irIndex ifTrue:
				[self abortCompilation: OilFailInternal.
				 ^failureCode].
			 oilIRTarget at: branchTarget put: ((oilIRTarget at: branchTarget) max: 1).
			 branchTarget <= irOffset ifTrue: "a loop header: 2 (see generateNativeCode)"
				[oilIRTarget at: branchTarget put: 2.
				 branchTarget to: irOffset do: [:targetOffset| oilLoopDepth at: targetOffset put: ((oilLoopDepth at: targetOffset) + 1 min: 3)]]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[self weighInstructionAt: irOffset.
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	"The receiver and arguments are copied in from the frame; registers referenced by deopt states need spill slots."
	0 to: (self numArgsOf: oilHomeMethod) do:
		[:vreg| oilVRegUses at: vreg put: (oilVRegUses at: vreg) + 1].
	self markMetadataRegisters.
	self analyzeTaggedRegisters.
	"Allocate machine registers, heaviest first."
	regsAllocated := 0.
	[regsAllocated < oilNumAllocRegs] whileTrue:
		[bestVReg := -1. bestWeight := 0.
		 0 to: OilMaxReg do:
			[:vreg|
			((oilVRegReg at: vreg) = NoReg and: [(oilVRegUses at: vreg) > bestWeight]) ifTrue:
				[bestVReg := vreg. bestWeight := oilVRegUses at: vreg]].
		 bestVReg < 0
			ifTrue: [oilNumAllocRegs := regsAllocated]
			ifFalse:
				[oilVRegReg at: bestVReg put: (oilAllocRegs at: regsAllocated).
				 regsAllocated := regsAllocated + 1]].
	"Spill slots, below the frame's receiver and temps (the frame of an ordinary machine code method)."
	oilNumSpillTemps := 0.
	spillBase := FoxMFReceiver - ((self numTempsOf: oilHomeMethod) - (self numArgsOf: oilHomeMethod) * objectMemory wordSize).
	0 to: OilMaxReg do:
		[:vreg|
		(oilVRegUses at: vreg) > 0 ifTrue:
			[oilNumSpillTemps := oilNumSpillTemps + 1.
			 oilVRegSpillTemp at: vreg put: spillBase - (oilNumSpillTemps * objectMemory wordSize)]].
	"Marrying or divorcing the frame copies its temps, spill slots and pushed values into a context, which is large (see
	 ProfilingCogit>>oilGenerateCogMethod): they must fit.  Calls push the receiver and up to 15 arguments."
	(self numTempsOf: oilHomeMethod) + oilNumSpillTemps + 16 > (LargeContextSlots - ReceiverIndex - 1) ifTrue:
		[self abortCompilation: OilFailOutOfRegisters.
		 ^failureCode].
	self prepareFloatLoops.
	^OilOK! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
isBranch: opcode
	<inline: true>
	^self opcode: opcode has: OilOpBranch! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
isFloatOpcode: opcode
	"A float instruction: an arithmetic (see isFloatArith:) or OilCmpFloat."
	<inline: true>
	^opcode between: OilAddFloat and: OilCmpFloat! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
isFloatArith: opcode
	"OilAddFloat, OilSubFloat, OilMulFloat or OilDivFloat."
	<inline: true>
	^opcode between: OilAddFloat and: OilDivFloat! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
flag: irOffset has: mask
	"Is one of the bits of mask set in the flags of the instruction at irOffset (Pass 2's OilP2..., then fuseFloats' OilFloat...)?"
	<inline: true>
	^((oilIRFlag at: irOffset) bitAnd: mask) ~= 0! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
mark: irOffset with: mask
	<inline: true>
	oilIRFlag at: irOffset put: ((oilIRFlag at: irOffset) bitOr: mask)! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
siteHasState: siteIndex
	"Does deopt site siteIndex have a recorded state (to deoptimize to)?"
	<inline: true>
	^(siteSnapBase at: siteIndex) >= 0! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
keepsSiteAt: irOffset
	"Does the instruction at irOffset keep its deopt site, if any: Pass 2 neither deleted it nor proved that it cannot deoptimize?"
	<inline: true>
	^(self flag: irOffset has: OilP2Delete + OilP2NoCheck) not! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
computeIRSites
	0 to: irIndex - 1 do: [:targetOffset| oilIRSite at: targetOffset put: -1].
	0 to: numSites - 1 do:
		[:siteIndex| (siteIR at: siteIndex) >= 0 ifTrue: [oilIRSite at: (siteIR at: siteIndex) put: siteIndex]]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
siteStateSize: siteIndex
	<inline: true>
	^(siteSnapTop at: siteIndex) + 1 + (OilMaxReg - (siteSnapHigh at: siteIndex))! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
recordUse: virtualReg
	"Count a use of register virtualReg (weighted by oilUseWeight), or, when probing for reads of oilUseProbe, note it."
	<inline: true>
	oilUseProbe >= 0
		ifTrue: [virtualReg = oilUseProbe ifTrue: [oilUseProbeHit := true]]
		ifFalse:
			[virtualReg < OilFlagsReg ifTrue:
				[oilVRegUses at: virtualReg put: (oilVRegUses at: virtualReg) + oilUseWeight]]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
instruction: irOffset reads: vreg
	"Does the instruction at irOffset read register vreg?  (As Pass 2 emits it: an OilP2ToMove load reads its oilIRAux register.)"
	<inline: false>
	oilUseProbe := vreg.
	oilUseProbeHit := false.
	(self flag: irOffset has: OilP2ToMove)
		ifTrue: [self recordUse: (oilIRAux at: irOffset)]
		ifFalse: [self countUsesAt: irOffset].
	oilUseProbe := -1.
	^oilUseProbeHit! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
countUsesAt: irOffset
	"Count the registers the instruction at irOffset reads (see the OilOpReads* properties)."
	<inline: false>
	| opcode regB regC |
	opcode := self opcodeAt: irOffset.
	regB := self fieldBAt: irOffset.
	regC := self fieldCAt: irOffset.
	(self opcode: opcode has: OilOpReadsA) ifTrue:
		[self recordUse: (self fieldAAt: irOffset)].
	(self opcode: opcode has: OilOpReadsB) ifTrue:
		[self recordUse: regB].
	(self opcode: opcode has: OilOpReadsC) ifTrue:
		[self recordUse: regC].
	(self opcode: opcode has: OilOpPackedArgs) ifTrue:
		[1 to: regC do: [:argIndex| self recordUse: (self packedArg: argIndex - 1 at: irOffset)]].
	((self opcode: opcode has: OilOpReadsRange)
	 and: [opcode ~= OilNewArray or: [regB ~= OilFlagsReg]]) ifTrue:
		[0 to: regC - 1 do: [:slotIndex| self recordUse: regB + slotIndex]].
	opcode = OilMakeClosure ifTrue: "(and its receiver)"
		[self recordUse: ((oilIRBuffer at: irOffset + 3) bitAnd: 255)]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
weighInstructionAt: irOffset
	"Count the registers the instruction at irOffset defines or reads, weighted by loop depth."
	| loopDepth |
	loopDepth := oilLoopDepth at: irOffset.
	oilUseWeight := loopDepth = 0 ifTrue: [1] ifFalse: [loopDepth = 1 ifTrue: [10] ifFalse: [loopDepth = 2 ifTrue: [100] ifFalse: [1000]]].
	(self opcodeHasDest: (self opcodeAt: irOffset)) ifTrue:
		[self recordUse: (self fieldAAt: irOffset)].
	self countUsesAt: irOffset! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 09:30'!
packedArg: argIndex at: irOffset
	"The register of argument argIndex (0-based) of the OilCallN/OilCallSuper/OilCallDirectedSuper at irOffset: four per word
	 after the selector (and, for OilCallDirectedSuper, the method class)."
	| word |
	word := oilIRBuffer at: irOffset + ((self opcodeAt: irOffset) = OilCallDirectedSuper ifTrue: [5] ifFalse: [3]) + (argIndex // 4).
	^(word bitShift: (3 - (argIndex \\ 4)) * -8) bitAnd: 255! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
markMetadataRegisters
	"Every register a deopt state refers to (directly, or through the virtual objects it refers to) needs a spill slot."
	self metadataRegistersDo: [:vreg| oilVRegUses at: vreg put: ((oilVRegUses at: vreg) max: 1)] sites: true! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
metadataRegistersDo: aBlock sites: withSites
	"Evaluate aBlock with each register the deoptimization metadata refers to: (if withSites) in the states of the live deopt
	 sites, the receivers of the inlined frames and of the virtual objects, and the values the virtual objects captured.
	 (In Pass 3 a site is live if it has a state and an instruction: fuseFloats cleared Pass 2's flags.)"
	<inline: true>
	| snapBase |
	withSites ifTrue:
		[0 to: numSites - 1 do:
			[:siteIndex|
			(self isLiveSite: siteIndex) ifTrue:
				[snapBase := siteSnapBase at: siteIndex.
				 0 to: (self siteStateSize: siteIndex) - 1 do:
					[:slotIndex| (sitePoolKind at: snapBase + slotIndex) = OilDescReg ifTrue:
						[aBlock value: (sitePoolValue at: snapBase + slotIndex)]]]]].
	0 to: numFrames - 1 do:
		[:frameIndex| (self frameAt: frameIndex) selfKind = OilDescReg ifTrue:
			[aBlock value: (self frameAt: frameIndex) selfValue]].
	0 to: numVObjs - 1 do:
		[:vobjIndex|
		(self vobjAt: vobjIndex) rcvrKind = OilDescReg ifTrue:
			[aBlock value: (self vobjAt: vobjIndex) rcvrValue].
		0 to: (self vobjAt: vobjIndex) copiedCount - 1 do:
			[:slotIndex| (capturedKind at: (self vobjAt: vobjIndex) copiedBase + slotIndex) = OilDescReg ifTrue:
				[aBlock value: (capturedValue at: (self vobjAt: vobjIndex) copiedBase + slotIndex)]]]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
src: virtualReg scratch: scratchReg
	"Answer a machine register holding virtual register virtualReg: its own, or scratchReg loaded from its spill slot."
	| reg |
	reg := oilVRegReg at: virtualReg.
	reg ~= NoReg ifTrue: [^reg].
	(oilVRegSpillTemp at: virtualReg) = 0 ifTrue:
		[self abortCompilation: OilFailInternal.
		 ^scratchReg].
	cogit MoveMw: (oilVRegSpillTemp at: virtualReg) r: FPReg R: scratchReg.
	^scratchReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
dst: virtualReg scratch: scratchReg
	"Answer the machine register to compute virtual register virtualReg into (its own, or scratchReg, then see setDst:from:)."
	| reg |
	reg := oilVRegReg at: virtualReg.
	^reg ~= NoReg ifTrue: [reg] ifFalse: [scratchReg]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
setDst: virtualReg from: machineReg
	"Virtual register virtualReg has been computed into the machine register machineReg: move it to virtualReg's location."
	| own |
	self forgetXmmsOf: virtualReg.
	own := oilVRegReg at: virtualReg.
	own ~= NoReg
		ifTrue: [own ~= machineReg ifTrue: [cogit MoveR: machineReg R: own]]
		ifFalse:
			[(oilVRegSpillTemp at: virtualReg) = 0 ifTrue: [^self abortCompilation: OilFailInternal].
			 cogit MoveR: machineReg Mw: (oilVRegSpillTemp at: virtualReg) r: FPReg]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
spillAll
	"Store every register-allocated virtual register into its spill slot (before a call or a deopt)."
	0 to: OilMaxReg do:
		[:vreg| (oilVRegReg at: vreg) ~= NoReg ifTrue:
			[cogit MoveR: (oilVRegReg at: vreg) Mw: (oilVRegSpillTemp at: vreg) r: FPReg]]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:30'!
reloadAll
	"Reload every register-allocated virtual register from its spill slot (after a call: the GC may have moved objects)."
	0 to: OilMaxReg do:
		[:vreg| (oilVRegReg at: vreg) ~= NoReg ifTrue:
			[cogit MoveMw: (oilVRegSpillTemp at: vreg) r: FPReg R: (oilVRegReg at: vreg)]]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
deopt: jump site: siteIndex
	"jump branches to the deopt stub of deopt site siteIndex (stubs are emitted after the method body)."
	<var: #jump type: #'AbstractInstruction *'>
	(self useSite: siteIndex) ifFalse: [^self].
	oilNumStubJumps >= OilBufferWords ifTrue:
		[^self abortCompilation: OilFailBackend].
	oilStubJump at: oilNumStubJumps put: jump.
	oilStubSite at: oilNumStubJumps put: siteIndex.
	oilNumStubJumps := oilNumStubJumps + 1! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
useSite: siteIndex
	"A stub branches to deopt site siteIndex: note that the site needs a deopt stub.  Answer false (and abort) if it cannot
	 deoptimize (no state)."
	(siteIndex < 0 or: [siteIndex >= numSites or: [(self siteHasState: siteIndex) not]]) ifTrue:
		[self abortCompilation: OilFailUnsafeSite.
		 ^false].
	oilSiteUsed at: siteIndex put: 1.
	oilFloatLoopCurrent >= 0 ifTrue: "its stub boxes the loop's float variables first (see genDeoptStubs)"
		[oilSiteFloatLoop at: siteIndex put: oilFloatLoopCurrent + 1].
	^true! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:30'!
branch: jump to: target
	"jump branches to the instruction at target.  Out of a loop whose float variables are in XMM registers, to an exit
	 stub that boxes them first (see genFloatLoopExits)."
	<var: #jump type: #'AbstractInstruction *'>
	(oilFloatLoopCurrent >= 0
	 and: [target < (oilFloatLoopHead at: oilFloatLoopCurrent) or: [target > (oilFloatLoopEnd at: oilFloatLoopCurrent)]]) ifTrue:
		[oilNumFloatExits >= OilMaxFloatExits ifTrue:
			[^self abortCompilation: OilFailBackend].
		 oilFloatExitJump at: oilNumFloatExits put: jump.
		 oilFloatExitTarget at: oilNumFloatExits put: target.
		 oilNumFloatExits := oilNumFloatExits + 1.
		 ^self].
	oilNumFixups >= OilBufferWords ifTrue:
		[^self abortCompilation: OilFailBackend].
	oilFixupJump at: oilNumFixups put: jump.
	oilFixupTarget at: oilNumFixups put: target.
	oilNumFixups := oilNumFixups + 1! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:30'!
genTagCheck: reg site: siteIndex
	"Deoptimize unless reg holds a SmallInteger."
	cogit TstCq: objectMemory smallIntegerTag R: reg.
	self deopt: (cogit JumpZero: 0) site: siteIndex! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:30'!
genTagCheckOf: virtualReg in: machineReg site: siteIndex
	"Deoptimize unless virtual register virtualReg (in machine register machineReg) holds a SmallInteger, unless it always does."
	(self isTagged: virtualReg) ifFalse:
		[self genTagCheck: machineReg site: siteIndex]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:30'!
genTagCheckOf: virtualRegA in: machineRegA and: virtualRegB in: machineRegB site: siteIndex
	(self isTagged: virtualRegA) ifTrue: [^self genTagCheckOf: virtualRegB in: machineRegB site: siteIndex].
	((self isTagged: virtualRegB) or: [machineRegA = machineRegB]) ifTrue: [^self genTagCheck: machineRegA site: siteIndex].
	cogit MoveR: machineRegA R: SendNumArgsReg.
	cogit AndR: machineRegB R: SendNumArgsReg.
	self genTagCheck: SendNumArgsReg site: siteIndex! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
generateNativeCode
	"Pass 3, step 2.  Emit the method body: copy the receiver and arguments into their locations, initialize the
	 other allocated registers (they are spilled at calls and deopts, so they must always hold objects), then
	 translate each IR instruction, then the deopt stubs.  The caller has emitted the method's entry and its
	 frame build (including the spill slots and the stack check).  Answer OilOK or a failure code."
	| irOffset numArgs |
	numArgs := self numArgsOf: oilHomeMethod.
	"The spill slots follow the method's temps.  They are pushed here, after the stack check, and not in the
	 frame build: the CoInterpreter also builds machine code frames itself (with the method's temps only, see
	 activateNewCogMethod:inInterpreter:) and enters them at the stack check."
	1 to: oilNumSpillTemps do:
		[:spillIndex| cogit PushCq: (objectMemory integerObjectOf: 0)].
	0 to: numArgs do:
		[:vreg| | dst |
		dst := self dst: vreg scratch: TempReg.
		vreg = 0
			ifTrue: [cogit MoveMw: FoxMFReceiver r: FPReg R: dst]
			ifFalse: [cogit MoveMw: FoxCallerSavedIP + (numArgs - vreg + 1 * objectMemory wordSize) r: FPReg R: dst].
		self setDst: vreg from: dst].
	numArgs + 1 to: OilMaxReg do:
		[:vreg| (oilVRegReg at: vreg) ~= NoReg ifTrue:
			[cogit MoveCq: (objectMemory integerObjectOf: 0) R: (oilVRegReg at: vreg)]].
	self resetXmms.
	oilXmmChain := -1.
	oilFloatLoopCurrent := -1.
	oilNumFloatExits := 0.
	oilNumPolls := 0.
	oilPollPending := false.
	irOffset := 0.
	[irOffset < irIndex and: [failed not]] whileTrue:
		[self genFloatLoopEntryAt: irOffset.
		 (oilIRTarget at: irOffset) = 2 ifTrue: "a loop header"
			[self genLoopAlignment].
		 (oilIRTarget at: irOffset) ~= 0 ifTrue:
			[oilIRLabel at: irOffset put: cogit Label].
		 (oilIRTarget at: irOffset) = 2 ifTrue: "a loop header: check for interrupts in the loop (see genPollBefore:)"
			[oilPollPending := true].
		 oilPollPending ifTrue:
			[self genPollBefore: irOffset].
		 irOffset := self genInstructionAt: irOffset.
		 (oilFloatLoopCurrent >= 0 and: [irOffset > (oilFloatLoopEnd at: oilFloatLoopCurrent)]) ifTrue:
			[self genFloatLoopExits]].
	failed ifTrue: [^failureCode].
	oilFailIndex := -1.
	self genDeoptStubs.
	self genPollStubs.
	failed ifTrue: [^failureCode].
	0 to: oilNumFixups - 1 do:
		[:fixupIndex| | target |
		target := oilIRLabel at: (oilFixupTarget at: fixupIndex).
		target = nil ifTrue: [self abortCompilation: OilFailInternal. ^failureCode].
		(oilFixupJump at: fixupIndex) jmpTarget: target].
	^OilOK! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
genInstructionAt: irOffset
	"Translate the IR instruction at irOffset.  Answer the index of the next instruction to translate."
	<inline: false>
	| opcode regA regB regC siteIndex nextOffset chainSite |
	opcode := self opcodeAt: irOffset.
	regA := self fieldAAt: irOffset.
	regB := self fieldBAt: irOffset.
	regC := self fieldCAt: irOffset.
	nextOffset := irOffset + (self instructionLengthAt: irOffset).
	oilFailIndex := irOffset.
	siteIndex := (opcode = OilGuardClass or: [opcode = OilCheckBounds or: [opcode = OilGuardClass2]])
			ifTrue: [opcode = OilCheckBounds ifTrue: [regC] ifFalse: [self imm16At: irOffset]]
			ifFalse: [oilIRSite at: irOffset].
	siteIndex >= 0 ifTrue: "the deopt fast path (an unforwarded guard) resumes here"
		[oilSiteResume at: siteIndex put: cogit Label].
	"XMM registers cache the double values of registers in straight-line code (see xmmFor:ints:except:site:) and hold
	 the unboxed results of a float chain (OilFullCompiler>>fuseFloats), every deopt of which goes to the chain's site."
	((oilIRTarget at: irOffset) ~= 0 or: [self mayClobberXmms: opcode]) ifTrue: [self resetXmms].
	chainSite := (self flag: irOffset has: OilFloatChained) ifTrue: [oilIRAux at: irOffset] ifFalse: [-1].
	chainSite ~= oilXmmChain ifTrue: "a chain ends: its unboxed results are dead"
		[0 to: OilNumXmms - 1 do: [:xmmIndex| (oilXmmKind at: xmmIndex) < 0 ifTrue: [oilXmmVReg at: xmmIndex put: -1]].
		 oilXmmChain := chainSite].
	chainSite >= 0 ifTrue: [siteIndex := chainSite].
	opcode caseOf: {
		[OilConstTagged]	-> [self genConstTagged: regA value: (self signed16: (self imm16At: irOffset))].
		[OilConst64]		-> [self genConst64: regA value: (self word64At: irOffset + 1)].
		[OilMove]			-> [self genMove: regA from: regB].
		[OilAddTagged]		-> [self genAddTagged: regA b: regB c: regC site: siteIndex].
		[OilSubTagged]		-> [self genSubTagged: regA b: regB c: regC site: siteIndex].
		[OilAndTagged]		-> [self genLogicTagged: opcode a: regA b: regB c: regC site: siteIndex].
		[OilOrTagged]		-> [self genLogicTagged: opcode a: regA b: regB c: regC site: siteIndex].
		[OilXorTagged]		-> [self genLogicTagged: opcode a: regA b: regB c: regC site: siteIndex].
		[OilShiftTagged]	-> [self genShiftTagged: regA b: regB shift: (self signed8: regC) site: siteIndex].
		[OilOddTagged]		-> [self genOddTagged: regA b: regB site: siteIndex].
		[OilAddImmTagged]	-> [self genAddImmTagged: regA b: regB imm: (self signed8: regC) site: siteIndex].
		[OilAddImmTaggedNC]	-> [self genAddImmTaggedNoCheck: regA b: regB imm: (self signed8: regC)].
		[OilModTagged]		-> [self genModTagged: regA b: regB c: regC site: siteIndex].
		[OilNewArray]		-> [self genNewArray: regA first: regB size: regC site: siteIndex].
		[OilLoadByteSize]	-> [self genLoadSize: regA object: regB bytes: true].
		[OilLoadByte]		-> [self genLoadByte: regA array: regB index: regC tag: objectMemory smallIntegerTag].
		[OilLoadChar]		-> [self genLoadByte: regA array: regB index: regC tag: objectMemory characterTag].
		[OilStoreByte]		-> [self genStoreByte: regA array: regB index: regC character: false site: siteIndex].
		[OilStoreChar]		-> [self genStoreByte: regA array: regB index: regC character: true site: siteIndex].
		[OilCompareBytes]	-> [self genCompareBytes: regA with: regB with: regC site: siteIndex].
		[OilTrap]			-> [self deopt: (cogit Jump: 0) site: siteIndex].
		[OilStreamNext]		-> [self genStreamNextAt: irOffset].
		[OilStreamNextPut]	-> [self genStreamNextPutAt: irOffset].
		[OilCharValue]		-> [self genCharValue: regA of: regB].
		[OilIdentityHash]	-> [self genIdentityHashAt: irOffset].
		[OilIndexOfByte]	-> [self genIndexOfByteAt: irOffset].
		[OilSkipSeparators]	-> [self genSkipSeparatorsAt: irOffset].
		[OilMakeClosure]	-> [self genMakeClosureAt: irOffset site: siteIndex].
		[OilLoadField]		-> [self genLoadField: regA object: regB slot: regC].
		[OilStoreField]		-> [self genStoreField: regA object: regB slot: regC site: siteIndex].
		[OilLoadElement]	-> [self genLoadElement: regA array: regB index: regC].
		[OilStoreElement]	-> [self genStoreElement: regA array: regB index: regC site: siteIndex].
		[OilLoadSize]		-> [self genLoadSize: regA object: regB bytes: false].
		[OilCheckBounds]	-> [self genCheckBounds: regA limit: regB site: siteIndex].
		[OilGuardClass]		-> [self genGuard: regA class: (self word64At: irOffset + 1) site: siteIndex].
		[OilCmpTagged]		-> [^self genCompareAt: irOffset site: siteIndex].
		[OilCmpImmTagged]	-> [^self genCompareAt: irOffset site: siteIndex].
		[OilCmpFloat]		-> [^self genFloatCompareAt: irOffset site: siteIndex].
		[OilAddFloat]		-> [self genFloatArith: opcode at: irOffset site: siteIndex].
		[OilSubFloat]		-> [self genFloatArith: opcode at: irOffset site: siteIndex].
		[OilMulFloat]		-> [self genFloatArith: opcode at: irOffset site: siteIndex].
		[OilDivFloat]		-> [self genFloatArith: opcode at: irOffset site: siteIndex].
		[OilBranchTrue]		-> [self genBranchOnBoolean: regA ifTrue: true to: (self imm16At: irOffset) site: siteIndex].
		[OilBranchFalse]	-> [self genBranchOnBoolean: regA ifTrue: false to: (self imm16At: irOffset) site: siteIndex].
		[OilJump]			-> [(self imm16At: irOffset) ~= nextOffset ifTrue: "(not to the next instruction)"
									[self branch: (cogit Jump: 0) to: (self imm16At: irOffset)]].
		[OilReturn]			-> [self genReturn: regA].
		[OilCall0]			-> [self genCallAt: irOffset site: siteIndex].
		[OilCall1]			-> [self genCallAt: irOffset site: siteIndex].
		[OilCallN]			-> [self genCallAt: irOffset site: siteIndex].
		[OilCallSuper]		-> [self genCallAt: irOffset site: siteIndex].
		[OilCallDirectedSuper]	-> [self genCallAt: irOffset site: siteIndex].
		[OilNewObject]		-> [self genNewObjectAt: irOffset site: siteIndex].
		[OilCmpClass]		-> [^self genCmpClassAt: irOffset].
		[OilGuardClass2]	-> [self genGuard2At: irOffset site: siteIndex].
		[OilStringHash]		-> [self genStringHashAt: irOffset] }
		otherwise: [self abortCompilation: OilFailBackend].
	^nextOffset! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genConstTagged: destReg value: tagged
	| dst |
	dst := self dst: destReg scratch: TempReg.
	cogit MoveCq: tagged R: dst.
	self setDst: destReg from: dst! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genConst64: destReg value: oop
	"An object literal: annotated so that the GC can update it (and the method is a young referrer if need be).  A Float
	 literal is also loaded as a double into an XMM register caching it (see xmmFor:ints:except:site:), so that the float
	 instructions using it do not unbox it."
	| dst |
	dst := self dst: destReg scratch: TempReg.
	cogit genMoveConstant: oop R: dst.
	self setDst: destReg from: dst.
	(self isFloatHandle: oop) ifTrue:
		[self cacheFloatLiteral: oop in: destReg]! !

!OilInliningCompiler methodsFor: 'float code generation' stamp: 'cb 10/25/2026 22:30'!
cacheFloatLiteral: oop in: destReg
	"Register destReg was just assigned the Float literal oop: load its double into an XMM register caching destReg."
	| xmmIndex |
	xmmIndex := self allocXmmExcept: -1 and: -1.
	cogit MoveCw: (self cCode: [coInterpreter oilApiFloatBitsOf: oop] inSmalltalk: [0]) R: TempReg.
	cogit MoveR: TempReg Rd: (oilXmmRegs at: xmmIndex).
	oilXmmVReg at: xmmIndex put: destReg.
	oilXmmKind at: xmmIndex put: 0! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genMove: destReg from: srcReg
	| src |
	(oilFloatLoopCurrent >= 0 and: [(oilXmmPinned at: destReg) >= 0]) ifTrue: "between float variables of the loop"
		[(oilXmmPinned at: srcReg) < 0 ifTrue: [^self abortCompilation: OilFailInternal].
		 cogit MoveRd: (oilXmmRegs at: (oilXmmPinned at: srcReg)) Rd: (oilXmmRegs at: (oilXmmPinned at: destReg)).
		 ^self].
	src := self src: srcReg scratch: TempReg.
	self setDst: destReg from: src! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genAddTagged: destReg b: leftReg c: rightReg site: siteIndex
	"(8x+1) - 1 + (8y+1) = 8(x+y)+1; the 64-bit add overflows exactly when x+y is not a SmallInteger.
	 Computed in a scratch register: on deopt the operands (and destReg) are intact.  But an accumulation, a := a + c
	 (or a := c + a) with a in a machine register, is computed in place, adding c - 1 (computed aside, so that the
	 loop carried dependency is one add): on overflow an undo stub subtracts it again (from the wrapped 64-bit sum)
	 before deoptimizing."
	| leftMach rightMach destMach otherReg otherMach |
	destMach := oilVRegReg at: destReg.
	(destMach ~= NoReg and: [oilNumUndos < OilMaxUndos and: [leftReg ~= rightReg and: [leftReg = destReg or: [rightReg = destReg]]]]) ifTrue:
		[otherReg := leftReg = destReg ifTrue: [rightReg] ifFalse: [leftReg].
		 otherMach := self src: otherReg scratch: ClassReg.
		 self genTagCheckOf: destReg in: destMach and: otherReg in: otherMach site: siteIndex.
		 cogit LoadEffectiveAddressMw: -1 r: otherMach R: SendNumArgsReg.
		 cogit AddR: SendNumArgsReg R: destMach.
		 ^self undoDeopt: (cogit JumpOverflow: 0) site: siteIndex reg: destMach src: SendNumArgsReg].
	leftMach := self src: leftReg scratch: TempReg.
	rightMach := self src: rightReg scratch: ClassReg.
	self genTagCheckOf: leftReg in: leftMach and: rightReg in: rightMach site: siteIndex.
	cogit MoveR: leftMach R: SendNumArgsReg.
	cogit SubCq: 1 R: SendNumArgsReg.
	cogit AddR: rightMach R: SendNumArgsReg.
	self deopt: (cogit JumpOverflow: 0) site: siteIndex.
	self setDst: destReg from: SendNumArgsReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
undoDeopt: jump site: siteIndex reg: destMachReg src: srcMachReg
	"jump (an overflow of reg := reg + src) branches to an undo stub, which restores reg (reg - src) and branches to the
	 deopt stub of deopt site siteIndex.  The stubs are emitted after the method body."
	<var: #jump type: #'AbstractInstruction *'>
	(self useSite: siteIndex) ifFalse: [^self].
	oilUndoJump at: oilNumUndos put: jump.
	oilUndoSite at: oilNumUndos put: siteIndex.
	oilUndoReg at: oilNumUndos put: destMachReg.
	oilUndoSrc at: oilNumUndos put: srcMachReg.
	oilNumUndos := oilNumUndos + 1! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genSubTagged: destReg b: leftReg c: rightReg site: siteIndex
	"(8x+1) - (8y+1) = 8(x-y), overflowing exactly when x-y is not a SmallInteger; then restore the tag."
	| leftMach rightMach |
	leftMach := self src: leftReg scratch: TempReg.
	rightMach := self src: rightReg scratch: ClassReg.
	self genTagCheckOf: leftReg in: leftMach and: rightReg in: rightMach site: siteIndex.
	cogit MoveR: leftMach R: SendNumArgsReg.
	cogit SubR: rightMach R: SendNumArgsReg.
	self deopt: (cogit JumpOverflow: 0) site: siteIndex.
	cogit AddCq: 1 R: SendNumArgsReg.
	self setDst: destReg from: SendNumArgsReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genModTagged: destReg b: leftReg c: rightReg site: siteIndex
	"x \\ y, the floored modulo (the result has the sign of y).  Deoptimize unless both are SmallIntegers and y is not 0.
	 If both are in [0, 2^31) (hash probes: a hash modulo a size), divide their double values (a 64-bit idiv takes 40 to 90
	 cycles, a double division about 14): the quotient q of x / y rounded to an integer is exact or one too many (the
	 error of the division is below 1/y as x < 2^53), so x - (q * y), plus y if negative, is the remainder.  Otherwise
	 untag both, divide (the back end's genDivR:R:Quo:Rem:, which saves and restores the registers the division needs), and
	 add y to a non-zero remainder whose sign differs from y's.  The result cannot overflow."
	| leftMach rightMach jumpZero jumpSameSign jumpLarge jumpPositive jumpDone |
	<var: #jumpZero type: #'AbstractInstruction *'>
	<var: #jumpSameSign type: #'AbstractInstruction *'>
	<var: #jumpLarge type: #'AbstractInstruction *'>
	<var: #jumpPositive type: #'AbstractInstruction *'>
	<var: #jumpDone type: #'AbstractInstruction *'>
	leftMach := self src: leftReg scratch: TempReg.
	rightMach := self src: rightReg scratch: ClassReg.
	self genTagCheckOf: leftReg in: leftMach and: rightReg in: rightMach site: siteIndex.
	cogit CmpCq: (objectMemory integerObjectOf: 0) R: rightMach.
	self deopt: (cogit JumpZero: 0) site: siteIndex.
	cogit MoveR: rightMach R: SendNumArgsReg.
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: SendNumArgsReg.
	cogit MoveR: leftMach R: ClassReg.
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: ClassReg.
	"both in [0, 2^31)?"
	cogit MoveR: ClassReg R: TempReg.
	cogit OrR: SendNumArgsReg R: TempReg.
	cogit LogicalShiftRightCq: 31 R: TempReg.
	jumpLarge := cogit JumpNonZero: 0.
	cogit ConvertR: ClassReg Rd: DPFPReg0.
	cogit ConvertR: SendNumArgsReg Rd: DPFPReg1.
	cogit DivRd: DPFPReg1 Rd: DPFPReg0.
	cogit ConvertRd: DPFPReg0 R: TempReg.
	cogit backEnd genMulR: SendNumArgsReg R: TempReg.
	cogit SubR: TempReg R: ClassReg.
	cogit CmpCq: 0 R: ClassReg.
	jumpPositive := cogit JumpGreaterOrEqual: 0.
	cogit AddR: SendNumArgsReg R: ClassReg.
	jumpPositive jmpTarget: cogit Label.
	jumpDone := cogit Jump: 0.
	jumpLarge jmpTarget: cogit Label.
	cogit backEnd genDivR: SendNumArgsReg R: ClassReg Quo: TempReg Rem: ClassReg.
	cogit CmpCq: 0 R: ClassReg.
	jumpZero := cogit JumpZero: 0.
	cogit MoveR: ClassReg R: TempReg.
	cogit XorR: SendNumArgsReg R: TempReg.
	jumpSameSign := cogit JumpGreaterOrEqual: 0.
	cogit AddR: SendNumArgsReg R: ClassReg.
	jumpDone jmpTarget: (jumpZero jmpTarget: (jumpSameSign jmpTarget: cogit Label)).
	cogit LogicalShiftLeftCq: objectMemory numTagBits R: ClassReg.
	cogit OrCq: objectMemory smallIntegerTag R: ClassReg.
	self setDst: destReg from: ClassReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 21:45'!
genAllocate: numBytes header: header site: siteIndex
	"Bump allocate numBytes in eden into ClassReg (TempReg is clobbered) and store its header.  If the new freeStart
	 would reach the scavenge threshold, deoptimize at the allocation's deopt site instead (an OilSiteAlloc, which does
	 not count as a deoptimization): the interpreter then allocates and the scavenge runs.  (Oil code checks for interrupts
	 only in its loops, so it must not allocate beyond the threshold like the baseline JIT does.)"
	cogit MoveAw: objectMemory freeStartAddress R: ClassReg.
	cogit LoadEffectiveAddressMw: numBytes r: ClassReg R: TempReg.
	cogit CmpCq: objectMemory getScavengeThreshold R: TempReg.
	self deopt: (cogit JumpAboveOrEqual: 0) site: siteIndex.
	cogit MoveR: TempReg Aw: objectMemory freeStartAddress.
	cogit oilGenStoreHeader: header into: ClassReg scratch: TempReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
genNewArray: destReg first: firstReg size: numSlots site: siteIndex
	"A brace array of the numSlots values in registers firstReg..firstReg+numSlots-1, or (firstReg = OilFlagsReg) an Array of numSlots nils (a temp vector in
	 eager mode).  Young, so its stores need no store check."
	numSlots >= objectMemory numSlotsMask ifTrue:
		[^self abortCompilation: OilFailBackend].
	self genAllocate: (objectMemory smallObjectBytesForSlots: numSlots)
		header: (objectMemory headerForSlots: numSlots format: objectMemory arrayFormat classIndex: ClassArrayCompactIndex)
		site: siteIndex.
	firstReg = OilFlagsReg ifTrue:
		[numSlots > 0 ifTrue:
			[cogit genMoveConstant: objectMemory nilObject R: TempReg.
			 0 to: numSlots - 1 do:
				[:slotIndex| cogit MoveR: TempReg Mw: slotIndex * objectMemory wordSize + objectMemory baseHeaderSize r: ClassReg]]]
		ifFalse: [self genStoreSlots: numSlots from: firstReg at: 0].
	self setDst: destReg from: ClassReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
genStoreSlots: numSlots from: firstReg at: firstSlot
	"Store the registers firstReg to firstReg + numSlots - 1 into the slots from firstSlot of the new object in ClassReg
	 (TempReg is the scratch)."
	| reg |
	0 to: numSlots - 1 do:
		[:index|
		reg := self src: firstReg + index scratch: TempReg.
		cogit MoveR: reg Mw: firstSlot + index * objectMemory wordSize + objectMemory baseHeaderSize r: ClassReg]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
genMakeClosureAt: irOffset site: siteIndex
	"An escaping FullBlockClosure (eager mode): [OilMakeClosure|Dest|FirstCopied|NumCopied] block (64 bits)
	 [frame:16|ignoreOuterContext:8|selfReg:8].  Its outerContext is the root frame's context (the frame is married
	 through the baseline JIT's active context trampoline, all registers spilled around the call), or nil for a block
	 that ignores it.  The context of an inlined frame does not exist: such closures are not supported."
	| destReg baseReg numCopied blockMethod word selfReg ignoreContext frameIndex valueReg slotOffset |
	destReg := self fieldAAt: irOffset.
	baseReg := self fieldBAt: irOffset.
	numCopied := self fieldCAt: irOffset.
	blockMethod := self word64At: irOffset + 1.
	word := oilIRBuffer at: irOffset + 3.
	selfReg := word bitAnd: 255.
	ignoreContext := (word bitAnd: 256) ~= 0.
	frameIndex := word bitShift: -16.
	(ignoreContext not and: [frameIndex ~= 0]) ifTrue:
		[^self abortCompilation: OilFailBackend].
	FullClosureFirstCopiedValueIndex + numCopied >= objectMemory numSlotsMask ifTrue:
		[^self abortCompilation: OilFailBackend].
	ignoreContext
		ifTrue: [cogit genMoveConstant: objectMemory nilObject R: SendNumArgsReg]
		ifFalse:
			[self spillAll.
			 cogit oilGenGetActiveContextInto: SendNumArgsReg.
			 self reloadAll].
	self genAllocate: (objectMemory smallObjectBytesForSlots: FullClosureFirstCopiedValueIndex + numCopied)
		header: (objectMemory
					headerForSlots: FullClosureFirstCopiedValueIndex + numCopied
					format: objectMemory indexablePointersFormat
					classIndex: ClassFullBlockClosureCompactIndex)
		site: siteIndex.
	slotOffset := objectMemory baseHeaderSize.
	cogit MoveR: SendNumArgsReg Mw: ClosureOuterContextIndex * objectMemory wordSize + slotOffset r: ClassReg.
	cogit genMoveConstant: blockMethod R: TempReg.
	cogit MoveR: TempReg Mw: FullClosureCompiledBlockIndex * objectMemory wordSize + slotOffset r: ClassReg.
	cogit MoveCq: (objectMemory integerObjectOf: (self numArgsOf: blockMethod)) R: TempReg.
	cogit MoveR: TempReg Mw: ClosureNumArgsIndex * objectMemory wordSize + slotOffset r: ClassReg.
	valueReg := self src: selfReg scratch: TempReg.
	cogit MoveR: valueReg Mw: FullClosureReceiverIndex * objectMemory wordSize + slotOffset r: ClassReg.
	self genStoreSlots: numCopied from: baseReg at: FullClosureFirstCopiedValueIndex.
	self setDst: destReg from: ClassReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:30'!
spillMachineReg: reg
	"Store the virtual register allocated to reg, if any, into its spill slot (reg is about to be used as a scratch)."
	0 to: OilMaxReg do:
		[:vreg| (oilVRegReg at: vreg) = reg ifTrue:
			[cogit MoveR: reg Mw: (oilVRegSpillTemp at: vreg) r: FPReg]]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:30'!
reloadMachineReg: reg
	0 to: OilMaxReg do:
		[:vreg| (oilVRegReg at: vreg) = reg ifTrue:
			[cogit MoveMw: (oilVRegSpillTemp at: vreg) r: FPReg R: reg]]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
spillExtraRegs
	"Spill the virtual registers allocated to Extra0Reg and Extra1Reg (the scratch registers of the stream and string intrinsics)."
	self spillMachineReg: Extra0Reg.
	self spillMachineReg: Extra1Reg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
reloadExtraRegs
	self reloadMachineReg: Extra0Reg.
	self reloadMachineReg: Extra1Reg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
genStreamChecks: limitIndex jumps: jumps count: numJumps
	"Of the stream in Extra0Reg, load the position (field 1) into ClassReg, the limit (field limitIndex) into SendNumArgsReg and the
	 collection (field 0) into Extra1Reg, adding to jumps the jumps taken unless the position and the limit are SmallIntegers,
	 position < limit and the collection is not an immediate.  Answer the number of jumps."
	| count |
	<var: #jumps type: #'AbstractInstruction **'>
	count := numJumps.
	cogit MoveMw: 1 * objectMemory wordSize + objectMemory baseHeaderSize r: Extra0Reg R: ClassReg.
	cogit MoveMw: limitIndex * objectMemory wordSize + objectMemory baseHeaderSize r: Extra0Reg R: SendNumArgsReg.
	cogit TstCq: objectMemory smallIntegerTag R: ClassReg.
	jumps at: count put: (cogit JumpZero: 0). count := count + 1.
	cogit TstCq: objectMemory smallIntegerTag R: SendNumArgsReg.
	jumps at: count put: (cogit JumpZero: 0). count := count + 1.
	cogit CmpR: SendNumArgsReg R: ClassReg.
	jumps at: count put: (cogit JumpGreaterOrEqual: 0). count := count + 1.
	cogit MoveMw: objectMemory baseHeaderSize r: Extra0Reg R: Extra1Reg.
	cogit TstCq: objectMemory tagMask R: Extra1Reg.
	jumps at: count put: (cogit JumpNonZero: 0).
	^count + 1! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
genSlowSendAt: i numArgs: numArgs jumps: jumps count: numJumps reloadAll: allRegs
	"The end of an intrinsic whose fast path has stored its result: jump over its slow path, which the jumps branch to: reload
	 the virtual registers (all of them, else those of Extra0Reg and Extra1Reg) and send the message."
	| jumpDone slowPath |
	<var: #jumps type: #'AbstractInstruction **'>
	<var: #jumpDone type: #'AbstractInstruction *'>
	<var: #slowPath type: #'AbstractInstruction *'>
	jumpDone := cogit Jump: 0.
	slowPath := cogit Label.
	0 to: numJumps - 1 do: [:jumpIndex| (jumps at: jumpIndex) jmpTarget: slowPath].
	allRegs ifTrue: [self reloadAll] ifFalse: [self reloadExtraRegs].
	self genSendAt: i numArgs: numArgs super: false.
	jumpDone jmpTarget: cogit Label! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
genStreamNextAt: i
	"a := b next (ReadStream>>next, primitive 65): collection (field 0) a ByteString (answer a Character) or an Array,
	 position (1) < readLimit (2) and the next index within the collection: answer the element and increment the
	 position.  Otherwise send next.  Scratch: Extra0Reg (the stream) and Extra1Reg (the collection), whose virtual
	 registers are spilled around, TempReg, ClassReg (the position) and SendNumArgsReg."
	| destReg streamReg streamRegMach jumps numJumps jumpPtr jumpDone |
	<var: #jumps declareC: 'AbstractInstruction *jumps[12]'>
	<var: #jumpPtr type: #'AbstractInstruction *'>
	<var: #jumpDone type: #'AbstractInstruction *'>
	destReg := self fieldAAt: i.
	streamReg := self fieldBAt: i.
	streamRegMach := self src: streamReg scratch: TempReg.
	self spillExtraRegs.
	streamRegMach ~= Extra0Reg ifTrue: [cogit MoveR: streamRegMach R: Extra0Reg].
	numJumps := self genStreamChecks: 2 jumps: jumps count: 0.
	cogit MoveM16: 0 r: Extra1Reg R: TempReg.
	cogit CmpCq: ClassByteStringCompactIndex R: TempReg.
	jumpPtr := cogit JumpNonZero: 0.
	"ByteString: index = position + 1 <= numBytes; byte at collection + 8 + index - 1, as a Character"
	cogit oilGenGetNumBytesOf: Extra1Reg into: SendNumArgsReg.
	cogit MoveR: ClassReg R: TempReg.
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: TempReg.
	cogit AddCq: 1 R: TempReg.
	cogit CmpR: SendNumArgsReg R: TempReg.
	jumps at: numJumps put: (cogit JumpGreater: 0). numJumps := numJumps + 1.
	cogit AddCq: objectMemory baseHeaderSize - 1 R: TempReg.
	cogit MoveCq: 0 R: SendNumArgsReg.
	cogit MoveXbr: TempReg R: Extra1Reg R: SendNumArgsReg.
	cogit LogicalShiftLeftCq: objectMemory numTagBits R: SendNumArgsReg.
	cogit OrCq: objectMemory characterTag R: SendNumArgsReg.
	jumpDone := cogit Jump: 0.
	"Array: index = position + 1 <= numSlots; slot index"
	jumpPtr jmpTarget: (cogit CmpCq: ClassArrayCompactIndex R: TempReg).
	jumps at: numJumps put: (cogit JumpNonZero: 0). numJumps := numJumps + 1.
	cogit oilGenGetNumSlotsOf: Extra1Reg into: SendNumArgsReg.
	cogit MoveR: ClassReg R: TempReg.
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: TempReg.
	cogit AddCq: 1 R: TempReg.
	cogit CmpR: SendNumArgsReg R: TempReg.
	jumps at: numJumps put: (cogit JumpGreater: 0). numJumps := numJumps + 1.
	cogit MoveXwr: TempReg R: Extra1Reg R: SendNumArgsReg.
	jumpDone jmpTarget: (cogit AddCq: 1 << objectMemory numTagBits R: ClassReg).
	cogit MoveR: ClassReg Mw: 1 * objectMemory wordSize + objectMemory baseHeaderSize r: Extra0Reg.
	self reloadExtraRegs.
	self setDst: destReg from: SendNumArgsReg.
	self genSlowSendAt: i numArgs: 0 jumps: jumps count: numJumps reloadAll: false! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
genStreamNextPutAt: i
	"a := b nextPut: c (WriteStream>>nextPut:, primitive 66): collection (field 0) a mutable ByteString, c a Character of
	 code 0..255, position (1) < writeLimit (3) and position + 1 within the collection: store the byte, increment the
	 position and answer c.  Otherwise send nextPut:.  Scratch registers as in genStreamNextAt:."
	| destReg streamReg valReg streamRegMach valRegMach jumps numJumps |
	<var: #jumps declareC: 'AbstractInstruction *jumps[12]'>
	destReg := self fieldAAt: i.
	streamReg := self fieldBAt: i.
	valReg := self fieldCAt: i.
	numJumps := 0.
	self spillExtraRegs.
	valRegMach := self src: valReg scratch: ClassReg.
	valRegMach ~= ClassReg ifTrue: [cogit MoveR: valRegMach R: ClassReg]. "the value, then the position"
	"a Character (tag 2r010) of code 0..255"
	cogit TstCq: objectMemory tagMask - objectMemory characterTag R: ClassReg.
	jumps at: numJumps put: (cogit JumpNonZero: 0). numJumps := numJumps + 1.
	cogit TstCq: objectMemory characterTag R: ClassReg.
	jumps at: numJumps put: (cogit JumpZero: 0). numJumps := numJumps + 1.
	cogit CmpCq: (255 << objectMemory numTagBits) + objectMemory characterTag R: ClassReg.
	jumps at: numJumps put: (cogit JumpAbove: 0). numJumps := numJumps + 1.
	streamRegMach := self src: streamReg scratch: TempReg.
	streamRegMach ~= Extra0Reg ifTrue: [cogit MoveR: streamRegMach R: Extra0Reg].
	cogit MoveR: ClassReg R: TempReg.
	cogit LogicalShiftRightCq: objectMemory numTagBits R: TempReg.
	numJumps := self genStreamChecks: 3 jumps: jumps count: numJumps.
	cogit MoveM32: 0 r: Extra1Reg R: SendNumArgsReg.
	cogit TstCq: objectMemory immutableBitMask R: SendNumArgsReg.
	jumps at: numJumps put: (cogit JumpNonZero: 0). numJumps := numJumps + 1.
	cogit AndCq: objectMemory classIndexMask R: SendNumArgsReg.
	cogit CmpCq: ClassByteStringCompactIndex R: SendNumArgsReg.
	jumps at: numJumps put: (cogit JumpNonZero: 0). numJumps := numJumps + 1.
	"index = position + 1 <= numBytes (genGetNumBytesOf: uses TempReg: save the byte in the stack)"
	cogit PushR: TempReg.
	cogit oilGenGetNumBytesOf: Extra1Reg into: SendNumArgsReg.
	cogit PopR: TempReg.
	cogit AddCq: 1 << objectMemory numTagBits R: ClassReg. "the new position, tagged"
	cogit PushR: ClassReg.
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: ClassReg.
	cogit CmpR: SendNumArgsReg R: ClassReg.
	cogit PopR: SendNumArgsReg. "the new position, tagged"
	jumps at: numJumps put: (cogit JumpGreater: 0). numJumps := numJumps + 1.
	cogit AddCq: objectMemory baseHeaderSize - 1 R: ClassReg.
	cogit MoveR: TempReg Xbr: ClassReg R: Extra1Reg.
	cogit MoveR: SendNumArgsReg Mw: 1 * objectMemory wordSize + objectMemory baseHeaderSize r: Extra0Reg.
	self reloadExtraRegs.
	valRegMach := self src: valReg scratch: ClassReg.
	self setDst: destReg from: valRegMach.
	self genSlowSendAt: i numArgs: 1 jumps: jumps count: numJumps reloadAll: false! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 03:00'!
genIdentityHashAt: i
	"a := b identityHash (primitive 75), b not immediate: the 22-bit identity hash in b's header, as a SmallInteger (three
	 instructions).  If b has no hash yet (0), send identityHash, whose primitive assigns it.  The hash is computed aside:
	 the send needs b's register intact."
	| jumpNoHash jumpDone |
	<var: #jumpNoHash type: #'AbstractInstruction *'>
	<var: #jumpDone type: #'AbstractInstruction *'>
	cogit oilGenGetHashOf: (self src: (self fieldBAt: i) scratch: TempReg) into: SendNumArgsReg.
	cogit CmpCq: (objectMemory integerObjectOf: 0) R: SendNumArgsReg.
	jumpNoHash := cogit JumpZero: 0.
	self setDst: (self fieldAAt: i) from: SendNumArgsReg.
	jumpDone := cogit Jump: 0.
	jumpNoHash jmpTarget: cogit Label.
	self genSendAt: i numArgs: 0 super: false.
	jumpDone jmpTarget: cogit Label! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 03:00'!
genIndexOfByteAt: i
	"a := b indexOfAscii: c inString: d startingAt: e (ByteString class>>indexOfAscii:inString:startingAt:, b ignored): if c is a
	 SmallInteger 0..255, d a byte object and e a SmallInteger >= 1, answer the index of the first byte of d equal to c at e
	 or after, else 0, scanning 8 bytes per iteration: a word w of d contains c iff w' := w bitXor: c * 16r0101010101010101
	 has a zero byte, i.e. iff (w' - 16r0101010101010101) bitAnd: (w' bitInvert bitAnd: 16r8080808080808080) is not 0
	 (exact for the word; the first such byte is then found bytewise, as are the bytes of the last partial word).
	 Otherwise send the message.
	 Registers: Extra2Reg d, Extra3Reg c, SendNumArgsReg the address of the current byte, Extra0Reg the end address,
	 Extra1Reg c in every byte, TempReg and ClassReg scratch."
	| jumps numJumps wordLoop byteLoop jumpTail jumpHit jumpEnd jumpFound jumpDone found shift |
	<var: #jumps declareC: 'AbstractInstruction *jumps[10]'>
	<var: #wordLoop type: #'AbstractInstruction *'>
	<var: #byteLoop type: #'AbstractInstruction *'>
	<var: #jumpTail type: #'AbstractInstruction *'>
	<var: #jumpHit type: #'AbstractInstruction *'>
	<var: #jumpEnd type: #'AbstractInstruction *'>
	<var: #jumpFound type: #'AbstractInstruction *'>
	<var: #jumpDone type: #'AbstractInstruction *'>
	<var: #found type: #'AbstractInstruction *'>
	numJumps := 0.
	"The scan uses most machine registers: store the virtual registers in their spill slots and load the operands from there
	 (genByteScanEpilogueAt:jumps:count:numArgs: reloads them, also before the slow path's send)."
	self spillAll.
	cogit MoveMw: (oilVRegSpillTemp at: (self callArg: 0 at: i)) r: FPReg R: Extra3Reg.
	cogit MoveMw: (oilVRegSpillTemp at: (self callArg: 1 at: i)) r: FPReg R: Extra2Reg.
	cogit MoveMw: (oilVRegSpillTemp at: (self callArg: 2 at: i)) r: FPReg R: SendNumArgsReg.
	cogit TstCq: objectMemory smallIntegerTag R: Extra3Reg.
	jumps at: numJumps put: (cogit JumpZero: 0). numJumps := numJumps + 1.
	cogit TstCq: objectMemory smallIntegerTag R: SendNumArgsReg.
	jumps at: numJumps put: (cogit JumpZero: 0). numJumps := numJumps + 1.
	cogit TstCq: objectMemory tagMask R: Extra2Reg.
	jumps at: numJumps put: (cogit JumpNonZero: 0). numJumps := numJumps + 1.
	cogit MoveMw: 0 r: Extra2Reg R: TempReg.
	cogit LogicalShiftRightCq: objectMemory formatShift R: TempReg.
	cogit AndCq: objectMemory formatMask R: TempReg.
	cogit CmpCq: objectMemory firstByteFormat R: TempReg.
	jumps at: numJumps put: (cogit JumpLess: 0). numJumps := numJumps + 1.
	cogit CmpCq: objectMemory firstCompiledMethodFormat R: TempReg.
	jumps at: numJumps put: (cogit JumpGreaterOrEqual: 0). numJumps := numJumps + 1.
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: Extra3Reg.
	cogit CmpCq: 255 R: Extra3Reg.
	jumps at: numJumps put: (cogit JumpAbove: 0). numJumps := numJumps + 1.
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: SendNumArgsReg.
	cogit CmpCq: 1 R: SendNumArgsReg.
	jumps at: numJumps put: (cogit JumpLess: 0). numJumps := numJumps + 1.
	cogit oilGenGetNumBytesOf: Extra2Reg into: Extra0Reg.
	cogit AddR: Extra2Reg R: SendNumArgsReg.
	cogit AddCq: objectMemory baseHeaderSize - 1 R: SendNumArgsReg.
	cogit AddR: Extra2Reg R: Extra0Reg.
	cogit AddCq: objectMemory baseHeaderSize R: Extra0Reg.
	cogit MoveR: Extra3Reg R: Extra1Reg.
	shift := 8.
	[shift <= 32] whileTrue:
		[cogit MoveR: Extra1Reg R: ClassReg.
		 cogit LogicalShiftLeftCq: shift R: ClassReg.
		 cogit OrR: ClassReg R: Extra1Reg.
		 shift := shift * 2].
	"8 bytes at a time while 8 remain"
	wordLoop := cogit LoadEffectiveAddressMw: 8 r: SendNumArgsReg R: ClassReg.
	cogit CmpR: Extra0Reg R: ClassReg.
	jumpTail := cogit JumpAbove: 0.
	cogit MoveMw: 0 r: SendNumArgsReg R: TempReg.
	cogit XorR: Extra1Reg R: TempReg.
	cogit MoveR: TempReg R: ClassReg.
	cogit SubCq: 16r0101010101010101 R: ClassReg.
	cogit XorCq: -1 R: TempReg.
	cogit AndR: TempReg R: ClassReg.
	cogit TstCq: 16r8080808080808080 R: ClassReg.
	jumpHit := cogit JumpNonZero: 0.
	cogit AddCq: 8 R: SendNumArgsReg.
	cogit Jump: wordLoop.
	"then bytewise"
	byteLoop := cogit CmpR: Extra0Reg R: SendNumArgsReg.
	jumpTail jmpTarget: byteLoop.
	jumpHit jmpTarget: byteLoop.
	jumpEnd := cogit JumpAboveOrEqual: 0.
	cogit MoveCq: 0 R: TempReg.
	cogit MoveMb: 0 r: SendNumArgsReg R: TempReg.
	cogit CmpR: Extra3Reg R: TempReg.
	jumpFound := cogit JumpZero: 0.
	cogit AddCq: 1 R: SendNumArgsReg.
	cogit Jump: byteLoop.
	found := cogit SubR: Extra2Reg R: SendNumArgsReg.
	jumpFound jmpTarget: found.
	cogit SubCq: objectMemory baseHeaderSize - 1 R: SendNumArgsReg.
	cogit LogicalShiftLeftCq: objectMemory numTagBits R: SendNumArgsReg.
	cogit OrCq: objectMemory smallIntegerTag R: SendNumArgsReg.
	jumpDone := cogit Jump: 0.
	jumpEnd jmpTarget: (cogit MoveCq: (objectMemory integerObjectOf: 0) R: SendNumArgsReg).
	jumpDone jmpTarget: cogit Label.
	self genByteScanEpilogueAt: i jumps: jumps count: numJumps numArgs: 3! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
genByteScanEpilogueAt: i jumps: jumps count: numJumps numArgs: numArgs
	"The result of a byte scan is in SendNumArgsReg: reload the virtual registers, store the result, and emit the slow
	 path, the send, that the jumps branch to."
	<var: #jumps type: #'AbstractInstruction **'>
	self reloadAll.
	self setDst: (self fieldAAt: i) from: SendNumArgsReg.
	self genSlowSendAt: i numArgs: numArgs jumps: jumps count: numJumps reloadAll: true! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 03:00'!
genSkipSeparatorsAt: i
	"a := b skipSeparators (PositionableStream>>skipSeparators of a ReadStream): if b's collection (field 0) is a ByteString
	 and 0 <= position (1) <= readLimit (2) <= its size, advance the position over the separators (Character>>isSeparator:
	 codes 32, 13, 9, 10, 12 and 1) and answer b, skipping 8 spaces or 8 tabs per iteration (indentation), else bytewise.
	 Otherwise send the message.
	 Registers: Extra0Reg the stream, Extra1Reg the collection, SendNumArgsReg the address of the current byte, Extra2Reg
	 the end address, TempReg and ClassReg scratch."
	| jumps sepJumps numJumps wordLoop byteLoop jumpTail jumpSpaces jumpOther jumpEnd jumpStop next |
	<var: #jumps declareC: 'AbstractInstruction *jumps[10]'>
	<var: #sepJumps declareC: 'AbstractInstruction *sepJumps[6]'>
	<var: #wordLoop type: #'AbstractInstruction *'>
	<var: #byteLoop type: #'AbstractInstruction *'>
	<var: #jumpTail type: #'AbstractInstruction *'>
	<var: #jumpSpaces type: #'AbstractInstruction *'>
	<var: #jumpOther type: #'AbstractInstruction *'>
	<var: #jumpEnd type: #'AbstractInstruction *'>
	<var: #jumpStop type: #'AbstractInstruction *'>
	<var: #next type: #'AbstractInstruction *'>
	numJumps := 0.
	self spillAll. "(see genIndexOfByteAt:)"
	cogit MoveMw: (oilVRegSpillTemp at: (self fieldBAt: i)) r: FPReg R: Extra0Reg.
	cogit MoveMw: 1 * objectMemory wordSize + objectMemory baseHeaderSize r: Extra0Reg R: SendNumArgsReg.
	cogit MoveMw: 2 * objectMemory wordSize + objectMemory baseHeaderSize r: Extra0Reg R: Extra2Reg.
	cogit TstCq: objectMemory smallIntegerTag R: SendNumArgsReg.
	jumps at: numJumps put: (cogit JumpZero: 0). numJumps := numJumps + 1.
	cogit TstCq: objectMemory smallIntegerTag R: Extra2Reg.
	jumps at: numJumps put: (cogit JumpZero: 0). numJumps := numJumps + 1.
	cogit CmpCq: (objectMemory integerObjectOf: 0) R: SendNumArgsReg.
	jumps at: numJumps put: (cogit JumpLess: 0). numJumps := numJumps + 1.
	cogit CmpR: Extra2Reg R: SendNumArgsReg.
	jumps at: numJumps put: (cogit JumpGreater: 0). numJumps := numJumps + 1.
	cogit MoveMw: objectMemory baseHeaderSize r: Extra0Reg R: Extra1Reg.
	cogit TstCq: objectMemory tagMask R: Extra1Reg.
	jumps at: numJumps put: (cogit JumpNonZero: 0). numJumps := numJumps + 1.
	cogit MoveM16: 0 r: Extra1Reg R: TempReg.
	cogit CmpCq: ClassByteStringCompactIndex R: TempReg.
	jumps at: numJumps put: (cogit JumpNonZero: 0). numJumps := numJumps + 1.
	cogit oilGenGetNumBytesOf: Extra1Reg into: ClassReg.
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: SendNumArgsReg.
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: Extra2Reg.
	cogit CmpR: ClassReg R: Extra2Reg.
	jumps at: numJumps put: (cogit JumpGreater: 0). numJumps := numJumps + 1.
	cogit AddR: Extra1Reg R: SendNumArgsReg.
	cogit AddCq: objectMemory baseHeaderSize R: SendNumArgsReg.
	cogit AddR: Extra1Reg R: Extra2Reg.
	cogit AddCq: objectMemory baseHeaderSize R: Extra2Reg.
	"8 spaces or 8 tabs at a time while 8 bytes remain"
	wordLoop := cogit LoadEffectiveAddressMw: 8 r: SendNumArgsReg R: ClassReg.
	cogit CmpR: Extra2Reg R: ClassReg.
	jumpTail := cogit JumpAbove: 0.
	cogit MoveMw: 0 r: SendNumArgsReg R: TempReg.
	cogit CmpCq: 16r2020202020202020 R: TempReg.
	jumpSpaces := cogit JumpZero: 0.
	cogit CmpCq: 16r0909090909090909 R: TempReg.
	jumpOther := cogit JumpNonZero: 0.
	jumpSpaces jmpTarget: (cogit AddCq: 8 R: SendNumArgsReg).
	cogit Jump: wordLoop.
	"then bytewise, up to the first non-separator"
	byteLoop := cogit CmpR: Extra2Reg R: SendNumArgsReg.
	jumpTail jmpTarget: byteLoop.
	jumpOther jmpTarget: byteLoop.
	jumpEnd := cogit JumpAboveOrEqual: 0.
	cogit MoveCq: 0 R: TempReg.
	cogit MoveMb: 0 r: SendNumArgsReg R: TempReg.
	cogit CmpCq: 32 R: TempReg.
	sepJumps at: 0 put: (cogit JumpZero: 0).
	cogit CmpCq: 13 R: TempReg.
	sepJumps at: 1 put: (cogit JumpZero: 0).
	cogit CmpCq: 9 R: TempReg.
	sepJumps at: 2 put: (cogit JumpZero: 0).
	cogit CmpCq: 10 R: TempReg.
	sepJumps at: 3 put: (cogit JumpZero: 0).
	cogit CmpCq: 12 R: TempReg.
	sepJumps at: 4 put: (cogit JumpZero: 0).
	cogit CmpCq: 1 R: TempReg.
	sepJumps at: 5 put: (cogit JumpZero: 0).
	jumpStop := cogit Jump: 0.
	next := cogit AddCq: 1 R: SendNumArgsReg.
	0 to: 5 do: [:jumpIndex| (sepJumps at: jumpIndex) jmpTarget: next].
	cogit Jump: byteLoop.
	"position := address - (collection + 8); answer the stream"
	jumpEnd jmpTarget: (jumpStop jmpTarget: (cogit SubR: Extra1Reg R: SendNumArgsReg)).
	cogit SubCq: objectMemory baseHeaderSize R: SendNumArgsReg.
	cogit LogicalShiftLeftCq: objectMemory numTagBits R: SendNumArgsReg.
	cogit OrCq: objectMemory smallIntegerTag R: SendNumArgsReg.
	cogit MoveR: SendNumArgsReg Mw: 1 * objectMemory wordSize + objectMemory baseHeaderSize r: Extra0Reg.
	cogit MoveR: Extra0Reg R: SendNumArgsReg.
	self genByteScanEpilogueAt: i jumps: jumps count: numJumps numArgs: 0! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genCharValue: destReg of: srcReg
	"The SmallInteger value of the Character in srcReg (its class was guarded): 8v+2 -> 8v+1."
	| srcMach dstMach |
	srcMach := self src: srcReg scratch: TempReg.
	dstMach := self dst: destReg scratch: SendNumArgsReg.
	dstMach ~= srcMach ifTrue: [cogit MoveR: srcMach R: dstMach].
	cogit SubCq: objectMemory characterTag - objectMemory smallIntegerTag R: dstMach.
	self setDst: destReg from: dstMach! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
genLoadSize: destReg object: objReg bytes: isBytes
	"The number of slots of an Array (no fixed fields), or (isBytes) of bytes of a byte object, tagged."
	| objMach |
	isBytes
		ifTrue:
			[objMach := self src: objReg scratch: ClassReg. "(not TempReg: genGetNumBytesOf:into: uses it)"
			 cogit oilGenGetNumBytesOf: objMach into: SendNumArgsReg]
		ifFalse:
			[objMach := self src: objReg scratch: TempReg.
			 cogit oilGenGetNumSlotsOf: objMach into: SendNumArgsReg].
	cogit LogicalShiftLeftCq: objectMemory numTagBits R: SendNumArgsReg.
	cogit AddCq: objectMemory smallIntegerTag R: SendNumArgsReg.
	self setDst: destReg from: SendNumArgsReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genLoadByte: destReg array: arrayReg index: indexReg tag: tag
	"Byte i (1-based, bounds checked) of a byte object is at array + 8 + i - 1: untag the index, add 7, load the byte
	 zero extended (MoveXbr writes the low byte only: clear the register first) and tag it (SmallInteger or Character)."
	| arrayMach indexMach |
	arrayMach := self src: arrayReg scratch: TempReg.
	indexMach := self src: indexReg scratch: ClassReg.
	cogit MoveR: indexMach R: SendNumArgsReg.
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: SendNumArgsReg.
	cogit AddCq: objectMemory baseHeaderSize - 1 R: SendNumArgsReg.
	cogit MoveCq: 0 R: ClassReg.
	cogit MoveXbr: SendNumArgsReg R: arrayMach R: ClassReg.
	cogit LogicalShiftLeftCq: objectMemory numTagBits R: ClassReg.
	cogit OrCq: tag R: ClassReg.
	self setDst: destReg from: ClassReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genStoreByte: valReg array: arrayReg index: indexReg character: isChar site: siteIndex
	"Store the SmallInteger 0..255 (or Character of code 0..255) in valReg into byte indexReg of the byte object arrayReg (bounds checked).
	 Deoptimize if arrayReg is read-only or the value does not fit (the interpreter then fails or grows the string)."
	| valMach arrayMach indexMach |
	arrayMach := self src: arrayReg scratch: TempReg.
	self genImmutabilityCheckOf: arrayMach scratch: SendNumArgsReg site: siteIndex.
	indexMach := self src: indexReg scratch: ClassReg.
	cogit MoveR: indexMach R: SendNumArgsReg.
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: SendNumArgsReg.
	cogit AddCq: objectMemory baseHeaderSize - 1 R: SendNumArgsReg.
	valMach := self src: valReg scratch: ClassReg.
	valMach ~= ClassReg ifTrue: [cogit MoveR: valMach R: ClassReg].
	isChar
		ifTrue: "tag bits 2r010"
			[cogit TstCq: objectMemory tagMask - objectMemory characterTag R: ClassReg.
			 self deopt: (cogit JumpNonZero: 0) site: siteIndex.
			 cogit TstCq: objectMemory characterTag R: ClassReg.
			 self deopt: (cogit JumpZero: 0) site: siteIndex]
		ifFalse:
			[cogit TstCq: objectMemory smallIntegerTag R: ClassReg.
			 self deopt: (cogit JumpZero: 0) site: siteIndex].
	cogit LogicalShiftRightCq: objectMemory numTagBits R: ClassReg.
	cogit CmpCq: 255 R: ClassReg.
	self deopt: (cogit JumpAbove: 0) site: siteIndex.
	cogit MoveR: ClassReg Xbr: SendNumArgsReg R: arrayMach! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genCompareBytes: destReg with: firstReg with: secondReg site: siteIndex
	"Primitive 158 (compareWith:) inlined: firstReg, a byte object (its class was guarded), and secondReg, which must be a byte
	 object too (else deoptimize): answer the difference of the first differing bytes, else of the sizes.  All the
	 registers are spilled and used as scratch: Arg0Reg s1, Arg1Reg s2, Extra0Reg size difference, SendNumArgsReg
	 the common size, ReceiverResultReg the byte index; 8 bytes are compared at a time while they are equal."
	| secondMach jumpMin wordLoop jumpToBytes jumpWordDiffers byteLoop jumpEnd jumpByteDiffers jumpDone |
	<var: #jumpMin type: #'AbstractInstruction *'>
	<var: #wordLoop type: #'AbstractInstruction *'>
	<var: #jumpToBytes type: #'AbstractInstruction *'>
	<var: #jumpWordDiffers type: #'AbstractInstruction *'>
	<var: #byteLoop type: #'AbstractInstruction *'>
	<var: #jumpEnd type: #'AbstractInstruction *'>
	<var: #jumpByteDiffers type: #'AbstractInstruction *'>
	<var: #jumpDone type: #'AbstractInstruction *'>
	"Check the argument first, while the registers still hold the virtual registers (a deopt spills them)."
	secondMach := self src: secondReg scratch: ClassReg.
	cogit TstCq: objectMemory tagMask R: secondMach.
	self deopt: (cogit JumpNonZero: 0) site: siteIndex.
	cogit MoveM32: 0 r: secondMach R: TempReg.
	cogit LogicalShiftRightCq: objectMemory formatShift R: TempReg.
	cogit AndCq: objectMemory formatMask R: TempReg.
	cogit CmpCq: objectMemory firstByteFormat R: TempReg.
	self deopt: (cogit JumpLess: 0) site: siteIndex.
	self spillAll.
	cogit MoveMw: (oilVRegSpillTemp at: firstReg) r: FPReg R: Arg0Reg.
	cogit MoveMw: (oilVRegSpillTemp at: secondReg) r: FPReg R: Arg1Reg.
	cogit oilGenGetNumBytesOf: Arg0Reg into: Extra0Reg.
	cogit oilGenGetNumBytesOf: Arg1Reg into: Extra1Reg.
	cogit MoveR: Extra0Reg R: SendNumArgsReg.
	cogit CmpR: Extra1Reg R: SendNumArgsReg.
	jumpMin := cogit JumpLessOrEqual: 0.
	cogit MoveR: Extra1Reg R: SendNumArgsReg.
	jumpMin jmpTarget: cogit Label.
	cogit SubR: Extra1Reg R: Extra0Reg.
	cogit MoveCq: 0 R: ReceiverResultReg.
	"8 bytes at a time while they are equal"
	wordLoop := cogit MoveR: ReceiverResultReg R: TempReg.
	cogit AddCq: objectMemory wordSize R: TempReg.
	cogit CmpR: SendNumArgsReg R: TempReg.
	jumpToBytes := cogit JumpGreater: 0.
	cogit MoveR: ReceiverResultReg R: ClassReg.
	cogit LogicalShiftRightCq: objectMemory shiftForWord R: ClassReg.
	cogit AddCq: 1 R: ClassReg.
	cogit MoveXwr: ClassReg R: Arg0Reg R: TempReg.
	cogit MoveXwr: ClassReg R: Arg1Reg R: ClassReg.
	cogit CmpR: ClassReg R: TempReg.
	jumpWordDiffers := cogit JumpNonZero: 0.
	cogit AddCq: objectMemory wordSize R: ReceiverResultReg.
	cogit Jump: wordLoop.
	"then a byte at a time"
	byteLoop := cogit CmpR: SendNumArgsReg R: ReceiverResultReg.
	jumpToBytes jmpTarget: byteLoop.
	jumpWordDiffers jmpTarget: byteLoop.
	jumpEnd := cogit JumpGreaterOrEqual: 0.
	cogit MoveR: ReceiverResultReg R: ClassReg.
	cogit AddCq: objectMemory baseHeaderSize R: ClassReg.
	cogit MoveCq: 0 R: TempReg.
	cogit MoveXbr: ClassReg R: Arg0Reg R: TempReg.
	cogit MoveCq: 0 R: Extra1Reg.
	cogit MoveXbr: ClassReg R: Arg1Reg R: Extra1Reg.
	cogit CmpR: Extra1Reg R: TempReg.
	jumpByteDiffers := cogit JumpNonZero: 0.
	cogit AddCq: 1 R: ReceiverResultReg.
	cogit Jump: byteLoop.
	jumpByteDiffers jmpTarget: (cogit SubR: Extra1Reg R: TempReg).
	cogit MoveR: TempReg R: SendNumArgsReg.
	jumpDone := cogit Jump: 0.
	jumpEnd jmpTarget: (cogit MoveR: Extra0Reg R: SendNumArgsReg).
	jumpDone jmpTarget: cogit Label.
	self reloadAll.
	cogit LogicalShiftLeftCq: objectMemory numTagBits R: SendNumArgsReg.
	cogit OrCq: objectMemory smallIntegerTag R: SendNumArgsReg.
	self setDst: destReg from: SendNumArgsReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genLogicTagged: opcode a: destReg b: leftReg c: rightReg site: siteIndex
	"bitAnd:/bitOr: on tagged values need no untagging (1 and 1 = 1 or 1 = 1); bitXor: clears the tag: set it again."
	| leftMach rightMach |
	leftMach := self src: leftReg scratch: TempReg.
	rightMach := self src: rightReg scratch: ClassReg.
	self genTagCheckOf: leftReg in: leftMach and: rightReg in: rightMach site: siteIndex.
	cogit MoveR: leftMach R: SendNumArgsReg.
	opcode = OilAndTagged ifTrue: [cogit AndR: rightMach R: SendNumArgsReg].
	opcode = OilOrTagged ifTrue: [cogit OrR: rightMach R: SendNumArgsReg].
	opcode = OilXorTagged ifTrue:
		[cogit XorR: rightMach R: SendNumArgsReg.
		 cogit OrCq: objectMemory smallIntegerTag R: SendNumArgsReg].
	self setDst: destReg from: SendNumArgsReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genShiftTagged: destReg b: srcReg shift: shiftAmount site: siteIndex
	"shiftAmount > 0: x // 2^shiftAmount, i.e. an arithmetic right shift: sar (3+shiftAmount), shl 3, or 1 (exact floor, no overflow).
	 shiftAmount < 0: x * 2^-shiftAmount: (t - 1) << -shiftAmount, checked by shifting back, then or 1."
	| srcMach |
	srcMach := self src: srcReg scratch: TempReg.
	self genTagCheckOf: srcReg in: srcMach site: siteIndex.
	cogit MoveR: srcMach R: SendNumArgsReg.
	shiftAmount > 0
		ifTrue:
			[cogit ArithmeticShiftRightCq: objectMemory numTagBits + shiftAmount R: SendNumArgsReg.
			 cogit LogicalShiftLeftCq: objectMemory numTagBits R: SendNumArgsReg]
		ifFalse:
			[cogit SubCq: 1 R: SendNumArgsReg.
			 cogit LogicalShiftLeftCq: shiftAmount negated R: SendNumArgsReg.
			 cogit MoveR: SendNumArgsReg R: ClassReg.
			 cogit ArithmeticShiftRightCq: shiftAmount negated R: ClassReg.
			 cogit AddCq: 1 R: ClassReg.
			 cogit CmpR: srcMach R: ClassReg.
			 self deopt: (cogit JumpNonZero: 0) site: siteIndex].
	cogit OrCq: objectMemory smallIntegerTag R: SendNumArgsReg.
	self setDst: destReg from: SendNumArgsReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genOddTagged: destReg b: srcReg site: siteIndex
	"x \\ 2 = x bitAnd: 1, i.e. on the tagged value (t bitAnd: 8) bitOr: 1."
	| srcMach |
	srcMach := self src: srcReg scratch: TempReg.
	self genTagCheckOf: srcReg in: srcMach site: siteIndex.
	cogit MoveR: srcMach R: SendNumArgsReg.
	cogit AndCq: 1 << objectMemory numTagBits R: SendNumArgsReg.
	cogit OrCq: objectMemory smallIntegerTag R: SendNumArgsReg.
	self setDst: destReg from: SendNumArgsReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genAddImmTagged: destReg b: srcReg imm: imm site: siteIndex
	"x + imm on tagged values is t + 8 imm: one add, overflow checked (e.g. the loop increment, addq $8)."
	| srcMach |
	srcMach := self src: srcReg scratch: TempReg.
	self genTagCheckOf: srcReg in: srcMach site: siteIndex.
	cogit MoveR: srcMach R: SendNumArgsReg.
	cogit AddCq: imm << objectMemory numTagBits R: SendNumArgsReg.
	self deopt: (cogit JumpOverflow: 0) site: siteIndex.
	self setDst: destReg from: SendNumArgsReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genAddImmTaggedNoCheck: destReg b: srcReg imm: imm
	"x + imm where Pass 2 proved x a SmallInteger and the sum one too (a counted loop index): addq $8imm, in place
	 if destReg and srcReg share a machine register."
	| destMach srcMach |
	srcMach := self src: srcReg scratch: TempReg.
	destMach := self dst: destReg scratch: SendNumArgsReg.
	destMach ~= srcMach ifTrue: [cogit MoveR: srcMach R: destMach].
	cogit AddCq: imm << objectMemory numTagBits R: destMach.
	self setDst: destReg from: destMach! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genLoadField: destReg object: objReg slot: slotIndex
	| objMach dstMach |
	objMach := self src: objReg scratch: TempReg.
	dstMach := self dst: destReg scratch: SendNumArgsReg.
	cogit MoveMw: slotIndex * objectMemory wordSize + objectMemory baseHeaderSize r: objMach R: dstMach.
	self setDst: destReg from: dstMach! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genImmutabilityCheckOf: objReg scratch: scratchReg site: siteIndex
	"Deoptimize if the object in objReg is read-only: the interpreter then retries the store and signals the failure."
	cogit MoveMw: 0 r: objReg R: scratchReg.
	cogit TstCq: objectMemory immutableBitMask R: scratchReg.
	self deopt: (cogit JumpNonZero: 0) site: siteIndex! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genStoreCheckObject: objReg value: valueReg scratch: scratch
	"The generational write barrier: if a young object is stored into an old, not yet remembered, object, remember it.
	 The slow path calls ceStoreCheckTrampoline (receiver in ReceiverResultReg) with every register spilled."
	| jmpImmediate jmpDestYoung jmpSourceOld jmpRemembered |
	<var: #jmpImmediate type: #'AbstractInstruction *'>
	<var: #jmpDestYoung type: #'AbstractInstruction *'>
	<var: #jmpSourceOld type: #'AbstractInstruction *'>
	<var: #jmpRemembered type: #'AbstractInstruction *'>
	cogit TstCq: objectMemory tagMask R: valueReg.
	jmpImmediate := cogit JumpNonZero: 0.
	cogit MoveCw: objectMemory storeCheckBoundary R: scratch.
	cogit CmpR: scratch R: objReg.
	jmpDestYoung := cogit JumpBelow: 0.
	cogit CmpR: scratch R: valueReg.
	jmpSourceOld := cogit JumpAboveOrEqual: 0.
	jmpRemembered := cogit oilGenJumpRemembered: objReg scratch: scratch.
	self spillAll.
	objReg ~= ReceiverResultReg ifTrue: [cogit MoveR: objReg R: ReceiverResultReg].
	cogit oilGenStoreCheckCall.
	self reloadAll.
	jmpImmediate jmpTarget: (jmpDestYoung jmpTarget: (jmpSourceOld jmpTarget: (jmpRemembered jmpTarget: cogit Label)))! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genStoreField: valReg object: objReg slot: slotIndex site: siteIndex
	| valMach objMach |
	valMach := self src: valReg scratch: TempReg.
	objMach := self src: objReg scratch: ClassReg.
	self genImmutabilityCheckOf: objMach scratch: SendNumArgsReg site: siteIndex.
	cogit MoveR: valMach Mw: slotIndex * objectMemory wordSize + objectMemory baseHeaderSize r: objMach.
	self genStoreCheckObject: objMach value: valMach scratch: SendNumArgsReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genLoadElement: destReg array: arrayReg index: indexReg
	"Element i (1-based) of an Array (no fixed fields) is at array + 8 + 8(i-1) = array + 8i = array + tagged(i) - 1.
	 The bounds were checked (by an OilCheckBounds, or by Pass 2)."
	| arrayMach indexMach dstMach |
	arrayMach := self src: arrayReg scratch: TempReg.
	indexMach := self src: indexReg scratch: ClassReg.
	dstMach := self dst: destReg scratch: SendNumArgsReg.
	cogit MoveR: indexMach R: SendNumArgsReg.
	cogit AddR: arrayMach R: SendNumArgsReg.
	cogit MoveMw: -1 r: SendNumArgsReg R: dstMach.
	self setDst: destReg from: dstMach! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genStoreElement: valReg array: arrayReg index: indexReg site: siteIndex
	| valMach arrayMach indexMach |
	arrayMach := self src: arrayReg scratch: ClassReg.
	self genImmutabilityCheckOf: arrayMach scratch: TempReg site: siteIndex.
	indexMach := self src: indexReg scratch: SendNumArgsReg.
	indexMach ~= SendNumArgsReg ifTrue: [cogit MoveR: indexMach R: SendNumArgsReg].
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: SendNumArgsReg.
	valMach := self src: valReg scratch: TempReg.
	cogit MoveR: valMach Xwr: SendNumArgsReg R: arrayMach.
	self genStoreCheckObject: arrayMach value: valMach scratch: SendNumArgsReg! !

!OilInliningCompiler methodsFor: 'interrupt checks' stamp: 'cb 10/26/2026 20:30'!
genPollBefore: irOffset
	"Oil code has no stack check at its back jumps, unlike the baseline JIT's (see SimpleStackBasedCogit>>genJumpBackTo:):
	 a loop of Oil code whose body sends nothing that builds a frame would never poll for events (the timer, process
	 switches, interrupts).  So each loop checks the stack limit once per iteration, before its first instruction from its
	 header (in straight-line code) that has a deopt site with a state: if it was hit, an out-of-line stub (see
	 genPollStubs) spills the registers and calls ceCheckForInterruptTrampoline, which may switch processes.  The frame is
	 then suspended in that call: a clone of the site, recorded as a call site without a send (OilMDSiteNoSend, see
	 noteCallSiteAt:), maps it to the activations it stands for at that bytecode (to marry, divorce or deoptimize it).  Not in
	 the loops whose float variables are in XMM registers (which the call would clobber), nor in a float chain."
	| siteIndex opcode |
	opcode := self opcodeAt: irOffset.
	siteIndex := oilIRSite at: irOffset.
	(oilFloatLoopCurrent < 0
	 and: [siteIndex >= 0
	 and: [(self siteHasState: siteIndex)
	 and: [(self flag: irOffset has: OilFloatChained) not
	 and: [numSites < OilMaxSites
	 and: [oilNumPolls < OilMaxPolls]]]]]) ifFalse:
		[(oilFloatLoopCurrent >= 0 or: [(self isBranch: opcode) or: [opcode = OilReturn]]) ifTrue:
			[oilPollPending := false].
		 ^self].
	oilPollPending := false.
	self resetXmms. "(the call clobbers them)"
	oilPollSite at: oilNumPolls put: (self cloneSite: siteIndex at: irOffset).
	oilSiteUsed at: (oilPollSite at: oilNumPolls) put: 3.
	cogit MoveAw: coInterpreter stackLimitAddress R: TempReg.
	cogit CmpR: TempReg R: SPReg. "N.B. FLAGS := SPReg - TempReg"
	oilPollJump at: oilNumPolls put: (cogit JumpBelow: 0).
	oilPollResume at: oilNumPolls put: cogit Label.
	oilNumPolls := oilNumPolls + 1! !

!OilInliningCompiler methodsFor: 'interrupt checks' stamp: 'cb 10/26/2026 19:30'!
genPollStubs
	"The out-of-line stubs of the interrupt checks of the loops (see genPollBefore:): spill everything (the garbage
	 collector may run, and the frame may be married or deoptimized while suspended), call ceCheckForInterruptTrampoline,
	 whose return address is the resume address of the check's site, reload and resume the loop."
	| stub |
	<var: #stub type: #'AbstractInstruction *'>
	0 to: oilNumPolls - 1 do:
		[:pollIndex|
		stub := cogit Label.
		(oilPollJump at: pollIndex) jmpTarget: stub.
		self spillAll.
		cogit oilGenInterruptCheckCall.
		oilSiteResume at: (oilPollSite at: pollIndex) put: cogit Label.
		self reloadAll.
		(cogit Jump: 0) jmpTarget: (oilPollResume at: pollIndex)]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 21:00'!
cloneSite: siteIndex at: irOffset
	"A new deopt site for the instruction at irOffset, a copy of the one of deopt site siteIndex: the same inlined frame,
	 bytecode pc and recorded state (the copy computes into the same registers, see useCondSite: in Pass 1)."
	| newSiteIndex |
	newSiteIndex := numSites.
	newSiteIndex >= OilMaxSites ifTrue:
		[self abortCompilation: OilFailTooManySites.
		 ^siteIndex].
	siteIR at: newSiteIndex put: irOffset.
	siteFrame at: newSiteIndex put: (siteFrame at: siteIndex).
	sitePC at: newSiteIndex put: (sitePC at: siteIndex).
	siteKind at: newSiteIndex put: (siteKind at: siteIndex).
	siteSnapBase at: newSiteIndex put: (siteSnapBase at: siteIndex).
	siteSnapTop at: newSiteIndex put: (siteSnapTop at: siteIndex).
	siteSnapHigh at: newSiteIndex put: (siteSnapHigh at: siteIndex).
	numSites := newSiteIndex + 1.
	^newSiteIndex! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/25/2026 22:30'!
prepareFloatLoops
	"Pass 3 (M10): find the innermost loops whose float variables can live in XMM registers across iterations (see
	 analyzeFloatLoop:end:).  Their code then computes on raw doubles: the variables are unboxed once when the loop is entered,
	 and boxed (as SmallFloat64s, which their values are checked to fit) only at the loop's exits and in its deopt stubs."
	| irOffset |
	oilNumFloatLoops := oilNumFloatExits := 0.
	oilFloatLoopCurrent := -1.
	0 to: OilNumRegs - 1 do: [:vreg| oilXmmPinned at: vreg put: -1].
	0 to: OilMaxSites - 1 do: [:siteIndex| oilSiteFloatLoop at: siteIndex put: 0].
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[(((self opcodeAt: irOffset) = OilJump
		   or: [(self opcodeAt: irOffset) = OilBranchTrue and: [(self fieldAAt: irOffset) = OilFlagsReg]]) "(a rotated loop)"
		  and: [(self imm16At: irOffset) <= irOffset]) ifTrue:
			[self analyzeFloatLoop: (self imm16At: irOffset) end: irOffset].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)]! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
analyzeFloatLoop: loopHead end: backJump
	"The loop from loopHead to the Jump at backJump gets XMM registers for its float variables if it is innermost, entered only
	 by falling into loopHead, whose instruction has a deopt site (its state is the one entering the loop; for a rotated loop,
	 closed by a BranchTrue, the site of the header's test before it), and nothing in it may clobber the XMM registers
	 (sends, guards and stores calling out...) or return.
	 Its float variables: the registers it assigns only float results (not unboxed in a float chain) or moves of float
	 variables, and reads only as operands of float instructions or into float variables.  Kind 1: read before assigned in the
	 loop, and holding a float entering it (the straight-line code before it assigns it a Float literal or a float result), or
	 else deoptimizing anyway (a float instruction the loop starts with uses it as its receiver): loaded when entering.  Kind 2: always assigned before read in the loop, and not read after it before assigned: just
	 0.0 when entering.  Its float invariants (kind 100 + the int mode of genLoadDouble:into:ints:site:): the registers it does
	 not assign that float instructions read.  At most OilMaxPinnedXmms of them, the variables first."
	| site entryOffset irOffset opcode target numCandidates candidate kind changed numPinned wanted candidates kinds |
	<var: #candidates declareC: 'sqInt candidates[16]'>
	<var: #kinds declareC: 'sqInt kinds[16]'>
	self cCode: [] inSmalltalk: [candidates := CArrayAccessor on: (Array new: 16). kinds := CArrayAccessor on: (Array new: 16)].
	oilNumFloatLoops >= OilMaxFloatLoops ifTrue: [^self].
	site := oilIRSite at: loopHead.
	entryOffset := loopHead.
	((self opcodeAt: backJump) = OilBranchTrue
	 and: [loopHead >= 2
	 and: [(self opcodeAt: loopHead - 1) = OilBranchFalse
	 and: [(self fieldAAt: loopHead - 1) = OilFlagsReg
	 and: [(oilIRTarget at: loopHead - 1) = 0
	 and: [(self opcodeAt: loopHead - 2) = OilCmpTagged or: [(self opcodeAt: loopHead - 2) = OilCmpImmTagged]]]]]]) ifTrue:
		["a rotated loop: entered after its header's test"
		 entryOffset := loopHead - 2.
		 ((oilIRSite at: entryOffset) >= 0 and: [self siteHasState: (oilIRSite at: entryOffset)]) ifTrue:
			[site := oilIRSite at: entryOffset]].
	site < 0 ifTrue: [site := self entrySiteAfter: loopHead].
	(site >= 0 and: [(self siteHasState: site) and: [numSites < OilMaxSites]]) ifFalse: [^self].
	"The loop's shape, and its float operands."
	numCandidates := 0.
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (self isBranch: opcode) ifTrue:
			[target := self imm16At: irOffset.
			 (irOffset ~= backJump and: [target = loopHead]) ifTrue: [^self].
			 (irOffset > loopHead and: [irOffset < backJump and: [target <= irOffset]]) ifTrue: [^self]].
		 (irOffset >= loopHead and: [irOffset < backJump]) ifTrue:
			[((self mayClobberXmms: opcode) or: [opcode = OilReturn]) ifTrue: [^self].
			 (self isFloatOpcode: opcode) ifTrue:
				[numCandidates := self addCandidate: (self fieldBAt: irOffset) to: candidates count: numCandidates.
				 numCandidates := self addCandidate: (self fieldCAt: irOffset) to: candidates count: numCandidates.
				 opcode ~= OilCmpFloat ifTrue:
					[numCandidates := self addCandidate: (self fieldAAt: irOffset) to: candidates count: numCandidates].
				 numCandidates < 0 ifTrue: [^self]]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	numCandidates = 0 ifTrue: [^self].
	"Invariants, and variables (provisionally kind 1 or 2)."
	0 to: numCandidates - 1 do:
		[:index|
		candidate := candidates at: index.
		(self isAssigned: candidate from: loopHead to: backJump - 1)
			ifTrue: [kind := (self isTempFloat: candidate from: loopHead to: backJump) ifTrue: [2] ifFalse: [1]]
			ifFalse: [kind := 100 + (self floatIntModeOf: candidate from: loopHead to: backJump)].
		kinds at: index put: kind].
	changed := true.
	[changed] whileTrue:
		[changed := false.
		 0 to: numCandidates - 1 do:
			[:index|
			kind := kinds at: index.
			((kind = 1 or: [kind = 2])
			 and: [(self isFloatVariable: (candidates at: index) from: loopHead to: backJump candidates: candidates kinds: kinds count: numCandidates) not
				or: [kind = 1
						ifTrue: [(self isFloatEntering: (candidates at: index) loop: loopHead entry: entryOffset) not
									and: [(self isFloatReceiver: (candidates at: index) atStartOf: loopHead) not]]
						ifFalse: [self isFloat: (candidates at: index) readAfterLoop: loopHead end: backJump]]]) ifTrue:
				[kinds at: index put: -1.
				 changed := true]]].
	"Pin them, the variables first."
	numPinned := 0.
	wanted := 0.
	[wanted < 2] whileTrue:
		[0 to: numCandidates - 1 do:
			[:index|
			kind := kinds at: index.
			((wanted = 0 ifTrue: [kind = 1 or: [kind = 2]] ifFalse: [kind >= 100]) and: [numPinned < OilMaxPinnedXmms]) ifTrue:
				[oilFloatLoopVReg at: oilNumFloatLoops * OilMaxPinnedXmms + numPinned put: (candidates at: index).
				 oilFloatLoopKind at: oilNumFloatLoops * OilMaxPinnedXmms + numPinned put: kind.
				 numPinned := numPinned + 1]].
		 wanted := wanted + 1].
	numPinned = 0 ifTrue: [^self].
	oilFloatLoopHead at: oilNumFloatLoops put: loopHead.
	oilFloatLoopEnd at: oilNumFloatLoops put: backJump.
	oilFloatLoopNum at: oilNumFloatLoops put: numPinned.
	"The loads when entering the loop deoptimize to (a clone of) the site of its first instruction, without boxing."
	oilFloatLoopSite at: oilNumFloatLoops put: (self cloneSite: site at: loopHead).
	oilNumFloatLoops := oilNumFloatLoops + 1! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
entrySiteAfter: loopHead
	"The deopt site of the first instruction with one in the straight-line code starting at loopHead, if the instructions
	 before it only compute registers (constants, moves, loads) its state does not refer to: then its state is the one entering
	 the loop.  Else -1."
	| irOffset opcode siteIndex |
	irOffset := loopHead.
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (irOffset > loopHead and: [(oilIRTarget at: irOffset) ~= 0]) ifTrue: [^-1].
		 siteIndex := oilIRSite at: irOffset.
		 (siteIndex >= 0 and: [self siteHasState: siteIndex]) ifTrue:
			[irOffset := loopHead.
			 [(oilIRSite at: irOffset) ~= siteIndex] whileTrue:
				[(self state: siteIndex refersTo: (self fieldAAt: irOffset)) ifTrue: [^-1].
				 irOffset := irOffset + (self instructionLengthAt: irOffset)].
			 ^siteIndex].
		 (opcode = OilConstTagged or: [opcode = OilConst64 or: [opcode = OilMove or: [opcode = OilLoadField
		  or: [opcode = OilLoadSize or: [opcode = OilLoadByteSize]]]]]) ifFalse: [^-1].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^-1! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
isFloatReceiver: vreg atStartOf: loopHead
	"Is register vreg the receiver of a float instruction in the straight-line code the loop starts with (which deoptimizes if
	 it is not a Float, as unboxing it when entering does)?"
	| irOffset opcode |
	irOffset := loopHead.
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 ((irOffset > loopHead and: [(oilIRTarget at: irOffset) ~= 0])
		  or: [(self isBranch: opcode) or: [opcode = OilReturn]]) ifTrue: [^false].
		 ((self isFloatOpcode: opcode) and: [(self fieldBAt: irOffset) = vreg]) ifTrue: [^true].
		 ((self opcodeHasDest: opcode) and: [(self fieldAAt: irOffset) = vreg]) ifTrue: [^false].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^false! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
floatIntModeOf: vreg from: loopHead to: backJump
	"How a float invariant is loaded (see genLoadDouble:into:ints:site:): 0 (a Float) if a float instruction of the loop uses
	 it as its receiver, else 2 (or a SmallInteger exactly representable) if a comparison uses it, else 1 (or a SmallInteger)."
	| irOffset opcode intMode |
	intMode := 1.
	irOffset := loopHead.
	[irOffset < backJump] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (self isFloatOpcode: opcode) ifTrue:
			[(self fieldBAt: irOffset) = vreg ifTrue: [intMode := 0].
			 ((self fieldCAt: irOffset) = vreg and: [opcode = OilCmpFloat and: [intMode = 1]]) ifTrue: [intMode := 2]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^intMode! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
isTempFloat: vreg from: loopHead to: backJump
	"Is every read of register vreg in the loop from loopHead to backJump preceded by an assignment of it in the same
	 straight-line code (no branch target in between)?"
	| irOffset assigned |
	assigned := false.
	irOffset := loopHead.
	[irOffset < backJump] whileTrue:
		[(oilIRTarget at: irOffset) ~= 0 ifTrue: [assigned := false].
		 (assigned not and: [self instruction: irOffset reads: vreg]) ifTrue: [^false].
		 ((self opcodeHasDest: (self opcodeAt: irOffset)) and: [(self fieldAAt: irOffset) = vreg]) ifTrue: [assigned := true].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^true! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
isFloatEntering: vreg loop: loopHead entry: entryOffset
	"Does the straight-line code falling into loopHead (or into entryOffset, the test of a rotated loop before it) last assign
	 register vreg a Float literal or a (boxed) float result?"
	| irOffset defOffset opcode |
	defOffset := -1.
	irOffset := self regionStartBefore: entryOffset.
	[irOffset < loopHead] whileTrue:
		[((self opcodeHasDest: (self opcodeAt: irOffset)) and: [(self fieldAAt: irOffset) = vreg]) ifTrue: [defOffset := irOffset].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	defOffset < 0 ifTrue: [^false].
	opcode := self opcodeAt: defOffset.
	opcode = OilConst64 ifTrue: [^self isFloatHandle: (self word64At: defOffset + 1)].
	^(self isFloatArith: opcode) and: [(self flag: defOffset has: OilFloatUnboxed) not]! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
isFloat: vreg readAfterLoop: loopHead end: backJump
	"May register vreg be read by an instruction (deopt states do not count: a dead temporary) after the loop from loopHead to
	 backJump exits, before being assigned (see mayRead:paths:count:states:)?  oilIRMap, free in Pass 3, marks the branch targets
	 followed."
	<inline: false>
	| stack sp irOffset opcode target |
	<var: #stack declareC: 'sqInt stack[16]'>
	self cCode: [] inSmalltalk: [stack := CArrayAccessor on: (Array new: 16)].
	0 to: irIndex - 1 do: [:offset| oilIRMap at: offset put: 0].
	sp := 0.
	(self opcodeAt: backJump) ~= OilJump ifTrue: "a rotated loop also exits by falling through its back branch"
		[stack at: sp put: backJump + (self instructionLengthAt: backJump).
		 sp := sp + 1].
	irOffset := loopHead.
	[irOffset <= backJump] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 ((self isBranch: opcode) and: [(target := self imm16At: irOffset) < loopHead or: [target > backJump]]) ifTrue:
			[sp >= 16 ifTrue: [^true].
			 stack at: sp put: target.
			 sp := sp + 1].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^self mayRead: vreg paths: stack count: sp states: false! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
mayRead: vreg paths: stack count: numPaths states: withStates
	"May register vreg be read before being assigned on a path from the numPaths offsets on stack (16 at most)?  Follows the
	 control flow, both ways at conditional branches, answering true beyond 16 pending paths or a budget of instructions.
	 Reads are the operands of the instructions, and, if withStates, the deopt states of their live sites (Pass 2, see
	 isLive:from:, budget 256).  Else (Pass 3, see isFloat:readAfterLoop:end:, budget 512) each branch target is followed
	 once: oilIRMap, cleared by the caller, marks them."
	<inline: false>
	<var: #stack type: #'sqInt *'>
	| sp irOffset opcode budget |
	sp := numPaths.
	budget := withStates ifTrue: [256] ifFalse: [512].
	[sp > 0] whileTrue:
		[sp := sp - 1.
		 irOffset := stack at: sp.
		 withStates ifFalse: [irOffset := self firstVisitOf: irOffset].
		 [irOffset < irIndex] whileTrue:
			[(budget := budget - 1) < 0 ifTrue: [^true].
			 opcode := self opcodeAt: irOffset.
			 (self instruction: irOffset reads: vreg) ifTrue: [^true].
			 (withStates and: [self liveStateAt: irOffset refersTo: vreg]) ifTrue: [^true].
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
									ifFalse: [irOffset + (self instructionLengthAt: irOffset)].
					 (withStates not and: [irOffset < irIndex and: [(oilIRTarget at: irOffset) ~= 0]]) ifTrue: "a label: once"
						[irOffset := self firstVisitOf: irOffset]]]].
	^false! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
firstVisitOf: irOffset
	"Mark irOffset visited (oilIRMap, see mayRead:paths:count:states:) and answer it, or irIndex (the path ends) if it was."
	irOffset >= irIndex ifTrue: [^irIndex].
	(oilIRMap at: irOffset) ~= 0 ifTrue: [^irIndex].
	oilIRMap at: irOffset put: 1.
	^irOffset! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/25/2026 22:30'!
genFloatLoopEntryAt: irOffset
	"If irOffset is the head of a loop with float registers, entered by falling into it: load its float variables and invariants
	 into their XMM registers (deoptimizing, without boxing, if one is not a Float, or a variable does not fit a SmallFloat64),
	 then translate the loop with them (oilXmmPinned, oilFloatLoopCurrent)."
	| loopIndex resume vreg xmmIndex kind |
	<var: #resume type: #'AbstractInstruction *'>
	loopIndex := -1.
	0 to: oilNumFloatLoops - 1 do:
		[:index| (oilFloatLoopHead at: index) = irOffset ifTrue: [loopIndex := index]].
	loopIndex < 0 ifTrue: [^self].
	self resetXmms.
	resume := cogit Label.
	oilSiteResume at: (oilFloatLoopSite at: loopIndex) put: resume.
	0 to: (oilFloatLoopNum at: loopIndex) - 1 do:
		[:index|
		vreg := oilFloatLoopVReg at: loopIndex * OilMaxPinnedXmms + index.
		kind := oilFloatLoopKind at: loopIndex * OilMaxPinnedXmms + index.
		xmmIndex := OilNumXmms + index.
		kind = 2
			ifTrue: "a temporary float variable: 0.0"
				[cogit MoveCq: 0 R: TempReg.
				 cogit ConvertR: TempReg Rd: (oilXmmRegs at: xmmIndex)]
			ifFalse:
				[self genLoadDouble: vreg into: (oilXmmRegs at: xmmIndex) ints: (kind = 1 ifTrue: [0] ifFalse: [kind - 100]) site: (oilFloatLoopSite at: loopIndex).
				 kind = 1 ifTrue:
					[cogit MoveRd: (oilXmmRegs at: xmmIndex) R: ClassReg.
					 self deopt: (cogit oilGenJumpNotSmallFloatValueBits: ClassReg scratch: TempReg) site: (oilFloatLoopSite at: loopIndex)]].
		oilXmmPinned at: vreg put: xmmIndex].
	oilFloatLoopCurrent := loopIndex! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/25/2026 22:30'!
genFloatLoopExits
	"After the back jump of the current loop with float registers: if it is a conditional branch (a rotated loop), the boxing
	 of the float variables into their registers on the way out, then the exit stubs, boxing them before going to the exit
	 targets; then translate the rest without them."
	| loopIndex label jumpOver |
	<var: #label type: #'AbstractInstruction *'>
	<var: #jumpOver type: #'AbstractInstruction *'>
	loopIndex := oilFloatLoopCurrent.
	oilFloatLoopCurrent := -1.
	jumpOver := nil.
	(self opcodeAt: (oilFloatLoopEnd at: loopIndex)) ~= OilJump ifTrue:
		[self genBoxFloatLoopVariables: loopIndex.
		 oilNumFloatExits > 0 ifTrue: [jumpOver := cogit Jump: 0]].
	0 to: oilNumFloatExits - 1 do:
		[:exitIndex|
		label := cogit Label.
		(oilFloatExitJump at: exitIndex) jmpTarget: label.
		self genBoxFloatLoopVariables: loopIndex.
		self branch: (cogit Jump: 0) to: (oilFloatExitTarget at: exitIndex)].
	oilNumFloatExits := 0.
	jumpOver ~= nil ifTrue: [jumpOver jmpTarget: cogit Label].
	0 to: (oilFloatLoopNum at: loopIndex) - 1 do:
		[:index| oilXmmPinned at: (oilFloatLoopVReg at: loopIndex * OilMaxPinnedXmms + index) put: -1].
	self resetXmms! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/25/2026 22:30'!
genBoxFloatLoopVariables: loopIndex
	"Box the float variables of loop loopIndex from their XMM registers into their registers, as SmallFloat64s (their values
	 fit, see genFloatArith:at:site: and genFloatLoopEntryAt:).  Scratch: TempReg, ClassReg."
	0 to: (oilFloatLoopNum at: loopIndex) - 1 do:
		[:index|
		(oilFloatLoopKind at: loopIndex * OilMaxPinnedXmms + index) < 100 ifTrue: "(a variable)"
			[cogit MoveRd: (oilXmmRegs at: OilNumXmms + index) R: ClassReg.
			 cogit oilGenConvertBitsToSmallFloatIn: ClassReg scratch: TempReg.
			 self setDst: (oilFloatLoopVReg at: loopIndex * OilMaxPinnedXmms + index) from: ClassReg]]! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/25/2026 22:30'!
addCandidate: vreg to: candidates count: numCandidates
	"Add register vreg to candidates (if a virtual register not there yet); answer their number, -1 if too many."
	<var: #candidates type: #'sqInt *'>
	numCandidates < 0 ifTrue: [^numCandidates].
	vreg >= OilFlagsReg ifTrue: [^numCandidates].
	0 to: numCandidates - 1 do: [:index| (candidates at: index) = vreg ifTrue: [^numCandidates]].
	numCandidates >= 16 ifTrue: [^-1].
	candidates at: numCandidates put: vreg.
	^numCandidates + 1! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
isFloatVariable: vreg from: loopHead to: backJump candidates: candidates kinds: kinds count: numCandidates
	"Does the loop from loopHead to backJump assign register vreg only float results (not unboxed in a float chain) or moves
	 of float variables (candidates of kind 1 or 2), and read it only as an operand of float instructions or into float
	 variables?"
	<var: #candidates type: #'sqInt *'>
	<var: #kinds type: #'sqInt *'>
	| irOffset opcode |
	irOffset := loopHead.
	[irOffset < backJump] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 opcode = OilMove
			ifTrue:
				[((self fieldAAt: irOffset) = vreg
				  and: [(self isVariableCandidate: (self fieldBAt: irOffset) in: candidates kinds: kinds count: numCandidates) not]) ifTrue: [^false].
				 ((self fieldBAt: irOffset) = vreg
				  and: [(self isVariableCandidate: (self fieldAAt: irOffset) in: candidates kinds: kinds count: numCandidates) not]) ifTrue: [^false]]
			ifFalse:
				[(self isFloatOpcode: opcode)
					ifTrue:
						[((self fieldAAt: irOffset) = vreg
						  and: [opcode ~= OilCmpFloat
						  and: [self flag: irOffset has: OilFloatUnboxed]]) ifTrue: [^false]]
					ifFalse:
						[((self opcodeHasDest: opcode) and: [(self fieldAAt: irOffset) = vreg]) ifTrue: [^false].
						 (self instruction: irOffset reads: vreg) ifTrue: [^false]]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^true! !

!OilInliningCompiler methodsFor: 'float loop registers' stamp: 'cb 10/25/2026 22:30'!
isVariableCandidate: vreg in: candidates kinds: kinds count: numCandidates
	"Is register vreg a candidate float variable (kind 1 or 2)?"
	<var: #candidates type: #'sqInt *'>
	<var: #kinds type: #'sqInt *'>
	0 to: numCandidates - 1 do:
		[:index| ((candidates at: index) = vreg and: [(kinds at: index) = 1 or: [(kinds at: index) = 2]]) ifTrue: [^true]].
	^false! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 22:20'!
genLoopAlignment
	"Pad with nops to the next multiple of OilLoopAlignment (16 bytes), by steps of at most 8 bytes: an AlignmentNops pads
	 with up to alignment - 1 bytes, and an abstract instruction has room for 14 (CogX64Compiler>>machineCodeBytes).  The
	 fall-through into the loop runs the padding.  How the instructions of a loop fall on 16 and 32 byte boundaries changes
	 its speed a lot (up to 1.5 times) from one compilation to another; aligning the headers to 16 bytes makes it faster on
	 average and less erratic."
	| alignment |
	alignment := 8.
	[alignment <= OilLoopAlignment] whileTrue:
		[cogit AlignmentNops: alignment.
		 alignment := alignment * 2]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genCheckBounds: indexReg limit: limitReg site: siteIndex
	"Deoptimize unless index (indexReg) is a SmallInteger with 1 <= index <= limit (limitReg, a tagged size)."
	| indexMach limitMach |
	indexMach := self src: indexReg scratch: TempReg.
	limitMach := self src: limitReg scratch: ClassReg.
	self genTagCheckOf: indexReg in: indexMach site: siteIndex.
	cogit CmpCq: (objectMemory integerObjectOf: 1) R: indexMach.
	self deopt: (cogit JumpLess: 0) site: siteIndex.
	cogit CmpR: limitMach R: indexMach.
	self deopt: (cogit JumpGreater: 0) site: siteIndex! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
singletonForClassTag: tag
	"The only instance of the class of class tag tag if it is UndefinedObject, True or False, else 0."
	tag = (objectMemory fetchClassTagOf: objectMemory nilObject) ifTrue: [^objectMemory nilObject].
	tag = (objectMemory fetchClassTagOf: objectMemory trueObject) ifTrue: [^objectMemory trueObject].
	tag = (objectMemory fetchClassTagOf: objectMemory falseObject) ifTrue: [^objectMemory falseObject].
	^0! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
genGuard: objReg class: classOop site: siteIndex
	"Deoptimize unless the object in objReg is an instance of classOop: a tag test for immediate classes, else a
	 compare of the class index in the header.  A forwarder (class index isForwardedObjectClassIndexPun) fails
	 the guard; the deopt fast path then follows it and resumes here."
	| objMach tag singleton |
	tag := objectMemory classTagForClass: classOop.
	tag = 0 ifTrue: [^self abortCompilation: OilFailBackend].
	objMach := self src: objReg scratch: TempReg.
	tag = objectMemory smallIntegerTag ifTrue:
		[^self genTagCheck: objMach site: siteIndex].
	tag <= objectMemory tagMask ifTrue:
		[cogit MoveR: objMach R: SendNumArgsReg.
		 cogit AndCq: objectMemory tagMask R: SendNumArgsReg.
		 cogit CmpCq: tag R: SendNumArgsReg.
		 ^self deopt: (cogit JumpNonZero: 0) site: siteIndex].
	singleton := self singletonForClassTag: tag.
	singleton ~= 0 ifTrue:
		[cogit CmpCq: singleton R: objMach.
		 ^self deopt: (cogit JumpNonZero: 0) site: siteIndex].
	cogit TstCq: objectMemory tagMask R: objMach.
	self deopt: (cogit JumpNonZero: 0) site: siteIndex.
	tag <= 16rFFFF
		ifTrue:
			[cogit MoveM16: 0 r: objMach R: SendNumArgsReg]
		ifFalse:
			[cogit MoveM32: 0 r: objMach R: SendNumArgsReg.
			 cogit AndCq: objectMemory classIndexMask R: SendNumArgsReg].
	cogit CmpCq: tag R: SendNumArgsReg.
	self deopt: (cogit JumpNonZero: 0) site: siteIndex! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
checkFlagsBranchAt: branchOffset
	"Is the instruction at branchOffset, after a comparison, the branch on the flags that consumes it, and nothing jumps to it
	 (between them)?  Else abort the compilation and answer false."
	(((self opcodeAt: branchOffset) = OilBranchTrue or: [(self opcodeAt: branchOffset) = OilBranchFalse])
	 and: [(self fieldAAt: branchOffset) = OilFlagsReg
	 and: [(oilIRTarget at: branchOffset) = 0]]) ifTrue: [^true].
	self abortCompilation: OilFailBackend.
	^false! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
genCompareAt: irOffset site: siteIndex
	"A comparison (OilCmpTagged/OilCmpImmTagged, condition in field A) always immediately followed by the branch on
	 the flags that consumes it: fuse them into one compare and one conditional jump.  Tagged values compare like
	 the integers they represent.  Answer the index of the instruction after the branch."
	<inline: false>
	| opcode cond leftMach rightMach branchOffset target onTrue tagged jump |
	<var: #jump type: #'AbstractInstruction *'>
	opcode := self opcodeAt: irOffset.
	cond := self fieldAAt: irOffset.
	branchOffset := irOffset + 1.
	(self checkFlagsBranchAt: branchOffset) ifFalse: [^branchOffset].
	onTrue := (self opcodeAt: branchOffset) = OilBranchTrue.
	target := self imm16At: branchOffset.
	leftMach := self src: (self fieldBAt: irOffset) scratch: TempReg.
	opcode = OilCmpImmTagged
		ifTrue:
			[self genTagCheckOf: (self fieldBAt: irOffset) in: leftMach site: siteIndex.
			 tagged := objectMemory integerObjectOf: (self signed8: (self fieldCAt: irOffset)).
			 cogit CmpCq: tagged R: leftMach]
		ifFalse:
			[rightMach := self src: (self fieldCAt: irOffset) scratch: ClassReg.
			 cond < OilCondIdentical ifTrue: [self genTagCheckOf: (self fieldBAt: irOffset) in: leftMach and: (self fieldCAt: irOffset) in: rightMach site: siteIndex].
			 cogit CmpR: rightMach R: leftMach].
	jump := self genJumpOn: cond ifTrue: onTrue.
	self branch: jump to: target.
	^branchOffset + 1! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genJumpOn: cond ifTrue: onTrue
	"Answer a conditional jump taken when (ra cond rb) = onTrue, the flags being those of ra - rb."
	<returnTypeC: #'AbstractInstruction *'>
	cond = OilCondLt ifTrue: [^onTrue ifTrue: [cogit JumpLess: 0] ifFalse: [cogit JumpGreaterOrEqual: 0]].
	cond = OilCondGt ifTrue: [^onTrue ifTrue: [cogit JumpGreater: 0] ifFalse: [cogit JumpLessOrEqual: 0]].
	cond = OilCondLe ifTrue: [^onTrue ifTrue: [cogit JumpLessOrEqual: 0] ifFalse: [cogit JumpGreater: 0]].
	cond = OilCondGe ifTrue: [^onTrue ifTrue: [cogit JumpGreaterOrEqual: 0] ifFalse: [cogit JumpLess: 0]].
	(cond = OilCondEq or: [cond = OilCondIdentical]) ifTrue: [^onTrue ifTrue: [cogit JumpZero: 0] ifFalse: [cogit JumpNonZero: 0]].
	^onTrue ifTrue: [cogit JumpNonZero: 0] ifFalse: [cogit JumpZero: 0]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genBranchOnBoolean: boolReg ifTrue: onTrue to: target site: siteIndex
	"A branch on a boolean in a register (not on the flags): deoptimize (mustBeBoolean) on a non-boolean."
	| boolMach jmpTarget |
	<var: #jmpTarget type: #'AbstractInstruction *'>
	boolReg = OilFlagsReg ifTrue: "flags are always consumed by genCompareAt:site:"
		[^self abortCompilation: OilFailBackend].
	boolMach := self src: boolReg scratch: TempReg.
	cogit genMoveConstant: (onTrue ifTrue: [objectMemory trueObject] ifFalse: [objectMemory falseObject]) R: ClassReg.
	cogit CmpR: ClassReg R: boolMach.
	jmpTarget := cogit JumpZero: 0.
	self branch: jmpTarget to: target.
	cogit genMoveConstant: (onTrue ifTrue: [objectMemory falseObject] ifFalse: [objectMemory trueObject]) R: ClassReg.
	cogit CmpR: ClassReg R: boolMach.
	self deopt: (cogit JumpNonZero: 0) site: siteIndex! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genReturn: valueReg
	| returnMach |
	returnMach := self src: valueReg scratch: ReceiverResultReg.
	returnMach ~= ReceiverResultReg ifTrue: [cogit MoveR: returnMach R: ReceiverResultReg].
	cogit oilGenReturnFrom: (self numArgsOf: oilHomeMethod)! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
selectorIndexOf: selector
	"The inline cache of a send holds the index of its selector, in the literals of the method (the root), negative,
	 in the special selectors, or OilExtraSelectorBase + its index in the Oil selector table (see
	 ProfilingCogit>>oilExtraSelectorIndexOf:add:).  Answer that index, or OilNoLink if the selector is in none."
	0 to: 31 do:
		[:litIndex| (coInterpreter specialSelector: litIndex) = selector ifTrue: [^-1 - litIndex]].
	0 to: (objectMemory literalCountOf: oilHomeMethod) - 1 do:
		[:litIndex| (coInterpreter literal: litIndex ofMethod: oilHomeMethod) = selector ifTrue: [^litIndex]].
	^cogit oilExtraSelectorIndexOf: selector add: true! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 09:30'!
genCallAt: irOffset site: siteIndex
	"An uninlined send, through the Cogit's inline cache and PIC machinery."
	<inline: false>
	| opcode numArgs isSuper |
	opcode := self opcodeAt: irOffset.
	numArgs := opcode = OilCall0 ifTrue: [0] ifFalse: [opcode = OilCall1 ifTrue: [1] ifFalse: [self fieldCAt: irOffset]].
	isSuper := opcode = OilCallSuper or: [opcode = OilCallDirectedSuper].
	"An OilCallSuper binds to the method class of the frame's method, which must be the root method's (an
	 OilCallDirectedSuper names its class)."
	(opcode = OilCallSuper and: [siteIndex < 0 or: [(siteFrame at: siteIndex) ~= 0]]) ifTrue:
		[^self abortCompilation: OilFailBackend].
	self genSendAt: irOffset numArgs: numArgs super: isSuper! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 09:30'!
genSendAt: irOffset numArgs: numArgs super: isSuper
	"Spill everything (the callee may run the GC, which scans and updates the spill slots), marshal the receiver and
	 arguments like the baseline JIT (registers for up to numRegArgs arguments, else pushed), call the send
	 trampoline (linked later to the target method or a PIC), store the result and reload.  An OilCallDirectedSuper
	 passes its method class to the directed super send trampoline."
	<inline: false>
	| destReg receiverReg selIndex methodClass |
	destReg := self fieldAAt: irOffset.
	receiverReg := self fieldBAt: irOffset.
	selIndex := self selectorIndexOf: (self word64At: irOffset + 1).
	selIndex = OilNoLink ifTrue:
		[^self abortCompilation: OilFailBackend].
	self spillAll.
	numArgs <= cogit numRegArgs
		ifTrue:
			[numArgs >= 1 ifTrue: [cogit MoveMw: (oilVRegSpillTemp at: (self callArg: 0 at: irOffset)) r: FPReg R: Arg0Reg].
			 numArgs >= 2 ifTrue: [cogit MoveMw: (oilVRegSpillTemp at: (self callArg: 1 at: irOffset)) r: FPReg R: Arg1Reg]]
		ifFalse:
			[cogit MoveMw: (oilVRegSpillTemp at: receiverReg) r: FPReg R: TempReg.
			 cogit PushR: TempReg.
			 0 to: numArgs - 1 do:
				[:argIndex|
				cogit MoveMw: (oilVRegSpillTemp at: (self callArg: argIndex at: irOffset)) r: FPReg R: TempReg.
				cogit PushR: TempReg]].
	cogit MoveMw: (oilVRegSpillTemp at: receiverReg) r: FPReg R: ReceiverResultReg.
	methodClass := (self opcodeAt: irOffset) = OilCallDirectedSuper ifTrue: [self word64At: irOffset + 3] ifFalse: [0].
	cogit oilGenSend: selIndex numArgs: numArgs super: isSuper above: methodClass.
	self noteCallSiteAt: irOffset.
	cogit MoveR: ReceiverResultReg Mw: (oilVRegSpillTemp at: destReg) r: FPReg.
	self reloadAll! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
noteCallSiteAt: irOffset
	"The call at irOffset was just emitted.  If its send has a deopt site with a state, record the site in the metadata
	 (oilSiteUsed 2: no deopt stub) with the return address of the call as its resume address, so that a frame suspended in
	 the call maps to the activations it stands for at the send (see CoInterpreter>>oilDeoptimizeFrame:context: and
	 primitiveOilContexts).  All the registers are in their spill slots during the call (see genSendAt:numArgs:super:)."
	| siteIndex |
	(self isSendOpcode: (self opcodeAt: irOffset)) ifFalse: [^self].
	siteIndex := oilIRSite at: irOffset.
	(siteIndex >= 0 and: [self siteHasState: siteIndex]) ifFalse: [^self].
	self setScanMethod: (self frameAt: (siteFrame at: siteIndex)) method.
	self decodeAt: (sitePC at: siteIndex).
	(opcodeTag = OilTagSend or: [opcodeTag = OilTagSendSuper or: [opcodeTag = OilTagSendSpecial]]) ifFalse: [^self].
	oilSiteResume at: siteIndex put: cogit Label.
	(oilSiteUsed at: siteIndex) = 0 ifTrue:
		[oilSiteUsed at: siteIndex put: 2]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
callArg: argIndex at: irOffset
	"The register of argument argIndex (0-based) of the call at irOffset."
	| opcode |
	opcode := self opcodeAt: irOffset.
	(opcode = OilCall1 or: [opcode = OilStreamNextPut or: [opcode = OilStringHash]]) ifTrue: [^self fieldCAt: irOffset].
	^self packedArg: argIndex at: irOffset! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
genDeoptStubs
	"After the body: one stub per deopt site used, passing the site index, and the common deoptimization sequence:
	 spill everything (the deoptimizer reads the virtual registers from their spill slots), call ceOilDeoptTrampoline,
	 which either deoptimizes the frame and continues in the interpreter (it does not return), or, having
	 unforwarded the object a class guard failed on, answers the address of the guard to resume at."
	| stub common |
	<var: #stub type: #'AbstractInstruction *'>
	<var: #common type: #'AbstractInstruction *'>
	(oilNumStubJumps = 0 and: [oilNumUndos = 0]) ifTrue: [^self].
	common := cogit Label.
	self spillAll.
	cogit MoveR: TempReg R: SendNumArgsReg.
	cogit oilGenDeoptCall.
	self reloadAll.
	cogit JumpR: TempReg.
	0 to: numSites - 1 do:
		[:siteIndex|
		(oilSiteUsed at: siteIndex) = 1 ifTrue: "(not the call sites, see noteCallSiteAt:)"
			[stub := cogit Label.
			 (oilSiteFloatLoop at: siteIndex) > 0 ifTrue: "in a loop with float registers: box its float variables first"
				[self genBoxFloatLoopVariables: (oilSiteFloatLoop at: siteIndex) - 1].
			 cogit MoveCq: siteIndex R: TempReg.
			 oilSiteStub at: siteIndex put: stub.
			 cogit Jump: common]].
	0 to: oilNumStubJumps - 1 do:
		[:jumpIndex| (oilStubJump at: jumpIndex) jmpTarget: (oilSiteStub at: (oilStubSite at: jumpIndex))].
	"The undo stubs of the in-place tagged adds: reg := reg - src, then the site's stub."
	0 to: oilNumUndos - 1 do:
		[:undoIndex|
		stub := cogit SubR: (oilUndoSrc at: undoIndex) R: (oilUndoReg at: undoIndex).
		(cogit Jump: 0) jmpTarget: (oilSiteStub at: (oilUndoSite at: undoIndex)).
		(oilUndoJump at: undoIndex) jmpTarget: stub]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
oilFailureCode
	"(Named so as not to clash in C with the failureCode variable.)"
	<inline: true>
	^failureCode! !

!OilInliningCompiler methodsFor: 'debugging' stamp: 'cb 10/25/2026 00:45'!
oilDebugInfo: what at: index
	"For primitiveOilLastCompilation: 0 failure code, 1 IR size, 2 IR word, 3 eager closures,
	 4 failed IR index, 5 sites, 6 frames, 7 spill slots, 8 allocated regs, 9 metadata bytes, 11/12 Pass 1 IR, 13 Pass 2 stats."
	<api>
	what = 0 ifTrue: [^failureCode].
	what = 1 ifTrue: [^irIndex].
	what = 2 ifTrue: [^(index between: 0 and: irIndex - 1) ifTrue: [oilIRBuffer at: index] ifFalse: [0]].
	what = 3 ifTrue: [^eagerClosures ifTrue: [1] ifFalse: [0]].
	what = 4 ifTrue: [^oilFailIndex].
	what = 5 ifTrue: [^numSites].
	what = 6 ifTrue: [^numFrames].
	what = 7 ifTrue: [^oilNumSpillTemps].
	what = 8 ifTrue: [^oilNumAllocRegs].
	what = 9 ifTrue: [^self metadataObjectBytes].
	what = 11 ifTrue: [^oilPass1Words].
	what = 12 ifTrue: [^(index between: 0 and: oilPass1Words - 1) ifTrue: [oilIRBuffer1 at: index] ifFalse: [0]].
	what = 13 ifTrue: [^self pass2Statistics: index].
	^0! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
analyzeTaggedRegisters
	"A virtual register all of whose definitions produce SmallIntegers (tagged arithmetic, tagged constants, sizes, or
	 moves of such registers) always holds a SmallInteger (before its first definition it holds the SmallInteger 0 the
	 prologue initializes it to; incoming arguments are excluded): its tag checks can be omitted.  E.g. a loop
	 index (ConstTagged, then AddImmTagged) or an accumulator.  Flow insensitive, iterated to a fixpoint for moves."
	| irOffset opcode destReg changed numArgs |
	numArgs := self numArgsOf: oilHomeMethod.
	0 to: OilNumRegs - 1 do:
		[:vreg| oilTagged at: vreg put: ((vreg > numArgs and: [vreg < OilFlagsReg]) ifTrue: [1] ifFalse: [0])].
	changed := true.
	[changed] whileTrue:
		[changed := false.
		 irOffset := 0.
		 [irOffset < irIndex] whileTrue:
			[opcode := self opcodeAt: irOffset.
			 destReg := self fieldAAt: irOffset.
			 ((self opcodeHasDest: opcode)
			  and: [(oilTagged at: destReg) ~= 0
			  and: [(self definitionIsTaggedAt: irOffset) not]]) ifTrue:
				[oilTagged at: destReg put: 0.
				 changed := true].
			 irOffset := irOffset + (self instructionLengthAt: irOffset)]]! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
definitionIsTaggedAt: irOffset
	"Does the instruction at irOffset (which has a destination) always produce a SmallInteger?"
	| opcode |
	opcode := self opcodeAt: irOffset.
	opcode = OilConst64 ifTrue: [^self isSmallIntegerHandle: (self word64At: irOffset + 1)].
	opcode = OilMove ifTrue: [^(oilTagged at: (self fieldBAt: irOffset)) ~= 0].
	^self opcode: opcode has: OilOpTagged! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:45'!
isTagged: virtualReg
	<inline: true>
	^(oilTagged at: virtualReg) ~= 0! !


!OilInliningCompiler methodsFor: 'float code generation' stamp: 'cb 10/25/2026 02:00'!
resetXmms
	"Forget the values of the XMM registers (at a label, or before a call that clobbers them)."
	0 to: OilNumXmms - 1 do: [:xmmIndex| oilXmmVReg at: xmmIndex put: -1]! !

!OilInliningCompiler methodsFor: 'float code generation' stamp: 'cb 10/26/2026 20:30'!
mayClobberXmms: opcode
	"May the instruction call out (C calls clobber the XMM registers), or resume after a deopt (a guard)?  (OilModTagged:
	 its division may use DPFPReg0 and DPFPReg1.)"
	<inline: true>
	^self opcode: opcode has: OilOpClobbersXmms! !

!OilInliningCompiler methodsFor: 'float code generation' stamp: 'cb 10/25/2026 02:00'!
forgetXmmsOf: virtualReg
	"virtualReg is assigned: an XMM register no longer holds its value."
	<inline: true>
	0 to: OilNumXmms - 1 do:
		[:xmmIndex| (oilXmmVReg at: xmmIndex) = virtualReg ifTrue: [oilXmmVReg at: xmmIndex put: -1]]! !

!OilInliningCompiler methodsFor: 'float code generation' stamp: 'cb 10/25/2026 02:00'!
allocXmmExcept: busyXmm and: otherBusyXmm
	"Answer the index of a free XMM register, or of one caching a boxed value (whose cache is dropped), other than
	 busyXmm and otherBusyXmm.  OilFullCompiler>>fuseFloats bounds the unboxed values of a chain so that one exists."
	0 to: OilNumXmms - 1 do:
		[:xmmIndex|
		((oilXmmVReg at: xmmIndex) < 0 and: [xmmIndex ~= busyXmm and: [xmmIndex ~= otherBusyXmm]]) ifTrue: [^xmmIndex]].
	0 to: OilNumXmms - 1 do:
		[:xmmIndex|
		((oilXmmKind at: xmmIndex) >= 0 and: [xmmIndex ~= busyXmm and: [xmmIndex ~= otherBusyXmm]]) ifTrue:
			[oilXmmVReg at: xmmIndex put: -1.
			 ^xmmIndex]].
	self abortCompilation: OilFailBackend.
	^0! !

!OilInliningCompiler methodsFor: 'float code generation' stamp: 'cb 10/25/2026 02:00'!
xmmFor: virtualReg ints: intMode except: busyXmm site: siteIndex
	"Answer the index of an XMM register holding the double value of virtualReg: the one of an unboxed result of
	 the chain or the one caching it, if that was loaded checking the same (oilXmmKind), or else load it (see
	 genLoadDouble:into:ints:site:) and cache it until virtualReg is assigned or the cache is reset."
	| xmmIndex kind |
	(oilFloatLoopCurrent >= 0 and: [(oilXmmPinned at: virtualReg) >= 0]) ifTrue: "a float variable of the loop (or an invariant)"
		[^oilXmmPinned at: virtualReg].
	0 to: OilNumXmms - 1 do:
		[:index|
		kind := oilXmmKind at: index.
		((oilXmmVReg at: index) = virtualReg and: [kind <= 0 or: [kind = intMode]]) ifTrue: [^index]].
	xmmIndex := self allocXmmExcept: busyXmm and: busyXmm.
	self genLoadDouble: virtualReg into: (oilXmmRegs at: xmmIndex) ints: intMode site: siteIndex.
	oilXmmVReg at: xmmIndex put: virtualReg.
	oilXmmKind at: xmmIndex put: intMode.
	^xmmIndex! !

!OilInliningCompiler methodsFor: 'float code generation' stamp: 'cb 10/25/2026 02:00'!
genLoadDouble: virtualReg into: dpReg ints: intMode site: siteIndex
	"Load the value of virtualReg into dpReg if it is a SmallFloat64 or a BoxedFloat64, or, if intMode > 0, a SmallInteger
	 (converted like the interpreter does; if intMode = 2, only if it is exactly representable, |n| < 2^53, as a comparison
	 must be exact).  Otherwise deoptimize.  Scratch: TempReg, ClassReg, SendNumArgsReg."
	| reg jumpNotSmallFloat jumpNotInt jumpSmallFloatDone jumpIntDone done |
	<var: #jumpNotSmallFloat type: #'AbstractInstruction *'>
	<var: #jumpNotInt type: #'AbstractInstruction *'>
	<var: #jumpSmallFloatDone type: #'AbstractInstruction *'>
	<var: #jumpIntDone type: #'AbstractInstruction *'>
	<var: #done type: #'AbstractInstruction *'>
	reg := self src: virtualReg scratch: TempReg.
	cogit TstCq: objectMemory smallFloatTag R: reg.
	jumpNotSmallFloat := cogit JumpZero: 0.
	cogit oilGenGetSmallFloatValueOf: reg scratch: ClassReg into: dpReg.
	jumpSmallFloatDone := cogit Jump: 0.
	jumpNotSmallFloat jmpTarget: cogit Label.
	intMode > 0 ifTrue:
		[cogit TstCq: objectMemory smallIntegerTag R: reg.
		 jumpNotInt := cogit JumpZero: 0.
		 cogit MoveR: reg R: ClassReg.
		 cogit ArithmeticShiftRightCq: objectMemory numTagBits R: ClassReg.
		 intMode = 2 ifTrue: "n >> 53 must be 0 or -1"
			[cogit MoveR: ClassReg R: SendNumArgsReg.
			 cogit ArithmeticShiftRightCq: 53 R: SendNumArgsReg.
			 cogit AddCq: 1 R: SendNumArgsReg.
			 cogit CmpCq: 1 R: SendNumArgsReg.
			 self deopt: (cogit JumpAbove: 0) site: siteIndex].
		 cogit ConvertR: ClassReg Rd: dpReg.
		 jumpIntDone := cogit Jump: 0.
		 jumpNotInt jmpTarget: cogit Label].
	"a BoxedFloat64"
	cogit TstCq: objectMemory tagMask R: reg.
	self deopt: (cogit JumpNonZero: 0) site: siteIndex.
	cogit MoveM16: 0 r: reg R: ClassReg.
	cogit CmpCq: ClassFloatCompactIndex R: ClassReg.
	self deopt: (cogit JumpNonZero: 0) site: siteIndex.
	cogit MoveM64: objectMemory baseHeaderSize r: reg Rd: dpReg.
	done := cogit Label.
	jumpSmallFloatDone jmpTarget: done.
	intMode > 0 ifTrue: [jumpIntDone jmpTarget: done]! !

!OilInliningCompiler methodsFor: 'float code generation' stamp: 'cb 10/25/2026 02:00'!
genBoxDouble: dpReg into: destReg site: siteIndex
	"destReg := the Float of value dpReg: a SmallFloat64 if in range, else a new BoxedFloat64 (allocated in eden, see
	 genAllocate:header:site:).  Scratch: TempReg, ClassReg."
	| jumpNotSmallFloat jumpDone |
	<var: #jumpNotSmallFloat type: #'AbstractInstruction *'>
	<var: #jumpDone type: #'AbstractInstruction *'>
	cogit MoveRd: dpReg R: ClassReg.
	jumpNotSmallFloat := cogit oilGenJumpNotSmallFloatValueBits: ClassReg scratch: TempReg.
	cogit oilGenConvertBitsToSmallFloatIn: ClassReg scratch: TempReg.
	jumpDone := cogit Jump: 0.
	jumpNotSmallFloat jmpTarget: cogit Label.
	self genAllocate: (objectMemory smallObjectBytesForSlots: 1)
		header: (objectMemory headerForSlots: 1 format: objectMemory firstLongFormat classIndex: ClassFloatCompactIndex)
		site: siteIndex.
	cogit MoveRd: dpReg M64: objectMemory baseHeaderSize r: ClassReg.
	jumpDone jmpTarget: cogit Label.
	self setDst: destReg from: ClassReg! !

!OilInliningCompiler methodsFor: 'float code generation' stamp: 'cb 10/26/2026 20:30'!
genFloatArith: opcode at: irOffset site: siteIndex
	"[OilAddFloat..OilDivFloat | Dest | Rcvr | Arg]: compute in an XMM register (a zero divisor deoptimizes, like the
	 primitive fails), then box the result into Dest (the XMM register caches it), or, in a float chain, leave it there
	 if it is OilFloatUnboxed."
	| destReg rcvrXmm argXmm resultXmm resultReg argReg |
	destReg := self fieldAAt: irOffset.
	rcvrXmm := self xmmFor: (self fieldBAt: irOffset) ints: 0 except: -1 site: siteIndex.
	argXmm := self xmmFor: (self fieldCAt: irOffset) ints: 1 except: rcvrXmm site: siteIndex.
	argReg := oilXmmRegs at: argXmm.
	opcode = OilDivFloat ifTrue: "+0.0 or -0.0: all bits but the sign are 0"
		[cogit MoveRd: argReg R: TempReg.
		 cogit LogicalShiftLeftCq: 1 R: TempReg.
		 cogit CmpCq: 0 R: TempReg.
		 self deopt: (cogit JumpZero: 0) site: siteIndex].
	resultXmm := self allocXmmExcept: rcvrXmm and: argXmm.
	resultReg := oilXmmRegs at: resultXmm.
	cogit MoveRd: (oilXmmRegs at: rcvrXmm) Rd: resultReg.
	opcode = OilAddFloat ifTrue: [cogit AddRd: argReg Rd: resultReg].
	opcode = OilSubFloat ifTrue: [cogit SubRd: argReg Rd: resultReg].
	opcode = OilMulFloat ifTrue: [cogit MulRd: argReg Rd: resultReg].
	opcode = OilDivFloat ifTrue: [cogit DivRd: argReg Rd: resultReg].
	(oilFloatLoopCurrent >= 0 and: [(oilXmmPinned at: destReg) >= 0]) ifTrue:
		["A float variable of the loop: no boxing, but its values must fit a SmallFloat64 (else deoptimize, the old value
		  still in its register), so that it can be boxed without allocating at the exits and deopts."
		 cogit MoveRd: resultReg R: ClassReg.
		 self deopt: (cogit oilGenJumpNotSmallFloatValueBits: ClassReg scratch: TempReg) site: siteIndex.
		 cogit MoveRd: resultReg Rd: (oilXmmRegs at: (oilXmmPinned at: destReg)).
		 ^self forgetXmmsOf: destReg].
	(self flag: irOffset has: OilFloatUnboxed)
		ifTrue: [self forgetXmmsOf: destReg]
		ifFalse: [self genBoxDouble: resultReg into: destReg site: siteIndex].
	oilXmmVReg at: resultXmm put: destReg.
	oilXmmKind at: resultXmm put: ((self flag: irOffset has: OilFloatUnboxed) ifTrue: [-1] ifFalse: [0])! !

!OilInliningCompiler methodsFor: 'float code generation' stamp: 'cb 10/26/2026 20:30'!
genFloatCompareAt: irOffset site: siteIndex
	"[OilCmpFloat | Cond | Rcvr | Arg] and the branch on the flags that follows it (see genCompareAt:site:).  The
	 Cogit's floating point jumps are false on unordered operands (NaNs), so a branch on false jumps over a jump."
	<inline: false>
	| cond branchOffset target rcvrXmm argXmm jump |
	<var: #jump type: #'AbstractInstruction *'>
	cond := self fieldAAt: irOffset.
	branchOffset := irOffset + 1.
	(self checkFlagsBranchAt: branchOffset) ifFalse: [^branchOffset].
	target := self imm16At: branchOffset.
	rcvrXmm := self xmmFor: (self fieldBAt: irOffset) ints: 0 except: -1 site: siteIndex.
	argXmm := self xmmFor: (self fieldCAt: irOffset) ints: 2 except: rcvrXmm site: siteIndex.
	cogit CmpRd: (oilXmmRegs at: argXmm) Rd: (oilXmmRegs at: rcvrXmm).
	jump := cond = OilCondLt ifTrue: [cogit JumpFPLess: 0]
			ifFalse: [cond = OilCondGt ifTrue: [cogit JumpFPGreater: 0]
			ifFalse: [cond = OilCondLe ifTrue: [cogit JumpFPLessOrEqual: 0]
			ifFalse: [cond = OilCondGe ifTrue: [cogit JumpFPGreaterOrEqual: 0]
			ifFalse: [cond = OilCondEq ifTrue: [cogit JumpFPEqual: 0]
			ifFalse: [cogit JumpFPNotEqual: 0]]]]].
	(self opcodeAt: branchOffset) = OilBranchTrue
		ifTrue: [self branch: jump to: target]
		ifFalse:
			[self branch: (cogit Jump: 0) to: target.
			 jump jmpTarget: cogit Label].
	^branchOffset + 1! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
genNewObjectAt: irOffset site: siteIndex
	"[OilNewObject|Dest|FirstSlot|NumSlots] class: a scalar replaced object that escapes.  Allocate an instance of the class
	 in eden, and store its slots from their registers: no nil filling first, and no store check (it is young)."
	| destReg firstReg numSlots classOop classIndex |
	destReg := self fieldAAt: irOffset.
	firstReg := self fieldBAt: irOffset.
	numSlots := self fieldCAt: irOffset.
	classOop := self word64At: irOffset + 1.
	classIndex := coInterpreter oilApiClassIndexOfClass: classOop.
	(classIndex <= 0 or: [numSlots >= objectMemory numSlotsMask]) ifTrue:
		[^self abortCompilation: OilFailBackend].
	"The class may have been reshaped (or become another) since: check that it still has the format and the class index
	 compiled in (its oop, a literal, is updated by the GC), else deoptimize and let the interpreter allocate."
	cogit genMoveConstant: classOop R: TempReg.
	cogit MoveMw: InstanceSpecificationIndex * objectMemory wordSize + objectMemory baseHeaderSize r: TempReg R: SendNumArgsReg.
	cogit CmpCq: (coInterpreter oilApiFormatOfClass: classOop) R: SendNumArgsReg.
	self deopt: (cogit JumpNonZero: 0) site: siteIndex.
	cogit oilGenGetHashOf: TempReg into: SendNumArgsReg.
	cogit CmpCq: (objectMemory integerObjectOf: classIndex) R: SendNumArgsReg.
	self deopt: (cogit JumpNonZero: 0) site: siteIndex.
	self genAllocate: (objectMemory smallObjectBytesForSlots: numSlots)
		header: (objectMemory
					headerForSlots: numSlots
					format: (coInterpreter oilApiInstSpecOfClass: classOop)
					classIndex: classIndex)
		site: siteIndex.
	self genStoreSlots: numSlots from: firstReg at: 0.
	self setDst: destReg from: ClassReg! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 09:30'!
genClassTagOf: objReg into: destReg
	"destReg := the class tag of the object in objReg: its tag bits if it is an immediate (they are the class indices of
	 the immediate classes), else the class index in its header."
	| jumpImmediate |
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	cogit MoveR: objReg R: destReg.
	cogit AndCq: objectMemory tagMask R: destReg.
	jumpImmediate := cogit JumpNonZero: 0.
	cogit MoveM16: 0 r: objReg R: destReg.
	jumpImmediate jmpTarget: cogit Label! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
genCmpClassAt: irOffset
	"[OilCmpClass|Cond|Reg|0] class, always followed by the branch on the flags that consumes it (like genCompareAt:site:):
	 compare the class tag of Reg with the class's, and branch.  Answer the index of the instruction after the branch."
	<inline: false>
	| cond branchOffset target onTrue tag jump objMach singleton |
	<var: #jump type: #'AbstractInstruction *'>
	cond := self fieldAAt: irOffset.
	branchOffset := irOffset + (self instructionLengthAt: irOffset).
	(self checkFlagsBranchAt: branchOffset) ifFalse: [^branchOffset].
	tag := objectMemory classTagForClass: (self word64At: irOffset + 1).
	tag = 0 ifTrue:
		[self abortCompilation: OilFailBackend.
		 ^branchOffset].
	onTrue := (self opcodeAt: branchOffset) = OilBranchTrue.
	target := self imm16At: branchOffset.
	objMach := self src: (self fieldBAt: irOffset) scratch: TempReg.
	singleton := self singletonForClassTag: tag.
	singleton ~= 0
		ifTrue: [cogit CmpCq: singleton R: objMach]
		ifFalse:
			[self genClassTagOf: objMach into: SendNumArgsReg.
			 cogit CmpCq: tag R: SendNumArgsReg].
	jump := self genJumpOn: cond ifTrue: onTrue.
	self branch: jump to: target.
	^branchOffset + 1! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 09:30'!
genGuard2At: irOffset site: siteIndex
	"[OilGuardClass2|Reg|Site16] class1 class2: deoptimize unless Reg is an instance of one of the two classes."
	| tag1 tag2 tagNil tagTrue tagFalse tagSmi jumpOK |
	<var: #jumpOK type: #'AbstractInstruction *'>
	tag1 := objectMemory classTagForClass: (self word64At: irOffset + 1).
	tag2 := objectMemory classTagForClass: (self word64At: irOffset + 3).
	(tag1 = 0 or: [tag2 = 0]) ifTrue: [^self abortCompilation: OilFailBackend].
	tagSmi := objectMemory smallIntegerTag.
	(tag1 = tagSmi or: [tag2 = tagSmi]) ifTrue:
		[| otherClass objMach |
		 otherClass := tag1 = tagSmi ifTrue: [self word64At: irOffset + 3] ifFalse: [self word64At: irOffset + 1].
		 objMach := self src: (self fieldAAt: irOffset) scratch: TempReg.
		 cogit TstCq: objectMemory smallIntegerTag R: objMach.
		 jumpOK := cogit JumpNonZero: 0.
		 self genGuard: (self fieldAAt: irOffset) class: otherClass site: siteIndex.
		 jumpOK jmpTarget: cogit Label.
		 ^self].
	tagNil := objectMemory fetchClassTagOf: objectMemory nilObject.
	(tag1 = tagNil or: [tag2 = tagNil]) ifTrue:
		[| otherClass objMach |
		 otherClass := tag1 = tagNil ifTrue: [self word64At: irOffset + 3] ifFalse: [self word64At: irOffset + 1].
		 objMach := self src: (self fieldAAt: irOffset) scratch: TempReg.
		 cogit CmpCq: objectMemory nilObject R: objMach.
		 jumpOK := cogit JumpZero: 0.
		 self genGuard: (self fieldAAt: irOffset) class: otherClass site: siteIndex.
		 jumpOK jmpTarget: cogit Label.
		 ^self].
	tagTrue := objectMemory fetchClassTagOf: objectMemory trueObject.
	tagFalse := objectMemory fetchClassTagOf: objectMemory falseObject.
	((tag1 = tagTrue and: [tag2 = tagFalse]) or: [tag1 = tagFalse and: [tag2 = tagTrue]]) ifTrue:
		[| objMach |
		 objMach := self src: (self fieldAAt: irOffset) scratch: TempReg.
		 cogit CmpCq: objectMemory trueObject R: objMach.
		 jumpOK := cogit JumpZero: 0.
		 cogit CmpCq: objectMemory falseObject R: objMach.
		 self deopt: (cogit JumpNonZero: 0) site: siteIndex.
		 jumpOK jmpTarget: cogit Label.
		 ^self].
	self genClassTagOf: (self src: (self fieldAAt: irOffset) scratch: TempReg) into: SendNumArgsReg.
	cogit CmpCq: tag1 R: SendNumArgsReg.
	jumpOK := cogit JumpZero: 0.
	cogit CmpCq: tag2 R: SendNumArgsReg.
	self deopt: (cogit JumpNonZero: 0) site: siteIndex.
	jumpOK jmpTarget: cogit Label! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/26/2026 20:30'!
genStringHashAt: i
	"[OilStringHash|Dest|Rcvr|InitialHash] selector: primitiveStringHash (String>>hashWithInitialHash:) of Rcvr, a byte object
	 (its class is known): if InitialHash is a SmallInteger h, h := (h + byte) * 16r19660D for each byte, answer
	 h bitAnd: 16r0FFFFFFF (the low 28 bits only depend on the low bits, so 64-bit arithmetic gives the 32-bit result of
	 the primitive).  Otherwise send the message.  Registers: Extra0Reg the address of the current byte, Extra1Reg the end
	 address (their virtual registers are spilled around), SendNumArgsReg h, ClassReg the multiplier, TempReg the byte."
	| rcvrMach initMach jumpNotInt loop jumpDone jumpEnd |
	<var: #jumpNotInt type: #'AbstractInstruction *'>
	<var: #loop type: #'AbstractInstruction *'>
	<var: #jumpDone type: #'AbstractInstruction *'>
	<var: #jumpEnd type: #'AbstractInstruction *'>
	initMach := self src: (self fieldCAt: i) scratch: ClassReg.
	cogit TstCq: objectMemory smallIntegerTag R: initMach.
	jumpNotInt := cogit JumpZero: 0.
	cogit MoveR: initMach R: SendNumArgsReg.
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: SendNumArgsReg.
	rcvrMach := self src: (self fieldBAt: i) scratch: TempReg.
	self spillExtraRegs.
	rcvrMach ~= Extra0Reg ifTrue: [cogit MoveR: rcvrMach R: Extra0Reg].
	cogit oilGenGetNumBytesOf: Extra0Reg into: Extra1Reg.
	cogit AddR: Extra0Reg R: Extra1Reg.
	cogit AddCq: objectMemory baseHeaderSize R: Extra1Reg.
	cogit AddCq: objectMemory baseHeaderSize R: Extra0Reg.
	cogit MoveCq: 16r19660D R: ClassReg.
	loop := cogit CmpR: Extra1Reg R: Extra0Reg.
	jumpEnd := cogit JumpAboveOrEqual: 0.
	cogit MoveCq: 0 R: TempReg.
	cogit MoveMb: 0 r: Extra0Reg R: TempReg.
	cogit AddR: TempReg R: SendNumArgsReg.
	cogit backEnd genMulR: ClassReg R: SendNumArgsReg.
	cogit AddCq: 1 R: Extra0Reg.
	cogit Jump: loop.
	jumpEnd jmpTarget: (cogit AndCq: 16r0FFFFFFF R: SendNumArgsReg).
	cogit LogicalShiftLeftCq: objectMemory numTagBits R: SendNumArgsReg.
	cogit OrCq: objectMemory smallIntegerTag R: SendNumArgsReg.
	self reloadExtraRegs.
	self setDst: (self fieldAAt: i) from: SendNumArgsReg.
	jumpDone := cogit Jump: 0.
	jumpNotInt jmpTarget: cogit Label.
	self genSendAt: i numArgs: 1 super: false.
	jumpDone jmpTarget: cogit Label! !
