Class {
	#name : #VMJittedPrimitivesTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#instVars : [
		'classFloat'
	],
	#pools : [
		'CogRTLOpcodes'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #helpers }
VMJittedPrimitivesTest >> executePrimitiveWithReceiver: receiverOop withArgument: argumentOop [
	
	"Simulate a primitive execution having an object as receiver and a single argument
	  - the receiver goes to the receiver register
	  - the argument should be pushed to the stack
	If we are in a system without a link register, we need to push the caller IP to the stack to simulate a call"
	
	self pushAddress: argumentOop.
	cogit backEnd hasLinkRegister ifFalse: [ 
		self pushAddress: callerAddress ].
	machineSimulator receiverRegisterValue: receiverOop.
	
	self runUntilReturn.

]

{ #category : #helpers }
VMJittedPrimitivesTest >> prepareStackForSendReceiver: aReceiver arguments: arguments [ 	

	self pushAddress: aReceiver.
	arguments do: [ :anArgument | self pushAddress: anArgument ].
	self machineSimulator receiverRegisterValue: aReceiver.

	machineSimulator hasLinkRegister 
		ifTrue: [ machineSimulator linkRegisterValue: callerAddress "The caller IP in ARM is in the linkRegister"]
		ifFalse: [ self pushAddress:  callerAddress. " I need to push the caller IP, as this is a message send" ]

]

{ #category : #helpers }
VMJittedPrimitivesTest >> setUp [

	super setUp.
	
	classFloat := self newClassInOldSpaceWithSlots: 0 format: memory firstLongFormat.
	memory setHashBitsOf: classFloat to: ClassFloatCompactIndex.
	memory
		storePointer: ClassFloatCompactIndex
		ofObject: memory classTableFirstPage
		withValue: classFloat.
]

{ #category : #'tests - support' }
VMJittedPrimitivesTest >> testCheckImmediateWhenImmediateFloat [

	"32 bits images does not have SmallFloats"
	self wordSize = 4 
		ifTrue: [ ^ self skip ].
		
	self compile: [ | jump | 
		jump := cogit objectRepresentation genJumpImmediate: Arg0Reg.
		"Non-Immediate => 0"
		cogit MoveCq: 0 R: ReceiverResultReg.
		cogit RetN: 0.
		jump jmpTarget: cogit Label.
		"Immediate => 1"
		cogit MoveCq: 1  R: ReceiverResultReg.
		cogit RetN: 0.
	].

	self assert: (memory isSmallFloatValue: 1.0).
	machineSimulator arg0RegisterValue: (memory floatObjectOf: 1.0).
	self runUntilReturn.
	
	self assert: machineSimulator receiverRegisterValue equals: 1
]

{ #category : #'tests - support' }
VMJittedPrimitivesTest >> testCheckImmediateWhenImmediateSmallInteger [
		
	self compile: [ | jump | 
		jump := cogit objectRepresentation genJumpImmediate: Arg0Reg.
		"Non-Immediate => 0"
		cogit MoveCq: 0 R: ReceiverResultReg.
		cogit RetN: 0.
		jump jmpTarget: cogit Label.
		"Immediate => 1"
		cogit MoveCq: 1  R: ReceiverResultReg.
		cogit RetN: 0.
	].

	machineSimulator arg0RegisterValue: (memory integerObjectOf: 17).
	self runUntilReturn.
	
	self assert: machineSimulator receiverRegisterValue equals: 1
]

{ #category : #'tests - support' }
VMJittedPrimitivesTest >> testCheckImmediateWhenNonImmediate [
		
	self compile: [ | jump | 
		jump := cogit objectRepresentation genJumpImmediate: Arg0Reg.
		"Non-Immediate => 0"
		cogit MoveCq: 0 R: ReceiverResultReg.
		cogit RetN: 0.
		jump jmpTarget: cogit Label.
		"Immediate => 1"
		cogit MoveCq: 1  R: ReceiverResultReg.
		cogit RetN: 0.
	].

	machineSimulator arg0RegisterValue: memory falseObject.
	self runUntilReturn.
	
	self assert: machineSimulator receiverRegisterValue equals: 0
]

{ #category : #'tests - equals comparison' }
VMJittedPrimitivesTest >> testCompareSmallIntegerEqualsToBoxedFloat [

	self compile: [ | jump | 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		jump := cogit objectRepresentation genPrimitiveEqual.
	].
	
	self 
		executePrimitiveWithReceiver: (self memory integerObjectOf: 42)
		withArgument: (self memory boxedFloatObjectOf: 42.0).

	self assert: machineSimulator receiverRegisterValue equals: self memory trueObject
]

{ #category : #'tests - equals comparison' }
VMJittedPrimitivesTest >> testCompareSmallIntegerEqualsToSmallInteger [

	self compile: [ | jump | 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		jump := cogit objectRepresentation genPrimitiveEqual.
	].
	
	self
		executePrimitiveWithReceiver: (self memory integerObjectOf: 42)
		withArgument: (self memory integerObjectOf: 42).
		
	self assert: machineSimulator receiverRegisterValue equals: self memory trueObject
]

{ #category : #'tests - greater or equal than comparison' }
VMJittedPrimitivesTest >> testCompareSmallIntegerGreaterOrEqualThanEqualBoxedFloat [

	self compile: [ | jump | 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		jump := cogit objectRepresentation genPrimitiveGreaterOrEqual.
	].

	self 
		executePrimitiveWithReceiver: (self memory integerObjectOf: 43)
		withArgument: (self memory boxedFloatObjectOf: 43.0).
	
	self assert: machineSimulator receiverRegisterValue equals: self memory trueObject
]

{ #category : #'tests - greater or equal than comparison' }
VMJittedPrimitivesTest >> testCompareSmallIntegerGreaterOrEqualThanEqualSmallInteger [

	self compile: [ | jump | 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		jump := cogit objectRepresentation genPrimitiveGreaterOrEqual.
	].

	self 
		executePrimitiveWithReceiver: (self memory integerObjectOf: 43)
		withArgument: (self memory integerObjectOf: 43).
	
	self assert: machineSimulator receiverRegisterValue equals: self memory trueObject
]

{ #category : #'tests - greater or equal than comparison' }
VMJittedPrimitivesTest >> testCompareSmallIntegerGreaterOrEqualThanGreaterBoxedFloat [

	self compile: [ | jump | 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		jump := cogit objectRepresentation genPrimitiveGreaterOrEqual.
	].

	self 
		executePrimitiveWithReceiver: (self memory integerObjectOf: 43)
		withArgument: (self memory boxedFloatObjectOf: 44.0).
	
	self assert: machineSimulator receiverRegisterValue equals: self memory falseObject
]

{ #category : #'tests - greater or equal than comparison' }
VMJittedPrimitivesTest >> testCompareSmallIntegerGreaterOrEqualThanGreaterSmallInteger [

	self compile: [ | jump | 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		jump := cogit objectRepresentation genPrimitiveGreaterOrEqual.
	].

	self 
		executePrimitiveWithReceiver: (self memory integerObjectOf: 43)
		withArgument: (self memory integerObjectOf: 44).
	
	self assert: machineSimulator receiverRegisterValue equals: self memory falseObject
]

{ #category : #'tests - greater or equal than comparison' }
VMJittedPrimitivesTest >> testCompareSmallIntegerGreaterOrEqualThanSmallerBoxedFloat [

	self compile: [ | jump | 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		jump := cogit objectRepresentation genPrimitiveGreaterOrEqual.
	].

	self 
		executePrimitiveWithReceiver: (self memory integerObjectOf: 43)
		withArgument: (self memory boxedFloatObjectOf: 42.0).
	
	self assert: machineSimulator receiverRegisterValue equals: self memory trueObject
]

{ #category : #'tests - greater or equal than comparison' }
VMJittedPrimitivesTest >> testCompareSmallIntegerGreaterOrEqualThanSmallerSmallInteger [

	self compile: [ | jump | 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		jump := cogit objectRepresentation genPrimitiveGreaterOrEqual.
	].

	self 
		executePrimitiveWithReceiver: (self memory integerObjectOf: 43)
		withArgument: (self memory integerObjectOf: 42).
	
	self assert: machineSimulator receiverRegisterValue equals: self memory trueObject
]

{ #category : #'tests - greater than comparison' }
VMJittedPrimitivesTest >> testCompareSmallIntegerGreaterThanBoxedFloat [

	self compile: [ | jump | 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		jump := cogit objectRepresentation genPrimitiveGreaterThan.
	].

	self 
		executePrimitiveWithReceiver: (self memory integerObjectOf: 43)
		withArgument: (self memory boxedFloatObjectOf: 42.0).
	
	self assert: machineSimulator receiverRegisterValue equals: self memory trueObject
]

{ #category : #'tests - greater than comparison' }
VMJittedPrimitivesTest >> testCompareSmallIntegerGreaterThanSmallInteger [

	self compile: [ | jump | 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		jump := cogit objectRepresentation genPrimitiveGreaterThan.
	].
	
	self 
		executePrimitiveWithReceiver: (self memory integerObjectOf: 43)
		withArgument: (self memory integerObjectOf: 42).
	
	self assert: machineSimulator receiverRegisterValue equals: self memory trueObject
]

{ #category : #'tests - equals comparison' }
VMJittedPrimitivesTest >> testCompareSmallIntegerNotEqualsToBoxedFloat [

	self compile: [ | jump | 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		jump := cogit objectRepresentation genPrimitiveEqual.
	].
	
	self 
		executePrimitiveWithReceiver: (self memory integerObjectOf: 43)
		withArgument: (self memory boxedFloatObjectOf: 42.0).

	self assert: machineSimulator receiverRegisterValue equals: self memory falseObject
]

{ #category : #'tests - equals comparison' }
VMJittedPrimitivesTest >> testCompareSmallIntegerNotEqualsToSmallInteger [

	self compile: [ | jump | 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		jump := cogit objectRepresentation genPrimitiveEqual.
	].
	
	self 
		executePrimitiveWithReceiver: (self memory integerObjectOf: 43)
		withArgument: (self memory integerObjectOf: 42).
	
	self assert: machineSimulator receiverRegisterValue equals: self memory falseObject
]

{ #category : #'tests - greater than comparison' }
VMJittedPrimitivesTest >> testCompareSmallIntegerNotGreaterThanBoxedFloat [

	self compile: [ | jump | 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		jump := cogit objectRepresentation genPrimitiveGreaterThan.
	].
	
	self 
		executePrimitiveWithReceiver: (self memory integerObjectOf: 43)
		withArgument: (self memory boxedFloatObjectOf: 44.0).
	
	self assert: machineSimulator receiverRegisterValue equals: self memory falseObject
]

{ #category : #'tests - greater than comparison' }
VMJittedPrimitivesTest >> testCompareSmallIntegerNotGreaterThanSmallInteger [

	self compile: [ | jump | 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag.
		jump := cogit objectRepresentation genPrimitiveGreaterThan.
	].
	
	self 
		executePrimitiveWithReceiver: (self memory integerObjectOf: 43)
		withArgument: (self memory integerObjectOf: 44).
	
	self assert: machineSimulator receiverRegisterValue equals: self memory falseObject
]

{ #category : #'tests - support' }
VMJittedPrimitivesTest >> testConvertSmallIntegerToInteger [

	self compile: [ | jump | 
		jump := cogit objectRepresentation genConvertSmallIntegerToIntegerInReg: ReceiverResultReg.
	].

	machineSimulator receiverRegisterValue: (memory integerObjectOf: 17).
	self runGeneratedCode.
	
	self assert: machineSimulator receiverRegisterValue equals: 17.
]

{ #category : #'tests - support' }
VMJittedPrimitivesTest >> testGetClassIndexOfObjectObtainsClassIndex [

	self compile: [ | jump | 
		jump := cogit objectRepresentation genGetCompactClassIndexNonImmOf: Arg0Reg into: ReceiverResultReg.
	].

	machineSimulator arg0RegisterValue: memory falseObject.
	self runGeneratedCode.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory classIndexOf: memory falseObject)
]

{ #category : #'tests - support' }
VMJittedPrimitivesTest >> testMoveFloatToFloatPointRegister [

	self compile: [ | jump | 
		jump := cogit objectRepresentation genGetDoubleValueOf: ReceiverResultReg into: DPFPReg0.
	]. 

	self deny: (memory isSmallFloatValue: Float fmax).
	machineSimulator receiverRegisterValue: (memory floatObjectOf: Float fmax).

	self runGeneratedCode.
	
	self assert: machineSimulator doublePrecisionFloatingPointRegister0Value equals: Float fmax.
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
