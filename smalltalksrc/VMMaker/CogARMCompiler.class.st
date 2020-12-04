"
I generate ARM instructions from CogAbstractInstructions.  For reference see
http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.set.architecture/index.html

The Architecture Reference Manual used is that of version 5, which includes some version 6 instructions. Of those, only pld is used(for PrefetchAw).

This class does not take any special action to flush the instruction cache on instruction-modification.
"
Class {
	#name : #CogARMCompiler,
	#superclass : #CogAbstractInstruction,
	#instVars : [
		'conditionOrNil'
	],
	#classVars : [
		'AL',
		'AddOpcode',
		'AndOpcode',
		'BicOpcode',
		'CArg0Reg',
		'CArg1Reg',
		'CArg2Reg',
		'CArg3Reg',
		'CC',
		'CMPSMULL',
		'CPSRReg',
		'CS',
		'CmpNotOpcode',
		'CmpOpcode',
		'ConcreteIPReg',
		'ConcretePCReg',
		'ConcreteVarBaseReg',
		'D0',
		'D1',
		'D2',
		'D3',
		'D4',
		'D5',
		'D6',
		'D7',
		'EQ',
		'GE',
		'GT',
		'HI',
		'LDMFD',
		'LE',
		'LR',
		'LS',
		'LT',
		'MI',
		'MRS',
		'MSR',
		'MoveNotOpcode',
		'MoveOpcode',
		'NE',
		'OrOpcode',
		'OverflowFlag',
		'PC',
		'PL',
		'PopLDM',
		'PushSTM',
		'R0',
		'R1',
		'R10',
		'R11',
		'R12',
		'R2',
		'R3',
		'R4',
		'R5',
		'R6',
		'R7',
		'R8',
		'R9',
		'RsbOpcode',
		'SMLALOpcode',
		'SMULL',
		'SP',
		'STMFD',
		'SubOpcode',
		'TstOpcode',
		'VC',
		'VS',
		'XorOpcode'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #accessing }
CogARMCompiler class >> IPReg [
	"Answer the number of the general temp reg in the ARM APCS convention, IP"
	^ConcreteIPReg
]

{ #category : #translation }
CogARMCompiler class >> ISA [
	"Answer the name of the ISA the receiver implements."
	^#ARMv5
]

{ #category : #accessing }
CogARMCompiler class >> PCReg [
	^ConcretePCReg
]

{ #category : #accessing }
CogARMCompiler class >> VarBaseReg [
	"Answer the number of the reg we use to hold the base address of CoInterpreter variables"
	^ConcreteVarBaseReg
]

{ #category : #translation }
CogARMCompiler class >> defaultCompilerClass [
	^CogOutOfLineLiteralsARMCompiler
]

{ #category : #translation }
CogARMCompiler class >> filteredInstVarNames [
	"Edit such that conditionOrNil is amongst the char size vars opcode machineCodeSize and maxSize."
	^(super filteredInstVarNames copyWithout: 'conditionOrNil')
		copyReplaceFrom: 5 to: 4 with: #('conditionOrNil')
]

{ #category : #translation }
CogARMCompiler class >> identifyingPredefinedMacros [
	^#('__ARM_ARCH_5__' '__ARM_ARCH_6__' '__ARM_ARCH_7__' '__arm__' '__arm32__' 'ARM32' '_M_ARM')
]

{ #category : #'class initialization' }
CogARMCompiler class >> initialize [

	"Initialize various ARM instruction-related constants."
	"CogARMCompiler initialize"

	super initialize.
	self ~~ CogARMCompiler ifTrue: [^self].

	"ARM general registers"
	R0 := 0.
	R1 := 1.
	R2 := 2.
	R3 := 3.
	R4 := 4.
	R5 := 5.
	R6 := 6.
	R7 := 7.
	R8 := 8.
	R9 := 9.
	R10 := 10.
	R11 := 11.
	R12 := 12.
	SP := 13.
	LR := 14.
	PC := 15.
	"ARM VFP Double precision floating point registers"
	D0 := 0.
	D1 := 1.
	D2 := 2.
	D3 := 3.
	D4 := 4.
	D5 := 5.
	D6 := 6.
	D7 := 7.

	CArg0Reg := 0.
	CArg1Reg := 1.
	CArg2Reg := 2.
	CArg3Reg := 3.

	ConcreteVarBaseReg := 10.
	ConcreteIPReg := 12. "IP, The Intra-Procedure-call scratch register."
	ConcretePCReg := 15.

	"Condition Codes. Note that cc=16rF is NOT ALLOWED as a condition; it specifies an extension instruction. See e.g.ARM_ARM v5 DDI01001.pdf A3.2.1"
	EQ := 0.
	NE := 1.
	CS := 2.
	CC := 3.
	MI := 4.
	PL := 5.
	VS := 6.
	VC := 7.
	HI := 8.
	LS := 9.
	GE := 10.
	LT := 11.
	GT := 12.
	LE := 13.
	AL := 14.

	"Table A3-2 in sec A3.4 Data-processing instructions of the AARM."
	AddOpcode := 	4.
	AndOpcode := 0.
	BicOpcode := 14.
	CmpOpcode := 10.
	CmpNotOpcode := 11.
	MoveOpcode := 13.
	MoveNotOpcode := 15.
	OrOpcode := 12.
	RsbOpcode := 3.
	SMLALOpcode := 7.
	SubOpcode := 2.
	TstOpcode := 8.
	XorOpcode := 1.

	CPSRReg := 16.
	OverflowFlag := 1 << 28.

	"Specific instructions"
	self
		initializeSpecificOpcodes: #(SMULL MSR MRS PopLDM PushSTM LDMFD STMFD CMPSMULL)
		in: thisContext method
]

{ #category : #'class initialization' }
CogARMCompiler class >> initializeAbstractRegisters [
	"Assign the abstract registers with the identities/indices of the relevant concrete registers."

	super initializeAbstractRegisters.

	"According to IHI0042E ARM Architecture Procedure Calling Standard, in section 5.1.1:
		A subroutine must preserve the contents of the registers r4-r8, r10, r11 and SP (and r9 in PCS variants that designate r9 as v6).
	 SP = r13, so the callee-saved regs are r4-r8 & r10-r12.
	 The caller-saved registers are those that are not callee-saved and not reserved for hardware/abi uses,
	 i..e r0-r3, r9 & r12.
	 We exclude registers 0 & 1 (TempReg/CArg0Reg & CArg1Reg) from the CallerSavedRegisterMask because we only
	 use them for argument passing and so never want to save and restore them.  In fact restoring TempReg/CArg0Reg
	 would overwrite function results, so it shouldn't be included under any circumstances."

	CallerSavedRegisterMask := self registerMaskFor: "0 and: 1 and:" 2 and: 3 and: 9 and: 12.

	TempReg			:= R0.
	ClassReg			:= R2.
	ReceiverResultReg	:= R5.
	SendNumArgsReg	:= R6.
	SPReg				:= SP. "a.k.a. R13" self assert: SP = 13.
	FPReg				:= R11.
	Arg0Reg			:= R3. "overlaps with last C arg reg"
	Arg1Reg			:= R4.
	Extra0Reg			:= R7.  "These are callee saved registers"
	Extra1Reg			:= R8.
	Extra2Reg			:= R9.
	VarBaseReg		:= R10.	"Must be callee saved" self assert: ConcreteVarBaseReg = R10.
	RISCTempReg		:= R12.	"a.k.a. IP" self assert: ConcreteIPReg = R12.
	LinkReg				:= LR. "R14"
	PCReg				:= PC. "R15"	

	NumRegisters := 16.

	DPFPReg0			:= D0.
	DPFPReg1			:= D1.
	DPFPReg2			:= D2.
	DPFPReg3			:= D3.
	DPFPReg4			:= D4.
	DPFPReg5			:= D5.
	DPFPReg6			:= D6.
	DPFPReg7			:= D7.

	NumFloatRegisters := 8
]

{ #category : #testing }
CogARMCompiler class >> isAbstract [
	^self == CogARMCompiler
]

{ #category : #testing }
CogARMCompiler class >> isRISCTempRegister: reg [
	"For tests to filter-out bogus values left in the RISCTempRegister, if any."
	^reg = ConcreteIPReg
]

{ #category : #translation }
CogARMCompiler class >> machineCodeDeclaration [
	"Answer the declaration for the machineCode array.
	 ARM instructions are 32-bits in length."
	^{#'unsigned int'. '[', self basicNew machineCodeWords printString, ']'}
]

{ #category : #accessing }
CogARMCompiler class >> orOpcode [
	^OrOpcode
]

{ #category : #'class initialization' }
CogARMCompiler class >> specificOpcodes [
	"Answer the processor-specific opcodes for this class.
	 They're all in an Array literal in the initialize method."
	^(self class >> #initialize) literals detect: [:l| l isArray and: [l includes: #LDMFD]]
]

{ #category : #translation }
CogARMCompiler class >> wordSize [
	"This is a 32-bit ISA"
	^4
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> add: destReg rn: srcReg imm: immediate ror: rot [
"Remember the ROR is doubled by the cpu so use 30>>1 etc.
	ADD destReg, srcReg, #immediate ROR #rot - ARM_ARM v7 DDI10406 p. A8-23"

	^self type: 1 op: AddOpcode set: 0 rn: srcReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate)
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> add: destReg rn: srcReg rm: addReg [
"return an ADD destReg, srcReg, addReg instruction
	ADD destReg, srcReg, addReg - ARM_ARM v7 DDI10406 p. A8-24"

	^self type: 0 op: AddOpcode set: 0 rn: srcReg rd: destReg shifterOperand: addReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> adds: destReg rn: srcReg imm: immediate ror: rot [
"Remember the ROR is doubled by the cpu so use 30>>1 etc
	ADDS destReg, srcReg, #immediate ROR #rot - ARM_ARM v7 DDI10406 p. A8-23"

	^self type: 1 op: AddOpcode set: 1 rn: srcReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate)
]

{ #category : #simulation }
CogARMCompiler >> aeabiDiv: dividend Mod: divisor [
"simulate the __aeabi_idivmod call"
	<doNotGenerate>
	| proc result dividendAsInteger divisorAsInteger|
	proc := cogit processor.

	dividendAsInteger := proc convertInternalToInteger: dividend.
	divisorAsInteger := proc convertInternalToInteger: divisor.
	
	proc r0: (result := proc convertIntegerToInternal: (dividendAsInteger quo: divisorAsInteger)).
	proc r1: (proc convertIntegerToInternal: (dividendAsInteger rem: divisorAsInteger)).
	^result
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> aeabiDivModFunctionAddr [
	"Answer the address of the __aeabi_idivmod() call provided by the ARM low level libs to do an integer divide that returns the quo in R0 and rem in R1.
	 A word on the somewhat strange usage of idivmod herein; we need a declaration for the _aeabi_idivmod helper function, despite the fact that in a simple C program test, you don't.
	 To get that declaration we need a variable to hang it off; thus the non-existent var idivmod, and in simulation we need to simulate it, which is what aeabiDiv:Mod: does."
	<returnTypeC: #usqInt>
	<var: #idivmod declareC: 'extern void __aeabi_idivmod(int dividend, int divisor)'>

	^self cCode: '(usqInt)__aeabi_idivmod' inSmalltalk:[#aeabiDiv:Mod:]
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> and: destReg rn: srcReg imm: immediate ror: rot [
"Remember the ROR is doubled by the cpu so use 30>>1 etc
	AND destReg, srcReg, #immediate ROR #rot - ARM_ARM v7 DDI10406 p. A8-34"

	^self type: 1 op: AndOpcode set: 0 rn: srcReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate)
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> ands: destReg rn: srcReg imm: immediate ror: rot [
"Remember the ROR is doubled by the cpu so use 30>>1 etc
	ANDS destReg, srcReg, #immediate ROR #rot - ARM_ARM v7 DDI10406 p. A8-34"

	^self type: 1 op: AndOpcode set: 1 rn: srcReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate)
]

{ #category : #'register allocation' }
CogARMCompiler >> availableRegisterOrNoneFor: liveRegsMask [
	"Answer an unused abstract register in the liveRegMask.
	 Subclasses with more registers can override to answer them.
	 N.B. Do /not/ allocate TempReg."
	<returnTypeC: #sqInt>
	(cogit register: Extra0Reg isInMask: liveRegsMask) ifFalse:
		[^Extra0Reg].
	(cogit register: Extra1Reg isInMask: liveRegsMask) ifFalse:
		[^Extra1Reg].
	(cogit register: Extra2Reg isInMask: liveRegsMask) ifFalse:
		[^Extra2Reg].
	^super availableRegisterOrNoneFor: liveRegsMask
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> b: offset [
"return a B offset instruction; offset is signed 24bits of WORD offset, so +_32Mbyte range
	B offset - ARM_ARM v7 DDI10406 pp. A8-44-5"
	^self cond: AL br: 0 offset: offset

]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> bics: destReg rn: srcReg imm: immediate ror: rot [
"Remember the ROR is doubled by the cpu so use 30>>1 etc
	BICS destReg, srcReg, #immediate ROR #rot - ARM_ARM v7 DDI10406 pp. A8-50-1"

	^self type: 1 op: BicOpcode set: 1 rn: srcReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate)
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> bl: offset [
"return a BL offset instruction; offset is signed 24bits of WORD offset, so +_32Mbyte range. Return address is in LR
	BL offset - ARM_ARM v7 DDI10406 pp. A8-58-9"
	^self cond: AL br: 1 offset: offset

]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> blx: targetReg [
	"Branch&link to the address in targetReg. Return address is in LR
	BLX targetReg - ARM_ARM v7 DDI10406 pp. A8-60-1"
	<inline: true>
	^self cond: AL bx: 1 target: targetReg

]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> bx: targetReg [
	"Branch to address in targetReg. BX targetReg
	BX targetReg  - ARM_ARM v7 DDI10406 pp. A8-62-3"
	<inline: true>
	^self cond: AL bx: 0 target: targetReg

]

{ #category : #testing }
CogARMCompiler >> byteReadsZeroExtend [
	^true
]

{ #category : #abi }
CogARMCompiler >> cResultRegister [
	"Answer the register through which C funcitons return integral results."
	<inline: true>
	^R0
]

{ #category : #accessing }
CogARMCompiler >> cStackPointer [
	
	^ SP
]

{ #category : #accessing }
CogARMCompiler >> callInstructionByteSize [
	"ARM calls and jumps span +/- 32 mb, more than enough for intra-zone calls and jumps."
	^4
]

{ #category : #'inline cacheing' }
CogARMCompiler >> callTargetFromReturnAddress: callSiteReturnAddress [
	"Answer the address that the call immediately preceding callSiteReturnAddress will jump to."
	"this is also used by #jumpLongTargetBeforeFollowingAddress:."
	| callDistance call |
	call := self instructionBeforeAddress: callSiteReturnAddress.
	self assert: ((self instructionIsB: call) or: [self instructionIsBL: call]).
	callDistance := self extractOffsetFromBL: call.
	"this is the pc's +8 offset, - the 4 byte correction for the previous instruction address"
	^callSiteReturnAddress + 4  + callDistance signedIntFromLong
]

{ #category : #testing }
CogARMCompiler >> canDivQuoRem [
	^true
]

{ #category : #testing }
CogARMCompiler >> canMulRR [
"we can do a MulRR be we can't simulate it correctly for some reason. More bug-fixing in the simulator one day"
	^true
]

{ #category : #testing }
CogARMCompiler >> canPushPopMultipleRegisters [
	<inline: true>
	^true
]

{ #category : #accessing }
CogARMCompiler >> codeGranularity [
	"Answer the size in bytes of a unit of machine code."
	<inline: true>
	^4
]

{ #category : #'generate machine code' }
CogARMCompiler >> computeMaximumSize [
	"Because we don't use Thumb, each ARM instruction has 4 bytes. Many
	 abstract opcodes need more than one instruction. Instructions that refer
	 to constants and/or literals depend on literals being stored in-line or out-of-line.

	 N.B.  The ^N forms are to get around the bytecode compiler's long branch
	 limits which are exceeded when each case jumps around the otherwise."

	opcode
		caseOf: {
		"Noops & Pseudo Ops"
		[Label]					-> [^0].
		[Literal]					-> [^4].
		[AlignmentNops]		-> [^(operands at: 0) - 4].
		[Fill32]					-> [^4].
		[Nop]					-> [^4].
		"Control"
		[Call]					-> [^4].
		[CallFull]				-> [^self literalLoadInstructionBytes + 4].
		[JumpR]					-> [^4].
		[Jump]					-> [^4].
		[JumpFull]				-> [^self literalLoadInstructionBytes + 4].
		[JumpLong]				-> [^4].
		[JumpZero]				-> [^4].
		[JumpNonZero]			-> [^4].
		[JumpNegative]			-> [^4].
		[JumpNonNegative]		-> [^4].
		[JumpOverflow]			-> [^4].
		[JumpNoOverflow]		-> [^4].
		[JumpCarry]			-> [^4].
		[JumpNoCarry]			-> [^4].
		[JumpLess]				-> [^4].
		[JumpGreaterOrEqual]	-> [^4].
		[JumpGreater]			-> [^4].
		[JumpLessOrEqual]		-> [^4].
		[JumpBelow]			-> [^4].
		[JumpAboveOrEqual]	-> [^4].
		[JumpAbove]			-> [^4].
		[JumpBelowOrEqual]	-> [^4].
		[JumpLongZero]		-> [^4].
		[JumpLongNonZero]	-> [^4].
		[JumpFPEqual]			-> [^8].
		[JumpFPNotEqual]		-> [^8].
		[JumpFPLess]			-> [^8].
		[JumpFPGreaterOrEqual]-> [^8].
		[JumpFPGreater]		-> [^8].
		[JumpFPLessOrEqual]	-> [^8].
		[JumpFPOrdered]		-> [^8].
		[JumpFPUnordered]		-> [^8].
		[RetN]					-> [^(operands at: 0) = 0 ifTrue: [4] ifFalse: [8]].
		[Stop]					-> [^4].

		"Arithmetic"
		[AddCqR]				-> [^self rotateable8bitSignedImmediate: (operands at: 0)
										ifTrue: [:r :i :n| 4]
										ifFalse: [self literalLoadInstructionBytes + 4]].
		[AndCqR]				-> [^self rotateable8bitBitwiseImmediate: (operands at: 0)
										ifTrue: [:r :i :n| 4]
										ifFalse:
											[self literalLoadInstructionBytes = 4
												ifTrue: [8]
												ifFalse:
													[1 << (operands at: 0) highBit = ((operands at: 0) + 1)
														ifTrue: [8]
														ifFalse: [self literalLoadInstructionBytes + 4]]]].
		[AndCqRR]				-> [^self rotateable8bitBitwiseImmediate: (operands at: 0)
										ifTrue: [:r :i :n| 4]
										ifFalse:
											[self literalLoadInstructionBytes = 4
												ifTrue: [8]
												ifFalse:
													[1 << (operands at: 0) highBit = ((operands at: 0) + 1)
														ifTrue: [8]
														ifFalse: [self literalLoadInstructionBytes + 4]]]].
		[CmpCqR]				-> [^self rotateable8bitSignedImmediate: (operands at: 0)
											ifTrue: [:r :i :n| 4]
											ifFalse: [self literalLoadInstructionBytes + 4]].
		[OrCqR]					-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| 4]
											ifFalse: [self literalLoadInstructionBytes + 4]].
		[SubCqR]				-> [^self rotateable8bitSignedImmediate: (operands at: 0)
											ifTrue: [:r :i :n| 4]
											ifFalse: [self literalLoadInstructionBytes + 4]].
		[TstCqR]				-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| 4]
											ifFalse: [self literalLoadInstructionBytes + 4]].
		[XorCqR]				-> [^self rotateable8bitBitwiseImmediate: (operands at: 0)
										ifTrue: [:r :i :n| 4]
										ifFalse:
											[self literalLoadInstructionBytes = 4
												ifTrue: [8]
												ifFalse:
													[1 << (operands at: 0) highBit = ((operands at: 0) + 1)
														ifTrue: [8]
														ifFalse: [self literalLoadInstructionBytes + 4]]]].
		[AddCwR]				-> [^self literalLoadInstructionBytes + 4].
		[AndCwR]				-> [^self literalLoadInstructionBytes + 4].
		[CmpCwR]				-> [^self literalLoadInstructionBytes + 4].
		[OrCwR]				-> [^self literalLoadInstructionBytes + 4].
		[SubCwR]				-> [^self literalLoadInstructionBytes + 4].
		[XorCwR]				-> [^self literalLoadInstructionBytes + 4].
		[AddRR]					-> [^4].
		[AndRR]					-> [^4].
		[CmpRR]				-> [^4].
		[OrRR]					-> [^4].
		[XorRR]					-> [^4].
		[SubRR]					-> [^4].
		[NegateR]				-> [^4].
		[LoadEffectiveAddressMwrR]
									-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| 4]
											ifFalse: [self literalLoadInstructionBytes + 4]].

		[LogicalShiftLeftCqR]		-> [^4].
		[LogicalShiftRightCqR]		-> [^4].
		[ArithmeticShiftRightCqR]	-> [^4].
		[LogicalShiftLeftRR]			-> [^4].
		[LogicalShiftRightRR]		-> [^4].
		[ArithmeticShiftRightRR]		-> [^4].
		[AddRdRd]					-> [^4].
		[CmpRdRd]					-> [^4].
		[SubRdRd]					-> [^4].
		[MulRdRd]					-> [^4].
		[DivRdRd]					-> [^4].
		[SqrtRd]					-> [^4].
		"ARM Specific Arithmetic"
		[SMULL]				-> [^4].
		[MSR]					-> [^4].
		[CMPSMULL]			-> [^4]. "special compare for genMulR:R: usage"
		"ARM Specific Data Movement"
		[PopLDM]				-> [^4].
		[PushSTM]				-> [^4].
		"Data Movement"						
		[MoveCqR]				-> [^self literalLoadInstructionBytes = 4
										ifTrue: [self literalLoadInstructionBytes]
										ifFalse:
											[self rotateable8bitBitwiseImmediate: (operands at: 0)
												ifTrue: [:r :i :n| 4]
												ifFalse: [self literalLoadInstructionBytes]]].
		[MoveCwR]				-> [^self literalLoadInstructionBytes = 4
										ifTrue: [self literalLoadInstructionBytes]
										ifFalse:
											[(self inCurrentCompilation: (operands at: 0))
												ifTrue: [4]
												ifFalse: [self literalLoadInstructionBytes]]].
		[MoveRR]				-> [^4].
		[MoveRdRd]				-> [^4].
		[MoveAwR]				-> [^(self isAddressRelativeToVarBase: (operands at: 0))
													ifTrue: [4]
													ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveRAw]				-> [^(self isAddressRelativeToVarBase: (operands at: 1))
													ifTrue: [4]
													ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveAbR]				-> [^(self isAddressRelativeToVarBase: (operands at: 0))
													ifTrue: [4]
													ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveRAb]				-> [^(self isAddressRelativeToVarBase: (operands at: 1))
													ifTrue: [4]
													ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveRMwr]			-> [^self is12BitValue: (operands at: 1)
										ifTrue: [:u :i| 4]
										ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveRdM64r]			-> [^self literalLoadInstructionBytes + 4]. 
		[MoveMbrR]				-> [^self is12BitValue: (operands at: 0)
										ifTrue: [:u :i| 4]
										ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveRMbr]				-> [^self is12BitValue: (operands at: 1)
										ifTrue: [:u :i| 4]
										ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveRM16r]				-> [^self is12BitValue: (operands at: 1)
										ifTrue: [:u :i| 4]
										ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveM16rR]			-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| 4]
											ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveM64rRd]			-> [^self literalLoadInstructionBytes + 4].
		[MoveMwrR]			-> [^self is12BitValue: (operands at: 0)
										ifTrue: [:u :i| 4]
										ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveXbrRR]			-> [^4].
		[MoveRXbrR]			-> [^4].
		[MoveXwrRR]			-> [^4].
		[MoveRXwrR]			-> [^4].
		[PopR]					-> [^4].
		[PushR]					-> [^4].
		[PushCw]				-> [^self literalLoadInstructionBytes = 4
										ifTrue: [self literalLoadInstructionBytes + 4]
										ifFalse:
											[(self inCurrentCompilation: (operands at: 0))
												ifTrue: [8]
												ifFalse:
													[self rotateable8bitBitwiseImmediate: (operands at: 0)
														ifTrue: [:r :i :n| 8]
														ifFalse: [self literalLoadInstructionBytes + 4]]]].
		[PushCq]				-> [^self literalLoadInstructionBytes = 4
										ifTrue: [self literalLoadInstructionBytes + 4]
										ifFalse:
											[self rotateable8bitBitwiseImmediate: (operands at: 0)
												ifTrue: [:r :i :n| 8]
												ifFalse: [self literalLoadInstructionBytes + 4]]].
		[PrefetchAw] 			-> [^(self isAddressRelativeToVarBase: (operands at: 0))
										ifTrue: [4]
										ifFalse: [self literalLoadInstructionBytes + 4]].
		"Conversion"
		[ConvertRRd]			-> [^8].
				
		"This is a fixed size instruction using a literal. We need exactly 1 instructions to move a literal from a PC relative position, so this takes ALWAYS 1 instruction of 4 bytes"
		[MovePatcheableC32R] -> [ ^ 4 ]
		}.
	^0 "to keep C compiler quiet"

]

{ #category : #accessing }
CogARMCompiler >> concreteCalleeSavedRegisterMask [
	"According to IHI0042E ARM Architecture Procedure Calling Standard, in section 5.1.1:
		A subroutine must preserve the contents of the registers r4-r8, r10, r11 and SP (and r9 in PCS variants that designate r9 as v6).
	 SP = r13, so..."
	^2r0000110111110000
]

{ #category : #accessing }
CogARMCompiler >> concreteCallerSavedRegisterMask [
	"According to IHI0042E ARM Architecture Procedure Calling Standard, in section 5.1.1:
		A subroutine must preserve the contents of the registers r4-r8, r10, r11 and SP (and r9 in PCS variants that designate r9 as v6).
	 SP = r13, so the callee-saved regs are r4-r8 & r10-r12.
	 The caller-saved registers are those that are not callee-saved and not reserved for hardware/abi uses,
	 i..e r0-r3, r9 & r12."
	^2r1001000001111
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeAddRdRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"Add FP regRHS to FP regLHS and stick result in FP regLHS"
	| regLHS regRHS |
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	machineCode at: 0 put:(self faddd: regLHS with: regRHS).
	^machineCodeSize := 4
	
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeAlignmentNops [
	<inline: true>
	"fill any slots with NOPs - in this case mov  r0, r0 - which is the NOP I always used to use"
	self assert: machineCodeSize \\ 4 = 0.
	0 to: machineCodeSize - 1 by: 4 do:
		[:p| self machineCodeAt: p put: 16rE1A00000]
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeAndCqRR [
	"Will get inlined into concretizeAt: switch."
	"AND is very important since it's used to mask all sorts of flags in the jit. We take special care to try to find compact ways to make the masks"
	<inline: true>
	| val srcReg dstReg |
	val := operands at: 0.
	srcReg := operands at: 1.
	dstReg := operands at: 2.
	self rotateable8bitBitwiseImmediate: val
		ifTrue:
			[:rot :immediate :invert|
			self machineCodeAt: 0 put: (invert
											ifTrue: [self bics: dstReg rn: srcReg imm: immediate ror: rot]
											ifFalse: [self ands: dstReg rn: srcReg imm: immediate ror: rot]).
			^machineCodeSize := 4]
		ifFalse: "let's try to see if the constant can be made from a simple shift of 0xFFFFFFFF"
			[| hb |
			hb := (operands at: 0) highBit.
			1 << hb = (val +1)
				ifTrue: "MVN temp reg, 0, making 0xffffffff"
					[self machineCodeAt: 0 put:(self mvn: ConcreteIPReg imm: 0 ror: 0).
					"Then AND reg, temp reg, lsr #(32-hb)"
					 self machineCodeAt: 4 put: (self dataOpType: AndOpcode rd: dstReg rn: srcReg rm: ConcreteIPReg lsr: 32 - hb).
					^machineCodeSize := 8]
				ifFalse:
					[^self concretizeDataOperationCwR: AndOpcode]].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeArithmeticShiftRightCqR [
	"Will get inlined into concretizeAt: switch."
	"this is an unfortunate waste of an instruction in most cases since the shift can usually be done in a subsequent arithmetic instruction. 
	Handle for now with a MOVS reg, reg, ASR #distance"
	<inline: true>
	| distance reg |
	distance := (operands at: 0) min: 31.
	reg := operands at: 1.
	"cond 000 1101 0 0000 dest dist -100 srcR"
	self machineCodeAt: 0 put: (self type: 0 op: MoveOpcode set: 1 rn: 0 rd: reg 
									shifterOperand: (distance << 7 bitOr: (64 "flag for arithmetic" bitOr: reg))).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeArithmeticShiftRightRR [
	"Will get inlined into concretizeAt: switch."
	"this is an unfortunate waste of an instruction in most cases since the shift can usually be done in a subsequent arithmetic instruction. 
	Handle for now with a MOVS reg, reg, ASR distReg"
	<inline: true>
	| destReg distReg |
	distReg := operands at: 0.
	destReg := operands at: 1.
	"cond 000 1101 0 0000 destR distR 0101 srcR"
	self machineCodeAt: 0 put: (self type: 0 op: MoveOpcode set: 1 rn: 0 rd: destReg 
									shifterOperand: (distReg << 8 bitOr: (80 bitOr: destReg))).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogARMCompiler >> concretizeAt: actualAddress [
	"Generate concrete machine code for the instruction at actualAddress,
	 setting machineCodeSize, and answer the following address."

	self assert: actualAddress \\ 4 = 0.
	^super concretizeAt: actualAddress
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeCMPSMULL [
	"Generate a CMP a, b, ASR #31 instruction, specifically for comparing the resutls of SMULLs in genMulR:R:"
	| hiReg loReg |
	hiReg := operands at: 0.
	loReg := operands at: 1.
	self machineCodeAt: 0
		put: (self type: 0 op: CmpOpcode set: 1 rn: hiReg rd: 0)
			+ (31<<7) "the shift amount"
			+ (2<<5) "the shift type - ASR"
			+ loReg.
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeCall [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"Call is used only for calls within code-space, See CallFull for general anywhere in address space calling"
	| offset |
	self assert: (operands at: 0) ~= 0.
	self assert: (operands at: 0) \\ 4 = 0.
	offset := (operands at: 0) signedIntFromLong - (address + 8 "normal pc offset") signedIntFromLong.
	self assert: (self isInImmediateJumpRange: offset). "+- 24Mb is plenty of range in code space"
	self machineCodeAt: 0 put: (self bl: offset).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeCallFull [
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating calls.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| jumpTarget instrOffset|
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := self longJumpTargetAddress.
	instrOffset := self moveCw: jumpTarget intoR: ConcreteIPReg.
	"blx ConcreteIPReg"
	self machineCodeAt: instrOffset put: (self blx: ConcreteIPReg).
	self assert: instrOffset = self literalLoadInstructionBytes.
	^machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeCmpRdRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"Compare FP regB with FP regA and leave the FP status reg ready to be transferred back to ARM with next instruction"
	| regB regA |
	regA := operands at:0.
	regB := operands at: 1.
	machineCode at: 0 put:(self fcmpFrom: regB to: regA).
	^machineCodeSize := 4
		

]

{ #category : #'generate machine code' }
CogARMCompiler >> concretizeConditionalInstruction [
	"Concretize the current instruction, but with a condition."
	<returnTypeC: #void>
	| savedCond |
	self assert: conditionOrNil notNil.
	savedCond := conditionOrNil.
	conditionOrNil := nil.
	self dispatchConcretize.
	conditionOrNil := savedCond.
	0 to: machineCodeSize-1 by: 4 do:
		[:i| | instr |
		instr := (self machineCodeAt: i) bitClear: 16rF<<28.
		self machineCodeAt: i put: (instr bitOr: (conditionOrNil bitAnd: 16rF)<<28)]
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeConditionalJump: conditionCode [
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| offset |
	offset := self computeJumpTargetOffsetPlus: 8.
 	self assert: (self isInImmediateJumpRange: offset).
	self machineCodeAt: 0 put: (self cond: conditionCode br: 0 offset: offset). "B offset"
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeConvertRRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg destReg |
	srcReg := operands at:0.
	destReg := operands at: 1.
	machineCode at: 0 put:(self fmsrFrom: srcReg to: 9).
	machineCode at: 1 put: (self fsitodFrom: 9 to: destReg). "probably not quite right"
	^machineCodeSize := 8
		

]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeDataOperationCqR: armOpcode [
	"Will get inlined into concretizeAt: switch."
	"4 == Add, 2 == Sub, Xor == 1, And == 0, Or == 12, Bic == 14"
	<inline: true>
	|val rd rn |
	val := operands at: 0.
	rn := operands at: 1.
	rd := opcode = CmpOpcode ifTrue: [0] ifFalse:[rn]. "Extra note - if ever a version of this code wants to NOT set the Set flag - Cmp must always have it set or it will pretend to be a SMALALBT and Very Bad Things might happen"

	self  rotateable8bitImmediate: val 
		ifTrue: [:rot :immediate |
			self machineCodeAt: 0 put: (self type: 1 op: armOpcode set: 1 rn: rn rd: rd shifterOperand: ((rot>>1)"in this usage we have to halve the rot value" << 8 bitOr: immediate)).
			^machineCodeSize := 4]
		ifFalse: ["let's try to see if the constant can be made from a simple shift of 0xFFFFFFFF"
				val > 0 ifTrue: [
					|hb |
					hb := val highBit.
					1 << hb = (val +1)
						ifTrue: [ "MVN temp,  #0, making 0xffffffff"
							self machineCodeAt: 0 put:(self mvn: ConcreteIPReg imm: 0 ror: 0).
							"Then armOpcode reg, temp reg, lsr #(32-hb)"
							 self machineCodeAt: 4 put:(self dataOpType: armOpcode rd: rd  rn: rn rm: ConcreteIPReg lsr: (32-hb)).
							^machineCodeSize :=8]].
					^self concretizeDataOperationCwR: armOpcode].
	^0 "to keep Slang happy"
	
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeDataOperationCwR: armOpcode [
	"Will get inlined into concretizeAt: switch."
	"Load the word into the RISCTempReg, then cmp R, RISCTempReg"
	<inline: true>
	| constant rn rd instrOffset|
	constant := operands at: 0.
	rn := operands at: 1.
	rd := armOpcode = CmpOpcode ifTrue: [0] ifFalse:[rn].
	instrOffset := self moveCw: constant intoR: ConcreteIPReg.
	self machineCodeAt: instrOffset 
		put: (self type: 0 op: armOpcode set: 1 rn: rn rd: rd shifterOperand: ConcreteIPReg).
	^machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeDataOperationRR: armOpcode [
	"Will get inlined into concretizeAt: switch."
	"Load the word into the RISCTempReg, then op R, RISCTempReg"
	<inline: true>
	| rn rd srcReg |
	srcReg := operands at: 0.
	rn := operands at: 1.
	rd := armOpcode = CmpOpcode ifTrue: [0] ifFalse: [rn].
	self machineCodeAt: 0 
		put: (self type: 0 op: armOpcode set: 1 rn: rn rd: rd shifterOperand: srcReg).
	^machineCodeSize := 4.
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeDivRdRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"FP divide regLHS by regRHS and stick result in regLHS"
	| regLHS regRHS |
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	machineCode at: 0 put:(self fdivd: regLHS by: regRHS).
	^machineCodeSize := 4
	
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeFPConditionalJump: conditionCode [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset |
	"transfer the FP status to ARM cpsr and then jump accordingly"
	offset := self computeJumpTargetOffsetPlus: 8+4 "pc is always 2 instr ahead plus add another to refer to the actual branch".
 	self assert: (self isInImmediateJumpRange: offset).
	self machineCodeAt: 0 put: self fmstat. "FMSTAT: copy the FPSCR to CPSR"
	self machineCodeAt: 4 put: (self cond: conditionCode br: 0 offset: offset). "B offset"
	^machineCodeSize := 8
]

{ #category : #'generate machine code' }
CogARMCompiler >> concretizeFill32 [
	"fill with operand 0 according to the processor's endianness"
	self machineCodeAt: 0 put: (operands at: 0).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeInvertibleDataOperationCqR: armOpcode [
	"Will get inlined into concretizeAt: switch."
	"Xor == 1, And == 0, Or == 12, Bic == 14"
	<inline: true>
	| val rn |
	val := operands at: 0.
	rn := operands at: 1.
	self deny: opcode = CmpOpcode.

	self rotateable8bitBitwiseImmediate: val 
		ifTrue:
			[:rot :immediate : invert|
			self machineCodeAt: 0
				put: (self
						type: 1
						op: (invert ifTrue: [self inverseOpcodeFor: armOpcode] ifFalse: [armOpcode])
						set: 1
						rn: rn
						rd: rn
						shifterOperand: (rot >> 1"in this usage we have to halve the rot value" << 8 bitOr: immediate)).
			^machineCodeSize := 4]
		ifFalse: "let's try to see if the constant can be made from a simple shift of 0xFFFFFFFF"
			[val > 0 ifTrue:
				[| hb |
				hb := val highBit.
				1 << hb = (val +1) ifTrue: "MVN temp,  #0, making 0xffffffff"
					[self machineCodeAt: 0 put: (self mvn: ConcreteIPReg imm: 0 ror: 0).
					 "Then armOpcode reg, temp reg, lsr #(32-hb)"
					 self machineCodeAt: 4 put: (self dataOpType: armOpcode rd: rn  rn: rn rm: ConcreteIPReg lsr: 32 - hb).
					^machineCodeSize := 8]].
			 ^self concretizeDataOperationCqR: armOpcode].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeJumpFull [
	"Will get inlined into concretizeAt: switch."
	"A JumpFull is used when we need to jump to anywhere in 32bit address space rather than somewhere known to be in code-space. It also must be relocatable and non-varying with the jump range. On ARM this means using the build-long-const + BX sequence."
	<inline: true>
	| jumpTarget instrOffset|
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := self longJumpTargetAddress.
	instrOffset := self moveCw: jumpTarget intoR: ConcreteIPReg.
	"bx ConcreteIPReg"
	self machineCodeAt: instrOffset put: (self bx: ConcreteIPReg).
	^machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeJumpR [
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| reg |
	reg := operands at: 0.
	"bx reg"
	self machineCodeAt: 0 put: (self bx: reg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeLoadEffectiveAddressMwrR [
	"Will get inlined into concretizeAt: switch."
	"destReg = srcReg (which contains an address) + offset"
	<inline: true>
	| srcReg offset destReg instrOffset |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self rotateable8bitImmediate: offset
		ifTrue:
			[ :rot :immediate | 
			self machineCodeAt: 0 
				"add destReg, srcReg, #immediate ROR rot"
				put: (self add: destReg rn: srcReg imm: immediate ror: rot<<1).
			machineCodeSize := 4]
		ifFalse:
			[instrOffset := self moveCw: offset intoR: ConcreteIPReg.
			"add destReg, srcReg, ConcreteIPReg"
			self machineCodeAt: 16 put: (self add: destReg rn: srcReg rm: ConcreteIPReg).
			machineCodeSize := instrOffset + 4].
	^machineCodeSize "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeLogicalShiftLeftCqR [
	"Will get inlined into concretizeAt: switch."
	"this is an unfortunate waste of an instruction in most cases since the shift can usually be done in a subsequent arithmetic instruction. 
	Handle for now with a MOVS reg, reg, LSL #distance"
	<inline: true>
	| distance reg |
	distance := (operands at: 0) min: 31.
	reg := operands at: 1.
	"cond 000 1101 0 0000 dest dista 000 srcR"
	self machineCodeAt: 0 put: (self type: 0 op: MoveOpcode set: 1 rn: 0 rd: reg shifterOperand: (distance << 7 bitOr: reg)).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeLogicalShiftLeftRR [
	"Will get inlined into concretizeAt: switch."
	"this is an unfortunate waste of an instruction in most cases since the shift can usually be done in a subsequent arithmetic instruction. 
	Handle for now with a MOVS reg, reg, LSL distReg" 
	<inline: true>
	| destReg distReg |
	distReg := operands at: 0.
	destReg := operands at: 1.
	"cond 000 1101 0 0000 dest dist 0001 srcR"
	self machineCodeAt: 0 put: (self type: 0 op: MoveOpcode set: 1 rn: 0 rd: destReg 
									shifterOperand: (distReg << 8 bitOr: (16 bitOr: destReg))).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeLogicalShiftRightCqR [
	"Will get inlined into concretizeAt: switch."
	"this is an unfortunate waste of an instruction in most cases since the shift can usually be done in a subsequent arithmetic instruction. 
	Handle for now with a MOVS reg, reg, LSR #distance"
	<inline: true>
	| distance reg |
	distance := (operands at: 0) min: 31.
	reg := operands at: 1.
	"cond 000 1101 0 0000 dest dist -010 srcR"
	self machineCodeAt: 0 put: (self type: 0 op: MoveOpcode set: 1 rn: 0 rd: reg 
									shifterOperand: (distance << 7 bitOr: (32 bitOr: reg))).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeLogicalShiftRightRR [
	"Will get inlined into concretizeAt: switch."
	"this is an unfortunate waste of an instruction in most cases since the shift can usually be done in a subsequent arithmetic instruction. 
	Handle for now with a MOVS reg, reg, LSR distReg"
	<inline: true>
	| destReg distReg |
	distReg := operands at: 0.
	destReg := operands at: 1.
	"cond 000 1101 0 0000 dest dist 0011 srcR"
	self machineCodeAt: 0 put: (self type: 0 op: MoveOpcode set: 1 rn: 0 rd: destReg 
									shifterOperand: (distReg << 8 bitOr: (48 bitOr: destReg))).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMSR [
	"Generate an MSR CPSR_f, #flags instruction.
Note that we only have business with the NZCV flags so we use
N -> 8
Z -> 4
C -> 2
V -> 1.
You don't want to mess with this too much."
	|  flags |
	flags := operands at: 0.
	self machineCodeAt: 0 put: (self msr: flags).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveAbR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcAddr destReg instrOffset|
	srcAddr := operands at: 0.
	destReg := operands at: 1.
	(self isAddressRelativeToVarBase: srcAddr) ifTrue:
		[self machineCodeAt: 0 put: (self ldrb: destReg rn: ConcreteVarBaseReg plus: 1 imm: srcAddr - cogit varBaseAddress).
		 ^machineCodeSize := 4].
	"load the address into ConcreteIPReg"
	instrOffset := self moveCw: srcAddr intoR: ConcreteIPReg.
	"We *could* overwrite the last instruction above with a LDR a, b, last-byte-of-srcAddr BUT that would break if we change to loading literals instead of forming long constants"
	self machineCodeAt: instrOffset put: (self ldrb: destReg rn: ConcreteIPReg plus: 1 imm: 0).
	^machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveAwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcAddr destReg instrOffset|
	srcAddr := operands at: 0.
	destReg := operands at: 1.
	(self isAddressRelativeToVarBase: srcAddr) ifTrue:
		[self machineCodeAt: 0 put: (self ldr: destReg rn: ConcreteVarBaseReg plusImm: srcAddr - cogit varBaseAddress).
		 ^machineCodeSize := 4].
	"load the address into ConcreteIPReg"
	instrOffset := self moveCw: srcAddr intoR: ConcreteIPReg.
	"We *could* overwrite the last instruction above with a LDR a, b, last-byte-of-srcAddr BUT that would break if we change to loading literals instead of forming long constants"
	self machineCodeAt: instrOffset put: (self ldr: destReg rn: ConcreteIPReg plusImm: 0).
	^machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveCqR [
	"Will get inlined into concretizeAt: switch."
	"If the quick constant is in fact a shiftable 8bit, generate the apropriate MOV, otherwise do what is necessary for a whole word."
	<var: #word type: #sqInt>
	<inline: true>
	|word reg|
	word := operands at: 0.
	reg := operands at: 1.
	self 
		rotateable8bitImmediate: word 
		ifTrue: [:rot :immediate |
			self machineCodeAt: 0 put: (self mov: reg imm: immediate ror: rot).
			^machineCodeSize := 4]
		ifFalse: [|invVal|
			word <0
				ifTrue:[invVal := -1 - word]
				ifFalse:[invVal := word bitInvert32].
			self rotateable8bitImmediate: invVal
				ifTrue: [ :rot :immediate |
					self machineCodeAt: 0 put: (self mvn: reg imm: immediate ror: rot).
					^machineCodeSize := 4]
				ifFalse: [^self concretizeMoveCwR]].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveCwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	^machineCodeSize := self loadCwInto: (operands at: 1)
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveM16rR [
	"Will get inlined into concretizeAt: switch."
	"ldrh destReg, [srcReg, #immediate],
	or 
	move offset to ConcreteIPReg
	ldrh destReg, [srcReg, ConcreteIPReg]"
	<var: #offset type: #sqInt>
	<inline: true>
	| srcReg offset destReg instrOffset|
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self is8BitValue: offset
		ifTrue:
			[ :u :immediate | 
			self machineCodeAt: 0 "ldrh destReg, [srcReg, #immediate]"
				put: (self ldrh: destReg rn: srcReg plus: u imm: immediate).
			^machineCodeSize := 4]
		ifFalse:
			[instrOffset := self moveCw: offset intoR: ConcreteIPReg.
			"ldrh destReg, [srcReg, ConcreteIPReg]"
			self machineCodeAt: instrOffset put: (self ldrh: destReg rn: srcReg rm: ConcreteIPReg).
			^machineCodeSize := instrOffset + 4 ].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveM64rRd [
	"Will get inlined into concretizeAt: switch."	
	<inline: true>
	"Load a float from srcReg+offset into FP destReg"
	| srcReg offset destReg u|
	offset := operands at: 0.
	u := offset >0 ifTrue:[1] ifFalse:[0].
	srcReg := operands at: 1.
	destReg := operands at: 2.
	machineCode at: 0 put: (self fldd: destReg rn: srcReg plus: u imm: offset>>2).
	^machineCodeSize := 4

]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveMbrR [
	"Will get inlined into concretizeAt: switch."
	"ldrb destReg, [srcReg, #immediate] or ldrb destReg, [srcReg, ConcreteIPReg]"
	<var: #offset type: #sqInt>
	<inline: true>
	| srcReg offset destReg instrOffset|
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self is12BitValue: offset
		ifTrue:
			[ :u :immediate | 
			self machineCodeAt: 0 "ldrb destReg, [srcReg, #immediate]"
				put: (self ldrb: destReg rn: srcReg plus: u imm: immediate).
			^machineCodeSize := 4]
		ifFalse:
			[(self isAddressRelativeToVarBase: offset)
				ifTrue:
					[self machineCodeAt: 0 put: (self adds: ConcreteIPReg rn: ConcreteVarBaseReg imm: offset - cogit varBaseAddress ror: 0).
					 instrOffset := 4]
				ifFalse:
					[instrOffset := self moveCw: offset intoR: ConcreteIPReg].
			 "ldrb destReg, [srcReg, ConcreteIPReg]"
			 self machineCodeAt: instrOffset put: (self ldrb: destReg rn: srcReg rm: ConcreteIPReg).
			 ^machineCodeSize := instrOffset + 4].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveMwrR [
	"Will get inlined into concretizeAt: switch."
	<var: #offset type: #sqInt>
	<inline: true>
	| srcReg offset destReg instrOffset|
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self is12BitValue: offset
		ifTrue:
			[ :u :immediate | 
			self machineCodeAt: 0 "ldr destReg, [srcReg, #immediate]"
				put: (self ldr: destReg rn: srcReg plus: u imm: immediate).
			^machineCodeSize := 4]
		ifFalse:
			[instrOffset := self moveCw: offset intoR: ConcreteIPReg.
			"ldr destReg, [srcReg, ConcreteIPReg]"
			self machineCodeAt: instrOffset put: (self ldr: destReg rn: srcReg rm: ConcreteIPReg).
			^machineCodeSize := instrOffset + 4].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRAb [
	"Will get inlined into concretizeAt: switch."
	"LEA ConcreteIPReg
	strb srcReg, [ConcreteIPReg]"
	<inline: true>
	| srcReg destAddr instrOffset|
	srcReg := operands at: 0.
	destAddr := operands at: 1.
	(self isAddressRelativeToVarBase: destAddr) ifTrue:
		[self machineCodeAt: 0 put: (self strb: srcReg rn: ConcreteVarBaseReg plus: 1 imm: destAddr - cogit varBaseAddress).
		 ^machineCodeSize := 4].
	"load the address into ConcreteIPReg"
	instrOffset := self moveCw: destAddr intoR: ConcreteIPReg.
	"We *could* overwrite the last instruction above with a LDR a, b, last-byte-of-srcAddr BUT that would break if we change to loading literals instead of forming long constants"
	self machineCodeAt: instrOffset put: (self strb: srcReg rn: ConcreteIPReg plus: 1 imm: 0).
	^machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRAw [
	"Will get inlined into concretizeAt: switch."
	"LEA ConcreteIPReg
	str srcReg, [ConcreteIPReg]"
	<inline: true>
	| srcReg destAddr instrOffset|
	srcReg := operands at: 0.
	destAddr := operands at: 1.
	(self isAddressRelativeToVarBase: destAddr) ifTrue:
		[self machineCodeAt: 0 put: (self str: srcReg rn: ConcreteVarBaseReg plusImm: destAddr - cogit varBaseAddress).
		 ^machineCodeSize := 4].
	"load the address into ConcreteIPReg"
	instrOffset := self moveCw: destAddr intoR: ConcreteIPReg.
	"We *could* overwrite the last instruction above with a LDR a, b, last-byte-of-srcAddr BUT that would break if we change to loading literals instead of forming long constants"
	self machineCodeAt: instrOffset put: (self str: srcReg rn: ConcreteIPReg plusImm: 0).
	^machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRM16r [
	"Will get inlined into concretizeAt: switch."
	<var: #offset type: #sqInt>
	<inline: true>
	| srcReg offset baseReg instrOffset|
	srcReg := operands at: 0.
	offset := operands at: 1.
	baseReg := operands at: 2.

	self is12BitValue: offset
		ifTrue:
			[ :u :immediate | 
			self machineCodeAt: 0 "strh 	srcReg, [baseReg, #immediate]"
				put: (self strh: srcReg rn: baseReg plus: u imm: immediate).
			^machineCodeSize := 4]
		ifFalse:
			[(self isAddressRelativeToVarBase: offset)
				ifTrue:
					[self machineCodeAt: 0 put: (self adds: ConcreteIPReg rn: ConcreteVarBaseReg imm: offset - cogit varBaseAddress ror: 0).
					 instrOffset := 4]
				ifFalse:
					[instrOffset := self moveCw: offset intoR: ConcreteIPReg].
			"strb 	srcReg, [baseReg, ConcreteIPReg]"
			self machineCodeAt: instrOffset put: (self strh: srcReg rn: baseReg rm: ConcreteIPReg).
			^machineCodeSize := instrOffset + 4 ].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRMbr [
	"Will get inlined into concretizeAt: switch."
	<var: #offset type: #sqInt>
	<inline: true>
	| srcReg offset baseReg instrOffset|
	srcReg := operands at: 0.
	offset := operands at: 1.
	baseReg := operands at: 2.
	self is12BitValue: offset
		ifTrue:
			[ :u :immediate | 
			self machineCodeAt: 0 "strb 	srcReg, [baseReg, #immediate]"
				put: (self strb: srcReg rn: baseReg plus: u imm: immediate).
			^machineCodeSize := 4]
		ifFalse:
			[(self isAddressRelativeToVarBase: offset)
				ifTrue:
					[self machineCodeAt: 0 put: (self adds: ConcreteIPReg rn: ConcreteVarBaseReg imm: offset - cogit varBaseAddress ror: 0).
					 instrOffset := 4]
				ifFalse:
					[instrOffset := self moveCw: offset intoR: ConcreteIPReg].
			"strb 	srcReg, [baseReg, ConcreteIPReg]"
			self machineCodeAt: instrOffset put: (self strb: srcReg rn: baseReg rm: ConcreteIPReg).
			^machineCodeSize := instrOffset + 4 ].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRMwr [
	"Will get inlined into concretizeAt: switch."
	<var: #offset type: #sqInt>
	<inline: true>
	| srcReg offset baseReg instrOffset|
	srcReg := operands at: 0.
	offset := operands at: 1.
	baseReg := operands at: 2.
	self is12BitValue: offset
		ifTrue:
			[ :u :immediate | 
			self machineCodeAt: 0  "str 	srcReg, [baseReg, #immediate]"
				put: (self str: srcReg rn: baseReg plus: u imm: immediate).
			^machineCodeSize := 4]
		ifFalse:
			[instrOffset := self moveCw: offset intoR: ConcreteIPReg.
			"str srcReg, [baseReg, ConcreteIPReg]"
			self machineCodeAt: instrOffset put: (self str: srcReg rn: baseReg rm: ConcreteIPReg).
			^machineCodeSize := instrOffset + 4].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	"cond 000 1101 0 0000 dest 0000 0000 srcR"
	self machineCodeAt: 0 put: (self mov: destReg rn: srcReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRXbrR [
	"Will get inlined into concretizeAt: switch."
	"Write the word in R(src) into memory at address (base+1*index)"
	<inline: true>
	| index base src |
	src := operands at: 0.
	index := operands at: 1.
	base := operands at: 2.
	"str	b	src, [base, +index, LSL #0]"
	"cond 011 1100 0 base srcR 00000 00 0 index"
	self machineCodeAt: 0 put: (self strb: src rn: base rm: index).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRXwrR [
	"Will get inlined into concretizeAt: switch."
	"Write the word in R(src) into memory at address (base+4*index)"
	<inline: true>
	| index base src |
	src := operands at: 0.
	index := operands at: 1. "index is number of *words* = 4* bytes"
	base := operands at: 2.
	"str		src, [base, +index, LSL #2]"
	"cond 011 1100 0 base srcR 00010 00 0 inde"
	self machineCodeAt: 0 put: (self memMxr: AL reg: src base: base p: 1 u: 1 b: 0 w: 0 l: 0 rmLsl2: index).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRdM64r [
	"Will get inlined into concretizeAt: switch."	
	<inline: true>
	"Store FP fpReg to dstReg+offset"
	| dstReg offset fpReg u|
	offset := operands at: 1.
	u := offset >0 ifTrue:[1] ifFalse:[0].
	dstReg := operands at: 2.
	fpReg := operands at: 0.
	machineCode at: 0 put: (self fstd: fpReg rn: dstReg plus: u imm: offset>>2).
	^machineCodeSize := 4

]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveXbrRR [
	"Will get inlined into concretizeAt: switch."
	
	<inline: true>
	| index base dest |
	index := operands at: 0. "index is number of *bytes*"
	base := operands at: 1.
	dest := operands at: 2.
	"LDRB	dest, [base, +index, LSL #0]"
	"cond 011 1100 1 base dest 00000 00 0 inde"
	self machineCodeAt: 0 put: (self ldrb: dest rn: base rm: index).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveXwrRR [
	"Will get inlined into concretizeAt: switch."
	
	<inline: true>
	| index base dest |
	index := operands at: 0.
	base := operands at: 1.
	dest := operands at: 2.
	"LDR	dest, [base, +index, LSL #2]"
	"cond 011 1100 1 base dest 00010 00 0 inde bulit by lowest level generator so we can do the lsl #2 on the index register"
	self machineCodeAt: 0 put: (self memMxr: AL reg: dest base: base p: 1 u: 1 b: 0 w: 0 l: 1 rmLsl2: index).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMulRdRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"FP multiply regLHS by regRHS and stick result in regLHS"
	| regLHS regRHS |
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	machineCode at: 0 put:(self fmuld: regLHS with: regRHS).
	^machineCodeSize := 4
	
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeNegateR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := operands at: 0.
	"RSB destReg, srcReg, #0"
	self machineCodeAt: 0 put: (self type: 1 op: RsbOpcode set: 0 rn: reg rd: reg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeNegateableDataOperationCqR: armOpcode [
	"Will get inlined into concretizeAt: switch."
	"4 == Add, 2 == Sub, 10 = Cmp"
	<inline: true>
	| val rd rn |
	val := operands at: 0.
	rn := operands at: 1.
	"Extra note - if ever a version of this code wants to NOT set the Set flag
	 - Cmp must always have it set or it will pretend to be a SMALALBT and Very Bad Things might happen."
	rd := armOpcode = CmpOpcode ifTrue: [0] ifFalse: [rn].
	self rotateable8bitSignedImmediate: val 
		ifTrue:
			[:rot :immediate : negate|
			self machineCodeAt: 0
				put: (self
						type: 1
						op: (negate ifTrue: [self inverseOpcodeFor: armOpcode] ifFalse: [armOpcode])
						set: 1
						rn: rn
						rd: rd
						shifterOperand: (rot >> 1"in this usage we have to halve the rot value" << 8 bitOr: immediate)).
			^machineCodeSize := 4]
		ifFalse: "let's try to see if the constant can be made from a simple shift of 0xFFFFFFFF"
			[val > 0 ifTrue:
				[| hb |
				hb := val highBit.
				1 << hb = (val +1) ifTrue: "MVN temp,  #0, making 0xffffffff"
					[self machineCodeAt: 0 put:(self mvn: ConcreteIPReg imm: 0 ror: 0).
					 "Then armOpcode reg, temp reg, lsr #(32-hb)"
					 self machineCodeAt: 4 put:(self dataOpType: armOpcode rd: rd  rn: rn rm: ConcreteIPReg lsr: 32 - hb).
					^machineCodeSize := 8]].
			 ^self concretizeDataOperationCwR: armOpcode].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeNop [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"(CogARMCompiler new  mov: 0 rn: 0 ) hex -> MOV r0, r0"
	self machineCodeAt: 0 put: 16rE1A00000.
	^machineCodeSize := 4
			
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizePopR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| destReg |
	destReg := operands at: 0.
	"LDR destReg, [SP], #4"
	self machineCodeAt: 0 put: (self popR: destReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizePrefetchAw [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand instrOffset|
	addressOperand := operands at: 0.
	(self isAddressRelativeToVarBase: addressOperand) ifTrue:
		[self machineCodeAt: 0 put: (self pld: ConcreteVarBaseReg plus: 1 offset: addressOperand - cogit varBaseAddress).
		 ^machineCodeSize := 4].
	instrOffset := self moveCw: addressOperand intoR: ConcreteIPReg.
	"pld	[ConcreteIPReg]"
	self machineCodeAt: instrOffset put: (self pld: ConcreteIPReg plus: 1offset: 0).
	^machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizePushCq [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| word instrOffset |
	word := operands at: 0.
	self 
		rotateable8bitBitwiseImmediate: word 
		ifTrue:
			[:rot :immediate :invert|
			self machineCodeAt: 0
				put: (invert
						ifTrue: [self mvn: ConcreteIPReg imm: immediate ror: rot]
						ifFalse: [self mov: ConcreteIPReg imm: immediate ror: rot]).
			instrOffset := 4]
		ifFalse:
			[instrOffset := self moveCw: word intoR: ConcreteIPReg].
	self machineCodeAt: instrOffset put: (self pushR: ConcreteIPReg).
	^machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizePushCw [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| word instrOffset |
	word := operands at: 0.	
	(self inCurrentCompilation: word)
		ifTrue:
			[instrOffset := self loadCwInto: ConcreteIPReg]
		ifFalse:
			[self 
				rotateable8bitBitwiseImmediate: word 
				ifTrue:
					[:rot :immediate :invert|
					self machineCodeAt: 0
						put: (invert
								ifTrue: [self mvn: ConcreteIPReg imm: immediate ror: rot]
								ifFalse: [self mov: ConcreteIPReg imm: immediate ror: rot]).
					instrOffset := 4]
				ifFalse:
					[instrOffset := self loadCwInto: ConcreteIPReg]].
	self machineCodeAt: instrOffset put: (self pushR: ConcreteIPReg).
	^machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizePushOrPopMultipleRegisters: doPush [
	self assert: (operands at: 0) ~= 0.
	machineCode at: 0 put: AL << 28
						  + (doPush     "2r100PUSWL"
								ifTrue: [2r10010010 << 20]
								ifFalse: [2r10001011 << 20])
						  + (SP << 16)
						  + (operands at: 0).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizePushR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg |
	srcReg := operands at: 0.
	"cond | 010 | 1001 | 0 | -Rn- | -Rd- | 0000 0000 0100" "STR srcReg, [sp, #-4]"
	self machineCodeAt: 0 put: (self pushR: srcReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeRetN [
	"Will get inlined into concretizeAt: switch."
	<var: #offset type: #sqInt>
	<inline: true>
	| offset |
	offset := operands at: 0.
	offset = 0 ifTrue:
		[self machineCodeAt: 0 put: (self mov: PC rn: LR). "pop	{pc}"
		^machineCodeSize := 4].
	self assert: offset < 255. "We have an 8 bit immediate. If needed, we could rotate it less than 30 bit."

	self machineCodeAt: 0 put: (self add: SP rn: SP imm: offset  ror: 0).
	self machineCodeAt: 4 put: (self mov: PC rn: LR).  "pop	{pc}"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeSMULL [
	| srcA srcB hiResultReg loResultReg |
	"Generate an SMULL loResultReg, hiResultReg, srcA, srcB instruction"
	srcA := operands at: 0.
	"NOTE: srcB contains the other mutiplicand at this point. It is OK to use it as the destination for the low part of the result and in fact this saves us moving it later"
	loResultReg := srcB := operands at: 1.
	hiResultReg := RISCTempReg.
	self machineCodeAt: 0
		put: (self type: 0 op: 6 set: 0 rn: hiResultReg rd: loResultReg)
			+ (srcA << 8)
			+ (9 << 4)
			+ srcB.
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeSqrtRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"Square root of FP regLHS into regLHS"
	| regLHS  |
	regLHS := operands at: 0.
	machineCode at: 0 put:(self fsqrtd: regLHS).
	^machineCodeSize := 4
	
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeStop [
	<inline: true>
	self machineCodeAt: 0 put: self stop.
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeSubCqR [
	"Will get inlined into concretizeAt: switch."
	"Try whether the quick constant is a small negative number. If it is, optimize."
	<var: #word type: #sqInt>
	<inline: true>
	| word |
	word := operands at: 0.
	self rotateable8bitImmediate: word
		ifTrue: [ :rot :immediate | | reg |
			reg := operands at: 1.
			self machineCodeAt: 0 put: (self subs: reg rn: reg imm: immediate ror: rot).
			^machineCodeSize := 4]
		ifFalse: [
			"before building a full load of a big constant, see if we can do an add of the constant negated"
			self rotateable8bitImmediate: word negated
				ifTrue: [ :rot :immediate | | reg |
					reg := operands at: 1.
					self machineCodeAt: 0 put: (self adds: reg rn: reg imm: immediate ror: rot).
					^machineCodeSize := 4]
				ifFalse: [^self concretizeDataOperationCwR: SubOpcode]].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeSubRdRd [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	"Subtract FP regRHS from FP regLHS and leave the result in FP regLHS"
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	machineCode at: 0 put:(self fsubd: regLHS with: regRHS).
	^machineCodeSize := 4
	
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeTstCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	self rotateable8bitImmediate: (operands at: 0)
		ifTrue: [ :rot :immediate | | reg |
			reg := operands at: 1.
			self machineCodeAt: 0 put: (self tst: reg rn: reg imm: immediate ror: rot).
			^machineCodeSize := 4]
		ifFalse: [^self concretizeDataOperationCwR: TstOpcode].
	^0 "to keep Slang happy"
]

{ #category : #encoding }
CogARMCompiler >> cond: c br: link offset: offset [
	"c : 4 bit, opcode = 10 bitOr: link, offset >>2, limited to 24 bits (which are sign-extended, shifted left 2 and added to 8 + pc to make the resulting address)"
	"single instr Branch, no link"
	<inline: true>
	^ c << 28 bitOr: (((2r1010 bitOr: (link bitAnd: 1)) << 24) bitOr: (offset >> 2 bitAnd: 16r00FFFFFF))
]

{ #category : #encoding }
CogARMCompiler >> cond: c bx: link target: targetReg [
	"c : 4 bit, opcode = 10 bitOr: link, offset >>2, limited to 24 bits (which are sign-extended, shifted left 2 and added to 8 + pc to make the resulting address)"
	"BX targetReg or BLX targetReg"
	<inline: true>
	^ c << 28 bitOr: ( (16r12FFF10  bitOr: (link bitAnd: 1) <<5 ) bitOr: targetReg)
]

{ #category : #encoding }
CogARMCompiler >> cond: c type: t op: o set: s [
	"c : 4 bit, t: 3 bit, o: 4 bit, s: 1bit"
	"cccctttoooos + oxFFFFF - the leftmost 12bits of (most) ARM instruction. The other 20 bits get built elsewhere"
	<inline: true>
	^ c << 28 bitOr: ((t << 25) bitOr: ((o << 21) bitOr: (s << 20)))
]

{ #category : #encoding }
CogARMCompiler >> cond: conditionCode type: type op: flagsOrOpcode set: doUpdateStatusRegister rn:  sourceRegister rd: targetRegister [
"build an instruction - cccctttoooo + source + target"
	<inline: true>
	^(self cond: conditionCode type: type op: flagsOrOpcode set: doUpdateStatusRegister) 
		bitOr: (sourceRegister << 16 bitOr: targetRegister << 12)
]

{ #category : #encoding }
CogARMCompiler >> cond: conditionCode type: type op: flagsOrOpcode set: doUpdateStatusRegister rn:  sourceRegister rd: targetRegister shifterOperand: so [
"build an instruction - cccctttoooo + source + target + shifter op"
	<inline: true>
	^(self cond: conditionCode type: type op: flagsOrOpcode set: doUpdateStatusRegister rn: sourceRegister rd: targetRegister) bitOr: (so bitAnd: 16rFFF)
]

{ #category : #testing }
CogARMCompiler >> conditionIsNotNever: instr [
	"test for the NV condition code; this isn't allowed as an actual condition and is used to encdoe many of the newer instructions"
	^instr >> 28 < 16rF 
]

{ #category : #accessing }
CogARMCompiler >> conditionOrNil [
"has to be named oddly like this to satisfay i-var code gen translating rules"
	^conditionOrNil
]

{ #category : #accessing }
CogARMCompiler >> conditionOrNil: condCode [
"has to be named oddly like this to satisfay i-var code gen translating rules"
	^conditionOrNil := condCode
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> dataOpType: armOpcode rd: destReg rn: srcReg rm: addReg lsr: shft [
"return an {opcode} destReg, srcReg, addReg lsl #shft"
"important detail - a 0 shft requires setting the shift-type code to 0 to avoid potential instruction confusion"
	shft = 0
		ifTrue:[^self type: 0 op: armOpcode set: 1 rn: srcReg rd: destReg shifterOperand: addReg]
		ifFalse:[^self type: 0 op: armOpcode set: 1 rn: srcReg rd: destReg shifterOperand: ((shft <<7 bitOr: 32) bitOr:  addReg)]
]

{ #category : #'generate machine code' }
CogARMCompiler >> dispatchConcretize [
	"Attempt to generate concrete machine code for the instruction at address.
	 This is the inner dispatch of concretizeAt: actualAddress which exists only
	 to get around the branch size limits in the SqueakV3 (blue book derived)
	 bytecode set."
	<returnTypeC: #void>
	conditionOrNil ifNotNil:
		[self concretizeConditionalInstruction.
		 ^self].
		 
	opcode caseOf: {
		"Noops & Pseudo Ops"
		[Label]					-> [^self concretizeLabel].
		[Literal]					-> [^self concretizeLiteral].
		[AlignmentNops]		-> [^self concretizeAlignmentNops].
		[Fill32]					-> [^self concretizeFill32].
		[Nop]					-> [^self concretizeNop].
		"Control"
		[Call]						-> [^self concretizeCall]. "call code within code space"
		[CallFull]					-> [^self concretizeCallFull]. "call code anywhere in address space"
		[JumpR]						-> [^self concretizeJumpR].
		[JumpFull]					-> [^self concretizeJumpFull]."jump within address space"
		[JumpLong]					-> [^self concretizeConditionalJump: AL]."jumps witihn code space"
		[JumpLongZero]			-> [^self concretizeConditionalJump: EQ].
		[JumpLongNonZero]		-> [^self concretizeConditionalJump: NE].
		[Jump]						-> [^self concretizeConditionalJump: AL].
		[JumpZero]					-> [^self concretizeConditionalJump: EQ].
		[JumpNonZero]				-> [^self concretizeConditionalJump: NE].
		[JumpNegative]				-> [^self concretizeConditionalJump: MI].
		[JumpNonNegative]			-> [^self concretizeConditionalJump: PL].
		[JumpOverflow]				-> [^self concretizeConditionalJump: VS].
		[JumpNoOverflow]			-> [^self concretizeConditionalJump: VC].
		[JumpCarry]				-> [^self concretizeConditionalJump: CS].
		[JumpNoCarry]				-> [^self concretizeConditionalJump: CC].
		[JumpLess]					-> [^self concretizeConditionalJump: LT].
		[JumpGreaterOrEqual]		-> [^self concretizeConditionalJump: GE].
		[JumpGreater]				-> [^self concretizeConditionalJump: GT].
		[JumpLessOrEqual]			-> [^self concretizeConditionalJump: LE].
		[JumpBelow]				-> [^self concretizeConditionalJump: CC]. "unsigned lower"
		[JumpAboveOrEqual]		-> [^self concretizeConditionalJump: CS]. "unsigned greater or equal"
		[JumpAbove]				-> [^self concretizeConditionalJump: HI].
		[JumpBelowOrEqual]		-> [^self concretizeConditionalJump: LS].
		[JumpFPEqual]				-> [^self concretizeFPConditionalJump: EQ].
		[JumpFPNotEqual]			-> [^self concretizeFPConditionalJump: NE].
		[JumpFPLess]				-> [^self concretizeFPConditionalJump: LT].
		[JumpFPGreaterOrEqual]	-> [^self concretizeFPConditionalJump: GE].
		[JumpFPGreater]			-> [^self concretizeFPConditionalJump: GT].
		[JumpFPLessOrEqual]		-> [^self concretizeFPConditionalJump: LE].
		[JumpFPOrdered]			-> [^self concretizeFPConditionalJump: VC].
		[JumpFPUnordered]			-> [^self concretizeFPConditionalJump: VS].
		[RetN]						-> [^self concretizeRetN].
		[Stop]						-> [^self concretizeStop].
		"Arithmetic"
		[AddCqR]					-> [^self concretizeNegateableDataOperationCqR: AddOpcode].
		[AndCqR]					-> [^self concretizeInvertibleDataOperationCqR: AndOpcode].
		[AndCqRR]					-> [^self concretizeAndCqRR].
		[CmpCqR]					-> [^self concretizeNegateableDataOperationCqR: CmpOpcode].
		[OrCqR]						-> [^self concretizeDataOperationCqR: OrOpcode].
		[SubCqR]					-> [^self concretizeSubCqR].
		[TstCqR]					-> [^self concretizeTstCqR].
		[XorCqR]					-> [^self concretizeInvertibleDataOperationCqR: XorOpcode].
		[AddCwR]					-> [^self concretizeDataOperationCwR: AddOpcode].
		[AndCwR]					-> [^self concretizeDataOperationCwR: AndOpcode].
		[CmpCwR]					-> [^self concretizeDataOperationCwR: CmpOpcode].
		[OrCwR]					-> [^self concretizeDataOperationCwR: OrOpcode].
		[SubCwR]					-> [^self concretizeDataOperationCwR: SubOpcode].
		[XorCwR]					-> [^self concretizeDataOperationCwR: XorOpcode].
		[AddRR]						-> [^self concretizeDataOperationRR: AddOpcode].
		[AndRR]						-> [^self concretizeDataOperationRR: AndOpcode].
		[CmpRR]					-> [^self concretizeDataOperationRR: CmpOpcode].
		[OrRR]						-> [^self concretizeDataOperationRR: OrOpcode].
		[SubRR]						-> [^self concretizeDataOperationRR: SubOpcode].
		[XorRR]						-> [^self concretizeDataOperationRR: XorOpcode].
		[AddRdRd]					-> [^self concretizeAddRdRd].
		[CmpRdRd]					-> [^self concretizeCmpRdRd].
		[DivRdRd]					-> [^self concretizeDivRdRd].
		[MulRdRd]					-> [^self concretizeMulRdRd].
		[SubRdRd]					-> [^self concretizeSubRdRd].
		[SqrtRd]					-> [^self concretizeSqrtRd].
		[NegateR]						-> [^self concretizeNegateR].
		[LoadEffectiveAddressMwrR]	-> [^self concretizeLoadEffectiveAddressMwrR].
		[ArithmeticShiftRightCqR]		-> [^self concretizeArithmeticShiftRightCqR].
		[LogicalShiftRightCqR]			-> [^self concretizeLogicalShiftRightCqR].
		[LogicalShiftLeftCqR]			-> [^self concretizeLogicalShiftLeftCqR].
		[ArithmeticShiftRightRR]			-> [^self concretizeArithmeticShiftRightRR].
		[LogicalShiftLeftRR]				-> [^self concretizeLogicalShiftLeftRR].
		[LogicalShiftRightRR]			-> [^self concretizeLogicalShiftRightRR].
		"ARM Specific Arithmetic" 
		[SMULL]			-> [^self concretizeSMULL]	.
		[CMPSMULL]		-> [^self concretizeCMPSMULL].
		[MSR]				-> [^self concretizeMSR].
		"ARM Specific Data Movement"
		[PopLDM]			-> [^self concretizePushOrPopMultipleRegisters: false].
		[PushSTM]			-> [^self concretizePushOrPopMultipleRegisters: true].
		"Data Movement"
		[MoveCqR]			-> [^self concretizeMoveCqR].
		[MoveCwR]			-> [^self concretizeMoveCwR].
		[MoveRR]			-> [^self concretizeMoveRR].
		[MoveAwR]			-> [^self concretizeMoveAwR].
		[MoveRAw]			-> [^self concretizeMoveRAw].
		[MoveAbR] 			 -> [^self concretizeMoveAbR].
 		[MoveRAb]			-> [^self concretizeMoveRAb].
		[MoveMbrR]			-> [^self concretizeMoveMbrR].
		[MoveRMbr]			-> [^self concretizeMoveRMbr].
		[MoveRM16r]		-> [^self concretizeMoveRM16r].
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
		[ConvertRRd]		-> [^self concretizeConvertRRd].
			
		"Patcheable literal instruction"
		[ MovePatcheableC32R ] -> [ ^ self concretizeMovePatcheableC32R ]}
]

{ #category : #testing }
CogARMCompiler >> extractOffsetFromBL: instr [
	"we are told this is a BL <offset> instruction, so work out the offset it encodes"
	<inline: true>
	| relativeJump |
	relativeJump := instr bitAnd: 16r00FFFFFF.
	relativeJump := (relativeJump anyMask: 1<<23)
						ifTrue: [((relativeJump bitOr: 16r3F000000) << 2) signedIntFromLong]
						ifFalse: [relativeJump << 2].
	^relativeJump
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> faddd: destReg with: srcReg [
"FADDD or VADD instruction to add double srcReg to double destReg and stick result in double destReg
FADDD destReg, destReg, srcReg -  ARM_ARM v5 DDI 01001.pdf pp. C4-6
VADD.F64 destReg, destReg, srcReg - ARM_ARM v7 DDI10406.pdf pp. A8-536-7"
	<inline: true>
	^((2r11101110001100000000101100000000 bitOr: destReg<<16 ) bitOr: destReg<<12) bitOr: srcReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> fcmpFrom: regA to: regB [
"FCMPD or VCMP instruction to compare two fpu double registers.
FCMPD regA, regB - ARM_ARM v5 DDI 01001.pdf pp. C4-10
VCMP.F64 regA, regB - ARM_ARM v7 DDI10406 -1"
	<inline: true>
	^(2r11101110101101000000101101000000 bitOr:(regA <<12)) bitOr: regB
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> fcmpeFrom: regA to: regB [
	"FCMPED or VCMPE instruction to compare two fpu double registers.
FCMPED regA, regB - ARM_ARM v5 DDI 01001.pdf pp. C4-12
VCMPE.F64 regA,regB - ARM_ARM v7 DDI10406 pp. 570-1"
	<inline: true>
	^(2r11101110101101000000101111000000 bitOr: (regA <<12)) bitOr: regB
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> fdivd: dividend by: divisor [
"FDIVD or VDIV instruction to divide double dividend by double divisor and stick result in double dividend
FDIVD dividend, dividend, divisor - ARM_ARM v5 DDI 01001.pdf pp. C4-32
VDIV.F64 dvidend, dividend, divisor - ARM_ARM v7 DDI10406 pp. A8-584-5"
	<inline: true>
	^((2r11101110100000000000101100000000 bitOr: dividend<<16 ) bitOr: dividend<<12) bitOr: divisor
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> fldd: destReg rn: srcReg plus: u imm: immediate8bitValue [
"FLDD or VLDR instruction to move a value from address in an ARM srcReg +/- offset<<2 to an fpu double destReg
FLDD ARM_ARM v5 DDI 01001.pdf pp. C4-36
VLDR.64 ARM_ARM v7 DDI10406 pp. A8-622-3"
	<inline: true>
	"Note that
		offset is <<2 to make byte address 
		u =1 -> srcReg + offset<<2
		u=0 -> srgREg - offset<<2"
	^(((2r11101101000100000000101100000000 bitOr:(srcReg <<16)) bitOr: destReg<<12) bitOr: u<<23) bitOr: immediate8bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> fmsrFrom: regA to: regB [
"FMSR or VMOV instruction to move a value from an ARM reg to an fpu double register ready for conversion
FMSR regB, regA - ARM_ARM v5 DDI 01001.pdf pp. C4-68
VMOV regB, regA - ARM_ARM v7 DDi10406 pp. A8-462-3"
	<inline: true>
	|destReg|
	"the dest reg bits are spread out a little"
	destReg := (regB >>1) <<16 bitOr:(regB bitAnd: 1) << 7.
	^(2r11101110000000000000101000010000 bitOr:(regA <<12)) bitOr: destReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> fmstat [
	"FMSTAT or VMRS unconditional transfer FP status to cpsr to choose jumps etc.
FMSTAT r15, FPSCR - ARM_ARM v5 DDI 01001.pdf pp. C4-72
VMRS APSR_nzcv, FPSCR - ARM_ARM v7 DDI10406 pp. A8-652-3"
	<inline: true>
	^2r11101110111100011111101000010000
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> fmuld: destReg with: srcReg [
"FMULD or VMUL instruction to multiply double srcReg by double destReg and stick result in double destReg
FMULD destReg, destReg, srcReg - ARM_ARM v5 DDI 01001.pdf pp. C4-73
VMUL.F64 destReg, destReg, srcReg - ARM_ARM v7 DDI10406 pp A8-658-9"
	<inline: true>
	^((2r11101110001000000000101100000000 bitOr: destReg<<16 ) bitOr: destReg<<12) bitOr: srcReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> fsitodFrom: regA to: regB [
"FSITOD or VCVT instruction to move convert an integer value to an fpu double
FSITOD regB, regA - ARM_ARM v5 DDI 01001.pdf pp. C4-95
VCVTW. regB, regA - ARM_ARM v7 DDI10406.pdf pp. A8-576-8"
	<inline: true>
	|srcReg|
	"the src reg bits are spread out a little"
	srcReg := (regA >>1) bitOr:(regA bitAnd: 1) << 5.
	^(2r11101110101110000000101111000000 bitOr: srcReg ) bitOr: regB<<12
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> fsqrtd: destReg [
"FSQRTD or VSQRT instruction to square root double dividend destReg and stick result in double destReg
ARM_ARM v5 DDI 01001.pdf pp. C4-97
VSQRT.F64 destReg, destReg - ARM_ARM v7 DDI10406 pp. A8-756-7"
	<inline: true>
	^((2r11101110101100010000101111000000 ) bitOr: destReg<<12) bitOr: destReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> fstd: fpReg rn: addrReg plus: u imm: immediate8bitValue [
"FSTD or VSTR instruction to move a value to address in an ARM addrReg +/- offset<<2 from an fpu double fpReg
FSTD fpReg, addrReg, #offset - ARM_ARM v5 DDI 01001.pdf pp. C4-101
VSTR.64 fpReg, addrReg, #offset - ARM_ARM v7 DDI10406 pp. A8-780-1"
	<inline: true>
	"Note that
		offset is <<2 to make byte address 
		u =1 -> addrReg + offset<<2
		u=0 -> addrReg - offset<<2"
	^(((2r11101101000000000000101100000000 bitOr:(addrReg <<16)) bitOr: fpReg<<12) bitOr: u<<23) bitOr: immediate8bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> fsubd: destReg with: srcReg [
"FSUBD or VSUB instruction to subtract double srcReg from double destREg and stick result in double destReg
FSUBD destReg, destReg, srcReg - ARM_ARM v5 DDI 01001.pdf pp. C4-112
VSUB.F64 destReg, destReg, srcReg - ARM_ARM v7 DDI10406 pp. A8-784-5"
	<inline: true>
	^((2r11101110001100000000101101000000 bitOr: destReg<<16 ) bitOr: destReg<<12) bitOr: srcReg
]

{ #category : #abi }
CogARMCompiler >> fullCallsAreRelative [
	"Answer if CallFull and/or JumpFull are relative and hence need relocating on method
	 compation. If so, they are annotated with IsRelativeCall in methods and relocated in
	 relocateIfCallOrMethodReference:mcpc:delta:"
	^false
]

{ #category : #'abstract instructions' }
CogARMCompiler >> genDivR: abstractRegDivisor R: abstractRegDividend Quo: abstractRegQuotient Rem: abstractRegRemainder [
"Currently no instruction level support for divide on ARM. See also #canDivQuoRem"
	| rDividend rDivisor rQuotient rRemainder divRemFunctionAddr |
	<var: #divRemFunctionAddr type: #usqInt>
	self assert: abstractRegDividend ~= abstractRegDivisor.
	self assert: abstractRegQuotient ~= abstractRegRemainder.
	rDividend := abstractRegDividend.
	rDivisor := abstractRegDivisor.
	rDividend = CArg0Reg ifFalse:
		["we need to move the value in rDividend to CArg0Reg. Best to double check if rDivisor is already using it first"
		rDivisor = CArg0Reg ifTrue: "oh dear; we also need to move rDivisor's value out of the way first.. I'll move it to CArg1Reg and if some nitwit has managed to put rDividend there they deserve the crash"
			[rDividend = CArg1Reg ifTrue:
				[self error: 'register choices in genDivR:R:Quo:Rem: made life impossible'].
			cogit MoveR: rDivisor R: CArg1Reg.
			"and update rDivisor or we get buggerd by the next clause"
			rDivisor := CArg1Reg].
		cogit MoveR: rDividend R: CArg0Reg].
	rDivisor = CArg1Reg ifFalse:
		[cogit MoveR: rDivisor R: CArg1Reg].
	divRemFunctionAddr := self aeabiDivModFunctionAddr.
	self saveAndRestoreLinkRegAround:
		[cogit CallFullRT: (self cCode: [divRemFunctionAddr asUnsignedInteger]
							   inSmalltalk: [cogit simulatedTrampolineFor: divRemFunctionAddr])
			registersToBeSavedMask: (cogit registerMaskFor: CArg2Reg and: CArg3Reg)].
	"Now we need to move the r0/1 results back to rQuotient & rRemainder"
	rQuotient := abstractRegQuotient.
	rRemainder := abstractRegRemainder.
	rQuotient = CArg0Reg ifFalse: "oh good grief, not again"
		[cogit MoveR: CArg0Reg R: rQuotient.
		 rQuotient = CArg1Reg ifTrue:
			[self error: 'register choices in genDivR:R:Quo:Rem: made life impossible'] ].
	rRemainder = CArg1Reg  ifFalse:
		[cogit MoveR: CArg1Reg R: rRemainder]
				

]

{ #category : #'smalltalk calling convention' }
CogARMCompiler >> genLoadCStackPointer [
	"Load the stack pointer register with that of the C stack, effecting
	 a switch to the C stack.  Used when machine code calls into the
	 CoInterpreter run-time (e.g. to invoke interpreter primitives)."
	cogit MoveAw: cogit cStackPointerAddress R: SPReg.
	^0
]

{ #category : #'smalltalk calling convention' }
CogARMCompiler >> genLoadCStackPointers [
	"Load the frame and stack pointer registers with those of the C stack,
	 effecting a switch to the C stack.  Used when machine code calls into
	 the CoInterpreter run-time (e.g. to invoke interpreter primitives)."
	cogit MoveAw: cogit cStackPointerAddress R: SPReg.
	cogit MoveAw: cogit cFramePointerAddress R: FPReg.
	^0
]

{ #category : #'smalltalk calling convention' }
CogARMCompiler >> genLoadStackPointers [
	"Switch back to the Smalltalk stack. Assign SPReg first
	 because typically it is used immediately afterwards."
	cogit MoveAw: cogit stackPointerAddress R: SPReg.
	cogit MoveAw: cogit framePointerAddress R: FPReg.
	^0
]

{ #category : #abi }
CogARMCompiler >> genMarshallNArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 [
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
	numArgs = 0 ifTrue: [^self].
	(cogit isTrampolineArgConstant: regOrConst0)
		ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst0) R: CArg0Reg]
		ifFalse: [cogit MoveR: regOrConst0 R: CArg0Reg].
	numArgs = 1 ifTrue: [^self].
	(cogit isTrampolineArgConstant: regOrConst1)
		ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst1) R: CArg1Reg]
		ifFalse: [cogit MoveR: regOrConst1 R: CArg1Reg].
	numArgs = 2 ifTrue: [^self].
	(cogit isTrampolineArgConstant: regOrConst2)
		ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst2) R: CArg2Reg]
		ifFalse: [cogit MoveR: regOrConst2 R: CArg2Reg].
	numArgs = 3 ifTrue: [^self].
	(cogit isTrampolineArgConstant: regOrConst3)
		ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst3) R: CArg3Reg]
		ifFalse: [cogit MoveR: regOrConst3 R: CArg3Reg]
]

{ #category : #'abstract instructions' }
CogARMCompiler >> genMulR: regSource R: regDest [
	"Use SMULL to produce a 64-bit result, explicitly in RISCTempReg,regDest. - ARM_ARM v7 DDI10406 pp. A8-354-5
	 By comparing RISCTempReg with regDest ASR 31(which effectively makes it 0 or -1) we know that the result being EQ means the hi reg and the top bit of the lo reg are the same - ie no overflow. The condition code can then be forced to oVerflow by use of MSR APSR_nzcvq, #1, lsl 28"
	| first |
	<var: 'first' type: #'AbstractInstruction *'>
	first := cogit gen: SMULL operand: regSource operand: regDest. "result in RISCTempReg,regDest"
	cogit gen: CMPSMULL operand: RISCTempReg operand: regDest.
	cogit gen: MSR operand: 1.
	^first
]

{ #category : #'generate machine code' }
CogARMCompiler >> genPopRegisterMask: registersToBeSavedMask [
	<inline: true>
	^registersToBeSavedMask = 0
		ifTrue: [cogit Label]
		ifFalse: [cogit gen: PopLDM operand: registersToBeSavedMask]
]

{ #category : #'smalltalk calling convention' }
CogARMCompiler >> genPushRegisterArgsForAbortMissNumArgs: numArgs [
	"Ensure that the register args are pushed before the outer and
	 inner retpcs at an entry miss for arity <= self numRegArgs.  The
	 outer retpc is that of a call at a send site.  The inner is the call
	 from a method or PIC abort/miss to the trampoline."

	"Putting the receiver and args above the return address means the
	 CoInterpreter has a single machine-code frame format which saves
	 us a lot of work."

	"Iff there are register args convert
		sp		->	outerRetpc			(send site retpc)
		linkReg = innerRetpc			(PIC abort/miss retpc)
	 to
		base	->	receiver
					(arg0)
					(arg1)
		sp		->	outerRetpc			(send site retpc)
		sp		->	linkReg/innerRetpc	(PIC abort/miss retpc)"
	numArgs <= cogit numRegArgs ifTrue:
		[self assert: cogit numRegArgs <= 2.
		 cogit MoveMw: 0 r: SPReg R: TempReg. "Save return address"
		 cogit MoveR: ReceiverResultReg Mw: 0 r: SPReg.
		 numArgs > 0 ifTrue:
			[cogit PushR: Arg0Reg.
			 numArgs > 1 ifTrue:
				[cogit PushR: Arg1Reg]].
		cogit PushR: TempReg]. "push back return address"
	cogit PushR: LinkReg
]

{ #category : #'smalltalk calling convention' }
CogARMCompiler >> genPushRegisterArgsForNumArgs: numArgs scratchReg: ignored [
	"Ensure that the register args are pushed before the retpc for arity <= self numRegArgs."
	"This is easy on a RISC like ARM because the return address is in the link register.  Putting
	 the receiver and args above the return address means the CoInterpreter has a single
	 machine-code frame format which saves us a lot of work
	NOTA BENE: we do NOT push the return address here, which means it must be dealt with later."
	numArgs <= cogit numRegArgs ifTrue:
		[self assert: cogit numRegArgs <= 2.
		 cogit PushR: ReceiverResultReg.
		numArgs > 0 ifTrue:
			[cogit PushR: Arg0Reg.
			 numArgs > 1 ifTrue:
				[cogit PushR: Arg1Reg]]]
]

{ #category : #'generate machine code' }
CogARMCompiler >> genPushRegisterMask: registersToBeSavedMask [
	<inline: true>
	^registersToBeSavedMask = 0
		ifTrue: [cogit Label]
		ifFalse: [cogit gen: PushSTM operand: registersToBeSavedMask]
]

{ #category : #abi }
CogARMCompiler >> genRemoveNArgsFromStack: n [
	"This is a no-op on ARM since the ABI passes up to 4 args in registers and trampolines currently observe that limit."
	<inline: true>
	self assert: n <= 4.
	^0
]

{ #category : #abi }
CogARMCompiler >> genRestoreRegs: regMask [
	"Restore the registers in regMask as saved by genSaveRegs:."
	<inline: true>
	^self genPopRegisterMask: regMask
]

{ #category : #abi }
CogARMCompiler >> genSaveRegForCCall [
	"Save the general purpose registers for a call into the C run-time from a trampoline."
	"Save none, because the ARM ABI only defines callee saved registers, no caller-saved regs."
	"cogit gen: STMFD operand: 16r7F"
]

{ #category : #abi }
CogARMCompiler >> genSaveRegs: regMask [
	"Save the registers in regMask for a call into the C run-time from a trampoline"
	<inline: true>
	^self genPushRegisterMask: regMask
]

{ #category : #'smalltalk calling convention' }
CogARMCompiler >> genSaveStackPointers [
	"Save the frame and stack pointer registers to the framePointer
	 and stackPointer variables.  Used to save the machine code frame
	 for use by the run-time when calling into the CoInterpreter run-time."
	cogit MoveR: FPReg Aw: cogit framePointerAddress.
	cogit MoveR: SPReg Aw: cogit stackPointerAddress.
	^0
]

{ #category : #'abstract instructions' }
CogARMCompiler >> genSubstituteReturnAddress: retpc [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^cogit MoveCw: retpc R: LR
]

{ #category : #disassembly }
CogARMCompiler >> generalPurposeRegisterMap [
	<doNotGenerate>
	"Answer a Dictionary from register getter to register index."
	^Dictionary newFromPairs:
		{	#r0. R0.
			#r1. R1.
			#r2. R2.
			#r3. R3.
			#r4. R4.
			#r5. R5.
			#r6. R6.
			#r7. R7.
			#r8. R8.
			#r9. R9.
			#r10. R10.
			#r11. R11.
			#r12. R12	}
]

{ #category : #testing }
CogARMCompiler >> hasConditionRegister [
	"Answer if the receiver supports, e.g., JumpOverflow after a regular AddRR"
	^true
]

{ #category : #testing }
CogARMCompiler >> hasDoublePrecisionFloatingPointSupport [
	"might be true, but is for the forseeable future disabled"
	^true
]

{ #category : #testing }
CogARMCompiler >> hasLinkRegister [
	^true "lr"
]

{ #category : #testing }
CogARMCompiler >> hasPCDependentInstruction [
	"e.g. B, BL: Branch, Branch and Link"
	^true
]

{ #category : #testing }
CogARMCompiler >> hasPCRegister [
	"Answer if the processor has a generally addressable pc register, which ARM does."
	^true
]

{ #category : #testing }
CogARMCompiler >> hasThreeAddressArithmetic [
	"Answer if the receiver supports three-address arithmetic instructions (currently only AndCqRR)"
	^true
]

{ #category : #testing }
CogARMCompiler >> hasVarBaseRegister [
	"Answer if the processor has a dedicated callee-saved register to point to
	 the base of commonly-accessed variables. On ARM we use R10 for this."
	^true "r10/sl"
]

{ #category : #'generate machine code' }
CogARMCompiler >> initialize [
	"This method intializes the Smalltalk instance.  The C instance is merely a struct and doesn't need initialization."
	<doNotGenerate>
	operands := CArrayAccessor on: (Array new: NumOperands).
	machineCode := CArrayAccessor on: (Array new: self machineCodeWords)
]

{ #category : #'inline cacheing' }
CogARMCompiler >> inlineCacheTagAt: callSiteReturnAddress [
	"Answer the inline cache tag for the return address of a send."
	^self subclassResponsibility
]

{ #category : #'inline cacheing' }
CogARMCompiler >> instructionAddressBefore: followingAddress [
	"Answer the instruction address immediately preceding followingAddress."
	<inline: true>
	^followingAddress -4
]

{ #category : #'inline cacheing' }
CogARMCompiler >> instructionBeforeAddress: followingAddress [
	"Answer the instruction immediately preceding followingAddress."
	<inline: true>
	^objectMemory longAt: (self instructionAddressBefore: followingAddress)
]

{ #category : #testing }
CogARMCompiler >> instructionIsB: instr [
"is this a B <offset> instruction?"
	^(self conditionIsNotNever: instr) and: [(instr bitAnd: (16rF<<24)) = (16rA<<24)]
]

{ #category : #testing }
CogARMCompiler >> instructionIsBL: instr [
"is this a BL <offset> instruction?"
	^(self conditionIsNotNever: instr)  and: [(instr bitAnd: (16rF<<24)) = (16rB<<24)]
]

{ #category : #testing }
CogARMCompiler >> instructionIsBLX: instr [
"is this a BLX <targetReg> instruction?"
	^(self conditionIsNotNever: instr)  and: [(instr bitAnd: 16r0FFFFFF0) = 16r12FFF30]
]

{ #category : #testing }
CogARMCompiler >> instructionIsBX: instr [
"is this a BX <targetReg> instruction?"
	^(self conditionIsNotNever: instr) and: [(instr bitAnd: 16r0FFFFFF0) = 16r12FFF10]
]

{ #category : #testing }
CogARMCompiler >> instructionIsCMP: instr [
	"is this a CMP instruction?"
	^(self conditionIsNotNever: instr) and: [(instr >> 21 bitAnd: 16r7F) = CmpOpcode]
]

{ #category : #testing }
CogARMCompiler >> instructionIsLDR: instr [
	"is this any kind of LDR instruction? c.f. memMxr:reg:base:u:b:l:imm:"
	^(self conditionIsNotNever: instr) and: [(instr >> 20 bitAnd: 16rC5) = 16r41] "ldr r1, [r2, #+/-imm] or ldr r1, [r2, r3]"
]

{ #category : #testing }
CogARMCompiler >> instructionIsOR: instr [
	"is this an ORR instruction?"
	^(self conditionIsNotNever: instr)  and:[(instr >> 21 bitAnd: 16r7F) = (16r10 bitOr: OrOpcode)]
]

{ #category : #testing }
CogARMCompiler >> instructionIsPush: instr [
	"is this a push -str r??, [sp, #-4] -  instruction?"
	^(self conditionIsNotNever: instr) and: [(instr bitAnd: 16rFFF0FFF) = 16r52D0004]
]

{ #category : #disassembly }
CogARMCompiler >> instructionSizeAt: pc [
	"Answer the instruction size at pc.Simple on ARM ;-)"
	^4
]

{ #category : #'generate machine code - support' }
CogARMCompiler >> inverseOpcodeFor: armOpcode [
	"Several of the opcodes are inverses.  Answer the inverse for an opcode if it has one.
	 See Table A3-2 in sec A3.4 Data-processing instructions of the AARM."
	^armOpcode caseOf: {
			[AddOpcode]		->	[SubOpcode].
			[AndOpcode]		->	[BicOpcode].
			[BicOpcode]		->	[AndOpcode].
			[CmpOpcode]		->	[CmpNotOpcode].
			[MoveOpcode]		->	[MoveNotOpcode].
			[MoveNotOpcode]	->	[MoveOpcode].
			[SubOpcode]		->	[AddOpcode] }
		otherwise:
			[self error: 'opcode has no inverse'.
			 -1]
]

{ #category : #testing }
CogARMCompiler >> is12BitValue: constant ifTrue: trueAlternativeBlock	ifFalse: falseAlternativeBlock [
	"For LDR and STR, there is an instruction allowing for one instruction encoding if the offset is encodable in signed 12 bit form. pass the trueBlock the value and a 1-bit flag to tell it the sign.
	The falseBlock can do whatever it needs to, typically building the constant as a full 32bit value and then ld/st with that as a register offset"
	<inline: true>
	constant abs <= 4095 "(2 raisedTo: 12)-1"
		ifTrue:
			[constant >= 0 
				ifTrue: [^trueAlternativeBlock value: 1 value: constant]
				ifFalse: [^trueAlternativeBlock value: 0 value: constant abs]]
		ifFalse: [^falseAlternativeBlock value]
]

{ #category : #testing }
CogARMCompiler >> is8BitValue: constant ifTrue: trueAlternativeBlock	ifFalse: falseAlternativeBlock [
	"For extended LDR and STR for half & double, there is an instruction allowing for one instruction encoding if the offset is encodable in 8 bit."
	<inline: true>
	constant abs <= 255 "(2 raisedTo: 8)-1"
		ifTrue:
			[constant >= 0 
				ifTrue: [trueAlternativeBlock value: 1 value: constant]
				ifFalse: [trueAlternativeBlock value: 0 value: constant abs]]
		ifFalse: falseAlternativeBlock
]

{ #category : #testing }
CogARMCompiler >> isAddressRelativeToVarBase: varAddress [
	<inline: true>
	<var: #varAddress type: #usqInt>
	"Support for addressing variables off the dedicated VarBaseReg"
	^varAddress notNil
	  and: [varAddress >= cogit varBaseAddress
	  and: [varAddress - cogit varBaseAddress < (1 << 12)]]
]

{ #category : #testing }
CogARMCompiler >> isBigEndian [
	^false
]

{ #category : #testing }
CogARMCompiler >> isCallPrecedingReturnPC: mcpc [
	"Assuming mcpc is a send return pc answer if the instruction before it is a call (not a CallFull)."
	"There are two types of calls: BL and/BLX encoding"
	| call |
	call := self instructionBeforeAddress: mcpc.
	^(self instructionIsBL: call) or:[self instructionIsBLX: call]
]

{ #category : #testing }
CogARMCompiler >> isInImmediateJumpRange: operand [
	"ARM calls and jumps span +/- 32 mb, more than enough for intra-zone calls and jumps."
	<var: #operand type: #'usqIntptr_t'>
	^operand signedIntFromLong between: -16r2000000 and: 16r1FFFFFC
]

{ #category : #testing }
CogARMCompiler >> isJumpAt: pc [
	| instr |
	instr := objectMemory long32At: pc.
	^(self instructionIsB: instr)
	  or: [self instructionIsBX: instr]
]

{ #category : #testing }
CogARMCompiler >> isPCRelativeValueLoad: instr [
	<var: 'instr' type: #'unsigned int'>
	"add xx, pc, blah or sub xx, pc, blah"
	^(instr >> 16) = 16rE28F or: [instr >> 16 = 16rE24F]
]

{ #category : #accessing }
CogARMCompiler >> jumpLongByteSize [
"	Branch/Call ranges.  Jump[Cond] can be generated as short as possible.  Call/Jump[Cond]Long must be generated
	in the same number of bytes irrespective of displacement since their targets may be updated, but they need only
	span 16Mb, the maximum size of the code zone.  This allows e.g. ARM to use single-word call and jump instructions
	for most calls and jumps.  CallFull/JumpFull must also be generated in the same number of bytes irrespective of
	displacement for the same reason, but they must be able to span the full (32-bit or 64-bit) address space because
	they are used to call code in the C runtime, which may be distant from the code zone"
	^4
]

{ #category : #accessing }
CogARMCompiler >> jumpLongConditionalByteSize [
	^self jumpLongByteSize
]

{ #category : #'inline cacheing' }
CogARMCompiler >> jumpLongTargetBeforeFollowingAddress: mcpc [ 
	"Answer the target address for the long jump immediately preceding mcpc"
	^self callTargetFromReturnAddress: mcpc
]

{ #category : #disassembly }
CogARMCompiler >> jumpTargetPCAt: pc [
	<returnTypeC: #usqInt>
	| operand word |
	word := objectMemory long32At: pc.
	operand := word bitAnd: 16rFFFFFF.
	(operand anyMask: 16r800000) ifTrue:
		[operand := operand - 16r1000000].
	^self
		cCode: [operand * 4 + pc + 8]
		inSmalltalk: [operand * 4 + pc + 8 bitAnd: cogit addressSpaceMask]
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> ldr: destReg rn: baseReg plus: u imm: immediate12bitValue [
"	LDR destReg, [baseReg, immediate12bitValue] u=0 -> subtract imm; =1 -> add imm  - ARM_ARM v7 DDI10406 pp. A8-120-1"
	^self memMxr: AL reg: destReg  base: baseReg u: u b: 0 l: 1 imm: immediate12bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> ldr: destReg rn: baseReg plusImm: immediate12bitValue [
"	LDR destReg, [baseReg, +immediate12bitValue] - ARM_ARM v7 DDI10406 pp. A8-120-1"
	^self memMxr: AL reg: destReg  base: baseReg u: 1 b: 0 l: 1 imm: immediate12bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> ldr: destReg rn: baseReg rm: offsetReg [
"	LDR destReg, [baseReg, + offsetReg]  - ARM_ARM v7 DDI10406 pp. A8-124-5
	The contents of offsetReg are assumed to be correctly signed"
	^self memMxr: AL reg: destReg  base: baseReg p: 1 u: 1 b: 0 w: 0 l: 1 rm: offsetReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> ldrb: destReg rn: baseReg plus: u imm: immediate12bitValue [
"	LDRB destReg, [baseReg, 'u' immediate12bitValue] u=0 ->  - ARM_ARM v7 DDI10406 pp. A8-128-9
	Note that this is a very low level interface that does not check the sign of the immediate, nor validity. See for example #concretizeMoveMbrR"
	^self memMxr: AL reg: destReg  base: baseReg u: u b: 1 l: 1 imm: immediate12bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> ldrb: destReg rn: baseReg rm: offsetReg [
"	LDRB destReg, [baseReg, + offsetReg]  - ARM_ARM v7 DDI10406 pp. A8-132-3
	The contents of offsetReg are assumed to be correctly signed"
	^self memMxr: AL reg: destReg  base: baseReg p: 1 u: 1 b: 1 w: 0 l: 1 rm: offsetReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> ldrh: destReg rn: baseReg plus: u imm: immediate8bitValue [
"	LDRH destReg, [baseReg, 'u' immediate8bitValue] u=0 -> subtract imm; =1 -> add imm  - ARM_ARM v7 DDI10406 pp. A8-152-3"
	^self memM16xr: AL reg: destReg  base: baseReg p: 1 u: u  w: 0 l: 1 offset: immediate8bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> ldrh: destReg rn: baseReg rm: offsetReg [
"	LDRH destReg, [baseReg, +offsetReg]  - ARM_ARM v7 DDI10406 pp. A8-156-7
	The contents of offsetReg are assumed to be correctly signed"
	^self memM16xr: AL reg: destReg  base: baseReg p: 1 u: 1  w: 0 l: 1 rm: offsetReg
]

{ #category : #abi }
CogARMCompiler >> leafCallStackPointerDelta [
	"Answer the delta from the stack pointer after a call to the stack pointer
	 immediately prior to the call.  This is used to compute the stack pointer
	 immediately prior to  call from within a leaf routine, which in turn is used
	 to capture the c stack pointer to use in trampolines back into the C run-time."
	"This might actually be false, since directly after a call, lr, fp and variable registers need be pushed onto the stack. It depends on the implementation of call."
	^0
]

{ #category : #accessing }
CogARMCompiler >> literalLoadInstructionBytes [
	"Answer the size of a literal load instruction (which may or may not include the size of the literal).
	 This differs between in-line and out-of-line literal generation."
	<inline: true>
	^self subclassResponsibility
]

{ #category : #'generate machine code - support' }
CogARMCompiler >> loadCwInto: destReg [
	"Load the operand into the destination register, answering
	 the size of the instructions generated to do so."
	| operand distance |
	operand := operands at: 0.
	self cCode:[] inSmalltalk:[operand := operand bitAnd: 16rFFFFFFFF]. "Need to clamp the value to a word size since one or two usages actually generate double sized values and rely upon the C code to narrow it within the running VM"
	(self isAnInstruction: (cogit cCoerceSimple: operand to: #'AbstractInstruction *')) ifTrue:
		[operand := (cogit cCoerceSimple: operand to: #'AbstractInstruction *') address].
	"First try and encode as a pc-relative reference..."
	(cogit addressIsInCurrentCompilation: operand) ifTrue:
		[distance := operand - (address + 8).
		 self rotateable8bitSignedImmediate: distance
		 	ifTrue:
				[:rot :immediate :negate|
		 		 self machineCodeAt: 0 put: (negate
												ifTrue: [self sub: destReg rn: PC imm: immediate ror: rot]
												ifFalse: [self add: destReg rn: PC imm: immediate ror: rot]).
		 		^4]
		 	ifFalse:
		 		[self deny: (self isAnInstruction: (cogit cCoerceSimple: (operands at: 0) to: #'AbstractInstruction *'))]].
	"If this fails, use the conventional literal load sequence."
	^self moveCw: operand intoR: destReg
]

{ #category : #accessing }
CogARMCompiler >> loadPICLiteralByteSize [
	"Answer the byte size of a MoveCwR opcode's corresponding machine code
	 when the argument is a PIC.  This is for the self-reference at the end of a
	 closed PIC.  On ARM this is a single instruction pc-relative register load."
	^4
]

{ #category : #accessing }
CogARMCompiler >> machineCodeAt: anOffset [
	"read aWord from machineCode, with little endian"
	<inline: true>
	^machineCode at: anOffset // 4
]

{ #category : #accessing }
CogARMCompiler >> machineCodeAt: anOffset put: aWord [
	"add aWord to machineCode, with little endian"
	<inline: true>
	machineCode at: anOffset // 4 put: aWord
]

{ #category : #'generate machine code' }
CogARMCompiler >> machineCodeBytes [
	"Answer the maximum number of bytes of machine code generated for any abstract instruction.
	 e.g. CmpCwR =>
			mov R3, #<addressByte1>, 12
			orr R3, R3, #<addressByte2>, 8
			orr R3, R3, #<addressByte3>, 4
			orr R3, R3, #<addressByte4>, 0
			cmp R?, R3"
	^20
]

{ #category : #'generate machine code' }
CogARMCompiler >> machineCodeWords [
	"Answer the maximum number of words of machine code generated for any abstract instruction.
	 e.g. CmpCwR =>
			mov R3, #<addressByte1>, 12
			orr R3, R3, #<addressByte2>, 8
			orr R3, R3, #<addressByte3>, 4
			orr R3, R3, #<addressByte4>, 0
			cmp R?, R3"
	^5
]

{ #category : #encoding }
CogARMCompiler >> memM16xr: cond reg: destReg base: baseReg p: postpreoffset u: updown w: weirdstuff l: loadstore offset: offset8 [ 
	"build an ARM [base +/- offset8]  half-word memory instruction
	p -> pre-index (1) or post-index (0) the offset. Combines with W to do some odd things.
	u -> up (1) or down (0) ie + or - for the offset
	b -> byte(1) or word (0)
	w -> write-back (1) if pre-indexing. 
	l -> load (1) or store (0)"
	^ cond << 28
		bitOr: (0 << 25
		bitOr: (postpreoffset << 24
		bitOr: (updown << 23
		bitOr: (1 << 22
		bitOr: (weirdstuff << 21
		bitOr: (loadstore << 20
		bitOr: (baseReg << 16
		bitOr: (destReg << 12 
		bitOr: ((offset8 bitAnd: 16rF0) << 4
		bitOr: (11 << 4
		bitOr: (offset8 bitAnd: 16rF)))))))))))
]

{ #category : #encoding }
CogARMCompiler >> memM16xr: cond reg: destReg base: baseReg p: postpreoffset u: updown w: weirdstuff l: loadstore rm: offsetReg [ 
	"build an ARM [base +/- offsetReg] memory instruction
	p -> pre-index (1) or post-index (0) the offset. Combines with W to do some odd things.
	u -> up (1) or down (0) ie + or - for the offset
	b -> byte(1) or word (0)
	w -> write-back (1) if pre-indexing. 
	l -> load (1) or store (0)"
	^ cond << 28
		bitOr: (0 << 25
		bitOr: (postpreoffset << 24
		bitOr: (updown << 23
		bitOr: (0 << 22
		bitOr: (weirdstuff << 21
		bitOr: (loadstore << 20
		bitOr: (baseReg << 16
		bitOr: (destReg << 12 
		bitOr: (16rB0
		bitOr: offsetReg)))))))))
]

{ #category : #encoding }
CogARMCompiler >> memMxr: cond reg: destReg base: baseReg p: postpreoffset u: updown b: byteword w: weirdstuff l: loadstore imm: offset [
	"build an ARM [base +/- offset] memory instruction
	p -> pre-index (1) or post-index (0) the offset. Combines with W to do some odd things.
	u -> up (1) or down (0) ie + or - for the offset
	b -> byte(1) or word (0)
	w -> write-back (1) if pre-indexing. 
	l -> load (1) or store (0)"
	^ cond << 28
		bitOr: (2 << 25
		bitOr: (postpreoffset << 24
		bitOr: (updown << 23
		bitOr: (byteword << 22
		bitOr: (weirdstuff << 21
		bitOr: (loadstore << 20
		bitOr: (baseReg << 16
		bitOr: (destReg << 12 bitOr: offset))))))))
]

{ #category : #encoding }
CogARMCompiler >> memMxr: cond reg: destReg base: baseReg p: postpreoffset u: updown b: byteword w: weirdstuff l: loadstore rm: offsetReg [ 
	"build an ARM [base +/- offsetReg] memory instruction
	p -> pre-index (1) or post-index (0) the offset. Combines with W to do some odd things.
	u -> up (1) or down (0) ie + or - for the offset
	b -> byte(1) or word (0)
	w -> write-back (1) if pre-indexing. 
	l -> load (1) or store (0)"
	^ (cond bitAnd: 16rF)  << 28
		bitOr: (3 << 25
		bitOr: ((postpreoffset  bitAnd: 1) << 24
		bitOr: ((updown bitAnd: 1) << 23
		bitOr: ((byteword bitAnd: 1) << 22
		bitOr: ((weirdstuff bitAnd: 1) << 21
		bitOr: ((loadstore bitAnd: 1) << 20
		bitOr: ((baseReg bitAnd: 16rF) << 16
		bitOr: ((destReg bitAnd: 16rF) << 12 
		bitOr: (offsetReg bitAnd: 16rF)))))))))
]

{ #category : #encoding }
CogARMCompiler >> memMxr: cond reg: destReg base: baseReg p: postpreoffset u: updown b: byteword w: weirdstuff l: loadstore rmLsl2: offsetReg [ 
	"build an ARM [base +/- offsetReg lsl #2] memory instruction - see also #memMxr:reg:base:p:u:b:w:l:rm: and keep them correlated properly
	p -> pre-index (1) or post-index (0) the offset. Combines with W to do some odd things.
	u -> up (1) or down (0) ie + or - for the offset
	b -> byte(1) or word (0)
	w -> write-back (1) if pre-indexing. 
	l -> load (1) or store (0)"
	^ (cond bitAnd: 16rF)  << 28
		bitOr: (3 << 25
		bitOr: ((postpreoffset  bitAnd: 1) << 24
		bitOr: ((updown bitAnd: 1) << 23
		bitOr: ((byteword bitAnd: 1) << 22
		bitOr: ((weirdstuff bitAnd: 1) << 21
		bitOr: ((loadstore bitAnd: 1) << 20
		bitOr: ((baseReg bitAnd: 16rF) << 16
		bitOr: ((destReg bitAnd: 16rF) << 12
		bitOr: (16r100
		bitOr: (offsetReg bitAnd: 16rF))))))))))
]

{ #category : #encoding }
CogARMCompiler >> memMxr: cond reg: destReg  base: baseReg u: updown b: byteword l: loadstore imm: immediate12bitValue [
"This is the lowest level build of an ARM [base +/- immediate 12bit offset] memory instruction
u -> up (1) or down (0) ie + or - for the offset
b -> byte(1) or word (0)
l -> load (1) or store (0)"

	^ (cond bitAnd: 16rF) << 28
		bitOr: (5<<24
		bitOr: ((updown bitAnd: 1) << 23
		bitOr:((byteword bitAnd: 1) <<22
		bitOr:((loadstore bitAnd: 1) <<20
		bitOr:((baseReg bitAnd: 16rF) <<16
		bitOr:((destReg bitAnd: 16rF) <<12
		bitOr: (immediate12bitValue bitAnd: 16rFFF)))))))
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> mov: destReg imm: immediate8bitValue ror: rot [
	"Remember the ROR is doubled by the cpu so use 30>>1 etc.
	MOV destReg, #immediate8BitValue ROR rot - ARM_ARM v7 DDI10406 pp. A8-194-5"
	^self type: 1 op: MoveOpcode set: 0 rn: 0 rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate8bitValue)
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> mov: destReg rn: srcReg [
"	MOV destReg, srcReg - ARM_ARM v7 DDI10406 pp. A8-196-7"

	^self type: 0 op: MoveOpcode set: 0 rn: 0 rd: destReg shifterOperand: srcReg
]

{ #category : #'generate machine code - support' }
CogARMCompiler >> moveCw: constant intoR: destReg [
	"Emit a load of aWord into destReg.  Answer the number of bytes of machine code generated."
	 <var: 'constant' type: #usqInt>
	<inline: true>
	^self subclassResponsibility
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> movs: destReg rn: srcReg [
"	MOVS destReg, srcReg - ARM_ARM v7 DDI10406 pp. A8-196-7"

	^self type: 0 op: MoveOpcode set: 1 rn: 0 rd: destReg shifterOperand: srcReg
]

{ #category : #encoding }
CogARMCompiler >> msr: flags [
"Generate an MSR CPSR_f, #flags instruction.
Note that 
a) CPSR_f is equivalent to APSR_nzcvq (ARM ARM DDI0406A p A8-209 & A2-14)
b) We only have business with the NZCV flags so the generated instruction shifts the flags value <<28 - which is a ROR 4"

	^16r1328F000
	+ (2 "rotate rights are in units of 2, remember" << 8)
	+ (flags bitAnd: 16rF) " to make sure we don't have silly values here"
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> mvn: destReg imm: immediate8bitValue ror: rot [
	"Remember the ROR is doubled by the cpu so use 30>>1 etc.
	MVN destReg, #immediate8BitValue ROR rot - ARM_ARM v7 DDI10406 pp. A8-214-5"
	^self type: 1 op: MoveNotOpcode set: 0 rn: 0 rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate8bitValue)
]

{ #category : #printing }
CogARMCompiler >> nameForFPRegister: reg [ "<Integer>"
	<doNotGenerate>
	(reg between: 0 and: 7) ifTrue:
		[^#(D0 D1 D2 D3 D4 D5 D6 D7) at: reg + 1].
	^super nameForFPRegister: reg
]

{ #category : #printing }
CogARMCompiler >> nameForRegister: reg [ "<Integer>"
	<doNotGenerate>
	| default |
	default := super nameForRegister: reg.
	^default last = $?
		ifTrue:
			[#(LR SP PC CArg0Reg CArg0Reg CArg1Reg CArg2Reg CArg3Reg)
				detect: [:sym| (thisContext method methodClass classPool at: sym) = reg] 
				ifNone: [default]]
		ifFalse:
			[default]
]

{ #category : #'inline cacheing' }
CogARMCompiler >> numICacheFlushOpcodes [
	"ARM needs to do icache flushing when code is written"
	"for now return 0 to skip it and probably blow up"
	^0
	
]

{ #category : #accessing }
CogARMCompiler >> numIntRegArgs [
	^4
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> orr: destReg imm: immediate8bitValue ror: rot [
	"Remember the ROR is doubled by the cpu so use 30>>1 etc.
	ORR destReg, #immediate8BitValue ROR rot - ARM_ARM v7 DDI10406 pp. A8-228-9"
	^self type: 1 op: OrOpcode set: 0 rn: destReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate8bitValue)
]

{ #category : #'generate machine code' }
CogARMCompiler >> outputMachineCodeAt: targetAddress [
	"Override to move machine code a word at a time."
	<inline: true>
	0 to: machineCodeSize - 1 by: 4 do:
		[:j|
		objectMemory longAt: targetAddress + j put: (machineCode at: j // 4)]
]

{ #category : #'generate machine code' }
CogARMCompiler >> padIfPossibleWithStopsFrom: startAddr to: endAddr [
	| nullBytes |
	nullBytes := (endAddr - startAddr + 1) \\ 4.
	self stopsFrom: startAddr to: endAddr - nullBytes.
	endAddr - nullBytes + 1 to: endAddr 
		do: [ :p | objectMemory byteAt: p put: 16rFF]
]

{ #category : #encoding }
CogARMCompiler >> pld: baseReg plus: u offset: immediate [
	"hint to memory that we will want to read from baseReg +/- imediate sometime soon
	PLD baseReg, immediate  - ARM_ARM v7 DDI10406 pp. A8-236-7"
	<inline: true>
	^ 2r11110101010100001111000000000000 bitOr: (baseReg<<16 bitOr:(u <<23 bitOr: immediate))
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> popR: dstReg [
"	pop word off TOS
	LDR srcReg, [sp] #4 - ARM_ARM v7 DDI10406 pp. A8-120-1"
	^self memMxr: AL reg: dstReg base: SP p: 0 u: 1 b: 0 w: 0 l: 1 imm: 4
]

{ #category : #'calling C function in Smalltalk stack' }
CogARMCompiler >> prepareStackToCallCFunctionInSmalltalkStack: anObject [

	"ARMv5 should be aligned to 16 bytes"

	cogit MoveR: SPReg R: Extra1Reg.
	cogit MoveR: SPReg R: Extra2Reg.
	
	cogit AndCq: ((1 << 32) - 16) R: Extra2Reg. 
	cogit MoveR: Extra2Reg R: SPReg.
]

{ #category : #accessing }
CogARMCompiler >> pushLinkRegisterByteSize [
	^4
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> pushR: srcReg [
"	push word to TOS 
	STR srcReg, [sp, #-4]! - ARM_ARM v7 DDI10406 pp. A8-382-3"
	^self memMxr: AL reg: srcReg base: SP p: 1 u: 0 b: 0 w: 1l: 0 imm: 4
]

{ #category : #'inline cacheing' }
CogARMCompiler >> relocateCallBeforeReturnPC: retpc by: delta [
	| instr distanceDiv4 |
	self assert: delta \\ 4 = 0.
	delta ~= 0 ifTrue:
		[instr := self instructionBeforeAddress: retpc.
		 self assert: ((self instructionIsB: instr) or: [self instructionIsBL: instr]).
		 distanceDiv4 := instr bitAnd: 16rFFFFFF.
		 distanceDiv4 := distanceDiv4 + (delta // 4).
		 objectMemory longAt: (self instructionAddressBefore: retpc ) put: ((instr bitAnd: 16rFF000000) bitOr: (distanceDiv4 bitAnd: 16rFFFFFF))]
]

{ #category : #'calling C function in Smalltalk stack' }
CogARMCompiler >> returnFromCallCFunctionInSmalltalkStack: anObject [

	cogit MoveR: Extra1Reg R: SPReg.

]

{ #category : #'inline cacheing' }
CogARMCompiler >> rewriteCPICJumpAt: addressFollowingJump target: jumpTargetAddr [
	"Rewrite a jump instruction to call a different target.  This variant is used to reset the 
	jumps in the prototype CPIC to suit each use,.   
	Answer the extent of the code change which is used to compute the range of the icache to flush."
	<var: #addressFollowingJump type: #usqInt>
	<var: #jumpTargetAddr type: #usqInt>
	<inline: true>
	^self rewriteTransferAt: addressFollowingJump target: jumpTargetAddr
]

{ #category : #'inline cacheing' }
CogARMCompiler >> rewriteCallAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a call instruction to call a different target.  This variant is used to link PICs
	 in ceSendMiss et al,.   
	Answer the extent of the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	^self rewriteTransferAt: callSiteReturnAddress target: callTargetAddress
]

{ #category : #'inline cacheing' }
CogARMCompiler >> rewriteCallFullAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a callFull instruction to jump to a different target.  This variant
	 is used to rewrite cached primitive calls where we load the target address into ip
	and use the 'blx ip' instruction for the actual call.
	Answer the extent of the
	 code change which is used to compute the range of the icache to flush."
	<inline: true>
	^self
		rewriteFullTransferAt: callSiteReturnAddress
		target: callTargetAddress
		expectedInstruction: 16rE12FFF3C
]

{ #category : #'inline cacheing' }
CogARMCompiler >> rewriteFullTransferAt: callSiteReturnAddress target: callTargetAddress expectedInstruction: expectedInstruction [
	"Rewrite a CallFull or JumpFull instruction to transfer to a different target.
	 This variant is used to rewrite cached primitive calls.   Answer the extent
	 of the code change which is used to compute the range of the icache to flush."
	^self subclassResponsibility
]

{ #category : #'inline cacheing' }
CogARMCompiler >> rewriteInlineCacheAt: callSiteReturnAddress tag: cacheTag target: callTargetAddress [
	"Rewrite an inline cache to call a different target for a new tag.  This variant is used
	 to link unlinked sends in ceSend:to:numArgs: et al.  Answer the extent of the code
	 change which is used to compute the range of the icache to flush."
	
	^self subclassResponsibility
]

{ #category : #'inline cacheing' }
CogARMCompiler >> rewriteJumpFullAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a full jump instruction to jump to a different target.  This variant
	 is used to rewrite cached primitive calls where we load the target address into ip
	and use the 'bx ip' instruction for the actual jump.
	Answer the extent of the
	 code change which is used to compute the range of the icache to flush."
	<inline: true>
	^self
		rewriteFullTransferAt: callSiteReturnAddress
		target: callTargetAddress
		expectedInstruction: 16rE12FFF1C
]

{ #category : #'inline cacheing' }
CogARMCompiler >> rewriteJumpLongAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a jump instruction to call a different target.  This variant is used to reset the 
	jumps in the prototype CPIC to suit each use,.   
	Answer the extent of the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	^self rewriteTransferAt: callSiteReturnAddress target: callTargetAddress
]

{ #category : #'inline cacheing' }
CogARMCompiler >> rewriteTransferAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a call/jump instruction to call a different target.  This variant is used to link PICs
	 in ceSendMiss et al, and to rewrite call/jumps in CPICs.
	Answer the extent of
	 the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	| callDistance instr |
	"for debug - [cogit disassembleFrom: callSiteReturnAddress - 10 to: callSiteReturnAddress - 1]."
	false
		ifTrue: [self assert: callTargetAddress >= cogit minCallAddress]
		ifFalse: [callTargetAddress >= cogit minCallAddress ifFalse:
					[self error: 'linking callsite to invalid address']].

	callDistance := (callTargetAddress - (callSiteReturnAddress + 8 "pc offset"- 4 "return offset")) signedIntToLong.
	self assert: (self isInImmediateJumpRange: callDistance). "we don't support long call updates, yet"

	instr := self instructionBeforeAddress: callSiteReturnAddress.
	self assert: ((self instructionIsB: instr) or: [self instructionIsBL: instr]).
	
	objectMemory longAt:  (self instructionAddressBefore: callSiteReturnAddress) put: ((instr bitAnd: 16rFF000000) bitOr: (callDistance // 4 bitAnd: 16rFFFFFF)).

	self assert: (self callTargetFromReturnAddress: callSiteReturnAddress) = callTargetAddress.

	^4
]

{ #category : #testing }
CogARMCompiler >> rotateable8bitBitwiseImmediate: constant ifTrue: trueAlternativeBlock ifFalse: falseAlternativeBlock [
	<inline: true>
	"Invoke trueAlternativeBlock with shift, value and inverted if constant can be represented
	 by a possibly rotated 8-bit constant, otherwise invoke falseAlternativeBlock. For data
	 processing operands, there is the immediate shifter_operand variant,  where an 8 bit value
	 is ring shifted _right_ by i. This is only suitable for quick constants (Cq), which won't change."
	| value |
	value := constant.
	[(value bitAnd: 16rFF) = value ifTrue:
		[^trueAlternativeBlock value: 0 value: value value: constant ~= value].
	 2 to: 30 by: 2 do:
		[:i |
		(value bitAnd: ((16rFF <<i bitAnd:16rFFFFFFFF) bitOr: 16rFF>>(32-i))) = value ifTrue:
			[^trueAlternativeBlock
				value: 32 - i
				value: ((value >> i) bitOr: (value <<(32 - i) bitAnd:16rFFFFFFFF))
				value: constant ~= value]].
	 value = constant]
		whileTrue:
			[value := constant < 0
						ifTrue:[-1 - constant]
						ifFalse:[constant bitInvert32]].
	^falseAlternativeBlock value
]

{ #category : #testing }
CogARMCompiler >> rotateable8bitImmediate: constant ifTrue: trueAlternativeBlock ifFalse: falseAlternativeBlock [
	<inline: true>
	"For data processing operands, there is the immediate shifter_operand variant, 
	 where an 8 bit value is ring shifted _right_ by i.
	 This is only suitable for quick constants(Cq), which won't change."
	
	(constant bitAnd: 16rFF) = constant ifTrue:
		[^trueAlternativeBlock value: 0 value: constant].
	2 to: 30 by: 2 do:
		[:i |
		(constant bitAnd: ((16rFF <<i bitAnd:16rFFFFFFFF) bitOr: 16rFF>>(32-i))) = constant ifTrue:
			[^trueAlternativeBlock value: 32 - i value: ((constant >> i) bitOr: (constant <<(32 - i) bitAnd:16rFFFFFFFF))]].
	^falseAlternativeBlock value
]

{ #category : #testing }
CogARMCompiler >> rotateable8bitSignedImmediate: constant ifTrue: trueAlternativeBlock ifFalse: falseAlternativeBlock [
	<inline: true>
	"Invoke trueAlternativeBlock with shift, value and negated if constant can be represented
	 by a possibly rotated 8-bit constant, otherwise invoke falseAlternativeBlock. For data
	 processing operands, there is the immediate shifter_operand variant,  where an 8 bit value
	 is ring shifted _right_ by i. This is only suitable for quick constants (Cq), which won't change."
	| value |
	value := constant.
	[(value bitAnd: 16rFF) = value ifTrue:
		[^trueAlternativeBlock value: 0 value: value value: constant ~= value].
	 2 to: 30 by: 2 do:
		[:i |
		(value bitAnd: ((16rFF <<i bitAnd:16rFFFFFFFF) bitOr: 16rFF>>(32-i))) = value ifTrue:
			[^trueAlternativeBlock
				value: 32 - i
				value: ((value >> i) bitOr: (value <<(32 - i) bitAnd:16rFFFFFFFF))
				value: constant ~= value]].
	 value = constant and: [constant ~= 0]]
		whileTrue:
			[value := constant negated].
	^falseAlternativeBlock value
]

{ #category : #abi }
CogARMCompiler >> saveAndRestoreLinkRegAround: aBlock [
	"If the processor's ABI includes a link register, generate instructions
	 to save and restore it around aBlock, which is assumed to generate code."
	<inline: true>
	| inst |
	inst := cogit PushR: LinkReg.
	aBlock value.
	cogit PopR: LinkReg.
	^inst
]

{ #category : #testing }
CogARMCompiler >> setsConditionCodesFor: aConditionalJumpOpcode [
	<inline: false> "to save Slang from having to be a real compiler (it can't inline switches that return)"
	"Answer if the receiver's opcode sets the condition codes correctly for the given conditional jump opcode.
	ARM has to check carefully since the V flag is not affected by non-comparison instructions"
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
CogARMCompiler >> shiftSetsConditionCodesFor: aConditionalJumpOpcode [
	"check what flags the opcdoe needs setting - ARM doesn't set V when simply MOVing"
		^aConditionalJumpOpcode caseOf:
		{	[JumpNegative]	->	[true].
			[JumpZero]	->	[true].
			[JumpLess]	->	[true].
		}
		otherwise: [self halt: 'unhandled opcode in setsConditionCodesFor:'. false]
]

{ #category : #accessing }
CogARMCompiler >> stackPageInterruptHeadroomBytes [
	"Return a minimum amount of headroom for each stack page (in bytes).  In a
	 JIT the stack has to have room for interrupt handlers which will run on the stack.
	According to ARM architecture v5 reference manual chapter A2.6, the basic interrupt procedure does not push anything onto the stack. It uses SPSR_err and R14_err to preserve state. Afterwards, it calls an interrupt procedure. So leave some room."
	^128 "32 words"
]

{ #category : #encoding }
CogARMCompiler >> stop [
"generate a BKPT ( - ARM_ARM v7 DDI10406 pp. A8-56) instruction. We could, given a good enough creative impulse and an over-active sense of humour, add some numerically encoded witticism to this instruction in bits 8-19 & 0-3. It has no effect on the execution but can be a way to specify which breakpoint has been hit etc."
	<inline: true>
	^AL << 28 bitOr: (16r12 << 20 bitOr: (7 << 4))
]

{ #category : #'generate machine code - support' }
CogARMCompiler >> stopsFrom: startAddr to: endAddr [
	self assert: endAddr - startAddr + 1 \\ 4 = 0.
	startAddr to: endAddr by: 4 do: 
		[:addr | objectMemory longAt: addr put: self stop].
]

{ #category : #'inline cacheing' }
CogARMCompiler >> storeLiteral: literal beforeFollowingAddress: followingAddress [
	"Rewrite the long constant loaded by the instruction sequence just before this address:"
	^self subclassResponsibility
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> str: destReg rn: baseReg plus: u imm: immediate12bitValue [
"	STR destReg, [baseReg, 'u' immediate12bitValue] u=0 -> subtract imm; =1 -> add imm - ARM_ARM v7 DDI10406 pp. A8-382-3 "
	^self memMxr: AL reg: destReg  base: baseReg u: u b: 0 l: 0 imm: immediate12bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> str: srcReg rn: baseReg plusImm: immediate12bitValue [
"	STR srcReg, [baseReg, +immediate12bitValue] - ARM_ARM v7 DDI10406 pp. A8-382-3"
	^self memMxr: AL reg: srcReg  base: baseReg u: 1 b: 0 l: 0 imm: immediate12bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> str: srcReg rn: baseReg rm: offsetReg [
"	STR srcReg, [baseReg, + offsetReg]  - ARM_ARM v7 DDI10406 pp. A8-384-5
The contents of offsetReg are assumed to be correctly signed"
	^self memMxr: AL reg: srcReg  base: baseReg p: 1 u: 1 b: 0 w: 0 l: 0 rm: offsetReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> strb: destReg rn: baseReg plus: u imm: immediate12bitValue [
"	STRB destReg, [baseReg, 'u' immediate12bitValue] u=0 -> subtract imm; =1 -> add imm  - ARM_ARM v7 DDI10406 pp. A8-388-9"
	^self memMxr: AL reg: destReg  base: baseReg u: u b: 1 l: 0 imm: immediate12bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> strb: srcReg rn: baseReg rm: offsetReg [
"	STRB srcReg, [baseReg, + offsetReg]  - ARM_ARM v7 DDI10406 pp. A8-390-1
	The contents of offsetReg are assumed to be correctly signed"
	^self memMxr: AL reg: srcReg  base: baseReg p: 1 u: 1 b: 1 w: 0 l: 0 rm: offsetReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> strh: destReg rn: baseReg plus: u imm: immediate8bitValue [
"	STRH destReg, [baseReg, 'u' immediate8bitValue] u=0 -> subtract imm; =1 -> add imm  - ARM_ARM v7 DDI10406 pp. A8-408-9"
	^self memM16xr: AL reg: destReg  base: baseReg p: 1 u: u  w: 0 l: 0 offset: immediate8bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> strh: srcReg rn: baseReg rm: offsetReg [
"	STRH srcReg, [baseReg, +offsetReg] - ARM_ARM v7 DDI10406 pp. A8-410-1"
	^self memM16xr: AL reg: srcReg base: baseReg p: 1 u: 1 w: 0 l: 0 rm: offsetReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> sub: destReg rn: srcReg imm: immediate ror: rot [
"	Remember the ROR is doubled by the cpu so use 30>>1 etc
	SUB destReg, srcReg, #immediate ROR rot - ARM_ARM v7 DDI10406 pp. A8-418-9"

	^self type: 1 op: SubOpcode set: 0 rn: srcReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate)
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> subs: destReg rn: srcReg imm: immediate ror: rot [
"	Remember the ROR is doubled by the cpu so use 30>>1 etc
	SUBS destReg, srcReg, #immediate ROR rot - ARM_ARM v7 DDI10406 pp. A8-418-9"

	^self type: 1 op: SubOpcode set: 1 rn: srcReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate)
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> tst: ignored rn: srcReg imm: immediate ror: rot [
"	Remember the ROR is doubled by the cpu so use 30>>1 etc"
"also note that TST has no destReg
	TST srcReg, #immediate ROR rot - ARM_ARM v7 DDI10406 pp. A8-452-3"

	^self type: 1 op: TstOpcode set: 1 rn: srcReg rd: 0 shifterOperand: ((rot>>1) <<8 bitOr: immediate)
]

{ #category : #encoding }
CogARMCompiler >> type: type op: flagsOrOpcode set: doUpdateStatusRegister rn:  sourceRegister rd: targetRegister [
	<inline: true>
	^(self cond: AL type: type op: flagsOrOpcode set: doUpdateStatusRegister) 
		bitOr: (sourceRegister << 16 bitOr: targetRegister << 12)
]

{ #category : #encoding }
CogARMCompiler >> type: type op: flagsOrOpcode set: doUpdateStatusRegister rn:  sourceRegister rd: targetRegister shifterOperand: so [
	<inline: true>
	^(self type: type op: flagsOrOpcode set: doUpdateStatusRegister rn: sourceRegister rd: targetRegister) bitOr: (so bitAnd: 16rFFF)
]

{ #category : #simulation }
CogARMCompiler >> wantsNearAddressFor: anObject [
	"A hack hook to allow ARM to override the simulated address for the short-cut trampolines"
	<doNotGenerate>
	^anObject isSymbol and: [anObject beginsWith: 'ceShortCut']
]

{ #category : #'inline cacheing' }
CogARMCompiler >> zoneCallsAreRelative [
	"Answer if Call and JumpLong are relative and hence need to take the caller's
	 relocation delta into account during code compaction, rather than just the
	 callee's delta."
	^true
]
