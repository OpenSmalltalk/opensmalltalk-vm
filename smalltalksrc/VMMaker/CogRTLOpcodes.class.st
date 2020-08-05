"
I am a pool for the Register-Transfer-Language to which Cog compiles.  I define unique integer values for all RTL opcodes.  See CogAbstractInstruction for instances of instructions with the opcodes that I define.
"
Class {
	#name : #CogRTLOpcodes,
	#superclass : #SharedPool,
	#classVars : [
		'AddCqR',
		'AddCwR',
		'AddRR',
		'AddRdRd',
		'AddRsRs',
		'AddcCqR',
		'AddcRR',
		'AlignmentNops',
		'AndCqR',
		'AndCqRR',
		'AndCwR',
		'AndRR',
		'ArithmeticShiftRightCqR',
		'ArithmeticShiftRightRR',
		'Call',
		'CallFull',
		'CallR',
		'CmpC32R',
		'CmpCqR',
		'CmpCwR',
		'CmpRR',
		'CmpRdRd',
		'CmpRsRs',
		'ConvertRRd',
		'ConvertRRs',
		'ConvertRdR',
		'ConvertRdRs',
		'ConvertRsR',
		'ConvertRsRd',
		'DivRdRd',
		'DivRsRs',
		'Fill32',
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
		'Literal',
		'LoadEffectiveAddressMwrR',
		'LogicalShiftLeftCqR',
		'LogicalShiftLeftRR',
		'LogicalShiftRightCqR',
		'LogicalShiftRightRR',
		'MoveA32R',
		'MoveAbR',
		'MoveAwR',
		'MoveC32R',
		'MoveCqR',
		'MoveCwR',
		'MoveM16rR',
		'MoveM32rR',
		'MoveM32rRs',
		'MoveM64rRd',
		'MoveM8rR',
		'MoveMbrR',
		'MoveMs8rR',
		'MoveMwrR',
		'MovePatcheableC32R',
		'MoveRA32',
		'MoveRAb',
		'MoveRAw',
		'MoveRM16r',
		'MoveRM32r',
		'MoveRM8r',
		'MoveRMbr',
		'MoveRMwr',
		'MoveRR',
		'MoveRRd',
		'MoveRX16rR',
		'MoveRX32rR',
		'MoveRXbrR',
		'MoveRXwrR',
		'MoveRdM64r',
		'MoveRdR',
		'MoveRdRd',
		'MoveRsM32r',
		'MoveRsRs',
		'MoveX16rRR',
		'MoveX32rRR',
		'MoveXbrRR',
		'MoveXwrRR',
		'MulRdRd',
		'MulRsRs',
		'NegateR',
		'Nop',
		'NotR',
		'OrCqR',
		'OrCwR',
		'OrRR',
		'PopR',
		'PrefetchAw',
		'PushCq',
		'PushCw',
		'PushR',
		'RetN',
		'RotateLeftCqR',
		'RotateRightCqR',
		'SignExtend16RR',
		'SignExtend32RR',
		'SignExtend8RR',
		'SqrtRd',
		'SqrtRs',
		'Stop',
		'SubCqR',
		'SubCwR',
		'SubRR',
		'SubRdRd',
		'SubRsRs',
		'SubbCqR',
		'SubbRR',
		'TstCqR',
		'XorCqR',
		'XorCwR',
		'XorRR',
		'XorRdRd',
		'XorRsRs',
		'ZeroExtend16RR',
		'ZeroExtend32RR',
		'ZeroExtend8RR'
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
		Rs		- single-precision floating-point register
		Rd		- double-precision floating-point register
		Cq		- a `quick' constant that can be encoded in the minimum space possible.
		Cw		- a constant with word size where word is the default operand size for the Smalltalk VM, 32-bits
				  for a 32-bit VM, 64-bits for a 64-bit VM.  The generated constant must occupy the default number
				  of bits.  This allows e.g. a garbage collector to update the value without invalidating the code.
		C32	- a constant with 32 bit size.  The generated constant must occupy 32 bits.
		C64	- a constant with 64 bit size.  The generated constant must occupy 64 bits.
		Aw		- memory word (32-bits for a 32-bit VM, 64-bits for a 64-bit VM) at an absolute address
		Ab		- memory byte at an absolute address
		A32	- memory 32-bit halfword at an absolute address
		Mwr	- memory word whose address is at a constant offset from an address in a register
		Mbr		- memory byte whose address is at a constant offset from an address in a register (zero-extended on read)
		M16r	- memory 16-bit halfword whose address is at a constant offset from an address in a register
		M32r	- memory 32-bit halfword whose address is at a constant offset from an address in a register
		M64r	- memory 64-bit doubleword whose address is at a constant offset from an address in a register
		Xbr		- memory byte whose address is r * byte size away from an address in a register
		X16r	- memory 16-bit halfword whose address is r * (2 bytes size) away from an address in a register
		X32r	- memory 32-bit halfword whose address is r * (4 bytes size) away from an address in a register (64-bit ISAs only)
		Xwr		- memory word whose address is r * word size away from an address in a register
		Xowr	- memory word whose address is o + (r * word size) away from an address in a register (scaled indexed)

	An alternative would be to decouple opcodes from operands, e.g.
		Move := 1. Add := 2. Sub := 3...
		RegisterOperand := 1. ConstantQuickOperand := 2. ConstantWordOperand := 3...
	But not all combinations make sense and even fewer are used so we stick with the simple compound approach.

	The assumption is that comparison and arithmetic instructions set condition codes and that move instructions
	leave the condition codes unaffected.  In particular LoadEffectiveAddressMwrR does not set condition codes
	although it can be used to do arithmetic.  On processors such as MIPS this distinction is invalid; there are no
	condition codes.  So the backend is allowed to collapse operation, branch pairs to internal instruction definitions
	(see senders and implementors of noteFollowingConditionalBranch:). 

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
	opcodeNames := #("Noops & Pseudo Ops"
						Label
						Literal			"a word-sized literal"
						AlignmentNops
						Fill32			"output four byte's worth of bytes with operand 0"
						Nop

						"Control"
						Call					"call within the code zone"
						CallFull				"call anywhere within the full address space"
						CallR
						RetN
						JumpR				"Not a regular jump, i.e. not pc dependent."
						Stop				"Halt the processor"

						"N.B.  Jumps are contiguous.  Long and Full jumps are contiguous within them.  See FirstJump et al below"
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
						MoveAwR MoveA32R
						MoveRAw MoveRA32
						MoveAbR
						MoveRAb
						MoveMwrR MoveRMwr MoveXwrRR MoveRXwrR "MoveXowrR MoveRXowr""Unused"
						MoveM8rR MoveMs8rR MoveRM8r 
						MoveM16rR MoveRM16r MoveX16rRR MoveRX16rR
						MoveM32rR MoveRM32r MoveX32rRR MoveRX32rR
						MoveMbrR MoveRMbr MoveXbrRR MoveRXbrR
						MoveCqR MoveCwR MoveC32R "MoveC64R""Not used"
						MoveRRd MoveRdR MoveRdRd MoveM64rRd MoveRdM64r
						MoveRsRs MoveM32rRs MoveRsM32r
						PopR PushR PushCq PushCw
						PrefetchAw
						
						"Patcheable instructions
						These instructions require a specific layout so they can be patched"
						MovePatcheableC32R

						"Arithmetic; destination is always last operand except Cmp; CmpXR is SubRX with no update of result"
						LoadEffectiveAddressMwrR "LoadEffectiveAddressXowrR" "Variants of add/multiply"
						NegateR "2's complement negation"
						NotR
						ArithmeticShiftRightCqR ArithmeticShiftRightRR
						LogicalShiftRightCqR LogicalShiftRightRR
						LogicalShiftLeftCqR LogicalShiftLeftRR
						RotateLeftCqR RotateRightCqR

						CmpRR AddRR SubRR AndRR OrRR XorRR
						CmpCqR AddCqR SubCqR AndCqR OrCqR TstCqR XorCqR
						CmpCwR CmpC32R AddCwR SubCwR AndCwR OrCwR XorCwR
						AddcRR AddcCqR SubbRR SubbCqR

						AndCqRR "Three address ops for RISCs; feel free to add and extend"

						CmpRdRd AddRdRd SubRdRd MulRdRd DivRdRd SqrtRd XorRdRd
						CmpRsRs AddRsRs SubRsRs MulRsRs DivRsRs SqrtRs XorRsRs

						"Conversion"
						ConvertRRd ConvertRdR
						ConvertRsRd ConvertRdRs ConvertRsR ConvertRRs

						SignExtend8RR SignExtend16RR SignExtend32RR
						ZeroExtend8RR ZeroExtend16RR ZeroExtend32RR

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
	opcode < LastRTLCode ifTrue:
		[classPool associations do:
			[:assoc| | opcodeName |
			 assoc value = opcode ifTrue:
				[(((opcodeName := assoc key) beginsWith: 'First')
				   or: [(opcodeName beginsWith: 'Last')]) ifFalse:
					[^opcodeName]]]].
	^nil
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
	"Answer a sequence of $r, $f or nil for the operands in the opcode, used for printing, where
	 r => integer register, f => floating point register, and nil => numeric or address operand."
	| printFormat operands |
	printFormat := OrderedCollection new.
	operands := opcodeName.
	[(#(	('Ab' nil) ('Aw' nil)
		('Cw' nil) ('Cq' nil) ('C32' nil)
		(Fill32 nil)
		(Label nil) (Literal nil)
		('Mb' nil) ('Mw' nil) ('M16' nil) ('M32' nil) ('M64' nil)
		('Nops' nil)
		('R' $r) ('Rd' $f) ('Rs' $f)
		('Xbr' $r) ('Xwr' $r) ('X16r' $r) ('X32r' $r) ('X64r' $r) ('X' $r) ('ow' nil)
		('Greater' exit) ('Xor' exit) ('r' $r))
				detect: [:pair| operands endsWith: pair first]
				ifNone: [])
			ifNil: [false]
			ifNotNil:
				[:match|
				match last ~~ #exit
				and: [operands := operands allButLast: match first size.
					 printFormat addFirst: match last.
					 true]]]
		whileTrue.
	(printFormat isEmpty and: [(operands beginsWith: 'Jump') or: [operands beginsWith: 'Call']]) ifTrue:
		[printFormat addFirst: nil].
	^printFormat
	
	"classPool keys sort collect: [:k| { k. (self printFormatForOpcodeName: k) asArray}]"
]
