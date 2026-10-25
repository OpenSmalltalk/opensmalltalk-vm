SharedPool subclass: #OilInstructionConstants
	instanceVariableNames: ''
	classVariableNames: 'OilConstTagged OilConst64 OilMove OilAddTagged OilSubTagged OilAndTagged OilOrTagged OilXorTagged OilShiftTagged OilOddTagged OilLoadField OilStoreField OilLoadElement OilStoreElement OilCmpTagged OilBranchTrue OilBranchFalse OilJump OilReturn OilGuardClass OilCheckBounds OilCall0 OilCall1 OilCallN OilAddImmTagged OilCmpImmTagged OilLoadSize OilMakeClosure OilNewArray OilCallSuper OilAddImmTaggedNC OilModTagged OilLoadByteSize OilLoadByte OilLoadChar OilStoreByte OilStoreChar OilCompareBytes OilTrap OilCharValue OilStreamNext OilStreamNextPut OilLastOpcode'
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
	OilLastOpcode := 42.! !

!OilInstructionConstants class methodsFor: 'accessing' stamp: 'cb 10/25/2026 00:10'!
opcodeNames
	"Answer the opcode names indexed by opcode (1-based, as opcodes start at 1)."
	^#(ConstTagged Const64 Move AddTagged SubTagged AndTagged OrTagged XorTagged ShiftTagged OddTagged LoadField StoreField LoadElement StoreElement CmpTagged BranchTrue BranchFalse Jump Return GuardClass CheckBounds Call0 Call1 CallN AddImmTagged CmpImmTagged LoadSize MakeClosure NewArray CallSuper AddImmTaggedNC ModTagged LoadByteSize LoadByte LoadChar StoreByte StoreChar CompareBytes Trap CharValue StreamNext StreamNextPut)! !

OilInstructionConstants initialize!
