Class {
	#name : #VMJittedPrimitivesTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#pools : [
		'CogRTLOpcodes'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #helpers }
VMJittedPrimitivesTest >> prepareStackForSendReceiver: aReceiver arguments: arguments [ 	

	self pushAddress: aReceiver.
	arguments do: [ :anArgument | self pushAddress: anArgument ].
	self machineSimulator receiverRegisterValue: aReceiver.

	machineSimulator hasLinkRegister 
		ifTrue: [ machineSimulator linkRegisterValue: callerAddress "The caller IP in ARM is in the linkRegister"]
		ifFalse: [ self pushAddress:  callerAddress. " I need to push the caller IP, as this is a message send" ]

]

{ #category : #'tests - support' }
VMJittedPrimitivesTest >> testConvertSmallIntegerToInteger [
	
	| result |
	
	self compile: [ result := cogit objectRepresentation genConvertSmallIntegerToIntegerInReg: ReceiverResultReg ].
	
	machineSimulator receiverRegisterValue: (self memory integerObjectOf: 42).
	self runGeneratedCode.
	
	self assert: machineSimulator receiverRegisterValue equals: 42.
]

{ #category : #'tests - primitiveAdd' }
VMJittedPrimitivesTest >> testPrimitiveAddDoesNotCompileIfReceiverTagIsNotSmallInteger [
	
	| result |
	
	"Setting a value that is not the SmallInteger tag"
	
	cogit receiverTags: 0.
	
	self compile: [ result := cogit objectRepresentation genPrimitiveAdd ].
	self assert: result equals: UnimplementedPrimitive.
]

{ #category : #'tests - primitiveAdd' }
VMJittedPrimitivesTest >> testPrimitiveAddFailsWhenArgumentIsNotSmallInteger [
	
	| endInstruction primitiveAddress |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveAdd.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self prepareStackForSendReceiver: (memory integerObjectOf: 7) arguments: { memory nilObject }.
	
	self runFrom: primitiveAddress until: endInstruction address.
]

{ #category : #'tests - primitiveAdd' }
VMJittedPrimitivesTest >> testPrimitiveAddFailsWhenSumOverflows [
	
	| endInstruction primitiveAddress |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveAdd.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self prepareStackForSendReceiver: (memory integerObjectOf: memory maxSmallInteger) arguments: { memory integerObjectOf: 1 }.

	self runFrom: primitiveAddress until: endInstruction address.
]

{ #category : #'tests - primitiveAdd' }
VMJittedPrimitivesTest >> testPrimitiveAddFailsWhenSumOverflowsWhenNegative [
	
	| endInstruction primitiveAddress |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveAdd.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].
	
	self prepareStackForSendReceiver: (memory integerObjectOf: memory minSmallInteger) arguments: { memory integerObjectOf: -1 }.
	
	self runFrom: primitiveAddress until: endInstruction address.
]

{ #category : #'tests - primitiveAdd' }
VMJittedPrimitivesTest >> testPrimitiveAddIsCompleteWhenReceiverTagIsSmallInteger [
	
	| result |
	
	cogit receiverTags: memory smallIntegerTag.
	
	self compile: [ result := cogit objectRepresentation genPrimitiveAdd ].
	self assert: result equals: CompletePrimitive.
]

{ #category : #'tests - primitiveAdd' }
VMJittedPrimitivesTest >> testPrimitiveAddReturnsAnSmallInteger [
	
	| endInstruction primitiveAddress |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveAdd.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self prepareStackForSendReceiver: (memory integerObjectOf: 42) arguments: { memory integerObjectOf: 52 }.
	self runFrom: primitiveAddress until: callerAddress.
	self assert: self machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 94).
]

{ #category : #'tests - primitiveAdd' }
VMJittedPrimitivesTest >> testPrimitiveAddReturnsAnSmallIntegerWhenNegativeNumbers [
	
	| endInstruction primitiveAddress |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveAdd.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self prepareStackForSendReceiver: (memory integerObjectOf: -42) arguments: { memory integerObjectOf: -52 }.
	
	self runFrom: primitiveAddress until: callerAddress.
	self assert: self machineSimulator receiverRegisterValue equals: (memory integerObjectOf: -94).
]

{ #category : #'tests - support' }
VMJittedPrimitivesTest >> testSmallIntegerLessShouldNotCompileForNonSmallIntegers [
		
	| result |
	self compile: [ 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag + 1.
		result := cogit objectRepresentation genSmallIntegerComparison: JumpLess ].
	
	self assert: result equals: UnimplementedPrimitive.
]

{ #category : #'tests - support' }
VMJittedPrimitivesTest >> testSmallIntegerLessThanNonSmallIntegerArgumentDoesNotReturn [
	
	"If the argument is not an small integer, flow jumps and return does not (yet) happen"
	
	self compile: [ 
		"Compile this code in the context ot a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		cogit objectRepresentation genSmallIntegerComparison: JumpLess ].
	
	"Simulate 42 < false.
	  - 42 is the receiver and goes to the receiver register
	  - false is the argument and should go to the stack
	If we are in a system without a link register, we need to push the caller IP to the stack to simulate a call"
	self pushAddress: self memory falseObject.
	cogit backEnd hasLinkRegister ifFalse: [ 
		self pushAddress: callerAddress ].
	machineSimulator receiverRegisterValue: (self memory integerObjectOf: 42).
	
	self runGeneratedCode.
	
	"Receiver and argument should stay untouched"
	self assert: machineSimulator receiverRegisterValue equals: (self memory integerObjectOf: 42).
	self assert: machineSimulator argument0RegisterValue equals: self memory falseObject.
]

{ #category : #'tests - support' }
VMJittedPrimitivesTest >> testSmallIntegerLessThanReturnsFalse [
	
	self compile: [ 
		"Compile this code in the context ot a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		cogit objectRepresentation genSmallIntegerComparison: JumpLess ].
	
	"Simulate 42 < 32.
	  - 42 is the receiver and goes to the receiver register
	  - 32 is the argument and should go to the stack
	If we are in a system without a link register, we need to push the caller IP to the stack to simulate a call"
	self pushAddress: (self memory integerObjectOf: 32).
	cogit backEnd hasLinkRegister ifFalse: [ 
		self pushAddress: callerAddress ].
	machineSimulator receiverRegisterValue: (self memory integerObjectOf: 42).
	
	self runUntilReturn.
	
	self assert: machineSimulator receiverRegisterValue equals: memory falseObject.
]

{ #category : #'tests - support' }
VMJittedPrimitivesTest >> testSmallIntegerLessThanReturnsTrue [
	
	self compile: [ 
		"Compile this code in the context ot a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		cogit objectRepresentation genSmallIntegerComparison: JumpLess ].
	
	"Simulate 32 < 42.
	  - 32 is the receiver and goes to the receiver register
	  - 42 is the argument and should go to the stack
	If we are in a system without a link register, we need to push the caller IP to the stack to simulate a call"
	self pushAddress: (self memory integerObjectOf: 42).
	cogit backEnd hasLinkRegister ifFalse: [ 
		self pushAddress: callerAddress ].
	machineSimulator receiverRegisterValue: (self memory integerObjectOf: 32).

	self runUntilReturn.
	
	self assert: machineSimulator receiverRegisterValue equals: memory trueObject.
]
