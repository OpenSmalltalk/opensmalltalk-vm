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
CogIA32Compiler class >> initialize [
	"Initialize various IA32/x86 instruction-related constants.
	 [1] IA-32 Intel® Architecture Software Developer's Manual Volume 2A: Instruction Set Reference, A-M"

	"CogIA32Compiler initialize"

	| specificOpcodes refs |
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
	LastRTLCode isNil ifTrue:
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

{ #category : #verification }
CogIA32Compiler class >> specificOpcodes [
	"Answer the processor-specific opcodes for this class.
	 They're all in an Array literal in the initialize method."
	^(self class >> #initialize) literals detect: [:l| l isArray and: [l includes: #LOCK]]
]

{ #category : #accessing }
CogIA32Compiler >> cResultRegister [
	"Answer the abstract register for the C result register.
	 Only partially implemented.  Works on x86 since TempReg = EAX = C result reg."
	^self abstractRegisterForConcreteRegister: EAX
]

{ #category : #accessing }
CogIA32Compiler >> callInstructionByteSize [
	^5
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> callTargetFromReturnAddress: callSiteReturnAddress [
	"Answer the address the call immediately preceeding callSiteReturnAddress will jump to."
	| callDistance |
	callDistance := self literalBeforeFollowingAddress: callSiteReturnAddress.
	^callSiteReturnAddress + callDistance signedIntFromLong
]

{ #category : #accessing }
CogIA32Compiler >> callerSavedRegisterMask [
	^cogit
		registerMaskFor: (self abstractRegisterForConcreteRegister: EAX)
		and: (self abstractRegisterForConcreteRegister: ECX)
		and: (self abstractRegisterForConcreteRegister: EDX)
]

{ #category : #testing }
CogIA32Compiler >> canDivQuoRem [
	<inline: true>
	^true
]

{ #category : #testing }
CogIA32Compiler >> canMulRR [
	<inline: true>
	^true
]

{ #category : #'generate machine code' }
CogIA32Compiler >> computeMaximumSize [
	"Compute the maximum size for each opcode.  This allows jump offsets to
	 be determined, provided that all backward branches are long branches."
	"N.B.  The ^maxSize := N forms are to get around the compiler's long branch
	 limits which are exceeded when each case jumps around the otherwise."
	opcode caseOf: {
		"Noops & Pseudo Ops"
		[Label]					-> [^maxSize := 0].
		[AlignmentNops]		-> [^maxSize := (operands at: 0) - 1].
		[Fill16]					-> [^maxSize := 2].
		[Fill32]					-> [^maxSize := 4].
		[FillFromWord]			-> [^maxSize := 4].
		[Nop]					-> [^maxSize := 1].
		"Specific Control/Data Movement"
		[CDQ]					-> [^maxSize := 1].
		[IDIVR]					-> [^maxSize := 2].
		[IMULRR]				-> [^maxSize := 3].
		[CPUID]					-> [^maxSize := 2].
		[CMPXCHGAwR]			-> [^maxSize := 7].
		[CMPXCHGMwrR]		-> [^maxSize := 8].
		[LFENCE]				-> [^maxSize := 3].
		[MFENCE]				-> [^maxSize := 3].
		[SFENCE]				-> [^maxSize := 3].
		[LOCK]					-> [^maxSize := 1].
		[XCHGAwR]				-> [^maxSize := 6].
		[XCHGMwrR]			-> [^maxSize := 7].
		[XCHGRR]				-> [^maxSize := 2].
		"Control"
		[Call]					-> [^maxSize := 5].
		[JumpR]					-> [^maxSize := 2].
		[Jump]					-> [self resolveJumpTarget. ^maxSize := 5].
		[JumpLong]				-> [self resolveJumpTarget. ^maxSize := 5].
		[JumpZero]				-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpNonZero]			-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpNegative]			-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpNonNegative]		-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpOverflow]			-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpNoOverflow]		-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpCarry]				-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpNoCarry]			-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpLess]				-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpGreaterOrEqual]	-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpGreater]			-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpLessOrEqual]		-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpBelow]				-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpAboveOrEqual]		-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpAbove]			-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpBelowOrEqual]		-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpLongZero]			-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpLongNonZero]		-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpFPEqual]			-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpFPNotEqual]		-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpFPLess]			-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpFPGreaterOrEqual]	-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpFPGreater]			-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpFPLessOrEqual]	-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpFPOrdered]		-> [self resolveJumpTarget. ^maxSize := 6].
		[JumpFPUnordered]		-> [self resolveJumpTarget. ^maxSize := 6].
		[RetN]					-> [^maxSize := (operands at: 0) = 0
													ifTrue: [1]
													ifFalse: [3]].
		"Arithmetic"
		[AddCqR]		-> [^maxSize := (self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[AndCqR]		-> [^maxSize := (self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[CmpCqR]		-> [^maxSize := (self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[OrCqR]			-> [^maxSize := (self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[SubCqR]		-> [^maxSize := (self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [(self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]]].
		[AddCwR]		-> [^maxSize := (self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]].
		[AndCwR]		-> [^maxSize := (self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]].
		[CmpCwR]		-> [^maxSize := (self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]].
		[OrCwR]		-> [^maxSize := (self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]].
		[SubCwR]		-> [^maxSize := (self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]].
		[XorCwR]		-> [^maxSize := (self concreteRegister: (operands at: 1)) = EAX
														ifTrue: [5]
														ifFalse: [6]].
		[AddRR]			-> [^maxSize := 2].
		[AndRR]			-> [^maxSize := 2].
		[CmpRR]		-> [^maxSize := 2].
		[OrRR]			-> [^maxSize := 2].
		[XorRR]			-> [^maxSize := 2].
		[SubRR]			-> [^maxSize := 2].
		[NegateR]		-> [^maxSize := 2].
		[LoadEffectiveAddressMwrR]
						-> [^maxSize := ((self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [6])
										+ ((self concreteRegister: (operands at: 1)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[LogicalShiftLeftCqR]		-> [^maxSize := (operands at: 0) = 1
														ifTrue: [2]
														ifFalse: [3]].
		[LogicalShiftRightCqR]	-> [^maxSize := (operands at: 0) = 1
														ifTrue: [2]
														ifFalse: [3]].
		[ArithmeticShiftRightCqR]	-> [^maxSize := (operands at: 0) = 1
														ifTrue: [2]
														ifFalse: [3]].
		[LogicalShiftLeftRR]		-> [self computeShiftRRSize].
		[LogicalShiftRightRR]		-> [self computeShiftRRSize].
		[ArithmeticShiftRightRR]	-> [self computeShiftRRSize].
		[AddRdRd]				-> [^maxSize := 4].
		[CmpRdRd]				-> [^maxSize := 4].
		[SubRdRd]				-> [^maxSize := 4].
		[MulRdRd]				-> [^maxSize := 4].
		[DivRdRd]				-> [^maxSize := 4].
		[SqrtRd]					-> [^maxSize := 4].
		"Data Movement"
		[MoveCqR]		-> [^maxSize := (operands at: 0) = 0 ifTrue: [2] ifFalse: [5]].
		[MoveCwR]		-> [^maxSize := 5].
		[MoveRR]		-> [^maxSize := 2].
		[MoveRdRd]		-> [^maxSize := 4].
		[MoveAwR]		-> [^maxSize := (self concreteRegister: (operands at: 1)) = EAX
											ifTrue: [5]
											ifFalse: [6]].
		[MoveRAw]		-> [^maxSize := (self concreteRegister: (operands at: 0)) = EAX
											ifTrue: [5]
											ifFalse: [6]].
		[MoveRMwr]		-> [^maxSize := ((self isQuick: (operands at: 1))
											ifTrue: [3]
											ifFalse: [6])
										+ ((self concreteRegister: (operands at: 2)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveRdM64r]	-> [^maxSize := ((self isQuick: (operands at: 1))
											ifTrue: [5]
											ifFalse: [8])
										+ ((self concreteRegister: (operands at: 2)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveMbrR]		-> [^maxSize := ((self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [6])
										+ ((self concreteRegister: (operands at: 1)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveRMbr]		-> [^maxSize := ((self isQuick: (operands at: 1))
											ifTrue: [3]
											ifFalse: [6])
										+ ((self concreteRegister: (operands at: 2)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveM16rR]	-> [^maxSize := ((self isQuick: (operands at: 0))
											ifTrue: [4]
											ifFalse: [7])
										+ ((self concreteRegister: (operands at: 1)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveM64rRd]	-> [^maxSize := ((self isQuick: (operands at: 0))
											ifTrue: [5]
											ifFalse: [8])
										+ ((self concreteRegister: (operands at: 1)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveMwrR]		-> [^maxSize := ((self isQuick: (operands at: 0))
											ifTrue: [3]
											ifFalse: [6])
										+ ((self concreteRegister: (operands at: 1)) = ESP
											ifTrue: [1]
											ifFalse: [0])].
		[MoveXbrRR]	-> [self assert: (self concreteRegister: (operands at: 0)) ~= ESP.
							^maxSize := (self concreteRegister: (operands at: 1)) = EBP
											ifTrue: [5]
											ifFalse: [4]].
		[MoveRXbrR]	->	[self assert: (self concreteRegister: (operands at: 1)) ~= ESP.
							^maxSize := (self concreteRegister: (operands at: 2)) = EBP
											ifTrue: [4]
											ifFalse: [3]].
		[MoveXwrRR]	-> [self assert: (self concreteRegister: (operands at: 0)) ~= ESP.
							^maxSize := (self concreteRegister: (operands at: 1)) = EBP
											ifTrue: [4]
											ifFalse: [3]].
		[MoveRXwrR]	-> [self assert: (self concreteRegister: (operands at: 1)) ~= ESP.
							^maxSize := (self concreteRegister: (operands at: 2)) = EBP
											ifTrue: [4]
											ifFalse: [3]].
		[PopR]			-> [^maxSize := 1].
		[PushR]			-> [^maxSize := 1].
		[PushCw]		-> [^maxSize := 5].
		[PrefetchAw]	-> [^maxSize := self hasSSEInstructions ifTrue: [7] ifFalse: [0]].
		"Conversion"
		[ConvertRRd]	-> [^maxSize := 4] }.
	^0 "to keep C compiler quiet"
]

{ #category : #'generate machine code' }
CogIA32Compiler >> computeShiftRRSize [
	"On the x86 the only instructions that shift by the value of a
	 register require the shift count to be  in %ecx.  So we may
	 have to use swap instructions to get the count into ecx."
	| shiftCountReg |
	shiftCountReg := self concreteRegister: (operands at: 0).
	shiftCountReg = ECX ifTrue:
		[^maxSize := 2].
	^maxSize := shiftCountReg = EAX
					ifTrue: [1 "XCHG EAX,r2" + 2 "Sxx" + 1 "XCHG EAX,r2"]
					ifFalse: [2 "XCHG r1,r2" + 2 "Sxx" + 2 "XCHG r1,r2"]
]

{ #category : #encoding }
CogIA32Compiler >> concreteDPFPRegister: registerIndex [
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

{ #category : #encoding }
CogIA32Compiler >> concreteRegister: registerIndex [
	 "Map a possibly abstract register into a concrete one.  Abstract registers
	  (defined in CogAbstractOpcodes) are all negative.  If registerIndex is
	 negative assume it is an abstract register.

	[1] IA-32 Intel® Architecture Software Developer's Manual Volume 2A: Instruction Set Reference, A-M


	N.B. EAX ECX & EDX are caller-save (scratch) registers.  Hence we use ECX for class and EDC for
		receiver/result since these are written in all normal sends.  EBX ESI & EDI are callee-save."

	^registerIndex
		caseOf: {
			[TempReg]				-> [EAX].
			[ClassReg]				-> [ECX].
			[ReceiverResultReg]	-> [EDX].
			[SendNumArgsReg]		-> [EBX].
			[SPReg]					-> [ESP].
			[FPReg]					-> [EBP].
			[Arg0Reg]				-> [ESI].
			[Arg1Reg]				-> [EDI] }
		otherwise:
			[self assert: (registerIndex between: EAX and: EDI).
			 registerIndex]
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeAddCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
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
	reg := self concreteRegister: (operands at: 1).
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
CogIA32Compiler >> concretizeAddRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regLHS := self concreteRegister: (operands at: 0).
	regRHS := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: 16r03;
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
	reg := self concreteRegister: (operands at: 1).
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
	reg := self concreteRegister: (operands at: 1).
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
CogIA32Compiler >> concretizeAndRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regLHS := self concreteRegister: (operands at: 0).
	regRHS := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: 16r23;
		at: 1 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeArithmeticShiftRightCqR [
	<inline: true>
	| shiftCount reg |
	shiftCount := (operands at: 0) min: 31.
	reg := self concreteRegister: (operands at: 1).
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
	shiftCountReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
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
CogIA32Compiler >> concretizeAt: actualAddress [
	"Generate concrete machine code for the instruction at actualAddress,
	 setting machineCodeSize, and answer the following address."

	address := actualAddress.
	self dispatchConcretize.
	self assert: (maxSize = nil or: [maxSize >= machineCodeSize]).
	^actualAddress + machineCodeSize
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeCDQ [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	machineCode at: 0 put: 16r99.
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeCMPXCHGAwR [
	<inline: true>
	| addressOperand reg |
	addressOperand := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
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
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
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
CogIA32Compiler >> concretizeCmpCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
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
	reg := self concreteRegister: (operands at: 1).
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
CogIA32Compiler >> concretizeCmpRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	"CmpRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	regRHS := self concreteRegister: (operands at: 0).
	regLHS := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: 16r39;
		at: 1 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeCmpRdRd [
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
	<inline: true>
	| srcReg destReg |
	srcReg := self concreteRegister: (operands at:0).
	destReg := self concreteDPFPRegister: (operands at: 1).
	machineCode
		at: 0 put: 16rF2;
		at: 1 put: 16r0F;
		at: 2 put: 16r2A;
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
CogIA32Compiler >> concretizeFill16 [
	<inline: true>
	| word |
	<var: #word type: 'unsigned short'>
	self assert: maxSize == 2.
	word := operands at: 0.
	machineCode at: 0 put: (word bitAnd: 16rFF).
	machineCode at: 1 put: word >> 8.
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeFill32 [
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
CogIA32Compiler >> concretizeFillFromWord [
	<inline: true>
	| word |
	<var: #word type: #'unsigned long'>
	self assert: maxSize == 4.
	word := (operands at: 0) + (operands at: 1).
	0 to: 3 do:
		[:i|
		machineCode at: i put: (word bitAnd: 16rFF).
		word := word >> 8].
	^machineCodeSize := maxSize
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeIDIVR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regDivisor |
	regDivisor := self concreteRegister: (operands at: 0).
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
	reg := self concreteRegister: (operands at: 0).
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
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
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
	reg := self concreteRegister: (operands at: 1).
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
	shiftCountReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
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
	reg := self concreteRegister: (operands at: 1).
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
CogIA32Compiler >> concretizeMoveAwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg |
	addressOperand := operands at: 0.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	reg := self concreteRegister: (operands at: 1).
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
	reg := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: 16r31;
		at: 1 put: (self mod: ModReg RM: reg RO: reg).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveCwR [
	"Will get inlined into concretizeAt: switch.
	 Note that for quick constants, xor reg,reg, movq r8 may be shorter.
	 We don't consider it worthwhile for other  than 0."
	<inline: true>
	| value |
	value := operands at: 0.
	machineCode
		at: 0 put: 16rB8 + (self concreteRegister: (operands at: 1));
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
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
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
CogIA32Compiler >> concretizeMoveM64rRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteDPFPRegister: (operands at: 2).
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
CogIA32Compiler >> concretizeMoveMbrR [
	"N.B. The Cogit compiler makes no assumption about the upper bits being set to zero.
	 It will clear the register before hand if necessary."
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[machineCode
				at: 0 put: 16r8A;
				at: 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
				at: 2 put: (offset bitAnd: 16rFF).
			 ^machineCodeSize := 3].
		machineCode
			at: 0 put: 16r8A;
			at: 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
			at: 2 put: (offset bitAnd: 16rFF);
			at: 3 put: (offset >> 8 bitAnd: 16rFF);
			at: 4 put: (offset >> 16 bitAnd: 16rFF);
			at: 5 put: (offset >> 24 bitAnd: 16rFF).
		^machineCodeSize := 6].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[machineCode
			at: 0 put: 16r8A;
			at: 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg);
			at: 2 put: (self s: SIB1 i: 4 b: srcReg);
			at: 3 put: (offset bitAnd: 16rFF).
		 ^machineCodeSize := 4].
	machineCode
		at: 0 put: 16r8A;
		at: 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg);
		at: 2 put: (self s: SIB1 i: 4 b: srcReg);
		at: 3 put: (offset bitAnd: 16rFF);
		at: 4 put: (offset >> 8 bitAnd: 16rFF);
		at: 5 put: (offset >> 16 bitAnd: 16rFF);
		at: 6 put: (offset >> 24 bitAnd: 16rFF).
	^machineCodeSize := 7
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveMwrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
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

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveRAw [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg |
	reg := self concreteRegister: (operands at: 0).
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
CogIA32Compiler >> concretizeMoveRMbr [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 1.
	srcReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 2).
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
	srcReg := self concreteRegister: (operands at: 0).
	offset := operands at: 1.
	destReg := self concreteRegister: (operands at: 2).
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
CogIA32Compiler >> concretizeMoveRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg destReg |
	srcReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: 16r89;
		at: 1 put: (self mod: ModReg RM: destReg RO: srcReg).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveRXbrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| src index base |
	src := self concreteRegister: (operands at: 0).
	index := self concreteRegister: (operands at: 1).
	base := self concreteRegister: (operands at: 2).
	base ~= EBP ifTrue:
		[machineCode
			at: 0 put: 16r88;
			at: 1 put: (self mod: ModRegInd RM: 4 RO: src);
			at: 2 put: (self s: SIB1 i: index b: base).
		 ^machineCodeSize := 3].
	machineCode
		at: 0 put: 16r88;
		at: 1 put: (self mod: ModRegRegDisp8 RM: 4 RO: src);
		at: 2 put: (self s: SIB1 i: index b: base);
		at: 3 put: 0.
	 ^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeMoveRXwrR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base src |
	src := self concreteRegister: (operands at: 0).
	index := self concreteRegister: (operands at: 1).
	base := self concreteRegister: (operands at: 2).
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
	srcReg := self concreteDPFPRegister: (operands at: 0).
	offset := operands at: 1.
	destReg := self concreteRegister: (operands at: 2).
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
CogIA32Compiler >> concretizeMoveXbrRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base dest |
	index := self concreteRegister: (operands at: 0).
	base := self concreteRegister: (operands at: 1).
	dest := self concreteRegister: (operands at: 2).
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
	index := self concreteRegister: (operands at: 0).
	base := self concreteRegister: (operands at: 1).
	dest := self concreteRegister: (operands at: 2).
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
	reg1 := self concreteRegister: (operands at: 0).
	reg2 := self concreteRegister: (operands at: 1).
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
	reg := self concreteRegister: (operands at: 0).
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
CogIA32Compiler >> concretizeOrCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| mask reg |
	mask := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
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
	reg := self concreteRegister: (operands at: 1).
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
CogIA32Compiler >> concretizeOrRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regLHS := self concreteRegister: (operands at: 0).
	regRHS := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: 16r0B;
		at: 1 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizePopR [
	<inline: true>
	machineCode at: 0 put: 16r58 + (self concreteRegister: (operands at: 0)).
	^machineCodeSize := 1
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizePrefetchAw [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand |
	machineCodeSize := maxSize.
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
	^maxSize
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
	machineCode at: 0 put: 16r50 + (self concreteRegister: (operands at: 0)).
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
CogIA32Compiler >> concretizeSEE2OpRdRd: opCode [
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
CogIA32Compiler >> concretizeSqrtRd [
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
CogIA32Compiler >> concretizeSubCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
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
	reg := self concreteRegister: (operands at: 1).
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
CogIA32Compiler >> concretizeSubRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regLHS := self concreteRegister: (operands at: 0).
	regRHS := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: 16r2B;
		at: 1 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> concretizeXCHGAwR [
	<inline: true>
	| addressOperand reg |
	addressOperand := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
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
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
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
	reg1 := self concreteRegister: (operands at: 0).
	reg2 := self concreteRegister: (operands at: 1).
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
	reg := self concreteRegister: (operands at: 1).
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
CogIA32Compiler >> concretizeXorRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regLHS := self concreteRegister: (operands at: 0).
	regRHS := self concreteRegister: (operands at: 1).
	machineCode
		at: 0 put: 16r33;
		at: 1 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^machineCodeSize := 2
]

{ #category : #'generate machine code' }
CogIA32Compiler >> dispatchConcretize [
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
		[JumpR]					-> [^self concretizeJumpR].
		[JumpLong]				-> [^self concretizeJumpLong].
		[JumpLongZero]		-> [^self concretizeConditionalJumpLong: 16r4].
		[JumpLongNonZero]	-> [^self concretizeConditionalJumpLong: 16r5].
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
		"Arithmetic"
		[AddCqR]					-> [^self concretizeAddCqR].
		[AddCwR]					-> [^self concretizeAddCwR].
		[AddRR]						-> [^self concretizeAddRR].
		[AddRdRd]					-> [^self concretizeSEE2OpRdRd: 16r58].
		[AndCqR]					-> [^self concretizeAndCqR].
		[AndCwR]					-> [^self concretizeAndCwR].
		[AndRR]						-> [^self concretizeAndRR].
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
		[PushCw]			-> [^self concretizePushCw].
		[PrefetchAw]		-> [^self concretizePrefetchAw].
		"Conversion"
		[ConvertRRd]		-> [^self concretizeConvertRRd] }
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> flushICacheFrom: startAddress "<Integer>" to: endAddress [ "<Integer>"
	<cmacro: '(me,startAddress,endAddress) 0'>
	"On Intel processors where code and data have the same linear address, no
	 special action is required to flush the instruciton cache.  One only needs to
	 execute a serializing instruction (e.g. CPUID) if code and data are at different
	 virtual addresses (e.g. a debugger using memory-mapping to access a debugee).
	 Using the macro avoids an unnecessary call."
	self halt: #ceFlushICache
]

{ #category : #'abstract instructions' }
CogIA32Compiler >> genDivR: abstractRegDivisor R: abstractRegDividend Quo: abstractRegQuotient Rem: abstractRegRemainder [
	| rDividend rDivisor rQuotient rRemainder saveRestoreEAX saveRestoreEDX saveRestoreExchanged |
	self assert: abstractRegDividend ~= abstractRegDivisor.
	self assert: abstractRegQuotient ~= abstractRegRemainder.
	rDividend := self concreteRegister: abstractRegDividend.
	rDivisor := self concreteRegister: abstractRegDivisor.
	rQuotient := self concreteRegister: abstractRegQuotient.
	rRemainder := self concreteRegister: abstractRegRemainder.
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

{ #category : #assertions }
CogIA32Compiler >> genGetLeafCallStackPointerFunction [
	cogit MoveR: ESP R: EAX.
	cogit RetN: 0
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

{ #category : #'abstract instructions' }
CogIA32Compiler >> genMulR: regSource R: regDest [
	cogit gen: IMULRR operand: regSource operand: regDest
]

{ #category : #abi }
CogIA32Compiler >> genPassConst: constant asArgument: zeroRelativeArgIndex [
	cogit
		MoveCq: constant R: TempReg;
		PushR: TempReg.
	^0
]

{ #category : #abi }
CogIA32Compiler >> genPassReg: abstractRegister asArgument: zeroRelativeArgIndex [
	cogit PushR: abstractRegister.
	^0
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
CogIA32Compiler >> genPushRegisterArgsForNumArgs: numArgs [
	"Ensure that the register args are pushed before the retpc for arity <= self numRegArgs."
	"This won't be as clumsy on a RISC.  But putting the receiver and
	 args above the return address means the CoInterpreter has a
	 single machine-code frame format which saves us a lot of work."
	numArgs <= cogit numRegArgs ifTrue:
		[self assert: cogit numRegArgs <= 2.
		 false "these two variants show the same performance on Intel Core i7, but the second one may be shorter."
			ifTrue:
				[cogit MoveMw: 0 r: SPReg R: TempReg. "Save return address"
				 numArgs > 0 ifTrue:
					[cogit PushR: Arg0Reg.
					 numArgs > 1 ifTrue:
						[cogit PushR: Arg1Reg]].
				 cogit PushR: TempReg.
				 cogit MoveR: ReceiverResultReg Mw: objectMemory wordSize * (1 + numArgs) r: SPReg]
			ifFalse:
				[cogit MoveMw: 0 r: SPReg R: TempReg. "Save return address"
				 cogit MoveR: ReceiverResultReg Mw: 0 r: SPReg.
				 numArgs > 0 ifTrue:
					[cogit PushR: Arg0Reg.
					 numArgs > 1 ifTrue:
						[cogit PushR: Arg1Reg]].
				cogit PushR: TempReg]] "Restore return address"
]

{ #category : #abi }
CogIA32Compiler >> genRemoveNArgsFromStack: n [ 
	cogit AddCq: n * 4 R: ESP.
	^0
]

{ #category : #abi }
CogIA32Compiler >> genRestoreRegs [
	cogit
		PopR: EAX;
		PopR: EBX;
		PopR: ECX;
		PopR: EDX;
		PopR: ESI;
		PopR: EDI.
	^0
]

{ #category : #abi }
CogIA32Compiler >> genRestoreRegsExcept: abstractReg [
	| realReg |
	realReg := self concreteRegister: abstractReg.
	realReg = EAX ifTrue: [cogit AddCq: 4 R: ESP] ifFalse: [cogit PopR: EAX].
	realReg = EBX ifTrue: [cogit AddCq: 4 R: ESP] ifFalse: [cogit PopR: EBX].
	realReg = ECX ifTrue: [cogit AddCq: 4 R: ESP] ifFalse: [cogit PopR: ECX].
	realReg = EDX ifTrue: [cogit AddCq: 4 R: ESP] ifFalse: [cogit PopR: EDX].
	realReg = ESI   ifTrue: [cogit AddCq: 4 R: ESP] ifFalse: [cogit PopR: ESI].
	realReg = EDI   ifTrue: [cogit AddCq: 4 R: ESP] ifFalse: [cogit PopR: EDI].
	^0
]

{ #category : #abi }
CogIA32Compiler >> genSaveRegisters [
	"Save the general purpose registers for a trampoline call."
	cogit
		PushR: EDI;
		PushR: ESI;
		PushR: EDX;
		PushR: ECX;
		PushR: EBX;
		PushR: EAX.
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
CogIA32Compiler >> hasDoublePrecisionFloatingPointSupport [
	"We can generate dpfp support if the processor has SSE2 instructions."
	^self hasSSE2Instructions
]

{ #category : #testing }
CogIA32Compiler >> hasLinkRegister [
	^false
]

{ #category : #testing }
CogIA32Compiler >> hasPCDependentInstructions [
	"Answer whether the concrete machine code contains pc-dependent
	 instructions, such as the IA32/x86's short and long relative jumps
	 and the EMT64/x86-64's pc-relative addressing mode.  Such
	 instructions require an extra pass to generate them correctly."
	^true
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
	<inline: true>
	^false
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> implicitReceiveCacheAt: callSiteReturnAddress [
	"Answer the implicit receiver cache for the return address
	 of a call to the ceImplicitReceiverTrampoline."
	<option: #NewspeakVM>
	<var: #callSiteReturnAddress type: #'char *'>
	<inline: false>
	^self literalBeforeFollowingAddress: callSiteReturnAddress asUnsignedInteger - 10
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
			[16rEB] ->	[2] "short unconditional jump" }
]

{ #category : #testing }
CogIA32Compiler >> isBigEndian [
	^false
]

{ #category : #testing }
CogIA32Compiler >> isCallPreceedingReturnPC: mcpc [
	"Assuming mcpc is a return pc answer if the instruction before it is a call."
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
	<var: #operand type: #'unsigned long'>
	^operand signedIntFromLong between: -128 and: 127
]

{ #category : #accessing }
CogIA32Compiler >> jmpTarget: anAbstractInstruction [
	"Set the target of a jump instruction.  These all have the target in the first operand.
	 Override to cope with JumpFPNotEqual where because if IEEE NaN conformance and
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
	^5
]

{ #category : #accessing }
CogIA32Compiler >> jumpLongConditionalByteSize [
	^6
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> jumpLongTargetBeforeFollowingAddress: mcpc [ 
	"Answer the target address for the long jump immediately preceeding mcpc"
	^self callTargetFromReturnAddress: mcpc
]

{ #category : #accessing }
CogIA32Compiler >> jumpShortByteSize [
	^2
]

{ #category : #disassembly }
CogIA32Compiler >> jumpTargetPCAt: pc [
	<returnTypeC: #sqInt>
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
	"Answer the literal embedded in the instruction immediately preceeding followingAddress."
	^  ((objectMemory byteAt: followingAddress - 1) << 24)
	+  ((objectMemory byteAt: followingAddress - 2) << 16)
	+  ((objectMemory byteAt: followingAddress - 3) << 8)
	+   (objectMemory byteAt: followingAddress - 4)
]

{ #category : #accessing }
CogIA32Compiler >> loadLiteralByteSize [
	"Answer the byte size of a MoveCwR opcode's corresponding machine code"
	^5
]

{ #category : #'generate machine code' }
CogIA32Compiler >> machineCodeBytes [
	"Answer the maximum number of bytes of machine code generated for any abstract instruction.
	 e.g. lock movsd  0x400(%esp),%xmm4 => f0 f2 0f 10 a4 24 00 04 00 00"
	^10
]

{ #category : #'abstract instructions' }
CogIA32Compiler >> maybeEstablishVarBase [
	"The receiver does not have a VarBaseReg; do nothing."
]

{ #category : #encoding }
CogIA32Compiler >> mod: mod RM: regMode RO: regOpcode [
	^mod << 6 + (regOpcode << 3) + regMode
]

{ #category : #'generate machine code' }
CogIA32Compiler >> nopsFrom: startAddr to: endAddr [
	startAddr to: endAddr do:
		[:p| objectMemory byteAt: p put: 16r90]
]

{ #category : #'feature detection' }
CogIA32Compiler >> numCheckFeaturesOpcodes [
	"Answer the number of opcodes required to compile the CPUID call to extract the extended features information."
	^11
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

{ #category : #abi }
CogIA32Compiler >> numberOfSaveableRegisters [
	"Answer the number of registers to be saved in a trampoline call that saves registers.
	 See genSaveRegisters"
	<cmacro: '(self) 6'>
	^6
]

{ #category : #'generate machine code' }
CogIA32Compiler >> padIfPossibleWithNopsFrom: startAddr to: endAddr [
	self nopsFrom: startAddr to: endAddr
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
CogIA32Compiler >> relocateJumpBeforeFollowingAddress: pc by: delta [
	self relocateCallBeforeReturnPC: pc by: delta
]

{ #category : #'inline cacheing' }
CogIA32Compiler >> relocateMethodReferenceBeforeAddress: pc by: delta [
	self relocateCallBeforeReturnPC: pc by: delta
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
	self assert: (self callTargetFromReturnAddress: callSiteReturnAddress) signedIntToLong = callTargetAddress.
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
	self assert: (self callTargetFromReturnAddress: callSiteReturnAddress) signedIntToLong = callTargetAddress.
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
	"OF flag only guaranteed to be set for 1-bit shifts.  See [1] p 490"
	^(opcode = ArithmeticShiftRightCqR or: [opcode = LogicalShiftLeftCqR])
	   and: [(operands at: 0) = 1]
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
	 span of a jump to a preceeding instruction or to an absolute address is
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
								[opcode = JumpLong
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

{ #category : #'inline cacheing' }
CogIA32Compiler >> storeLiteral: literal beforeFollowingAddress: followingAddress [
	"Rewrite the literal in the instruction immediately preceeding followingAddress."
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
	<cmacro: '(inst,byteAddress) longAt(byteAddress)'>
	^objectMemory unalignedLongAt: byteAddress
]

{ #category : #'memory access' }
CogIA32Compiler >> unalignedLongAt: byteAddress put: aWord [
	<cmacro: '(inst,byteAddress,aWord) longAtput(byteAddress,aWord)'>
	^objectMemory unalignedLongAt: byteAddress put: aWord
]

{ #category : #accessing }
CogIA32Compiler >> unsignedShortAt: byteAddress [
	^(objectMemory byteAt: byteAddress) + ((objectMemory byteAt: byteAddress + 1) bitShift: 8)
]
