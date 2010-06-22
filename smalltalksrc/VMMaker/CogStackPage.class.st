Class {
	#name : #CogStackPage,
	#superclass : #CogSimpleStackPage,
	#instVars : [
		'savedRegisters'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CogStackPage class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a StackPage struct."

	superclass instVarNamesAndTypesForTranslationDo: aBinaryBlock.
	aBinaryBlock
		value: 'savedRegisters'
		value: #(#sqInt '[NumSavedRegisters]')
]

{ #category : #'simulation only' }
CogStackPage class >> surrogateClass [
	^BytesPerWord = 4
		ifTrue: [CogStackPageSurrogate32]
		ifFalse: [CogStackPageSurrogate64]
]
