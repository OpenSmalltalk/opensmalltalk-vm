Class {
	#name : #SpurGenerationScavengerSimulator,
	#superclass : #SpurGenerationScavenger,
	#category : 'VMMaker-SpurMemoryManagerSimulation'
}

{ #category : #'remembered set' }
SpurGenerationScavengerSimulator >> computeRefCountToShrinkRT [
	self halt.
	^super computeRefCountToShrinkRT
]

{ #category : #initialization }
SpurGenerationScavengerSimulator >> manager: aSpurNBitMMXEndianSimulator [
	manager := aSpurNBitMMXEndianSimulator.
	aSpurNBitMMXEndianSimulator coInterpreter ifNotNil:
		[:coint| coInterpreter := coint]
]

{ #category : #scavenger }
SpurGenerationScavengerSimulator >> scavenge: tenuringCriterion [
	manager bootstrapping ifFalse:
		[coInterpreter transcript nextPutAll: 'scavenging('; print: manager statScavenges; nextPutAll: ')...'; flush].
	^super scavenge: tenuringCriterion
]
