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
		'ABI',
		'CDQ',
		'CMPXCHGAwR',
		'CMPXCHGMwrR',
		'CPUID',
		'IDIVR',
		'IMULRR',
		'LFENCE',
		'LOCK',
		'MFENCE',
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
		'RSI',
		'RSP',
		'SFENCE',
		'SIB1',
		'SIB2',
		'SIB4',
		'SIB8',
		'XCHGAwR',
		'XCHGMwrR',
		'XCHGRR',
		'XMM0H',
		'XMM0L',
		'XMM1H',
		'XMM1L',
		'XMM2H',
		'XMM2L',
		'XMM3H',
		'XMM3L',
		'XMM4H',
		'XMM4L',
		'XMM5H',
		'XMM5L',
		'XMM6H',
		'XMM6L',
		'XMM7H',
		'XMM7L'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #accessing }
CogX64Compiler class >> ABI [
	"Answer the name of the supported ABI, #SysV or #MSVC"
	^ABI
]

{ #category : #translation }
CogX64Compiler class >> ISA [
	^#X64
]

{ #category : #accessing }
CogX64Compiler class >> VarBaseReg [
	"Answer the number of the reg we use to hold the base address of CoInterpreter variables"
	^RBX
]

{ #category : #'class initialization' }
CogX64Compiler class >> initialize [
	"Initialize various x64 instruction-related constants.
	 [1] IA-32 Intel® Architecture Software Developer's Manual Volume 2A: Instruction Set Reference, A-M"

	"CogX64Compiler initialize"

	self ~~ CogX64Compiler ifTrue: [^self].

	ABI ifNil:
		[ABI := #SysV]. "Default ABI; other choice is #MSVC"

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
	XMM1L := 2.
	XMM2L := 4.
	XMM3L := 6.
	XMM4L := 8.
	XMM5L := 10.
	XMM6L := 12.
	XMM7L := 14.

	XMM0H := 1.
	XMM1H := 3.
	XMM2H := 5.
	XMM3H := 7.
	XMM4H := 9.
	XMM5H := 11.
	XMM6H := 13.
	XMM7H := 15.

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
		initializeSpecificOpcodes: #(CDQ IDIVR IMULRR CPUID LFENCE MFENCE SFENCE LOCK CMPXCHGAwR CMPXCHGMwrR XCHGAwR XCHGMwrR XCHGRR)
		in: thisContext method
]

{ #category : #translation }
CogX64Compiler class >> machineCodeDeclaration [
	"Answer the declaration for the machineCode array."
	^{#'unsigned char'. '[', self basicNew machineCodeBytes printString, ']'}
]

{ #category : #private }
CogX64Compiler >> abstractRegisterForConcreteRegister: reg [
	(self concreteRegister: TempReg) = reg ifTrue: [^TempReg].
	(self concreteRegister: ReceiverResultReg) = reg ifTrue: [^ReceiverResultReg].
	(self concreteRegister: ClassReg) = reg ifTrue: [^ClassReg].
	(self concreteRegister: SendNumArgsReg) = reg ifTrue: [^SendNumArgsReg].
	(self concreteRegister: Arg0Reg) = reg ifTrue: [^Arg0Reg].
	(self concreteRegister: Arg1Reg) = reg ifTrue: [^Arg1Reg].
	(self concreteRegister: FPReg) = reg ifTrue: [^FPReg].
	(self concreteRegister: SPReg) = reg ifTrue: [^SPReg].
	(self concreteRegister: RISCTempReg) = reg ifTrue: [^RISCTempReg].
	(self concreteRegister: VarBaseReg) = reg ifTrue: [^VarBaseReg].
	(self concreteRegister: Scratch0Reg) = reg ifTrue: [^Scratch0Reg].
	(self concreteRegister: Scratch1Reg) = reg ifTrue: [^Scratch1Reg].
	(self concreteRegister: Scratch2Reg) = reg ifTrue: [^Scratch2Reg].
	(self concreteRegister: Scratch3Reg) = reg ifTrue: [^Scratch3Reg].
	(self concreteRegister: Scratch4Reg) = reg ifTrue: [^Scratch4Reg].
	(self concreteRegister: Scratch5Reg) = reg ifTrue: [^Scratch5Reg].
	self error: 'could not find abstract register'.
	^0

	"({	TempReg. ReceiverResultReg. ClassReg. SendNumArgsReg. Arg0Reg. Arg1Reg.
		FPReg. SPReg.
		RISCTempReg. VarBaseReg.
		Scratch0Reg. Scratch1Reg. Scratch2Reg. Scratch3Reg. Scratch4Reg. Scratch5Reg. } collect: [:i| self basicNew concreteRegister: i]) sort"

	"While the below works fine in Smalltalk it of course doesn't work in C ;)"
	
	"^reg caseOf: {
		[self concreteRegister: TempReg] -> [TempReg].
		[self concreteRegister: ReceiverResultReg] -> [ReceiverResultReg].
		[self concreteRegister: ClassReg] -> [ClassReg].
		[self concreteRegister: SendNumArgsReg] -> [SendNumArgsReg].
		[self concreteRegister: Arg0Reg] -> [Arg0Reg].
		[self concreteRegister: Arg1Reg] -> [Arg1Reg].
		[self concreteRegister: FPReg] -> [FPReg].
		[self concreteRegister: SPReg] -> [SPReg] }"
]

{ #category : #accessing }
CogX64Compiler >> cResultRegister [
	"Answer the abstract register for the C result register.
	 Only partially implemented.  Works on x64 since TempReg = RAX = C result reg."
	^self abstractRegisterForConcreteRegister: RAX
]

{ #category : #accessing }
CogX64Compiler >> callInstructionByteSize [
	^5
]

{ #category : #'inline cacheing' }
CogX64Compiler >> callTargetFromReturnAddress: callSiteReturnAddress [
	"Answer the address the call immediately preceding callSiteReturnAddress will jump to."
	| callDistance |
	callDistance := self thirtyTwoBitLiteralBefore: callSiteReturnAddress.
	^callSiteReturnAddress + callDistance signedIntFromLong
]

{ #category : #accessing }
CogX64Compiler >> callerSavedRegisterMask [
	"See e.g. Figure 3.4 Register Usage in
		System V Application Binary Interface
		AMD64 Architecture Processor Supplement
	 N.B.  We are playing fast and loose here being processor-specific.
	 Soon enough this needs to be OS-specific."
	^cogit
		registerMaskFor: (self abstractRegisterForConcreteRegister: RAX)
		and: (self abstractRegisterForConcreteRegister: RCX)
		and: (self abstractRegisterForConcreteRegister: RDX)
		and: (self abstractRegisterForConcreteRegister: RSI)
		and: (self abstractRegisterForConcreteRegister: RDI)
		and: (self abstractRegisterForConcreteRegister: R8)
		and: (self abstractRegisterForConcreteRegister: R9)
		and: (self abstractRegisterForConcreteRegister: R10)
		and: (self abstractRegisterForConcreteRegister: R11)
]

{ #category : #accessing }
CogX64Compiler >> cmpC32RTempByteSize [
	^6
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
		[Fill16]					-> [^2].
		[Fill32]					-> [^4].
		[FillFromWord]			-> [^4].
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
		"[XCHGAwR]				-> [^6].
		[XCHGMwrR]			-> [^7]."
		[XCHGRR]				-> [^((self concreteRegister: (operands at: 0)) = RAX
									   or: [(self concreteRegister: (operands at: 1)) = RAX])
											ifTrue: [2]
											ifFalse: [3]].
		"Control"
		[CallFull]					-> [^12].
		[Call]						-> [^5].
		[JumpR]						-> [^2].
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
		[AndCqR]		-> [^self computeSizeOfArithCqR].
		[CmpCqR]		-> [^self computeSizeOfArithCqR].
		[OrCqR]			-> [^self computeSizeOfArithCqR].
		[SubCqR]		-> [^self computeSizeOfArithCqR].
		[TstCqR]		-> [^self computeSizeOfArithCqR].
		[AddCwR]		-> [^self computeSizeOfArithCwR].
		[AndCwR]		-> [^self computeSizeOfArithCwR].
		[CmpCwR]		-> [^self computeSizeOfArithCwR].
		[CmpC32R]		-> [^self computeSizeOfArithCwR].
		[OrCwR]		-> [^self computeSizeOfArithCwR].
		[SubCwR]		-> [^self computeSizeOfArithCwR].
		[XorCwR]		-> [^self computeSizeOfArithCwR].
		[AddRR]			-> [^3].
		[AndRR]			-> [^3].
		[CmpRR]		-> [^3].
		[OrRR]			-> [^3].
		[XorRR]			-> [^3].
		[SubRR]			-> [^3].
		[NegateR]		-> [^3].
		[LoadEffectiveAddressMwrR]
						-> [^((self isQuick: (operands at: 0))
									ifTrue: [4]
									ifFalse: [7])
								+ (((self concreteRegister: (operands at: 1)) bitAnd: 7) = RSP
									ifTrue: [1]
									ifFalse: [0])].
		[LogicalShiftLeftCqR]		-> [^self computeShiftCqRegSize].
		[LogicalShiftRightCqR]		-> [^self computeShiftCqRegSize].
		[ArithmeticShiftRightCqR]	-> [^self computeShiftCqRegSize].
		[LogicalShiftLeftRR]			-> [^self computeShiftRRSize].
		[LogicalShiftRightRR]		-> [^self computeShiftRRSize].
		[ArithmeticShiftRightRR]		-> [^self computeShiftRRSize].
		[AddRdRd]					-> [^4].
		[CmpRdRd]					-> [^4].
		[SubRdRd]					-> [^4].
		[MulRdRd]					-> [^4].
		[DivRdRd]					-> [^4].
		[SqrtRd]					-> [^4].
		"Data Movement"
		[MoveCqR]		-> [^(operands at: 0) = 0
								ifTrue: [3]
								ifFalse:
									[(self is32BitSignedImmediate: (operands at: 0))
										ifTrue: [7]
										ifFalse: [self moveCwRByteSize]]].
		[MoveCwR]		-> [^(self inCurrentCompilation: (operands at: 0))
								ifTrue: [7]
								ifFalse: [self moveCwRByteSize]].
		[MoveC32R]	-> [^7]. "N.B. Always inlined."
		[MoveRR]		-> [^3].
		[MoveRdRd]		-> [^4].
		[MoveAwR]		-> [^(self isAddressRelativeToVarBase: (operands at: 0))
								ifTrue: [7]
								ifFalse: [(self concreteRegister: (operands at: 1)) = RAX ifTrue: [10] ifFalse: [14]]].
		[MoveRAw]		-> [^(self isAddressRelativeToVarBase: (operands at: 1))
								ifTrue: [7]
								ifFalse: [(self concreteRegister: (operands at: 0)) = RAX ifTrue: [10] ifFalse: [14]]].
		[MoveAbR]		-> [^(self isAddressRelativeToVarBase: (operands at: 0))
								ifTrue: [7]
								ifFalse: [(self concreteRegister: (operands at: 1)) = RAX ifTrue: [10] ifFalse: [14]]].
		[MoveRAb]		-> [^(self isAddressRelativeToVarBase: (operands at: 1))
								ifTrue: [7]
								ifFalse: [(self concreteRegister: (operands at: 0)) = RAX ifTrue: [10] ifFalse: [14]]].
		[MoveRMwr]	-> [self assert: (self is32BitSignedImmediate: (operands at: 1)).
							^((self isQuick: (operands at: 1))
									ifTrue: [((operands at: 1) = 0
											and: [((self concreteRegister: (operands at: 2)) bitAnd: 7) ~= RBP])
												ifTrue: [3]
												ifFalse: [4]]
									ifFalse: [7])
								+ (((self concreteRegister: (operands at: 2)) bitAnd: 7) = RSP
									ifTrue: [1]
									ifFalse: [0])].
		"[MoveRdM64r]	-> [^((self isQuick: (operands at: 1))
											ifTrue: [5]
											ifFalse: [8])
										+ ((self concreteRegister: (operands at: 2)) = ESP
											ifTrue: [1]
											ifFalse: [0])]."
		[MoveMbrR]		-> [self assert: (self is32BitSignedImmediate: (operands at: 0)).
							^((self isQuick: (operands at: 0))
									ifTrue: [((operands at: 0) = 0
											and: [((self concreteRegister: (operands at: 1)) bitAnd: 7) ~= RBP])
												ifTrue: [3]
												ifFalse: [4]]
									ifFalse: [7])
								+ (((self concreteRegister: (operands at: 1)) bitAnd: 7) = RSP
									ifTrue: [1]
									ifFalse: [0])].
		[MoveRMbr]		-> [self assert: (self is32BitSignedImmediate: (operands at: 1)).
							^((self isQuick: (operands at: 1))
									ifTrue: [((operands at: 1) = 0
											and: [((self concreteRegister: (operands at: 0)) bitAnd: 7) ~= RBP])
												ifTrue: [3]
												ifFalse: [4]]
									ifFalse: [7])
								+ (((self concreteRegister: (operands at: 2)) bitAnd: 7) = RSP
									ifTrue: [1]
									ifFalse: [0])].
		[MoveM16rR]	-> [^((self isQuick: (operands at: 0))
									ifTrue: [((operands at: 0) = 0
											and: [((self concreteRegister: (operands at: 1)) bitAnd: 7) ~= RBP])
												ifTrue: [4]
												ifFalse: [5]]
									ifFalse: [8])
								+ (((self concreteRegister: (operands at: 1)) bitAnd: 7) = RSP
									ifTrue: [1]
									ifFalse: [0])].
		"[MoveM64rRd]	-> [^((self isQuick: (operands at: 0))
											ifTrue: [5]
											ifFalse: [8])
										+ ((self concreteRegister: (operands at: 1)) = ESP
											ifTrue: [1]
											ifFalse: [0])]."
		[MoveMwrR]		-> [self assert: (self is32BitSignedImmediate: (operands at: 0)).
								^((self isQuick: (operands at: 0))
									ifTrue: [((operands at: 0) = 0
											and: [((self concreteRegister: (operands at: 1)) bitAnd: 7) ~= RBP])
												ifTrue: [3]
												ifFalse: [4]]
									ifFalse: [7])
								+ (((self concreteRegister: (operands at: 1)) bitAnd: 7) = RSP
									ifTrue: [1]
									ifFalse: [0])].
		[MoveXbrRR]	-> [self assert: (self concreteRegister: (operands at: 0)) ~= RSP.
							^((self concreteRegister: (operands at: 1)) bitAnd: 7) = RBP
											ifTrue: [5]
											ifFalse: [4]].
		[MoveRXbrR]	->	[self assert: (self concreteRegister: (operands at: 1)) ~= RSP.
							^(((self concreteRegister: (operands at: 0)) < 8
							   and: [(self concreteRegister: (operands at: 1)) < 8
							   and: [(self concreteRegister: (operands at: 2)) < 8]])
								ifTrue: [3]
								ifFalse: [4])
							+ (((self concreteRegister: (operands at: 2)) bitAnd: 7) = RBP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveXwrRR]	-> [self assert: (self concreteRegister: (operands at: 0)) ~= RSP.
							^((self concreteRegister: (operands at: 1)) = RBP
							   or: [(self concreteRegister: (operands at: 1)) = R13])
											ifTrue: [5]
											ifFalse: [4]].
		[MoveRXwrR]	-> [self assert: (self concreteRegister: (operands at: 1)) ~= RSP.
							^((self concreteRegister: (operands at: 2)) = RBP
							   or: [(self concreteRegister: (operands at: 2)) = R13])
											ifTrue: [5]
											ifFalse: [4]].
		[MoveX32rRR]	-> [self assert: (self concreteRegister: (operands at: 0)) ~= RSP.
							^(((self concreteRegister: (operands at: 1)) = RBP
							   or: [(self concreteRegister: (operands at: 1)) = R13])
										ifTrue: [7]
										ifFalse: [6])
							 + (((self concreteRegister: (operands at: 0)) > 7
							     or: [(self concreteRegister: (operands at: 1)) > 7
							     or: [(self concreteRegister: (operands at: 2)) > 7]])
										ifTrue: [1]
										ifFalse: [0])].
		[PopR]			-> [^(self concreteRegister: (operands at: 0)) < 8 ifTrue: [1] ifFalse: [2]].
		[PushR]			-> [^(self concreteRegister: (operands at: 0)) < 8 ifTrue: [1] ifFalse: [2]].
		[PushCq]		-> [^(self isQuick: (operands at: 0)) ifTrue: [2] ifFalse: [5]].
		[PushCw]		-> [^(self inCurrentCompilation: (operands at: 0))
								ifTrue: [9]
								ifFalse: [self pushCwByteSize]].
		[PrefetchAw]	-> [^(self isAddressRelativeToVarBase: (operands at: 0)) ifTrue: [7] ifFalse: [0]].
		"Conversion"
		"[ConvertRRd]	-> [^4]" }.
	^0 "to keep C compiler quiet"
]

{ #category : #'generate machine code' }
CogX64Compiler >> computeShiftCqRegSize [
	"Immediate shifts are limited to a maximum of 31."
	<inline: true>
	| distance |
	distance := operands at: 0.
	distance = 1 ifTrue:
		[^3].
	distance <= 31 ifTrue:
		[^4].
	distance = 32 ifTrue:
		[^7].
	^8
]

{ #category : #'generate machine code' }
CogX64Compiler >> computeShiftRRSize [
	"On the x86 the only instructions that shift by the value of a
	 register require the shift count to be  in %ecx.  So we may
	 have to use swap instructions to get the count into ecx."
	| shiftCountReg |
	shiftCountReg := self concreteRegister: (operands at: 0).
	shiftCountReg = RCX ifTrue:
		[^maxSize := 3].
	^maxSize := shiftCountReg = RAX
					ifTrue: [2 "XCHG RAX,r2" + 3 "Sxx" + 2 "XCHG RAX,r2"]
					ifFalse: [3 "XCHG r1,r2" + 3 "Sxx" + 3 "XCHG r1,r2"]
]

{ #category : #'generate machine code' }
CogX64Compiler >> computeSizeOfArithCqR [
	"With CqR we assume constants are 32-bits or less."
	<inline: true>
	^(self isQuick: (operands at: 0))
		ifTrue: [4]
		ifFalse: [(self concreteRegister: (operands at: 1)) = RAX
					ifTrue: [6]
					ifFalse: [7]]
]

{ #category : #'generate machine code' }
CogX64Compiler >> computeSizeOfArithCwR [
	"The implementation depends on in-line or out-of-line literals."
	^self subclassResponsibility
]

{ #category : #encoding }
CogX64Compiler >> concreteDPFPRegister: registerIndex [
	 "Map a possibly abstract double-precision floating-point register into a concrete one.
	  Abstract registers (defined in CogAbstractOpcodes) are all negative.  If registerIndex
	  is negative assume it is an abstract register.

	[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2A: Instruction Set Reference, A-M"

	^registerIndex
		caseOf: {
			[DPFPReg0]	-> [XMM0L / 2].
			[DPFPReg1]	-> [XMM1L / 2].
			[DPFPReg2]	-> [XMM2L / 2].
			[DPFPReg3]	-> [XMM3L / 2].
			[DPFPReg4]	-> [XMM4L / 2].
			[DPFPReg5]	-> [XMM5L / 2].
			[DPFPReg6]	-> [XMM6L / 2].
			[DPFPReg7]	-> [XMM7L / 2] }
		otherwise:
			[self assert: (registerIndex between: XMM0L and: XMM7L).
			 self assert: (registerIndex bitAnd: 1) = 0.
			 registerIndex / 2]
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeAddRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regLHS := self concreteRegister: (operands at: 0).
	regRHS := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: (self rexR: regRHS x: 0 b: regLHS);
		at: 1 put: 16r03;
		at: 2 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^machineCodeSize := 3
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
	reg := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: (self rexR: 0 x: 0 b: reg).
	(self isQuick: value) ifTrue:
		[machineCode
			at: 1 put: 16r83;
			at: 2 put: (self mod: ModReg RM: reg RO: regOpcode);
			at: 3 put: (value bitAnd: 16rFF).
		 ^machineCodeSize := 4].
	self assert: value >> 32 = 0.
	reg = RAX ifTrue:
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
	 ^machineCodeSize := 7
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
	 movabsq 0x123456789abcdef0, %rax; callq *%rax."
	<inline: true>
	| operand |
	operand := operands at: 0.
	machineCode
		at: 0 put: 16r48;
		at: 1 put: 16rA1;
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
CogX64Compiler >> concretizeCmpC32R [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	reg = RAX ifTrue:
		[machineCode
			at: 0 put: 16r48;
			at: 1 put: 16r3D;
			at: 2 put: (value bitAnd: 16rFF);
			at: 3 put: (value >> 8 bitAnd: 16rFF);
			at: 4 put: (value >> 16 bitAnd: 16rFF);
			at: 5 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 6].
	machineCode
		at: 0 put: 16r49;
		at: 1 put: 16r81;
		at: 2 put: (self mod: ModReg RM: reg RO: 7);
		at: 3 put: (value bitAnd: 16rFF);
		at: 4 put: (value >> 8 bitAnd: 16rFF);
		at: 5 put: (value >> 16 bitAnd: 16rFF);
		at: 6 put: (value >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 7
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeCmpRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	"CmpRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	regRHS := self concreteRegister: (operands at: 0).
	regLHS := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: (self rexR: regRHS x: 0 b: regLHS);
		at: 1 put: 16r39;
		at: 2 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeCmpRdRd [
	"Will get inlined into concretizeAt: switch.
	 We use UCOMISD (see p 4-260 [2])"
	<inline: true>
	| regLHS regRHS |
	"CmpRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	regRHS := self concreteDPFPRegister: (operands at: 0).
	regLHS := self concreteDPFPRegister: (operands at: 1).
	machineCode
		at: 0 put: 16r66;
		at: 1 put: 16r0F;
		at: 2 put: 16r2E;
		at: 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^machineCodeSize := 4
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
CogX64Compiler >> concretizeFill32 [
	<inline: true>
	| word |
	<var: #word type: #'unsigned long'>
	word := operands at: 0.
	machineCode at: 0 put: (word bitAnd: 16rFF).
	machineCode at: 1 put: word >> 8.
	machineCode at: 2 put: word >> 16.
	machineCode at: 3 put: word >> 24.
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeIDIVR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regDivisor |
	regDivisor := self concreteRegister: (operands at: 0).
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
		at: 1 put: 16rA1;
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
	reg := self concreteRegister: (operands at: 0).
	machineCode
		at: 0 put: 16rFF;
		at: 1 put: (self mod: ModReg RM: reg RO: 4).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeLoadEffectiveAddressMwrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
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
	reg := self concreteRegister: (operands at: 1).
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
	reg := self concreteRegister: (operands at: 1).
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
	reg := self concreteRegister: (operands at: 1).
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
	 On x64 we can short-cut mov 0, reg using xor, and use 32-bit displacement, signed or unsigned, if possible."
	<inline: true>
	| value reg |
	value := operands at: 0.
	(self is32BitSignedImmediate: value) ifFalse:
		[^self concretizeMoveCwR].
	reg := self concreteRegister: (operands at: 1).
	value = 0 ifTrue:
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
	^machineCodeSize := 7
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
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
	machineCode
		at: 0 put: (self rexR: destReg x: 0 b: srcReg);
		at: 1 put: 16r0f;
		at: 2 put: 16rb7.
	(srcReg ~= RSP and: [srcReg ~= R12]) ifTrue:
		[(offset = 0 and: [destReg ~= RBP and: [destReg ~= R13]]) ifTrue:
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
	(offset = 0 and: [destReg ~= RBP and: [destReg ~= R13]]) ifTrue:
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
CogX64Compiler >> concretizeMoveMbrR [
	"N.B. The Cogit makes no assumption about the upper bits being set to zero because we
	 deny byteReadsZeroExtend.  The cogit will clear the register before hand if necessary."
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
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
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
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
CogX64Compiler >> concretizeMoveRAb [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg offset save1 |
	reg := self concreteRegister: (operands at: 0).
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
	reg := self concreteRegister: (operands at: 0).
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
CogX64Compiler >> concretizeMoveRMbr [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := self concreteRegister: (operands at: 0).
	offset := operands at: 1.
	destReg := self concreteRegister: (operands at: 2).
	machineCode
		at: 0 put: (self rexR: srcReg x: 0 b: destReg);
		at: 1 put: 16r88.
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
CogX64Compiler >> concretizeMoveRMwr [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := self concreteRegister: (operands at: 0).
	offset := operands at: 1.
	destReg := self concreteRegister: (operands at: 2).
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
CogX64Compiler >> concretizeMoveRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg destReg |
	srcReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: (self rexR: srcReg x: 0 b: destReg);
		at: 1 put: 16r89;
		at: 2 put: (self mod: ModReg RM: destReg RO: srcReg).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRXbrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base dest offset |
	index := self concreteRegister: (operands at: 0).
	base := self concreteRegister: (operands at: 1).
	dest := self concreteRegister: (operands at: 2).
	offset := 0.
	(dest >= 8 or: [base >= 8 or: [index >= 8]]) ifTrue:
		[machineCode at: 0 put: (self rexR: dest x: index b: base).
		 offset := 1].
	machineCode
		at: 0 + offset put: 16r88.
	(base ~= RBP and: [base ~= R13]) ifTrue:
		[machineCode
			at: 1 + offset put: (self mod: ModRegInd RM: 4 RO: dest);
			at: 2 + offset put: (self s: SIB1 i: index b: base).
		 ^machineCodeSize := 3 + offset].
	machineCode
		at: 1 + offset put: (self mod: ModRegRegDisp8 RM: 4 RO: dest);
		at: 2 + offset put: (self s: SIB1 i: index b: base);
		at: 3 + offset put: 0.
	 ^machineCodeSize := 4 + offset
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveRXwrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base src |
	src := self concreteRegister: (operands at: 0).
	index := self concreteRegister: (operands at: 1).
	base := self concreteRegister: (operands at: 2).
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
CogX64Compiler >> concretizeMoveX32rRR [
	"MoveX32rRR is expected to zero-extend, so explicitly zero the destination."
	| index base dest offset |
	index := self concreteRegister: (operands at: 0).
	base := self concreteRegister: (operands at: 1).
	dest := self concreteRegister: (operands at: 2).
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
	index := self concreteRegister: (operands at: 0).
	base := self concreteRegister: (operands at: 1).
	dest := self concreteRegister: (operands at: 2).
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
	index := self concreteRegister: (operands at: 0).
	base := self concreteRegister: (operands at: 1).
	dest := self concreteRegister: (operands at: 2).
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
CogX64Compiler >> concretizeNegateR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := self concreteRegister: (operands at: 0).
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
CogX64Compiler >> concretizePopR [
	<inline: true>
	| reg |
	reg := self concreteRegister: (operands at: 0).
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
CogX64Compiler >> concretizePushR [
	<inline: true>
	| reg |
	reg := self concreteRegister: (operands at: 0).
	reg < 8 ifTrue:
		[machineCode at: 0 put: 16r50 + reg.
		^machineCodeSize := 1].
	machineCode
		at: 0 put: 16r41;
		at: 1 put: 16r50 + (reg - 8).
	^machineCodeSize := 2
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
CogX64Compiler >> concretizeSEE2OpRdRd: opCode [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regRHS := self concreteDPFPRegister: (operands at: 0).
	regLHS := self concreteDPFPRegister: (operands at: 1).
	machineCode
		at: 0 put: 16rF2;
		at: 1 put: 16r0F;
		at: 2 put: opCode;
		at: 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeShiftCqRegOpcode: regOpcode [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| distance reg |
	distance := operands at: 0.
	self assert: (distance between: 1 and: 63).
	reg := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: (self rexR: 0 x: 0 b: reg).
	distance = 1 ifTrue:
		[machineCode
			at: 1 put: 16rD1;
			at: 2 put: (self mod: ModReg RM: reg RO: regOpcode).
		 ^machineCodeSize := 3].
	machineCode
		at: 1 put: 16rC1;
		at: 2 put: (self mod: ModReg RM: reg RO: regOpcode);
		at: 3 put: (distance min: 31).
	distance <= 31 ifTrue:
		[^machineCodeSize := 4].
	distance = 32 ifTrue:
		[machineCode
			at: 4 put: 16rD1;
			at: 5 put: (self mod: ModReg RM: reg RO: regOpcode).
		 ^machineCodeSize := 7].
	machineCode
		at: 4 put: 16rC1;
		at: 5 put: (self mod: ModReg RM: reg RO: regOpcode);
		at: 6 put: distance - 31.
	^machineCodeSize := 8
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeShiftRegRegOpcode: regOpcode [
	"On the x64 the only instructions that shift by the value of a
	 register require the shift count to be  in %ecx.  So we may
	 have to use swap instructions to get the count into %ecx."
	<inline: true>
	| shiftCountReg destReg regToShift |
	shiftCountReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
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
CogX64Compiler >> concretizeSqrtRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := self concreteDPFPRegister: (operands at: 0).
	machineCode
		at: 0 put: 16rF2;
		at: 1 put: 16r0F;
		at: 2 put: 16r51;
		at: 3 put: (self mod: ModReg RM: reg RO: reg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeSubRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regLHS := self concreteRegister: (operands at: 0).
	regRHS := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: (self rexR: regRHS x: 0 b: regLHS);
		at: 1 put: 16r2b;
		at: 2 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeTstCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: (self rexR: 0 x: 0 b: reg).
	(self isQuick: value) ifTrue:
		[machineCode
			at: 1 put: 16rF6;
			at: 2 put: (self mod: ModReg RM: reg RO: 0);
			at: 3 put: (value bitAnd: 16rFF).
		 ^machineCodeSize := 4].
	self assert: value >> 32 = 0.
	reg = RAX ifTrue:
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
	 ^machineCodeSize := 7
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeXCHGRR [
	| r1 r2 |
	r1 := self concreteRegister: (operands at: 0).
	r2 := self concreteRegister: (operands at: 1).
	r2 = RAX ifTrue:
		[r2 := r1. r1 := RAX].
	r1 = RAX ifTrue:
		[machineCode
			at: 0 put: (self rexR: 0 x: 0 b: r2);
			at: 1 put: 16r90 + (r2 \\ 8).
		 ^machineCodeSize := 2].
	machineCode
		at: 0 put: (self rexR: r1 x: 0 b: r2);
		at: 1 put: 87;
		at: 2 put: (self mod: r2 RM: 0 RO: r1).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogX64Compiler >> dispatchConcretize [
	"Attempt to generate concrete machine code for the instruction at address.
	 This is the inner dispatch of concretizeAt: actualAddress which exists only
	 to get around the branch size limits in the SqueakV3 (blue book derived)
	 bytecode set."
	<returnTypeC: #void>
	opcode caseOf: {
		"Noops & Pseudo Ops"
		[Label]				-> [^self concretizeLabel].
		[AlignmentNops]	-> [^self concretizeAlignmentNops].
		[Fill16]				-> [^self concretizeFill16].
		[Fill32]				-> [^self concretizeFill32].
		[FillFromWord]		-> [^self concretizeFillFromWord].
		[Nop]				-> [^self concretizeNop].
		"Specific Control/Data Movement"
		[CDQ]					-> [^self concretizeCDQ].
		[IDIVR]					-> [^self concretizeIDIVR].
		[IMULRR]				-> [^self concretizeMulRR].
		[CPUID]					-> [^self concretizeCPUID].
		[CMPXCHGAwR]			-> [^self concretizeCMPXCHGAwR].
		[CMPXCHGMwrR]		-> [^self concretizeCMPXCHGMwrR].
		[LFENCE]				-> [^self concretizeFENCE: 5].
		[MFENCE]				-> [^self concretizeFENCE: 6].
		[SFENCE]				-> [^self concretizeFENCE: 7].
		[LOCK]					-> [^self concretizeLOCK].
		[XCHGAwR]				-> [^self concretizeXCHGAwR].
		[XCHGMwrR]			-> [^self concretizeXCHGMwrR].
		[XCHGRR]				-> [^self concretizeXCHGRR].
		"Control"
		[Call]					-> [^self concretizeCall].
		[CallFull]				-> [^self concretizeCallFull].
		[JumpR]					-> [^self concretizeJumpR].
		[JumpFull]				-> [^self concretizeJumpFull].
		[JumpLong]				-> [^self concretizeJumpLong].
		[JumpLongZero]		-> [^self concretizeConditionalJump: 16r4].
		[JumpLongNonZero]	-> [^self concretizeConditionalJump: 16r5].
		[Jump]					-> [^self concretizeJump].
		"Table B-1 Intel¬Æ 64 and IA-32 Architectures Software Developer's Manual Volume 1: Basic Architecture"
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
		[AddCwR]					-> [^self concretizeArithCwR: 16r03].
		[AddRR]						-> [^self concretizeAddRR].
		[AddRdRd]					-> [^self concretizeSEE2OpRdRd: 16r58].
		[AndCqR]					-> [^self concretizeArithCqRWithRO: 4 raxOpcode: 16r25].
		[AndCwR]					-> [^self concretizeArithCwR: 16r23].
		[AndRR]						-> [^self concretizeAndRR].
		[TstCqR]					-> [^self concretizeTstCqR].
		[CmpCqR]					-> [^self concretizeArithCqRWithRO: 7 raxOpcode: 16r3D].
		[CmpCwR]					-> [^self concretizeArithCwR: 16r39].
		[CmpC32R]					-> [^self concretizeCmpC32R].
		[CmpRR]					-> [^self concretizeCmpRR].
		[CmpRdRd]					-> [^self concretizeCmpRdRd].
		[DivRdRd]					-> [^self concretizeSEE2OpRdRd: 16r5E].
		[MulRdRd]					-> [^self concretizeSEE2OpRdRd: 16r59].
		[OrCqR]						-> [^self concretizeArithCqRWithRO: 1 raxOpcode: 16r0D].
		[OrCwR]					-> [^self concretizeArithCwR: 16r0B].
		[OrRR]						-> [^self concretizeOrRR].
		[SubCqR]					-> [^self concretizeArithCqRWithRO: 5 raxOpcode: 16r2D].
		[SubCwR]					-> [^self concretizeArithCwR: 16r2B].
		[SubRR]						-> [^self concretizeSubRR].
		[SubRdRd]					-> [^self concretizeSEE2OpRdRd: 16r5C].
		[SqrtRd]					-> [^self concretizeSqrtRd].
		[XorCwR]					-> [^self concretizeArithCwR: 16r33].
		[XorRR]						-> [^self concretizeXorRR].
		[NegateR]					-> [^self concretizeNegateR].
		[LoadEffectiveAddressMwrR]	-> [^self concretizeLoadEffectiveAddressMwrR].
		[ArithmeticShiftRightCqR]		-> [^self concretizeShiftCqRegOpcode: 7].
		[LogicalShiftRightCqR]			-> [^self concretizeShiftCqRegOpcode: 5].
		[LogicalShiftLeftCqR]			-> [^self concretizeShiftCqRegOpcode: 4].
		[ArithmeticShiftRightRR]			-> [^self concretizeShiftRegRegOpcode: 7].
		[LogicalShiftLeftRR]				-> [^self concretizeShiftRegRegOpcode: 4].
		"Data Movement"
		[MoveCqR]			-> [^self concretizeMoveCqR].
		[MoveCwR]			-> [^self concretizeMoveCwR].
		[MoveC32R]		-> [^self concretizeMoveC32R].
		[MoveRR]			-> [^self concretizeMoveRR].
		[MoveAwR]			-> [^self concretizeMoveAwR].
		[MoveRAw]			-> [^self concretizeMoveRAw].
		[MoveAbR]			-> [^self concretizeMoveAbR].
		[MoveRAb]			-> [^self concretizeMoveRAb].
		[MoveMbrR]			-> [^self concretizeMoveMbrR].
		[MoveRMbr]			-> [^self concretizeMoveRMbr].
		[MoveM16rR]		-> [^self concretizeMoveM16rR].
		[MoveM64rRd]		-> [^self concretizeMoveM64rRd].
		[MoveMwrR]		-> [^self concretizeMoveMwrR].
		[MoveXbrRR]		-> [^self concretizeMoveXbrRR].
		[MoveRXbrR]		-> [^self concretizeMoveRXbrR].
		[MoveXwrRR]		-> [^self concretizeMoveXwrRR].
		[MoveRXwrR]		-> [^self concretizeMoveRXwrR].
		[MoveX32rRR]		-> [^self concretizeMoveX32rRR].
		[MoveRMwr]		-> [^self concretizeMoveRMwr].
		[MoveRdM64r]		-> [^self concretizeMoveRdM64r].
		[PopR]				-> [^self concretizePopR].
		[PushR]				-> [^self concretizePushR].
		[PushCq]			-> [^self concretizePushCq].
		[PushCw]			-> [^self concretizePushCw].
		[PrefetchAw]		-> [^self concretizePrefetchAw].
		"Conversion"
		[ConvertRRd]		-> [^self concretizeConvertRRd] }
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
	rDividend := self concreteRegister: abstractRegDividend.
	rDivisor := self concreteRegister: abstractRegDivisor.
	rQuotient := self concreteRegister: abstractRegQuotient.
	rRemainder := self concreteRegister: abstractRegRemainder.
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

{ #category : #assertions }
CogX64Compiler >> genGetLeafCallStackPointerFunction [
	cogit
		MoveR: RSP R: RAX;
		RetN: 0
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
	"Generate the code to pass up to four arguments in a C run-time call.  Hack: each argument is either a
	 negative number, that of an abstract register, or a non-negative number, that of a constant parameter.

	 Run-time calls have no more than four arguments, so chosen so that on ARM, where in its C ABI the
	 first four integer arguments are passed in registers, all arguments can be passed in registers.  We
	 defer to the back end to generate this code not so much that the back end knows whether it uses
	 the stack or registers to pass arguments (it does, but...). In fact we defer for an extremely evil reason.
	 Doing so allows the x64 (where up to 6 args are passed) to assign the register arguments in an order
	 that allows some of the argument registers to be used for specific abstract  registers, specifically
	 ReceiverResultReg and ClassReg.  This is evil, evil, evil, but also its really nice to keep using the old
	 register assignments the principal author has grown accustomed to.

	 How can this possibly work?  Look at Cogit class>>runtime for a list of the run-time calls and their
	 arguments, including which arguments are passed in which registers.  Look at CogX64Compiler's
	 subclass implementations of concreteRegister:.  There are no calls in which ReceiverResultReg (RDX)
	 and/or ClassReg (RCX) are passed along with Arg0Reg and Arg1Reg, and none in which the use of
	 either ReceiverResultReg or ClassReg conflict for args 3 & 4.  So if args are assigned in order, the
	 registers do not get overwritten.  Yes, this is evil, but it's so nice to continue to use RCX & RDX."
	<inline: true>
	numArgs = 0 ifTrue: [^self].
	regOrConst0 >= 0
		ifTrue: [cogit MoveCq: regOrConst0 R: RDI]
		ifFalse:
			[(self concreteRegister: regOrConst0) ~= RDI ifTrue:
				[cogit MoveR: regOrConst0 R: RDI]].
	numArgs = 1 ifTrue: [^self].
	regOrConst1 >= 0
		ifTrue: [cogit MoveCq: regOrConst1 R: RSI]
		ifFalse:
			[(self concreteRegister: regOrConst1) ~= RSI ifTrue:
				[cogit MoveR: regOrConst1 R: RSI]].
	numArgs = 2 ifTrue: [^self].
	self cppIf: ABI == #SysV ifTrue:
		[regOrConst2 >= 0
			ifTrue: [cogit MoveCq: regOrConst2 R: RDX]
			ifFalse:
				[(self concreteRegister: regOrConst2) ~= RDX ifTrue:
					[cogit MoveR: regOrConst2 R: RDX]].
		 numArgs = 3 ifTrue: [^self].
		 regOrConst3 >= 0
				ifTrue: [cogit MoveCq: regOrConst3 R: RCX]
				ifFalse:
					[(self concreteRegister: regOrConst3) ~= RCX ifTrue:
						[cogit MoveR: regOrConst3 R: RCX]]].
	self cppIf: ABI == #MSVC ifTrue:
		[regOrConst2 >= 0
			ifTrue: [cogit MoveCq: regOrConst2 R: R8]
			ifFalse:
				[(self concreteRegister: regOrConst2) ~= R8 ifTrue:
					[cogit MoveR: regOrConst2 R: R8]].
		 numArgs = 3 ifTrue: [^self].
		 regOrConst3 >= 0
				ifTrue: [cogit MoveCq: regOrConst3 R: R9]
				ifFalse:
					[(self concreteRegister: regOrConst3) ~= R9 ifTrue:
						[cogit MoveR: regOrConst3 R: R9]]].
	self assert: numArgs <= 4
]

{ #category : #'abstract instructions' }
CogX64Compiler >> genMulR: regSource R: regDest [
	cogit gen: IMULRR operand: regSource operand: regDest
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

{ #category : #abi }
CogX64Compiler >> genRemoveNArgsFromStack: n [
	"This is a no-op on x64 since the ABI passes up to 6 args in registers and trampolines currently observe a limit of 4."
	self assert: n <= 6.
	^0
]

{ #category : #abi }
CogX64Compiler >> genRestoreRegs [
	"Restore the general purpose registers for a trampoline call.
	 c.f. genSaveRegisters"
	cogit
		PopR: RAX;
		PopR: RBX;
		PopR: RCX;
		PopR: RDX;
		PopR: RSI;
		PopR: RDI;
		PopR: R8;
		PopR: R9;
		PopR: R10;
		PopR: R11;
		PopR: R12;
		PopR: R13;
		PopR: R14;
		PopR: R15.
	^0
]

{ #category : #abi }
CogX64Compiler >> genSaveRegisters [
	"Save the general purpose registers for a trampoline call."
	cogit
		PushR: R15;
		PushR: R14;
		PushR: R13;
		PushR: R12;
		PushR: R11;
		PushR: R10;
		PushR: R9;
		PushR: R8;
		PushR: RDI;
		PushR: RSI;
		PushR: RDX;
		PushR: RCX;
		PushR: RBX;
		PushR: RAX.
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

{ #category : #testing }
CogX64Compiler >> hasConditionRegister [
	"Answer if the receiver supports, e.g., JumpOverflow after a regular AddRR"
	<inline: true>
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
	<inline: true>
	^false
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
			[16rEB] ->	[2] "short unconditional jump" }
]

{ #category : #testing }
CogX64Compiler >> is32BitSignedImmediate: a64BitUnsignedOperand [
	^self cCode: [(self cCoerceSimple: a64BitUnsignedOperand to: #int) = (self cCoerceSimple: a64BitUnsignedOperand to: #long)]
		inSmalltalk: [((a64BitUnsignedOperand >> 32) signedIntFromLong between: -1 and: 0)
					and: [(a64BitUnsignedOperand >> 31) signedIntFromLong between: -1 and: 0]]
]

{ #category : #testing }
CogX64Compiler >> isAddressRelativeToVarBase: varAddress [
	<inline: true>
	<var: #varAddress type: #usqInt>
	"Support for addressing variables off the dedicated VarBaseReg.  Allow for 16k of variables.
	 The x64 supports 32-bit offsets, but we choose not to address everything from VarBaseReg."
	^varAddress notNil
	  and: [varAddress >= cogit varBaseAddress
	  and: [varAddress - cogit varBaseAddress < (1 << 14)]]
]

{ #category : #testing }
CogX64Compiler >> isBigEndian [
	<inline: true>
	^false
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
	<var: #operand type: #'unsigned long'>
	^operand signedIntFromLong between: -128 and: 127
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

{ #category : #'abstract instructions' }
CogX64Compiler >> maybeEstablishVarBase [
	"The receiver has a VarBaseReg; generate the code to set it to its value."
	cogit MoveCq: cogit varBaseAddress R: VarBaseReg
]

{ #category : #accessing }
CogX64Compiler >> minAbstractGeneralPurposeReg [
	"Answer the smallest index of an abstract general-purpose register used by this compiler.
	 N.B.  Abstract registers are negative numbers."
	<inline: true>
	^Scratch5Reg
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
CogX64Compiler >> nameForRegister: reg [ "<Integer>"
	<doNotGenerate>
	(reg between: 0 and: 15) ifTrue:
		[^#(RAX RCX RDX RBX RSP RBP RSI RDI R8 R9 R10 R11 R12 R13 R14 R15) at: reg + 1].
	^super nameForRegister: reg
]

{ #category : #'generate machine code' }
CogX64Compiler >> nopsFrom: startAddr to: endAddr [
	startAddr to: endAddr do:
		[:p| objectMemory byteAt: p put: 16r90]
]

{ #category : #accessing }
CogX64Compiler >> numIntRegArgs [
	^6
]

{ #category : #abi }
CogX64Compiler >> numberOfSaveableRegisters [
	"Answer the number of registers to be saved in a trampoline call that saves registers.
	 See genSaveRegisters"
	<cmacro: '(self) 14'>
	^14
]

{ #category : #'generate machine code' }
CogX64Compiler >> padIfPossibleWithNopsFrom: startAddr to: endAddr [
	self nopsFrom: startAddr to: endAddr
]

{ #category : #accessing }
CogX64Compiler >> pushCwByteSize [
	<inline: true>
	self subclassResponsibility
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
	self assert: (self callTargetFromReturnAddress: callSiteReturnAddress) signedIntToLong = callTargetAddress.
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 12 to: callSiteReturnAddress - 1]."
	^12
]

{ #category : #encoding }
CogX64Compiler >> rexR: reg "<0-15>" x: sibReg "<0-15>"  b: fieldReg [ "<0-15>"
	^self rexw: true r: reg x: sibReg b: fieldReg
]

{ #category : #encoding }
CogX64Compiler >> rexw: width64 "<Boolean>" r: reg "<0-15>" x: sibReg "<0-15>"  b: fieldReg [ "<0-15>"
	"Given width64, the R register, sib register, and modrm/sib/reg field, answer either nil,
	 if a REX prefix  byte is not needed, or the correctly encoded REX prefix byte.
	 See AMD64 Architecture Programmer's Manual Volume 3: General-Purpose and System Instructions, Table 1-11"
	| regBits |
	regBits := ((reg bitAnd: 8) >> 1) + ((sibReg bitAnd: 8) >> 2) + ((fieldReg bitAnd: 8) >> 3).
	^(width64 or: [regBits ~= 0]) ifTrue:
		[(width64 ifTrue: [16r48] ifFalse: [16r40]) + regBits]
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

{ #category : #'inline cacheing' }
CogX64Compiler >> storeLiteral32: literal beforeFollowingAddress: followingAddress [
	"Rewrite the 32-bit literal in the instruction immediately preceding followingAddress."
	objectMemory
		byteAt: followingAddress - 1 put: (literal >> 24 bitAnd: 16rFF);
		byteAt: followingAddress - 2 put: (literal >> 16 bitAnd: 16rFF);
		byteAt: followingAddress - 3 put: (literal >>   8 bitAnd: 16rFF);
		byteAt: followingAddress - 4 put: (literal            bitAnd: 16rFF)
]

{ #category : #'inline cacheing' }
CogX64Compiler >> thirtyTwoBitLiteralBefore: followingAddress [
	<inline: true>
	^self cCode: [objectMemory unalignedLong32At: followingAddress - 5]
		inSmalltalk: [   ((objectMemory byteAt: followingAddress - 1) << 24)
					+ ((objectMemory byteAt: followingAddress - 2) << 16)
					+ ((objectMemory byteAt: followingAddress - 3) << 8)
					+  (objectMemory byteAt: followingAddress - 4)]
]

{ #category : #disassembly }
CogX64Compiler >> twoByteInstructionSizeAt: pc [
	| op |
	op := objectMemory byteAt: pc + 1. 
	^(op bitAnd: 16rF0) caseOf:
		{	[16r80]	->	[6 "long conditional jumps"] }
]

{ #category : #simulation }
CogX64Compiler >> wantsNearAddressFor: anObject [
	"A hack hook to allow x64 to address CStackPointer and CFramePointer relative to VarBaseReg."
	<doNotGenerate>
	^anObject isSymbol and: ['C*Pointer' match: anObject]
]
