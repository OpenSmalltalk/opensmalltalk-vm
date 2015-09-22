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
		"[LoadEffectiveAddressMwrR]
						-> [^((self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [6])
										+ ((self concreteRegister: (operands at: 1)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[LogicalShiftLeftCqR]		-> [^(operands at: 0) = 1 ifTrue: [2] ifFalse: [3]].
		[LogicalShiftRightCqR]		-> [^(operands at: 0) = 1 ifTrue: [2] ifFalse: [3]].
		[ArithmeticShiftRightCqR]	-> [^(operands at: 0) = 1 ifTrue: [2] ifFalse: [3]]."
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
		[MoveCqR]		-> [^(operands at: 0) = 0 ifTrue: [3] ifFalse: [(self is32BitSignedImmediate: (operands at: 0)) ifTrue: [7] ifFalse: [10]]].
		[MoveCwR]		-> [^10].
		[MoveRR]		-> [^3].
		[MoveRdRd]		-> [^4].
		"[MoveAwR]		-> [^(self concreteRegister: (operands at: 1)) = EAX ifTrue: [5] ifFalse: [6]].
		[MoveRAw]		-> [^(self concreteRegister: (operands at: 0)) = EAX ifTrue: [5] ifFalse: [6]]."
		[MoveRMwr]	-> [^((self isQuick: (operands at: 1))
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
											ifFalse: [3]]."
		[PopR]			-> [^(self concreteRegister: (operands at: 0)) < 8 ifTrue: [1] ifFalse: [2]].
		[PushR]			-> [^(self concreteRegister: (operands at: 0)) < 8 ifTrue: [1] ifFalse: [2]].
		[PushCq]		-> [^(self isQuick: (operands at: 0)) ifTrue: [2] ifFalse: [5]].
		[PushCw]		-> [^self computeSizeOfArithCwR - 1].
		[PrefetchAw]	-> [^self hasSSEInstructions ifTrue: [12] ifFalse: [0]].
		"Conversion"
		"[ConvertRRd]	-> [^4]" }.
	^0 "to keep C compiler quiet"
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
CogX64Compiler >> concretizeAddCqR [
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
			at: 2 put: (self mod: ModReg RM: reg RO: 0);
			at: 3 put: (mask bitAnd: 16rFF).
		 ^machineCodeSize := 4].
	self assert: mask >> 32 = 0.
	reg = RAX ifTrue:
		[machineCode
			at: 1 put: 16r05;
			at: 2 put: (mask bitAnd: 16rFF);
			at: 3 put: (mask >> 8 bitAnd: 16rFF);
			at: 4 put: (mask >> 16 bitAnd: 16rFF);
			at: 5 put: (mask >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 6].
	machineCode
		at: 1 put: 16r81;
		at: 2 put: (self mod: ModReg RM: reg RO: 0);
		at: 3 put: (mask bitAnd: 16rFF);
		at: 4 put: (mask >> 8 bitAnd: 16rFF);
		at: 5 put: (mask >> 16 bitAnd: 16rFF);
		at: 6 put: (mask >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 7
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
CogX64Compiler >> concretizeArithmeticShiftRightRR [
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
			at: 2 put: (self mod: ModReg RM: destReg RO: 7).
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
			at: 4 put: (self mod: ModReg RM: regToShift RO: 7);
			at: 5 put: 16r48;
			at: 6 put: 16r90 + RCX. "XCHG RAX,RCX"
		 ^machineCodeSize := 7].
	machineCode
		at: 0 put: (self rexR: shiftCountReg x: 0 b: RCX);		"XCHG R?X,RCX"
		at: 1 put: 16r87;
		at: 2 put: (self mod: ModReg RM: RCX RO: shiftCountReg);
		at: 3 put: (self rexR: 0 x: 0 b: regToShift);			"SAR RCX,R!X"
		at: 4 put: 16rD3;
		at: 5 put: (self mod: ModReg RM: regToShift RO: 7);
		at: 6 put: (self rexR: shiftCountReg x: 0 b: RCX);		"XCHG R?X,RCX"
		at: 7 put: 16r87;
		at: 8 put: (self mod: ModReg RM: RCX RO: shiftCountReg).
	^machineCodeSize := 9
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
CogX64Compiler >> concretizeCmpCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: (self rexR: 0 x: 0 b: reg).
	(self isQuick: value) ifTrue:
		[machineCode
			at: 1 put: 16r83;
			at: 2 put: (self mod: ModReg RM: reg RO: 7);
			at: 3 put: (value bitAnd: 16rFF).
		 ^machineCodeSize := 4].
	self assert: value >> 32 = 0.
	reg = RAX ifTrue:
		[machineCode
			at: 1 put: 16r3D;
			at: 2 put: (value bitAnd: 16rFF);
			at: 3 put: (value >> 8 bitAnd: 16rFF);
			at: 4 put: (value >> 16 bitAnd: 16rFF);
			at: 5 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 6].
	machineCode
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
CogX64Compiler >> concretizeIDIVR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regDivisor |
	regDivisor := self concreteRegister: (operands at: 0).
	machineCode
		at: 0 put: (self rexR: regDivisor x: 0 b: 0);
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
CogX64Compiler >> concretizeMoveCqR [
	"Will get inlined into concretizeAt: switch.
	 On x64 we can short-cut mov 0, reg using xor, and use 32-bit displacement, signed or unsigned, if possible."
	<inline: true>
	| value reg |
	value := operands at: 0.
	(self is32BitSignedImmediate: value) ifFalse:
		[^self concretizeMoveCwR].
	reg := self concreteRegister: (operands at: 1).
	machineCode at: 0 put: (self rexR: reg x: 0 b: reg).
	value = 0 ifTrue:
		[machineCode
			at: 1 put: 16r31;
			at: 2 put: (self mod: ModReg RM: reg RO: reg).
		^machineCodeSize := 3].
	machineCode
		at: 1 put: 16rC7;
		at: 2 put: (self mod: ModReg RM: reg RO: reg);
		at: 3 put: (value bitAnd: 16rFF);
		at: 4 put: (value >> 8 bitAnd: 16rFF);
		at: 5 put: (value >> 16 bitAnd: 16rFF);
		at: 6 put: (value >> 24 bitAnd: 16rFF).
	^machineCodeSize := 7
]

{ #category : #'generate machine code' }
CogX64Compiler >> concretizeMoveCwR [
	"Will get inlined into concretizeAt: switch.
	 Note that for quick constants, xor reg,reg, movq r8 may be shorter.
	 We don't consider it worthwhile for other  than 0."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: (self rexR: reg x: 0 b: reg);
		at: 1 put: 16rB8 + (reg bitAnd: 7);
		at: 2 put: (value bitAnd: 16rFF);
		at: 3 put: (value >> 8 bitAnd: 16rFF);
		at: 4 put: (value >> 16 bitAnd: 16rFF);
		at: 5 put: (value >> 24 bitAnd: 16rFF);
		at: 6 put: (value >> 32 bitAnd: 16rFF);
		at: 7 put: (value >> 40 bitAnd: 16rFF);
		at: 8 put: (value >> 48 bitAnd: 16rFF);
		at: 9 put: (value >> 56 bitAnd: 16rFF).
	^machineCodeSize := 10
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
CogX64Compiler >> concretizeNegateR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := self concreteRegister: (operands at: 0).
	machineCode
		at: 0 put: (self rexR: reg x: 0 b: reg);
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
CogX64Compiler >> concretizeSubCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: (self rexR: 0 x: 0 b: reg).
	(self isQuick: value) ifTrue:
		[machineCode
			at: 1 put: 16r83;
			at: 2 put: (self mod: ModReg RM: reg RO: 5);
			at: 3 put: (value bitAnd: 16rFF).
		 ^machineCodeSize := 4].
	self assert: value >> 32 = 0.
	reg = RAX ifTrue:
		[machineCode
			at: 1 put: 16r2D;
			at: 2 put: (value bitAnd: 16rFF);
			at: 3 put: (value >> 8 bitAnd: 16rFF);
			at: 4 put: (value >> 16 bitAnd: 16rFF);
			at: 5 put: (value >> 24 bitAnd: 16rFF).
		 ^machineCodeSize := 6].
	machineCode
		at: 1 put: 16r81;
		at: 2 put: (self mod: ModReg RM: reg RO: 5);
		at: 3 put: (value bitAnd: 16rFF);
		at: 4 put: (value >> 8 bitAnd: 16rFF);
		at: 5 put: (value >> 16 bitAnd: 16rFF);
		at: 6 put: (value >> 24 bitAnd: 16rFF).
	 ^machineCodeSize := 7
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

{ #category : #'abstract instructions' }
CogX64Compiler >> genMulR: regSource R: regDest [
	cogit gen: IMULRR operand: regSource operand: regDest
]

{ #category : #'abstract instructions' }
CogX64Compiler >> genSubstituteReturnAddress: retpc [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^cogit PushCw: retpc
]

{ #category : #testing }
CogX64Compiler >> hasDoublePrecisionFloatingPointSupport [
	^true
]

{ #category : #testing }
CogX64Compiler >> is32BitSignedImmediate: a64BitUnsignedOperand [
	^(a64BitUnsignedOperand >> 31) signedIntFromLong between: -1 and: 0
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
CogX64Compiler >> machineCodeAt: anOffset [
	^machineCode at: anOffset
]

{ #category : #'generate machine code' }
CogX64Compiler >> machineCodeBytes [
	"Answer the maximum number of bytes of machine code generated for any abstract instruction.
	 e.g. movq $0x12345678ABCDEF0, %rax; jmp *%rax => 48 B8 F0 DE BC 9A 78 56 34 12 FF E0"
	^12
]

{ #category : #'abstract instructions' }
CogX64Compiler >> maybeEstablishVarBase [
	"The receiver does not have a VarBaseReg; do nothing."
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

{ #category : #encoding }
CogX64Compiler >> s: scale i: indexReg b: baseReg [ 
	^scale << 6 + ((indexReg bitAnd: 7) << 3) + (baseReg bitAnd: 7)
]
