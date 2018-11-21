Extension { #name : #Boolean }

{ #category : #'*vmmakerjs' }
Boolean class >> jscg: cg generateCoerceToOopFrom: aNode on: aStream [
	"N.B.  The is used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToBooleanObjectFrom: aNode on: aStream
]

{ #category : #'*vmmakerjs' }
Boolean class >> jscg: cg generateCoerceToValueFrom: aNode on: aStream [
	"N.B.  The could be used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToBooleanValueFrom: aNode on: aStream
]

{ #category : #'*vmmakerjs' }
Boolean class >> jscg: cg prolog: aBlock expr: aString index: anInteger [

	^cg jscgLoad: aBlock expr: aString asBooleanValueFrom: anInteger
]
