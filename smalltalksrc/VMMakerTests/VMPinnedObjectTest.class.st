Class {
	#name : #VMPinnedObjectTest,
	#superclass : #VMSpurInitializedOldSpaceTest,
	#category : #'VMMakerTests-MemoryTests'
}

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
	| pinned obj destination |
	"D = Dead
	P = Pinned
	A Alive
	scenario : 
	before : D D P D A -
	after : A D P -"
	memory fullGC.

	"first dead object, to differenciate the start of the old space with the pinned object"
	destination := self newOldSpaceObjectWithSlots: 0. 
	self newOldSpaceObjectWithSlots: 0 "second dead".
	pinned := self newOldSpaceObjectWithSlots: 0.
	memory pinObject: pinned.
	self keepObjectInVMVariable1: pinned.
	
	self newOldSpaceObjectWithSlots: 0.
	
	obj := self newOldSpaceObjectWithSlots: 0.
	self keepObjectInVMVariable2: obj.
	
	memory fullGC.
	
	self assert: (memory isForwarded: obj).
	self assert: self keptObjectInVMVariable2 equals: destination.
]

{ #category : #testCompactor }
VMPinnedObjectTest >> testAllocatingObjectAfterAPinObjectShouldSlideBeforeLastPinnedObject [
	| pinned obj destination |
	"D = Dead
	P = Pinned
	A Alive
	scenario : 
	before : D P D A -
	after : A P -
	"
	memory fullGC.
	
	destination := self newOldSpaceObjectWithSlots: 0. "first dead object, to differenciate the start of the old space with the pinned object"
	
	pinned := self newOldSpaceObjectWithSlots: 0.
	memory pinObject: pinned.
	self keepObjectInVMVariable1: pinned.
	
	self newOldSpaceObjectWithSlots: 0. "second dead object"
	
	obj := self newOldSpaceObjectWithSlots: 0.
	self keepObjectInVMVariable2: obj.
	
	memory fullGC.
	
	self assert: (memory isForwarded: obj).
	self assert: self keptObjectInVMVariable2 equals: destination.
]

{ #category : #testCompactor }
VMPinnedObjectTest >> testAllocatingObjectAfterManyPinnedObjectShouldSlideAtStartOfOldSpace [
	| pinned obj destination newPinned |
	"D = Dead
	P = Pinned
	A Alive
	scenario : 
	before : D D P P D A -
	after : A D P P -"
	memory fullGC.

	"first dead object, to differenciate the start of the old space with the pinned object"
	destination := self newOldSpaceObjectWithSlots: 0. 
	self newOldSpaceObjectWithSlots: 0 "second dead".
	
	"first pinned"
	pinned := self newOldSpaceObjectWithSlots: 1.
	memory pinObject: pinned.
	self keepObjectInVMVariable1: pinned.
	
	"second pinned"
	newPinned :=self newOldSpaceObjectWithSlots: 1.
	memory pinObject: newPinned.
	memory storePointer: 0 ofObject: pinned withValue: newPinned.
	
	"third dead"
	self newOldSpaceObjectWithSlots: 0.
	
	obj := self newOldSpaceObjectWithSlots: 0.
	self keepObjectInVMVariable2: obj.
	
	memory fullGC.
	
	self assert: (memory isForwarded: obj).
	self assert: self keptObjectInVMVariable2 equals: destination.
]

{ #category : #testCompactor }
VMPinnedObjectTest >> testAllocatingObjectAfterManyPinnedObjectShouldSlideBeforeFirstPinned [
	| pinned obj destination newPinned |
	"D = Dead
	P = Pinned
	A Alive
	scenario : 
	before : D P P D A -
	after : A P P -"
	memory fullGC.

	"first dead object, to differenciate the start of the old space with the pinned object"
	destination := self newOldSpaceObjectWithSlots: 0.
	
	"first pinned"
	pinned := self newOldSpaceObjectWithSlots: 1.
	memory pinObject: pinned.
	self keepObjectInVMVariable1: pinned.
	
	"second pinned"
	newPinned :=self newOldSpaceObjectWithSlots: 1.
	memory pinObject: newPinned.
	memory storePointer: 0 ofObject: pinned withValue: newPinned.
	
	"third dead"
	self newOldSpaceObjectWithSlots: 0.
	
	obj := self newOldSpaceObjectWithSlots: 0.
	self keepObjectInVMVariable2: obj.
	
	memory fullGC.
	
	self assert: (memory isForwarded: obj).
	self assert: self keptObjectInVMVariable2 equals: destination.
]

{ #category : #testCompactor }
VMPinnedObjectTest >> testAllocatingObjectAfterThreePinObjectShouldSlideAtStartOfOldSpace [
	| obj destination shouldBeFree |
	"D = Dead
	P = Pinned
	A Alive
	scenario : 
	before : D P A-
	after : A P -"

	"an alive object doesn't seem to move when it's right after a pinned one"	
	self error.
]

{ #category : #testCompactor }
VMPinnedObjectTest >> testAllocatingObjectAfterTwoPinObjectShouldSlideAtStartOfOldSpace [
	| pinned obj destination shouldBeFree newPinned |
	"D = Dead
	P = Pinned
	A Alive
	scenario : 
	before : D P D P D A -
	after : A P F P -"
	memory fullGC.

	"first dead object, to differenciate the start of the old space with the pinned object"
	destination := self newOldSpaceObjectWithSlots: 0.
	
	"first pinned"
	pinned := self newOldSpaceObjectWithSlots: 1.
	memory pinObject: pinned.
	self keepObjectInVMVariable1: pinned.
	
	"second dead , between pinned"
	shouldBeFree := self newOldSpaceObjectWithSlots: 0.
	
	"second pinned"
	newPinned := self newOldSpaceObjectWithSlots: 1.
	memory pinObject: newPinned.
	memory storePointer: 0 ofObject: pinned withValue: newPinned.
	
	self newOldSpaceObjectWithSlots: 0.
	
	"alive !"
	obj := self newOldSpaceObjectWithSlots: 0.
	self keepObjectInVMVariable2: obj.
	
	memory fullGC.
	
	self assert: (memory isForwarded: obj).
	self assert: self keptObjectInVMVariable2 equals: destination.
	self assert: (memory isFreeObject: shouldBeFree)
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
