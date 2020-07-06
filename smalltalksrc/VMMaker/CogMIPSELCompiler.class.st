"
Implemenation for 32-bit, little-endian MIPS running with the OABI (Debian port name 'mipsel').

Status: incomplete, no work planned

In December 2015, this implementation was complete enough to run the Newspeak test suite under the simulator. The compiled VM, however, failed at startup. The author suspects that some variables are lacking correct type annotations, being translated by Slang as unsigned when they should be signed or vice versa, causing some shift or comparison to have the wrong signness in C, but it may well be some other discrepancy between the behavior of Slang code when run in Smalltalk and when translated to C.

This implementation also does not provide instructions for working with floating point numbers, instead falling back to the interpreter's implementation for all floating point operations.

"
Class {
	#name : #CogMIPSELCompiler,
	#superclass : #CogAbstractInstruction,
	#classVars : [
		'AddCheckOverflowCqR',
		'AddCheckOverflowRR',
		'BrEqualRR',
		'BrLongEqualRR',
		'BrLongNotEqualRR',
		'BrNotEqualRR',
		'BrSignedGreaterEqualRR',
		'BrSignedGreaterRR',
		'BrSignedLessEqualRR',
		'BrSignedLessRR',
		'BrUnsignedGreaterEqualRR',
		'BrUnsignedGreaterRR',
		'BrUnsignedLessEqualRR',
		'BrUnsignedLessRR',
		'BranchTemp',
		'Cmp',
		'ConcreteVarBaseReg',
		'DivRR',
		'MoveHighR',
		'MoveLowR',
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

{ #category : #translation }
CogMIPSELCompiler class >> declareCVarsIn: aCCodeGenerator [
	super declareCVarsIn: aCCodeGenerator.
	aCCodeGenerator addHeaderFile: '<asm/cachectl.h>'. "For cacheflush"
]

{ #category : #translation }
CogMIPSELCompiler class >> identifyingPredefinedMacros [
	^#('__MIPSEL__')
]

{ #category : #'class initialization' }
CogMIPSELCompiler class >> initialize [
	"CogRTLOpcodes initialize. CogMIPSELCompiler initialize"

	super initialize.
	
	ConcreteVarBaseReg := S6.

	Cmp := T0.

	Overflow := T0.
	OverflowTemp1 := T1.
	OverflowTemp2 := T2.
	
	"Can't use AT, Cmp or Overflow because we may need to preserve them for sequences like
	 CmpCwR
	 JumpZero
	 JumpBelow"
	BranchTemp := T3.

	"OABI position independent code expects T9 to have its entry point on entry?"
	self flag: #OABI.
	TargetReg := T9.

	"Specific instructions"
	self initializeSpecificOpcodes: #(
		MulRR
		DivRR
		MoveLowR
		MoveHighR
		AddCheckOverflowCqR 
		AddCheckOverflowRR
		MulCheckOverflowRR
		SubCheckOverflowCqR
		SubCheckOverflowRR
		BrEqualRR
		BrNotEqualRR 
		BrUnsignedLessRR
		BrUnsignedLessEqualRR
		BrUnsignedGreaterRR
		BrUnsignedGreaterEqualRR
		BrSignedLessRR
		BrSignedLessEqualRR
		BrSignedGreaterRR
		BrSignedGreaterEqualRR
		BrLongEqualRR
		BrLongNotEqualRR) 
			in: thisContext method
		
	
]

{ #category : #'class initialization' }
CogMIPSELCompiler class >> initializeAbstractRegisters [
	"Assign the abstract registers with the identities/indices of the relevant concrete registers."

	"See MIPSConstants>>initializeRegisters for a description of the C ABI."

	"Note we can fit all of the abstract registers in C preserved registers, and
	 not need to save or restore them at runtime calls."
	super initializeAbstractRegisters.

	self flag: #OABI.
	CallerSavedRegisterMask := self
									registerMaskFor: T0 and: T1 and: T2 and: T3
									and: T4 and: T5 and: T6 and: T7 and: T8 and: T9.

	ReceiverResultReg		:= S0.
	Arg0Reg				:= S1.
	Arg1Reg				:= S2.
	ClassReg				:= S3.
	SendNumArgsReg		:= S4.
	TempReg				:= S5.
	VarBaseReg			:= S6. "Must be callee saved"
	SPReg					:= SP.
	FPReg					:= FP.
	RISCTempReg			:= AT.
	LinkReg					:= RA.

	NumRegisters := 32.

	self flag: #todo.
	"Extra0Reg			:= ??.
	Extra1Reg			:= ??.
	Extra2Reg			:= ??.
	Extra3Reg			:= ??.
	Extra4Reg			:= ??.
	Extra5Reg			:= ??.
	Extra6Reg			:= ??.
	Extra7Reg			:= ??."

	self flag: #todo.
	"DPFPReg0				:= ??.
	DPFPReg1				:= ??.
	DPFPReg2				:= ??.
	DPFPReg3				:= ??.
	DPFPReg4				:= ??.
	DPFPReg5				:= ??.
	DPFPReg6				:= ??.
	DPFPReg7				:= ??.
	DPFPReg8				:= ??.
	DPFPReg9				:= ??.
	DPFPReg10				:= ??.
	DPFPReg11				:= ??.
	DPFPReg12				:= ??.
	DPFPReg13				:= ??.
	DPFPReg14				:= ??.
	DPFPReg15				:= ??"
]

{ #category : #translation }
CogMIPSELCompiler class >> machineCodeDeclaration [
	"Answer the declaration for the machineCode array.
	 MPIS instructions are 32-bits in length."
	^{#'unsigned int'. '[', self basicNew machineCodeWords printString, ']'}
]

{ #category : #'debug printing' }
CogMIPSELCompiler class >> printFormatForOpcodeName: opcodeName [
	"Answer a sequence of $r, $f or nil for the operands in the opcode, used for printing, where
	 r => integer register, f => floating point register, and nil => numeric or address operand.
	 Subclasses can override to provide a format string for their own private opcodes."
	^(opcodeName startsWith: 'Br') ifTrue: [' rr'] ifFalse: [#()]
]

{ #category : #translation }
CogMIPSELCompiler class >> wordSize [
	"This is a 32-bit ISA"
	^4
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
	^self itype: BEQ rs: leftReg rt: rightReg signedImmediate: offset >>> 2
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> bgezR: cmpReg offset: offset [
	self assert: (offset bitAnd: 3) = 0.
	self assert: (offset between: -16r20000 and: 16r1FFFF).
	^self itype: REGIMM rs: cmpReg rt: BGEZ signedImmediate: offset >>> 2
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> bgtzR: cmpReg offset: offset [
	self assert: (offset bitAnd: 3) = 0.
	self assert: (offset between: -16r20000 and: 16r1FFFF).
	^self itype: BGTZ rs: cmpReg rt: 0 signedImmediate: offset >>> 2
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> blezR: cmpReg offset: offset [
	self assert: (offset bitAnd: 3) = 0.
	self assert: (offset between: -16r20000 and: 16r1FFFF).
	^self itype: BLEZ rs: cmpReg rt: 0 signedImmediate: offset >>> 2
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> bltzR: cmpReg offset: offset [
	self assert: (offset bitAnd: 3) = 0.
	self assert: (offset between: -16r20000 and: 16r1FFFF).
	^self itype: REGIMM rs: cmpReg rt: BLTZ signedImmediate: offset >>> 2
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> bneR: leftReg R: rightReg offset: offset [
	self assert: (offset bitAnd: 3) = 0.
	self assert: (offset between: -16r20000 and: 16r1FFFF).
	^self itype: BNE rs: leftReg rt: rightReg signedImmediate: offset >>> 2
]

{ #category : #'generate machine code' }
CogMIPSELCompiler >> cResultRegister [
	"Answer the register through which C funcitons return integral results."
	<inline: true>
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

{ #category : #testing }
CogMIPSELCompiler >> canDivQuoRem [
	^true
]

{ #category : #testing }
CogMIPSELCompiler >> canMulRR [
	^true
]

{ #category : #accessing }
CogMIPSELCompiler >> cmpC32RTempByteSize [
	^8
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
		[BrEqualRR]						-> [^8].
		[BrNotEqualRR]					-> [^8].
		[BrUnsignedLessRR]			-> [^12].
		[BrUnsignedLessEqualRR]		-> [^12].
		[BrUnsignedGreaterRR]			-> [^12].
		[BrUnsignedGreaterEqualRR]	-> [^12].
		[BrSignedLessRR]				-> [^12].
		[BrSignedLessEqualRR]			-> [^12].
		[BrSignedGreaterRR]			-> [^12].
		[BrSignedGreaterEqualRR]		-> [^12].
		[BrLongEqualRR]				-> [^16].
		[BrLongNotEqualRR]				-> [^16].
		[MulRR]					-> [^4].
		[DivRR]					-> [^4].
		[MoveLowR]			-> [^4].
		[MoveHighR]			-> [^4].

		"Noops & Pseudo Ops"
		[Label]					-> [^0].
		[Literal]					-> [^4].
		[AlignmentNops]		-> [^(operands at: 0) - 4].
		[Fill32]					-> [^4].
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
		[AddCheckOverflowCqR]	-> [^28].
		[AddCheckOverflowRR]		-> [^20].
		[SubCheckOverflowCqR]	-> [^28].
		[SubCheckOverflowRR]		-> [^20].
		[MulCheckOverflowRR]		-> [^20].
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
		[MoveMbrR]				-> [^4].
		[MoveRMbr]				-> [^4].
		[MoveM16rR]			-> [^4].
		[MoveRM16r]			-> [^4].
		[MoveM64rRd]			-> [^self literalLoadInstructionBytes + 4].
		[MoveMwrR]			-> [^16].
		[MoveXbrRR]			-> [^8].
		[MoveRXbrR]			-> [^8].
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

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeAddCheckOverflowCqR [
	| destReg leftReg rightImm |
	rightImm := operands at: 0.
	destReg := leftReg := operands at: 1.

	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: rightImm)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: rightImm)).

	"Save original LHS"
	self machineCodeAt: 8 put: (self adduR: OverflowTemp1 R: leftReg R: ZR). 
	
	"The actual addition"
	self machineCodeAt: 12 put: (self adduR: destReg R: leftReg R: AT). 

	"Set sign bit of OverflowTemp2 if sign of result differs from sign of RHS."
	self machineCodeAt: 16 put: (self xorR: OverflowTemp2 R: destReg R: AT).
	"Set sign bit of OverflowTemp1 if sign of result differs from sign of LHS."
	self machineCodeAt: 20 put: (self xorR: OverflowTemp1 R: destReg R: OverflowTemp1).
	"Set sign bit of Overflow if sign of result differs from both LHS and RHS, which indicates overflow."
	self machineCodeAt: 24 put: (self andR: Overflow R: OverflowTemp1 R: OverflowTemp2).
	^machineCodeSize := 28
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeAddCheckOverflowRR [
	| destReg leftReg rightReg |
	rightReg := operands at: 0.
	destReg := leftReg := operands at: 1.

	"Save original LHS"
	self machineCodeAt: 0 put: (self adduR: OverflowTemp1 R: leftReg R: ZR). 
	
	"The actual addition"
	self machineCodeAt: 4 put: (self adduR: destReg R: leftReg R: rightReg). 

	"Set sign bit of OverflowTemp2 if sign of result differs from sign of RHS."
	self machineCodeAt: 8 put: (self xorR: OverflowTemp2 R: destReg R: rightReg).
	"Set sign bit of OverflowTemp1 if sign of result differs from sign of LHS."
	self machineCodeAt: 12 put: (self xorR: OverflowTemp1 R: destReg R: OverflowTemp1).
	"Set sign bit of Overflow if sign of result differs from both LHS and RHS, which indicates overflow."
	self machineCodeAt: 16 put: (self andR: Overflow R: OverflowTemp1 R: OverflowTemp2).
	^machineCodeSize := 20
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeAddCqR [
	| destReg leftReg rightImm |
	rightImm := operands at: 0.
	destReg := leftReg := operands at: 1.
	
	(rightImm between: -16r8000 and: 16r7FFF) ifFalse: [^self concretizeAddCwR].
	
	self machineCodeAt: 0 put: (self addiuR: destReg R: leftReg C: rightImm).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeAddCwR [
	| destReg leftReg rightImm |
	rightImm := operands at: 0.
	destReg := leftReg := operands at: 1.
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: rightImm)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: rightImm)).
	self machineCodeAt: 8 put: (self adduR: destReg R: leftReg R: AT).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeAddRR [
	| destReg leftReg rightReg |
	rightReg := operands at: 0.
	destReg := leftReg := operands at: 1.
	self machineCodeAt: 0 put: (self adduR: destReg R: leftReg R: rightReg).
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
	| destReg leftReg rightImm |
	rightImm := operands at: 0.
	destReg := leftReg := operands at: 1.
	
	(rightImm between: -16r8000 and: 16r7FFF) ifFalse: [^self concretizeAndCwR].
	
	self machineCodeAt: 0 put: (self andiR: destReg R: leftReg C: rightImm).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeAndCqRR [
	| value srcReg dstReg |
	value := operands at: 0.
	srcReg := operands at: 1.
	dstReg := operands at: 2.
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: value)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: value)).
	self machineCodeAt: 8 put: (self andR: dstReg R: srcReg R: AT).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeAndCwR [
	| destReg leftReg rightImm |
	rightImm := operands at: 0.
	destReg := leftReg := operands at: 1.
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: rightImm)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: rightImm)).
	self machineCodeAt: 8 put: (self andR: destReg R: leftReg R: AT).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeAndRR [
	| destReg leftReg rightReg |
	rightReg := operands at: 0.
	destReg := leftReg := operands at: 1.
	self machineCodeAt: 0 put: (self andR: destReg R: leftReg R: rightReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeArithmeticShiftRightCqR [
	| distance reg |
	distance := (operands at: 0) min: 31.
	reg := operands at: 1.
	self machineCodeAt: 0 put: (self sraR: reg R: reg C: distance).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeArithmeticShiftRightRR [
	| destReg distReg |
	distReg := operands at: 0.
	destReg := operands at: 1.
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
CogMIPSELCompiler >> concretizeBrEqualRR [
	| offset leftReg rightReg |
	offset := self computeJumpTargetOffsetPlus: 4.
	leftReg := operands at: 1.
	rightReg := operands at: 2.
	self machineCodeAt: 0 put: (self beqR: leftReg R: rightReg offset: offset).
	self machineCodeAt: 4 put: (self nop). "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeBrLongEqualRR [
	| jumpTargetInstruction jumpTargetAddr leftReg rightReg |
	<var: #jumpTargetInstruction type: #'AbstractInstruction *'>
	jumpTargetInstruction := self longJumpTargetAddress.
	self flag: #todo. "Check not crossing 256MB block."
	jumpTargetAddr := jumpTargetInstruction asUnsignedInteger bitAnd: 16rFFFFFFF.
	leftReg := operands at: 1.
	rightReg := operands at: 2.

	self machineCodeAt: 0 put: (self bneR: leftReg R: rightReg offset: 12).
	self machineCodeAt: 4 put: (self nop). "Delay slot"
	self machineCodeAt: 8 put: (self jA: jumpTargetAddr).
	self machineCodeAt: 12 put: self nop. "Delay slot"
	^machineCodeSize := 16
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeBrLongNotEqualRR [
	| jumpTargetInstruction jumpTargetAddr leftReg rightReg |
	<var: #jumpTargetInstruction type: #'AbstractInstruction *'>
	jumpTargetInstruction := self longJumpTargetAddress.
	self flag: #todo. "Check not crossing 256MB block."
	jumpTargetAddr := jumpTargetInstruction asUnsignedInteger bitAnd: 16rFFFFFFF.
	leftReg := operands at: 1.
	rightReg := operands at: 2.

	self machineCodeAt: 0 put: (self beqR: leftReg R: rightReg offset: 12).
	self machineCodeAt: 4 put: (self nop). "Delay slot"
	self machineCodeAt: 8 put: (self jA: jumpTargetAddr).
	self machineCodeAt: 12 put: self nop. "Delay slot"
	^machineCodeSize := 16
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeBrNotEqualRR [
	| offset leftReg rightReg |
	offset := self computeJumpTargetOffsetPlus: 4.
	leftReg := operands at: 1.
	rightReg := operands at: 2.
	self machineCodeAt: 0 put: (self bneR: leftReg R: rightReg offset: offset).
	self machineCodeAt: 4 put: (self nop). "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeBrSignedGreaterEqualRR [
	| offset leftReg rightReg |
	offset := self computeJumpTargetOffsetPlus: 8. "Relative to delay slot"
	leftReg := operands at: 1.
	rightReg := operands at: 2.
	self assert: leftReg ~= BranchTemp.
	self assert: rightReg ~= BranchTemp.
	self machineCodeAt: 0 put: (self sltR: BranchTemp R: leftReg R: rightReg).
	self machineCodeAt: 4 put: (self beqR: BranchTemp R: ZR offset: offset).
	self machineCodeAt: 8 put: (self nop). "Delay slot"
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeBrSignedGreaterRR [
	| offset leftReg rightReg |
	offset := self computeJumpTargetOffsetPlus: 8. "Relative to delay slot"
	leftReg := operands at: 1.
	rightReg := operands at: 2.
	self assert: leftReg ~= BranchTemp.
	self assert: rightReg ~= BranchTemp.
	self machineCodeAt: 0 put: (self sltR: BranchTemp R: rightReg R: leftReg).
	self machineCodeAt: 4 put: (self bneR: BranchTemp R: ZR offset: offset).
	self machineCodeAt: 8 put: (self nop). "Delay slot"
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeBrSignedLessEqualRR [
	| offset leftReg rightReg |
	offset := self computeJumpTargetOffsetPlus: 8. "Relative to delay slot"
	leftReg := operands at: 1.
	rightReg := operands at: 2.
	self assert: leftReg ~= BranchTemp.
	self assert: rightReg ~= BranchTemp.
	self machineCodeAt: 0 put: (self sltR: BranchTemp R: rightReg R: leftReg).
	self machineCodeAt: 4 put: (self beqR: BranchTemp R: ZR offset: offset).
	self machineCodeAt: 8 put: (self nop). "Delay slot"
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeBrSignedLessRR [
	| offset leftReg rightReg |
	offset := self computeJumpTargetOffsetPlus: 8. "Relative to delay slot"
	leftReg := operands at: 1.
	rightReg := operands at: 2.
	self assert: leftReg ~= BranchTemp.
	self assert: rightReg ~= BranchTemp.
	self machineCodeAt: 0 put: (self sltR: BranchTemp R: leftReg R: rightReg).
	self machineCodeAt: 4 put: (self bneR: BranchTemp R: ZR offset: offset).
	self machineCodeAt: 8 put: (self nop). "Delay slot"
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeBrUnsignedGreaterEqualRR [
	| offset leftReg rightReg |
	offset := self computeJumpTargetOffsetPlus: 8. "Relative to delay slot"
	leftReg := operands at: 1.
	rightReg := operands at: 2.
	self assert: leftReg ~= BranchTemp.
	self assert: rightReg ~= BranchTemp.
	self machineCodeAt: 0 put: (self sltuR: BranchTemp R: leftReg R: rightReg).
	self machineCodeAt: 4 put: (self beqR: BranchTemp R: ZR offset: offset).
	self machineCodeAt: 8 put: (self nop). "Delay slot"
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeBrUnsignedGreaterRR [
	| offset leftReg rightReg |
	offset := self computeJumpTargetOffsetPlus: 8. "Relative to delay slot"
	leftReg := operands at: 1.
	rightReg := operands at: 2.
	self assert: leftReg ~= BranchTemp.
	self assert: rightReg ~= BranchTemp.
	self machineCodeAt: 0 put: (self sltuR: BranchTemp R: rightReg R: leftReg).
	self machineCodeAt: 4 put: (self bneR: BranchTemp R: ZR offset: offset).
	self machineCodeAt: 8 put: (self nop). "Delay slot"
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeBrUnsignedLessEqualRR [
	| offset leftReg rightReg |
	offset := self computeJumpTargetOffsetPlus: 8. "Relative to delay slot"
	leftReg := operands at: 1.
	rightReg := operands at: 2.
	self assert: leftReg ~= BranchTemp.
	self assert: rightReg ~= BranchTemp.
	self machineCodeAt: 0 put: (self sltuR: BranchTemp R: rightReg R: leftReg).
	self machineCodeAt: 4 put: (self beqR: BranchTemp R: ZR offset: offset).
	self machineCodeAt: 8 put: (self nop). "Delay slot"
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeBrUnsignedLessRR [
	| offset leftReg rightReg |
	offset := self computeJumpTargetOffsetPlus: 8. "Relative to delay slot"
	leftReg := operands at: 1.
	rightReg := operands at: 2.
	self assert: leftReg ~= BranchTemp.
	self assert: rightReg ~= BranchTemp.
	self machineCodeAt: 0 put: (self sltuR: BranchTemp R: leftReg R: rightReg).
	self machineCodeAt: 4 put: (self bneR: BranchTemp R: ZR offset: offset).
	self machineCodeAt: 8 put: (self nop). "Delay slot"
	^machineCodeSize := 12
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
	| jumpTargetInstruction jumpTargetAddr |
	<var: #jumpTargetInstruction type: #'AbstractInstruction *'>
	jumpTargetInstruction := self longJumpTargetAddress.
	jumpTargetAddr := jumpTargetInstruction asUnsignedInteger.
	self machineCodeAt: 0 put: (self luiR: TargetReg C: (self high16BitsOf: jumpTargetAddr)).
	self machineCodeAt: 4 put: (self oriR: TargetReg R: TargetReg C: (self low16BitsOf: jumpTargetAddr)).
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
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeCmpRR [
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeDivRR [
	| dividendReg divisorReg |
	dividendReg := operands at: 0.
	divisorReg := operands at: 1.
	self machineCodeAt: 0 put: (self divR: dividendReg R: divisorReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeFill32 [
	"fill with operand 0 according to the processor's endianness.
	 You might think this is bogus and we should fill with stop instrurctions instead,
	 but this is used to leave room for a CMBlock header before the code for a block;
	 the gaps get filled in by fillInBlockHeadersAt: after code has been generated."
	self machineCodeAt: 0 put: (operands at: 0).
	^machineCodeSize := 4
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
	| jumpTargetInstruction jumpTargetAddr |
	<var: #jumpTargetInstruction type: #'AbstractInstruction *'>
	jumpTargetInstruction := self longJumpTargetAddress.
	jumpTargetAddr := jumpTargetInstruction asUnsignedInteger.
	self machineCodeAt: 0 put: (self luiR: TargetReg C: (self high16BitsOf: jumpTargetAddr)).
	self machineCodeAt: 4 put: (self oriR: TargetReg R: TargetReg C: (self low16BitsOf: jumpTargetAddr)).
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
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpLongZero [
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpNoOverflow [
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpNonZero [
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpOverflow [
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpR [
	| reg |
	self flag: #OABI. "Does this ever target C code? If so we should move the target into TargetReg first."
	reg := operands at: 0.
	self machineCodeAt: 0 put: (self jR: reg).
	self machineCodeAt: 4 put: self nop. "Delay slot"
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpSignedGreaterEqual [
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpSignedGreaterThan [
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpSignedLessEqual [
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpSignedLessThan [
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpUnsignedGreaterEqual [
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpUnsignedGreaterThan [
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpUnsignedLessEqual [
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpUnsignedLessThan [
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeJumpZero [
	self unreachable. "Should have been rewritten by noteFollowingConditionalBranch:"
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeLoadEffectiveAddressMwrR [
	<var: #offset type: #sqInt>
	| baseReg offset destReg |
	offset := operands at: 0.
	baseReg := operands at: 1.
	destReg := operands at: 2.
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
	reg := operands at: 1.
	self machineCodeAt: 0 put: (self sllR: reg R: reg C: distance).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeLogicalShiftLeftRR [
	| destReg distReg |
	distReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeAt: 0 put: (self sllvR: destReg R: destReg R: distReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeLogicalShiftRightCqR [
	| distance reg |
	distance := (operands at: 0) min: 31.
	reg := operands at: 1.
	self machineCodeAt: 0 put: (self srlR: reg R: reg C: distance).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeLogicalShiftRightRR [
	| destReg distReg |
	distReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeAt: 0 put: (self srlvR: destReg R: destReg R: distReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveAbR [
	| srcAddr destReg |
	srcAddr := operands at: 0.
	destReg := operands at: 1.

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
	destReg := operands at: 1.

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
	reg := operands at: 1.
	
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
	reg := operands at: 1.
	self machineCodeAt: 0 put: (self luiR: reg C: (self high16BitsOf: word)).
	self machineCodeAt: 4 put: (self oriR: reg R: reg C: (self low16BitsOf: word)).
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveHighR [
	| destReg |
	destReg := operands at: 0.
	self machineCodeAt: 0 put: (self mfhiR: destReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveLowR [
	| destReg |
	destReg := operands at: 0.
	self machineCodeAt: 0 put: (self mfloR: destReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveM16rR [
	<var: #offset type: #sqInt>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self machineCodeAt: 0 put: (self lhuR: destReg base: srcReg offset: offset).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveMbrR [
	<var: #offset type: #sqInt>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self machineCodeAt: 0 put: (self lbuR: destReg base: srcReg offset: offset).
	^machineCodeSize := 4
	
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveMwrR [
	<var: #offset type: #sqInt>
	| baseReg offset destReg |
	offset := operands at: 0.
	baseReg := operands at: 1.
	destReg := operands at: 2.
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
	srcReg := operands at: 0.
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
	srcReg := operands at: 0.
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
CogMIPSELCompiler >> concretizeMoveRM16r [
	<var: #offset type: #sqInt>
	| srcReg offset destReg |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	self machineCodeAt: 0 put: (self shR: srcReg base: destReg offset: offset).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveRMbr [
	<var: #offset type: #sqInt>
	| srcReg offset destReg |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	self machineCodeAt: 0 put: (self sbR: srcReg base: destReg offset: offset).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveRMwr [
	<var: #offset type: #sqInt>
	| srcReg offset baseReg |
	srcReg := operands at: 0.
	offset := operands at: 1.
	baseReg := operands at: 2.
	self machineCodeAt: 0 put: (self swR: srcReg base: baseReg offset: offset).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveRR [
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeAt: 0 put: (self adduR: destReg R: srcReg R: ZR).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveRXbrR [
	| srcReg indexReg baseReg |
	srcReg := operands at: 0.
	indexReg := operands at: 1.
	baseReg := operands at: 2.
	self machineCodeAt: 0 put: (self adduR: AT R: baseReg R: indexReg).
	self machineCodeAt: 4 put: (self sbR: srcReg base: AT offset: 0).
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveRXwrR [
	| srcReg indexReg baseReg |
	srcReg := operands at: 0.
	indexReg := operands at: 1.
	baseReg := operands at: 2.
	self machineCodeAt: 0 put: (self sllR: AT R: indexReg C: 2). "index is number of words"
	self machineCodeAt: 4 put: (self adduR: AT R: baseReg R: AT).
	self machineCodeAt: 8 put: (self swR: srcReg base: AT offset: 0).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveXbrRR [
	| indexReg baseReg destReg |
	indexReg := operands at: 0. "index is number of *bytes*"
	baseReg := operands at: 1.
	destReg := operands at: 2.
	self machineCodeAt: 0 put: (self adduR: AT R: baseReg R: indexReg).
	self machineCodeAt: 4 put: (self lbuR: destReg base: AT offset: 0).
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMoveXwrRR [
	| indexReg baseReg destReg |
	indexReg := operands at: 0.
	baseReg := operands at: 1.
	destReg := operands at: 2.
	self machineCodeAt: 0 put: (self sllR: AT R: indexReg C: 2). "index is in words"
	self machineCodeAt: 4 put: (self adduR: AT R: baseReg R: AT).
	self machineCodeAt: 8 put: (self lwR: destReg base: AT offset: 0).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeMulCheckOverflowRR [
	| destReg leftReg rightReg |
	rightReg := operands at: 0.
	destReg := leftReg := operands at: 1.

	"Overflow occured if the sign bit of the low part is different from the high part."
	self machineCodeAt: 0 put: (self multR: leftReg R: rightReg).
	self machineCodeAt: 4 put: (self mfloR: destReg).
	self machineCodeAt: 8 put: (self sraR: OverflowTemp1 R: destReg C: 31).
	self machineCodeAt: 12 put: (self mfhiR: OverflowTemp2).
	^machineCodeSize := 16
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeNegateR [
	| reg |
	reg := operands at: 0.
	self machineCodeAt: 0 put: (self subuR: reg R: ZR R: reg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeNop [
	self machineCodeAt: 0 put: self nop.
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeOrCqR [
	| destReg leftReg rightImm |
	rightImm := operands at: 0.
	destReg := leftReg := operands at: 1.

	(rightImm between: 0 and: 16rFFFF) ifFalse: [^self concretizeOrCwR].
	
	self machineCodeAt: 0 put: (self oriR: destReg R: leftReg C: rightImm).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeOrCwR [
	| destReg leftReg rightImm |
	rightImm := operands at: 0.
	destReg := leftReg := operands at: 1.
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: rightImm)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: rightImm)).
	self machineCodeAt: 8 put: (self orR: destReg R: leftReg R: AT).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeOrRR [
	| destReg leftReg rightReg |
	rightReg := operands at: 0.
	destReg := leftReg := operands at: 1.
	self machineCodeAt: 0 put: (self orR: destReg R: leftReg R: rightReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizePopR [
	| destReg |
	destReg := operands at: 0.
	self machineCodeAt: 0 put: (self lwR: destReg base: SP offset: 0).
	self machineCodeAt: 4 put: (self addiuR: SP R: SP C: 4).
	^machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizePrefetchAw [
	| addressOperand |
	addressOperand := operands at: 0.
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: addressOperand)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: addressOperand)).
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
	srcReg := operands at: 0.
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
	| destReg leftReg rightImm |
	rightImm := operands at: 0.
	destReg := leftReg := operands at: 1.

	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: rightImm)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: rightImm)).

	"Save original LHS"
	self machineCodeAt: 8 put: (self adduR: OverflowTemp1 R: leftReg R: ZR). 
	
	"The actual subtraction"
	self machineCodeAt: 12 put: (self subuR: destReg R: leftReg R: AT). 

	"Set sign bit of OverflowTemp2 if sign of result differs from sign of RHS."
	self machineCodeAt: 16 put: (self xorR: OverflowTemp2 R: destReg R: AT).
	"Set sign bit of OverflowTemp1 if sign of result differs from sign of LHS."
	self machineCodeAt: 20 put: (self xorR: OverflowTemp1 R: destReg R: OverflowTemp1).
	"Set sign bit of Overflow if sign of result differs from both LHS and RHS, which indicates overflow."
	self machineCodeAt: 24 put: (self andR: Overflow R: OverflowTemp1 R: OverflowTemp2).
	^machineCodeSize := 28
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeSubCheckOverflowRR [
	| destReg leftReg rightReg |
	rightReg := operands at: 0.
	destReg := leftReg := operands at: 1.

	"Save original LHS"
	self machineCodeAt: 0 put: (self adduR: OverflowTemp1 R: leftReg R: ZR). 
	
	"The actual subtraction"
	self machineCodeAt: 4 put: (self subuR: destReg R: leftReg R: rightReg). 

	"Set sign bit of OverflowTemp2 if sign of result differs from sign of RHS."
	self machineCodeAt: 8 put: (self xorR: OverflowTemp2 R: destReg R: rightReg).
	"Set sign bit of OverflowTemp1 if sign of result differs from sign of LHS."
	self machineCodeAt: 12 put: (self xorR: OverflowTemp1 R: destReg R: OverflowTemp1).
	"Set sign bit of Overflow if sign of result differs from both LHS and RHS, which indicates overflow."
	self machineCodeAt: 16 put: (self andR: Overflow R: OverflowTemp1 R: OverflowTemp2).
	^machineCodeSize := 20
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeSubCqR [
	| destReg leftReg rightImm |
	rightImm := operands at: 0.
	destReg := leftReg := operands at: 1.
	
	(rightImm negated between: -16r8000 and: 16r7FFF) ifFalse: [^self concretizeSubCwR].
	
	self machineCodeAt: 0 put: (self addiuR: destReg R: leftReg C: rightImm negated).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeSubCwR [
	| destReg leftReg rightImm |
	rightImm := operands at: 0.
	destReg := leftReg := operands at: 1.
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: rightImm)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: rightImm)).
	self machineCodeAt: 8 put: (self subuR: destReg R: leftReg R: AT).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeSubRR [
	| destReg leftReg rightReg |
	rightReg := operands at: 0.
	destReg := leftReg := operands at: 1.
	self machineCodeAt: 0 put: (self subuR: destReg R: leftReg R: rightReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeTstCqR [
	| leftReg rightImm |
	rightImm := operands at: 0.
	leftReg := operands at: 1.
	
	(rightImm between: -16r8000 and: 16r7FFF) ifFalse: [^self concretizeTstCwR].
	
	self machineCodeAt: 0 put: (self andiR: Cmp R: leftReg C: rightImm).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeTstCwR [
	| leftReg rightImm |
	rightImm := operands at: 0.
	leftReg := operands at: 1.
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: rightImm)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: rightImm)).
	self machineCodeAt: 8 put: (self andR: Cmp R: leftReg R: AT).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeUnimplemented [
	self error: 'Unimplemented RTL instruction'.
	^0
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeXorCwR [
	| destReg leftReg rightImm |
	rightImm := operands at: 0.
	destReg := leftReg := operands at: 1.
	self machineCodeAt: 0 put: (self luiR: AT C: (self high16BitsOf: rightImm)).
	self machineCodeAt: 4 put: (self oriR: AT R: AT C: (self low16BitsOf: rightImm)).
	self machineCodeAt: 8 put: (self xorR: destReg R: leftReg R: AT).
	^machineCodeSize := 12
]

{ #category : #'generate machine code - concretize' }
CogMIPSELCompiler >> concretizeXorRR [
	| destReg leftReg rightReg |
	rightReg := operands at: 0.
	destReg := leftReg := operands at: 1.
	self machineCodeAt: 0 put: (self xorR: destReg R: leftReg R: rightReg).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogMIPSELCompiler >> dispatchConcretize [
	"Attempt to generate concrete machine code for the instruction at address.
	 This is the inner dispatch of concretizeAt: actualAddress which exists only
	 to get around the branch size limits in the SqueakV3 (blue book derived)
	 bytecode set."
	<returnTypeC: #void>		 
	opcode caseOf: {
		[BrEqualRR]						-> [^self concretizeBrEqualRR].
		[BrNotEqualRR]					-> [^self concretizeBrNotEqualRR].
		[BrUnsignedLessRR]			-> [^self concretizeBrUnsignedLessRR].
		[BrUnsignedLessEqualRR]		-> [^self concretizeBrUnsignedLessEqualRR].
		[BrUnsignedGreaterRR]			-> [^self concretizeBrUnsignedGreaterRR].
		[BrUnsignedGreaterEqualRR]	-> [^self concretizeBrUnsignedGreaterEqualRR].
		[BrSignedLessRR]				-> [^self concretizeBrSignedLessRR].
		[BrSignedLessEqualRR]			-> [^self concretizeBrSignedLessEqualRR].
		[BrSignedGreaterRR]			-> [^self concretizeBrSignedGreaterRR].
		[BrSignedGreaterEqualRR]		-> [^self concretizeBrSignedGreaterEqualRR].	
		[BrLongEqualRR]				-> [^self concretizeBrLongEqualRR].
		[BrLongNotEqualRR]				-> [^self concretizeBrLongNotEqualRR].
		[MulRR]				-> [^self concretizeUnimplemented].
		[DivRR]				-> [^self concretizeDivRR].
		[MoveLowR]		-> [^self concretizeMoveLowR].
		[MoveHighR]		-> [^self concretizeMoveHighR].

										
		"Noops & Pseudo Ops"
		[Label]					-> [^self concretizeLabel].
		[AlignmentNops]		-> [^self concretizeAlignmentNops].
		[Fill32]					-> [^self concretizeFill32].
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
		[JumpOverflow]				-> [^self concretizeJumpOverflow].
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
		[XorCqR]					-> [^self concretizeUnimplemented].
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
		[XorRR]						-> [^self concretizeXorRR].
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
		[MoveRM16r]		-> [^self concretizeMoveRM16r].
		[MoveM64rRd]		-> [^self concretizeUnimplemented].
		[MoveMwrR]		-> [^self concretizeMoveMwrR].
		[MoveXbrRR]		-> [^self concretizeMoveXbrRR].
		[MoveRXbrR]		-> [^self concretizeMoveRXbrR].
		[MoveXwrRR]		-> [^self concretizeMoveXwrRR].
		[MoveRXwrR]		-> [^self concretizeMoveRXwrR].
		[MoveRMwr]		-> [^self concretizeMoveRMwr].
		[MoveRdM64r]		-> [^self concretizeUnimplemented].
		[PopR]				-> [^self concretizePopR].
		[PushR]				-> [^self concretizePushR].
		[PushCq]			-> [^self concretizePushCq].
		[PushCw]			-> [^self concretizePushCw].
		[PrefetchAw]		-> [^self concretizePrefetchAw].
		[AddCheckOverflowCqR] -> [^self concretizeAddCheckOverflowCqR].
		[AddCheckOverflowRR] -> [^self concretizeAddCheckOverflowRR].
		[SubCheckOverflowCqR] -> [^self concretizeSubCheckOverflowCqR].
		[SubCheckOverflowRR] -> [^self concretizeSubCheckOverflowRR].
		[MulCheckOverflowRR] -> [^self concretizeMulCheckOverflowRR].
		"Conversion"
		[ConvertRRd]		-> [^self concretizeUnimplemented]}
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> divR: dividendReg R: divisorReg [
	self flag: #todo. "Ascertain what ISA revision adds this instruction"
	^self rtype: SPECIAL rs: dividendReg rt: divisorReg rd: 0 sa: 0 funct: DIV
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> flushICacheFrom: startAddress "<Integer>" to: endAddress [ "<Integer>"
	<cmacro: '(me,startAddress,endAddress) cacheflush((char*) startAddress, endAddress - startAddress, ICACHE)'>
	"See http://www.linux-mips.org/wiki/Cacheflush_Syscall"
	self halt: #ceFlushICache
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

{ #category : #'abstract instructions' }
CogMIPSELCompiler >> genDivR: abstractRegDivisor R: abstractRegDividend Quo: abstractRegQuotient Rem: abstractRegRemainder [
	cogit gen: DivRR operand: abstractRegDividend operand: abstractRegDivisor.
	cogit gen: MoveLowR operand: abstractRegQuotient.
	cogit gen: MoveHighR operand: abstractRegRemainder.
	^0
]

{ #category : #'smalltalk calling convention' }
CogMIPSELCompiler >> genLoadCStackPointer [
	"Load the stack pointer register with that of the C stack, effecting
	 a switch to the C stack.  Used when machine code calls into the
	 CoInterpreter run-time (e.g. to invoke interpreter primitives)."
	cogit MoveAw: cogit cStackPointerAddress R: SPReg.
	^0
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
	self flag: #OABI.
	numArgs = 0 ifTrue: [^self].
	(cogit isTrampolineArgConstant: regOrConst0)
		ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst0) R: A0]
		ifFalse: [cogit MoveR: regOrConst0 R: A0].
	numArgs = 1 ifTrue: [^self].
	(cogit isTrampolineArgConstant: regOrConst1)
		ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst1) R: A1]
		ifFalse: [cogit MoveR: regOrConst1 R: A1].
	numArgs = 2 ifTrue: [^self].
	(cogit isTrampolineArgConstant: regOrConst2)
		ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst2) R: A2]
		ifFalse: [cogit MoveR: regOrConst2 R: A2].
	numArgs = 3 ifTrue: [^self].
	(cogit isTrampolineArgConstant: regOrConst3)
		ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst3) R: A3]
		ifFalse: [cogit MoveR: regOrConst3 R: A3]
]

{ #category : #'abstract instructions' }
CogMIPSELCompiler >> genMulR: regSource R: regDest [
	^cogit gen: MulRR operand: regSource operand: regDest
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
	<inline: true>
	self assert: n <= 4.
	^0
]

{ #category : #abi }
CogMIPSELCompiler >> genRestoreRegs: regMask [
	"Restore the registers in regMask as saved by genSaveRegs:.
	 We don't need to do anything because all of the abstract registers are
	 allocated to C preserved registers.  But for the future..."
	self assert: regMask = 0.
	self deny: (regMask anyMask: (cogit registerMaskFor: SP and: FP and: RA)).
	R0 to: R28 do:
		[:reg|
		 (regMask anyMask: (cogit registerMaskFor: reg)) ifTrue:
			[cogit PopR: reg]].
	^0
]

{ #category : #abi }
CogMIPSELCompiler >> genSaveRegs: regMask [
	"Save the registers in regMask for a call into the C run-time from a trampoline.
	 We don't need to do anything because all of the abstract registers are
	 allocated to C preserved registers.  But for the future..."
	self assert: regMask = 0.
	self deny: (regMask anyMask: (cogit registerMaskFor: SP and: FP and: RA)).
	R28 to: R0 by: -1 do:
		[:reg|
		 (regMask anyMask: (cogit registerMaskFor: reg)) ifTrue:
			[cogit PushR: reg]].
	^0
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

{ #category : #'abstract instructions' }
CogMIPSELCompiler >> genSubstituteReturnAddress: retpc [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^cogit MoveCw: retpc R: RA
]

{ #category : #accessing }
CogMIPSELCompiler >> getDefaultCogCodeSize [
	"Return the default number of bytes to allocate for native code at startup.
	 The actual value can be set via vmParameterAt: and/or a preference in the ini file."
	<inline: true>
	^1024 * 1536
]

{ #category : #testing }
CogMIPSELCompiler >> hasConditionRegister [
	"Answer if the receiver supports, e.g., JumpOverflow after a regular AddRR"
	^false
]

{ #category : #testing }
CogMIPSELCompiler >> hasDoublePrecisionFloatingPointSupport [
	<inline: true>
	self flag: #todo.
	^false
]

{ #category : #testing }
CogMIPSELCompiler >> hasLinkRegister [
	^true "RA"
]

{ #category : #testing }
CogMIPSELCompiler >> hasThreeAddressArithmetic [
	"Answer if the receiver supports three-address arithmetic instructions"
	^true
]

{ #category : #testing }
CogMIPSELCompiler >> hasVarBaseRegister [
	"Answer if the processor has a dedicated callee-saved register to point to
	 the base of commonly-accessed variables."
	^true "S6"
]

{ #category : #encoding }
CogMIPSELCompiler >> high16BitsOf: word [
	<var: #word type: #usqInt>
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

{ #category : #disassembly }
CogMIPSELCompiler >> instructionSizeAt: pc [
	"Answer the instruction size at pc."
	^4
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
	^false
]

{ #category : #testing }
CogMIPSELCompiler >> isCallPrecedingReturnPC: mcpc [
	"Assuming mcpc is a send return pc answer if the instruction before it is a call (not a CallFull)."
	"cogit disassembleFrom: mcpc - 8 to: mcpc."

	(self opcodeAtAddress: mcpc - 8) = JAL ifTrue: [^true].
	
	((self opcodeAtAddress: mcpc - 8) = SPECIAL
		and: [(self functionAtAddress: mcpc - 8) = JALR]) ifTrue: [^true].
	
	^false
]

{ #category : #testing }
CogMIPSELCompiler >> isJump [
	^super isJump or: [opcode between: BrEqualRR and: BrLongNotEqualRR]
]

{ #category : #testing }
CogMIPSELCompiler >> isJumpAt: pc [
	"cogit disassembleFrom: pc to: pc + 4."

	(self opcodeAtAddress: pc) = J ifTrue: [^true].
	
	(self opcodeAtAddress: pc) = SPECIAL ifTrue: 
		[(self functionAtAddress: pc) = JR ifTrue: [^true]].

	(self opcodeAtAddress: pc) = BEQ ifTrue: [^true].
	(self opcodeAtAddress: pc) = BNE ifTrue: [^true].
	(self opcodeAtAddress: pc) = BLEZ ifTrue: [^true].
	(self opcodeAtAddress: pc) = BGTZ ifTrue: [^true].

	(self opcodeAtAddress: pc) = REGIMM ifTrue: 
		[(self rtAtAddress: pc) = BLTZ ifTrue: [^true].
		 (self rtAtAddress: pc) = BGEZ ifTrue: [^true]].	
	
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
CogMIPSELCompiler >> itype: op rs: rs rt: rt eitherImmediate: immediate [	
	self assert: (op between: 0 and: 63).
	self assert: (rs between: 0 and: 31).
	self assert: (rt between: 0 and: 31).
	"signedImmediate < 0
		ifTrue: [unsignedImmediate := signedImmediate + 16r10000]
		ifFalse: [unsignedImmediate := signedImmediate].
	self assert: (unsignedImmediate between: 0 and: 16rFFFF)."
	^(((op << 26) bitOr: (rs << 21)) bitOr: (rt << 16)) bitOr: (immediate bitAnd: 16rFFFF)
]

{ #category : #encoding }
CogMIPSELCompiler >> itype: op rs: rs rt: rt signedImmediate: immediate [	
	self assert: (op between: 0 and: 63).
	self assert: (rs between: 0 and: 31).
	self assert: (rt between: 0 and: 31).
	self assert: (immediate between: -16r8000 and: 16r7FFF).
	"signedImmediate < 0
		ifTrue: [unsignedImmediate := signedImmediate + 16r10000]
		ifFalse: [unsignedImmediate := signedImmediate].
	self assert: (unsignedImmediate between: 0 and: 16rFFFF)."
	^(((op << 26) bitOr: (rs << 21)) bitOr: (rt << 16)) bitOr: (immediate bitAnd: 16rFFFF)
]

{ #category : #encoding }
CogMIPSELCompiler >> itype: op rs: rs rt: rt unsignedImmediate: immediate [	
	self assert: (op between: 0 and: 63).
	self assert: (rs between: 0 and: 31).
	self assert: (rt between: 0 and: 31).
	self assert: (immediate between: 0 and: 16rFFFF).
	^(((op << 26) bitOr: (rs << 21)) bitOr: (rt << 16)) bitOr: immediate
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
CogMIPSELCompiler >> jtype: op target: target [
	self assert: (op between: 0 and: 63).
	self assert: (target between: 0 and: 16r7FFFFFF).
	^(op << 26) bitOr: target
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

{ #category : #disassembly }
CogMIPSELCompiler >> jumpTargetPCAt: pc [
	<returnTypeC: #usqInt>
	"cogit disassembleFrom: pc to: pc + 4."
	
	(self opcodeAtAddress: pc) = J ifTrue: [^self targetFromJTypeAtAddress: pc].

	(self opcodeAtAddress: pc) = BEQ ifTrue: [^self targetFromITypeAtAddress: pc].
	(self opcodeAtAddress: pc) = BNE ifTrue: [^self targetFromITypeAtAddress: pc].
	(self opcodeAtAddress: pc) = BLEZ ifTrue: [^self targetFromITypeAtAddress: pc].
	(self opcodeAtAddress: pc) = BGTZ ifTrue: [^self targetFromITypeAtAddress: pc].
	(self opcodeAtAddress: pc) = REGIMM ifTrue:
		[(self rtAtAddress: pc) = BLTZ ifTrue: [^self targetFromITypeAtAddress: pc].
		 (self rtAtAddress: pc) = BGEZ ifTrue: [^self targetFromITypeAtAddress: pc]].
	
	self unreachable.
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
	<var: #high type: #usqInt>
	<var: #low type: #usqInt>
	| high low |
	self assert: (self opcodeAtAddress: mcpc) = ORI.
	self assert: (self opcodeAtAddress: mcpc - 4) = LUI.
	low := (objectMemory longAt: mcpc) bitAnd: 16rFFFF.
	high := (objectMemory longAt: mcpc - 4) bitAnd: 16rFFFF.
	^high << 16 bitOr: low

]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> literalAtAddress: mcpc put: newLiteral [
	<var: #oldUpper type: #usqInt>
	<var: #newUpper type: #usqInt>
	<var: #oldLower type: #usqInt>
	<var: #newLower type: #usqInt>
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
	 This is used in the MoveCwR, PushCw and CmpCwR cases."
	
	"Cmp/MoveCwR
	 pc-8	lui rx, uper
	 pc-4	ori rx, rx, lower"
	(self opcodeAtAddress: followingAddress - 4) = ORI ifTrue:
		[^self literalAtAddress: followingAddress - 4].
	
	"PushCw
	 pc-16	lui at, upper
	 pc-12	ori at, at, lower
	 pc-8	addiu sp, sp, -4
	 pc-4	sw at, 0(sp)"
	((self opcodeAtAddress: followingAddress - 4) = SW and:
		[(self opcodeAtAddress: followingAddress - 8) = ADDIU]) ifTrue:
			[^self literalAtAddress: followingAddress - 12].
	
	self unreachable.
	^0
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
	<var: #word type: #usqInt>
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
	 e.g. AddCheckOverflowCqR"
	^7
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> mfhiR: destReg [
	self flag: #todo. "Ascertain what ISA revision adds this instruction"
	^self rtype: SPECIAL rs: 0 rt: 0 rd: destReg sa: 0 funct: MFHI
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> mfloR: destReg [
	self flag: #todo. "Ascertain what ISA revision adds this instruction"
	^self rtype: SPECIAL rs: 0 rt: 0 rd: destReg sa: 0 funct: MFLO
]

{ #category : #'encoding - control' }
CogMIPSELCompiler >> mipsbreak: code [
	self assert: (code between: 0 and: 16rFFFFF).
	^(code << 6) bitOr: BREAK
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> multR: leftReg R: rightReg [
	self flag: #todo. "Ascertain what ISA revision adds this instruction"
	^self rtype: SPECIAL rs: leftReg rt: rightReg rd: 0 sa: 0 funct: MULT
]

{ #category : #printing }
CogMIPSELCompiler >> nameForRegister: reg [ "<Integer>"
	<doNotGenerate>
	^MIPSConstants nameForRegister: reg
]

{ #category : #'encoding - arithmetic' }
CogMIPSELCompiler >> nop [
	^0 "SLL ZR, ZR, 0"
]

{ #category : #'abstract instructions' }
CogMIPSELCompiler >> noteFollowingConditionalBranch: branch [
	"Support for processors without condition codes, such as the MIPS.
	 Answer the branch opcode.  Modify the receiver and the branch to
	 implement a suitable conditional branch that doesn't depend on
	 condition codes being set by the receiver."
	<returnTypeC: #'AbstractInstruction *'>
	<var: #branch type: #'AbstractInstruction *'>
	| newBranchLeft newBranchOpcode newBranchRight |
	
	((branch opcode = JumpOverflow) or: [branch opcode = JumpNoOverflow]) 
		ifTrue: [^self noteFollowingOverflowBranch: branch].

	newBranchOpcode := branch opcode caseOf: {
		[JumpZero] 			-> [BrEqualRR].
		[JumpNonZero]			-> [BrNotEqualRR].
		[JumpBelow]			-> [BrUnsignedLessRR].
		[JumpBelowOrEqual]	-> [BrUnsignedLessEqualRR].
		[JumpAbove]			-> [BrUnsignedGreaterRR].
		[JumpAboveOrEqual]	-> [BrUnsignedGreaterEqualRR].
		[JumpLess]				-> [BrSignedLessRR].
		[JumpLessOrEqual]		-> [BrSignedLessEqualRR].
		[JumpGreater]			-> [BrSignedGreaterRR].
		[JumpGreaterOrEqual]	-> [BrSignedGreaterEqualRR].
		[JumpLongZero] 		-> [BrLongEqualRR].
		[JumpLongNonZero]	-> [BrLongNotEqualRR].
		
		[JumpNegative]			-> [BrSignedLessRR].
	} otherwise: [self unreachable. 0].
	
	opcode caseOf: {
		[BrEqualRR]	->	["I.e., two jumps after a compare."
						newBranchLeft := operands at: 1.
						newBranchRight := operands at: 2].
		[BrUnsignedLessRR]	->	["I.e., two jumps after a compare."
						newBranchLeft := operands at: 1.
						newBranchRight := operands at: 2].

		[CmpRR] 	-> 	[newBranchLeft := operands at: 1.
						 newBranchRight := operands at: 0.
						 opcode := Label].
		[CmpCqR]	-> 	[newBranchLeft := operands at: 1.
						 newBranchRight := AT.
						 opcode := MoveCqR.
						 operands at: 1 put: AT].
		[CmpCwR]	-> 	[newBranchLeft := operands at: 1.
						 newBranchRight := AT.
						 opcode := MoveCwR.
						 operands at: 1 put: AT].
		[TstCqR]	->	[newBranchLeft := Cmp.
						 newBranchRight := ZR].
		[AndCqR]	->	[newBranchLeft := operands at: 1.
						 newBranchRight := ZR].
		[AndCqRR]	->	[newBranchLeft := operands at: 2.
						 newBranchRight := ZR].
		[OrRR]	->		[newBranchLeft := operands at: 1.
						 newBranchRight := ZR].
		[XorRR]	->		[newBranchLeft := operands at: 1.
						 newBranchRight := ZR].
		[SubCwR]	->	[newBranchLeft := operands at: 1.
						 newBranchRight := ZR].
		[SubCqR]	->	[newBranchLeft := operands at: 1.
						 newBranchRight := ZR].
		[ArithmeticShiftRightCqR]	->	[newBranchLeft := operands at: 1.
						 newBranchRight := ZR].
	} otherwise: [self unreachable].

	branch rewriteOpcode: newBranchOpcode with: newBranchLeft with: newBranchRight.
	^branch
]

{ #category : #'abstract instructions' }
CogMIPSELCompiler >> noteFollowingOverflowBranch: branch [
	"Support for processors without condition codes, such as the MIPS.
	 Answer the branch opcode.  Modify the receiver and the branch to
	 implement a suitable conditional branch that doesn't depend on
	 condition codes being set by the receiver."
	<var: #branch type: #'AbstractInstruction *'>
	| newBranchOpcode |
	
	(opcode = MulRR) ifTrue:
		[opcode := MulCheckOverflowRR.
		 newBranchOpcode := branch opcode caseOf: {
			[JumpOverflow]		-> [BrNotEqualRR].
			[JumpNoOverflow]	-> [BrEqualRR].
		 } otherwise: [self unreachable. 0].
		 branch rewriteOpcode: newBranchOpcode with: OverflowTemp1 with: OverflowTemp2.
		 ^branch].


	opcode := opcode caseOf: {
		[AddCqR]	-> [AddCheckOverflowCqR].
		[AddRR]		-> [AddCheckOverflowRR].
		[SubCqR]	-> [SubCheckOverflowCqR].
		[SubRR]		-> [SubCheckOverflowRR].
	} otherwise: [self unreachable. 0].

	newBranchOpcode := branch opcode caseOf: {
		[JumpOverflow]		-> [BrSignedLessRR].
		[JumpNoOverflow]	-> [BrSignedGreaterEqualRR].
	} otherwise: [self unreachable. 0].
	branch rewriteOpcode: newBranchOpcode with: Overflow with: ZR.
	^branch
]

{ #category : #abi }
CogMIPSELCompiler >> numIntRegArgs [
	self flag: #OABI.
	^4
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
CogMIPSELCompiler >> padIfPossibleWithStopsFrom: startAddr to: endAddr [
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
CogMIPSELCompiler >> relocateCallBeforeReturnPC: retpc by: delta [
	| target |
	self assert: delta \\ 4 = 0.
	delta = 0 ifTrue: [^self].
	
	self assert: (self opcodeAtAddress: retpc - 16) = LUI.
	self assert: (self opcodeAtAddress: retpc - 12) = ORI.
	self assert: (self opcodeAtAddress: retpc - 8) = SPECIAL.
	self assert: (self functionAtAddress: retpc - 8) = JALR.
	self assert: (objectMemory longAt: retpc - 4) = self nop.
	"cogit disassembleFrom: retpc - 16 to: retpc."

	target := self literalAtAddress: retpc - 12.
	target := target + delta.
	self literalAtAddress: retpc - 12 put: target.

	self assert: (self opcodeAtAddress: retpc - 16) = LUI.
	self assert: (self opcodeAtAddress: retpc - 12) = ORI.
	self assert: (self opcodeAtAddress: retpc - 8) = SPECIAL.
	self assert: (self functionAtAddress: retpc - 8) = JALR.
	self assert: (objectMemory longAt: retpc - 4) = self nop.
	"cogit disassembleFrom: retpc - 16 to: retpc."
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> relocateJumpLongBeforeFollowingAddress: pc by: delta [	
	"lui t9, stub/targetHigh
	 ori t9, t9, stub/targetLow
	 jr t9
	 nop (delay slot)
	 ...  <-- pc"

	| oldTarget newTarget |
	self assert: delta \\ 4 = 0.
	delta = 0 ifTrue: [^self].
	
	self assert: (self opcodeAtAddress: pc - 16) = LUI.
	self assert: (self opcodeAtAddress: pc - 12) = ORI.
	self assert: (self opcodeAtAddress: pc - 8) = SPECIAL.
	self assert: (self functionAtAddress: pc - 8) = JR.
	self assert: (objectMemory longAt: pc - 4) = self nop.
	"cogit disassembleFrom: pc - 16 to: pc."

	oldTarget := self literalAtAddress: pc - 12.
	newTarget := oldTarget + delta.
	self literalAtAddress: pc - 12 put: newTarget.

	self assert: (self opcodeAtAddress: pc - 16) = LUI.
	self assert: (self opcodeAtAddress: pc - 12) = ORI.
	self assert: (self opcodeAtAddress: pc - 8) = SPECIAL.
	self assert: (self functionAtAddress: pc - 8) = JR.
	self assert: (objectMemory longAt: pc - 4) = self nop.
	"cogit disassembleFrom: pc - 16 to: pc."
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> relocateJumpLongConditionalBeforeFollowingAddress: pc by: delta [	
	"lui t9, stub/targetHigh
	 ori t9, t9, stub/targetLow
	 jalr t9
	 nop (delay slot)
	 ...  <-- callSiteReturnAddress"

	self assert: (self opcodeAtAddress: pc - 16) = BNE.
	self assert: (objectMemory longAt: pc - 12) = self nop.
	self assert: (self opcodeAtAddress: pc - 8) = J.
	self assert: (objectMemory longAt: pc - 4) = self nop.
	"cogit disassembleFrom: pc - 16 to: pc."
	
	self rewriteJTypeAtAddress: pc - 8 delta: delta.

	self assert: (self opcodeAtAddress: pc - 16) = BNE.
	self assert: (objectMemory longAt: pc - 12) = self nop.
	self assert: (self opcodeAtAddress: pc - 8) = J.
	self assert: (objectMemory longAt: pc - 4) = self nop.
	"cogit disassembleFrom: pc - 16 to: pc."
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> relocateMethodReferenceBeforeAddress: pc by: delta [
	| oldValue newValue |
	"cogit disassembleFrom: pc - 16 to: pc + 16 a StackToRegisterMappingCogit."
	
	((self opcodeAtAddress: pc - 8) = ADDIU and: [(self opcodeAtAddress: pc - 4) = SW]) ifTrue:
		["PushCw"
		oldValue := self literalAtAddress: pc - 12.
		newValue := oldValue + delta.
		self literalAtAddress: pc - 12 put: newValue.	
		self assert: (self literalAtAddress: pc - 12) = newValue.
		^self].

	"MoveCwR"
	oldValue := self literalAtAddress: pc - 4.
	newValue := oldValue + delta.
	self literalAtAddress: pc - 4 put: newValue.
	
	"cogit disassembleFrom: pc - 8 to: pc."
	self assert: (self literalAtAddress: pc - 4) = newValue.
	
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> rewriteCPICJumpAt: addressFollowingJump target: jumpTargetAddr [
	"Rewrite a jump instruction to call a different target.  This variant is used to reset the 
	jumps in the prototype CPIC to suit each use,.   
	Answer the extent of the code change which is used to compute the range of the icache to flush."
	<var: #addressFollowingJump type: #usqInt>
	<var: #jumpTargetAddr type: #usqInt>
	
	"self CmpR: ClassReg R: TempReg.
	^self JumpNonZero: 0"
	
	"bne s5, s3, +156 ; =BE7C
	 nop (delay slot)
	 .... <-- addressFollowingJump"
	
	self assert: (self opcodeAtAddress: addressFollowingJump - 8) = BNE.
	self assert: (objectMemory longAt: addressFollowingJump - 4) = self nop.
	"cogit disassembleFrom: addressFollowingJump - 8 to: addressFollowingJump."
	
	self rewriteITypeBranchAtAddress: addressFollowingJump - 8 target: jumpTargetAddr.
	
	self assert: (self opcodeAtAddress: addressFollowingJump - 8) = BNE.
	self assert: (objectMemory longAt: addressFollowingJump - 4) = self nop.
	"cogit disassembleFrom: addressFollowingJump - 8 to: addressFollowingJump."
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
	"cogit disassembleFrom: callSiteReturnAddress - 16 to: callSiteReturnAddress."

	self literalAtAddress: callSiteReturnAddress - 12 put: callTargetAddress.

	self assert: (self opcodeAtAddress: callSiteReturnAddress - 16) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 12) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 8) = SPECIAL.
	self assert: (self functionAtAddress: callSiteReturnAddress - 8) = JALR.
	self assert: (objectMemory longAt: callSiteReturnAddress - 4) = self nop.
	"cogit disassembleFrom: callSiteReturnAddress - 16 to: callSiteReturnAddress."

	^20
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> rewriteConditionalJumpLongAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a jump instruction to call a different target.  This variant is used to reset the 
	jumps in the prototype CPIC to suit each use,.   
	Answer the extent of the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 8) = J.
	self assert: (objectMemory longAt: callSiteReturnAddress - 4) = self nop.
	"cogit disassembleFrom: callSiteReturnAddress - 8 to: callSiteReturnAddress."

	self rewriteJTypeAtAddress: callSiteReturnAddress - 8 target: callTargetAddress.

	self assert: (self opcodeAtAddress: callSiteReturnAddress - 8) = J.
	self assert: (objectMemory longAt: callSiteReturnAddress - 4) = self nop.
	"cogit disassembleFrom: callSiteReturnAddress - 8 to: callSiteReturnAddress."

]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> rewriteITypeBranchAtAddress: mcpc target: newTarget [
	| newDisplacement oldInstruction newInstruction |
	newDisplacement := newTarget - (mcpc + 4). "Displacement is relative to delay slot."
	newDisplacement := newDisplacement >>> 2. "Displacement is in words."
	newDisplacement := (newDisplacement bitAnd: 16rFFFF).

	oldInstruction := objectMemory longAt: mcpc.
	newInstruction := (oldInstruction bitAnd: 16rFFFF0000) bitOr: newDisplacement.
	
	objectMemory longAt: mcpc put: newInstruction.
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
	"cogit disassembleFrom: callSiteReturnAddress - 24 to: callSiteReturnAddress."

	self literalAtAddress: callSiteReturnAddress - 20 put: cacheTag.
	self literalAtAddress: callSiteReturnAddress - 12 put: callTargetAddress.

	self assert: (self opcodeAtAddress: callSiteReturnAddress - 24) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 20) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 16) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 12) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 8) = SPECIAL.
	self assert: (self functionAtAddress: callSiteReturnAddress - 8) = JALR.
	self assert: (objectMemory longAt: callSiteReturnAddress - 4) = self nop.
	"cogit disassembleFrom: callSiteReturnAddress - 24 to: callSiteReturnAddress."

	^24
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> rewriteInlineCacheTag: cacheTag at: callSiteReturnAddress [
	"Rewrite an inline cache with a new tag.  This variant is used
	 by the garbage collector."
	
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
	"cogit disassembleFrom: callSiteReturnAddress - 24 to: callSiteReturnAddress."

	self literalAtAddress: callSiteReturnAddress - 20 put: cacheTag.

	self assert: (self opcodeAtAddress: callSiteReturnAddress - 24) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 20) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 16) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 12) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 8) = SPECIAL.
	self assert: (self functionAtAddress: callSiteReturnAddress - 8) = JALR.
	self assert: (objectMemory longAt: callSiteReturnAddress - 4) = self nop.
	"cogit disassembleFrom: callSiteReturnAddress - 24 to: callSiteReturnAddress."
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> rewriteJTypeAtAddress: mcpc delta: delta [
	| oldTarget newTarget |
	oldTarget := self targetFromJTypeAtAddress: mcpc.
	newTarget := oldTarget + delta.
	self rewriteJTypeAtAddress: mcpc target: newTarget.
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> rewriteJTypeAtAddress: mcpc target: newTarget [
	| regionMask |
	self assert: (self opcodeAtAddress: mcpc) = J.
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
	"cogit disassembleFrom: callSiteReturnAddress - 16 to: callSiteReturnAddress."

	self literalAtAddress: callSiteReturnAddress - 12 put: callTargetAddress.

	self assert: (self opcodeAtAddress: callSiteReturnAddress - 16) = LUI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 12) = ORI.
	self assert: (self opcodeAtAddress: callSiteReturnAddress - 8) = SPECIAL.
	self assert: (self functionAtAddress: callSiteReturnAddress - 8) = JR.
	self assert: (objectMemory longAt: callSiteReturnAddress - 4) = self nop.
	"cogit disassembleFrom: callSiteReturnAddress - 16 to: callSiteReturnAddress."

	^20
]

{ #category : #'abstract instructions' }
CogMIPSELCompiler >> rewriteOpcode: anOpcode with: left with: right [
	<inline: true>
	opcode := anOpcode.
	operands
		"0 is target"
		at: 1 put: left;
		at: 2 put: right
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> rtAtAddress: mcpc [
	^(objectMemory longAt: mcpc) >> 16 bitAnd: 31

]

{ #category : #encoding }
CogMIPSELCompiler >> rtype: op rs: rs rt: rt rd: rd sa: sa funct: funct [
	self assert: (op between: 0 and: 63).
	self assert: (rs between: 0 and: 31).
	self assert: (rt between: 0 and: 31).
	self assert: (rd between: 0 and: 31).
	self assert: (sa between: 0 and: 31).
	self assert: (funct between: 0 and: 63).
	^(((((op << 26) bitOr: (rs << 21)) bitOr: (rt << 16)) bitOr: (rd << 11)) bitOr: (sa << 6)) bitOr: funct
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

{ #category : #testing }
CogMIPSELCompiler >> setsConditionCodesFor: aConditionalJumpOpcode [
	<inline: false>
	"Not really, but we can merge this in noteFollowingConditionalBranch:."
	opcode = XorRR ifTrue: [^true]. 
	opcode = ArithmeticShiftRightCqR ifTrue: [^true].
	self unreachable.
	^false
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
	^self mipsbreak: 0
]

{ #category : #'generate machine code' }
CogMIPSELCompiler >> stopsFrom: startAddr to: endAddr [
	self assert: endAddr - startAddr + 1 \\ 4 = 0.
	startAddr to: endAddr by: 4 do: 
		[:addr | objectMemory longAt: addr put: self stop].
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> storeLiteral: literal beforeFollowingAddress: followingAddress [
	"Rewrite the long constant loaded by a MoveCwR or PushCw before the given address"
	self flag: #bogus. "The caller ought to know what it is patching, and this should be split into separate methods with stricter checking. rmacnak 12/13/2015"
	
	"Cmp/MoveCwR
	 pc-8	lui rx, uper
	 pc-4	ori rx, rx, lower"
	(self opcodeAtAddress: followingAddress - 4) = ORI ifTrue:
		[^self literalAtAddress: followingAddress - 4 put: literal].

	"PushCw
	 pc-16	lui at, upper
	 pc-12	ori at, at, lower
	 pc-8	addiu sp, sp, -4
	 pc-4	sw at, 0(sp)"
	((self opcodeAtAddress: followingAddress - 4) = SW and:
		[(self opcodeAtAddress: followingAddress - 8) = ADDIU]) ifTrue:
			[^self literalAtAddress: followingAddress - 12 put: literal].
	
	self unreachable.
	^0
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
CogMIPSELCompiler >> targetFromITypeAtAddress: mcpc [
	<var: #offset type: #usqInt>
	<var: #mcpc type: #usqInt>
	<returnTypeC: #usqInt>
	| offset |
	offset := (objectMemory longAt: mcpc) bitAnd: 16rFFFF.
	self cCode: '' inSmalltalk: [offset >= 16r8000 ifTrue: [offset := offset - 16r10000]].
	offset := offset << 2.
	^mcpc + offset + OneInstruction. "Offset is relative to the delay slot"
]

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> targetFromJTypeAtAddress: mcpc [
	<var: #mcpc type: #usqInt>
	<returnTypeC: #usqInt>
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

{ #category : #'inline cacheing' }
CogMIPSELCompiler >> zoneCallsAreRelative [
	"Answer if Call and JumpLong are relative and hence need to take the caller's
	 relocation delta into account during code compaction, rather than just the
	 callee's delta."
	^false
]
