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
	"(#(16r167280 16r19A670) includes: survivor) ifTrue: [self halt]."
	true ifTrue: [^super copyAndForward: survivor.].
	newLocation := super copyAndForward: survivor.
	comeFroms at: newLocation put: survivor.
	"((manager isContextNonImm: newLocation)
	 and: [#(16r11D6988 16r11D6A48 16r11D6AC0 16r11D6B80) includes: newLocation]) ifTrue:
		[self halt]."
	^newLocation
]

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
SpurGenerationScavengerSimulator >> scavenge [
	comeFroms := Dictionary new.
	^super scavenge
]
