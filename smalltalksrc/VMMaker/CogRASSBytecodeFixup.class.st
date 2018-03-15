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
	#category : 'VMMaker-JIT'
}

{ #category : #translation }
CogRASSBytecodeFixup class >> filteredInstVarNames [
	"Override to group char and short vars together for compactness.
	 self typedef"
	| vars |
	vars := super filteredInstVarNames asOrderedCollection.
	vars
		remove: 'mergeSimStack';
		add: 'mergeSimStack' afterIndex: (vars indexOf: 'targetInstruction').
	^vars
]

{ #category : #'instance creation' }
CogRASSBytecodeFixup class >> for: aCogit [
	^self new cogit: aCogit
]

{ #category : #'initialize-release' }
CogRASSBytecodeFixup >> cogit: aCogit [
	cogit := aCogit.
	^self
]

{ #category : #'debug printing' }
CogRASSBytecodeFixup >> hasMergeSimStack [
	^self needsFixup and: [mergeSimStack notNil]
]

{ #category : #accessing }
CogRASSBytecodeFixup >> mergeSimStack [
	<returnTypeC: #'CogSimStackEntry *'>
	^mergeSimStack
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

{ #category : #accessing }
CogRASSBytecodeFixup >> reinitialize [
	<inline: true>
	super reinitialize.
	mergeSimStack := nil
]

{ #category : #'debug printing' }
CogRASSBytecodeFixup >> simStackPrintString [
	<doNotGenerate>
	^String streamContents:
		[:s|
		 self notAFixup
			ifTrue: [s nextPutAll: 'notAFixup']
			ifFalse: [cogit printSimStack: mergeSimStack toDepth: simStackPtr spillBase: -1 on: s]]
]
