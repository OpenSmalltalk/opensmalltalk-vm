Class {
	#name : #VMSpurInitializedOldSpaceTest,
	#superclass : #VMSpurMemoryManagerTest,
	#category : #VMMakerTests
}

{ #category : #testing }
VMSpurInitializedOldSpaceTest class >> isAbstract [

	^ self == VMSpurInitializedOldSpaceTest
]

{ #category : #helpers }
VMSpurInitializedOldSpaceTest >> initializeOldSpaceForScavenger [

	memory coInterpreter bootstrapping: true.

	"Create a nil object required to initialize several fields"
	memory nilObject: self newZeroSizedObject.

	"Initialize Stack"
	memory coInterpreter desiredNumStackPages: 8.
	memory coInterpreter initStackPages.

	"Initialize Special Root objects"
	memory coInterpreter method: memory nilObject.
	memory coInterpreter instructionPointer: memory nilObject.
	memory coInterpreter newMethod: memory nilObject.
	memory coInterpreter profileProcess: memory nilObject.
	memory coInterpreter profileMethod: memory nilObject.
	memory coInterpreter profileSemaphore: memory nilObject.
	memory mournQueue: memory nilObject.
	memory specialObjectsOop: memory nilObject.
	
	"Initialize old space with free list, class table, hidden roots and remembered set to be able to scavenge"
	memory initializeFreeList.
	memory segmentManager collapseSegmentsPostSwizzle.
	memory updateFreeLists.
	memory computeFreeSpacePostSwizzle.
	memory initializeOldSpaceFirstFree: memory freeOldSpaceStart.
	memory allocateClassTable.	
	memory scavenger initializeRememberedSet.
	memory specialObjectsOop: (self newObjectWithSlots: 20).
	
	"Force moving the special objects array to old space..."
	memory flushNewSpace.
	
	"Initialize Special Root objects"
	memory nilObject: (memory remapObj: memory nilObject).
	memory coInterpreter method: memory nilObject.
	memory coInterpreter instructionPointer: memory nilObject.
	memory coInterpreter newMethod: memory nilObject.
	memory coInterpreter profileProcess: memory nilObject.
	memory coInterpreter profileMethod: memory nilObject.
	memory coInterpreter profileSemaphore: memory nilObject.
	memory mournQueue: memory nilObject.
]

{ #category : #running }
VMSpurInitializedOldSpaceTest >> setUp [

	super setUp.
	self initializeOldSpaceForScavenger.
	memory lastHash: 1.
]
