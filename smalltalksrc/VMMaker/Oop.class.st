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
	"N.B.  The is used both for generation and simulation so answer the result (for interpretation)"
	^cg emitCExpression: aNode on: aStream
]

{ #category : #'plugin generation' }
Oop class >> ccg: cg generateCoerceToValueFrom: aNode on: aStream [
	"N.B.  The could be used both for generation and simulation so answer the result (for interpretation)"
	^cg emitCExpression: aNode on: aStream
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

	^'sqInt ', aSymbolOrString
]
