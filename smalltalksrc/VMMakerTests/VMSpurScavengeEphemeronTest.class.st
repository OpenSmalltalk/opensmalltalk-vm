Class {
	#name : #VMSpurScavengeEphemeronTest,
	#superclass : #VMSpurInitializedOldSpaceTest,
	#instVars : [
		'ourEphemeronClass'
	],
	#category : #VMMakerTests
}

{ #category : #'as yet unclassified' }
VMSpurScavengeEphemeronTest >> createEphemeronClass [
	ourEphemeronClass := self newObjectWithSlots: 3.
	memory
		storePointer: "InstanceSpecificationIndex" 2
		ofObject: ourEphemeronClass
		withValue: (memory integerObjectOf: Ephemeron format).
	memory ensureBehaviorHash: ourEphemeronClass.
]

{ #category : #'instance creation' }
VMSpurScavengeEphemeronTest >> newEphemeronObject [

"In pharo Ephemerons have 3 slots"
	
	^ self
		newObjectWithSlots: 3
		format: memory ephemeronFormat
		classIndex: (memory ensureBehaviorHash: ourEphemeronClass)
]

{ #category : #tests }
VMSpurScavengeEphemeronTest >> testDequeueMournerWithOnlyOneEphemeronShouldEmptyMournQueue [
	| ephemeronObjectOop nonEphemeronObjectOop |
	self createEphemeronClass.
	ephemeronObjectOop := self newEphemeronObject.
	nonEphemeronObjectOop := self newZeroSizedObject.
	memory
		storePointer: 0
		ofObject: ephemeronObjectOop
		withValue: nonEphemeronObjectOop.

	"Force object to not be collected by putting them in special variables"
	self keepObject1: ephemeronObjectOop.

	memory doScavenge: 1.	"TenureByAge"
	ephemeronObjectOop := memory remapObj: ephemeronObjectOop.
	memory dequeueMourner.
	self assert: (memory popObjStack: memory mournQueue) equals: nil
	
]

{ #category : #tests }
VMSpurScavengeEphemeronTest >> testNewEphemeronObjectShouldBeInstanceOfEphemeronClass [

	| ephemeronObjectOop |
	self createEphemeronClass.
	ephemeronObjectOop := self newEphemeronObject.

	self assert: (memory fetchClassOfNonImm: ephemeronObjectOop) equals: ourEphemeronClass
]

{ #category : #tests }
VMSpurScavengeEphemeronTest >> testScavengeEphemeronObjectBecomesNormalObjectAfterFinalizationIsFired [
	| ephemeronObjectOop nonEphemeronObjectOop |
	self createEphemeronClass.
	ephemeronObjectOop := self newEphemeronObject.
	nonEphemeronObjectOop := self newZeroSizedObject.
	memory
		storePointer: 0
		ofObject: ephemeronObjectOop
		withValue: nonEphemeronObjectOop.

	"Force object to not be collected by putting them in special variables"
	self keepObject1: ephemeronObjectOop.
	
	memory doScavenge: 1.	"TenureByAge"
	ephemeronObjectOop := memory remapObj: ephemeronObjectOop.
	self
		assert:
			(memory
				formatOf: ephemeronObjectOop)
		equals: memory nonIndexablePointerFormat
]

{ #category : #tests }
VMSpurScavengeEphemeronTest >> testScavengeEphemeronObjectReferencingDyingObjectShouldBeAddedInTheMournQueue [
	| ephemeronObjectOop nonEphemeronObjectOop  |
	self createEphemeronClass.
	ephemeronObjectOop := self newEphemeronObject.
	nonEphemeronObjectOop := self newZeroSizedObject.
	memory
		storePointer: 0
		ofObject: ephemeronObjectOop
		withValue: nonEphemeronObjectOop.

	"Force object to not be collected by putting them in special variables"
	self keepObject1: ephemeronObjectOop.

	memory doScavenge: 1.	"TenureByAge"
	ephemeronObjectOop := memory remapObj: ephemeronObjectOop.
	self
		assert: memory dequeueMourner
		equals: ephemeronObjectOop
]

{ #category : #tests }
VMSpurScavengeEphemeronTest >> testScavengeEphemeronObjectReferencingDyingObjectShouldFireFinalization [
	| ephemeronObjectOop nonEphemeronObjectOop  oldFinalization |
	self createEphemeronClass.
	ephemeronObjectOop := self newEphemeronObject.
	nonEphemeronObjectOop := self newZeroSizedObject.
	oldFinalization := memory coInterpreter pendingFinalizationSignals.
	memory
		storePointer: 0
		ofObject: ephemeronObjectOop
		withValue: nonEphemeronObjectOop.

	"Force object to not be collected by putting them in special variables"
	self keepObject1: ephemeronObjectOop.

	memory doScavenge: 1.	"TenureByAge"
	ephemeronObjectOop := memory remapObj: ephemeronObjectOop.
	self
		assert: memory coInterpreter pendingFinalizationSignals
		equals: oldFinalization + 1
]

{ #category : #tests }
VMSpurScavengeEphemeronTest >> testScavengeEphemeronObjectReferencingDyingObjectShouldScavengeEphemeronKey [
	| ephemeronObjectOop nonEphemeronObjectOop  nonEphemeronObjectHash |
	self createEphemeronClass.
	ephemeronObjectOop := self newEphemeronObject.
	nonEphemeronObjectOop := self newZeroSizedObject.
	nonEphemeronObjectHash := memory hashBitsOf: nonEphemeronObjectOop.
	memory
		storePointer: 0
		ofObject: ephemeronObjectOop
		withValue: nonEphemeronObjectOop.

	"Force object to not be collected by putting them in special variables"
	self keepObject1: ephemeronObjectOop.

	memory doScavenge: 1.	"TenureByAge"
	nonEphemeronObjectOop := memory remapObj: nonEphemeronObjectOop.
	self
		assert: (memory hashBitsOf: nonEphemeronObjectOop)
		equals: nonEphemeronObjectHash
]

{ #category : #tests }
VMSpurScavengeEphemeronTest >> testScavengeEphemeronObjectReferencingSurvivorShouldLeaveEphemeronObjectAsIs [
	| ephemeronObjectOop nonEphemeronObjectOop nonEphemeronObjectHash |
	self createEphemeronClass.
	ephemeronObjectOop := self newEphemeronObject.
	nonEphemeronObjectOop := self newZeroSizedObject.
	nonEphemeronObjectHash := memory hashBitsOf: nonEphemeronObjectOop.
	memory
		storePointer: 0
		ofObject: ephemeronObjectOop
		withValue: nonEphemeronObjectOop.

	"Force object to not be collected by putting them in special variables"
	self keepObject1: ephemeronObjectOop.
	self keepObject2: nonEphemeronObjectOop.
	
	memory doScavenge: 1.	"TenureByAge"
	ephemeronObjectOop := memory remapObj: ephemeronObjectOop.
	self
		assert:
			(memory
				hashBitsOf: (memory fetchPointer: 0 ofObject: ephemeronObjectOop))
		equals: nonEphemeronObjectHash
]

{ #category : #tests }
VMSpurScavengeEphemeronTest >> testScavengeTwoEphemeronObjectsReferencingDifferentDyingObjectsShouldBeAddedInTheMournQueueAfterScavengingInEden [
	| ephemeronObjectOop nonEphemeronObjectOop  anotherEphemeronObjectOop anotherNonEphemeronObjectOop |
	self createEphemeronClass.
	ephemeronObjectOop := self newEphemeronObject.
	anotherEphemeronObjectOop := self newEphemeronObject.
	nonEphemeronObjectOop := self newZeroSizedObject.
	anotherNonEphemeronObjectOop := self newZeroSizedObject.
	memory
		storePointer: 0
		ofObject: ephemeronObjectOop
		withValue: nonEphemeronObjectOop.
		
	memory
		storePointer: 0
		ofObject: anotherEphemeronObjectOop
		withValue: anotherNonEphemeronObjectOop.

	"Force object to not be collected by putting them in special variables"
	self keepObject1: ephemeronObjectOop.
	self keepObject2: anotherEphemeronObjectOop.

	memory doScavenge: 1.	"TenureByAge"
	ephemeronObjectOop := memory remapObj: ephemeronObjectOop.
	anotherEphemeronObjectOop := memory remapObj: anotherEphemeronObjectOop.
	self
		assert: memory dequeueMourner
		equals: ephemeronObjectOop.

	self
		assert: memory dequeueMourner
		equals: anotherEphemeronObjectOop.
]

{ #category : #tests }
VMSpurScavengeEphemeronTest >> testScavengeTwoEphemeronObjectsReferencingDifferentDyingObjectsShouldBeAddedInTheMournQueueAfterScavengingInPastSpace [
	| ephemeronObjectOop nonEphemeronObjectOop  anotherEphemeronObjectOop anotherNonEphemeronObjectOop |
	self createEphemeronClass.
	ephemeronObjectOop := self newEphemeronObject.
	anotherEphemeronObjectOop := self newEphemeronObject.
	nonEphemeronObjectOop := self newZeroSizedObject.
	anotherNonEphemeronObjectOop := self newZeroSizedObject.
	memory
		storePointer: 0
		ofObject: ephemeronObjectOop
		withValue: nonEphemeronObjectOop.
		
	memory
		storePointer: 0
		ofObject: anotherEphemeronObjectOop
		withValue: anotherNonEphemeronObjectOop.

	"Force object to not be collected by putting them in special variables"
	self keepObject1: ephemeronObjectOop.
	self keepObject2: anotherEphemeronObjectOop.
	self keepObject3: anotherNonEphemeronObjectOop.

	"Scavence once so all three objects are moved from eden to past space"
	memory doScavenge: 1.	"TenureByAge"
	ephemeronObjectOop := memory remapObj: ephemeronObjectOop.
	anotherEphemeronObjectOop := memory remapObj: anotherEphemeronObjectOop.
	anotherNonEphemeronObjectOop := memory remapObj: anotherNonEphemeronObjectOop.
	
	self forgetObject3.
	memory doScavenge: 1.	"TenureByAge"
	ephemeronObjectOop := memory remapObj: ephemeronObjectOop.
	anotherEphemeronObjectOop := memory remapObj: anotherEphemeronObjectOop.

	self
		assert: memory dequeueMourner
		equals: anotherEphemeronObjectOop.

	self
		assert: memory dequeueMourner
		equals: ephemeronObjectOop.
]

{ #category : #tests }
VMSpurScavengeEphemeronTest >> testScavengeTwoEphemeronObjectsReferencingSameDyingObjectsShouldAddOnlyOneEphemeron [
	| ephemeronObjectOop nonEphemeronObjectOop  anotherEphemeronObjectOop |
	self createEphemeronClass.
	ephemeronObjectOop := self newEphemeronObject.
	anotherEphemeronObjectOop := self newEphemeronObject.
	nonEphemeronObjectOop := self newZeroSizedObject.

	memory
		storePointer: 0
		ofObject: ephemeronObjectOop
		withValue: nonEphemeronObjectOop.
		
	memory
		storePointer: 0
		ofObject: anotherEphemeronObjectOop
		withValue: nonEphemeronObjectOop.

	"Force object to not be collected by putting them in special variables"
	self keepObject1: ephemeronObjectOop.
	self keepObject2: anotherEphemeronObjectOop.

	memory doScavenge: 1.	"TenureByAge"
	ephemeronObjectOop := memory remapObj: ephemeronObjectOop.
	anotherEphemeronObjectOop := memory remapObj: anotherEphemeronObjectOop.

	"Consume the first mourner"
	memory dequeueMourner.
	self
		assert: memory dequeueMourner
		equals: nil
]

{ #category : #tests }
VMSpurScavengeEphemeronTest >> testScavengeTwoEphemeronObjectsReferencingSameDyingObjectsShouldAddOnlySecond [
	| ephemeronObjectOop nonEphemeronObjectOop  anotherEphemeronObjectOop |
	self createEphemeronClass.
	ephemeronObjectOop := self newEphemeronObject.
	anotherEphemeronObjectOop := self newEphemeronObject.
	nonEphemeronObjectOop := self newZeroSizedObject.

	memory
		storePointer: 0
		ofObject: ephemeronObjectOop
		withValue: nonEphemeronObjectOop.
		
	memory
		storePointer: 0
		ofObject: anotherEphemeronObjectOop
		withValue: nonEphemeronObjectOop.

	"Force object to not be collected by putting them in special variables"
	self keepObject1: ephemeronObjectOop.
	self keepObject2: anotherEphemeronObjectOop.

	memory doScavenge: 1.	"TenureByAge"
	ephemeronObjectOop := memory remapObj: ephemeronObjectOop.
	anotherEphemeronObjectOop := memory remapObj: anotherEphemeronObjectOop.

	self
		assert: memory dequeueMourner
		equals: anotherEphemeronObjectOop.
]

{ #category : #tests }
VMSpurScavengeEphemeronTest >> testScavengeTwoEphemeronObjectsReferencingSameDyingObjectsShouldBeQueuedAfterConsumingMournQueue [
	| ephemeronObjectOop nonEphemeronObjectOop  anotherEphemeronObjectOop |
	self createEphemeronClass.
	ephemeronObjectOop := self newEphemeronObject.
	anotherEphemeronObjectOop := self newEphemeronObject.
	nonEphemeronObjectOop := self newZeroSizedObject.

	memory
		storePointer: 0
		ofObject: ephemeronObjectOop
		withValue: nonEphemeronObjectOop.
		
	memory
		storePointer: 0
		ofObject: anotherEphemeronObjectOop
		withValue: nonEphemeronObjectOop.

	"Force object to not be collected by putting them in special variables"
	self keepObject1: ephemeronObjectOop.
	self keepObject2: anotherEphemeronObjectOop.

	memory doScavenge: 1.	"TenureByAge"
	ephemeronObjectOop := memory remapObj: ephemeronObjectOop.

	"The second ephemeron changed format, now it keeps the key strongly.
	Nil the ephemeron key to allow the next ephemeron to be finalized too"
	memory storePointer: 0 ofObject: memory dequeueMourner withValue: memory nilObject.
	
	memory doScavenge: 1.	"TenureByAge"
	ephemeronObjectOop := memory remapObj: ephemeronObjectOop.

	self
		assert: memory dequeueMourner
		equals: ephemeronObjectOop
]

{ #category : #tests }
VMSpurScavengeEphemeronTest >> testScavengeTwoEphemeronObjectsReferencingSameDyingObjectsShouldLeaveFirstOneAsEphemeron [
	| ephemeronObjectOop nonEphemeronObjectOop  anotherEphemeronObjectOop |
	self createEphemeronClass.
	ephemeronObjectOop := self newEphemeronObject.
	anotherEphemeronObjectOop := self newEphemeronObject.
	nonEphemeronObjectOop := self newZeroSizedObject.

	memory
		storePointer: 0
		ofObject: ephemeronObjectOop
		withValue: nonEphemeronObjectOop.
		
	memory
		storePointer: 0
		ofObject: anotherEphemeronObjectOop
		withValue: nonEphemeronObjectOop.

	"Force object to not be collected by putting them in special variables"
	self keepObject1: ephemeronObjectOop.
	self keepObject2: anotherEphemeronObjectOop.

	memory doScavenge: 1.	"TenureByAge"
	ephemeronObjectOop := memory remapObj: ephemeronObjectOop.
	anotherEphemeronObjectOop := memory remapObj: anotherEphemeronObjectOop.

	self assert: (memory isEphemeron: ephemeronObjectOop)
]

{ #category : #tests }
VMSpurScavengeEphemeronTest >> testScavengeTwoEphemeronObjectsReferencingSameDyingObjectsShouldScavengeKeyOfSecond [
	| ephemeronObjectOop nonEphemeronObjectOop  anotherEphemeronObjectOop |
	self createEphemeronClass.
	ephemeronObjectOop := self newEphemeronObject.
	anotherEphemeronObjectOop := self newEphemeronObject.
	nonEphemeronObjectOop := self newZeroSizedObject.

	memory
		storePointer: 0
		ofObject: ephemeronObjectOop
		withValue: nonEphemeronObjectOop.
		
	memory
		storePointer: 0
		ofObject: anotherEphemeronObjectOop
		withValue: nonEphemeronObjectOop.

	"Force object to not be collected by putting them in special variables"
	self keepObject1: ephemeronObjectOop.
	self keepObject2: anotherEphemeronObjectOop.

	memory doScavenge: 1.	"TenureByAge"
	ephemeronObjectOop := memory remapObj: ephemeronObjectOop.
	anotherEphemeronObjectOop := memory remapObj: anotherEphemeronObjectOop.

	self
		assert: (memory
			fetchPointer: 0
			ofObject: ephemeronObjectOop)
		equals: (memory remapObj: nonEphemeronObjectOop)
]
