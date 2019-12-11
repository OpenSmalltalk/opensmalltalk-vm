Class {
	#name : #VMSpurMemoryManagerTest,
	#superclass : #TestCase,
	#instVars : [
		'newSpaceSize',
		'stackSize',
		'memory',
		'oldSpaceSize',
		'nextIndex',
		'objectHeaderSize'
	],
	#category : #VMMakerTests
}

{ #category : #helpers }
VMSpurMemoryManagerTest >> nextOrdinaryClassIndex [
	
	^ nextIndex
		ifNil: [ nextIndex := memory classTablePageSize ]
		ifNotNil: [ nextIndex := nextIndex + 1 ]
]

{ #category : #running }
VMSpurMemoryManagerTest >> setUp [
	
	super setUp.

	oldSpaceSize := 1 * 1024.
 	newSpaceSize := 1 * 1024.
	stackSize := 16 * 1024.
	
	objectHeaderSize := 8.
	
	memory := Spur64BitMMLESimulator new.
	memory
		allocateMemoryOfSize: oldSpaceSize
		newSpaceSize: newSpaceSize
		stackSize: stackSize
		codeSize: 0.
	memory initializePostBootstrap.
	
	"Schedule a GC, so it does not try to schedule one"
	memory needGCFlag: 1.
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
