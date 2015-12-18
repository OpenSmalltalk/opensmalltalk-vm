Class {
	#name : #CogOutOfLineLiteralsX64Compiler,
	#superclass : #CogX64Compiler,
	#category : #'VMMaker-JIT'
}

{ #category : #'class initialization' }
CogOutOfLineLiteralsX64Compiler class >> initializeAbstractRegisters [
	"Assign the abstract registers with the identities/indices of the relevant concrete registers."
	"[1] Figure 3.4 Register Usage in
		System V Application Binary Interface
		AMD64 Architecture Processor Supplement

	N.B. RAX RCX & RDX are caller-save (scratch) registers.  Hence we use RCX for class and RDX for
		receiver/result since these are written in all normal sends."

	TempReg				:= RAX.
	ClassReg				:= RCX.
	ReceiverResultReg		:= RDX.
	SendNumArgsReg		:= R9.
	SPReg					:= RSP.
	FPReg					:= RBP.
	Arg0Reg				:= RDI. "So as to agree with C ABI arg 0"
	Arg1Reg				:= RSI. "So as to agree with C ABI arg 1"
	VarBaseReg			:= RBX. "Must be callee saved"
	"No need for a RISCTempReg because out-of-line literal loads imply no need for a special MoveCwR"
	"RISCTempReg			:= R8."
	Scratch0Reg			:= R10.
	Scratch1Reg			:= R11.
	Scratch2Reg			:= R12.
	Scratch3Reg			:= R13.
	Scratch4Reg			:= R14.
	Scratch5Reg			:= R15.
	Scratch6Reg			:= R8.

	DPFPReg0				:= XMM0L / 2.
	DPFPReg1				:= XMM1L / 2.
	DPFPReg2				:= XMM2L / 2.
	DPFPReg3				:= XMM3L / 2.
	DPFPReg4				:= XMM4L / 2.
	DPFPReg5				:= XMM5L / 2.
	DPFPReg6				:= XMM6L / 2.
	DPFPReg7				:= XMM7L / 2
]

{ #category : #testing }
CogOutOfLineLiteralsX64Compiler class >> isConcreteRISCTempRegister: concreteRegister [
	"For tests to filter-out bogus values left in the ConcreteRISCTempRegister, if any."
	^false
]

{ #category : #testing }
CogOutOfLineLiteralsX64Compiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction.  With out-of-line literals any instruction
	 that refers to a literal depends on the address of the literal, so add them in addition to the jumps."
	^self isJump
	  or: [opcode = AlignmentNops
	  or: [opcode ~= Literal and: [dependent notNil and: [dependent opcode = Literal]]]]
]
