Extension { #name : #IntegerArray }

{ #category : #'*VMMaker-plugin generation' }
IntegerArray class >> ccg: cg emitLoadFor: aString from: anInteger on: aStream [

	cg emitLoad: aString asIntPtrFrom: anInteger on: aStream
]

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
