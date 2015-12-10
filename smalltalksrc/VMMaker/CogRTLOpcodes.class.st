"
I am a pool for the Register-Transfer-Language to which Cog compiles.  I define unique integer values for all RTL opcodes and abstract registers.  See CogAbstractInstruction for instances of instructions with the opcodes that I define.
"
Class {
	#name : #CogRTLOpcodes,
	#superclass : #SharedPool,
	#classVars : [
		'AddCqR',
		'AddCwR',
		'AddRR',
		'AddRdRd',
		'AlignmentNops',
		'AndCqR',
		'AndCqRR',
		'AndCwR',
		'AndRR',
		'Arg0Reg',
		'Arg1Reg',
		'ArithmeticShiftRightCqR',
		'ArithmeticShiftRightRR',
		'Call',
		'CallFull',
		'ClassReg',
		'CmpC32R',
		'CmpCqR',
		'CmpCwR',
		'CmpRR',
		'CmpRdRd',
		'ConvertRRd',
		'DPFPReg0',
		'DPFPReg1',
		'DPFPReg2',
		'DPFPReg3',
		'DPFPReg4',
		'DPFPReg5',
		'DPFPReg6',
		'DPFPReg7',
		'DivRdRd',
		'FPReg',
		'Fill16',
		'Fill32',
		'Fill8',
		'FillBytesFrom',
		'FillFromWord',
		'FirstJump',
		'FirstShortJump',
		'Jump',
		'JumpAbove',
		'JumpAboveOrEqual',
		'JumpBelow',
		'JumpBelowOrEqual',
		'JumpCarry',
		'JumpFPEqual',
		'JumpFPGreater',
		'JumpFPGreaterOrEqual',
		'JumpFPLess',
		'JumpFPLessOrEqual',
		'JumpFPNotEqual',
		'JumpFPOrdered',
		'JumpFPUnordered',
		'JumpFull',
		'JumpGreater',
		'JumpGreaterOrEqual',
		'JumpLess',
		'JumpLessOrEqual',
		'JumpLong',
		'JumpLongNonZero',
		'JumpLongZero',
		'JumpNegative',
		'JumpNoCarry',
		'JumpNoOverflow',
		'JumpNonNegative',
		'JumpNonZero',
		'JumpOverflow',
		'JumpR',
		'JumpZero',
		'Label',
		'LastJump',
		'LastRTLCode',
		'LinkReg',
		'Literal',
		'LoadEffectiveAddressMwrR',
		'LoadEffectiveAddressXowrR',
		'LogicalShiftLeftCqR',
		'LogicalShiftLeftRR',
		'LogicalShiftRightCqR',
		'LogicalShiftRightRR',
		'MoveAbR',
		'MoveAwR',
		'MoveC32R',
		'MoveC64R',
		'MoveCqR',
		'MoveCwR',
		'MoveM16rR',
		'MoveM32rR',
		'MoveM64rRd',
		'MoveMbrR',
		'MoveMwrR',
		'MoveRAb',
		'MoveRAw',
		'MoveRM16r',
		'MoveRM32r',
		'MoveRMbr',
		'MoveRMwr',
		'MoveRR',
		'MoveRRd',
		'MoveRX16rR',
		'MoveRX32rR',
		'MoveRXbrR',
		'MoveRXowr',
		'MoveRXwrR',
		'MoveRdM64r',
		'MoveRdR',
		'MoveRdRd',
		'MoveX16rRR',
		'MoveX32rRR',
		'MoveXbrRR',
		'MoveXowrR',
		'MoveXwrRR',
		'MulRdRd',
		'NegateR',
		'NoReg',
		'Nop',
		'OrCqR',
		'OrCwR',
		'OrRR',
		'PCReg',
		'PopR',
		'PrefetchAw',
		'PushCq',
		'PushCw',
		'PushR',
		'RISCTempReg',
		'ReceiverResultReg',
		'RetN',
		'RotateLeftCqR',
		'RotateRightCqR',
		'SPReg',
		'Scratch0Reg',
		'Scratch1Reg',
		'Scratch2Reg',
		'Scratch3Reg',
		'Scratch4Reg',
		'Scratch5Reg',
		'Scratch6Reg',
		'Scratch7Reg',
		'SendNumArgsReg',
		'SqrtRd',
		'Stop',
		'SubCqR',
		'SubCwR',
		'SubRR',
		'SubRdRd',
		'TempReg',
		'TstCqR',
		'VarBaseReg',
		'XorCqR',
		'XorCwR',
		'XorRR'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'class initialization' }
CogRTLOpcodes class >> initialize [
	"Abstract opcodes are a compound of a one word operation specifier and zero or more operand type specifiers.
	 The assembler is in Cogit protocol abstract instructions and uses `at&t' syntax, assigning to the register on the
	 right. e.g. MoveRR is the Move opcode with two register operand specifiers and defines a move register to
	 register instruction from operand 0 to operand 1.  The word and register size is assumed to be either 32-bits
	 on a 32-bit architecture or 64-bits on a 64-bit architecture.  The abstract machine is mostly a 2 address machine
	 with the odd three address instruction added to better exploit RISCs.
			(self initialize)
	The operand specifiers are
		R		- general purpose register
		Rd		- double-precision floating-point register
		Cq		- a `quick' constant that can be encoded in the minimum space possible.
		Cw		- a constant with word size where word is the default operand size for the Smalltalk VM, 32-bits
				  for a 32-bit VM, 64-bits for a 64-bit VM.  The generated constant must occupy the default number
				  of bits.  This allows e.g. a garbage collector to update the value without invalidating the code.
		C32	- a constant with 32 bit size.  The generated constant must occupy 32 bits.
		C64	- a constant with 64 bit size.  The generated constant must occupy 64 bits.
		Aw		- memory word at an absolute address
		Ab		- memory byte at an absolute address
		Mwr	- memory word whose address is at a constant offset from an address in a register
		Mbr		- memory byte whose address is at a constant offset from an address in a register (zero-extended on read)
		M16r	- memory 16-bit halfword whose address is at a constant offset from an address in a register
		M32r	- memory 32-bit halfword whose address is at a constant offset from an address in a register
		M64r	- memory 64-bit doubleword whose address is at a constant offset from an address in a register
		XbrR	- memory word whose address is r * byte size away from an address in a register
		X16rR	- memory word whose address is r * (2 bytes size) away from an address in a register
		X32rR	- memory word whose address is r * (4 bytes size) away from an address in a register
		XwrR	- memory word whose address is r * word size away from an address in a register
		XowrR	- memory word whose address is (r * word size) + o away from an address in a register (scaled indexed)

	An alternative would be to decouple opcodes from operands, e.g.
		Move := 1. Add := 2. Sub := 3...
		RegisterOperand := 1. ConstantQuickOperand := 2. ConstantWordOperand := 3...
	But not all combinations make sense and even fewer are used so we stick with the simple compound approach.

	The assumption is that comparison and arithmetic instructions set condition codes and that move instructions
	leave the condition codes unaffected.  In particular LoadEffectiveAddressMwrR does not set condition codes
	although it can be used to do arithmetic.  On processors such as MIPS this distinction is invalid; there are no
	condition codes.  So the backend is allowed to collapse operation, branch pairs to internal instruciton definitions
	(see sender and implementors of noteFollowingConditionalBranch:). 

	Not all of the definitions in opcodeDefinitions below are implemented.  In particular we do not implement the
	XowrR scaled index addressing mode since it requires 4 operands.

	Not all instructions make sense on all architectures.  MoveRRd and MoveRdR aqre meaningful only on 64-bit machines.

	Note that there are no generic division instructions defined, but a processor may define some.

	Branch/Call ranges.  Jump[Cond] can be generated as short as possible.  Call/Jump[Cond]Long must be generated
	in the same number of bytes irrespective of displacement since their targets may be updated, but they need only
	span 16Mb, the maximum size of the code zone.  This allows e.g. ARM to use single-word call and jump instructions
	for most calls and jumps.  CallFull/JumpFull must also be generated in the same number of bytes irrespective of
	displacement for the same reason, but they must be able to span the full (32-bit or 64-bit) address space because
	they are used to call code in the C runtime, which may be distant from the code zone.  CallFull/JumpFull are allowed
	to use the cResultRegister as a scratch if required (e.g. on x64 where there is no direct 64-bit call or jump).

	Byte reads.  If the concrete compiler class answers true to byteReadsZeroExtend then byte reads must zero-extend
	the byte read into the destination register.  If not, the other bits of the register should be left undisturbed and the
	Cogit will add an instruction to zero the register as required.  Under no circumstances should byte reads sign-extend.

	16-bit (and on 64-bits, 32-bit) reads.  These /are/ expected to always zero-extend."

	| opcodeNames refs |
	"A small fixed set of abstract registers are defined and used in code generation
	 for Smalltalk code, and executes on stack pages in the stack zone.
	 Currently, these are mapped to and from processor-specific registers by
	 concreteRegister: & abstractRegisterForConcreteRegister:"

	"NoReg encodes no register.  We hope soon to discard the need to map between
	 abstract and concrete registers, but for that we can't use nil to mean no register
	 because 0 is a valid register number and in C nil maps to 0."
	NoReg := nil.

	"The core set of abstract registers that define the Cogits model of Smalltalk code."
	FPReg := -1.	"A frame pointer is used for Smalltalk frames."
	SPReg := -2.
	ReceiverResultReg := -3.		"The receiver at point of send, and return value of a send"
	TempReg := -4.
	ClassReg := -5.					"The inline send cache class tag is in this register, loaded at the send site"
	SendNumArgsReg := -6.		"Sends > 2 args set the arg count in this reg"
	Arg0Reg := -7.					"In the StackToRegisterMappingCogit 1 & 2 arg sends marshall into these registers."
	Arg1Reg := -8.

	"A small fixed set of abstract scratch registers for register-rich machines (ARM can use 1, x64 can use 6)."
	Scratch0Reg := -9.
	Scratch1Reg := -10.
	Scratch2Reg := -11.
	Scratch3Reg := -12.
	Scratch4Reg := -13.
	Scratch5Reg := -14.
	Scratch6Reg := -15.
	Scratch7Reg := -16.

	"RISC-specific registers"
	LinkReg := -17.
	RISCTempReg := -18.	"Used to synthesize CISC instructions from multiple RISC instructions."
	PCReg := -19.
	VarBaseReg := -20.		"If useful, points to base of interpreter variables."

	"Floating-point registers"
	DPFPReg0 := -21.
	DPFPReg1 := -22.
	DPFPReg2 := -23.
	DPFPReg3 := -24.
	DPFPReg4 := -25.
	DPFPReg5 := -26.
	DPFPReg6 := -27.
	DPFPReg7 := -28.

	opcodeNames := #("Noops & Pseudo Ops"
						Label
						Literal			"a word-sized literal"
						AlignmentNops
						FillBytesFrom	"output operand 0's worth of bytes from the address in operand 1"
						Fill8				"output a byte's worth of bytes with operand 0"
						Fill16			"output two byte's worth of bytes with operand 0"
						Fill32			"output four byte's worth of bytes with operand 0"
						FillFromWord	"output BytesPerWord's worth of bytes with operand 0 + operand 1"
						Nop

						"Control"
						Call					"call within the code zone"
						CallFull				"call anywhere within the full address space"
						RetN
						JumpR				"Not a regular jump, i.e. not pc dependent."
						Stop				"Halt the processor"

						"N.B.  Jumps are contiguous.  Long and Full jumps are contigiuous within them.  See FirstJump et al below"
						JumpFull			"Jump anywhere within the address space"
						JumpLong			"Jump anywhere within the 16mb code zone."
						JumpLongZero			"a.k.a. JumpLongEqual"
						JumpLongNonZero		"a.k.a. JumpLongNotEqual"
						Jump				"short jumps; can be encoded in as few bytes as possible; will not be disturbed by GC or relocation."
						JumpZero				"a.k.a. JumpEqual"
						JumpNonZero			"a.k.a. JumpNotEqual"
						JumpNegative
						JumpNonNegative
						JumpOverflow
						JumpNoOverflow
						JumpCarry
						JumpNoCarry
						JumpLess			"signed"
						JumpGreaterOrEqual
						JumpGreater
						JumpLessOrEqual
						JumpBelow			"unsigned"
						JumpAboveOrEqual
						JumpAbove
						JumpBelowOrEqual

						JumpFPEqual
						JumpFPNotEqual
						JumpFPLess
						JumpFPLessOrEqual
						JumpFPGreater
						JumpFPGreaterOrEqual
						JumpFPOrdered
						JumpFPUnordered

						"Data Movement; destination is always last operand"
						MoveRR
						MoveAwR
						MoveRAw
						MoveAbR
						MoveRAb
						MoveMwrR MoveRMwr MoveXwrRR MoveRXwrR MoveXowrR MoveRXowr
						MoveM16rR MoveRM16r MoveX16rRR MoveRX16rR
						MoveM32rR MoveRM32r MoveX32rRR MoveRX32rR
						MoveMbrR MoveRMbr MoveXbrRR MoveRXbrR
						MoveCqR MoveCwR MoveC32R MoveC64R
						MoveRRd MoveRdR MoveRdRd MoveM64rRd MoveRdM64r
						PopR PushR PushCq PushCw
						PrefetchAw

						"Arithmetic; destination is always last operand except Cmp; CmpXR is SubRX with no update of result"
						LoadEffectiveAddressMwrR LoadEffectiveAddressXowrR "Variants of add/multiply"
						NegateR "2's complement negation"
						ArithmeticShiftRightCqR ArithmeticShiftRightRR
						LogicalShiftRightCqR LogicalShiftRightRR
						LogicalShiftLeftCqR LogicalShiftLeftRR
						RotateLeftCqR RotateRightCqR

						CmpRR AddRR SubRR AndRR OrRR XorRR
						CmpCqR AddCqR SubCqR AndCqR OrCqR TstCqR XorCqR
						CmpCwR CmpC32R AddCwR SubCwR AndCwR OrCwR XorCwR

						AndCqRR "Three address ops for RISCs; feel free to add and extend"

						CmpRdRd AddRdRd SubRdRd MulRdRd DivRdRd SqrtRd

						"Conversion"
						ConvertRRd

						LastRTLCode).

	"Magic auto declaration. Add to the classPool any new variables and nuke any obsolete ones, and assign values"
	"Find the variables directly referenced by this method"
	refs := (thisContext method literals select: [:l| l isVariableBinding and: [classPool includesKey: l key]]) collect:
				[:ea| ea key].
	"Move to Undeclared any opcodes in classPool not in opcodes or this method."
	(classPool keys reject: [:k| (opcodeNames includes: k) or: [refs includes: k]]) do:
		[:k|
		Undeclared declare: k from: classPool].
	"Declare as class variables and number elements of opcodeArray above"
	opcodeNames withIndexDo:
		[:classVarName :value|
		self classPool
			declare: classVarName from: Undeclared;
			at: classVarName put: value].

	"For CogAbstractInstruction>>isJump etc..."
	FirstJump := JumpFull.
	LastJump := JumpFPUnordered.
	FirstShortJump := Jump.

	"And now initialize the backends; they add their own opcodes and hence these must be reinitialized."
	(Smalltalk classNamed: #CogAbstractInstruction) ifNotNil:
		[:cogAbstractInstruction| cogAbstractInstruction allSubclasses do: [:sc| sc initialize]]
]

{ #category : #'debug printing' }
CogRTLOpcodes class >> nameForOpcode: opcode [ "<Integer>"
	^opcode < LastRTLCode ifTrue:
		[(classPool keyAtValue: opcode ifAbsent: []) ifNotNil:
			[:opcodeName|
			((opcodeName beginsWith: 'First')
			 or: [opcodeName beginsWith: 'Last'])
				ifTrue: [#(JumpFull JumpLong JumpBelowOrEqual Jump) detect: [:k| (classPool at: k) = opcode]]
				ifFalse: [opcodeName]]]
]

{ #category : #'debug printing' }
CogRTLOpcodes class >> nameForRegister: reg [ "<Integer>"
	^#(Arg0Reg Arg1Reg ClassReg FPReg ReceiverResultReg SPReg SendNumArgsReg TempReg
		DPFPReg0 DPFPReg1 DPFPReg2 DPFPReg3 DPFPReg4 DPFPReg5 DPFPReg6 DPFPReg7
		LinkReg RISCTempReg VarBaseReg PCReg
		Scratch0Reg Scratch1Reg Scratch2Reg Scratch3Reg Scratch4Reg Scratch5Reg)
			detect: [:sym| (classPool at: sym) = reg]
			ifNone: ['REG', reg printString, '?']
]

{ #category : #accessing }
CogRTLOpcodes class >> opcodes [
	"CogRTLOpcodes opcodes"
	"CogRTLOpcodes opcodes select:
		[:opcode|
		(Cogit organization listAtCategoryNamed: #'abstract instructions') noneSatisfy:
			[:s|
			(Cogit compiledMethodAt: s) literals anySatisfy:
				[:l|
				l isVariableBinding and: [l key = opcode]]]]"
	^(classPool keys reject:
		[:k|
		(#('First' 'Last' 'DPFP') anySatisfy: [:prefix| k beginsWith: prefix])
		or: [#('Reg' 'Min' 'Max') anySatisfy: [:postfix| k endsWith: postfix]]]) asArray sort
]

{ #category : #'debug printing' }
CogRTLOpcodes class >> printFormatForOpcodeName: opcodeName [
	"Answer a sequence of $r or nil for the operands in the opcode, used for printing."
	| format operands size |
	format := OrderedCollection new.
	size := (operands := opcodeName) size.
	(operands startsWith: 'Br') ifTrue: [^' rr'].
	[#('XwrR' 'X16rR' 'XbrR' 'RR' 'RdR' 'RRd' 'RdRd') do:
		[:regRegFmt|
		(operands endsWith: regRegFmt) ifTrue:
			[format addLast: $r; addLast: $r.
			 operands := operands allButLast: regRegFmt size]].
	  #('Mwr' 'M16r' 'Mbr' 'M64r') do:
		[:constRegFmt|
		(operands endsWith: constRegFmt) ifTrue:
			[format addLast: $r; addLast: nil.
			 operands := operands allButLast: constRegFmt size]].
	  #('Cq' 'Cw' 'C32' 'C64' 'Aw' 'Ab') do:
		[:constFmt|
		(operands endsWith: constFmt) ifTrue:
			[format addLast: nil.
			 operands := operands allButLast: constFmt size]].
	 #('R' 'Rd') do:
		[:regFmt|
		(operands endsWith: regFmt) ifTrue:
			[format addLast: $r.
			 operands := operands allButLast: regFmt size]].
	 operands size < size]
		whileTrue: [size := operands size].
	^format reverse
	
	"classPool keys collect: [:k| { k. (self printFormatForOpcodeName: k) asArray}]"
]
