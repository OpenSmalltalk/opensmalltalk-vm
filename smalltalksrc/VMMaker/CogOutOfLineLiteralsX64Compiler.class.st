Class {
	#name : #CogOutOfLineLiteralsX64Compiler,
	#superclass : #CogX64Compiler,
	#category : #'VMMaker-JIT'
}

{ #category : #testing }
CogOutOfLineLiteralsX64Compiler class >> isConcreteRISCTempRegister: concreteRegister [
	"For tests to filter-out bogus values left in the ConcreteRISCTempRegister, if any."
	^false
]

{ #category : #encoding }
CogOutOfLineLiteralsX64Compiler >> concreteRegister: registerIndex [
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
			[SendNumArgsReg]		-> [R8].
			[SPReg]					-> [RSP].
			[FPReg]					-> [RBP].
			[Arg0Reg]				-> [RDI]. "So as to agree with C ABI arg 0"
			[Arg1Reg]				-> [RSI]. "So as to agree with C ABI arg 1"
			[VarBaseReg]			-> [RBX]. "Must be callee saved"
			"No need for a RISCTempReg because out-of-line literal loads imply
			 no need for a special MoveCwR, given movabsq only targets RAX"
			"[RISCTempReg]		-> [R8]."
			[Scratch0Reg]			-> [R9].
			[Scratch1Reg]			-> [R10].
			[Scratch2Reg]			-> [R11].
			[Scratch3Reg]			-> [R12].
			[Scratch4Reg]			-> [R13].
			[Scratch5Reg]			-> [R14].
			[Scratch6Reg]			-> [R15] }
		otherwise:
			[self assert: (registerIndex between: RAX and: R15).
			 registerIndex]
]

{ #category : #testing }
CogOutOfLineLiteralsX64Compiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction.  With out-of-line literals any instruction
	 that refers to a literal depends on the address of the literal, so add them in addition to the jumps."
	^self isJump
	  or: [opcode = AlignmentNops
	  or: [opcode ~= Literal and: [dependent notNil and: [dependent opcode = Literal]]]]
]
