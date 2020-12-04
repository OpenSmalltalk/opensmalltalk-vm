Class {
	#name : #CogARMv8Compiler,
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
		'CMPMULOverflow',
		'CMPSMULL',
		'CPSRReg',
		'CS',
		'CmpNotOpcode',
		'CmpOpcode',
		'ConcreteIPReg',
		'ConcreteIPReg2',
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
		'MSUB',
		'MUL',
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
		'R16',
		'R17',
		'R19',
		'R2',
		'R20',
		'R21',
		'R22',
		'R23',
		'R24',
		'R25',
		'R3',
		'R4',
		'R5',
		'R6',
		'R7',
		'R8',
		'R9',
		'RsbOpcode',
		'SDIV',
		'SMLALOpcode',
		'SMULH',
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
CogARMv8Compiler class >> IPReg [
	"Answer the number of the general temp reg in the ARM APCS convention, IP"
	^ConcreteIPReg
]

{ #category : #translation }
CogARMv8Compiler class >> ISA [
	"Answer the name of the ISA the receiver implements."
	^#aarch64
]

{ #category : #accessing }
CogARMv8Compiler class >> PCReg [
	^ConcretePCReg
]

{ #category : #accessing }
CogARMv8Compiler class >> VarBaseReg [
	"Answer the number of the reg we use to hold the base address of CoInterpreter variables"
	^ConcreteVarBaseReg
]

{ #category : #translation }
CogARMv8Compiler class >> defaultCompilerClass [
	^CogOutOfLineLiteralsARMv8Compiler
]

{ #category : #translation }
CogARMv8Compiler class >> filteredInstVarNames [
	"Edit such that conditionOrNil is amongst the char size vars opcode machineCodeSize and maxSize."
	^(super filteredInstVarNames copyWithout: 'conditionOrNil')
		copyReplaceFrom: 5 to: 4 with: #('conditionOrNil')
]

{ #category : #translation }
CogARMv8Compiler class >> identifyingPredefinedMacros [

	^#('__aarch64__' '_M_ARM64')
]

{ #category : #'class initialization' }
CogARMv8Compiler class >> initialize [

	"Initialize various ARM instruction-related constants."
	"CogARMCompiler initialize"

	super initialize.
	self ~~ CogARMv8Compiler ifTrue: [^self].

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
	
	R16 := 16.
	R17 := 17.

	R19 := 19.
	R20 := 20.
	R21 := 21.
	R22 := 22.
	R23 := 23.
	R24 := 24.
	R25 := 25.

	SP := 31.
	LR := 30.
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

	ConcreteVarBaseReg := R24.
	"X16 and X17 are the Intra procedural scratch registers"
	ConcreteIPReg := R16.
	ConcreteIPReg2 := R17.

	"C3.1.1 Conditional branch
	Conditional branches change the flow of execution depending on the current state of the Condition flags or the value in a general-purpose register."
	
	"C1.2.4 Condition code
	The A64 ISA has some instructions that set Condition flags or test Condition codes or both.
	"
	EQ := 0. "Equal"
	NE := 1. "Not equal"
	CS := 2. "Carry set"
	CC := 3. "Carry clear"
	MI := 4. "Minus, negative"
	PL := 5. "Plus, positive or zero"
	VS := 6. "Overflow"
	VC := 7. "No overflow"
	HI := 8. "Unsigned higher"
	LS := 9. "Unsigned lower or same"
	GE := 10. "Signed greater than or equal"
	LT := 11. "Signed less than"
	GT := 12. "Signed greater than"
	LE := 13. "Signed less than or equal"
	AL := 14. "Always"

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
		initializeSpecificOpcodes: #(MUL SMULH CMPMULOverflow SMULL MSR MRS LDMFD STMFD CMPSMULL SDIV MSUB)
		in: thisContext method
]

{ #category : #'class initialization' }
CogARMv8Compiler class >> initializeAbstractRegisters [
	"Assign the abstract registers with the identities/indices of the relevant concrete registers."

	super initializeAbstractRegisters.

	"According to IHI0042E ARM Architecture Procedure Calling Standard, in section 5.1.1:
		A subroutine must preserve the contents of the registers r4-r8, r10, r11 and SP (and r9 in PCS variants that designate r9 as v6).
	 SP = r13, so the callee-saved regs are r4-r8 & r10-r12.
	 The caller-saved registers are those that are not callee-saved and not reserved for hardware/abi uses,
	
	 
	Caller saved Registers:
	X0 - X7 are to pass arguments.
	X8 is indirect return address.
	X9 - X15 general purpose.
	
	X16 - X17 - Intra procedure scratch register.
	
	Callee saved registers:
	X18 is caller saved but platform specific (user programs should not use it).	
	X19 - X29 are callee saved.
	
	X30 is LR.
	X31 is SP.
	
	 We exclude registers 0 & 1 (TempReg/CArg0Reg & CArg1Reg) from the CallerSavedRegisterMask because we only
	 use them for argument passing and so never want to save and restore them.  In fact restoring TempReg/CArg0Reg
	 would overwrite function results, so it shouldn't be included under any circumstances."

	CallerSavedRegisterMask := self registerMaskFor: 3 and: 4.

	TempReg			:= R1.
	ClassReg			:= R22.
	ReceiverResultReg	:= R23.
	SendNumArgsReg	:= R25.
	SPReg				:= 28. "X28 is used to manage the Smalltalk stack".
	FPReg				:= 29. "X29"
	Arg0Reg			:= R3. "overlaps with last C arg reg"
	Arg1Reg			:= R4.
	Extra0Reg			:= R19. "These are callee saved registers"
	Extra1Reg			:= R20.
	Extra2Reg			:= R21.
	VarBaseReg		:= R24.	"Must be callee saved" self assert: ConcreteVarBaseReg = R24.
	RISCTempReg		:= R16.	"a.k.a. IP" self assert: ConcreteIPReg = R16.
	LinkReg				:= LR. "X30"
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
CogARMv8Compiler class >> isAbstract [
	^self == CogARMv8Compiler
]

{ #category : #testing }
CogARMv8Compiler class >> isRISCTempRegister: reg [
	"For tests to filter-out bogus values left in the RISCTempRegister, if any."
	^reg = ConcreteIPReg
]

{ #category : #translation }
CogARMv8Compiler class >> machineCodeDeclaration [
	"Answer the declaration for the machineCode array.
	 ARM instructions are 32-bits in length."
	^{#'unsigned int'. '[', self basicNew machineCodeWords printString, ']'}
]

{ #category : #accessing }
CogARMv8Compiler class >> orOpcode [
	^OrOpcode
]

{ #category : #'class initialization' }
CogARMv8Compiler class >> specificOpcodes [
	"Answer the processor-specific opcodes for this class.
	 They're all in an Array literal in the initialize method."
	^(self class >> #initialize) literals detect: [:l| l isArray and: [l includes: #LDMFD]]
]

{ #category : #translation }
CogARMv8Compiler class >> wordSize [
	"This is a 64-bit ISA"
	^8
]

{ #category : #'ARM convenience instructions' }
CogARMv8Compiler >> add: destReg rn: srcReg imm: immediate ror: rot [

	self assert: rot = 0.
	^ self
		addSize: 1
		sourceRegister: srcReg
		shift: 0
		immediate12: immediate
		destinationRegister: destReg
]

{ #category : #assembler }
CogARMv8Compiler >> addSize: is64Bits sourceRegister: sourceRegister shift: shift immediate12: immediate12bitValue destinationRegister: destinationRegister [
	
	"C6.2.4 ADD (immediate)
	
	Add (immediate) adds a register value and an optionally-shifted immediate value, and writes the result to the destination register.
	
	ADD <Xd|SP>, <Xn|SP>, #<imm>{, <shift>}
	
	if shift = 1 the immediate will be shifted by 12
	"
	
	^ is64Bits << 31
		bitOr: (2r00100010 << 23
		bitOr: ((shift bitAnd: 2r1) << 22
		bitOr: (immediate12bitValue << 10
		bitOr: ((sourceRegister bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111)))))
]

{ #category : #assembler }
CogARMv8Compiler >> addsExtendedSize: is64Bits leftRegisterMaybeSP: leftRegister shiftedRightRegister: rightRegister option: option shiftOffset: immediate3bitValue destinationRegister: destinationRegister [
	
	"C6.2.7 ADDS (extended register)
	
	Add (extended register), setting flags, adds a register value and a sign or zero-extended register value, followed by an optional left shift amount, and writes the result to the destination register. The argument that is extended from the <Rm> register can be a byte, halfword, word, or doubleword. It updates the condition flags based on the result.
	
	ADDS <Xd>, <Xn|SP>, <R><m>{, <extend> {#<amount>}}"
	
	^ is64Bits << 31
		bitOr: (2r0101011001 << 21
		bitOr: ((rightRegister bitAnd: 16r1f) << 16
		bitOr: ((option bitAnd: 2r11) << 13
		bitOr: ((immediate3bitValue bitAnd: 2r111) << 10
		bitOr: ((leftRegister bitAnd: 16r1f) << 5
		bitOr: (destinationRegister bitAnd: 16r1f))))))
]

{ #category : #assembler }
CogARMv8Compiler >> addsSize: is64Bits leftRegister: leftRegister shiftedRightRegister: rightRegister shiftType: shiftType shiftOffset: immediate6bitValue destinationRegister: destinationRegister [

	"C6.2.9 ADDS (shifted register)
	
	Add (shifted register), setting flags, adds a register value and an optionally-shifted register value, and writes the result to the destination register. It updates the condition flags based on the result.
	
	ADDS <Xd>, <Xn>, <Xm>{, <shift> #<amount>}
	
	LSL when shift = 00
	LSR when shift = 01
	ASR when shift = 10"

	^ self
		arithmeticShiftedRegisterSize: is64Bits
		isSubstraction: 0
		setFlags: 1
		leftRegister: leftRegister
		shiftedRightRegister: rightRegister
		shiftType: shiftType
		shiftOffset: immediate6bitValue
		destinationRegister: destinationRegister
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> addsSize: is64Bits sourceRegister: leftRegister immediate12BitValue: immediate12BitValue shifted: shiftedFlag destinationRegister: destinationRegister [

	"C6.2.8 ADDS (immediate)
	
	Add (immediate), setting flags, adds a register value and an optionally-shifted immediate value, and writes the result to the destination register. It updates the condition flags based on the result.
		
	ADDS <Xd>, <Xn|SP>, #<imm>{, <shift>}"

	^ self
		arithmeticImmediateSize: is64Bits
		isSubstraction: 0
		setFlags: 1
		sourceRegister: leftRegister
		immediate12BitValue: immediate12BitValue
		shifted: shiftedFlag destinationRegister: destinationRegister
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> adrSignedImmediate21BitsValue: signedImmediate21bitValue destinationRegister: destinationRegister [

	"C6.2.10 ADR

	Form PC-relative address adds an immediate value to the PC value to form a PC-relative address, and writes the result to the destination register.
	
	ADR <Xd>, <label>
	
	signedImmediate21bitValue - Is the program label whose address is to be calculated. Its offset from the address of this instruction, in the range +/-1MB, is encoded in 
		immhi:immlo"
	
	| twoComplement immhi immlo |
	twoComplement := signedImmediate21bitValue < 0
		ifTrue: [ 16r1fffff - signedImmediate21bitValue abs + 1 ]
		ifFalse: [ signedImmediate21bitValue ].

	immhi := twoComplement >> 2.
	immlo := twoComplement bitAnd: 2r11.
	
	^ immlo << 29
		bitOr: (2r10000 << 24
		bitOr: (immhi << 5
		bitOr: (destinationRegister bitAnd: 16r1f)))
]

{ #category : #assembler }
CogARMv8Compiler >> andSetFlagsSize: is64Bits immediate13bitValue: logicalEncodedImmediate13BitValue sourceRegister: sourceRegister destinationRegister: destinationRegister [
	
	"C6.2.14 ANDS (immediate)
	
	Bitwise AND (immediate), setting flags, performs a bitwise AND of a register value and an immediate value, and writes the result to the destination
	register. It updates the condition flags based on the result. This instruction is used by the alias TST (immediate). See Alias conditions for details of
	when each alias is preferred.
	
	ANDS <Xd|SP>, <Xn>, #<imm>"
	
	^ self
		logicalImmediate: is64Bits
		opcode: 2r11
		immediate13bitValue: logicalEncodedImmediate13BitValue
		sourceRegister: sourceRegister
		destinationRegister: destinationRegister
]

{ #category : #assembler }
CogARMv8Compiler >> andSetFlagsSize: is64Bits shiftedRegister: shiftedRegister shiftType: shiftType shiftValue: immediate6bitValue withRegister: sourceRegister2 destinationRegister: destinationRegister [
	
	"C6.2.15 ANDS (shifted register)
	
	Bitwise AND (shifted register), setting flags, performs a bitwise AND of a register value and an optionally-shifted register value, and writes the
	result to the destination register. It updates the condition flags based on the result.
	This instruction is used by the alias TST (shifted register). See Alias conditions for details of when each alias is preferred.

	ANDS <Xd>, <Xn>, <Xm>{, <shift> #<amount>}
	
	LSL when shift = 00 LSR when shift = 01 ASR when shift = 10 ROR when shift = 11"
	
	^ is64Bits << 31
		bitOr: (2r1101010 << 24
		bitOr: ((shiftType bitAnd: 2r11) << 22
		bitOr: ((shiftedRegister bitAnd: 2r11111) << 16
		bitOr: ((immediate6bitValue bitAnd: 2r111111) << 10
		bitOr: ((sourceRegister2 bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111))))))
		
]

{ #category : #assembler }
CogARMv8Compiler >> andSize: is64Bits immediate13bitValue: logicalEncodedImmediate13BitValue sourceRegister: sourceRegister destinationRegister: destinationRegister [
	
	"C6.2.12 AND (immediate)
	
	Bitwise AND (immediate) performs a bitwise AND of a register value and an immediate value, and writes the result to the destination register.
	
	AND <Xd|SP>, <Xn>, #<imm>"
	
	^ is64Bits << 31
		bitOr: (2r00100100 << 23
		bitOr: ((logicalEncodedImmediate13BitValue bitAnd: 16r1fff)
		bitOr: ((sourceRegister bitAnd: 16r1f) << 5
		bitOr: (destinationRegister bitAnd: 16r1f))))
]

{ #category : #assembler }
CogARMv8Compiler >> andSize: is64Bits shiftedRegister: shiftedRegister shiftType: shiftType shiftValue: immediate6bitValue withRegister: sourceRegister2 destinationRegister: destinationRegister [
	
	"C6.2.13 AND (shifted register)
	
	Bitwise AND (shifted register) performs a bitwise AND of a register value and an optionally-shifted register value, and writes the result to the destination register.

	AND <Xd>, <Xn>, <Xm>{, <shift> #<amount>}
	
	LSL when shift = 00 LSR when shift = 01 ASR when shift = 10 ROR when shift = 11"
	
	^ is64Bits << 31
		bitOr: (2r0001010 << 24
		bitOr: ((shiftType bitAnd: 2r11) << 22
		bitOr: ((shiftedRegister bitAnd: 2r11111) << 16
		bitOr: ((immediate6bitValue bitAnd: 2r111111) << 10
		bitOr: ((sourceRegister2 bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111))))))
		
]

{ #category : #assembler }
CogARMv8Compiler >> arithmeticImmediateSize: is64Bits isSubstraction: substractionFlag setFlags: setFlagsFlag sourceRegister: sourceRegister immediate12BitValue: immediate12BitValue shifted: shiftedFlag destinationRegister: destinationRegister [

	"C4.1.2 Data Processing -- Immediate
	 C3.3.1 Arithmetic (immediate)
	
	The Arithmetic (immediate) instructions accept a 12-bit unsigned immediate value, optionally shifted left by 12 bits.
The Arithmetic (immediate) instructions that do not set Condition flags can read from and write to the current stack pointer. The flag setting instructions can read from the stack pointer, but they cannot write to it.
	
	- is64Bits: single bit indicating if the registers should be interpreted as 64bit (X) or 32bit (W) registers.
	- substractionFlag: single bit indicating if the instruction is a SUB or ADD
	- setFlagsFlag: single bit indicating if the instruction should set flags (SUBS vs SUB, ADDS vs ADD)
	- shiftedFlag: single bit indicating if the immediate value should be shifted 12 bits
	LSL when shiftType = 00
	LSR when shiftType = 01
	ASR when shiftType = 10"

	^ (is64Bits bitAnd: 1) << 31
		bitOr: ((substractionFlag bitAnd: 1) << 30
		bitOr: ((setFlagsFlag bitAnd: 1) << 29
		bitOr: (2r100010 << 23
		bitOr: ((shiftedFlag bitAnd: 2r1) << 22
		bitOr: ((immediate12BitValue bitAnd: 16rfff) << 10
		bitOr: ((sourceRegister bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111)))))))
]

{ #category : #assembler }
CogARMv8Compiler >> arithmeticShiftRightSize: is64bits sourceRegister: sourceRegister shiftRegister: shiftRegister destinationRegister: destinationRegister [ 

	"C6.2.16 ASR (register)
	
	Arithmetic Shift Right (register) shifts a register value right by a variable number of bits, shifting in copies of its sign bit, and writes the result to the destination register. The remainder obtained by dividing the second source register by the data size defines the number of bits by which the first source register is right-shifted.
	
	ASR <Xd>, <Xn>, <Xm>
	"

	
	^ is64bits << 31
		bitOr: (2r11010110 << 21
		bitOr: ((shiftRegister bitAnd: 16r1f) << 16
		bitOr: (2r1010 << 10
		bitOr: ((sourceRegister bitAnd: 16r1f) << 5
		bitOr: (destinationRegister bitAnd: 16r1f)))))
	
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> arithmeticShiftRightSize: is64Bits sourceRegister: sourceRegister shiftValue: shiftValue destinationRegister: destinationRegister [
	
	"C6.2.17 ASR (immediate)
	
	Arithmetic Shift Right (immediate) shifts a register value right by an immediate number of bits, shifting in copies of the sign bit in the upper bits and zeros in the lower bits, and writes the result to the destination register.

	ASR <Xd>, <Xn>, #<shift>"
	
	^ is64Bits << 31
		bitOr: (2r00100110 << 23
		bitOr: ((is64Bits bitAnd: 1) << 22
		bitOr: ((shiftValue bitAnd: 16r3f) << 16
		bitOr: (16r3f << 10
		bitOr: ((sourceRegister bitAnd: 16r1f) << 5
		bitOr: (destinationRegister bitAnd: 16r1f))))))
]

{ #category : #assembler }
CogARMv8Compiler >> arithmeticShiftedRegisterSize: is64Bits isSubstraction: substractionFlag setFlags: setFlagsFlag leftRegister: leftRegister shiftedRightRegister: rightRegister shiftType: shiftType shiftOffset: immediate6bitValue destinationRegister: destinationRegister [

	"C4.1.5 Data Processing -- Register
	
	- is64Bits: single bit indicating if the registers should be interpreted as 64bit (X) or 32bit (W) registers.
	- substractionFlag: single bit indicating if the instruction is a SUB or ADD
	- setFlagsFlag: single bit indicating if the instruction should set flags (SUBS vs SUB, ADDS vs ADD)
	
	LSL when shiftType = 00
	LSR when shiftType = 01
	ASR when shiftType = 10"

	^ (is64Bits bitAnd: 1) << 31
		bitOr: ((substractionFlag bitAnd: 1) << 30
		bitOr: ((setFlagsFlag bitAnd: 1) << 29
		bitOr: (2r01011 << 24
		bitOr: ((shiftType bitAnd: 2r11) << 22
		bitOr: ((rightRegister bitAnd: 2r11111) << 16
		bitOr:((immediate6bitValue bitAnd: 2r111111) << 10
		bitOr: ((leftRegister bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111))))))))
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> assembleSubCq: quickValue R: registerToUse [

	| fits12Bits |
	fits12Bits := (quickValue bitAnd: 16rfff) = quickValue.
	fits12Bits ifTrue: [ | reg |
		reg := operands at: 1.
		self
			machineCodeAt: 0
			put:
				(self
					subsSize: 1
					sourceRegister: reg
					immediate12BitValue: quickValue
					shifted: 0
					destinationRegister: reg).
		^ machineCodeSize := 4
	].

	self notYetImplemented.
	^ 0
]

{ #category : #'register allocation' }
CogARMv8Compiler >> availableRegisterOrNoneFor: liveRegsMask [
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

{ #category : #assembler }
CogARMv8Compiler >> b: immediate26bitValue [

	"C6.2.26 B
	
	Branch causes an unconditional branch to a label at a PC-relative offset, with a hint that this is not a subroutine call or return.
	
	26-bit signed PC-relative branch offset variant
	
	BL <label>
	
	<label> Is the program label to be unconditionally branched to. Its offset from the address of this instruction, in the range +/-128MB, is encoded as imm26 times 4."

	^ self b: immediate26bitValue withLink: false
]

{ #category : #assembler }
CogARMv8Compiler >> b: immediate26bitValue withLink: aBoolean [
	| twoComplement multiplier |

	"Branch optionally with Link branches to a PC-relative offset, setting the register X30 to PC+4. It provides a hint that this is a subroutine call.
	
	26-bit signed PC-relative branch offset variant
	
	BL <label>
	
	<label> Is the program label to be unconditionally branched to. Its offset from the address of this instruction, in the range +/-128MB, is encoded as imm26 times 4."
	
	self seeAlso: #b:.
	self seeAlso: #bl:.

	multiplier := immediate26bitValue / 4.
	self assert: multiplier isInteger.
	twoComplement := multiplier > 0
		ifTrue: [ multiplier ]
		ifFalse: [ 2r11111111111111111111111111 - multiplier abs + 1 ].

	^ (aBoolean ifTrue: [1]ifFalse: [0]) << 31
		bitOr: (2r00101 << 26
		bitOr: twoComplement)
]

{ #category : #assembler }
CogARMv8Compiler >> bl: immediate26bitValue [

	"C6.2.33 BL
	
	Branch with Link branches to a PC-relative offset, setting the register X30 to PC+4. It provides a hint that this is a subroutine call.
	
	26-bit signed PC-relative branch offset variant
	
	BL <label>
	
	<label> Is the program label to be unconditionally branched to. Its offset from the address of this instruction, in the range +/-128MB, is encoded as imm26 times 4."
	^ self b: immediate26bitValue withLink: true
]

{ #category : #assembler }
CogARMv8Compiler >> blr: registerToUse [

	"C6.2.34 BLR
	
	Branch with Link to Register calls a subroutine at an address in a register, setting register X30 to PC+4.

	BLR <Xn>"

	^ self br: registerToUse withLink: 1
]

{ #category : #'ARM convenience instructions' }
CogARMv8Compiler >> blx: targetReg [
	"Branch&link to the address in targetReg. Return address is in LR
	BLX targetReg - ARM_ARM v7 DDI10406 pp. A8-60-1"
	<inline: true>
	^self cond: AL bx: 1 target: targetReg

]

{ #category : #assembler }
CogARMv8Compiler >> br: registerToUse [

	"C6.2.36 BR
	
	Branch to Register branches unconditionally to an address in a register, with a hint that this is not a subroutine return.

	BR <Xn>"

	^ self br: registerToUse withLink: 0
]

{ #category : #assembler }
CogARMv8Compiler >> br: registerToUse withLink: withLink [

	"Branch optionally with Link branches to Register calls a subroutine at an address in a register, setting register X30 to PC+4.
	
	BRL Xn
	"

	^ 2r110101100 << 23
		bitOr: ((withLink bitAnd: 2r11) << 21
		bitOr: (2r11111 << 16
		bitOr: (registerToUse bitAnd: 16r1f) << 5))
]

{ #category : #assembler }
CogARMv8Compiler >> branchCondition: condition offset: immediate19bitValue [

	"C6.2.25 B.cond
	
	Branch conditionally to a label at a PC-relative offset, with a hint that this is not a subroutine call or return.
	
	B.<cond> <label>
	"
	
	| multiplier twoComplement |
	"Precondition:
	the jump target can be encoded as an immediate of 19 bits multiplied by 4"
	self assert: (immediate19bitValue >> 2 << 2 = immediate19bitValue).
	self assert: (16r3ffff allMask: immediate19bitValue abs >> 2).
	
	multiplier := immediate19bitValue >> 2.
	self assert: multiplier isInteger.
	twoComplement := multiplier < 0
		ifTrue: [ 2r1111111111111111111 - multiplier abs + 1 ]
		ifFalse: [ multiplier ].

	^ 2r01010100 << 24
		bitOr: ((twoComplement bitAnd: 2r1111111111111111111) << 5
		bitOr: (condition bitAnd: 16rf))
]

{ #category : #testing }
CogARMv8Compiler >> byteReadsZeroExtend [
	^true
]

{ #category : #abi }
CogARMv8Compiler >> cResultRegister [
	"Answer the register through which C funcitons return integral results."
	<inline: true>
	^R0
]

{ #category : #accessing }
CogARMv8Compiler >> cStackPointer [
	
	^ SP
]

{ #category : #accessing }
CogARMv8Compiler >> callInstructionByteSize [
	"ARM calls and jumps span +/- 32 mb, more than enough for intra-zone calls and jumps."
	^4
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> callTargetFromReturnAddress: callSiteReturnAddress [
	"Answer the address that the call immediately preceding callSiteReturnAddress will jump to."
	"this is also used by #jumpLongTargetBeforeFollowingAddress:."
	| callDistance callInstruction callAddress |
	callAddress := self instructionAddressBefore: callSiteReturnAddress.
	callInstruction := objectMemory long32At: callAddress.
	self assert: ((self instructionIsB: callInstruction) or: [self instructionIsBL: callInstruction]).
	
	callDistance := self extractOffsetFromBL: callInstruction.

	"this is the pc's offset at the branch"
	^callAddress + callDistance signedIntFromLong
]

{ #category : #testing }
CogARMv8Compiler >> canDivQuoRem [
	^true
]

{ #category : #testing }
CogARMv8Compiler >> canMulRR [
"we can do a MulRR be we can't simulate it correctly for some reason. More bug-fixing in the simulator one day"
	^true
]

{ #category : #assembler }
CogARMv8Compiler >> cmnSize: is64bits immediate12BitValue: immediate12BitValue shiftFlag: shiftFlag register: registerToUse [
	
	"C6.2.58 CMN (immediate)
	
	Compare Negative (immediate) adds a register value and an optionally-shifted immediate value. It updates the condition flags based on the result, and discards the result.
	
	CMN <Xn|SP>, #<imm>{, <shift>}
	
	- shiftFlag: single bit indicating if the immediate value should be shifted 12 bits or not"
	
	^ self
		addsSize: is64bits
		sourceRegister: registerToUse
		immediate12BitValue: immediate12BitValue
		shifted: shiftFlag
		destinationRegister: 2r11111
]

{ #category : #assembler }
CogARMv8Compiler >> cmpExtendedRegisterSize: is64Bits leftRegisterMaybeSP: leftRegister option: option shiftOffset: immediate3bitValue destinationRegister: destinationRegister [
	
	"C6.2.60 CMP (extended register)
	
	Compare (extended register) subtracts a sign or zero-extended register value, followed by an optional left shift amount, from a register value. The argument that is extended from the <Rm> register can be a byte, halfword, word, or doubleword. It updates the condition flags based on the result, and discards the result.

	
	CMP <Xn|SP>, <R><m>{, <extend> {#<amount>}}
	"
	
	^ self
		subsExtendedSize: is64Bits
		leftRegisterMaybeSP: leftRegister
		shiftedRightRegister: destinationRegister
		option: option
		shiftOffset: immediate3bitValue
		destinationRegister: 2r11111
]

{ #category : #assembler }
CogARMv8Compiler >> cmpSize: is64bits immediate12BitValue: immediate12BitValue shiftFlag: shiftFlag register: registerToUse [
	
	"C6.2.61 CMP (immediate)
	
	Compare (immediate) subtracts an optionally-shifted immediate value from a register value. It updates the condition flags based on the result, and discards the result.
	
	CMP <Xn|SP>, #<imm>{, <shift>}
	
	- shiftFlag: single bit indicating if the immediate value should be shifted 12 bits or not"
	
	^ self
		subsSize: is64bits
		sourceRegister: registerToUse
		immediate12BitValue: immediate12BitValue
		shifted: shiftFlag
		destinationRegister: 2r11111
]

{ #category : #assembler }
CogARMv8Compiler >> cmpSize: is64bits shiftedRegister: register1 shiftType: shiftType shiftValue: immediate6BitShiftValue secondRegister: register2 [
	
	"C6.2.62 CMP (shifted register)
	
	Compare (shifted register) subtracts an optionally-shifted register value from a register value. It updates the condition flags based on the result, and discards the result.
	
	CMP <Xn>, <Xm>{, <shift> #<amount>}
	
	LSL when shift = 00
	LSR when shift = 01
	ASR when shift = 10"
	
	^ is64bits << 31
		bitOr: (2r1101011 << 24
		bitOr: ((shiftType bitAnd: 2r11) << 22
		bitOr: ((register1 bitAnd: 16r1f) << 16
		bitOr: ((immediate6BitShiftValue bitAnd: 16r3f) << 10
		bitOr: ((register2 bitAnd: 16r1f) << 5
		bitOr: 2r11111)))))
]

{ #category : #accessing }
CogARMv8Compiler >> codeGranularity [
	"Answer the size in bytes of a unit of machine code."
	<inline: true>
	^4
]

{ #category : #'generate machine code' }
CogARMv8Compiler >> computeMaximumSize [
	"Because we don't use Thumb, each ARM instruction has 4 bytes. Many
	 abstract opcodes need more than one instruction. Instructions that refer
	 to constants and/or literals depend on literals being stored in-line or out-of-line.

	 N.B.  The ^N forms are to get around the bytecode compiler's long branch
	 limits which are exceeded when each case jumps around the otherwise."

	| offset |

	<var: #offset type: #'sqInt'>

	opcode
		caseOf: {
		"Noops & Pseudo Ops"
		[Label]					-> [^0].
		[Literal]					-> [^8].
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
		[JumpLongZero]		-> [^self jumpLongConditionalByteSize].
		[JumpLongNonZero]	-> [^self jumpLongConditionalByteSize].
		[JumpFPEqual]			-> [^4].
		[JumpFPNotEqual]		-> [^4].
		[JumpFPLess]			-> [^4].
		[JumpFPGreaterOrEqual]-> [^4].
		[JumpFPGreater]		-> [^4].
		[JumpFPLessOrEqual]	-> [^4].
		[JumpFPOrdered]		-> [^4].
		[JumpFPUnordered]		-> [^4].
		[RetN]					-> [^(operands at: 0) = 0 ifTrue: [4] ifFalse: [8]].
		[Stop]					-> [^4].

		"Arithmetic"
		[AddCqR]				-> [
			^ ((operands at: 1) = SP)
				ifTrue: [ 12 ]
				ifFalse: [ | fits12Bits word |
					word := operands at: 0.
					fits12Bits := (word bitAnd: 16rfff) = word.
					fits12Bits ifTrue: [ 4 ] ifFalse: [ 8 ] ] ].
		[AndCqR]				-> [^self
										encodeLogicalImmediate: (operands at: 0)
										registerSize: 64
										ifPossible: [ :v | 4 ]
										ifNotPossible: [ 8 ]].
		[AndCqRR]				-> [^self rotateable8bitBitwiseImmediate: (operands at: 0)
										ifTrue: [:r :i :n| 4]
										ifFalse:
											[self literalLoadInstructionBytes = 4
												ifTrue: [8]
												ifFalse:
													[1 << (operands at: 0) highBit = ((operands at: 0) + 1)
														ifTrue: [8]
														ifFalse: [self literalLoadInstructionBytes + 4]]]].

		[CmpCqR]				-> [| immediate |
			immediate := (operands at: 0) abs.
			^ ((immediate bitAnd: 16rfff) = immediate
				or: [ (immediate << 12 >> 12 bitAnd: 16rFFF) = immediate ])
					ifTrue: [ 4]
					ifFalse: [self literalLoadInstructionBytes + 4]].
		[CmpC32R]				-> [^self rotateable8bitSignedImmediate: (operands at: 0)
											ifTrue: [:r :i :n| 4]
											ifFalse: [self literalLoadInstructionBytes + 4]].
		[OrCqR]				-> [
			^self
				encodeLogicalImmediate: (operands at: 0)
				registerSize: 64
				ifPossible: [ :v | 4 ]
				ifNotPossible: [ self literalLoadInstructionBytes + 4 ] ].
			
		[SubCqR]				-> [| constant |
			"If it fits in 12 bits, we can used an immediate instruction.
			Othewise we need to use a literal and load it"
			constant := operands at: 0.
			(constant bitAnd: 16rfff) = constant
				ifTrue: [ ^ 4 ]
				ifFalse: [ ^ self literalLoadInstructionBytes + 4 ] ].
		[TstCqR]				-> [
			^self
				encodeLogicalImmediate: (operands at: 0)
				registerSize: 64
				ifPossible: [ :v | 4 ]
				ifNotPossible: [ self literalLoadInstructionBytes + 4 ] ].
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
		[CmpRR]				-> [^(((operands at:0) = SP) or: [(operands at: 1) = SP]) ifTrue: [8] ifFalse: [4]].
		[OrRR]					-> [^4].
		[XorRR]					-> [^4].
		[SubRR]					-> [ "When the operation includes the SP, we might need two instructions" ^(operands at: 0) = SP ifTrue: [ 8 ] ifFalse: [ 4 ]].
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
		[RotateLeftCqR]					-> [^4].
		[RotateRightCqR]					-> [^4].
	
		"Floating point operations"
	
		[AddRdRd]					-> [^4].
		[CmpRdRd]					-> [^4].
		[SubRdRd]					-> [^4].
		[MulRdRd]					-> [^4].
		[DivRdRd]					-> [^4].
		[SqrtRd]					-> [^4].
		[XorRdRd]					-> [^4].
						
		"ARM Specific Arithmetic"
		[MUL]			-> [^4].
		[SMULH] 		-> 	[^4].
		[CMPMULOverflow]				-> [^4].
		[SDIV]					-> [^4].
		[MSUB]					-> [^4].
				
		"Data Movement"						
		[MoveCqR]				-> [^4].
		[MoveC32R]			-> [^4].
		[MoveCwR]				-> [^self literalLoadInstructionBytes = 4
										ifTrue: [self literalLoadInstructionBytes]
										ifFalse:
											[(self inCurrentCompilation: (operands at: 0))
												ifTrue: [4]
												ifFalse: [self literalLoadInstructionBytes]]].
		[MoveRR]				-> [^4].
		[MoveRdRd]			-> [^4].
		[MoveAwR]				-> [
			"if register is SP we need an extra move"
			^(self isAddressRelativeToVarBase: (operands at: 0))
					ifTrue: [(operands at: 1) = SP
						ifTrue: [ 8 ]
						ifFalse: [ 4 ]  ]
					ifFalse: [self literalLoadInstructionBytes + 8 ]].
		[MoveRAw]				-> [^(self isAddressRelativeToVarBase: (operands at: 1))
													ifTrue: [(operands at: 0) = SP
														ifTrue: [ 8 ]
														ifFalse: [ 4 ]]
													ifFalse: [
													 	(operands at: 0) = SP
															ifTrue: [ 4 + self literalLoadInstructionBytes + 4 ]
															ifFalse: [ self literalLoadInstructionBytes + 4 ]]].
		[MoveAbR]				-> [^(self isAddressRelativeToVarBase: (operands at: 0))
													ifTrue: [4]
													ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveRAb]				-> [^(self isAddressRelativeToVarBase: (operands at: 1))
													ifTrue: [4]
													ifFalse: [self literalLoadInstructionBytes + 4]].

		[MoveRM32r]			-> [self is9BitValue: (operands at: 1)
										ifTrue: [ :value | ^  4 ]
										ifFalse: [ self shiftable16bitImmediate: (operands at: 1) 
														ifTrue: [ :value :shift | ^  8 ] 
														ifFalse: [ ^ self literalLoadInstructionBytes + 4 ] ]].

		[MoveRMwr]			-> [self is9BitValue: (operands at: 1)
										ifTrue: [ :value | ^  4 ]
										ifFalse: [ self shiftable16bitImmediate: (operands at: 1) 
														ifTrue: [ :value :shift | ^  8 ] 
														ifFalse: [ ^ self literalLoadInstructionBytes + 4 ] ]].
		[MoveRsM32r]			-> [^self is12BitValue: (operands at: 1)
										ifTrue: [:u :i | 4]
										ifFalse: [self notYetImplemented. self literalLoadInstructionBytes + 4]]. 
		[MoveRdM64r]			-> [^self is12BitValue: (operands at: 1)
										ifTrue: [:u :i | 4]
										ifFalse: [self notYetImplemented. self literalLoadInstructionBytes + 4]]. 
		[MoveMbrR]			-> [^self is9BitValue: (operands at: 0)
										ifTrue: [:value | 8 "2 instrutions" ]
										ifFalse: [ self literalLoadInstructionBytes + 4 ]].

		[MoveRM8r]				-> [^self is12BitValue: (operands at: 1)
										ifTrue: [:u :i | 4]
										ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveRMbr]				-> [^self is12BitValue: (operands at: 1)
										ifTrue: [:u :i | 4]
										ifFalse: [self literalLoadInstructionBytes + 4]].

		[MoveRM16r]				-> [^self is12BitValue: (operands at: 1)
										ifTrue: [:u :i| 4]
										ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveM16rR]			-> [^self rotateable8bitImmediate: (operands at: 0)
											ifTrue: [:r :i| 4]
											ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveM32rRs]			-> [^self is12BitValue: (operands at: 0) 
										ifTrue: [:s :v| 4] ifFalse: [self notYetImplemented. 0]].
		[MoveM64rRd]			-> [^self is12BitValue: (operands at: 0) 
										ifTrue: [:s :v| 4] ifFalse: [self notYetImplemented. 0]].
		[MoveM32rR]			-> [ 			
			offset := (operands at: 0).
			(offset >= 0 and: [ (offset bitAnd: 16rFFF) = offset ]) 
				ifTrue: [ ^ 4 ]
				ifFalse: [ 	self
									is9BitValue: offset
										ifTrue: [ :v | ^ 4 ] 
										ifFalse: [^ self literalLoadInstructionBytes + 4 ] ]].

		[MoveMwrR]			-> [ 			
			offset := (operands at: 0).
			(offset >= 0 and: [ (offset bitAnd: 16rFFF) = offset ]) 
				ifTrue: [ ^ 4 ]
				ifFalse: [ 	self
									is9BitValue: offset
										ifTrue: [ :v | ^ 4 ] 
										ifFalse: [^ self literalLoadInstructionBytes + 4 ] ]].
		[MoveXbrRR]			-> [^4].
		[MoveX32rRR]			-> [^4].
		[MoveRX32rR]			-> [^4].
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
		[ConvertRdRs]			-> [^4].
		[ConvertRsRd]			-> [^4].
		[ConvertRRd]			-> [^4].
		[MoveRdR]				-> [^4].
		[MoveRRd]				-> [^4].
				
		"This is a fixed size instruction using a literal. We need exactly 1 instructions to move a literal from a PC relative position, so this takes ALWAYS 1 instruction of 4 bytes"
		[MovePatcheableC32R] -> [ ^ 4 ]
		}.
	^0 "to keep C compiler quiet"

]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeAddCqR [

	<var: #word type: #sqInt>
	<inline: true>
	| word fits12Bits |
	word := operands at: 0.
	
	((operands at: 1) = SP) ifTrue: [
		"This only works if Cq fits in 12 bits..."
		"If it is the SP, it requires additional handling"
		self notYetImplemented.

		self assert: (word bitAnd: 16rfff) = word.
		self
			machineCodeAt: 0
			put: (self movSize: 1 sourceRegisterMaybeSP: SP destinationRegisterMaybeSP: ConcreteIPReg).
		self
			machineCodeAt: 4
			put: (self
					addsSize: 1
					sourceRegister: ConcreteIPReg
					immediate12BitValue: word
					shifted: 0
					destinationRegister: ConcreteIPReg).
		self
			machineCodeAt: 8
			put: (self movSize: 1 sourceRegisterMaybeSP: ConcreteIPReg destinationRegisterMaybeSP: SP).
		^ machineCodeSize := 12
	].
	
	word < 0 ifTrue: [
		^ self assembleSubCq: word negated R: (operands at: 1)
	].
	
	fits12Bits := (word bitAnd: 16rfff) = word.
	fits12Bits ifTrue: [ | reg |
		reg := operands at: 1.
		self
			machineCodeAt: 0
			put:
				(self
					addsSize: 1
					sourceRegister: reg
					immediate12BitValue: word
					shifted: 0
					destinationRegister: reg).
		^ machineCodeSize := 4
	].
	
	^ self concretizeAddCwR.
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> concretizeAddCwR [
	
	self assert: dependent notNil.
	
	self loadCwInto: ConcreteIPReg.
	self
		machineCodeAt: machineCodeSize
		put: ( self
			addsSize: 1
			leftRegister: ConcreteIPReg
			shiftedRightRegister: (operands at: 1)
			shiftType: 0
			shiftOffset: 0
			destinationRegister: (operands at: 1)).
	^ machineCodeSize := machineCodeSize + 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeAddRR [

	| instruction destinationRegister leftRegister rightRegister |
	leftRegister := operands at: 0.
	destinationRegister := rightRegister := operands at: 1.

	"If one of the operands is the stack pointer, we need to use the extended version"
	rightRegister = SP ifTrue: [ self notYetImplemented ].
	
	instruction := leftRegister = SP ifFalse: [ 
		self
			addsSize: 1
			leftRegister: leftRegister
			shiftedRightRegister: rightRegister
			shiftType: 0
			shiftOffset: 0
			destinationRegister: destinationRegister
	] ifTrue: [
		self notYetImplemented.
		self
			addsExtendedSize: 1
			leftRegisterMaybeSP: leftRegister
			shiftedRightRegister: rightRegister
			option: 2r011 "interpret right register as unsigned 64bits UXTX"
			shiftOffset: 0
			destinationRegister: destinationRegister
	].

	self machineCodeAt: 0 put: instruction.
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeAddRdRd [

	"Will get inlined into concretizeAt: switch."

	"Add FP regRHS to FP regLHS and stick result in FP regLHS"

	<inline: true>
	| regLHS regRHS |

	regRHS := operands at: 0.
	regLHS := operands at: 1.

	machineCode at: 0 put: (self
			 faddSize: 1
			 firstSourceRegister: regLHS
			 secondSourceRegister: regRHS
			 destinationRegister: regLHS).

	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeAlignmentNops [
	"fill any slots with NOPs"

	<inline: true>
	self assert: machineCodeSize \\ 4 = 0.
	0 to: machineCodeSize - 1 by: 4 do: [ :p | self machineCodeAt: p put: self nop ]
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeAndCqR [
	<var: #val type: #sqInt>
	<inline: true>
	| val rd rn |
	val := operands at: 0.
	
	"Both source and destination register are the same..."
	rn := operands at: 1.
	rd := rn.
	self
		encodeLogicalImmediate: val
		registerSize: 64
		ifPossible: [ :encodedValue |
			self
				machineCodeAt: 0
				put: (self
					andSetFlagsSize: 1
					immediate13bitValue: encodedValue
					sourceRegister: rn
					destinationRegister: rd).
			^ machineCodeSize := 4
		] ifNotPossible: [
			"If this does not fit in a logical immediate value => Try to move it to a register, then AND the registers"
			self moveCw: val intoR: ConcreteIPReg.
			self
				machineCodeAt: 4
				put: (self
					andSetFlagsSize: 1
					shiftedRegister: ConcreteIPReg
					shiftType: 0
					shiftValue: 0
					withRegister: rn
					destinationRegister: rd).
			^ machineCodeSize := 8 "A move and an AND"
		].
	^ 0	"to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeAndCqRR [
	"Will get inlined into concretizeAt: switch."

	"AND is very important since it's used to mask all sorts of flags in the jit. We take special care to try to find compact ways to make the masks"

	<var: #val type: #sqInt>
	<inline: true>
	| val srcReg dstReg |

	val := operands at: 0.
	srcReg := operands at: 1.
	dstReg := operands at: 2.
	self assert: (val bitAnd: 16r1fff) = val.
	self
		encodeLogicalImmediate: val
		registerSize: 64
		ifPossible: [ :encodedLogicalImmediate |
			self
				machineCodeAt: 0
				put: (self andSetFlagsSize: 1
					immediate13bitValue: encodedLogicalImmediate
					sourceRegister: srcReg
					destinationRegister: dstReg).
			^ machineCodeSize := 4 ]
		ifNotPossible: [ self notYetImplemented ].
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> concretizeAndRR [

	| srcReg dstReg |
	srcReg := operands at: 0.
	dstReg := operands at: 1.
	self
		machineCodeAt: 0
		put: (self
			andSetFlagsSize: 1
			shiftedRegister: srcReg
			shiftType: 0
			shiftValue: 0
			withRegister: dstReg
			destinationRegister: dstReg).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeArithmeticShiftRightCqR [

	<var: #shiftValue type: #sqInt>
	<inline: true>
	| shiftValue reg |
	shiftValue := operands at: 0.
	reg := operands at: 1.
	self
		machineCodeAt: 0
		put: (self
			arithmeticShiftRightSize: 1
			sourceRegister: reg
			shiftValue: shiftValue
			destinationRegister: reg).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeArithmeticShiftRightRR [

	self 
		machineCodeAt: 0 
		put: (self
			 arithmeticShiftRightSize: 1
			 sourceRegister: (operands at: 1)
			 shiftRegister: (operands at: 0)
			 destinationRegister: (operands at: 1)).

	^ machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogARMv8Compiler >> concretizeAt: actualAddress [
	"Generate concrete machine code for the instruction at actualAddress,
	 setting machineCodeSize, and answer the following address."

	self assert: actualAddress \\ 4 = 0.
	^ super concretizeAt: actualAddress
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> concretizeCMPMULOverflow [
	
	| registerA destinationRegister registerB |
	registerA := operands at: 0.
	registerB := destinationRegister := operands at: 1.
	
	self
		machineCodeAt: 0
		put: (self
			cmpSize: 1
			shiftedRegister: registerA
			shiftType: 2r10 "Arithmetic Shift Right so the sign is extended and kept"
			shiftValue: 63 "Shift all but sign"
			secondRegister: registerB).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeCall [
	"Will get inlined into concretizeAt: switch."

	"Call is used only for calls within code-space, See CallFull for general anywhere in address space calling"

	<inline: true>
	| offset |
	self assert: (operands at: 0) ~= 0.
	self assert: (operands at: 0) \\ 4 = 0.
	offset := (operands at: 0) signedIntFromLong
		- address signedIntFromLong.	"normal pc offset"
	self assert: (self isInImmediateJumpRange: offset).	"+- 24Mb is plenty of range in code space"
	self machineCodeAt: 0 put: (self bl: offset).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeCallFull [
	"Will get inlined into concretizeAt: switch."

	"Sizing/generating calls.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."

	<inline: true>
	<var: #jumpTarget type: #'AbstractInstruction *'>
	| jumpTarget instrOffset |
	jumpTarget := self longJumpTargetAddress.
	instrOffset := self moveCw: jumpTarget intoR: ConcreteIPReg.
	"blx ConcreteIPReg"
	self machineCodeAt: instrOffset put: (self blr: ConcreteIPReg).
	self assert: instrOffset = self literalLoadInstructionBytes.
	^ machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code' }
CogARMv8Compiler >> concretizeCmpC32R [

	<inline: true>
	^ self concretizeCmpCqR
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeCmpCqR [
	
	<var: #quickImmediate type: #sqInt>
	<inline: true>
	| quickImmediate registerToUse fits12Bits fitsShifted12Bits |
	quickImmediate := operands at: 0.
	registerToUse := operands at: 1.

	quickImmediate >= 0 ifTrue: [  
		fits12Bits := (quickImmediate bitAnd: 16rfff) = quickImmediate.
		fits12Bits ifTrue: [
			self
				machineCodeAt: 0
				put:
					(self cmpSize: 1 immediate12BitValue: quickImmediate shiftFlag: 0 register: registerToUse).
			^ machineCodeSize := 4 ].
		
		fitsShifted12Bits := (quickImmediate << 12 >> 12 bitAnd: 16rFFF) = quickImmediate.
		fitsShifted12Bits ifTrue: [ 
			self
				machineCodeAt: 0
				put:
					(self cmpSize: 1 immediate12BitValue: quickImmediate >> 12 shiftFlag: 1 register: registerToUse).
			^ machineCodeSize := 4
		]]
	ifFalse: [
		quickImmediate := quickImmediate abs.
		fits12Bits := (quickImmediate bitAnd: 16rfff) = quickImmediate.
		fits12Bits ifTrue: [
			self
				machineCodeAt: 0
				put:
					(self cmnSize: 1 immediate12BitValue: quickImmediate shiftFlag: 0 register: registerToUse).
			^ machineCodeSize := 4 ].
		
		fitsShifted12Bits := (quickImmediate << 12 >> 12 bitAnd: 16rFFF) = quickImmediate.
		fitsShifted12Bits ifTrue: [ 
			self
				machineCodeAt: 0
				put:
					(self cmnSize: 1 immediate12BitValue: quickImmediate >> 12 shiftFlag: 1 register: registerToUse).
			^ machineCodeSize := 4 ]].
	 
	"If the value does not fit in 12 bits, not even shifted, then use two instructions"
	self moveCw: quickImmediate intoR: ConcreteIPReg.
	self
		machineCodeAt: machineCodeSize
		put:
			(self
				cmpSize: 1
				shiftedRegister: ConcreteIPReg
				shiftType: 0
				shiftValue: 0
				secondRegister: registerToUse).
	^ machineCodeSize := machineCodeSize + 4
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> concretizeCmpCwR [
	
	self assert: dependent notNil.
	self moveCw: (operands at: 0) intoR: ConcreteIPReg.
	(operands at: 1) = SP ifTrue: [ self notYetImplemented ].	

	self
		machineCodeAt: machineCodeSize
		put:
			(self
				cmpSize: 1
				shiftedRegister: (operands at: 1)
				shiftType: 0
				shiftValue: 0
				secondRegister: ConcreteIPReg).
	^ machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeCmpRR [

	<inline: true>
	| register1 register2 |
	register1 := operands at: 0.
	register2 := operands at: 1.
	register1 = SP ifTrue: [ 		
		self
			machineCodeAt: 0
			put: (self movToFromSP: ConcreteIPReg rn: SP ).
		self
			machineCodeAt: 4
			put:
				(self
					cmpSize: 1
					shiftedRegister: ConcreteIPReg
					shiftType: 0
					shiftValue: 0
					secondRegister: register2).

			^ machineCodeSize := 8].
		
	register2 = SP ifTrue: [ 
		self machineCodeAt: 0 put: (self movSize: 1 sourceRegisterMaybeSP: SP destinationRegisterMaybeSP: ConcreteIPReg).
		self
			machineCodeAt: 4
			put:
				(self
					cmpSize: 1
					shiftedRegister: register1
					shiftType: 0
					shiftValue: 0
					secondRegister: ConcreteIPReg).

			^ machineCodeSize := 8 ].
	
	self
		machineCodeAt: 0
		put:
			(self
				cmpSize: 1
				shiftedRegister: register1
				shiftType: 0
				shiftValue: 0
				secondRegister: register2).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeCmpRdRd [
	"Will get inlined into concretizeAt: switch."

	"Compare FP regB with FP regA and leave the FP status reg ready to be transferred back to ARM with next instruction"

	<inline: true>
	| regB regA |
	regA := operands at: 0.
	regB := operands at: 1.
	machineCode at: 0 put: (self
		fcmpFType: 2r01 "64bit variant"
		leftRegister: regB
		rightRegister: regA).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeConditionalJump: conditionCode [
	"Will get inlined into concretizeAt: switch."

	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."

	<inline: true>
	| offset |
	offset := self computeJumpTargetOffsetPlus: 0.
	self assert: (self isInImmediateJumpRange: offset).
	self
		machineCodeAt: 0
		put: (self branchCondition: conditionCode offset: offset).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeConvertRRd [
	"Convert an integer value into a double precision float value"

	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	machineCode at: 0 put: (self scalarConvertSize: 1 fromScalarRegister: srcReg toDoublePrecisionFloatRegister: destReg).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeConvertRdRs [

	"Convert a double precision float to a single precision float in a register"

	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.

	machineCode at: 0 put: (self
			 fConvertSourceRegister: srcReg
			 toRegister: destReg
			 sourcePrecision: 2r01 "Double precision"
			 toPrecision: 2r00 "Single precision").
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeConvertRsRd [

	"Convert a single precision float to a double precision float in a register"

	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.

	machineCode at: 0 put: (self
			 fConvertSourceRegister: srcReg
			 toRegister: destReg
			 sourcePrecision: 2r00 "Single precision"
			 toPrecision: 2r01 "Double precision").
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeDataOperationCwR: armOpcode [

	self notYetImplemented.
	^ 0
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeDivRdRd [
	"FP divide regLHS by regRHS and stick result in regLHS"

	<inline: true>
	| registerA registerB destinationRegister |
	registerA := operands at: 0.
	destinationRegister := registerB := operands at: 1.
	machineCode at: 0 put: (self
		fDivFirstRegister: registerB
		secondRegister: registerA
		destinationRegister: destinationRegister).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeFPConditionalJump: conditionCode [
	"Will get inlined into concretizeAt: switch."

	<inline: true>
	^ self concretizeConditionalJump: conditionCode
]

{ #category : #'generate machine code' }
CogARMv8Compiler >> concretizeFill32 [
	"fill with operand 0 according to the processor's endianness"

	self machineCodeAt: 0 put: (operands at: 0).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeInvertibleDataOperationCqR: armOpcode [

	self notYetImplemented.
	^ 0
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeJumpFull [
"Will get inlined into concretizeAt: switch."

	"Sizing/generating calls.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."

	<inline: true>
	<var: #jumpTarget type: #'AbstractInstruction *'>
	| jumpTarget instrOffset |
	jumpTarget := self longJumpTargetAddress.
	instrOffset := self moveCw: jumpTarget intoR: ConcreteIPReg.
	"blx ConcreteIPReg"
	self machineCodeAt: instrOffset put: (self br: ConcreteIPReg).
	self assert: instrOffset = self literalLoadInstructionBytes.
	^ machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code' }
CogARMv8Compiler >> concretizeJumpLong [

	| offset |
	offset := (operands at: 0) signedIntFromLong
		- address signedIntFromLong.	"normal pc offset"
	self assert: (self isInImmediateJumpRange: offset).	"+- 24Mb is plenty of range in code space"
	self machineCodeAt: 0 put: (self b: offset). 
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeJumpLongNonZero [

	self notYetImplemented.
	^ 0
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeJumpLongZero [
	
	"There are no conditional long jumps in AARCH64.
	Compile this to a sequence as follows:
	
		b.ne nonZero
		b target
	
		nonZero:
	
	...
	"
	
	| offset |
	"Calculate the offset between the B and the target. The B is the second instruction thus the -4"
	offset := (operands at: 0) signedIntFromLong - address signedIntFromLong - 4.
	self assert: (self isInImmediateJumpRange: offset).

	self machineCodeAt: 0 put: (self branchCondition: NE offset: 8 "should jump after the b").
	self machineCodeAt: 4 put: (self b: offset).
	
	^ machineCodeSize := 8
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeJumpR [
	"Will get inlined into concretizeAt: switch."

	<inline: true>
	| reg |
	reg := operands at: 0.
	self machineCodeAt: 0 put: (self br: reg).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeLiteral [

	<doNotGenerate>
	self subclassResponsibility 
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeLoadEffectiveAddressMwrR [
	"Will get inlined into concretizeAt: switch."

	"destReg = srcReg (which contains an address) + offset"

	<inline: true>
	| srcReg offset destReg instrOffset |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	
	self is12BitValue: offset
		ifTrue: [ :positive :value |
			self
				machineCodeAt: 0
				put: (self
					addSize: 1
					sourceRegister: srcReg
					shift: 0
					immediate12: offset
					destinationRegister: destReg).
			^ machineCodeSize := 4 ]
		ifFalse: [ self notYetImplemented ].
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeLogicalShiftLeftCqR [
	"Will get inlined into concretizeAt: switch."

	<var: #distance type: #sqInt>
	<inline: true>
	| distance reg |
	distance := (operands at: 0) min: 63.
	reg := operands at: 1.
	self
		machineCodeAt: 0
		put: (self
			logicalShiftLeftSize: 1
			sourceRegister: reg
			shiftValue: distance
			destinationRegister: reg).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeLogicalShiftLeftRR [
	self 
		machineCodeAt: 0 
		put: (self
			 logicalShiftLeftSize: 1
			 sourceRegister: (operands at: 1)
			 shiftRegister: (operands at: 0)
			 destinationRegister: (operands at: 1)).
			
		
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeLogicalShiftRightCqR [
	"Will get inlined into concretizeAt: switch."

	<var: #distance type: #sqInt>
	<inline: true>
	| distance reg |
	distance := (operands at: 0) min: 63.
	reg := operands at: 1.
	self
		machineCodeAt: 0
		put: (self
			logicalShiftRightSize: 1
			sourceRegister: reg
			shiftValue: distance
			destinationRegister: reg).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeLogicalShiftRightRR [

	self notYetImplemented.
	^ 0
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMSUB [

	<inline: true>

	| minuendReg factor1Reg factor2Reg destinationReg |

	minuendReg := operands at: 0.
	factor1Reg := operands at: 1.
	factor2Reg := operands at: 2.
	destinationReg := operands at: 3.
		
	self
		machineCodeAt: 0
		put:(
			self
				msubSize: 1
				minuendReg: minuendReg
				factor1Reg: factor1Reg
				factor2Reg: factor2Reg
				destinationRegister: destinationReg).
	
	^ machineCodeSize := 4	

]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> concretizeMUL [
	
	| registerA destinationRegister registerB |
	registerA := operands at: 0.
	registerB := destinationRegister := operands at: 1.
	
	self
		machineCodeAt: 0
		put: (self
			mulSize: 1
			firstRegister: registerA
			secondRegister: registerB
			destinationRegister: destinationRegister).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveAbR [
	"Will get inlined into concretizeAt: switch."

	<inline: true>
	| srcAddr destReg instrOffset |
	srcAddr := operands at: 0.
	destReg := operands at: 1.
	(self isAddressRelativeToVarBase: srcAddr) ifTrue: [ | offset |
		offset := srcAddr - cogit varBaseAddress.
		self assert: (offset bitAnd: 16rfff) = offset.
		self
			machineCodeAt: 0
			put: (self
				ldrbSourceRegister: ConcreteVarBaseReg
				destinationRegister: destReg
				offset: srcAddr - cogit varBaseAddress).
		^ machineCodeSize := 4 ].

	"load the address into ConcreteIPReg"
	instrOffset := self moveCw: srcAddr intoR: ConcreteIPReg.
	self
		machineCodeAt: instrOffset
		put:
			(self
				ldrbSourceRegister: ConcreteIPReg
				destinationRegister: destReg).
	^ machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveAwR [
	"Will get inlined into concretizeAt: switch."

	<inline: true>
	| srcAddr destReg instrOffset |
	srcAddr := operands at: 0.
	destReg := operands at: 1.
	(self isAddressRelativeToVarBase: srcAddr) ifTrue: [ | actualDestination |
		actualDestination := destReg = SP
			ifTrue: [ ConcreteIPReg ]
			ifFalse: [ destReg ].
		self
			machineCodeAt: 0
			put: (self
				ldrSize: 1
				baseRegister: ConcreteVarBaseReg
				unsignedOffset: srcAddr - cogit varBaseAddress
				destinationRegister: actualDestination).
		machineCodeSize := 4.
			
		destReg = SP ifTrue: [ 
			self machineCodeAt: 4 put: (self movToFromSP: SP rn: actualDestination).
			machineCodeSize := machineCodeSize + 4.
		].

		^ machineCodeSize ].
	
	"load the address into ConcreteIPReg"
	instrOffset := self moveCw: srcAddr intoR: ConcreteIPReg.
	self
		machineCodeAt: instrOffset
		put: (self ldurSize: 1
			baseRegister: ConcreteIPReg
			signedOffset: 0
			destinationRegister: ConcreteIPReg).
	self
		machineCodeAt: instrOffset + 4
		put: (self movSize: 1 sourceRegisterMaybeSP: ConcreteIPReg destinationRegisterMaybeSP: destReg).
	^ machineCodeSize := instrOffset + 8
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveC32R [

	<doNotGenerate>
	self subclassResponsibility 
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveCqR [
	"Will get inlined into concretizeAt: switch."

	"If the quick constant is in fact a shiftable 8bit, generate the apropriate MOV, otherwise do what is necessary for a whole word."

	<inline: true>

	^ self concretizeMoveC32R
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveCwR [
	"Will get inlined into concretizeAt: switch."

	<inline: true>
	^ machineCodeSize := self loadCwInto: (operands at: 1)
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveM16rR [
	"Will get inlined into concretizeAt: switch."

	"ldrh destReg, [srcReg, #immediate],
	or 
	move offset to ConcreteIPReg
	ldrh destReg, [srcReg, ConcreteIPReg]"

	<var: #offset type: #sqInt>
	<inline: true>
	| baseRegister offset destReg |
	offset := operands at: 0.
	baseRegister := operands at: 1.
	destReg := operands at: 2.

	(offset >= 0 and: [ (offset / 2 bitAnd: 16rFFF) = (offset / 2)]) 
		ifTrue: [ self
				machineCodeAt: 0
				put:
					(self
						ldrhBaseRegister: baseRegister
						offsetDividedBy2: offset / 2
						destinationRegister: destReg).
			^ machineCodeSize := 4  ].
	
	self notYetImplemented.
	
	^0
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveM32rR [
	"Will get inlined into concretizeAt: switch."

	<var: #offset type: #sqInt>
	<inline: true>
	| srcReg offset destReg instrOffset |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.

	"If it is a positive 12 bit value this can be encoded as a LDR with a positive 12bit offset"
	(offset >= 0 and: [ (offset bitAnd: 16rFFF) = offset ]) ifTrue: [
		self
			machineCodeAt: 0
			put:
				(self
					ldrSize: 0"is32Bits"
					baseRegister: srcReg
					unsignedOffset: offset
					destinationRegister: destReg).
		^ machineCodeSize := 4
	].
	
	"If it is negative, maybe we can encode it as a LDUR signed 9bit offset"
	self
		is9BitValue: offset
		ifTrue: [ :immediate | 
			self
				machineCodeAt: 0
				put:
					(self
						ldurSize: 0 "32bits"
						baseRegister: srcReg
						signedOffset: immediate
						destinationRegister: destReg).
			^ machineCodeSize := 4 ]
		ifFalse: [
			"Otherwise, this may be a literal"
			self assert: dependent notNil.
			instrOffset := self moveCw: offset intoR: ConcreteIPReg.
			self
				machineCodeAt: instrOffset
				put: (self ldrSize: 0 "32 bits" indexRegister: ConcreteIPReg baseRegister: srcReg destinationRegister: destReg).
			^ machineCodeSize := instrOffset + 4 ].
		
	^ 0	"to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveM32rRs [
	"Will get inlined into concretizeAt: switch."
	"Load a float from srcReg+offset into FP destReg"

	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	"offset should a 12bit multiple of 8 constant"
	self assert: (offset >> 3 bitAnd: 16rfff) << 3 = offset.
	machineCode
		at: 0
		put: (self
			ldrSize: 2r10 "32bits"
			baseRegister: srcReg
			unsignedOffset: offset / 8
			destinationFloatingPointRegister: destReg
			is128BitVariant: 0).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveM64rRd [
	"Will get inlined into concretizeAt: switch."
	"Load a float from srcReg+offset into FP destReg"

	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	"offset should a 12bit multiple of 8 constant"
	self assert: (offset >> 3 bitAnd: 16rfff) << 3 = offset.
	machineCode
		at: 0
		put: (self
			ldrSize: 2r11 "64bits"
			baseRegister: srcReg
			unsignedOffset: offset / 8
			destinationFloatingPointRegister: destReg
			is128BitVariant: 0).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveMbrR [

	<doNotGenerate>
	self subclassResponsibility 
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveMwrR [
	"Will get inlined into concretizeAt: switch."

	<var: #offset type: #sqInt>
	<inline: true>
	| srcReg offset destReg instrOffset |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.

	"If it is a positive 12 bit value this can be encoded as a LDR with a positive 12bit offset"
	(offset >= 0 and: [ (offset bitAnd: 16rFFF) = offset ]) ifTrue: [
		self
			machineCodeAt: 0
			put:
				(self
					ldrSize: 1"is64Bits"
					baseRegister: srcReg
					unsignedOffset: offset
					destinationRegister: destReg).
		^ machineCodeSize := 4
	].
	
	"If it is negative, maybe we can encode it as a LDUR signed 9bit offset"
	self
		is9BitValue: offset
		ifTrue: [ :immediate | 
			self
				machineCodeAt: 0
				put:
					(self
						ldurSize: 1 "64bits"
						baseRegister: srcReg
						signedOffset: immediate
						destinationRegister: destReg).
			^ machineCodeSize := 4 ]
		ifFalse: [
			"Otherwise, this may be a literal"
			self assert: dependent notNil.
			instrOffset := self moveCw: offset intoR: ConcreteIPReg.
			self
				machineCodeAt: instrOffset
				put: (self ldrSize: 1 indexRegister: ConcreteIPReg baseRegister: srcReg destinationRegister: destReg).
			^ machineCodeSize := instrOffset + 4 ].
		
	^ 0	"to keep Slang happy"
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveRAb [
	"Will get inlined into concretizeAt: switch."

	"LEA ConcreteIPReg
	strb srcReg, [ConcreteIPReg]"

	<inline: true>
	| srcReg destAddr instrOffset |
	srcReg := operands at: 0.
	destAddr := operands at: 1.
	(self isAddressRelativeToVarBase: destAddr)
		ifTrue: [ | offset |
			offset := destAddr - cogit varBaseAddress.
			self assert: (offset bitAnd: 16rfff) = offset.
			self
				machineCodeAt: 0
				put: (self strbSourceRegister: srcReg destinationRegister: ConcreteVarBaseReg offset: offset).
			^ machineCodeSize := 4 ].
	"load the address into ConcreteIPReg"
	instrOffset := self moveCw: destAddr intoR: ConcreteIPReg.
	"We *could* overwrite the last instruction above with a LDR a, b, last-byte-of-srcAddr BUT that would break if we change to loading literals instead of forming long constants"
	self
		machineCodeAt: instrOffset
		put: (self strbSourceRegister: srcReg destinationRegister: ConcreteIPReg).
	^ machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveRAw [
	"Will get inlined into concretizeAt: switch."

	<inline: true>
	| srcReg destAddr instrOffset actualSourceRegister |
	srcReg := operands at: 0.
	destAddr := operands at: 1.
	(self isAddressRelativeToVarBase: destAddr) ifTrue: [ | actualSourceRegister2 |
		machineCodeSize := 0.
		actualSourceRegister2 := srcReg = SP
			ifTrue: [ 
				self
					machineCodeAt: 0
					put: (self movToFromSP: ConcreteIPReg rn: SP).
				machineCodeSize := 4.
				ConcreteIPReg ]
			ifFalse: [ srcReg ].

		self
			machineCodeAt: machineCodeSize
			put:
				(self
					strSize: 1
					baseRegister: ConcreteVarBaseReg
					positiveOffset: destAddr - cogit varBaseAddress
					destinationRegister: actualSourceRegister2).
		^ machineCodeSize := machineCodeSize + 4 ].

	"load the address into ConcreteIPReg"
	instrOffset := self moveCw: destAddr intoR: ConcreteIPReg.
	
	actualSourceRegister := srcReg = SP
		ifTrue: [ 
				self
					machineCodeAt: instrOffset
					put: (self movToFromSP: ConcreteIPReg2 rn: SP).
				instrOffset := instrOffset + 4.
				ConcreteIPReg2 ]
		ifFalse: [ srcReg ].
	
	self
		machineCodeAt: instrOffset
		put: (self strSize: 1 baseRegister: ConcreteIPReg positiveOffset: 0 destinationRegister: actualSourceRegister).
	^ machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveRM16r [

	<var: #offset type: #sqInt>
	<inline: true>
	| srcReg offset baseReg instrOffset |
	srcReg := operands at: 0.
	offset := operands at: 1.
	baseReg := operands at: 2.

	self assert: offset >= 0.
	self assert: offset \\ 2 = 0.

	self
		is12BitValue: offset / 2 
		ifTrue: [ :u :immediate | 
			self
				machineCodeAt: 0
				put: (self strhSourceRegister: srcReg destinationRegister: baseReg offset: offset / 2).
			^ machineCodeSize := 4 ]
		ifFalse: [ 
			self notYetImplemented.
			^ machineCodeSize := instrOffset + 4 ].
	^ 0	"to keep Slang happy"
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> concretizeMoveRM32r [

	<doNotGenerate>
	self subclassResponsibility 
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveRMbr [
	"Will get inlined into concretizeAt: switch."

	<var: #offset type: #sqInt>
	<inline: true>
	| srcReg offset baseReg |
	
	srcReg := operands at: 0.
	offset := operands at: 1.
	baseReg := operands at: 2.
	
	(offset >= 0 and: [ (offset bitAnd: 16rFFF) = offset]) 
		ifTrue: [ self
				machineCodeAt: 0
				put:
					(self strbSourceRegister: srcReg destinationRegister: baseReg offset: offset). 
				^ machineCodeSize := 4 ]
		ifFalse: [ 
			self notYetImplemented.
			^ machineCodeSize := 4  ].
	^ 0	"to keep Slang happy"
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> concretizeMoveRMwr [

	<doNotGenerate>
	self subclassResponsibility 
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveRR [
	"Will get inlined into concretizeAt: switch."

	<inline: true>
	| srcReg destReg instruction |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	instruction := (srcReg = SP or: [ destReg = SP ])
		ifTrue: [ self movToFromSP: destReg rn: srcReg  ]
		ifFalse: [ self mov: destReg rn: srcReg  ].
	self machineCodeAt: 0 put: instruction.
	^ machineCodeSize := 4
]

{ #category : #concretize }
CogARMv8Compiler >> concretizeMoveRRd [

	<inline: true>
	| sourceRegister destinationRegister |
	sourceRegister := operands at: 0.
	destinationRegister := operands at: 1.

	self
		machineCodeAt: 0
		put: (self
			fMoveSize: 1
			fromScalarRegister: sourceRegister
			toDoublePrecisionFloatRegister: destinationRegister).
	^ machineCodeSize := 4
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> concretizeMoveRX32rR [

	"Write the word in R(src) into memory at address (base+4*index)"

	<inline: true>
	| index base src |
	src := operands at: 0.
	index := operands at: 1.	"index is number of *words* = 4* bytes"
	base := operands at: 2.
	
	self
		machineCodeAt: 0
		put: (self
			strSize: 0
			baseRegister: base
			offsetRegister: index
			extension: 3 shift: 1
			storedRegister: src).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveRXbrR [
	"Will get inlined into concretizeAt: switch."

	"Write the word in R(src) into memory at address (base+1*index)"

	<inline: true>
	| index base src |
	src := operands at: 0.
	index := operands at: 1.
	base := operands at: 2.

	self machineCodeAt: 0 put: (self strbBaseRegister: base offsetRegister: index extension: 3 shift: 1 srcRegister: src).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveRXwrR [
	"Will get inlined into concretizeAt: switch."

	"Write the word in R(src) into memory at address (base+8*index)"

	<inline: true>
	| index base src |
	src := operands at: 0.
	index := operands at: 1.	"index is number of *words* = 8* bytes"
	base := operands at: 2.
	"str		src, [base, +index, LSL #2]"
	"cond 011 1100 0 base srcR 00010 00 0 inde"
	
	self
		machineCodeAt: 0
		put: (self
			strSize: 1
			baseRegister: base
			offsetRegister: index
			extension: 3 shift: 1
			storedRegister: src).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveRdM64r [

	"Will get inlined into concretizeAt: switch."

	"Store FP fpReg to dstReg+offset"

	<inline: true>
	| baseRegister offset fpReg |
	fpReg := operands at: 0.
	offset := operands at: 1.
	baseRegister := operands at: 2.

	self assert: offset >= 0.

	self machineCodeAt: 0 put: (self
			 strBaseRegister: baseRegister
			 positiveOffset: offset
			 sourceFloatingPointRegister: fpReg
			 precision: 2r11). "64 bits"
	^ machineCodeSize := 4
]

{ #category : #concretize }
CogARMv8Compiler >> concretizeMoveRdR [
	<inline: true>
	| sourceDoublePrecisionRegister destinationScalerRegister |
	sourceDoublePrecisionRegister := operands at: 0.
	destinationScalerRegister := operands at: 1.

	self
		machineCodeAt: 0
		put: (self
			fMoveSize: 1
			fromDoublePrecisionFloatRegister: sourceDoublePrecisionRegister
			toScalarRegister: destinationScalerRegister).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveRsM32r [

	"Will get inlined into concretizeAt: switch."

	"Store FP fpReg to dstReg+offset"

	<inline: true>
	| baseRegister offset fpReg |
	fpReg := operands at: 0.
	offset := operands at: 1.
	baseRegister := operands at: 2.

	self assert: offset >= 0.

	self machineCodeAt: 0 put: (self
			 strBaseRegister: baseRegister
			 positiveOffset: offset
			 sourceFloatingPointRegister: fpReg
			 precision: 2r10). "32 bits"
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveX32rRR [

	"Will get inlined into concretizeAt: switch."

	"This Instruction as all the memory access should Zero-Extend the value"

	<inline: true>
	| index base dest |
	index := operands at: 0.
	base := operands at: 1.
	dest := operands at: 2.
	
	self machineCodeAt: 0 put: (self
			 ldrSize: 0
			 indexRegister: index
			 option: 2r011 "LSL"
			 scale: 1
			 baseRegister: base
			 destinationRegister: dest). "32bits"

	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveXbrRR [
	"Will get inlined into concretizeAt: switch."

	<inline: true>
	| index base dest |
	index := operands at: 0.
	base := operands at: 1.
	dest := operands at: 2.
	self machineCodeAt: 0 put: (self
		ldrbSourceRegister: base
		offsetRegister: index
		destinationRegister: dest).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMoveXwrRR [
	"Will get inlined into concretizeAt: switch."

	<inline: true>
	| indexRegister baseRegister destinationRegister |
	indexRegister := operands at: 0.
	baseRegister := operands at: 1.
	destinationRegister := operands at: 2.

	self
		machineCodeAt: 0
		put: (
			self
				ldrSize: 1
				indexRegister: indexRegister
				option: 2r011 "LSL"
				scale: 1
				baseRegister: baseRegister
				destinationRegister: destinationRegister).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeMulRdRd [
	"FP multiply regLHS by regRHS and stick result in regLHS"

	<inline: true>
	| registerA registerB destinationRegister |
	registerA := operands at: 0.
	destinationRegister := registerB := operands at: 1.
	machineCode at: 0 put: (self
		fMulFirstRegister: registerA
		secondRegister: registerB
		destinationRegister: destinationRegister).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeNegateR [
	"Will get inlined into concretizeAt: switch."

	<inline: true>
	self machineCodeAt: 0 put: 
		(self negateSize: 1
			sourceRegister: (operands at: 0)
			sourceRegisterShiftType: 0 "LSL"
			sourceRegisterShift: 0 "no shift"
			destinationRegister: (operands at: 0)).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeNop [

	<inline: true>
	self machineCodeAt: 0 put: self nop.
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeOrCqR [
	<var: #val type: #sqInt>
	<inline: true>
	| val rd rn |
	val := operands at: 0.
	
	"Both source and destination register are the same..."
	rn := operands at: 1.
	rd := rn.
	self
		encodeLogicalImmediate: val
		registerSize: 64
		ifPossible: [ :encodedValue |
			self
				machineCodeAt: 0
				put: (self
					orSize: 1
					immediate13bitValue: encodedValue
					sourceRegister: rn
					destinationRegister: rd).
			^ machineCodeSize := 4
		] ifNotPossible: [
			"If this does not fit in a logical immediate value => Try to move it to a register, then AND the registers"
			self moveCw: val intoR: ConcreteIPReg.
			self
				machineCodeAt: 4
				put: (self
					orSize: 1
					shiftedRegister: ConcreteIPReg
					shiftType: 0
					shiftValue: 0
					withRegister: rn
					destinationRegister: rd).
			machineCodeSize := 8 "A move and an AND"
		].
	^ 0	"to keep Slang happy"
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> concretizeOrRR [

	self machineCodeAt: 0 put: (self
			 inclusiveOrSize: 1
			 firstRegister: (operands at: 0)
			 secondRegister: (operands at: 1)
			 destinationRegister: (operands at: 1)).
			
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizePopR [
	"Will get inlined into concretizeAt: switch."

	<inline: true>
	| destReg |
	destReg := operands at: 0.
	"LDR destReg, [SP], #8"
	self machineCodeAt: 0 put: (self popR: destReg).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizePrefetchAw [
	"Will get inlined into concretizeAt: switch."

	<inline: true>
	| addressOperand instrOffset |
	addressOperand := operands at: 0.
	(self isAddressRelativeToVarBase: addressOperand)
		ifTrue: [ | offset |
			offset := addressOperand - cogit varBaseAddress.
			self
				machineCodeAt: 0
				put:
					(self
						prefetchMemory: 0 "prefetchFlags: load in L1 KEEP" 
						sourceRegister: ConcreteVarBaseReg
						offset: addressOperand - cogit varBaseAddress).
			^ machineCodeSize := 4 ].
	
	self notYetImplemented.
	
	instrOffset := self moveCw: addressOperand intoR: ConcreteIPReg.
	"pld	[ConcreteIPReg]"
	self
		machineCodeAt: instrOffset
		put: (self pld: ConcreteIPReg plus: 1 offset: 0).
	^ machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizePushCq [

	"Will get inlined into concretizeAt: switch."
	<var: #word type: #sqInt>
	<inline: true>
	| word instrOffset |
	word := operands at: 0.
	self
		shiftable16bitImmediate: word
		ifTrue: [ :shift :value | 
			self machineCodeAt: 0 put: (self
				movSize: 1
				destinationRegister: ConcreteIPReg
				imm: value
				shift: shift).
				instrOffset := 4 ]
		ifFalse: [ instrOffset := self loadCwInto: ConcreteIPReg ].
	self machineCodeAt: instrOffset put: (self pushR: ConcreteIPReg).
	^ machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizePushCw [

	"Will get inlined into concretizeAt: switch."

	<inline: true>
	| word instrOffset |
	word := operands at: 0.
	instrOffset := self loadCwInto: ConcreteIPReg.
	self machineCodeAt: instrOffset put: (self pushR: ConcreteIPReg).
	^ machineCodeSize := instrOffset + 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizePushR [
	"Will get inlined into concretizeAt: switch."

	<inline: true>
	| srcReg |
	srcReg := operands at: 0.
	"cond | 010 | 1001 | 0 | -Rn- | -Rd- | 0000 0000 0100"	"STR srcReg, [sp, #-4]"
	self machineCodeAt: 0 put: (self pushR: srcReg).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeRetN [
	"Will get inlined into concretizeAt: switch."

	<var: #offset type: #sqInt>
	<inline: true>
	| offset |
	offset := operands at: 0.
	offset = 0
		ifTrue: [ self machineCodeAt: 0 put: self ret.	
			^ machineCodeSize := 4 ].
	self assert: offset < 255.	"We have an 8 bit immediate. If needed, we could rotate it less than 30 bit."
	self
		machineCodeAt: 0
		put: 
			(self
				add: SPReg
				rn: SPReg
				imm: offset
				ror: 0).
	self machineCodeAt: 4 put: self ret.
	^ machineCodeSize := 8
]

{ #category : #concretize }
CogARMv8Compiler >> concretizeRotateLeftCqR [
	<var: #rotation type: #sqInt>
	<inline: true>
	| rotation sourceRegister destinationRegister |
	rotation := operands at: 0.
	destinationRegister := sourceRegister := operands at: 1.
	self machineCodeAt: 0 put: (self
		rorSize: 1
		sourceRegister: sourceRegister
		rotationBits: 64 - rotation "We rotate right by the inverse number of bits..."
		destinationRegister: destinationRegister).
	^ machineCodeSize := 4
]

{ #category : #concretize }
CogARMv8Compiler >> concretizeRotateRightCqR [
	<var: #rotation type: #sqInt>
	<inline: true>
	| rotation sourceRegister destinationRegister |
	rotation := operands at: 0.
	destinationRegister := sourceRegister := operands at: 1.
	self machineCodeAt: 0 put: (self
		rorSize: 1
		sourceRegister: sourceRegister
		rotationBits: rotation
		destinationRegister: destinationRegister).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeSDIV [
	<inline: true>

	| regNumerator regDenominator regDestination |
	regNumerator := operands at: 0.
	regDenominator := operands at: 1. 
	regDestination := operands at: 2.

	self 
		machineCodeAt: 0 
		put: (self
			 sdivSize: 1
			 numeratorReg: regNumerator
			 denominatorReg: regDenominator
			 destinationRegister: regDestination).

	^ machineCodeSize := 4
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> concretizeSMULH [
	
	| registerA destinationRegister registerB |
	registerA := operands at: 0.
	registerB := operands at: 1.
	destinationRegister := operands at: 2.
	
	self
		machineCodeAt: 0
		put: (self
			smulhSize: 1
			firstRegister: registerA
			secondRegister: registerB
			destinationRegister: destinationRegister).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeSqrtRd [
	"Will get inlined into concretizeAt: switch."

	"Square root of FP regLHS into regLHS"

	<inline: true>
	| regLHS |
	
	regLHS := operands at: 0.
	machineCode at: 0 put: (self fSqrtd: regLHS destinationRegister: regLHS).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeStop [
	<inline: true>
	self machineCodeAt: 0 put: self stop.
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeSubCqR [
	"Will get inlined into concretizeAt: switch."

	"Try whether the quick constant is a small negative number. If it is, optimize."

	<var: #word type: #usqInt>
	<inline: true>
	| word fits12Bits reg instrOffset |
	word := operands at: 0.
	reg := operands at: 1.
	
	word < 0 ifTrue: [ 
			self logError: 'Invalid constant'. 
			self abort  ].
	
	fits12Bits := (word bitAnd: 16rfff) = word.
	fits12Bits ifTrue: [
		self
			machineCodeAt: 0
			put:
				(self
					subsSize: 1
					sourceRegister: reg
					immediate12BitValue: word
					shifted: 0
					destinationRegister: reg).
		^ machineCodeSize := 4
	].
	instrOffset := self loadCwInto: ConcreteIPReg.
	self machineCodeAt: 4 put: (self
			subsSize: 1
			leftRegister: reg
			shiftedRightRegister: ConcreteIPReg
			shiftType: 0
			shiftOffset: 0
			destinationRegister: reg).
	^ machineCodeSize := machineCodeSize + 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeSubRR [

	| instruction destReg leftReg rightReg |
	
	"In ARM destReg <- leftReg - rightReg"
	
	leftReg := operands at: 1.
	rightReg := operands at: 0.
	destReg := operands at: 1.

	"If one of the operands is the stack pointer, we need to use the extended version"
	rightReg = SP ifTrue: [ 
		self machineCodeAt: 0 put: (self movToFromSP: ConcreteIPReg rn: SP).
		self machineCodeAt: 4 put: (self
			subsSize: 1
			leftRegister: leftReg
			shiftedRightRegister: ConcreteIPReg
			shiftType: 0
			shiftOffset: 0
			destinationRegister: destReg).

		^ machineCodeSize := 8.		
		 ].
	
	leftReg = SP ifFalse: [ 
		instruction := 	self
			subsSize: 1
			leftRegister: leftReg
			shiftedRightRegister: rightReg
			shiftType: 0
			shiftOffset: 0
			destinationRegister: destReg
	] ifTrue: [
		self notYetImplemented.
		"Maybe this is the implementation.... ??"
		instruction := self
			subsExtendedSize: 1
			leftRegisterMaybeSP: leftReg
			shiftedRightRegister: rightReg
			option: 2r011
			shiftOffset: 0
			destinationRegister: destReg
	].

	self machineCodeAt: 0 put: instruction.
	^machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeSubRdRd [
	"FP substract registerA from registerB and stick result in registerB"

	<inline: true>
	| registerA registerB destinationRegister |
	registerA := operands at: 0.
	destinationRegister := registerB := operands at: 1.
	machineCode at: 0 put: (self
		fSubFirstRegister: registerB
		secondRegister: registerA
		destinationRegister: destinationRegister).
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeTstCqR [
	"Will get inlined into concretizeAt: switch."
	<var: #word type: #sqInt>
	<inline: true>
	| word |
	word := operands at: 0.
	self
		encodeLogicalImmediate: word
		registerSize: 64
		ifPossible: [ :immediate13LogicalValue |
			self
				machineCodeAt: 0
				put: (self tstSize: 1 immediate13bitValue: immediate13LogicalValue register: (operands at: 1)).
			^ machineCodeSize := 4 ]
		ifNotPossible: [ self notYetImplemented ].
	^ 0	"to keep Slang happy"
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> concretizeXorCwR [

	self moveCw: (operands at: 0) intoR: ConcreteIPReg.
	self
		machineCodeAt: machineCodeSize
		put: (self
				exclusiveOrSize: 1
				firstRegister: ConcreteIPReg
				secondRegister: (operands at: 1)
				destinationRegister: ConcreteIPReg).
	^ machineCodeSize := machineCodeSize + 4
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> concretizeXorRR [

	| registerOne registerTwo |
	registerOne := operands at: 0.
	registerTwo := operands at: 1.

	self machineCodeAt: 0 put: (self
			 exclusiveOrSize: 1
			 firstRegister: registerOne
			 secondRegister: registerTwo
			 destinationRegister: registerTwo).
			
	^ machineCodeSize := 4
]

{ #category : #'generate machine code - concretize' }
CogARMv8Compiler >> concretizeXorRdRd [
	"FP XOR registerA by registerB and stick result in registerB"

	<inline: true>
	| registerA registerB destinationRegister |
	registerA := operands at: 0.
	destinationRegister := registerB := operands at: 1.

	machineCode at: 0 put: (self
		fEorFirstRegister: registerA
		secondRegister: registerB
		destinationRegister: destinationRegister).
	^ machineCodeSize := 4
]

{ #category : #encoding }
CogARMv8Compiler >> cond: c br: link offset: offset [
	"c : 4 bit, opcode = 10 bitOr: link, offset >>2, limited to 24 bits (which are sign-extended, shifted left 2 and added to 8 + pc to make the resulting address)"
	"single instr Branch, no link"
	<inline: true>
	^ c << 28 bitOr: (((2r1010 bitOr: (link bitAnd: 1)) << 24) bitOr: (offset >> 2 bitAnd: 16r00FFFFFF))
]

{ #category : #encoding }
CogARMv8Compiler >> cond: c bx: link target: targetReg [
	"c : 4 bit, opcode = 10 bitOr: link, offset >>2, limited to 24 bits (which are sign-extended, shifted left 2 and added to 8 + pc to make the resulting address)"
	"BX targetReg or BLX targetReg"
	<inline: true>
	^ c << 28 bitOr: ( (16r12FFF10  bitOr: (link bitAnd: 1) <<5 ) bitOr: targetReg)
]

{ #category : #encoding }
CogARMv8Compiler >> cond: conditionCode type: type op: flagsOrOpcode set: doUpdateStatusRegister rn:  sourceRegister rd: targetRegister [
"build an instruction - cccctttoooo + source + target"
	<inline: true>
	^(self cond: conditionCode type: type op: flagsOrOpcode set: doUpdateStatusRegister) 
		bitOr: (sourceRegister << 16 bitOr: targetRegister << 12)
]

{ #category : #encoding }
CogARMv8Compiler >> cond: conditionCode type: type op: flagsOrOpcode set: doUpdateStatusRegister rn:  sourceRegister rd: targetRegister shifterOperand: so [
"build an instruction - cccctttoooo + source + target + shifter op"
	<inline: true>
	^(self cond: conditionCode type: type op: flagsOrOpcode set: doUpdateStatusRegister rn: sourceRegister rd: targetRegister) bitOr: (so bitAnd: 16rFFF)
]

{ #category : #testing }
CogARMv8Compiler >> conditionIsNotNever: instr [
	"test for the NV condition code; this isn't allowed as an actual condition and is used to encdoe many of the newer instructions"
	^instr >> 28 < 16rF 
]

{ #category : #accessing }
CogARMv8Compiler >> conditionOrNil [
"has to be named oddly like this to satisfay i-var code gen translating rules"
	^conditionOrNil
]

{ #category : #accessing }
CogARMv8Compiler >> conditionOrNil: condCode [
"has to be named oddly like this to satisfay i-var code gen translating rules"
	^conditionOrNil := condCode
]

{ #category : #'generate machine code' }
CogARMv8Compiler >> dispatchConcretize [
	"Attempt to generate concrete machine code for the instruction at address.
	 This is the inner dispatch of concretizeAt: actualAddress which exists only
	 to get around the branch size limits in the SqueakV3 (blue book derived)
	 bytecode set."
	<returnTypeC: #void>
	conditionOrNil ifNotNil:
		[self error: 'ARMv8 / aarch64 does not support conditions encoded in the instruction'.
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
		[JumpLong]					-> [^self concretizeJumpLong]."jumps witihn code space"
		[JumpLongZero]			-> [^self concretizeJumpLongZero].
		[JumpLongNonZero]		-> [^self concretizeJumpLongNonZero].
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
		[AndCqR]					-> [^self concretizeAndCqR].
		[AndCqRR]					-> [^self concretizeAndCqRR].
		[CmpCqR]					-> [^self concretizeCmpCqR].
		[OrCqR]						-> [^self concretizeOrCqR].
		[SubCqR]					-> [^self concretizeSubCqR].
		[TstCqR]					-> [^self concretizeTstCqR].
		[XorCqR]					-> [^self concretizeInvertibleDataOperationCqR: XorOpcode].
		[AddCwR]					-> [^self concretizeDataOperationCwR: AddOpcode].
		[AndCwR]					-> [^self concretizeDataOperationCwR: AndOpcode].
		[CmpCwR]					-> [^self concretizeCmpCwR].
		[CmpC32R]					-> [^self concretizeCmpC32R].
		[OrCwR]					-> [^self concretizeDataOperationCwR: OrOpcode].
		[SubCwR]					-> [^self concretizeDataOperationCwR: SubOpcode].
		[XorCwR]					-> [^self concretizeXorCwR].
		[AddRR]						-> [^self concretizeAddRR].
		[AndRR]						-> [^self concretizeAndRR].
		[CmpRR]					-> [^self concretizeCmpRR].
		[OrRR]						-> [^self concretizeOrRR].
		[SubRR]						-> [^self concretizeSubRR].
		[XorRR]						-> [^self concretizeXorRR].

		"Floating point operations"
	
		[AddRdRd]					-> [^self concretizeAddRdRd].
		[CmpRdRd]					-> [^self concretizeCmpRdRd].
		[DivRdRd]					-> [^self concretizeDivRdRd].
		[MulRdRd]					-> [^self concretizeMulRdRd].
		[SubRdRd]					-> [^self concretizeSubRdRd].
		[SqrtRd]					-> [^self concretizeSqrtRd].
		[XorRdRd]					-> [^self concretizeXorRdRd].

		[NegateR]						-> [^self concretizeNegateR].
		[LoadEffectiveAddressMwrR]	-> [^self concretizeLoadEffectiveAddressMwrR].
		[ArithmeticShiftRightCqR]		-> [^self concretizeArithmeticShiftRightCqR].
		[LogicalShiftRightCqR]			-> [^self concretizeLogicalShiftRightCqR].
		[LogicalShiftLeftCqR]			-> [^self concretizeLogicalShiftLeftCqR].
		[ArithmeticShiftRightRR]			-> [^self concretizeArithmeticShiftRightRR].
		[LogicalShiftLeftRR]				-> [^self concretizeLogicalShiftLeftRR].
		[LogicalShiftRightRR]			-> [^self concretizeLogicalShiftRightRR].
		[RotateLeftCqR]					->	[^self concretizeRotateLeftCqR].
		[RotateRightCqR]				->	[^self concretizeRotateRightCqR].

		"ARM Specific Arithmetic" 
		[MUL]			-> [^self concretizeMUL].
		[SMULH]			-> [^self concretizeSMULH].
		[CMPMULOverflow]		-> [^self concretizeCMPMULOverflow].
		[SDIV]				-> [^self concretizeSDIV].
		[MSUB]				-> [^self concretizeMSUB].
		"Data Movement"
		[MoveCqR]			-> [^self concretizeMoveCqR].
		[MoveCwR]			-> [^self concretizeMoveCwR].
		[MoveC32R]		-> [^self concretizeMoveC32R].
		[MoveRR]			-> [^self concretizeMoveRR].
		[MoveAwR]			-> [^self concretizeMoveAwR].
		[MoveRAw]			-> [^self concretizeMoveRAw].
		[MoveAbR] 			 -> [^self concretizeMoveAbR].
 		[MoveRAb]			-> [^self concretizeMoveRAb].
		[MoveMbrR]			-> [^self concretizeMoveMbrR].
		[MoveRMbr]			-> [^self concretizeMoveRMbr].
		[MoveRM8r]			-> [^self concretizeMoveRMbr].
		[MoveRM16r]		-> [^self concretizeMoveRM16r].
		[MoveM16rR]		-> [^self concretizeMoveM16rR].
		[MoveM32rRs]		-> [^self concretizeMoveM32rRs].
		[MoveM64rRd]		-> [^self concretizeMoveM64rRd].
		[MoveM32rR]		-> [^self concretizeMoveM32rR].
		[MoveMwrR]		-> [^self concretizeMoveMwrR].
		[MoveXbrRR]		-> [^self concretizeMoveXbrRR].
		[MoveRXbrR]		-> [^self concretizeMoveRXbrR].
		[MoveX32rRR]		-> [^self concretizeMoveX32rRR].
		[MoveRX32rR]		-> [^self concretizeMoveRX32rR].
		[MoveXwrRR]		-> [^self concretizeMoveXwrRR].
		[MoveRXwrR]		-> [^self concretizeMoveRXwrR].
		[MoveRM32r]		-> [^self concretizeMoveRM32r].
		[MoveRMwr]		-> [^self concretizeMoveRMwr].
		[MoveRsM32r]		-> [^self concretizeMoveRsM32r].
		[MoveRdM64r]		-> [^self concretizeMoveRdM64r].
		[PopR]				-> [^self concretizePopR].
		[PushR]				-> [^self concretizePushR].
		[PushCq]			-> [^self concretizePushCq].
		[PushCw]			-> [^self concretizePushCw].
		[PrefetchAw]		-> [^self concretizePrefetchAw].
		"Conversion"
		[ConvertRdRs]		-> [^self concretizeConvertRdRs].
		[ConvertRsRd]		-> [^self concretizeConvertRsRd].
		[ConvertRRd]		-> [^self concretizeConvertRRd].
		[MoveRdR]			-> [^self concretizeMoveRdR].
		[MoveRRd]			-> [^self concretizeMoveRRd].
		
		"Patcheable literal instruction"
		[ MovePatcheableC32R ] -> [ ^ self concretizeMovePatcheableC32R ]
		}
]

{ #category : #'immediate-encodings' }
CogARMv8Compiler >> encodeLogicalImmediate: immediate registerSize: registerSize ifPossible: aBlockWithEncoding ifNotPossible: aNotPossibleBlock [

	"https://github.com/llvm-mirror/llvm/blob/5c95b810cb3a7dee6d49c030363e5bf0bb41427e/lib/Target/AArch64/MCTargetDesc/AArch64AddressingModes.h#L213
	
	https://dinfuehr.github.io/blog/encoding-of-immediate-values-on-aarch64/
	"
	<inline: #always>
	<var: #immediate type: 'uint64_t'>
	<var: #maskedImmediate type: 'uint64_t'>

	<var: #size type: 'uint64_t'>
	<var: #trailingZeros type: #'uint32_t'>
	<var: #trailingOnes type: #'uint32_t'>
	<var: #mask type: #'uint64_t'>
	<var: #leadingOnes type: #'uint32_t'>
	<var: #immr type: #'uint32_t'>
	<var: #nimms type: #'uint64_t'>
	<var: #n type: #'uint32_t'>

	| size mask maskedImmediate trailingZeros trailingOnes leadingOnes immr nimms n |

	(immediate = 0 or: [ 
		immediate = 0 bitInvert64
			or: [ registerSize ~= 64
				and: [ (immediate >> registerSize) ~= 0
					or: [ immediate == 0 bitInvert32 ] ] ] ])
		ifTrue: [ ^ aNotPossibleBlock value ].

	size := self sizeOf: immediate registerSize: registerSize.
	mask := 16rFFFFFFFFFFFFFFFF >> (64 - size).
	
	maskedImmediate := immediate bitAnd: mask.
	
	(self isShiftedMask: maskedImmediate) ifTrue: [
		trailingZeros := self trailingZerosOf: maskedImmediate.
		trailingOnes := self trailingOnesOf: (maskedImmediate >> trailingZeros).
	] ifFalse: [
	   maskedImmediate := maskedImmediate bitOr: mask bitInvert64.
		(self isShiftedMask: maskedImmediate bitInvert64)
			ifFalse: [ ^ aNotPossibleBlock value ].

		leadingOnes := self leadingOnesOf: maskedImmediate.
		trailingZeros := 64 "bits" - leadingOnes.
		trailingOnes := leadingOnes + (self trailingOnesOf: maskedImmediate) - (64 - size)
	].

	immr := (size - trailingZeros) bitAnd: (size - 1).
	nimms := (size-1) bitInvert64 << 1 bitAnd: 16rFFFFFFFFFFFFFFFF.
	nimms := nimms bitOr: trailingOnes - 1.
	
	n := ((nimms >> 6) bitAnd: 1) bitXor: 1.
	
	^ aBlockWithEncoding value: ((n << 12) bitOr: (immr << 6 bitOr: (nimms bitAnd: 16r3f)))
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> exclusiveOrSize: is64Bits firstRegister: firstRegister secondRegister: secondRegister destinationRegister: destinationRegister [
	
	"C6.2.86 EOR (shifted register)
	
	Bitwise Exclusive OR (shifted register) performs a bitwise Exclusive OR of a register value and an optionally-shifted register value, and writes the result to the destination register.
	
	EOR <Xd>, <Xn>, <Xm>{, <shift> #<amount>}"
	
	^ self
		logicalShiftedRegisterSize: is64Bits
		opcode: 2r10
		firstRegister: firstRegister
		shiftedRegister: secondRegister
		shiftOption: 0 "LSL"
		shiftValue: 0
		negated: 0
		destinationRegister: destinationRegister
]

{ #category : #assembler }
CogARMv8Compiler >> exclusiveOrSize: is64Bits immediate13bitValue: logicalEncodedImmediate13BitValue sourceRegister: sourceRegister destinationRegister: destinationRegister [
	
	"C6.2.85 EOR (immediate)
	
	Bitwise Exclusive OR (immediate) performs a bitwise Exclusive OR of a register value and an immediate value, and writes the result to the destination register.
	
	EOR <Xd|SP>, <Xn>, #<imm>"
	
	^ self
		logicalImmediate: is64Bits
		opcode: 2r10
		immediate13bitValue: logicalEncodedImmediate13BitValue
		sourceRegister: sourceRegister
		destinationRegister: destinationRegister
]

{ #category : #patching }
CogARMv8Compiler >> extractConditionFromB: instruction [ 
	
	"Extract the offset inside a branch instruction of the formformat: 
	
	C6.2.25 B.cond
	
	Branch conditionally to a label at a PC-relative offset, with a hint that this is not a subroutine call or return.
	
	B.<cond> <label>
	
	The condition is encoded as the last 4 bits"
	self seeAlso: #branchCondition:offset:.
	
	^ instruction bitAnd: 16rf.
]

{ #category : #patching }
CogARMv8Compiler >> extractOffsetFromBL: instr [
	"we are told this is a BL <offset> instruction, so work out the offset it encodes.
	
	Its offset from the address of this instruction, in the range +/-128MB, is encoded as imm26 times 4.
	So extract the immediate, and multiply it by 4.
	If negative, sign extend it."
	<inline: true>
	| relativeJump |
	relativeJump := instr bitAnd: 16r03FFFFFF.
	relativeJump := (relativeJump allMask: 1<<25)
						ifTrue: [(relativeJump bitOr: 16rFC000000) signedIntFromLong * 4]
						ifFalse: [relativeJump << 2].
	^relativeJump
]

{ #category : #patching }
CogARMv8Compiler >> extractOffsetFromConditionalBranch: instruction [ 
	
	"Extract the offset inside a branch instruction of the formformat: 
	
	C6.2.25 B.cond
	
	Branch conditionally to a label at a PC-relative offset, with a hint that this is not a subroutine call or return.
	
	B.<cond> <label>
	
	The offset is encoded as an immediate of 19 bits that should be multiplied by 4 => so we do it by shifting it by 2
	"
	| twoComplement |
	self seeAlso: #branchCondition:offset:.
	
	twoComplement := instruction >> 5 bitAnd: 16r7FFFF.
	
	"Check if negative, if the highest bit is on"
	^ (twoComplement allMask: 1 << 18)
		ifTrue: [ self notYetImplemented  ]
		ifFalse: [ twoComplement << 2 ]
]

{ #category : #assembler }
CogARMv8Compiler >> fConvertSourceRegister: sourceRegister toRegister: destRegister sourcePrecision: ftype toPrecision: opc [ 
	
	"C7.2.69 FCVT
	
	Floating-point Convert precision (scalar). This instruction converts the floating-point value in the SIMD&FP source register to the precision for the destination register data type using the rounding mode that is determined by the FPCR and writes the result to the SIMD&FP destination register.
	
	FCVT <Dd>, <Sn>
	"
	
	^ 2r1111 << 25
		bitOr: ((ftype bitAnd: 2r11) << 22
		bitOr: (2r10001 << 17
		bitOr: ((opc bitAnd: 2r11) << 15
		bitOr: (2r1 << 14
		bitOr: ((sourceRegister bitAnd: 16r1f) << 5
		bitOr: ((destRegister bitAnd: 16r1f)))))))

]

{ #category : #assembler }
CogARMv8Compiler >> fDivFirstRegister: registerA secondRegister: registerB destinationRegister: destinationRegister [ 

	"C7.2.98 FDIV (scalar)
	
	Floating-point Divide (scalar). This instruction divides the floating-point value of the first source SIMD&FP register by the floating-point value of the second source SIMD&FP register, and writes the result to the destination SIMD&FP register.
	
	FDIV <Dd>, <Dn>, <Dm>"
	
	^ 2r1111 << 25
		bitOr: (2r01 "double precision variant only" << 22
		bitOr: (2r1 << 21
		bitOr: (((registerB bitAnd: 16r1f) << 16)
		bitOr: (2r11 << 11
		bitOr: (((registerA bitAnd: 16r1f) << 5)
		bitOr: (destinationRegister bitAnd: 16r1f))))))
]

{ #category : #assembler }
CogARMv8Compiler >> fEorFirstRegister: registerA secondRegister: registerB destinationRegister: destinationRegister [ 

	"C7.2.41 EOR (vector)
	
	Bitwise Exclusive OR (vector). This instruction performs a bitwise Exclusive OR operation between the two source SIMD&FP registers, and places the result in the destination SIMD&FP register.
	
	EOR <Vd>.<T>, <Vn>.<T>, <Vm>.<T> (We only implemented for 64 bits double precision)"
	
	^ 2r101110001 << 21
		bitOr: (((registerB bitAnd: 16r1f) << 16)
		bitOr: (2r111 << 10
		bitOr: (((registerA bitAnd: 16r1f) << 5)
		bitOr: (destinationRegister bitAnd: 16r1f))))	
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> fMoveSize: is64Bits fromDoublePrecisionFloatRegister: sourceDoublePrecisionFloatRegister toScalarRegister: destinationScalarRegister [
	
	^ self
		fMoveSize: is64Bits
		fromScalarToDoublePrecision: 0
		sourceRegister: sourceDoublePrecisionFloatRegister
		destinationRegister: destinationScalarRegister
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> fMoveSize: is64Bits fromScalarRegister: sourceScalarRegister toDoublePrecisionFloatRegister: destinationDoublePrecisionFloatRegister [
	
	^ self
		fMoveSize: is64Bits
		fromScalarToDoublePrecision: 1
		sourceRegister: sourceScalarRegister
		destinationRegister: destinationDoublePrecisionFloatRegister
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> fMoveSize: is64Bits fromScalarToDoublePrecision: fromScalarToDoublePrecision sourceRegister: sourceRegister destinationRegister: destinationRegister [
	
	"C7.2.131 FMOV (general)
	
	Floating-point Move to or from general-purpose register without conversion. This instruction transfers the contents of a SIMD&FP register to a general-purpose register, or the contents of a general-purpose register to a SIMD&FP register.
	
	Double-precision to 64-bit variant
	FMOV <Xd>, <Dn>"
	
	^ (is64Bits bitAnd: 1) << 31
		bitOr: (2r1111 << 25
		bitOr: (2r01 "ftype" << 22
		bitOr: (2r10011 << 17
		bitOr: ((fromScalarToDoublePrecision bitAnd: 1) << 16
		bitOr: ((sourceRegister bitAnd: 16r1f) << 5
		bitOr: ((destinationRegister bitAnd: 16r1f)))))))
]

{ #category : #assembler }
CogARMv8Compiler >> fMulFirstRegister: registerA secondRegister: registerB destinationRegister: destinationRegister [ 
	
	"C7.2.136 FMUL (Scalar)
	
	Floating-point Multiply (scalar). This instruction multiplies the floating-point values of the two source SIMD&FP registers, and writes the result to the destination SIMD&FP register.
	
	FMUL <Dd>, <Dn>, <Dm>"
	
	^ 2r1111 << 25
		bitOr: (2r01 "double precision variant only" << 22
		bitOr: (2r1 << 21
		bitOr: (((registerB bitAnd: 16r1f) << 16)
		bitOr: (2r1 << 11
		bitOr: (((registerA bitAnd: 16r1f) << 5)
		bitOr: (destinationRegister bitAnd: 16r1f))))))
]

{ #category : #assembler }
CogARMv8Compiler >> fSqrtd: sourceRegister destinationRegister: destinationRegister [

	"C7.2.172 FSQRT (scalar)
	
	Floating-point Square Root (scalar). This instruction calculates the square root of the value in the SIMD&FP source register and writes the result to the SIMD&FP destination register.

	FSQRT <Dd>, <Dn>
	"

	^ 2r1111 << 25
		bitOr: (2r01 "double precision variant only" << 22
		bitOr: (2r1 << 21
		bitOr: (2r111 << 14
		bitOr: (((sourceRegister bitAnd: 16r1f) << 5)
		bitOr: (destinationRegister bitAnd: 16r1f)))))
]

{ #category : #assembler }
CogARMv8Compiler >> fSubFirstRegister: registerA secondRegister: registerB destinationRegister: destinationRegister [

	"C7.2.174 FSUB (scalar)
	
	Floating-point Subtract (scalar). This instruction subtracts the floating-point value of the second source SIMD&FP register from the floating-point value of the first source SIMD&FP register, and writes the result to the destination SIMD&FP register.
	
	FSUB <Dd>, <Dn>, <Dm>"
	
	^ 2r1111 << 25
		bitOr: (2r01 "double precision variant only" << 22
		bitOr: (2r1 << 21
		bitOr: (((registerB bitAnd: 16r1f) << 16)
		bitOr: (2r111 << 11
		bitOr: (((registerA bitAnd: 16r1f) << 5)
		bitOr: (destinationRegister bitAnd: 16r1f))))))
]

{ #category : #assembler }
CogARMv8Compiler >> faddSize: precision firstSourceRegister: registerA secondSourceRegister: registerB destinationRegister: destinationRegister [ 

		"C7.2.50 FADD (scalar)
	
	Floating-point Add (scalar). This instruction adds the floating-point values of the two source SIMD&FP registers, and writes the result to the destination SIMD&FP register.
	
	FADD <Dd>, <Dn>, <Dm>"
	
	^ 2r11110 << 24
		bitOr: ((precision bitAnd: 2r11) << 22
		bitOr: (2r1 << 21
		bitOr: (((registerB bitAnd: 16r1f) << 16)
		bitOr: (2r101 << 11
		bitOr: (((registerA bitAnd: 16r1f) << 5)
		bitOr: (destinationRegister bitAnd: 16r1f))))))
]

{ #category : #assembler }
CogARMv8Compiler >> fcmpFType: ftype leftRegister: firstRegister rightRegister: secondRegister [
	
	"C7.2.66 FCMP
	
	Floating-point quiet Compare (scalar). This instruction compares the two SIMD&FP source register values, or the first SIMD&FP source register value and zero. It writes the result to the PSTATE.{N, Z, C, V} flags.

	Double-precision variant
	FCMP <Dn>, <Dm>
	
	ftype:
		11 => half precision
		00 => single precision
		01 => double precision"
		
	^ 2r1111 << 25
		bitOr: ((ftype bitAnd: 2r11) << 22
		bitOr: (1 << 21
		bitOr: ((secondRegister bitAnd: 16r1f) << 16
		bitOr: (1 << 13
		bitOr: ((firstRegister bitAnd: 16r1f) << 5)))))
]

{ #category : #'ARM convenience instructions' }
CogARMv8Compiler >> fldd: destReg rn: srcReg plus: u imm: immediate8bitValue [
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
CogARMv8Compiler >> fmsrFrom: regA to: regB [
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
CogARMv8Compiler >> fmstat [
	"FMSTAT or VMRS unconditional transfer FP status to cpsr to choose jumps etc.
FMSTAT r15, FPSCR - ARM_ARM v5 DDI 01001.pdf pp. C4-72
VMRS APSR_nzcv, FPSCR - ARM_ARM v7 DDI10406 pp. A8-652-3"
	<inline: true>
	^2r11101110111100011111101000010000
]

{ #category : #'ARM convenience instructions' }
CogARMv8Compiler >> fmuld: destReg with: srcReg [
"FMULD or VMUL instruction to multiply double srcReg by double destReg and stick result in double destReg
FMULD destReg, destReg, srcReg - ARM_ARM v5 DDI 01001.pdf pp. C4-73
VMUL.F64 destReg, destReg, srcReg - ARM_ARM v7 DDI10406 pp A8-658-9"
	<inline: true>
	^((2r11101110001000000000101100000000 bitOr: destReg<<16 ) bitOr: destReg<<12) bitOr: srcReg
]

{ #category : #'ARM convenience instructions' }
CogARMv8Compiler >> fsitodFrom: regA to: regB [
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
CogARMv8Compiler >> fstd: fpReg rn: addrReg plus: u imm: immediate8bitValue [
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
CogARMv8Compiler >> fsubd: destReg with: srcReg [
"FSUBD or VSUB instruction to subtract double srcReg from double destREg and stick result in double destReg
FSUBD destReg, destReg, srcReg - ARM_ARM v5 DDI 01001.pdf pp. C4-112
VSUB.F64 destReg, destReg, srcReg - ARM_ARM v7 DDI10406 pp. A8-784-5"
	<inline: true>
	^((2r11101110001100000000101101000000 bitOr: destReg<<16 ) bitOr: destReg<<12) bitOr: srcReg
]

{ #category : #abi }
CogARMv8Compiler >> fullCallsAreRelative [
	"Answer if CallFull and/or JumpFull are relative and hence need relocating on method
	 compation. If so, they are annotated with IsRelativeCall in methods and relocated in
	 relocateIfCallOrMethodReference:mcpc:delta:"
	^false
]

{ #category : #abi }
CogARMv8Compiler >> genCaptureCStackPointers: captureFramePointer [

	"Save the register to a caller-saved register.
	The caller may have been using the same register for something else.
	So we need to save it and restore it later.
	Make sure to reuse a caller-saved register: we can reuse it freely"
	self hasVarBaseRegister ifTrue:
		[cogit
			MoveR: VarBaseReg R: R1;
			MoveCq: cogit varBaseAddress R: VarBaseReg].
	captureFramePointer ifTrue:
		[cogit MoveR: FPReg Aw: cogit cFramePointerAddress].

	"Capture the stack pointer prior to the call"
	cogit MoveR: self cStackPointer Aw: cogit cStackPointerAddress.
	
	"Restore the base register for our caller"
	self hasVarBaseRegister ifTrue:
		[cogit MoveR: R1 R: VarBaseReg].

	cogit RetN: 0.
]

{ #category : #'abstract instructions' }
CogARMv8Compiler >> genDivR: abstractRegDenominator R: abstractRegNumerator Quo: abstractRegQuotient Rem: abstractRegRemainder [

	cogit gen: SDIV operand: abstractRegNumerator operand: abstractRegDenominator operand: ConcreteIPReg.
	cogit gen: MSUB operand: abstractRegNumerator operand: ConcreteIPReg operand: abstractRegDenominator operand: abstractRegRemainder.
	cogit MoveR: ConcreteIPReg R: abstractRegQuotient

]

{ #category : #'abstract instructions' }
CogARMv8Compiler >> genJumpMultiplyOverflow: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^cogit JumpNonZero: jumpTarget
]

{ #category : #'smalltalk calling convention' }
CogARMv8Compiler >> genLoadCStackPointer [
	"Load the stack pointer register with that of the C stack, effecting
	 a switch to the C stack.  Used when machine code calls into the
	 CoInterpreter run-time (e.g. to invoke interpreter primitives)."
	cogit MoveAw: cogit cStackPointerAddress R: SPReg.
	^0
]

{ #category : #'smalltalk calling convention' }
CogARMv8Compiler >> genLoadCStackPointers [
	"Load the frame and stack pointer registers with those of the C stack,
	 effecting a switch to the C stack.  Used when machine code calls into
	 the CoInterpreter run-time (e.g. to invoke interpreter primitives)."
	cogit MoveAw: cogit cStackPointerAddress R: SP.
	cogit MoveAw: cogit cFramePointerAddress R: FPReg.
	^0
]

{ #category : #'smalltalk calling convention' }
CogARMv8Compiler >> genLoadStackPointers [
	"Switch back to the Smalltalk stack. Assign SPReg first
	 because typically it is used immediately afterwards."
	cogit MoveAw: cogit stackPointerAddress R: SPReg.
	cogit MoveAw: cogit framePointerAddress R: FPReg.
	^0
]

{ #category : #abi }
CogARMv8Compiler >> genMarshallNArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 [
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
CogARMv8Compiler >> genMulR: regSource R: regDest [
	"In ARMv8 the multiplication operation (MUL) does not set the overflow flag.
	MUL multiplies two 64bit registers and produces the lower 64bit part of the 128bit result into a register.
	SMULH multiplies two 64bit registers and produces the higher 64bit part of the 128bit result into a register, sign-extended.
	An overflow happens in the higher part is just an extension of the sign of the lower part.
	In other words, an overflow does NOT happen if:
		=> the number lower part is positive (sign = 0) and the higher part is all 0s or
		=> the number lower part is negative (sign = 1) and the higher part is all 1s"
	

	<var: 'first' type: #'AbstractInstruction *'>
	| first |
	"First get the high part in a temporary register"
	cogit gen: SMULH operand: regSource operand: regDest operand: RISCTempReg.
	"Then get the low part on the destination register.
	Since this is a two-address code, destination register is the second operand too.
	Thus, writing to the destination register will override the operand:
	This is why we do this SMULH first and then MUL because both need the operands, and in this order we avoid an extra move..."
	first := cogit gen: MUL operand: regSource operand: regDest operand: regDest.
	cogit gen: CMPMULOverflow operand: regDest operand: RISCTempReg.
	^ first
]

{ #category : #'smalltalk calling convention' }
CogARMv8Compiler >> genPushRegisterArgsForAbortMissNumArgs: numArgs [
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
CogARMv8Compiler >> genPushRegisterArgsForNumArgs: numArgs scratchReg: ignored [
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
CogARMv8Compiler >> genRemoveNArgsFromStack: n [
	"This is a no-op on ARM since the ABI passes up to 4 args in registers and trampolines currently observe that limit."
	<inline: true>
	self assert: n <= 4.
	^0
]

{ #category : #abi }
CogARMv8Compiler >> genRestoreRegs: regMask [
	"Restore the registers in regMask as saved by genSaveRegs:."
	<inline: true>
	| registerCount |
	self assert: (R12 > R1 and: [R12 - R1 + 1 = 12]).
	self deny: (regMask anyMask: (cogit registerMaskFor: SPReg and: FPReg)).
	
	registerCount := 0.
	R1 to: R12 do:
		[:reg|
		 (regMask anyMask: (cogit registerMaskFor: reg)) ifTrue:
			[registerCount := registerCount + 1]].
	
	R1 to: R12 do:
		[:reg|
		 (regMask anyMask: (cogit registerMaskFor: reg)) ifTrue:
			[cogit PopR: reg]].
	
	"If we are restoring an odd number of registers, this would unalign the stack.
	Then, lets pop the extra thing to force the stack alignment"
	registerCount \\ 2 == 0
		ifFalse: [ 
			cogit PopR: R0  ].
	
	^0
]

{ #category : #abi }
CogARMv8Compiler >> genSaveRegForCCall [
	"Save the general purpose registers for a call into the C run-time from a trampoline."
	"Save none, because the ARM ABI only defines callee saved registers, no caller-saved regs."
	"cogit gen: STMFD operand: 16r7F"
]

{ #category : #abi }
CogARMv8Compiler >> genSaveRegs: regMask [
	"Save the registers in regMask for a call into the C run-time from a trampoline"
	<inline: true>
	| registerCount |
	self assert: (R12 > R1 and: [R12 - R1 + 1 = 12]).
	self deny: (regMask anyMask: (cogit registerMaskFor: SPReg and: FPReg)).
	
	registerCount := 0.
	R12 to: R1 by: -1 do:
		[:reg|
		 (regMask anyMask: (cogit registerMaskFor: reg)) ifTrue:
			[registerCount := registerCount + 1]].
	
	"If we are saving an odd number of registers, this would unalign the stack.
	Then, lets save an extra thing to force the stack alignment"
	registerCount \\ 2 == 0
		ifFalse: [ cogit PushCq: 16rBEEF "Marker smallinteger to generate a valid stack" ].
	
	R12 to: R1 by: -1 do:
		[:reg|
		 (regMask anyMask: (cogit registerMaskFor: reg)) ifTrue:
			[cogit PushR: reg]].
	^0
]

{ #category : #'smalltalk calling convention' }
CogARMv8Compiler >> genSaveStackPointers [
	"Save the frame and stack pointer registers to the framePointer
	 and stackPointer variables.  Used to save the machine code frame
	 for use by the run-time when calling into the CoInterpreter run-time."
	cogit MoveR: FPReg Aw: cogit framePointerAddress.
	cogit MoveR: SPReg Aw: cogit stackPointerAddress.
	^0
]

{ #category : #'abstract instructions' }
CogARMv8Compiler >> genSubstituteReturnAddress: retpc [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^cogit MoveCw: retpc R: LR
]

{ #category : #disassembly }
CogARMv8Compiler >> generalPurposeRegisterMap [
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
CogARMv8Compiler >> hasConditionRegister [
	"Answer if the receiver supports, e.g., JumpOverflow after a regular AddRR"
	^true
]

{ #category : #testing }
CogARMv8Compiler >> hasDoublePrecisionFloatingPointSupport [
	"might be true, but is for the forseeable future disabled"
	^true
]

{ #category : #testing }
CogARMv8Compiler >> hasLinkRegister [
	^true "lr"
]

{ #category : #testing }
CogARMv8Compiler >> hasPCDependentInstruction [
	"e.g. B, BL: Branch, Branch and Link"
	^true
]

{ #category : #testing }
CogARMv8Compiler >> hasThreeAddressArithmetic [
	"Answer if the receiver supports three-address arithmetic instructions (currently only AndCqRR)"
	^true
]

{ #category : #testing }
CogARMv8Compiler >> hasVarBaseRegister [
	"Answer if the processor has a dedicated callee-saved register to point to
	 the base of commonly-accessed variables. On ARM we use R10 for this."
	^true "r10/sl"
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> inclusiveOrSize: is64Bits firstRegister: firstRegister secondRegister: secondRegister destinationRegister: destinationRegister [
	
	"C6.2.206 OOR (shifted register)
	
	Bitwise inclusive OR (shifted register) performs a bitwise inclusive OR of a register value and an optionally-shifted register value, and writes the result to the destination register.
	
	OOR <Xd>, <Xn>, <Xm>{, <shift> #<amount>}"
	
	^ self
		logicalShiftedRegisterSize: is64Bits
		opcode: 2r01
		firstRegister: firstRegister
		shiftedRegister: secondRegister
		shiftOption: 0 "LSL"
		shiftValue: 0
		negated: 0
		destinationRegister: destinationRegister
]

{ #category : #'generate machine code' }
CogARMv8Compiler >> initialize [
	"This method intializes the Smalltalk instance.  The C instance is merely a struct and doesn't need initialization."
	<doNotGenerate>
	operands := CArrayAccessor on: (Array new: NumOperands).
	machineCode := CArrayAccessor on: (Array new: self machineCodeWords)
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> inlineCacheTagAt: callSiteReturnAddress [
	"Answer the inline cache tag for the return address of a send."
	^self subclassResponsibility
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> instructionAddressBefore: followingAddress [
	"Answer the instruction address immediately preceding followingAddress."
	<inline: true>
	^followingAddress -4
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> instructionBeforeAddress: followingAddress [
	"Answer the instruction immediately preceding followingAddress."
	<inline: true>
	<returnTypeC: #'uint32_t'>
	^objectMemory long32At: (self instructionAddressBefore: followingAddress)
]

{ #category : #testing }
CogARMv8Compiler >> instructionIsB: instr [
	"is this a B <label> instruction?"
	self seeAlso: #b:.
	^ (instr bitAnd: 16r3f << 26) = (2r000101 << 26)
]

{ #category : #testing }
CogARMv8Compiler >> instructionIsBL: instr [
	"is this a BL <label> instruction?"
	self seeAlso: #bl:.
	^ instr allMask: 2r100101 << 26
]

{ #category : #testing }
CogARMv8Compiler >> instructionIsBLX: instr [
"is this a BLX <targetReg> instruction?"
	^(self conditionIsNotNever: instr)  and: [(instr bitAnd: 16r0FFFFFF0) = 16r12FFF30]
]

{ #category : #testing }
CogARMv8Compiler >> instructionIsBX: instr [
"is this a BX <targetReg> instruction?"
	^(self conditionIsNotNever: instr) and: [(instr bitAnd: 16r0FFFFFF0) = 16r12FFF10]
]

{ #category : #testing }
CogARMv8Compiler >> instructionIsCMP: instr [
	"is this a CMP instruction?"
	^(self conditionIsNotNever: instr) and: [(instr >> 21 bitAnd: 16r7F) = CmpOpcode]
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> instructionIsConditionalBranch: instruction [
	
	
	^ (instruction bitAnd: 16rFF << 24) = (2r01010100 << 24)
]

{ #category : #testing }
CogARMv8Compiler >> instructionIsLDR: instr [

	^ instr allMask: 2r01011000 << 24
]

{ #category : #testing }
CogARMv8Compiler >> instructionIsOR: instr [
	"is this an ORR instruction?"
	^(self conditionIsNotNever: instr)  and:[(instr >> 21 bitAnd: 16r7F) = (16r10 bitOr: OrOpcode)]
]

{ #category : #testing }
CogARMv8Compiler >> instructionIsPush: instr [
	"is this a push R str r??, [sp, #-8] -  instruction?"
	<var: #instr type: #'uint32_t'> 
	
	^ (self pushR: 0) = (instr bitAnd: 16rFFFFFFFFFFFFFFE0)
]

{ #category : #disassembly }
CogARMv8Compiler >> instructionSizeAt: pc [
	"Answer the instruction size at pc.Simple on ARM ;-)"
	^4
]

{ #category : #'generate machine code - support' }
CogARMv8Compiler >> inverseOpcodeFor: armOpcode [
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

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> is12BitValue: constant ifTrue: aTrueBlock ifFalse: aFalseBlock [ 
	
	<inline: true>
	
	^ constant abs <= 2047 "(2 raisedTo: 11) - 1"
		ifTrue: [ | twoComplement |
			"Two complement using 12 bits"
			twoComplement := constant >= 0
				ifTrue: [ constant ]
				ifFalse: [ 16rfff - constant abs + 1 ].
			aTrueBlock value: constant >= 0 value: twoComplement ]
		ifFalse: [aFalseBlock value]
]

{ #category : #'private-bit-manipulation' }
CogARMv8Compiler >> is64bitMask64: aMask [

	^ aMask ~= 0 and: [ ((aMask + 1) bitAnd: aMask) == 0 ]
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> is9BitValue: originalConstant ifTrue: aTrueBlock ifFalse: aFalseBlock [ 
	
	| constant |
	
	<inline: true>
	<var: #constant type: 'sqInt'>
	
	"This is needed to force the type conversion in an inlined function.
	If not... the variable is removed and using the parameter of the call site."
	constant := self cCoerce: originalConstant to: #'sqInt'.
	
	^ (constant abs <= 255 or: [ constant = -256 ]) "9 bits go from -256..255"
		ifTrue: [ | twoComplement |
			"Two complement using 9 bits"
			twoComplement := constant >= 0
				ifTrue: [ constant ]
				ifFalse: [ 16r1ff - constant abs + 1 ].
			aTrueBlock value: twoComplement ]
		ifFalse: [ aFalseBlock value ]
]

{ #category : #testing }
CogARMv8Compiler >> isAddressRelativeToVarBase: varAddress [
	<inline: true>
	<var: #varAddress type: #usqInt>
	"Support for addressing variables off the dedicated VarBaseReg"
	^varAddress notNil
	  and: [varAddress >= cogit varBaseAddress
	  and: [varAddress - cogit varBaseAddress < (1 << 12)]]
]

{ #category : #testing }
CogARMv8Compiler >> isBigEndian [
	^false
]

{ #category : #testing }
CogARMv8Compiler >> isCallPrecedingReturnPC: mcpc [
	"Assuming mcpc is a send return pc answer if the instruction before it is a call (not a CallFull)."
	"There are two types of calls: BL and/BLX encoding"
	| call |
	call := self instructionBeforeAddress: mcpc.
	^(self instructionIsBL: call) or:[self instructionIsBLX: call]
]

{ #category : #testing }
CogARMv8Compiler >> isInImmediateJumpRange: operand [
	"ARM calls and jumps span +/- 32 mb, more than enough for intra-zone calls and jumps."
	<var: #operand type: #'usqIntptr_t'>
	^operand signedIntFromLong between: -16r2000000 and: 16r1FFFFFC
]

{ #category : #testing }
CogARMv8Compiler >> isJumpAt: pc [
	| instr |
	instr := objectMemory long32At: pc.
	^(self instructionIsB: instr)
	  or: [self instructionIsBX: instr]
]

{ #category : #testing }
CogARMv8Compiler >> isPCRelativeValueLoad: instr [
	<var: 'instr' type: #'unsigned int'>
	"If ADR <Xd>, <label>"
	
	^ (instr bitAnd: 2r10011111 << 24) = (1 << 28)
]

{ #category : #'private-bit-manipulation' }
CogARMv8Compiler >> isShiftedMask: aMask [

	^ aMask ~= 0 and: [ self is64bitMask64: ((aMask - 1) bitOr: aMask) ]
]

{ #category : #accessing }
CogARMv8Compiler >> jumpLongByteSize [
"	Branch/Call ranges.  Jump[Cond] can be generated as short as possible.  Call/Jump[Cond]Long must be generated
	in the same number of bytes irrespective of displacement since their targets may be updated, but they need only
	span 16Mb, the maximum size of the code zone.  This allows e.g. ARM to use single-word call and jump instructions
	for most calls and jumps.  CallFull/JumpFull must also be generated in the same number of bytes irrespective of
	displacement for the same reason, but they must be able to span the full (32-bit or 64-bit) address space because
	they are used to call code in the C runtime, which may be distant from the code zone"
	^4
]

{ #category : #accessing }
CogARMv8Compiler >> jumpLongConditionalByteSize [
	" AArch64 does not have conditional long jumps. Be a short conditional jump and a long jump "
	^ 8
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> jumpLongTargetBeforeFollowingAddress: mcpc [ 
	"Answer the target address for the long jump immediately preceding mcpc"
	^self callTargetFromReturnAddress: mcpc
]

{ #category : #disassembly }
CogARMv8Compiler >> jumpTargetPCAt: pc [
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
CogARMv8Compiler >> ldr: destReg rn: baseReg plus: u imm: immediate12bitValue [
	
	^ self
		ldrSize: 1 "64bits"
		baseRegister: baseReg
		unsignedOffset: immediate12bitValue
		destinationRegister: destReg
]

{ #category : #assembler }
CogARMv8Compiler >> ldrSize: size baseRegister: baseReg signedOffset: immediate9bitValue destinationFloatingPointRegister: destinationRegister is128BitVariant: is128BitVariant preIndex: isPreIndex [

	"C7.2.191 LDR (immediate, SIMD&FP)
	
	Load SIMD&FP Register (immediate offset). This instruction loads an element from memory, and writes the result as a scalar to the SIMD&FP register. The address that is used for the load is calculated from a base register value, a signed immediate offset, and an optional offset that is a multiple of the element size.
	
	Post-Index
	LDR <Dt>, [<Xn|SP>], #<simm>
	
	Pre-Index
	LDR <Dt>, [<Xn|SP>, #<simm>]!"
	
	^ (size bitAnd: 2r11) << 30
		bitOr: (2r1111 << 26
		bitOr: ((is128BitVariant bitAnd: 1) << 23
		bitOr: (1 << 22
		bitOr: ((immediate9bitValue bitAnd: 16r1ff) << 12
		bitOr: ((isPreIndex bitAnd: 1) << 11
		bitOr: ((1 << 10)
		bitOr: ((baseReg bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111))))))))
]

{ #category : #assembler }
CogARMv8Compiler >> ldrSize: is64Bits baseRegister: baseReg signedOffset: immediate9bitValue destinationRegister: destinationRegister preIndex: preIndex [

	"Encodes a Load Register (immediate) instruction of the form
	
	LDR <Xt>, [<Xn|SP>, #<simm>]!"
	
	self assert: immediate9bitValue > 0.
	^ 1 << 31
		bitOr: ((is64Bits bitAnd: 1) << 30
		bitOr: (2r111000010 << 21
		bitOr: ((immediate9bitValue bitAnd: 2r111111111) << 12
		bitOr: (preIndex << 11
		bitOr:(2r1 << 10
		bitOr:((baseReg bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111)))))))
]

{ #category : #assembler }
CogARMv8Compiler >> ldrSize: size baseRegister: baseReg unsignedOffset: immediate12bitValue destinationFloatingPointRegister: destinationRegister is128BitVariant: is128BitVariant [

	"C7.2.191 LDR (immediate, SIMD&FP)
	
	Load SIMD&FP Register (immediate offset). This instruction loads an element from memory, and writes the result as a scalar to the SIMD&FP register. The address that is used for the load is calculated from a base register value, a signed immediate offset, and an optional offset that is a multiple of the element size.
	
	Unsigned offset Variant
	LDR <Dt>, [<Xn|SP>{, #<pimm>}]"
	
	^ (size bitAnd: 2r11) << 30
		bitOr: (2r1111 << 26
		bitOr: (2r1 << 24
		bitOr: ((is128BitVariant bitAnd: 1) << 23
		bitOr: (1 << 22
		bitOr: ((immediate12bitValue bitAnd: 16rfff) << 10
		bitOr: ((baseReg bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111)))))))
]

{ #category : #assembler }
CogARMv8Compiler >> ldrSize: is64Bits baseRegister: baseReg unsignedOffset: immediate12bitValue destinationRegister: destinationRegister [

	"C6.2.131 LDR (immediate)
	
	oad Register (immediate) loads a word or doubleword from memory and writes it to a register. The address that is used for the load is calculated from a base register and an immediate offset.
	
	Unsigned offset variant
	
	LDR <Xt>, [<Xn|SP>{, #<pimm>}]"
	
	self assert: immediate12bitValue >= 0.
	^ 1 << 31
		bitOr: ((is64Bits bitAnd: 1) << 30
		bitOr: (2r11100101 << 22
		bitOr: ((immediate12bitValue / 8 bitAnd: 2r111111111111) << 10
		bitOr:((baseReg bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111)))))
]

{ #category : #assembler }
CogARMv8Compiler >> ldrSize: is64Bits indexRegister: indexRegister baseRegister: baseRegister destinationRegister: destinationRegister [
	
	"C6.2.133 LDR (register)
	
	Load Register (register) calculates an address from a base register value and an offset register value, loads a word from memory, and writes it to a register. The offset register value can optionally be shifted and extended
	
	LDR <Xt>, [<Xn|SP>, (<Wm>|<Xm>){, <extend> {<amount>}}]"
	
	^ self
		ldrSize: is64Bits
		indexRegister: indexRegister
		option: 2r011 "LSL"
		scale: 0 "Not scaled"
		baseRegister: baseRegister
		destinationRegister: destinationRegister
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> ldrSize: size indexRegister: indexRegister option: extendShiftOption scale: isScaled baseRegister: baseRegister destinationFloatingPointRegister: destinationRegister opcode: anOpcode [
	
	"C7.2.193 LDR (register, SIMD&FP)
	
	Load SIMD&FP Register (register offset). This instruction loads a SIMD&FP register from memory. The address that is used for the load is calculated from a base register value and an offset register value. The offset can be optionally shifted and extended.
	
	64-fsreg,LDR-64-fsreg variant
	LDR <Dt>, [<Xn|SP>, (<Wm>|<Xm>){, <extend> {<amount>}}]"
	
	^ (size bitAnd: 2r11) << 30
		bitOr: (2r1111 << 26
		bitOr: ((anOpcode bitAnd: 2r11) << 22
		bitOr: (1 << 21
		bitOr: ((indexRegister bitAnd: 16r1f) << 16
		bitOr: ((extendShiftOption bitAnd: 2r111) << 13
		bitOr: ((isScaled bitAnd: 1) << 12
		bitOr: ((2r10) << 10
		bitOr: ((baseRegister bitAnd: 16r1f) << 5
		bitOr: (destinationRegister bitAnd: 16r1f)))))))))
]

{ #category : #assembler }
CogARMv8Compiler >> ldrSize: is64Bits indexRegister: indexRegister option: extendShiftOption scale: isScaled baseRegister: baseRegister destinationRegister: destinationRegister [
	
	"C6.2.133 LDR (register)
	
	Load Register (register) calculates an address from a base register value and an offset register value, loads a word from memory, and writes it to a register. The offset register value can optionally be shifted and extended
	
	LDR <Xt>, [<Xn|SP>, (<Wm>|<Xm>){, <extend> {<amount>}}]"
	
	^ 1 << 31
		bitOr: ((is64Bits bitAnd: 1) << 30
		bitOr: (2r111000011 << 21
		bitOr: ((indexRegister bitAnd: 2r11111) << 16
		bitOr:((extendShiftOption bitAnd: 2r111) << 13
		bitOr:((isScaled bitAnd: 1) << 12
		bitOr:((2r10) << 10
		bitOr:((baseRegister bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111))))))))
]

{ #category : #assembler }
CogARMv8Compiler >> ldrSize: is64Bits programCounterRelativeOffset: immediate19bitValue destinationRegister: destinationRegister [

	"Encodes a Load Register (immediate) instruction of the form
		
	LDR <Xt>, <label>"
	
	| twoComplement multiplier |
	multiplier := immediate19bitValue / 4.
	self assert: multiplier isInteger.
	twoComplement := multiplier > 0
		ifTrue: [ multiplier ]
		ifFalse: [ 2r1111111111111111111 - multiplier abs + 1 ].

	^ 0 << 31
		bitOr: ((is64Bits bitAnd: 1) << 30
		bitOr: (2r011000 << 24
		bitOr: ((twoComplement bitAnd: 2r1111111111111111111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111))))
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> ldrbSourceRegister: sourceRegister destinationRegister: destinationRegister [
	
	"C6.2.135 LDRB (immediate)

	Load Register Byte (immediate) loads a byte from memory, zero-extends it, and writes the result to a register. The address that is used for the load is calculated from a base register and an immediate offset. For information about memory accesses, see Load/Store addressing modes on page C1-189.
	
	Unsigned offset variant
	LDRB <Wt>, [<Xn|SP>{, #<pimm>}]"
	
	^ self ldrbSourceRegister: sourceRegister destinationRegister: destinationRegister offset: 0
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> ldrbSourceRegister: sourceRegister destinationRegister: destinationRegister offset: immediate12BitValue [
	
	"C6.2.135 LDRB (immediate)

	Load Register Byte (immediate) loads a byte from memory, zero-extends it, and writes the result to a register. The address that is used for the load is calculated from a base register and an immediate offset. For information about memory accesses, see Load/Store addressing modes on page C1-189.
	
	Unsigned offset variant
	LDRB <Wt>, [<Xn|SP>{, #<pimm>}]"
	
	^ 2r111 << 27
		bitOr: (1 << 24
		bitOr: (1 << 22
		bitOr: ((immediate12BitValue bitAnd: 16rfff) << 10
		bitOr: ((sourceRegister bitAnd: 16r1f) << 5
		bitOr: (destinationRegister bitAnd: 16r1f)))))
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> ldrbSourceRegister: sourceRegister offsetRegister: offsetRegister destinationRegister: destinationRegister [ 
	
	"C6.2.136 LDRB (register)

	Load Register Byte (register) calculates an address from a base register value and an offset register value, loads a byte from memory, zero-extends it, and writes it to a register. 
	
	Shifted register variant
	LDRB <Wt>, [<Xn|SP>, <Xm>{, LSL <amount>}]"
	
	^ 2r111 << 27
		bitOr: (2r11 << 21
		bitOr: ((offsetRegister bitAnd: 16r1f) << 16
		bitOr: (2r01101 "LSL" << 11
		bitOr: ((sourceRegister bitAnd: 16r1f) << 5
		bitOr: (destinationRegister bitAnd: 16r1f)))))
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> ldrhBaseRegister: baseRegister offsetDividedBy2: offset12Bits destinationRegister: destinationRegister [

 	"C6.2.137
		LDRH (immediate)
			Load Register Halfword (immediate) loads a halfword from memory, zero-extends it, and writes the result to a register. The address that is used for the load is calculated from a base register and an 			immediate offset. For information about memory accesses, see Load/Store addressing modes on page C1-189."
						
	"LDRH <Wt>, [<Xn|SP>{, #<pimm>}]"
	
	^ 2r111100101 << 22
		bitOr: ((offset12Bits bitAnd: 16rfff) << 10
		bitOr:((baseRegister bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111)))
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> ldrhSourceRegister: sourceRegister offsetRegister: offsetRegister destinationRegister: destinationRegister [ 
	
	"C6.2.138 LDRH (register)

	Load Register Halfword (register) calculates an address from a base register value and an offset register value, loads a halfword from memory, zero-extends it, and writes it to a register.
	
	LDRH <Wt>, [<Xn|SP>, (<Wm>|<Xm>){, <extend> {<amount>}}]"
	
	^ 2r1111 << 27
		bitOr: (2r11 << 21
		bitOr: ((offsetRegister bitAnd: 16r1f) << 16
		bitOr: (2r01111 "LSL" << 11
		bitOr: ((sourceRegister bitAnd: 16r1f) << 5
		bitOr: (destinationRegister bitAnd: 16r1f)))))
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> ldrswSourceRegister: sourceRegister offsetRegister: offsetRegister destinationRegister: destinationRegister [ 
	
	"C6.2.145 LDRSW (register)

	Load Register Signed Word (register) calculates an address from a base register value and an offset register value, loads a word from memory, sign-extends it to form a 64-bit value, and writes it to a register. The offset register value can be shifted left by 0 or 2 bits.
	
	LDRSW <Xt>, [<Xn|SP>, (<Wm>|<Xm>){, <extend> {<amount>}}]"
	
	^ 2r10111000101 << 21
		bitOr: ((offsetRegister bitAnd: 16r1f) << 16
		bitOr: (2r01111 "LSL" << 11
		bitOr: ((sourceRegister bitAnd: 16r1f) << 5
		bitOr: (destinationRegister bitAnd: 16r1f))))
]

{ #category : #assembler }
CogARMv8Compiler >> ldurSize: is64Bits baseRegister: baseReg signedOffset: immediate9bitValue destinationRegister: destinationRegister [

	"C6.2.167 LDUR
	
	Load Register (unscaled) calculates an address from a base register and an immediate offset, loads a 32-bit word or 64-bit doubleword from memory, zero-extends it, and writes it to a register.
	
	LDUR <Xt>, [<Xn|SP>{, #<simm>}]"
	
	| twoComplement |
	twoComplement := immediate9bitValue > 0
		ifTrue: [ immediate9bitValue ]
		ifFalse: [ 2r111111111 - immediate9bitValue abs + 1 ].

	self assert: twoComplement > 0.

	^ 1 << 31
		bitOr: ((is64Bits bitAnd: 1) << 30
		bitOr: (2r111000010 << 21
		bitOr: ((twoComplement bitAnd: 2r111111111) << 12
		bitOr:((baseReg bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111)))))
]

{ #category : #assembler }
CogARMv8Compiler >> ldurbSize: is64Bits baseRegister: baseRegister signedOffset: immediate9bitTwoComplementOffset destinationRegister: destinationRegister [
	
	"C6.2.168 LDURB
	
	Load Register Byte (unscaled) calculates an address from a base register and an immediate offset, loads a byte from memory, zero-extends it, and writes it to a register.
	
	LDURB <Wt>, [<Xn|SP>{, #<simm>}]"
	
	^ 2r111000010 << 21
		bitOr: ((immediate9bitTwoComplementOffset bitAnd: 16r1ff) << 12
		bitOr: ((baseRegister bitAnd: 16r1f) << 5
		bitOr: (destinationRegister bitAnd: 16r1f)))
]

{ #category : #'private-bit-manipulation' }
CogARMv8Compiler >> leadingOnesOf: aNumber [
	"Return how many leading ones are in the 64bit bitString representation of aNumber.
	That is, how many ones are in the most significant bits before there is a zero.
	For example, the 64bit binary number 2r11101101000110001111...00 has 3 leading ones"
	
	"Calculate it by calculating the leading zeros of the bit-inverted number"
	^ self leadingZerosOf: (aNumber bitXor: 16rFFFFFFFFFFFFFFFF)
]

{ #category : #'private-bit-manipulation' }
CogARMv8Compiler >> leadingZerosOf: aNumber [
	"Return how many leading zeros are in the 64bit bitString representation of aNumber.
	That is, how many zeros are in the most significant bits before there is a one.
	For example, the 64bit binary number 2r00010101000110001111000...00 has 3 trailing zeros.
	
	Uses a bisect method looking at the number by halfs"
	
	"We take a look at the most significant part of the number by ignoring the lower part (shifting it).
	If the non ignored part is not all zeros, continue the procedure with the non-ignored bits.
	On each iteration, ignore less (dividing the shift by two) because there may be more leading zeros.
	"
	| zeroBits currentNumber shift shiftedValue |
	zeroBits := 0.
	currentNumber := aNumber.
	shift := 64"bits" >>1.
	[ shift ~= 0 ] whileTrue: [
		shiftedValue := currentNumber >> shift.
		(shiftedValue ~= 0)
			ifTrue: [ currentNumber := shiftedValue ]
			ifFalse: [ 
				"If we found they are all zeros, record them"
				zeroBits := zeroBits bitOr: shift ].
		shift := shift >> 1.
	].
	^ zeroBits
]

{ #category : #abi }
CogARMv8Compiler >> leafCallStackPointerDelta [
	"Answer the delta from the stack pointer after a call to the stack pointer
	 immediately prior to the call.  This is used to compute the stack pointer
	 immediately prior to  call from within a leaf routine, which in turn is used
	 to capture the c stack pointer to use in trampolines back into the C run-time."
	"This might actually be false, since directly after a call, lr, fp and variable registers need be pushed onto the stack. It depends on the implementation of call."
	^0
]

{ #category : #accessing }
CogARMv8Compiler >> literalLoadInstructionBytes [
	"Answer the size of a literal load instruction (which may or may not include the size of the literal).
	 This differs between in-line and out-of-line literal generation."
	<inline: true>
	^self subclassResponsibility
]

{ #category : #'generate machine code - support' }
CogARMv8Compiler >> loadCwInto: destReg [
	"Load the operand into the destination register, answering
	 the size of the instructions generated to do so."
	| operand distance |
	operand := operands at: 0.
	self cCode:[] inSmalltalk:[operand := operand bitAnd: 16rFFFFFFFFFFFFFFFF]. "Need to clamp the value to a word size since one or two usages actually generate double sized values and rely upon the C code to narrow it within the running VM"
	(self isAnInstruction: (cogit cCoerceSimple: operand to: #'AbstractInstruction *')) ifTrue:
		[operand := (cogit cCoerceSimple: operand to: #'AbstractInstruction *') address].
	"First try and encode as a pc-relative reference..."
	(cogit addressIsInCurrentCompilation: operand) ifTrue: [
		distance := operand - address.
		"Check if the absolute distance fits in 20 bits.
		We need to encode the offset in 21 bits signed, so 1 bit is for the sign."
		(distance abs bitAnd: 16rfffff) = distance abs
			ifTrue: [ 
				self machineCodeAt: 0 put: (self adrSignedImmediate21BitsValue: distance destinationRegister: destReg).
				^ machineCodeSize := 4 ]
			ifFalse: [ self notYetImplemented. ]].
	
	"If this fails, use the conventional literal load sequence."
	^self moveCw: operand intoR: destReg
]

{ #category : #accessing }
CogARMv8Compiler >> loadPICLiteralByteSize [
	"Answer the byte size of a MoveCwR opcode's corresponding machine code
	 when the argument is a PIC.  This is for the self-reference at the end of a
	 closed PIC.  On ARM this is a single instruction pc-relative register load."
	^4
]

{ #category : #assembler }
CogARMv8Compiler >> logicalImmediate: is64Bits opcode: instructionOpcode immediate13bitValue: logicalEncodedImmediate13BitValue sourceRegister: sourceRegister destinationRegister: destinationRegister [
	
	"C3.3.2 Logical (immediate)
	
	The Logical (immediate) instructions accept a bitmask immediate value that is a 32-bit pattern or a 64-bit pattern viewed as a vector of identical elements of size e = 2, 4, 8, 16, 32 or, 64 bits. Each element contains the same sub-pattern, that is a single run of 1 to (e - 1) nonzero bits from bit 0 followed by zero bits, then rotated by 0 to (e - 1) bits. This mechanism can generate 5334 unique 64-bit patterns as 2667 pairs of pattern and their bitwise inverse.
	
	AND <Xd|SP>, <Xn>, #<imm>  => opcode 00
	ANDS <Xd|SP>, <Xn>, #<imm> => opcode 11
	EOR <Xd|SP>, <Xn>, #<imm>  => opcode 10
	ORR <Xd|SP>, <Xn>, #<imm>  => opcode 01
	TST <Xd|SP>, <Xn>, #<imm>  => alias of ANDS
	"
	
	^ is64Bits << 31
		bitOr: ((instructionOpcode bitAnd: 2r11) << 29
		bitOr: (2r100100 << 23
		bitOr: ((logicalEncodedImmediate13BitValue bitAnd: 16r1fff) << 10
		bitOr: ((sourceRegister bitAnd: 16r1f) << 5
		bitOr: (destinationRegister bitAnd: 16r1f)))))
]

{ #category : #assembler }
CogARMv8Compiler >> logicalShiftLeftSize: is64bits sourceRegister: sourceRegister shiftRegister: shiftRegister destinationRegister: destinationRegister [ 
	
	"C6.2.177 LSL (register)
	
	Logical Shift Left (register) shifts a register value left by a variable number of bits, shifting in zeros, and writes the result to the destination register. The remainder obtained by dividing the second source register by the data size defines the number of bits by which the first source register is left-shifted.
	
	LSL <Xd>, <Xn>, <Xm>"
	
	^ is64bits << 31
		bitOr: (2r11010110 << 21
		bitOr: ((shiftRegister bitAnd: 16r1f) << 16
		bitOr: (1 << 13
		bitOr: ((sourceRegister bitAnd: 16r1f) << 5
		bitOr: (destinationRegister bitAnd: 16r1f)))))
	
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> logicalShiftLeftSize: is64Bits sourceRegister: sourceRegister shiftValue: shiftValue destinationRegister: destinationRegister [

	"C6.2.178 LSL (immediate)
	
	Logical Shift Left (immediate) shifts a register value left by an immediate number of bits, shifting in zeros, and writes the result to the destination register.

	LSL <Xd>, <Xn>, #<shift>"

	| base |
	base := is64Bits = 1 ifTrue: [64] ifFalse: [ 32 ].
	^ self
		unsignedBitfieldMoveSize: is64Bits
		immr: shiftValue negated \\ base
		imms: base - 1 - shiftValue
		sourceRegister: sourceRegister
		destinationRegister: destinationRegister
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> logicalShiftRightSize: is64Bits sourceRegister: sourceRegister shiftValue: shiftValue destinationRegister: destinationRegister [
	
	"C6.2.181 LSR (immediate)
	
	Logical Shift Right (immediate) shifts a register value right by an immediate number of bits, shifting in zeros, and writes the result to the destination register.

	LSR <Xd>, <Xn>, #<shift>"
	^ self
		unsignedBitfieldMoveSize: is64Bits
		immr: shiftValue
		imms: (is64Bits = 1 ifTrue: [63] ifFalse: [ 31 ])
		sourceRegister: sourceRegister
		destinationRegister: destinationRegister
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> logicalShiftedRegisterSize: is64Bits opcode: logicalOpcode firstRegister: firstRegister shiftedRegister: shiftedRegister shiftOption: shiftOption shiftValue: immediate6BitsValue negated: negatedFlag destinationRegister: destinationRegister [

	"C3.4.5 Logical (shifted register)
	
	The Logical (shifted register) instructions apply an optional shift operator to the second source register value before performing the main operation. The register width of the instruction controls whether the new bits are fed into the intermediate result on a right shift or rotate at bit[63] or bit[31].
The shift operators LSL, ASR, LSR, and ROR accept a constant immediate shift amount in the range 0 to one less than the register width of the instruction, inclusive.
Omitting the shift operator and amount implies LSL #0, which means that there is no shift. A disassembler must not output LSL #0. However, a disassembler must output all other shifts by zero."

	^ is64Bits << 31
		bitOr: ((logicalOpcode bitAnd: 2r11) << 29
		bitOr: (2r01010 << 24
		bitOr: ((shiftOption bitAnd: 2r11) << 22
		bitOr: ((negatedFlag bitAnd: 1) << 21
		bitOr: ((shiftedRegister bitAnd: 16r1f) << 16
		bitOr: ((immediate6BitsValue bitAnd: 16r3f) << 10
		bitOr: ((firstRegister bitAnd: 16r1f) << 5
		bitOr: (destinationRegister bitAnd: 16r1f))))))))
]

{ #category : #accessing }
CogARMv8Compiler >> machineCodeAt: anOffset [
	"read aWord from machineCode, with little endian"
	<inline: true>
	^machineCode at: anOffset // 4
]

{ #category : #accessing }
CogARMv8Compiler >> machineCodeAt: anOffset put: aWord [
	"add aWord to machineCode, with little endian"
	<inline: true>
	self haltIf: [ aWord highBit > 32 ].
	machineCode at: anOffset // 4 put: aWord
]

{ #category : #'generate machine code' }
CogARMv8Compiler >> machineCodeBytes [
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
CogARMv8Compiler >> machineCodeWords [
	"Answer the maximum number of words of machine code generated for any abstract instruction.
	 e.g. CmpCwR =>
			mov R3, #<addressByte1>, 12
			orr R3, R3, #<addressByte2>, 8
			orr R3, R3, #<addressByte3>, 4
			orr R3, R3, #<addressByte4>, 0
			cmp R?, R3"
	^5
]

{ #category : #'ARM convenience instructions' }
CogARMv8Compiler >> mov: destReg imm: immediate16bitValue ror: rot [

	^ self 
		movSize: 1
		destinationRegister: destReg
		imm: immediate16bitValue
		shift: rot
]

{ #category : #'ARM convenience instructions' }
CogARMv8Compiler >> mov: destReg rn: srcReg [

	^ self
		movSize: 1
		sourceRegister: srcReg
		destinationRegister: destReg
]

{ #category : #assembler }
CogARMv8Compiler >> movSize: is64Bits destinationRegister: destinationRegister imm: immediate16bitValue shift: shift [
	
	"C6.2.187
	
	Move (wide immediate) moves a 16-bit immediate value to a register.
	
	MOV <Xd>, #<imm>
	MOVZ <Xd>, #<imm16>, LSL #<shift>
	
	shift is a magnitude to shift left with values in (0, 16, 32, 64) encoded as shift/16
	"
	
	^ is64Bits << 31
		bitOr: (2r10100101 << 23
		bitOr: ((shift / 16 bitAnd: 2r11) << 21
		bitOr: (immediate16bitValue << 5
		bitOr: (destinationRegister bitAnd: 2r11111))))
]

{ #category : #assembler }
CogARMv8Compiler >> movSize: is64Bits destinationRegister: destinationRegister negatedImm: immediate16bitValue shift: shift [
	
	"C6.2.191 MOVN
	
	Complete me pliz
	"
	
	^ is64Bits << 31
		bitOr: (2r00100101 << 23
		bitOr: ((shift / 16 bitAnd: 2r11) << 21
		bitOr: (immediate16bitValue << 5
		bitOr: (destinationRegister bitAnd: 2r11111))))
]

{ #category : #assembler }
CogARMv8Compiler >> movSize: is64Bits sourceRegister: sourceRegister destinationRegister: destinationRegister [
	
	"C6.2.189
	
	Move (register) copies the value in a source register to the destination register.
	
	MOV <Xd>, <Xm>
	
	"
	
	^ is64Bits << 31
		bitOr: (2r0101010000 << 21
		bitOr: ((sourceRegister bitAnd: 2r11111) << 16
		bitOr: (2r11111 << 5
		bitOr: (destinationRegister bitAnd: 2r11111))))
]

{ #category : #assembler }
CogARMv8Compiler >> movSize: is64Bits sourceRegisterMaybeSP: sourceRegister destinationRegisterMaybeSP: destinationRegister [
	
	"C6.2.185 MOV (to/from SP)
	
	Move between register and stack pointer : Rd = Rn.
	
	MOV <Xd|SP>, <Xn|SP>
	
	"
	
	^ is64Bits << 31
		bitOr: (2r0010001 << 24
		bitOr: ((sourceRegister bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111)))
]

{ #category : #assembler }
CogARMv8Compiler >> movToFromSP: destinationRegister rn: sourceRegister [
	
	^ self
		movSize: 1
		sourceRegisterMaybeSP: sourceRegister
		destinationRegisterMaybeSP: destinationRegister
]

{ #category : #'generate machine code - support' }
CogARMv8Compiler >> moveCw: constant intoR: destReg [
	"Emit a load of aWord into destReg.  Answer the number of bytes of machine code generated."
	 <var: 'constant' type: #usqInt>
	<inline: true>
	^self subclassResponsibility
]

{ #category : #encoding }
CogARMv8Compiler >> msr: flags [
"Generate an MSR CPSR_f, #flags instruction.
Note that 
a) CPSR_f is equivalent to APSR_nzcvq (ARM ARM DDI0406A p A8-209 & A2-14)
b) We only have business with the NZCV flags so the generated instruction shifts the flags value <<28 - which is a ROR 4"

	^16r1328F000
	+ (2 "rotate rights are in units of 2, remember" << 8)
	+ (flags bitAnd: 16rF) " to make sure we don't have silly values here"
]

{ #category : #assembler }
CogARMv8Compiler >> msubSize: is64Bits minuendReg: minuendReg factor1Reg: factor1Reg factor2Reg: factor2Reg destinationRegister: destinationReg [ 

	"C6.2.196 MSUB

	Multiply-Subtract multiplies two register values, subtracts the product from a third register value, and writes the result to the destination register.
	
	MSUB <Xd>, <Xn>, <Xm>, <Xa> "
	
	^ is64Bits << 31
		bitOr: (2r11011 << 24
		bitOr: ((factor2Reg bitAnd: 16r1f) << 16
		bitOr: (1 << 15
		bitOr: ((minuendReg bitAnd: 16r1f) << 10
		bitOr: ((factor1Reg bitAnd: 16r1f) << 5
		bitOr: (destinationReg bitAnd: 16r1f))))))
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> mulSize: is64bits firstRegister: registerA secondRegister: registerB destinationRegister: destinationRegister [

	"C6.2.197 MUL
	
	Multiply : Rd = Rn * Rm
	
	MUL <Xd>, <Xn>, <Xm>"
	
	^ (is64bits bitAnd: 1) << 31
		bitOr: (2r11011 << 24
		bitOr: (((registerB bitAnd: 16r1f) << 16)
		bitOr: (16r1f << 10
		bitOr: (((registerA bitAnd: 16r1f) << 5)
		bitOr: (destinationRegister bitAnd: 16r1f)))))
]

{ #category : #printing }
CogARMv8Compiler >> nameForFPRegister: reg [ "<Integer>"
	<doNotGenerate>
	(reg between: 0 and: 7) ifTrue:
		[^#(D0 D1 D2 D3 D4 D5 D6 D7) at: reg + 1].
	^super nameForFPRegister: reg
]

{ #category : #printing }
CogARMv8Compiler >> nameForRegister: reg [ "<Integer>"
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

{ #category : #assembler }
CogARMv8Compiler >> negateSize: is64Bits sourceRegister: sourceRegister sourceRegisterShiftType: immediate2bitShiftType sourceRegisterShift: immediate6bitsShiftValue destinationRegister: destinationRegister [
	
	"C6.2.199 NEG (shifted register)
	
	Negate (shifted register) negates an optionally-shifted register value, and writes the result to the destination register.
	
	NEG <Xd>, <Xm>{, <shift> #<amount>}
	
	shiftType is the optional shift type to be applied to the second source operand, defaulting to LSL and encoded in the shift field. It can have the following values:
		LSL when shift = 00
		LSR when shift = 01
		ASR when shift = 10
	"
	
	^ is64Bits << 31
		bitOr: (2r1001011 << 24
		bitOr: ((immediate2bitShiftType bitAnd: 2r11) << 22
		bitOr: ((sourceRegister bitAnd: 16r1f) << 16
		bitOr: ((immediate6bitsShiftValue bitAnd: 16r3f) << 10
		bitOr: (16r1f << 5
		bitOr: (destinationRegister bitAnd: 16r1f))))))
]

{ #category : #assembler }
CogARMv8Compiler >> nop [

	"C6.2.203 NOP
	
	No Operation does nothing, other than advance the value of the program counter by 4. This instruction can be used for instruction alignment purposes
	
	NOP"
	
	^ 2r11010101000000110010000000011111 
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> numICacheFlushOpcodes [
	"ARM needs to do icache flushing when code is written"
	"for now return 0 to skip it and probably blow up"
	^0
	
]

{ #category : #accessing }
CogARMv8Compiler >> numIntRegArgs [
	^4
]

{ #category : #assembler }
CogARMv8Compiler >> orSize: is64Bits immediate13bitValue: logicalEncodedImmediate13BitValue sourceRegister: sourceRegister destinationRegister: destinationRegister [
	
	"C6.2.205 ORR (immediate)
	
	Bitwise OR (immediate) performs a bitwise (inclusive) OR of a register value and an immediate register value, and writes the result to the destination register.
	
	ORR <Xd|SP>, <Xn>, #<imm>"
	
	^ self
		logicalImmediate: is64Bits
		opcode: 2r01
		immediate13bitValue: logicalEncodedImmediate13BitValue
		sourceRegister: sourceRegister
		destinationRegister: destinationRegister
]

{ #category : #assembler }
CogARMv8Compiler >> orSize: is64Bits shiftedRegister: shiftedRegister shiftType: shiftType shiftValue: immediate6bitValue withRegister: sourceRegister2 destinationRegister: destinationRegister [

	" C6.2.206 Bitwise OR (shifted register) 
		performs a bitwise (inclusive) OR of a register value and an optionally-shifted register value, and writes the 		result to the destination register."

	^ self
		  logicalShiftedRegisterSize: is64Bits
		  opcode: 2r01
		  firstRegister: sourceRegister2
		  shiftedRegister: shiftedRegister
		  shiftOption: shiftType
		  shiftValue: immediate6bitValue
		  negated: 0
		  destinationRegister: destinationRegister
]

{ #category : #'generate machine code' }
CogARMv8Compiler >> outputMachineCodeAt: targetAddress [
	"Override to move machine code a word at a time."
	<inline: true>
	0 to: machineCodeSize - 1 by: 4 do:
		[:j|
		objectMemory long32At: targetAddress + j put: (machineCode at: j // 4)]
]

{ #category : #'generate machine code' }
CogARMv8Compiler >> padIfPossibleWithStopsFrom: startAddr to: endAddr [
	| nullBytes |
	nullBytes := (endAddr - startAddr + 1) \\ 4.
	self stopsFrom: startAddr to: endAddr - nullBytes.
	endAddr - nullBytes + 1 to: endAddr 
		do: [ :p | objectMemory byteAt: p put: 16rFF]
]

{ #category : #encoding }
CogARMv8Compiler >> pld: baseReg plus: u offset: immediate [
	"hint to memory that we will want to read from baseReg +/- imediate sometime soon
	PLD baseReg, immediate  - ARM_ARM v7 DDI10406 pp. A8-236-7"
	<inline: true>
	^ 2r11110101010100001111000000000000 bitOr: (baseReg<<16 bitOr:(u <<23 bitOr: immediate))
]

{ #category : #assembler }
CogARMv8Compiler >> popR: dstReg [
"	pop word off TOS
	LDR srcReg, [sp] #4 - ARM_ARM v7 DDI10406 pp. A8-120-1"
	^ self
		ldrSize: 1
		baseRegister: SPReg
		signedOffset: 8
		destinationRegister: dstReg
		preIndex: 0
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> prefetchMemory: prefetchOperationFlags sourceRegister: sourceRegister offset: offset [
	
	"C6.2.212 PRFM (immediate)
	
	Prefetch Memory (immediate) signals the memory system that data memory accesses from a specified address are likely to occur in the near future. The memory system can respond by taking actions that are expected to speed up the memory accesses when they do occur, such as preloading the cache line containing the specified address into one or more caches.
	
	PRFM (<prfop>|#<imm5>), [<Xn|SP>{, #<pimm>}]"
	
	^ 2r1111100110 << 22
		bitOr: ((offset bitAnd: 16rfff) << 10
		bitOr: ((sourceRegister bitAnd: 16r1f) << 5
		bitOr: (prefetchOperationFlags bitAnd: 16r1f)))
]

{ #category : #'calling C function in Smalltalk stack' }
CogARMv8Compiler >> prepareStackToCallCFunctionInSmalltalkStack: anObject [ 

	"In ARMv8 we are using an alternative SPReg that is not the machine SP.
	We need to sync the SP register to the Smalltalk stackPointer, so the called function 
	will execute correctly."
	
	cogit MoveR: SPReg R: Extra2Reg.

	"ARMv8 should be aligned to 16 bytes"

	cogit AndCq: ((1 << 64) - 16) R: Extra2Reg. 
	cogit MoveR: Extra2Reg R: SP.
]

{ #category : #accessing }
CogARMv8Compiler >> pushLinkRegisterByteSize [
	^4
]

{ #category : #'ARM convenience instructions' }
CogARMv8Compiler >> pushR: srcReg [
	
	^ self strSize: 1
		baseRegister: SPReg
		signedOffset: -8 "word size, size of the elements in the stack"
		sourceRegister: srcReg
		preIndex: 1 "Access before incrementing"
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> relocateCallBeforeReturnPC: retpc by: delta [
	| instr distanceDiv4 |
	self assert: delta \\ 4 = 0.
	delta ~= 0 ifTrue:
		[instr := self instructionBeforeAddress: retpc.
		 self assert: ((self instructionIsB: instr) or: [self instructionIsBL: instr]).
		 distanceDiv4 := instr bitAnd: 16rFFFFFF.
		 distanceDiv4 := distanceDiv4 + (delta // 4).
		 objectMemory long32At: (self instructionAddressBefore: retpc ) put: ((instr bitAnd: 16rFF000000) bitOr: (distanceDiv4 bitAnd: 16rFFFFFF))]
]

{ #category : #assembler }
CogARMv8Compiler >> ret [
	
	"C6.2.219 RET
	
	Return from subroutine branches unconditionally to an address in a register, with a hint that this is a subroutine return."
	
	^ (2r1101011001011111000000 << 10)
		bitOr: LR << 5
]

{ #category : #'calling C function in Smalltalk stack' }
CogARMv8Compiler >> returnFromCallCFunctionInSmalltalkStack: anObject [ 

	"In ARMv8 I don't need to do nothing"

]

{ #category : #patching }
CogARMv8Compiler >> rewriteBranch: conditionalBranch withNewOffset: newOffset [
	
	"Rewrite the offset inside a branch instruction of the form: 
	26-bit signed PC-relative branch offset variant
	
	B <label>
	
	<label> Is the program label to be unconditionally branched to. Its offset from the address of this instruction, in the range +/-128MB, is encoded as imm26 times 4."
	
	self seeAlso: #b:.
	^ self b: newOffset
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> rewriteCPICJumpAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a jump instruction to call a different target.  This variant is used to reset the 
	jumps in the prototype CPIC to suit each use,.   
	Answer the extent of the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	| callDistance instr |

	callTargetAddress >= cogit minCallAddress
		ifFalse: [self error: 'linking callsite to invalid address'].

	callDistance := (callTargetAddress - (callSiteReturnAddress - 4 "return offset")).
	self assert: (self isInImmediateJumpRange: callDistance). "we don't support long call updates, yet"

	instr := self instructionBeforeAddress: callSiteReturnAddress.
	self assert: (self instructionIsConditionalBranch: instr).

	objectMemory
		long32At: (self instructionAddressBefore: callSiteReturnAddress)
		put: (self branchCondition: (self extractConditionFromB: instr) offset: callDistance).

	self assert: (self extractOffsetFromConditionalBranch: ((self branchCondition: (self extractConditionFromB: instr) offset: callDistance))) = callDistance.
	^4
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> rewriteCallAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a call instruction to call a different target.  This variant is used to link PICs
	 in ceSendMiss et al,.   
	Answer the extent of the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	^self rewriteTransferAt: callSiteReturnAddress target: callTargetAddress
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> rewriteCallFullAt: callSiteReturnAddress target: callTargetAddress [
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
CogARMv8Compiler >> rewriteConditionalJumpLongAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a jump instruction to call a different target.  This variant is used to reset the 
	jumps in the prototype CPIC to suit each use,.   
	Answer the extent of the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	| callDistance instr |

	callTargetAddress >= cogit minCallAddress
		ifFalse: [self error: 'linking callsite to invalid address'].

	callDistance := (callTargetAddress - (callSiteReturnAddress - 4 "return offset")).
	self assert: (self isInImmediateJumpRange: callDistance). "we don't support long call updates, yet"

	instr := self instructionBeforeAddress: callSiteReturnAddress.
	self assert: (self instructionIsConditionalBranch: instr).

	objectMemory
		long32At: (self instructionAddressBefore: callSiteReturnAddress)
		put: (self branchCondition: (self extractConditionFromB: instr) offset: callDistance).

	self assert: (self extractOffsetFromConditionalBranch: ((self branchCondition: (self extractConditionFromB: instr) offset: callDistance))) = callDistance.
	^4
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> rewriteFullTransferAt: callSiteReturnAddress target: callTargetAddress expectedInstruction: expectedInstruction [
	"Rewrite a CallFull or JumpFull instruction to transfer to a different target.
	 This variant is used to rewrite cached primitive calls.   Answer the extent
	 of the code change which is used to compute the range of the icache to flush."
	^self subclassResponsibility
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> rewriteInlineCacheAt: callSiteReturnAddress tag: cacheTag target: callTargetAddress [
	"Rewrite an inline cache to call a different target for a new tag.  This variant is used
	 to link unlinked sends in ceSend:to:numArgs: et al.  Answer the extent of the code
	 change which is used to compute the range of the icache to flush."
	
	^self subclassResponsibility
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> rewriteJumpFullAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a full jump instruction to jump to a different target.  This variant
	 is used to rewrite cached primitive calls where we load the target address into ip
	and use the 'bx ip' instruction for the actual jump.
	Answer the extent of the
	 code change which is used to compute the range of the icache to flush."
	<inline: true>
	
	^self
		rewriteFullTransferAt: callSiteReturnAddress
		target: callTargetAddress
		expectedInstruction: 16rD61F0200 "This is the assembled instruction br x16. This will break if we change the assignment of registers"
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> rewriteJumpLongAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a jump instruction to call a different target.  This variant is used to reset the 
	jumps in the prototype CPIC to suit each use,.   
	Answer the extent of the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	^self rewriteTransferAt: callSiteReturnAddress target: callTargetAddress
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> rewriteTransferAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a call/jump instruction to call a different target.  This variant is used to link PICs
	 in ceSendMiss et al, and to rewrite call/jumps in CPICs.
	Answer the extent of
	 the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	| callDistance instr |

	callTargetAddress >= cogit minCallAddress
		ifFalse: [self error: 'linking callsite to invalid address'].

	callDistance := (callTargetAddress - (callSiteReturnAddress - 4 "return offset")).
	self assert: (self isInImmediateJumpRange: callDistance). "we don't support long call updates, yet"

	instr := self instructionBeforeAddress: callSiteReturnAddress.
	self assert: ((self instructionIsB: instr) or: [self instructionIsBL: instr]).

	objectMemory
		long32At: (self instructionAddressBefore: callSiteReturnAddress)
		put: (self b: callDistance withLink: (self instructionIsBL: instr)).

	self assert: (self callTargetFromReturnAddress: callSiteReturnAddress) = callTargetAddress.

	^4
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> rightShiftSize: is64Bits sourceRegister: sourceRegister shiftValue: shiftValue shiftType: shiftType destinationRegister: destinationRegister [
	
	"C3.3.9 Shift (immediate)
	
	Shifts and rotates by a constant amount are implemented as aliases of the Bitfield move or Extract register instructions. The shift or rotate amount must be in the range 0 to one less than the register width of the instruction, inclusive.
	
	LSR <Xd>, <Xn>, #<shift>  => shiftType = 10
	ASR <Xd>, <Xn>, #<shift>  => shiftType = 00
	
	"
	
	^ (is64Bits bitAnd: 1) << 31
		bitOr: ((shiftType bitAnd: 2r11) << 29
		bitOr: (2r100110 << 23
		bitOr: ((is64Bits bitAnd: 1) << 31
		bitOr: ((shiftValue bitAnd: 2r111111) << 16
		bitOr: ((2r11111 << 10)
		bitOr: ((sourceRegister bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111)))))))
]

{ #category : #assembler }
CogARMv8Compiler >> rorSize: is64bits sourceRegister: sourceRegister rotationBits: immediate6bitValue destinationRegister: destinationRegister [

	"C6.2.226 ROR (immediate)
	
	Rotate right (immediate) provides the value of the contents of a register rotated by a variable number of bits. The bits that are rotated off the right end are inserted into the vacated bit positions on the left.
	
	ROR <Xd>, <Xs>, #<shift>"
	
	^ (is64bits bitAnd: 1) << 31
		bitOr: (2r100111 << 23
		bitOr: ((is64bits "N" bitAnd: 1) << 22
		bitOr: ((sourceRegister bitAnd: 16r1f) << 16
		bitOr: ((immediate6bitValue bitAnd: 16r3f) << 10
		bitOr: ((sourceRegister bitAnd: 16r1f) << 5
		bitOr: ((destinationRegister bitAnd: 16r1f)))))))
]

{ #category : #testing }
CogARMv8Compiler >> rotateable8bitBitwiseImmediate: constant ifTrue: trueAlternativeBlock ifFalse: falseAlternativeBlock [
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
CogARMv8Compiler >> rotateable8bitImmediate: constant ifTrue: trueAlternativeBlock ifFalse: falseAlternativeBlock [
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
CogARMv8Compiler >> rotateable8bitSignedImmediate: constant ifTrue: trueAlternativeBlock ifFalse: falseAlternativeBlock [
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
CogARMv8Compiler >> saveAndRestoreLinkRegAround: aBlock [
	"If the processor's ABI includes a link register, generate instructions
	 to save and restore it around aBlock, which is assumed to generate code."
	<inline: true>
	| inst |
	inst := cogit PushR: LinkReg.
	aBlock value.
	cogit PopR: LinkReg.
	^inst
]

{ #category : #assembler }
CogARMv8Compiler >> scalarConvertSize: is64Bits fromScalarRegister: scalarRegister toDoublePrecisionFloatRegister: doublePrecisionFloatingPointRegister [

	"C7.2.236 SCVTF (scalar, integer)
	
	Signed integer Convert to Floating-point (scalar). This instruction converts the signed integer value in the general-purpose source register to a floating-point value using the rounding mode that is specified by the FPCR, and writes the result to the SIMD&FP destination register.
	
	64-bit to double-precision variant
	
	SCVTF <Dd>, <Xn>"

	^ ((is64Bits bitAnd: 1) << 31)
		bitOr: (2r1111 << 25
		bitOr: (2r01 "double precision" << 22
		bitOr: (2r10001 << 17
		bitOr: ((scalarRegister bitAnd: 16r1f) << 5
		bitOr: (doublePrecisionFloatingPointRegister bitAnd: 16r1f)))))
]

{ #category : #assembler }
CogARMv8Compiler >> sdivSize: is64Bits numeratorReg: numeratorReg denominatorReg: denominatorReg destinationRegister: destinationReg [ 

	"C6.2.235 SDIV
		A64 Base Instruction Descriptions C6.2 Alphabetical list of A64 base instructions
		Signed Divide divides a signed integer register value by another signed integer register value, and writes the result to the destination register. The condition flags are not affected.
		
		SDIV <Xd>, <Xn>, <Xm>"
		
	^ is64Bits << 31
		bitOr: (2r11010110 << 21
		bitOr: ((denominatorReg bitAnd: 16r1f) << 16
		bitOr: (2r11 << 10
		bitOr: ((numeratorReg bitAnd: 16r1f) << 5
		bitOr: (destinationReg bitAnd: 16r1f)))))
]

{ #category : #testing }
CogARMv8Compiler >> setsConditionCodesFor: aConditionalJumpOpcode [
	<inline: false> "to save Slang from having to be a real compiler (it can't inline switches that return)"
	"Answer if the receiver's opcode sets the condition codes correctly for the given conditional jump opcode.
	ARM has to check carefully since the V flag is not affected by non-comparison instructions"
	^opcode caseOf:
		{	[ArithmeticShiftRightCqR]	->	[false].
			[ArithmeticShiftRightRR]		->	[false].
			[LogicalShiftLeftCqR]			->	[false].
			[LogicalShiftLeftRR]			->	[false].
			[LogicalShiftRightCqR]		->	[false].
			[XorRR]							->	[false]
		}
		otherwise: [self logError: 'unhandled opcode in setsConditionCodesFor:'. self abort. false]
]

{ #category : #testing }
CogARMv8Compiler >> shiftSetsConditionCodesFor: aConditionalJumpOpcode [
	"check what flags the opcdoe needs setting - ARM doesn't set V when simply MOVing"
		^aConditionalJumpOpcode caseOf:
		{	[JumpNegative]	->	[true].
			[JumpZero]	->	[true].
			[JumpLess]	->	[true].
		}
		otherwise: [self halt: 'unhandled opcode in setsConditionCodesFor:'. false]
]

{ #category : #testing }
CogARMv8Compiler >> shiftable16bitImmediate: constant ifTrue: trueAlternativeBlock ifFalse: falseAlternativeBlock [
	<inline: true>
	"For data processing operands, there is the immediate shifter_operand variant, 
	 where an 16 bit value is left shifted by i.
	 This is only suitable for quick constants(Cq), which won't change."
	
	(constant bitAnd: 16rFFFF) = constant ifTrue:
		[^trueAlternativeBlock value: 0 value: constant].
	0 to: 2 do: [:i | | shiftedValue shiftMagnitude |
		shiftMagnitude := (1 << i) * 16.
		shiftedValue := constant >> shiftMagnitude.
		(shiftedValue << shiftMagnitude = constant and: [ (shiftedValue bitAnd: 16rFFFF) = shiftedValue ])
			ifTrue: [ ^ trueAlternativeBlock
					value: shiftMagnitude
					value: shiftedValue ] ].
	^falseAlternativeBlock value
]

{ #category : #assembler }
CogARMv8Compiler >> sizeOf: immediate registerSize: registerSize [

	"First, determine the element size."
	| size |
	size := registerSize.
	[ | mask |
		size := size / 2.
		mask := 1 << size - 1.
		(immediate bitAnd: mask) ~= ((immediate >> size) bitAnd: mask)
			ifTrue: [ ^ size * 2 ].
		size > 2 ] whileTrue.
	
	^ size
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> smulhSize: is64bits firstRegister: registerA secondRegister: registerB destinationRegister: destinationRegister [

	"C6.2.243 SMULH
	
	Signed Multiply High multiplies two 64-bit register values, and writes bits[127:64] of the 128-bit result to the 64-bit destination register.
	
	SMULH <Xd>, <Xn>, <Xm>"
	
	^ 2r1001101101 << 22
		bitOr: (((registerB bitAnd: 16r1f) << 16)
		bitOr: (16r1f << 10
		bitOr: (((registerA bitAnd: 16r1f) << 5)
		bitOr: (destinationRegister bitAnd: 16r1f))))
]

{ #category : #accessing }
CogARMv8Compiler >> stackPageInterruptHeadroomBytes [
	"Return a minimum amount of headroom for each stack page (in bytes).  In a
	 JIT the stack has to have room for interrupt handlers which will run on the stack.
	According to ARM architecture v5 reference manual chapter A2.6, the basic interrupt procedure does not push anything onto the stack. It uses SPSR_err and R14_err to preserve state. Afterwards, it calls an interrupt procedure. So leave some room."
	^128 "32 words"
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> stackPointerAlignment [
	
	<doNotGenerate>
	"As for the ARMv8 Arm® Architecture Reference Manual
	
	D1.8.2 SP alignment checking
	A misaligned stack pointer is where bits[3:0] of the stack pointer are not 0b0000, when the stack pointer is used as the base address of the calculation, regardless of any offset applied by the instruction.
	
	Meaning that the stack should be aligned to 16 bytes"

	^ 16
]

{ #category : #encoding }
CogARMv8Compiler >> stop [

	"C6.2.38 BRK
	
	Breakpoint instruction. A BRK instruction generates a Breakpoint Instruction exception.
	
	BRK #<imm>"
	
	"This is a BRK 0..."
	^ 2r11010100001 << 21
]

{ #category : #'generate machine code - support' }
CogARMv8Compiler >> stopsFrom: startAddr to: endAddr [
	self assert: endAddr - startAddr + 1 \\ 4 = 0.
	startAddr to: endAddr by: 4 do: 
		[:addr | objectMemory long32At: addr put: self stop].
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> storeLiteral: literal beforeFollowingAddress: followingAddress [
	"Rewrite the long constant loaded by the instruction sequence just before this address:"
	^self subclassResponsibility
]

{ #category : #'ARM convenience instructions' }
CogARMv8Compiler >> str: destinationRegister rn: baseReg plus: u imm: immediate9bitValue [
"	STR destReg, [baseReg, 'u' immediate12bitValue] u=0 -> subtract imm; =1 -> add imm - ARM_ARM v7 DDI10406 pp. A8-382-3 "

	^ self
		sturSize: 1
		baseRegister: baseReg
		signedOffset: (u = 0 ifTrue: [ immediate9bitValue negated ] ifFalse: [ immediate9bitValue ])
		destinationRegister: destinationRegister
]

{ #category : #assembler }
CogARMv8Compiler >> strBaseRegister: baseReg positiveOffset: immediate12bitValue sourceDoublePrecisionFloatingPointRegister: sourceRegister [

	"C7.2.331 STR (immediate, SIMD&FP)
	
	Store SIMD&FP register (immediate offset). This instruction stores a single SIMD&FP register to memory. The address that is used for the store is calculated from a base register value and an immediate offset.
	
	Unsigned offset Variant
		
	STR <Dt>, [<Xn|SP>{, #<pimm>}]
		
	only 64bits are supported for now
	"

	^ 2r11 << 30
		bitOr: (2r111101 << 24
		bitOr: ((immediate12bitValue / 8 bitAnd: 16rfff) << 10
		bitOr: ((baseReg bitAnd: 16r1f) << 5
		bitOr: (sourceRegister bitAnd: 16r1f))))
]

{ #category : #assembler }
CogARMv8Compiler >> strBaseRegister: baseReg positiveOffset: immediate12bitValue sourceFloatingPointRegister: sourceRegister precision: size [

	"C7.2.331 STR (immediate, SIMD&FP)
	
	Store SIMD&FP register (immediate offset). This instruction stores a single SIMD&FP register to memory. The address that is used for the store is calculated from a base register value and an immediate offset.
	
	Unsigned offset Variant
		
	STR <Dt>, [<Xn|SP>{, #<pimm>}]
	"

	^ (size bitOr: 2r11) << 30
		bitOr: (2r111101 << 24
		bitOr: ((immediate12bitValue / 8 bitAnd: 16rfff) << 10
		bitOr: ((baseReg bitAnd: 16r1f) << 5
		bitOr: (sourceRegister bitAnd: 16r1f))))
]

{ #category : #assembler }
CogARMv8Compiler >> strSize: is64Bits addressRegister: baseRegister storedRegister: storedRegister [

	^ self
		strSize: is64Bits
		baseRegister: address
		offsetRegister: 0
		extension: 2r011 "LSL"
		shift: 1
		storedRegister: storedRegister
]

{ #category : #assembler }
CogARMv8Compiler >> strSize: is64Bits baseRegister: baseRegister offsetRegister: offsetRegister extension: extensionType shift: shiftFlag storedRegister: storedRegister [

	"C6.2.275 STR (register)
	
	Store Register (register) calculates an address from a base register value and an offset register value, and stores a 32-bit word or a 64-bit doubleword to the calculated address, from a register. For information about memory accesses, see Load/Store addressing modes on page C1-189.
		
	The instruction uses an offset addressing mode, that calculates the address used for the memory access from a base register value and an offset register value. The offset can be optionally shifted and extended
	
	STR <Xt>, [<Xn|SP>, (<Wm>|<Xm>){, <extend> {<amount>}}]"

	^ 1 << 31
		bitOr: ((is64Bits bitAnd: 1) << 30
		bitOr: (2r111000001 << 21
		bitOr: ((offsetRegister bitAnd: 2r11111) << 16
		bitOr:((extensionType bitAnd: 2r111) << 13
		bitOr: ((shiftFlag bitAnd: 1) << 12
		bitOr: (2r10 << 10
		bitOr: ((baseRegister bitAnd: 2r11111) << 5
		bitOr: (storedRegister bitAnd: 2r11111))))))))
]

{ #category : #assembler }
CogARMv8Compiler >> strSize: is64Bits baseRegister: baseReg positiveOffset: immediate12bitValue destinationRegister: destinationRegister [

	"Encodes a Load Register (immediate) instruction of the form
		
	STR <Xt>, [<Xn|SP>{, #<pimm>}]"

	self assert: immediate12bitValue >= 0.
	^ 1 << 31
		bitOr: ((is64Bits bitAnd: 1) << 30
		bitOr: (2r11100100 << 22
		bitOr: ((immediate12bitValue / 8 bitAnd: 2r111111111111) << 10
		bitOr:((baseReg bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111)))))
]

{ #category : #assembler }
CogARMv8Compiler >> strSize: is64Bits baseRegister: baseRegister signedOffset: immediate9bitValue sourceRegister: sourceRegister preIndex: preIndex [

	"Encodes a Load Register (immediate) instruction of the form
		
	STR <Xt>, [<Xn|SP>, #<simm>]!"
	
	| twoComplement |
	twoComplement := immediate9bitValue > 0
		ifTrue: [ immediate9bitValue ]
		ifFalse: [ 2r111111111 - immediate9bitValue abs + 1 ].

	^ 1 << 31
		bitOr: ((is64Bits bitAnd: 1) << 30
		bitOr: (2r111000000 << 21
		bitOr: ((twoComplement bitAnd: 2r111111111) << 12
		bitOr: (preIndex << 11
		bitOr:(1 << 10
		bitOr:((baseRegister bitAnd: 2r11111) << 5
		bitOr: (sourceRegister bitAnd: 2r11111)))))))
]

{ #category : #assembler }
CogARMv8Compiler >> strbBaseRegister: baseRegister offsetRegister: offsetRegister extension: extensionType shift: shiftFlag srcRegister: srcRegister [

		"C6.2.277 STRB (register)
		
		Store Register Byte (register) calculates an address from a base register value and an offset register value, and stores a byte from a 
		32-bit register to the calculated address. For information about memory accesses, see Load/Store addressing modes on page C1-189.
		The instruction uses an offset addressing mode, that calculates the address used for the memory access from a base register value and 
		an offset register value. The offset can be optionally shifted and extended.
		
	STRB <Wt>, [<Xn|SP>, <Xm>{, LSL <amount>}]"

	^ 2r00111000001 << 21
		bitOr: ((offsetRegister bitAnd: 16r1F) << 16
		bitOr:((extensionType bitAnd: 2r111) << 13
		bitOr: ((shiftFlag bitAnd: 1) << 12
		bitOr: (2r10 << 10
		bitOr: ((baseRegister bitAnd: 16r1F) << 5
		bitOr: (srcRegister bitAnd: 16r1F))))))
]

{ #category : #assembler }
CogARMv8Compiler >> strbSourceRegister: sourceRegister destinationRegister: destinationRegister [
	
	"C6.2.276 STRB (immediate)

	Store Register Byte (immediate) stores the least significant byte of a 32-bit register to memory. The address that is used for the store is calculated from a base register and an immediate offset. 
	
	Unsigned offset variant
	STRB <Wt>, [<Xn|SP>{, #<pimm>}]"
	
	
	^ self strbSourceRegister: sourceRegister destinationRegister: destinationRegister offset: 0
]

{ #category : #assembler }
CogARMv8Compiler >> strbSourceRegister: sourceRegister destinationRegister: destinationRegister offset: immediate12BitValue [
	
	"C6.2.276 STRB (immediate)

	Store Register Byte (immediate) stores the least significant byte of a 32-bit register to memory. The address that is used for the store is calculated from a base register and an immediate offset. 
	
	Unsigned offset variant
	STRB <Wt>, [<Xn|SP>{, #<pimm>}]"
	
	^ 2r111 << 27
		bitOr: (1 << 24
		bitOr: ((immediate12BitValue bitAnd: 16rfff) << 10
		bitOr: ((destinationRegister bitAnd: 16r1f) << 5
		bitOr: (sourceRegister bitAnd: 16r1f))))
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> strhSourceRegister: sourceRegister destinationRegister: destinationRegister offset: immediate12BitValue [
	
	"C6.2.278 STRH (immediate)

	Store Register Halfword (immediate) stores the least significant halfword of a 32-bit register to memory. The address that is used for the store is calculated from a base register and an immediate offset.
		
	Unsigned offset variant
	STRH <Wt>, [<Xn|SP>{, #<pimm>}]"
	
	^ 2r1111 << 27
		bitOr: (1 << 24
		bitOr: ((immediate12BitValue bitAnd: 16rfff) << 10
		bitOr: ((destinationRegister bitAnd: 16r1f) << 5
		bitOr: (sourceRegister bitAnd: 16r1f))))
]

{ #category : #assembler }
CogARMv8Compiler >> sturSize: is64Bits baseRegister: baseReg signedOffset: immediate9bitValue destinationRegister: destinationRegister [

	"C6.2.298 STUR
	
	Store Register (unscaled) calculates an address from a base register value and an immediate offset, and stores a 32-bit word or a 64-bit doubleword to the calculated address, from a register. For information about memory accesses
		
	STUR <Xt>, [<Xn|SP>{, #<simm>}]"

	| twoComplement |
	twoComplement := immediate9bitValue > 0
		ifTrue: [ immediate9bitValue ]
		ifFalse: [ 2r111111111 - immediate9bitValue abs + 1 ].

	self assert: twoComplement > 0.
	^ 1 << 31
		bitOr: ((is64Bits bitAnd: 1) << 30
		bitOr: (2r111000000 << 21
		bitOr: ((twoComplement bitAnd: 2r111111111) << 12
		bitOr:((baseReg bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111)))))
]

{ #category : #assembler }
CogARMv8Compiler >> subsExtendedSize: is64Bits leftRegisterMaybeSP: leftRegister shiftedRightRegister: rightRegister option: option shiftOffset: immediate3bitValue destinationRegister: destinationRegister [
	
	"C6.2.314 SUBS (extended register)
	
	Subtract (extended register), setting flags, subtracts a sign or zero-extended register value, followed by an optional left shift amount, from a register value, and writes the result to the destination register. The argument that is extended from the <Rm> register can be a byte, halfword, word, or doubleword. It updates the condition flags based on the result
	
	SUBS <Xd>, <Xn|SP>, <R><m>{, <extend> {#<amount>}}"
	
	^ is64Bits << 31
		bitOr: (2r1101011001 << 21
		bitOr: ((rightRegister bitAnd: 16r1f) << 16
		bitOr: ((option bitAnd: 2r11) << 13
		bitOr: ((immediate3bitValue bitAnd: 2r111) << 10
		bitOr: ((leftRegister bitAnd: 16r1f) << 5
		bitOr: (destinationRegister bitAnd: 16r1f))))))
]

{ #category : #assembler }
CogARMv8Compiler >> subsSize: is64Bits leftRegister: leftRegister shiftedRightRegister: rightRegister shiftType: shiftType shiftOffset: immediate6bitValue destinationRegister: destinationRegister [

	"C6.2.316 SUBS (shifted register)
	
	Subtract (shifted register), setting flags, subtracts an optionally-shifted register value from a register value, and writes the result to the destination register. It updates the condition flags based on the result.
		
	SUBS <Xd>, <Xn>, <Xm>{, <shift> #<amount>}
	
	LSL when shift = 00
	LSR when shift = 01
	ASR when shift = 10"

	^ self
		arithmeticShiftedRegisterSize: is64Bits
		isSubstraction: 1
		setFlags: 1
		leftRegister: leftRegister
		shiftedRightRegister: rightRegister
		shiftType: shiftType
		shiftOffset: immediate6bitValue
		destinationRegister: destinationRegister
]

{ #category : #assembler }
CogARMv8Compiler >> subsSize: is64Bits sourceRegister: leftRegister immediate12BitValue: immediate12BitValue shifted: shiftedFlag destinationRegister: destinationRegister [

	"C6.2.315 SUBS (immediate)
	
	Subtract (immediate), setting flags, subtracts an optionally-shifted immediate value from a register value, and writes the result to the destination register. It updates the condition flags based on the result.
		
	SUBS <Xd>, <Xn|SP>, #<imm>{, <shift>}"

	^ self
		arithmeticImmediateSize: is64Bits
		isSubstraction: 1
		setFlags: 1
		sourceRegister: leftRegister
		immediate12BitValue: immediate12BitValue
		shifted: shiftedFlag
		destinationRegister: destinationRegister
]

{ #category : #assembler }
CogARMv8Compiler >> subsSize: is64Bits sourceRegister: sourceRegister shift: shift immediate12: immediate12bitValue destinationRegister: destinationRegister [
	
	"C6.2.315 SUBS (immediate)
	
	Subtract (immediate), setting flags, subtracts an optionally-shifted immediate value from a register value, and writes the result to the destination register. It updates the condition flags based on the result.
	
	SUBS <Xd>, <Xn|SP>, #<imm>{, <shift>}
	
	if shift = 1 the immediate will be shifted by 12
	"
	
	| isSubstractionFlag setFlagsFlag |
	^ is64Bits << 31
		bitOr: ((isSubstractionFlag := 1 bitAnd: 1) << 30
		bitOr: ((setFlagsFlag := 1 bitAnd: 1) << 29
		bitOr: (2r100010 << 23
		bitOr: ((shift bitAnd: 2r1) << 22
		bitOr: (immediate12bitValue << 10
		bitOr: ((sourceRegister bitAnd: 2r11111) << 5
		bitOr: (destinationRegister bitAnd: 2r11111)))))))
]

{ #category : #'private-bit-manipulation' }
CogARMv8Compiler >> trailingOnesOf: aNumber [
	"Return how many trailing ones are in the 64bit bitString representation of aNumber.
	That is, how many ones are in the least significant bits before there is a zero.
	For example, the 64bit binary number 2r10101000110001111 has 4 trailing ones"
	
	"Calculate it by calculating the trailing zeros of the bit-inverted number"
	^ self trailingZerosOf: aNumber bitInvert64
]

{ #category : #'private-bit-manipulation' }
CogARMv8Compiler >> trailingZerosOf: aNumber [
	"Return how many trailing zeros are in the 64bit bitString representation of aNumber.
	That is, how many zeros are in the least significant bits before there is a one.
	For example, the 64bit binary number 2r10101000110001111000 has 3 trailing zeros.
	
	Uses a bisect method looking at the number by halfs"
	
	| zeroBits shift mask currentNumber |
	"First two fast cases. If 1 or 0, return some quick constants"
	aNumber = 0
		ifTrue: [ ^ 64 "bits" ].

	(aNumber bitAnd: 1) = 1
		ifTrue: [ ^ 0 ].
 
	"Otherwise calculate trailing zeros by iterating the number with a mask and accumulating a value"
	zeroBits := 0.

	"This is a bisection method to iterate a 64-long bitstring in log2.
	It will first look at the least significant half of the number using a mask of half of its size.
	If they are all zeros, taking the other half of the number by shifting it.
	Of they are not all zeros, continue with this half.
	Then iterate with half the mask and shift sizes."
	shift := 64 "bits" >> 1.
	mask := 16rFFFFFFFFFFFFFFFF >> shift.
	currentNumber := aNumber.
	
	[ shift ~= 0 ] whileTrue: [ 
		(currentNumber bitAnd: mask) = 0 ifTrue: [ 
			"If this half is all zeros, let's take the other half of the number"
			currentNumber := currentNumber >> shift.
			"Also, mark that we found zeros of the size of the current shift"
			zeroBits := zeroBits bitOr: shift.
		].
		"Continue next iterations with masks half the size"
		shift := shift >> 1.
		mask := mask >> shift.
	].

	^ zeroBits
]

{ #category : #assembler }
CogARMv8Compiler >> tstSize: is64bits immediate13bitValue: immediate13bitValue register: registerToUse [

	"C6.2.330 TST (immediate)
	
	Test bits (immediate) , setting the condition flags and discarding the result : Rn AND imm
	
	TST <Xn>, #<imm>
	"

	^ is64bits << 31
		bitOr: (2r11100100 << 23
		bitOr: (immediate13bitValue << 10
		bitOr: ((registerToUse bitAnd: 2r11111) << 5
		bitOr: 2r11111)))
]

{ #category : #'as yet unclassified' }
CogARMv8Compiler >> unsignedBitfieldMoveSize: is64Bits immr: immr imms: imms sourceRegister: sourceRegister destinationRegister: destinationRegister [
	
	"C6.2.333 UBFM
	
	Unsigned Bitfield Move is usually accessed via one of its aliases, which are always preferred for disassembly.
	If <imms> is greater than or equal to <immr>, this copies a bitfield of (<imms>-<immr>+1) bits starting from bit position <immr> in the source register to the least significant bits of the destination register.
	
	If <imms> is less than <immr>, this copies a bitfield of (<imms>+1) bits from the least significant bits of the source register to bit position (regsize-<immr>) of the destination register, where regsize is the destination register size of 32 or 64 bits.
	
	In both cases the destination bits below and above the bitfield are set to zero
	
	UBFM <Xd>, <Xn>, #<immr>, #<imms>
	"
	
	^ is64Bits << 31
		bitOr: (2r10100110 << 23
		bitOr: ((is64Bits bitAnd: 1) << 22
		bitOr: ((immr bitAnd: 16r3f) << 16
		bitOr: ((imms bitAnd: 16r3f) << 10
		bitOr: ((sourceRegister bitAnd: 16r1f) << 5
		bitOr: (destinationRegister bitAnd: 16r1f))))))
]

{ #category : #simulation }
CogARMv8Compiler >> wantsNearAddressFor: anObject [
	"A hack hook to allow ARM to override the simulated address for the short-cut trampolines"
	<doNotGenerate>
	^anObject isSymbol and: [anObject beginsWith: 'ceShortCut']
]

{ #category : #'inline cacheing' }
CogARMv8Compiler >> zoneCallsAreRelative [
	"Answer if Call and JumpLong are relative and hence need to take the caller's
	 relocation delta into account during code compaction, rather than just the
	 callee's delta."
	^true
]
