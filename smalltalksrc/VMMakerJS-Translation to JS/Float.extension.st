Extension { #name : #Float }

{ #category : #'*vmmakerjs' }
Float class >> jscg: cg generateCoerceToOopFrom: aNode on: aStream [
	"N.B.  The is used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToFloatObjectFrom: aNode on: aStream
]

{ #category : #'*vmmakerjs' }
Float class >> jscg: cg generateCoerceToValueFrom: aNode on: aStream [
	"N.B.  The could be used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToFloatValueFrom: aNode on: aStream
]

{ #category : #'*vmmakerjs' }
Float class >> jscg: cg prolog: aBlock expr: aString index: anInteger [

	^cg jscgLoad: aBlock expr: aString asFloatValueFrom: anInteger
]

{ #category : #'*vmmakerjs' }
Float class >> jscgCanConvertFrom: anObject [

	^anObject class == self
]
