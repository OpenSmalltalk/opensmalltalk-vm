Extension { #name : #MultiString }

{ #category : #'*VMMaker-plugin generation' }
MultiString classSide >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg 
		ccgLoad: aBlock 
		expr: aString 
		asCharPtrFrom: anInteger
		andThen: (cg ccgValBlock: 'isBytes')
]

{ #category : #'*VMMaker-plugin generation' }
MultiString classSide >> ccgDeclareCForVar: aSymbolOrString [

	^'char *', aSymbolOrString
]
