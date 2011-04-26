Extension { #name : #Float }

{ #category : #'*VMMaker-Cog tests' }
Float >> asIEEE64BitWord [
	^((self basicAt: 1) bitShift: 32) + (self basicAt: 2)
]

{ #category : #'*VMMaker-plugin generation' }
Float class >> ccg: cg generateCoerceToOopFrom: aNode on: aStream [
	"N.B.  The is used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToFloatObjectFrom: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
Float class >> ccg: cg generateCoerceToValueFrom: aNode on: aStream [
	"N.B.  The could be used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToFloatValueFrom: aNode on: aStream
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
