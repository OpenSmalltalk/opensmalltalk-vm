Class {
	#name : #VMSpurOldSpaceTest,
	#superclass : #VMSpurInitializedOldSpaceTest,
	#category : #VMMakerTests
}

{ #category : #tests }
VMSpurOldSpaceTest >> testAllocateAllFreeMemoryShouldFillSingleSegment [

	1halt.
	memory allocateOldSpaceChunkOfBytes: memory totalFreeListBytes.
	
	self assert: memory totalFreeListBytes equals: 0
]

{ #category : #tests }
VMSpurOldSpaceTest >> testAllocateChunkOfMemoryShouldHaveSoMuchMemoryLessAfter [

	| someBytes freeBytesBefore |
	someBytes := 32.
	freeBytesBefore := memory totalFreeListBytes.
	memory allocateOldSpaceChunkOfBytes: someBytes.
	
	self assert: memory totalFreeListBytes equals: freeBytesBefore - someBytes
]

{ #category : #tests }
VMSpurOldSpaceTest >> testAllocateExactBiggerChunkShouldNotReuseSmallFreeChunk [

	| firstAddress secondAddress thirdAddress newAddress |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 160.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	thirdAddress := memory allocateOldSpaceChunkOfBytes: 160.

	memory freeChunkWithBytes: 160 at: secondAddress.

	newAddress := memory allocateOldSpaceChunkOfBytes: 240.
	self deny: newAddress equals: secondAddress
]

{ #category : #tests }
VMSpurOldSpaceTest >> testAllocateExactFitShouldReuseFreeChunk [

	| firstAddress secondAddress thirdAddress newAddress |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 160.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	thirdAddress := memory allocateOldSpaceChunkOfBytes: 160.

	memory freeChunkWithBytes: 160 at: secondAddress.

	newAddress := memory allocateOldSpaceChunkOfBytes: 160.
	self assert: newAddress equals: secondAddress
]

{ #category : #tests }
VMSpurOldSpaceTest >> testAllocateLessThanFreeMemoryShouldKeepFreeSpaceContiguous [

	"We allocate less memory than the free memory"
	memory allocateOldSpaceChunkOfBytes: (memory totalFreeListBytes - 32).
	
	self assert: memory allFreeObjects size equals: 1
]

{ #category : #tests }
VMSpurOldSpaceTest >> testAllocateManyChunksShouldKeepSingleFreeEntry [

	| firstAddress secondAddress thirdAddress |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 160.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	thirdAddress := memory allocateOldSpaceChunkOfBytes: 160.

	self assert: memory allFreeObjects size equals: 1
]

{ #category : #tests }
VMSpurOldSpaceTest >> testAllocateMoreThanFreeMemoryShouldFailReturningNil [
	
	| address |
	address := memory allocateOldSpaceChunkOfBytes: memory totalFreeListBytes + 1.
	
	self assert: address isNil
]

{ #category : #tests }
VMSpurOldSpaceTest >> testAllocateSmallerChunkShouldReusePartiallyFreeChunk [

	| firstAddress secondAddress thirdAddress newAddress |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 160.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	thirdAddress := memory allocateOldSpaceChunkOfBytes: 160.

	memory freeChunkWithBytes: 160 at: secondAddress.

	newAddress := memory allocateOldSpaceChunkOfBytes: 80.
	self assert: newAddress equals: secondAddress
]

{ #category : #tests }
VMSpurOldSpaceTest >> testAllocatedChunkAddressesShouldBeInAllocationOrder [

	| secondAddress thirdAddress |
	memory allocateOldSpaceChunkOfBytes: 160.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	thirdAddress := memory allocateOldSpaceChunkOfBytes: 160.
	
	self assert: secondAddress < thirdAddress
]

{ #category : #tests }
VMSpurOldSpaceTest >> testAllocatedChunkOfMemoryShouldRemoveSpaceFromFreeList [

	| freeChunkStart allocatedSize |
	allocatedSize := 16.
	freeChunkStart := memory startOfObject: (memory freeLists at: 0).
	memory allocateOldSpaceChunkOfBytes: allocatedSize.
	self
		assert: (memory startOfObject: (memory freeLists at: 0))
		equals: freeChunkStart + allocatedSize
]

{ #category : #tests }
VMSpurOldSpaceTest >> testAllocatedChunkOfMemoryShouldStartWhereFreeChunkStarted [

	| freeChunkStart allocatedAddress |
	freeChunkStart := memory startOfObject: (memory freeLists at: 0).
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: 16.
	self
		assert: allocatedAddress
		equals: freeChunkStart
]

{ #category : #tests }
VMSpurOldSpaceTest >> testContiguousFreeChunksShouldBeContiguous [

	| firstAddress secondAddress thirdAddress previousFreeChunk |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 160.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	thirdAddress := memory allocateOldSpaceChunkOfBytes: 160.
	
	previousFreeChunk := memory freeLists at: 0.
	memory freeChunkWithBytes: 160 at: thirdAddress.
	
	self
		assert: thirdAddress + (memory bytesInObject: thirdAddress)
		equals: (memory startOfObject: previousFreeChunk)
]

{ #category : #tests }
VMSpurOldSpaceTest >> testFreeChunkInTheMidstOfTwoChunksShouldCreateAnEntryInTheFreeList [

	| firstAddress secondAddress thirdAddress |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 160.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	thirdAddress := memory allocateOldSpaceChunkOfBytes: 160.

	memory freeChunkWithBytes: 160 at: secondAddress.
	self assert: memory allFreeObjects size equals: 2
]

{ #category : #tests }
VMSpurOldSpaceTest >> testFreeListEntryIsFreeObject [

	self assert: (memory isFreeObject: (memory freeLists at: 0))
]

{ #category : #tests }
VMSpurOldSpaceTest >> testInitialFreeObjectSizeShouldBeTotalFreeSpace [

	self
		assert: (memory bytesInObject: (memory freeLists at: 0))
		equals: memory totalFreeListBytes
]

{ #category : #tests }
VMSpurOldSpaceTest >> testNewMemoryFreeListShouldHaveSingleEntry [

	self assert: memory allFreeObjects size equals: 1
]

{ #category : #tests }
VMSpurOldSpaceTest >> testNewObjectShouldBeOld [
	
	| oop |
	oop := memory allocateSlotsInOldSpace: 0 format: 0 classIndex: self zeroSizedObjectClassIndex.
	
	self assert: (memory isOldObject: oop)
]

{ #category : #tests }
VMSpurOldSpaceTest >> testPartiallyReusingFreeChunkShouldKeepNumberOfEntriesInFreeList [

	| firstAddress secondAddress thirdAddress newAddress freeChunksBefore |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 160.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	thirdAddress := memory allocateOldSpaceChunkOfBytes: 160.

	memory freeChunkWithBytes: 160 at: secondAddress.
	freeChunksBefore := memory allFreeObjects size.
	newAddress := memory allocateOldSpaceChunkOfBytes: 80.
	
	self assert: memory allFreeObjects size equals: freeChunksBefore.
]

{ #category : #tests }
VMSpurOldSpaceTest >> testReuseFreeChunkShouldRemoveEntryFromFreeList [

	| firstAddress secondAddress thirdAddress |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 160.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	thirdAddress := memory allocateOldSpaceChunkOfBytes: 160.

	memory freeChunkWithBytes: 160 at: secondAddress.
	memory allocateOldSpaceChunkOfBytes: 160.
	
	self assert: memory allFreeObjects size equals: 1
]

{ #category : #tests }
VMSpurOldSpaceTest >> testTotalListFreeBytesShouldBeOldSpaceSizeMinusAllocatedObjectsSize [
	
	self assert: memory totalFreeListBytes < oldSpaceSize
]
