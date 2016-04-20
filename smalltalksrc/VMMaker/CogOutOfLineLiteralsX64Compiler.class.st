Class {
	#name : #CogOutOfLineLiteralsX64Compiler,
	#superclass : #CogX64Compiler,
	#category : #'VMMaker-JIT'
}

{ #category : #'class initialization' }
CogOutOfLineLiteralsX64Compiler class >> initializeAbstractRegisters [
	"Assign the abstract registers with the identities/indices of the relevant concrete registers."

	super initializeAbstractRegisters.
	Extra6Reg := R8
]

{ #category : #testing }
CogOutOfLineLiteralsX64Compiler class >> isRISCTempRegister: reg [
	"For tests to filter-out bogus values left in the RISCTempRegister, if any."
	^false
]

{ #category : #'register allocation' }
CogOutOfLineLiteralsX64Compiler >> availableRegisterOrNoneFor: liveRegsMask [
	"Answer an unused abstract register in the liveRegMask.
	 Subclasses with more registers can override to answer them.
	 N.B. Do /not/ allocate TempReg."
	<returnTypeC: #sqInt>
	(cogit register: Extra6Reg isInMask: liveRegsMask) ifFalse:
		[^Extra6Reg].
	^super availableRegisterOrNoneFor: liveRegsMask
]

{ #category : #testing }
CogOutOfLineLiteralsX64Compiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction.  With out-of-line literals any instruction
	 that refers to a literal depends on the address of the literal, so add them in addition to the jumps."
	^self isJump
	  or: [opcode = AlignmentNops
	  or: [opcode ~= Literal and: [dependent notNil and: [dependent opcode = Literal]]]]
]
