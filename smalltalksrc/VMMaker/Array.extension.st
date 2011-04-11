Extension { #name : #Array }

{ #category : #'*VMMaker-plugin generation' }
Array class >> ccg: cg emitLoadFor: aString from: anInteger on: aStream [

	cg emitLoad: aString asIntPtrFrom: anInteger on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
Array class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg 
		ccgLoad: aBlock 
		expr: aString 
		asIntPtrFrom: anInteger
		andThen: (cg ccgValBlock: 'isIndexable')
]

{ #category : #'*VMMaker-plugin generation' }
Array class >> ccgDeclareCForVar: aSymbolOrString [

	^'sqInt *', aSymbolOrString
]
