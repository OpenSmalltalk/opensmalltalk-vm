Class {
	#name : #VMDivisionInstructionTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#pools : [
		'CogAbstractRegisters',
		'CogRTLOpcodes'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #'as yet unclassified' }
VMDivisionInstructionTest >> testDivide: numerator by: divisor quotient: quotient remainer: remainer [

	| expectedQuotient expectedRemainer |
	self compile: [ 
		cogit MoveCq: numerator R: ReceiverResultReg.
		cogit MoveCq: divisor R: ClassReg.
		cogit backend
			genDivR: ClassReg
			R: ReceiverResultReg
			Quo: ReceiverResultReg
			Rem: ClassReg ].

	self runGeneratedCode.

	expectedQuotient := self twoComplementOf: quotient.
	expectedRemainer := self twoComplementOf: remainer.
	
	self assert: machineSimulator receiverRegisterValue equals: expectedQuotient.
	self assert: machineSimulator classRegisterValue equals: expectedRemainer
]

{ #category : #tests }
VMDivisionInstructionTest >> testDivisionWithNegativeDividentWithRemainerReturnsCorrectQuotientAndRemainder [

	self testDivide: -10 by: 7 quotient: -1 remainer: -3.

]

{ #category : #tests }
VMDivisionInstructionTest >> testDivisionWithNegativeDivisorAndDividentWithRemainerReturnsCorrectQuotientAndRemainder [

	self testDivide: -10 by: -7 quotient: 1 remainer: -3.

]

{ #category : #tests }
VMDivisionInstructionTest >> testDivisionWithNegativeDivisorWithRemainerReturnsCorrectQuotientAndRemainder [

	self testDivide: 10 by: -7 quotient: -1 remainer: 3.

]

{ #category : #tests }
VMDivisionInstructionTest >> testDivisionWithRemainerReturnsCorrectQuotientAndRemainder [

	self testDivide: 10 by: 7 quotient: 1 remainer: 3.

]

{ #category : #tests }
VMDivisionInstructionTest >> testIntegerDivisionReturnsCorrectQuotientAndRemainder [

	self testDivide: 10 by: 2 quotient: 5 remainer: 0.

]

{ #category : #tests }
VMDivisionInstructionTest >> testIntegerDivisionWithNegativeDivisorReturnsCorrectQuotientAndRemainder [

	self testDivide: 10 by: -2 quotient: -5 remainer: 0.

]

{ #category : #tests }
VMDivisionInstructionTest >> testIntegerDivisionWithNegativeNumeratorAndDivisorReturnsCorrectQuotientAndRemainder [

	self testDivide: -10 by: -2 quotient: 5 remainer: 0.

]

{ #category : #tests }
VMDivisionInstructionTest >> testIntegerDivisionWithNegativeNumeratorReturnsCorrectQuotientAndRemainder [

	self testDivide: -10 by: 2 quotient: -5 remainer: 0.

]

{ #category : #'as yet unclassified' }
VMDivisionInstructionTest >> twoComplementOf: anInteger [

	^ self wordSize = 8
		  ifTrue: [ anInteger twoComplementOfBitSize: 64 ]
		  ifFalse: [ anInteger twoComplementOfBitSize: 32 ]
]
