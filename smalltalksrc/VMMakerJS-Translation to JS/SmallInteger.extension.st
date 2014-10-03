Extension { #name : #SmallInteger }

{ #category : #'*vmmakerjs' }
SmallInteger class >> jscg: cg generateCoerceToOopFrom: aNode on: aStream [
	"N.B.  The is used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToSmallIntegerObjectFrom: aNode on: aStream
]

{ #category : #'*vmmakerjs' }
SmallInteger class >> jscg: cg generateCoerceToValueFrom: aNode on: aStream [
	"N.B.  The could be used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToSmallIntegerValueFrom: aNode on: aStream
]

{ #category : #'*vmmakerjs' }
SmallInteger class >> jscg: cg prolog: aBlock expr: aString index: anInteger [

	^cg jscgLoad: aBlock expr: aString asIntegerValueFrom: anInteger
]

{ #category : #'*vmmakerjs' }
SmallInteger class >> jscgCanConvertFrom: anObject [

	^anObject class == self
]
