Class {
	#name : #VMPinnedObjectTest,
	#superclass : #VMSpurInitializedOldSpaceTest,
	#category : #'VMMakerTests-MemoryTests'
}

{ #category : #helper }
VMPinnedObjectTest >> lastAliveObject [
	^ self keptObjectInVMVariable2
]

{ #category : #helper }
VMPinnedObjectTest >> lastPinnedObject [
	^ self keptObjectInVMVariable1
]

{ #category : #helper }
VMPinnedObjectTest >> newAliveObject [
	| newAliveObject |
	newAliveObject := self newOldSpaceObjectWithSlots: 1.
	memory storePointer: 0 ofObject: newAliveObject withValue: self keptObjectInVMVariable2.
	self keepObjectInVMVariable2: newAliveObject.
	^ newAliveObject
]

{ #category : #helper }
VMPinnedObjectTest >> newDeadObject [
	^ self newOldSpaceObjectWithSlots: 1
]

{ #category : #helper }
VMPinnedObjectTest >> newKeptPinnedObject [
	| newPinned |
	newPinned := self newOldSpaceObjectWithSlots: 1.
	memory pinObject: newPinned.
	memory storePointer: 0 ofObject: newPinned withValue: self keptObjectInVMVariable1.
	self keepObjectInVMVariable1: newPinned.
	^ newPinned
]

{ #category : #tests }
VMPinnedObjectTest >> setUp [
	super setUp.
	self setUpScheduler.
]

{ #category : #testCompactor }
VMPinnedObjectTest >> testAllocatingObjectAfterAPinObjectShouldSlideAtStartOfOldSpace [
	| aliveObject destination shouldBeFreed |
	"D = Dead
	P = Pinned
	A = Alive
	F = Free
	scenario : 
	before : D D P D A -
	after : A F P -"
	memory fullGC.

	destination := self newDeadObject. 
	shouldBeFreed := self newDeadObject.
	self newKeptPinnedObject.
	self newDeadObject.
	aliveObject := self newAliveObject.
	
	memory fullGC.
	
	self assert: (memory isForwarded: aliveObject).
	self assert: self lastAliveObject equals: destination.
	self assert: (memory isFreeObject: shouldBeFreed)
]

{ #category : #testCompactor }
VMPinnedObjectTest >> testAllocatingObjectAfterAPinObjectShouldSlideBeforeLastPinnedObject [
	| aliveObject destination |
	"D = Dead
	P = Pinned
	A = Alive
	F = Free
	scenario : 
	before : D P D A -
	after : A P -
	"
	memory fullGC.
	
	destination := self newDeadObject.
	self newKeptPinnedObject.	
	self newDeadObject.	
	aliveObject := self newAliveObject.
	
	memory fullGC.
	
	self assert: (memory isForwarded: aliveObject).
	self assert: self lastAliveObject equals: destination.
]

{ #category : #testCompactor }
VMPinnedObjectTest >> testAllocatingObjectAfterManyPinnedObjectShouldSlideAtStartOfOldSpace [
	| aliveObject destination shouldBeFreed |
	"D = Dead
	P = Pinned
	A = Alive
	F = Free
	scenario : 
	before : D D P P D A -
	after : A F P P -"
	memory fullGC.
	
	destination := self newDeadObject. 
	shouldBeFreed := self newDeadObject.
	self newKeptPinnedObject.	
	self newKeptPinnedObject.	
	self newDeadObject.
	aliveObject := self newAliveObject.
	
	memory fullGC.
	
	self assert: (memory isForwarded: aliveObject).
	self assert: self lastAliveObject equals: destination.
	self assert: (memory isFreeObject: shouldBeFreed)
]

{ #category : #testCompactor }
VMPinnedObjectTest >> testAllocatingObjectAfterManyPinnedObjectShouldSlideBeforeFirstPinned [
	| aliveObject destination |
	"D = Dead
	P = Pinned
	A = Alive
	F = Free
	scenario : 
	before : D P P D A -
	after : A P P -"
	memory fullGC.
	
	destination := self newDeadObject.
	self newKeptPinnedObject.
	self newKeptPinnedObject.
	self newDeadObject.
	aliveObject := self newAliveObject.
	
	memory fullGC.
	
	self assert: (memory isForwarded: aliveObject).
	self assert: self lastAliveObject equals: destination.
]

{ #category : #testCompactor }
VMPinnedObjectTest >> testAllocatingObjectAfterThreePinObjectShouldSlideAtStartOfOldSpace [
	| obj destination shouldBeFree |
	"D = Dead
	P = Pinned
	A = Alive
	F = Free
	scenario : 
	before : D P A-
	after : A P -"

	"an alive object doesn't seem to move when it's right after a pinned one"	
	self error.
]

{ #category : #testCompactor }
VMPinnedObjectTest >> testAllocatingObjectAfterTwoPinObjectShouldSlideAtStartOfOldSpace [
	| aliveObject destination shouldBeFreed |
	"D = Dead
	P = Pinned
	A = Alive
	F = Free
	scenario : 
	before : D P D P D A -
	after : A P F P -"
	memory fullGC.

	destination := self newDeadObject .
	self newKeptPinnedObject.
	shouldBeFreed := self newDeadObject.
	self newKeptPinnedObject.
	self newDeadObject.
	aliveObject := self newAliveObject.
	
	memory fullGC.
	
	self assert: (memory isForwarded: aliveObject).
	self assert: self lastAliveObject equals: destination.
	self assert: (memory isFreeObject: shouldBeFreed)
]

{ #category : #tests }
VMPinnedObjectTest >> testPinANewObjectShouldMoveItToTheOldSpace [
	"if we follow the forwarder, the object is in the old space"
	| obj |
	obj := self newObjectWithSlots: 0.
	self keepObjectInVMVariable1: obj.
	memory pinObject: obj.
	
	self assert: (memory isInOldSpace: (memory followForwarded: obj))
]

{ #category : #tests }
VMPinnedObjectTest >> testPinANewObjectShouldMoveItToTheOldSpaceAndLeaveAForwarderBehind [
	| obj |
	obj := self newObjectWithSlots: 0.
	self keepObjectInVMVariable1: obj.
	memory pinObject: obj.
	
	self assert: (memory isForwarded: obj)
]

{ #category : #tests }
VMPinnedObjectTest >> testPinnedObjectShouldNotBeMovedByGC [
	| pinned |
	self newOldSpaceObjectWithSlots: 0. "deadObject, that differenciate the start of the old space to the pin"	

	pinned := self newObjectWithSlots: 0.
	memory pinObject: pinned.
	self keepObjectInVMVariable1: (memory followForwarded: pinned).
	
	memory fullGC.
	
	self assert: (memory isForwarded: self keptObjectInVMVariable1) not.
]
