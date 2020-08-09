Class {
	#name : #VMSpurScavengeWeakTest,
	#superclass : #VMSpurInitializedOldSpaceTest,
	#instVars : [
		'ourWeakClass'
	],
	#category : #'VMMakerTests-MemoryTests'
}

{ #category : #tests }
VMSpurScavengeWeakTest >> createWeakArrayClass [
	ourWeakClass := self newObjectWithSlots: 3.
	memory
		storePointer: "InstanceSpecificationIndex" 2
		ofObject: ourWeakClass
		withValue: (memory integerObjectOf: WeakArray format).
	memory ensureBehaviorHash: ourWeakClass.
	
]

{ #category : #tests }
VMSpurScavengeWeakTest >> newWeakObjectOfSize: aSize [
	
	^ self
		newObjectWithSlots: aSize
		format: memory weakArrayFormat
		classIndex: (memory ensureBehaviorHash: ourWeakClass)
]

{ #category : #'test-format' }
VMSpurScavengeWeakTest >> testNewWeakObjectShouldBeInstanceOfWeakClass [

	| weakObjectOop |
	self createWeakArrayClass.
	weakObjectOop := self newWeakObjectOfSize: 1.

	self assert: (memory fetchClassOfNonImm: weakObjectOop) equals: ourWeakClass
]

{ #category : #'test-format' }
VMSpurScavengeWeakTest >> testNewWeakObjectShouldHaveClassIndexOfItsClass [

	| weakObjectOop classIndex |
	self createWeakArrayClass.
	weakObjectOop := self newWeakObjectOfSize: 1.

	classIndex := memory classIndexOf: weakObjectOop.
	
	self assert: classIndex equals: (memory ensureBehaviorHash: ourWeakClass)
]

{ #category : #tests }
VMSpurScavengeWeakTest >> testScavengeOldWeakObjectReferencingNewSurvivorShouldNotFireFinalization [

	| weakObjectOop nonWeakObjectOop nonWeakObjectHash |
	self createWeakArrayClass.
	weakObjectOop := self newWeakObjectOfSize: 1.

	"Force object to not be collected by putting them in special variables"
	memory coInterpreter newMethod: weakObjectOop.
	
	memory flushNewSpace.
	weakObjectOop := memory remapObj: weakObjectOop.
	ourWeakClass := (memory remapObj: ourWeakClass).
	nonWeakObjectOop := self newZeroSizedObject.
	nonWeakObjectHash := memory hashBitsOf: nonWeakObjectOop.
	memory storePointer: 0 ofObject: weakObjectOop withValue: nonWeakObjectOop.
	
	"Force object to not be collected by putting them in special variables"
	memory coInterpreter profileSemaphore: nonWeakObjectOop.

	memory doScavenge: 1 "TenureByAge".	
	
	self
		assert: memory coInterpreter pendingFinalizationSignals
		equals: 0
]

{ #category : #tests }
VMSpurScavengeWeakTest >> testScavengeOldWeakObjectReferencingNonSurvivorShouldBeNilled [

	| weakObjectOop nonWeakObjectOop nonWeakObjectHash nilHash |
	self createWeakArrayClass.
	weakObjectOop := self newWeakObjectOfSize: 1.

	"Force object to not be collected by putting them in special variables"
	memory coInterpreter newMethod: weakObjectOop.
	memory flushNewSpace.
	weakObjectOop := memory remapObj: weakObjectOop.

	nonWeakObjectOop := self newZeroSizedObject.
	nonWeakObjectHash := memory hashBitsOf: nonWeakObjectOop.
	memory storePointer: 0 ofObject: weakObjectOop withValue: nonWeakObjectOop.
	
	nilHash := memory hashBitsOf: memory nilObject.
	memory doScavenge: 1 "TenureByAge".	
	
	self
		assert: (memory hashBitsOf: (memory fetchPointer: 0 ofObject: weakObjectOop))
		equals: nilHash
]

{ #category : #tests }
VMSpurScavengeWeakTest >> testScavengeOldWeakObjectReferencingNonSurvivorShouldFireFinalization [

	| weakObjectOop nonWeakObjectOop nonWeakObjectHash |
	self createWeakArrayClass.
	weakObjectOop := self newWeakObjectOfSize: 1.

	"Force object to not be collected by putting them in special variables"
	memory coInterpreter newMethod: weakObjectOop.
	
	memory flushNewSpace.
	weakObjectOop := memory remapObj: weakObjectOop.
	ourWeakClass := (memory remapObj: ourWeakClass).

	nonWeakObjectOop := self newZeroSizedObject.
	nonWeakObjectHash := memory hashBitsOf: nonWeakObjectOop.
	memory storePointer: 0 ofObject: weakObjectOop withValue: nonWeakObjectOop.
	
	memory doScavenge: 1 "TenureByAge".	
	
	self
		assert: memory coInterpreter pendingFinalizationSignals
		equals: 1
]

{ #category : #tests }
VMSpurScavengeWeakTest >> testScavengeWeakObjectReferencingNonSurvivorShouldBeNilled [

	| weakObjectOop nonWeakObjectOop nilHash |
	self createWeakArrayClass.
	weakObjectOop := self newWeakObjectOfSize: 1.
	nonWeakObjectOop := self newZeroSizedObject.
	memory storePointer: 0 ofObject: weakObjectOop withValue: nonWeakObjectOop.
	
	"Force object to not be collected by putting them in special variables"
	memory coInterpreter newMethod: weakObjectOop.
	nilHash := memory hashBitsOf: memory nilObject.
	memory doScavenge: 1 "TenureByAge".
	weakObjectOop := memory remapObj: weakObjectOop.	
	
	self
		assert: (memory hashBitsOf: (memory fetchPointer: 0 ofObject: weakObjectOop))
		equals: nilHash
]

{ #category : #tests }
VMSpurScavengeWeakTest >> testScavengeWeakObjectReferencingNonSurvivorShouldFireFinalisation [

	| weakObjectOop nonWeakObjectOop |
	self createWeakArrayClass.
	weakObjectOop := self newWeakObjectOfSize: 1.
	nonWeakObjectOop := self newZeroSizedObject.
	memory storePointer: 0 ofObject: weakObjectOop withValue: nonWeakObjectOop.
	
	"Force object to not be collected by putting them in special variables"
	memory coInterpreter newMethod: weakObjectOop.
	memory doScavenge: 1 "TenureByAge".
		
	self
		assert: memory coInterpreter pendingFinalizationSignals
		equals: 1
]

{ #category : #tests }
VMSpurScavengeWeakTest >> testScavengeWeakObjectReferencingSurvivorShouldLeaveWeakObjectAsIs [

	| weakObjectOop nonWeakObjectOop nonWeakObjectHash |
	self createWeakArrayClass.
	weakObjectOop := self newWeakObjectOfSize: 1.
	nonWeakObjectOop := self newZeroSizedObject.
	nonWeakObjectHash := memory hashBitsOf: nonWeakObjectOop.
	memory storePointer: 0 ofObject: weakObjectOop withValue: nonWeakObjectOop.
	
	"Force object to not be collected by putting them in special variables"
	memory coInterpreter newMethod: weakObjectOop.
	memory coInterpreter profileSemaphore: nonWeakObjectOop.

	memory doScavenge: 1 "TenureByAge".
	weakObjectOop := memory remapObj: weakObjectOop.	
	
	self
		assert: (memory hashBitsOf: (memory fetchPointer: 0 ofObject: weakObjectOop))
		equals: nonWeakObjectHash
]

{ #category : #tests }
VMSpurScavengeWeakTest >> testScavengeWeakObjectReferencingSurvivorShouldNotFireFinalization [

	| weakObjectOop nonWeakObjectOop nonWeakObjectHash |
	self createWeakArrayClass.
	weakObjectOop := self newWeakObjectOfSize: 1.
	nonWeakObjectOop := self newZeroSizedObject.
	nonWeakObjectHash := memory hashBitsOf: nonWeakObjectOop.
	memory storePointer: 0 ofObject: weakObjectOop withValue: nonWeakObjectOop.
	
	"Force object to not be collected by putting them in special variables"
	memory coInterpreter newMethod: weakObjectOop.
	memory coInterpreter profileSemaphore: nonWeakObjectOop.

	memory doScavenge: 1 "TenureByAge".
	weakObjectOop := memory remapObj: weakObjectOop.	
	
	self
		assert: memory coInterpreter pendingFinalizationSignals
		equals: 0
]
