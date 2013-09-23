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
	true ifTrue: [^super copyAndForward: survivor.].
	"(#(16r13BC78 16r13BD68 16r1ED780 16r1FC558) includes: survivor) ifTrue: [self halt]."
	newLocation := super copyAndForward: survivor.
	comeFroms at: newLocation put: survivor.
	"((manager isContextNonImm: newLocation)
	 and: [#(16r11D6988 16r11D6A48 16r11D6AC0 16r11D6B80) includes: newLocation]) ifTrue:
		[self halt]."
	^newLocation
]

{ #category : #scavenger }
SpurGenerationScavengerSimulator >> scavenge [
	comeFroms := Dictionary new.
	^super scavenge
]
