"
I generate x64 (x86-64) instructions from CogAbstractInstructions.  For reference see
1. IA-32 Intel® Architecture Software Developer's Manual Volume 2A: Instruction Set Reference, A-M
2. IA-32 Intel® Architecture Software Developer's Manual Volume 2A: Instruction Set Reference, N-Z
	http://www.intel.com/products/processor/manuals/
or
AMD64 Architecture Programmer's Manual Volume 3: General-Purpose and System Instructions
AMD64 Architecture Programmer's Manual Volume 4: 128-bit Media Instructions
AMD64 Architecture Programmer's Manual Volume 5: 64-bit Media and x87 Floating Point Instructions
	http://developer.amd.com/resources/documentation-articles/developer-guides-manuals/
(® is supposed to be the Unicode ""registered  sign"").
"
Class {
	#name : #CogX64Compiler,
	#superclass : #CogAbstractInstruction,
	#classVars : [
		'CDQ',
		'CLD',
		'CMPXCHGAwR',
		'CMPXCHGMwrR',
		'CPUID',
		'IDIVR',
		'IMULRR',
		'LFENCE',
		'LOCK',
		'MFENCE',
		'MOVSB',
		'MOVSQ',
		'ModReg',
		'ModRegInd',
		'ModRegIndDisp32',
		'ModRegIndSIB',
		'ModRegRegDisp32',
		'ModRegRegDisp8',
		'R10',
		'R11',
		'R12',
		'R13',
		'R14',
		'R15',
		'R8',
		'R9',
		'RAX',
		'RBP',
		'RBX',
		'RCX',
		'RDI',
		'RDX',
		'REP',
		'RSI',
		'RSP',
		'SFENCE',
		'SIB1',
		'SIB2',
		'SIB4',
		'SIB8',
		'SysV',
		'XCHGAwR',
		'XCHGMwrR',
		'XCHGRR',
		'XMM0L',
		'XMM10L',
		'XMM11L',
		'XMM12L',
		'XMM13L',
		'XMM14L',
		'XMM15L',
		'XMM1L',
		'XMM2L',
		'XMM3L',
		'XMM4L',
		'XMM5L',
		'XMM6L',
		'XMM7L',
		'XMM8L',
		'XMM9L'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CogX64Compiler class >> ISA [
	^#X64
]

{ #category : #accessing }
CogX64Compiler class >> VarBaseReg [
	"Answer the number of the reg we use to hold the base address of CoInterpreter variables"
	^RBX
]

{ #category : #translation }
CogX64Compiler class >> defaultCompilerClass [
	^CogInLineLiteralsX64Compiler
]

{ #category : #translation }
CogX64Compiler class >> identifyingPredefinedMacros [
	^#('x86_64' '__amd64' '__x86_64' '__amd64__' '__x86_64__' '_M_AMD64' '_M_X64')
]

{ #category : #translation }
CogX64Compiler class >> ifTranslateableAddWithOptionsTo: aCollection [
	"Override to create cogitX64.c and cogitX64Win64.c"
	(self wordSize = Cogit objectMemoryClass wordSize
	 and: [self identifyingPredefinedMacros notNil]) ifTrue:
		[aCollection
			"SysV must preceed _WIN64; see Cogit class>>#generateCodeStringForCogitDotC"
			add: {self. {#ISA. self ISA. #ABI. #SysV}}; 
			add: {self. {#ISA. self ISA. #ABI. #'_WIN64'}}]
]

{ #category : #'class initialization' }
CogX64Compiler class >> initialize [
	"Initialize various x64 instruction-related constants.
	 [1] IA-32 Intel® Architecture Software Developer's Manual Volume 2A: Instruction Set Reference, A-M"

	"CogX64Compiler initialize"

	self ~~ CogX64Compiler ifTrue: [^self].

	(self initializationOptions ifNil: [Dictionary new])
		at: #ABI
		ifPresent: [:abi| SysV := abi asUppercase ~= #WIN64 and: [abi asUppercase ~= #'_WIN64']]
		ifAbsent: [SysV := true]. "Default ABI; set to true for SysV, false for WIN64/_WIN64"

	RAX := 0.
	RCX := 1.  "Were they completely mad or simply sadistic?"
	RDX := 2.
	RBX := 3.
	RSP := 4.
	RBP := 5.
	RSI := 6.
	RDI := 7.
	R8 := 8.
	R9 := 9.
	R10 := 10.
	R11 := 11.
	R12 := 12.
	R13 := 13.
	R14 := 14.
	R15 := 15.

	XMM0L := 0.
	XMM1L := 1.
	XMM2L := 2.
	XMM3L := 3.
	XMM4L := 4.
	XMM5L := 5.
	XMM6L := 6.
	XMM7L := 7.
	XMM8L := 8.
	XMM9L := 9.
	XMM10L := 10.
	XMM11L := 11.
	XMM12L := 12.
	XMM13L := 13.
	XMM14L := 14.
	XMM15L := 15.

	"Mod R/M Mod fields.  See [1] Sec 2.4, 2.5 & 2.6 & Table 2-2"
	ModRegInd := 0.
		ModRegIndSIB := 4.
		ModRegIndDisp32 := 5.
	ModRegRegDisp8 := 1.
	ModRegRegDisp32 := 2.
	ModReg := 3.

	"SIB Scaled Index modes.  See [1] Sec 2.4, 2.5 & 2.6 & Table 2-3"
	SIB1 := 0.
	SIB2 := 1.
	SIB4 := 2.
	SIB8 := 3.

	"Specific instructions"
	self
		initializeSpecificOpcodes: #(CDQ IDIVR IMULRR CPUID LFENCE MFENCE SFENCE LOCK CMPXCHGAwR CMPXCHGMwrR XCHGAwR XCHGMwrR XCHGRR CLD REP MOVSB MOVSQ)
		in: thisContext method
]

{ #category : #'class initialization' }
CogX64Compiler class >> initializeAbstractRegisters [
	"Assign the abstract registers with the identities/indices of the relevant concrete registers."
	"[1] Figure 3.4 Register Usage in
		System V Application Binary Interface
		AMD64 Architecture Processor Supplement"

	super initializeAbstractRegisters.

	"N.B. RAX RCX & RDX are caller-save (scratch) registers.  Hence we use RCX for class and RDX for
		receiver/result since these are written in all normal sends."

	SysV
		ifTrue: [self initializeAbstractRegistersSysV]
		ifFalse: [self initializeAbstractRegistersWin64].

	NumRegisters := 16.

	DPFPReg0				:= XMM0L.
	DPFPReg1				:= XMM1L.
	DPFPReg2				:= XMM2L.
	DPFPReg3				:= XMM3L.
	DPFPReg4				:= XMM4L.
	DPFPReg5				:= XMM5L.
	DPFPReg6				:= XMM6L.
	DPFPReg7				:= XMM7L.
	DPFPReg8				:= XMM8L.
	DPFPReg9				:= XMM9L.
	DPFPReg10				:= XMM10L.
	DPFPReg11				:= XMM11L.
	DPFPReg12				:= XMM12L.
	DPFPReg13				:= XMM13L.
	DPFPReg14				:= XMM14L.
	DPFPReg15				:= XMM15L.

	NumFloatRegisters := 16
]

{ #category : #'class initialization' }
CogX64Compiler class >> initializeAbstractRegistersSysV [
	"Assign the abstract registers with the identities/indices of the relevant concrete registers."
	"[1] Figure 3.4 Register Usage in
		System V Application Binary Interface
		AMD64 Architecture Processor Supplement"

	"N.B. RAX RCX & RDX are caller-save (scratch) registers.  Hence we use RCX for class and RDX for
		receiver/result since these are written in all normal sends."

	CallerSavedRegisterMask := self
									registerMaskFor: RAX
									and: RCX
									and: RDX
									and: RSI
									and: RDI
									and: R8
									and: R9
									and: R10
									and: R11.

	TempReg				:= RAX.
	ClassReg				:= RCX.
	ReceiverResultReg		:= RDX.
	SendNumArgsReg		:= R9.
	SPReg					:= RSP.
	FPReg					:= RBP.
	Arg0Reg				:= RDI. "So as to agree with C ABI arg 0"
	Arg1Reg				:= RSI. "So as to agree with C ABI arg 1"
	VarBaseReg			:= RBX. "Must be callee saved"
	"R8 is either RISCTempReg or Extra6Reg depending on subclass."
	Extra0Reg				:= R10.
	Extra1Reg				:= R11.
	Extra2Reg				:= R12.
	Extra3Reg				:= R13.
	Extra4Reg				:= R14.
	Extra5Reg				:= R15
]

{ #category : #'class initialization' }
CogX64Compiler class >> initializeAbstractRegistersWin64 [
	"Assign the abstract registers with the identities/indices of the relevant concrete registers."

	"N.B. Since receiver/result are written in all normal sends,
	it's better to use scratch registers for them (those which are caller-saved).
	In Win64 ABI, this does not let that many choices:
	- RAX is TempReg (overwritten by result etc...)
	- RCX and RDX are used for first 2 args (see genMarshallNArgs:arg:arg:arg:arg:)
	- it remains R8,R9,R10 & R11 : we choose the first two"

	CallerSavedRegisterMask := self
									registerMaskFor: RAX
									and: RCX
									and: RDX
									and: R8
									and: R9
									and: R10
									and: R11.

	TempReg				:= RAX.
	ClassReg				:= R8.
	ReceiverResultReg		:= R9.
	SendNumArgsReg		:= R10.
	SPReg					:= RSP.
	FPReg					:= RBP.
	Arg0Reg				:= RCX. "So as to agree with C ABI arg 0"
	Arg1Reg				:= RDX. "So as to agree with C ABI arg 1"
	VarBaseReg			:= RBX. "Must be callee saved"
	"R11 is either RISCTempReg or Extra6Reg depending on subclass."
	Extra0Reg				:= RDI.
	Extra1Reg				:= RSI.
	Extra2Reg				:= R12.
	Extra3Reg				:= R13.
	Extra4Reg				:= R14.
	Extra5Reg				:= R15
]

{ #category : #testing }
CogX64Compiler class >> isAbstract [
	^self == CogX64Compiler
]

{ #category : #accessing }
CogX64Compiler class >> isSysV [
	"Answer true is ABI is SysV, false otherwise (for WIN64)"
	^SysV
]

{ #category : #translation }
CogX64Compiler class >> machineCodeDeclaration [
	"Answer the declaration for the machineCode array."
	^{#'unsigned char'. '[', self basicNew machineCodeBytes printString, ']'}
]

{ #category : #translation }
CogX64Compiler class >> moduleName [
	"CogAbstractInstruction subclasses collect: [:ea| ea moduleName]"
	^'cogit', self ISA, ((self initializationOptions at: #ABI ifAbsent: ['']) copyWithout: $_)
]

{ #category : #translation }
CogX64Compiler class >> wordSize [
	"This is a 64-bit ISA"
	^8
]

{ #category : #'register allocation' }
CogX64Compiler >> availableRegisterOrNoneFor: liveRegsMask [
	"Answer an unused abstract register in the liveRegMask.
	 Subclasses with more registers can override to answer them.
	 N.B. Do /not/ allocate TempReg."
	<returnTypeC: #sqInt>
	(cogit register: Extra5Reg isInMask: liveRegsMask) ifFalse:
		[^Extra5Reg].
	(cogit register: Extra4Reg isInMask: liveRegsMask) ifFalse:
		[^Extra4Reg].
	(cogit register: Extra3Reg isInMask: liveRegsMask) ifFalse:
		[^Extra3Reg].
	(cogit register: Extra2Reg isInMask: liveRegsMask) ifFalse:
		[^Extra2Reg].
	(cogit register: Extra1Reg isInMask: liveRegsMask) ifFalse:
		[^Extra1Reg].
	(cogit register: Extra0Reg isInMask: liveRegsMask) ifFalse:
		[^Extra0Reg].
	^super availableRegisterOrNoneFor: liveRegsMask
]

{ #category : #abi }
CogX64Compiler >> cFloatResultToRd: reg [
	XMM0L ~= reg ifTrue: [ 
		cogit MoveRd: XMM0L Rd: reg
	].
]

{ #category : #abi }
CogX64Compiler >> cFloatResultToRs: reg [
	XMM0L ~= reg ifTrue: [ 
		cogit MoveRs: XMM0L Rs: reg
	].
]

{ #category : #accessing }
CogX64Compiler >> cResultRegister [
	"Answer the register through which C functions return integral results."
	<inline: true>
	^RAX
]

{ #category : #accessing }
CogX64Compiler >> cResultRegisterHigh [
	"Answer the register through which C functions return the high part of big integral results."
	<inline: true>
	^ RDX
]

{ #category : #accessing }
CogX64Compiler >> cStackPointer [
	
	^ RSP
]

{ #category : #'full transfer run-time support' }
CogX64Compiler >> callFullTargetFromReturnAddress: callSiteReturnAddress [
	"Answer the address the full call immediately preceding callSiteReturnAddress will jump to."
	^self sixtyFourBitLiteralBefore: callSiteReturnAddress - 2
]

{ #category : #accessing }
CogX64Compiler >> callInstructionByteSize [
	^5
]

{ #category : #'inline cacheing' }
CogX64Compiler >> callTargetFromReturnAddress: callSiteReturnAddress [
	"Answer the address the call immediately preceding callSiteReturnAddress will jump to."
	| callDistance |
	callDistance := self literal32BeforeFollowingAddress: callSiteReturnAddress.
	^callSiteReturnAddress + callDistance signedIntFromLong
]

{ #category : #testing }
CogX64Compiler >> canDivQuoRem [
	^true
]

{ #category : #testing }
CogX64Compiler >> canMulRR [
	^true
]

{ #category : #testing }
CogX64Compiler >> canSignExtend [
	"x64 has native SignExtend8RR, SignExtend16RR, & SignExtend32RR."
	<inline: true>
	^true
]

{ #category : #testing }
CogX64Compiler >> canZeroExtend [
	"x64 has native ZeroExtend8RR, ZeroExtend16RR, & ZeroExtend32RR."
	<inline: true>
	^true
]

{ #category : #accessing }
CogX64Compiler >> cmpC32RTempByteSize [
	^5
]

{ #category : #accessing }
CogX64Compiler >> codeGranularity [
	^1
]

{ #category : #'generate machine code' }
CogX64Compiler >> computeMaximumSize [
	"Compute the maximum size for each opcode.  This allows jump offsets to
	 be determined, provided that all backward branches are long branches."
	"N.B.  The ^N forms are to get around the bytecode compiler's long branch
	 limits which are exceeded when each case jumps around the otherwise."
	opcode caseOf: {
		"Noops & Pseudo Ops"
		[Label]					-> [^0].
		[AlignmentNops]		-> [^(operands at: 0) - 1].
		[Fill32]					-> [^4].
		[Nop]					-> [^1].
		"Specific Control/Data Movement"
		[CDQ]					-> [^2].
		[IDIVR]					-> [^3].
		[IMULRR]				-> [^4].
		[CPUID]					-> [^2].
		[CMPXCHGAwR]			-> [^8].
		[CMPXCHGMwrR]		-> [^9].
		[LFENCE]				-> [^3].
		[MFENCE]				-> [^3].
		[SFENCE]				-> [^3].
		[LOCK]					-> [^1].
		[XCHGAwR]				-> [^6].
		[XCHGMwrR]			-> [^7].
		[XCHGRR]				-> [^((operands at: 0) = RAX
									   or: [(operands at: 1) = RAX])
											ifTrue: [2]
											ifFalse: [3]].
		[REP]					-> [^1].
		[CLD]					-> [^1].
		[MOVSB]				-> [^1].
		[MOVSQ]				-> [^2].
		"Control"
		[CallFull]					-> [^12].
		[Call]						-> [^5].
		[CallR]						-> [^3].
		[JumpR]					-> [^3].
		[JumpFull]					-> [self resolveJumpTarget. ^12].
		[JumpLong]					-> [self resolveJumpTarget. ^5].
		[Jump]						-> [self resolveJumpTarget. ^5].
		[JumpZero]					-> [self resolveJumpTarget. ^6].
		[JumpNonZero]				-> [self resolveJumpTarget. ^6].
		[JumpNegative]				-> [self resolveJumpTarget. ^6].
		[JumpNonNegative]			-> [self resolveJumpTarget. ^6].
		[JumpOverflow]				-> [self resolveJumpTarget. ^6].
		[JumpNoOverflow]			-> [self resolveJumpTarget. ^6].
		[JumpCarry]				-> [self resolveJumpTarget. ^6].
		[JumpNoCarry]				-> [self resolveJumpTarget. ^6].
		[JumpLess]					-> [self resolveJumpTarget. ^6].
		[JumpGreaterOrEqual]		-> [self resolveJumpTarget. ^6].
		[JumpGreater]				-> [self resolveJumpTarget. ^6].
		[JumpLessOrEqual]			-> [self resolveJumpTarget. ^6].
		[JumpBelow]				-> [self resolveJumpTarget. ^6].
		[JumpAboveOrEqual]		-> [self resolveJumpTarget. ^6].
		[JumpAbove]				-> [self resolveJumpTarget. ^6].
		[JumpBelowOrEqual]		-> [self resolveJumpTarget. ^6].
		[JumpLongZero]			-> [self resolveJumpTarget. ^6].
		[JumpLongNonZero]		-> [self resolveJumpTarget. ^6].
		[JumpFPEqual]				-> [self resolveJumpTarget. ^6].
		[JumpFPNotEqual]			-> [self resolveJumpTarget. ^6].
		[JumpFPLess]				-> [self resolveJumpTarget. ^6].
		[JumpFPGreaterOrEqual]	-> [self resolveJumpTarget. ^6].
		[JumpFPGreater]			-> [self resolveJumpTarget. ^6].
		[JumpFPLessOrEqual]		-> [self resolveJumpTarget. ^6].
		[JumpFPOrdered]			-> [self resolveJumpTarget. ^6].
		[JumpFPUnordered]			-> [self resolveJumpTarget. ^6].
		[RetN]						-> [^(operands at: 0) = 0 ifTrue: [1] ifFalse: [3]].
		[Stop]						-> [^1].

		"Arithmetic"
		[AddCqR]		-> [^self computeSizeOfArithCqR].
		[AddcCqR]		-> [^self computeSizeOfArithCqR].
		[AndCqR]		-> [^self computeSizeOfArithCqR].
		[CmpCqR]		-> [^self computeSizeOfArithCqR].
		[OrCqR]		-> [^self computeSizeOfArithCqR].
		[SubCqR]		-> [^self computeSizeOfArithCqR].
		[SubbCqR]		-> [^self computeSizeOfArithCqR].
		[TstCqR]		-> [^self computeSizeOfArithCqR].
		[AddCwR]		-> [^self computeSizeOfArithCwR].
		[AndCwR]		-> [^self computeSizeOfArithCwR].
		[CmpCwR]		-> [^self computeSizeOfArithCwR].
		[CmpC32R]		-> [^(operands at: 1) <= 7
								ifTrue: [(operands at: 1) = RAX
											ifTrue: [5]
											ifFalse: [6]]
								ifFalse: [7]].
		[OrCwR]		-> [^self computeSizeOfArithCwR].
		[SubCwR]		-> [^self computeSizeOfArithCwR].
		[XorCwR]		-> [^self computeSizeOfArithCwR].
		[AddRR]		-> [^3].
		[AddcRR]		-> [^3].
		[AndRR]		-> [^3].
		[CmpRR]		-> [^3].
		[OrRR]			-> [^3].
		[XorRR]			-> [^3].
		[SubRR]		-> [^3].
		[SubbRR]		-> [^3].
		[NegateR]		-> [^3].
		[LoadEffectiveAddressMwrR]
						-> [^((self isQuick: (operands at: 0))
									ifTrue: [4]
									ifFalse: [7])
								+ (((operands at: 1) bitAnd: 7) = RSP
									ifTrue: [1]
									ifFalse: [0])].
		[LogicalShiftLeftCqR]		-> [^(operands at: 0) = 1 ifTrue: [3] ifFalse: [4]].
		[LogicalShiftRightCqR]		-> [^(operands at: 0) = 1 ifTrue: [3] ifFalse: [4]].
		[ArithmeticShiftRightCqR]	-> [^(operands at: 0) = 1 ifTrue: [3] ifFalse: [4]].
		[RotateRightCqR]			-> [^(operands at: 0) = 1 ifTrue: [3] ifFalse: [4]].
		[RotateLeftCqR]			-> [^(operands at: 0) = 1 ifTrue: [3] ifFalse: [4]].
		[LogicalShiftLeftRR]			-> [^self computeShiftRRSize].
		[LogicalShiftRightRR]		-> [^self computeShiftRRSize].
		[ArithmeticShiftRightRR]		-> [^self computeShiftRRSize].
		[AddRdRd]					-> [^ 4 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
											ifTrue: [1]
											ifFalse: [0])].
		[CmpRdRd]					-> [^ 4
											+ ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
											ifTrue: [1]
											ifFalse: [0])].
		[SubRdRd]					-> [^ 4 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
											ifTrue: [1]
											ifFalse: [0])].
		[MulRdRd]					-> [^ 4 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
											ifTrue: [1]
											ifFalse: [0])].
		[DivRdRd]					-> [^ 4 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
											ifTrue: [1]
											ifFalse: [0])].
		[SqrtRd]					-> [^ 4 + (((operands at: 0) > 7)
											ifTrue: [1]
											ifFalse: [0])].
		[XorRdRd]					-> [^ 4 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
											ifTrue: [1]
											ifFalse: [0])].
						
		[AddRsRs]				-> [^ 4 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
											ifTrue: [1]
											ifFalse: [0])].
		[CmpRsRs]				-> [^ 3 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
											ifTrue: [1]
											ifFalse: [0])].
		[SubRsRs]				-> [^ 4 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
											ifTrue: [1]
											ifFalse: [0])].
		[MulRsRs]				-> [^ 4 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
											ifTrue: [1]
											ifFalse: [0])].
		[DivRsRs]				-> [^ 4 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
											ifTrue: [1]
											ifFalse: [0])].
		[SqrtRs]					-> [^ 4 + (((operands at: 0) > 7)
											ifTrue: [1]
											ifFalse: [0])].
		[XorRsRs]					-> [^ 3 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
											ifTrue: [1]
											ifFalse: [0])].
						
		"Data Movement"
		[MoveCqR]		-> [^(operands at: 0) = 0
								ifTrue: [3]
								ifFalse:
									[(self is32BitSignedImmediate: (operands at: 0))
										ifTrue: [7]
										ifFalse: [self moveCwRByteSize - 1]]].
		[MoveCwR]		-> [^(self inCurrentCompilation: (operands at: 0))
								ifTrue: [7]
								ifFalse: [self moveCwRByteSize]].
		[MoveC32R]	-> [^7]. "N.B. Always inlined."
		[MoveRR]		-> [^3].
		[MoveRdRd]		-> [^4 
								+((((operands at: 1) > 7) or: [(operands at: 0) > 7])
											ifTrue: [1]
											ifFalse: [0])].
		[MoveRsRs]		-> [^4
								 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
											ifTrue: [1]
											ifFalse: [0])].
		[MoveRRd]		-> [^5].
		[MoveRdR]		-> [^5].
		[MoveAwR]		-> [^(self isAddressRelativeToVarBase: (operands at: 0))
								ifTrue: [7]
								ifFalse: [(operands at: 1) = RAX ifTrue: [10] ifFalse: [14]]].
		[MoveA32R]	-> [^(operands at: 1) = RAX ifTrue: [9] ifFalse: [13]].
		[MoveRAw]		-> [^(self isAddressRelativeToVarBase: (operands at: 1))
								ifTrue: [7]
								ifFalse: [(operands at: 0) = RAX ifTrue: [10] ifFalse: [14]]].
		[MoveRA32]	-> [^(operands at: 0) = RAX ifTrue: [9] ifFalse: [13]].
		[MoveAbR]		-> [^(self isAddressRelativeToVarBase: (operands at: 0))
								ifTrue: [7]
								ifFalse: [(operands at: 1) = RAX ifTrue: [10] ifFalse: [14]]].
		[MoveRAb]		-> [^(self isAddressRelativeToVarBase: (operands at: 1))
								ifTrue: [7]
								ifFalse: [(operands at: 0) = RAX ifTrue: [10] ifFalse: [14]]].
		[MoveRMwr]	-> [self assert: (self is32BitSignedImmediate: (operands at: 1)).
							^((self isQuick: (operands at: 1))
									ifTrue: [((operands at: 1) = 0
											and: [((operands at: 2) bitAnd: 7) ~= RBP])
												ifTrue: [3]
												ifFalse: [4]]
									ifFalse: [7])
								+ (((operands at: 2) bitAnd: 7) = RSP
									ifTrue: [1]
									ifFalse: [0])].
		[MoveRM32r]	-> [^((self isQuick: (operands at: 1))
								ifTrue: [((operands at: 1) = 0
										and: [((operands at: 2) bitAnd: 6) ~= RSP])
											ifTrue: [2]
											ifFalse: [3]]
								ifFalse: [6])
							+ ((((operands at: 2) bitAnd: 7) = RSP and: [(operands at: 1) ~= 0])
								ifTrue: [1]
								ifFalse: [0])
							+ ((((operands at: 2) > 7) or: [(operands at: 0) > 7])
								ifTrue: [1]
								ifFalse: [0])].
		[MoveRsM32r]	-> [^((self isQuick: (operands at: 1))
								ifTrue: [((operands at: 1) = 0
										and: [((operands at: 2) bitAnd: 6) ~= RSP])
											ifTrue: [4]
											ifFalse: [5]]
								ifFalse: [8])
							+ ((((operands at: 2) bitAnd: 7) = RSP and: [(operands at: 1) ~= 0])
								ifTrue: [1]
								ifFalse: [0])
							+ ((((operands at: 2) > 7) or: [(operands at: 0) > 7])
								ifTrue: [1]
								ifFalse: [0])].
		[MoveRdM64r]	-> [^((self isQuick: (operands at: 1))
								ifTrue: [((operands at: 1) = 0
										and: [((operands at: 2) bitAnd: 6) ~= RSP])
											ifTrue: [4]
											ifFalse: [5]]
								ifFalse: [8])
							+ ((((operands at: 2) bitAnd: 7) = RSP and: [(operands at: 1) ~= 0])
								ifTrue: [1]
								ifFalse: [0])
							+ ((((operands at: 2) > 7) or: [(operands at: 0) > 7])
								ifTrue: [1]
								ifFalse: [0])].
		[MoveMbrR]		-> [self assert: (self is32BitSignedImmediate: (operands at: 0)).
							^((self isQuick: (operands at: 0))
									ifTrue: [((operands at: 0) = 0
											and: [((operands at: 1) bitAnd: 7) ~= RBP])
												ifTrue: [3]
												ifFalse: [4]]
									ifFalse: [7])
								+ (((operands at: 1) bitAnd: 7) = RSP
									ifTrue: [1]
									ifFalse: [0])].
		[MoveRMbr]		-> [self assert: (self is32BitSignedImmediate: (operands at: 1)).
							^((self isQuick: (operands at: 1))
									ifTrue: [((operands at: 1) = 0
											and: [((operands at: 0) bitAnd: 7) ~= RBP])
												ifTrue: [3]
												ifFalse: [4]]
									ifFalse: [7])
								+ (((operands at: 2) bitAnd: 7) = RSP
									ifTrue: [1]
									ifFalse: [0])].
		[MoveM8rR]		-> [self assert: (self is32BitSignedImmediate: (operands at: 0)).
							^((self isQuick: (operands at: 0))
									ifTrue: [((operands at: 0) = 0
											and: [((operands at: 1) bitAnd: 7) ~= RBP])
												ifTrue: [3]
												ifFalse: [4]]
									ifFalse: [7])
								+ (((operands at: 1) bitAnd: 7) = RSP
									ifTrue: [1]
									ifFalse: [0])].
		[MoveMs8rR]		-> [self assert: (self is32BitSignedImmediate: (operands at: 0)).
							^((self isQuick: (operands at: 0))
									ifTrue: [((operands at: 0) = 0
											and: [((operands at: 1) bitAnd: 7) ~= RBP])
												ifTrue: [3]
												ifFalse: [4]]
									ifFalse: [7])
								+ (((operands at: 1) bitAnd: 7) = RSP
									ifTrue: [1]
									ifFalse: [0])].
		[MoveRM8r]		-> [self assert: (self is32BitSignedImmediate: (operands at: 1)).
							^((self isQuick: (operands at: 1))
									ifTrue: [((operands at: 1) = 0
											and: [((operands at: 0) bitAnd: 7) ~= RBP])
												ifTrue: [3]
												ifFalse: [4]]
									ifFalse: [7])
								+ (((operands at: 2) bitAnd: 7) = RSP
									ifTrue: [1]
									ifFalse: [0])].
		[MoveM16rR]	-> [self assert: (self is32BitSignedImmediate: (operands at: 0)).
							^((self isQuick: (operands at: 0))
									ifTrue: [((operands at: 0) = 0
											and: [((operands at: 1) bitAnd: 7) ~= RBP])
												ifTrue: [4]
												ifFalse: [5]]
									ifFalse: [8])
								+ (((operands at: 1) bitAnd: 7) = RSP
									ifTrue: [1]
									ifFalse: [0])].
		[MoveRM16r]	-> [self assert: (self is32BitSignedImmediate: (operands at: 1)).
							^((self isQuick: (operands at: 1))
									ifTrue: [4]
									ifFalse: [7])
								+ (((operands at: 2) bitAnd: 7) = RSP
									ifTrue: [1]
									ifFalse: [0])
								+ (((operands at: 0) > 7 or: [(operands at: 2) > 7])
									ifTrue: [1]
									ifFalse: [0])].
		[MoveM32rR]	-> [^((self isQuick: (operands at: 0))
								ifTrue: [((operands at: 0) = 0
										and: [((operands at: 1) bitAnd: 6) ~= RSP])
											ifTrue: [2]
											ifFalse: [3]]
								ifFalse: [6])
							+ ((((operands at: 1) bitAnd: 7) = RSP and: [(operands at: 0) ~= 0])
								ifTrue: [1]
								ifFalse: [0])
							+ ((((operands at: 1) > 7) or: [(operands at: 2) > 7])
								ifTrue: [1]
								ifFalse: [0])].
		[MoveM32rRs]	-> [^((self isQuick: (operands at: 0))
								ifTrue: [((operands at: 0) = 0
										and: [((operands at: 1) bitAnd: 6) ~= RSP])
											ifTrue: [4]
											ifFalse: [5]]
								ifFalse: [8])
							+ ((((operands at: 1) bitAnd: 7) = RSP and: [(operands at: 0) ~= 0])
								ifTrue: [1]
								ifFalse: [0])
							+ ((((operands at: 1) > 7) or: [(operands at: 2) > 7])
								ifTrue: [1]
								ifFalse: [0])].
		[MoveM64rRd]	-> [^((self isQuick: (operands at: 0))
								ifTrue: [((operands at: 0) = 0
										and: [((operands at: 1) bitAnd: 6) ~= RSP])
											ifTrue: [4]
											ifFalse: [5]]
								ifFalse: [8])
							+ ((((operands at: 1) bitAnd: 7) = RSP and: [(operands at: 0) ~= 0])
								ifTrue: [1]
								ifFalse: [0])
							+ ((((operands at: 1) > 7) or: [(operands at: 2) > 7])
								ifTrue: [1]
								ifFalse: [0])].
		[MoveMwrR]	-> [self assert: (self is32BitSignedImmediate: (operands at: 0)).
							^((self isQuick: (operands at: 0))
								ifTrue: [((operands at: 0) = 0
										and: [((operands at: 1) bitAnd: 7) ~= RBP])
											ifTrue: [3]
											ifFalse: [4]]
								ifFalse: [7])
							+ (((operands at: 1) bitAnd: 7) = RSP
								ifTrue: [1]
								ifFalse: [0])].
		[MoveXbrRR]	-> [self assert: (operands at: 0) ~= RSP.
							^((operands at: 1) bitAnd: 7) = RBP
											ifTrue: [5]
											ifFalse: [4]].
		[MoveRXbrR]	->	[self assert: (operands at: 1) ~= RSP.
							^(((operands at: 0) > 3
							   or: [(operands at: 1) > 7
							   or: [(operands at: 2) > 7]])
								ifTrue: [4]
								ifFalse: [3])
							+ (((operands at: 2) bitAnd: 7) = RBP
								ifTrue: [1]
								ifFalse: [0])].
		[MoveXwrRR]	-> [self assert: (operands at: 0) ~= RSP.
							^((operands at: 1) = RBP
							   or: [(operands at: 1) = R13])
											ifTrue: [5]
											ifFalse: [4]].
		[MoveRXwrR]	-> [self assert: (operands at: 1) ~= RSP.
							^((operands at: 2) = RBP
							   or: [(operands at: 2) = R13])
											ifTrue: [5]
											ifFalse: [4]].
		[MoveX32rRR]	-> [self assert: (operands at: 0) ~= RSP.
							^(((operands at: 1) = RBP
							   or: [(operands at: 1) = R13])
										ifTrue: [7]
										ifFalse: [6])
							 + (((operands at: 0) > 7
							     or: [(operands at: 1) > 7
							     or: [(operands at: 2) > 7]])
										ifTrue: [1]
										ifFalse: [0])].
		[MoveRX32rR]	-> [self assert: (operands at: 1) ~= RSP.
							^(((operands at: 2) = RBP
							   or: [(operands at: 2) = R13])
										ifTrue: [4]
										ifFalse: [3])
							 + (((operands at: 0) > 7
							     or: [(operands at: 1) > 7
							     or: [(operands at: 2) > 7]])
										ifTrue: [1]
										ifFalse: [0])].
		[PopR]			-> [^(operands at: 0) < 8 ifTrue: [1] ifFalse: [2]].
		[PushR]			-> [^(operands at: 0) < 8 ifTrue: [1] ifFalse: [2]].
		[PushCq]		-> [^(self isQuick: (operands at: 0))
								ifTrue: [2]
								ifFalse:
									[(self is32BitSignedImmediate: (operands at: 0))
										ifTrue: [5]
										ifFalse: [self computeSizeOfPushCw]]].
		[PushCw]		-> [^self computeSizeOfPushCw].
		[PrefetchAw]	-> [^(self isAddressRelativeToVarBase: (operands at: 0)) ifTrue: [7] ifFalse: [0]].
		"Conversion"
		[ConvertRRd]		-> [^5].
		[ConvertRdR]		-> [^5].
		[ConvertRRs]		-> [^4 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
									ifTrue: [1]
									ifFalse: [0])].
		[ConvertRsR]		-> [^4 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
									ifTrue: [1]
									ifFalse: [0])].
		[ConvertRsRd]	-> [^4 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
									ifTrue: [1]
									ifFalse: [0])].
		[ConvertRdRs]	-> [^4 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
									ifTrue: [1]
									ifFalse: [0])].

		[SignExtend8RR] -> [^4].
		[SignExtend16RR] -> [^4].
		[SignExtend32RR] -> [^4].
		[ZeroExtend8RR] -> [^4].
		[ZeroExtend16RR] -> [^4].
		[ZeroExtend32RR] -> [^2 + ((((operands at: 1) > 7) or: [(operands at: 0) > 7])
									ifTrue: [1]
									ifFalse: [0])].
								
		"This is a fixed size instruction using a patcheable literal. This takes ALWAYS 7 bytes"
		[MovePatcheableC32R] -> [ ^ 7 ]
		}.
	^0 "to keep C compiler quiet"
]

{ #category : #'generate machine code' }
CogX64Compiler >> computeShiftRRSize [
	"On the x86 the only instructions that shift by the value of a
	 register require the shift count to be  in %ecx.  So we may
	 have to use swap instructions to get the count into ecx."
	| shiftCountReg |
	shiftCountReg := operands at: 0.
	^shiftCountReg = RCX
		ifTrue: [3]
		ifFalse:
			[shiftCountReg = RAX
				ifTrue: [2 "XCHG RAX,r2" + 3 "Sxx" + 2 "XCHG RAX,r2"]
				ifFalse: [3 "XCHG r1,r2" + 3 "Sxx" + 3 "XCHG r1,r2"]]
]

{ #category : #'generate machine code' }
CogX64Compiler >> computeSizeOfArithCqR [
	self subclassResponsibility
]

{ #category : #'generate machine code' }
CogX64Compiler >> computeSizeOfArithCwR [
	"The implementation depends on in-line or out-of-line literals."
	^self subclassResponsibility
]

{ #category : #'generate machine code' }
CogX64Compiler >> computeSizeOfPushCw [
	^(self inCurrentCompilation: (operands at: 0))
		ifTrue: [9]
		ifFalse: [self pushCwByteSize]
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeAlignmentNops [
	<inline: true>
	self flag: 'if performance is an issue generate longer nops'.
	0 to: machineCodeSize - 1 do:
		[:i|
		machineCode at: i put: 16r90]
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeArithCqRWithRO: regOpcode raxOpcode: raxOpcode [
	"Will get inlined into concretizeAt: switch."
	<inline: false>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	machineCode
		at: 0 put: (self rexR: 0 x: 0 b: reg).
	(self isQuick: value) ifTrue:
		[machineCode
			at: 1 put: 16r83;
			at: 2 put: (self mod: ModReg RM: reg RO: regOpcode);
			at: 3 put: (value bitAnd: 16rFF).
		 ^machineCodeSize := 4].
	(self is32BitSignedImmediate: value) ifTrue:
		[reg = RAX ifTrue:
			[machineCode
				at: 1 put: raxOpcode;
				at: 2 put: (value bitAnd: 16rFF);
				at: 3 put: (value >> 8 bitAnd: 16rFF);
				at: 4 put: (value >> 16 bitAnd: 16rFF);
				at: 5 put: (value >> 24 bitAnd: 16rFF).
			 ^machineCodeSize := 6].
		machineCode
			at: 1 put: 16r81;
			at: 2 put: (self mod: ModReg RM: reg RO: regOpcode);
			at: 3 put: (value bitAnd: 16rFF);
			at: 4 put: (value >> 8 bitAnd: 16rFF);
			at: 5 put: (value >> 16 bitAnd: 16rFF);
			at: 6 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 7].
	^self concretizeArithCwR: (raxOpcode = 16r3D "Cmp" ifTrue: [16r39] ifFalse: [raxOpcode - 2])
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeCDQ [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	machineCode
		at: 0 put: 16r48;
		at: 1 put: 16r99.
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeCLD [
	<inline: true>
	machineCode at: 0 put: 16rFC.
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeCall [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset |
	self assert: (operands at: 0) ~= 0.
	offset := (operands at: 0) signedIntFromLong - (address + 5) signedIntFromLong.
	machineCode
		at: 0 put: 16rE8;
		at: 1 put: (offset bitAnd: 16rFF);
		at: 2 put: (offset >> 8 bitAnd: 16rFF);
		at: 3 put: (offset >> 16 bitAnd: 16rFF);
		at: 4 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 5
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeCallFull [
	"Since CallFull (and JumpFull) is used to invoke code in dynamically-loaded plugins it shouldn't
	 assume that code will be loaded within 2Gb of the code zone.  Hence generate a full 64-bit call,
	 movabsq $0x123456789abcdef0, %rax; callq *%rax."
	<inline: true>
	| operand |
	operand := operands at: 0.
	machineCode
		at: 0 put: 16r48;
		at: 1 put: 16rB8;
		at: 2 put: (operand bitAnd: 16rFF);
		at: 3 put: (operand >> 8 bitAnd: 16rFF);
		at: 4 put: (operand >> 16 bitAnd: 16rFF);
		at: 5 put: (operand >> 24 bitAnd: 16rFF);
		at: 6 put: (operand >> 32 bitAnd: 16rFF);
		at: 7 put: (operand >> 40 bitAnd: 16rFF);
		at: 8 put: (operand >> 48 bitAnd: 16rFF);
		at: 9 put: (operand >> 56 bitAnd: 16rFF);
		at: 10 put: 16rFF;
		at: 11 put: (self mod: ModReg RM: RAX RO: 2).
	^machineCodeSize := 12
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeCallR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := operands at: 0.
	machineCode
		at: 0 put: (self rexR: 0 x: 0 b: reg);
		at: 1 put: 16rFF;
		at: 2 put: (self mod: ModReg RM: reg RO: 2).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeCmpC32R [
	"Will get inlined into concretizeAt: switch."
	"N.B. This use of 32-bit comparss allows us to squeak by and use a short jump
	 in PIC case dispatch, where a jump to the abort is 126 bytes (!!)."
	<inline: true>
	| value reg skip |
	value := operands at: 0.
	reg := operands at: 1.
	reg = RAX
		ifTrue:
			[machineCode at: 0 put: 16r3D.
			 skip := 0]
		ifFalse:
			[reg > 7
				ifTrue:
					[machineCode at: 0 put: 16r41.
					 skip := 2]
				ifFalse:
					[skip := 1].
			 machineCode
				at: skip - 1 put: 16r81;
				at: skip put:  (self mod: ModReg RM: reg RO: 7)].
	machineCode		
		at: skip + 1 put: (value bitAnd: 16rFF);
		at: skip + 2 put: (value >> 8 bitAnd: 16rFF);
		at: skip + 3 put: (value >> 16 bitAnd: 16rFF);
		at: skip + 4 put: (value >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 5 + skip
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeCmpRdRd [
	"Will get inlined into concretizeAt: switch.
	 We use UCOMISD (see p 4-260 [2])"
	<inline: true>
	| regLHS regRHS skip |
	"CmpRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	
	machineCode
		at: 0 put: 16r66.
	(regLHS <= 7 and: [regRHS <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: regLHS x: 0 b: regRHS)].	
	
	machineCode
		at: skip + 1 put: 16r0F;
		at: skip + 2 put: 16r2E;
		at: skip + 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^machineCodeSize := skip + 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeCmpRsRs [
	"Will get inlined into concretizeAt: switch.
	 We use UCOMISS"
	<inline: true>
	| regLHS regRHS skip |
	"CmpRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	
	(regLHS <= 7 and: [regRHS <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: regLHS x: 0 b: regRHS)].
		
	machineCode
		at: skip + 0 put: 16r0F;
		at: skip + 1 put: 16r2E;
		at: skip + 2 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^machineCodeSize := skip + 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeConditionalJump: conditionCode [
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| offset |
	offset := self computeJumpTargetOffsetPlus: 2.
	(machineCodeSize = 0 "size not determined because no sizeJump pass; generating initial trampolines"
		ifTrue: [self isQuick: offset]
		ifFalse: [machineCodeSize = 2]) ifTrue:
		[machineCode
			at: 0 put: 16r70 + conditionCode;
			at: 1 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 2].
	^self concretizeConditionalJumpLong: conditionCode
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeConditionalJumpLong: conditionCode [
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| offset |
	offset := self computeJumpTargetOffsetPlus: 6.
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16r80 + conditionCode;
		at: 2 put: (offset bitAnd: 16rFF);
		at: 3 put: (offset >> 8 bitAnd: 16rFF);
		at: 4 put: (offset >> 16 bitAnd: 16rFF);
		at: 5 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeConvertRRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg destReg |
	srcReg := operands at:0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF2;
		at: 1 put: (self rexR: destReg x: 0 b: srcReg);
		at: 2 put: 16r0F;
		at: 3 put: 16r2A;
		at: 4 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^machineCodeSize := 5
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeConvertRRs [
	"Will get inlined into concretizeAt: switch."
	"CVTSI2SS"
	<inline: true>
	| srcReg destReg skip |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF3.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: destReg x: 0 b: srcReg)].
		
	machineCode
		at: skip + 1 put: 16r0F;
		at: skip + 2 put: 16r2A;
		at: skip + 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^machineCodeSize := skip + 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeConvertRdR [
	"Will get inlined into concretizeAt: switch."
	"CVTSD2SI"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at:0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF2;
		at: 1 put: (self rexR: destReg x: 0 b: srcReg);
		at: 2 put: 16r0F;
		at: 3 put: 16r2D;
		at: 4 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^machineCodeSize := 5
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeConvertRdRs [
	"Will get inlined into concretizeAt: switch."
	"CVTSD2SS"
	<inline: true>
	| srcReg destReg skip |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF2.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: destReg x: 0 b: srcReg)].
		
	machineCode
		at: skip + 1 put: 16r0F;
		at: skip + 2 put: 16r5A;
		at: skip + 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^machineCodeSize := skip + 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeConvertRsR [
	"Will get inlined into concretizeAt: switch."
	"CVTSS2SI"
	<inline: true>
	| srcReg destReg skip |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF3.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: destReg x: 0 b: srcReg)].
		
	machineCode 
		at: skip + 1 put: 16r0F;
		at: skip + 2 put: 16r2D;
		at: skip + 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^machineCodeSize := skip + 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeConvertRsRd [
	"Will get inlined into concretizeAt: switch."
	"CVTSS2SD"
	<inline: true>
	| srcReg destReg skip |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF3.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: destReg x: 0 b: srcReg)].
		
	machineCode
		at: skip + 1 put: 16r0F;
		at: skip + 2 put: 16r5A;
		at: skip + 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^machineCodeSize := skip + 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeFENCE: regOpcode [
	<inline: true>
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16rAE;
		at: 2 put: (self mod: ModReg RM: 0 RO: regOpcode).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeFill32 [
	<inline: true>
	| word |
	<var: #word type: #'usqIntptr_t'>
	word := operands at: 0.
	machineCode at: 0 put: (word bitAnd: 16rFF).
	machineCode at: 1 put: (word >> 8 bitAnd: 16rFF).
	machineCode at: 2 put: (word >> 16 bitAnd: 16rFF).
	machineCode at: 3 put: (word >> 24 bitAnd: 16rFF).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeIDIVR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regDivisor |
	regDivisor := operands at: 0.
	machineCode
		at: 0 put: (self rexR: 0 x: 0 b: regDivisor);
		at: 1 put: 16rF7;
		at: 2 put: (self mod: ModReg RM: regDivisor RO: 7).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeJump [
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| jumpTarget offset |
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := cogit cCoerceSimple: (operands at: 0) to: #'AbstractInstruction *'.
	cogit assertSaneJumpTarget: jumpTarget.
	(self isAnInstruction: jumpTarget) ifTrue:
		[jumpTarget := cogit cCoerceSimple: jumpTarget address to: #'AbstractInstruction *'].
	self assert: jumpTarget ~= 0.
	offset := jumpTarget signedIntFromLong - (address + 2) signedIntFromLong.
	(machineCodeSize = 0 "size not determined because no sizeJump pass; generating initial trampolines"
		ifTrue: [self isQuick: offset]
		ifFalse: [machineCodeSize = 2]) ifTrue:
		[machineCode
			at: 0 put: 16rEB;
			at: 1 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 2].
	offset := jumpTarget signedIntFromLong - (address + 5) signedIntFromLong.
	machineCode
		at: 0 put: 16rE9;
		at: 1 put: (offset bitAnd: 16rFF);
		at: 2 put: (offset >> 8 bitAnd: 16rFF);
		at: 3 put: (offset >> 16 bitAnd: 16rFF);
		at: 4 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 5
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeJumpFull [
	"Since JumpFull (and CallFull) is used to invoke code in dynamically-loaded plugins it shouldn't
	 assume that code will be loaded within 2Gb of the code zone.  Hence generate a full 64-bit call,
	 movabsq 0x123456789abcdef0, %rax; jmpq *%rax."
	<inline: true>
	| operand |
	operand := operands at: 0.
	machineCode
		at: 0 put: 16r48;
		at: 1 put: 16rB8;
		at: 2 put: (operand bitAnd: 16rFF);
		at: 3 put: (operand >> 8 bitAnd: 16rFF);
		at: 4 put: (operand >> 16 bitAnd: 16rFF);
		at: 5 put: (operand >> 24 bitAnd: 16rFF);
		at: 6 put: (operand >> 32 bitAnd: 16rFF);
		at: 7 put: (operand >> 40 bitAnd: 16rFF);
		at: 8 put: (operand >> 48 bitAnd: 16rFF);
		at: 9 put: (operand >> 56 bitAnd: 16rFF);
		at: 10 put: 16rFF;
		at: 11 put: (self mod: ModReg RM: RAX RO: 4).
	^machineCodeSize := 12
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeJumpLong [
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| jumpTarget offset |
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := cogit cCoerceSimple: (operands at: 0) to: #'AbstractInstruction *'.
	(self isAnInstruction: jumpTarget) ifTrue:
		[jumpTarget := cogit cCoerceSimple: jumpTarget address to: #'AbstractInstruction *'].
	self assert: jumpTarget ~= 0.
	offset := jumpTarget signedIntFromLong - (address + 5) signedIntFromLong.
	machineCode
		at: 0 put: 16rE9;
		at: 1 put: (offset bitAnd: 16rFF);
		at: 2 put: (offset >> 8 bitAnd: 16rFF);
		at: 3 put: (offset >> 16 bitAnd: 16rFF);
		at: 4 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 5
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeJumpR [
	<inline: true>
	| reg |
	reg := operands at: 0.
	machineCode
		at: 0 put: (self rexR: 0 x: 0 b: reg);
		at: 1 put: 16rFF;
		at: 2 put: (self mod: ModReg RM: reg RO: 4).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeLoadEffectiveAddressMwrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	machineCode
		at: 0 put: (self rexR: destReg x: 0 b: srcReg);
		at: 1 put: 16r8D.
	(srcReg ~= RSP and: [srcReg ~= R12]) ifTrue:
		[(self isQuick: offset) ifTrue:
			[machineCode
				at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: 3 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 4].
		machineCode
			at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
			at: 3 put: (offset bitAnd: 16rFF);
			at: 4 put: (offset >> 8 bitAnd: 16rFF);
			at: 5 put: (offset >> 16 bitAnd: 16rFF);
			at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 7].
	"ESP/R12:"
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: 3 put: (self s: SIB1 i: 4 b: srcReg);
			at: 4 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
		at: 3 put: (self s: SIB1 i: 4 b: srcReg);
		at: 4 put: (offset bitAnd: 16rFF);
		at: 5 put: (offset >> 8 bitAnd: 16rFF);
		at: 6 put: (offset >> 16 bitAnd: 16rFF);
		at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 8
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMOVSB [
	<inline: true>
	machineCode at: 0 put: 16rA4.
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMOVSQ [
	<inline: true>
	machineCode
		at: 0 put: (self rexw: true r: 0 x: 0 b: 0);
		at: 1 put: 16rA5.
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveA32R [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg offset |
	addressOperand := operands at: 0.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	reg := operands at: 1.
	reg = RAX
		ifTrue: [offset := 0]
		ifFalse:
			[machineCode
				at: 0 put: (self rexR: 0 x: 0 b: reg);
				at: 1 put: 16r90 + (reg \\ 8).
			 offset := 2].
	machineCode
		at: 0 + offset put: 16rA1;
		at: 1 + offset put: (addressOperand bitAnd: 16rFF);
		at: 2 + offset put: (addressOperand >> 8 bitAnd: 16rFF);
		at: 3 + offset put: (addressOperand >> 16 bitAnd: 16rFF);
		at: 4 + offset put: (addressOperand >> 24 bitAnd: 16rFF);
		at: 5 + offset put: (addressOperand >> 32 bitAnd: 16rFF);
		at: 6 + offset put: (addressOperand >> 40 bitAnd: 16rFF);
		at: 7 + offset put: (addressOperand >> 48 bitAnd: 16rFF);
		at: 8 + offset put: (addressOperand >> 56 bitAnd: 16rFF).
	reg = RAX ifTrue:
		[^machineCodeSize := 9].
	machineCode
		at: 11 put: (machineCode at: 0);
		at: 12 put: (machineCode at: 1).
	^machineCodeSize := 13
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveAbR [
	"N.B. The Cogit makes no assumption about the upper bits being set to zero because we
	 deny byteReadsZeroExtend.  The cogit will clear the register before hand if necessary."
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg offset save0 save1 |
	addressOperand := operands at: 0.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	(self isAddressRelativeToVarBase: addressOperand) ifTrue:
		[save0 := operands at: 0.
		 save1 := operands at: 1.
		 operands
			at: 0 put: addressOperand - cogit varBaseAddress;
			at: 1 put: RBX;
			at: 2 put: save1.
		 self concretizeMoveMbrR.
		 operands
			at: 0 put: save0;
			at: 1 put: save1;
			at: 2 put: 0.
		^machineCodeSize].
	reg := operands at: 1.
	reg = RAX
		ifTrue: [offset := 0]
		ifFalse:
			[machineCode
				at: 0 put: (self rexR: 0 x: 0 b: reg);
				at: 1 put: 16r90 + (reg \\ 8).
			 offset := 2].
	machineCode
		at: 0 + offset put: 16r48;
		at: 1 + offset put: 16rA0;
		at: 2 + offset put: (addressOperand bitAnd: 16rFF);
		at: 3 + offset put: (addressOperand >> 8 bitAnd: 16rFF);
		at: 4 + offset put: (addressOperand >> 16 bitAnd: 16rFF);
		at: 5 + offset put: (addressOperand >> 24 bitAnd: 16rFF);
		at: 6 + offset put: (addressOperand >> 32 bitAnd: 16rFF);
		at: 7 + offset put: (addressOperand >> 40 bitAnd: 16rFF);
		at: 8 + offset put: (addressOperand >> 48 bitAnd: 16rFF);
		at: 9 + offset put: (addressOperand >> 56 bitAnd: 16rFF).
	reg = RAX ifTrue:
		[^machineCodeSize := 10].
	machineCode
		at: 12 put: (machineCode at: 0);
		at: 13 put: (machineCode at: 1).
	^machineCodeSize := 14
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveAwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg offset save0 save1 |
	addressOperand := operands at: 0.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	(self isAddressRelativeToVarBase: addressOperand) ifTrue:
		[save0 := operands at: 0.
		 save1 := operands at: 1.
		 operands
			at: 0 put: addressOperand - cogit varBaseAddress;
			at: 1 put: RBX;
			at: 2 put: save1.
		 self concretizeMoveMwrR.
		 operands
			at: 0 put: save0;
			at: 1 put: save1;
			at: 2 put: 0.
		^machineCodeSize].
	reg := operands at: 1.
	reg = RAX
		ifTrue: [offset := 0]
		ifFalse:
			[machineCode
				at: 0 put: (self rexR: 0 x: 0 b: reg);
				at: 1 put: 16r90 + (reg \\ 8).
			 offset := 2].
	machineCode
		at: 0 + offset put: 16r48;
		at: 1 + offset put: 16rA1;
		at: 2 + offset put: (addressOperand bitAnd: 16rFF);
		at: 3 + offset put: (addressOperand >> 8 bitAnd: 16rFF);
		at: 4 + offset put: (addressOperand >> 16 bitAnd: 16rFF);
		at: 5 + offset put: (addressOperand >> 24 bitAnd: 16rFF);
		at: 6 + offset put: (addressOperand >> 32 bitAnd: 16rFF);
		at: 7 + offset put: (addressOperand >> 40 bitAnd: 16rFF);
		at: 8 + offset put: (addressOperand >> 48 bitAnd: 16rFF);
		at: 9 + offset put: (addressOperand >> 56 bitAnd: 16rFF).
	reg = RAX ifTrue:
		[^machineCodeSize := 10].
	machineCode
		at: 12 put: (machineCode at: 0);
		at: 13 put: (machineCode at: 1).
	^machineCodeSize := 14
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveC32R [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	machineCode
		at: 0 put: (self rexR: 0 x: 0 b: reg);
		at: 1 put: 16rC7;
		at: 2 put: (self mod: ModReg RM: reg RO: 0);
		at: 3 put: (value bitAnd: 16rFF);
		at: 4 put: (value >> 8 bitAnd: 16rFF);
		at: 5 put: (value >> 16 bitAnd: 16rFF);
		at: 6 put: (value >> 24 bitAnd: 16rFF).
	^machineCodeSize := 7
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveCqR [
	"Will get inlined into concretizeAt: switch.
	 On x64 we can short-cut mov 0, reg using xor, and use signed 32-bit displacement, if possible."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	(self is32BitSignedImmediate: value) ifTrue:
		[value = 0 ifTrue:
			[machineCode
				at: 0 put: (self rexR: reg x: 0 b: reg);
				at: 1 put: 16r31;
				at: 2 put: (self mod: ModReg RM: reg RO: reg).
			 ^machineCodeSize := 3].
		 machineCode
			at: 0 put: (self rexR: 0 x: 0 b: reg);
			at: 1 put: 16rC7;
			at: 2 put: (self mod: ModReg RM: reg RO: 0);
			at: 3 put: (value bitAnd: 16rFF);
			at: 4 put: (value >> 8 bitAnd: 16rFF);
			at: 5 put: (value >> 16 bitAnd: 16rFF);
			at: 6 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 7].

	machineCode
		at:  0 put: (self rexR: 0 x: 0 b: reg);
		at:  1 put: 16rB8 + (reg bitAnd: 7);
		at:  2 put: (value bitAnd: 16rFF);
		at:  3 put: (value >> 8 bitAnd: 16rFF);
		at:  4 put: (value >> 16 bitAnd: 16rFF);
		at:  5 put: (value >> 24 bitAnd: 16rFF);
		at:  6 put: (value >> 32 bitAnd: 16rFF);
		at:  7 put: (value >> 40 bitAnd: 16rFF);
		at:  8 put: (value >> 48 bitAnd: 16rFF);
		at:  9 put: (value >> 56 bitAnd: 16rFF).
	^machineCodeSize := 10
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveCwR [
	self subclassResponsibility
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveM16rR [
	"N.B. The Cogit compiler makes no assumption about the upper bits being set to zero.
	 It will clear the register before hand if necessary."
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	machineCode
		at: 0 put: (self rexR: destReg x: 0 b: srcReg);
		at: 1 put: 16r0f;
		at: 2 put: 16rb7.
	(srcReg ~= RSP and: [srcReg ~= R12]) ifTrue:
		[(offset = 0 and: [srcReg ~= RBP and: [srcReg ~= R13]]) ifTrue:
			[machineCode
				at: 3 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 ^machineCodeSize := 4].
		 (self isQuick: offset) ifTrue:
			[machineCode
				at: 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: 4 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 5].
		machineCode
			at: 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
			at: 4 put: (offset bitAnd: 16rFF);
			at: 5 put: (offset >> 8 bitAnd: 16rFF);
			at: 6 put: (offset >> 16 bitAnd: 16rFF);
			at: 7 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 8].
	"RSP & R12:"
	(offset = 0 and: [srcReg ~= RBP and: [srcReg ~= R13]]) ifTrue:
		[machineCode
			at: 3 put: (self mod: ModRegInd RM: srcReg RO: destReg);
			at: 4 put: (self s: SIB1 i: 4 b: srcReg).
		 ^machineCodeSize := 5].
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: 4 put: (self s: SIB1 i: 4 b: srcReg);
			at: 5 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 6].
	machineCode
		at: 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
		at: 4 put: (self s: SIB1 i: 4 b: srcReg);
		at: 5 put: (offset bitAnd: 16rFF);
		at: 6 put: (offset >> 8 bitAnd: 16rFF);
		at: 7 put: (offset >> 16 bitAnd: 16rFF);
		at: 8 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 9
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveM32rR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset srcReg destReg skip |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [skip := 1. machineCode at: 0 put: (self rexw: false r: destReg x: 0 b: srcReg)].
	machineCode
		at: skip + 0 put: 16r8b.
	offset = 0 ifTrue:
		[(srcReg bitAnd: 6) ~= RSP ifTrue:
			[machineCode at: skip + 1 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 ^machineCodeSize := skip + 2].
		 (srcReg bitAnd: 7) = RSP ifTrue: "RBP & R13 fall through"
			[machineCode
				at: skip + 1 put: (self mod: ModRegInd RM: srcReg RO: destReg);
				at: skip + 2 put: (self s: SIB1 i: 4 b: srcReg).
			 ^machineCodeSize := skip + 3]].
	(self isQuick: offset) ifTrue:
		[(srcReg bitAnd: 7) ~= RSP ifTrue:
			[machineCode
				at: skip + 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: skip + 2 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := skip + 3].
		 machineCode
			at: skip + 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: skip + 2 put: (self s: SIB1 i: 4 b: srcReg);
			at: skip + 3 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := skip + 4].
	machineCode at: skip + 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	(srcReg bitAnd: 7) = RSP ifTrue:
		[machineCode at: skip + 2 put: (self s: SIB1 i: 4 b: srcReg).
		 skip := skip + 1].
	machineCode
		at: skip + 2 put: (offset bitAnd: 16rFF);
		at: skip + 3 put: (offset >> 8 bitAnd: 16rFF);
		at: skip + 4 put: (offset >> 16 bitAnd: 16rFF);
		at: skip + 5 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := skip + 6
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveM32rRs [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset srcReg destReg skip |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	machineCode at: 0 put: 16r66.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: destReg x: 0 b: srcReg)].
	machineCode
		at: skip + 1 put: 16r0f;
		at: skip + 2 put: 16r6e.
	offset = 0 ifTrue:
		[(srcReg bitAnd: 6) ~= RSP ifTrue:
			[machineCode at: skip + 3 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 ^machineCodeSize := skip + 4].
		 (srcReg bitAnd: 7) = RSP ifTrue: "RBP & R13 fall through"
			[machineCode
				at: skip + 3 put: (self mod: ModRegInd RM: srcReg RO: destReg);
				at: skip + 4 put: (self s: SIB1 i: 4 b: srcReg).
			 ^machineCodeSize := skip + 5]].
	(self isQuick: offset) ifTrue:
		[(srcReg bitAnd: 7) ~= RSP ifTrue:
			[machineCode
				at: skip + 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: skip + 4 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := skip + 5].
		 machineCode
			at: skip + 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: skip + 4 put: (self s: SIB1 i: 4 b: srcReg);
			at: skip + 5 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := skip + 6].
	machineCode at: skip + 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	(srcReg bitAnd: 7) = RSP ifTrue:
		[machineCode at: skip + 4 put: (self s: SIB1 i: 4 b: srcReg).
		 skip := skip + 1].
	machineCode
		at: skip + 4 put: (offset bitAnd: 16rFF);
		at: skip + 5 put: (offset >> 8 bitAnd: 16rFF);
		at: skip + 6 put: (offset >> 16 bitAnd: 16rFF);
		at: skip + 7 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := skip + 8
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveM64rRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset srcReg destReg skip |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	machineCode at: 0 put: 16rF3.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: destReg x: 0 b: srcReg)].
	machineCode
		at: skip + 1 put: 16r0f;
		at: skip + 2 put: 16r7e.
	offset = 0 ifTrue:
		[(srcReg bitAnd: 6) ~= RSP ifTrue:
			[machineCode at: skip + 3 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 ^machineCodeSize := skip + 4].
		 (srcReg bitAnd: 7) = RSP ifTrue: "RBP & R13 fall through"
			[machineCode
				at: skip + 3 put: (self mod: ModRegInd RM: srcReg RO: destReg);
				at: skip + 4 put: (self s: SIB1 i: 4 b: srcReg).
			 ^machineCodeSize := skip + 5]].
	(self isQuick: offset) ifTrue:
		[(srcReg bitAnd: 7) ~= RSP ifTrue:
			[machineCode
				at: skip + 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: skip + 4 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := skip + 5].
		 machineCode
			at: skip + 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: skip + 4 put: (self s: SIB1 i: 4 b: srcReg);
			at: skip + 5 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := skip + 6].
	machineCode at: skip + 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	(srcReg bitAnd: 7) = RSP ifTrue:
		[machineCode at: skip + 4 put: (self s: SIB1 i: 4 b: srcReg).
		 skip := skip + 1].
	machineCode
		at: skip + 4 put: (offset bitAnd: 16rFF);
		at: skip + 5 put: (offset >> 8 bitAnd: 16rFF);
		at: skip + 6 put: (offset >> 16 bitAnd: 16rFF);
		at: skip + 7 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := skip + 8
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveMbrR [
	"N.B. The Cogit makes no assumption about the upper bits being set to zero because we
	 deny byteReadsZeroExtend.  The cogit will clear the register before hand if necessary."
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	machineCode
		at: 0 put: (self rexR: destReg x: 0 b: srcReg);
		at: 1 put: 16r8A.
	(srcReg ~= RSP and: [srcReg ~= R12]) ifTrue:
		[(offset = 0 and: [srcReg ~= RBP and: [srcReg ~= R13]]) ifTrue:
			[machineCode
				at: 2 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 ^machineCodeSize := 3].
		(self isQuick: offset) ifTrue:
			[machineCode
				at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: 3 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 4].
		machineCode
			at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
			at: 3 put: (offset bitAnd: 16rFF);
			at: 4 put: (offset >> 8 bitAnd: 16rFF);
			at: 5 put: (offset >> 16 bitAnd: 16rFF);
			at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 7].
	"RSP:"
	offset = 0 ifTrue:
		[machineCode
			at: 2 put: (self mod: ModRegInd RM: srcReg RO: destReg);
			at: 3 put: (self s: SIB1 i: 4 b: srcReg).
		 ^machineCodeSize := 4].
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: 3 put: (self s: SIB1 i: 4 b: srcReg);
			at: 4 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
		at: 3 put: (self s: SIB1 i: 4 b: srcReg);
		at: 4 put: (offset bitAnd: 16rFF);
		at: 5 put: (offset >> 8 bitAnd: 16rFF);
		at: 6 put: (offset >> 16 bitAnd: 16rFF);
		at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 8
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveMwrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	machineCode
		at: 0 put: (self rexR: destReg x: 0 b: srcReg);
		at: 1 put: 16r8B.
	(srcReg ~= RSP and: [srcReg ~= R12]) ifTrue:
		[(offset = 0 and: [srcReg ~= RBP and: [srcReg ~= R13]]) ifTrue:
			[machineCode
				at: 2 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 ^machineCodeSize := 3].
		(self isQuick: offset) ifTrue:
			[machineCode
				at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: 3 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 4].
		machineCode
			at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
			at: 3 put: (offset bitAnd: 16rFF);
			at: 4 put: (offset >> 8 bitAnd: 16rFF);
			at: 5 put: (offset >> 16 bitAnd: 16rFF);
			at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 7].
	"RSP:"
	offset = 0 ifTrue:
		[machineCode
			at: 2 put: (self mod: ModRegInd RM: srcReg RO: destReg);
			at: 3 put: (self s: SIB1 i: 4 b: srcReg).
		 ^machineCodeSize := 4].
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: 3 put: (self s: SIB1 i: 4 b: srcReg);
			at: 4 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
		at: 3 put: (self s: SIB1 i: 4 b: srcReg);
		at: 4 put: (offset bitAnd: 16rFF);
		at: 5 put: (offset >> 8 bitAnd: 16rFF);
		at: 6 put: (offset >> 16 bitAnd: 16rFF);
		at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 8
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRA32 [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg offset |
	reg := operands at: 0.
	addressOperand := operands at: 1.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	reg = RAX
		ifTrue: [offset := 0]
		ifFalse:
			[machineCode
				at: 0 put: (self rexR: 0 x: 0 b: reg);
				at: 1 put: 16r90 + (reg \\ 8).
			 offset := 2].
	machineCode
		at: 0 + offset put: 16rA3;
		at: 1 + offset put: (addressOperand bitAnd: 16rFF);
		at: 2 + offset put: (addressOperand >>   8 bitAnd: 16rFF);
		at: 3 + offset put: (addressOperand >> 16 bitAnd: 16rFF);
		at: 4 + offset put: (addressOperand >> 24 bitAnd: 16rFF);
		at: 5 + offset put: (addressOperand >> 32 bitAnd: 16rFF);
		at: 6 + offset put: (addressOperand >> 40 bitAnd: 16rFF);
		at: 7 + offset put: (addressOperand >> 48 bitAnd: 16rFF);
		at: 8 + offset put: (addressOperand >> 56 bitAnd: 16rFF).
	reg = RAX ifTrue:
		[^machineCodeSize := 9].
	machineCode
		at: 11 put: (machineCode at: 0);
		at: 12 put: (machineCode at: 1).
	^machineCodeSize := 13
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRAb [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg offset save1 |
	reg := operands at: 0.
	addressOperand := operands at: 1.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	(self isAddressRelativeToVarBase: addressOperand) ifTrue:
		[save1 := operands at: 1.
		 operands
			at: 1 put: addressOperand - cogit varBaseAddress;
			at: 2 put: RBX.
		 self concretizeMoveRMbr.
		 operands
			at: 1 put: save1;
			at: 2 put: 0.
		^machineCodeSize].
	reg = RAX
		ifTrue: [offset := 0]
		ifFalse:
			[machineCode
				at: 0 put: (self rexR: 0 x: 0 b: reg);
				at: 1 put: 16r90 + (reg \\ 8).
			 offset := 2].
	machineCode
		at: 0 + offset put: 16r48;
		at: 1 + offset put: 16rA2;
		at: 2 + offset put: (addressOperand bitAnd: 16rFF);
		at: 3 + offset put: (addressOperand >> 8 bitAnd: 16rFF);
		at: 4 + offset put: (addressOperand >> 16 bitAnd: 16rFF);
		at: 5 + offset put: (addressOperand >> 24 bitAnd: 16rFF);
		at: 6 + offset put: (addressOperand >> 32 bitAnd: 16rFF);
		at: 7 + offset put: (addressOperand >> 40 bitAnd: 16rFF);
		at: 8 + offset put: (addressOperand >> 48 bitAnd: 16rFF);
		at: 9 + offset put: (addressOperand >> 56 bitAnd: 16rFF).
	reg = RAX ifTrue:
		[^machineCodeSize := 10].
	machineCode
		at: 12 put: (machineCode at: 0);
		at: 13 put: (machineCode at: 1).
	^machineCodeSize := 14
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRAw [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg offset save1 |
	reg := operands at: 0.
	addressOperand := operands at: 1.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	(self isAddressRelativeToVarBase: addressOperand) ifTrue:
		[save1 := operands at: 1.
		 operands
			at: 1 put: addressOperand - cogit varBaseAddress;
			at: 2 put: RBX.
		 self concretizeMoveRMwr.
		 operands
			at: 1 put: save1;
			at: 2 put: 0.
		^machineCodeSize].
	reg = RAX
		ifTrue: [offset := 0]
		ifFalse:
			[machineCode
				at: 0 put: (self rexR: 0 x: 0 b: reg);
				at: 1 put: 16r90 + (reg \\ 8).
			 offset := 2].
	machineCode
		at: 0 + offset put: 16r48;
		at: 1 + offset put: 16rA3;
		at: 2 + offset put: (addressOperand bitAnd: 16rFF);
		at: 3 + offset put: (addressOperand >> 8 bitAnd: 16rFF);
		at: 4 + offset put: (addressOperand >> 16 bitAnd: 16rFF);
		at: 5 + offset put: (addressOperand >> 24 bitAnd: 16rFF);
		at: 6 + offset put: (addressOperand >> 32 bitAnd: 16rFF);
		at: 7 + offset put: (addressOperand >> 40 bitAnd: 16rFF);
		at: 8 + offset put: (addressOperand >> 48 bitAnd: 16rFF);
		at: 9 + offset put: (addressOperand >> 56 bitAnd: 16rFF).
	reg = RAX ifTrue:
		[^machineCodeSize := 10].
	machineCode
		at: 12 put: (machineCode at: 0);
		at: 13 put: (machineCode at: 1).
	^machineCodeSize := 14
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRM16r [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg skip |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	machineCode at: 0 put: 16r66.
	(srcReg > 7 or: [destReg > 7])
		ifTrue:
			[machineCode at: 1 put: (self rexw: false r: srcReg x: 0 b: destReg).
			 skip := 1]
		ifFalse:
			[skip := 0].
	(destReg bitAnd: 7) ~= RSP ifTrue:
		[(self isQuick: offset) ifTrue:
			[machineCode
				at: skip + 1 put: 16r89;
				at: skip + 2 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
				at: skip + 3 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := skip + 4].
		machineCode
			at: skip + 1 put: 16r89;
			at: skip + 2 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
			at: skip + 3 put: (offset bitAnd: 16rFF);
			at: skip + 4 put: (offset >> 8 bitAnd: 16rFF);
			at: skip + 5 put: (offset >> 16 bitAnd: 16rFF);
			at: skip + 6 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := skip + 7].
	"RSP:"
	(self isQuick: offset) ifTrue:
		[machineCode
			at: skip + 1 put: 16r89;
			at: skip + 2 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
			at: skip + 3 put: (self s: SIB1 i: 4 b: destReg);
			at: skip + 4 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := skip + 5].
	machineCode
		at: skip + 1 put: 16r89;
		at: skip + 2 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
		at: skip + 3 put: (self s: SIB1 i: 4 b: destReg);
		at: skip + 4 put: (offset bitAnd: 16rFF);
		at: skip + 5 put: (offset >> 8 bitAnd: 16rFF);
		at: skip + 6 put: (offset >> 16 bitAnd: 16rFF);
		at: skip + 7 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := skip + 8
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRM32r [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset srcReg destReg skip |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [skip := 1. machineCode at: 0 put: (self rexw: false r: srcReg x: 0 b: destReg)].
	machineCode
		at: skip + 0 put: 16r89.
	offset = 0 ifTrue:
		[(destReg bitAnd: 6) ~= RSP ifTrue:
			[machineCode at: skip + 1 put: (self mod: ModRegInd RM: destReg RO: srcReg).
			 ^machineCodeSize := skip + 2].
		 (destReg bitAnd: 7) = RSP ifTrue: "RBP & R13 fall through"
			[machineCode
				at: skip + 1 put: (self mod: ModRegInd RM: destReg RO: srcReg);
				at: skip + 2 put: (self s: SIB1 i: 4 b: destReg).
			 ^machineCodeSize := skip + 3]].
	(self isQuick: offset) ifTrue:
		[(destReg bitAnd: 7) ~= RSP ifTrue:
			[machineCode
				at: skip + 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
				at: skip + 2 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := skip + 3].
		 machineCode
			at: skip + 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
			at: skip + 2 put: (self s: SIB1 i: 4 b: destReg);
			at: skip + 3 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := skip + 4].
	machineCode at: skip + 1 put: (self mod: ModRegRegDisp32  RM: destReg RO: srcReg).
	(destReg bitAnd: 7) = RSP ifTrue:
		[machineCode at: skip + 2 put: (self s: SIB1 i: 4 b: destReg).
		 skip := skip + 1].
	machineCode
		at: skip + 2 put: (offset bitAnd: 16rFF);
		at: skip + 3 put: (offset >> 8 bitAnd: 16rFF);
		at: skip + 4 put: (offset >> 16 bitAnd: 16rFF);
		at: skip + 5 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := skip + 6
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRMbr [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset baseReg |
	srcReg := operands at: 0.
	offset := operands at: 1.
	baseReg := operands at: 2.
	machineCode
		at: 0 put: (self rexR: srcReg x: 0 b: baseReg);
		at: 1 put: 16r88.
	(baseReg ~= RSP and: [baseReg ~= R12]) ifTrue:
		[(offset = 0 and: [baseReg ~= RBP and: [baseReg ~= R13]]) ifTrue:
			[machineCode
				at: 2 put: (self mod: ModRegInd RM: baseReg RO: srcReg).
			 ^machineCodeSize := 3].
		 (self isQuick: offset) ifTrue:
			[machineCode
				at: 2 put: (self mod: ModRegRegDisp8 RM: baseReg RO: srcReg);
				at: 3 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 4].
		machineCode
			at: 2 put: (self mod: ModRegRegDisp32 RM: baseReg RO: srcReg);
			at: 3 put: (offset bitAnd: 16rFF);
			at: 4 put: (offset >> 8 bitAnd: 16rFF);
			at: 5 put: (offset >> 16 bitAnd: 16rFF);
			at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 7].
	"RSP:"
	offset = 0 ifTrue:
		[machineCode
			at: 2 put: (self mod: ModRegInd RM: baseReg RO: srcReg);
			at: 3 put: (self s: SIB1 i: 4 b: baseReg).
		 ^machineCodeSize := 4].
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 2 put: (self mod: ModRegRegDisp8 RM: baseReg RO: srcReg);
			at: 3 put: (self s: SIB1 i: 4 b: baseReg);
			at: 4 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 2 put: (self mod: ModRegRegDisp32 RM: baseReg RO: srcReg);
		at: 3 put: (self s: SIB1 i: 4 b: baseReg);
		at: 4 put: (offset bitAnd: 16rFF);
		at: 5 put: (offset >> 8 bitAnd: 16rFF);
		at: 6 put: (offset >> 16 bitAnd: 16rFF);
		at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 8
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRMwr [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	machineCode
		at: 0 put: (self rexR: srcReg x: 0 b: destReg);
		at: 1 put: 16r89.
	(destReg ~= RSP and: [destReg ~= R12]) ifTrue:
		[(offset = 0 and: [destReg ~= RBP and: [destReg ~= R13]]) ifTrue:
			[machineCode
				at: 2 put: (self mod: ModRegInd RM: destReg RO: srcReg).
			 ^machineCodeSize := 3].
		 (self isQuick: offset) ifTrue:
			[machineCode
				at: 2 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
				at: 3 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 4].
		machineCode
			at: 2 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
			at: 3 put: (offset bitAnd: 16rFF);
			at: 4 put: (offset >> 8 bitAnd: 16rFF);
			at: 5 put: (offset >> 16 bitAnd: 16rFF);
			at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 7].
	"RSP:"
	offset = 0 ifTrue:
		[machineCode
			at: 2 put: (self mod: ModRegInd RM: destReg RO: srcReg);
			at: 3 put: (self s: SIB1 i: 4 b: destReg).
		 ^machineCodeSize := 4].
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 2 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
			at: 3 put: (self s: SIB1 i: 4 b: destReg);
			at: 4 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 2 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
		at: 3 put: (self s: SIB1 i: 4 b: destReg);
		at: 4 put: (offset bitAnd: 16rFF);
		at: 5 put: (offset >> 8 bitAnd: 16rFF);
		at: 6 put: (offset >> 16 bitAnd: 16rFF);
		at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 8
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRRd [
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16r66;
		at: 1 put: (self rexR: destReg x: 0 b: srcReg);
		at: 2 put: 16r0f;
		at: 3 put: 16r6e;
		at: 4 put: (self mod: ModReg RM: srcReg RO: destReg).
	^machineCodeSize := 5
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRX32rR [
	| index base src offset |
	src := operands at: 0.
	index := operands at: 1.
	base := operands at: 2.
	(index > 7 or: [base > 7 or: [src > 7]])
		ifTrue:
			[machineCode at: 0 put: (self rexw: false r: src x: index b: base).
			 offset := 1]
		ifFalse:
			[offset := 0].
	(base bitAnd: 7) ~= RBP ifTrue:
		[machineCode
			at: offset + 0 put: 16r89;
			at: offset + 1 put: (self mod: ModRegInd RM: 4 RO: src);
			at: offset + 2 put: (self s: SIB4 i: index b: base).
		 ^machineCodeSize := offset + 3].
	machineCode
		at: offset + 0 put: 16r89;
		at: offset + 1 put: (self mod: ModRegRegDisp8 RM: 4 RO: src);
		at: offset + 2 put: (self s: SIB4 i: index b: base);
		at: offset + 3 put: 0.
	 ^machineCodeSize := offset + 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRXbrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| src index base offset |
	src := operands at: 0.
	index := operands at: 1.
	base := operands at: 2.
	offset := 0.
	(src > 3 or: [base > 7 or: [index > 7]]) ifTrue:
		[machineCode at: 0 put: (self rexR: src x: index b: base).
		 offset := 1].
	machineCode at: 0 + offset put: 16r88.
	(base bitAnd: 7) ~= RBP "RBP,R13" ifTrue:
		[machineCode
			at: 1 + offset put: (self mod: ModRegInd RM: 4 RO: src);
			at: 2 + offset put: (self s: SIB1 i: index b: base).
		 ^machineCodeSize := 3 + offset].
	machineCode
		at: 1 + offset put: (self mod: ModRegRegDisp8 RM: 4 RO: src);
		at: 2 + offset put: (self s: SIB1 i: index b: base);
		at: 3 + offset put: 0.
	 ^machineCodeSize := 4 + offset
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRXwrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base src |
	src := operands at: 0.
	index := operands at: 1.
	base := operands at: 2.
	machineCode
		at: 0 put: (self rexR: src x: index b: base).
	(base ~= RBP and: [base ~= R13]) ifTrue:
		[machineCode
			at: 1 put: 16r89;
			at: 2 put: (self mod: ModRegInd RM: 4 RO: src);
			at: 3 put: (self s: SIB8 i: index b: base).
		 ^machineCodeSize := 4].
	machineCode
		at: 1 put: 16r89;
		at: 2 put: (self mod: ModRegRegDisp8 RM: 4 RO: src);
		at: 3 put: (self s: SIB8 i: index b: base);
		at: 4 put: 0.
	 ^machineCodeSize := 5
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRdM64r [
	<inline: true>
	| offset srcReg destReg skip |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	machineCode at: 0 put: 16r66.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: srcReg x: 0 b: destReg)].
	machineCode
		at: skip + 1 put: 16r0f;
		at: skip + 2 put: 16rd6.
	offset = 0 ifTrue:
		[(destReg bitAnd: 6) ~= RSP ifTrue:
			[machineCode at: skip + 3 put: (self mod: ModRegInd RM: destReg RO: srcReg).
			 ^machineCodeSize := skip + 4].
		 (destReg bitAnd: 7) = RSP ifTrue: "RBP & R13 fall through"
			[machineCode
				at: skip + 3 put: (self mod: ModRegInd RM: destReg RO: srcReg);
				at: skip + 4 put: (self s: SIB1 i: 4 b: destReg).
			 ^machineCodeSize := skip + 5]].
	(self isQuick: offset) ifTrue:
		[(destReg bitAnd: 7) ~= RSP ifTrue:
			[machineCode
				at: skip + 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
				at: skip + 4 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := skip + 5].
		 machineCode
			at: skip + 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
			at: skip + 4 put: (self s: SIB1 i: 4 b: destReg);
			at: skip + 5 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := skip + 6].
	machineCode at: skip + 3 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
	(destReg bitAnd: 7) = RSP ifTrue:
		[machineCode at: skip + 4 put: (self s: SIB1 i: 4 b: destReg).
		 skip := skip + 1].
	machineCode
		at: skip + 4 put: (offset bitAnd: 16rFF);
		at: skip + 5 put: (offset >> 8 bitAnd: 16rFF);
		at: skip + 6 put: (offset >> 16 bitAnd: 16rFF);
		at: skip + 7 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := skip + 8
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRdR [
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16r66;
		at: 1 put: (self rexR: srcReg x: 0 b: destReg);
		at: 2 put: 16r0f;
		at: 3 put: 16r7e;
		at: 4 put: (self mod: ModReg RM: destReg RO: srcReg).
	^machineCodeSize := 5
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRdRd [
	"Will get inlined into concretizeAt: switch."
	"MOVSD"
	<inline: true>
	| srcReg destReg skip |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF2.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: srcReg x: 0 b: destReg)].
	machineCode
		at: skip + 1 put: 16r0F;
		at: skip + 2 put: 16r11;
		at: skip + 3 put: (self mod: ModReg RM: destReg RO: srcReg).
	^machineCodeSize := skip + 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRsM32r [
	<inline: true>
	| offset srcReg destReg skip |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	machineCode at: 0 put: 16r66.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: srcReg x: 0 b: destReg)].
	machineCode
		at: skip + 1 put: 16r0f;
		at: skip + 2 put: 16r7e.
	offset = 0 ifTrue:
		[(destReg bitAnd: 6) ~= RSP ifTrue:
			[machineCode at: skip + 3 put: (self mod: ModRegInd RM: destReg RO: srcReg).
			 ^machineCodeSize := skip + 4].
		 (destReg bitAnd: 7) = RSP ifTrue: "RBP & R13 fall through"
			[machineCode
				at: skip + 3 put: (self mod: ModRegInd RM: destReg RO: srcReg);
				at: skip + 4 put: (self s: SIB1 i: 4 b: destReg).
			 ^machineCodeSize := skip + 5]].
	(self isQuick: offset) ifTrue:
		[(destReg bitAnd: 7) ~= RSP ifTrue:
			[machineCode
				at: skip + 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
				at: skip + 4 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := skip + 5].
		 machineCode
			at: skip + 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
			at: skip + 4 put: (self s: SIB1 i: 4 b: destReg);
			at: skip + 5 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := skip + 6].
	machineCode at: skip + 3 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
	(destReg bitAnd: 7) = RSP ifTrue:
		[machineCode at: skip + 4 put: (self s: SIB1 i: 4 b: destReg).
		 skip := skip + 1].
	machineCode
		at: skip + 4 put: (offset bitAnd: 16rFF);
		at: skip + 5 put: (offset >> 8 bitAnd: 16rFF);
		at: skip + 6 put: (offset >> 16 bitAnd: 16rFF);
		at: skip + 7 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := skip + 8
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRsRs [
	"Will get inlined into concretizeAt: switch."
	"MOVSS"
	<inline: true>
	| srcReg destReg skip |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF3.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: srcReg x: 0 b: destReg)].
	machineCode
		at: skip + 1 put: 16r0F;
		at: skip + 2 put: 16r11;
		at: skip + 3 put: (self mod: ModReg RM: destReg RO: srcReg).
	^machineCodeSize := skip + 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveX32rRR [
	"MoveX32rRR is expected to zero-extend, so explicitly zero the destination."
	| index base dest offset |
	index := operands at: 0.
	base := operands at: 1.
	dest := operands at: 2.
	machineCode
		at: 0 put: (self rexR: dest x: 0 b: dest);
		at: 1 put: 16r31;
		at: 2 put: (self mod: ModReg RM: dest RO: dest).
	(index > 7 or: [base > 7 or: [dest > 7]])
		ifTrue:
			[machineCode at: 3 put: (self rexw: false r: dest x: index b: base).
			 offset := 1]
		ifFalse:
			[offset := 0].
	(base bitAnd: 7) ~= RBP ifTrue:
		[machineCode
			at: offset + 3 put: 16r8B;
			at: offset + 4 put: (self mod: ModRegInd RM: 4 RO: dest);
			at: offset + 5 put: (self s: SIB4 i: index b: base).
		 ^machineCodeSize := offset + 6].
	machineCode
		at: offset + 3 put: 16r8B;
		at: offset + 4 put: (self mod: ModRegRegDisp8 RM: 4 RO: dest);
		at: offset + 5 put: (self s: SIB4 i: index b: base);
		at: offset + 6 put: 0.
	 ^machineCodeSize := offset + 7
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveXbrRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base dest |
	index := operands at: 0.
	base := operands at: 1.
	dest := operands at: 2.
	machineCode
		at: 0 put: (self rexR: dest x: index b: base);
		at: 1 put: 16r8A.
	(base ~= RBP and: [base ~= R13]) ifTrue:
		[machineCode
			at: 2 put: (self mod: ModRegInd RM: 4 RO: dest);
			at: 3 put: (self s: SIB1 i: index b: base).
		 ^machineCodeSize := 4].
	machineCode
		at: 2 put: (self mod: ModRegRegDisp8 RM: 4 RO: dest);
		at: 3 put: (self s: SIB1 i: index b: base);
		at: 4 put: 0.
	 ^machineCodeSize := 5
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveXwrRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base dest |
	index := operands at: 0.
	base := operands at: 1.
	dest := operands at: 2.
	machineCode
		at: 0 put: (self rexR: dest x: index b: base).
	(base ~= RBP and: [base ~= R13]) ifTrue:
		[machineCode
			at: 1 put: 16r8B;
			at: 2 put: (self mod: ModRegInd RM: 4 RO: dest);
			at: 3 put: (self s: SIB8 i: index b: base).
		 ^machineCodeSize := 4].
	machineCode
		at: 1 put: 16r8B;
		at: 2 put: (self mod: ModRegRegDisp8 RM: 4 RO: dest);
		at: 3 put: (self s: SIB8 i: index b: base);
		at: 4 put: 0.
	 ^machineCodeSize := 5
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMulRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg1 reg2 |
	reg1 := operands at: 0.
	reg2 := operands at: 1.
	machineCode
		at: 0 put: (self rexR: reg2 x: 0 b: reg1);
		at: 1 put: 16r0F;
		at: 2 put: 16rAF;
		at: 3 put: (self mod: ModReg RM: reg1 RO: reg2).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeNegateR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := operands at: 0.
	machineCode
		at: 0 put: (self rexR: 0 x: 0 b: reg);
		at: 1 put: 16rF7;
		at: 2 put: (self mod: ModReg RM: reg RO: 3).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeNop [
	<inline: true>
	machineCode at: 0 put: 16r90.
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeOpRR: x64opcode [
	| regLHS regRHS |
	regLHS := operands at: 0.
	regRHS := operands at: 1.
	machineCode
		at: 0 put: (self rexR: regRHS x: 0 b: regLHS);
		at: 1 put: x64opcode;
		at: 2 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizePopR [
	<inline: true>
	| reg |
	reg := operands at: 0.
	reg < 8 ifTrue:
		[machineCode at: 0 put: 16r58 + reg.
		^machineCodeSize := 1].
	machineCode
		at: 0 put: 16r41;
		at: 1 put: 16r58 + (reg - 8).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizePrefetchAw [
	"We support only prefetches for addresses that are variables relative to VarBase"
	| operand offset |
	operand := operands at: 0.
	(self isAddressRelativeToVarBase: operand) ifFalse:
		[^machineCodeSize := 0].
	offset := operand - cogit varBaseAddress.
	machineCode
		at: 0 put: 16r0f;
		at: 1 put: 16r18;
		at: 2 put: 16r93;
		at: 3 put: (offset bitAnd: 16rFF);
		at: 4 put: (offset >> 16 bitAnd: 16rFF);
		at: 5 put: (offset >> 8 bitAnd: 16rFF);
		at: 6 put: offset >> 24.
	^machineCodeSize := 7
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizePushCq [
	<inline: true>
	| value |
	value := operands at: 0.
	(self isQuick: value) ifTrue:
		[machineCode
			at: 0 put: 16r6A;
			at: 1 put: (value bitAnd: 16rFF).
		^machineCodeSize := 2].
	(self is32BitSignedImmediate: value) ifTrue:
		[machineCode
			at: 0 put: 16r68;
			at: 1 put: (value bitAnd: 16rFF);
			at: 2 put: (value >> 8 bitAnd: 16rFF);
			at: 3 put: (value >> 16 bitAnd: 16rFF);
			at: 4 put: (value >> 24 bitAnd: 16rFF).
		^machineCodeSize := 5].
	^self concretizePushCw
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizePushR [
	<inline: true>
	| reg |
	reg := operands at: 0.
	reg < 8 ifTrue:
		[machineCode at: 0 put: 16r50 + reg.
		^machineCodeSize := 1].
	machineCode
		at: 0 put: 16r41;
		at: 1 put: 16r50 + (reg - 8).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeREP [
	<inline: true>
	machineCode at: 0 put: 16rF3.
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeRetN [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset |
	offset := operands at: 0.
	offset = 0 ifTrue:
		[machineCode at: 0 put: 16rC3.
		^machineCodeSize := 1].
	machineCode
		at: 0 put: 16rC2;
		at: 1 put: (offset bitAnd: 16rFF);
		at: 2 put: (offset >> 8).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeReverseOpRR: x64opcode [
	| regLHS regRHS |
	"CmpRR/MoveRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	machineCode
		at: 0 put: (self rexR: regRHS x: 0 b: regLHS);
		at: 1 put: x64opcode;
		at: 2 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeSEE2OpRdRd: x64opcode [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS skip |
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	machineCode
		at: 0 put: 16rF2.
	(regLHS <= 7 and: [regRHS <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: regLHS x: 0 b: regRHS)].
	machineCode 
		at: skip + 1 put: 16r0F;
		at: skip + 2 put: x64opcode;
		at: skip + 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^machineCodeSize := skip + 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeSEEOpRsRs: x64opcode [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS skip |
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	machineCode
		at: 0 put: 16rF3.
	(regLHS <= 7 and: [regRHS <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: regLHS x: 0 b: regRHS)].
	machineCode 
		at: skip + 1 put: 16r0F;
		at: skip + 2 put: x64opcode;
		at: skip + 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^machineCodeSize := skip + 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeShiftCqRegOpcode: regOpcode [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| distance reg |
	distance := operands at: 0.
	self assert: (distance between: 1 and: 63).
	reg := operands at: 1.
	machineCode at: 0 put: (self rexR: 0 x: 0 b: reg).
	distance = 1 ifTrue:
		[machineCode
			at: 1 put: 16rD1;
			at: 2 put: (self mod: ModReg RM: reg RO: regOpcode).
		 ^machineCodeSize := 3].
	machineCode
		at: 1 put: 16rC1;
		at: 2 put: (self mod: ModReg RM: reg RO: regOpcode);
		at: 3 put: distance.
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeShiftRegRegOpcode: regOpcode [
	"On the x64 the only instructions that shift by the value of a
	 register require the shift count to be  in %ecx.  So we may
	 have to use swap instructions to get the count into %ecx."
	<inline: true>
	| shiftCountReg destReg regToShift |
	shiftCountReg := operands at: 0.
	destReg := operands at: 1.
	shiftCountReg = RCX ifTrue:
		[machineCode
			at: 0 put: (self rexR: 0 x: 0 b: destReg);
			at: 1 put: 16rD3;
			at: 2 put: (self mod: ModReg RM: destReg RO: regOpcode).
		 ^machineCodeSize := 3].
	regToShift := destReg = shiftCountReg
					ifTrue: [RCX]
					ifFalse: [destReg = RCX
								ifTrue: [shiftCountReg]
								ifFalse: [destReg]].
	shiftCountReg = RAX ifTrue:
		[machineCode
			at: 0 put: 16r48;
			at: 1 put: 16r90 + RCX; "XCHG RAX,RCX"
			at: 2 put: (self rexR: 0 x: 0 b: regToShift);
			at: 3 put: 16rD3;			"SAR RCX,RAX"
			at: 4 put: (self mod: ModReg RM: regToShift RO: regOpcode);
			at: 5 put: 16r48;
			at: 6 put: 16r90 + RCX. "XCHG RAX,RCX"
		 ^machineCodeSize := 7].
	machineCode
		at: 0 put: (self rexR: shiftCountReg x: 0 b: RCX);		"XCHG R?X,RCX"
		at: 1 put: 16r87;
		at: 2 put: (self mod: ModReg RM: RCX RO: shiftCountReg);
		at: 3 put: (self rexR: 0 x: 0 b: regToShift);			"SAR RCX,R!X"
		at: 4 put: 16rD3;
		at: 5 put: (self mod: ModReg RM: regToShift RO: regOpcode);
		at: 6 put: (self rexR: shiftCountReg x: 0 b: RCX);		"XCHG R?X,RCX"
		at: 7 put: 16r87;
		at: 8 put: (self mod: ModReg RM: RCX RO: shiftCountReg).
	^machineCodeSize := 9
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeSignExtend16RR [
	"Will get inlined into concretizeAt: switch."
	"movsxwq"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: (self rexw: true r: destReg x: 0 b: srcReg);
		at: 1 put: 16r0F;
		at: 2 put: 16rBF;
		at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeSignExtend32RR [
	"Will get inlined into concretizeAt: switch."
	"movsxdq"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: (self rexw: true r: destReg x: 0 b: srcReg);
		at: 1 put: 16r63;
		at: 2 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeSignExtend8RR [
	"Will get inlined into concretizeAt: switch."
	"movsxbq"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: (self rexw: true r: destReg x: 0 b: srcReg);
		at: 1 put: 16r0F;
		at: 2 put: 16rBE;
		at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeSqrtRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg skip |
	reg := operands at: 0.
	machineCode
		at: 0 put: 16rF2.
	(reg <= 7)
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: reg x: 0 b: reg)].
	machineCode
		at: skip + 1 put: 16r0F;
		at: skip + 2 put: 16r51;
		at: skip + 3 put: (self mod: ModReg RM: reg RO: reg).
	^machineCodeSize := skip + 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeSqrtRs [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg skip |
	reg := operands at: 0.
	machineCode
		at: 0 put: 16rF3.
	(reg <= 7)
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: reg x: 0 b: reg)].
	machineCode
		at: skip + 1 put: 16r0F;
		at: skip + 2 put: 16r51;
		at: skip + 3 put: (self mod: ModReg RM: reg RO: reg).
	^machineCodeSize := skip + 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeStop [
	<inline: true>
	machineCode at: 0 put: 16rCC.
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeTstCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	machineCode
		at: 0 put: (self rexR: 0 x: 0 b: reg).
	(self isQuick: value) ifTrue:
		[machineCode
			at: 1 put: 16rF6;
			at: 2 put: (self mod: ModReg RM: reg RO: 0);
			at: 3 put: (value bitAnd: 16rFF).
		 ^machineCodeSize := 4].
	
	(self is32BitSignedImmediate: value) ifTrue:
		[reg = RAX ifTrue:
			[machineCode
				at: 1 put: 16rA9;
				at: 2 put: (value bitAnd: 16rFF);
				at: 3 put: (value >> 8 bitAnd: 16rFF);
				at: 4 put: (value >> 16 bitAnd: 16rFF);
				at: 5 put: (value >> 24 bitAnd: 16rFF).
			 ^machineCodeSize := 6].
		machineCode
			at: 1 put: 16rF7;
			at: 2 put: (self mod: ModReg RM: reg RO: 0);
			at: 3 put: (value bitAnd: 16rFF);
			at: 4 put: (value >> 8 bitAnd: 16rFF);
			at: 5 put: (value >> 16 bitAnd: 16rFF);
			at: 6 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 7].
	^self concretizeArithCwR: 16r85
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeXCHGAwR [
	<inline: true>
	| addressOperand reg |
	addressOperand := operands at: 0.
	reg := operands at: 1.
	machineCode
		at: 0 put: (self rexw: true r: reg x: 0 b: 0);
		at: 1 put: 16r87;
		at: 2 put: (self mod: ModReg RM: 0 RO: 7);
		at: 3 put: (addressOperand bitAnd: 16rFF);
		at: 4 put: (addressOperand >> 8 bitAnd: 16rFF);
		at: 5 put: (addressOperand >> 16 bitAnd: 16rFF);
		at: 6 put: (addressOperand >> 24 bitAnd: 16rFF);
		at: 7 put: (addressOperand >> 32 bitAnd: 16rFF);
		at: 8 put: (addressOperand >> 40 bitAnd: 16rFF);
		at: 9 put: (addressOperand >> 48 bitAnd: 16rFF);
		at: 10 put: (addressOperand >> 56 bitAnd: 16rFF).
	^machineCodeSize := 11
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeXCHGRR [
	| r1 r2 |
	r1 := operands at: 0.
	r2 := operands at: 1.
	r2 = RAX ifTrue:
		[r2 := r1. r1 := RAX].
	r1 = RAX ifTrue:
		[machineCode
			at: 0 put: (self rexR: 0 x: 0 b: r2);
			at: 1 put: 16r90 + (r2 \\ 8).
		 ^machineCodeSize := 2].
	machineCode
		at: 0 put: (self rexR: r1 x: 0 b: r2);
		at: 1 put: 16r87;
		at: 2 put: (self mod: ModReg RM: r2 RO: r1).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeXorRdRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS skip |
	regRHS := self operands at: 0.
	regLHS := self operands at: 1.
	machineCode
		at: 0 put: 16r66.
	(regLHS <= 7 and: [regRHS <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: regLHS x: 0 b: regRHS)].
	machineCode
		at: skip + 1 put: 16r0f;
		at: skip + 2 put: 16r57;
		at: skip + 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^machineCodeSize := skip + 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeXorRsRs [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS skip |
	regRHS := self operands at: 0.
	regLHS := self operands at: 1.
	machineCode
		at: 0 put: 16r0F.
	(regLHS <= 7 and: [regRHS <= 7])
		ifTrue: [skip := 0]
		ifFalse: [machineCode at: (skip := 1) put: (self rexw: false r: regLHS x: 0 b: regRHS)].
	
	machineCode	
		at: skip + 1 put: 16r57;
		at: skip + 2 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^machineCodeSize := skip + 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeZeroExtend16RR [
	"Will get inlined into concretizeAt: switch."
	"movzxwq"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: (self rexw: true r: destReg x: 0 b: srcReg);
		at: 1 put: 16r0F;
		at: 2 put: 16rB7;
		at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeZeroExtend32RR [
	"Will get inlined into concretizeAt: switch."
	"movzxbq"
	<inline: true>
	| srcReg destReg skip |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [skip := 1. machineCode at: 0 put: (self rexw: false r: destReg x: 0 b: srcReg)].
		
	machineCode
		at: skip + 0 put: 16r8b;
		at: skip + 1 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ machineCodeSize := skip + 2
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeZeroExtend8RR [
	"Will get inlined into concretizeAt: switch."
	"movzxbq"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: (self rexw: true r: destReg x: 0 b: srcReg);
		at: 1 put: 16r0F;
		at: 2 put: 16rB6;
		at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> dispatchConcretize [
	"Attempt to generate concrete machine code for the instruction at address.
	 This is the inner dispatch of concretizeAt: actualAddress which exists only
	 to get around the branch size limits in the SqueakV3 (blue book derived)
	 bytecode set."
	<returnTypeC: #void>
	opcode >= CDQ ifTrue:
		[^self dispatchConcretizeProcessorSpecific].
	opcode caseOf: {
		"Noops & Pseudo Ops"
		[Label]				-> [^self concretizeLabel].
		[AlignmentNops]	-> [^self concretizeAlignmentNops].
		[Fill32]				-> [^self concretizeFill32].
		[Nop]				-> [^self concretizeNop].
		"Control"
		[Call]					-> [^self concretizeCall].
		[CallR]					-> [^self concretizeCallR].
		[CallFull]				-> [^self concretizeCallFull].
		[JumpR]					-> [^self concretizeJumpR].
		[JumpFull]				-> [^self concretizeJumpFull].
		[JumpLong]				-> [^self concretizeJumpLong].
		[JumpLongZero]		-> [^self concretizeConditionalJump: 16r4].
		[JumpLongNonZero]	-> [^self concretizeConditionalJump: 16r5].
		[Jump]					-> [^self concretizeJump].
		"Table B-1 Intel 64 and IA-32 Architectures Software Developer's Manual Volume 1: Basic Architecture"
		[JumpZero]				-> [^self concretizeConditionalJump: 16r4].
		[JumpNonZero]			-> [^self concretizeConditionalJump: 16r5].
		[JumpNegative]			-> [^self concretizeConditionalJump: 16r8].
		[JumpNonNegative]		-> [^self concretizeConditionalJump: 16r9].
		[JumpOverflow]			-> [^self concretizeConditionalJump: 16r0].
		[JumpNoOverflow]		-> [^self concretizeConditionalJump: 16r1].
		[JumpCarry]			-> [^self concretizeConditionalJump: 16r2].
		[JumpNoCarry]			-> [^self concretizeConditionalJump: 16r3].
		[JumpLess]				-> [^self concretizeConditionalJump: 16rC].
		[JumpGreaterOrEqual]	-> [^self concretizeConditionalJump: 16rD].
		[JumpGreater]			-> [^self concretizeConditionalJump: 16rF].
		[JumpLessOrEqual]		-> [^self concretizeConditionalJump: 16rE].
		[JumpBelow]			-> [^self concretizeConditionalJump: 16r2].
		[JumpAboveOrEqual]	-> [^self concretizeConditionalJump: 16r3].
		[JumpAbove]			-> [^self concretizeConditionalJump: 16r7].
		[JumpBelowOrEqual]	-> [^self concretizeConditionalJump: 16r6].
		[JumpFPEqual]				-> [^self concretizeConditionalJump: 16r4].
		[JumpFPNotEqual]			-> [^self concretizeConditionalJump: 16r5].
		[JumpFPLess]				-> [^self concretizeConditionalJump: 16r2].
		[JumpFPGreaterOrEqual]	-> [^self concretizeConditionalJump: 16r3].
		[JumpFPGreater]			-> [^self concretizeConditionalJump: 16r7].
		[JumpFPLessOrEqual]		-> [^self concretizeConditionalJump: 16r6].
		[JumpFPOrdered]			-> [^self concretizeConditionalJump: 16rB].
		[JumpFPUnordered]			-> [^self concretizeConditionalJump: 16rA].
		[RetN]						-> [^self concretizeRetN].
		[Stop]						-> [^self concretizeStop].
		"Arithmetic"
		[AddCqR]					-> [^self concretizeArithCqRWithRO: 0 raxOpcode: 15r05].
		[AddcCqR]					-> [^self concretizeArithCqRWithRO: 2 raxOpcode: 15r15].
		[AddCwR]					-> [^self concretizeArithCwR: 16r03].
		[AddRR]						-> [^self concretizeOpRR: 16r03].
		[AddRsRs]					-> [^self concretizeSEEOpRsRs: 16r58].
		[AddRdRd]					-> [^self concretizeSEE2OpRdRd: 16r58].
		[AndCqR]					-> [^self concretizeArithCqRWithRO: 4 raxOpcode: 16r25].
		[AndCwR]					-> [^self concretizeArithCwR: 16r23].
		[AndRR]						-> [^self concretizeOpRR: 16r23].
		[TstCqR]					-> [^self concretizeTstCqR].
		[CmpCqR]					-> [^self concretizeArithCqRWithRO: 7 raxOpcode: 16r3D].
		[CmpCwR]					-> [^self concretizeArithCwR: 16r39].
		[CmpC32R]					-> [^self concretizeCmpC32R].
		[CmpRR]					-> [^self concretizeReverseOpRR: 16r39].
		[CmpRdRd]					-> [^self concretizeCmpRdRd].
		[CmpRsRs]					-> [^self concretizeCmpRsRs].
		[DivRdRd]					-> [^self concretizeSEE2OpRdRd: 16r5E].
		[DivRsRs]					-> [^self concretizeSEEOpRsRs: 16r5E].
		[MulRdRd]					-> [^self concretizeSEE2OpRdRd: 16r59].
		[MulRsRs]					-> [^self concretizeSEEOpRsRs: 16r59].
		[OrCqR]						-> [^self concretizeArithCqRWithRO: 1 raxOpcode: 16r0D].
		[OrCwR]					-> [^self concretizeArithCwR: 16r0B].
		[OrRR]						-> [^self concretizeOpRR: 16r0B].
		[SubCqR]					-> [^self concretizeArithCqRWithRO: 5 raxOpcode: 16r2D].
		[SubbCqR]					-> [^self concretizeArithCqRWithRO: 3 raxOpcode: 16r1D].
		[SubCwR]					-> [^self concretizeArithCwR: 16r2B].
		[SubRR]						-> [^self concretizeOpRR: 16r2B].
		[SubRdRd]					-> [^self concretizeSEE2OpRdRd: 16r5C].
		[SubRsRs]					-> [^self concretizeSEEOpRsRs: 16r5C].
		[SqrtRd]					-> [^self concretizeSqrtRd].
		[SqrtRs]					-> [^self concretizeSqrtRs].
		[XorCwR]					-> [^self concretizeArithCwR: 16r33].
		[XorRR]						-> [^self concretizeOpRR: 16r33].
		[XorRdRd]						-> [^self concretizeXorRdRd].
		[XorRsRs]						-> [^self concretizeXorRsRs].
		[NegateR]					-> [^self concretizeNegateR].
		[LoadEffectiveAddressMwrR]	-> [^self concretizeLoadEffectiveAddressMwrR].
		[RotateLeftCqR]				-> [^self concretizeShiftCqRegOpcode: 0].
		[RotateRightCqR]				-> [^self concretizeShiftCqRegOpcode: 1].
		[ArithmeticShiftRightCqR]		-> [^self concretizeShiftCqRegOpcode: 7].
		[LogicalShiftRightCqR]			-> [^self concretizeShiftCqRegOpcode: 5].
		[LogicalShiftLeftCqR]			-> [^self concretizeShiftCqRegOpcode: 4].
		[ArithmeticShiftRightRR]			-> [^self concretizeShiftRegRegOpcode: 7].
		[LogicalShiftLeftRR]				-> [^self concretizeShiftRegRegOpcode: 4].
		"Data Movement"
		[MoveCqR]			-> [^self concretizeMoveCqR].
		[MoveCwR]			-> [^self concretizeMoveCwR].
		[MoveC32R]		-> [^self concretizeMoveC32R].
		[MoveRR]			-> [^self concretizeReverseOpRR: 16r89].
		[MoveAwR]			-> [^self concretizeMoveAwR].
		[MoveA32R]		-> [^self concretizeMoveA32R].
		[MoveRAw]			-> [^self concretizeMoveRAw].
		[MoveRA32]		-> [^self concretizeMoveRA32].
		[MoveAbR]			-> [^self concretizeMoveAbR].
		[MoveRAb]			-> [^self concretizeMoveRAb].
		[MoveMbrR]			-> [^self concretizeMoveMbrR].
		[MoveRMbr]			-> [^self concretizeMoveRMbr].
		[MoveM8rR]		-> [^self concretizeMoveMbrR].
		[MoveRM8r]		-> [^self concretizeMoveRMbr].
		[MoveM16rR]		-> [^self concretizeMoveM16rR].
		[MoveRM16r]		-> [^self concretizeMoveRM16r].
		[MoveM32rR]		-> [^self concretizeMoveM32rR].
		[MoveM32rRs]		-> [^self concretizeMoveM32rRs].
		[MoveM64rRd]		-> [^self concretizeMoveM64rRd].
		[MoveMwrR]		-> [^self concretizeMoveMwrR].
		[MoveXbrRR]		-> [^self concretizeMoveXbrRR].
		[MoveRXbrR]		-> [^self concretizeMoveRXbrR].
		[MoveXwrRR]		-> [^self concretizeMoveXwrRR].
		[MoveRXwrR]		-> [^self concretizeMoveRXwrR].
		[MoveX32rRR]		-> [^self concretizeMoveX32rRR].
		[MoveRX32rR]		-> [^self concretizeMoveRX32rR].
		[MoveRMwr]		-> [^self concretizeMoveRMwr].
		[MoveRM32r]		-> [^self concretizeMoveRM32r].
		[MoveRsM32r]		-> [^self concretizeMoveRsM32r].
		[MoveRdM64r]		-> [^self concretizeMoveRdM64r].
		[MoveRdR]			-> [^self concretizeMoveRdR].
		[MoveRRd]			-> [^self concretizeMoveRRd].
		[MoveRdRd]		-> [^self concretizeMoveRdRd].
		[MoveRsRs]		-> [^self concretizeMoveRsRs].
		[PopR]				-> [^self concretizePopR].
		[PushR]				-> [^self concretizePushR].
		[PushCq]			-> [^self concretizePushCq].
		[PushCw]			-> [^self concretizePushCw].
		[PrefetchAw]		-> [^self concretizePrefetchAw].
		"Conversion"
		[ConvertRRd]		-> [^self concretizeConvertRRd].
		[ConvertRdR]		-> [^self concretizeConvertRdR].
		[ConvertRRs]		-> [^self concretizeConvertRRs].
		[ConvertRsR]		-> [^self concretizeConvertRsR].
		[ConvertRsRd]	-> [^self concretizeConvertRsRd].
		[ConvertRdRs]	-> [^self concretizeConvertRdRs].
			
		[SignExtend8RR]		-> [^self concretizeSignExtend8RR].
		[SignExtend16RR]	-> [^self concretizeSignExtend16RR].
		[SignExtend32RR]	-> [^self concretizeSignExtend32RR].
		
		[ZeroExtend8RR]		-> [^self concretizeZeroExtend8RR].
		[ZeroExtend16RR]	-> [^self concretizeZeroExtend16RR].
		[ZeroExtend32RR]	-> [^self concretizeZeroExtend32RR].
		
		"This is a fixed size instruction using a patcheable literal."
		[MovePatcheableC32R] -> [ ^ self concretizeMovePatcheableC32R ]
		}
]

{ #category : #'generate machine code' }
CogX64Compiler >> dispatchConcretizeProcessorSpecific [
	"Attempt to generate concrete machine code for the instruction at address.
	 This is part of the inner dispatch of concretizeAt: actualAddress which exists only
	 to get around the number of literals limits in the SqueakV3 (blue book derived)
	 bytecode set."
	<returnTypeC: #void>
	opcode caseOf: {
		"Specific Control/Data Movement"
		[CDQ]					-> [^self concretizeCDQ].
		[IDIVR]					-> [^self concretizeIDIVR].
		[IMULRR]				-> [^self concretizeMulRR].
"		[CPUID]					-> [^self concretizeCPUID].
		[CMPXCHGAwR]			-> [^self concretizeCMPXCHGAwR].
		[CMPXCHGMwrR]		-> [^self concretizeCMPXCHGMwrR].
		"[LFENCE]				-> [^self concretizeFENCE: 5].
		[MFENCE]				-> [^self concretizeFENCE: 6].
		[SFENCE]				-> [^self concretizeFENCE: 7].
		"[LOCK]					-> [^self concretizeLOCK]."
		[XCHGAwR]				-> [^self concretizeXCHGAwR].
		"[XCHGMwrR]			-> [^self concretizeXCHGMwrR]."
		[XCHGRR]				-> [^self concretizeXCHGRR].
		[REP]					-> [^self concretizeREP].
		[CLD]					-> [^self concretizeCLD].
		[MOVSB]				-> [^self concretizeMOVSB].
		[MOVSQ]				-> [^self concretizeMOVSQ].
	}
]

{ #category : #'inline cacheing' }
CogX64Compiler >> flushICacheFrom: startAddress "<Integer>" to: endAddress [ "<Integer>"
	<cmacro: '(me,startAddress,endAddress) 0'>
	"On Intel processors where code and data have the same linear address, no
	 special action is required to flush the instruciton cache.  One only needs to
	 execute a serializing instruction (e.g. CPUID) if code and data are at different
	 virtual addresses (e.g. a debugger using memory-mapping to access a debugee).
	 Using the macro avoids an unnecessary call."
	self halt: #ceFlushICache
]

{ #category : #abi }
CogX64Compiler >> fullCallsAreRelative [
	^false
]

{ #category : #'abstract instructions' }
CogX64Compiler >> genDivR: abstractRegDivisor R: abstractRegDividend Quo: abstractRegQuotient Rem: abstractRegRemainder [
	| rDividend rDivisor rQuotient rRemainder saveRestoreEAX saveRestoreEDX saveRestoreExchanged |
	self assert: abstractRegDividend ~= abstractRegDivisor.
	self assert: abstractRegQuotient ~= abstractRegRemainder.
	rDividend := abstractRegDividend.
	rDivisor := abstractRegDivisor.
	rQuotient := abstractRegQuotient.
	rRemainder := abstractRegRemainder.
	"IDIV r does a signed divide of RDX:RAX by r, RAX := Quotient, RDX := Remainder.
	 Since we must sign extend the dividend into RDX we must substitute another register if RDX is an input."
	(rDividend = RDX or: [rDivisor = RDX]) ifTrue:
		[| rUnused |
		"Slang, sigh..."
		rUnused := RAX.
		[rUnused <= RDI] whileTrue:
			[(rUnused ~= RSP and: [rUnused ~= RBP and: [rUnused ~= RDX
			  and: [rUnused ~= rDividend and: [rUnused ~= rDivisor
			  and: [rUnused ~= rQuotient and: [rUnused ~= rRemainder]]]]]]) ifTrue:
				[cogit PushR: rUnused.
				cogit MoveR: RDX R: rUnused.
				rDividend = RDX
					ifTrue: [self genDivR: rDivisor R: rUnused Quo: rQuotient Rem: rRemainder]
					ifFalse: [self genDivR: rUnused R: rDividend Quo: rQuotient Rem: rRemainder].
				cogit PopR: rUnused.
				^self].
			  rUnused := rUnused + 1].
		self error: 'couldn''t find unused register in genDivR:R:Quo:Rem:'].
	"If either output does not include RAX or RDX we must save and restore RAX and/or RDX."
	(saveRestoreEAX := rQuotient ~= RAX and: [rRemainder ~= RAX]) ifTrue:
		[cogit PushR: RAX].
	(saveRestoreEDX := rQuotient ~= RDX and: [rRemainder ~= RDX]) ifTrue:
		[cogit PushR: RDX].
	saveRestoreExchanged := -1.
	rDividend ~= RAX ifTrue:
		[rDivisor = RAX
			ifTrue: [((rDividend ~= rQuotient and: [rDividend ~= rRemainder])
					and: [rDividend ~= RDX or: [saveRestoreEDX not]]) ifTrue:
						[cogit PushR: (saveRestoreExchanged := rDividend)].
					cogit gen: XCHGRR operand: rDivisor operand: rDividend]
			ifFalse: [cogit MoveR: rDividend R: RAX]].
	"CDQ sign-extends RAX into RDX as required for IDIV"
	cogit gen: CDQ.
	cogit gen: IDIVR operand: (rDivisor = RAX ifTrue: [rDividend] ifFalse: [rDivisor]).
	"Must not overwrite result while juggling"
	(rQuotient = RDX and: [rRemainder = RAX])
		ifTrue: [cogit gen: XCHGRR operand: rQuotient operand: rRemainder]
		ifFalse:
			[rQuotient = RDX
				ifTrue:
					[rRemainder ~= RDX ifTrue:
						[cogit MoveR: RDX R: rRemainder].
					rQuotient ~= RAX ifTrue:
						[cogit MoveR: RAX R: rQuotient]]
				ifFalse:
					[rQuotient ~= RAX ifTrue:
						[cogit MoveR: RAX R: rQuotient].
					rRemainder ~= RDX ifTrue:
						[cogit MoveR: RDX R: rRemainder]]].
	saveRestoreExchanged >= 0 ifTrue:
		[cogit PopR: saveRestoreExchanged].
	saveRestoreEDX ifTrue:
		[cogit PopR: RDX].
	saveRestoreEAX ifTrue:
		[cogit PopR: RAX]
]

{ #category : #'abstract instructions' }
CogX64Compiler >> genJumpFPEqual: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	| jumpUnordered jumpToTarget |
	<var: #jumpUnordered type: #'AbstractInstruction *'>
	<var: #jumpToTarget type: #'AbstractInstruction *'>
	jumpUnordered := cogit gen: JumpFPUnordered.
	jumpToTarget := cogit gen: JumpFPEqual operand: jumpTarget asInteger.
	jumpUnordered jmpTarget: cogit Label.
	^jumpToTarget
]

{ #category : #'abstract instructions' }
CogX64Compiler >> genJumpFPNotEqual: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	| jumpUnordered jumpToTarget |
	<var: #jumpUnordered type: #'AbstractInstruction *'>
	<var: #jumpToTarget type: #'AbstractInstruction *'>
	jumpToTarget := cogit gen: JumpFPNotEqual operand: jumpTarget asInteger.
	jumpUnordered := cogit gen: JumpFPUnordered operand: jumpTarget asInteger.
	jumpToTarget addDependent: jumpUnordered.
	^jumpToTarget
]

{ #category : #'smalltalk calling convention' }
CogX64Compiler >> genLoadCStackPointer [
	"Load the stack pointer register with that of the C stack, effecting
	 a switch to the C stack.  Used when machine code calls into the
	 CoInterpreter run-time (e.g. to invoke interpreter primitives)."
	cogit MoveAw: cogit cStackPointerAddress R: SPReg.
	^0
]

{ #category : #'smalltalk calling convention' }
CogX64Compiler >> genLoadCStackPointers [
	"Load the frame and stack pointer registers with those of the C stack,
	 effecting a switch to the C stack.  Used when machine code calls into
	 the CoInterpreter run-time (e.g. to invoke interpreter primitives)."
	cogit MoveAw: cogit cStackPointerAddress R: SPReg.
	cogit MoveAw: cogit cFramePointerAddress R: FPReg.
	^0
]

{ #category : #'smalltalk calling convention' }
CogX64Compiler >> genLoadStackPointers [
	"Switch back to the Smalltalk stack. Assign SPReg first
	 because typically it is used immediately afterwards."
	cogit MoveAw: cogit stackPointerAddress R: SPReg.
	cogit MoveAw: cogit framePointerAddress R: FPReg.
	^0
]

{ #category : #abi }
CogX64Compiler >> genMarshallNArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 [
	"Generate the code to pass up to four arguments in a C run-time call.  Hack: each argument is
	 either a negative number, which encodes a constant, or a non-negative number, that of a register.

	 Run-time calls have no more than four arguments, so chosen so that on ARM, where in its C ABI the
	 first four integer arguments are passed in registers, all arguments can be passed in registers.  We
	 defer to the back end to generate this code not so much that the back end knows whether it uses
	 the stack or registers to pass arguments (it does, but...). In fact we defer for an extremely evil reason.
	 Doing so allows the x64 (where up to 6 args are passed) to assign the register arguments in an order
	 that allows some of the argument registers to be used for specific abstract  registers, specifically
	 ReceiverResultReg and ClassReg.  This is evil, evil, evil, but also it's really nice to keep using the old
	 register assignments the original author has grown accustomed to.

	 How can this possibly work?  Look at Cogit class>>runtime for a list of the run-time calls and their
	 arguments, including which arguments are passed in which registers.  Look at CogX64Compiler's
	 subclass implementations of initializeAbstractRegisters.  There are no calls in which ReceiverResultReg
	 (RDX) and/or ClassReg (RCX) are passed along with Arg0Reg and Arg1Reg, and none in which the use of
	 either ReceiverResultReg or ClassReg conflict for args 3 & 4.  So if args are assigned in order, the
	 registers do not get overwritten.  Yes, this is evil, but it's so nice to continue to use RCX & RDX.

	 Argument registers for args 0 to 3 in SysV are RDI RSI RDX RCX, and in Win64 are RCX RDX R8 R9"
	<inline: true>
	SysV ifFalse: "WIN64 ABI allways reserve shadow space on the stack for callee to save up to 4 register parameters"
		[cogit SubCq: 32 R: RSP].
	numArgs = 0 ifTrue: [^self].
	SysV
		 ifTrue:
			[(cogit isTrampolineArgConstant: regOrConst0)
				ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst0) R: RDI] "a.k.a. Arg0Reg"
				ifFalse:
					[regOrConst0 ~= RDI ifTrue:
						[cogit MoveR: regOrConst0 R: RDI]].
			numArgs = 1 ifTrue: [^self].
			(cogit isTrampolineArgConstant: regOrConst1)
				ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst1) R: RSI] "a.k.a. Arg1Reg"
				ifFalse:
					[regOrConst1 ~= RSI ifTrue:
						[cogit MoveR: regOrConst1 R: RSI]].
			numArgs = 2 ifTrue: [^self].
			(cogit isTrampolineArgConstant: regOrConst2)
				ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst2) R: RDX] "a.k.a. ReceiverResultReg"
				ifFalse:
					[regOrConst2 ~= RDX ifTrue:
						[cogit MoveR: regOrConst2 R: RDX]].
			 numArgs = 3 ifTrue: [^self].
			 (cogit isTrampolineArgConstant: regOrConst3)
					ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst3) R: RCX] "a.k.a. ClassReg"
					ifFalse:
						[regOrConst3 ~= RCX ifTrue:
							[cogit MoveR: regOrConst3 R: RCX]]]
		ifFalse:
			[(cogit isTrampolineArgConstant: regOrConst0)
				ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst0) R: RCX] "a.k.a. Arg0Reg"
				ifFalse:
					[regOrConst0 ~= RCX ifTrue:
						[cogit MoveR: regOrConst0 R: RCX]].
			numArgs = 1 ifTrue: [^self].
			(cogit isTrampolineArgConstant: regOrConst1)
				ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst1) R: RDX] "a.k.a. Arg1Reg"
				ifFalse:
					[regOrConst1 ~= RDX ifTrue:
						[cogit MoveR: regOrConst1 R: RDX]].
			numArgs = 2 ifTrue: [^self].
			(cogit isTrampolineArgConstant: regOrConst2)
				ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst2) R: R8] "a.k.a. RISCTempReg in CogInLineLiteralsX64Compiler and Extra6Reg in CogOutOfLineLiteralsX64Compiler"
				ifFalse:
					[regOrConst2 ~= R8 ifTrue:
						[cogit MoveR: regOrConst2 R: R8]].
			 numArgs = 3 ifTrue: [^self].
			 (cogit isTrampolineArgConstant: regOrConst3)
					ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst3) R: R9] "a.k.a. SendNumArgsReg"
					ifFalse:
						[regOrConst3 ~= R9 ifTrue:
							[cogit MoveR: regOrConst3 R: R9]]].
	self assert: numArgs <= 4
]

{ #category : #abi }
CogX64Compiler >> genMarshallNArgs: numArgs floatArg: regOrConst0 floatArg: regOrConst1 floatArg: regOrConst2 floatArg: regOrConst3 [
	"Generate the code to pass up to four float arguments in a C run-time call.  Hack: each argument is
	 either a negative number, which encodes a constant, or a non-negative number, that of a register.

	 Run-time calls have no more than four arguments, so chosen so that on ARM, where in its C ABI the
	 first four integer arguments are passed in registers, all arguments can be passed in registers.  We
	 defer to the back end to generate this code not so much that the back end knows whether it uses
	 the stack or registers to pass arguments (it does, but...). In fact we defer for an extremely evil reason.
	 Doing so allows the x64 (where up to 6 args are passed) to assign the register arguments in an order
	 that allows some of the argument registers to be used for specific abstract  registers, specifically
	 ReceiverResultReg and ClassReg.  This is evil, evil, evil, but also it's really nice to keep using the old
	 register assignments the original author has grown accustomed to."
	<inline: true>
	SysV ifFalse: "WIN64 ABI allways reserve shadow space on the stack for callee to save up to 4 register parameters"
		[cogit SubCq: 32 R: RSP].
	numArgs = 0 ifTrue: [^self].
	
	(cogit isTrampolineArgConstant: regOrConst0)
		ifTrue: [cogit MoveCf64: (cogit trampolineArgValue: regOrConst0) Rd: XMM0L] "a.k.a. DPFPReg0"
		ifFalse: [regOrConst0 ~= XMM0L ifTrue:
						[cogit MoveR: regOrConst0 R: XMM0L]].
	numArgs = 1 ifTrue: [^self].
	
	(cogit isTrampolineArgConstant: regOrConst1)
		ifTrue: [cogit MoveCf64: (cogit trampolineArgValue: regOrConst1) Rd: XMM1L] "a.k.a. DPFPReg1"
		ifFalse: [regOrConst1 ~= XMM1L ifTrue:
						[cogit MoveR: regOrConst1 R: XMM1L]].
	numArgs = 2 ifTrue: [^self].

	(cogit isTrampolineArgConstant: regOrConst2)
		ifTrue: [cogit MoveCf64: (cogit trampolineArgValue: regOrConst2) Rd: XMM2L] "a.k.a. DPFPReg0"
		ifFalse: [regOrConst2 ~= XMM2L ifTrue:
						[cogit MoveR: regOrConst2 R: XMM2L]].
	numArgs = 3 ifTrue: [^self].

	(cogit isTrampolineArgConstant: regOrConst3)
		ifTrue: [cogit MoveCf64: (cogit trampolineArgValue: regOrConst3) Rd: XMM3L] "a.k.a. DPFPReg3"
		ifFalse: [regOrConst3 ~= XMM3L ifTrue:
						[cogit MoveR: regOrConst3 R: XMM3L]].

	self assert: numArgs <= 4
]

{ #category : #'abstract instructions' }
CogX64Compiler >> genMemCopy: originalSourceReg to: originalDestReg constantSize: size [
	| numbytes numwords sourceReg destReg countReg inst |

	"Get the abstract registers for ECX, EDI and ESI"
	sourceReg := RSI.
	destReg := RDI.
	countReg := RCX.

	"Put the source in ESI and the dest in EDI"
	inst := cogit Label.
	originalSourceReg ~= sourceReg ifTrue: [
		originalDestReg = sourceReg ifTrue: [
			cogit MoveR: originalDestReg R: TempReg.
		].
		cogit MoveR: originalSourceReg R: sourceReg.
	].

	originalDestReg ~= destReg ifTrue: [
		originalDestReg = sourceReg ifTrue: [
			cogit MoveR: TempReg R: destReg.
		] ifFalse: [
			cogit MoveR: originalDestReg R: destReg.
		]
	].

	"Store the count and clear the direction"
	cogit gen: CLD.

	"First copy the bytes"
	numbytes := size bitAnd: 16r07.
	numbytes > 0 ifTrue: [
		cogit MoveCq: numbytes R: countReg.
		cogit gen: REP.
		cogit gen: MOVSB.
	].

	"Now copy the qwords"
	numwords := size // 8.
	cogit MoveCq:  numwords R: countReg.
	cogit gen: REP.
	cogit gen: MOVSQ.


]

{ #category : #'abstract instructions' }
CogX64Compiler >> genMemCopy: originalSourceReg to: originalDestReg size: originalSize [
	| spilledSize size sourceReg destReg countReg inst |

	"Get the abstract registers for ECX, EDI and ESI"
	sourceReg := RSI.
	destReg := RDI.
	countReg := RCX.

	"TODO: Avoid spilling"
	spilledSize := false.
	(originalSize = sourceReg or: [originalSize = destReg]) ifTrue: [
		cogit PushR: originalSize.
		spilledSize := true.
	].

	"Put the source in ESI and the dest in EDI"
	inst := cogit Label.
	originalSourceReg ~= sourceReg ifTrue: [
		originalDestReg = sourceReg ifTrue: [
			cogit MoveR: originalDestReg R: TempReg.
		].
		cogit MoveR: originalSourceReg R: sourceReg.
	].

	originalDestReg ~= destReg ifTrue: [
		originalDestReg = sourceReg ifTrue: [
			cogit MoveR: TempReg R: destReg.
		] ifFalse: [
			cogit MoveR: originalDestReg R: destReg.
		]
	].

	"Put the original size register in somewhere different than ECX"
	spilledSize ifTrue: [
		cogit PopR: TempReg.
		size := TempReg.
	] ifFalse: [
		originalSize = countReg ifTrue: [
			cogit MoveR: originalSize R: TempReg.
			size := TempReg.
		] ifFalse: [
			size := originalSize.
		]
	].

	cogit gen: CLD.

	"First copy the bytes"
	cogit MoveR: size R: countReg.
	cogit AndCq: 16r07 R: countReg.
	cogit gen: REP.
	cogit gen: MOVSB.

	"Now copy the words"
	cogit MoveR: size R: countReg.
	cogit LogicalShiftRightCq: 3 R: countReg.
	cogit gen: REP.
	cogit gen: MOVSQ.

]

{ #category : #'abstract instructions' }
CogX64Compiler >> genMoveCf32: constantFloat32 Rs: register [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #constantFloat32 type: #float>
	| inst |
	inst := cogit PushCw: constantFloat32 asIEEE32BitWord.
	cogit PopRs: register.
	^ inst
]

{ #category : #'abstract instructions' }
CogX64Compiler >> genMoveCf64: constantFloat64 Rd: register [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #constantFloat64 type: #double>
	| inst |
	inst := cogit PushCw: constantFloat64 asIEEE64BitWord.
	cogit PopRd: register.
	^ inst
]

{ #category : #'abstract instructions' }
CogX64Compiler >> genMulR: regSource R: regDest [
	^cogit gen: IMULRR operand: regSource operand: regDest
]

{ #category : #'abstract instructions' }
CogX64Compiler >> genPopRd: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	| inst |
	inst := cogit MoveM64: 0 r: SPReg Rd: reg .
	cogit AddCq: 8 R: SPReg.
	^ inst
]

{ #category : #'abstract instructions' }
CogX64Compiler >> genPopRs: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	| inst |
	inst := cogit MoveM32: 0 r: SPReg Rs: reg .
	cogit AddCq: 8 R: SPReg.
	^ inst
]

{ #category : #'abstract instructions' }
CogX64Compiler >> genPushC64: constant64Bits [
	<inline: true>
	^cogit PushCw: constant64Bits
]

{ #category : #'abstract instructions' }
CogX64Compiler >> genPushRd: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	| inst |
	inst := cogit MoveRd: reg M64: -8 r: SPReg.
	cogit SubCq: 8 R: SPReg.
	^ inst
]

{ #category : #'smalltalk calling convention' }
CogX64Compiler >> genPushRegisterArgsForAbortMissNumArgs: numArgs [
	"Ensure that the register args are pushed before the outer and
	 inner retpcs at an entry miss for arity <= self numRegArgs.  The
	 outer retpc is that of a call at a send site.  The inner is the call
	 from a method or PIC abort/miss to the trampoline."

	"This won't be as clumsy on a RISC.  But putting the receiver and
	 args above the return address means the CoInterpreter has a
	 single machine-code frame format which saves us a lot of work."

	"Iff there are register args convert
		base	->	outerRetpc		(send site retpc)
		sp		->	innerRetpc		(PIC abort/miss retpc)
	 to
		base	->	receiver
					(arg0)
					(arg1)
					outerRetpc
		sp		->	innerRetpc		(PIC abort/miss retpc)"
	numArgs <= cogit numRegArgs ifTrue:
		[self assert: cogit numRegArgs <= 2.
		 numArgs = 0 ifTrue:
			[cogit MoveMw: 0 r: SPReg R: TempReg.
			 cogit PushR: TempReg.
			 cogit MoveMw: objectMemory wordSize * 2 r: SPReg R: TempReg.
			 cogit MoveR: TempReg Mw: objectMemory wordSize r: SPReg.
			 cogit MoveR: ReceiverResultReg Mw: 2 * objectMemory wordSize r: SPReg.
			 ^self].
		 numArgs = 1 ifTrue:
			[cogit MoveMw: objectMemory wordSize r: SPReg R: TempReg.
			 cogit PushR: TempReg.
			 cogit MoveMw: objectMemory wordSize r: SPReg R: TempReg.
			 cogit PushR: TempReg.
			 cogit MoveR: ReceiverResultReg Mw: 3 * objectMemory wordSize r: SPReg.
			 cogit MoveR: Arg0Reg Mw: 2 * objectMemory wordSize r: SPReg.
			 ^self].
		 numArgs = 2 ifTrue:
			[cogit PushR: Arg1Reg.
			 cogit MoveMw: objectMemory wordSize * 2 r: SPReg R: TempReg.
			 cogit PushR: TempReg.
			 cogit MoveMw: objectMemory wordSize * 2 r: SPReg R: TempReg.
			 cogit PushR: TempReg.
			 cogit MoveR: ReceiverResultReg Mw: 4 * objectMemory wordSize r: SPReg.
			 cogit MoveR: Arg0Reg Mw: 3 * objectMemory wordSize r: SPReg.
			 ^self]]
]

{ #category : #'smalltalk calling convention' }
CogX64Compiler >> genPushRegisterArgsForNumArgs: numArgs scratchReg: scratchReg [
	"Ensure that the register args are pushed before the retpc for arity <= self numRegArgs.  This
	 isn't as clumsy on a RISC.  But putting the receiver and args above the return address
	 means the CoInterpreter has a single machine-code frame format which saves us a lot of work.
	 N.B. Take great care to /not/ smash TempReg, which is used in directed send marshalling.
	 We could use XCHG to swap the ReceiverResultReg and top-of-stack return address, pushing the
	 the ret pc (now in ReceiverResultReg) later, but XCHG is very slow.  We can use SendNumArgsReg
	 because it is only live in sends of arity >= (NumSendTrampolines - 1)."
	self assert: cogit numRegArgs < (NumSendTrampolines - 1).
	numArgs <= cogit numRegArgs ifTrue:
		[self assert: cogit numRegArgs <= 2.
		 false "these two variants show the same performance on Intel Core i7, but the second one may be shorter."
			ifTrue:
				[cogit MoveMw: 0 r: SPReg R: scratchReg. "Save return pc"
				 numArgs > 0 ifTrue:
					[cogit PushR: Arg0Reg.
					 numArgs > 1 ifTrue:
						[cogit PushR: Arg1Reg]].
				 cogit PushR: scratchReg.
				 cogit MoveR: ReceiverResultReg Mw: objectMemory wordSize * (1 + numArgs) r: SPReg]
			ifFalse:
				["a.k.a.
					cogit gen: XCHGMwrR operand: 0 operand: SPReg operand: ReceiverResultReg.
				  but XCHG is slow."
				 cogit MoveMw: 0 r: SPReg R: scratchReg. "Save return pc"
				 cogit MoveR: ReceiverResultReg Mw: 0 r: SPReg.
				 numArgs > 0 ifTrue:
					[cogit PushR: Arg0Reg.
					 numArgs > 1 ifTrue:
						[cogit PushR: Arg1Reg]].
				 cogit PushR: scratchReg]] "Restore return address"
]

{ #category : #'abstract instructions' }
CogX64Compiler >> genPushRs: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	| inst |
	inst := cogit MoveRs: reg M32: -8 r: SPReg.
	cogit SubCq: 8 R: SPReg.
	^ inst
]

{ #category : #abi }
CogX64Compiler >> genRemoveNArgsFromStack: n [
	"This is a no-op on x64 SysV since the ABI passes up to 6 args in registers and trampolines currently observe a limit of 4.
	But the WIN64 ABI allways reserve shadow space for saving up to 4 parameter registers (even if less than 4 args)."
	<inline: true>
	self assert: n <= 4.
	SysV ifFalse: [cogit AddCq: 32 R: RSP].
	^0
]

{ #category : #abi }
CogX64Compiler >> genRemoveNFloatArgsFromStack: n [
	"This is a no-op on x64 SysV since the ABI passes up to 6 args in registers and trampolines currently observe a limit of 4.
	But the WIN64 ABI allways reserve shadow space for saving up to 4 parameter registers (even if less than 4 args)."
	<inline: true>
	self assert: n <= 4.
	SysV ifFalse: [cogit AddCq: 32 R: RSP].
	^0
]

{ #category : #abi }
CogX64Compiler >> genRestoreRegs: regMask [
	"Restore the registers in regMask as saved by genSaveRegs:."
	self deny: (regMask anyMask: (cogit registerMaskFor: RSP and: RBP)).
	RAX to: R15 do:
		[:reg|
		 (regMask anyMask: (cogit registerMaskFor: reg)) ifTrue:
			[cogit PopR: reg]].
	^0
]

{ #category : #abi }
CogX64Compiler >> genSaveRegs: regMask [
	"Save the registers in regMask for a call into the C run-time from a trampoline."

	self assert: (R15 > RAX and: [R15 - RAX + 1 = 16]).
	self deny: (regMask anyMask: (cogit registerMaskFor: RSP and: RBP)).
	R15 to: RAX by: -1 do:
		[:reg|
		 (regMask anyMask: (cogit registerMaskFor: reg)) ifTrue:
			[cogit PushR: reg]].
	^0
]

{ #category : #'smalltalk calling convention' }
CogX64Compiler >> genSaveStackPointers [
	"Save the frame and stack pointer registers to the framePointer
	 and stackPointer variables.  Used to save the machine code frame
	 for use by the run-time when calling into the CoInterpreter run-time."
	cogit MoveR: FPReg Aw: cogit framePointerAddress.
	cogit MoveR: SPReg Aw: cogit stackPointerAddress.
	^0
]

{ #category : #'abstract instructions' }
CogX64Compiler >> genSubstituteReturnAddress: retpc [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^cogit PushCw: retpc
]

{ #category : #'abstract instructions' }
CogX64Compiler >> genSwapR: regA R: regB Scratch: regTmp [
	^cogit gen: XCHGRR operand: regA operand: regB
]

{ #category : #disassembly }
CogX64Compiler >> generalPurposeRegisterMap [
	<doNotGenerate>
	"Answer a Dictionary from register getter to register index."
	^Dictionary newFromPairs:
		{	#rax. RAX.
			#rcx. RCX.
			#rdx. RDX.
			#rbx. RBX.
			#rsi.  RSI.
			#rdi.  RDI.
			#r8. R8.
			#r9. R9.
			#r10. R10.
			#r11. R11.
			#r12. R12.
			#r13. R13.
			#r14. R14.
			#r15. R15	}
]

{ #category : #'multi-threading' }
CogX64Compiler >> generateLowLevelTryLock: vmOwnerLockAddress [
	"Generate a function that attempts to lock the vmOwnerLock and answers
	 true if it succeeded."
	vmOwnerLockAddress = 0 ifTrue:
		[cogit
			MoveCq: 1 R: RAX;
			RetN: 0.
		 ^self].
	cogit
		MoveCq: 1 R: RAX;
		gen: MFENCE; "make the XCHG globally consistent"
		MoveAw: vmOwnerLockAddress R: R10;
		gen: XCHGRR operand: RAX operand: R10;
		gen: SFENCE; "make the store globally visible"
		SubCq: 1 R: RAX; "Since we only ever set the lock to 1 or 0, subtracting 1 sets
						   EAX to 0 if the lock was already locked and non-zero if it wasn't."
		RetN: 0
]

{ #category : #'multi-threading' }
CogX64Compiler >> generateLowLevelUnlock: vmOwnerLockAddress [
	vmOwnerLockAddress ~= 0 ifTrue:
		[cogit
			MoveCq: 0 R: RAX;
			MoveR: RAX Aw: vmOwnerLockAddress;
			gen: SFENCE].
	cogit RetN: 0
]

{ #category : #testing }
CogX64Compiler >> hasConditionRegister [
	"Answer if the receiver supports, e.g., JumpOverflow after a regular AddRR"
	^true
]

{ #category : #testing }
CogX64Compiler >> hasDoublePrecisionFloatingPointSupport [
	^true
]

{ #category : #testing }
CogX64Compiler >> hasLinkRegister [
	^false
]

{ #category : #testing }
CogX64Compiler >> hasThreeAddressArithmetic [
	"Answer if the receiver supports three-address arithmetic instructions"
	^false
]

{ #category : #testing }
CogX64Compiler >> hasVarBaseRegister [
	"Answer if the processor has a dedicated callee-saved register to point to
	 the base of commonly-accessed variables."
	^true "RBX"
]

{ #category : #disassembly }
CogX64Compiler >> instructionSizeAt: pc [
	"Answer the instruction size at pc. This is used in method disassembly
	 to decode the jumps in block dispatch to discover where block methods
	 occur within a larger method.   This is very far from a full decode."
	| op |
	op := objectMemory byteAt: pc.
	(op bitAnd: 16rF8) = 16r48 ifTrue:
		[^1 + (self instructionSizeAt: pc + 1)].
	^op caseOf:
		{	[16r0F]	->	[self twoByteInstructionSizeAt: pc].
			[16r3D]	->	[5]. "cmp EAX,imm32"
			[16r70]	->	[2]. "short conditional jumps"
			[16r71]	->	[2].
			[16r72]	->	[2].
			[16r73]	->	[2].
			[16r74]	->	[2].
			[16r75]	->	[2].
			[16r76]	->	[2].
			[16r77]	->	[2].
			[16r78]	->	[2].
			[16r79]	->	[2].
			[16r7A]	->	[2].
			[16r7B]	->	[2].
			[16r7C]	->	[2].
			[16r7D]	->	[2].
			[16r7E]	->	[2].
			[16r7F]	->	[2].
			[16r83]	->	[self sizeImmediateGroup1: op at: pc].
			[16r89]	->	[2]. "MOV Eb,Gb"
			[16r8B]	->	[self sizeHasModrm: op at: pc].
			[16r90]	->	[1]. "nop"
			[16rE9] ->	[5]. "long unconditional jump"
			[16rEB] ->	[2]. "short unconditional jump"
			[16rCC]	->	[1]. "int3" }
]

{ #category : #testing }
CogX64Compiler >> is32BitSignedImmediate: a64BitUnsignedOperand [
	"Top 32 bits all the same as the bottom 32 bits' sign bit implies we can use a sign-extended 4 byte offset."
	^self cCode: [(self cCoerceSimple: a64BitUnsignedOperand to: #int) = (self cCoerceSimple: a64BitUnsignedOperand to: #sqLong)]
		inSmalltalk: [((a64BitUnsignedOperand >> 32) signedIntFromLong + 1 bitXor: 1) = (a64BitUnsignedOperand >> 31 bitAnd: 1)]
]

{ #category : #testing }
CogX64Compiler >> isAddressRelativeToVarBase: varAddress [
	<inline: true>
	<var: #varAddress type: #usqInt>
	"Support for addressing variables off the dedicated VarBaseReg.  Allow for 1Mb of variables.
	 The x64 supports 32-bit offsets, but we choose not to address everything from VarBaseReg."
	^varAddress notNil
	  and: [varAddress >= cogit varBaseAddress
	  and: [varAddress - cogit varBaseAddress < (1 << 20)]]
]

{ #category : #testing }
CogX64Compiler >> isBigEndian [
	^false
]

{ #category : #testing }
CogX64Compiler >> isCallPrecedingReturnPC: mcpc [
	"Assuming mcpc is a send return pc answer if the instruction before it is a call (not a CallFull)."
	^(objectMemory byteAt: mcpc - 5) = 16rE8
]

{ #category : #disassembly }
CogX64Compiler >> isJumpAt: pc [
	| op |
	op := objectMemory byteAt: pc.
	^  (op between: 16r70 and: 16r7F) "short conditional jumps"
	or: [op = 16rE9 "long unconditional jump"
	or: [op = 16rEB "short unconditional jump"
	or: [(op = 16r0F "long conditional jumps"
		and: [(objectMemory byteAt: pc + 1) between: 16r80 and: 16r8F])
	or: [op = 16r48 "full unconditional jumps"
		and: [(objectMemory byteAt: pc + 1) = 16rA1
		and: [(objectMemory byteAt: pc + 10) = 16rFF
		and: [(objectMemory byteAt: pc + 11) = 16rE0]]]]]]]
]

{ #category : #testing }
CogX64Compiler >> isQuick: operand [
	<var: #operand type: #'usqIntptr_t'>
	^operand signedIntFromLong64 between: -128 and: 127
]

{ #category : #testing }
CogX64Compiler >> isWithinMwOffsetRange: anAddress [
	"Answer if an address can be accessed using the offset in a MoveMw:r:R: or similar instruction.
	 We assume this is true for 32-bit processors and expect 64-bit processors to answer false
	 for values in the interpreter or the object memory.    Restrict our use of offsets to reference
	 addresses within the method zone, rather than checking for a 32-bit offset, si as to keep the
	 simulator and real VM in sync."

	^cogit addressIsInCodeZone: anAddress
]

{ #category : #accessing }
CogX64Compiler >> jmpTarget: anAbstractInstruction [
	"Set the target of a jump instruction.  These all have the target in the first operand.
	 Override to cope with JumpFPNotEqual where because of IEEE NaN conformance and
	 the behaviour of COMISD/UCOMISD we generate two jumps to the same target."
	| aDependent |
	<var: #aDependent type: #'AbstractInstruction *'>
	aDependent := dependent.
	[aDependent notNil] whileTrue:
		[aDependent jmpTarget: anAbstractInstruction.
		 aDependent := aDependent dependent].
	^super jmpTarget: anAbstractInstruction
]

{ #category : #accessing }
CogX64Compiler >> jumpLongByteSize [
"	Branch/Call ranges.  Jump[Cond] can be generated as short as possible.  Call/Jump[Cond]Long must be generated
	in the same number of bytes irrespective of displacement since their targets may be updated, but they need only
	span 16Mb, the maximum size of the code zone.  This allows e.g. ARM to use single-word call and jump instructions
	for most calls and jumps.  CallFull/JumpFull must also be generated in the same number of bytes irrespective of
	displacement for the same reason, but they must be able to span the full (32-bit or 64-bit) address space because
	they are used to call code in the C runtime, which may be distant from the code zone"
	^5
]

{ #category : #accessing }
CogX64Compiler >> jumpLongConditionalByteSize [
	^6
]

{ #category : #'inline cacheing' }
CogX64Compiler >> jumpLongTargetBeforeFollowingAddress: mcpc [ 
	"Answer the target address for the long jump immediately preceding mcpc"
	^self callTargetFromReturnAddress: mcpc
]

{ #category : #disassembly }
CogX64Compiler >> jumpTargetPCAt: pc [
	<returnTypeC: #usqInt>
	| size byte offset |
	size := self instructionSizeAt: pc.
	size = 2
		ifTrue:
			[byte := objectMemory byteAt: pc + 1.
			 offset := (byte bitAnd: 16r80) = 0 ifTrue: [byte] ifFalse: [byte - 256]]
		ifFalse:
			[byte := objectMemory byteAt: pc + size - 1.
			 offset := (byte bitAnd: 16r80) = 0 ifTrue: [byte] ifFalse: [byte - 256].
			 offset := offset << 8 + (objectMemory byteAt: pc + size - 2).
			 offset := offset << 8 + (objectMemory byteAt: pc + size - 3).
			 offset := offset << 8 + (objectMemory byteAt: pc + size - 4)].
	^pc + size + offset
]

{ #category : #abi }
CogX64Compiler >> leafCallStackPointerDelta [
	"Answer the delta from the stack pointer after a call to the stack pointer
	 immediately prior to the call.  This is used to compute the stack pointer
	 immediately prior to  call from within a leaf routine, which in turn is used
	 to capture the c stack pointer to use in trampolines back into the C run-time."
	^8
]

{ #category : #'inline cacheing' }
CogX64Compiler >> literalBeforeInlineCacheTagAt: callSiteReturnAddress [
	"Answer a literal loaded before the inline cache tag load for the return address of a send."
	^self literalBeforeFollowingAddress: callSiteReturnAddress - 12 "5 for the call plus 7 for the selectorIndex/classIndex load"
]

{ #category : #accessing }
CogX64Compiler >> loadPICLiteralByteSize [
	"Answer the byte size of a MoveCwR opcode's corresponding machine code
	 when the argument is a PIC.  This is for the self-reference at the end of a
	 closed PIC: leaq 0xffffffffffffff2b(%rip), %rcx : 48 8D 0D 2B FF FF FF"
	<inline: true>
	^7
]

{ #category : #accessing }
CogX64Compiler >> machineCodeAt: anOffset [
	^machineCode at: anOffset
]

{ #category : #'generate machine code' }
CogX64Compiler >> machineCodeBytes [
	"Answer the maximum number of bytes of machine code generated for any abstract instruction.
	 e.g. xchg %rdx, %rax; movq $0x12345678ABCDEF0, %(rax); xchg %rdx, %rax => 48 92 48 A3 F0 DE BC 9A 78 56 34 12 48 92"
	^14
]

{ #category : #encoding }
CogX64Compiler >> mod: mod RM: regMode RO: regOpcode [
	"See ModR/M byte & opcode syntax
	 In addition to the notation shown above in 'Mnemonic Syntax' on page 43,
	 the following notation indicates the size and type of operands in the syntax of an instruction opcode:
		/digit	Indicates that the ModRM byte specifies only one register or memory (r/m) operand.
				The digit is specified by the ModRM reg field and is used as an instruction-opcode extension.
				Valid digit values range from 0 to 7.
		/r		Indicates that the ModRM byte specifies both a register operand and a reg/mem (register or memory) operand."
	^mod << 6 + ((regOpcode bitAnd: 7) << 3) + (regMode bitAnd: 7)
]

{ #category : #accessing }
CogX64Compiler >> moveCwRByteSize [
	<inline: true>
	self subclassResponsibility
]

{ #category : #printing }
CogX64Compiler >> nameForFPRegister: reg [ "<Integer>"
	<doNotGenerate>
	(reg between: 0 and: 15) ifTrue:
		[^#(XMM0L XMM1L XMM2L XMM3L XMM4L XMM5L XMM6L XMM7L XMM8L XMM9L XMM10L XMM11L XMM12L XMM13L XMM14L XMM15L) at: reg + 1].
	^super nameForFPRegister: reg
]

{ #category : #printing }
CogX64Compiler >> nameForRegister: reg [ "<Integer>"
	<doNotGenerate>
	| default |
	default := super nameForRegister: reg.
	^(default last = $?
	  and: [reg between: 0 and: 15])
		ifTrue: [#(RAX RCX RDX RBX RSP RBP RSI RDI R8 R9 R10 R11 R12 R13 R14 R15) at: reg + 1]
		ifFalse: [default]
]

{ #category : #accessing }
CogX64Compiler >> numIntRegArgs [
	^SysV ifTrue: [6] ifFalse: [4]
]

{ #category : #'multi-threading' }
CogX64Compiler >> numLowLevelLockOpcodes [
	"movq   $0x1, %rax
    mfence 
    movq   0x13850(%rbx), %r9
    xchgq  %r9, %rax
    sfence 
    subq   $0x1, %rax
    retq"
	^14
]

{ #category : #'generate machine code' }
CogX64Compiler >> padIfPossibleWithStopsFrom: startAddr to: endAddr [
	self stopsFrom: startAddr to: endAddr
]

{ #category : #'calling C function in Smalltalk stack' }
CogX64Compiler >> prepareStackToCallCFunctionInSmalltalkStack: anInteger [ 

	"In SysV and Win64 Extra5Reg (R15) is callee preserved"
	cogit MoveR: SPReg R: Extra5Reg.
	cogit AndCq: 16rFFFFFFFFFFFFFFF0 R: SPReg. 
	cogit SubCq: 8 R: SPReg. 	
]

{ #category : #accessing }
CogX64Compiler >> pushCwByteSize [
	<inline: true>
	self subclassResponsibility
]

{ #category : #'inline cacheing' }
CogX64Compiler >> relocateCallBeforeReturnPC: retpc by: delta [
	| distance |
	delta ~= 0 ifTrue:
		[distance :=    ((objectMemory byteAt: retpc - 1) << 24)
					+  ((objectMemory byteAt: retpc - 2) << 16)
					+  ((objectMemory byteAt: retpc - 3) << 8)
					+   (objectMemory byteAt: retpc - 4).
		 distance := distance + delta.
		 objectMemory
			byteAt: retpc - 1 put: (distance >> 24 bitAnd: 16rFF);
			byteAt: retpc - 2 put: (distance >> 16 bitAnd: 16rFF);
			byteAt: retpc - 3 put: (distance >>   8 bitAnd: 16rFF);
			byteAt: retpc - 4 put: (distance            bitAnd: 16rFF)]
]

{ #category : #'inline cacheing' }
CogX64Compiler >> relocateMethodReferenceBeforeAddress: pc by: delta [
	"We generate the method address using pc-relative addressing.
	 Simply check that rip-relative addressing is being used. c.f.
	 concretizeMoveCwR"
	<inline: true>
	self assert: (((objectMemory byteAt: pc - 6) = 16r8D "move"
				and: [((objectMemory byteAt: pc - 5) bitOr: (self mod: 0 RM: 0 RO: 7)) = (self mod: ModRegInd RM: 5 RO: 7)])
				or: [(objectMemory byteAt: pc - 8) = 16r8D "push"
				and: [((objectMemory byteAt: pc - 7) bitOr: (self mod: 0 RM: 0 RO: 7)) = (self mod: ModRegInd RM: 5 RO: 7)]])
]

{ #category : #'calling C function in Smalltalk stack' }
CogX64Compiler >> returnFromCallCFunctionInSmalltalkStack: anInteger [ 

	cogit MoveR: Extra5Reg R: SPReg.

]

{ #category : #'inline cacheing' }
CogX64Compiler >> rewriteCPICJumpAt: addressFollowingJump target: jumpTargetAddr [
	"Rewrite the short jump instruction to jump to a new cpic case target. "
	<var: #addressFollowingJump type: #usqInt>
	<var: #jumpTargetAddr type: #usqInt>
	<var: #callDistance type: #sqInt> "prevent type inference for avoiding warning on abs"
	| callDistance |
	callDistance := jumpTargetAddr - addressFollowingJump.
	self assert: callDistance abs < 128.
	objectMemory
		byteAt: addressFollowingJump - 1
		put:  (callDistance bitAnd: 16rFF).
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: addressFollowingJump - 10 to: addressFollowingJump - 1]."
]

{ #category : #'inline cacheing' }
CogX64Compiler >> rewriteCallAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a call instruction to call a different target.  This variant is used to link PICs
	 in ceSendMiss et al, and to rewrite cached primitive calls.   Answer the extent of
	 the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	| callDistance |
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 10 to: callSiteReturnAddress - 1]."
	false
		ifTrue: [self assert: callTargetAddress >= cogit minCallAddress]
		ifFalse: [callTargetAddress >= cogit minCallAddress ifFalse:
					[self error: 'linking callsite to invalid address']].
	callDistance := (callTargetAddress - callSiteReturnAddress) signedIntToLong.
	objectMemory
		byteAt: callSiteReturnAddress - 1 put: (callDistance >> 24 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 2 put: (callDistance >> 16 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 3 put: (callDistance >>   8 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 4 put: (callDistance            bitAnd: 16rFF).
	self assert: (self callTargetFromReturnAddress: callSiteReturnAddress) = callTargetAddress.
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 10 to: callSiteReturnAddress - 1]."
	^5
]

{ #category : #'full transfer run-time support' }
CogX64Compiler >> rewriteCallFullAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a CallFull instruction to call a different target.  This variant is used to rewrite cached primitive calls.
	 Answer the extent of the code change which is used to compute the range of the icache to flush.
	 On x64 this is a rewrite of
		movq #64bits, %rax : 48 A1 b0 b1 b2 b3 b4 b5 b6 b7
		jmp %rax : FF E0 "
	self assert: (objectMemory byteAt: callSiteReturnAddress - 12) = 16r48.
	objectMemory unalignedLongAt: callSiteReturnAddress - 10 put: callTargetAddress.
	self assert: (self callFullTargetFromReturnAddress: callSiteReturnAddress) signedIntToLong64 = callTargetAddress.
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 10 to: callSiteReturnAddress - 1]."
	^12
]

{ #category : #'inline cacheing' }
CogX64Compiler >> rewriteInlineCacheAt: callSiteReturnAddress tag: cacheTag target: callTargetAddress [
	"Rewrite an inline cache to call a different target for a new tag.  This variant is used
	 to link unlinked sends in ceSend:to:numArgs: et al.  Answer the extent of the code
	 change which is used to compute the range of the icache to flush.
	 N.B.  On 64-bit platforms the inline cache tag is only 32-bits wide, hence this code
	 is identical to that for the IA32."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	| callDistance |
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 12 to: callSiteReturnAddress - 1]."
	false
		ifTrue: [self assert: callTargetAddress >= cogit minCallAddress]
		ifFalse: [callTargetAddress >= cogit minCallAddress ifFalse:
					[self error: 'linking callsite to invalid address']].
	callDistance := (callTargetAddress - callSiteReturnAddress) signedIntToLong.
	objectMemory
		byteAt: callSiteReturnAddress - 1 put: (callDistance >> 24 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 2 put: (callDistance >> 16 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 3 put: (callDistance >>   8 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 4 put: (callDistance            bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 6 put: (cacheTag >> 24 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 7 put: (cacheTag >> 16 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 8 put: (cacheTag >>   8 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 9 put: (cacheTag            bitAnd: 16rFF).
	self assert: (self callTargetFromReturnAddress: callSiteReturnAddress) = callTargetAddress.
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 12 to: callSiteReturnAddress - 1]."
	^12
]

{ #category : #'inline cacheing' }
CogX64Compiler >> rewriteInlineCacheTag: cacheTag at: callSiteReturnAddress [
	"Rewrite an inline cache with a new tag.  This variant is used
	 by the garbage collector."
	self unalignedLong32At: callSiteReturnAddress - 9 put: cacheTag
]

{ #category : #'full transfer run-time support' }
CogX64Compiler >> rewriteJumpFullAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a JumpFull instruction to jump to a different target.  This variant is used to rewrite cached primitive calls.
	 Answer the extent of the code change which is used to compute the range of the icache to flush.
	 On x64 this is a rewrite of
		movq #64bits, %rax : 48 A1 b0 b1 b2 b3 b4 b5 b6 b7
		jmp %rax : FF E0 "
	^self rewriteCallFullAt: callSiteReturnAddress target: callTargetAddress
]

{ #category : #'inline cacheing' }
CogX64Compiler >> rewriteJumpLongAt: addressFollowingJump target: jumpTargetAddr [
	"Rewrite a long jump instruction to jump to a different target.  This variant
	 is used to rewrite cached primitive calls.   Answer the extent of the
	 code change which is used to compute the range of the icache to flush."
	<inline: true>
	^self rewriteCallAt: addressFollowingJump target: jumpTargetAddr
]

{ #category : #encoding }
CogX64Compiler >> rexR: reg "<0-15>" x: sibReg "<0-15>"  b: fieldReg [ "<0-15>"
	^self rexw: true r: reg x: sibReg b: fieldReg
]

{ #category : #encoding }
CogX64Compiler >> rexw: width64 "<Boolean>" r: reg "<0-15>" x: sibReg "<0-15>"  b: fieldReg [ "<0-15>"
	"Given width64, the R register, sib register, and modrm/sib/reg field register,
	 answer the correctly encoded REX prefix byte.
	 See AMD64 Architecture Programmer's Manual Volume 3: General-Purpose and System Instructions, Table 1-11"
	| regBits |
	regBits := ((reg bitAnd: 8) >> 1) + ((sibReg bitAnd: 8) >> 2) + (fieldReg >> 3).
	^(width64 ifTrue: [16r48] ifFalse: [16r40]) + regBits
]

{ #category : #encoding }
CogX64Compiler >> s: scale i: indexReg b: baseReg [ 
	^scale << 6 + ((indexReg bitAnd: 7) << 3) + (baseReg bitAnd: 7)
]

{ #category : #abi }
CogX64Compiler >> saveAndRestoreLinkRegAround: aBlock [
	"If the processor's ABI includes a link register, generate instructions
	 to save and restore it around aBlock, which is assumed to generate code."
	<inline: true>
	^aBlock value
]

{ #category : #testing }
CogX64Compiler >> setsConditionCodesFor: aConditionalJumpOpcode [
	<inline: false> "to save Slang from having to be a real compiler (it can't inline switches that return)"
	"Answer if the receiver's opcode sets the condition codes correctly for the given conditional jump opcode."
	^opcode caseOf:
		{	[ArithmeticShiftRightCqR]	->	[self shiftSetsConditionCodesFor: aConditionalJumpOpcode].
			[ArithmeticShiftRightRR]	->	[self shiftSetsConditionCodesFor: aConditionalJumpOpcode].
			[LogicalShiftLeftCqR]		->	[self shiftSetsConditionCodesFor: aConditionalJumpOpcode].
			[LogicalShiftLeftRR]			->	[self shiftSetsConditionCodesFor: aConditionalJumpOpcode].
			[LogicalShiftRightCqR]		->	[false].
			[XorRR]						->	[true]
		}
		otherwise: [self halt: 'unhandled opcode in setsConditionCodesFor:'. false]
]

{ #category : #testing }
CogX64Compiler >> shiftSetsConditionCodesFor: aConditionalJumpOpcode [
	"OF flag only guaranteed to be set for 1-bit shifts.  See [1] p 490.
	 Only SF, ZF & PF set according to result.  Since the question is currently
	 asked only for Zero and Negative use the following simplification."
	<inline: true>
	^(aConditionalJumpOpcode between: JumpZero and: JumpNonNegative)
]

{ #category : #'inline cacheing' }
CogX64Compiler >> sixtyFourBitLiteralBefore: followingAddress [
	<inline: true>
	^objectMemory unalignedLongAt: followingAddress - 8
]

{ #category : #disassembly }
CogX64Compiler >> sizeHasModrm: op at: pc [
	| modrm mod ro rm |
	modrm := objectMemory byteAt: pc + 1.
	mod := modrm >> 6.
	ro := modrm >> 3 bitAnd: 7.
	rm := modrm bitAnd: 7.
	mod = 3 ifTrue:
		[^2].
	rm ~= 4 ifTrue: "no SIB byte"
		[^mod caseOf:
		   {	[0]	->	[rm = 5
						ifTrue: [6] "reg or 32-bit displacement"
						ifFalse: [3]].
			[1]	->	[3]. "8-bit displacement"
			[2]	->	[6] }].
	self halt: 'fall through in sizeHasModrm:at:'.
	^0
]

{ #category : #disassembly }
CogX64Compiler >> sizeImmediateGroup1: op at: pc [
	"see [1] p A-7, p A-13"
	| modrm mod ro rm |
	modrm := objectMemory byteAt: pc + 1.
	mod := modrm >> 6.
	ro := modrm >> 3 bitAnd: 7.
	rm := modrm bitAnd: 7.
	^ro caseOf:
	   {	[7 "cmp"]	->	[op = 16r81
							ifTrue: [6]
							ifFalse: [3]] }
]

{ #category : #encoding }
CogX64Compiler >> stop [
	"int3"
	<inline: true>
	^16rCC
]

{ #category : #'generate machine code' }
CogX64Compiler >> stopsFrom: startAddr to: endAddr [
	self
		cCode: [self me: startAddr ms: self stop et: endAddr - startAddr + 1]
		inSmalltalk:
			[| alignedEnd alignedStart stops |
			stops := self stop << 8 + self stop.
			stops := stops << 16 + stops.
			stops := stops << 32 + stops.
			alignedStart := startAddr + 7 // 8 * 8.
			alignedEnd := endAddr - 1 // 8 * 8.
			alignedEnd <= startAddr
				ifTrue:
					[startAddr to: endAddr do:
						[:addr | objectMemory byteAt: addr put: self stop]]
				ifFalse:
					[startAddr to: alignedStart - 1 do:
						[:addr | objectMemory byteAt: addr put: self stop].
					 alignedStart to: alignedEnd by: 8 do:
						[:addr | objectMemory long64At: addr put: stops].
					 alignedEnd + 8 to: endAddr do:
						[:addr | objectMemory byteAt: addr put: self stop]]]
]

{ #category : #'inline cacheing' }
CogX64Compiler >> storeLiteral32: literal beforeFollowingAddress: followingAddress [
	"Rewrite the 32-bit literal in the instruction immediately preceding followingAddress."
	objectMemory
		byteAt: followingAddress - 1 put: (literal >> 24 bitAnd: 16rFF);
		byteAt: followingAddress - 2 put: (literal >> 16 bitAnd: 16rFF);
		byteAt: followingAddress - 3 put: (literal >>   8 bitAnd: 16rFF);
		byteAt: followingAddress - 4 put: (literal            bitAnd: 16rFF)
]

{ #category : #disassembly }
CogX64Compiler >> twoByteInstructionSizeAt: pc [
	| op |
	op := objectMemory byteAt: pc + 1. 
	^(op bitAnd: 16rF0) caseOf:
		{	[16r80]	->	[6 "long conditional jumps"] }
]

{ #category : #'memory access' }
CogX64Compiler >> unalignedLong32At: byteAddress [
	<cmacro: '(inst,byteAddress) long32At(byteAddress)'>
	^ ((objectMemory byteAt: byteAddress + 3) << 24)
	+ ((objectMemory byteAt: byteAddress + 2) << 16)
	+ ((objectMemory byteAt: byteAddress + 1) << 8)
	+  (objectMemory byteAt: byteAddress)
]

{ #category : #'memory access' }
CogX64Compiler >> unalignedLong32At: byteAddress put: aWord [
	<cmacro: '(inst,byteAddress,aWord) long32Atput(byteAddress,aWord)'>
	objectMemory
		byteAt: byteAddress + 0 put:  (aWord bitAnd: 16rFF);
		byteAt: byteAddress + 1 put: ((aWord >> 8) bitAnd: 16rFF);
		byteAt: byteAddress + 2 put: ((aWord >> 16) bitAnd: 16rFF);
		byteAt: byteAddress + 3 put: ((aWord >> 24) bitAnd: 16rFF).
	^aWord
]

{ #category : #'memory access' }
CogX64Compiler >> unalignedLongAt: byteAddress [
	<cmacro: '(byteAddress) longAt(byteAddress)'>
	^objectMemory unalignedLongAt: byteAddress
]

{ #category : #'memory access' }
CogX64Compiler >> unalignedLongAt: byteAddress put: aWord [
	<cmacro: '(byteAddress,aWord) longAtput(byteAddress,aWord)'>
	^objectMemory unalignedLongAt: byteAddress put: aWord
]

{ #category : #testing }
CogX64Compiler >> usesTempRegForAbsoluteLoads [
	"Answer if TempReg is used in absolute memory loads (as it is on x64).  By default answer false, allowing subclasses to override."
	<inline: true>
	^true
]

{ #category : #simulation }
CogX64Compiler >> wantsNearAddressFor: anObject [
	"A hack hook to allow x64 to address CStackPointer and CFramePointer relative to VarBaseReg."
	<doNotGenerate>
	^anObject isSymbol and: ['C*Pointer' match: anObject]
]

{ #category : #'inline cacheing' }
CogX64Compiler >> zoneCallsAreRelative [
	"Answer if Call and JumpLong are relative and hence need to take the caller's
	 relocation delta into account during code compaction, rather than just the
	 callee's delta."
	^true
]
