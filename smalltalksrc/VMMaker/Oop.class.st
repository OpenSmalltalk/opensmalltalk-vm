"
Cooercion specification for Identity coercions:

	x asOop: Oop == x
	y asValue: Oop == y
"
Class {
	#name : #Oop,
	#superclass : #Behavior,
	#category : 'VMMaker-SmartSyntaxPlugins'
}

{ #category : #'plugin generation' }
Oop class >> ccg: cg generateCoerceToOopFrom: aNode on: aStream [

	cg emitCExpression: aNode on: aStream
]

{ #category : #'plugin generation' }
Oop class >> ccg: cg generateCoerceToValueFrom: aNode on: aStream [

	cg emitCExpression: aNode on: aStream
]

{ #category : #'plugin generation' }
Oop class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asRawOopFrom: anInteger
]

{ #category : #'plugin generation' }
Oop class >> ccgCanConvertFrom: anObject [

	^(anObject isKindOf: SmallInteger) not
]

{ #category : #'plugin generation' }
Oop class >> ccgDeclareCForVar: aSymbolOrString [

	^'int ', aSymbolOrString
]
