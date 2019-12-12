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
		'zeroSizedObjectClassIndex'
	],
	#category : #VMMakerTests
}

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
	
	objectHeaderSize := 8.
	
	"Set it to bootstrapping to allow smaller memories"
	interpreter := StackInterpreterSimulator new.
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

{ #category : #'tests-instantiation' }
VMSpurMemoryManagerTest >> testInstantiateNewObjectMovesFreeStartAfterObject [
	
	| freeStartBefore classIndex |
	freeStartBefore := memory freeStart.
	
	classIndex := self nextOrdinaryClassIndex.
	memory
		allocateNewSpaceSlots: 0
		format: 0 "zero sized object"
		classIndex: classIndex.
	
	"New zero sized object has 64bit header + 1 * 64bit empty slot = 16bytes"
	self assert: memory freeStart equals: freeStartBefore + 16
]

{ #category : #'tests-memory-bootstrap' }
VMSpurMemoryManagerTest >> testNewFreeListHasAllSlotsInitializedInZero [

	| freeListOop |
	freeListOop := memory initializeFreeList.

	0 to: memory numFreeLists - 1 do: [ :i |
		self assert: (memory fetchPointer: i ofObject: freeListOop) equals: 0 ]
]

{ #category : #'test-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryEdenIsRestOfNewSpace [
	
	self
		assert: memory scavenger eden size
		equals: newSpaceSize - memory scavenger pastSpace size - memory scavenger futureSpace size
]

{ #category : #'test-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryFreeStartIsEdenStart [
	
	self assert: memory freeStart equals: memory scavenger eden start
]

{ #category : #'test-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryFutureSpaceEndIsAtTheStartOfEden [

	self assert: memory scavenger futureSpace limit equals: memory scavenger eden start
]

{ #category : #'test-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryFutureSpaceIsRoughlyOneSeventhOfNewSpace [
	
	self assert: memory scavenger pastSpaceBytes equals: (newSpaceSize // 7 truncateTo: memory allocationUnit)
]

{ #category : #'test-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryFutureSurvivorSpaceIsAtFutureSpaceStart [
	
	self assert: memory scavenger futureSurvivorStart equals: memory scavenger futureSpace start
]

{ #category : #'test-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryLimitIsSumOfSpaces [
	
	self assert: memory memoryLimit equals: oldSpaceSize + newSpaceSize + stackSize
]

{ #category : #'test-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryNewSpaceLimitIsNewSpaceStartPlusSize [
	
	self assert: memory newSpaceLimit equals: newSpaceSize + stackSize
]

{ #category : #'test-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryNewSpaceStartIsStackSize [

	self assert: memory newSpaceStart equals: stackSize
]

{ #category : #'test-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryPastSpaceEndIsAtTheStartOfFutureSpace [

	self assert: memory scavenger pastSpace limit equals: memory scavenger futureSpace start
]

{ #category : #'test-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryPastSpaceFreeStartIsAtPastSpaceStart [
	
	self assert: memory pastSpaceStart equals: memory scavenger pastSpace start
]

{ #category : #'test-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryPastSpaceIsAtTheStartOfNewSpace [
	
	self assert: memory pastSpaceStart equals: memory newSpaceStart
]

{ #category : #'test-memory-initialization' }
VMSpurMemoryManagerTest >> testNewMemoryPastSpaceIsRoughlyOneSeventhOfNewSpace [
	
	self assert: memory scavenger pastSpaceBytes equals: (newSpaceSize // 7 truncateTo: memory allocationUnit)
]

{ #category : #'tests-instantiation' }
VMSpurMemoryManagerTest >> testNewObjectAfterEdenLimitThrowsError [
	
	| classIndex newObjectSize |
	classIndex := self nextOrdinaryClassIndex.
	newObjectSize := 16 "bytes".

	"Allocate enough objects to fill the eden."
	1
		to: memory scavenger eden size // newObjectSize
		do: [ :index | 
			memory
				allocateNewSpaceSlots: 0
				format: 0 "zero sized object"
				classIndex: classIndex ].
	
	"Allocating one more object should not be allowed, and should throw an error"
	[ memory
		allocateNewSpaceSlots: 0
		format: 0 "zero sized object"
		classIndex: classIndex.
		
		"Fail the test if it does not raise an exception"
		self fail ] on: Error do: [ :error | 
			self assert: error messageText equals: 'no room in eden for allocateNewSpaceSlots:format:classIndex:' ]
]

{ #category : #'tests-instantiation' }
VMSpurMemoryManagerTest >> testNewObjectPositionIsBeforeObjectHeader [
	
	| freeStartBefore classIndex oop |
	freeStartBefore := memory freeStart.
	
	classIndex := self nextOrdinaryClassIndex.
	oop := memory
		allocateNewSpaceSlots: 0
		format: 0 "zero sized object"
		classIndex: classIndex.
	
	self assert: oop equals: freeStartBefore
]

{ #category : #'tests-scavenge' }
VMSpurMemoryManagerTest >> testScavengeEmptyMemoryShouldExchangePastAndFutureSpaces [

	| oldPastSpaceStart oldFutureSpaceStart |

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
	memory allocateClassTable.	
	memory scavenger initializeRememberedSet.
	
	oldPastSpaceStart := memory scavenger pastSpace start.
	oldFutureSpaceStart := memory scavenger futureSpace start.
	
	memory doScavenge: 1 "TenureByAge".
	
	self assert: memory scavenger pastSpace start equals: oldFutureSpaceStart.
	self assert: memory scavenger futureSpace start equals: oldPastSpaceStart.
]

{ #category : #helpers }
VMSpurMemoryManagerTest >> zeroSizedObjectClassIndex [

	^ zeroSizedObjectClassIndex ifNil: [ self nextOrdinaryClassIndex ]
]
