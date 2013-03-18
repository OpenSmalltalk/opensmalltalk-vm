Extension { #name : #WordArray }

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
	"Address of an unsigned 32 bit value, regardless of Smalltalk wordSize"

	^'unsigned *', aSymbolOrString
]
