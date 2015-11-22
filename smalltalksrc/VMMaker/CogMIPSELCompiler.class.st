Class {
	#name : #CogMIPSELCompiler,
	#superclass : #CogAbstractInstruction,
	#classVars : [
		'AddCheckOverflowCqR',
		'AddCheckOverflowRR',
		'BrEqRR',
		'BrGtzRR',
		'BrLezRR',
		'BrNeRR',
		'Cmp',
		'CmpSGT',
		'CmpSLT',
		'CmpUGT',
		'CmpULT',
		'ConcreteVarBaseReg',
		'MulCheckOverflowRR',
		'MulRR',
		'Overflow',
		'OverflowTemp1',
		'OverflowTemp2',
		'SubCheckOverflowCqR',
		'SubCheckOverflowRR',
		'TargetReg'
	],
	#pools : [
		'MIPSConstants'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'class initialization' }
CogMIPSELCompiler class >> ISA [
	^#MIPSEL
]

{ #category : #'class initialization' }
CogMIPSELCompiler class >> initialize [
	"CogMIPSELCompiler initialize"

	super initialize.
	
	ConcreteVarBaseReg := S6.

	"Simulating a condition register."
	Cmp := T0.
	CmpSLT := T1.
	CmpSGT := T2.
	CmpULT := T3.
	CmpUGT := T4.
	Overflow := T0.
	OverflowTemp1 := T1.
	OverflowTemp2 := T2.

	"OABI position independent code expects T9 to have its entry point on entry?"
	self flag: #OABI.
	TargetReg := T9.

	"Specific instructions"
	self
		initializeSpecificOpcodes: #(MulRR
									AddCheckOverflowCqR AddCheckOverflowRR MulCheckOverflowRR SubCheckOverflowCqR SubCheckOverflowRR
									"Ryan, here are proposed opcodes for conditional branches."
									BrEqRR BrNeRR BrLezRR BrGtzRR)
		in: thisContext method
		
	
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> addiuR: destReg R: srcReg C: imm [
	^self itype: ADDIU rs: srcReg rt: destReg signedImmediate: imm
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> adduR: destReg R: leftReg R: rightReg [
	^self rtype: SPECIAL rs: leftReg rt: rightReg rd: destReg sa: 0 funct: ADDU
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> andR: destReg R: leftReg R: rightReg [
	^self rtype: SPECIAL rs: leftReg rt: rightReg rd: destReg sa: 0 funct: AND
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> andiR: destReg R: srcReg C: imm [
	^self itype: ANDI rs: srcReg rt: destReg eitherImmediate: imm
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> beqR: leftReg R: rightReg offset: offset [
	self assert: (offset bitAnd: 3) = 0.
	self assert: (offset between: -16r20000 and: 16r1FFFF).
	^self itype: BEQ rs: leftReg rt: rightReg signedImmediate: offset >> 2
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> bgezR: cmpReg offset: offset [
	self assert: (offset bitAnd: 3) = 0.
	self assert: (offset between: -16r20000 and: 16r1FFFF).
	^self itype: REGIMM rs: cmpReg rt: BGEZ signedImmediate: offset >> 2
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> bgtzR: cmpReg offset: offset [
	self assert: (offset bitAnd: 3) = 0.
	self assert: (offset between: -16r20000 and: 16r1FFFF).
	^self itype: BGTZ rs: cmpReg rt: 0 signedImmediate: offset >> 2
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> blezR: cmpReg offset: offset [
	self assert: (offset bitAnd: 3) = 0.
	self assert: (offset between: -16r20000 and: 16r1FFFF).
	^self itype: BLEZ rs: cmpReg rt: 0 signedImmediate: offset >> 2
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> bltzR: cmpReg offset: offset [
	self assert: (offset bitAnd: 3) = 0.
	self assert: (offset between: -16r20000 and: 16r1FFFF).
	^self itype: REGIMM rs: cmpReg rt: BLTZ signedImmediate: offset >> 2
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> bneR: leftReg R: rightReg offset: offset [
	self assert: (offset bitAnd: 3) = 0.
	self assert: (offset between: -16r20000 and: 16r1FFFF).
	^self itype: BNE rs: leftReg rt: rightReg signedImmediate: offset >> 2
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> break: code [
	self assert: (code between: 0 and: 16rFFFFF).
	^(code << 6) bitOr: BREAK
]

{ #category : #'generate machine code' }
CogMIPSELCompiler >> cResultRegister [
	"Answer the abstract register for the C result register."
	^V0
]

{ #category : #accessing }
CogMIPSELCompiler >> callInstructionByteSize [
	self flag: #todo. "Which call opcode does this want the size of?"
	^16
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> callTargetFromReturnAddress: callSiteReturnAddress [
	"csra - 16:	lui t9, high
	 csra - 12:	ori t9, low
	 csra - 8:	jalr t9
	 csra - 4:	nop (delay slot)"
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 16) == LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 12) == ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 8) == SPECIAL.
	self assert: (self functionAtAddress: callSiteReturnAddress - 8) == JALR.
	self assert: (objectMemory longAt: callSiteReturnAddress - 4) == self nop. "Delay slot"
	^self literalAtAddress: callSiteReturnAddress - 12
]

{ #category : #accessing }
CogMIPSELCompiler >> callerSavedRegisterMask [
	"See MIPSConstants initializeRegisters."
	| mask |
	self flag: #OABI.
	mask := 0.
	mask := mask bitOr: 1 << S0.
	mask := mask bitOr: 1 << S1.
	mask := mask bitOr: 1 << S2.
	mask := mask bitOr: 1 << S3.
	mask := mask bitOr: 1 << S4.
	mask := mask bitOr: 1 << S5.
	mask := mask bitOr: 1 << S6.
	mask := mask bitOr: 1 << S7.
	^mask
]

{ #category : #accessing }
CogMIPSELCompiler >> cmpC32RTempByteSize [
	self flag: #todo. "value - reg or reg - value?"
	self flag: #inefficient. "Cog RTL assumes we can do any kind of conditional branch after a Cmp."
	^28
]

{ #category : #accessing }
CogMIPSELCompiler >> codeGranularity [
	"Answer the size in bytes of a unit of machine code."
	<inline: true>
	^4
]

{ #category : #'generate machine code' }
CogMIPSELCompiler >> computeMaximumSize [
	"Each MIPS instruction has 4 bytes. Many abstract opcodes need more than one
	 instruction. Instructions that refer to constants and/or literals depend on literals
	 being stored in-line or out-of-line.

	 N.B.  The ^N forms are to get around the bytecode compiler's long branch
	 limits which are exceeded when each case jumps around the otherwise."

	opcode
		caseOf: {
		"Noops & Pseudo Ops"
		[Label]					-> [^0].
		[Literal]					-> [^4].
		[AlignmentNops]		-> [^(operands at: 0) - 4].
		[Fill16]					-> [^4].
		[Fill32]					-> [^4].
		[FillFromWord]			-> [^4].
		[Nop]					-> [^4].
		"Control"
		[Call]					-> [^self literalLoadInstructionBytes + 8].
		[CallFull]				-> [^self literalLoadInstructionBytes + 8].
		[JumpR]					-> [^8].
		[Jump]					-> [^8].
		[JumpFull]				-> [^self literalLoadInstructionBytes + 8].
		[JumpLong]				-> [^self literalLoadInstructionBytes + 8].
		[JumpZero]				-> [^8].
		[JumpNonZero]			-> [^8].
		[JumpNegative]			-> [^8].
		[JumpNonNegative]		-> [^8].
		[JumpOverflow]			-> [^8].
		[JumpNoOverflow]		-> [^8].
		[JumpCarry]			-> [^8].
		[JumpNoCarry]			-> [^8].
		[JumpLess]				-> [^8].
		[JumpGreaterOrEqual]	-> [^8].
		[JumpGreater]			-> [^8].
		[JumpLessOrEqual]		-> [^8].
		[JumpBelow]			-> [^8].
		[JumpAboveOrEqual]	-> [^8].
		[JumpAbove]			-> [^8].
		[JumpBelowOrEqual]	-> [^8].
		[JumpLongZero]		-> [^self literalLoadInstructionBytes + 8].
		[JumpLongNonZero]	-> [^self literalLoadInstructionBytes + 8].
		[JumpFPEqual]			-> [^8].
		[JumpFPNotEqual]		-> [^8].
		[JumpFPLess]			-> [^8].
		[JumpFPGreaterOrEqual]-> [^8].
		[JumpFPGreater]		-> [^8].
		[JumpFPLessOrEqual]	-> [^8].
		[JumpFPOrdered]		-> [^8].
		[JumpFPUnordered]		-> [^8].
		[RetN]					-> [^8].
		[Stop]					-> [^4].

		"Arithmetic"
		[AddCqR]				-> [^12].
		[AndCqR]				-> [^16].
		[AndCqRR]				-> [^12].
		[CmpCqR]				-> [^28].
		[OrCqR]					-> [^12].
		[SubCqR]				-> [^12].
		[TstCqR]				-> [^12].
		[XorCqR]				-> [^12].
		[AddCwR]				-> [^12].
		[AndCwR]				-> [^12].
		[CmpCwR]				-> [^28].
		[OrCwR]				-> [^12].
		[SubCwR]				-> [^12].
		[XorCwR]				-> [^12].
		[AddRR]					-> [^4].
		[AndRR]					-> [^4].
		[CmpRR]				-> [^20].
		[OrRR]					-> [^4].
		[XorRR]					-> [^4].
		[SubRR]					-> [^4].
		[NegateR]				-> [^4].
		[LoadEffectiveAddressMwrR] -> [^12].
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
		[SubCheckOverflowCqR]	-> [^28].
		"Data Movement"						
		[MoveCqR]				-> [^8 "or 4"].
		[MoveCwR]				-> [^8].
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
		[MoveRMwr]			-> [^16].
		[MoveRdM64r]			-> [^self literalLoadInstructionBytes + 4]. 
		[MoveMbrR]				-> [^16].
		[MoveRMbr]				-> [^16].
		[MoveM16rR]			-> [^4].
		[MoveM64rRd]			-> [^self literalLoadInstructionBytes + 4].
		[MoveMwrR]			-> [^16].
		[MoveXbrRR]			-> [^0].
		[MoveRXbrR]			-> [^0].
		[MoveXwrRR]			-> [^12].
		[MoveRXwrR]			-> [^12].
		[PopR]					-> [^8].
		[PushR]					-> [^8].
		[PushCw]				-> [^16].
		[PushCq]				-> [^16].
		[PrefetchAw] 			-> [^12].
		"Conversion"
		[ConvertRRd]			-> [^8].
		}.
	^0 "to keep C compiler quiet"

]

{ #category : #encoding }
CogMIPSELCompiler >> concreteRegister: registerIndex [
	"Map a possibly abstract register into a concrete one.  Abstract registers
	 (defined in CogAbstractOpcodes) are all negative.  If registerIndex is
	 negative assume it is an abstract register."
	
	"See MIPSConstants>>initializeRegisters for a description of the C ABI."

	"Note we can fit all of the abstract registers in C preserved registers, and
	 not need to save or restore them at runtime calls."
	
	^registerIndex
		caseOf: {
			[ReceiverResultReg]	-> [S0].
			[Arg0Reg]				-> [S1].
			[Arg1Reg]				-> [S2].
			[ClassReg]				-> [S3].
			[SendNumArgsReg]		-> [S4].
			[TempReg]				-> [S5].
			[VarBaseReg]			-> [S6]. "Must be callee saved"
			[SPReg]					-> [SP].
			[FPReg]					-> [FP].
			[RISCTempReg]			-> [AT].
			[LinkReg]				-> [RA]. }
		otherwise:
			[self assert: (registerIndex between: R0 and: R31).
			 registerIndex]
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeAddCqR [
	^self concretizeAddCwR
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeAddCwR [
	| val reg |
	val := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: val)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: val)).
	self machineCodeAt: 8 put: (self adduR: reg R: reg R: AT).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeAddRR [
	| leftReg rightReg |
	leftReg := self concreteRegister: (operands at: 0).
	rightReg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self adduR: rightReg R: leftReg R: rightReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeAlignmentNops [
	self assert: machineCodeSize \\ 4 = 0.
	0 to: machineCodeSize - 1 by: 4 do:
		[:p | self machineCodeAt: p put: self nop]
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeAndCqR [
	^self concretizeAndCwR
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeAndCqRR [
	| value srcReg dstReg |
	value := operands at: 0.
	srcReg := self concreteRegister: (operands at: 1).
	dstReg := self concreteRegister: (operands at: 2).
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: value)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: value)).
	self machineCodeAt: 8 put: (self andR: dstReg R: srcReg R: AT).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeAndCwR [
	| value reg |
	value := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: value)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: value)).
	self machineCodeAt: 8 put: (self andR: reg R: reg R: AT).
	self flag: #inefficient. "Cog RTL assumes we can do any kind of conditional branch after a Cmp."
	self machineCodeAt: 12 put: (self andR: Cmp R: reg R: AT).
	^machineCodeSize := 16
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeArithmeticShiftRightCqR [
	| distance reg |
	distance := (operands at: 0) min: 31.
	reg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self sraR: reg R: reg C: distance).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeArithmeticShiftRightRR [
	| destReg distReg |
	distReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self sravR: destReg R: destReg R: distReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogMIPSELCompiler >> concretizeAt: actualAddress [
	"Generate concrete machine code for the instruction at actualAddress,
	 setting machineCodeSize, and answer the following address."

	self assert: actualAddress \\ 4 = 0.
	^super concretizeAt: actualAddress
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeCall [
	"Call is used only for calls within code-space, See CallFull for general anywhere in address space calling"
	"Relative branches in MIPS have a displacement of +/- 131kB (signed 18 bits), which is too small to cover
	 the method zone."
	^self concretizeCallFull
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeCallFull [
	| jumpTarget |
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := self longJumpTargetAddress.
	self machineCodeAt: 0 put: (self luiR: TargetReg C: (self high16BitsOf: jumpTarget)).
	self machineCodeAt: 4 put: (self oriR: TargetReg R: TargetReg C: (self low16BitsOf: jumpTarget)).	
	self machineCodeAt: 8 put: (self jalR: TargetReg).
	self machineCodeAt: 12 put: self nop. "Delay slot"
	^machineCodeSize := 16
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeCmpCqR [
	^self concretizeCmpCwR
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeCmpCwR [
	| value reg |
	value := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	self flag: #todo. "value - reg or reg - value?"
	self flag: #inefficient. "Cog RTL assumes we can do any kind of conditional branch after a Cmp."
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: value)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: value)).
	self machineCodeAt: 8 put: (self subuR: Cmp R: reg R: AT).
	self machineCodeAt: 12 put: (self sltR: CmpSLT R: reg R: AT).
	self machineCodeAt: 16 put: (self sltR: CmpSGT R: AT R: reg).
	self machineCodeAt: 20 put: (self sltuR: CmpULT R: reg R: AT).
	self machineCodeAt: 24 put: (self sltuR: CmpUGT R: AT R: reg).
	^machineCodeSize := 28
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeCmpRR [
	| leftReg rightReg |
	"CmpRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	rightReg := self concreteRegister: (operands at: 0).
	leftReg := self concreteRegister: (operands at: 1).
	self flag: #inefficient. "Cog RTL assumes we can do any kind of conditional branch after a Cmp."
	self machineCodeAt: 0 put: (self subuR: Cmp R: leftReg R: rightReg).
	self machineCodeAt: 4 put: (self sltR: CmpSLT R: leftReg R: rightReg).
	self machineCodeAt: 8 put: (self sltR: CmpSGT R: rightReg R: leftReg).
	self machineCodeAt: 12 put: (self sltuR: CmpULT R: leftReg R: rightReg).
	self machineCodeAt: 16 put: (self sltuR: CmpUGT R: rightReg R: leftReg).
	^machineCodeSize := 20
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJump [
	| offset |
	offset := self computeJumpTargetOffsetPlus: 4.
	self flag: #BranchRange.
	self machineCodeAt: 0 put: (self beqR: ZR R: ZR offset: offset).
	self machineCodeAt: 4 put: self nop. "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpFull [
	| jumpTarget |
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := self longJumpTargetAddress.
	self machineCodeAt: 0 put: (self luiR: TargetReg C: (self high16BitsOf: jumpTarget)).
	self machineCodeAt: 4 put: (self oriR: TargetReg R: TargetReg C: (self low16BitsOf: jumpTarget)).	
	self machineCodeAt: 8 put: (self jR: TargetReg).
	self machineCodeAt: 12 put: self nop. "Delay slot"
	^machineCodeSize := 16
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpLong [
	^self concretizeJumpFull
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpLongNonZero [
	| jumpTarget |
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := self longJumpTargetAddress.
	self flag: #todo. "Check not crossing 256MB block."
	jumpTarget := jumpTarget bitAnd: 16rFFFFFFF.
	self machineCodeAt: 0 put: (self beqR: Cmp R: ZR offset: 12).
	self machineCodeAt: 4 put: self nop. "Delay slot"
	self machineCodeAt: 8 put: (self jA: jumpTarget).
	self machineCodeAt: 12 put: self nop. "Delay slot"
	^machineCodeSize := 16
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpLongZero [
	| jumpTarget |
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := self longJumpTargetAddress.
	self flag: #todo. "Check not crossing 256MB block."
	jumpTarget := jumpTarget bitAnd: 16rFFFFFFF.
	self machineCodeAt: 0 put: (self bneR: Cmp R: ZR offset: 12).
	self machineCodeAt: 4 put: self nop. "Delay slot"
	self machineCodeAt: 8 put: (self jA: jumpTarget).
	self machineCodeAt: 12 put: self nop. "Delay slot"
	^machineCodeSize := 16
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpNoOverflow [
	| offset |
	offset := self computeJumpTargetOffsetPlus: 4.
	self flag: #BranchRange.
	self machineCodeAt: 0 put: (self bgezR: Overflow offset: offset).
	self machineCodeAt: 4 put: self nop. "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpNonZero [
	| offset |
	offset := self computeJumpTargetOffsetPlus: 4.
	self flag: #BranchRange.
	self machineCodeAt: 0 put: (self bneR: Cmp R: ZR offset: offset).
	self machineCodeAt: 4 put: self nop. "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpOverflow [
	| offset |
	offset := self computeJumpTargetOffsetPlus: 4.
	self flag: #BranchRange.
	self machineCodeAt: 0 put: (self bltzR: Overflow offset: offset).
	self machineCodeAt: 4 put: self nop. "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpR [
	| reg |
	self flag: #OABI. "Does this ever target C code? If so we should move the target into TargetReg first."
	reg := self concreteRegister: (operands at: 0).
	self machineCodeAt: 0 put: (self jR: reg).
	self machineCodeAt: 4 put: self nop. "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpSignedGreaterEqual [
	| offset |
	offset := self computeJumpTargetOffsetPlus: 4.
	self machineCodeAt: 0 put: (self bneR: CmpSLT R: ZR offset: offset).
	self machineCodeAt: 4 put: (self nop). "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpSignedGreaterThan [
	| offset |
	offset := self computeJumpTargetOffsetPlus: 4.
	self machineCodeAt: 0 put: (self bneR: CmpSGT R: ZR offset: offset).
	self machineCodeAt: 4 put: (self nop). "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpSignedLessEqual [
	| offset |
	offset := self computeJumpTargetOffsetPlus: 4.
	self machineCodeAt: 0 put: (self beqR: CmpSGT R: ZR offset: offset).
	self machineCodeAt: 4 put: (self nop). "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpSignedLessThan [
	| offset |
	offset := self computeJumpTargetOffsetPlus: 4.
	self machineCodeAt: 0 put: (self bneR: CmpSLT R: ZR offset: offset).
	self machineCodeAt: 4 put: (self nop). "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpUnsignedGreaterEqual [
	| offset |
	offset := self computeJumpTargetOffsetPlus: 4.
	self machineCodeAt: 0 put: (self bneR: CmpULT R: ZR offset: offset).
	self machineCodeAt: 4 put: (self nop). "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpUnsignedGreaterThan [
	| offset |
	offset := self computeJumpTargetOffsetPlus: 4.
	self machineCodeAt: 0 put: (self bneR: CmpUGT R: ZR offset: offset).
	self machineCodeAt: 4 put: (self nop). "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpUnsignedLessEqual [
	| offset |
	offset := self computeJumpTargetOffsetPlus: 4.
	self machineCodeAt: 0 put: (self beqR: CmpUGT R: ZR offset: offset).
	self machineCodeAt: 4 put: (self nop). "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpUnsignedLessThan [
	| offset |
	offset := self computeJumpTargetOffsetPlus: 4.
	self machineCodeAt: 0 put: (self bneR: CmpULT R: ZR offset: offset).
	self machineCodeAt: 4 put: (self nop). "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpZero [
	| offset |
	offset := self computeJumpTargetOffsetPlus: 4.
	self flag: #BranchRange.
	self machineCodeAt: 0 put: (self beqR: Cmp R: ZR offset: offset).
	self machineCodeAt: 4 put: self nop. "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeLoadEffectiveAddressMwrR [
	<var: #offset type: #sqInt>
	| baseReg offset destReg |
	offset := operands at: 0.
	baseReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
	(self isShortOffset: offset) ifTrue:
		[self machineCodeAt: 0 put: (self addiuR: destReg R: baseReg C: offset).
		^machineCodeSize := 4].
	
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: offset)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: offset)).
	self machineCodeAt: 8 put: (self adduR: destReg R: baseReg R: AT).
	^machineCodeSize := 12.

]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeLogicalShiftLeftCqR [
	| distance reg |
	distance := (operands at: 0) min: 31.
	reg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self sllR: reg R: reg C: distance).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeLogicalShiftLeftRR [
	| destReg distReg |
	distReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self sllvR: destReg R: destReg R: distReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeLogicalShiftRightCqR [
	| distance reg |
	distance := (operands at: 0) min: 31.
	reg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self srlR: reg R: reg C: distance).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeLogicalShiftRightRR [
	| destReg distReg |
	distReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self srlvR: destReg R: destReg R: distReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveAbR [
	| srcAddr destReg |
	srcAddr := operands at: 0.
	destReg := self concreteRegister: (operands at: 1).

	(self isAddressRelativeToVarBase: srcAddr) ifTrue:
		[self machineCodeAt: 0 put: (self lwR: destReg base: ConcreteVarBaseReg offset: srcAddr - cogit varBaseAddress).
		 ^machineCodeSize := 4].

	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: srcAddr)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: srcAddr)).
	self machineCodeAt: 8 put: (self lbuR: destReg base: AT offset: 0).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveAwR [
	| srcAddr destReg |
	srcAddr := operands at: 0.
	destReg := self concreteRegister: (operands at: 1).

	(self isAddressRelativeToVarBase: srcAddr) ifTrue:
		[self machineCodeAt: 0 put: (self lwR: destReg base: ConcreteVarBaseReg offset: srcAddr - cogit varBaseAddress).
		 ^machineCodeSize := 4].

	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: srcAddr)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: srcAddr)).
	self machineCodeAt: 8 put: (self lwR: destReg base: AT offset: 0).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveCqR [
	<var: #word type: #sqInt>
	| word reg |
	word := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	
	(word between: -16r8000 and: 16r7FFF) ifFalse: [^self concretizeMoveCwR].
	"Could also load up to 16rFFFF with ori or 16rXXXX0000 with lui"
	
	self machineCodeAt: 0 put: (self addiuR: reg R: ZR C: word).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveCwR [
	<var: #word type: #sqInt>
	| word reg |
	word := operands at: 0.
	reg := self concreteRegister: (operands at: 1).	
	self machineCodeAt: 0 put: (self luiR: reg C: (self high16BitsOf: word)).
	self machineCodeAt: 4 put: (self oriR: reg R: reg C: (self low16BitsOf: word)).
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveM16rR [
	<var: #offset type: #sqInt>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
	self machineCodeAt: 0 put: (self lhR: destReg base: srcReg offset: offset).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveMbrR [
	<var: #offset type: #sqInt>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
	self machineCodeAt: 0 put: (self lbuR: destReg base: srcReg offset: offset).
	^machineCodeSize := 4
	
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveMwrR [
	<var: #offset type: #sqInt>
	| baseReg offset destReg |
	offset := operands at: 0.
	baseReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
	(self isShortOffset: offset) ifTrue:
		[self machineCodeAt: 0 put: (self lwR: destReg base: baseReg offset: offset).
		^machineCodeSize := 4].
	
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: offset)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: offset)).
	self machineCodeAt: 8 put: (self adduR: AT R: baseReg R: AT).
	self machineCodeAt: 12 put: (self lwR: destReg base: AT offset: 0).
	^machineCodeSize := 16.

]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveRAb [
	| srcReg destAddr |
	srcReg := self concreteRegister: (operands at: 0).
	destAddr := operands at: 1.

	(self isAddressRelativeToVarBase: destAddr) ifTrue:
		[self machineCodeAt: 0 put: (self swR: srcReg base: ConcreteVarBaseReg offset: destAddr - cogit varBaseAddress).
		 ^machineCodeSize := 4].

	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: destAddr)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: destAddr)).
	self machineCodeAt: 8 put: (self sbR: srcReg base: AT offset: 0).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveRAw [
	| srcReg destAddr |
	srcReg := self concreteRegister: (operands at: 0).
	destAddr := operands at: 1.

	(self isAddressRelativeToVarBase: destAddr) ifTrue:
		[self machineCodeAt: 0 put: (self swR: srcReg base: ConcreteVarBaseReg offset: destAddr - cogit varBaseAddress).
		 ^machineCodeSize := 4].

	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: destAddr)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: destAddr)).
	self machineCodeAt: 8 put: (self swR: srcReg base: AT offset: 0).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveRMwr [
	<var: #offset type: #sqInt>
	| srcReg offset baseReg |
	srcReg := self concreteRegister: (operands at: 0).
	offset := operands at: 1.
	baseReg := self concreteRegister: (operands at: 2).
	self machineCodeAt: 0 put: (self swR: srcReg base: baseReg offset: offset).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveRR [
	| srcReg destReg |
	srcReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self adduR: destReg R: srcReg R: ZR).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveRXwrR [
	| srcReg indexReg baseReg |
	srcReg := self concreteRegister: (operands at: 0).
	indexReg := self concreteRegister: (operands at: 1).
	baseReg := self concreteRegister: (operands at: 2).
	self machineCodeAt: 0 put: (self sllR: AT R: indexReg C: 2). "index is number of words"
	self machineCodeAt: 4 put: (self adduR: AT R: baseReg R: AT).
	self machineCodeAt: 8 put: (self swR: srcReg base: AT offset: 0).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveXwrRR [
	| indexReg baseReg destReg |
	indexReg := self concreteRegister: (operands at: 0).
	baseReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
	self machineCodeAt: 0 put: (self sllR: AT R: indexReg C: 2). "index is in words"
	self machineCodeAt: 4 put: (self adduR: AT R: baseReg R: AT).
	self machineCodeAt: 8 put: (self lwR: destReg base: AT offset: 0).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeNop [
	self machineCodeAt: 0 put: self nop.
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeOrCqR [
	^self concretizeOrCwR
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeOrCwR [
	| value reg |
	value := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: value)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: value)).
	self machineCodeAt: 8 put: (self orR: reg R: reg R: AT).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeOrRR [
	| leftReg rightReg |
	leftReg := self concreteRegister: (operands at: 0).
	rightReg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self orR: rightReg R: leftReg R: rightReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizePopR [
	| destReg |
	destReg := self concreteRegister: (operands at: 0).
	self machineCodeAt: 0 put: (self lwR: destReg base: SP offset: 0).
	self machineCodeAt: 4 put: (self addiuR: SP R: SP C: 4).
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizePrefetchAw [
	| address |
	address := operands at: 0.
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: address)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: address)).
	self machineCodeAt: 8 put: (self prefR: AT offset: 0 hint: HintLoad).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizePushCq [
	^self concretizePushCw
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizePushCw [
	| value |
	value := operands at: 0.
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: value)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: value)).
	self machineCodeAt: 8 put: (self addiuR: SP R: SP C: -4).
	self machineCodeAt: 12 put: (self swR: AT base: SP offset: 0).
	^machineCodeSize := 16
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizePushR [
	| srcReg |
	srcReg := self concreteRegister: (operands at: 0).
	self machineCodeAt: 0 put: (self addiuR: SP R: SP C: -4).
	self machineCodeAt: 4 put: (self swR: srcReg base: SP offset: 0).
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeRetN [
	<var: #offset type: #sqInt>
	| offset |
	offset := operands at: 0.
	self machineCodeAt: 0 put: (self jR: RA).
	offset = 0 
		ifTrue: [self machineCodeAt: 4 put: self nop "Delay slot"]
		ifFalse: [self machineCodeAt: 4 put: (self addiuR: SP R: SP C: offset) "We actually get to fill a delay slot!"].
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeStop [
	self machineCodeAt: 0 put: self stop.
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeSubCheckOverflowCqR [
	| value reg |
	value := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: value)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: value)).

	"Save original LHS"
	self machineCodeAt: 8 put: (self adduR: OverflowTemp1 R: reg R: ZR). 
	
	"The actual subtraction"
	self machineCodeAt: 12 put: (self subuR: reg R: reg R: AT). 

	"Set sign bit of OverflowTemp2 if sign of result differs from sign of RHS."
	self machineCodeAt: 16 put: (self xorR: OverflowTemp2 R: reg R: AT).
	"Set sign bit of OverflowTemp1 if sign of result differs from sign of LHS."
	self machineCodeAt: 20 put: (self xorR: OverflowTemp1 R: reg R: OverflowTemp1).
	"Set sign bit of Overflow if sign of result differs from both LHS and RHS, which indicates overflow."
	self machineCodeAt: 24 put: (self andR: Overflow R: OverflowTemp1 R: OverflowTemp2).
	^machineCodeSize := 28
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeSubCqR [
	^self concretizeSubCwR
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeSubCwR [
	| value reg |
	value := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: value)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: value)).
	self machineCodeAt: 8 put: (self subuR: reg R: reg R: AT).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeSubRR [
	| leftReg rightReg |
	leftReg := self concreteRegister: (operands at: 0).
	rightReg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self subuR: rightReg R: leftReg R: rightReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeTstCqR [
	^self concretizeTstCwR
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeTstCwR [
	| val reg |
	val := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: val)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: val)).
	self machineCodeAt: 8 put: (self andR: Cmp R: reg R: AT).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeXorCwR [
	| val reg |
	val := operands at: 0.
	reg := self concreteRegister: (operands at: 1).
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: val)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: val)).
	self machineCodeAt: 8 put: (self xorR: reg R: reg R: AT).
	^machineCodeSize := 12
]

{ #category : #'generate machine code' }
CogMIPSELCompiler >> dispatchConcretize [
	"Attempt to generate concrete machine code for the instruction at address.
	 This is the inner dispatch of concretizeAt: actualAddress which exists only
	 to get around the branch size limits in the SqueakV3 (blue book derived)
	 bytecode set."
	<returnTypeC: #void>		 
	opcode caseOf: {
		"Noops & Pseudo Ops"
		[Label]					-> [^self concretizeLabel].
		[AlignmentNops]		-> [^self concretizeAlignmentNops].
		[Fill16]					-> [^self concretizeFill16].
		[Fill32]					-> [^self concretizeFill32].
		[FillFromWord]			-> [^self concretizeFillFromWord].
		[Nop]					-> [^self concretizeNop].
		"Control"
		[Call]						-> [^self concretizeCall]. "call code within code space"
		[CallFull]					-> [^self concretizeCallFull]. "call code anywhere in address space"
		[JumpR]						-> [^self concretizeJumpR].
		[JumpFull]					-> [^self concretizeJumpFull]."jump within address space"
		[JumpLong]					-> [^self concretizeJumpLong]."jumps witihn code space"
		[JumpLongZero]			-> [^self concretizeJumpLongZero].
		[JumpLongNonZero]		-> [^self concretizeJumpLongNonZero].
		[Jump]						-> [^self concretizeJump].
		[JumpZero]					-> [^self concretizeJumpZero].
		[JumpNonZero]				-> [^self concretizeJumpNonZero].
		[JumpNegative]				-> [^self concretizeUnimplemented].
		[JumpNonNegative]			-> [^self concretizeUnimplemented].
		[JumpOverflow]				-> [^self concretizeUnimplemented].
		[JumpNoOverflow]			-> [^self concretizeJumpNoOverflow].
		[JumpCarry]				-> [^self concretizeUnimplemented].
		[JumpNoCarry]				-> [^self concretizeUnimplemented].
		[JumpLess]					-> [^self concretizeJumpSignedLessThan].
		[JumpGreaterOrEqual]		-> [^self concretizeJumpSignedGreaterEqual].
		[JumpGreater]				-> [^self concretizeJumpSignedGreaterThan].
		[JumpLessOrEqual]			-> [^self concretizeJumpSignedLessEqual].
		[JumpBelow]				-> [^self concretizeJumpUnsignedLessThan].
		[JumpAboveOrEqual]		-> [^self concretizeJumpUnsignedGreaterEqual].
		[JumpAbove]				-> [^self concretizeJumpUnsignedGreaterThan].
		[JumpBelowOrEqual]		-> [^self concretizeJumpUnsignedLessEqual].
		[JumpFPEqual]				-> [^self concretizeUnimplemented].
		[JumpFPNotEqual]			-> [^self concretizeUnimplemented].
		[JumpFPLess]				-> [^self concretizeUnimplemented].
		[JumpFPGreaterOrEqual]	-> [^self concretizeUnimplemented].
		[JumpFPGreater]			-> [^self concretizeUnimplemented].
		[JumpFPLessOrEqual]		-> [^self concretizeUnimplemented].
		[JumpFPOrdered]			-> [^self concretizeUnimplemented].
		[JumpFPUnordered]			-> [^self concretizeUnimplemented].
		[RetN]						-> [^self concretizeRetN].
		[Stop]						-> [^self concretizeStop].
		"Arithmetic"
		[AddCqR]					-> [^self concretizeAddCqR].
		[AndCqR]					-> [^self concretizeAndCqR].
		[AndCqRR]					-> [^self concretizeAndCqRR].
		[CmpCqR]					-> [^self concretizeCmpCqR].
		[OrCqR]						-> [^self concretizeOrCqR].
		[SubCqR]					-> [^self concretizeSubCqR].
		[TstCqR]					-> [^self concretizeTstCqR].
		[XorCqR]					-> [^self concretizeXorCqR].
		[AddCwR]					-> [^self concretizeAddCwR].
		[AndCwR]					-> [^self concretizeAndCwR].
		[CmpCwR]					-> [^self concretizeCmpCwR].
		[OrCwR]					-> [^self concretizeOrCwR].
		[SubCwR]					-> [^self concretizeSubCwR].
		[XorCwR]					-> [^self concretizeXorCwR].
		[AddRR]						-> [^self concretizeAddRR].
		[AndRR]						-> [^self concretizeAndRR].
		[CmpRR]					-> [^self concretizeCmpRR].
		[OrRR]						-> [^self concretizeOrRR].
		[SubRR]						-> [^self concretizeSubRR].
		[XorRR]						-> [^self concretizeUnimplemented].
		[AddRdRd]					-> [^self concretizeUnimplemented].
		[CmpRdRd]					-> [^self concretizeUnimplemented].
		[DivRdRd]					-> [^self concretizeUnimplemented].
		[MulRdRd]					-> [^self concretizeUnimplemented].
		[SubRdRd]					-> [^self concretizeUnimplemented].
		[SqrtRd]					-> [^self concretizeUnimplemented].
		[NegateR]						-> [^self concretizeNegateR].
		[LoadEffectiveAddressMwrR]	-> [^self concretizeLoadEffectiveAddressMwrR].
		[ArithmeticShiftRightCqR]		-> [^self concretizeArithmeticShiftRightCqR].
		[LogicalShiftRightCqR]			-> [^self concretizeLogicalShiftRightCqR].
		[LogicalShiftLeftCqR]			-> [^self concretizeLogicalShiftLeftCqR].
		[ArithmeticShiftRightRR]			-> [^self concretizeArithmeticShiftRightRR].
		[LogicalShiftLeftRR]				-> [^self concretizeLogicalShiftLeftRR].
		[LogicalShiftRightRR]			-> [^self concretizeLogicalShiftRightRR].
		"Data Movement"
		[MoveCqR]			-> [^self concretizeMoveCqR].
		[MoveCwR]			-> [^self concretizeMoveCwR].
		[MoveRR]			-> [^self concretizeMoveRR].
		[MoveAwR]			-> [^self concretizeMoveAwR].
		[MoveRAw]			-> [^self concretizeMoveRAw].
		[MoveAbR]			-> [^self concretizeMoveAbR].
		[MoveRAb]			-> [^self concretizeMoveRAb].
		[MoveMbrR]			-> [^self concretizeMoveMbrR].
		[MoveRMbr]			-> [^self concretizeUnimplemented].
		[MoveM16rR]		-> [^self concretizeMoveM16rR].
		[MoveM64rRd]		-> [^self concretizeUnimplemented].
		[MoveMwrR]		-> [^self concretizeMoveMwrR].
		[MoveXbrRR]		-> [^self concretizeUnimplemented].
		[MoveRXbrR]		-> [^self concretizeUnimplemented].
		[MoveXwrRR]		-> [^self concretizeMoveXwrRR].
		[MoveRXwrR]		-> [^self concretizeMoveRXwrR].
		[MoveRMwr]		-> [^self concretizeMoveRMwr].
		[MoveRdM64r]		-> [^self concretizeUnimplemented].
		[PopR]				-> [^self concretizePopR].
		[PushR]				-> [^self concretizePushR].
		[PushCq]			-> [^self concretizePushCq].
		[PushCw]			-> [^self concretizePushCw].
		[PrefetchAw]		-> [^self concretizePrefetchAw].
		[SubCheckOverflowCqR] -> [^self concretizeSubCheckOverflowCqR].
		"Conversion"
		[ConvertRRd]		-> [^self concretizeUnimplemented]}
]

{ #category : #abi }
CogMIPSELCompiler >> fullCallsAreRelative [
	"Answer if CallFull and/or JumpFull are relative and hence need relocating on method
	 compation. If so, they are annotated with IsRelativeCall in methods and relocated in
	 relocateIfCallOrMethodReference:mcpc:delta:"
	^false
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> functionAtAddress: mcpc [
	^(objectMemory longAt: mcpc) bitAnd: 63

]

{ #category : #assertions }
CogMIPSELCompiler >> genGetLeafCallStackPointerFunction [
	cogit MoveR: SP R: V0.
	cogit RetN: 0
]

{ #category : #'smalltalk calling convention' }
CogMIPSELCompiler >> genLoadCStackPointers [
	"Load the frame and stack pointer registers with those of the C stack,
	 effecting a switch to the C stack.  Used when machine code calls into
	 the CoInterpreter run-time (e.g. to invoke interpreter primitives)."
	cogit MoveAw: cogit cStackPointerAddress R: SPReg.
	cogit MoveAw: cogit cFramePointerAddress R: FPReg.
	^0
]

{ #category : #'smalltalk calling convention' }
CogMIPSELCompiler >> genLoadStackPointers [
	"Switch back to the Smalltalk stack. Assign SPReg first
	 because typically it is used immediately afterwards."
	cogit MoveAw: cogit stackPointerAddress R: SPReg.
	cogit MoveAw: cogit framePointerAddress R: FPReg.
	^0
]

{ #category : #abi }
CogMIPSELCompiler >> genMarshallNArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 [
	"Generate the code to pass up to four arguments in a C run-time call.  Hack: each argument is either a
	 negative number, that of an abstract register, or a non-negative number, that of a constant parameter.

	 Run-time calls have no more than four arguments, so chosen so that on ARM, where in its C ABI the
	 first four integer arguments are passed in registers, all arguments can be passed in registers.  We
	 defer to the back end to generate this code not so much that teh back end knows whether it uses
	 the stack or registers to pass arguments (it does, but...). In fact we defer for an extremely evil reason.
	 Doing so allows the x64 (where up to 6 args are passed) to assign the register arguments in an order
	 that allows some of the argument registers to be used for specificabstract  registers, specifically
	 ReceiverResultReg and ClassReg.  This is evil, evil, evil, but also its really nice to keep using the old
	 register assignments the principal author has grown accustomed to."
	<inline: true>
	self flag: #OABI.
	numArgs = 0 ifTrue: [^self].
	regOrConst0 >= 0
		ifTrue: [cogit MoveCq: regOrConst0 R: A0]
		ifFalse: [cogit MoveR: regOrConst0 R: A0].
	numArgs = 1 ifTrue: [^self].
	regOrConst1 >= 0
		ifTrue: [cogit MoveCq: regOrConst1 R: A1]
		ifFalse: [cogit MoveR: regOrConst1 R: A1].
	numArgs = 2 ifTrue: [^self].
	regOrConst2 >= 0
		ifTrue: [cogit MoveCq: regOrConst2 R: A2]
		ifFalse: [cogit MoveR: regOrConst2 R: A2].
	numArgs = 3 ifTrue: [^self].
	regOrConst3 >= 0
		ifTrue: [cogit MoveCq: regOrConst3 R: A3]
		ifFalse: [cogit MoveR: regOrConst3 R: A3]
]

{ #category : #'smalltalk calling convention' }
CogMIPSELCompiler >> genPushRegisterArgsForAbortMissNumArgs: numArgs [
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
						
	self flag: #inefficient. "Update SP once."
	
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
CogMIPSELCompiler >> genPushRegisterArgsForNumArgs: numArgs scratchReg: ignored [
	"Ensure that the register args are pushed before the retpc for arity <= self numRegArgs."
	"This is easy on a RISC like ARM because the return address is in the link register.  Putting
	 the receiver and args above the return address means the CoInterpreter has a single
	 machine-code frame format which saves us a lot of work
	NOTA BENE: we do NOT push the return address here, which means it must be dealt with later."
	self flag: #inefficient. "Update SP once."
	numArgs <= cogit numRegArgs ifTrue:
		[self assert: cogit numRegArgs <= 2.
		 cogit PushR: ReceiverResultReg.
		numArgs > 0 ifTrue:
			[cogit PushR: Arg0Reg.
			 numArgs > 1 ifTrue:
				[cogit PushR: Arg1Reg]]]
]

{ #category : #abi }
CogMIPSELCompiler >> genRemoveNArgsFromStack: n [
	"This is a no-op on MIPS since the ABI passes up to 4 args in registers and trampolines currently observe that limit."
	self assert: n <= 4.
	^0
]

{ #category : #abi }
CogMIPSELCompiler >> genRestoreRegs [
	"This method is poorly named. Is this for a Smalltalk -> C call or C -> Smalltalk call?
	 If the former we don't need to do anything because all of the abstract registers are
	 allocated to C preserved registers."
	self flag: #bogus.
]

{ #category : #abi }
CogMIPSELCompiler >> genSaveRegisters [
	"This method is poorly named. Is this for a Smalltalk -> C call or C -> Smalltalk call?
	 If the former we don't need to do anything because all of the abstract registers are
	 allocated to C preserved registers."
	self flag: #bogus.
]

{ #category : #'smalltalk calling convention' }
CogMIPSELCompiler >> genSaveStackPointers [
	"Save the frame and stack pointer registers to the framePointer
	 and stackPointer variables.  Used to save the machine code frame
	 for use by the run-time when calling into the CoInterpreter run-time."
	cogit MoveR: FPReg Aw: cogit framePointerAddress.
	cogit MoveR: SPReg Aw: cogit stackPointerAddress.
	^0
]

{ #category : #testing }
CogMIPSELCompiler >> hasConditionRegister [
	"Answer if the receiver supports, e.g., JumpOverflow after a regular AddRR"
	<inline: true>
	^false
]

{ #category : #testing }
CogMIPSELCompiler >> hasLinkRegister [
	^true "RA"
]

{ #category : #testing }
CogMIPSELCompiler >> hasThreeAddressArithmetic [
	"Answer if the receiver supports three-address arithmetic instructions"
	<inline: true>
	^true
]

{ #category : #encoding }
CogMIPSELCompiler >> high16BitsOf: word [
	^word >> 16
]

{ #category : #'generate machine code' }
CogMIPSELCompiler >> initialize [
	"This method intializes the Smalltalk instance.  The C instance is merely a struct and doesn't need initialization."
	<doNotGenerate>
	operands := CArrayAccessor on: (Array new: NumOperands).
	machineCode := CArrayAccessor on: (Array new: self machineCodeWords)
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> inlineCacheTagAt: callSiteReturnAddress [
	"Answer the inline cache tag for the return address of a send."
	
	"MoveCwR ClassReg selectorIndex/expectedClass
	 Call: unlinked send stub/expectedTarget
	 Push ReceiverResult <-- callSiteReturnAddress"
	
	"lui s3, selector/tagHigh
	 ori s3, s3, selector/tagLow
	 lui t9, stub/targetHigh
	 ori t9, t9, stub/targetLow
	 jalr t9
	 nop (delay slot)
	 ...  <-- callSiteReturnAddress"
	
	<var: #callSiteReturnAddress type: #usqInt>
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 24) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 20) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 16) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 12) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 8) = SPECIAL.
	self assert: (self functionAtAddress: callSiteReturnAddress - 8) = JALR.
	self assert: (objectMemory longAt: callSiteReturnAddress - 4) = self nop.

	^self literalAtAddress: callSiteReturnAddress - 20
]

{ #category : #testing }
CogMIPSELCompiler >> isAddressRelativeToVarBase: varAddress [
	<inline: true>
	<var: #varAddress type: #usqInt>
	"Support for addressing variables off the dedicated VarBaseReg"
	^varAddress notNil
	  and: [(cogit varBaseAddress - (1 << 15)) < varAddress
	  and: [varAddress < (cogit varBaseAddress + (1 << 15))]]
]

{ #category : #testing }
CogMIPSELCompiler >> isBigEndian [
	<inline: true>
	^false
]

{ #category : #testing }
CogMIPSELCompiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction."
	^self isJump or: [opcode = AlignmentNops]
]

{ #category : #accessing }
CogMIPSELCompiler >> isShortOffset: offset [
	^offset between: -16r8000 and: 16r7FFF
]

{ #category : #encoding }
CogMIPSELCompiler >> itype: opcode rs: rs rt: rt eitherImmediate: signedImmediate [	
	| unsignedImmediate |
	self assert: (opcode between: 0 and: 63).
	self assert: (rs between: 0 and: 31).
	self assert: (rt between: 0 and: 31).
	signedImmediate < 0
		ifTrue: [unsignedImmediate := signedImmediate + 16r10000]
		ifFalse: [unsignedImmediate := signedImmediate].
	self assert: (unsignedImmediate between: 0 and: 16rFFFF).
	^(((opcode << 26) bitOr: (rs << 21)) bitOr: (rt << 16)) bitOr: unsignedImmediate
]

{ #category : #encoding }
CogMIPSELCompiler >> itype: opcode rs: rs rt: rt signedImmediate: signedImmediate [	
	| unsignedImmediate |
	self assert: (opcode between: 0 and: 63).
	self assert: (rs between: 0 and: 31).
	self assert: (rt between: 0 and: 31).
	self assert: (signedImmediate between: -16r8000 and: 16r7FFF).
	signedImmediate < 0
		ifTrue: [unsignedImmediate := signedImmediate + 16r10000]
		ifFalse: [unsignedImmediate := signedImmediate].
	self assert: (unsignedImmediate between: 0 and: 16rFFFF).
	^(((opcode << 26) bitOr: (rs << 21)) bitOr: (rt << 16)) bitOr: unsignedImmediate
]

{ #category : #encoding }
CogMIPSELCompiler >> itype: opcode rs: rs rt: rt unsignedImmediate: immediate [	
	self assert: (opcode between: 0 and: 63).
	self assert: (rs between: 0 and: 31).
	self assert: (rt between: 0 and: 31).
	self assert: (immediate between: 0 and: 16rFFFF).
	^(((opcode << 26) bitOr: (rs << 21)) bitOr: (rt << 16)) bitOr: immediate
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> jA: target [
	self assert: (target bitAnd: 3) = 0.
	^self jtype: J target: (target bitAnd: 16r0FFFFFFF) >> 2
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> jR: targetReg [
	^self rtype: SPECIAL rs: targetReg rt: 0 rd: 0 sa: 0 funct: JR.
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> jalA: target [
	self assert: (target bitAnd: 3) = 0.
	^self jtype: JAL target: (target bitAnd: 16r0FFFFFFF) >> 2
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> jalR: targetReg [
	^self rtype: SPECIAL rs: targetReg rt: 0 rd: RA sa: 0 funct: JALR.
]

{ #category : #encoding }
CogMIPSELCompiler >> jtype: opcode target: target [
	self assert: (opcode between: 0 and: 63).
	self assert: (opcode between: 0 and: 16r7FFFFFF).
	^(opcode << 26) bitOr: target
]

{ #category : #accessing }
CogMIPSELCompiler >> jumpLongByteSize [
	self flag: #bogus. "Caller seems to actually want jumpFullByteSize"
	^16
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> jumpLongConditionalByteSize [
	^16
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> jumpLongConditionalTargetBeforeFollowingAddress: mcpc [
	Transcript nextPutAll: mcpc hex; cr.
	"mcpc - 16:	beq/ne Cmp, ZR, +12
	 mcpc - 12:	nop (delay slot)
	 mcpc - 8:	j psuedo-address
	 mcpc - 4:	nop (delay slot)"		
	self assert: (((self opcodeAtAddress: mcpc - 16) == BEQ) 
				or: [(self opcodeAtAddress: mcpc - 16) == BNE]).
	self assert: (objectMemory longAt: mcpc - 12) == self nop. "Delay slot"
	self assert: (self opcodeAtAddress: mcpc - 8) == J.
	self assert: (objectMemory longAt: mcpc - 4) == self nop. "Delay slot"
	^self targetFromJTypeAtAddress: mcpc - 8
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> jumpLongTargetBeforeFollowingAddress: mcpc [ 
	"Answer the target address for the long jump immediately preceding mcpc"
	self assert: (objectMemory longAt: mcpc - 4) == self nop. "Delay slot"
	self assert: (self opcodeAtAddress: mcpc - 8) == SPECIAL.
	self assert: (self functionAtAddress: mcpc - 8) == JR.
	^self literalAtAddress: mcpc - 12
	
]

{ #category : #accessing }
CogMIPSELCompiler >> jumpShortByteSize [
	^8
]

{ #category : #'encoding - memory' }
CogMIPSELCompiler >> lbR: destReg base: baseReg offset: offset [
	^self itype: LB rs: baseReg rt: destReg signedImmediate: offset
]

{ #category : #'encoding - memory' }
CogMIPSELCompiler >> lbuR: destReg base: baseReg offset: offset [
	^self itype: LBU rs: baseReg rt: destReg signedImmediate: offset
]

{ #category : #abi }
CogMIPSELCompiler >> leafCallStackPointerDelta [
	"Answer the delta from the stack pointer after a call to the stack pointer
	 immediately prior to the call.  This is used to compute the stack pointer
	 immediately prior to  call from within a leaf routine, which in turn is used
	 to capture the c stack pointer to use in trampolines back into the C run-time."
	"This might actually be false, since directly after a call, lr, fp and variable registers need be pushed onto the stack. It depends on the implementation of call."
	^0
]

{ #category : #'encoding - memory' }
CogMIPSELCompiler >> lhR: destReg base: baseReg offset: offset [
	^self itype: LH rs: baseReg rt: destReg signedImmediate: offset
]

{ #category : #'encoding - memory' }
CogMIPSELCompiler >> lhuR: destReg base: baseReg offset: offset [
	^self itype: LHU rs: baseReg rt: destReg signedImmediate: offset
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> literalAtAddress: mcpc [
	| high low |
	self assert: (self opcodeAtAddress: mcpc) = ORI.
	self assert: (self opcodeAtAddress: mcpc - 4) = LUI.
	low := (objectMemory longAt: mcpc) bitAnd: 16rFFFF.
	high := (objectMemory longAt: mcpc - 4) bitAnd: 16rFFFF.
	^high << 16 bitOr: low

]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> literalAtAddress: mcpc put: newLiteral [
	| oldUpper newUpper oldLower newLower |
	self assert: (self opcodeAtAddress: mcpc - 4) = LUI.
	self assert: (self opcodeAtAddress: mcpc) = ORI.
	
	oldUpper := objectMemory longAt: mcpc - 4.
	newUpper := (oldUpper bitAnd: 16rFFFF0000) bitOr: (self high16BitsOf: newLiteral).
	objectMemory longAt: mcpc - 4 put: newUpper.
	
	oldLower := objectMemory longAt: mcpc.
	newLower := (oldLower bitAnd: 16rFFFF0000) bitOr: (self low16BitsOf: newLiteral).
	objectMemory longAt: mcpc put: newLower.
	
	self assert: (self opcodeAtAddress: mcpc - 4) = LUI.
	self assert: (self opcodeAtAddress: mcpc) = ORI.
	
	self assert: (self literalAtAddress: mcpc) = newLiteral.
	
	^newLiteral
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> literalBeforeFollowingAddress: followingAddress [
	"Answer the literal embedded in the instruction immediately preceding followingAddress.
	 This is used in the MoveCwR, PushCwR and CmpCwR cases."
	
	"lui/ori, lui/ori/sw/addi, lui/ori/subu/slt/slt/sltu/sltu"
	
	| lastOpcode lastFunction oriAddress |
	lastOpcode := self opcodeAtAddress: followingAddress - 4.
	lastFunction := self functionAtAddress: followingAddress - 4.
	oriAddress := 0.
	lastOpcode = ORI ifTrue: [oriAddress := followingAddress - 4].
	lastOpcode = ADDIU ifTrue: [oriAddress := followingAddress - 16].
	(lastOpcode = SPECIAL and: [lastFunction = SLTU]) ifTrue: [oriAddress := followingAddress - 24].
	self assert: oriAddress ~= 0.
	^self literalAtAddress: oriAddress

]

{ #category : #testing }
CogMIPSELCompiler >> literalLoadInstructionBytes [
	"Answer the size of a literal load instruction (which may or may not include the size of the literal).
	 This differs between in-line and out-of-line literal generation."
	<inline: true>
	^8
]

{ #category : #accessing }
CogMIPSELCompiler >> loadLiteralByteSize [
	^8
]

{ #category : #accessing }
CogMIPSELCompiler >> loadPICLiteralByteSize [
	"Answer the byte size of a MoveCwR opcode's corresponding machine code
	 when the argument is a PIC.  This is for the self-reference at the end of a
	 closed PIC."
	<inline: true>
	^self loadLiteralByteSize
]

{ #category : #encoding }
CogMIPSELCompiler >> low16BitsOf: word [
	^word bitAnd: 16rFFFF
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> luiR: destReg C: imm [
	^self itype: LUI rs: 0 rt: destReg eitherImmediate: imm
]

{ #category : #'encoding - memory' }
CogMIPSELCompiler >> lwR: destReg base: baseReg offset: offset [
	^self itype: LW rs: baseReg rt: destReg signedImmediate: offset
]

{ #category : #accessing }
CogMIPSELCompiler >> machineCodeAt: anOffset [
	"read aWord from machineCode, with little endian"
	<inline: true>
	^machineCode at: anOffset // 4
]

{ #category : #accessing }
CogMIPSELCompiler >> machineCodeAt: anOffset put: aWord [
	"add aWord to machineCode, with little endian"
	<inline: true>
	machineCode at: anOffset // 4 put: aWord
]

{ #category : #'generate machine code' }
CogMIPSELCompiler >> machineCodeBytes [
	^self machineCodeWords * 4
]

{ #category : #'generate machine code' }
CogMIPSELCompiler >> machineCodeWords [
	"Answer the maximum number of words of machine code generated for any abstract instruction.
	 e.g. CmpCwR =>
			lui at, <high>
			ori at, <low>
			subu Cmp, reg, at
			slt CmpSLT, reg, at
			slt CmpSGT, reg, at
			slt CmpULT, reg, at
			slt CmpUGT, reg, at"
	self flag: #inefficient.
	^7
]

{ #category : #accessing }
CogMIPSELCompiler >> maxAbstractGeneralPurposeReg [
	"Answer the largest index of an abstract general-purpose register used by this compiler.
	 N.B.  Abstract registers are negative numbers."
	<inline: true>
	self flag: #bogus. "The caller should ask for a register mask, not a range."
	^TempReg
]

{ #category : #'abstract instructions' }
CogMIPSELCompiler >> maybeEstablishVarBase [
	"The receiver has a VarBaseReg; generate the code to set it to its value."
	cogit MoveCq: cogit varBaseAddress R: VarBaseReg
]

{ #category : #accessing }
CogMIPSELCompiler >> minAbstractGeneralPurposeReg [
	"Answer the smallest index of an abstract general-purpose register used by this compiler.
	 N.B.  Abstract registers are negative numbers."
	<inline: true>
	self flag: #bogus. "The caller should ask for a register mask, not a range."
	^TempReg
]

{ #category : #printing }
CogMIPSELCompiler >> nameForRegister: reg [ "<Integer>"
	<doNotGenerate>
	reg < 0 ifTrue: [^super nameForRegister: reg].
	^MIPSConstants nameForRegister: reg
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> nop [
	^0 "SLL ZR, ZR, 0"
]

{ #category : #'generate machine code' }
CogMIPSELCompiler >> nopsFrom: startAddr to: endAddr [
	self assert: endAddr - startAddr + 1 \\ 4 = 0.
	self assert: (self nop = 0).
	startAddr to: endAddr do: [:p| objectMemory byteAt: p put: 0].
]

{ #category : #'abstract instructions' }
CogMIPSELCompiler >> noteFollowingConditionalBranch: branch [
	"Support for processors without condition codes, such as the MIPS.
	 Answer the branch opcode.  Modify the receiver and the branch to
	 implement a suitable conditional branch that doesn't depend on
	 condition codes being set by the receiver."
	<var: #branch type: #'AbstractInstruction *'>
	branch opcode caseOf: {
		[JumpOverflow]		-> [opcode := opcode caseOf: {
										[AddCqR]	-> [AddCheckOverflowCqR].
										[AddRR]		-> [AddCheckOverflowRR].
										[MulRR]		-> [MulCheckOverflowRR].
										[SubCqR]	-> [SubCheckOverflowCqR].
										[SubRR]		-> [SubCheckOverflowRR].
										}].
		[JumpNoOverflow]	-> [opcode := opcode caseOf: {
										[AddCqR]	-> [AddCheckOverflowCqR].
										[AddRR]		-> [AddCheckOverflowRR].
										[MulRR]		-> [MulCheckOverflowRR].
										[SubCqR]	-> [SubCheckOverflowCqR].
										[SubRR]		-> [SubCheckOverflowRR].
										}].
		"Ryan, I'm imagining that all the other cases go in here, such as collapsing CmpRR; JumpZero to Label; BrEqRR.
		 This is obviously not nearly complete."
		[JumpZero]			-> [opcode caseOf: {
									[CmpRR]	-> [branch setOpcode: BrEqRR andOperandsFrom: self.
													branch operands at: 3 put: (operands at: 1).
													opcode := Label].
								}].
		[JumpNonZero]		-> [opcode caseOf: {
									[CmpRR]	-> [branch setOpcode: BrNeRR andOperandsFrom: self.
													branch operands at: 3 put: (operands at: 1).
													opcode := Label].
								}].
		[JumpLongZero]		-> [opcode caseOf: {
									[CmpRR]	-> [branch setOpcode: BrNeRR andOperandsFrom: self.
													"skip the following long branch"
													branch operands at: 3 put: self jumpLongByteSize.
													opcode := JumpLong].
								}].
		[JumpLongNonZero]	-> [opcode caseOf: {
									[CmpRR]	-> [branch setOpcode: BrEqRR andOperandsFrom: self.
													"skip the following long branch"
													branch operands at: 3 put: self jumpLongByteSize.
													opcode := JumpLong].
								}].
		}
		"No otherwise for now to catch all cases"
		"otherwise: []".
	^branch
]

{ #category : #abi }
CogMIPSELCompiler >> numIntRegArgs [
	self flag: #OABI.
	^4
]

{ #category : #abi }
CogMIPSELCompiler >> numberOfSaveableRegisters [
	"Answer the number of registers to be saved in a trampoline call that saves registers.
	 None, See genSaveRegisters."
	<cmacro: '(self) 0'>
	^0
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> opcodeAtAddress: mcpc [
	^(objectMemory longAt: mcpc) >> 26

]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> orR: destReg R: leftReg R: rightReg [
	^self rtype: SPECIAL rs: leftReg rt: rightReg rd: destReg sa: 0 funct: OR
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> oriR: destReg R: srcReg C: imm [
	^self itype: ORI rs: srcReg rt: destReg eitherImmediate: imm
]

{ #category : #'generate machine code' }
CogMIPSELCompiler >> outputMachineCodeAt: targetAddress [
	"Override to move machine code a word at a time."
	<inline: true>
	0 to: machineCodeSize - 1 by: 4 do:
		[:j|
		objectMemory longAt: targetAddress + j put: (machineCode at: j // 4)]
]

{ #category : #'generate machine code' }
CogMIPSELCompiler >> padIfPossibleWithNopsFrom: startAddr to: endAddr [
	self flag: #bogus. "Methods should be initialized with the stop instruction, not nop."

	startAddr to: endAddr - 1 by: 4 do: 
		[:addr | objectMemory longAt: addr put: self stop].
]

{ #category : #'encoding - memory' }
CogMIPSELCompiler >> prefR: baseReg offset: offset hint: hint [
	self flag: #todo. "Should we generate a nop instead? gcc gives an error trying to assemble this for mips1 (1985), mips2 (1990) and mips3 (1992), but succeeds with mips4 (1994) and mips32 (1999)."
	self assert: (hint == HintLoad or: [hint == HintStore]).
	^self itype: PREF rs: baseReg rt: hint signedImmediate: offset
]

{ #category : #accessing }
CogMIPSELCompiler >> pushLinkRegisterByteSize [
	^8
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> relocateMethodReferenceBeforeAddress: pc by: delta [
	| oldValue newValue |
	cogit disassembleFrom: pc - 8 to: pc.

	oldValue := self literalAtAddress: pc - 4.
	newValue := oldValue + delta.
	self literalAtAddress: pc - 4 put: newValue.
	
	cogit disassembleFrom: pc - 8 to: pc.
	self assert: (self literalAtAddress: pc - 4) = newValue.
	
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> rewriteCPICCaseAt: followingAddress tag: newTag objRef: newObjRef target: newTarget [
	"rewrite the three values involved in a CPIC case. Used by the create & extend cpcic methods"

	"lui at, tagHigh
	 ori at, at, tagLow
	 subu t0, s5, at (Cmp)
	 slt ... (Cmp)
	 slt ... (Cmp)
	 sltu ... (Cmp)
	 sltu ... (Cmp)
	 lui s4, objRefHigh
	 ori s4, s4, objRefLow
	 bne t0, zr, +12
	 nop (delay slot)
	 j target
	 nop (delay slot)
	 .... <-- followingAddress"

	cogit disassembleFrom: followingAddress - 52 to: followingAddress.
	self assert: (self opcodeAtAddress: followingAddress - 52) = LUI.
	self assert: (self opcodeAtAddress: followingAddress - 48) = ORI.
	self assert: (self functionAtAddress: followingAddress - 44) = SUBU.
	self assert: (self functionAtAddress: followingAddress - 40) = SLT.
	self assert: (self functionAtAddress: followingAddress - 36) = SLT.
	self assert: (self functionAtAddress: followingAddress - 32) = SLTU.
	self assert: (self functionAtAddress: followingAddress - 28) = SLTU.
	self assert: (self opcodeAtAddress: followingAddress - 24) = LUI.
	self assert: (self opcodeAtAddress: followingAddress - 20) = ORI.
	self assert: (self opcodeAtAddress: followingAddress - 16) = BNE.
	self assert: (objectMemory longAt: followingAddress - 12) = self nop.
	self assert: (self opcodeAtAddress: followingAddress - 8) = J.
	self assert: (objectMemory longAt: followingAddress - 4) = self nop.
	
	self literalAtAddress: followingAddress - 48 put: newTag.
	self literalAtAddress: followingAddress - 20 put: newObjRef.
	self rewriteJTypeAtAddress: followingAddress - 8 target: newTarget.

	cogit disassembleFrom: followingAddress - 52 to: followingAddress.
	self assert: (self opcodeAtAddress: followingAddress - 52) = LUI.
	self assert: (self opcodeAtAddress: followingAddress - 48) = ORI.
	self assert: (self functionAtAddress: followingAddress - 44) = SUBU.
	self assert: (self functionAtAddress: followingAddress - 40) = SLT.
	self assert: (self functionAtAddress: followingAddress - 36) = SLT.
	self assert: (self functionAtAddress: followingAddress - 32) = SLTU.
	self assert: (self functionAtAddress: followingAddress - 28) = SLTU.
	self assert: (self opcodeAtAddress: followingAddress - 24) = LUI.
	self assert: (self opcodeAtAddress: followingAddress - 20) = ORI.
	self assert: (self opcodeAtAddress: followingAddress - 16) = BNE.
	self assert: (objectMemory longAt: followingAddress - 12) = self nop.
	self assert: (self opcodeAtAddress: followingAddress - 8) = J.
	self assert: (objectMemory longAt: followingAddress - 4) = self nop.

	^56
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> rewriteCPICJumpAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a jump instruction to call a different target.  This variant is used to reset the 
	jumps in the prototype CPIC to suit each use,.   
	Answer the extent of the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	
	cogit disassembleFrom: callSiteReturnAddress - 16 to: callSiteReturnAddress + 16.
	self halt.
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> rewriteCallAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a call instruction to call a different target.  This variant is used to link PICs
	 in ceSendMiss et al,.   
	Answer the extent of the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	
	"lui t9, stub/targetHigh
	 ori t9, t9, stub/targetLow
	 jalr t9
	 nop (delay slot)
	 ...  <-- callSiteReturnAddress"

	self assert: (self opcodeAtAddress: callSiteReturnAddress - 16) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 12) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 8) = SPECIAL.
	self assert: (self functionAtAddress: callSiteReturnAddress - 8) = JALR.
	self assert: (objectMemory longAt: callSiteReturnAddress - 4) = self nop.
	
	cogit disassembleFrom: callSiteReturnAddress - 16 to: callSiteReturnAddress.

	self literalAtAddress: callSiteReturnAddress - 12 put: callTargetAddress.

	self assert: (self opcodeAtAddress: callSiteReturnAddress - 16) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 12) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 8) = SPECIAL.
	self assert: (self functionAtAddress: callSiteReturnAddress - 8) = JALR.
	self assert: (objectMemory longAt: callSiteReturnAddress - 4) = self nop.

	cogit disassembleFrom: callSiteReturnAddress - 16 to: callSiteReturnAddress.

	^20
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> rewriteInlineCacheAt: callSiteReturnAddress tag: cacheTag target: callTargetAddress [
	"Rewrite an inline cache to call a different target for a new tag.  This variant is used
	 to link unlinked sends in ceSend:to:numArgs: et al.  Answer the extent of the code
	 change which is used to compute the range of the icache to flush."
	
	"MoveCwR ClassReg selectorIndex/expectedClass
	 Call: unlinked send stub/expectedTarget
	 Push ReceiverResult <-- callSiteReturnAddress"
	
	"lui s3, selector/tagHigh
	 ori s3, s3, selector/tagLow
	 lui t9, stub/targetHigh
	 ori t9, t9, stub/targetLow
	 jalr t9
	 nop (delay slot)
	 ...  <-- callSiteReturnAddress"
	
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 24) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 20) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 16) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 12) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 8) = SPECIAL.
	self assert: (self functionAtAddress: callSiteReturnAddress - 8) = JALR.
	self assert: (objectMemory longAt: callSiteReturnAddress - 4) = self nop.
	
	cogit disassembleFrom: callSiteReturnAddress - 24 to: callSiteReturnAddress.

	self literalAtAddress: callSiteReturnAddress - 20 put: cacheTag.
	self literalAtAddress: callSiteReturnAddress - 12 put: callTargetAddress.

	self assert: (self opcodeAtAddress: callSiteReturnAddress - 24) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 20) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 16) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 12) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 8) = SPECIAL.
	self assert: (self functionAtAddress: callSiteReturnAddress - 8) = JALR.
	self assert: (objectMemory longAt: callSiteReturnAddress - 4) = self nop.

	cogit disassembleFrom: callSiteReturnAddress - 24 to: callSiteReturnAddress.

	^28
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> rewriteJTypeAtAddress: mcpc target: newTarget [
	| regionMask |
	regionMask := 16rF0000000.
	"mcpc + 4: relative to delay slot not j"
	self assert: (mcpc + 4 bitAnd: regionMask) = (newTarget bitAnd: regionMask).
	objectMemory longAt: mcpc put: (self jA: newTarget).
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> rewriteJumpLongAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a jump instruction to call a different target.  This variant is used to reset the 
	jumps in the prototype CPIC to suit each use,.   
	Answer the extent of the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	
	"lui t9, stub/targetHigh
	 ori t9, t9, stub/targetLow
	 jr t9
	 nop (delay slot)
	 ...  <-- callSiteReturnAddress"

	self assert: (self opcodeAtAddress: callSiteReturnAddress - 16) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 12) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 8) = SPECIAL.
	self assert: (self functionAtAddress: callSiteReturnAddress - 8) = JR.
	self assert: (objectMemory longAt: callSiteReturnAddress - 4) = self nop.
	
	cogit disassembleFrom: callSiteReturnAddress - 16 to: callSiteReturnAddress.

	self literalAtAddress: callSiteReturnAddress - 12 put: callTargetAddress.

	self assert: (self opcodeAtAddress: callSiteReturnAddress - 16) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 12) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 8) = SPECIAL.
	self assert: (self functionAtAddress: callSiteReturnAddress - 8) = JR.
	self assert: (objectMemory longAt: callSiteReturnAddress - 4) = self nop.

	cogit disassembleFrom: callSiteReturnAddress - 16 to: callSiteReturnAddress.

	^20
]

{ #category : #encoding }
CogMIPSELCompiler >> rtype: opcode rs: rs rt: rt rd: rd sa: sa funct: funct [
	self assert: (opcode between: 0 and: 63).
	self assert: (rs between: 0 and: 31).
	self assert: (rt between: 0 and: 31).
	self assert: (rd between: 0 and: 31).
	self assert: (sa between: 0 and: 31).
	self assert: (funct between: 0 and: 63).
	^(((((opcode << 26) bitOr: (rs << 21)) bitOr: (rt << 16)) bitOr: (rd << 11)) bitOr: (sa << 6)) bitOr: funct
]

{ #category : #abi }
CogMIPSELCompiler >> saveAndRestoreLinkRegAround: aBlock [
	"If the processor's ABI includes a link register, generate instructions
	 to save and restore it around aBlock, which is assumed to generate code."
	<inline: true>
	| inst |
	inst := cogit PushR: LinkReg.
	aBlock value.
	cogit PopR: LinkReg.
	^inst
]

{ #category : #'encoding - memory' }
CogMIPSELCompiler >> sbR: srcReg base: baseReg offset: offset [
	^self itype: SB rs: baseReg rt: srcReg signedImmediate: offset
]

{ #category : #accessing }
CogMIPSELCompiler >> setOpcode: anOpcode andOperandsFrom: cmpInstruction [
	<var: #cmpInstruction type: #'AbstractInstruction *'>
	<inline: true>
	opcode := anOpcode.
	operands
		at: 0 put: (cmpInstruction opcodes at: 0);
		at: 1 put: (cmpInstruction opcodes at: 1)
]

{ #category : #'encoding - memory' }
CogMIPSELCompiler >> shR: srcReg base: baseReg offset: offset [
	^self itype: SH rs: baseReg rt: srcReg signedImmediate: offset
]

{ #category : #'generate machine code' }
CogMIPSELCompiler >> sizePCDependentInstructionAt: eventualAbsoluteAddress [
	"Size a jump and set its address.  The target may be another instruction
	 or an absolute address.  On entry the address inst var holds our virtual
	 address. On exit address is set to eventualAbsoluteAddress, which is
	 where this instruction will be output.  The span of a jump to a following
	 instruction is therefore between that instruction's address and this
	 instruction's address ((which are both still their virtual addresses), but the
	 span of a jump to a preceding instruction or to an absolute address is
	 between that instruction's address (which by now is its eventual absolute
	 address) or absolute address and eventualAbsoluteAddress.

	 ARM is simple; the 26-bit call/jump range means no short jumps.  This routine
	 only has to determine the targets of jumps, not determine sizes."

	opcode = AlignmentNops ifTrue:
		[| alignment |
		 address := eventualAbsoluteAddress.
		 alignment := operands at: 0.
		 ^machineCodeSize := (eventualAbsoluteAddress + (alignment - 1) bitAnd: alignment negated)
							   - eventualAbsoluteAddress].
	self assert: (self isJump or: [opcode = Call or: [opcode = CallFull]]).
	self isJump ifTrue: [self resolveJumpTarget].
	address := eventualAbsoluteAddress.
	^machineCodeSize := maxSize
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> sllR: destReg R: sourceReg C: shiftAmount [
	^self rtype: SPECIAL rs: 0 rt: sourceReg rd: destReg sa: shiftAmount funct: SLL
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> sllvR: destReg R: leftReg R: rightReg [
	^self rtype: SPECIAL rs: rightReg rt: leftReg rd: destReg sa: 0 funct: SLLV
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> sltR: destReg R: leftReg R: rightReg [
	^self rtype: SPECIAL rs: leftReg rt: rightReg rd: destReg sa: 0 funct: SLT
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> sltiR: destReg R: leftReg C: imm [
	^self itype: SLTI rs: leftReg rt: destReg signedImmediate: imm
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> sltiuR: destReg R: leftReg C: imm [
	^self itype: SLTIU rs: leftReg rt: destReg signedImmediate: imm
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> sltuR: destReg R: leftReg R: rightReg [
	^self rtype: SPECIAL rs: leftReg rt: rightReg rd: destReg sa: 0 funct: SLTU
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> sraR: destReg R: sourceReg C: shiftAmount [
	^self rtype: SPECIAL rs: 0 rt: sourceReg rd: destReg sa: shiftAmount funct: SRA
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> sravR: destReg R: leftReg R: rightReg [
	^self rtype: SPECIAL rs: rightReg rt: leftReg rd: destReg sa: 0 funct: SRAV
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> srlR: destReg R: sourceReg C: shiftAmount [
	^self rtype: SPECIAL rs: 0 rt: sourceReg rd: destReg sa: shiftAmount funct: SRL
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> srlvR: destReg R: leftReg R: rightReg [
	^self rtype: SPECIAL rs: rightReg rt: leftReg rd: destReg sa: 0 funct: SRLV
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> stop [
	^self break: 0
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> storeLiteral: literal beforeFollowingAddress: followingAddress [
	"Rewrite the long constant loaded by a MoveCwR or PushCwR before the given address"
	| lastOpcode oriAddress |
	
	self flag: #bogus. "The caller ought to know what it is patching, and this should be split into separate methods with stricter checking."
	
	lastOpcode := self opcodeAtAddress: followingAddress - 4.
	oriAddress := 0.
	lastOpcode = ORI ifTrue: [oriAddress := followingAddress - 4].
	lastOpcode = ADDIU ifTrue: [oriAddress := followingAddress - 16].
	self assert: oriAddress ~= 0.
	^self literalAtAddress: oriAddress put: literal
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> subuR: destReg R: leftReg R: rightReg [
	^self rtype: SPECIAL rs: leftReg rt: rightReg rd: destReg sa: 0 funct: SUBU
]

{ #category : #'encoding - memory' }
CogMIPSELCompiler >> swR: srcReg base: baseReg offset: offset [
	^self itype: SW rs: baseReg rt: srcReg signedImmediate: offset
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> targetFromJTypeAtAddress: mcpc [
	| targetLow |
	targetLow := (objectMemory longAt: mcpc) bitAnd: 16r3FFFFFF.
	"mcpc + 4: relative to delay slot not j"
	^((mcpc + 4) bitAnd: 16rF0000000) + (targetLow << 2) 
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> xorR: destReg R: leftReg R: rightReg [
	^self rtype: SPECIAL rs: leftReg rt: rightReg rd: destReg sa: 0 funct: XOR
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> xoriR: destReg R: srcReg C: imm [
	^self itype: XORI rs: srcReg rt: destReg eitherImmediate: imm
]
