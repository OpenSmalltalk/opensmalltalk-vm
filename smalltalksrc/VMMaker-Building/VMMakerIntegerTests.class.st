Class {
	#name : #VMMakerIntegerTests,
	#superclass : #TestCase,
	#category : #'VMMaker-Tests'
}

{ #category : #tests }
VMMakerIntegerTests >> testSignedIntFromFoo [
	self assert: 16r55 signedIntFromChar equals: 16r55.
	self assert: 16r155 signedIntFromChar equals: 16r55.
	self assert: 16rAA signedIntFromChar < 0.
	self assert: (16rAA signedIntFromChar bitAnd: 16rFF) = 16rAA.

	self assert: 16r5555 signedIntFromShort equals: 16r5555.
	self assert: 16r15555 signedIntFromShort equals: 16r5555.
	self assert: 16rAAAA signedIntFromShort < 0.
	self assert: (16rAAAA signedIntFromShort bitAnd: 16rFFFF) = 16rAAAA.

	self assert: 16r55555555 signedIntFromLong equals: 16r55555555.
	self assert: 16r155555555 signedIntFromLong equals: 16r55555555.
	self assert: 16rAAAAAAAA signedIntFromLong< 0.
	self assert: (16rAAAAAAAA signedIntFromLong bitAnd: 16rFFFFFFFF) = 16rAAAAAAAA.

	self assert: 16r5555555555555555 signedIntFromLong64 equals: 16r5555555555555555.
	self assert: 16r15555555555555555 signedIntFromLong64 equals: 16r5555555555555555.
	self assert: 16rAAAAAAAAAAAAAAAA signedIntFromLong64< 0.
	self assert: (16rAAAAAAAAAAAAAAAA signedIntFromLong64 bitAnd: 16rFFFFFFFFFFFFFFFF) = 16rAAAAAAAAAAAAAAAA
]

{ #category : #tests }
VMMakerIntegerTests >> testSignedIntToFoo [
	#(16r55 -16r56 16r5555 -16r5556 16r55555555 -16r55555556 16r5555555555555555 -16r5555555555555556) do:
		[:n|
		n abs digitLength = 1 ifTrue:
			[self assert: n signedIntToChar signedIntFromChar equals: n].
		self assert: (n signedIntToChar signedIntFromChar bitAnd: 16rFF) equals: (n bitAnd: 16rFF).
		n abs digitLength <= 2 ifTrue:
			[self assert: n signedIntToShort signedIntFromShort equals: n].
		self assert: (n signedIntToShort signedIntFromShort bitAnd: 16rFFFF) equals: (n bitAnd: 16rFFFF).
		n abs digitLength <= 4 ifTrue:
			[self assert: n signedIntToLong signedIntFromLong equals: n].
		self assert: (n signedIntToLong signedIntFromLong bitAnd: 16rFFFFFFFF) equals: (n bitAnd: 16rFFFFFFFF).
		n abs digitLength <= 8 ifTrue:
			[self assert: n signedIntToLong64 signedIntFromLong64 equals: n].
		self assert: (n signedIntToLong64 signedIntFromLong64 bitAnd: 16rFFFFFFFFFFFFFFFF) equals: (n bitAnd: 16rFFFFFFFFFFFFFFFF)]
]
