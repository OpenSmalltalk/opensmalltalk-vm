"
A SpurHybridCompactor is a compactor that uses SpurSelectiveCompactor for normal GC compactions, but uses SpurPlanningCompactor for snapshot.

Instance Variables
	planNotSelect:			<Boolean>
	planningCompactor:	<SpurPlanningCompactor>
	selectiveCompactor:	<SpurSelectiveCompactor>

planNotSelect
	- the boolean that selects between the two compactors; if true it chooses SpurPlanningCompactor

planningCompactor
	- the SpurPlanningCompactor

selectiveCompactor
	- the SpurSelectiveCompactor

"
Class {
	#name : #SpurHybridCompactor,
	#superclass : #SpurCompactor,
	#instVars : [
		'planningCompactor',
		'selectiveCompactor',
		'planNotSelect'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #translation }
SpurHybridCompactor class >> classesForTranslation [
	^{	SpurPlanningCompactor.
		SpurSelectiveCompactor.
		SpurSweeper }, super classesForTranslation
]

{ #category : #translation }
SpurHybridCompactor class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator
		staticallyResolvedPolymorphicReceiver: 'planningCompactor' to: SpurPlanningCompactor;
		staticallyResolvedPolymorphicReceiver: 'selectiveCompactor' to: SpurSweeper"SpurSelectiveCompactor" "The selector mangling is easier this way"
]

{ #category : #api }
SpurHybridCompactor >> biasForGC [
	<inline: true>
	planNotSelect := false.
	selectiveCompactor biasForGC
]

{ #category : #api }
SpurHybridCompactor >> biasForSnapshot [
	planNotSelect := true.
	planningCompactor biasForSnapshot
]

{ #category : #initialization }
SpurHybridCompactor >> coInterpreter: aVMSimulator [
	<doNotGenerate>
	super coInterpreter: aVMSimulator.
	planningCompactor coInterpreter: aVMSimulator.
	selectiveCompactor coInterpreter: aVMSimulator
]

{ #category : #api }
SpurHybridCompactor >> compact [
	planNotSelect
		ifTrue: [planningCompactor compact]
		ifFalse: [selectiveCompactor compact]
]

{ #category : #initialization }
SpurHybridCompactor >> manager: aSpurNBitMMXEndianSimulator [
	<doNotGenerate>
	super manager: aSpurNBitMMXEndianSimulator.
	(planningCompactor ifNil: [planningCompactor := SpurPlanningCompactor simulatorClass new])
		manager: aSpurNBitMMXEndianSimulator.
	(selectiveCompactor ifNil: [selectiveCompactor := SpurSelectiveCompactor simulatorClass new])
		manager: aSpurNBitMMXEndianSimulator.

	planNotSelect := false
]

{ #category : #api }
SpurHybridCompactor >> remapObj: objOop [
	<api>
	<inline: false>
	planNotSelect ifTrue:
		[^manager slidingCompactionRemapObj: objOop].
	^super remapObj: objOop
]

{ #category : #initialization }
SpurHybridCompactor >> scavenger: aSpurGenerationScavenger [
	<doNotGenerate>
	super scavenger: aSpurGenerationScavenger. "I always thought the scavenger was super..."
	planningCompactor scavenger: aSpurGenerationScavenger.
	selectiveCompactor scavenger: aSpurGenerationScavenger
]

{ #category : #api }
SpurHybridCompactor >> shouldRemapObj: objOop [
	<api>
	<inline: false>
	planNotSelect ifTrue:
		[^manager slidingCompactionShouldRemapObj: objOop].
	^super shouldRemapObj: objOop
]
