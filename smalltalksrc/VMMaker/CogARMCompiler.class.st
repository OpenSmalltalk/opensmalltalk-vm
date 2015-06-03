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
		'BICCqR',
		'BicOpcode',
		'CArg0Reg',
		'CArg1Reg',
		'CArg2Reg',
		'CArg3Reg',
		'CC',
		'CMPSMULL',
		'CPSRReg',
		'CS',
		'CmpOpcode',
		'ConcreteIPReg',
		'ConcreteVarBaseReg',
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
CogARMCompiler class >> VarBaseReg [
	"Answer the number of the reg we use to hold the base address of CoInterpreter variables"
	^ConcreteVarBaseReg
]

{ #category : #translation }
CogARMCompiler class >> filteredInstVarNames [
	"Edit such that conditionOrNil is amongst the char size vars opcode machineCodeSize and maxSize."
	^(super filteredInstVarNames copyWithout: 'conditionOrNil')
		copyReplaceFrom: 4 to: 3 with: #('conditionOrNil')
]

{ #category : #translation }
CogARMCompiler class >> identifyingPredefinedMacros [
	^#('__ARM_ARCH__' '__arm__' '__arm32__' 'ARM32')
]

{ #category : #'class initialization' }
CogARMCompiler class >> initialize [
	
	"Initialize various ARM instruction-related constants."
	"CogARMCompiler initialize"
	
	| specificOpcodes refs |
	super initialize.
	self ~~ CogARMCompiler ifTrue: [^self].
	
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
	
	CArg0Reg := 0.
	CArg1Reg := 1.
	CArg2Reg := 2.
	CArg3Reg := 3.

	ConcreteVarBaseReg := 10.
	ConcreteIPReg := 12. "IP, The Intra-Procedure-call scratch register."
	
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

	AddOpcode := 	4.
	AndOpcode := 0.
	BicOpcode := 14.
	CmpOpcode := 10.
	MoveOpcode := 13.
	MoveNotOpcode := 15.
	OrOpcode := 12.
	RsbOpcode := 3.
	SubOpcode := 2.
	XorOpcode := 1.
	SMLALOpcode := 7.

	CPSRReg := 16.
	OverflowFlag := 1 << 28.

	"Specific instructions"
	LastRTLCode isNil ifTrue:
		[CogRTLOpcodes initialize].
	specificOpcodes := #(SMULL MSR MRS LDMFD STMFD BICCqR CMPSMULL).
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
CogARMCompiler class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in an AbstractInstruction struct."
	"{CogAbstractInstruction. CogIA32Compiler. CogARMCompiler} do:
		[:c| Transcript print: c; cr. c printTypedefOn: Transcript]"
	(self filteredInstVarNames copyWithout: 'machineCode'), #('machineCode') do:
		[:ivn|
		ivn ~= 'bcpc' ifTrue:
			[aBinaryBlock
				value: ivn
				value: (ivn caseOf: {
							['address']			-> [#'unsigned long'].
							['machineCode']	-> [{#'unsigned long'. '[', self basicNew machineCodeWords printString, ']'}].
							['operands']		-> [{#'unsigned long'. '[', NumOperands, ']'}].
							['dependent']		-> ['struct _AbstractInstruction *']}
						otherwise:
							[#'unsigned char'])]]
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

{ #category : #private }
CogARMCompiler >> abstractRegisterForConcreteRegister: reg [
	(self concreteRegister: TempReg) = reg ifTrue: [^TempReg].
	(self concreteRegister: ReceiverResultReg) = reg ifTrue: [^ReceiverResultReg].
	(self concreteRegister: ClassReg) = reg ifTrue: [^ClassReg].
	(self concreteRegister: SendNumArgsReg) = reg ifTrue: [^SendNumArgsReg].
	(self concreteRegister: Arg0Reg) = reg ifTrue: [^Arg0Reg].
	(self concreteRegister: Arg1Reg) = reg ifTrue: [^Arg1Reg].
	(self concreteRegister: FPReg) = reg ifTrue: [^FPReg].
	(self concreteRegister: SPReg) = reg ifTrue: [^SPReg].
	(self concreteRegister: LinkReg) = reg ifTrue: [^LinkReg].
	(self concreteRegister: RISCTempReg) = reg ifTrue: [^RISCTempReg].
	(self concreteRegister: PCReg) = reg ifTrue: [^PCReg].
	(self concreteRegister: VarBaseReg) = reg ifTrue: [^VarBaseReg].
	self error: 'could not find abstract register'.
	^0

	"({	TempReg. ReceiverResultReg. ClassReg. SendNumArgsReg. Arg0Reg. Arg1Reg.
		FPReg. SPReg.
		LinkReg. RISCTempReg. PCReg. VarBaseReg} collect: [:i| self basicNew concreteRegister: i]) sort"

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

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> add: destReg rn: srcReg imm: immediate ror: rot [
"Remember the ROR is doubled by the cpu so use 30>>1 etc.
	ADD destReg, srcReg, #immediate ROR #rot"

	^self type: 1 op: AddOpcode set: 0 rn: srcReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate)
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> add: destReg rn: srcReg rm: addReg [
"return an ADD destReg, srcReg, addReg instruction
	ADD destReg, srcReg, addReg"

	^self type: 0 op: AddOpcode set: 0 rn: srcReg rd: destReg shifterOperand: addReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> adds: destReg rn: srcReg imm: immediate ror: rot [
"Remember the ROR is doubled by the cpu so use 30>>1 etc
	ADDS destReg, srcREg, #immediate ROR #rot"

	^self type: 1 op: AddOpcode set: 1 rn: srcReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate)
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> and: destReg rn: srcReg imm: immediate ror: rot [
"Remember the ROR is doubled by the cpu so use 30>>1 etc
	AND destReg, srcReg, #immediate ROR #rot"

	^self type: 1 op: AndOpcode set: 0 rn: srcReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate)
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> ands: destReg rn: srcReg imm: immediate ror: rot [
"Remember the ROR is doubled by the cpu so use 30>>1 etc
	ANDS destReg, srcReg, #immediate ROR #rot"

	^self type: 1 op: AndOpcode set: 1 rn: srcReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate)
]

{ #category : #'generate machine code - support' }
CogARMCompiler >> at: offset moveCw: constant intoR: destReg [
	"This loads aWord into the inter-opcode temporary register. Because most ARM instruction enable using a (8-12bit) offset relative to a register, the LS Byte can be included in that instruction, saving one instruction. This is done in a decorator, e.g. CmpCqR"
	"Generates:along the lines of
	MOV destReg, #<constantByte3>, 12
	ORR destReg, destReg, #<constantByte2>, 8
	ORR destReg, destReg, #<constantByte1>, 4
	ORR destReg, destReg, #<constantByte0>, 0
	with minimal choice of the rotation (last digit)"
	"The same area can be modified multiple times, because the opperation is (inclusive) or."
	 <var: 'constant' type: #usqInt>
	<inline: true>
	"self assert: destReg < 12."

	self machineCodeAt: offset put: (self mov: destReg imm: (constant >>24 bitAnd: 16rFF) ror: 8).
	self machineCodeAt: offset +4 put: (self orr: destReg imm: (constant >> 16 bitAnd: 16rFF) ror: 16).
	self machineCodeAt: offset +8 put: (self orr: destReg imm: (constant >> 8 bitAnd: 16rFF) ror: 24).
	self machineCodeAt: offset +12 put: (self orr: destReg imm: (constant bitAnd: 16rFF) ror: 0).
	^16
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> b: offset [
"return a B offset instruction; offset is signed 24bits of WORD offset, so +_32Mbyte range
	B offset"
	^self cond: AL br: 0 offset: offset

]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> bics: destReg rn: srcReg imm: immediate ror: rot [
"Remember the ROR is doubled by the cpu so use 30>>1 etc
	BICS destReg, srcReg, #immediate ROR #rot"

	^self type: 1 op: 14 set: 1 rn: srcReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate)
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> bl: offset [
"return a BL offset instruction; offset is signed 24bits of WORD offset, so +_32Mbyte range. Return address is in LR
	BL offset"
	^self cond: AL br: 1 offset: offset

]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> blx: targetReg [
	"Branch&link to the address in targetReg. Return address is in LR
	BX targetReg"
	<inline: true>
	^self cond: AL bx: 1 target: targetReg

]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> bx: targetReg [
	"Branch to address in targetReg. BX targetReg"
	<inline: true>
	^self cond: AL bx: 0 target: targetReg

]

{ #category : #abi }
CogARMCompiler >> cResultRegister [
	"Answer the abstract register for the C result register.
	 Only partially implemented.  Works on x86 since TempReg = EAX = C result reg."
	^R0
]

{ #category : #'inline cacheing' }
CogARMCompiler >> callFullTargetFromReturnAddress: callSiteReturnAddress [
	"Answer the address that the call immediately preceeding callSiteReturnAddress will jump to."
	"this is also used by #jumpLongTargetBeforeFollowingAddress: and so we check for both call and jump related instructions; later on we can use simpler tests once it feels safe to assume we get here always with a call/jump in the proper place"
	| call |
	call := self instructionBeforeAddress: callSiteReturnAddress.
	self assert: ((self instructionIsBX: call) or: [self instructionIsBLX: call]).
	"A Long Call/Jump. Extract the value saved to RISCTempReg from all the instructions before."
	^self extract32BitOperandFrom4InstructionsPreceeding: callSiteReturnAddress - 4
]

{ #category : #accessing }
CogARMCompiler >> callInstructionByteSize [
	"ARM calls and jumps span +/- 32 mb, more than enough for intra-zone calls and jumps."
	^4
]

{ #category : #'inline cacheing' }
CogARMCompiler >> callTargetFromReturnAddress: callSiteReturnAddress [
	"Answer the address that the call immediately preceeding callSiteReturnAddress will jump to."
	"this is also used by #jumpLongTargetBeforeFollowingAddress:."
	| callDistance call |
	call := self instructionBeforeAddress: callSiteReturnAddress.
	self assert: ((self instructionIsB: call) or: [self instructionIsBL: call]).
	callDistance := self extractOffsetFromBL: call.
	^callSiteReturnAddress + 4 + callDistance signedIntFromLong
]

{ #category : #accessing }
CogARMCompiler >> callerSavedRegisterMask [
	"According to IHI0042E ARM Architecture Procedure Calling Standard, in section 5.1.1:
		A subroutine must preserve the contents of the registers r4-r8, r10, r11 and SP (and r9 in PCS variants that designate r9 as v6).
	 SP = r13, so the callee-saved regs are r4-r8 & r10-r12.
	 The caller-saved registers are those that are not callee-saved and not reserved for hardware/abi uses,
	 i..e r0-r3, r9 & r12.  We can't name all the C argument registers.  So..."
	^cogit
		registerMaskFor: (self abstractRegisterForConcreteRegister: 0)
		"and: (self abstractRegisterForConcreteRegister: 1)"
		"and: (self abstractRegisterForConcreteRegister: 2)"
		"and: (self abstractRegisterForConcreteRegister: 3)"
		"and: (self abstractRegisterForConcreteRegister: 9)"
		and: (self abstractRegisterForConcreteRegister: 12)
]

{ #category : #testing }
CogARMCompiler >> canDivQuoRem [
	<inline: true>
	^false
]

{ #category : #testing }
CogARMCompiler >> canMulRR [
"we can do a MulRR be we can't simulate it correctly for some reason. More bug-fixing in the simulator one day"
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
	"Because we don't use Thumb, each ARM instruction has 4 bytes. Some abstract opcodes need more than one instruction. We only handle those in this caseOf: and let the default return 4"
	
	
	opcode
		caseOf: {
		"Noops & Pseudo Ops"
		[Label]					-> [^maxSize := 0].
		[AlignmentNops]		-> [^maxSize := (operands at: 0) - 4].
		[Fill16]					-> [^maxSize := 4].
		[Fill32]					-> [^maxSize := 4].
		[FillFromWord]			-> [^maxSize := 4].
		[Nop]					-> [^maxSize := 4].
		"ARM Specific Control/Data Movement"
		[BICCqR]				-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| maxSize := 4]
											ifFalse: [maxSize := 20]].
		[TstCqR]				-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| maxSize := 4]
											ifFalse: [maxSize := 20]].
		[SMULL]				-> [^maxSize := 4].
		[MSR]					-> [^maxSize := 4].
		[CMPSMULL]			-> [^maxSize := 4]. "special compare for genMulR:R: usage"
		"Control"
		[Call]					-> [^maxSize := 4].
		[CallFull]				-> [^maxSize := 20].
		[JumpR]					-> [^maxSize := 4].
		[Jump]					-> [^maxSize := 4].
		[JumpFull]				-> [^maxSize := 20].
		[JumpLong]				-> [^maxSize := 4].
		[JumpZero]				-> [^maxSize := 4].
		[JumpNonZero]			-> [^maxSize := 4].
		[JumpNegative]			-> [^maxSize := 4].
		[JumpNonNegative]		-> [^maxSize := 4].
		[JumpOverflow]			-> [^maxSize := 4].
		[JumpNoOverflow]		-> [^maxSize := 4].
		[JumpCarry]			-> [^maxSize := 4].
		[JumpNoCarry]			-> [^maxSize := 4].
		[JumpLess]				-> [^maxSize := 4].
		[JumpGreaterOrEqual]	-> [^maxSize := 4].
		[JumpGreater]			-> [^maxSize := 4].
		[JumpLessOrEqual]		-> [^maxSize := 4].
		[JumpBelow]			-> [^maxSize := 4].
		[JumpAboveOrEqual]	-> [^maxSize := 4].
		[JumpAbove]			-> [^maxSize := 4].
		[JumpBelowOrEqual]	-> [^maxSize := 4].
		[JumpLongZero]		-> [^maxSize := 4].
		[JumpLongNonZero]	-> [^maxSize := 4].
		[JumpFPEqual]			-> [^maxSize := 8].
		[JumpFPNotEqual]		-> [^maxSize := 8].
		[JumpFPLess]			-> [^maxSize := 8].
		[JumpFPGreaterOrEqual]-> [^maxSize := 8].
		[JumpFPGreater]		-> [^maxSize := 8].
		[JumpFPLessOrEqual]	-> [^maxSize := 8].
		[JumpFPOrdered]		-> [^maxSize := 8].
		[JumpFPUnordered]		-> [^maxSize := 8].
		[RetN]					-> [^(operands at: 0) = 0 
										ifTrue: [maxSize := 4]
										ifFalse: [maxSize := 8]].
		[Stop]					-> [^maxSize := 4].

		"Arithmetic"
		[AddCqR]				-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| maxSize := 4]
											ifFalse: [maxSize := 20]].
		[AndCqR]				-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| maxSize := 4]
											ifFalse: [maxSize := 20]].
		[AndCqRR]				-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| maxSize := 4]
											ifFalse: [maxSize := 20]].
		[CmpCqR]				-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| maxSize := 4]
											ifFalse: [maxSize := 20]].
		[OrCqR]					-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| maxSize := 4]
											ifFalse: [maxSize := 20]].
		[SubCqR]				-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| maxSize := 4]
											ifFalse: [maxSize := 20]].
		[XorCqR]				-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| maxSize := 4]
											ifFalse: [maxSize := 20]].
		[AddCwR]				-> [^maxSize := 20].
		[AndCwR]				-> [^maxSize := 20].
		[CmpCwR]				-> [^maxSize := 20].
		[OrCwR]				-> [^maxSize := 20].
		[SubCwR]				-> [^maxSize := 20].
		[XorCwR]				-> [^maxSize := 20].
		[AddRR]					-> [^maxSize := 4].
		[AndRR]					-> [^maxSize := 4].
		[CmpRR]				-> [^maxSize := 4].
		[OrRR]					-> [^maxSize := 4].
		[XorRR]					-> [^maxSize := 4].
		[SubRR]					-> [^maxSize := 4].
		[NegateR]				-> [^maxSize := 4].
		[LoadEffectiveAddressMwrR]
									-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| maxSize := 4]
											ifFalse: [maxSize := 20]].

		[LogicalShiftLeftCqR]		-> [^maxSize := 4].
		[LogicalShiftRightCqR]		->  [^maxSize := 4].
		[ArithmeticShiftRightCqR]	-> [^maxSize := 4].
		[LogicalShiftLeftRR]			->  [^maxSize := 4].
		[LogicalShiftRightRR]		->  [^maxSize := 4].
		[ArithmeticShiftRightRR]		-> [^maxSize := 4].
		[AddRdRd]			-> [^maxSize := 4].
		[CmpRdRd]			-> [^maxSize := 4].
		[SubRdRd]			-> [^maxSize := 4].
		[MulRdRd]			-> [^maxSize := 4].
		[DivRdRd]			-> [^maxSize := 4].
		[SqrtRd]			-> [^maxSize := 4].		
		"Data Movement"						
		[MoveCqR]				-> [^self rotateable8bitImmediate: (operands at: 0)
										ifTrue: [:r :i| maxSize := 4]
										ifFalse: [maxSize := 16]].
		[MoveCwR]				-> [^maxSize := 16].
		[MoveRR]				-> [^maxSize := 4].
		[MoveRdRd]		-> [^maxSize := 4].
		[MoveAwR]				-> [^maxSize := (self isAddressRelativeToVarBase: (operands at: 0))
													ifTrue: [4]
													ifFalse: [20]].
		[MoveRAw]				-> [^maxSize := (self isAddressRelativeToVarBase: (operands at: 1))
													ifTrue: [4]
													ifFalse: [20]].
		[MoveRMwr]			-> [self is12BitValue: (operands at: 1)
										ifTrue: [ :u :i | ^maxSize := 4]
										ifFalse: [ ^maxSize := 20 ]].
		[MoveRdM64r]	-> [^maxSize := 20]. 
		[MoveMbrR]				-> [self is12BitValue: (operands at: 0)
										ifTrue: [ :u :i | ^maxSize := 4]
										ifFalse: [ ^maxSize := 20 ]].
		[MoveRMbr]				-> [self is12BitValue: (operands at: 1)
										ifTrue: [ :u :i | ^maxSize := 4]
										ifFalse: [ ^maxSize := 20 ]].
		[MoveM16rR]			-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| maxSize := 4]
											ifFalse: [maxSize := 20]].
		[MoveM64rRd]	-> [^maxSize := 20].
		[MoveMwrR]			-> [self is12BitValue: (operands at: 0)
										ifTrue: [ :u :i | ^maxSize := 4]
										ifFalse: [ ^maxSize := 20 ]].
		[MoveXbrRR]			-> [^maxSize := 4].
		[MoveRXbrR]			-> [^maxSize := 4].
		[MoveXwrRR]			-> [^maxSize := 4].
		[MoveRXwrR]			-> [^maxSize := 4].
		[PopR]					-> [^maxSize := 4].
		[PushR]					-> [^maxSize := 4].
		[PushCw]				-> [^maxSize := 20].
		[PushCq]				-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| maxSize := 8]
											ifFalse: [maxSize := 20]].
		[PrefetchAw] 			-> [^maxSize := (self isAddressRelativeToVarBase: (operands at: 1))
													ifTrue: [4]
													ifFalse: [20]].
		"Conversion"
		[ConvertRRd]	-> [^maxSize := 4].


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

{ #category : #encoding }
CogARMCompiler >> concreteRegister: registerIndex [
	 "Map a possibly abstract register into a concrete one.  Abstract registers
	  (defined in CogAbstractOpcodes) are all negative.  If registerIndex is
	  negative assume it is an abstract register."
	
	"N.B. According to BSABI, R0-R3 are caller-save, R4-R12 are callee save.
	 Note that R9 might be a special register for the implementation. In some slides
	 it is refered to as sb. R10 can contain the stack limit (sl), R11 the fp. R12 is an
	 intra-procedure scratch instruction pointer for link purposes. It can also be used.
	 R10 is used as temporary inside a single abstract opcode implementation"
	"R0-R3 are used when calling back to the interpreter. Using them would require
	 saving and restoring their values, so they are omitted so far. R12 is the only
	 unused register at the moment.."
	^registerIndex
		caseOf: {
			[TempReg]				-> [R0].
			[ClassReg]				-> [R8].
			[ReceiverResultReg]	-> [R7].
			[SendNumArgsReg]		-> [R6].
			[SPReg]					-> [SP]. "R13"
			[FPReg]					-> [R11].
			[Arg0Reg]				-> [R4].
			[Arg1Reg]				-> [R5].
			[VarBaseReg]			-> [ConcreteVarBaseReg]. "Must be callee saved"
			[RISCTempReg]			-> [ConcreteIPReg]. "a.k.a. IP"
			[LinkReg]				-> [LR]. "R14"
			[PCReg]					-> [PC] "R15" }
		otherwise:
			[self assert: (registerIndex between: R0 and: PC).
			 registerIndex]
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeAddCqR [
	"Will get inlined into concretizeAt: switch."
	"Try whether the quick constant is a small negative number. If it is, optimize."
	<inline: true>
	self rotateable8bitImmediate: (operands at: 0)
		ifTrue: [ :rot :immediate | | reg |
			reg := self concreteRegister: (operands at: 1).
			self machineCodeAt: 0 put: (self adds: reg rn: reg imm: immediate ror: rot).
			^machineCodeSize := 4]
		ifFalse: [
			self rotateable8bitImmediate: (operands at: 0) negated
				ifTrue: [ :rot :immediate | |reg|
					reg := self concreteRegister: (operands at: 1).
					self machineCodeAt: 0 put: (self subs: reg rn: reg imm: immediate ror: rot).
					^machineCodeSize := 4]
				ifFalse: [^self concretizeDataOperationCwR: 4]].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeAddRdRd [
	self assert: false.
	self notYetImplemented

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
CogARMCompiler >> concretizeAndCqR [
	"Will get inlined into concretizeAt: switch."
	"AND is very important since it's used to mask all sorts of flags in the jit. We take special care to try to find fast ways to make the masks"
	<inline: true>
	|val|
	val := operands at: 0.
	self rotateable8bitImmediate: val
		ifTrue: [ :rot :immediate | | reg |
			reg := self concreteRegister: (operands at: 1).
			self machineCodeAt: 0 put: (self ands: reg rn: reg imm: immediate ror: rot).
			^machineCodeSize := 4]
		ifFalse: [
			"see if the constant bit-inverted makes a quick value and if so BIC it instead
			If the value is -ve, we 2s complement it instead"
			|invVal|
			val <0
				ifTrue:[invVal := -1 - val]
				ifFalse:[invVal := val bitInvert32].
			self rotateable8bitImmediate: invVal
				ifTrue: [ :rot :immediate | |reg|
					reg := self concreteRegister: (operands at: 1).
					self machineCodeAt: 0 put: (self bics: reg rn: reg imm: immediate ror: rot).
					^machineCodeSize := 4]
				ifFalse: ["let's try to see if the constant can be made from a simple shift of 0xFFFFFFFF"
					|hb reg|
					reg := self concreteRegister: (operands at: 1).
					hb := (operands at: 0) highBit.
					1 << hb = (val +1)
						ifTrue: [ "MVN temp reg, 0, making 0xffffffff"
							self machineCodeAt: 0 put:(self mvn: ConcreteIPReg imm: 0 ror: 0).
							"Then AND reg, temp reg, lsr #(32-hb)"
							 self machineCodeAt: 4 put:(self dataOpType: AndOpcode rd: reg rn: reg rm: ConcreteIPReg lsr: (32-hb )).
							^machineCodeSize :=8]
						ifFalse: [^self concretizeDataOperationCwR: AndOpcode]]].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeAndCqRR [
	"Will get inlined into concretizeAt: switch."
	"AND is very important since it's used to mask all sorts of flags in the jit. We take special care to try to find fast ways to make the masks"
	<inline: true>
	| val srcReg dstReg |
	val := operands at: 0.
	srcReg := self concreteRegister: (operands at: 1).
	dstReg := self concreteRegister: (operands at: 2).
	self rotateable8bitImmediate: val
		ifTrue:
			[ :rot :immediate |
			self machineCodeAt: 0 put: (self ands: dstReg rn: srcReg imm: immediate ror: rot).
			^machineCodeSize := 4]
		ifFalse:
			["see if the constant bit-inverted makes a quick value and if so BIC it instead
			If the value is -ve, we 2s complement it instead"
			|invVal|
			invVal := val < 0
						ifTrue:[-1 - val]
						ifFalse:[val bitInvert32].
			self rotateable8bitImmediate: invVal
				ifTrue:
					[ :rot :immediate |
					self machineCodeAt: 0 put: (self bics: dstReg rn: srcReg imm: immediate ror: rot).
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
							[^self concretizeDataOperationCwR: AndOpcode]]].
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
	reg := self concreteRegister: (operands at: 1).
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
	distReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
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
	address := actualAddress.
	self dispatchConcretize.
	self assert: (maxSize = nil or: [maxSize >= machineCodeSize]).
	^actualAddress + machineCodeSize
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeCMPSMULL [
	"Generate a CMP a, b, ASR #31 instruction, specifically for comparing the resutls of SMULLs in genMulR:R:"
	| hiReg loReg |
	hiReg := self concreteRegister: (operands at: 0).
	loReg := self concreteRegister: (operands at: 1).
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
	instrOffset := self at: 0 moveCw: jumpTarget intoR: ConcreteIPReg.
	"blx ConcreteIPReg"
	self machineCodeAt: instrOffset put: (self blx: ConcreteIPReg).
	self assert: instrOffset = 16.
	^machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeCmpRdRd [
	self assert: false.
	self notYetImplemented

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
	self assert: false.
	self notYetImplemented

]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeDataOperationCqR: armOpcode [
	"Will get inlined into concretizeAt: switch."
	"4 == Add, 2 == Sub, Xor == 1, And == 0, Or == 12, Bic == 14"
	<inline: true>
	|val rd rn |
	val := operands at: 0.
	rn := self concreteRegister: (operands at: 1).
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
	rn := (self concreteRegister: (operands at: 1)).
	rd := armOpcode = CmpOpcode ifTrue: [0] ifFalse:[rn].
	instrOffset := self at: 0 moveCw: constant intoR: ConcreteIPReg.
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
	srcReg := self concreteRegister: (operands at: 0).
	rn := (self concreteRegister: (operands at: 1)).
	rd := armOpcode = CmpOpcode ifTrue: [0] ifFalse: [rn].
	self machineCodeAt: 0 
		put: (self type: 0 op: armOpcode set: 1 rn: rn rd: rd shifterOperand: srcReg).
	^machineCodeSize := 4.
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeDivRdRd [
	self assert: false.
	self notYetImplemented

]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeFPConditionalJump: conditionCode [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset |
	self assert: (operands at: 0) ~= 0.
	offset := ((operands at: 0) - (address + 8)) signedIntFromLong "signed-conversion for range assertion".
	self assert: offset <= 33554428 & (offset >= -33554432).
	self machineCodeAt: 0 put: self fmstat. "FMSTAT: copy the FPSCR to CPSR"
	self machineCodeAt: 4 put: (self cond: conditionCode br: 0 offset: offset). "B offset"
	^machineCodeSize := 8
]

{ #category : #'generate machine code' }
CogARMCompiler >> concretizeFill16 [
	"fill with (operand 0 bitAnd: 16rFFFF) according to the processor's endianness"
	self halt: 'unused opcode?'
]

{ #category : #'generate machine code' }
CogARMCompiler >> concretizeFill32 [
	"fill with operand 0 according to the processor's endianness"
	| word |
	<var: #word type: #'unsigned long'>
	word := operands at: 0.
	self machineCodeAt: 0 put: word.
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeFillFromWord [
	self assert: false.
	self notYetImplemented

]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeJumpFull [
	"Will get inlined into concretizeAt: switch."
	"A JumpFull is used when we need to jump to anywhere in 32bit address space rather than somewhere known to be in code-space. It also must be relocatable and non-varying with the jump range. On ARM this means using the build-long-const + BX sequence."
	<inline: true>
	| jumpTarget instrOffset|
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := self longJumpTargetAddress.
	instrOffset := self at: 0 moveCw: jumpTarget intoR: ConcreteIPReg.
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
	reg := self concreteRegister: (operands at: 0).
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
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
	self rotateable8bitImmediate: offset
		ifTrue:
			[ :rot :immediate | 
			self machineCodeAt: 0 
				"add destReg, srcReg, #immediate ROR rot"
				put: (self add: destReg rn: srcReg imm: immediate ror: rot<<1).
			machineCodeSize := 4]
		ifFalse:
			[instrOffset := self at: 0 moveCw: offset intoR: ConcreteIPReg.
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
	reg := self concreteRegister: (operands at: 1).
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
	distReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
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
	reg := self concreteRegister: (operands at: 1).
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
	distReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
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
	flags := self concreteRegister: (operands at: 0).
	self machineCodeAt: 0 put: (self msr: flags).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveAwR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcAddr destReg instrOffset|
	srcAddr := operands at: 0.
	destReg := self concreteRegister: (operands at: 1).
	(self isAddressRelativeToVarBase: srcAddr) ifTrue:
		[self machineCodeAt: 0 put: (self ldr: destReg rn: ConcreteVarBaseReg plusImm: srcAddr - cogit varBaseAddress).
		 ^machineCodeSize := 4].
	"load the address into ConcreteIPReg"
	instrOffset := self at: 0 moveCw: srcAddr intoR: ConcreteIPReg.
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
	reg := self concreteRegister: (operands at: 1).
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
	^machineCodeSize := self loadCwInto: (self concreteRegister: (operands at: 1))
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
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
	self is8BitValue: offset
		ifTrue:
			[ :u :immediate | 
			self machineCodeAt: 0 "ldrh destReg, [srcReg, #immediate]"
				put: (self ldrh: destReg rn: srcReg plus: u imm: immediate).
			^machineCodeSize := 4]
		ifFalse:
			[instrOffset := self at: 0 moveCw: offset intoR: ConcreteIPReg.
			"ldrh destReg, [srcReg, ConcreteIPReg]"
			self machineCodeAt: instrOffset put: (self ldrh: destReg rn: srcReg rm: ConcreteIPReg).
			^machineCodeSize := instrOffset + 4 ].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveM64rRd [
	self assert: false.
	self notYetImplemented

]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveMbrR [
	"Will get inlined into concretizeAt: switch."
	"ldrb destReg, [srcReg, #immediate] or ldrb destReg, [srcReg, ConcreteIPReg]"
	<var: #offset type: #sqInt>
	<inline: true>
	| srcReg offset destReg instrOffset|
	offset := operands at: 0.
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
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
					[instrOffset := self at: 0 moveCw: offset intoR: ConcreteIPReg].
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
	srcReg := self concreteRegister: (operands at: 1).
	destReg := self concreteRegister: (operands at: 2).
	self is12BitValue: offset
		ifTrue:
			[ :u :immediate | 
			self machineCodeAt: 0 "ldr destReg, [srcReg, #immediate]"
				put: (self ldr: destReg rn: srcReg plus: u imm: immediate).
			^machineCodeSize := 4]
		ifFalse:
			[instrOffset := self at: 0 moveCw: offset intoR: ConcreteIPReg.
			"ldr destReg, [srcReg, ConcreteIPReg]"
			self machineCodeAt: instrOffset put: (self ldr: destReg rn: srcReg rm: ConcreteIPReg).
			^machineCodeSize := instrOffset + 4].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRAw [
	"Will get inlined into concretizeAt: switch."
	"LEA ConcreteIPReg
	str srcReg, [ConcreteIPReg]"
	<inline: true>
	| srcReg destAddr instrOffset|
	srcReg := self concreteRegister: (operands at: 0).
	destAddr := operands at: 1.
	(self isAddressRelativeToVarBase: destAddr) ifTrue:
		[self machineCodeAt: 0 put: (self str: srcReg rn: ConcreteVarBaseReg plusImm: destAddr - cogit varBaseAddress).
		 ^machineCodeSize := 4].
	"load the address into ConcreteIPReg"
	instrOffset := self at: 0 moveCw: destAddr intoR: ConcreteIPReg.
	"We *could* overwrite the last instruction above with a LDR a, b, last-byte-of-srcAddr BUT that would break if we change to loading literals instead of forming long constants"
	self machineCodeAt: instrOffset put: (self str: srcReg rn: ConcreteIPReg plusImm: 0).
	^machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRMbr [
	"Will get inlined into concretizeAt: switch."
	<var: #offset type: #sqInt>
	<inline: true>
	| srcReg offset baseReg instrOffset|
	srcReg := self concreteRegister: (operands at: 0).
	offset := operands at: 1.
	baseReg := self concreteRegister: (operands at: 2).
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
					[instrOffset := self at: 0 moveCw: offset intoR: ConcreteIPReg].
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
	srcReg := self concreteRegister: (operands at: 0).
	offset := operands at: 1.
	baseReg := self concreteRegister: (operands at: 2).
	self is12BitValue: offset
		ifTrue:
			[ :u :immediate | 
			self machineCodeAt: 0  "str 	srcReg, [baseReg, #immediate]"
				put: (self str: srcReg rn: baseReg plus: u imm: immediate).
			^machineCodeSize := 4]
		ifFalse:
			[instrOffset := self at: 0 moveCw: offset intoR: ConcreteIPReg.
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
	srcReg := self concreteRegister: (operands at: 0).
	destReg := self concreteRegister: (operands at: 1).
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
	src := self concreteRegister: (operands at: 0).
	index := self concreteRegister: (operands at: 1).
	base := self concreteRegister: (operands at: 2).
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
	src := self concreteRegister: (operands at: 0).
	index := self concreteRegister: (operands at: 1). "index is number of *words* = 4* bytes"
	base := self concreteRegister: (operands at: 2).
	"str		src, [base, +index, LSL #2]"
	"cond 011 1100 0 base srcR 00010 00 0 inde"
	self machineCodeAt: 0 put: (self memMxr: AL reg: src base: base p: 1 u: 1 b: 0 w: 0 l: 0 rmLsl2: index).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveRdM64r [
	self assert: false.
	self notYetImplemented
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMoveXbrRR [
	"Will get inlined into concretizeAt: switch."
	
	<inline: true>
	| index base dest |
	index := self concreteRegister: (operands at: 0). "index is number of *bytes*"
	base := self concreteRegister: (operands at: 1).
	dest := self concreteRegister: (operands at: 2).
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
	index := self concreteRegister: (operands at: 0).
	base := self concreteRegister: (operands at: 1).
	dest := self concreteRegister: (operands at: 2).
	"LDR	dest, [base, +index, LSL #2]"
	"cond 011 1100 1 base dest 00010 00 0 inde bulit by lowest level generator so we can do the lsl #2 on the index register"
	self machineCodeAt: 0 put: (self memMxr: AL reg: dest base: base p: 1 u: 1 b: 0 w: 0 l: 1 rmLsl2: index).
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeMulRdRd [
	self assert: false.
	self notYetImplemented

]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeNegateR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := self concreteRegister: (operands at: 0).
	"RSB destReg, srcReg, #0"
	self machineCodeAt: 0 put: (self type: 1 op: RsbOpcode set: 0 rn: reg rd: reg).
	^machineCodeSize := 4
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
	destReg := self concreteRegister: (operands at: 0).
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
	instrOffset := self at: 0 moveCw: addressOperand intoR: ConcreteIPReg.
	"pld	[ConcreteIPReg]"
	self machineCodeAt: instrOffset put: (self pld: ConcreteIPReg plus: 1offset: 0).
	^machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizePushCq [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| word instrOffset|
	word := operands at: 0.
	self 
		rotateable8bitImmediate: word 
		ifTrue: [:rot :immediate |
			self machineCodeAt: 0 put: (self mov: ConcreteIPReg imm: immediate ror: rot).
			instrOffset := 4]
		ifFalse:[|invVal|
			word <0
				ifTrue:[invVal := -1 - word]
				ifFalse:[invVal := word bitInvert32].
			self rotateable8bitImmediate: invVal
				ifTrue: [ :rot :immediate |
					self machineCodeAt: 0 put: (self mvn: ConcreteIPReg imm: immediate ror: rot).
					^machineCodeSize := 4]
				ifFalse: [instrOffset := self at: 0 moveCw: word intoR: ConcreteIPReg]].
	self machineCodeAt: instrOffset put: (self pushR: ConcreteIPReg).
	^machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizePushCw [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| instrOffset |
	instrOffset := self loadCwInto: ConcreteIPReg.
	self machineCodeAt: instrOffset put: (self pushR: ConcreteIPReg).
	^machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizePushR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg |
	srcReg := self concreteRegister: (operands at: 0).
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
	srcA := self concreteRegister: (operands at: 0).
	"NOTE: srcB contains the other mutiplicand at this point. It is OK to use it as the destination for the low part of the result and in fact this saves us moving it later"
	loResultReg := srcB := self concreteRegister: (operands at: 1).
	hiResultReg := self concreteRegister: RISCTempReg.
	self machineCodeAt: 0
		put: (self type: 0 op: 6 set: 0 rn: hiResultReg rd: loResultReg)
			+ (srcA << 8)
			+ (9 << 4)
			+ srcB.
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeSqrtRd [
	self assert: false.
	self notYetImplemented

]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeStop [
"generate a BKPT instruction. We could, given a good enough creative impulse and an over-active sense of humour, add some numerically encoded witticism to this instruction in bits 8-19 & 0-3. It has no effect on the execution but can be a way to specify which breakpoint has been hit etc."
	<inline: true>
	self machineCodeAt: 0 put: (AL <<28 bitOr: (16r42 <<20 bitOr:(7<<4))).
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
			reg := self concreteRegister: (operands at: 1).
			self machineCodeAt: 0 put: (self subs: reg rn: reg imm: immediate ror: rot).
			^machineCodeSize := 4]
		ifFalse: [
			"before building a full load of a big constant, see if we can do an add of the constant negated"
			self rotateable8bitImmediate: word negated
				ifTrue: [ :rot :immediate | | reg |
					reg := self concreteRegister: (operands at: 1).
					self machineCodeAt: 0 put: (self adds: reg rn: reg imm: immediate ror: rot).
					^machineCodeSize := 4]
				ifFalse: [^self concretizeDataOperationCwR: 2]].
	^0 "to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeSubRdRd [
	self assert: false.
	self notYetImplemented

]

{ #category : #'generate machine code - concretize' }
CogARMCompiler >> concretizeTstCqR [
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	self rotateable8bitImmediate: (operands at: 0)
		ifTrue: [ :rot :immediate | | reg |
			reg := self concreteRegister: (operands at: 1).
			self machineCodeAt: 0 put: (self tst: reg rn: reg imm: immediate ror: rot).
			^machineCodeSize := 4]
		ifFalse: [^self concretizeDataOperationCwR: 8].
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
		[AlignmentNops]		-> [^self concretizeAlignmentNops].
		[Fill16]					-> [^self concretizeFill16].
		[Fill32]					-> [^self concretizeFill32].
		[FillFromWord]			-> [^self concretizeFillFromWord].
		[Nop]					-> [^self concretizeNop].
		"ARM Specific Control/Data Movement" 
		[SMULL]				-> [^self concretizeSMULL]	.
		[CMPSMULL]				-> [^self concretizeCMPSMULL].
		[MSR]						-> [^self concretizeMSR].
		[BICCqR]					-> [^self concretizeDataOperationCqR: BicOpcode].
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
		[AddCqR]					-> [^self concretizeAddCqR].
		[AddCwR]					-> [^self concretizeDataOperationCwR: AddOpcode].
		[AddRR]						-> [^self concretizeDataOperationRR: AddOpcode].
		[AddRdRd]					-> [^self concretizeAddRdRd].
		[AndCqR]					-> [^self concretizeAndCqR].
		[AndCqRR]					-> [^self concretizeAndCqRR].
		[AndCwR]					-> [^self concretizeDataOperationCwR: AndOpcode].
		[AndRR]						-> [^self concretizeDataOperationRR: AndOpcode].
		[CmpCqR]					-> [^self concretizeDataOperationCqR: CmpOpcode].
		[CmpCwR]					-> [^self concretizeDataOperationCwR: CmpOpcode].
		[CmpRR]					-> [^self concretizeDataOperationRR: CmpOpcode].
		[CmpRdRd]					-> [^self concretizeCmpRdRd].
		[DivRdRd]					-> [^self concretizeDivRdRd].
		[MulRdRd]					-> [^self concretizeMulRdRd].
		[OrCqR]						-> [^self concretizeDataOperationCqR: OrOpcode].
		[OrCwR]					-> [^self concretizeDataOperationCwR: OrOpcode].
		[OrRR]						-> [^self concretizeDataOperationRR: OrOpcode].
		[SubCqR]					-> [^self concretizeSubCqR].
		[SubCwR]					-> [^self concretizeDataOperationCwR: SubOpcode].
		[SubRR]						-> [^self concretizeDataOperationRR: SubOpcode].
		[SubRdRd]					-> [^self concretizeSubRdRd].
		[SqrtRd]					-> [^self concretizeSqrtRd].
		[TstCqR]					-> [^self concretizeTstCqR].
		[XorCqR]						-> [^self concretizeDataOperationCqR: XorOpcode].
		[XorCwR]						-> [^self concretizeDataOperationCwR: XorOpcode].
		[XorRR]							-> [^self concretizeDataOperationRR: XorOpcode].
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
		[ConvertRRd]		-> [^self concretizeConvertRRd]}
]

{ #category : #testing }
CogARMCompiler >> extract32BitOperandFrom4InstructionsPreceeding: addr [
	<inline: true>
	^(objectMemory byteAt: addr -4) 
	 + ((objectMemory byteAt: addr - 8) << 8) 
	 + ((objectMemory byteAt: addr - 12) << 16) 
	 + ((objectMemory byteAt: addr - 16) << 24)
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

{ #category : #'inline cacheing' }
CogARMCompiler >> flushICacheFrom: startAddress "<Integer>" to: endAddress [ "<Integer>"
	<cmacro: '(me,startAddress,endAddress) __clear_cache((char*) startAddress, (char*) (endAddress + 4))'>
	"On ARM we almost certainly need to flush and wash hands. On linux we use __clear_cache (see http://community.arm.com/groups/processors/blog/2010/02/17/caches-and-self-modifying-code for a decent example) and remember that the end address is *exclusive* so we add 4 for now"
	self halt: #ceFlushICache
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> fmstat [
	"unconditional transfer FP status to cpsr to choose jumps etc. Manually fudged for now"
	<inline: true>
	^16rEF1FA10
]

{ #category : #abi }
CogARMCompiler >> fullCallsAreRelative [
	"Answer if CallFull and/or JumpFull are relative and hence need relocating on method
	 compation. If so, they are annotated with IsRelativeCall in methods and relocated in
	 relocateIfCallOrMethodReference:mcpc:delta:"
	^false
]

{ #category : #abi }
CogARMCompiler >> genAlignCStackSavingRegisters: saveRegs numArgs: numArgs wordAlignment: alignment [ 
"ARM doesn't push the first 4 arguments. Now, currently Cog doesn't use more than 4 args so we should never need to push any - but just in case we'll check for it"
	| wordsPushedModAlignment delta |
	wordsPushedModAlignment := ((saveRegs ifTrue: [self numberOfSaveableRegisters] ifFalse: [0])
									+ (numArgs > 4 ifTrue:[numArgs - 4] ifFalse:[0]))
									\\ alignment.
	wordsPushedModAlignment ~= 0 ifTrue:
		[delta := alignment - wordsPushedModAlignment.
		 cogit SubCq: delta * 4 R: SPReg].
	^0
]

{ #category : #'abstract instructions' }
CogARMCompiler >> genDivR: abstractRegDivisor R: abstractRegDividend Quo: abstractRegQuotient Rem: abstractRegRemainder [
"Currently no instruction level support for divide on ARM. See also #canDivQuoRem"
]

{ #category : #assertions }
CogARMCompiler >> genGetLeafCallStackPointerFunction [
"create a tiny leaf function that just returns the SP in r0 "
	cogit MoveR: SP R: R0.
	cogit RetN: 0
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

{ #category : #'abstract instructions' }
CogARMCompiler >> genMulR: regSource R: regDest [
	"Use SMULL to produce a 64-bit result, explicitly in RISCTempReg,regDest.
	 By comparing RISCTempReg with regDest ASR 31(which effectively makes it 0 or -1) we know that the result being EQ means the hi reg and the top bit of the lo reg are the same - ie no overflow. The condition code can then be forced to oVerflow by use of MSR APSR_nzcvq, #1, lsl 28"

	cogit
		gen: SMULL operand: regSource operand: regDest; "result in RISCTempReg,regDest"
		gen: CMPSMULL operand: RISCTempReg operand: regDest;
		gen: MSR operand: 1
]

{ #category : #abi }
CogARMCompiler >> genPassConst: constant asArgument: zeroRelativeArgIndex [
	zeroRelativeArgIndex caseOf: {
		[0] -> [cogit MoveCq: constant R: CArg0Reg].
		[1] -> [cogit MoveCq: constant R: CArg1Reg].
		[2] -> [cogit MoveCq: constant R: CArg2Reg].
		[3] -> [cogit MoveCq: constant R: CArg3Reg].}.
	^0
]

{ #category : #abi }
CogARMCompiler >> genPassReg: abstractRegister asArgument: zeroRelativeArgIndex [
	zeroRelativeArgIndex caseOf: {
		[0] -> [cogit MoveR: abstractRegister R: CArg0Reg].
		[1] -> [cogit MoveR: abstractRegister R: CArg1Reg].
		[2] -> [cogit MoveR: abstractRegister R: CArg2Reg].
		[3] -> [cogit MoveR: abstractRegister R: CArg3Reg].}.
	^0
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

{ #category : #abi }
CogARMCompiler >> genRemoveNArgsFromStack: n [
	"This is a no-op on ARM since the ABI passes up to 4 args in registers and trampolines currently observe that limit."
	self assert: n <= 4.
	^0
]

{ #category : #abi }
CogARMCompiler >> genRestoreRegs [
	"Restore the general purpose registers for a trampoline call."
	"Restore none, because the ARM ABI only defines callee saved registers, no caller-saved regs."
	"cogit gen: LDMFD operand: 16r7F"
]

{ #category : #abi }
CogARMCompiler >> genRestoreRegsExcept: abstractReg [
	"Restore the general purpose registers except for abstractReg for a trampoline call."
	"Restore none, because the ARM ABI only defines callee saved registers, no caller-saved regs."

]

{ #category : #abi }
CogARMCompiler >> genSaveRegisters [
	"Save the general purpose registers for a trampoline call."
	"Save none, because the ARM ABI only defines callee saved registers, no caller-saved regs."
	"cogit gen: STMFD operand: 16r7F"
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
			#r4. R4.
			#r5. R5.
			#r6. R6.
			#r7. R7.
			#r8. R8.
			#r10. R10.
			#r11. R11.
			#r12. R12	}
]

{ #category : #testing }
CogARMCompiler >> hasDoublePrecisionFloatingPointSupport [
	"might be true, but is for the forseeable future disabled"
	<inline: true>
	^false
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
	<inline: true>
	^true
]

{ #category : #testing }
CogARMCompiler >> hasVarBaseRegister [
	"Answer if the processor has a dedicated callee-saved register to point to
	 the base of commonly-accessed variables. On ARM we use R10 for this."
	<inline: true>
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
	self assert: (self instructionIsBL: (self instructionBeforeAddress: callSiteReturnAddress)).
	^self extract32BitOperandFrom4InstructionsPreceeding: callSiteReturnAddress - 4
]

{ #category : #testing }
CogARMCompiler >> insert32BitOperand: operand into4InstructionsPreceeding: addr [
	<inline: true>
	objectMemory
		byteAt: addr -   4 put: (operand			bitAnd: 16rFF);
		byteAt: addr -   8 put: (operand >>   8	bitAnd: 16rFF);
		byteAt: addr - 12 put: (operand >> 16	bitAnd: 16rFF);
		byteAt: addr - 16 put: (operand >> 24	bitAnd: 16rFF)
]

{ #category : #'inline cacheing' }
CogARMCompiler >> instructionBeforeAddress: followingAddress [
	"Answer the instruction immediately preceeding followingAddress."
	<inline: true>
	^objectMemory longAt: followingAddress -4
]

{ #category : #testing }
CogARMCompiler >> instructionIsB: instr [
"is this a B <offset> instruction?"
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [(instr bitAnd: (16rF<<24)) = (16rA<<24)]
]

{ #category : #testing }
CogARMCompiler >> instructionIsBL: instr [
"is this a BL <offset> instruction?"
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [(instr bitAnd: (16rF<<24)) = (16rB<<24)]
]

{ #category : #testing }
CogARMCompiler >> instructionIsBLX: instr [
"is this a BLX <targetReg> instruction?"
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [(instr bitAnd: 16r0FFFFFF0) = 16r12FFF30]
]

{ #category : #testing }
CogARMCompiler >> instructionIsBX: instr [
"is this a BX <targetReg> instruction?"
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension" and: [(instr bitAnd: 16r0FFFFFF0) = 16r12FFF10]
]

{ #category : #testing }
CogARMCompiler >> instructionIsOR: instr [
	"is this an ORR instruction?"
	^(instr >> 21 bitAnd: 16rF) = 16rC
]

{ #category : #testing }
CogARMCompiler >> instructionIsPush: instr [
	"is this a push -str r??, [sp, #-4] -  instruction?"
	^instr >> 28 < 16rF "test for allowed condcode - 0xF is extension"
	  and: [(instr bitAnd: 16rFFF0FFF) = 16r52D0004]
]

{ #category : #disassembly }
CogARMCompiler >> instructionSizeAt: pc [
	"Answer the instruction size at pc.Simple on ARM ;-)"
	^4
]

{ #category : #testing }
CogARMCompiler >> is12BitValue: constant ifTrue: trueAlternativeBlock	ifFalse: falseAlternativeBlock [
	"For LDR and STR, there is an instruction allowing for one instruction encoding if the offset is encodable in signed 12 bit form. pass the trueBlock the value and a 1-bit flag to tell it the sign.
	The falseBlock can do whatever it needs to, typically building the constant as a full 32bit value and then ld/st with that as a register offset"
	<inline: true>
	constant abs <= 4095 "(2 raisedTo: 12)-1"
		ifTrue:
			[constant >= 0 
				ifTrue: [trueAlternativeBlock value: 1 value: constant]
				ifFalse: [trueAlternativeBlock value: 0 value: constant abs]]
		ifFalse: falseAlternativeBlock
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
	<inline: true>
	^false
]

{ #category : #testing }
CogARMCompiler >> isCallPreceedingReturnPC: mcpc [
	"Assuming mcpc is a return pc answer if the instruction before it is a call."
	"There are two types of calls: BL and/BLX encoding"
	| call |
	call := self instructionBeforeAddress: mcpc.
	^(self instructionIsBL: call) or:[self instructionIsBLX: call]
]

{ #category : #testing }
CogARMCompiler >> isInImmediateJumpRange: operand [
	"ARM calls and jumps span +/- 32 mb, more than enough for intra-zone calls and jumps."
	<var: #operand type: #'unsigned long'>
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
CogARMCompiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction."
	^self isJump or: [opcode = AlignmentNops or: [opcode = Call]]
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
	"Answer the target address for the long jump immediately preceeding mcpc"
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
"	LDR destReg, [baseReg, immediate12bitValue] u=0 -> subtract imm; =1 -> add imm "
	^self memMxr: AL reg: destReg  base: baseReg u: u b: 0 l: 1 imm: immediate12bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> ldr: destReg rn: baseReg plusImm: immediate12bitValue [
"	LDR destReg, [baseReg, +immediate12bitValue]"
	^self memMxr: AL reg: destReg  base: baseReg u: 1 b: 0 l: 1 imm: immediate12bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> ldr: destReg rn: baseReg rm: offsetReg [
"	LDR destReg, [baseReg, + offsetReg]
	The contents of offsetReg are assumed to be correctly signed"
	^self memMxr: AL reg: destReg  base: baseReg p: 1 u: 1 b: 0 w: 0 l: 1 rm: offsetReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> ldrb: destReg rn: baseReg plus: u imm: immediate12bitValue [
"	LDRB destReg, [baseReg, 'u' immediate12bitValue] u=0 -> subtract imm; =1 -> add imm 
	Note that this is a very low level interface that does not check the sign of the immediate, nor validity. See for example #concretizeMoveMbrR"
	^self memMxr: AL reg: destReg  base: baseReg u: u b: 1 l: 1 imm: immediate12bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> ldrb: destReg rn: baseReg rm: offsetReg [
"	LDR destReg, [baseReg, + offsetReg] 
	The contents of offsetReg are assumed to be correctly signed"
	^self memMxr: AL reg: destReg  base: baseReg p: 1 u: 1 b: 1 w: 0 l: 1 rm: offsetReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> ldrh: destReg rn: baseReg plus: u imm: immediate8bitValue [
"	LDRH destReg, [baseReg, 'u' immediate8bitValue] u=0 -> subtract imm; =1 -> add imm "
	^self memM16xr: AL reg: destReg  base: baseReg p: 1 u: u  w: 0 l: 1 offset: immediate8bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> ldrh: destReg rn: baseReg rm: offsetReg [
"	LDRH destReg, [baseReg, +offsetReg]
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

{ #category : #'inline cacheing' }
CogARMCompiler >> literalBeforeFollowingAddress: followingAddress [
	"Answer the long constant loaded by a MOV/ORR/ORR/ORR
	 or MOV/ORR/ORR/ORR/PUSH, or MOV/ORR/ORR/ORR/CMP sequence, just before this address:"
	^(self instructionIsOR: (self instructionBeforeAddress: followingAddress))
		ifTrue: [self extract32BitOperandFrom4InstructionsPreceeding: followingAddress]
		ifFalse: [self extract32BitOperandFrom4InstructionsPreceeding: followingAddress - 4]
]

{ #category : #'generate machine code - support' }
CogARMCompiler >> loadCwInto: destReg [
	"Load the operand into the destination register, answering
	 the size of the instructions generated to do so."
	| operand distance |
	operand := operands at: 0.
	"First try and encode as a pc-relative reference..."
	(cogit addressIsInCurrentCompilation: operand) ifTrue:
		[distance := operand - (address + 8).
		 self rotateable8bitImmediate: distance
		 	ifTrue: [ :rot :immediate |
		 		self machineCodeAt: 0 put: (self add: destReg rn: PC imm: immediate ror: rot).
		 		^4]
		 	ifFalse:
		 		[self rotateable8bitImmediate: distance negated
		 			ifTrue: [ :rot :immediate |
		 				self machineCodeAt: 0 put: (self sub: destReg rn: PC imm: immediate ror: rot).
		 				^4]
					ifFalse: []]].
	"If this fails, use the conventional and painfully long 4 instruction sequence."
	^self at: 0 moveCw: operand intoR: destReg
]

{ #category : #accessing }
CogARMCompiler >> loadLiteralByteSize [
	"Answer the byte size of a MoveCwR opcode's corresponding machine code"
	^16
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

{ #category : #'abstract instructions' }
CogARMCompiler >> maybeEstablishVarBase [
	"The receiver has a VarBaseReg; generate the code to set it to its value."
	cogit MoveCq: cogit varBaseAddress R: VarBaseReg
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
	MOV destReg, #immediate8BitValue ROR rot"
	^self type: 1 op: MoveOpcode set: 0 rn: 0 rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate8bitValue)
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> mov: destReg rn: srcReg [
"	MOV destReg, srcReg"

	^self type: 0 op: MoveOpcode set: 0 rn: 0 rd: destReg shifterOperand: srcReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> movs: destReg rn: srcReg [
"	MOVS destReg, srcReg"

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
	MVN destReg, #immediate8BitValue ROR rot"
	^self type: 1 op: MoveNotOpcode set: 0 rn: 0 rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate8bitValue)
]

{ #category : #printing }
CogARMCompiler >> nameForRegister: reg [ "<Integer>"
	
	<doNotGenerate>
	^#(LR SP PC CArg0Reg CArg0Reg CArg1Reg CArg2Reg CArg3Reg) detect: [:sym| (self class classPool at: sym) = reg] 
		ifNone: [super nameForRegister: reg]
]

{ #category : #'generate machine code - support' }
CogARMCompiler >> nopsFrom: startAddr to: endAddr [
"fill with MOV R0, R0 no-op instructions"
	self assert: endAddr - startAddr + 1 \\ 4 = 0.
	startAddr to: endAddr by: 4 do:
		[:p| objectMemory 
			byteAt: p put: 16r0;
			byteAt: p+1 put: 16r0;
			byteAt: p+2 put: 16rA0;
			byteAt: p+3 put: 16rE1]
]

{ #category : #'inline cacheing' }
CogARMCompiler >> numICacheFlushOpcodes [
	"ARM needs to do icache flushing when code is written"
	"for now return 0 to skip it and probably blow up"
	^0
	
]

{ #category : #abi }
CogARMCompiler >> numberOfSaveableRegisters [
	"Answer the number of registers to be saved in a trampoline call that saves registers.
	 None, See genSaveRegisters."
	<cmacro: '(self) 0'>
	^0
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> orr: destReg imm: immediate8bitValue ror: rot [
	"Remember the ROR is doubled by the cpu so use 30>>1 etc.
	ORR destReg, #immediate8BitValue ROR rot"
	^self type: 1 op: OrOpcode set: 0 rn: destReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate8bitValue)
]

{ #category : #'inline cacheing' }
CogARMCompiler >> outputMachineCodeAt: targetAddress [
	"Override to move machine code a word at a time."
	<inline: true>
	0 to: machineCodeSize - 1 by: 4 do:
		[:j|
		objectMemory longAt: targetAddress + j put: (machineCode at: j // 4)]
]

{ #category : #'generate machine code' }
CogARMCompiler >> padIfPossibleWithNopsFrom: startAddr to: endAddr [
	| nullBytes |
	nullBytes := (endAddr - startAddr + 1) \\ 4.
	self nopsFrom: startAddr to: endAddr - nullBytes.
	endAddr - nullBytes + 1 to: endAddr 
		do: [ :p | objectMemory byteAt: p put: 16r0]
]

{ #category : #encoding }
CogARMCompiler >> pld: baseReg plus: u offset: immediate [
	"hint to memory that we will want to read from baseReg +/- imediate sometime soon"
	<inline: true>
	^ 2r11110101010100001111000000000000 bitOr: (baseReg<<16 bitOr:(u <<23 bitOr: immediate))
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> popR: dstReg [
"	pop word off TOS
	LDR srcReg, [sp] #4"
	^self memMxr: AL reg: dstReg base: SP p: 0 u: 1 b: 0 w: 0 l: 1 imm: 4
]

{ #category : #accessing }
CogARMCompiler >> pushLinkRegisterByteSize [
	^4
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> pushR: srcReg [
"	push word to TOS 
	STR srcReg, [sp, #-4]!"
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
		 objectMemory longAt: retpc - 4 put: ((instr bitAnd: 16rFF000000) bitOr: (distanceDiv4 bitAnd: 16rFFFFFF))]
]

{ #category : #'inline cacheing' }
CogARMCompiler >> relocateMethodReferenceBeforeAddress: pc by: delta [
	"If possible we generate the method address using pc-relative addressing.
	 If so we don't need to relocate it in code.  So check if pc-relative code was
	 generated, and if not, adjust a long sequence.  There are two cases, a push
	 or a register load.  If a push, then there is a register load, but in the instruction
	 before."
	| pcPreceedingLoad reference |
	pcPreceedingLoad := (self instructionIsPush: (self instructionBeforeAddress: pc))
							ifTrue: [pc - 4]
							ifFalse: [pc].
	"If the load is not done via pc-relative addressing we have to relocate."
	(self isPCRelativeValueLoad: (self instructionBeforeAddress: pcPreceedingLoad)) ifFalse:
		[reference := self extract32BitOperandFrom4InstructionsPreceeding: pcPreceedingLoad.
		 reference := reference + delta.
		 self insert32BitOperand: reference into4InstructionsPreceeding: pcPreceedingLoad]
]

{ #category : #'inline cacheing' }
CogARMCompiler >> rewriteCallAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a call instruction to call a different target.  This variant is used to link PICs
	 in ceSendMiss et al, and to rewrite cached primitive calls.   Answer the extent of
	 the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	| callDistance call |
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 10 to: callSiteReturnAddress - 1]."
	false
		ifTrue: [self assert: callTargetAddress >= cogit minCallAddress]
		ifFalse: [callTargetAddress >= cogit minCallAddress ifFalse:
					[self error: 'linking callsite to invalid address']].
	callDistance := (callTargetAddress - (callSiteReturnAddress + 8 "pc offset"- 4 "return offset")) signedIntToLong.
	self assert: (self isInImmediateJumpRange: callDistance). "we don't support long call updates, yet"
	call := self bl: callDistance.
	objectMemory longAt:  callSiteReturnAddress - 4 put: call.

	self assert: (self callTargetFromReturnAddress: callSiteReturnAddress) signedIntToLong = callTargetAddress.
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 10 to: callSiteReturnAddress - 1]."
	^4
]

{ #category : #'inline cacheing' }
CogARMCompiler >> rewriteCallFullAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a callFull instruction to jump to a different target.  This variant
	 is used to rewrite cached primitive calls.   Answer the extent of the
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
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	"cogit disassembleFrom: callSiteReturnAddress - 20 to: callSiteReturnAddress - 1"
	self assert: (self instructionBeforeAddress: callSiteReturnAddress) = expectedInstruction.
	self insert32BitOperand: callTargetAddress into4InstructionsPreceeding: callSiteReturnAddress - 4.
	self assert: (self callFullTargetFromReturnAddress: callSiteReturnAddress) signedIntToLong = callTargetAddress.
	^20
]

{ #category : #'inline cacheing' }
CogARMCompiler >> rewriteInlineCacheAt: callSiteReturnAddress tag: cacheTag target: callTargetAddress [
	"Rewrite an inline cache to call a different target for a new tag.  This variant is used
	 to link unlinked sends in ceSend:to:numArgs: et al.  Answer the extent of the code
	 change which is used to compute the range of the icache to flush."
	
	"chacheTag contains an oop to the selector which need be loaded before jumping"
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	| call callDistance |
	false
		ifTrue: [self assert: callTargetAddress >= cogit minCallAddress]
		ifFalse: [callTargetAddress >= cogit minCallAddress ifFalse:
					[self error: 'linking callsite to invalid address']].
	callDistance := (callTargetAddress - (callSiteReturnAddress + 8 "pc offset"- 4 "return offset")) signedIntToLong.
	self assert: (self isInImmediateJumpRange: callDistance). "we don't support long call updates here"
	call := self bl: callDistance.
	objectMemory longAt: callSiteReturnAddress - 4 put: call.
	self insert32BitOperand: cacheTag into4InstructionsPreceeding: callSiteReturnAddress - 4.
	self assert: (self callTargetFromReturnAddress: callSiteReturnAddress) signedIntToLong = callTargetAddress.
	self assert: (self extract32BitOperandFrom4InstructionsPreceeding: callSiteReturnAddress - 4) = cacheTag.
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 20 to: callSiteReturnAddress - 1]."
	^20
]

{ #category : #'inline cacheing' }
CogARMCompiler >> rewriteInlineCacheTag: cacheTag at: callSiteReturnAddress [
	"Rewrite an inline cache with a new tag.  This variant is used
	 by the garbage collector."
	self insert32BitOperand: cacheTag into4InstructionsPreceeding: callSiteReturnAddress -4
]

{ #category : #'inline cacheing' }
CogARMCompiler >> rewriteJumpFullAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a full jump instruction to jump to a different target.  This variant
	 is used to rewrite cached primitive calls.   Answer the extent of the
	 code change which is used to compute the range of the icache to flush."
	<inline: true>
	^self
		rewriteFullTransferAt: callSiteReturnAddress
		target: callTargetAddress
		expectedInstruction: 16rE12FFF1C
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
		}
		otherwise: [self halt: 'unhandled opcode in setsConditionCodesFor:'. false]
]

{ #category : #'generate machine code' }
CogARMCompiler >> sizePCDependentInstructionAt: eventualAbsoluteAddress [
	"Size a jump and set its address.  The target may be another instruction
	 or an absolute address.  On entry the address inst var holds our virtual
	 address. On exit address is set to eventualAbsoluteAddress, which is
	 where this instruction will be output.  The span of a jump to a following
	 instruction is therefore between that instruction's address and this
	 instruction's address ((which are both still their virtual addresses), but the
	 span of a jump to a preceeding instruction or to an absolute address is
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

{ #category : #accessing }
CogARMCompiler >> stackPageInterruptHeadroomBytes [
	"Return a minimum amount of headroom for each stack page (in bytes).  In a
	 JIT the stack has to have room for interrupt handlers which will run on the stack.
	According to ARM architecture v5 reference manual chapter A2.6, the basic interrupt procedure does not push anything onto the stack. It uses SPSR_err and R14_err to preserve state. Afterwards, it calls an interrupt procedure. So leave some room."
	^128 "32 words"
]

{ #category : #'inline cacheing' }
CogARMCompiler >> storeLiteral: literal beforeFollowingAddress: followingAddress [
	"Rewrite the long constant loaded by a MOV/ORR/ORR/ORR
	 or MOV/ORR/ORR/ORR/PUSH  sequence, just before this address:"
	^(self instructionIsOR: (self instructionBeforeAddress: followingAddress))
		ifTrue: [self insert32BitOperand: literal into4InstructionsPreceeding: followingAddress]
		ifFalse: [self insert32BitOperand: literal into4InstructionsPreceeding: followingAddress - 4]
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> str: destReg rn: baseReg plus: u imm: immediate12bitValue [
"	STR destReg, [baseReg, 'u' immediate12bitValue] u=0 -> subtract imm; =1 -> add imm "
	^self memMxr: AL reg: destReg  base: baseReg u: u b: 0 l: 0 imm: immediate12bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> str: srcReg rn: baseReg plusImm: immediate12bitValue [
"	STR srcReg, [baseReg, +immediate12bitValue]"
	^self memMxr: AL reg: srcReg  base: baseReg u: 1 b: 0 l: 0 imm: immediate12bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> str: srcReg rn: baseReg rm: offsetReg [
"	STR srcReg, [baseReg, + offsetReg] 
The contents of offsetReg are assumed to be correctly signed"
	^self memMxr: AL reg: srcReg  base: baseReg p: 1 u: 1 b: 0 w: 0 l: 0 rm: offsetReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> strb: destReg rn: baseReg plus: u imm: immediate12bitValue [
"	STRB destReg, [baseReg, 'u' immediate12bitValue] u=0 -> subtract imm; =1 -> add imm "
	^self memMxr: AL reg: destReg  base: baseReg u: u b: 1 l: 0 imm: immediate12bitValue
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> strb: srcReg rn: baseReg rm: offsetReg [
"	STRB srcReg, [baseReg, + offsetReg] 
	The contents of offsetReg are assumed to be correctly signed"
	^self memMxr: AL reg: srcReg  base: baseReg p: 1 u: 1 b: 1 w: 0 l: 0 rm: offsetReg
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> sub: destReg rn: srcReg imm: immediate ror: rot [
"	Remember the ROR is doubled by the cpu so use 30>>1 etc
	SUB destReg, srcReg, #immediate ROR rot"

	^self type: 1 op: SubOpcode set: 0 rn: srcReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate)
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> subs: destReg rn: srcReg imm: immediate ror: rot [
"	Remember the ROR is doubled by the cpu so use 30>>1 etc
	SUBS destReg, srcReg, #immediate ROR rot"

	^self type: 1 op: SubOpcode set: 1 rn: srcReg rd: destReg shifterOperand: ((rot>>1) <<8 bitOr: immediate)
]

{ #category : #'ARM convenience instructions' }
CogARMCompiler >> tst: ignored rn: srcReg imm: immediate ror: rot [
"	Remember the ROR is doubled by the cpu so use 30>>1 etc"
"also note that TST has no destReg
	TST srcReg, #immediate ROR rot"

	^self type: 1 op: 8 set: 1 rn: srcReg rd: 0 shifterOperand: ((rot>>1) <<8 bitOr: immediate)
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
