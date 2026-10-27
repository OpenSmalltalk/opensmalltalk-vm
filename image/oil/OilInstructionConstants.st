SharedPool subclass: #OilInstructionConstants
	instanceVariableNames: ''
	classVariableNames: 'OilConstTagged OilConst64 OilMove OilAddTagged OilSubTagged OilAndTagged OilOrTagged OilXorTagged OilShiftTagged OilOddTagged OilLoadField OilStoreField OilLoadElement OilStoreElement OilCmpTagged OilBranchTrue OilBranchFalse OilJump OilReturn OilGuardClass OilCheckBounds OilCall0 OilCall1 OilCallN OilAddImmTagged OilCmpImmTagged OilLoadSize OilMakeClosure OilNewArray OilCallSuper OilAddImmTaggedNC OilModTagged OilLoadByteSize OilLoadByte OilLoadChar OilStoreByte OilStoreChar OilCompareBytes OilTrap OilCharValue OilStreamNext OilStreamNextPut OilAddFloat OilSubFloat OilMulFloat OilDivFloat OilCmpFloat OilIdentityHash OilIndexOfByte OilSkipSeparators OilNewObject OilCmpClass OilGuardClass2 OilStringHash OilCallDirectedSuper OilSqrtFloat OilAbsFloat OilNegatedFloat OilFindSubstring OilFindFirstInString OilLastOpcode OilOpLengthMask OilOpPackedArgs OilOpDest OilOpSend OilOpCall OilOpClobbersXmms OilOpTagged OilOpPure OilOpBranch OilOpReadsA OilOpReadsB OilOpReadsC OilOpReadsRange OilOpFloat'
	poolDictionaries: ''
	category: 'VMMaker-JIT-Oil'!

!OilInstructionConstants commentStamp: 'cb 10/25/2026 00:10' prior: 0!
I hold the instruction opcodes of Oil, the optimizing JIT for the 64-bit Spur Cog VM.  Each opcode identifies an instruction in Oil's compact 32-bit linear IR [Op:8 | Dest:8 | Src1:8 | Src2/Imm:8].  Initialize with OilInstructionConstants initialize.!

!OilInstructionConstants class methodsFor: 'class initialization' stamp: 'cb 10/25/2026 00:10'!
initialize
	"OilInstructionConstants initialize"
	"opcodes (32-bit linear IR: Op:8 Dest:8 Src1:8 Src2/Imm:8)"
	OilConstTagged := 1.
	OilConst64 := 2.
	OilMove := 3.
	OilAddTagged := 4.
	OilSubTagged := 5.
	OilAndTagged := 6.
	OilOrTagged := 7.
	OilXorTagged := 8.
	OilShiftTagged := 9.
	OilOddTagged := 10.
	OilLoadField := 11.
	OilStoreField := 12.
	OilLoadElement := 13.
	OilStoreElement := 14.
	OilCmpTagged := 15.
	OilBranchTrue := 16.
	OilBranchFalse := 17.
	OilJump := 18.
	OilReturn := 19.
	OilGuardClass := 20.
	OilCheckBounds := 21.
	OilCall0 := 22.
	OilCall1 := 23.
	OilCallN := 24.
	OilAddImmTagged := 25.
	OilCmpImmTagged := 26.
	OilLoadSize := 27.
	OilMakeClosure := 28.
	OilNewArray := 29.
	OilCallSuper := 30.
	"Pass 2 only: x + imm on a SmallInteger that cannot overflow (a bounded loop index): no tag or overflow check"
	OilAddImmTaggedNC := 31.
	"x \\ y (floored modulo) on SmallIntegers, y not a power of two: a division; deoptimizes on a zero divisor"
	OilModTagged := 32.
	"byte objects (ByteString, ByteArray): size in bytes; element as SmallInteger or Character; stores; primitive 158 (compareWith:)"
	OilLoadByteSize := 33.
	OilLoadByte := 34.
	OilLoadChar := 35.
	OilStoreByte := 36.
	OilStoreChar := 37.
	OilCompareBytes := 38.
	"an uncommon trap: deoptimize unconditionally at the deopt site in field C/imm16 (a send never executed so far that the back end cannot encode)"
	OilTrap := 39.
	"the SmallInteger value of a Character (asInteger, or character value from an inlined string)"
	OilCharValue := 40.
	"streaming byte read/write intrinsics for buffered stream next / nextPut: without method dispatch"
	OilStreamNext := 41.
	OilStreamNextPut := 42.
	"Float arithmetic [Op|Dest|Rcvr|Arg] and comparison [Op|Cond|Rcvr|Arg] (then a branch on the flags, like OilCmpTagged)
	 on doubles: the receiver must be a Float (SmallFloat64 or BoxedFloat64), the argument a Float or a SmallInteger, and
	 a divisor non-zero, else they deoptimize; the result is boxed (see OilFullCompiler>>fuseFloats for chains of them)"
	OilAddFloat := 43.
	OilSubFloat := 44.
	OilMulFloat := 45.
	OilDivFloat := 46.
	OilCmpFloat := 47.
	"primitive 75 (identityHash) of a non-immediate [Op|Dest|Rcvr|0] then the selector: the hash in its header, or, if it
	 has none yet, the send"
	OilIdentityHash := 48.
	"word-at-a-time byte scans, else (unexpected operands) the send: ByteString class>>indexOfAscii:inString:startingAt:
	 [Op|Dest|Rcvr|3] then the selector and the packed argument registers (like OilCallN), and PositionableStream>>skipSeparators
	 of a ReadStream on a ByteString [Op|Dest|Rcvr|0] then the selector"
	OilIndexOfByte := 49.
	OilSkipSeparators := 50.
	"a new instance of a class with fixed pointer fields only [Op|Dest|FirstSlot|NumSlots] then the class: its slots are the
	 registers FirstSlot..FirstSlot+NumSlots-1 (a scalar replaced object that escapes, see OilInliningCompiler>>materializeVObj:scratch:);
	 young, so the stores need no store check, and not nil filled first.  Beyond the scavenge threshold it deoptimizes (OilSiteAlloc)"
	OilNewObject := 51.
	"[Op|Cond|Reg|0] then a class: the flags of class(Reg) == class (OilCondIdentical / OilCondNotIdentical), followed by a branch
	 on the flags (the class test of a bimorphic send or of a predicate answering true for one class and false for the other)"
	OilCmpClass := 52.
	"[Op|Reg|Site16] then two classes: deoptimize unless Reg is an instance of one of them (a bimorphic predicate)"
	OilGuardClass2 := 53.
	"primitiveStringHash (String>>hashWithInitialHash:) of a byte object [Op|Dest|Rcvr|InitialHash] then the selector:
	 ((((h + b1) * 16r19660D) + b2) * 16r19660D ...) bitAnd: 16r0FFFFFFF, h the SmallInteger initial hash, else the send"
	OilStringHash := 54.
	"a super send of an inlined method [Op|Dest|Rcvr|NumArgs] then the selector, the method class of the inlined method
	 (the lookup starts in its superclass) and the packed argument registers (like OilCallN): OilCallSuper binds to the
	 method class of the root method, the directed super send trampolines take the class"
	OilCallDirectedSuper := 55.
	"Unary Float arithmetic [Op|Dest|Rcvr|0] on doubles: #sqrt (deoptimizes on a negative or NaN receiver), #abs and #negated"
	OilSqrtFloat := 56.
	OilAbsFloat := 57.
	OilNegatedFloat := 58.
	"primitive 154 (findSubstring:in:startingAt:matchTable:, findSubstringViaPrimitive:startingAt:) and primitive 155
	 (findFirstInString:inSet:startingAt:, findFirstInByteString:startingAt:) [Op|Dest|Rcvr|NumArgs] then the selector and the
	 packed argument registers (like OilIndexOfByte), falling back to the send on unexpected operands"
	OilFindSubstring := 59.
	OilFindFirstInString := 60.
	OilLastOpcode := 60.
	"The properties of the opcodes (see opInfoSpec and OilInliningCompiler>>opcode:has:): the length in words of an
	 instruction (plus, if OilOpPackedArgs, one word per 4 argument registers packed after its fixed words, C of them), and
	 property bits"
	OilOpLengthMask := 7.
	OilOpPackedArgs := 8.
	OilOpDest := 16.			"defines register A"
	OilOpSend := 32.			"a send"
	OilOpCall := 64.			"a send, or a byte scan that falls back to one, which may run any code (Pass 2)"
	OilOpClobbersXmms := 128.	"may call out (C calls clobber the XMM registers) or resume after a deopt (a guard)"
	OilOpTagged := 256.		"always defines a SmallInteger (OilConst64 and OilMove depend on their operand)"
	OilOpPure := 512.			"only computes its destination: no side effect, no deopt, no control flow (OilAddImmTagged only if it
	 cannot overflow, see OilLoopOptimizer>>isPureAt:)"
	OilOpBranch := 1024.		"a jump or a conditional branch"
	OilOpReadsA := 2048.		"reads register A"
	OilOpReadsB := 4096.		"reads register B"
	OilOpReadsC := 8192.		"reads register C"
	OilOpReadsRange := 16384.	"reads the C registers from B (OilNewArray: unless B is OilFlagsReg; OilMakeClosure: also the
	 register of its receiver)"
	OilOpFloat := 32768.		"a float arithmetic or comparison instruction (OilAddFloat..OilCmpFloat, OilSqrtFloat..OilNegatedFloat)"! !

!OilInstructionConstants class methodsFor: 'accessing' stamp: 'cb 10/27/2026 13:50'!
opInfoSpec
	"The opcodes in order, with the length of their fixed part in words and their properties (OilOp* without the prefix)."
	^#(	(ConstTagged		1 Dest Tagged Pure)
		(Const64			3 Dest Pure)
		(Move				1 Dest ReadsB Pure)
		(AddTagged		1 Dest ReadsB ReadsC Tagged)
		(SubTagged		1 Dest ReadsB ReadsC Tagged)
		(AndTagged		1 Dest ReadsB ReadsC Tagged)
		(OrTagged			1 Dest ReadsB ReadsC Tagged)
		(XorTagged		1 Dest ReadsB ReadsC Tagged)
		(ShiftTagged		1 Dest ReadsB Tagged)
		(OddTagged		1 Dest ReadsB Tagged)
		(LoadField			1 Dest ReadsB Pure)
		(StoreField		1 ReadsA ReadsB ClobbersXmms)
		(LoadElement		1 Dest ReadsB ReadsC)
		(StoreElement		1 ReadsA ReadsB ReadsC ClobbersXmms)
		(CmpTagged		1 ReadsB ReadsC)
		(BranchTrue		1 ReadsA Branch)
		(BranchFalse		1 ReadsA Branch)
		(Jump				1 Branch)
		(Return			1 ReadsA)
		(GuardClass		3 ReadsA ClobbersXmms)
		(CheckBounds		1 ReadsA ReadsB)
		(Call0				3 Dest ReadsB Send Call ClobbersXmms)
		(Call1				3 Dest ReadsB ReadsC Send Call ClobbersXmms)
		(CallN				3 PackedArgs Dest ReadsB Send Call ClobbersXmms)
		(AddImmTagged		1 Dest ReadsB Tagged)
		(CmpImmTagged	1 ReadsB)
		(LoadSize			1 Dest ReadsB Tagged Pure)
		(MakeClosure		4 Dest ReadsRange ClobbersXmms)
		(NewArray			1 Dest ReadsRange)
		(CallSuper			3 PackedArgs Dest ReadsB Send Call ClobbersXmms)
		(AddImmTaggedNC	1 Dest ReadsB Tagged)
		(ModTagged		1 Dest ReadsB ReadsC Tagged ClobbersXmms)
		(LoadByteSize		1 Dest ReadsB Tagged Pure)
		(LoadByte			1 Dest ReadsB ReadsC Tagged)
		(LoadChar			1 Dest ReadsB ReadsC)
		(StoreByte			1 ReadsA ReadsB ReadsC)
		(StoreChar			1 ReadsA ReadsB ReadsC)
		(CompareBytes		1 Dest ReadsB ReadsC Tagged)
		(Trap				1)
		(CharValue			1 Dest ReadsB Tagged)
		(StreamNext		3 Dest ReadsB ClobbersXmms)
		(StreamNextPut	3 Dest ReadsB ReadsC ClobbersXmms)
		(AddFloat			1 Dest ReadsB ReadsC Float)
		(SubFloat			1 Dest ReadsB ReadsC Float)
		(MulFloat			1 Dest ReadsB ReadsC Float)
		(DivFloat			1 Dest ReadsB ReadsC Float)
		(CmpFloat			1 ReadsB ReadsC Float)
		(IdentityHash		3 Dest ReadsB Tagged ClobbersXmms)
		(IndexOfByte		3 PackedArgs Dest ReadsB Call ClobbersXmms)
		(SkipSeparators	3 Dest ReadsB Call ClobbersXmms)
		(NewObject		3 Dest ReadsRange)
		(CmpClass			3 ReadsB)
		(GuardClass2		5 ReadsA ClobbersXmms)
		(StringHash		3 Dest ReadsB ReadsC Call ClobbersXmms)
		(CallDirectedSuper	5 PackedArgs Dest ReadsB Send Call ClobbersXmms)
		(SqrtFloat			1 Dest ReadsB Float)
		(AbsFloat			1 Dest ReadsB Float)
		(NegatedFloat		1 Dest ReadsB Float)
		(FindSubstring		3 PackedArgs Dest ReadsB Call ClobbersXmms)
		(FindFirstInString	3 PackedArgs Dest ReadsB Call ClobbersXmms))! !

!OilInstructionConstants class methodsFor: 'accessing' stamp: 'cb 10/26/2026 20:30'!
opInfoTable
	"The properties of each opcode (see opInfoSpec), indexed by opcode from 0 (no opcode 0: 0), for the static oilOpInfo of
	 OilInliningCompiler."
	| table |
	table := Array new: OilLastOpcode + 1 withAll: 0.
	self opInfoSpec doWithIndex:
		[:tuple :opcode|
		(self classPool at: ('Oil', tuple first) asSymbol) = opcode ifFalse: [self error: 'opInfoSpec out of order at ', tuple first].
		table
			at: opcode + 1
			put: ((tuple allButFirst: 2) inject: (tuple at: 2) into: [:info :property| info bitOr: (self classPool at: ('OilOp', property) asSymbol)])].
	^table! !

!OilInstructionConstants class methodsFor: 'accessing' stamp: 'cb 10/26/2026 20:30'!
opcodeNames
	"Answer the opcode names indexed by opcode (1-based, as opcodes start at 1)."
	^self opInfoSpec collect: [:tuple| tuple first]! !

OilInstructionConstants initialize!
