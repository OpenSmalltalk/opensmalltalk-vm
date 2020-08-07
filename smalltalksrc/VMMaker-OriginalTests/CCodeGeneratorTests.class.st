Class {
	#name : #CCodeGeneratorTests,
	#superclass : #TestCase,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #private }
CCodeGeneratorTests >> cg [
	^CCodeGenerator new
]

{ #category : #tests }
CCodeGeneratorTests >> testIntegerGeneration [

	"Test the 32-bit integers. They need to be marked as unsigned longs.
	 Test 16rFFFFFFFF, 16rFFFFFFFE, ... through to ..., 16rC0000000, 16r80000000"
	((0 to: 31) collect: [:shift| 16rFFFFFFFF bitClear: (1 bitShift: shift) - 1]) do:
		[:number| | literal |
		literal := self cg cLiteralFor: number.
		self assert: ((literal allButLast: 2) allSatisfy: [:c| c isDigit]).
		self assert: (literal endsWith: 'UL').

		literal := self cg cLiteralFor: number name: 'Mask'.
		self assert: (literal beginsWith: '0x').
		self assert: (((literal allButFirst: 2) allButLast: 2) allSatisfy: [:c| '0123456789CEF' includes: c]).
		self assert: (literal endsWith: 'UL')].

	"Test the 64-bit integers. They need to be marked as unsigned long longs."
	((32 to: 63) collect: [:shift| 16rFFFFFFFFFFFFFFFF bitClear: (1 bitShift: shift) - 1]) do:
		[:number| | literal |
		literal := self cg cLiteralFor: number.
		self assert: ((literal allButLast: 3) allSatisfy: [:c| c isDigit]).
		self assert: (literal endsWith: 'ULL').

		literal := self cg cLiteralFor: number name: 'Mask'.
		self assert: (literal beginsWith: '0x').
		self assert: (((literal allButFirst: 2) allButLast: 3) allSatisfy: [:c| '0123456789CEF' includes: c]).
		self assert: (literal endsWith: 'ULL')]
]
