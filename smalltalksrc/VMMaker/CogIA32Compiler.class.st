"
I generate IA32 (x86) instructions from CogAbstractInstructions.  For reference see
1. IA-32 Intel® Architecture Software Developer's Manual Volume 2A: Instruction Set Reference, A-M
2. IA-32 Intel® Architecture Software Developer's Manual Volume 2A: Instruction Set Reference, N-Z
	http://www.intel.com/products/processor/manuals/
(® is supposed to be the Unicode ""registered  sign"".

This class does not take any special action to flush the instruction cache on instruction-modification, trusting that Intel and AMD processors correctly invalidate the instruction cache via snooping.  According to the manuals, this will work on systems where code and data have the same virtual address.  The CogICacheFlushingIA32Compiler subclass exists to use the CPUID instruction to serialize instruction-modification for systems with code and data at different virtual addresses.
"
Class {
	#name : #CogIA32Compiler,
	#superclass : #CogAbstractInstruction,
	#classVars : [
		'CDQ',
		'CLD',
		'CMPXCHGAwR',
		'CMPXCHGMwrR',
		'CPUID',
		'EAX',
		'EBP',
		'EBX',
		'ECX',
		'EDI',
		'EDX',
		'ESI',
		'ESP',
		'FSTPD',
		'FSTPS',
		'IDIVR',
		'IMULRR',
		'LFENCE',
		'LOCK',
		'MFENCE',
		'MOVSB',
		'MOVSD',
		'ModReg',
		'ModRegInd',
		'ModRegIndDisp32',
		'ModRegIndSIB',
		'ModRegRegDisp32',
		'ModRegRegDisp8',
		'REP',
		'SFENCE',
		'SIB1',
		'SIB2',
		'SIB4',
		'SIB8',
		'XCHGAwR',
		'XCHGMwrR',
		'XCHGRR',
		'XMM0L',
		'XMM1L',
		'XMM2L',
		'XMM3L',
		'XMM4L',
		'XMM5L',
		'XMM6L',
		'XMM7L'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CogIA32Compiler class >> ISA [
	"Answer the name of the ISA the receiver implements."
	^#IA32
]

{ #category : #translation }
CogIA32Compiler class >> identifyingPredefinedMacros [
	^#('_M_I386' '_M_IX86' '_X86_' 'i386' 'i486' 'i586' 'i686' '__i386__' '__386__' 'X86' 'I386')
]

{ #category : #'class initialization' }
CogIA32Compiler class >> initialize [
	"Initialize various IA32/x86 instruction-related constants.
	 [1] IA-32 Intel® Architecture Software Developer's Manual Volume 2A: Instruction Set Reference, A-M"

	"CogIA32Compiler initialize"

	self ~~ CogIA32Compiler ifTrue: [^self].

	"N.B. EAX ECX and EDX are caller-save (scratch) registers.
		EBX ESI and EDI are callee-save; see concreteRegisterFor:"
	EAX := 0.
	ECX := 1.  "Were they completely mad or simply sadistic?"
	EDX := 2.
	EBX := 3.
	ESP := 4.
	EBP := 5.
	ESI := 6.
	EDI := 7.

	XMM0L := 0.
	XMM1L := 1.
	XMM2L := 2.
	XMM3L := 3.
	XMM4L := 4.
	XMM5L := 5.
	XMM6L := 6.
	XMM7L := 7.

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
		initializeSpecificOpcodes: #(CDQ IDIVR IMULRR CPUID LFENCE MFENCE SFENCE LOCK CMPXCHGAwR CMPXCHGMwrR XCHGAwR XCHGMwrR XCHGRR FSTPS FSTPD CLD REP MOVSB MOVSD)
		in: thisContext method
]

{ #category : #'class initialization' }
CogIA32Compiler class >> initializeAbstractRegisters [
	"Assign the abstract registers with the identities/indices of the relevant concrete registers."

	super initializeAbstractRegisters.

	"N.B. EAX ECX & EDX are caller-save (scratch) registers.  Hence we use ECX for class and EDX for
		receiver/result since these are written in all normal sends.  EBX ESI & EDI are callee-save."

	CallerSavedRegisterMask := self registerMaskFor: EAX and: ECX and: EDX.

	TempReg				:= EAX.
	ClassReg				:= ECX.
	ReceiverResultReg		:= EDX.
	SendNumArgsReg		:= EBX.
	SPReg					:= ESP.
	FPReg					:= EBP.
	Arg0Reg				:= ESI.
	Arg1Reg				:= EDI.

	NumRegisters := 8.

	DPFPReg0				:= XMM0L.
	DPFPReg1				:= XMM1L.
	DPFPReg2				:= XMM2L.
	DPFPReg3				:= XMM3L.
	DPFPReg4				:= XMM4L.
	DPFPReg5				:= XMM5L.
	DPFPReg6				:= XMM6L.
	DPFPReg7				:= XMM7L.

	NumFloatRegisters := 8
]

{ #category : #testing }
CogIA32Compiler class >> isRISCTempRegister: reg [
	"For tests to filter-out bogus values left in the RISCTempRegister, if any."
	^false
]

{ #category : #translation }
CogIA32Compiler class >> machineCodeDeclaration [
	"Answer the declaration for the machineCode array."
	^{#'unsigned char'. '[', self basicNew machineCodeBytes printString, ']'}
]

{ #category : #verification }
CogIA32Compiler class >> specificOpcodes [
	"Answer the processor-specific opcodes for this class.
	 They're all in an Array literal in the initialize method."
	^(self class >> #initialize) literals detect: [:l| l isArray and: [l includes: #LOCK]]
]

{ #category : #translation }
CogIA32Compiler class >> wordSize [
	"This is a 32-bit ISA"
	^4
]

{ #category : #testing }
CogIA32Compiler >> byteReadsZeroExtend [
	"Answer if a byte read, via MoveAbR, MoveMbrR, or MoveXbrRR zero-extends
	 into the full register, or merely affects the least significant 8 bits of the
	 the register.  By default the code generator assumes that byte reads
	 to not zero extend.  Note that byte reads /must not/ sign extend.
	 On x86 we always use movzbl"
	^true
]

{ #category : #abi }
CogIA32Compiler >> cFloatResultToRd: reg [
	cogit gen: FSTPD operand: -8 operand: SPReg .
	cogit MoveM64: -8 r: SPReg Rd: reg
]

{ #category : #abi }
CogIA32Compiler >> cFloatResultToRs: reg [
	cogit gen: FSTPS operand: -4 operand: SPReg.
	cogit MoveM32: -4 r: SPReg Rs: reg
]

{ #category : #accessing }
CogIA32Compiler >> cResultRegister [
	"Answer the register through which C funcitons return integral results."
	<inline: true>
	^EAX
]

{ #category : #accessing }
CogIA32Compiler >> cResultRegisterHigh [
	"Answer the abstract register for the C result register.
	 Only partially implemented.  Works on x86 since TempReg = EAX = C result reg."
	^ EDX
]

{ #category : #accessing }
CogIA32Compiler >> cResultRegisterLow [
	"Answer the abstract register for the C result register.
	 Only partially implemented.  Works on x86 since TempReg = EAX = C result reg."
	^ EAX
]

{ #category : #accessing }
CogIA32Compiler >> cStackPointer [
	
	^ ESP
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> callFullTargetFromReturnAddress: callSiteReturnAddress [
	"Answer the address the call immediately preceding callSiteReturnAddress will jump to."
	^self callTargetFromReturnAddress: callSiteReturnAddress
]

{ #category : #accessing }
CogIA32Compiler >> callInstructionByteSize [
	^5
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> callTargetFromReturnAddress: callSiteReturnAddress [
	"Answer the address the call immediately preceding callSiteReturnAddress will jump to."
	| callDistance |
	callDistance := self literalBeforeFollowingAddress: callSiteReturnAddress.
	^callSiteReturnAddress + callDistance signedIntFromLong
]

{ #category : #testing }
CogIA32Compiler >> canDivQuoRem [
	^true
]

{ #category : #testing }
CogIA32Compiler >> canMulRR [
	^true
]

{ #category : #testing }
CogIA32Compiler >> canSignExtend [
	"IA32 has native SignExtend8RR & SignExtend16RR."
	<inline: true>
	^true
]

{ #category : #testing }
CogIA32Compiler >> canZeroExtend [
	"IA32 has native ZeroExtend8RR & ZeroExtend16RR."
	<inline: true>
	^true
]

{ #category : #accessing }
CogIA32Compiler >> cmpC32RTempByteSize [
	^5
]

{ #category : #accessing }
CogIA32Compiler >> codeGranularity [
	"Answer the size in bytes of a unit of machine code."
	^1
]

{ #category : #'generate machine code' }
CogIA32Compiler >> computeMaximumSize [
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
		[REP]					-> [^1].
		[CLD]					-> [^1].
		[MOVSB]				-> [^1].
		[MOVSD]				-> [^1].
		[CDQ]					-> [^1].
		[IDIVR]					-> [^2].
		[IMULRR]				-> [^3].
		[CPUID]					-> [^2].
		[CMPXCHGAwR]			-> [^7].
		[CMPXCHGMwrR]		-> [^(operands at: 1) = ESP
										ifTrue: [(self isQuick: (operands at: 0)) ifTrue: [5] ifFalse: [8]]
										ifFalse: [(self isQuick: (operands at: 0)) ifTrue: [4] ifFalse: [7]]].
		[LFENCE]				-> [^3].
		[MFENCE]				-> [^3].
		[SFENCE]				-> [^3].
		[LOCK]					-> [^1].
		[XCHGAwR]				-> [^6].
		[XCHGMwrR]			-> [^(operands at: 1) = ESP
										ifTrue: [(self isQuick: (operands at: 0)) ifTrue: [4] ifFalse: [7]]
										ifFalse: [(self isQuick: (operands at: 0)) ifTrue: [3] ifFalse: [6]]].
		[XCHGRR]				-> [^((operands at: 0) = EAX
									   or: [(operands at: 1) = EAX])
										ifTrue: [1]
										ifFalse: [2]].
		[FSTPS]					-> [^7].
		[FSTPD]					-> [^7].
						
		"Control"
		[CallFull]					-> [^5].
		[Call]						-> [^5].
		[CallR]					-> [^2].
		[JumpR]						-> [^2].
		[JumpFull]					-> [self resolveJumpTarget. ^5].
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
		[AddCqR]		-> [^(self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(operands at: 1) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[AddcCqR]		-> [^(self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(operands at: 1) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[AndCqR]		-> [^(self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(operands at: 1) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[CmpCqR]		-> [^(self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(operands at: 1) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[OrCqR]			-> [^(self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(operands at: 1) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[SubCqR]		-> [^(self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(operands at: 1) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[TstCqR]		-> [^((self isQuick: (operands at: 0)) and: [(operands at: 1) < 4])
											ifTrue: [3]
											ifFalse: [(operands at: 1) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[AddCwR]		-> [^(operands at: 1) = EAX ifTrue: [5] ifFalse: [6]].
		[AndCwR]		-> [^(operands at: 1) = EAX ifTrue: [5] ifFalse: [6]].
		[CmpCwR]		-> [^(operands at: 1) = EAX ifTrue: [5] ifFalse: [6]].
		[OrCwR]		-> [^(operands at: 1) = EAX ifTrue: [5] ifFalse: [6]].
		[SubCwR]		-> [^(operands at: 1) = EAX ifTrue: [5] ifFalse: [6]].
		[XorCwR]		-> [^(operands at: 1) = EAX ifTrue: [5] ifFalse: [6]].
		[AddRR]			-> [^2].
		[AndRR]			-> [^2].
		[CmpRR]		-> [^2].
		[OrRR]			-> [^2].
		[XorRR]			-> [^2].
		[SubRR]			-> [^2].
		[NegateR]		-> [^2].
		[NotR]		-> [^2].
		[LoadEffectiveAddressMwrR]
						-> [^((self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [6])
										+ ((operands at: 1) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[LogicalShiftLeftCqR]		-> [^(operands at: 0) = 1 ifTrue: [2] ifFalse: [3]].
		[LogicalShiftRightCqR]		-> [^(operands at: 0) = 1 ifTrue: [2] ifFalse: [3]].
		[ArithmeticShiftRightCqR]	-> [^(operands at: 0) = 1 ifTrue: [2] ifFalse: [3]].
		[LogicalShiftLeftRR]			-> [^self computeShiftRRSize].
		[LogicalShiftRightRR]		-> [^self computeShiftRRSize].
		[ArithmeticShiftRightRR]		-> [^self computeShiftRRSize].
		[AddRdRd]					-> [^4].
		[CmpRdRd]					-> [^4].
		[SubRdRd]					-> [^4].
		[MulRdRd]					-> [^4].
		[DivRdRd]					-> [^4].
		[SqrtRd]					-> [^4].
		[XorRdRd]					-> [^4].
						
		[AddRsRs]				-> [^4].
		[CmpRsRs]				-> [^3].
		[SubRsRs]				-> [^4].
		[MulRsRs]				-> [^4].
		[DivRsRs]				-> [^4].
		[SqrtRs]					-> [^4].
		[XorRsRs]					-> [^3].
						
		"Data Movement"
		[MoveCqR]		-> [^(operands at: 0) = 0 ifTrue: [2] ifFalse: [5]].
		[MoveCwR]		-> [^5].
		[MoveRR]		-> [^2].
		[MoveRdRd]		-> [^4].
		[MoveRsRs]		-> [^4].
		[MoveAwR]		-> [^(operands at: 1) = EAX ifTrue: [5] ifFalse: [6]].
		[MoveRAw]		-> [^(operands at: 0) = EAX ifTrue: [5] ifFalse: [6]].
		[MoveAbR]		-> [^7].
		[MoveRAb]		-> [^(operands at: 0) = EAX ifTrue: [5] ifFalse: [6]].
		[MoveRM32r]	-> [^((self isQuick: (operands at: 1))
									ifTrue: [((operands at: 1) = 0
											and: [(operands at: 2) ~= EBP])
												ifTrue: [2]
												ifFalse: [3]]
									ifFalse: [6])
								+ ((operands at: 2) = ESP
									ifTrue: [1]
									ifFalse: [0])].
		[MoveRMwr]	-> [^((self isQuick: (operands at: 1))
									ifTrue: [((operands at: 1) = 0
											and: [(operands at: 2) ~= EBP])
												ifTrue: [2]
												ifFalse: [3]]
									ifFalse: [6])
								+ ((operands at: 2) = ESP
									ifTrue: [1]
									ifFalse: [0])].
		[MoveRdM64r]	-> [^((self isQuick: (operands at: 1))
											ifTrue: [5]
											ifFalse: [8])
										+ ((operands at: 2) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveRsM32r]	-> [^((self isQuick: (operands at: 1))
											ifTrue: [5]
											ifFalse: [8])
										+ ((operands at: 2) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveMbrR]		-> [^(operands at: 1) = ESP
								ifTrue: [(self isQuick: (operands at: 0)) ifTrue: [5] ifFalse: [8]]
								ifFalse: [(self isQuick: (operands at: 0)) ifTrue: [4] ifFalse: [7]]].
		[MoveRMbr]		-> [^(operands at: 2) = ESP
								ifTrue: [7]
								ifFalse: [(self isQuick: (operands at: 1)) ifTrue: [3] ifFalse: [6]]].
		[MoveM8rR]		-> [^(operands at: 1) = ESP
								ifTrue: [(self isQuick: (operands at: 0)) ifTrue: [5] ifFalse: [8]]
								ifFalse: [(self isQuick: (operands at: 0)) ifTrue: [4] ifFalse: [7]]].
		[MoveRM8r]		-> [^(operands at: 2) = ESP
								ifTrue: [7]
								ifFalse: [(self isQuick: (operands at: 1)) ifTrue: [3] ifFalse: [6]]].
		[MoveM16rR]	-> [^(operands at: 1) = ESP
								ifTrue: [(self isQuick: (operands at: 0)) ifTrue: [5] ifFalse: [8]]
								ifFalse: [(self isQuick: (operands at: 0)) ifTrue: [4] ifFalse: [7]]].
		[MoveRM16r]	-> [^(operands at: 2) = ESP
								ifTrue: [8]
								ifFalse: [(self isQuick: (operands at: 1)) ifTrue: [4] ifFalse: [7]]].
		[MoveM64rRd]	-> [^((self isQuick: (operands at: 0))
											ifTrue: [5]
											ifFalse: [8])
										+ ((operands at: 1) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveM32rRs]	-> [^((self isQuick: (operands at: 0))
											ifTrue: [5]
											ifFalse: [8])
										+ ((operands at: 1) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveM32rR]		-> [^((self isQuick: (operands at: 0))
									ifTrue: [((operands at: 0) = 0
											and: [(operands at: 1) ~= EBP])
												ifTrue: [2]
												ifFalse: [3]]
									ifFalse: [6])
								+ ((operands at: 1) = ESP
									ifTrue: [1]
									ifFalse: [0])].
		[MoveMwrR]		-> [^((self isQuick: (operands at: 0))
									ifTrue: [((operands at: 0) = 0
											and: [(operands at: 1) ~= EBP])
												ifTrue: [2]
												ifFalse: [3]]
									ifFalse: [6])
								+ ((operands at: 1) = ESP
									ifTrue: [1]
									ifFalse: [0])].
		[MoveXbrRR]	-> [self assert: (operands at: 0) ~= ESP.
							^(operands at: 1) = EBP
											ifTrue: [5]
											ifFalse: [4]].
		[MoveRXbrR]	->	[self assert: (operands at: 1) ~= ESP.
							^((operands at: 2) = EBP
											ifTrue: [4]
											ifFalse: [3])
										+ ((operands at: 0) >= 4
											ifTrue: [2]
											ifFalse: [0])].
		[MoveXwrRR]	-> [self assert: (operands at: 0) ~= ESP.
							^(operands at: 1) = EBP
											ifTrue: [4]
											ifFalse: [3]].
		[MoveRXwrR]	-> [self assert: (operands at: 1) ~= ESP.
							^(operands at: 2) = EBP
											ifTrue: [4]
											ifFalse: [3]].
		[PopR]			-> [^1].
		[PushR]			-> [^1].
		[PushCq]		-> [^(self isQuick: (operands at: 0)) ifTrue: [2] ifFalse: [5]].
		[PushCw]		-> [^5].
		[PrefetchAw]	-> [^self hasSSEInstructions ifTrue: [7] ifFalse: [0]].
		"Conversion"
		[ConvertRRd]	-> [^4].
		[ConvertRdR]	-> [^4].

		[ConvertRsRd]	-> [^4].
		[ConvertRdRs]	-> [^4].
		[ConvertRsR]	-> [^4].
		[ConvertRRs]	-> [^4].

		[SignExtend8RR] -> [^3].
		[SignExtend16RR] -> [^3].
		[ZeroExtend8RR] -> [^3].
		[ZeroExtend16RR] -> [^3].
	
		"This is a fixed size instruction using a patcheable literal. This takes ALWAYS 1 instruction of 5 bytes"
		[MovePatcheableC32R] -> [ ^ 5 ]
	 }.
	^0 "to keep C compiler quiet"
]

{ #category : #'generate machine code' }
CogIA32Compiler >> computeShiftRRSize [
	"On the x86 the only instructions that shift by the value of a
	 register require the shift count to be  in %ecx.  So we may
	 have to use swap instructions to get the count into ecx."
	| shiftCountReg |
	shiftCountReg := operands at: 0.
	^shiftCountReg = ECX
		ifTrue: [2]
		ifFalse:
			[shiftCountReg = EAX
				ifTrue: [1 "XCHG EAX,r2" + 2 "Sxx" + 1 "XCHG EAX,r2"]
				ifFalse: [2 "XCHG r1,r2" + 2 "Sxx" + 2 "XCHG r1,r2"]]
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeAddCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	(self isQuick: value) ifTrue:
		[machineCode
			at: 0 put: 16r83;
			at: 1 put: (self mod: ModReg RM: reg RO: 0);
			at: 2 put: (value bitAnd: 16rFF).
		 ^machineCodeSize := 3].
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16r05;
			at: 1 put: (value bitAnd: 16rFF);
			at: 2 put: (value >> 8 bitAnd: 16rFF);
			at: 3 put: (value >> 16 bitAnd: 16rFF);
			at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r81;
		at: 1 put: (self mod: ModReg RM: reg RO: 0);
		at: 2 put: (value bitAnd: 16rFF);
		at: 3 put: (value >> 8 bitAnd: 16rFF);
		at: 4 put: (value >> 16 bitAnd: 16rFF);
		at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeAddCwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16r05;
			at: 1 put: (value bitAnd: 16rFF);
			at: 2 put: (value >> 8 bitAnd: 16rFF);
			at: 3 put: (value >> 16 bitAnd: 16rFF);
			at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r81;
		at: 1 put: (self mod: ModReg RM: reg RO: 0);
		at: 2 put: (value bitAnd: 16rFF);
		at: 3 put: (value >> 8 bitAnd: 16rFF);
		at: 4 put: (value >> 16 bitAnd: 16rFF);
		at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeAddcCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	(self isQuick: value) ifTrue:
		[machineCode
			at: 0 put: 16r83;
			at: 1 put: (self mod: ModReg RM: reg RO: 2);
			at: 2 put: (value bitAnd: 16rFF).
		 ^machineCodeSize := 3].
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16r15;
			at: 1 put: (value bitAnd: 16rFF);
			at: 2 put: (value >> 8 bitAnd: 16rFF);
			at: 3 put: (value >> 16 bitAnd: 16rFF);
			at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r81;
		at: 1 put: (self mod: ModReg RM: reg RO: 2);
		at: 2 put: (value bitAnd: 16rFF);
		at: 3 put: (value >> 8 bitAnd: 16rFF);
		at: 4 put: (value >> 16 bitAnd: 16rFF);
		at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeAddcRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"Assemble the ADC instruction"
	| regLHS regRHS |
	regLHS := operands at: 0.
	regRHS := operands at: 1.
	machineCode
		at: 0 put: 16r13;
		at: 1 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeAlignmentNops [
	<inline: true>
	self flag: 'if performance is an issue generate longer nops'.
	0 to: machineCodeSize - 1 do:
		[:i|
		machineCode at: i put: 16r90]
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeAndCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| mask reg |
	mask := operands at: 0.
	reg := operands at: 1.
	(self isQuick: mask) ifTrue:
		[machineCode
			at: 0 put: 16r83;
			at: 1 put: (self mod: ModReg RM: reg RO: 4);
			at: 2 put: (mask bitAnd: 16rFF).
		 ^machineCodeSize := 3].
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16r25;
			at: 1 put: (mask bitAnd: 16rFF);
			at: 2 put: (mask >> 8 bitAnd: 16rFF);
			at: 3 put: (mask >> 16 bitAnd: 16rFF);
			at: 4 put: (mask >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r81;
		at: 1 put: (self mod: ModReg RM: reg RO: 4);
		at: 2 put: (mask bitAnd: 16rFF);
		at: 3 put: (mask >> 8 bitAnd: 16rFF);
		at: 4 put: (mask >> 16 bitAnd: 16rFF);
		at: 5 put: (mask >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeAndCwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16r25;
			at: 1 put: (value bitAnd: 16rFF);
			at: 2 put: (value >> 8 bitAnd: 16rFF);
			at: 3 put: (value >> 16 bitAnd: 16rFF);
			at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r83;
		at: 1 put: (self mod: ModReg RM: reg RO: 4);
		at: 2 put: (value bitAnd: 16rFF);
		at: 3 put: (value >> 8 bitAnd: 16rFF);
		at: 4 put: (value >> 16 bitAnd: 16rFF);
		at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeArithmeticShiftRightCqR [
	<inline: true>
	| shiftCount reg |
	shiftCount := (operands at: 0) min: 31.
	reg := operands at: 1.
	shiftCount = 1 ifTrue:
		[machineCode
			at: 0 put: 16rD1;
			at: 1 put: (self mod: ModReg RM: reg RO: 7).
		^machineCodeSize := 2].

	machineCode
		at: 0 put: 16rC1;
		at: 1 put: (self mod: ModReg RM: reg RO: 7);
		at: 2 put: shiftCount.
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeArithmeticShiftRightRR [
	"On the x86 the only instructions that shift by the value of a
	 register require the shift count to be  in %ecx.  So we may
	 have to use swap instructions to get the count into %ecx."
	<inline: true>
	| shiftCountReg destReg regToShift |
	shiftCountReg := operands at: 0.
	destReg := operands at: 1.
	shiftCountReg = ECX ifTrue:
		[machineCode
			at: 0 put: 16rD3;
			at: 1 put: (self mod: ModReg RM: destReg RO: 7).
		 ^machineCodeSize := 2].
	regToShift := destReg == shiftCountReg
					ifTrue: [ECX]
					ifFalse: [destReg = ECX
								ifTrue: [shiftCountReg]
								ifFalse: [destReg]].
	shiftCountReg = EAX ifTrue:
		[machineCode
			at: 0 put: 16r90 + ECX; "XCHG EAX,ECX"
			at: 1 put: 16rD3;			"SAR ECX,EAX"
			at: 2 put: (self mod: ModReg RM: regToShift RO: 7);
			at: 3 put: 16r90 + ECX. "XCHG EAX,ECX"
		 ^machineCodeSize := 4].
	machineCode
		at: 0 put: 16r87;		"XCHG E?X,ECX"
		at: 1 put: (self mod: ModReg RM: ECX RO: shiftCountReg);
		at: 2 put: 16rD3;		"SAR ECX,E!X"
		at: 3 put: (self mod: ModReg RM: regToShift RO: 7);
		at: 4 put: 16r87;		"XCHG E?X,ECX"
		at: 5 put: (self mod: ModReg RM: ECX RO: shiftCountReg).
	^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeCDQ [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	machineCode at: 0 put: 16r99.
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeCLD [
	<inline: true>
	machineCode at: 0 put: 16rFC.
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeCMPXCHGAwR [
	<inline: true>
	| addressOperand reg |
	addressOperand := operands at: 0.
	reg := operands at: 1.
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16rB1;
		at: 2 put: (self mod: ModRegInd RM: 5 RO: reg);
		at: 3 put: (addressOperand bitAnd: 16rFF);
		at: 4 put: (addressOperand >> 8 bitAnd: 16rFF);
		at: 5 put: (addressOperand >> 16 bitAnd: 16rFF);
		at: 6 put: (addressOperand >> 24 bitAnd: 16rFF).
	^machineCodeSize := 7
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeCMPXCHGMwrR [
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[machineCode
				at: 0 put: 16r0F;
				at: 1 put: 16rB1;
				at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: 3 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 4].
		machineCode
			at: 0 put: 16r0F;
			at: 1 put: 16rB1;
			at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
			at: 3 put: (offset bitAnd: 16rFF);
			at: 4 put: (offset >> 8 bitAnd: 16rFF);
			at: 5 put: (offset >> 16 bitAnd: 16rFF);
			at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 7].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 0 put: 16r0F;
			at: 1 put: 16rB1;
			at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: 3 put: (self s: SIB1 i: 4 b: srcReg);
			at: 4 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16rB1;
		at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
		at: 3 put: (self s: SIB1 i: 4 b: srcReg);
		at: 4 put: (offset bitAnd: 16rFF);
		at: 5 put: (offset >> 8 bitAnd: 16rFF);
		at: 6 put: (offset >> 16 bitAnd: 16rFF);
		at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 8
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeCPUID [
	<inline: true>
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16rA2.
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeCall [
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
CogIA32Compiler >> concretizeCallR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	"CmpRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	reg := operands at: 0.
	machineCode
		at: 0 put: 16rFF;
		at: 1 put: (self mod: ModReg RM: reg RO: 2).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeCmpCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	(self isQuick: value) ifTrue:
		[machineCode
			at: 0 put: 16r83;
			at: 1 put: (self mod: ModReg RM: reg RO: 7);
			at: 2 put: (value bitAnd: 16rFF).
		 ^machineCodeSize := 3].
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16r3D;
			at: 1 put: (value bitAnd: 16rFF);
			at: 2 put: (value >> 8 bitAnd: 16rFF);
			at: 3 put: (value >> 16 bitAnd: 16rFF);
			at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r81;
		at: 1 put: (self mod: ModReg RM: reg RO: 7);
		at: 2 put: (value bitAnd: 16rFF);
		at: 3 put: (value >> 8 bitAnd: 16rFF);
		at: 4 put: (value >> 16 bitAnd: 16rFF);
		at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeCmpCwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16r3D;
			at: 1 put: (value bitAnd: 16rFF);
			at: 2 put: (value >> 8 bitAnd: 16rFF);
			at: 3 put: (value >> 16 bitAnd: 16rFF);
			at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r81;
		at: 1 put: (self mod: ModReg RM: reg RO: 7);
		at: 2 put: (value bitAnd: 16rFF);
		at: 3 put: (value >> 8 bitAnd: 16rFF);
		at: 4 put: (value >> 16 bitAnd: 16rFF);
		at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeCmpRdRd [
	"Will get inlined into concretizeAt: switch.
	 We use UCOMISD (see p 4-260 [2])"
	<inline: true>
	| regLHS regRHS |
	"CmpRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	machineCode
		at: 0 put: 16r66;
		at: 1 put: 16r0F;
		at: 2 put: 16r2E;
		at: 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeCmpRsRs [
	"Will get inlined into concretizeAt: switch.
	 We use UCOMISS (see p 4-260 [2])"
	<inline: true>
	| regLHS regRHS |
	"CmpRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16r2E;
		at: 2 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeConditionalJump: conditionCode [
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
CogIA32Compiler >> concretizeConditionalJumpLong: conditionCode [
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
CogIA32Compiler >> concretizeConvertRRd [
	"Will get inlined into concretizeAt: switch."
	"CVTSI2D"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF2;
		at: 1 put: 16r0F;
		at: 2 put: 16r2A;
		at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeConvertRRs [
	"Will get inlined into concretizeAt: switch."
	"CVTSI2SS"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF3;
		at: 1 put: 16r0F;
		at: 2 put: 16r2A;
		at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeConvertRdR [
	"Will get inlined into concretizeAt: switch."
	"CVTSD2SI"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at:0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF2;
		at: 1 put: 16r0F;
		at: 2 put: 16r2D;
		at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeConvertRdRs [
	"Will get inlined into concretizeAt: switch."
	"CVTSD2SS"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF2;
		at: 1 put: 16r0F;
		at: 2 put: 16r5A;
		at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeConvertRsR [
	"Will get inlined into concretizeAt: switch."
	"CVTSS2SI"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF3;
		at: 1 put: 16r0F;
		at: 2 put: 16r2D;
		at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeConvertRsRd [
	"Will get inlined into concretizeAt: switch."
	"CVTSS2SD"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF3;
		at: 1 put: 16r0F;
		at: 2 put: 16r5A;
		at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeFENCE: regOpcode [
	<inline: true>
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16rAE;
		at: 2 put: (self mod: ModReg RM: 0 RO: regOpcode).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeFSTPD [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := 3.
	offset := operands at: 0.
	destReg := operands at: 1.
	destReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			"FSTP dest"
			[machineCode
				at: 0 put: 16rDD;
				at: 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
				at: 2 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 3].
		"FSTP dest"
		machineCode
			at: 0 put: 16rDD;
			at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
			at: 2 put: (offset bitAnd: 16rFF);
			at: 3 put: (offset >> 8 bitAnd: 16rFF);
			at: 4 put: (offset >> 16 bitAnd: 16rFF);
			at: 5 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 6].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 0 put: 16rDD;
			at: 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
			at: 2 put: (self s: SIB1 i: 4 b: destReg);
			at: 3 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 4].
	machineCode
		at: 0 put: 16rDD;
		at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
		at: 2 put: (self s: SIB1 i: 4 b: destReg);
		at: 3 put: (offset bitAnd: 16rFF);
		at: 4 put: (offset >> 8 bitAnd: 16rFF);
		at: 5 put: (offset >> 16 bitAnd: 16rFF);
		at: 6 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 7
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeFSTPS [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := 3.
	offset := operands at: 0.
	destReg := operands at: 1.
	destReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			"FSTP dest"
			[machineCode
				at: 0 put: 16rD9;
				at: 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
				at: 2 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 3].
		"FSTP dest"
		machineCode
			at: 0 put: 16rD9;
			at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
			at: 2 put: (offset bitAnd: 16rFF);
			at: 3 put: (offset >> 8 bitAnd: 16rFF);
			at: 4 put: (offset >> 16 bitAnd: 16rFF);
			at: 5 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 6].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 0 put: 16rD9;
			at: 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
			at: 2 put: (self s: SIB1 i: 4 b: destReg);
			at: 3 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 4].
	machineCode
		at: 0 put: 16rD9;
		at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
		at: 2 put: (self s: SIB1 i: 4 b: destReg);
		at: 3 put: (offset bitAnd: 16rFF);
		at: 4 put: (offset >> 8 bitAnd: 16rFF);
		at: 5 put: (offset >> 16 bitAnd: 16rFF);
		at: 6 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 7
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeFill32 [
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
CogIA32Compiler >> concretizeIDIVR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regDivisor |
	regDivisor := operands at: 0.
	machineCode
		at: 0 put: 16rF7;
		at: 1 put: (self mod: ModReg RM: regDivisor RO: 7).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeJump [
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
CogIA32Compiler >> concretizeJumpLong [
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
CogIA32Compiler >> concretizeJumpR [
	<inline: true>
	| reg |
	reg := operands at: 0.
	machineCode
		at: 0 put: 16rFF;
		at: 1 put: (self mod: ModReg RM: reg RO: 4).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeLOCK [
	<inline: true>
	machineCode at: 0 put: 16rF0.
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeLoadEffectiveAddressMwrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[machineCode
				at: 0 put: 16r8D;
				at: 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: 2 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 3].
		machineCode
			at: 0 put: 16r8D;
			at: 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
			at: 2 put: (offset bitAnd: 16rFF);
			at: 3 put: (offset >> 8 bitAnd: 16rFF);
			at: 4 put: (offset >> 16 bitAnd: 16rFF);
			at: 5 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 6].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 0 put: 16r8D;
			at: 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: 2 put: (self s: SIB1 i: 4 b: srcReg);
			at: 3 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 4].
	machineCode
		at: 0 put: 16r8D;
		at: 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
		at: 2 put: (self s: SIB1 i: 4 b: srcReg);
		at: 3 put: (offset bitAnd: 16rFF);
		at: 4 put: (offset >> 8 bitAnd: 16rFF);
		at: 5 put: (offset >> 16 bitAnd: 16rFF);
		at: 6 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 7
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeLogicalShiftLeftCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| distance reg |
	distance := (operands at: 0) min: 31.
	reg := operands at: 1.
	distance = 1 ifTrue:
		[machineCode
			at: 0 put: 16rD1;
			at: 1 put: (self mod: ModReg RM: reg RO: 4).
		 ^machineCodeSize := 2].
	machineCode
		at: 0 put: 16rC1;
		at: 1 put: (self mod: ModReg RM: reg RO: 4);
		at: 2 put: distance.
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeLogicalShiftLeftRR [
	<inline: true>
	"On the x86 the only instructions that shift by the value of a
	 register require the shift count to be  in %ecx.  So we may
	 have to use swap instructions to get the count into %ecx."
	| shiftCountReg destReg regToShift |
	shiftCountReg := operands at: 0.
	destReg := operands at: 1.
	shiftCountReg = ECX ifTrue:
		[machineCode
			at: 0 put: 16rD3;
			at: 1 put: (self mod: ModReg RM: destReg RO: 4).
		 ^machineCodeSize := 2].
	regToShift := destReg == shiftCountReg
					ifTrue: [ECX]
					ifFalse: [destReg = ECX
								ifTrue: [shiftCountReg]
								ifFalse: [destReg]].
	shiftCountReg = EAX ifTrue:
		[machineCode
			at: 0 put: 16r90 + ECX; "XCHG EAX,ECX"
			at: 1 put: 16rD3;			"SAR ECX,EAX"
			at: 2 put: (self mod: ModReg RM: regToShift RO: 4);
			at: 3 put: 16r90 + ECX. "XCHG EAX,ECX"
		 ^machineCodeSize := 4].
	machineCode
		at: 0 put: 16r87;		"XCHG E?X,ECX"
		at: 1 put: (self mod: ModReg RM: ECX RO: shiftCountReg);
		at: 2 put: 16rD3;		"SAR ECX,E!X"
		at: 3 put: (self mod: ModReg RM: regToShift RO: 4);
		at: 4 put: 16r87;		"XCHG E?X,ECX"
		at: 5 put: (self mod: ModReg RM: ECX RO: shiftCountReg).
	^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeLogicalShiftRightCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| distance reg |
	distance := (operands at: 0) min: 31.
	reg := operands at: 1.
	distance = 1 ifTrue:
		[machineCode
			at: 0 put: 16rD1;
			at: 1 put: (self mod: ModReg RM: reg RO: 5).
		 ^machineCodeSize := 2].
	machineCode
		at: 0 put: 16rC1;
		at: 1 put: (self mod: ModReg RM: reg RO: 5);
		at: 2 put: distance.
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMOVSB [
	<inline: true>
	machineCode at: 0 put: 16rA4.
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMOVSD [
	<inline: true>
	machineCode at: 0 put: 16rA5.
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveAbR [
	"N.B. we zero-extend because we state byteReadsZeroExtend."
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg |
	addressOperand := operands at: 0.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	reg := operands at: 1.
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16rB6;
		at: 2 put: (self mod: ModRegInd RM: 5 RO: reg);
		at: 3 put: (addressOperand bitAnd: 16rFF);
		at: 4 put: (addressOperand >> 8 bitAnd: 16rFF);
		at: 5 put: (addressOperand >> 16 bitAnd: 16rFF);
		at: 6 put: (addressOperand >> 24 bitAnd: 16rFF).
	^machineCodeSize := 7
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveAwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg |
	addressOperand := operands at: 0.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	reg := operands at: 1.
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16rA1;
			at: 1 put: (addressOperand bitAnd: 16rFF);
			at: 2 put: (addressOperand >> 8 bitAnd: 16rFF);
			at: 3 put: (addressOperand >> 16 bitAnd: 16rFF);
			at: 4 put: (addressOperand >> 24 bitAnd: 16rFF).
			^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r8B;
		at: 1 put: (self mod: ModRegInd RM: 5 RO: reg);
		at: 2 put: (addressOperand bitAnd: 16rFF);
		at: 3 put: (addressOperand >> 8 bitAnd: 16rFF);
		at: 4 put: (addressOperand >> 16 bitAnd: 16rFF);
		at: 5 put: (addressOperand >> 24 bitAnd: 16rFF).
	^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveCqR [
	"Will get inlined into concretizeAt: switch.
	 Note that for quick constants, xor reg,reg, movq r8 may be shorter.  But
	 we don't consider it worthwhile and so just provide concretizeMoveCwR."
	<inline: true>
	| reg |
	(operands at: 0) ~= 0 ifTrue:
		[^self concretizeMoveCwR].
	reg := operands at: 1.
	machineCode
		at: 0 put: 16r31;
		at: 1 put: (self mod: ModReg RM: reg RO: reg).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveCwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value |
	value := operands at: 0.
	machineCode
		at: 0 put: 16rB8 + (operands at: 1);
		at: 1 put: (value bitAnd: 16rFF);
		at: 2 put: (value >> 8 bitAnd: 16rFF);
		at: 3 put: (value >> 16 bitAnd: 16rFF);
		at: 4 put: (value >> 24 bitAnd: 16rFF).
	^machineCodeSize := 5
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveM16rR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[machineCode
				at: 0 put: 16r0F;
				at: 1 put: 16rB7;
				at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: 3 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 4].
		machineCode
			at: 0 put: 16r0F;
			at: 1 put: 16rB7;
			at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
			at: 3 put: (offset bitAnd: 16rFF);
			at: 4 put: (offset >> 8 bitAnd: 16rFF);
			at: 5 put: (offset >> 16 bitAnd: 16rFF);
			at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 7].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 0 put: 16r0F;
			at: 1 put: 16rB7;
			at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: 3 put: (self s: SIB1 i: 4 b: srcReg);
			at: 4 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16rB7;
		at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
		at: 3 put: (self s: SIB1 i: 4 b: srcReg);
		at: 4 put: (offset bitAnd: 16rFF);
		at: 5 put: (offset >> 8 bitAnd: 16rFF);
		at: 6 put: (offset >> 16 bitAnd: 16rFF);
		at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 8
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveM32rRs [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[machineCode
				at: 0 put: 16rF3;
				at: 1 put: 16r0F;
				at: 2 put: 16r10;
				at: 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: 4 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 5].
		machineCode
			at: 0 put: 16rF3;
			at: 1 put: 16r0F;
			at: 2 put: 16r10;
			at: 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
			at: 4 put: (offset bitAnd: 16rFF);
			at: 5 put: (offset >> 8 bitAnd: 16rFF);
			at: 6 put: (offset >> 16 bitAnd: 16rFF);
			at: 7 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 8].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 0 put: 16rF3;
			at: 1 put: 16r0F;
			at: 2 put: 16r10;
			at: 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: 4 put: (self s: SIB1 i: 4 b: srcReg);
			at: 5 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 6].
	machineCode
		at: 0 put: 16rF3;
		at: 1 put: 16r0F;
		at: 2 put: 16r10;
		at: 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
		at: 4 put: (self s: SIB1 i: 4 b: srcReg);
		at: 5 put: (offset bitAnd: 16rFF);
		at: 6 put: (offset >> 8 bitAnd: 16rFF);
		at: 7 put: (offset >> 16 bitAnd: 16rFF);
		at: 8 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 9
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveM64rRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[machineCode
				at: 0 put: 16rF2;
				at: 1 put: 16r0F;
				at: 2 put: 16r10;
				at: 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: 4 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 5].
		machineCode
			at: 0 put: 16rF2;
			at: 1 put: 16r0F;
			at: 2 put: 16r10;
			at: 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
			at: 4 put: (offset bitAnd: 16rFF);
			at: 5 put: (offset >> 8 bitAnd: 16rFF);
			at: 6 put: (offset >> 16 bitAnd: 16rFF);
			at: 7 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 8].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 0 put: 16rF2;
			at: 1 put: 16r0F;
			at: 2 put: 16r10;
			at: 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: 4 put: (self s: SIB1 i: 4 b: srcReg);
			at: 5 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 6].
	machineCode
		at: 0 put: 16rF2;
		at: 1 put: 16r0F;
		at: 2 put: 16r10;
		at: 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
		at: 4 put: (self s: SIB1 i: 4 b: srcReg);
		at: 5 put: (offset bitAnd: 16rFF);
		at: 6 put: (offset >> 8 bitAnd: 16rFF);
		at: 7 put: (offset >> 16 bitAnd: 16rFF);
		at: 8 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 9
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveM8rR [
	"Will get inlined into concretizeAt: switch."
	"movzwl"
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[machineCode
				at: 0 put: 16r0F;
				at: 1 put: 16rB6;
				at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: 3 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 4].
		machineCode
			at: 0 put: 16r0F;
			at: 1 put: 16rB6;
			at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
			at: 3 put: (offset bitAnd: 16rFF);
			at: 4 put: (offset >> 8 bitAnd: 16rFF);
			at: 5 put: (offset >> 16 bitAnd: 16rFF);
			at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 7].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 0 put: 16r0F;
			at: 1 put: 16rB6;
			at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: 3 put: (self s: SIB1 i: 4 b: srcReg);
			at: 4 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16rB6;
		at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
		at: 3 put: (self s: SIB1 i: 4 b: srcReg);
		at: 4 put: (offset bitAnd: 16rFF);
		at: 5 put: (offset >> 8 bitAnd: 16rFF);
		at: 6 put: (offset >> 16 bitAnd: 16rFF);
		at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 8
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveMbrR [
	"N.B. we zero-extend because we state byteReadsZeroExtend."
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[machineCode
				at: 0 put: 16r0f;
				at: 1 put: 16rb6;
				at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: 3 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 4].
		machineCode
			at: 0 put: 16r0f;
			at: 1 put: 16rb6;
			at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
			at: 3 put: (offset bitAnd: 16rFF);
			at: 4 put: (offset >> 8 bitAnd: 16rFF);
			at: 5 put: (offset >> 16 bitAnd: 16rFF);
			at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 7].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 0 put: 16r0f;
			at: 1 put: 16rb6;
			at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: 3 put: (self s: SIB1 i: 4 b: srcReg);
			at: 4 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r0f;
		at: 1 put: 16rb6;
		at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
		at: 3 put: (self s: SIB1 i: 4 b: srcReg);
		at: 4 put: (offset bitAnd: 16rFF);
		at: 5 put: (offset >> 8 bitAnd: 16rFF);
		at: 6 put: (offset >> 16 bitAnd: 16rFF);
		at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 8
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveMwrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(offset = 0 and: [srcReg ~= EBP]) ifTrue:
			[machineCode
				at: 0 put: 16r8B;
				at: 1 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 ^machineCodeSize := 2].
		(self isQuick: offset) ifTrue:
			[machineCode
				at: 0 put: 16r8B;
				at: 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: 2 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 3].
		machineCode
			at: 0 put: 16r8B;
			at: 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
			at: 2 put: (offset bitAnd: 16rFF);
			at: 3 put: (offset >> 8 bitAnd: 16rFF);
			at: 4 put: (offset >> 16 bitAnd: 16rFF);
			at: 5 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 6].
	"ESP:"
	offset = 0 ifTrue:
		[machineCode
			at: 0 put: 16r8B;
			at: 1 put: (self mod: ModRegInd RM: srcReg RO: destReg);
			at: 2 put: (self s: SIB1 i: 4 b: srcReg).
		 ^machineCodeSize := 3].
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 0 put: 16r8B;
			at: 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: 2 put: (self s: SIB1 i: 4 b: srcReg);
			at: 3 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 4].
	machineCode
		at: 0 put: 16r8B;
		at: 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
		at: 2 put: (self s: SIB1 i: 4 b: srcReg);
		at: 3 put: (offset bitAnd: 16rFF);
		at: 4 put: (offset >> 8 bitAnd: 16rFF);
		at: 5 put: (offset >> 16 bitAnd: 16rFF);
		at: 6 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 7
]

{ #category : #'as yet unclassified' }
CogIA32Compiler >> concretizeMovePatcheableC32R [
	
	^ self concretizeMoveCwR
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveRAb [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg |
	reg := operands at: 0.
	addressOperand := operands at: 1.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16rA2;
			at: 1 put: (addressOperand bitAnd: 16rFF);
			at: 2 put: (addressOperand >> 8 bitAnd: 16rFF);
			at: 3 put: (addressOperand >> 16 bitAnd: 16rFF);
			at: 4 put: (addressOperand >> 24 bitAnd: 16rFF).
			^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r88;
		at: 1 put: (self mod: ModRegInd RM: 5 RO: reg);
		at: 2 put: (addressOperand bitAnd: 16rFF);
		at: 3 put: (addressOperand >> 8 bitAnd: 16rFF);
		at: 4 put: (addressOperand >> 16 bitAnd: 16rFF);
		at: 5 put: (addressOperand >> 24 bitAnd: 16rFF).
	^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveRAw [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg |
	reg := operands at: 0.
	addressOperand := operands at: 1.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16rA3;
			at: 1 put: (addressOperand bitAnd: 16rFF);
			at: 2 put: (addressOperand >> 8 bitAnd: 16rFF);
			at: 3 put: (addressOperand >> 16 bitAnd: 16rFF);
			at: 4 put: (addressOperand >> 24 bitAnd: 16rFF).
			^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r89;
		at: 1 put: (self mod: ModRegInd RM: 5 RO: reg);
		at: 2 put: (addressOperand bitAnd: 16rFF);
		at: 3 put: (addressOperand >> 8 bitAnd: 16rFF);
		at: 4 put: (addressOperand >> 16 bitAnd: 16rFF);
		at: 5 put: (addressOperand >> 24 bitAnd: 16rFF).
	^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveRM16r [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 1.
	srcReg := operands at: 0.
	destReg := operands at: 2.
	destReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[machineCode
				at: 0 put: 16r66;
				at: 1 put: 16r89;
				at: 2 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
				at: 3 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 4].
		machineCode
			at: 0 put: 16r66;
			at: 1 put: 16r89;
			at: 2 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
			at: 3 put: (offset bitAnd: 16rFF);
			at: 4 put: (offset >> 8 bitAnd: 16rFF);
			at: 5 put: (offset >> 16 bitAnd: 16rFF);
			at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 7].
	machineCode
		at: 0 put: 16r66;
		at: 1 put: 16r89;
		at: 2 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
		at: 3 put: (self s: SIB1 i: 4 b: destReg);
		at: 4 put: (offset bitAnd: 16rFF);
		at: 5 put: (offset >> 8 bitAnd: 16rFF);
		at: 6 put: (offset >> 16 bitAnd: 16rFF);
		at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 8
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveRMbr [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 1.
	srcReg := operands at: 0.
	destReg := operands at: 2.
	srcReg >= 4 ifTrue: [self error: 'invalid register'].
	destReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[machineCode
				at: 0 put: 16r88;
				at: 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
				at: 2 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 3].
		machineCode
			at: 0 put: 16r88;
			at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
			at: 2 put: (offset bitAnd: 16rFF);
			at: 3 put: (offset >> 8 bitAnd: 16rFF);
			at: 4 put: (offset >> 16 bitAnd: 16rFF);
			at: 5 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 6].
	machineCode
		at: 0 put: 16r88;
		at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
		at: 2 put: (self s: SIB1 i: 4 b: destReg);
		at: 3 put: (offset bitAnd: 16rFF);
		at: 4 put: (offset >> 8 bitAnd: 16rFF);
		at: 5 put: (offset >> 16 bitAnd: 16rFF);
		at: 6 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 7
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveRMwr [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	destReg ~= ESP ifTrue:
		[(offset = 0 and: [destReg ~= EBP]) ifTrue:
			[machineCode
				at: 0 put: 16r89;
				at: 1 put: (self mod: ModRegInd RM: destReg RO: srcReg).
			 ^machineCodeSize := 2].
		 (self isQuick: offset) ifTrue:
			[machineCode
				at: 0 put: 16r89;
				at: 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
				at: 2 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 3].
		machineCode
			at: 0 put: 16r89;
			at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
			at: 2 put: (offset bitAnd: 16rFF);
			at: 3 put: (offset >> 8 bitAnd: 16rFF);
			at: 4 put: (offset >> 16 bitAnd: 16rFF);
			at: 5 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 6].
	"ESP:"
	offset = 0 ifTrue:
		[machineCode
			at: 0 put: 16r89;
			at: 1 put: (self mod: ModRegInd RM: destReg RO: srcReg);
			at: 2 put: (self s: SIB1 i: 4 b: destReg).
		 ^machineCodeSize := 3].
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 0 put: 16r89;
			at: 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
			at: 2 put: (self s: SIB1 i: 4 b: destReg);
			at: 3 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 4].
	machineCode
		at: 0 put: 16r89;
		at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
		at: 2 put: (self s: SIB1 i: 4 b: destReg);
		at: 3 put: (offset bitAnd: 16rFF);
		at: 4 put: (offset >> 8 bitAnd: 16rFF);
		at: 5 put: (offset >> 16 bitAnd: 16rFF);
		at: 6 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 7
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveRXbrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| src index base swapreg mcIdx |
	src := operands at: 0.
	index := operands at: 1.
	base := operands at: 2.
	mcIdx := 0.
	swapreg := NoReg.
	src >= 4 ifTrue: "x86 allows movb %rl, mem only with %al, %bl, %cl, %dl, so swap with the first one that isn't used."
		[swapreg := src.
		 index = EAX ifTrue: [index := swapreg].
		 base = EAX ifTrue: [base := swapreg].
		 src := EAX. 
		 mcIdx := 1.
		 machineCode at: 0 put: 16r90 + swapreg].
	base ~= EBP ifTrue:
		[machineCode
			at: mcIdx + 0 put: 16r88;
			at: mcIdx + 1 put: (self mod: ModRegInd RM: 4 RO: src);
			at: mcIdx + 2 put: (self s: SIB1 i: index b: base).
		 swapreg ~= NoReg ifTrue:
			[machineCode at: mcIdx + 3 put: 16r90 + swapreg].
		 ^machineCodeSize := 3 + (2 * mcIdx)].
	machineCode
		at: mcIdx + 0 put: 16r88;
		at: mcIdx + 1 put: (self mod: ModRegRegDisp8 RM: 4 RO: src);
		at: mcIdx + 2 put: (self s: SIB1 i: index b: base);
		at: mcIdx + 3 put: 0.
	swapreg ~= NoReg ifTrue:
		[machineCode at: mcIdx + 4 put: 16r90 + swapreg].
	 ^machineCodeSize := 4 + (2 * mcIdx)
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveRXwrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base src |
	src := operands at: 0.
	index := operands at: 1.
	base := operands at: 2.
	base ~= EBP ifTrue:
		[machineCode
			at: 0 put: 16r89;
			at: 1 put: (self mod: ModRegInd RM: 4 RO: src);
			at: 2 put: (self s: SIB4 i: index b: base).
		 ^machineCodeSize := 3].
	machineCode
		at: 0 put: 16r89;
		at: 1 put: (self mod: ModRegRegDisp8 RM: 4 RO: src);
		at: 2 put: (self s: SIB4 i: index b: base);
		at: 3 put: 0.
	 ^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveRdM64r [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	destReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[machineCode
				at: 0 put: 16rF2;
				at: 1 put: 16r0F;
				at: 2 put: 16r11;
				at: 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
				at: 4 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 5].
		machineCode
			at: 0 put: 16rF2;
			at: 1 put: 16r0F;
			at: 2 put: 16r11;
			at: 3 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
			at: 4 put: (offset bitAnd: 16rFF);
			at: 5 put: (offset >> 8 bitAnd: 16rFF);
			at: 6 put: (offset >> 16 bitAnd: 16rFF);
			at: 7 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 8].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 0 put: 16rF2;
			at: 1 put: 16r0F;
			at: 2 put: 16r11;
			at: 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
			at: 4 put: (self s: SIB1 i: 4 b: destReg);
			at: 5 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 6].
	machineCode
		at: 0 put: 16rF2;
		at: 1 put: 16r0F;
		at: 2 put: 16r11;
		at: 3 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
		at: 4 put: (self s: SIB1 i: 4 b: destReg);
		at: 5 put: (offset bitAnd: 16rFF);
		at: 6 put: (offset >> 8 bitAnd: 16rFF);
		at: 7 put: (offset >> 16 bitAnd: 16rFF);
		at: 8 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 9
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveRdRd [
	"Will get inlined into concretizeAt: switch."
	"MOVSD"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF2;
		at: 1 put: 16r0F;
		at: 2 put: 16r11;
		at: 3 put: (self mod: ModReg RM: destReg RO: srcReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveRsM32r [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	destReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			"MOVSD destReg, srcReg"
			[machineCode
				at: 0 put: 16rF3;
				at: 1 put: 16r0F;
				at: 2 put: 16r11;
				at: 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
				at: 4 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 5].
		"MOVSD destReg, srcReg"
		machineCode
			at: 0 put: 16rF3;
			at: 1 put: 16r0F;
			at: 2 put: 16r11;
			at: 3 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
			at: 4 put: (offset bitAnd: 16rFF);
			at: 5 put: (offset >> 8 bitAnd: 16rFF);
			at: 6 put: (offset >> 16 bitAnd: 16rFF);
			at: 7 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 8].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 0 put: 16rF3;
			at: 1 put: 16r0F;
			at: 2 put: 16r11;
			at: 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg);
			at: 4 put: (self s: SIB1 i: 4 b: destReg);
			at: 5 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 6].
	machineCode
		at: 0 put: 16rF3;
		at: 1 put: 16r0F;
		at: 2 put: 16r11;
		at: 3 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg);
		at: 4 put: (self s: SIB1 i: 4 b: destReg);
		at: 5 put: (offset bitAnd: 16rFF);
		at: 6 put: (offset >> 8 bitAnd: 16rFF);
		at: 7 put: (offset >> 16 bitAnd: 16rFF);
		at: 8 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 9
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveRsRs [
	"Will get inlined into concretizeAt: switch."
	"MOVSS"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16rF3;
		at: 1 put: 16r0F;
		at: 2 put: 16r11;
		at: 3 put: (self mod: ModReg RM: destReg RO: srcReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveXbrRR [
	"N.B. we zero-extend because we state byteReadsZeroExtend."
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base dest |
	index := operands at: 0.
	base := operands at: 1.
	dest := operands at: 2.
	base ~= EBP ifTrue:
		[machineCode
			at: 0 put: 16r0F;
			at: 1 put: 16rB6;
			at: 2 put: (self mod: ModRegInd RM: 4 RO: dest);
			at: 3 put: (self s: SIB1 i: index b: base).
		 ^machineCodeSize := 4].
	machineCode
			at: 0 put: 16r0F;
			at: 1 put: 16rB6;
		at: 2 put: (self mod: ModRegRegDisp8 RM: 4 RO: dest);
		at: 3 put: (self s: SIB1 i: index b: base);
		at: 4 put: 0.
	 ^machineCodeSize := 5
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveXwrRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base dest |
	index := operands at: 0.
	base := operands at: 1.
	dest := operands at: 2.
	base ~= EBP ifTrue:
		[machineCode
			at: 0 put: 16r8B;
			at: 1 put: (self mod: ModRegInd RM: 4 RO: dest);
			at: 2 put: (self s: SIB4 i: index b: base).
		 ^machineCodeSize := 3].
	machineCode
		at: 0 put: 16r8B;
		at: 1 put: (self mod: ModRegRegDisp8 RM: 4 RO: dest);
		at: 2 put: (self s: SIB4 i: index b: base);
		at: 3 put: 0.
	 ^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMulRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg1 reg2 |
	reg1 := operands at: 0.
	reg2 := operands at: 1.
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16rAF;
		at: 2 put: (self mod: ModReg RM: reg1 RO: reg2).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeNegateR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := operands at: 0.
	machineCode
		at: 0 put: 16rF7;
		at: 1 put: (self mod: ModReg RM: reg RO: 3).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeNop [
	<inline: true>
	machineCode at: 0 put: 16r90.
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeNotR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := operands at: 0.
	machineCode
		at: 0 put: 16rF7;
		at: 1 put: (self mod: ModReg RM: reg RO: 2).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeOpRR: x86opcode [
	| regLHS regRHS |
	regLHS := operands at: 0.
	regRHS := operands at: 1.
	machineCode
		at: 0 put: x86opcode;
		at: 1 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeOrCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| mask reg |
	mask := operands at: 0.
	reg := operands at: 1.
	(self isQuick: mask) ifTrue:
		[machineCode
			at: 0 put: 16r83;
			at: 1 put: (self mod: ModReg RM: reg RO: 1);
			at: 2 put: (mask bitAnd: 16rFF).
		 ^machineCodeSize := 3].
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16r0D;
			at: 1 put: (mask bitAnd: 16rFF);
			at: 2 put: (mask >> 8 bitAnd: 16rFF);
			at: 3 put: (mask >> 16 bitAnd: 16rFF);
			at: 4 put: (mask >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r81;
		at: 1 put: (self mod: ModReg RM: reg RO: 1);
		at: 2 put: (mask bitAnd: 16rFF);
		at: 3 put: (mask >> 8 bitAnd: 16rFF);
		at: 4 put: (mask >> 16 bitAnd: 16rFF);
		at: 5 put: (mask >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeOrCwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16r0D;
			at: 1 put: (value bitAnd: 16rFF);
			at: 2 put: (value >> 8 bitAnd: 16rFF);
			at: 3 put: (value >> 16 bitAnd: 16rFF);
			at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r83;
		at: 1 put: (self mod: ModReg RM: reg RO: 1);
		at: 2 put: (value bitAnd: 16rFF);
		at: 3 put: (value >> 8 bitAnd: 16rFF);
		at: 4 put: (value >> 16 bitAnd: 16rFF);
		at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizePopR [
	<inline: true>
	machineCode at: 0 put: 16r58 + (operands at: 0).
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizePrefetchAw [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand |
	"Note that maxSize has been set to 7 or 0 in computeMaximumSize whether hasSSEInstructions or not"
	maxSize > 0 ifTrue:
		[addressOperand := operands at: 0.
		 machineCode
			at: 0 put: 16r0f;
			at: 1 put: 16r18;
			at: 2 put: (self mod: 0 RM: 5 RO: 1); "prefetch0, prefetch using the T0 temporal data hint"
			at: 3 put: (addressOperand bitAnd: 16rFF);
			at: 4 put: (addressOperand >> 8 bitAnd: 16rFF);
			at: 5 put: (addressOperand >> 16 bitAnd: 16rFF);
			at: 6 put: (addressOperand >> 24 bitAnd: 16rFF)].
	^machineCodeSize := maxSize
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizePushCq [
	<inline: true>
	| value |
	value := operands at: 0.
	(self isQuick: value) ifTrue:
		[machineCode
			at: 0 put: 16r6A;
			at: 1 put: (value bitAnd: 16rFF).
		^machineCodeSize := 2].
	machineCode
		at: 0 put: 16r68;
		at: 1 put: (value bitAnd: 16rFF);
		at: 2 put: (value >> 8 bitAnd: 16rFF);
		at: 3 put: (value >> 16 bitAnd: 16rFF);
		at: 4 put: (value >> 24 bitAnd: 16rFF).
	^machineCodeSize := 5
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizePushCw [
	<inline: true>
	| value |
	value := operands at: 0.
	machineCode
		at: 0 put: 16r68;
		at: 1 put: (value bitAnd: 16rFF);
		at: 2 put: (value >> 8 bitAnd: 16rFF);
		at: 3 put: (value >> 16 bitAnd: 16rFF);
		at: 4 put: (value >> 24 bitAnd: 16rFF).
	^machineCodeSize := 5
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizePushR [
	<inline: true>
	machineCode at: 0 put: 16r50 + (operands at: 0).
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeREP [
	<inline: true>
	machineCode at: 0 put: 16rF3.
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeRetN [
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
CogIA32Compiler >> concretizeReverseOpRR: x86opcode [
	| regLHS regRHS |
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	machineCode
		at: 0 put: x86opcode;
		at: 1 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeSEE2OpRdRd: opCode [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	machineCode
		at: 0 put: 16rF2;
		at: 1 put: 16r0F;
		at: 2 put: opCode;
		at: 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeSEEOpRsRs: opCode [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regRHS := self operands at: 0.
	regLHS := self operands at: 1.
	machineCode
		at: 0 put: 16rF3;
		at: 1 put: 16r0F;
		at: 2 put: opCode;
		at: 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeSignExtend16RR [
	"Will get inlined into concretizeAt: switch."
	"movswl"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16rBF;
		at: 2 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeSignExtend8RR [
	"Will get inlined into concretizeAt: switch."
	"movsbl"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16rBE;
		at: 2 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeSqrtRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := operands at: 0.
	machineCode
		at: 0 put: 16rF2;
		at: 1 put: 16r0F;
		at: 2 put: 16r51;
		at: 3 put: (self mod: ModReg RM: reg RO: reg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeSqrtRs [
	"Will get inlined into concretizeAt: switch."
	"SRTSS"
	<inline: true>
	| reg |
	reg := operands at: 0.
	machineCode
		at: 0 put: 16rF3;
		at: 1 put: 16r0F;
		at: 2 put: 16r51;
		at: 3 put: (self mod: ModReg RM: reg RO: reg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeStop [
	<inline: true>
	machineCode at: 0 put: 16rCC.
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeSubCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	(self isQuick: value) ifTrue:
		[machineCode
			at: 0 put: 16r83;
			at: 1 put: (self mod: ModReg RM: reg RO: 5);
			at: 2 put: (value bitAnd: 16rFF).
		 ^machineCodeSize := 3].
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16r2D;
			at: 1 put: (value bitAnd: 16rFF);
			at: 2 put: (value >> 8 bitAnd: 16rFF);
			at: 3 put: (value >> 16 bitAnd: 16rFF);
			at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r81;
		at: 1 put: (self mod: ModReg RM: reg RO: 5);
		at: 2 put: (value bitAnd: 16rFF);
		at: 3 put: (value >> 8 bitAnd: 16rFF);
		at: 4 put: (value >> 16 bitAnd: 16rFF);
		at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeSubCwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16r2D;
			at: 1 put: (value bitAnd: 16rFF);
			at: 2 put: (value >> 8 bitAnd: 16rFF);
			at: 3 put: (value >> 16 bitAnd: 16rFF);
			at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r81;
		at: 1 put: (self mod: ModReg RM: reg RO: 5);
		at: 2 put: (value bitAnd: 16rFF);
		at: 3 put: (value >> 8 bitAnd: 16rFF);
		at: 4 put: (value >> 16 bitAnd: 16rFF);
		at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeSubbRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"Assemble the SBB instruction"
	| regLHS regRHS |
	regLHS := operands at: 0.
	regRHS := operands at: 1.
	machineCode
		at: 0 put: 16r1B;
		at: 1 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeTstCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| mask reg |
	mask := operands at: 0.
	reg := operands at: 1.
	((self isQuick: mask) and: [reg < 4]) ifTrue:
		[machineCode
			at: 0 put: 16rF6;
			at: 1 put: (self mod: ModReg RM: reg RO: 0);
			at: 2 put: (mask bitAnd: 16rFF).
		 ^machineCodeSize := 3].
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16rA9;
			at: 1 put: (mask bitAnd: 16rFF);
			at: 2 put: (mask >> 8 bitAnd: 16rFF);
			at: 3 put: (mask >> 16 bitAnd: 16rFF);
			at: 4 put: (mask >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16rF7;
		at: 1 put: (self mod: ModReg RM: reg RO: 0);
		at: 2 put: (mask bitAnd: 16rFF);
		at: 3 put: (mask >> 8 bitAnd: 16rFF);
		at: 4 put: (mask >> 16 bitAnd: 16rFF);
		at: 5 put: (mask >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeXCHGAwR [
	<inline: true>
	| addressOperand reg |
	addressOperand := operands at: 0.
	reg := operands at: 1.
	machineCode
		at: 0 put: 16r87;
		at: 1 put: (self mod: ModRegInd RM: 5 RO: reg);
		at: 2 put: (addressOperand bitAnd: 16rFF);
		at: 3 put: (addressOperand >> 8 bitAnd: 16rFF);
		at: 4 put: (addressOperand >> 16 bitAnd: 16rFF);
		at: 5 put: (addressOperand >> 24 bitAnd: 16rFF).
	^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeXCHGMwrR [
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[machineCode
				at: 0 put: 16r87;
				at: 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: 2 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 3].
		machineCode
			at: 0 put: 16r87;
			at: 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
			at: 2 put: (offset bitAnd: 16rFF);
			at: 3 put: (offset >> 8 bitAnd: 16rFF);
			at: 4 put: (offset >> 16 bitAnd: 16rFF);
			at: 5 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 6].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 0 put: 16r87;
			at: 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: 2 put: (self s: SIB1 i: 4 b: srcReg);
			at: 3 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 4].
	machineCode
		at: 0 put: 16r87;
		at: 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
		at: 2 put: (self s: SIB1 i: 4 b: srcReg);
		at: 3 put: (offset bitAnd: 16rFF);
		at: 4 put: (offset >> 8 bitAnd: 16rFF);
		at: 5 put: (offset >> 16 bitAnd: 16rFF);
		at: 6 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 7
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeXCHGRR [
	<inline: true>
	| reg1 reg2 |
	reg1 := operands at: 0.
	reg2 := operands at: 1.
	reg2 = EAX ifTrue:
		[reg2 := reg1.
		 reg1 := EAX].
	reg1 = EAX ifTrue:
		[machineCode at: 0 put: 16r90 + reg2.
		 ^machineCodeSize := 1].
	machineCode
		at: 0 put: 16r87;
		at: 1 put: (self mod: ModReg RM: reg1 RO: reg2).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeXorCwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	reg = EAX ifTrue:
		[machineCode
			at: 0 put: 16r35;
			at: 1 put: (value bitAnd: 16rFF);
			at: 2 put: (value >> 8 bitAnd: 16rFF);
			at: 3 put: (value >> 16 bitAnd: 16rFF);
			at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 5].
	machineCode
		at: 0 put: 16r81;
		at: 1 put: (self mod: ModReg RM: reg RO: 6);
		at: 2 put: (value bitAnd: 16rFF);
		at: 3 put: (value >> 8 bitAnd: 16rFF);
		at: 4 put: (value >> 16 bitAnd: 16rFF);
		at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeXorRdRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regRHS := self operands at: 0.
	regLHS := self operands at: 1.
	machineCode
		at: 0 put: 16r66;
		at: 1 put: 16r0f;
		at: 2 put: 16r57;
		at: 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeXorRsRs [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regRHS := self operands at: 0.
	regLHS := self operands at: 1.
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16r57;
		at: 2 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeZeroExtend16RR [
	"Will get inlined into concretizeAt: switch."
	"movzwl"
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16rB7;
		at: 2 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeZeroExtend8RR [
	"Will get inlined into concretizeAt: switch."
	"movzbl"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode
		at: 0 put: 16r0F;
		at: 1 put: 16rB6;
		at: 2 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ machineCodeSize := 3
]

{ #category : #'generate machine code' }
CogIA32Compiler >> dispatchConcretize [
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
		[CallFull]				-> [^self concretizeCall].
		[JumpR]				-> [^self concretizeJumpR].
		[JumpFull]				-> [^self concretizeJumpLong].
		[JumpLong]			-> [^self concretizeJumpLong].
		[JumpLongZero]		-> [^self concretizeConditionalJump: 16r4].
		[JumpLongNonZero]	-> [^self concretizeConditionalJump: 16r5].
		[Jump]					-> [^self concretizeJump].
		"Table B-1 Intel® 64 and IA-32 Architectures Software Developer's Manual Volume 1: Basic Architecture"
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
		[AddCqR]					-> [^self concretizeAddCqR].
		[AddCwR]					-> [^self concretizeAddCwR].
		[AddRR]					-> [^self concretizeOpRR: 16r03].
		[AddcRR]					-> [^self concretizeAddcRR].
		[AddcCqR]					-> [^self concretizeAddcCqR].
		[AddRdRd]					-> [^self concretizeSEE2OpRdRd: 16r58].
		[AddRsRs]					-> [^self concretizeSEEOpRsRs: 16r58].
		[AndCqR]					-> [^self concretizeAndCqR].
		[AndCwR]					-> [^self concretizeAndCwR].
		[AndRR]					-> [^self concretizeOpRR: 16r23].
		[TstCqR]					-> [^self concretizeTstCqR].
		[CmpCqR]					-> [^self concretizeCmpCqR].
		[CmpCwR]					-> [^self concretizeCmpCwR].
		[CmpRR]					-> [^self concretizeReverseOpRR: 16r39].
		[CmpRdRd]					-> [^self concretizeCmpRdRd].
		[CmpRsRs]					-> [^self concretizeCmpRsRs].
		[DivRdRd]					-> [^self concretizeSEE2OpRdRd: 16r5E].
		[DivRsRs]					-> [^self concretizeSEEOpRsRs: 16r5E].
		[MulRdRd]					-> [^self concretizeSEE2OpRdRd: 16r59].
		[MulRsRs]					-> [^self concretizeSEEOpRsRs: 16r59].
		[OrCqR]					-> [^self concretizeOrCqR].
		[OrCwR]					-> [^self concretizeOrCwR].
		[OrRR]						-> [^self concretizeOpRR: 16r0B].
		[SubCqR]					-> [^self concretizeSubCqR].
		[SubCwR]					-> [^self concretizeSubCwR].
		[SubRR]					-> [^self concretizeOpRR: 16r2B].
		[SubbRR]					-> [^self concretizeSubbRR].
		[SubRdRd]					-> [^self concretizeSEE2OpRdRd: 16r5C].
		[SubRsRs]					-> [^self concretizeSEEOpRsRs: 16r5C].
		[SqrtRd]						-> [^self concretizeSqrtRd].
		[SqrtRs]						-> [^self concretizeSqrtRs].
		[XorCwR]						-> [^self concretizeXorCwR].
		[XorRR]							-> [^self concretizeOpRR: 16r33].
		[XorRdRd]						-> [^self concretizeXorRdRd].
		[XorRsRs]						-> [^self concretizeXorRsRs].
		[NegateR]						-> [^self concretizeNegateR].
		[NotR]							-> [^self concretizeNotR].
		[LoadEffectiveAddressMwrR]	-> [^self concretizeLoadEffectiveAddressMwrR].
		[ArithmeticShiftRightCqR]		-> [^self concretizeArithmeticShiftRightCqR].
		[LogicalShiftRightCqR]			-> [^self concretizeLogicalShiftRightCqR].
		[LogicalShiftLeftCqR]			-> [^self concretizeLogicalShiftLeftCqR].
		[ArithmeticShiftRightRR]		-> [^self concretizeArithmeticShiftRightRR].
		[LogicalShiftLeftRR]				-> [^self concretizeLogicalShiftLeftRR].
		"Data Movement"
		[MoveCqR]			-> [^self concretizeMoveCqR].
		[MoveCwR]			-> [^self concretizeMoveCwR].
		[MoveRR]			-> [^self concretizeReverseOpRR: 16r89].
		[MoveRdRd]		-> [^self concretizeMoveRdRd].
		[MoveRsRs]			-> [^self concretizeMoveRsRs].
		[MoveAwR]			-> [^self concretizeMoveAwR].
		[MoveRAw]			-> [^self concretizeMoveRAw].
		[MoveAbR]			-> [^self concretizeMoveAbR].
		[MoveRAb]			-> [^self concretizeMoveRAb].
		[MoveMbrR]		-> [^self concretizeMoveMbrR].
		[MoveRMbr]		-> [^self concretizeMoveRMbr].
		[MoveRM8r]		-> [^self concretizeMoveRMbr].
		[MoveM8rR]		-> [^self concretizeMoveM8rR].
		[MoveM16rR]		-> [^self concretizeMoveM16rR].
		[MoveRM16r]		-> [^self concretizeMoveRM16r].
		[MoveM32rR]		-> [^self concretizeMoveMwrR].
		[MoveRM32r]		-> [^self concretizeMoveRMwr].
		[MoveM32rRs]		-> [^self concretizeMoveM32rRs].
		[MoveRsM32r]		-> [^self concretizeMoveRsM32r].
		[MoveM64rRd]		-> [^self concretizeMoveM64rRd].
		[MoveMwrR]		-> [^self concretizeMoveMwrR].
		[MoveXbrRR]		-> [^self concretizeMoveXbrRR].
		[MoveRXbrR]		-> [^self concretizeMoveRXbrR].
		[MoveXwrRR]		-> [^self concretizeMoveXwrRR].
		[MoveRXwrR]		-> [^self concretizeMoveRXwrR].
		[MoveRMwr]		-> [^self concretizeMoveRMwr].
		[MoveRdM64r]		-> [^self concretizeMoveRdM64r].
		[PopR]				-> [^self concretizePopR].
		[PushR]				-> [^self concretizePushR].
		[PushCq]			-> [^self concretizePushCq].
		[PushCw]			-> [^self concretizePushCw].
		[PrefetchAw]		-> [^self concretizePrefetchAw].
		"Conversion"
		[ConvertRRd]		-> [^self concretizeConvertRRd].
		[ConvertRdR]		-> [^self concretizeConvertRdR].
		
		[ConvertRsRd]		-> [^self concretizeConvertRsRd].
		[ConvertRdRs]		-> [^self concretizeConvertRdRs].
		[ConvertRsR]		-> [^self concretizeConvertRsR].
		[ConvertRRs]		-> [^self concretizeConvertRRs].
			
		[SignExtend8RR]		-> [^self concretizeSignExtend8RR].
		[SignExtend16RR]		-> [^self concretizeSignExtend16RR].
		
		[ZeroExtend8RR]		-> [^self concretizeZeroExtend8RR].
		[ZeroExtend16RR]		-> [^self concretizeZeroExtend16RR].
			
		[ MovePatcheableC32R ] -> [ ^ self concretizeMovePatcheableC32R ] }
]

{ #category : #'generate machine code' }
CogIA32Compiler >> dispatchConcretizeProcessorSpecific [
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
		[FSTPS]					-> [^self concretizeFSTPS].
		[FSTPD]				-> [^self concretizeFSTPD].
		[REP]					-> [^self concretizeREP].
		[CLD]					-> [^self concretizeCLD].
		[MOVSB]				-> [^self concretizeMOVSB].
		[MOVSD]				-> [^self concretizeMOVSD].
	}
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> flushICacheFrom: startAddress "<Integer>" to: endAddress [ "<Integer>"
	<cmacro: '(me,startAddress,endAddress) 0'>
	"On Intel processors where code and data have the same linear address, no
	 special action is required to flush the instruction cache.  One only needs to
	 execute a serializing instruction (e.g. CPUID) if code and data are at different
	 virtual addresses (e.g. a debugger using memory-mapping to access a debugee).
	 Using the macro avoids an unnecessary call."
	self halt: #ceFlushICache
]

{ #category : #abi }
CogIA32Compiler >> fullCallsAreRelative [
	"Answer if CallFull and/or JumpFull are relative and hence need relocating on method
	 compation. If so, they are annotated with IsRelativeCall in methods and relocated in
	 relocateIfCallOrMethodReference:mcpc:delta:"
	^true
]

{ #category : #'abstract instructions' }
CogIA32Compiler >> genDivR: abstractRegDivisor R: abstractRegDividend Quo: abstractRegQuotient Rem: abstractRegRemainder [
	| rDividend rDivisor rQuotient rRemainder saveRestoreEAX saveRestoreEDX saveRestoreExchanged |
	self assert: abstractRegDividend ~= abstractRegDivisor.
	self assert: abstractRegQuotient ~= abstractRegRemainder.
	rDividend := abstractRegDividend.
	rDivisor := abstractRegDivisor.
	rQuotient := abstractRegQuotient.
	rRemainder := abstractRegRemainder.
	"IDIV r does a signed divide of EDX:EAX by r, EAX := Quotient, EDX := Remainder.
	 Since we must sign extend the dividend into EDX we must substitute another register if EDX is an input"
	(rDividend = EDX or: [rDivisor = EDX]) ifTrue:
		[| rUnused |
		"Slang, sigh..."
		rUnused := EAX.
		[rUnused <= EDI] whileTrue:
			[(rUnused ~= ESP and: [rUnused ~= EBP and: [rUnused ~= EDX
			  and: [rUnused ~= rDividend and: [rUnused ~= rDivisor
			  and: [rUnused ~= rQuotient and: [rUnused ~= rRemainder]]]]]]) ifTrue:
				[cogit PushR: rUnused.
				cogit MoveR: EDX R: rUnused.
				rDividend = EDX
					ifTrue: [self genDivR: rDivisor R: rUnused Quo: rQuotient Rem: rRemainder]
					ifFalse: [self genDivR: rUnused R: rDividend Quo: rQuotient Rem: rRemainder].
				cogit PopR: rUnused.
				^self].
			  rUnused := rUnused + 1].
		self error: 'couldn''t find unused register in genDivR:R:Quo:Rem:'].
	"If either output does not include EAX or EDX we must save and restore EAX and/or EDX."
	(saveRestoreEAX := rQuotient ~= EAX and: [rRemainder ~= EAX]) ifTrue:
		[cogit PushR: EAX].
	(saveRestoreEDX := rQuotient ~= EDX and: [rRemainder ~= EDX]) ifTrue:
		[cogit PushR: EDX].
	saveRestoreExchanged := -1.
	rDividend ~= EAX ifTrue:
		[rDivisor = EAX
			ifTrue: [((rDividend ~= rQuotient and: [rDividend ~= rRemainder])
					and: [rDividend ~= EDX or: [saveRestoreEDX not]]) ifTrue:
						[cogit PushR: (saveRestoreExchanged := rDividend)].
					cogit gen: XCHGRR operand: rDivisor operand: rDividend]
			ifFalse: [cogit MoveR: rDividend R: EAX]].
	"CDQ sign-extends EAX into EDX as required for IDIV"
	cogit gen: CDQ.
	cogit gen: IDIVR operand: (rDivisor = EAX ifTrue: [rDividend] ifFalse: [rDivisor]).
	"Must not overwrite result while juggling"
	(rQuotient = EDX and: [rRemainder = EAX])
		ifTrue: [cogit gen: XCHGRR operand: rQuotient operand: rRemainder]
		ifFalse:
			[rQuotient = EDX
				ifTrue:
					[rRemainder ~= EDX ifTrue:
						[cogit MoveR: EDX R: rRemainder].
					rQuotient ~= EAX ifTrue:
						[cogit MoveR: EAX R: rQuotient]]
				ifFalse:
					[rQuotient ~= EAX ifTrue:
						[cogit MoveR: EAX R: rQuotient].
					rRemainder ~= EDX ifTrue:
						[cogit MoveR: EDX R: rRemainder]]].
	saveRestoreExchanged >= 0 ifTrue:
		[cogit PopR: saveRestoreExchanged].
	saveRestoreEDX ifTrue:
		[cogit PopR: EDX].
	saveRestoreEAX ifTrue:
		[cogit PopR: EAX]
]

{ #category : #'abstract instructions' }
CogIA32Compiler >> genJumpFPEqual: jumpTarget [
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
CogIA32Compiler >> genJumpFPNotEqual: jumpTarget [
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
CogIA32Compiler >> genLoadCStackPointer [
	"Load the stack pointer register with that of the C stack, effecting
	 a switch to the C stack.  Used when machine code calls into the
	 CoInterpreter run-time (e.g. to invoke interpreter primitives)."
	cogit MoveAw: cogit cStackPointerAddress R: SPReg.
	^0
]

{ #category : #'smalltalk calling convention' }
CogIA32Compiler >> genLoadCStackPointers [
	"Load the frame and stack pointer registers with those of the C stack,
	 effecting a switch to the C stack.  Used when machine code calls into
	 the CoInterpreter run-time (e.g. to invoke interpreter primitives)."
	cogit MoveAw: cogit cStackPointerAddress R: SPReg.
	cogit MoveAw: cogit cFramePointerAddress R: FPReg.
	^0
]

{ #category : #'smalltalk calling convention' }
CogIA32Compiler >> genLoadStackPointers [
	"Switch back to the Smalltalk stack. Assign SPReg first
	 because typically it is used immediately afterwards."
	cogit MoveAw: cogit stackPointerAddress R: SPReg.
	cogit MoveAw: cogit framePointerAddress R: FPReg.
	^0
]

{ #category : #abi }
CogIA32Compiler >> genMarshallNArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 [
	"Generate the code to pass up to four arguments in a C run-time call.  Hack: each argument is
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
	numArgs = 0 ifTrue:
		[^self].
	numArgs > 1 ifTrue:
		[numArgs > 2 ifTrue:
			[numArgs > 3 ifTrue:
				[(cogit isTrampolineArgConstant: regOrConst3)
					ifFalse: [cogit PushR: regOrConst3]
					ifTrue: [cogit PushCq: (cogit trampolineArgValue: regOrConst3)]].
			 (cogit isTrampolineArgConstant: regOrConst2)
				ifFalse: [cogit PushR: regOrConst2]
				ifTrue: [cogit PushCq: (cogit trampolineArgValue: regOrConst2)]].
		(cogit isTrampolineArgConstant: regOrConst1)
			ifFalse: [cogit PushR: regOrConst1]
			ifTrue: [cogit PushCq: (cogit trampolineArgValue: regOrConst1)]].
	(cogit isTrampolineArgConstant: regOrConst0)
		ifFalse: [cogit PushR: regOrConst0]
		ifTrue: [cogit PushCq: (cogit trampolineArgValue: regOrConst0)]
]

{ #category : #abi }
CogIA32Compiler >> genMarshallNArgs: numArgs floatArg: regOrConst0 floatArg: regOrConst1 floatArg: regOrConst2 floatArg: regOrConst3 [
	"Generate the code to pass up to four arguments in a C run-time call.  Hack: each argument is
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
	numArgs = 0 ifTrue:
		[^self].
	numArgs > 1 ifTrue:
		[numArgs > 2 ifTrue:
			[numArgs > 3 ifTrue:
				[(cogit isTrampolineArgConstant: regOrConst3)
					ifFalse: [cogit PushRd: regOrConst3]
					ifTrue: [cogit PushC64: (cogit trampolineArgValue: regOrConst3)]].
			 (cogit isTrampolineArgConstant: regOrConst2)
				ifFalse: [cogit PushRd: regOrConst2]
				ifTrue: [cogit PushC64: (cogit trampolineArgValue: regOrConst2)]].
		(cogit isTrampolineArgConstant: regOrConst1)
			ifFalse: [cogit PushRd: regOrConst1]
			ifTrue: [cogit PushC64: (cogit trampolineArgValue: regOrConst1)]].
	(cogit isTrampolineArgConstant: regOrConst0)
		ifFalse: [cogit PushRd: regOrConst0]
		ifTrue: [cogit PushC64: (cogit trampolineArgValue: regOrConst0)]
]

{ #category : #'abstract instructions' }
CogIA32Compiler >> genMemCopy: originalSourceReg to: originalDestReg constantSize: size [
	| numbytes numwords sourceReg destReg countReg inst |

	"Get the abstract registers for ECX, EDI and ESI"
	sourceReg := ESI.
	destReg := EDI.
	countReg := ECX.

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
	numbytes := size bitAnd: 16r03.
	numbytes > 0 ifTrue: [
		cogit MoveCq: numbytes R: countReg.
		cogit gen: REP.
		cogit gen: MOVSB.
	].

	"Now copy the words"
	numwords := size // 4.
	cogit MoveCq:  numwords R: countReg.
	cogit gen: REP.
	cogit gen: MOVSD.


]

{ #category : #'abstract instructions' }
CogIA32Compiler >> genMemCopy: originalSourceReg to: originalDestReg size: originalSize [
	| spilledSize size sourceReg destReg countReg inst |

	"Get the abstract registers for ECX, EDI and ESI"
	sourceReg := ESI.
	destReg := EDI.
	countReg := ECX.

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
	cogit AndCq: 16r03 R: countReg.
	cogit gen: REP.
	cogit gen: MOVSB.

	"Now copy the words"
	cogit MoveR: size R: countReg.
	cogit LogicalShiftRightCq: 2 R: countReg.
	cogit gen: REP.
	cogit gen: MOVSD.


]

{ #category : #'abstract instructions' }
CogIA32Compiler >> genMoveCf32: constantFloat32 Rs: register [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #constantFloat32 type: #float>
	| inst |
	inst := cogit PushCw: constantFloat32 asIEEE32BitWord.
	cogit PopRs: register.
	^ inst
]

{ #category : #'abstract instructions' }
CogIA32Compiler >> genMoveCf64: constantFloat64 Rd: register [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #constantFloat64 type: #double>
	| inst |
	inst := cogit PushC64: constantFloat64 asIEEE64BitWord.
	cogit PopRd: register.
	^ inst
]

{ #category : #'abstract instructions' }
CogIA32Compiler >> genMulR: regSource R: regDest [
	^cogit gen: IMULRR operand: regSource operand: regDest
]

{ #category : #'abstract instructions' }
CogIA32Compiler >> genPopRd: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	| inst |
	inst := cogit MoveM64: 0 r: SPReg Rd: reg .
	cogit AddCq: 8 R: SPReg.
	^ inst
]

{ #category : #'abstract instructions' }
CogIA32Compiler >> genPopRs: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	| inst |
	inst := cogit MoveM32: 0 r: SPReg Rs: reg .
	cogit AddCq: 4 R: SPReg.
	^ inst
]

{ #category : #'abstract instructions' }
CogIA32Compiler >> genPushC64: constant64Bits [
	<inline: true>
	<var: #constant64Bits type: #sqLong>
	<returnTypeC: #'AbstractInstruction *'>
	| inst highPart |
	highPart := constant64Bits bitShift: -32.
	inst :=cogit PushCw: highPart.
	cogit PushCw: (constant64Bits bitAnd: 16rFFFFFFFF).
	^inst
]

{ #category : #'abstract instructions' }
CogIA32Compiler >> genPushRd: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	| inst |
	inst := cogit MoveRd: reg M64: -8 r: SPReg.
	cogit SubCq: 8 R: SPReg.
	^ inst
]

{ #category : #'smalltalk calling convention' }
CogIA32Compiler >> genPushRegisterArgsForAbortMissNumArgs: numArgs [
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
CogIA32Compiler >> genPushRegisterArgsForNumArgs: numArgs scratchReg: scratchReg [
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
CogIA32Compiler >> genPushRs: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	| inst |
	inst := cogit MoveRs: reg M32: -4 r: SPReg.
	cogit SubCq: 4 R: SPReg.
	^ inst
]

{ #category : #abi }
CogIA32Compiler >> genRemoveNArgsFromStack: n [
	<inline: true>
	n = 0 ifFalse: [cogit AddCq: n * 4 R: ESP].
	^0
]

{ #category : #abi }
CogIA32Compiler >> genRemoveNFloatArgsFromStack: n [
	<inline: true>
	n > 0 ifTrue: [cogit AddCq: n * 8 R: ESP].
	^0
]

{ #category : #abi }
CogIA32Compiler >> genRestoreRegs: regMask [
	"Restore the registers in regMask as saved by genSaveRegs:."
	self deny: (regMask anyMask: (cogit registerMaskFor: ESP and: EBP)).
	EAX to: EDI do:
		[:reg|
		 (regMask anyMask: (cogit registerMaskFor: reg)) ifTrue:
			[cogit PopR: reg]].
	^0
]

{ #category : #abi }
CogIA32Compiler >> genSaveRegs: regMask [
	"Save the registers in regMask for a call into the C run-time from a trampoline."

	self assert: (EDI > EAX and: [EDI - EAX + 1 = 8]).
	self deny: (regMask anyMask: (cogit registerMaskFor: ESP and: EBP)).
	EDI to: EAX by: -1 do:
		[:reg|
		 (regMask anyMask: (cogit registerMaskFor: reg)) ifTrue:
			[cogit PushR: reg]].
	^0
]

{ #category : #'smalltalk calling convention' }
CogIA32Compiler >> genSaveStackPointers [
	"Save the frame and stack pointer registers to the framePointer
	 and stackPointer variables.  Used to save the machine code frame
	 for use by the run-time when calling into the CoInterpreter run-time."
	cogit MoveR: FPReg Aw: cogit framePointerAddress.
	cogit MoveR: SPReg Aw: cogit stackPointerAddress.
	^0
]

{ #category : #'abstract instructions' }
CogIA32Compiler >> genSubstituteReturnAddress: retpc [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^cogit PushCw: retpc
]

{ #category : #'abstract instructions' }
CogIA32Compiler >> genSwapR: regA R: regB Scratch: regTmp [
	^cogit gen: XCHGRR operand: regA operand: regB
]

{ #category : #disassembly }
CogIA32Compiler >> generalPurposeRegisterMap [
	<doNotGenerate>
	"Answer a Dictionary from register getter to register index."
	^Dictionary newFromPairs:
		{	#eax. EAX.
			#ecx. ECX.
			#edx. EDX.
			#ebx. EBX.
			#esi.  ESI.
			#edi.  EDI	}
]

{ #category : #'feature detection' }
CogIA32Compiler >> generateCheckFeatures [
	cogit
		PushR: EDX;
		PushR: ECX;
		PushR: EBX;
		MoveCq: 1 R: EAX;
		gen: CPUID;
		MoveR: EDX R: EAX;
		PopR: EBX;
		PopR: ECX;
		PopR: EDX;
		RetN: 0
]

{ #category : #'multi-threading' }
CogIA32Compiler >> generateLowLevelTryLock: vmOwnerLockAddress [
	"Generate a function that attempts to lock the vmOwnerLock and answers
	 true if it succeeded."
	vmOwnerLockAddress = 0 ifTrue:
		[cogit
			MoveCq: 1 R: EAX;
			RetN: 0.
		 ^self].
	cogit
		MoveCq: 1 R: EAX;
		gen: MFENCE; "make the XCHG globally consistent"
		gen: XCHGAwR operand: vmOwnerLockAddress operand: EAX;
		gen: SFENCE; "make the store globally visible"
		SubCq: 1 R: EAX; "Since we only ever set the lock to 1 or 0, subtracting 1 sets
						   EAX to 0 if the lock was already locked and non-zero if it wasn't."
		RetN: 0
]

{ #category : #'multi-threading' }
CogIA32Compiler >> generateLowLevelUnlock: vmOwnerLockAddress [
	vmOwnerLockAddress ~= 0 ifTrue:
		[cogit
			MoveCq: 0 R: EAX;
			MoveR: EAX Aw: vmOwnerLockAddress;
			gen: SFENCE].
	cogit RetN: 0
]

{ #category : #testing }
CogIA32Compiler >> hasConditionRegister [
	"Answer if the receiver supports, e.g., JumpOverflow after a regular AddRR"
	^true
]

{ #category : #testing }
CogIA32Compiler >> hasDoublePrecisionFloatingPointSupport [
	"We can generate dpfp support if the processor has SSE2 instructions."
	<inline: true>
	^self hasSSE2Instructions
]

{ #category : #testing }
CogIA32Compiler >> hasLinkRegister [
	^false
]

{ #category : #testing }
CogIA32Compiler >> hasSSE2Instructions [
	"Answer if we support SSE2"
	^(cogit ceCheckFeatures bitAnd: (1 << 26)) ~= 0
]

{ #category : #testing }
CogIA32Compiler >> hasSSEInstructions [
	"Answer if we support SSE"
	^(cogit ceCheckFeatures bitAnd: (1 << 25)) ~= 0
]

{ #category : #testing }
CogIA32Compiler >> hasThreeAddressArithmetic [
	"Answer if the receiver supports three-address arithmetic instructions"
	^false
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> inlineCacheTagAt: callSiteReturnAddress [
	"Answer the inline cache tag for the return address of a send."
	^self literalBeforeFollowingAddress: callSiteReturnAddress - 5
]

{ #category : #disassembly }
CogIA32Compiler >> instructionSizeAt: pc [
	"Answer the instruction size at pc.  This is very far from a full decode.
	 It only has to cope with the instructions generated in a block dispatch."
	| op |
	op := objectMemory byteAt: pc.
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
CogIA32Compiler >> isBigEndian [
	^false
]

{ #category : #testing }
CogIA32Compiler >> isCallPrecedingReturnPC: mcpc [
	"Assuming mcpc is a send return pc answer if the instruction before it is a call (not a CallFull)."
	^(objectMemory byteAt: mcpc - 5) = 16rE8
]

{ #category : #disassembly }
CogIA32Compiler >> isJumpAt: pc [
	| op |
	op := objectMemory byteAt: pc.
	^  (op between: 16r70 and: 16r7F) "short conditional jumps"
	or: [op = 16rE9 "long unconditional jump"
	or: [op = 16rEB "short unconditional jump"
	or: [op = 16r0F "long conditional jumps"
		and: [(objectMemory byteAt: pc + 1) between: 16r80 and: 16r8F]]]]
]

{ #category : #testing }
CogIA32Compiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction."
	^self isJump or: [opcode = AlignmentNops]
]

{ #category : #testing }
CogIA32Compiler >> isQuick: operand [
	<var: #operand type: #'usqIntptr_t'>
	^operand signedIntFromLong between: -128 and: 127
]

{ #category : #accessing }
CogIA32Compiler >> jmpTarget: anAbstractInstruction [
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
CogIA32Compiler >> jumpLongByteSize [
"	Branch/Call ranges.  Jump[Cond] can be generated as short as possible.  Call/Jump[Cond]Long must be generated
	in the same number of bytes irrespective of displacement since their targets may be updated, but they need only
	span 16Mb, the maximum size of the code zone.  This allows e.g. ARM to use single-word call and jump instructions
	for most calls and jumps.  CallFull/JumpFull must also be generated in the same number of bytes irrespective of
	displacement for the same reason, but they must be able to span the full (32-bit or 64-bit) address space because
	they are used to call code in the C runtime, which may be distant from the code zone"
	^5
]

{ #category : #accessing }
CogIA32Compiler >> jumpLongConditionalByteSize [
	^6
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> jumpLongTargetBeforeFollowingAddress: mcpc [ 
	"Answer the target address for the long jump immediately preceding mcpc"
	^self callTargetFromReturnAddress: mcpc
]

{ #category : #accessing }
CogIA32Compiler >> jumpShortByteSize [
	^2
]

{ #category : #disassembly }
CogIA32Compiler >> jumpTargetPCAt: pc [
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
CogIA32Compiler >> leafCallStackPointerDelta [
	"Answer the delta from the stack pointer after a call to the stack pointer
	 immediately prior to the call.  This is used to compute the stack pointer
	 immediately prior to  call from within a leaf routine, which in turn is used
	 to capture the c stack pointer to use in trampolines back into the C run-time."
	^4
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> literalBeforeFollowingAddress: followingAddress [
	"Answer the literal embedded in the instruction immediately preceding followingAddress."
	^  ((objectMemory byteAt: followingAddress - 1) << 24)
	+  ((objectMemory byteAt: followingAddress - 2) << 16)
	+  ((objectMemory byteAt: followingAddress - 3) << 8)
	+   (objectMemory byteAt: followingAddress - 4)
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> literalBeforeInlineCacheTagAt: callSiteReturnAddress [
	"Answer a literal loaded before the inline cache tag load for the return address of a send."
	^self literalBeforeFollowingAddress: callSiteReturnAddress - 10
]

{ #category : #accessing }
CogIA32Compiler >> loadLiteralByteSize [
	"Answer the byte size of a MoveCwR opcode's corresponding machine code"
	^5
]

{ #category : #accessing }
CogIA32Compiler >> loadPICLiteralByteSize [
	"Answer the byte size of a MoveCwR opcode's corresponding machine code
	 when the argument is a PIC.  This is for the self-reference at the end of a
	 closed PIC."
	<inline: true>
	^self loadLiteralByteSize
]

{ #category : #accessing }
CogIA32Compiler >> machineCodeAt: anOffset [
	^machineCode at: anOffset
]

{ #category : #'generate machine code' }
CogIA32Compiler >> machineCodeBytes [
	"Answer the maximum number of bytes of machine code generated for any abstract instruction.
	 e.g. lock movsd  0x400(%esp),%xmm4 => f0 f2 0f 10 a4 24 00 04 00 00"
	^10
]

{ #category : #encoding }
CogIA32Compiler >> mod: mod RM: regMode RO: regOpcode [
	"See ModR/M byte & opcode syntax
	 In addition to the notation shown above in 'Mnemonic Syntax' on page 43,
	 the following notation indicates the size and type of operands in the syntax of an instruction opcode:
		/digit	Indicates that the ModRM byte specifies only one register or memory (r/m) operand.
				The digit is specified by the ModRM reg field and is used as an instruction-opcode extension.
				Valid digit values range from 0 to 7.
		/r		Indicates that the ModRM byte specifies both a register operand and a reg/mem (register or memory) operand."
	^mod << 6 + (regOpcode << 3) + regMode
]

{ #category : #'feature detection' }
CogIA32Compiler >> numCheckFeaturesOpcodes [
	"Answer the number of opcodes required to compile the CPUID call to extract the extended features information."
	^11
]

{ #category : #accessing }
CogIA32Compiler >> numIntRegArgs [
	^0
]

{ #category : #accessing }
CogIA32Compiler >> numLowLevelLockOpcodes [
	"push $ebx
	 movl #0, %eax
	 movl 1, $ebx
	 mfence
	 lock cmpxchg %eax, &vmOwnerLock; # N.B. 2 instructions
	 pop $ebx
	 jnz locked
	 sfence
	 movl 1, $eax
	 ret
	locked:								; N.B. Requires an instruction
	 movl 0, $eax
	 ret"
	^14
]

{ #category : #'generate machine code' }
CogIA32Compiler >> padIfPossibleWithStopsFrom: startAddr to: endAddr [
	self stopsFrom: startAddr to: endAddr
]

{ #category : #'calling C function in Smalltalk stack' }
CogIA32Compiler >> prepareStackToCallCFunctionInSmalltalkStack: numberOfArguments [

	| numberAdditionalPushes remainer |

	remainer := numberOfArguments + 2 \\ 4 "Includes the caller address, and the original stack pointer".
	numberAdditionalPushes := remainer = 0 ifTrue: [ 0 ] ifFalse: [ 4 - remainer  ].

	cogit MoveR: SPReg R: TempReg.
	cogit AndCq: 16rFFFFFFF0 R: SPReg.

	"Save Original Stack Pointer"
	cogit PushR: TempReg.
	
	"I just push some padding for alignement"
	numberAdditionalPushes > 0 
		ifTrue: [ cogit SubCq: numberAdditionalPushes * 4 R: SPReg ]. 
	
	
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> relocateCallBeforeReturnPC: retpc by: delta [
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
CogIA32Compiler >> relocateMethodReferenceBeforeAddress: pc by: delta [
	<inline: true>
	self relocateCallBeforeReturnPC: pc by: delta
]

{ #category : #'calling C function in Smalltalk stack' }
CogIA32Compiler >> returnFromCallCFunctionInSmalltalkStack: numberOfArguments [

	| numberAdditionalPushes remainer |

	remainer := numberOfArguments + 2 \\ 4 "Includes the caller address, and the original stack pointer, and the temporary pointer".
	numberAdditionalPushes := remainer = 0 ifTrue: [ 0 ] ifFalse: [ 4 - remainer  ].

	"I just push some padding for alignement"
	numberAdditionalPushes > 0 
		ifTrue: [ cogit AddCq: numberAdditionalPushes * 4 R: SPReg ]. 

	"Restore Original Stack Pointer"
	cogit PopR: Arg0Reg.
	cogit MoveR: Arg0Reg R: SPReg.

	
	
	
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> rewriteCPICJumpAt: addressFollowingJump target: jumpTargetAddr [
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
CogIA32Compiler >> rewriteCallAt: callSiteReturnAddress target: callTargetAddress [
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

{ #category : #'inline cacheing' }
CogIA32Compiler >> rewriteInlineCacheAt: callSiteReturnAddress tag: cacheTag target: callTargetAddress [
	"Rewrite an inline cache to call a different target for a new tag.  This variant is used
	 to link unlinked sends in ceSend:to:numArgs: et al.  Answer the extent of the code
	 change which is used to compute the range of the icache to flush."
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
		byteAt: callSiteReturnAddress - 4 put: (callDistance            bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 6 put: (cacheTag >> 24 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 7 put: (cacheTag >> 16 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 8 put: (cacheTag >>   8 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 9 put: (cacheTag            bitAnd: 16rFF).
	self assert: (self callTargetFromReturnAddress: callSiteReturnAddress) = callTargetAddress.
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 10 to: callSiteReturnAddress - 1]."
	^10
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> rewriteInlineCacheTag: cacheTag at: callSiteReturnAddress [
	"Rewrite an inline cache with a new tag.  This variant is used
	 by the garbage collector."
	objectMemory
		byteAt: callSiteReturnAddress - 6 put: (cacheTag >> 24 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 7 put: (cacheTag >> 16 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 8 put: (cacheTag >>   8 bitAnd: 16rFF);
		byteAt: callSiteReturnAddress - 9 put: (cacheTag            bitAnd: 16rFF)
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> rewriteJumpLongAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a long jump instruction to jump to a different target.  This variant
	 is used to rewrite cached primitive calls.   Answer the extent of the
	 code change which is used to compute the range of the icache to flush."
	^self rewriteCallAt: callSiteReturnAddress target: callTargetAddress
]

{ #category : #encoding }
CogIA32Compiler >> s: scale i: indexReg b: baseReg [ 
	^scale << 6 + (indexReg << 3) + baseReg
]

{ #category : #abi }
CogIA32Compiler >> saveAndRestoreLinkRegAround: aBlock [
	"If the processor's ABI includes a link register, generate instructions
	 to save and restore it around aBlock, which is assumed to generate code."
	<inline: true>
	^aBlock value
]

{ #category : #testing }
CogIA32Compiler >> setsConditionCodesFor: aConditionalJumpOpcode [
	<inline: false> "to save Slang from having to be a real compiler (it can't inline switches that return)"
	"Answer if the receiver's opcode sets the condition codes correctly for the given conditional jump opcode."
	^opcode caseOf:
		{	[ArithmeticShiftRightCqR]	->	[self shiftSetsConditionCodesFor: aConditionalJumpOpcode].
			[ArithmeticShiftRightRR]	->	[self shiftSetsConditionCodesFor: aConditionalJumpOpcode].
			[LogicalShiftLeftCqR]		->	[self shiftSetsConditionCodesFor: aConditionalJumpOpcode].
			[LogicalShiftLeftRR]		->	[self shiftSetsConditionCodesFor: aConditionalJumpOpcode].
			[XorRR]					->	[true]
		}
		otherwise: [self halt: 'unhandled opcode in setsConditionCodesFor:'. false]
]

{ #category : #testing }
CogIA32Compiler >> shiftSetsConditionCodesFor: aConditionalJumpOpcode [
	"OF flag only guaranteed to be set for 1-bit shifts.  See [1] p 490.
	 Only SF, ZF & PF set according to result.  Since the question is currently
	 asked only for Zero and Negative use the following simplification."
	<inline: true>
	^(aConditionalJumpOpcode between: JumpZero and: JumpNonNegative)
]

{ #category : #disassembly }
CogIA32Compiler >> sizeHasModrm: op at: pc [
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
CogIA32Compiler >> sizeImmediateGroup1: op at: pc [
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

{ #category : #'generate machine code' }
CogIA32Compiler >> sizePCDependentInstructionAt: eventualAbsoluteAddress [
	"Size a jump and set its address.  The target may be another instruction
	 or an absolute address.  On entry the address inst var holds our virtual
	 address. On exit address is set to eventualAbsoluteAddress, which is
	 where this instruction will be output.  The span of a jump to a following
	 instruction is therefore between that instruction's address and this
	 instruction's address ((which are both still their virtual addresses), but the
	 span of a jump to a preceding instruction or to an absolute address is
	 between that instruction's address (which by now is its eventual absolute
	 address) or absolute address and eventualAbsoluteAddress."

	| target maximumSpan abstractInstruction |
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	opcode = AlignmentNops ifTrue:
		[| alignment |
		 address := eventualAbsoluteAddress.
		 alignment := operands at: 0.
		 ^machineCodeSize := (eventualAbsoluteAddress + (alignment - 1) bitAnd: alignment negated)
							   - eventualAbsoluteAddress].
	self assert: self isJump.
	target := operands at: 0.
	abstractInstruction := cogit cCoerceSimple: target to: #'AbstractInstruction *'.
	(self isAnInstruction: abstractInstruction)
		ifTrue:
			[maximumSpan := abstractInstruction address
							- (((cogit abstractInstruction: self follows: abstractInstruction)
								ifTrue: [eventualAbsoluteAddress]
								ifFalse: [address]) + 2)]
		ifFalse:
			[maximumSpan := target - (eventualAbsoluteAddress + 2)].
	address := eventualAbsoluteAddress.
	^machineCodeSize := opcode >= FirstShortJump
							ifTrue:
								[(self isQuick: maximumSpan)
									ifTrue: [2]
									ifFalse: [opcode = Jump
												ifTrue: [5]
												ifFalse: [6]]]
							ifFalse:
								[(opcode = JumpLong or: [opcode = JumpFull])
									ifTrue: [5]
									ifFalse: [6]]
]

{ #category : #abi }
CogIA32Compiler >> stackBytesForNumArgs: numArgs [
	^numArgs * 4
]

{ #category : #accessing }
CogIA32Compiler >> stackPageInterruptHeadroomBytes [
	"Return a minimum amount of headroom for each stack page (in bytes).  In a
	 JIT the stack has to have room for interrupt handlers which will run on the stack.
	 See [1] pp 6-13 to 6-14.  On an interrupt or exception the maximum state that
	 an IA32 CPU will push is SS, ESP, EFLAGS, CS, EIP and an error code.  It may then
	 call an interrupt procedure.  Leave some room above the minimum state."
	^256
]

{ #category : #encoding }
CogIA32Compiler >> stop [
	"int3"
	<inline: true>
	^16rCC
]

{ #category : #'generate machine code' }
CogIA32Compiler >> stopsFrom: startAddr to: endAddr [
	self
		cCode: [self me: startAddr ms: self stop et: endAddr - startAddr + 1]
		inSmalltalk:
			[| alignedEnd alignedStart stops |
			stops := self stop << 8 + self stop.
			stops := stops << 16 + stops.
			alignedStart := startAddr + 3 // 4 * 4.
			alignedEnd := endAddr - 1 // 4 * 4.
			alignedEnd <= startAddr
				ifTrue:
					[startAddr to: endAddr do:
						[:addr | objectMemory byteAt: addr put: self stop]]
				ifFalse:
					[startAddr to: alignedStart - 1 do:
						[:addr | objectMemory byteAt: addr put: self stop].
					 alignedStart to: alignedEnd by: 4 do:
						[:addr | objectMemory long32At: addr put: stops].
					 alignedEnd + 4 to: endAddr do:
						[:addr | objectMemory byteAt: addr put: self stop]]]
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> storeLiteral: literal beforeFollowingAddress: followingAddress [
	"Rewrite the literal in the instruction immediately preceding followingAddress."
	objectMemory
		byteAt: followingAddress - 1 put: (literal >> 24 bitAnd: 16rFF);
		byteAt: followingAddress - 2 put: (literal >> 16 bitAnd: 16rFF);
		byteAt: followingAddress - 3 put: (literal >>   8 bitAnd: 16rFF);
		byteAt: followingAddress - 4 put: (literal            bitAnd: 16rFF)
]

{ #category : #disassembly }
CogIA32Compiler >> twoByteInstructionSizeAt: pc [
	| op |
	op := objectMemory byteAt: pc + 1. 
	^(op bitAnd: 16rF0) caseOf:
		{	[16r80]	->	[6 "long conditional jumps"] }
]

{ #category : #'memory access' }
CogIA32Compiler >> unalignedLongAt: byteAddress [
	<cmacro: '(byteAddress) longAt(byteAddress)'>
	^objectMemory unalignedLongAt: byteAddress
]

{ #category : #'memory access' }
CogIA32Compiler >> unalignedLongAt: byteAddress put: aWord [
	<cmacro: '(byteAddress,aWord) longAtput(byteAddress,aWord)'>
	^objectMemory unalignedLongAt: byteAddress put: aWord
]

{ #category : #accessing }
CogIA32Compiler >> unsignedShortAt: byteAddress [
	^(objectMemory byteAt: byteAddress) + ((objectMemory byteAt: byteAddress + 1) bitShift: 8)
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> zoneCallsAreRelative [
	"Answer if Call and JumpLong are relative and hence need to take the caller's
	 relocation delta into account during code compaction, rather than just the
	 callee's delta."
	^true
]
