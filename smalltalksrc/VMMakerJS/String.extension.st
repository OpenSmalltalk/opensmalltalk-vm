Extension { #name : #String }

{ #category : #'*vmmakerjs' }
String class >> jscg: cg prolog: aBlock expr: aString index: anInteger [

	^cg 
		jscgLoad: aBlock 
		expr: aString 
		asCharPtrFrom: anInteger
		andThen: (cg jscgValBlock: 'isBytes')
]
