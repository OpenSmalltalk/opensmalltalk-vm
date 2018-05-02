"
Coercion specification for bits objects like ByteString, Bitmap, ByteArray, WordArray, LargePositiveInteger et al
"
Class {
	#name : #WordsOrBytes,
	#superclass : #Behavior,
	#category : 'VMMaker-SmartSyntaxPlugins'
}

{ #category : #'plugin generation' }
WordsOrBytes class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg 
		ccgLoad: aBlock 
		expr: aString 
		asCharPtrFrom: anInteger
		andThen: (cg ccgValBlock: 'isWordsOrBytes')
]

{ #category : #'plugin generation' }
WordsOrBytes class >> ccgCanConvertFrom: anObject [

	^anObject class isBits
]

{ #category : #'plugin generation' }
WordsOrBytes class >> ccgDeclareCForVar: aSymbolOrString [

	^'char *', aSymbolOrString
]
