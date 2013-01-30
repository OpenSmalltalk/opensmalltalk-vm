"
I am the superclass for the Simulation CPU instance wrappers. I ensure that methods used in both/all of them need not be copied.
"
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

{ #category : #'accessing-abstract' }
CogProcessorAlien >> cResultRegister [
	^self subclassResponsibility
]

{ #category : #'accessing-abstract' }
CogProcessorAlien >> cResultRegister: aValue [
	^self subclassResponsibility
]

{ #category : #opcodes }
CogProcessorAlien >> callOpcode [
	self subclassResponsibility.
]

{ #category : #disassembly }
CogProcessorAlien >> decorateDisassembly: anInstructionString for: aSymbolManager [ "<Cogit>"
	| string i1 i2 v |
	string := anInstructionString.
	(i1 := string indexOfSubCollection: '%ds:0x') > 0 ifTrue:
		[i2 := i1 + 6.
		 ['0123456789abcdef' includes: (string at: i2)] whileTrue: [i2 := i2 + 1].
		 string := string
					copyReplaceFrom: i1 + 4
					to: i2 - 1
					with: (aSymbolManager lookupCHexString: (string copyFrom: i1 + 4 to: i2 - 1))].
	(i1 := string indexOfSubCollection: '%ss:0x') > 0 ifTrue:
		[i2 := i1 + 6.
		 ['0123456789abcdef' includes: (string at: i2)] whileTrue: [i2 := i2 + 1].
		 ((string at: i2) = $(
		 and: [(string at: i2 + 1) = $%]) ifTrue:
			[v := Integer readFrom: (ReadStream on: string from: i1 + 6 to: i2 - 1) base: 16.
			string := string
						copyReplaceFrom: i1
						to: i2 - 1
						with: ((v bitAnd: (1 bitShift: 31) - 1) - (v bitAnd: (1 bitShift: 31))) printString]].
	(i1 := string indexOfSubCollection: '$0x') > 0 ifTrue:
		[i2 := i1 + 3.
		 ['0123456789abcdef' includes: (string at: i2)] whileTrue: [i2 := i2 + 1].
		 string := string
					copyReplaceFrom: i1 + 1
					to: i2 - 1
					with: (aSymbolManager lookupCHexString: (string copyFrom: i1 + 1 to: i2 - 1))].
	((i1 := string indexOf: $() > 1
	 and: [(string at: i1 + 1) isDigit
	 and: [i1 < (i2 := string indexOf: $))]]) ifTrue:
		[string := string
					copyReplaceFrom: i1 + 1
					to: i2 - 1
					with: (aSymbolManager lookupCHexString: (string copyFrom: i1 + 1 to: i2 - 1))].
	^string
]

{ #category : #disassembly }
CogProcessorAlien >> decorateDisassembly: anInstructionString for: aSymbolManager "<Cogit>" fromAddress: address [
	^self decorateDisassembly: anInstructionString for: aSymbolManager
]

{ #category : #disassembly }
CogProcessorAlien >> disassembleFrom: startAddress to: endAddress in: memory for: aSymbolManager "<Cogit>" labels: labelDictionary on: aStream [
	| address |
	address := startAddress.
	[address <= endAddress] whileTrue:
		[[:size :string|
		(aSymbolManager labelForPC: address) ifNotNil:
			[:label| aStream nextPutAll: label; nextPut: $:; cr].
		(labelDictionary at: address ifAbsent: []) ifNotNil:
			[:label| aStream nextPutAll: label; nextPut: $:; cr].
		aStream nextPutAll: (self decorateDisassembly: string for: aSymbolManager fromAddress: address); cr; flush.
		address := address + size]
			valueWithArguments: (self
									primitiveDisassembleAt: address
									inMemory: memory)]
]

{ #category : #disassembly }
CogProcessorAlien >> disassembleFrom: startAddress to: endAddress in: memory on: aStream [
	| address |
	address := startAddress.
	[address < endAddress] whileTrue:
		[[:size :string|
		aStream nextPutAll: (address printStringBase: 16 length: 8 padded: true); nextPut: $:; tab; tab; nextPutAll: string; cr; flush.
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

{ #category : #disassembly }
CogProcessorAlien >> disassembleNextInstructionIn: memory for: aSymbolManager [ "<Cogit|nil>"
	| string |
	string := self pc < memory size 
				ifTrue: [(self primitiveDisassembleAt: self pc inMemory: memory) last.]
				ifFalse: ['Invalid address (', (self pc hex allButFirst: 3), ')'].
	^aSymbolManager
		ifNil: [string]
		ifNotNil: [self decorateDisassembly: string for: aSymbolManager]
]

{ #category : #'accessing-abstract' }
CogProcessorAlien >> endianness [
	self subclassResponsibility
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

{ #category : #'accessing-abstract' }
CogProcessorAlien >> registerStatePCIndex [
	"Return the index of the PC register among all register, assuming they are copied into a Smalltalk array."
	^self subclassResponsibility
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

{ #category : #'accessing-abstract' }
CogProcessorAlien >> smashRegisterAccessors [
	self subclassResponsibility
]

{ #category : #'accessing-abstract' }
CogProcessorAlien >> smashRegistersWithValuesFrom: base by: step [
	self smashRegisterAccessors
	   withIndexDo:
		[:accessor :index|
		self perform: accessor with: index - 1 * step + base]
]
