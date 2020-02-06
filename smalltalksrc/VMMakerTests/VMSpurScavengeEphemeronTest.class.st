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
