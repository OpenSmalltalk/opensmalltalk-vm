Extension { #name : #ByteArray }

{ #category : #'*VMMaker-plugin generation' }
ByteArray class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg 
		ccgLoad: aBlock 
		expr: aString 
		asCharPtrFrom: anInteger
		andThen: (cg ccgValBlock: 'isBytes')
]

{ #category : #'*VMMaker-plugin generation' }
ByteArray class >> ccgDeclareCForVar: aSymbolOrString [

	^'char *', aSymbolOrString
]
