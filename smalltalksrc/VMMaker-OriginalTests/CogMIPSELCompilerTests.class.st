Class {
	#name : #CogMIPSELCompilerTests,
	#superclass : #AbstractInstructionTests,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #accessing }
CogMIPSELCompilerTests >> assertCheckLongArithOpCodeSize: bytes [
	self assert: bytes = 12.
]

{ #category : #'as yet unclassified' }
CogMIPSELCompilerTests >> assertCheckQuickArithOpCodeSize: bytes [
	self assert: bytes <= 12
]

{ #category : #accessing }
CogMIPSELCompilerTests >> concreteCompilerClass [
	^CogMIPSELCompilerForTests
]

{ #category : #'as yet unclassified' }
CogMIPSELCompilerTests >> memoryAsBytes: instructionMachineCode [
	"Manage the fact that in the simulator inst machineCode object is an Array and the disassembler requires a ByteArray or some such."
	| bytes |
	instructionMachineCode isCObjectAccessor ifTrue:
		[^self memoryAsBytes: instructionMachineCode object].
	instructionMachineCode isArray ifFalse:
		[self assert: instructionMachineCode class isBits.
		 ^instructionMachineCode].
	bytes := ByteArray new: instructionMachineCode size * 4.
	1 to: instructionMachineCode size do:
		[:i|
		(instructionMachineCode at: i) ifNotNil:
			[:word|
			bytes unsignedLongAt: i - 1* 4 + 1 put: word]].
	^bytes
]

{ #category : #accessing }
CogMIPSELCompilerTests >> processor [
	processor ifNil:
		[processor := MIPSELSimulator new].
	^processor
]
