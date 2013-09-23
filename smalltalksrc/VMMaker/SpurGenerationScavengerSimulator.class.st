Class {
	#name : #SpurGenerationScavengerSimulator,
	#superclass : #SpurGenerationScavenger,
	#instVars : [
		'comeFroms'
	],
	#category : #'VMMaker-SpurMemoryManagerSimulation'
}

{ #category : #scavenger }
SpurGenerationScavengerSimulator >> copyAndForward: survivor [
	| newLocation |
	survivor = 16r19BC60 ifTrue: [self halt].
	newLocation := super copyAndForward: survivor.
	comeFroms at: newLocation put: survivor.
	^newLocation
]

{ #category : #scavenger }
SpurGenerationScavengerSimulator >> scavenge [
	comeFroms := Dictionary new.
	^super scavenge
]
