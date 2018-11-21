Extension { #name : #String }

{ #category : #'*VMMaker-plugin generation' }
String class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg 
		ccgLoad: aBlock 
		expr: aString 
		asCharPtrFrom: anInteger
		andThen: (cg ccgValBlock: 'isBytes')
]

{ #category : #'*VMMaker-plugin generation' }
String class >> ccgDeclareCForVar: aSymbolOrString [

	^'char *', aSymbolOrString
]
