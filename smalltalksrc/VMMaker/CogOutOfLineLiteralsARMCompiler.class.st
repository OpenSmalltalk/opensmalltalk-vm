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
	"Generate an out-of-line literal.  Copy the value and any annotation from the stand-in in the literals manager."
	| literalAsInstruction literal |
	<var: #jumpTarget type: #'AbstractInstruction *'>
	literalAsInstruction := cogit cCoerceSimple: (operands at: 0) to: #'AbstractInstruction *'.
	literal := (self isAnInstruction: literalAsInstruction)
				ifTrue: [literalAsInstruction address]
				ifFalse: [self cCode: [literalAsInstruction asUnsignedInteger]
							inSmalltalk: [literalAsInstruction]].
	self assert: (dependent notNil and: [dependent opcode = Literal and: [dependent address = address]]).
	dependent annotation ifNotNil:
		[self assert: annotation isNil.
		 annotation := dependent annotation].
	self machineCodeAt: 0 put: literal
]

{ #category : #accessing }
CogOutOfLineLiteralsARMCompiler >> getDefaultCogCodeSize [
	"Return the default number of bytes to allocate for native code at startup.
	 The actual value can be set via vmParameterAt: and/or a preference in the ini file."
	<inline: true>
	^1024 * 1280
]

{ #category : #'inline cacheing' }
CogOutOfLineLiteralsARMCompiler >> inlineCacheTagAt: address [
	^objectMemory longAt: (self pcRelativeAddressAt: address - 8)
]

{ #category : #testing }
CogOutOfLineLiteralsARMCompiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction.  With out-of-line literals any instruction
	 that refers to a literal depends on the address of the literal, so add them in addition to the jumps."
	^self isJump
	  or: [opcode = AlignmentNops
	  or: [dependent notNil and: [dependent opcode = Literal]]]
]

{ #category : #'generate machine code' }
CogOutOfLineLiteralsARMCompiler >> isSharable [
	"Hack:  To know if a literal should be unique (not shared) mark the second operand."
	<inline: true>
	self assert: opcode = Literal.
	^(operands at: 1) isNil
]

{ #category : #'generate machine code' }
CogOutOfLineLiteralsARMCompiler >> isUnique [
	"Hack:  To know if a literal should be unique (not shared) mark the second operand."
	<inline: true>
	self assert: opcode = Literal.
	^(operands at: 1) notNil
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
	self assert: opcode = Literal.
	^operands at: 2
]

{ #category : #'generate machine code' }
CogOutOfLineLiteralsARMCompiler >> mapEntryAddress [
	"Typically map entries apply to the end of an instruction, for two reasons:
	  a)	to cope with literals embedded in variable-length instructions, since, e.g.
		on x86, the literal typically comes at the end of the instruction.
	  b)	in-line cache detection is based on return addresses, which are typically
		to the instruction following a call.
	 But with out-of-line literals it is more convenient to annotate the literal itself."
	<inline: true>
	^opcode = Literal
		ifTrue: [address]
		ifFalse: [address + machineCodeSize]
]

{ #category : #'generate machine code - support' }
CogOutOfLineLiteralsARMCompiler >> moveCw: constant intoR: destReg [
	"Emit a load of aWord into destReg.  Answer the number of bytes of machine code generated.
	 Literals are stored out-of-line; emit a LDR with the relevant offset."
	 <var: 'constant' type: #usqInt>
	<inline: true>
	self assert: (cogit addressIsInCurrentCompilation: dependent address).
	self machineCodeAt: 0
		put: (self
				ldr: destReg
				rn: PC
				plus: (dependent address >= (address + 8) ifTrue: [1] ifFalse: [0])
				imm: (dependent address - (address + 8)) abs).
	^machineCodeSize := 4
]

{ #category : #'compile abstract instructions' }
CogOutOfLineLiteralsARMCompiler >> outOfLineLiteralOpcodeLimit [
	"The maximum offset in a LDR is 1<<12.  Be conservative."
	^1<<(11-2)
]

{ #category : #'inline cacheing' }
CogOutOfLineLiteralsARMCompiler >> pcRelativeAddressAt: address [
	"Extract the address of the ldr rX, [pc, #NNN] instruction at address"
	| inst offset |
	inst := objectMemory longAt: address.
	self assert: (inst bitAnd: 16rFF5F0000) = (self ldr: 0 rn: PC plus: 0 imm: 0).
	offset := inst bitAnd: 16rFFF.
	^address + 8 + ((inst anyMask: 1 << 23)
						ifTrue: [offset]
						ifFalse: [offset negated])
]

{ #category : #'inline cacheing' }
CogOutOfLineLiteralsARMCompiler >> rewriteInlineCacheAt: callSiteReturnAddress tag: cacheTag target: callTargetAddress [
	"Rewrite an inline cache to call a different target for a new tag.  This variant is used
	 to link unlinked sends in ceSend:to:numArgs: et al.  Answer the extent of the code
	 change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	| call callDistance |
	callTargetAddress >= cogit minCallAddress ifFalse:
		[self error: 'linking callsite to invalid address'].
	callDistance := (callTargetAddress - (callSiteReturnAddress + 8 "pc offset"- 4 "return offset")) signedIntToLong.
	self assert: (self isInImmediateJumpRange: callDistance). "we don't support long call updates here"
	call := self bl: callDistance.
	objectMemory
		longAt: callSiteReturnAddress - 4 put: call;
		longAt: (self pcRelativeAddressAt: callSiteReturnAddress - 8) put: cacheTag.
	self assert: (self inlineCacheTagAt: callSiteReturnAddress) = cacheTag.
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 20 to: callSiteReturnAddress - 1]."
	^4
]

{ #category : #'generate machine code' }
CogOutOfLineLiteralsARMCompiler >> setIsUnique [
	"Hack:  To know if a literal should be unique (not shared) mark the second operand."
	<inline: true>
	self assert: opcode = Literal.
	^operands at: 1 put: true
]

{ #category : #'generate machine code' }
CogOutOfLineLiteralsARMCompiler >> setLiteralOpcodeIndex: index [
	"Hack:  To know how far away a literal is from its referencing instruction we store
	 its opcodeIndex, or -1, if as yet unassigned, in the second operand of the literal."
	<inline: true>
	self assert: opcode = Literal.
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

	 ARM is simple; the 26-bit call/jump range means no short jumps.  This
	 routine only has to determine the targets of jumps, not determine sizes.

	 This version also deals with out-of-line literals.  If this is the real literal,
	 update the stand-in in literalsManager with the address (because instructions
	 referring to the literal are referring to the stand-in).  If this is annotated with
	 IsObjectReference transfer the annotation to the stand-in, whence it will be
	 transferred to the real literal, simplifying update of literals."

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
	(dependent notNil and: [dependent opcode = Literal]) ifTrue:
		[opcode = Literal ifTrue:
			[dependent address: address].
		 annotation = cogit getIsObjectReference ifTrue:
			[dependent annotation: annotation.
			 annotation := nil]].
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
		[AddCqR]		-> [^self rotateable8bitSignedImmediate: (operands at: 0) ifTrue: [:r :i :n| false] ifFalse: [true]].
		[AndCqR]		-> [^self rotateable8bitBitwiseImmediate: (operands at: 0)
								ifTrue: [:r :i :n| false]
								ifFalse: [1 << (operands at: 0) highBit ~= ((operands at: 0) + 1)]].
		[AndCqRR]		-> [^self rotateable8bitBitwiseImmediate: (operands at: 0)
								ifTrue: [:r :i :n| false]
								ifFalse: [1 << (operands at: 0) highBit ~= ((operands at: 0) + 1)]].
		[CmpCqR]		-> [^self rotateable8bitSignedImmediate: (operands at: 0) ifTrue: [:r :i :n| false] ifFalse: [true]].
		[OrCqR]			-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[SubCqR]		-> [^self rotateable8bitSignedImmediate: (operands at: 0) ifTrue: [:r :i :n| false] ifFalse: [true]].
		[TstCqR]		-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[XorCqR]		-> [^self rotateable8bitBitwiseImmediate: (operands at: 0) ifTrue: [:r :i :n| false] ifFalse: [true]].
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
		[MoveCwR]		-> [^((self isAnInstruction: (operands at: 0)) "i.e. a label, which by definition will be in the current compilation."
							  or: [cogit addressIsInCurrentCompilation: (operands at: 0)]) not].
		[MoveAwR]		-> [^(self isAddressRelativeToVarBase: (operands at: 0)) ifTrue: [false] ifFalse: [true]].
		[MoveRAw]		-> [^(self isAddressRelativeToVarBase: (operands at: 1)) ifTrue: [false] ifFalse: [true]].
		[MoveRMwr]	-> [^self is12BitValue: (operands at: 1) ifTrue: [:u :i| false] ifFalse: [true]].
		[MoveRdM64r]	-> [^self is12BitValue: (operands at: 1) ifTrue: [:u :i| false] ifFalse: [true]]. 
		[MoveMbrR]		-> [^self is12BitValue: (operands at: 0) ifTrue: [:u :i| false] ifFalse: [true]].
		[MoveRMbr]		-> [^self is12BitValue: (operands at: 1) ifTrue: [:u :i| false] ifFalse: [true]].
		[MoveM16rR]	-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[MoveM64rRd]	-> [^self is12BitValue: (operands at: 0) ifTrue: [:u :i| false] ifFalse: [true]].
		[MoveMwrR]	-> [^self is12BitValue: (operands at: 0) ifTrue: [:u :i| false] ifFalse: [true]].
		[PushCw]		-> [^((self isAnInstruction: (operands at: 0)) "i.e. a label, which by definiion will be in the current compilation."
							  or: [cogit addressIsInCurrentCompilation: (operands at: 0)]) not].
		[PushCq]		-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[PrefetchAw] 	-> [^(self isAddressRelativeToVarBase: (operands at: 0)) ifTrue: [false] ifFalse: [true]].
		}
		otherwise: [self assert: false].
	^false "to keep C compiler quiet"

]
