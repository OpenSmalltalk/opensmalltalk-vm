Class {
	#name : #VMSpurOldSpaceTest,
	#superclass : #VMSpurInitializedOldSpaceTest,
	#category : #VMMakerTests
}

{ #category : #tests }
VMSpurOldSpaceTest >> test8ByteFragmentedFreeChunksShouldBeInFreeList [

	| firstAddress secondAddress thirdAddress newAddress |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 32.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 32.
	thirdAddress := memory allocateOldSpaceChunkOfBytes: 32.

	memory freeChunkWithBytes: 32 at: secondAddress.
	newAddress := memory allocateOldSpaceChunkOfBytes: 24.
	
	self assert: memory allFreeObjects size equals: 2
]

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
VMSpurOldSpaceTest >> testAllocationShouldNotLeaveFreeChunkSmallerThanLiliputian [

	| firstAddress secondAddress thirdAddress newAddress freeLargeSpaceBeforeAllocation |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 32.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 32.
	thirdAddress := memory allocateOldSpaceChunkOfBytes: 32.

	memory freeChunkWithBytes: 32 at: secondAddress.

	"Allocating 24 bytes should not reuse the 32bytes free chunk because it will leave a free chunk < 16bytes (a liliputian)"	
	freeLargeSpaceBeforeAllocation := memory freeLists at: 0.
	newAddress := memory allocateOldSpaceChunkOfBytes: 24.

	self assert: newAddress equals: (memory startOfObject: freeLargeSpaceBeforeAllocation)
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
VMSpurOldSpaceTest >> testFreeAChunkShouldBePutAsHeadOfFreeList [

	| firstAddress secondAddress freeListHead |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 32.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 32.

	memory freeChunkWithBytes: 32 at: firstAddress.	
	memory freeChunkWithBytes: 32 at: secondAddress.

	freeListHead := memory freeLists at: 32 / memory allocationUnit.
	self assert: freeListHead equals: secondAddress
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
VMSpurOldSpaceTest >> testFreeChunkShouldKnowNextChunkOfSameSize [

	| firstAddress secondAddress freeListHead nextFreeChunk |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 32.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 32.

	memory freeChunkWithBytes: 32 at: firstAddress.	
	memory freeChunkWithBytes: 32 at: secondAddress.

	freeListHead := memory freeLists at: 32 / memory allocationUnit.
	nextFreeChunk := memory fetchPointer: memory freeChunkNextIndex ofFreeChunk: freeListHead.
	self assert: nextFreeChunk equals: firstAddress
]

{ #category : #tests }
VMSpurOldSpaceTest >> testFreeChunkShouldKnowPreviousChunkOfSameSize [

	| firstAddress secondAddress freeListHead nextFreeChunk previousFreeChunk |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 32.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 32.

	memory freeChunkWithBytes: 32 at: firstAddress.	
	memory freeChunkWithBytes: 32 at: secondAddress.

	freeListHead := memory freeLists at: 32 / memory allocationUnit.
	nextFreeChunk := memory fetchPointer: memory freeChunkNextIndex ofFreeChunk: freeListHead.
	previousFreeChunk := memory fetchPointer: memory freeChunkPrevIndex ofFreeChunk: nextFreeChunk.
	self assert: previousFreeChunk equals: freeListHead
]

{ #category : #tests }
VMSpurOldSpaceTest >> testFreeChunksWithSameSizeShouldBeListedAsDifferentFreeChunks [

	| firstAddress secondAddress thirdAddress newAddress |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 160.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	thirdAddress := memory allocateOldSpaceChunkOfBytes: 160.

	memory freeChunkWithBytes: 160 at: secondAddress.
	newAddress := memory allocateOldSpaceChunkOfBytes: 80.
	memory freeChunkWithBytes: 80 at: newAddress.
	
	self assert: memory allFreeObjects size equals: 3
]

{ #category : #tests }
VMSpurOldSpaceTest >> testFreeChunksWithSameSizeShouldShareSingleHead [

	| firstAddress secondAddress thirdAddress newAddress |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 160.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	thirdAddress := memory allocateOldSpaceChunkOfBytes: 160.

	memory freeChunkWithBytes: 160 at: secondAddress.
	newAddress := memory allocateOldSpaceChunkOfBytes: 80.
	memory freeChunkWithBytes: 80 at: newAddress.
	
	self assert: memory allFreeHeads size equals: 2
]

{ #category : #tests }
VMSpurOldSpaceTest >> testFreeListEntryIsFreeObject [

	self assert: (memory isFreeObject: (memory freeLists at: 0))
]

{ #category : #tests }
VMSpurOldSpaceTest >> testFreeListsShouldBeIndexedBySlotSize [

	| firstAddress freeListHead |
	
	2 to: 63 do: [ :numberOfSlots | | byteSize |
		byteSize := numberOfSlots * memory allocationUnit.
		
		firstAddress := memory allocateOldSpaceChunkOfBytes: byteSize.
		memory freeChunkWithBytes: byteSize at: firstAddress.
	
		freeListHead := memory freeLists at: numberOfSlots.
		self assert: freeListHead equals: firstAddress
	]
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
VMSpurOldSpaceTest >> testSingleFreeChunkListNextShouldBeZero [

	| firstAddress freeListHead nextFreeChunk |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 32.

	memory freeChunkWithBytes: 32 at: firstAddress.	

	freeListHead := memory freeLists at: 32 / memory allocationUnit.
	nextFreeChunk := memory fetchPointer: memory freeChunkNextIndex ofFreeChunk: freeListHead.

	self assert: nextFreeChunk equals: 0
]

{ #category : #tests }
VMSpurOldSpaceTest >> testSingleFreeChunkListPreviousShouldBeZero [

	| firstAddress freeListHead previousFreeChunk |
	firstAddress := memory allocateOldSpaceChunkOfBytes: 32.

	memory freeChunkWithBytes: 32 at: firstAddress.	

	freeListHead := memory freeLists at: 32 / memory allocationUnit.
	previousFreeChunk := memory fetchPointer: memory freeChunkPrevIndex ofFreeChunk: freeListHead.

	self assert: previousFreeChunk equals: 0
]

{ #category : #tests }
VMSpurOldSpaceTest >> testTotalListFreeBytesShouldBeOldSpaceSizeMinusAllocatedObjectsSize [
	
	self assert: memory totalFreeListBytes < oldSpaceSize
]
