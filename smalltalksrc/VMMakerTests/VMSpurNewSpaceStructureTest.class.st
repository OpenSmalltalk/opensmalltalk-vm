Class {
	#name : #VMSpurNewSpaceStructureTest,
	#superclass : #VMSpurMemoryManagerTest,
	#category : #VMMakerTests
}

{ #category : #'tests-2-instantiation' }
VMSpurNewSpaceStructureTest >> fillEden [

	"Allocate enough objects to fill the eden."
	1
		to: memory scavenger eden size // emptyObjectSize
		do: [ :index | self newZeroSizedObject ]
]

{ #category : #'tests-2-instantiation' }
VMSpurNewSpaceStructureTest >> testInstantiateNewObjectMovesFreeStartAfterObject [
	
	| freeStartBefore |
	freeStartBefore := memory freeStart.
	self newZeroSizedObject.
	
	"New zero sized object has 64bit header + 1 * 64bit empty slot = 16bytes"
	self assert: memory freeStart equals: freeStartBefore + emptyObjectSize
]

{ #category : #'tests-2-instantiation' }
VMSpurNewSpaceStructureTest >> testInstantiateNewObjectWithSlotMovesFreeStartAfterObject [
	
	| freeStartBefore |
	freeStartBefore := memory freeStart.
	self newObjectWithSlots: 0.
	
	"New zero sized object has 64bit header + 1 * 64bit empty slot = 16bytes"
	self assert: memory freeStart equals: freeStartBefore + emptyObjectSize
]

{ #category : #'tests-1-memory-initialization' }
VMSpurNewSpaceStructureTest >> testNewMemoryEdenEndIsAtTheStartOfOldSpace [

	self assert: memory scavenger eden limit equals: memory oldSpaceStart
]

{ #category : #'tests-1-memory-initialization' }
VMSpurNewSpaceStructureTest >> testNewMemoryEdenIsRestOfNewSpace [
	
	self
		assert: memory scavenger eden size
		equals: newSpaceSize - memory scavenger pastSpace size - memory scavenger futureSpace size
]

{ #category : #'tests-1-memory-initialization' }
VMSpurNewSpaceStructureTest >> testNewMemoryFreeStartIsEdenStart [
	
	self assert: memory freeStart equals: memory scavenger eden start
]

{ #category : #'tests-1-memory-initialization' }
VMSpurNewSpaceStructureTest >> testNewMemoryFutureSpaceEndIsAtTheStartOfEden [

	self assert: memory scavenger futureSpace limit equals: memory scavenger eden start
]

{ #category : #'tests-1-memory-initialization' }
VMSpurNewSpaceStructureTest >> testNewMemoryFutureSpaceIsRoughlyOneSeventhOfNewSpace [
	
	self assert: memory scavenger futureSpace size equals: (newSpaceSize // 7 truncateTo: memory allocationUnit)
]

{ #category : #'tests-1-memory-initialization' }
VMSpurNewSpaceStructureTest >> testNewMemoryFutureSurvivorSpaceIsAtFutureSpaceStart [
	
	"The future survivor start indicates during the execution of the scavenger, where the next free space in future space starts."
	
	self assert: memory scavenger futureSurvivorStart equals: memory scavenger futureSpace start
]

{ #category : #'tests-1-memory-initialization' }
VMSpurNewSpaceStructureTest >> testNewMemoryLimitIsSumOfSpaces [
	
	self assert: memory memoryLimit equals: oldSpaceSize + newSpaceSize + stackSpaceSize + initialAddress + self primitiveTraceLogSize + methodCacheSize 
]

{ #category : #'tests-1-memory-initialization' }
VMSpurNewSpaceStructureTest >> testNewMemoryNewSpaceLimitIsNewSpaceStartPlusSize [
	
	self assert: memory newSpaceLimit equals: newSpaceSize + stackSpaceSize + initialAddress	+ self primitiveTraceLogSize + methodCacheSize 
]

{ #category : #'tests-1-memory-initialization' }
VMSpurNewSpaceStructureTest >> testNewMemoryNewSpaceStartIsStackSize [

	self assert: memory newSpaceStart equals: stackSpaceSize + initialAddress + self primitiveTraceLogSize + methodCacheSize 
]

{ #category : #'tests-1-memory-initialization' }
VMSpurNewSpaceStructureTest >> testNewMemoryPastSpaceEndIsAtTheStartOfFutureSpace [

	self assert: memory scavenger pastSpace limit equals: memory scavenger futureSpace start
]

{ #category : #'tests-1-memory-initialization' }
VMSpurNewSpaceStructureTest >> testNewMemoryPastSpaceFreeStartIsAtPastSpaceStart [
	
	" - pastSpaceStart points to where the free space in the past space starts => it **does** move
	  - scavenger pastSpace start points to the actual beginning of the past space => it does not move"
	
	self assert: memory pastSpaceStart equals: memory scavenger pastSpace start
]

{ #category : #'tests-1-memory-initialization' }
VMSpurNewSpaceStructureTest >> testNewMemoryPastSpaceIsAtTheStartOfNewSpace [
	
	self assert: memory scavenger pastSpace start equals: memory newSpaceStart
]

{ #category : #'tests-1-memory-initialization' }
VMSpurNewSpaceStructureTest >> testNewMemoryPastSpaceIsRoughlyOneSeventhOfNewSpace [
	
	self assert: memory scavenger pastSpaceBytes equals: (newSpaceSize // 7 truncateTo: memory allocationUnit)
]

{ #category : #'tests-2-instantiation' }
VMSpurNewSpaceStructureTest >> testNewObjectAfterEdenLimitThrowsError [

	"Allocate enough objects to fill the eden."
	self fillEden.
	
	"Allocating one more object should not be allowed, and should throw an error"
	[ self newZeroSizedObject.
		
		"Fail the test if it does not raise an exception"
		self fail ] on: Error do: [ :error | 
			self assert: error messageText equals: 'no room in eden for allocateNewSpaceSlots:format:classIndex:' ]
]

{ #category : #'tests-2-instantiation' }
VMSpurNewSpaceStructureTest >> testNewObjectInEdenDoesNotModifyFutureSpace [
	
	| futureSpaceStartBefore |
	futureSpaceStartBefore := memory scavenger futureSurvivorStart.
	self newZeroSizedObject.
	
	self assert: memory scavenger futureSurvivorStart equals: futureSpaceStartBefore
]

{ #category : #'tests-2-instantiation' }
VMSpurNewSpaceStructureTest >> testNewObjectInEdenDoesNotModifyPastSpace [
	
	| pastSpaceStartBefore |
	pastSpaceStartBefore := memory pastSpaceStart.
	self newZeroSizedObject.
	
	self assert: memory pastSpaceStart equals: pastSpaceStartBefore
]

{ #category : #'tests-2-instantiation' }
VMSpurNewSpaceStructureTest >> testNewObjectPositionIsBeforeObjectHeader [
	
	| freeStartBefore oop |
	freeStartBefore := memory freeStart.
	
	oop := self newZeroSizedObject.
	
	self assert: oop equals: freeStartBefore
]

{ #category : #'tests-2-instantiation' }
VMSpurNewSpaceStructureTest >> testNewObjectWithSlotsPositionIsBeforeObjectHeader [
	
	| freeStartBefore oop |
	freeStartBefore := memory freeStart.
	
	oop := self newObjectWithSlots: 0.
	
	self assert: oop equals: freeStartBefore
]

{ #category : #'tests-2-instantiation' }
VMSpurNewSpaceStructureTest >> testScavengeThresholdIsInsideTheEden [

	self assert:(memory scavengeThreshold
						between: memory scavenger eden start
						and: memory scavenger eden limit)
]
