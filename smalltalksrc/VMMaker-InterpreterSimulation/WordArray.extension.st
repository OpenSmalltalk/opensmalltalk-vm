Extension { #name : #WordArray }

{ #category : #'*VMMaker-plugin generation' }
WordArray class >> ccg: cg emitLoadFor: aString from: anInteger on: aStream [

	cg emitLoad: aString asIntPtrFrom: anInteger on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
WordArray class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg 
		ccgLoad: aBlock 
		expr: aString 
		asUnsignedPtrFrom: anInteger
		andThen: (cg ccgValBlock: 'isWords')
]

{ #category : #'*VMMaker-plugin generation' }
WordArray class >> ccgDeclareCForVar: aSymbolOrString [

	^'usqInt *', aSymbolOrString
]
