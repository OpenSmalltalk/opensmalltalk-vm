"Oil Milestone 3: Pass 3 of OilCompiler, the native back end.  It translates the linear IR produced by Pass 1
 into the Cogit's abstract instructions (CogAbstractInstruction), which the Cogit then assembles into a CogMethod.
 See ProfilingCogit>>oilCog:receiverClass: (oil/oil-m3-native-backend.st) for the driver.  Author: cb."!

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
prepareNativeCode
	"Pass 3, step 1.  Analyse the IR: branch targets, loop nesting, the deopt site of each instruction.
	 Weigh every virtual register by its uses, ten times more per loop nesting level, give the heaviest ones
	 machine registers and every live virtual register a home slot in the frame (where it is spilled around
	 calls and bailouts; the GC scans it, so it always holds an object).  Answer OilOK or a failure code."
	| i op t n best bestWeight homeBase |
	oilFailIndex := -2.
	failed ifTrue: [^failureCode].
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
	0 to: OilNumRegs - 1 do:
		[:r|
		oilVRegWeight at: r put: 0.
		oilVRegReg at: r put: NoReg.
		oilVRegHome at: r put: 0].
	0 to: irIndex do:
		[:j|
		oilIRTarget at: j put: 0.
		oilLoopDepth at: j put: 0.
		oilIRSite at: j put: -1.
		oilIRLabel at: j put: nil].
	0 to: OilMaxSites - 1 do:
		[:s|
		oilSiteUsed at: s put: 0.
		oilSiteResume at: s put: nil.
		oilSiteStub at: s put: nil].
	oilNumFixups := oilNumStubJumps := oilNumUndos := 0.
	oilBailoutCommon := nil.
	0 to: numSites - 1 do:
		[:s| (siteIR at: s) >= 0 ifTrue: [oilIRSite at: (siteIR at: s) put: s]].
	"Branch targets, loops (a backward branch closes a loop) and supported opcodes."
	i := 0.
	[i < irIndex] whileTrue:
		[op := self opcodeAt: i.
		 (op = OilJump or: [op = OilBranchTrue or: [op = OilBranchFalse]]) ifTrue:
			[t := self imm16At: i.
			 t > irIndex ifTrue:
				[self abortCompilation: OilFailInternal.
				 ^failureCode].
			 oilIRTarget at: t put: 1.
			 t <= i ifTrue:
				[t to: i do: [:j| oilLoopDepth at: j put: ((oilLoopDepth at: j) + 1 min: 3)]]].
		 i := i + (self instructionLengthAt: i)].
	i := 0.
	[i < irIndex] whileTrue:
		[self weighInstructionAt: i.
		 i := i + (self instructionLengthAt: i)].
	"The receiver and arguments are copied in from the frame; registers referenced by deopt states need homes."
	0 to: (self numArgsOf: rootMethod) do:
		[:r| oilVRegWeight at: r put: (oilVRegWeight at: r) + 1].
	0 to: numSites - 1 do:
		[:s| ((siteIR at: s) >= 0 and: [(siteSnapBase at: s) >= 0]) ifTrue:
			[self markRegistersOfSiteState: s]].
	self analyzeTaggedRegisters.
	"Allocate machine registers, heaviest first."
	n := 0.
	[n < oilNumAllocRegs] whileTrue:
		[best := -1. bestWeight := 0.
		 0 to: OilMaxReg do:
			[:r|
			((oilVRegReg at: r) = NoReg and: [(oilVRegWeight at: r) > bestWeight]) ifTrue:
				[best := r. bestWeight := oilVRegWeight at: r]].
		 best < 0
			ifTrue: [oilNumAllocRegs := n]
			ifFalse:
				[oilVRegReg at: best put: (oilAllocRegs at: n).
				 n := n + 1]].
	"Home slots, below the frame's receiver and temps (the frame of an ordinary machine code method)."
	oilNumHomes := 0.
	homeBase := FoxMFReceiver - ((self numTempsOf: rootMethod) - (self numArgsOf: rootMethod) * objectMemory wordSize).
	0 to: OilMaxReg do:
		[:r|
		(oilVRegWeight at: r) > 0 ifTrue:
			[oilNumHomes := oilNumHomes + 1.
			 oilVRegHome at: r put: homeBase - (oilNumHomes * objectMemory wordSize)]].
	^OilOK! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
numHomes
	^oilNumHomes! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
weigh: r at: i
	"Count a use or definition of virtual register r by the instruction at i."
	<inline: true>
	| d w |
	d := oilLoopDepth at: i.
	w := d = 0 ifTrue: [1] ifFalse: [d = 1 ifTrue: [10] ifFalse: [d = 2 ifTrue: [100] ifFalse: [1000]]].
	r < OilFlagsReg ifTrue:
		[oilVRegWeight at: r put: (oilVRegWeight at: r) + w]! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
weighInstructionAt: i
	<inline: false>
	| op a b c |
	op := self opcodeAt: i.
	a := self fieldAAt: i.
	b := self fieldBAt: i.
	c := self fieldCAt: i.
	(op = OilConstTagged or: [op = OilConst64 or: [op = OilReturn or: [op = OilGuardClass]]]) ifTrue:
		[^self weigh: a at: i].
	(op = OilMove or: [op = OilShiftTagged or: [op = OilOddTagged or: [op = OilAddImmTagged or: [op = OilAddImmTaggedNC
	 or: [op = OilLoadField or: [op = OilStoreField or: [op = OilLoadSize or: [op = OilCheckBounds]]]]]]]]) ifTrue:
		[self weigh: a at: i.
		 ^self weigh: b at: i].
	((op between: OilAddTagged and: OilXorTagged)
	 or: [op = OilModTagged or: [op = OilLoadElement or: [op = OilStoreElement or: [op = OilCall1]]]]) ifTrue:
		[self weigh: a at: i.
		 self weigh: b at: i.
		 ^self weigh: c at: i].
	op = OilCmpTagged ifTrue:
		[self weigh: b at: i.
		 ^self weigh: c at: i].
	op = OilCmpImmTagged ifTrue:
		[^self weigh: b at: i].
	(op = OilBranchTrue or: [op = OilBranchFalse]) ifTrue:
		[^self weigh: a at: i].
	op = OilCall0 ifTrue:
		[self weigh: a at: i.
		 ^self weigh: b at: i].
	(op = OilCallN or: [op = OilCallSuper]) ifTrue:
		[self weigh: a at: i.
		 self weigh: b at: i.
		 1 to: c do: [:k| self weigh: (self packedArg: k - 1 at: i) at: i]].
	op = OilNewArray ifTrue:
		[self weigh: a at: i.
		 b ~= OilFlagsReg ifTrue:
			[0 to: c - 1 do: [:k| self weigh: b + k at: i]]].
	op = OilMakeClosure ifTrue:
		[self weigh: a at: i.
		 self weigh: ((oilIRBuffer at: i + 3) bitAnd: 255) at: i.
		 0 to: c - 1 do: [:k| self weigh: b + k at: i]]! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
packedArg: k at: i
	"The register of argument k (0-based) of the OilCallN/OilCallSuper at i: four per word after the selector."
	| word |
	word := oilIRBuffer at: i + 3 + (k // 4).
	^(word bitShift: (3 - (k \\ 4)) * -8) bitAnd: 255! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
markRegistersOfSiteState: s
	"Every register a deopt state refers to (directly, or through the virtual objects it refers to) needs a home."
	| base n k |
	base := siteSnapBase at: s.
	n := (siteSnapTop at: s) + 1 + (OilMaxReg - (siteSnapHigh at: s)).
	0 to: n - 1 do:
		[:j|
		k := sitePoolKind at: base + j.
		(k = OilDescReg and: [(oilVRegWeight at: (sitePoolValue at: base + j)) = 0]) ifTrue:
			[oilVRegWeight at: (sitePoolValue at: base + j) put: 1]].
	0 to: numFrames - 1 do:
		[:f|
		((frameSelfKind at: f) = OilDescReg and: [(oilVRegWeight at: (frameSelfValue at: f)) = 0]) ifTrue:
			[oilVRegWeight at: (frameSelfValue at: f) put: 1]].
	0 to: numVObjs - 1 do:
		[:v|
		((vobjSelfKind at: v) = OilDescReg and: [(oilVRegWeight at: (vobjSelfValue at: v)) = 0]) ifTrue:
			[oilVRegWeight at: (vobjSelfValue at: v) put: 1].
		0 to: (vobjNumCopied at: v) - 1 do:
			[:j|
			((capturedKind at: (vobjCopiedBase at: v) + j) = OilDescReg
			 and: [(oilVRegWeight at: (capturedValue at: (vobjCopiedBase at: v) + j)) = 0]) ifTrue:
				[oilVRegWeight at: (capturedValue at: (vobjCopiedBase at: v) + j) put: 1]]]! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
homeOf: r
	^oilVRegHome at: r! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
machineRegOf: r
	<inline: true>
	^oilVRegReg at: r! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
src: r scratch: scratch
	"Answer a machine register holding virtual register r: its own, or scratch loaded from its home."
	| reg |
	reg := oilVRegReg at: r.
	reg ~= NoReg ifTrue: [^reg].
	(oilVRegHome at: r) = 0 ifTrue:
		[self abortCompilation: OilFailInternal.
		 ^scratch].
	cogit MoveMw: (oilVRegHome at: r) r: FPReg R: scratch.
	^scratch! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
dst: r scratch: scratch
	"Answer the machine register to compute virtual register r into (its own, or scratch, then see setDst:from:)."
	| reg |
	reg := oilVRegReg at: r.
	^reg ~= NoReg ifTrue: [reg] ifFalse: [scratch]! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
setDst: r from: reg
	"Virtual register r has been computed into the machine register reg: move it to r's location."
	| own |
	own := oilVRegReg at: r.
	own ~= NoReg
		ifTrue: [own ~= reg ifTrue: [cogit MoveR: reg R: own]]
		ifFalse:
			[(oilVRegHome at: r) = 0 ifTrue: [^self abortCompilation: OilFailInternal].
			 cogit MoveR: reg Mw: (oilVRegHome at: r) r: FPReg]! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
spillAll
	"Store every register-allocated virtual register into its home (before a call or a bailout)."
	0 to: OilMaxReg do:
		[:r| (oilVRegReg at: r) ~= NoReg ifTrue:
			[cogit MoveR: (oilVRegReg at: r) Mw: (oilVRegHome at: r) r: FPReg]]! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
reloadAll
	"Reload every register-allocated virtual register from its home (after a call: the GC may have moved objects)."
	0 to: OilMaxReg do:
		[:r| (oilVRegReg at: r) ~= NoReg ifTrue:
			[cogit MoveMw: (oilVRegHome at: r) r: FPReg R: (oilVRegReg at: r)]]! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
bail: jump site: s
	"jump branches to the bailout stub of deopt site s (stubs are emitted after the method body)."
	<var: #jump type: #'AbstractInstruction *'>
	(s < 0 or: [s >= numSites or: [(siteSnapBase at: s) < 0]]) ifTrue:
		[^self abortCompilation: OilFailUnsafeSite].
	oilNumStubJumps >= OilBufferWords ifTrue:
		[^self abortCompilation: OilFailBackend].
	oilStubJump at: oilNumStubJumps put: jump.
	oilStubSite at: oilNumStubJumps put: s.
	oilNumStubJumps := oilNumStubJumps + 1.
	oilSiteUsed at: s put: 1! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
branch: jump to: target
	<var: #jump type: #'AbstractInstruction *'>
	oilNumFixups >= OilBufferWords ifTrue:
		[^self abortCompilation: OilFailBackend].
	oilFixupJump at: oilNumFixups put: jump.
	oilFixupTarget at: oilNumFixups put: target.
	oilNumFixups := oilNumFixups + 1! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genTagCheck: reg site: s
	"Bail out unless reg holds a SmallInteger."
	cogit TstCq: objectMemory smallIntegerTag R: reg.
	self bail: (cogit JumpZero: 0) site: s! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genTagCheckOf: va in: ra site: s
	"Bail out unless virtual register va (in machine register ra) holds a SmallInteger, unless it always does."
	(self isTagged: va) ifFalse:
		[self genTagCheck: ra site: s]! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genTagCheckOf: va in: ra and: vb in: rb site: s
	(self isTagged: va) ifTrue: [^self genTagCheckOf: vb in: rb site: s].
	(self isTagged: vb) ifTrue: [^self genTagCheck: ra site: s].
	self genTagCheck: ra and: rb site: s! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genTagCheck: ra and: rb site: s
	"Bail out unless both ra and rb hold SmallIntegers: the tag bit survives an and only if both have it."
	ra = rb ifTrue: [^self genTagCheck: ra site: s].
	cogit MoveR: ra R: SendNumArgsReg.
	cogit AndR: rb R: SendNumArgsReg.
	self genTagCheck: SendNumArgsReg site: s! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
generateNativeCode
	"Pass 3, step 2.  Emit the method body: copy the receiver and arguments into their locations, initialize the
	 other allocated registers (they are spilled at calls and bailouts, so they must always hold objects), then
	 translate each IR instruction, then the bailout stubs.  The caller has emitted the method's entry and its
	 frame build (including the home slots and the stack check).  Answer OilOK or a failure code."
	| i numArgs next |
	failed ifTrue: [^failureCode].
	numArgs := self numArgsOf: rootMethod.
	"The home slots follow the method's temps.  They are pushed here, after the stack check, and not in the
	 frame build: the CoInterpreter also builds machine code frames itself (with the method's temps only, see
	 activateNewCogMethod:inInterpreter:) and enters them at the stack check."
	1 to: oilNumHomes do:
		[:k| cogit PushCq: (objectMemory integerObjectOf: 0)].
	0 to: numArgs do:
		[:r| | dst |
		dst := self dst: r scratch: TempReg.
		r = 0
			ifTrue: [cogit MoveMw: FoxMFReceiver r: FPReg R: dst]
			ifFalse: [cogit MoveMw: FoxCallerSavedIP + (numArgs - r + 1 * objectMemory wordSize) r: FPReg R: dst].
		self setDst: r from: dst].
	numArgs + 1 to: OilMaxReg do:
		[:r| (oilVRegReg at: r) ~= NoReg ifTrue:
			[cogit MoveCq: (objectMemory integerObjectOf: 0) R: (oilVRegReg at: r)]].
	i := 0.
	[i < irIndex and: [failed not]] whileTrue:
		[(oilIRTarget at: i) ~= 0 ifTrue:
			[oilIRLabel at: i put: cogit Label].
		 next := self genInstructionAt: i.
		 i := next].
	failed ifTrue: [^failureCode].
	oilFailIndex := -1.
	(oilIRTarget at: irIndex) ~= 0 ifTrue: "a branch to the end of the IR (should not happen: the IR ends with a return)"
		[^self abortCompilation: OilFailInternal].
	self genBailoutStubs.
	failed ifTrue: [^failureCode].
	0 to: oilNumFixups - 1 do:
		[:k| | target |
		target := oilIRLabel at: (oilFixupTarget at: k).
		target = nil ifTrue: [^self abortCompilation: OilFailInternal].
		(oilFixupJump at: k) jmpTarget: target].
	^OilOK! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genInstructionAt: i
	"Translate the IR instruction at i.  Answer the index of the next instruction to translate."
	<inline: false>
	| op a b c s next |
	op := self opcodeAt: i.
	a := self fieldAAt: i.
	b := self fieldBAt: i.
	c := self fieldCAt: i.
	next := i + (self instructionLengthAt: i).
	oilFailIndex := i.
	s := (op = OilGuardClass or: [op = OilCheckBounds])
			ifTrue: [op = OilGuardClass ifTrue: [self imm16At: i] ifFalse: [c]]
			ifFalse: [oilIRSite at: i].
	s >= 0 ifTrue: "the bailout fast path (an unforwarded guard) resumes here"
		[oilSiteResume at: s put: cogit Label].
	op caseOf: {
		[OilConstTagged]	-> [self genConstTagged: a value: (self signed16: (self imm16At: i))].
		[OilConst64]		-> [self genConst64: a value: (self word64At: i + 1)].
		[OilMove]			-> [self genMove: a from: b].
		[OilAddTagged]		-> [self genAddTagged: a b: b c: c site: s].
		[OilSubTagged]		-> [self genSubTagged: a b: b c: c site: s].
		[OilAndTagged]		-> [self genLogicTagged: op a: a b: b c: c site: s].
		[OilOrTagged]		-> [self genLogicTagged: op a: a b: b c: c site: s].
		[OilXorTagged]		-> [self genLogicTagged: op a: a b: b c: c site: s].
		[OilShiftTagged]	-> [self genShiftTagged: a b: b shift: (self signed8: c) site: s].
		[OilOddTagged]		-> [self genOddTagged: a b: b site: s].
		[OilAddImmTagged]	-> [self genAddImmTagged: a b: b imm: (self signed8: c) site: s].
		[OilAddImmTaggedNC]	-> [self genAddImmTaggedNoCheck: a b: b imm: (self signed8: c)].
		[OilModTagged]		-> [self genModTagged: a b: b c: c site: s].
		[OilNewArray]		-> [self genNewArray: a first: b size: c site: s].
		[OilMakeClosure]	-> [self genMakeClosureAt: i site: s].
		[OilLoadField]		-> [self genLoadField: a object: b slot: c].
		[OilStoreField]		-> [self genStoreField: a object: b slot: c site: s].
		[OilLoadElement]	-> [self genLoadElement: a array: b index: c].
		[OilStoreElement]	-> [self genStoreElement: a array: b index: c site: s].
		[OilLoadSize]		-> [self genLoadSize: a object: b].
		[OilCheckBounds]	-> [self genCheckBounds: a limit: b site: s].
		[OilGuardClass]		-> [self genGuard: a class: (self word64At: i + 1) site: s].
		[OilCmpTagged]		-> [^self genCompareAt: i site: s].
		[OilCmpImmTagged]	-> [^self genCompareAt: i site: s].
		[OilBranchTrue]		-> [self genBranchOnBoolean: a ifTrue: true to: (self imm16At: i) site: s].
		[OilBranchFalse]	-> [self genBranchOnBoolean: a ifTrue: false to: (self imm16At: i) site: s].
		[OilJump]			-> [self branch: (cogit Jump: 0) to: (self imm16At: i)].
		[OilReturn]			-> [self genReturn: a].
		[OilCall0]			-> [self genCallAt: i site: s].
		[OilCall1]			-> [self genCallAt: i site: s].
		[OilCallN]			-> [self genCallAt: i site: s].
		[OilCallSuper]		-> [self genCallAt: i site: s] }
		otherwise: [self abortCompilation: OilFailBackend].
	^next! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
signed16: v
	<inline: true>
	^v > 32767 ifTrue: [v - 65536] ifFalse: [v]! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genConstTagged: a value: tagged
	| dst |
	dst := self dst: a scratch: TempReg.
	cogit MoveCq: tagged R: dst.
	self setDst: a from: dst! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genConst64: a value: oop
	"An object literal: annotated so that the GC can update it (and the method is a young referrer if need be)."
	| dst |
	dst := self dst: a scratch: TempReg.
	cogit genMoveConstant: oop R: dst.
	self setDst: a from: dst! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genMove: a from: b
	| src |
	src := self src: b scratch: TempReg.
	self setDst: a from: src! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genAddTagged: a b: b c: c site: s
	"(8x+1) - 1 + (8y+1) = 8(x+y)+1; the 64-bit add overflows exactly when x+y is not a SmallInteger.
	 Computed in a scratch register: on bailout the operands (and a) are intact.  But an accumulation, a := a + c
	 (or a := c + a) with a in a machine register, is computed in place, adding c - 1 (computed aside, so that the
	 loop carried dependency is one add): on overflow an undo stub subtracts it again (from the wrapped 64-bit sum)
	 before bailing out."
	| rb rc ra other ro |
	ra := oilVRegReg at: a.
	(ra ~= NoReg and: [oilNumUndos < OilMaxUndos and: [b ~= c and: [b = a or: [c = a]]]]) ifTrue:
		[other := b = a ifTrue: [c] ifFalse: [b].
		 ro := self src: other scratch: ClassReg.
		 self genTagCheckOf: a in: ra and: other in: ro site: s.
		 cogit LoadEffectiveAddressMw: -1 r: ro R: SendNumArgsReg.
		 cogit AddR: SendNumArgsReg R: ra.
		 ^self undoBail: (cogit JumpOverflow: 0) site: s reg: ra src: SendNumArgsReg].
	rb := self src: b scratch: TempReg.
	rc := self src: c scratch: ClassReg.
	self genTagCheckOf: b in: rb and: c in: rc site: s.
	cogit MoveR: rb R: SendNumArgsReg.
	cogit SubCq: 1 R: SendNumArgsReg.
	cogit AddR: rc R: SendNumArgsReg.
	self bail: (cogit JumpOverflow: 0) site: s.
	self setDst: a from: SendNumArgsReg! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 16:00'!
undoBail: jump site: s reg: reg src: src
	"jump (an overflow of reg := reg + src) branches to an undo stub, which restores reg (reg - src) and branches to the
	 bailout stub of deopt site s.  The stubs are emitted after the method body."
	<var: #jump type: #'AbstractInstruction *'>
	(s < 0 or: [s >= numSites or: [(siteSnapBase at: s) < 0]]) ifTrue:
		[^self abortCompilation: OilFailUnsafeSite].
	oilUndoJump at: oilNumUndos put: jump.
	oilUndoSite at: oilNumUndos put: s.
	oilUndoReg at: oilNumUndos put: reg.
	oilUndoSrc at: oilNumUndos put: src.
	oilNumUndos := oilNumUndos + 1.
	oilSiteUsed at: s put: 1! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genSubTagged: a b: b c: c site: s
	"(8x+1) - (8y+1) = 8(x-y), overflowing exactly when x-y is not a SmallInteger; then restore the tag."
	| rb rc |
	rb := self src: b scratch: TempReg.
	rc := self src: c scratch: ClassReg.
	self genTagCheckOf: b in: rb and: c in: rc site: s.
	cogit MoveR: rb R: SendNumArgsReg.
	cogit SubR: rc R: SendNumArgsReg.
	self bail: (cogit JumpOverflow: 0) site: s.
	cogit AddCq: 1 R: SendNumArgsReg.
	self setDst: a from: SendNumArgsReg! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 17:00'!
genModTagged: a b: b c: c site: s
	"x \\ y, the floored modulo (the result has the sign of y): untag both, divide (the back end's genDivR:R:Quo:Rem:,
	 which saves and restores the registers the division needs), and add y to a non-zero remainder whose sign differs
	 from y's.  Bail out unless both are SmallIntegers and y is not 0.  The result cannot overflow."
	| rb rc jumpZero jumpSameSign |
	<var: #jumpZero type: #'AbstractInstruction *'>
	<var: #jumpSameSign type: #'AbstractInstruction *'>
	rb := self src: b scratch: TempReg.
	rc := self src: c scratch: ClassReg.
	self genTagCheckOf: b in: rb and: c in: rc site: s.
	cogit CmpCq: (objectMemory integerObjectOf: 0) R: rc.
	self bail: (cogit JumpZero: 0) site: s.
	cogit MoveR: rc R: SendNumArgsReg.
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: SendNumArgsReg.
	cogit MoveR: rb R: ClassReg.
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: ClassReg.
	cogit backEnd genDivR: SendNumArgsReg R: ClassReg Quo: TempReg Rem: ClassReg.
	cogit CmpCq: 0 R: ClassReg.
	jumpZero := cogit JumpZero: 0.
	cogit MoveR: ClassReg R: TempReg.
	cogit XorR: SendNumArgsReg R: TempReg.
	jumpSameSign := cogit JumpGreaterOrEqual: 0.
	cogit AddR: SendNumArgsReg R: ClassReg.
	jumpZero jmpTarget: (jumpSameSign jmpTarget: cogit Label).
	cogit LogicalShiftLeftCq: objectMemory numTagBits R: ClassReg.
	cogit OrCq: objectMemory smallIntegerTag R: ClassReg.
	self setDst: a from: ClassReg! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 17:30'!
genAllocate: numBytes header: header site: s
	"Bump allocate numBytes in eden into ClassReg (TempReg is clobbered) and store its header.  If the new freeStart
	 would reach the scavenge threshold, bail out at the allocation's deopt site instead (an OilSiteAlloc, which does
	 not count as a deoptimization): the interpreter then allocates and the scavenge runs.  (Oil code has no
	 interrupt checks, so it must not allocate beyond the threshold like the baseline JIT does.)"
	cogit MoveAw: objectMemory freeStartAddress R: ClassReg.
	cogit LoadEffectiveAddressMw: numBytes r: ClassReg R: TempReg.
	cogit CmpCq: objectMemory getScavengeThreshold R: TempReg.
	self bail: (cogit JumpAboveOrEqual: 0) site: s.
	cogit MoveR: TempReg Aw: objectMemory freeStartAddress.
	cogit oilGenStoreHeader: header into: ClassReg scratch: TempReg! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 17:30'!
genNewArray: a first: b size: n site: s
	"A brace array of the n values in registers b..b+n-1, or (b = OilFlagsReg) an Array of n nils (a temp vector in
	 eager mode).  Young, so its stores need no store check."
	| reg |
	n >= objectMemory numSlotsMask ifTrue:
		[^self abortCompilation: OilFailBackend].
	self genAllocate: (objectMemory smallObjectBytesForSlots: n)
		header: (objectMemory headerForSlots: n format: objectMemory arrayFormat classIndex: ClassArrayCompactIndex)
		site: s.
	b = OilFlagsReg ifTrue:
		[n > 0 ifTrue:
			[cogit genMoveConstant: objectMemory nilObject R: TempReg.
			 0 to: n - 1 do:
				[:k| cogit MoveR: TempReg Mw: k * objectMemory wordSize + objectMemory baseHeaderSize r: ClassReg]]]
		ifFalse:
			[0 to: n - 1 do:
				[:k|
				reg := self src: b + k scratch: TempReg.
				cogit MoveR: reg Mw: k * objectMemory wordSize + objectMemory baseHeaderSize r: ClassReg]].
	self setDst: a from: ClassReg! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 17:30'!
genMakeClosureAt: i site: s
	"An escaping FullBlockClosure (eager mode): [OilMakeClosure|Dest|FirstCopied|NumCopied] block (64 bits)
	 [frame:16|ignoreOuterContext:8|selfReg:8].  Its outerContext is the root frame's context (the frame is married
	 through the baseline JIT's active context trampoline, all registers spilled around the call), or nil for a block
	 that ignores it.  The context of an inlined frame does not exist: such closures are not supported."
	| a b n block word selfReg ignoreContext frame reg slot |
	a := self fieldAAt: i.
	b := self fieldBAt: i.
	n := self fieldCAt: i.
	block := self word64At: i + 1.
	word := oilIRBuffer at: i + 3.
	selfReg := word bitAnd: 255.
	ignoreContext := (word bitAnd: 256) ~= 0.
	frame := word bitShift: -16.
	(ignoreContext not and: [frame ~= 0]) ifTrue:
		[^self abortCompilation: OilFailBackend].
	FullClosureFirstCopiedValueIndex + n >= objectMemory numSlotsMask ifTrue:
		[^self abortCompilation: OilFailBackend].
	ignoreContext
		ifTrue: [cogit genMoveConstant: objectMemory nilObject R: SendNumArgsReg]
		ifFalse:
			[self spillAll.
			 cogit oilGenGetActiveContextInto: SendNumArgsReg.
			 self reloadAll].
	self genAllocate: (objectMemory smallObjectBytesForSlots: FullClosureFirstCopiedValueIndex + n)
		header: (objectMemory
					headerForSlots: FullClosureFirstCopiedValueIndex + n
					format: objectMemory indexablePointersFormat
					classIndex: ClassFullBlockClosureCompactIndex)
		site: s.
	slot := objectMemory baseHeaderSize.
	cogit MoveR: SendNumArgsReg Mw: ClosureOuterContextIndex * objectMemory wordSize + slot r: ClassReg.
	cogit genMoveConstant: block R: TempReg.
	cogit MoveR: TempReg Mw: ClosureStartPCIndex * objectMemory wordSize + slot r: ClassReg.
	cogit MoveCq: (objectMemory integerObjectOf: (self numArgsOf: block)) R: TempReg.
	cogit MoveR: TempReg Mw: ClosureNumArgsIndex * objectMemory wordSize + slot r: ClassReg.
	reg := self src: selfReg scratch: TempReg.
	cogit MoveR: reg Mw: FullClosureReceiverIndex * objectMemory wordSize + slot r: ClassReg.
	0 to: n - 1 do:
		[:k|
		reg := self src: b + k scratch: TempReg.
		cogit MoveR: reg Mw: FullClosureFirstCopiedValueIndex + k * objectMemory wordSize + slot r: ClassReg].
	self setDst: a from: ClassReg! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genLogicTagged: op a: a b: b c: c site: s
	"bitAnd:/bitOr: on tagged values need no untagging (1 and 1 = 1 or 1 = 1); bitXor: clears the tag: set it again."
	| rb rc |
	rb := self src: b scratch: TempReg.
	rc := self src: c scratch: ClassReg.
	self genTagCheckOf: b in: rb and: c in: rc site: s.
	cogit MoveR: rb R: SendNumArgsReg.
	op = OilAndTagged ifTrue: [cogit AndR: rc R: SendNumArgsReg].
	op = OilOrTagged ifTrue: [cogit OrR: rc R: SendNumArgsReg].
	op = OilXorTagged ifTrue:
		[cogit XorR: rc R: SendNumArgsReg.
		 cogit OrCq: objectMemory smallIntegerTag R: SendNumArgsReg].
	self setDst: a from: SendNumArgsReg! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genShiftTagged: a b: b shift: k site: s
	"k > 0: x // 2^k, i.e. an arithmetic right shift: sar (3+k), shl 3, or 1 (exact floor, no overflow).
	 k < 0: x * 2^-k: (t - 1) << -k, checked by shifting back, then or 1."
	| rb |
	rb := self src: b scratch: TempReg.
	self genTagCheckOf: b in: rb site: s.
	cogit MoveR: rb R: SendNumArgsReg.
	k > 0
		ifTrue:
			[cogit ArithmeticShiftRightCq: objectMemory numTagBits + k R: SendNumArgsReg.
			 cogit LogicalShiftLeftCq: objectMemory numTagBits R: SendNumArgsReg]
		ifFalse:
			[cogit SubCq: 1 R: SendNumArgsReg.
			 cogit LogicalShiftLeftCq: k negated R: SendNumArgsReg.
			 cogit MoveR: SendNumArgsReg R: ClassReg.
			 cogit ArithmeticShiftRightCq: k negated R: ClassReg.
			 cogit AddCq: 1 R: ClassReg.
			 cogit CmpR: rb R: ClassReg.
			 self bail: (cogit JumpNonZero: 0) site: s].
	cogit OrCq: objectMemory smallIntegerTag R: SendNumArgsReg.
	self setDst: a from: SendNumArgsReg! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genOddTagged: a b: b site: s
	"x \\ 2 = x bitAnd: 1, i.e. on the tagged value (t bitAnd: 8) bitOr: 1."
	| rb |
	rb := self src: b scratch: TempReg.
	self genTagCheckOf: b in: rb site: s.
	cogit MoveR: rb R: SendNumArgsReg.
	cogit AndCq: 1 << objectMemory numTagBits R: SendNumArgsReg.
	cogit OrCq: objectMemory smallIntegerTag R: SendNumArgsReg.
	self setDst: a from: SendNumArgsReg! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genAddImmTagged: a b: b imm: imm site: s
	"x + imm on tagged values is t + 8 imm: one add, overflow checked (e.g. the loop increment, addq $8)."
	| rb |
	rb := self src: b scratch: TempReg.
	self genTagCheckOf: b in: rb site: s.
	cogit MoveR: rb R: SendNumArgsReg.
	cogit AddCq: imm << objectMemory numTagBits R: SendNumArgsReg.
	self bail: (cogit JumpOverflow: 0) site: s.
	self setDst: a from: SendNumArgsReg! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 16:00'!
genAddImmTaggedNoCheck: a b: b imm: imm
	"x + imm where Pass 2 proved x a SmallInteger and the sum one too (a counted loop index): addq $8imm, in place
	 if a and b share a machine register."
	| ra rb |
	ra := oilVRegReg at: a.
	(ra ~= NoReg and: [(oilVRegReg at: b) = ra]) ifTrue:
		[cogit AddCq: imm << objectMemory numTagBits R: ra.
		 ^self].
	rb := self src: b scratch: TempReg.
	ra := self dst: a scratch: SendNumArgsReg.
	ra ~= rb ifTrue: [cogit MoveR: rb R: ra].
	cogit AddCq: imm << objectMemory numTagBits R: ra.
	self setDst: a from: ra! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genLoadField: a object: b slot: index
	| rb dst |
	rb := self src: b scratch: TempReg.
	dst := self dst: a scratch: SendNumArgsReg.
	cogit MoveMw: index * objectMemory wordSize + objectMemory baseHeaderSize r: rb R: dst.
	self setDst: a from: dst! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genImmutabilityCheckOf: objReg scratch: scratch site: s
	"Bail out if the object in objReg is read-only: the interpreter then retries the store and signals the failure."
	cogit MoveMw: 0 r: objReg R: scratch.
	cogit TstCq: objectMemory immutableBitMask R: scratch.
	self bail: (cogit JumpNonZero: 0) site: s! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
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

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genStoreField: a object: b slot: index site: s
	| ra rb |
	ra := self src: a scratch: TempReg.
	rb := self src: b scratch: ClassReg.
	self genImmutabilityCheckOf: rb scratch: SendNumArgsReg site: s.
	cogit MoveR: ra Mw: index * objectMemory wordSize + objectMemory baseHeaderSize r: rb.
	self genStoreCheckObject: rb value: ra scratch: SendNumArgsReg! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genLoadElement: a array: b index: c
	"Element i (1-based) of an Array (no fixed fields) is at array + 8 + 8(i-1) = array + 8i = array + tagged(i) - 1:
	 on x64 one movq -1(array,taggedIndex), else the untagged index scaled by 8 (see the back ends'
	 oilGenMoveTaggedIndex:base:into:scratch:).  The bounds were checked (by an OilCheckBounds, or by Pass 2)."
	| rb rc dst |
	rb := self src: b scratch: TempReg.
	rc := self src: c scratch: ClassReg.
	dst := self dst: a scratch: SendNumArgsReg.
	cogit backEnd oilGenMoveTaggedIndex: rc base: rb into: dst scratch: SendNumArgsReg.
	self setDst: a from: dst! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genStoreElement: a array: b index: c site: s
	| ra rb rc |
	rb := self src: b scratch: ClassReg.
	self genImmutabilityCheckOf: rb scratch: TempReg site: s.
	rc := self src: c scratch: SendNumArgsReg.
	rc ~= SendNumArgsReg ifTrue: [cogit MoveR: rc R: SendNumArgsReg].
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: SendNumArgsReg.
	ra := self src: a scratch: TempReg.
	cogit MoveR: ra Xwr: SendNumArgsReg R: rb.
	self genStoreCheckObject: rb value: ra scratch: SendNumArgsReg! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genLoadSize: a object: b
	"The number of slots of an Array (no fixed fields), tagged."
	| rb |
	rb := self src: b scratch: TempReg.
	cogit oilGenGetNumSlotsOf: rb into: SendNumArgsReg.
	cogit LogicalShiftLeftCq: objectMemory numTagBits R: SendNumArgsReg.
	cogit AddCq: objectMemory smallIntegerTag R: SendNumArgsReg.
	self setDst: a from: SendNumArgsReg! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genCheckBounds: a limit: b site: s
	"Bail out unless index (a) is a SmallInteger with 1 <= index <= limit (b, a tagged size)."
	| ra rb |
	ra := self src: a scratch: TempReg.
	rb := self src: b scratch: ClassReg.
	self genTagCheckOf: a in: ra site: s.
	cogit CmpCq: (objectMemory integerObjectOf: 1) R: ra.
	self bail: (cogit JumpLess: 0) site: s.
	cogit CmpR: rb R: ra.
	self bail: (cogit JumpGreater: 0) site: s! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genGuard: a class: classHandle site: s
	"Bail out unless the object in a is an instance of classHandle: a tag test for immediate classes, else a
	 compare of the class index in the header.  A forwarder (class index isForwardedObjectClassIndexPun) fails
	 the guard; the bailout's fast path then follows it and resumes here."
	| ra tag |
	tag := objectMemory classTagForClass: classHandle.
	tag = 0 ifTrue: [^self abortCompilation: OilFailBackend].
	ra := self src: a scratch: TempReg.
	tag = objectMemory smallIntegerTag ifTrue:
		[^self genTagCheck: ra site: s].
	tag <= objectMemory tagMask ifTrue:
		[cogit MoveR: ra R: SendNumArgsReg.
		 cogit AndCq: objectMemory tagMask R: SendNumArgsReg.
		 cogit CmpCq: tag R: SendNumArgsReg.
		 ^self bail: (cogit JumpNonZero: 0) site: s].
	cogit TstCq: objectMemory tagMask R: ra.
	self bail: (cogit JumpNonZero: 0) site: s.
	cogit MoveM32: 0 r: ra R: SendNumArgsReg.
	cogit AndCq: objectMemory classIndexMask R: SendNumArgsReg.
	cogit CmpCq: tag R: SendNumArgsReg.
	self bail: (cogit JumpNonZero: 0) site: s! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genCompareAt: i site: s
	"A comparison (OilCmpTagged/OilCmpImmTagged, condition in field A) always immediately followed by the branch on
	 the flags that consumes it: fuse them into one compare and one conditional jump.  Tagged values compare like
	 the integers they represent.  Answer the index of the instruction after the branch."
	<inline: false>
	| op cond ra rb br target onTrue tagged jump |
	<var: #jump type: #'AbstractInstruction *'>
	op := self opcodeAt: i.
	cond := self fieldAAt: i.
	br := i + 1.
	((self opcodeAt: br) = OilBranchTrue or: [(self opcodeAt: br) = OilBranchFalse]) ifFalse:
		[self abortCompilation: OilFailBackend.
		 ^br].
	(self fieldAAt: br) = OilFlagsReg ifFalse:
		[self abortCompilation: OilFailBackend.
		 ^br].
	(oilIRTarget at: br) ~= 0 ifTrue: "nothing may jump between the compare and the branch"
		[self abortCompilation: OilFailBackend.
		 ^br].
	onTrue := (self opcodeAt: br) = OilBranchTrue.
	target := self imm16At: br.
	ra := self src: (self fieldBAt: i) scratch: TempReg.
	op = OilCmpImmTagged
		ifTrue:
			[self genTagCheckOf: (self fieldBAt: i) in: ra site: s.
			 tagged := objectMemory integerObjectOf: (self signed8: (self fieldCAt: i)).
			 cogit CmpCq: tagged R: ra]
		ifFalse:
			[rb := self src: (self fieldCAt: i) scratch: ClassReg.
			 cond < OilCondIdentical ifTrue: [self genTagCheckOf: (self fieldBAt: i) in: ra and: (self fieldCAt: i) in: rb site: s].
			 cogit CmpR: rb R: ra].
	jump := self genJumpOn: cond ifTrue: onTrue.
	self branch: jump to: target.
	^br + 1! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genJumpOn: cond ifTrue: onTrue
	"Answer a conditional jump taken when (ra cond rb) = onTrue, the flags being those of ra - rb."
	<returnTypeC: #'AbstractInstruction *'>
	| c |
	c := cond.
	onTrue ifFalse:
		[c := c caseOf: {
				[OilCondLt] -> [OilCondGe].
				[OilCondGt] -> [OilCondLe].
				[OilCondLe] -> [OilCondGt].
				[OilCondGe] -> [OilCondLt].
				[OilCondEq] -> [OilCondNe].
				[OilCondNe] -> [OilCondEq].
				[OilCondIdentical] -> [OilCondNotIdentical] }
				otherwise: [OilCondIdentical]].
	c = OilCondLt ifTrue: [^cogit JumpLess: 0].
	c = OilCondGt ifTrue: [^cogit JumpGreater: 0].
	c = OilCondLe ifTrue: [^cogit JumpLessOrEqual: 0].
	c = OilCondGe ifTrue: [^cogit JumpGreaterOrEqual: 0].
	(c = OilCondEq or: [c = OilCondIdentical]) ifTrue: [^cogit JumpZero: 0].
	^cogit JumpNonZero: 0! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genBranchOnBoolean: a ifTrue: onTrue to: target site: s
	"A branch on a boolean in a register (not on the flags): bail out (mustBeBoolean) on a non-boolean."
	| ra jmpTarget |
	<var: #jmpTarget type: #'AbstractInstruction *'>
	a = OilFlagsReg ifTrue: "flags are always consumed by genCompareAt:site:"
		[^self abortCompilation: OilFailBackend].
	ra := self src: a scratch: TempReg.
	cogit genMoveConstant: (onTrue ifTrue: [objectMemory trueObject] ifFalse: [objectMemory falseObject]) R: ClassReg.
	cogit CmpR: ClassReg R: ra.
	jmpTarget := cogit JumpZero: 0.
	self branch: jmpTarget to: target.
	cogit genMoveConstant: (onTrue ifTrue: [objectMemory falseObject] ifFalse: [objectMemory trueObject]) R: ClassReg.
	cogit CmpR: ClassReg R: ra.
	self bail: (cogit JumpNonZero: 0) site: s! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genReturn: a
	| reg |
	reg := oilVRegReg at: a.
	reg = NoReg
		ifTrue: [cogit MoveMw: (oilVRegHome at: a) r: FPReg R: ReceiverResultReg]
		ifFalse: [reg ~= ReceiverResultReg ifTrue: [cogit MoveR: reg R: ReceiverResultReg]].
	cogit oilGenReturnFrom: (self numArgsOf: rootMethod)! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
selectorIndexOf: selector
	"The inline cache of a send holds the index of its selector, in the literals of the method (the root) or,
	 negative, in the special selectors.  Answer that index, or OilNoLink if the selector is in neither."
	0 to: 31 do:
		[:k| (coInterpreter specialSelector: k) = selector ifTrue: [^-1 - k]].
	0 to: (objectMemory literalCountOf: rootMethod) - 1 do:
		[:k| (coInterpreter literal: k ofMethod: rootMethod) = selector ifTrue: [^k]].
	^OilNoLink! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genCallAt: i site: s
	"An uninlined send, through the Cogit's inline cache and PIC machinery: spill everything (the callee may run
	 the GC, which scans and updates the homes), marshal the receiver and arguments like the baseline JIT
	 (registers for up to numRegArgs arguments, else pushed), call the send trampoline (linked later to the target
	 method or a PIC), store the result and reload."
	<inline: false>
	| op a b n selector selIndex isSuper |
	op := self opcodeAt: i.
	a := self fieldAAt: i.
	b := self fieldBAt: i.
	n := op = OilCall0 ifTrue: [0] ifFalse: [op = OilCall1 ifTrue: [1] ifFalse: [self fieldCAt: i]].
	selector := self word64At: i + 1.
	isSuper := op = OilCallSuper.
	"A super send binds to the method class of the frame's method, which must be the root method's."
	(isSuper and: [s < 0 or: [(siteFrame at: s) ~= 0]]) ifTrue:
		[^self abortCompilation: OilFailBackend].
	selIndex := self selectorIndexOf: selector.
	selIndex = OilNoLink ifTrue:
		[^self abortCompilation: OilFailBackend].
	self spillAll.
	n <= cogit numRegArgs
		ifTrue:
			[n >= 1 ifTrue: [cogit MoveMw: (oilVRegHome at: (self callArg: 0 at: i)) r: FPReg R: Arg0Reg].
			 n >= 2 ifTrue: [cogit MoveMw: (oilVRegHome at: (self callArg: 1 at: i)) r: FPReg R: Arg1Reg]]
		ifFalse:
			[cogit MoveMw: (oilVRegHome at: b) r: FPReg R: TempReg.
			 cogit PushR: TempReg.
			 0 to: n - 1 do:
				[:k|
				cogit MoveMw: (oilVRegHome at: (self callArg: k at: i)) r: FPReg R: TempReg.
				cogit PushR: TempReg]].
	cogit MoveMw: (oilVRegHome at: b) r: FPReg R: ReceiverResultReg.
	cogit oilGenSend: selIndex numArgs: n super: isSuper.
	cogit MoveR: ReceiverResultReg Mw: (oilVRegHome at: a) r: FPReg.
	self reloadAll! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
callArg: k at: i
	"The register of argument k (0-based) of the call at i."
	| op |
	op := self opcodeAt: i.
	op = OilCall1 ifTrue: [^self fieldCAt: i].
	^self packedArg: k at: i! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
genBailoutStubs
	"After the body: one stub per deopt site used, passing the site index, and the common bailout sequence:
	 spill everything (the deoptimizer reads the virtual registers from their homes), call ceOilBailoutTrampoline,
	 which either deoptimizes the frame and continues in the interpreter (it does not return), or, having
	 unforwarded the object a class guard failed on, answers the address of the guard to resume at."
	| stub |
	<var: #stub type: #'AbstractInstruction *'>
	(oilNumStubJumps = 0 and: [oilNumUndos = 0]) ifTrue: [^self].
	oilBailoutCommon := cogit Label.
	self spillAll.
	cogit MoveR: TempReg R: SendNumArgsReg.
	cogit oilGenBailoutCall.
	self reloadAll.
	cogit JumpR: TempReg.
	0 to: numSites - 1 do:
		[:s|
		(oilSiteUsed at: s) ~= 0 ifTrue:
			[stub := cogit MoveCq: s R: TempReg.
			 oilSiteStub at: s put: stub.
			 cogit Jump: oilBailoutCommon]].
	0 to: oilNumStubJumps - 1 do:
		[:k| (oilStubJump at: k) jmpTarget: (oilSiteStub at: (oilStubSite at: k))].
	"The undo stubs of the in-place tagged adds: reg := reg - src, then the site's stub."
	0 to: oilNumUndos - 1 do:
		[:k|
		stub := cogit SubR: (oilUndoSrc at: k) R: (oilUndoReg at: k).
		(cogit Jump: 0) jmpTarget: (oilSiteStub at: (oilUndoSite at: k)).
		(oilUndoJump at: k) jmpTarget: stub]! !

!OilCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 15:00'!
siteResumeLabel: s
	<returnTypeC: #'AbstractInstruction *'>
	^oilSiteResume at: s! !

!OilCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 15:00'!
isSiteUsed: s
	^(oilSiteUsed at: s) ~= 0! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
oilFailureCode
	"(Named so as not to clash in C with the failureCode variable.)"
	<inline: true>
	^failureCode! !

!OilCompiler methodsFor: 'debugging' stamp: 'cb 10/24/2026 15:00'!
oilDebugInfo: what at: index
	"For primitiveOilLastCompilation: what = 0 failure code, 1 IR size in words, 2 IR word at index, 3 eager closures,
	 4 IR index of the instruction the back end failed on (or -1), 5 number of deopt sites, 6 number of frames,
	 7 number of virtual register homes, 8 number of register-allocated virtual registers."
	<api>
	what = 0 ifTrue: [^failureCode].
	what = 1 ifTrue: [^irIndex].
	what = 2 ifTrue: [^(index between: 0 and: irIndex - 1) ifTrue: [oilIRBuffer at: index] ifFalse: [0]].
	what = 3 ifTrue: [^eagerClosures ifTrue: [1] ifFalse: [0]].
	what = 4 ifTrue: [^oilFailIndex].
	what = 5 ifTrue: [^numSites].
	what = 6 ifTrue: [^numFrames].
	what = 7 ifTrue: [^oilNumHomes].
	what = 8 ifTrue: [^oilNumAllocRegs].
	what = 9 ifTrue: [^oilTraceTop].
	what = 10 ifTrue: [^(index between: 0 and: oilTraceTop - 1) ifTrue: [oilTraceBuf at: index] ifFalse: [0]].
	what = 11 ifTrue: [^oilPass1Words].
	what = 12 ifTrue: [^(index between: 0 and: oilPass1Words - 1) ifTrue: [oilIRBuffer1 at: index] ifFalse: [0]].
	what = 13 ifTrue: [^index = 7 ifTrue: [oilNumUndos] ifFalse: [self pass2Statistics: index]].
	^0! !

!OilCompiler methodsFor: 'debugging' stamp: 'cb 10/24/2026 15:00'!
oilTrace: a with: b
	"Record a pair of values in the debugging trace of the last compilation (see oilDebugInfo:at:)."
	<inline: false>
	self cCode: [] inSmalltalk: [oilTraceBuf ifNil: [^self]].
	oilTraceTop < 254 ifTrue:
		[oilTraceBuf at: oilTraceTop put: a.
		 oilTraceBuf at: oilTraceTop + 1 put: b.
		 oilTraceTop := oilTraceTop + 2]! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
analyzeTaggedRegisters
	"A virtual register all of whose definitions produce SmallIntegers (tagged arithmetic, tagged constants, sizes, or
	 moves of such registers) always holds a SmallInteger (before its first definition it holds the SmallInteger 0 the
	 prologue initializes it to; incoming arguments are excluded): its tag checks can be omitted.  E.g. a loop
	 index (ConstTagged, then AddImmTagged) or an accumulator.  Flow insensitive, iterated to a fixpoint for moves."
	| i op a changed numArgs |
	numArgs := self numArgsOf: rootMethod.
	0 to: OilNumRegs - 1 do:
		[:r| oilTagged at: r put: ((r > numArgs and: [r < OilFlagsReg]) ifTrue: [1] ifFalse: [0])].
	changed := true.
	[changed] whileTrue:
		[changed := false.
		 i := 0.
		 [i < irIndex] whileTrue:
			[op := self opcodeAt: i.
			 a := self fieldAAt: i.
			 ((self opcodeHasDest: op)
			  and: [(oilTagged at: a) ~= 0
			  and: [(self definitionIsTaggedAt: i) not]]) ifTrue:
				[oilTagged at: a put: 0.
				 changed := true].
			 i := i + (self instructionLengthAt: i)]]! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
definitionIsTaggedAt: i
	"Does the instruction at i (which has a destination) always produce a SmallInteger?"
	| op |
	op := self opcodeAt: i.
	op = OilConstTagged ifTrue: [^true].
	op = OilConst64 ifTrue: [^self isSmallIntegerHandle: (self word64At: i + 1)].
	op = OilMove ifTrue: [^(oilTagged at: (self fieldBAt: i)) ~= 0].
	((op between: OilAddTagged and: OilOddTagged)
	 or: [op = OilAddImmTagged or: [op = OilAddImmTaggedNC or: [op = OilLoadSize or: [op = OilModTagged]]]]) ifTrue: [^true].
	^false! !

!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
isTagged: r
	<inline: true>
	^(oilTagged at: r) ~= 0! !
