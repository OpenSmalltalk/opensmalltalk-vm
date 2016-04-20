Class {
	#name : #CogRASSBytecodeFixup,
	#superclass : #CogSSBytecodeFixup,
	#instVars : [
		'mergeFixup'
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
					['mergeFixup']		-> [#'CogSimStackEntry *'] }
					otherwise: [#sqInt])]
]

{ #category : #accessing }
CogRASSBytecodeFixup >> mergeFixup [

	^ mergeFixup
]

{ #category : #accessing }
CogRASSBytecodeFixup >> mergeFixup: anObject [

	^mergeFixup := anObject
]
