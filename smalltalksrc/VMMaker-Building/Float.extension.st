Extension { #name : #Float }

{ #category : #'*VMMaker-plugin generation' }
Float class >> ccg: cg emitLoadFor: aString from: anInteger on: aStream [

	cg emitLoad: aString asFloatValueFrom: anInteger on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
Float class >> ccg: cg generateCoerceToOopFrom: aNode on: aStream [

	cg generateCoerceToFloatObjectFrom: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
Float class >> ccg: cg generateCoerceToValueFrom: aNode on: aStream [

	cg generateCoerceToFloatValueFrom: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
Float class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asFloatValueFrom: anInteger
]

{ #category : #'*VMMaker-plugin generation' }
Float class >> ccgCanConvertFrom: anObject [

	^anObject class == self
]

{ #category : #'*VMMaker-plugin generation' }
Float class >> ccgDeclareCForVar: aSymbolOrString [

	^'double ', aSymbolOrString
]
