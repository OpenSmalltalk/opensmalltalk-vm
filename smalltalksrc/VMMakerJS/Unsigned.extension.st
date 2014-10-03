Extension { #name : #Unsigned }

{ #category : #'*vmmakerjs' }
Unsigned classSide >> jscg: cg generateCoerceToOopFrom: aNode on: aStream [
	"N.B.  The is used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToUnsignedObjectFrom: aNode on: aStream
]

{ #category : #'*vmmakerjs' }
Unsigned classSide >> jscg: cg generateCoerceToValueFrom: aNode on: aStream [
	"N.B.  The could be used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToUnsignedValueFrom: aNode on: aStream
]

{ #category : #'*vmmakerjs' }
Unsigned classSide >> jscg: cg prolog: aBlock expr: aString index: anInteger [

	^cg jscgLoad: aBlock expr: aString asUnsignedValueFrom: anInteger
]

{ #category : #'*vmmakerjs' }
Unsigned classSide >> jscgCanConvertFrom: anObject [

	anObject isInteger ifFalse: 
		[self error: 'Not an Integer object'. ^false].
	anObject >= 0 ifFalse: 
		[self error: 'Object is negative integer'. ^false].
	anObject < (2 raisedToInteger: 32) ifFalse: 
		[self error: 'Object is too large'. ^false].
	^true
]
