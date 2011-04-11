Extension { #name : #FloatArray }

{ #category : #'*VMMaker-plugin generation' }
FloatArray class >> ccg: cg emitLoadFor: aString from: anInteger on: aStream [

	cg emitLoad: aString asFloatPtrFrom: anInteger on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
FloatArray class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asWBFloatPtrFrom: anInteger
]

{ #category : #'*VMMaker-plugin generation' }
FloatArray class >> ccgDeclareCForVar: aSymbolOrString [

	^'float *', aSymbolOrString
]
