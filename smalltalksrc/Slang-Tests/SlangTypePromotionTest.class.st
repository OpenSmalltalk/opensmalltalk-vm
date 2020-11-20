Class {
	#name : #SlangTypePromotionTest,
	#superclass : #SlangAbstractTestCase,
	#category : #'Slang-Tests'
}

{ #category : #'integer-types' }
SlangTypePromotionTest >> testCharAndChar [
	"representative of two types smaller than sizeOf(int) with same size"
	| firstType secondType resType |
	firstType := #char.
	secondType := #char.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #int.
	

	"check that the system is in the assumed state."
	self assert: (ccg isIntegralCType: #char).
	self assert: (ccg sizeOfIntegralCType: #char) equals: 1.
]

{ #category : #'float-types' }
SlangTypePromotionTest >> testCharAndFloat [
	"representative of two types bigger than sizeOf(int) and with same size"
	| firstType secondType resType |
	firstType := #char.
	secondType := #float.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #float.
	self assert: (ccg isFloatingPointCType: resType).
]

{ #category : #'integer-types' }
SlangTypePromotionTest >> testCharAndLongLong [
	"representative of two types bigger than sizeOf(int) and with same size"
	| firstType secondType resType |
	firstType := #char.
	secondType := #'long long'.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #'long long'.
	
	"check that the system is in the assumed state."
	self assert: (ccg isIntegralCType: #char).
	self assert: (ccg sizeOfIntegralCType: #char) equals: 1.
	self assert: (ccg isIntegralCType: #'long long').
	self assert: (ccg sizeOfIntegralCType: #'long long') equals: 8.
]

{ #category : #'float-types' }
SlangTypePromotionTest >> testDoubleAndDouble [
	| firstType secondType resType |
	firstType := #double.
	secondType := #double.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #double.
	self assert: (ccg isFloatingPointCType: resType).
]

{ #category : #'float-types' }
SlangTypePromotionTest >> testDoubleAndFloat [
	| firstType secondType resType |
	firstType := #double.
	secondType := #float.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #double.
	self assert: (ccg isFloatingPointCType: resType).
	
]

{ #category : #'float-types' }
SlangTypePromotionTest >> testFloatAndDouble [
	| firstType secondType resType |
	firstType := #float.
	secondType := #double.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #double.
	self assert: (ccg isFloatingPointCType: resType).
	
]

{ #category : #'float-types' }
SlangTypePromotionTest >> testFloatAndFloat [
	| firstType secondType resType |
	firstType := #float.
	secondType := #float.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #float.
	self assert: (ccg isFloatingPointCType: resType).
	
]

{ #category : #general }
SlangTypePromotionTest >> testFloatAndNil [
	| firstType secondType resType |
	firstType := #float.
	secondType := nil.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #float.
	
	"this feels wrong"
	"inconsistent with integer types too"
	self assert: false.
]

{ #category : #'float-types' }
SlangTypePromotionTest >> testIntAndFloat [
	| firstType secondType resType |
	firstType := #int.
	secondType := #float.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #float.
	self assert: (ccg isFloatingPointCType: resType).
	
]

{ #category : #'integer-types' }
SlangTypePromotionTest >> testIntAndInt [
	"representative of two types with size = sizeOf(int) of same size"
	| firstType secondType resType |
	firstType := #int.
	secondType := #int.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #int.
	
	"check that the system is in the assumed state."
	self assert: (ccg isIntegralCType: #int).
	self assert: (ccg sizeOfIntegralCType: #int) equals: 4.
]

{ #category : #'integer-types' }
SlangTypePromotionTest >> testIntAndLongLong [
	"representative of a different size types"
	| firstType secondType resType |
	firstType := #int .
	secondType := #'long long'.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #'long long'.
	
	"check that the system is in the assumed state."
	self assert: (ccg isIntegralCType: #int).
	self assert: (ccg sizeOfIntegralCType: #int) equals: 4.
	self assert: (ccg isIntegralCType: #'long long').
	self assert: (ccg sizeOfIntegralCType: #'long long') equals: 8.
]

{ #category : #general }
SlangTypePromotionTest >> testIntAndNil [
	| firstType secondType resType |
	firstType := #int.
	secondType := nil.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: nil.
	
]

{ #category : #'unsigned-priority' }
SlangTypePromotionTest >> testIntAndUnsignedChar [
	"representative of an unsigned that is ignored because of integerType promotion"
	| firstType secondType resType |
	firstType := #int.
	secondType := #'unsigned char'.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #int.
	
	"check that the system is in the assumed state."
	self assert: (ccg isIntegralCType: #int).
	self assert: (ccg sizeOfIntegralCType: #int) equals: 4.
	self assert: (ccg isIntegralCType: #'unsigned char').
	self assert: (ccg sizeOfIntegralCType: #'unsigned char') equals: 1.
]

{ #category : #'unsigned-priority' }
SlangTypePromotionTest >> testIntAndUnsignedInt [
	"representative of two types bigger than sizeOf(int) and with same size"
	| firstType secondType resType |
	firstType := #int.
	secondType := #'unsigned int'.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #'unsigned int'.
	
	"check that the system is in the assumed state."
	self assert: (ccg isIntegralCType: #int).
	self assert: (ccg sizeOfIntegralCType: #int) equals: 4.
	self assert: (ccg isIntegralCType: #'unsigned int').
	self assert: (ccg sizeOfIntegralCType: #'unsigned int') equals: 4.
]

{ #category : #'integer-types' }
SlangTypePromotionTest >> testLongLongAndChar [
	"representative of different sized types"
	| firstType secondType resType |
	firstType := #'long long'.
	secondType := #char.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #'long long'.
	
	"check that the system is in the assumed state."
	self assert: (ccg isIntegralCType: #'long long').
	self assert: (ccg sizeOfIntegralCType: #'long long') equals: 8.
	self assert: (ccg isIntegralCType: #char).
	self assert: (ccg sizeOfIntegralCType: #char) equals: 1.
]

{ #category : #'float-types' }
SlangTypePromotionTest >> testLongLongAndFloat [
	| firstType secondType resType |
	firstType := #'long long'.
	secondType := #float.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #float.
	self assert: (ccg isFloatingPointCType: resType).
	
]

{ #category : #'integer-types' }
SlangTypePromotionTest >> testLongLongAndInt [
	"representative of different sized types"
	| firstType secondType resType |
	firstType := #'long long'.
	secondType := #int.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #'long long'.

	"check that the system is in the assumed state."
	self assert: (ccg isIntegralCType: #'long long').
	self assert: (ccg sizeOfIntegralCType: #'long long') equals: 8.
	self assert: (ccg isIntegralCType: #int).
	self assert: (ccg sizeOfIntegralCType: #int) equals: 4.
]

{ #category : #'integer-types' }
SlangTypePromotionTest >> testLongLongAndSqLong [
	"representative of two types bigger than sizeOf(int)"
	| firstType secondType resType |
	firstType := #'long long'.
	secondType := #sqLong.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #'long long'.
	
	"check that the system is in the assumed state."
	self assert: (ccg isIntegralCType: #'long long').
	self assert: (ccg sizeOfIntegralCType: #'long long') equals: 8.
	self assert: (ccg isIntegralCType: #sqLong).
	self assert: (ccg sizeOfIntegralCType: #sqLong) equals: 8.
]

{ #category : #general }
SlangTypePromotionTest >> testNilAndFloat [
	| firstType secondType resType |
	firstType := nil.
	secondType := #float.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #float.
	
	"this feels wrong"
	"inconsistent with integer types too"
	self assert: false.
]

{ #category : #general }
SlangTypePromotionTest >> testNilAndInt [
	| firstType secondType resType |
	firstType := nil.
	secondType := #int.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: nil.
	
]

{ #category : #general }
SlangTypePromotionTest >> testNilAndNil [
	| firstType secondType resType |
	firstType := nil.
	secondType := nil.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: nil.
	
]

{ #category : #'unsigned-priority' }
SlangTypePromotionTest >> testUnsignedIntAndInt [
	"representative of two types bigger than sizeOf(int) and with same size"
	| firstType secondType resType |
	firstType := #'unsigned int'.
	secondType := #'int'.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #'unsigned int'.
	
	"check that the system is in the assumed state."
	self assert: (ccg isIntegralCType: #'unsigned int').
	self assert: (ccg sizeOfIntegralCType: #'unsigned int') equals: 4.
	self assert: (ccg isIntegralCType: #int).
	self assert: (ccg sizeOfIntegralCType: #int) equals: 4.
]

{ #category : #'unsigned-priority' }
SlangTypePromotionTest >> testUnsignedIntAndLongLong [
	"representative of an unsigned that is ignored because of integerType promotion"
	| firstType secondType resType |
	firstType := #'unsigned int'.
	secondType := #'long long'.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #'long long'.
	
	"check that the system is in the assumed state."
	self assert: (ccg isIntegralCType: #'unsigned int').
	self assert: (ccg sizeOfIntegralCType: #'unsigned int') equals: 4.
	self assert: (ccg isIntegralCType: #'long long').
	self assert: (ccg sizeOfIntegralCType: #'long long') equals: 8.
]

{ #category : #'integer-types' }
SlangTypePromotionTest >> testsqLongAndLongLong [
	"representative of two types bigger than sizeOf(int) and with same size"
	| firstType secondType resType |
	firstType := #sqLong.
	secondType := #'long long'.
	resType := ccg promoteArithmeticTypes: firstType and: secondType.
	
	self assert: resType equals: #sqLong.
	
	"check that the system is in the assumed state."
	self assert: (ccg isIntegralCType: #sqLong).
	self assert: (ccg sizeOfIntegralCType: #sqLong) equals: 8.
	self assert: (ccg isIntegralCType: #'long long').
	self assert: (ccg sizeOfIntegralCType: #'long long') equals: 8.
]
