"
Coercion specification for 32-bit unsigned numbers within plugins.

Note: ""x asOop: Unsigned"" can cause garbage collection when x is outside SmallInteger range.
"
Class {
	#name : #Unsigned,
	#superclass : #Behavior,
	#category : #'VMMaker-SmartSyntaxPlugins'
}

{ #category : #'plugin generation' }
Unsigned class >> ccg: cg generateCoerceToOopFrom: aNode on: aStream [
	"N.B.  The is used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToUnsignedObjectFrom: aNode on: aStream
]

{ #category : #'plugin generation' }
Unsigned class >> ccg: cg generateCoerceToValueFrom: aNode on: aStream [
	"N.B.  The could be used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToUnsignedValueFrom: aNode on: aStream
]

{ #category : #'plugin generation' }
Unsigned class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asUnsignedValueFrom: anInteger
]

{ #category : #'plugin generation' }
Unsigned class >> ccgCanConvertFrom: anObject [

	anObject isInteger ifFalse: 
		[self error: 'Not an Integer object'. ^false].
	anObject >= 0 ifFalse: 
		[self error: 'Object is negative integer'. ^false].
	anObject < (2 raisedToInteger: 32) ifFalse: 
		[self error: 'Object is too large'. ^false].
	^true
]

{ #category : #'plugin generation' }
Unsigned class >> ccgDeclareCForVar: aSymbolOrString [

	^'usqIntptr_t ', aSymbolOrString
]
