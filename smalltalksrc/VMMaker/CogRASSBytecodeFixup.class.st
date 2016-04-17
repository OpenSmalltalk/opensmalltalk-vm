Class {
	#name : #CogRASSBytecodeFixup,
	#superclass : #CogSSBytecodeFixup,
	#instVars : [
		'mergeSimStack'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CogRASSBytecodeFixup class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a CogRASSBytecodeFixup struct."

	self allInstVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
					['targetInstruction']	-> [#'AbstractInstruction *'].
					['mergeSimStack']	-> [#'CogSimStackEntry *'] }
					otherwise: [#sqInt])]
]

{ #category : #accessing }
CogRASSBytecodeFixup >> mergeSimStack [

	^ mergeSimStack
]

{ #category : #accessing }
CogRASSBytecodeFixup >> mergeSimStack: anObject [

	^mergeSimStack := anObject
]
