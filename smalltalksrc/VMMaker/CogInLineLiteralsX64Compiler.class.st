Class {
	#name : #CogInLineLiteralsX64Compiler,
	#superclass : #CogX64Compiler,
	#category : #'VMMaker-JIT'
}

{ #category : #'generate machine code' }
CogInLineLiteralsX64Compiler >> computeSizeOfArithCwR [
	<inline: true>
	^10 "MoveCwR" +  3 "ArithRR"
]

{ #category : #testing }
CogInLineLiteralsX64Compiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction."
	^self isJump or: [opcode = AlignmentNops]
]

{ #category : #'generate machine code' }
CogInLineLiteralsX64Compiler >> sizePCDependentInstructionAt: eventualAbsoluteAddress [
	"Size a jump and set its address.  The target may be another instruction
	 or an absolute address.  On entry the address inst var holds our virtual
	 address. On exit address is set to eventualAbsoluteAddress, which is
	 where this instruction will be output.  The span of a jump to a following
	 instruction is therefore between that instruction's address and this
	 instruction's address ((which are both still their virtual addresses), but the
	 span of a jump to a preceeding instruction or to an absolute address is
	 between that instruction's address (which by now is its eventual absolute
	 address) or absolute address and eventualAbsoluteAddress."

	| target maximumSpan abstractInstruction |
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	opcode = AlignmentNops ifTrue:
		[| alignment |
		 address := eventualAbsoluteAddress.
		 alignment := operands at: 0.
		 ^machineCodeSize := (eventualAbsoluteAddress + (alignment - 1) bitAnd: alignment negated)
							   - eventualAbsoluteAddress].
	self assert: self isJump.
	target := operands at: 0.
	abstractInstruction := cogit cCoerceSimple: target to: #'AbstractInstruction *'.
	(self isAnInstruction: abstractInstruction)
		ifTrue:
			[maximumSpan := abstractInstruction address
							- (((cogit abstractInstruction: self follows: abstractInstruction)
								ifTrue: [eventualAbsoluteAddress]
								ifFalse: [address]) + 2)]
		ifFalse:
			[maximumSpan := target - (eventualAbsoluteAddress + 2)].
	address := eventualAbsoluteAddress.
	^machineCodeSize := opcode >= FirstShortJump
							ifTrue:
								[(self isQuick: maximumSpan)
									ifTrue: [2]
									ifFalse: [opcode = Jump
												ifTrue: [5]
												ifFalse: [6]]]
							ifFalse:
								[opcode caseOf:
									{	[JumpLong]	->	[5].
										[JumpFull]	->	[12].
										[Call]		->	[5].
										[CallFull]	->	[12] }]
]
