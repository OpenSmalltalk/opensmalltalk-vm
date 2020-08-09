Class {
	#name : #VMSpurOldSpaceBootstrapTest,
	#superclass : #VMSpurMemoryManagerTest,
	#category : #'VMMakerTests-MemoryTests'
}

{ #category : #'tests-memory-bootstrap' }
VMSpurOldSpaceBootstrapTest >> testClassTableHasTablePagesAndHiddenRoots [

	| tableRoot |
	
	memory coInterpreter desiredNumStackPages: 8.
	memory coInterpreter initStackPages.
	memory coInterpreter bootstrapping: true.
	memory nilObject: self newZeroSizedObject.

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


	tableRoot := memory allocateClassTable.
	
	self
		assert: (memory numSlotsOf: tableRoot)
		equals: memory classTableRootSlots + memory hiddenRootSlots
]

{ #category : #'tests-memory-bootstrap' }
VMSpurOldSpaceBootstrapTest >> testFreeListHasAsManySlotsAsRequiredByTheVM [

	| freeListOop |
	freeListOop := memory initializeFreeList.

	self assert: (memory numSlotsOf: freeListOop) equals: memory numFreeLists
]

{ #category : #'tests-memory-bootstrap' }
VMSpurOldSpaceBootstrapTest >> testFreeListIsWordIndexable [

	| freeListOop |
	freeListOop := memory initializeFreeList.

	self assert: (memory formatOf: freeListOop) equals: memory wordIndexableFormat
]

{ #category : #'tests-memory-bootstrap' }
VMSpurOldSpaceBootstrapTest >> testNewFreeListHasAllSlotsInitializedInZero [

	| freeListOop |
	freeListOop := memory initializeFreeList.

	0 to: memory numFreeLists - 1 do: [ :i |
		self assert: (memory fetchPointer: i ofObject: freeListOop) equals: 0 ]
]

{ #category : #'tests-memory-bootstrap' }
VMSpurOldSpaceBootstrapTest >> testNewFreeListIsValid [

	memory initializeFreeList.
	memory validFreeTree
]

{ #category : #'tests-memory-bootstrap' }
VMSpurOldSpaceBootstrapTest >> testNewFreeListIsValid2 [

	memory initializeFreeList.
	memory totalFreeListBytes
]
