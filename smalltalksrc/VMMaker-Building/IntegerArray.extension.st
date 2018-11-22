Extension { #name : #IntegerArray }

{ #category : #'*VMMaker-plugin generation' }
IntegerArray class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg 
		ccgLoad: aBlock 
		expr: aString 
		asIntPtrFrom: anInteger
		andThen: (cg ccgValBlock: 'isWords')
]

{ #category : #'*VMMaker-plugin generation' }
IntegerArray class >> ccgDeclareCForVar: aSymbolOrString [

	^'int *', aSymbolOrString
]
