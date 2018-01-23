"
I am the superclass for the Simulation CPU instance wrappers. I ensure that methods used in both/all of them need not be copied.
"
Class {
	#name : #CogProcessorAlien,
	#superclass : #Alien,
	#type : #bytes,
	#classVars : [
		'PrintCodeBytes',
		'PrintTempNames',
		'ReceiverResultRegDereference',
		'SavedState'
	],
	#category : #'Cog-Processors'
}

{ #category : #debugger }
CogProcessorAlien class >> defaultIntegerBaseInDebugger [
	^16
]

{ #category : #'instance creation' }
CogProcessorAlien class >> implementationClass [
	^self subclassResponsibility
]

{ #category : #'class initialization' }
CogProcessorAlien class >> initialize [
	PrintCodeBytes ifNil: [PrintCodeBytes := true].  "Does disassembly include code bytes?"
	PrintTempNames ifNil: [PrintTempNames := false].  "Does disassembly include temp names?"
	SavedState := WeakIdentityKeyDictionary new.
	Smalltalk
		addToStartUpList: self;
		addToShutDownList: self
]

{ #category : #'instance creation' }
CogProcessorAlien class >> new [
	^(self implementationClass atAddress: self primitiveNewCPU) reset
]

{ #category : #accessing }
CogProcessorAlien class >> printCodeBytes [
	<preference: 'Does disassembly include code bytes'
	  category: 'Cogit'
	  description: 'If true, assembly will include machine code bytes..'
	  type: #Boolean>
	^PrintCodeBytes ifNil: [true]
]

{ #category : #accessing }
CogProcessorAlien class >> printCodeBytes: aBoolean [
	PrintCodeBytes := aBoolean
]

{ #category : #accessing }
CogProcessorAlien class >> printTempNames [
	<preference: 'Does disassembly include temp names?'
	  category: 'Cogit'
	  description: 'If true, assembly will try and associate frame-relative offsets as temp names.'
	  type: #Boolean>
	^PrintTempNames ifNil: [false]
]

{ #category : #accessing }
CogProcessorAlien class >> printTempNames: aBoolean [
	PrintTempNames := aBoolean
]

{ #category : #accessing }
CogProcessorAlien class >> setReceiverResultReg: integerOrNil [
	ReceiverResultRegDereference := integerOrNil ifNotNil: ['(%', (self basicNew registerStateGetters at: integerOrNil + 1), ')']
]

{ #category : #'system startup' }
CogProcessorAlien class >> shutDown: quitting [
	self allSubInstancesDo:
		[:processor|
		SavedState at: processor put: processor registerState]
]

{ #category : #'system startup' }
CogProcessorAlien class >> startUp: resuming [
	resuming ifTrue:
		[SavedState keysAndValuesDo:
			[:processorOrNil :state|
			 processorOrNil ifNotNil:
				[processorOrNil addressFieldPut: processorOrNil class primitiveNewCPU.
				 state with: processorOrNil registerStateSetters do:
					[:value :setter|
					processorOrNil perform: setter with: value]]]].
	SavedState removeAll
]

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

{ #category : #'tests support' }
CogProcessorAlien >> convertIntegerToInternal: anInteger [
	"Default conversion for 32-bit processors.  64-bit processors override."
	^anInteger signedIntToLong
]

{ #category : #'tests support' }
CogProcessorAlien >> convertInternalToInteger: unsigned [
	"Default conversion for 32-bit processors.  64-bit processors override."
	^unsigned signedIntFromLong
]

{ #category : #disassembly }
CogProcessorAlien >> decorateDisassembly: anInstructionString for: aSymbolManager "<Cogit>" fromAddress: address [
	^self subclassResponsibility
]

{ #category : #disassembly }
CogProcessorAlien >> disassembleFrom: startAddress to: endAddress in: memory for: aSymbolManager "<Cogit>" labels: labelDictionary on: aStream [
	| address |
	address := startAddress.
	[address <= endAddress] whileTrue:
		[[:sizeArg :stringArg| | size string |
		  size := sizeArg.
		  string := stringArg.
		  (aSymbolManager labelForPC: address) ifNotNil:
			[:label| aStream nextPutAll: label; nextPut: $:; cr].
		  (labelDictionary at: address ifAbsent: []) ifNotNil:
			[:label|
			self printLabel: label on: aStream at: address for: aSymbolManager.
			label isArray ifTrue:
				[string := nil.
				 size := label third]].
		  string ifNotNil:
			[aStream nextPutAll: (self decorateDisassembly: string for: aSymbolManager fromAddress: address)].
		  aStream cr; flush.
		  address := address + size]
			valueWithArguments: (self
									primitiveDisassembleAt: address
									inMemory: memory)].
	(labelDictionary at: address ifAbsent: []) ifNotNil:
		[:label| self printLabel: label on: aStream at: address for: aSymbolManager]
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
	| arrayOfLengthAndString |
	self pc >= memory size ifTrue:
		[| string |
		 string := aSymbolManager ifNotNil:
									[aSymbolManager lookupAddress: self pc].
		 ^self pc hex, ' : ', (string ifNil: ['Invalid address'])].
	arrayOfLengthAndString := self primitiveDisassembleAt: self pc inMemory: memory.
	(arrayOfLengthAndString isArray
	and: [arrayOfLengthAndString first isInteger
	and: [arrayOfLengthAndString last isString]]) ifFalse:
		[^'ERROR: ', (arrayOfLengthAndString printString contractTo: 40)].
	^aSymbolManager
		ifNil: [arrayOfLengthAndString last]
		ifNotNil: [self decorateDisassembly: arrayOfLengthAndString last for: aSymbolManager fromAddress: self pc]
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
CogProcessorAlien >> printLabel: label on: aStream at: address for: aSymbolManager [
	"Print label on aStream.  The label is either a triple of {type, printer, size} or a simple string."
	label isArray
		ifTrue: [label first == #literal
					ifTrue:
						[aStream
							nextPutAll: (address printStringBase: 16 length: 8 padded: true) asLowercase;
							nextPut: $:; space;
							nextPutAll: (aSymbolManager lookupAddress: (aSymbolManager objectMemory longAt: address))]
					ifFalse:
						[aStream
							nextPutAll: label first;
							nextPut: $:; cr;
							nextPutAll: (address printStringBase: 16 length: 8 padded: true) asLowercase;
							nextPut: $:; space;
							nextPutAll: (aSymbolManager perform: label second with: address) asString]]
		ifFalse: [aStream nextPutAll: label; nextPut: $:; cr]
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
"Note that minimumWritableAddress is both the minimum writeable address AND the maximum executable address"
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

{ #category : #'accessing-abstract' }
CogProcessorAlien >> zeroFloatingPointRegisters [
	self floatingPointRegisterStateSetters do:
		[:setter| self perform: setter with: 0]
]
