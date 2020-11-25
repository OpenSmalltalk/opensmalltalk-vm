Class {
	#name : #VMJittedSmallFloatPrimitiveTest,
	#superclass : #VMJittedPrimitivesTest,
	#pools : [
		'CogRTLOpcodes'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #'building suites' }
VMJittedSmallFloatPrimitiveTest class >> testParameters [

	"SmallFloats only exist in 64bits systems"

	^ ParametrizedTestMatrix new
		addCase: { #ISA -> #'aarch64'. #wordSize -> 8};
		addCase: { #ISA -> #'X64'. #wordSize -> 8};
		yourself
]

{ #category : #'tests - primitiveAdd' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveAddTwoSmallFloatsReturnsASmallFloat [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatAdd ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 1.0)
		withArgument: (self memory floatObjectOf: 2.0).

	self assert: machineSimulator receiverRegisterValue equals: (self memory floatObjectOf: 3.0)
]

{ #category : #'tests - primitiveDivide' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveDivideTwoSmallFloatsReturnsASmallFloat [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatDivide ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 1.0)
		withArgument: (self memory floatObjectOf: 2.0).

	self 
		assert: (memory floatValueOf: machineSimulator receiverRegisterValue)
		equals: 0.5
]

{ #category : #'tests - primitiveEquals' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveEqualTwoSmallFloatsReturnsFalse [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatEqual ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 1.0)
		withArgument: (self memory floatObjectOf: 2.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory falseObject
]

{ #category : #'tests - primitiveEquals' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveEqualTwoSmallFloatsReturnsTrue [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatEqual ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 1.0)
		withArgument: (self memory floatObjectOf: 1.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory trueObject
]

{ #category : #'tests - primitiveGreaterThan' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveGreaterOrEqualTwoSmallFloatsReturnsFalseWhenLower [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatGreaterOrEqual ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 1.0)
		withArgument: (self memory floatObjectOf: 2.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory falseObject
]

{ #category : #'tests - primitiveGreaterThan' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveGreaterOrEqualTwoSmallFloatsReturnsTrueWhenEquals [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatGreaterOrEqual ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 1.0)
		withArgument: (self memory floatObjectOf: 1.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory trueObject
]

{ #category : #'tests - primitiveGreaterThan' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveGreaterOrEqualTwoSmallFloatsReturnsTrueWhenGreater [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatGreaterOrEqual ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 2.0)
		withArgument: (self memory floatObjectOf: 1.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory trueObject
]

{ #category : #'tests - primitiveGreaterThan' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveGreaterThanTwoSmallFloatsReturnsFalseWhenEqual [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatGreaterThan ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 1.0)
		withArgument: (self memory floatObjectOf: 1.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory falseObject
]

{ #category : #'tests - primitiveGreaterThan' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveGreaterThanTwoSmallFloatsReturnsFalseWhenLower [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatGreaterThan ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 1.0)
		withArgument: (self memory floatObjectOf: 2.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory falseObject
]

{ #category : #'tests - primitiveGreaterThan' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveGreaterThanTwoSmallFloatsReturnsTrueWhenGreater [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatGreaterThan ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 2.0)
		withArgument: (self memory floatObjectOf: 1.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory trueObject
]

{ #category : #'tests - primitiveLessThan' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveLessOrEqualTwoSmallFloatsReturnsFalseWhenGreater [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatLessOrEqual ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 2.0)
		withArgument: (self memory floatObjectOf: 1.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory falseObject
]

{ #category : #'tests - primitiveLessThan' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveLessOrEqualTwoSmallFloatsReturnsTrueWhenEquals [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatLessOrEqual ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 1.0)
		withArgument: (self memory floatObjectOf: 1.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory trueObject
]

{ #category : #'tests - primitiveLessThan' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveLessOrEqualTwoSmallFloatsReturnsTrueWhenLower [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatLessOrEqual ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 1.0)
		withArgument: (self memory floatObjectOf: 2.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory trueObject
]

{ #category : #'tests - primitiveLessThan' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveLessThanTwoSmallFloatsReturnsFalseWhenEquals [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatLessThan ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 1.0)
		withArgument: (self memory floatObjectOf: 1.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory falseObject
]

{ #category : #'tests - primitiveLessThan' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveLessThanTwoSmallFloatsReturnsFalseWhenGreater [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatLessThan ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 2.0)
		withArgument: (self memory floatObjectOf: 1.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory falseObject
]

{ #category : #'tests - primitiveLessThan' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveLessThanTwoSmallFloatsReturnsTrueWhenLower [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatLessThan ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 1.0)
		withArgument: (self memory floatObjectOf: 2.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory trueObject
]

{ #category : #'tests - primitiveMultiply' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveMultiplyTwoSmallFloatsReturnsASmallFloat [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatMultiply ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 3.0)
		withArgument: (self memory floatObjectOf: 2.0).

	self 
		assert: (memory floatValueOf: machineSimulator receiverRegisterValue) 
		equals: 6.0
]

{ #category : #'tests - primitiveEquals' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveNotEqualTwoSmallFloatsReturnsFalse [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatNotEqual ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 1.0)
		withArgument: (self memory floatObjectOf: 1.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory falseObject
]

{ #category : #'tests - primitiveEquals' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveNotEqualTwoSmallFloatsReturnsTrue [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatNotEqual ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 1.0)
		withArgument: (self memory floatObjectOf: 2.0).

	self 
		assert: machineSimulator receiverRegisterValue
		equals: memory trueObject
]

{ #category : #'tests - primitiveSquareRoot' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveSquareRootASmallFloatsReturnsASmallFloat [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatSquareRoot ].

	self prepareStackForSendReceiver: (self memory floatObjectOf: 2.0).
	self runUntilReturn.

	self 
		assert: (memory floatValueOf: machineSimulator receiverRegisterValue) 
		equals: 2.0 sqrt
]

{ #category : #'tests - primitiveSubtract' }
VMJittedSmallFloatPrimitiveTest >> testPrimitiveSubtractTwoSmallFloatsReturnsASmallFloat [
	
	cogit receiverTags: memory smallFloatTag.
	
	self compile: [ cogit objectRepresentation genPrimitiveSmallFloatSubtract ].

	self 
		executePrimitiveWithReceiver: (self memory floatObjectOf: 2.0)
		withArgument: (self memory floatObjectOf: 3.0).

	self 
		assert: (memory floatValueOf: machineSimulator receiverRegisterValue) 
		equals: -1.0
]
