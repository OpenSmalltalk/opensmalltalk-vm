Class {
	#name : #VMSpurMemoryManagerTest,
	#superclass : #TestCase,
	#instVars : [
		'newSpaceSize',
		'stackSize',
		'memory',
		'oldSpaceSize',
		'nextIndex',
		'objectHeaderSize',
		'zeroSizedObjectClassIndex',
		'emptyObjectSize'
	],
	#category : #VMMakerTests
}

{ #category : #helpers }
VMSpurMemoryManagerTest >> newObjectWithSlots: slots [
	
	^ self newObjectWithSlots: slots classIndex: memory arrayClassIndexPun
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newObjectWithSlots: slots classIndex: anIndex [
	
	| oop |
	oop := memory
			allocateSlots: slots
			format: memory arrayFormat
			classIndex: anIndex.
	memory nilFieldsOf: oop.
	^ oop
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> newZeroSizedObject [
	
	^ memory
		allocateNewSpaceSlots: 0
		format: 0 "zero sized object"
		classIndex: self zeroSizedObjectClassIndex.
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> nextOrdinaryClassIndex [
	
	^ nextIndex
		ifNil: [ nextIndex := memory classTablePageSize ]
		ifNotNil: [ nextIndex := nextIndex + 1 ]
]

{ #category : #running }
VMSpurMemoryManagerTest >> setUp [
	
	| interpreter |
	super setUp.

	"100 k at least to put the class table in the old space"
	oldSpaceSize := 100 * 1024.
 	newSpaceSize := 1 * 1024.
	stackSize := 16 * 1024.
	
	objectHeaderSize := 8 "bytes".
	emptyObjectSize := objectHeaderSize + 8 "minimum required single empty slot, to use for forwarders".
	
	"Set it to bootstrapping to allow smaller memories"
	interpreter := StackInterpreterSimulator newWithOptions: {#BytesPerWord . 8}.
	memory := Spur64BitMMLESimulator new.
	
	memory coInterpreter: interpreter.
	interpreter objectMemory: memory.
	
	memory
		allocateMemoryOfSize: oldSpaceSize
		newSpaceSize: newSpaceSize
		stackSize: stackSize
		codeSize: 0.
	memory initializePostBootstrap.
	memory setHeapSizeAtPreviousGC.
	
	"Schedule a GC, so it does not try to schedule one"
	memory needGCFlag: 1.
]

{ #category : #accessing }
VMSpurMemoryManagerTest >> sizeOfObjectWithSlots: slots [

	^ objectHeaderSize + ((slots min: 1 "at least one for the forwarder pointer") * memory wordSize "bytes")
]

{ #category : #'tests-memory-bootstrap' }
VMSpurMemoryManagerTest >> testClassTableHasTablePagesAndHiddenRoots [

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
VMSpurMemoryManagerTest >> testFreeListHasAsManySlotsAsRequiredByTheVM [

	| freeListOop |
	freeListOop := memory initializeFreeList.

	self assert: (memory numSlotsOf: freeListOop) equals: memory numFreeLists
]

{ #category : #'tests-memory-bootstrap' }
VMSpurMemoryManagerTest >> testFreeListIsWordIndexable [

	| freeListOop |
	freeListOop := memory initializeFreeList.

	self assert: (memory formatOf: freeListOop) equals: memory wordIndexableFormat
]

{ #category : #'tests-memory-bootstrap' }
VMSpurMemoryManagerTest >> testNewFreeListHasAllSlotsInitializedInZero [

	| freeListOop |
	freeListOop := memory initializeFreeList.

	0 to: memory numFreeLists - 1 do: [ :i |
		self assert: (memory fetchPointer: i ofObject: freeListOop) equals: 0 ]
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> zeroSizedObjectClassIndex [

	^ zeroSizedObjectClassIndex ifNil: [ self nextOrdinaryClassIndex ]
]
