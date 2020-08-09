Class {
	#name : #VMJittedPrimitivesTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
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
