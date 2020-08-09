Class {
	#name : #CogOutOfLineLiteralsARMCompiler,
	#superclass : #CogARMCompiler,
	#category : #'VMMaker-JIT'
}

{ #category : #'accessing class hierarchy' }
CogOutOfLineLiteralsARMCompiler class >> literalsManagerClass [
	^OutOfLineLiteralsManager
]

{ #category : #accessing }
CogOutOfLineLiteralsARMCompiler >> cmpC32RTempByteSize [
	^8
]

{ #category : #'generate machine code' }
CogOutOfLineLiteralsARMCompiler >> concretizeLiteral [
	"Generate an out-of-line literal.  Copy the value and any annotation from the stand-in in the literals manager."
	| literalAsInstruction literal |
	literalAsInstruction := cogit cCoerceSimple: (operands at: 0) to: #'AbstractInstruction *'.
	literal := (self isAnInstruction: literalAsInstruction)
				ifTrue: [literalAsInstruction address]
				ifFalse: [self cCode: [literalAsInstruction asUnsignedInteger]
							inSmalltalk: [literalAsInstruction]].
	self assert: (dependent notNil and: [dependent opcode = Literal]).
	dependent annotation ifNotNil:
		[self assert: annotation isNil.
		 annotation := dependent annotation].
	dependent address ifNotNil: [self assert: dependent address = address].
	dependent address: address.
	self machineCodeAt: 0 put: literal.
	machineCodeSize := 4
]

{ #category : #'as yet unclassified' }
CogOutOfLineLiteralsARMCompiler >> concretizeMovePatcheableC32R [
	
	^ self concretizeMoveCwR
]

{ #category : #accessing }
CogOutOfLineLiteralsARMCompiler >> getDefaultCogCodeSize [
	"Return the default number of bytes to allocate for native code at startup.
	 The actual value can be set via vmParameterAt: and/or a preference in the ini file."
	<inline: true>
	^1024 * 1280
]

{ #category : #'inline cacheing' }
CogOutOfLineLiteralsARMCompiler >> inlineCacheTagAt: callSiteReturnAddress [
	<inline: true>
	^objectMemory longAt: (self pcRelativeAddressAt: (callSiteReturnAddress - 8) asUnsignedInteger)
]

{ #category : #testing }
CogOutOfLineLiteralsARMCompiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction.  With out-of-line literals any instruction
	 that refers to a literal depends on the address of the literal, so add them in addition to the jumps."
	^self isJump
	  or: [opcode = AlignmentNops
	  or: [opcode ~= Literal and: [dependent notNil and: [dependent opcode = Literal]]]]
]

{ #category : #'generate machine code' }
CogOutOfLineLiteralsARMCompiler >> isSharable [
	"Hack:  To know if a literal should be unique (not shared) mark the second operand."
	<inline: true>
	self assert: opcode = Literal.
	^operands at: 1
]

{ #category : #'inline cacheing' }
CogOutOfLineLiteralsARMCompiler >> literalBeforeFollowingAddress: followingAddress [
	"Return the literal referenced by the instruction immediately preceding followingAddress."
	^objectMemory longAt: (self pcRelativeAddressAt:
		((self instructionIsLDR: (self instructionBeforeAddress: followingAddress))
			ifTrue: [self instructionAddressBefore: followingAddress]
			ifFalse: [self instructionAddressBefore: followingAddress - 4]))
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
	^(operands at: 2) asInteger
]

{ #category : #accessing }
CogOutOfLineLiteralsARMCompiler >> loadLiteralByteSize [
	"Answer the byte size of a MoveCwR opcode's corresponding machine code. On ARM this is a single instruction pc-relative register load - unless we have made a mistake and not turned on the out of line literals manager"
	^4
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
	self assert: (dependent address - (address + 8)) abs < (1<<12).
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
	"The maximum offset in a LDR is (1<<12)-1, or (1<<10)-1 instructions.
	 Be conservative.  The issue is that one abstract instruction can emit
	 multiple hardware instructions so we assume a 2 to 1 worst case of
	 hardware instructions to abstract opcodes.."
	^1 << (12 "12-bit offset field"
			- 2 "4 bytes per literal"
			- 1 "2 hardware instructions to 1 abstract opcode") - 1
]

{ #category : #'inline cacheing' }
CogOutOfLineLiteralsARMCompiler >> pcRelativeAddressAt: instrAddress [
	"Extract the address of the ldr rX, [pc, #NNN] instruction at address"
	| inst offset |
	inst := objectMemory longAt: instrAddress.
	self assert: (inst bitAnd: 16rFF5F0000) = (self ldr: 0 rn: PC plus: 0 imm: 0).
	offset := inst bitAnd: 16rFFF.
	^instrAddress + 8 + ((inst anyMask: 1 << 23)
							ifTrue: [offset]
							ifFalse: [offset negated])
]

{ #category : #'inline cacheing' }
CogOutOfLineLiteralsARMCompiler >> relocateMethodReferenceBeforeAddress: pc by: delta [
	"If possible we generate the method address using pc-relative addressing.
	 If so we don't need to relocate it in code.  So check if pc-relative code was
	 generated, and if not, adjust a load literal.  There are two cases, a push
	 or a register load.  If a push, then there is a register load, but in the instruction
	 before."
	| pcPrecedingLoad reference litAddr |
	pcPrecedingLoad := (self instructionIsPush: (self instructionBeforeAddress: pc))
							ifTrue: [pc - 4]
							ifFalse: [pc].
	"If the load is not done via pc-relative addressing we have to relocate."
	(self isPCRelativeValueLoad: (self instructionBeforeAddress: pcPrecedingLoad)) ifFalse:
		[litAddr := self pcRelativeAddressAt: pcPrecedingLoad.
		 reference := objectMemory longAt: litAddr.
		 objectMemory longAt: litAddr put: reference + delta]
]

{ #category : #'inline cacheing' }
CogOutOfLineLiteralsARMCompiler >> rewriteFullTransferAt: callSiteReturnAddress target: callTargetAddress expectedInstruction: expectedInstruction [
	"Rewrite a CallFull or JumpFull instruction to transfer to a different target.
	 This variant is used to rewrite cached primitive calls where we load the target address into ip
	and use the 'bx ip' or 'blx ip' instruction for the actual jump or call.
	Answer the extent
	 of the code change which is used to compute the range of the icache to flush."
	<var: #callSiteReturnAddress type: #usqInt>
	<var: #callTargetAddress type: #usqInt>
	self assert: (self instructionBeforeAddress: callSiteReturnAddress) = expectedInstruction.
	objectMemory longAt: (self pcRelativeAddressAt: callSiteReturnAddress - 8) put: callTargetAddress.
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 8 to: (self pcRelativeAddressAt: callSiteReturnAddress - 8)]."
	^0
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
		longAt: (self instructionAddressBefore: callSiteReturnAddress ) put: call;
		longAt: (self pcRelativeAddressAt: callSiteReturnAddress - 8) put: cacheTag.
	self assert: (self inlineCacheTagAt: callSiteReturnAddress) = cacheTag.
	"self cCode: ''
		inSmalltalk: [cogit disassembleFrom: callSiteReturnAddress - 8 to: (self pcRelativeAddressAt: callSiteReturnAddress - 8)]."
	^4
]

{ #category : #'inline cacheing' }
CogOutOfLineLiteralsARMCompiler >> rewriteInlineCacheTag: cacheTag at: callSiteReturnAddress [
	"Rewrite an inline cache with a new tag.  This variant is used
	 by the garbage collector."
	<inline: true>
	objectMemory longAt: (self pcRelativeAddressAt: callSiteReturnAddress - 8) put: cacheTag
]

{ #category : #'generate machine code' }
CogOutOfLineLiteralsARMCompiler >> setLiteralOpcodeIndex: index [
	"Hack:  To know how far away a literal is from its referencing instruction we store
	 its opcodeIndex, or -1, if as yet unassigned, in the second operand of the literal."
	<inline: true>
	self assert: opcode = Literal.
	operands at: 2 put: index
]

{ #category : #'generate machine code' }
CogOutOfLineLiteralsARMCompiler >> sizePCDependentInstructionAt: eventualAbsoluteAddress [
	"Size a jump and set its address.  The target may be another instruction
	 or an absolute address.  On entry the address inst var holds our virtual
	 address. On exit address is set to eventualAbsoluteAddress, which is
	 where this instruction will be output.  The span of a jump to a following
	 instruction is therefore between that instruction's address and this
	 instruction's address ((which are both still their virtual addresses), but the
	 span of a jump to a preceding instruction or to an absolute address is
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

{ #category : #'inline cacheing' }
CogOutOfLineLiteralsARMCompiler >> storeLiteral: literal beforeFollowingAddress: followingAddress [
	"Rewrite the literal in the instruction immediately preceding followingAddress."
	objectMemory
		longAt: (self pcRelativeAddressAt:
					((self instructionIsLDR: (self instructionBeforeAddress: followingAddress))
						ifTrue: [self instructionAddressBefore: followingAddress]
						ifFalse: [self instructionAddressBefore: followingAddress - 4]))
		put: literal
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
		[MoveCwR]		-> [^(self inCurrentCompilation: (operands at: 0)) not].
		[MoveAwR]		-> [^(self isAddressRelativeToVarBase: (operands at: 0)) ifTrue: [false] ifFalse: [true]].
		[MoveRAw]		-> [^(self isAddressRelativeToVarBase: (operands at: 1)) ifTrue: [false] ifFalse: [true]].
		[MoveAbR]		-> [^(self isAddressRelativeToVarBase: (operands at: 0)) ifTrue: [false] ifFalse: [true]].
		[MoveRAb]		-> [^(self isAddressRelativeToVarBase: (operands at: 1)) ifTrue: [false] ifFalse: [true]].
		[MoveRMwr]	-> [^self is12BitValue: (operands at: 1) ifTrue: [:u :i| false] ifFalse: [true]].
		[MoveRdM64r]	-> [^self is12BitValue: (operands at: 1) ifTrue: [:u :i| false] ifFalse: [true]]. 
		[MoveMbrR]		-> [^self is12BitValue: (operands at: 0) ifTrue: [:u :i| false] ifFalse: [true]].
		[MoveRMbr]		-> [^self is12BitValue: (operands at: 1) ifTrue: [:u :i| false] ifFalse: [true]].
		[MoveM16rR]	-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[MoveRM16r]	-> [^self is12BitValue: (operands at: 1) ifTrue: [:u :i| false] ifFalse: [true]].
		[MoveM64rRd]	-> [^self is12BitValue: (operands at: 0) ifTrue: [:u :i| false] ifFalse: [true]].
		[MoveMwrR]	-> [^self is12BitValue: (operands at: 0) ifTrue: [:u :i| false] ifFalse: [true]].
		[PushCw]		-> [^(self inCurrentCompilation: (operands at: 0)) not].
		[PushCq]		-> [^self rotateable8bitImmediate: (operands at: 0) ifTrue: [:r :i| false] ifFalse: [true]].
		[PrefetchAw] 	-> [^(self isAddressRelativeToVarBase: (operands at: 0)) ifTrue: [false] ifFalse: [true]].
		
		"Patcheable instruction. Moves a literal. Uses out of line literal."
		[MovePatcheableC32R] -> [ ^ true ]
		}
		otherwise: [self assert: false].
	^false "to keep C compiler quiet"

]
