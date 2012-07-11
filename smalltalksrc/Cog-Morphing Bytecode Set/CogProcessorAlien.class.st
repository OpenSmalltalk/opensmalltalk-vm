Class {
	#name : #CogProcessorAlien,
	#superclass : #Alien,
	#type : #bytes,
	#category : #'Cog-Processors'
}

{ #category : #'Cog API' }
CogProcessorAlien >> abstractInstructionCompilerClass [
	self subclassResponsibility
]

{ #category : #opcodes }
CogProcessorAlien >> callOpcode [
	self subclassResponsibility.
]

{ #category : #disassembly }
CogProcessorAlien >> disassembleFrom: startAddress to: endAddress in: memory on: aStream [
	| address |
	address := startAddress.
	[address < endAddress] whileTrue:
		[[:size :string|
		aStream nextPutAll: string; cr; flush.
		address := address + size]
			valueWithArguments: (self
									primitiveDisassembleAt: address
									inMemory: memory)]
]

{ #category : #disassembly }
CogProcessorAlien >> disassembleInstructionAt: pc In: memory [
	^(self primitiveDisassembleAt: pc inMemory: memory) last
]

{ #category : #disassembly }
CogProcessorAlien >> disassembleInstructionAt: ip In: memory into: aBlock [
	| lenAndDi |
	lenAndDi := self primitiveDisassembleAt: ip inMemory: memory.
	^aBlock value: lenAndDi last value: lenAndDi first
]

{ #category : #disassembly }
CogProcessorAlien >> disassembleNextInstructionIn: memory [
	^(self primitiveDisassembleAt: self pc inMemory: memory) last
]

{ #category : #opcodes }
CogProcessorAlien >> nopOpcode [
	self subclassResponsibility.
]

{ #category : #printing }
CogProcessorAlien >> printRegisterState: registerStateVector on: aStream [

	self subclassResponsibility.
]

{ #category : #printing }
CogProcessorAlien >> printRegistersOn: aStream [
	self printRegisterState: self registerState on: aStream.
	aStream flush
]

{ #category : #'error handling' }
CogProcessorAlien >> reportPrimitiveFailure [
	| errorAndLog |
	errorAndLog := self primitiveErrorAndLog.
	self error: 'Error ', errorAndLog first printString, (errorAndLog last ifNil: [''] ifNotNil: [:log| ': ', log])
]

{ #category : #execution }
CogProcessorAlien >> runInMemory: aMemory [
	| result |
	result := self primitiveRunInMemory: aMemory minimumAddress: 0 readOnlyBelow: 0.
	result ~~ self ifTrue:
		[self error: 'eek!']
]

{ #category : #execution }
CogProcessorAlien >> runInMemory: aMemory minimumAddress: minimumAddress readOnlyBelow: minimumWritableAddress [
	| result |
	result := self primitiveRunInMemory: aMemory
				minimumAddress: minimumAddress
				readOnlyBelow: minimumWritableAddress.
	result ~~ self ifTrue:
		[self error: 'eek!']
]

{ #category : #execution }
CogProcessorAlien >> runInMemory: aMemory readExecuteOnlyBelow: minWriteMaxExecAddr [
	| result |
	result := self primitiveRunInMemory: aMemory minimumAddress: 0 readOnlyBelow: minWriteMaxExecAddr.
	result ~~ self ifTrue:
		[self error: 'eek!']
]

{ #category : #execution }
CogProcessorAlien >> singleStepIn: aMemory [
	| result |
	result := self primitiveSingleStepInMemory: aMemory minimumAddress: 0 readOnlyBelow: aMemory size.
	result ~~ self ifTrue:
		[self error: 'eek!']
]

{ #category : #execution }
CogProcessorAlien >> singleStepIn: aMemory minimumAddress: minimumAddress readOnlyBelow: minimumWritableAddress [
	| result |
	result := self primitiveSingleStepInMemory: aMemory
				minimumAddress: minimumAddress
				readOnlyBelow: minimumWritableAddress.
	result ~~ self ifTrue:
		[self error: 'eek!']
]

{ #category : #execution }
CogProcessorAlien >> singleStepIn: aMemory readExecuteOnlyBelow: minWriteMaxExecAddr [
	| result |
	result := self primitiveSingleStepInMemory: aMemory minimumAddress: 0 readOnlyBelow: minWriteMaxExecAddr.
	result ~~ self ifTrue:
		[self error: 'eek!']
]
