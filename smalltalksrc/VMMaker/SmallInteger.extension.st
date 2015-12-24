Extension { #name : #SmallInteger }

{ #category : #'*VMMaker-plugin generation' }
SmallInteger class >> ccg: cg generateCoerceToOopFrom: aNode on: aStream [
	"N.B.  The is used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToSmallIntegerObjectFrom: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
SmallInteger class >> ccg: cg generateCoerceToValueFrom: aNode on: aStream [
	"N.B.  The could be used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToSmallIntegerValueFrom: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
SmallInteger class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asIntegerValueFrom: anInteger
]

{ #category : #'*VMMaker-plugin generation' }
SmallInteger class >> ccgCanConvertFrom: anObject [

	^anObject isInteger
]

{ #category : #'*VMMaker-interpreter simulator' }
SmallInteger >> isBreakpointFor: address [
	<primitive: 7>
	^self = address
]

{ #category : #'*VMMaker-interpreter simulator' }
SmallInteger >> signedIntFromLong64 [
	"Self is a signed or unsigned 64-bit integer.
	 Currently SmallIntegers are either 31-bit (in the 32-bit implementation) or 61-bit
	 (in the 64-bit implementation) so save some time by overriding in the subclass."
	^self
]
