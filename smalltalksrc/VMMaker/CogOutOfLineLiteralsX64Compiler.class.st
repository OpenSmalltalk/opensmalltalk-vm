Class {
	#name : #CogOutOfLineLiteralsX64Compiler,
	#superclass : #CogX64Compiler,
	#category : #'VMMaker-JIT'
}

{ #category : #testing }
CogOutOfLineLiteralsX64Compiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction.  With out-of-line literals any instruction
	 that refers to a literal depends on the address of the literal, so add them in addition to the jumps."
	^self isJump
	  or: [opcode = AlignmentNops
	  or: [opcode ~= Literal and: [dependent notNil and: [dependent opcode = Literal]]]]
]
