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

{ #category : #'class initialization' }
CogX64Compiler class >> initialize [
	"Initialize various x64 instruction-related constants.
	 [1] IA-32 Intel® Architecture Software Developer's Manual Volume 2A: Instruction Set Reference, A-M"

	"CogX64Compiler initialize"

	| specificOpcodes refs |
	self ~~ CogX64Compiler ifTrue: [^self].

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
	LastRTLCode ifNil:
		[CogRTLOpcodes initialize].
	specificOpcodes := #(CDQ IDIVR IMULRR CPUID LFENCE MFENCE SFENCE LOCK CMPXCHGAwR CMPXCHGMwrR XCHGAwR XCHGMwrR XCHGRR).
	refs := (thisContext method literals select: [:l| l isVariableBinding and: [classPool includesKey: l key]]) collect:
				[:ea| ea key].
	(classPool keys reject: [:k| (specificOpcodes includes: k) or: [refs includes: k]]) do:
		[:k|
		Undeclared declare: k from: classPool].
	specificOpcodes withIndexDo:
		[:classVarName :value|
		self classPool
			declare: classVarName from: Undeclared;
			at: classVarName put: value + LastRTLCode - 1]
]

{ #category : #translation }
CogX64Compiler class >> machineCodeDeclaration [
	"Answer the declaration for the machineCode array."
	^{#'unsigned char'. '[', self basicNew machineCodeBytes printString, ']'}
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
		"[CDQ]					-> [^1].
		[IDIVR]					-> [^2].
		[IMULRR]				-> [^3].
		[CPUID]					-> [^2].
		[CMPXCHGAwR]			-> [^7].
		[CMPXCHGMwrR]		-> [^8].
		[LFENCE]				-> [^3].
		[MFENCE]				-> [^3].
		[SFENCE]				-> [^3].
		[LOCK]					-> [^1].
		[XCHGAwR]				-> [^6].
		[XCHGMwrR]			-> [^7].
		[XCHGRR]				-> [^2]."
		"Control"
		[CallFull]					-> [^5].
		[Call]						-> [^5].
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
		"[AddCqR]		-> [^(self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[AndCqR]		-> [^(self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[CmpCqR]		-> [^(self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[OrCqR]			-> [^(self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[SubCqR]		-> [^(self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[TstCqR]		-> [^((self isQuick: (operands at: 0)) and: [(self concreteRegister: (operands at: 1)) < 4])
											ifTrue: [3]
											ifFalse: [(self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[AddCwR]		-> [^(self concreteRegister: (operands at: 1)) = EAX ifTrue: [5] ifFalse: [6]].
		[AndCwR]		-> [^(self concreteRegister: (operands at: 1)) = EAX ifTrue: [5] ifFalse: [6]].
		[CmpCwR]		-> [^(self concreteRegister: (operands at: 1)) = EAX ifTrue: [5] ifFalse: [6]].
		[OrCwR]		-> [^(self concreteRegister: (operands at: 1)) = EAX ifTrue: [5] ifFalse: [6]].
		[SubCwR]		-> [^(self concreteRegister: (operands at: 1)) = EAX ifTrue: [5] ifFalse: [6]].
		[XorCwR]		-> [^(self concreteRegister: (operands at: 1)) = EAX ifTrue: [5] ifFalse: [6]].
		[AddRR]			-> [^2].
		[AndRR]			-> [^2].
		[CmpRR]		-> [^2].
		[OrRR]			-> [^2].
		[XorRR]			-> [^2].
		[SubRR]			-> [^2].
		[NegateR]		-> [^2].
		[LoadEffectiveAddressMwrR]
						-> [^((self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [6])
										+ ((self concreteRegister: (operands at: 1)) = ESP
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
		[SqrtRd]					-> [^4]."
		"Data Movement"
		"[MoveCqR]		-> [^(operands at: 0) = 0 ifTrue: [2] ifFalse: [5]].
		[MoveCwR]		-> [^5].
		[MoveRR]		-> [^2].
		[MoveRdRd]		-> [^4].
		[MoveAwR]		-> [^(self concreteRegister: (operands at: 1)) = EAX ifTrue: [5] ifFalse: [6]].
		[MoveRAw]		-> [^(self concreteRegister: (operands at: 0)) = EAX ifTrue: [5] ifFalse: [6]].
		[MoveRMwr]	-> [^((self isQuick: (operands at: 1))
											ifTrue: [3]
											ifFalse: [6])
										+ ((self concreteRegister: (operands at: 2)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveRdM64r]	-> [^((self isQuick: (operands at: 1))
											ifTrue: [5]
											ifFalse: [8])
										+ ((self concreteRegister: (operands at: 2)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveMbrR]		-> [^((self isQuick: (operands at: 0))
											ifTrue: [4]
											ifFalse: [7])
										+ ((self concreteRegister: (operands at: 1)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveRMbr]		-> [^((self isQuick: (operands at: 1))
											ifTrue: [3]
											ifFalse: [6])
										+ ((self concreteRegister: (operands at: 2)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveM16rR]	-> [^((self isQuick: (operands at: 0))
											ifTrue: [4]
											ifFalse: [7])
										+ ((self concreteRegister: (operands at: 1)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveM64rRd]	-> [^((self isQuick: (operands at: 0))
											ifTrue: [5]
											ifFalse: [8])
										+ ((self concreteRegister: (operands at: 1)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveMwrR]		-> [^((self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [6])
										+ ((self concreteRegister: (operands at: 1)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveXbrRR]	-> [self assert: (self concreteRegister: (operands at: 0)) ~= ESP.
							^(self concreteRegister: (operands at: 1)) = EBP
											ifTrue: [5]
											ifFalse: [4]].
		[MoveRXbrR]	->	[self assert: (self concreteRegister: (operands at: 1)) ~= ESP.
							^((self concreteRegister: (operands at: 2)) = EBP
											ifTrue: [4]
											ifFalse: [3])
										+ ((self concreteRegister: (operands at: 0)) >= 4
											ifTrue: [2]
											ifFalse: [0])].
		[MoveXwrRR]	-> [self assert: (self concreteRegister: (operands at: 0)) ~= ESP.
							^(self concreteRegister: (operands at: 1)) = EBP
											ifTrue: [4]
											ifFalse: [3]].
		[MoveRXwrR]	-> [self assert: (self concreteRegister: (operands at: 1)) ~= ESP.
							^(self concreteRegister: (operands at: 2)) = EBP
											ifTrue: [4]
											ifFalse: [3]].
		[PopR]			-> [^1].
		[PushR]			-> [^1].
		[PushCq]		-> [^(self isQuick: (operands at: 0)) ifTrue: [2] ifFalse: [5]].
		[PushCw]		-> [^5].
		[PrefetchAw]	-> [^self hasSSEInstructions ifTrue: [7] ifFalse: [0]]."
		"Conversion"
		"[ConvertRRd]	-> [^4]" }.
	^0 "to keep C compiler quiet"
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeAndCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| mask reg |
	mask := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: (self rexR: 0 x: 0 b: reg).
	(self isQuick: mask) ifTrue:
		[machineCode
			at: 1 put: 16r83;
			at: 2 put: (self mod: ModReg RM: reg RO: 4);
			at: 3 put: (mask bitAnd: 16rFF).
		 ^machineCodeSize := 4].
	self assert: mask >> 32 = 0.
	reg = RAX ifTrue:
		[machineCode
			at: 1 put: 16r25;
			at: 2 put: (mask bitAnd: 16rFF);
			at: 3 put: (mask >> 8 bitAnd: 16rFF);
			at: 4 put: (mask >> 16 bitAnd: 16rFF);
			at: 5 put: (mask >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 6].
	machineCode
		at: 1 put: 16r81;
		at: 2 put: (self mod: ModReg RM: reg RO: 4);
		at: 3 put: (mask bitAnd: 16rFF);
		at: 4 put: (mask >> 8 bitAnd: 16rFF);
		at: 5 put: (mask >> 16 bitAnd: 16rFF);
		at: 6 put: (mask >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 7
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeAt: actualAddress [
	"Generate concrete machine code for the instruction at actualAddress,
	 setting machineCodeSize, and answer the following address."

	address := actualAddress.
	self dispatchConcretize.
	self assert: (maxSize = nil or: [maxSize >= machineCodeSize]).
	^actualAddress + machineCodeSize
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
		[CallFull]				-> [^self concretizeCall].
		[JumpR]					-> [^self concretizeJumpR].
		[JumpFull]				-> [^self concretizeJumpLong].
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
		[AddCqR]					-> [^self concretizeAddCqR].
		[AddCwR]					-> [^self concretizeAddCwR].
		[AddRR]						-> [^self concretizeAddRR].
		[AddRdRd]					-> [^self concretizeSEE2OpRdRd: 16r58].
		[AndCqR]					-> [^self concretizeAndCqR].
		[AndCwR]					-> [^self concretizeAndCwR].
		[AndRR]						-> [^self concretizeAndRR].
		[TstCqR]					-> [^self concretizeTstCqR].
		[CmpCqR]					-> [^self concretizeCmpCqR].
		[CmpCwR]					-> [^self concretizeCmpCwR].
		[CmpRR]					-> [^self concretizeCmpRR].
		[CmpRdRd]					-> [^self concretizeCmpRdRd].
		[DivRdRd]					-> [^self concretizeSEE2OpRdRd: 16r5E].
		[MulRdRd]					-> [^self concretizeSEE2OpRdRd: 16r59].
		[OrCqR]						-> [^self concretizeOrCqR].
		[OrCwR]					-> [^self concretizeOrCwR].
		[OrRR]						-> [^self concretizeOrRR].
		[SubCqR]					-> [^self concretizeSubCqR].
		[SubCwR]					-> [^self concretizeSubCwR].
		[SubRR]						-> [^self concretizeSubRR].
		[SubRdRd]					-> [^self concretizeSEE2OpRdRd: 16r5C].
		[SqrtRd]						-> [^self concretizeSqrtRd].
		[XorCwR]						-> [^self concretizeXorCwR].
		[XorRR]							-> [^self concretizeXorRR].
		[NegateR]						-> [^self concretizeNegateR].
		[LoadEffectiveAddressMwrR]	-> [^self concretizeLoadEffectiveAddressMwrR].
		[ArithmeticShiftRightCqR]		-> [^self concretizeArithmeticShiftRightCqR].
		[LogicalShiftRightCqR]			-> [^self concretizeLogicalShiftRightCqR].
		[LogicalShiftLeftCqR]			-> [^self concretizeLogicalShiftLeftCqR].
		[ArithmeticShiftRightRR]			-> [^self concretizeArithmeticShiftRightRR].
		[LogicalShiftLeftRR]				-> [^self concretizeLogicalShiftLeftRR].
		"Data Movement"
		[MoveCqR]			-> [^self concretizeMoveCqR].
		[MoveCwR]			-> [^self concretizeMoveCwR].
		[MoveRR]			-> [^self concretizeMoveRR].
		[MoveAwR]			-> [^self concretizeMoveAwR].
		[MoveRAw]			-> [^self concretizeMoveRAw].
		[MoveMbrR]			-> [^self concretizeMoveMbrR].
		[MoveRMbr]			-> [^self concretizeMoveRMbr].
		[MoveM16rR]		-> [^self concretizeMoveM16rR].
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
		[ConvertRRd]		-> [^self concretizeConvertRRd] }
]

{ #category : #testing }
CogX64Compiler >> isQuick: operand [
	<var: #operand type: #'unsigned long'>
	^operand signedIntFromLong between: -128 and: 127
]

{ #category : #'generate machine code' }
CogX64Compiler >> machineCodeBytes [
	"Answer the maximum number of bytes of machine code generated for any abstract instruction.
	 e.g. lock movsd  0x400(%rsp),%xmm4 => f0 f2 0f 10 a4 24 00 04 00 00"
	^10
]

{ #category : #encoding }
CogX64Compiler >> mod: mod RM: regMode RO: regOpcode [
	^mod << 6 + ((regOpcode bitAnd: 7) << 3) + (regMode bitAnd: 7)
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
