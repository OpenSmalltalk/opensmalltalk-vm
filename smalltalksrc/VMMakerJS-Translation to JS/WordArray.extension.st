Extension { #name : #WordArray }

{ #category : #'*vmmakerjs' }
WordArray class >> jscg: cg prolog: aBlock expr: aString index: anInteger [

	^cg 
		jscgLoad: aBlock 
		expr: aString 
		asUnsignedPtrFrom: anInteger
		andThen: (cg jscgValBlock: 'isWords')
]
