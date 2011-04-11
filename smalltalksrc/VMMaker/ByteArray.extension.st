Extension { #name : #ByteArray }

{ #category : #'*VMMaker-plugin generation' }
ByteArray class >> ccg: cg emitLoadFor: aString from: anInteger on: aStream [

	cg emitLoad: aString asCharPtrFrom: anInteger on: aStream
]

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
