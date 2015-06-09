Class {
	#name : #CogOutOfLineLiteralsARMCompiler,
	#superclass : #CogARMCompiler,
	#category : #'VMMaker-JIT'
}

{ #category : #'accessing class hierarchy' }
CogOutOfLineLiteralsARMCompiler class >> literalsManagerClass [
	^OutOfLineLiteralsManager
]

{ #category : #'generate machine code' }
CogOutOfLineLiteralsARMCompiler >> concretizeLiteral [
	self assert: (dependent notNil and: [dependent opcode = Literal and: [dependent address = address]]).
	self machineCodeAt: 0 put: (operands at: 0)
]

{ #category : #testing }
CogOutOfLineLiteralsARMCompiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction.  With out-of-line literals any instruction
	 that refers to a literal depends on the address of the literal, so add them in addition to the jumps."
	^self isJump or: [opcode = AlignmentNops or: [opcode = Call or: [dependent notNil and: [dependent opcode = Literal]]]]
]

{ #category : #accessing }
CogOutOfLineLiteralsARMCompiler >> literalLoadInstructionBytes [
	"Answer the size of a literal load instruction (which does not include the size of the literal).
	 With out-of-line literals this is always a single LDR instruction that refers to the literal."
	<inline: true>
	^4
]

{ #category : #'generate machine code' }
CogOutOfLineLiteralsARMCompiler >> literalOpcodeIndex [
	"Hack:  To know how far away a literal is from its referencing instruction we store
	 its opcodeIndex, or -1, if as yet unassigned, in the second operand of the literal."
	<inline: true>
	^operands at: 2
]

{ #category : #'generate machine code - support' }
CogOutOfLineLiteralsARMCompiler >> moveCw: constant intoR: destReg [
	"Emit a load of aWord into destReg.  Answer the number of bytes of machine code generated.
	 Literals are stored out-of-line; emit a LDR with the relevant offset."
	 <var: 'constant' type: #usqInt>
	<inline: true>
	self machineCodeAt: 0 put: (self ldr: destReg rn: PC plusImm: address - dependent address).
	^machineCodeSize := 4
]

{ #category : #'generate machine code' }
CogOutOfLineLiteralsARMCompiler >> setLiteralOpcodeIndex: index [
	"Hack:  To know how far away a literal is from its referencing instruction we store
	 its opcodeIndex, or -1, if as yet unassigned, in the second operand of the literal."
	<inline: true>
	^operands at: 2 put: index
]

{ #category : #'generate machine code' }
CogOutOfLineLiteralsARMCompiler >> sizePCDependentInstructionAt: eventualAbsoluteAddress [
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
	self assert: (self isJump or: [opcode = Call or: [opcode = CallFull
				or: [dependent notNil and: [dependent opcode = Literal]]]]).
	self isJump ifTrue: [self resolveJumpTarget].
	address := eventualAbsoluteAddress.
	(opcode = Literal and: [dependent notNil and: [dependent opcode = Literal]]) ifTrue:
		[dependent address: address].
	^machineCodeSize := maxSize
]

{ #category : #'generate machine code' }
CogOutOfLineLiteralsARMCompiler >> updateLabel: labelInstruction [
	opcode ~= Literal ifTrue:
		[super updateLabel: labelInstruction]
]

{ #category : #testing }
CogOutOfLineLiteralsARMCompiler >> usesOutOfLineLiteral [
	"Answer if the receiver uses an out-of-line literal.  Needs only
	 to work for the opcodes created with gen:literal:operand: et al."

	opcode
		caseOf: {
		[CallFull]		-> [^true].
		[JumpFull]		-> [^true].
		"Arithmetic"
		[AddCqR]		-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[AndCqR]		-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[AndCqRR]		-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[CmpCqR]		-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[OrCqR]			-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[SubCqR]		-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[TstCqR]		-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[XorCqR]		-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[AddCwR]		-> [^true].
		[AndCwR]		-> [^true].
		[CmpCwR]		-> [^true].
		[OrCwR]		-> [^true].
		[SubCwR]		-> [^true].
		[XorCwR]		-> [^true].
		[LoadEffectiveAddressMwrR]
						-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		"Data Movement"						
		[MoveCqR]		-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[MoveCwR]		-> [^true].
		[MoveAwR]		-> [^(self isAddressRelativeToVarBase: (operands at: 0)) ifTrue: [false] ifFalse: [true]].
		[MoveRAw]		-> [^(self isAddressRelativeToVarBase: (operands at: 1)) ifTrue: [false] ifFalse: [true]].
		[MoveRMwr]	-> [^self is12BitValue: (operands at: 1) ifTrue: [:u :i| false] ifFalse: [true]].
		[MoveRdM64r]	-> [^true]. 
		[MoveMbrR]		-> [^self is12BitValue: (operands at: 0) ifTrue: [:u :i| false] ifFalse: [true]].
		[MoveRMbr]		-> [^self is12BitValue: (operands at: 1) ifTrue: [:u :i| false] ifFalse: [true]].
		[MoveM16rR]	-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[MoveM64rRd]	-> [^true].
		[MoveMwrR]	-> [^self is12BitValue: (operands at: 0) ifTrue: [:u :i| false] ifFalse: [true]].
		[PushCw]		-> [^true].
		[PushCq]		-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[PrefetchAw] 	-> [^(self isAddressRelativeToVarBase: (operands at: 0)) ifTrue: [false] ifFalse: [true]].
		}
		otherwise: [self assert: false].
	^false "to keep C compiler quiet"

]
