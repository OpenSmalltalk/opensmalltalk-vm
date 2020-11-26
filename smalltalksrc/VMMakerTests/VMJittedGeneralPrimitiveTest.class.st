Class {
	#name : #VMJittedGeneralPrimitiveTest,
	#superclass : #VMJittedPrimitivesTest,
	#pools : [
		'CogRTLOpcodes'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #'tests - support' }
VMJittedGeneralPrimitiveTest >> testCheckImmediateWhenImmediateFloat [

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
VMJittedGeneralPrimitiveTest >> testCheckImmediateWhenImmediateSmallInteger [
		
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
VMJittedGeneralPrimitiveTest >> testCheckImmediateWhenNonImmediate [
		
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
VMJittedGeneralPrimitiveTest >> testCompareSmallIntegerEqualsToBoxedFloat [

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
VMJittedGeneralPrimitiveTest >> testCompareSmallIntegerEqualsToSmallInteger [

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
VMJittedGeneralPrimitiveTest >> testCompareSmallIntegerGreaterOrEqualThanEqualBoxedFloat [

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
VMJittedGeneralPrimitiveTest >> testCompareSmallIntegerGreaterOrEqualThanEqualSmallInteger [

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
VMJittedGeneralPrimitiveTest >> testCompareSmallIntegerGreaterOrEqualThanGreaterBoxedFloat [

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
VMJittedGeneralPrimitiveTest >> testCompareSmallIntegerGreaterOrEqualThanGreaterSmallInteger [

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
VMJittedGeneralPrimitiveTest >> testCompareSmallIntegerGreaterOrEqualThanSmallerBoxedFloat [

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
VMJittedGeneralPrimitiveTest >> testCompareSmallIntegerGreaterOrEqualThanSmallerSmallInteger [

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
VMJittedGeneralPrimitiveTest >> testCompareSmallIntegerGreaterThanBoxedFloat [

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
VMJittedGeneralPrimitiveTest >> testCompareSmallIntegerGreaterThanSmallInteger [

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
VMJittedGeneralPrimitiveTest >> testCompareSmallIntegerNotEqualsToBoxedFloat [

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
VMJittedGeneralPrimitiveTest >> testCompareSmallIntegerNotEqualsToSmallInteger [

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
VMJittedGeneralPrimitiveTest >> testCompareSmallIntegerNotGreaterThanBoxedFloat [

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
VMJittedGeneralPrimitiveTest >> testCompareSmallIntegerNotGreaterThanSmallInteger [

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
VMJittedGeneralPrimitiveTest >> testConvertIntegerToSmallInteger [

	self compile: [
		cogit objectRepresentation genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
	].

	machineSimulator receiverRegisterValue: 17.
	self runGeneratedCode.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 17).
]

{ #category : #'tests - support' }
VMJittedGeneralPrimitiveTest >> testConvertSmallIntegerToInteger [

	self compile: [ | jump | 
		jump := cogit objectRepresentation genConvertSmallIntegerToIntegerInReg: ReceiverResultReg.
	].

	machineSimulator receiverRegisterValue: (memory integerObjectOf: 17).
	self runGeneratedCode.
	
	self assert: machineSimulator receiverRegisterValue equals: 17.
]

{ #category : #'tests - support' }
VMJittedGeneralPrimitiveTest >> testGetClassIndexOfObjectObtainsClassIndex [

	self compile: [ | jump | 
		jump := cogit objectRepresentation genGetCompactClassIndexNonImmOf: Arg0Reg into: ReceiverResultReg.
	].

	machineSimulator arg0RegisterValue: memory falseObject.
	self runGeneratedCode.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory classIndexOf: memory falseObject)
]

{ #category : #'tests - support' }
VMJittedGeneralPrimitiveTest >> testGetClassObjectOfClassIndex [

	self compile: [
		cogit objectRepresentation genGetClassObjectOfClassIndex: ReceiverResultReg into: Arg0Reg scratchReg: TempReg.
	].

	machineSimulator receiverRegisterValue: ClassFloatCompactIndex.
	self runGeneratedCode.
	
	self assert: machineSimulator argument0RegisterValue equals: classFloat
]

{ #category : #'tests - support' }
VMJittedGeneralPrimitiveTest >> testGetNumberOfSlotsOf16BitIndexable [

	self compile: [
		cogit objectRepresentation
			genGetNumSlotsOf: ReceiverResultReg
			into: Arg0Reg ].

	machineSimulator receiverRegisterValue: (self new16BitIndexableOfSize: 8).
	self runGeneratedCode.

	self assert: machineSimulator argument0RegisterValue equals: 8 * 2 "bytes" / self wordSize
]

{ #category : #'tests - support' }
VMJittedGeneralPrimitiveTest >> testGetNumberOfSlotsOf16BitIndexableWithPadding [

	self compile: [
		cogit objectRepresentation
			genGetNumSlotsOf: ReceiverResultReg
			into: Arg0Reg ].

	machineSimulator receiverRegisterValue: (self new16BitIndexableOfSize: 7).
	self runGeneratedCode.

	self assert: machineSimulator argument0RegisterValue equals: 8 * 2 "bytes" / self wordSize
]

{ #category : #'tests - support' }
VMJittedGeneralPrimitiveTest >> testGetNumberOfSlotsOf32BitIndexable [

	self compile: [
		cogit objectRepresentation
			genGetNumSlotsOf: ReceiverResultReg
			into: Arg0Reg ].

	machineSimulator receiverRegisterValue: (self new32BitIndexableOfSize: 8).
	self runGeneratedCode.

	self assert: machineSimulator argument0RegisterValue equals: 8 * 4 "bytes" / self wordSize
]

{ #category : #'tests - support' }
VMJittedGeneralPrimitiveTest >> testGetNumberOfSlotsOf32BitIndexableWithPadding [

	self compile: [
		cogit objectRepresentation
			genGetNumSlotsOf: ReceiverResultReg
			into: Arg0Reg ].

	machineSimulator receiverRegisterValue: (self new32BitIndexableOfSize: 7).
	self runGeneratedCode.

	self assert: machineSimulator argument0RegisterValue equals: (7 * 4 roundUpTo: self wordSize) "bytes" / self wordSize
]

{ #category : #'tests - support' }
VMJittedGeneralPrimitiveTest >> testGetNumberOfSlotsOf64BitIndexable [

	| desiredSlots |
	
	desiredSlots := 7.

	self compile: [
		cogit objectRepresentation
			genGetNumSlotsOf: ReceiverResultReg
			into: Arg0Reg ].

	machineSimulator receiverRegisterValue: (self new64BitIndexableOfSize: desiredSlots).
	self runGeneratedCode.

	self assert: machineSimulator argument0RegisterValue equals: (desiredSlots * 8 / self wordSize)
]

{ #category : #'tests - support' }
VMJittedGeneralPrimitiveTest >> testGetNumberOfSlotsOf8BitIndexable [

	self compile: [
		cogit objectRepresentation
			genGetNumSlotsOf: ReceiverResultReg
			into: Arg0Reg ].

	machineSimulator receiverRegisterValue: (self new8BitIndexableOfSize: 8).
	self runGeneratedCode.

	self assert: machineSimulator argument0RegisterValue equals: 8 "bytes" / self wordSize
]

{ #category : #'tests - support' }
VMJittedGeneralPrimitiveTest >> testGetNumberOfSlotsOf8BitIndexableWithPadding [

	self compile: [
		cogit objectRepresentation
			genGetNumSlotsOf: ReceiverResultReg
			into: Arg0Reg ].

	machineSimulator receiverRegisterValue: (self new8BitIndexableOfSize: 7).
	self runGeneratedCode.

	self assert: machineSimulator argument0RegisterValue equals: 8 "bytes" / self wordSize
]

{ #category : #'tests - support' }
VMJittedGeneralPrimitiveTest >> testMoveFloatToFloatPointRegister [

	self compile: [ | jump | 
		jump := cogit objectRepresentation genGetDoubleValueOf: ReceiverResultReg into: DPFPReg0.
	]. 

	self deny: (memory isSmallFloatValue: Float fmax).
	machineSimulator receiverRegisterValue: (memory floatObjectOf: Float fmax).

	self runGeneratedCode.
	
	self assert: machineSimulator doublePrecisionFloatingPointRegister0Value equals: Float fmax.
]

{ #category : #'tests - primitiveAdd' }
VMJittedGeneralPrimitiveTest >> testPrimitiveAddDoesNotCompileIfReceiverTagIsNotSmallInteger [
	
	| result |
	
	"Setting a value that is not the SmallInteger tag"
	
	cogit receiverTags: 0.
	
	self compile: [ result := cogit objectRepresentation genPrimitiveAdd ].
	self assert: result equals: UnimplementedPrimitive.
]

{ #category : #'tests - primitiveAdd' }
VMJittedGeneralPrimitiveTest >> testPrimitiveAddFailsWhenArgumentIsNotSmallInteger [
	
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
VMJittedGeneralPrimitiveTest >> testPrimitiveAddFailsWhenSumOverflows [
	
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
VMJittedGeneralPrimitiveTest >> testPrimitiveAddFailsWhenSumOverflowsWhenNegative [
	
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
VMJittedGeneralPrimitiveTest >> testPrimitiveAddIsCompleteWhenReceiverTagIsSmallInteger [
	
	| result |
	
	cogit receiverTags: memory smallIntegerTag.
	
	self compile: [ result := cogit objectRepresentation genPrimitiveAdd ].
	self assert: result equals: CompletePrimitive.
]

{ #category : #'tests - primitiveAdd' }
VMJittedGeneralPrimitiveTest >> testPrimitiveAddReturnsAnSmallInteger [
	
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
VMJittedGeneralPrimitiveTest >> testPrimitiveAddReturnsAnSmallIntegerWhenNegativeNumbers [
	
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

{ #category : #'tests - primitiveAsFloat' }
VMJittedGeneralPrimitiveTest >> testPrimitiveAsFloatDoesNotCompileIfReceiverTagIsNotSmallInteger [
	
	| result |
	
	"Setting a value that is not the SmallInteger tag"
	
	cogit receiverTags: 0.
	
	self compile: [ result := cogit objectRepresentation genPrimitiveAsFloat ].
	self assert: result equals: UnimplementedPrimitive.
]

{ #category : #'tests - primitiveAsFloat' }
VMJittedGeneralPrimitiveTest >> testPrimitiveAsFloatIsCompleteWhenReceiverTagIsSmallInteger [
	
	| result |
	
	self setUpCogMethodEntry.
	
	cogit receiverTags: memory smallIntegerTag.
	
	self compile: [ result := cogit objectRepresentation genPrimitiveAsFloat ].
	self assert: result equals: CompletePrimitive.
]

{ #category : #'tests - primitiveAsFloat' }
VMJittedGeneralPrimitiveTest >> testPrimitiveAsFloatReturnsASmallFloat [
	
	| endInstruction primitiveAddress |
	
	"Small floats are only valid in 64 bits"
	self wordSize = 4 ifTrue: [ ^ self skip ].
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveAsFloat.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].
	
	self prepareStackForSendReceiver: (memory integerObjectOf: 42).
	self runUntilReturn.
	self assert: self machineSimulator receiverRegisterValue equals: (memory floatObjectOf: 42.0)
]

{ #category : #'tests - primitiveAsFloat' }
VMJittedGeneralPrimitiveTest >> testPrimitiveAsFloatWith64BitIntegerReturnsASmallFloat [
	
	| endInstruction primitiveAddress |
	
	"Small floats are only valid in 64 bits"
	self wordSize = 4 ifTrue: [ ^ self skip ].
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveAsFloat.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].
	
	self prepareStackForSendReceiver: (memory integerObjectOf: 8589934592).
	self runUntilReturn.
	
	self 
		assert: (memory floatValueOf: self machineSimulator receiverRegisterValue) 
		equals: 8589934592 asFloat
]

{ #category : #'tests - primitiveBitAnd/Or' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitAndDoesCompileForSmallIntegerReceiver [
	
	| result |
	
	cogit receiverTags: memory smallIntegerTag.
	
	self compile: [ 
		result := cogit objectRepresentation genPrimitiveBitAnd ].

	self assert: result equals: CompletePrimitive
]

{ #category : #'tests - primitiveBitAnd/Or' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitAndDoesNotCompileForNonSmallIntegerReceiver [
	
	| result |
	
	cogit receiverTags: memory smallIntegerTag + 1.
	
	self compile: [ 
		result := cogit objectRepresentation genPrimitiveBitAnd ].

	self assert: result equals: UnimplementedPrimitive
]

{ #category : #'tests - primitiveBitAnd/Or' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitAndShouldFailWithNonSmallIntegerArgument [
	
	| primitiveAddress endInstruction |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveBitAnd.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self prepareStackForSendReceiver: (memory integerObjectOf: 1) arguments: {memory nilObject}.
	self runFrom: primitiveAddress until: endInstruction address.
]

{ #category : #'tests - primitiveBitAnd/Or' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitAndShouldPreserveSmallIntegerTag [
	
	| primitiveAddress endInstruction |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveBitAnd.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self prepareStackForSendReceiver: (memory integerObjectOf: 1) arguments: {(memory integerObjectOf: 3)}.
	self runUntilReturn.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 1)
]

{ #category : #'tests - primitiveBitAnd/Or' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitOrDoesCompileForSmallIntegerReceiver [
	
	| result |
	
	cogit receiverTags: memory smallIntegerTag.
	
	self compile: [ 
		result := cogit objectRepresentation genPrimitiveBitOr ].

	self assert: result equals: CompletePrimitive
]

{ #category : #'tests - primitiveBitAnd/Or' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitOrDoesNotCompileForNonSmallIntegerReceiver [
	
	| result |
	
	cogit receiverTags: memory smallIntegerTag + 1.
	
	self compile: [ 
		result := cogit objectRepresentation genPrimitiveBitOr ].

	self assert: result equals: UnimplementedPrimitive
]

{ #category : #'tests - primitiveBitAnd/Or' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitOrShouldFailWithNonSmallIntegerArgument [
	
	| primitiveAddress endInstruction |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveBitOr.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self prepareStackForSendReceiver: (memory integerObjectOf: 1) arguments: {memory nilObject}.
	self runFrom: primitiveAddress until: endInstruction address.
]

{ #category : #'tests - primitiveBitAnd/Or' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitOrShouldPreserveSmallIntegerTag [
	
	| primitiveAddress endInstruction |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveBitOr.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self prepareStackForSendReceiver: (memory integerObjectOf: 1) arguments: {(memory integerObjectOf: 3)}.
	self runUntilReturn.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 3)
]

{ #category : #'tests - primitiveBitShift' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitShiftDoesCompileForSmallIntegerReceiver [
	
	| result |
	
	cogit receiverTags: memory smallIntegerTag.
	
	self compile: [ 
		result := cogit objectRepresentation genPrimitiveBitShift ].

	self assert: result equals: CompletePrimitive
]

{ #category : #'tests - primitiveBitShift' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitShiftDoesNotCompileForNonSmallIntegerReceiver [
	
	| result |
	
	cogit receiverTags: memory smallIntegerTag + 1.
	
	self compile: [ 
		result := cogit objectRepresentation genPrimitiveBitShift ].

	self assert: result equals: UnimplementedPrimitive
]

{ #category : #'tests - primitiveBitShift' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitShiftShouldFailWithArgumentBiggerThanSmallIntegerBits [
	
	| primitiveAddress endInstruction |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveBitShift.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self
		prepareStackForSendReceiver: (memory integerObjectOf: 1)
		arguments: {memory integerObjectOf: memory numSmallIntegerBits + 1}.
	self runFrom: primitiveAddress until: endInstruction address.
]

{ #category : #'tests - primitiveBitShift' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitShiftShouldFailWithNonSmallIntegerArgument [
	
	| primitiveAddress endInstruction |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveBitShift.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self prepareStackForSendReceiver: (memory integerObjectOf: 1) arguments: {memory nilObject}.
	self runFrom: primitiveAddress until: endInstruction address.
]

{ #category : #'tests - primitiveBitShift' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitShiftShouldFailWithOverflow [
	
	| primitiveAddress endInstruction |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveBitShift.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self
		prepareStackForSendReceiver: (memory integerObjectOf: memory maxSmallInteger)
		arguments: {memory integerObjectOf: 1}.
	self runFrom: primitiveAddress until: endInstruction address.
]

{ #category : #'tests - primitiveBitShift' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitShiftShouldReturnSmallInteger [
	
	| primitiveAddress endInstruction |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveBitShift.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self
		prepareStackForSendReceiver: (memory integerObjectOf: memory maxSmallInteger >> 1)
		arguments: {memory integerObjectOf: 1}.
	self runUntilReturn.
	
	self
		assert: machineSimulator receiverRegisterValue
		equals: (memory integerObjectOf: memory maxSmallInteger >> 1 << 1)
]

{ #category : #'tests - primitiveBitShift' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitShiftShouldReturnSmallIntegerWithShiftRight [
	
	| primitiveAddress endInstruction |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveBitShift.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self
		prepareStackForSendReceiver: (memory integerObjectOf: 17 << 22)
		arguments: {memory integerObjectOf: -22}.
	self runUntilReturn.
	
	self
		assert: machineSimulator receiverRegisterValue
		equals: (memory integerObjectOf: 17)
]

{ #category : #'tests - primitiveBitShift' }
VMJittedGeneralPrimitiveTest >> testPrimitiveBitShiftShouldReturnZeroIfShiftIsBiggerThanNumSmallIntegerBits [
	
	| primitiveAddress endInstruction |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveBitShift.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self
		prepareStackForSendReceiver: (memory integerObjectOf: memory maxSmallInteger >> 1)
		arguments: {memory integerObjectOf: (memory numSmallIntegerBits + 1) negated}.
	self runUntilReturn.
	
	self
		assert: machineSimulator receiverRegisterValue
		equals: (memory integerObjectOf: 0)
]

{ #category : #'tests - primitiveMultiply' }
VMJittedGeneralPrimitiveTest >> testPrimitiveMultiplyDoesNotCompileIfReceiverTagIsNotSmallInteger [
	
	| result |
	
	"Setting a value that is not the SmallInteger tag"
	
	cogit receiverTags: 0.
	
	self compile: [ result := cogit objectRepresentation genPrimitiveMultiply ].
	self assert: result equals: UnimplementedPrimitive.
]

{ #category : #'tests - primitiveMultiply' }
VMJittedGeneralPrimitiveTest >> testPrimitiveMultiplyFailsWhenArgumentIsNotSmallInteger [
	
	| endInstruction primitiveAddress |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveMultiply.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self prepareStackForSendReceiver: (memory integerObjectOf: 7) arguments: { memory nilObject }.
	
	self runFrom: primitiveAddress until: endInstruction address.
]

{ #category : #'tests - primitiveMultiply' }
VMJittedGeneralPrimitiveTest >> testPrimitiveMultiplyFailsWhenNegativeOverflow [
	
	| endInstruction primitiveAddress |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveMultiply.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self
		prepareStackForSendReceiver:  (memory integerObjectOf: memory minSmallInteger)
		arguments: { (memory integerObjectOf: -2) }.
	
	self runFrom: primitiveAddress until: endInstruction address.
]

{ #category : #'tests - primitiveMultiply' }
VMJittedGeneralPrimitiveTest >> testPrimitiveMultiplyFailsWhenPositiveOverflow [
	
	| endInstruction primitiveAddress |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveMultiply.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self
		prepareStackForSendReceiver: (memory integerObjectOf: memory maxSmallInteger)
		arguments: { (memory integerObjectOf: 2) }.
	
	self runFrom: primitiveAddress until: endInstruction address.
]

{ #category : #'tests - primitiveMultiply' }
VMJittedGeneralPrimitiveTest >> testPrimitiveMultiplyIsCompleteWhenReceiverTagIsSmallInteger [
	
	| result |
	
	cogit receiverTags: memory smallIntegerTag.
	
	self compile: [ result := cogit objectRepresentation genPrimitiveMultiply ].
	self assert: result equals: CompletePrimitive.
]

{ #category : #'tests - primitiveMultiply' }
VMJittedGeneralPrimitiveTest >> testPrimitiveMultiplyReturnsANegativeSmallInteger [
	
	| endInstruction primitiveAddress |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveMultiply.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self prepareStackForSendReceiver: (memory integerObjectOf: 42) arguments: { memory integerObjectOf:  -2 }.
	self runFrom: primitiveAddress until: callerAddress.
	self assert: self machineSimulator receiverRegisterValue equals: (memory integerObjectOf: -84).
]

{ #category : #'tests - primitiveMultiply' }
VMJittedGeneralPrimitiveTest >> testPrimitiveMultiplyReturnsASmallInteger [
	
	| endInstruction primitiveAddress |
	
	cogit receiverTags: memory smallIntegerTag.
	
	primitiveAddress := self compile: [ 
		cogit objectRepresentation genPrimitiveMultiply.
		"If the primitive fails it continues, so we need to have an instruction to detect the end"
		endInstruction := cogit Stop ].

	self prepareStackForSendReceiver: (memory integerObjectOf: 42) arguments: { memory integerObjectOf:  2 }.
	self runFrom: primitiveAddress until: callerAddress.
	self assert: self machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 84).
]

{ #category : #'tests - support' }
VMJittedGeneralPrimitiveTest >> testSmallIntegerLessShouldNotCompileForNonSmallIntegers [
		
	| result |
	self compile: [ 
		"Compile this code in the context != of a small integer class"
		cogit receiverTags: memory smallIntegerTag + 1.
		result := cogit objectRepresentation genSmallIntegerComparison: JumpLess ].
	
	self assert: result equals: UnimplementedPrimitive.
]

{ #category : #'tests - support' }
VMJittedGeneralPrimitiveTest >> testSmallIntegerLessThanNonSmallIntegerArgumentDoesNotReturn [
	
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
VMJittedGeneralPrimitiveTest >> testSmallIntegerLessThanReturnsFalse [
	
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
VMJittedGeneralPrimitiveTest >> testSmallIntegerLessThanReturnsTrue [
	
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
