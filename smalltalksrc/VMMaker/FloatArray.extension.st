Extension { #name : #FloatArray }

{ #category : #'*VMMaker-plugin generation' }
FloatArray class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asWBFloatPtrFrom: anInteger
]

{ #category : #'*VMMaker-plugin generation' }
FloatArray class >> ccgDeclareCForVar: aSymbolOrString [

	^'float *', aSymbolOrString
]
