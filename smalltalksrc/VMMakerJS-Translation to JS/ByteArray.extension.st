Extension { #name : #ByteArray }

{ #category : #'*vmmakerjs' }
ByteArray class >> jscg: cg prolog: aBlock expr: aString index: anInteger [

	^cg 
		jscgLoad: aBlock 
		expr: aString 
		asCharPtrFrom: anInteger
		andThen: (cg jscgValBlock: 'isBytes')
]
