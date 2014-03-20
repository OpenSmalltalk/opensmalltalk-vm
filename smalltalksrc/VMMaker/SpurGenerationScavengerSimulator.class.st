Class {
	#name : #SpurGenerationScavengerSimulator,
	#superclass : #SpurGenerationScavenger,
	#category : #'VMMaker-SpurMemoryManagerSimulation'
}

{ #category : #initialization }
SpurGenerationScavengerSimulator >> manager: aSpurNBitMMXEndianSimulator [
	manager := aSpurNBitMMXEndianSimulator.
	aSpurNBitMMXEndianSimulator coInterpreter ifNotNil:
		[:coint| coInterpreter := coint]
]

{ #category : #'store check' }
SpurGenerationScavengerSimulator >> remember: objOop [
	(rememberedSetSize > 0
	 and: [(rememberedSet at: rememberedSetSize - 1) = objOop]) ifTrue:
		[self halt].
	^super remember: objOop
]

{ #category : #scavenger }
SpurGenerationScavengerSimulator >> scavenge: tenuringCriterion [
	coInterpreter transcript nextPutAll: 'scavenging ('; print: manager statScavenges; nextPutAll: ') ...'; flush.
	^super scavenge: tenuringCriterion
]
