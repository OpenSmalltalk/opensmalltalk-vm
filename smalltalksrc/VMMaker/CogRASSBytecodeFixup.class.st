Class {
	#name : #CogRASSBytecodeFixup,
	#superclass : #CogSSBytecodeFixup,
	#instVars : [
		'cogit',
		'mergeSimStack'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'instance creation' }
CogRASSBytecodeFixup class >> for: aCogit [
	^self new cogit: aCogit
]

{ #category : #translation }
CogRASSBytecodeFixup class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a CogRASSBytecodeFixup struct."

	(self allInstVarNames copyWithout: 'cogit') do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
					['targetInstruction']	-> [#'AbstractInstruction *'].
					['mergeSimStack']	-> [#'CogSimStackEntry *'] }
					otherwise: [#sqInt])]
]

{ #category : #'initialize-release' }
CogRASSBytecodeFixup >> cogit: aCogit [
	cogit := aCogit.
	^self
]

{ #category : #accessing }
CogRASSBytecodeFixup >> mergeSimStack [

	^ mergeSimStack
]

{ #category : #accessing }
CogRASSBytecodeFixup >> mergeSimStack: anObject [

	^mergeSimStack := anObject
]

{ #category : #'debug printing' }
CogRASSBytecodeFixup >> printMergeSimStack [
	<doNotGenerate>
	self notAFixup ifFalse:
		[cogit printSimStack: mergeSimStack toDepth: simStackPtr spillBase: -1]
]
