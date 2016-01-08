Class {
	#name : #CogPrimitiveDescriptor,
	#superclass : #VMStructType,
	#instVars : [
		'primitiveGenerator',
		'primNumArgs'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CogPrimitiveDescriptor class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a PrimitiveDescriptor struct."

	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn = 'primitiveGenerator'
					ifTrue: [#('sqInt (*' ')(void)')]
					ifFalse: [#sqInt])]
]

{ #category : #translation }
CogPrimitiveDescriptor class >> structTypeName [
	^self name allButFirst: 3 "Drop initial Cog"
]

{ #category : #accessing }
CogPrimitiveDescriptor >> primNumArgs [
	"Answer the value of primNumArgs"

	^primNumArgs
]

{ #category : #accessing }
CogPrimitiveDescriptor >> primNumArgs: anObject [
	"Set the value of primNumArgs"

	^primNumArgs := anObject
]

{ #category : #accessing }
CogPrimitiveDescriptor >> primitiveGenerator [
	"Answer the value of primitiveGenerator"

	^primitiveGenerator
]

{ #category : #accessing }
CogPrimitiveDescriptor >> primitiveGenerator: anObject [
	"Set the value of primitiveGenerator"

	^primitiveGenerator := anObject
]

{ #category : #translation }
CogPrimitiveDescriptor >> printCInitializerOn: aStream in: aCCodeGenerator [
	<doNotGenerate>
	| first |
	first := true.
	aStream nextPut: ${; space.
	self class instVarNamesAndTypesForTranslationDo:
		[:ivn :type| | value |
		first ifTrue: [first := false] ifFalse: [aStream nextPut: $,; space].
		value := self instVarNamed: ivn.
		aStream nextPutAll: (value
								ifNotNil: [value isSymbol
											ifTrue: [aCCodeGenerator cFunctionNameFor: value]
											ifFalse: [aCCodeGenerator cLiteralFor: value]]
								ifNil: ['0'])].
	aStream space; nextPut: $}
]
