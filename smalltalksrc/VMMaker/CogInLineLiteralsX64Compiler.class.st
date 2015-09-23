Class {
	#name : #CogInLineLiteralsX64Compiler,
	#superclass : #CogX64Compiler,
	#category : #'VMMaker-JIT'
}

{ #category : #private }
CogInLineLiteralsX64Compiler >> abstractRegisterForConcreteRegister: reg [
	(self concreteRegister: TempReg) = reg ifTrue: [^TempReg].
	(self concreteRegister: ReceiverResultReg) = reg ifTrue: [^ReceiverResultReg].
	(self concreteRegister: ClassReg) = reg ifTrue: [^ClassReg].
	(self concreteRegister: SendNumArgsReg) = reg ifTrue: [^SendNumArgsReg].
	(self concreteRegister: Arg0Reg) = reg ifTrue: [^Arg0Reg].
	(self concreteRegister: Arg1Reg) = reg ifTrue: [^Arg1Reg].
	(self concreteRegister: FPReg) = reg ifTrue: [^FPReg].
	(self concreteRegister: SPReg) = reg ifTrue: [^SPReg].
	(self concreteRegister: RISCTempReg) = reg ifTrue: [^RISCTempReg].
	(self concreteRegister: VarBaseReg) = reg ifTrue: [^VarBaseReg].
	(self concreteRegister: Scratch0Reg) = reg ifTrue: [^Scratch0Reg].
	(self concreteRegister: Scratch1Reg) = reg ifTrue: [^Scratch1Reg].
	(self concreteRegister: Scratch2Reg) = reg ifTrue: [^Scratch2Reg].
	(self concreteRegister: Scratch3Reg) = reg ifTrue: [^Scratch3Reg].
	(self concreteRegister: Scratch4Reg) = reg ifTrue: [^Scratch4Reg].
	(self concreteRegister: Scratch5Reg) = reg ifTrue: [^Scratch5Reg].
	self error: 'could not find abstract register'.
	^0

	"({	TempReg. ReceiverResultReg. ClassReg. SendNumArgsReg. Arg0Reg. Arg1Reg.
		FPReg. SPReg.
		RISCTempReg. VarBaseReg.
		Scratch0Reg. Scratch1Reg. Scratch2Reg. Scratch3Reg. Scratch4Reg. Scratch5Reg. } collect: [:i| self basicNew concreteRegister: i]) sort"

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

{ #category : #'generate machine code' }
CogInLineLiteralsX64Compiler >> computeSizeOfArithCwR [
	<inline: true>
	^10 "MoveCwR" +  3 "ArithRR"
]

{ #category : #encoding }
CogInLineLiteralsX64Compiler >> concreteRegister: registerIndex [
	 "Map a possibly abstract register into a concrete one.  Abstract registers
	  (defined in CogAbstractOpcodes) are all negative.  If registerIndex is
	 negative assume it is an abstract register.

	[1] Figure 3.4 Register Usage in
		System V Application Binary Interface
		AMD64 Architecture Processor Supplement


	N.B. RAX RCX & RDX are caller-save (scratch) registers.  Hence we use RCX for class and RDX for
		receiver/result since these are written in all normal sends."

	^registerIndex
		caseOf: {
			[TempReg]				-> [RAX].
			[ClassReg]				-> [RCX].
			[ReceiverResultReg]	-> [RDX].
			[SendNumArgsReg]		-> [R9].
			[SPReg]					-> [RSP].
			[FPReg]					-> [RBP].
			[Arg0Reg]				-> [RSI].
			[Arg1Reg]				-> [RDI].
			[VarBaseReg]			-> [RBX]. "Must be callee saved"
			[RISCTempReg]			-> [R8].
			[Scratch0Reg]			-> [R10].
			[Scratch1Reg]			-> [R11].
			[Scratch2Reg]			-> [R12].
			[Scratch3Reg]			-> [R13].
			[Scratch4Reg]			-> [R14].
			[Scratch5Reg]			-> [R15] }
		otherwise:
			[self assert: (registerIndex between: RAX and: R15).
			 registerIndex]
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
