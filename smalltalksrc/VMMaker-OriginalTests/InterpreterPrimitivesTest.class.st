"
InterpreterPrimitivesTest provides test coverage for certain potentially problematic
primitives and methods in the interpreter.
"
Class {
	#name : #InterpreterPrimitivesTest,
	#superclass : #TestCase,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #testing }
InterpreterPrimitivesTest >> expectedFailures [
	^#("testPrimitiveSubtractLargeIntegersParameterBounds")
]

{ #category : #'testing - primitiveSubtractLargeIntegers' }
InterpreterPrimitivesTest >> testPrimitiveSubtractLargeIntegersParameterBounds [
	"Prior to VMMaker VMMaker 4.10.1 enhancement by Nicolas Cellier, range was
	restricted and this test would fail."

	| intOne intTwo |
	"LargeNegativeInteger at lower range boundary"
	intOne := -16r8000000000000000. "maximum negative 64 bit value"
	intTwo := -16r7FFFFFFFFFFFFFFF.
	self shouldnt: [intTwo minus64: intOne]
		raise: Error.

]

{ #category : #'testing - signed64BitValueOf' }
InterpreterPrimitivesTest >> testSigned64BitValueOfLargeNegativeInteger [
	"Exercise #signed64BitValueOf: using a LargeNegativeInteger at the maximum of
	its range. Note, IntegerArrayTest provides coverage of 32-bit equivalent."

	| intOne diff intTwo |
	"LargeNegativeInteger at lower range boundary"
	intOne := -16r8000000000000000. "maximum negative 64 bit value"
	intTwo := -16r7FFFFFFFFFFFFFFF.
	self shouldnt: [diff := intOne minus64: intTwo]
		raise: Error.
	self assert: diff = -1.

	"See testPrimitiveSubtractLargeIntegersParameterBounds"
	"self shouldnt: [diff := intTwo minus64: intOne]
		raise: Error.
	self assert: diff = 1."

	self shouldnt: [diff := intOne minus64: -1]
		raise: Error.
	self assert: diff = intTwo.
	
	"Parameters exceeding allowable range"
	"Prior to VMMaker VMMaker 4.10.1 enhancement by Nicolas Cellier, range was
	restricted and the following would raise errors."
	intOne := -16r8000000000000000 - 1. "exceed most negative 64 bit twos complement"
	intTwo := -16r7FFFFFFFFFFFFFFF.
	diff := intOne minus64: intTwo.
	self assert: diff = -2.
	diff := intTwo minus64: intOne.
	self assert: diff = 2.
	"Full 64 bit magnitude range is now available"
	intOne := -16rFFFFFFFFFFFFFFFF. ""
	intTwo := -16rFFFFFFFFFFFFFFFE.
	diff := intOne minus64: intTwo.
	self assert: diff = -1.
	diff := intTwo minus64: intOne.
	self assert: diff = 1.
	intOne := 16rFFFFFFFFFFFFFFFF. ""
	intTwo := 16rFFFFFFFFFFFFFFFE.
	diff := intOne minus64: intTwo.
	self assert: diff = 1.
	diff := intTwo minus64: intOne.
	self assert: diff = -1.
	"Out of range"
	intOne := -16rFFFFFFFFFFFFFFFF - 1. "exceed most negative 64 bit unsigned magnitude"
	intTwo := -16rFFFFFFFFFFFFFFFF.
	self should: [intOne minus64: intTwo]
		raise: Error.
	self should: [intTwo minus64: intOne]
		raise: Error.

]

{ #category : #'testing - signed64BitValueOf' }
InterpreterPrimitivesTest >> testSigned64BitValueOfLargePositiveInteger [
	"Exercise #signed64BitValueOf: using a LargePositiveInteger at the maximum of
	its range. Note, IntegerArrayTest provides coverage of 32-bit equivalent."

	| intOne diff intTwo |
	"LargePositiveInteger at upper range boundary"
	intOne := 16r7FFFFFFFFFFFFFFF. "maximum 64 bit positive"
	intTwo := 16r7FFFFFFFFFFFFFFE.
	self shouldnt: [diff := intOne minus64: intTwo]
		raise: Error.
	self assert: diff = 1.
	self shouldnt: [diff := intTwo minus64: intOne]
		raise: Error.
	self assert: diff = -1.
	self shouldnt: [diff := intOne minus64: 1]
		raise: Error.
	self assert: diff = intTwo.
	
	"Parameters exceeding allowable range"
	"Prior to VMMaker VMMaker 4.10.1 enhancement by Nicolas Cellier, range was
	restricted and the following would raise errors."
	intOne := 16r7FFFFFFFFFFFFFFF + 1.  "exceed maximum 64 bit twos complement positive"
	intTwo := 16r7FFFFFFFFFFFFFFE.
	diff := intOne minus64: intTwo.
	self should: diff = 2.
	diff := intTwo minus64: intOne.
	self should: diff = -2.

	"Full 64 bit magnitude range is now available"
	intOne := 16rFFFFFFFFFFFFFFFF.
	intTwo := 16rFFFFFFFFFFFFFFFE.
	diff := intOne minus64: intTwo.
	self should: diff = 1.
	diff := intTwo minus64: intOne.
	self should: diff = -1.

	intOne := 16rFFFFFFFFFFFFFFFF + 1. "exceed maximum 64 bit unsigned magnitude"
	intTwo := 16rFFFFFFFFFFFFFFFE.
	self should: [intOne minus64: intTwo]
		raise: Error.
	self should: [intTwo minus64: intOne]
		raise: Error.

]
