"
This plugin defines primitives that support the DigitalSignatureAlgorithm class. Three of these primitives support fast multiplication and division of very large integers, three others support the SecureHashAlgorithm.

"
Class {
	#name : #DSAPlugin,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'dsaRemainder',
		'dsaDivisor',
		'dsaQuotient',
		'remainderDigitCount',
		'divisorDigitCount'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #'plugin translation' }
DSAPlugin class >> declareCVarsIn: cg [
	cg var: #dsaRemainder type: #'unsigned char*'.
	cg var: #dsaDivisor type:  #'unsigned char*'.
	cg var: #dsaQuotient type: #'unsigned char*'
]

{ #category : #'plugin translation' }
DSAPlugin class >> moduleName [
	"Time millisecondsToRun: [
		DSAPlugin translateDoInlining: true]"

	^ 'DSAPrims' "Yes - it needs to be named this way or else we'll not find it"

]

{ #category : #private }
DSAPlugin >> addBackDivisorDigitShift: digitShift [
	"Add back the divisor shifted left by the given number of digits. This is done only when the estimate of quotient digit was one larger than the correct value."

	| carry rIndex sum |
	carry _ 0.
	rIndex _ digitShift + 1.
	1 to: divisorDigitCount do: [:i |
		sum _ (dsaRemainder at: rIndex) + (dsaDivisor at: i) + carry.
		dsaRemainder at: rIndex put: (sum bitAnd: 16rFF).
		carry _ sum bitShift: -8.
		rIndex _ rIndex + 1].

	"do final carry"
	sum _ (dsaRemainder at: rIndex) + carry.
	dsaRemainder at: rIndex put: (sum bitAnd: 16rFF).

	"Note: There should be a final carry that cancels out the excess borrow."
	"Assert: (sum bitShift: -8) ~= 1 ifTrue: [self halt: 'no carry!']."

]

{ #category : #private }
DSAPlugin >> bigDivideLoop [
	"This is the core of the divide algorithm. This loop steps through the digit positions of the quotient, each time estimating the right quotient digit, subtracting from the remainder the divisor times the quotient digit shifted left by the appropriate number of digits. When the loop terminates, all digits of the quotient have been filled in and the remainder contains a value less than the divisor. The tricky bit is estimating the next quotient digit. Knuth shows that the digit estimate computed here will never be less than it should be and cannot be more than one over what it should be. Furthermore, the case where the estimate is one too large is extremely rare. For example, in a typical test of 100000 random 60-bit division problems, the rare case only occured five times. See Knuth, volume 2 ('Semi-Numerical Algorithms') 2nd edition, pp. 257-260"

	| d1 d2 firstDigit firstTwoDigits thirdDigit q digitShift qTooBig |
	"extract the top two digits of the divisor"
	d1 _ dsaDivisor at: divisorDigitCount.
	d2 _ dsaDivisor at: divisorDigitCount - 1.

	remainderDigitCount to: divisorDigitCount + 1 by: -1 do: [:j |
		"extract the top several digits of remainder."
		firstDigit _ dsaRemainder at: j.
		firstTwoDigits _ (firstDigit bitShift: 8) + (dsaRemainder at: j - 1).
		thirdDigit _ dsaRemainder at: j - 2.

		"estimate q, the next digit of the quotient"
		firstDigit = d1
			ifTrue: [q _ 255]
			ifFalse: [q _ firstTwoDigits // d1].

		"adjust the estimate of q if necessary"
		(d2 * q) > (((firstTwoDigits - (q * d1)) bitShift: 8) + thirdDigit) ifTrue: [	
			q _ q - 1.
			(d2 * q) > (((firstTwoDigits - (q * d1)) bitShift: 8) + thirdDigit) ifTrue: [
				q _ q - 1]].

		digitShift _ j - divisorDigitCount - 1.
		q > 0 ifTrue: [
			qTooBig _ self subtractDivisorMultipliedByDigit: q digitShift: digitShift.
			qTooBig ifTrue: [  "this case is extremely rare"
				self addBackDivisorDigitShift: digitShift.
				q _ q - 1]].

		"record this digit of the quotient"
		dsaQuotient at: digitShift + 1 put: q].

]

{ #category : #private }
DSAPlugin >> leftRotate: anInteger by: bits [
	"Rotate the given 32-bit integer left by the given number of bits and answer the result."

	self var: #anInteger declareC: 'unsigned int anInteger'.
	^ (anInteger << bits) bitOr: (anInteger >> (32 - bits))

]

{ #category : #'primitives-integers' }
DSAPlugin >> primitiveBigDivide [
	"Called with three LargePositiveInteger arguments, rem, div, quo. Divide div into rem and store the quotient into quo, leaving the remainder in rem."
	"Assume: quo starts out filled with zeros."

	| rem div quo |
	self export: true.
	quo _ interpreterProxy stackObjectValue: 0.
	div _ interpreterProxy stackObjectValue: 1.
	rem _ interpreterProxy stackObjectValue: 2.

	interpreterProxy success:
		(interpreterProxy fetchClassOf: rem) = interpreterProxy classLargePositiveInteger.
	interpreterProxy success:
		(interpreterProxy fetchClassOf: div) = interpreterProxy classLargePositiveInteger.
	interpreterProxy success:
		(interpreterProxy fetchClassOf: quo) = interpreterProxy classLargePositiveInteger.
	interpreterProxy failed ifTrue:[^ nil].

	dsaRemainder _ interpreterProxy firstIndexableField: rem.
	dsaDivisor _ interpreterProxy firstIndexableField: div.
	dsaQuotient _ interpreterProxy firstIndexableField: quo.

	divisorDigitCount _ interpreterProxy stSizeOf: div.
	remainderDigitCount _ interpreterProxy stSizeOf: rem.

	"adjust pointers for base-1 indexing"
	dsaRemainder _ dsaRemainder - 1.
	dsaDivisor _ dsaDivisor - 1.
	dsaQuotient _ dsaQuotient - 1.

	self bigDivideLoop.
	interpreterProxy pop: 3.

]

{ #category : #'primitives-integers' }
DSAPlugin >> primitiveBigMultiply [
	"Multiple f1 by f2, placing the result into prod. f1, f2, and prod must be LargePositiveIntegers, and the length of prod must be the sum of the lengths of f1 and f2."
	"Assume: prod starts out filled with zeros"

	| prod f2 f1 prodLen f1Len f2Len prodPtr f2Ptr f1Ptr digit carry k sum |
	self export: true.
	self var: #prodPtr declareC: 'unsigned char *prodPtr'.
	self var: #f2Ptr declareC: 'unsigned char *f2Ptr'.
	self var: #f1Ptr declareC: 'unsigned char *f1Ptr'.

	prod _ interpreterProxy stackObjectValue: 0.
	f2 _ interpreterProxy stackObjectValue: 1.
	f1 _ interpreterProxy stackObjectValue: 2.
	interpreterProxy success: (interpreterProxy isBytes: prod).
	interpreterProxy success: (interpreterProxy isBytes: f2).
	interpreterProxy success: (interpreterProxy isBytes: f1).
	interpreterProxy success:
		(interpreterProxy fetchClassOf: prod) = interpreterProxy classLargePositiveInteger.
	interpreterProxy success:
		(interpreterProxy fetchClassOf: f2) = interpreterProxy classLargePositiveInteger.
	interpreterProxy success:
		(interpreterProxy fetchClassOf: f1) = interpreterProxy classLargePositiveInteger.
	interpreterProxy failed ifTrue:[^ nil].

	prodLen _ interpreterProxy stSizeOf: prod.
	f1Len _ interpreterProxy stSizeOf: f1.
	f2Len _ interpreterProxy stSizeOf: f2.
	interpreterProxy success: (prodLen = (f1Len + f2Len)).
	interpreterProxy failed ifTrue:[^ nil].

	prodPtr _ interpreterProxy firstIndexableField: prod.
	f2Ptr _ interpreterProxy firstIndexableField: f2.
	f1Ptr _ interpreterProxy firstIndexableField: f1.

	0 to: f1Len-1 do: [:i | 
		(digit _ f1Ptr at: i) ~= 0 ifTrue: [
			carry _ 0.
			k _ i.
			"Loop invariants: 0 <= carry <= 16rFF, k = i + j - 1"
			0 to: f2Len-1 do: [:j | 
				sum _ ((f2Ptr at: j) * digit) + (prodPtr at: k) + carry.
				carry _ sum bitShift: -8.
				prodPtr at: k put: (sum bitAnd: 255).
				k _ k + 1].
			prodPtr at: k put: carry]].

	interpreterProxy pop: 3.

]

{ #category : #'primitives-SHA' }
DSAPlugin >> primitiveExpandBlock [
	"Expand a 64 byte ByteArray (the first argument) into and an Bitmap of 80 32-bit words (the second argument). When reading a 32-bit integer from the ByteArray, consider the first byte to contain the most significant bits of the word (i.e., use big-endian byte ordering)."

	| expanded buf wordPtr bytePtr src v |
	self export: true.
	self var: #wordPtr declareC: 'unsigned int *wordPtr'.
	self var: #bytePtr declareC: 'unsigned char *bytePtr'.

	expanded _ interpreterProxy stackObjectValue: 0.
	buf _ interpreterProxy stackObjectValue: 1.
	interpreterProxy success: (interpreterProxy isWords: expanded).
	interpreterProxy success: (interpreterProxy isBytes: buf).
	interpreterProxy failed ifTrue: [^ nil].

	interpreterProxy success: ((interpreterProxy stSizeOf: expanded) = 80).
	interpreterProxy success: ((interpreterProxy stSizeOf: buf) = 64).
	interpreterProxy failed ifTrue: [^ nil].

	wordPtr _ interpreterProxy firstIndexableField: expanded.
	bytePtr _ interpreterProxy firstIndexableField: buf.

	src _ 0.
	0 to: 15 do: [:i |
		v _ ((bytePtr at: src) << 24) +
			((bytePtr at: src + 1) << 16) +
			((bytePtr at: src + 2) << 8) +
			(bytePtr at: src + 3).
		wordPtr at: i put: v.
		src _ src + 4].

	16 to: 79 do: [:i |
		v _ (((wordPtr at: i - 3) bitXor:
			 (wordPtr at: i - 8)) bitXor:
			 (wordPtr at: i - 14)) bitXor:
			 (wordPtr at: i - 16).
		v _ self leftRotate: v by: 1.
		wordPtr at: i put: v].

	interpreterProxy pop: 2.

]

{ #category : #'primitives-SHA' }
DSAPlugin >> primitiveHasSecureHashPrimitive [
	"Answer true if the secure hash primitive is implemented."

	self export: true.
	interpreterProxy pop: 1.
	interpreterProxy pushBool: true.

]

{ #category : #'primitives-SHA' }
DSAPlugin >> primitiveHashBlock [
	"Hash a Bitmap of 80 32-bit words (the first argument), using the given state (the second argument)."

	| state buf statePtr bufPtr a b c d e tmp |
	self export: true.
	self var: #statePtr declareC: 'unsigned int *statePtr'.
	self var: #bufPtr declareC: 'unsigned int *bufPtr'.

	state _ interpreterProxy stackObjectValue: 0.
	buf _ interpreterProxy stackObjectValue: 1.
	interpreterProxy success: (interpreterProxy isWords: state).
	interpreterProxy success: (interpreterProxy isWords: buf).
	interpreterProxy failed ifTrue: [^ nil].

	interpreterProxy success: ((interpreterProxy stSizeOf: state) = 5).
	interpreterProxy success: ((interpreterProxy stSizeOf: buf) = 80).
	interpreterProxy failed ifTrue: [^ nil].

	statePtr _ interpreterProxy firstIndexableField: state.
	bufPtr _ interpreterProxy firstIndexableField: buf.

	a _ statePtr at: 0.
	b _ statePtr at: 1.
	c _ statePtr at: 2.
	d _ statePtr at: 3.
	e _ statePtr at: 4.
 
	0 to: 19 do: [:i |
		tmp _ 16r5A827999 + ((b bitAnd: c) bitOr: (b bitInvert32 bitAnd: d)) +
				(self leftRotate: a by: 5) +  e + (bufPtr at: i).
		e _ d.  d _ c.  c _ self leftRotate: b by: 30.  b _ a.  a _ tmp].

	20 to: 39 do: [:i |
		tmp _ 16r6ED9EBA1 + ((b bitXor: c) bitXor: d) +
				(self leftRotate: a by: 5) +  e + (bufPtr at: i).
		e _ d.  d _ c.  c _ self leftRotate: b by: 30.  b _ a.  a _ tmp].

	40 to: 59 do: [:i |
		tmp _ 16r8F1BBCDC + (((b bitAnd: c) bitOr: (b bitAnd: d)) bitOr: (c bitAnd: d)) +
				(self leftRotate: a by: 5) +  e + (bufPtr at: i).
		e _ d.  d _ c.  c _ self leftRotate: b by: 30.  b _ a.  a _ tmp].

	60 to: 79 do: [:i |
		tmp _ 16rCA62C1D6 + ((b bitXor: c) bitXor: d) +
				(self leftRotate: a by: 5) +  e + (bufPtr at: i).
		e _ d.  d _ c.  c _ self leftRotate: b by: 30.  b _ a.  a _ tmp].

	statePtr at: 0 put: (statePtr at: 0) + a.
	statePtr at: 1 put: (statePtr at: 1) + b.
	statePtr at: 2 put: (statePtr at: 2) + c.
	statePtr at: 3 put: (statePtr at: 3) + d.
	statePtr at: 4 put: (statePtr at: 4) + e.

	interpreterProxy pop: 2.

]

{ #category : #'primitives-integers' }
DSAPlugin >> primitiveHighestNonZeroDigitIndex [
	"Called with one LargePositiveInteger argument. Answer the index of the top-most non-zero digit."

	| arg bigIntPtr i |
	self export: true.
	self var: #bigIntPtr declareC: 'unsigned char *bigIntPtr'.

	arg _ interpreterProxy stackObjectValue: 0.
	interpreterProxy success:
		(interpreterProxy fetchClassOf: arg) = interpreterProxy classLargePositiveInteger.
	interpreterProxy failed ifTrue: [^ nil].

	bigIntPtr _ interpreterProxy firstIndexableField: arg.
	i _ interpreterProxy stSizeOf: arg.
	[(i > 0) and: [(bigIntPtr at: (i _ i - 1)) = 0]]
		whileTrue: ["scan down from end to first non-zero digit"].

	interpreterProxy pop: 1.
	interpreterProxy pushInteger: i + 1.

]

{ #category : #private }
DSAPlugin >> subtractDivisorMultipliedByDigit: digit digitShift: digitShift [
	"Multiply the divisor by the given digit (an integer in the range 0..255), shift it left by the given number of digits, and subtract the result from the current remainder. Answer true if there is an excess borrow, indicating that digit was one too large. (This case is quite rare.)"

	| borrow rIndex prod resultDigit |
	borrow _ 0.
	rIndex _ digitShift + 1.
	1 to: divisorDigitCount do: [:i |
		prod _ ((dsaDivisor at: i) * digit) + borrow.
		borrow _ prod bitShift: -8.
		resultDigit _ (dsaRemainder at: rIndex) - (prod bitAnd: 16rFF).
		resultDigit < 0 ifTrue: [  "borrow from the next digit"
			resultDigit _ resultDigit + 256.
			borrow _ borrow + 1].
		dsaRemainder at: rIndex put: resultDigit.
		rIndex _ rIndex + 1].

	"propagate the final borrow if necessary"
	borrow = 0 ifTrue: [^ false].
	resultDigit _ (dsaRemainder at: rIndex) - borrow.
	resultDigit < 0
		ifTrue: [  "digit was too large (this case is quite rare)"
			dsaRemainder at: rIndex put: resultDigit + 256.
			^ true]
		ifFalse: [
			dsaRemainder at: rIndex put: resultDigit.
			^ false].

]
