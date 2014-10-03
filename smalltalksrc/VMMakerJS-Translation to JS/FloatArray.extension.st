Extension { #name : #FloatArray }

{ #category : #'*vmmakerjs' }
FloatArray class >> jscg: cg prolog: aBlock expr: aString index: anInteger [

	^cg jscgLoad: aBlock expr: aString asWBFloatPtrFrom: anInteger
]
