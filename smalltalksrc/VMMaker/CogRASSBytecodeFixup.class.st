"
A CogRASSBytecodeFixup extends CogSSBytecodeFixup with state to merge the stack at control-flow joins, preserving register contents.  By holding onto the entire stack state a CogRASSBytecodeFixup allows RegisterAllocatingCogit to merge individual stack entries, instead of merely spilling to the same height.

Instance Variables
	cogit:					<RegisterAllocatingCogit>
	mergeSimStack:		<Array of: CogRegisterAllocatingSimStackEntry>

cogit
	- the JIT compiler

mergeSimStack
	- the state of the stack at the jump to this fixup
"
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
CogRASSBytecodeFixup >> printSimStack [
	<doNotGenerate>
	self notAFixup ifFalse:
		[cogit printSimStack: mergeSimStack toDepth: simStackPtr spillBase: -1 on: cogit coInterpreter transcript]
]

{ #category : #'debug printing' }
CogRASSBytecodeFixup >> printStateOn: aStream [
	<doNotGenerate>
	(targetInstruction isNil and: [simStackPtr isNil]) ifTrue:
		[^self].
	super printStateOn: aStream.
	mergeSimStack ifNotNil:
		[aStream skip: -1; space; nextPut: $(.
		 cogit printSimStack: mergeSimStack toDepth: simStackPtr spillBase: -1 on: aStream.
		 aStream nextPut: $); nextPut: $)]
]
