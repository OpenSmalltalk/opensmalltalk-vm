Class {
	#name : #VMSpurOldSpaceTest,
	#superclass : #VMSpurInitializedOldSpaceTest,
	#category : #'VMMakerTests-MemoryTests'
}

{ #category : #'tests-2-allocation-basic' }
VMSpurOldSpaceTest >> testAllocateAllFreeMemoryShouldLeaveNoFreeMemory [

	memory allocateOldSpaceChunkOfBytes: memory totalFreeListBytes.
	
	self assert: memory totalFreeListBytes equals: 0
]

{ #category : #'tests-8-allocation-strategy-list-bestfit' }
VMSpurOldSpaceTest >> testAllocateBestFitInListShouldAddLeftoverInList [

	self createFreeChunkOfSize: 120.
	self createFreeChunkOfSize: 160.

	"Not exact, nor multiple of a power of 2"
	memory allocateOldSpaceChunkOfBytes: 96.

	self denyFreeListEmpty: (self freeListForSize: 24)
]

{ #category : #'tests-8-allocation-strategy-list-bestfit' }
VMSpurOldSpaceTest >> testAllocateBestFitInListShouldRemoveSmallerNodeFromLists [

	self createFreeChunkOfSize: 120.
	self createFreeChunkOfSize: 160.

	"Not exact, nor multiple of a power of 2"
	memory allocateOldSpaceChunkOfBytes: 96.

	self assertFreeListEmpty: (self freeListForSize: 120)
]

{ #category : #'tests-8-allocation-strategy-list-bestfit' }
VMSpurOldSpaceTest >> testAllocateBestFitInListShouldReuseSmallerAddress [

	| smallerAddress newAddress |
	smallerAddress := self createFreeChunkOfSize: 120.
	self createFreeChunkOfSize: 160.

	"Not exact, nor multiple of a power of 2"
	newAddress := memory allocateOldSpaceChunkOfBytes: 96.

	self assert: newAddress equals: smallerAddress
]

{ #category : #'tests-8-allocation-strategy-list-bestfit' }
VMSpurOldSpaceTest >> testAllocateBestFitInListShouldUseIgnoreBiggerChunk [

	self createFreeChunkOfSize: 120.
	self createFreeChunkOfSize: 160.

	"Not exact, nor multiple of a power of 2"
	memory allocateOldSpaceChunkOfBytes: 96.

	self denyFreeListEmpty: (self freeListForSize: 160)
]

{ #category : #'tests-2-allocation-basic' }
VMSpurOldSpaceTest >> testAllocateChunkOfMemoryShouldHaveSoMuchMemoryLessAfter [

	| someBytes freeBytesBefore |
	someBytes := 32.
	freeBytesBefore := memory totalFreeListBytes.
	memory allocateOldSpaceChunkOfBytes: someBytes.
	
	self assert: memory totalFreeListBytes equals: freeBytesBefore - someBytes
]

{ #category : #'tests-5-allocation-strategy' }
VMSpurOldSpaceTest >> testAllocateExactBiggerChunkShouldNotReuseSmallFreeChunk [

	| secondAddress newAddress |
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	memory freeChunkWithBytes: 160 at: secondAddress.

	newAddress := memory allocateOldSpaceChunkOfBytes: 240.
	self deny: newAddress equals: secondAddress
]

{ #category : #'tests-6-allocation-strategy-list-exact' }
VMSpurOldSpaceTest >> testAllocateExactFitInListShouldIgnoreBiggerChunks [

	self createFreeChunkOfSize: 160.
	self createFreeChunkOfSize: 200.

	memory allocateOldSpaceChunkOfBytes: 160.

	self assertFreeListEmpty: (self freeListForSize: 160).
	self denyFreeListEmpty: (self freeListForSize: 200)
]

{ #category : #'tests-6-allocation-strategy-list-exact' }
VMSpurOldSpaceTest >> testAllocateExactFitInListShouldRemoveNodeFromList [

	| secondAddress |
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	memory freeChunkWithBytes: 160 at: secondAddress.

	memory allocateOldSpaceChunkOfBytes: 160.
	self assert: (self freeListForSize: 160) equals: 0
]

{ #category : #'tests-6-allocation-strategy-list-exact' }
VMSpurOldSpaceTest >> testAllocateExactFitInListShouldReuseAddress [

	| secondAddress newAddress |
	secondAddress := self createFreeChunkOfSize: 160.

	newAddress := memory allocateOldSpaceChunkOfBytes: 160.
	self assert: newAddress equals: secondAddress
]

{ #category : #'tests-9-allocation-strategy-tree' }
VMSpurOldSpaceTest >> testAllocateExactFitTreeRootShouldRemoveRootFromTree [

	memory allocateOldSpaceChunkOfBytes: (memory bytesInObject: self freeTreeRootOop).

	self assert: self freeTreeRootOop equals: 0
]

{ #category : #'tests-9-allocation-strategy-tree' }
VMSpurOldSpaceTest >> testAllocateExactTreeRootShouldReuseRootAddress [

	| oldRootAddress newAddress |
	oldRootAddress := self freeTreeRootStartAddress.

	newAddress := memory allocateOldSpaceChunkOfBytes: (memory bytesInObject: self freeTreeRootOop).

	self assert: newAddress equals: oldRootAddress
]

{ #category : #'tests-4-free-tree' }
VMSpurOldSpaceTest >> testAllocateHalfOfTreeNodeShouldSplitIt [
	| size childAddress smallerChildOop largerChildOop aBitBiggerThanHalf |
	
	size := 1600.	"Big enough size to be in the tree"
	childAddress := memory allocateOldSpaceChunkOfBytes: size.
	memory freeChunkWithBytes: size at: childAddress.
	
	aBitBiggerThanHalf := size / 2 + 8.	"node a bit bigger than half"
	childAddress := memory allocateOldSpaceChunkOfBytes: aBitBiggerThanHalf.
	memory freeChunkWithBytes: aBitBiggerThanHalf at: childAddress.
	
	smallerChildOop := self smallerNodeOf: self freeTreeRootOop.
	self assert: (memory bytesInObject: smallerChildOop) equals: (size - aBitBiggerThanHalf).

	largerChildOop := self largerNodeOf: smallerChildOop.
	self assert: (memory bytesInObject: largerChildOop) equals: aBitBiggerThanHalf
]

{ #category : #'tests-4-free-tree' }
VMSpurOldSpaceTest >> testAllocateInFreeTreeShouldChangeRoot [

	| freeRootOopBeforeAllocation |
	freeRootOopBeforeAllocation := self freeTreeRootOop.
	
	memory allocateOldSpaceChunkOfBytes: 800 "Big enough to be in the tree".
	
	self deny: freeRootOopBeforeAllocation equals: self freeTreeRootOop
]

{ #category : #'tests-2-allocation-basic' }
VMSpurOldSpaceTest >> testAllocateManyChunksShouldKeepSingleFreeEntry [

	"Allocation should be contiguous because we have a single big chunk of memory to take memory from"
	memory allocateOldSpaceChunkOfBytes: 160.
	memory allocateOldSpaceChunkOfBytes: 160.
	memory allocateOldSpaceChunkOfBytes: 160.

	self assert: memory allFreeObjects size equals: 1
]

{ #category : #'tests-2-allocation-basic' }
VMSpurOldSpaceTest >> testAllocateMoreThanFreeMemoryShouldFailReturningNil [
	
	| address |
	address := memory allocateOldSpaceChunkOfBytes: memory totalFreeListBytes + 1.
	
	self assert: address isNil
]

{ #category : #'tests-9-allocation-strategy-tree' }
VMSpurOldSpaceTest >> testAllocatePartOfTreeRootShouldAddBigLeftOverAsFreeTreeRoot [

	| leftOverSize |
	leftOverSize := 64 * 8 "more than 63 slots".
	memory allocateOldSpaceChunkOfBytes: (memory totalFreeListBytes - leftOverSize).

	self assert: (memory bytesInObject: self freeTreeRootOop) equals: leftOverSize
]

{ #category : #'tests-9-allocation-strategy-tree' }
VMSpurOldSpaceTest >> testAllocatePartOfTreeRootShouldAddSmallLeftOverInFreeList [

	| leftOverSize |
	leftOverSize := 120.
	memory allocateOldSpaceChunkOfBytes: (memory totalFreeListBytes - leftOverSize).

	self denyFreeListEmpty: (self freeListForSize: leftOverSize)
]

{ #category : #'tests-9-allocation-strategy-tree' }
VMSpurOldSpaceTest >> testAllocatePartOfTreeRootShouldReuseRootAddress [

	| oldRootAddress newAddress |
	oldRootAddress := self freeTreeRootStartAddress.

	"At this point we can allocate whatever we want, only the tree has space, so we will take space from the tree anyways"
	self assert: 120 < (memory bytesInObject: self freeTreeRootOop).
	newAddress := memory allocateOldSpaceChunkOfBytes: 120.

	self assert: newAddress equals: oldRootAddress
]

{ #category : #'tests-7-allocation-strategy-list-power' }
VMSpurOldSpaceTest >> testAllocatePowerInListShouldAddLeftoverInList [

	| sizeToAllocate powerOfSizeToAllocate leftOverSize |
	sizeToAllocate := 80.
	powerOfSizeToAllocate := sizeToAllocate * (2 ** 2).
	leftOverSize := powerOfSizeToAllocate - sizeToAllocate.
	self createFreeChunkOfSize: powerOfSizeToAllocate.

	memory allocateOldSpaceChunkOfBytes: sizeToAllocate.
	self denyFreeListEmpty: (self freeListForSize: leftOverSize)
]

{ #category : #'tests-7-allocation-strategy-list-power' }
VMSpurOldSpaceTest >> testAllocatePowerInListShouldIgnoreNonPowers [

	| sizeToAllocate powerOfSizeToAllocate nonMultipleAddress newAddress |
	"bitSize * allocationUnit equals maxChunckSize in the freeList
	The freeList has bitsPerWords slots.
	Each slots contains a pointer (wordsize), which behaves as a linked list.
	Each linked list contains links free chunks of the same size.
	The nodeSize of each list equals index * allocationUnit.
	For example in 32 bits the free list will have 31 slots (1 for reserved for the tree).
	The last linked list is stored at index 31 (0 based) and will contain nodes of size 248 (index * 8)."
	sizeToAllocate := 10 * wordSize.
	powerOfSizeToAllocate := sizeToAllocate * (2 ** 2).
	
	nonMultipleAddress := self createFreeChunkOfSize: 120.
	
	self createFreeChunkOfSize: powerOfSizeToAllocate.
	
	newAddress := memory allocateOldSpaceChunkOfBytes: sizeToAllocate.
	self deny: newAddress equals: nonMultipleAddress.
]

{ #category : #'tests-7-allocation-strategy-list-power' }
VMSpurOldSpaceTest >> testAllocatePowerInListShouldRemoveNodeFromList [

	| sizeToAllocate powerOfSizeToAllocate |
	sizeToAllocate := 10 * wordSize.
	powerOfSizeToAllocate := sizeToAllocate * (2 ** 2).
	self createFreeChunkOfSize: powerOfSizeToAllocate.

	memory allocateOldSpaceChunkOfBytes: sizeToAllocate.
	self assertFreeListEmpty: (self freeListForSize: powerOfSizeToAllocate)
]

{ #category : #'tests-7-allocation-strategy-list-power' }
VMSpurOldSpaceTest >> testAllocatePowerInListShouldReuseMultipleAddress [

	| sizeToAllocate freeMultipleAddress newAddress powerOfSizeToAllocate |
	sizeToAllocate := 80.
	powerOfSizeToAllocate := sizeToAllocate * (2 ** 2).
	freeMultipleAddress := self createFreeChunkOfSize: powerOfSizeToAllocate.

	newAddress := memory allocateOldSpaceChunkOfBytes: sizeToAllocate.
	self assert: newAddress equals: freeMultipleAddress
]

{ #category : #'tests-5-allocation-strategy' }
VMSpurOldSpaceTest >> testAllocateSmallerChunkShouldReusePartiallyFreeChunk [

	| secondAddress newAddress |
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	memory freeChunkWithBytes: 160 at: secondAddress.

	newAddress := memory allocateOldSpaceChunkOfBytes: 80.
	self assert: newAddress equals: secondAddress
]

{ #category : #'tests-2-allocation-basic' }
VMSpurOldSpaceTest >> testAllocatedChunkAddressesShouldBeInAllocationOrder [

	| secondAddress thirdAddress |
	memory allocateOldSpaceChunkOfBytes: 160.
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	thirdAddress := memory allocateOldSpaceChunkOfBytes: 160.
	
	self assert: secondAddress < thirdAddress
]

{ #category : #'tests-2-allocation-basic' }
VMSpurOldSpaceTest >> testAllocatedChunkOfMemoryShouldRemoveSpaceFromFreeList [

	| freeChunkStartAddress allocatedSize |
	allocatedSize := 16.
	freeChunkStartAddress := self freeTreeRootStartAddress.
	memory allocateOldSpaceChunkOfBytes: allocatedSize.
	self
		assert: self freeTreeRootStartAddress
		equals: freeChunkStartAddress + allocatedSize
]

{ #category : #'tests-2-allocation-basic' }
VMSpurOldSpaceTest >> testAllocatedChunkOfMemoryShouldStartWhereFreeChunkStarted [

	| freeChunkStartAddressBeforeAllocation allocatedAddress |
	freeChunkStartAddressBeforeAllocation := self freeTreeRootStartAddress.
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: 16.
	self
		assert: allocatedAddress
		equals: freeChunkStartAddressBeforeAllocation
]

{ #category : #'tests-4-free-tree' }
VMSpurOldSpaceTest >> testAllocationLargerThanFreeListLimitShouldUseFreeTree [

	| firstAddress byteSize smallerNodeOop |
	
	byteSize := memory numFreeLists * memory allocationUnit.
	firstAddress := memory allocateOldSpaceChunkOfBytes: byteSize.
	memory freeChunkWithBytes: byteSize at: firstAddress.
	
	smallerNodeOop := self smallerNodeOf: self freeTreeRootOop.
	self assert: smallerNodeOop equals: firstAddress
]

{ #category : #'tests-5-allocation-strategy' }
VMSpurOldSpaceTest >> testAllocationShouldNotLeaveFreeChunkSmallerThanLiliputian [

	| newAddress freeLargeSpaceAddressBeforeAllocation freeAddress |
	freeAddress := memory allocateOldSpaceChunkOfBytes: 32.
	memory freeChunkWithBytes: 32 at: freeAddress.

	"Allocating 24 bytes should not reuse the 32bytes free chunk because it will leave a free chunk < 16bytes (a liliputian)"	
	freeLargeSpaceAddressBeforeAllocation := self freeTreeRootStartAddress.
	newAddress := memory allocateOldSpaceChunkOfBytes: 24.

	self assert: newAddress equals: freeLargeSpaceAddressBeforeAllocation
]

{ #category : #'tests-5-allocation-strategy' }
VMSpurOldSpaceTest >> testChildNodeShouldHaveRootAsParent [

	| smallerChild freeTreeRoot parentNode |
	memory freeChunkWithBytes: 800 at: (memory allocateOldSpaceChunkOfBytes: 800).
	freeTreeRoot := memory freeLists at: 0.
	smallerChild := memory fetchPointer: memory freeChunkSmallerIndex ofFreeChunk: freeTreeRoot.
	
	parentNode := memory fetchPointer: memory freeChunkParentIndex ofFreeChunk: smallerChild.
	
	self assert: parentNode equals: freeTreeRoot
]

{ #category : #'tests-5-allocation-strategy' }
VMSpurOldSpaceTest >> testChildSiblingNodesInFreeTreeShouldHavePrevious [

	| freeTreeRoot size child1 child2 nextChildOop child3 siblingOop previousOop |
	size := 800.
	child1 := memory allocateOldSpaceChunkOfBytes: size.
	child2 := memory allocateOldSpaceChunkOfBytes: size.
	child3 := memory allocateOldSpaceChunkOfBytes: size.	
	memory freeChunkWithBytes: size at: child1.
	memory freeChunkWithBytes: size at: child2.
	memory freeChunkWithBytes: size at: child3.
		
	freeTreeRoot := memory freeLists at: 0.

	nextChildOop := memory fetchPointer: memory freeChunkSmallerIndex ofFreeChunk: freeTreeRoot.
	previousOop := memory fetchPointer: memory freeChunkPrevIndex ofFreeChunk: nextChildOop.
	self assert: previousOop equals: 0.
	
	siblingOop := memory fetchPointer: memory freeChunkNextIndex ofFreeChunk: nextChildOop.
	previousOop := memory fetchPointer: memory freeChunkPrevIndex ofFreeChunk: siblingOop.
	self assert: previousOop equals: nextChildOop.

	siblingOop := memory fetchPointer: memory freeChunkNextIndex ofFreeChunk: nextChildOop.
	previousOop := memory fetchPointer: memory freeChunkPrevIndex ofFreeChunk: siblingOop.
	self assert: previousOop equals: nextChildOop.
]

{ #category : #'tests-5-allocation-strategy' }
VMSpurOldSpaceTest >> testChildSiblingNodesInFreeTreeShouldNotHaveLarger [

	| freeTreeRoot size child1 child2 nextChildOop child3 largerOop largerThanSmaller siblingOop |
	size := 800.
	child1 := memory allocateOldSpaceChunkOfBytes: size.
	child2 := memory allocateOldSpaceChunkOfBytes: size.
	child3 := memory allocateOldSpaceChunkOfBytes: size.	

	"Create a smaller than smaller chunk to check that this is not propagated to smaller siblings"
	largerThanSmaller := memory allocateOldSpaceChunkOfBytes: 808.

	memory freeChunkWithBytes: size at: child1.
	memory freeChunkWithBytes: size at: child2.
	memory freeChunkWithBytes: size at: child3.
	memory freeChunkWithBytes: 808 at: largerThanSmaller.
		
	freeTreeRoot := memory freeLists at: 0.

	nextChildOop := memory fetchPointer: memory freeChunkSmallerIndex ofFreeChunk: freeTreeRoot.
	largerOop := memory fetchPointer: memory freeChunkLargerIndex ofFreeChunk: nextChildOop.
	self assert: (memory startOfObject: largerOop) equals: largerThanSmaller.
	
	siblingOop := memory fetchPointer: memory freeChunkNextIndex ofFreeChunk: nextChildOop.
	largerOop := memory fetchPointer: memory freeChunkLargerIndex ofFreeChunk: siblingOop.
	self assert: largerOop equals: 0.

	siblingOop := memory fetchPointer: memory freeChunkNextIndex ofFreeChunk: siblingOop.
	largerOop := memory fetchPointer: memory freeChunkLargerIndex ofFreeChunk: siblingOop.
	self assert: largerOop equals: 0.
]

{ #category : #'tests-5-allocation-strategy' }
VMSpurOldSpaceTest >> testChildSiblingNodesInFreeTreeShouldNotHaveParent [

	| freeTreeRoot size child1 child2 nextChild child3 parentOop |
	size := 800.
	child1 := memory allocateOldSpaceChunkOfBytes: size.
	child2 := memory allocateOldSpaceChunkOfBytes: size.
	child3 := memory allocateOldSpaceChunkOfBytes: size.
	memory freeChunkWithBytes: size at: child1.
	memory freeChunkWithBytes: size at: child2.
	memory freeChunkWithBytes: size at: child3.
		
	freeTreeRoot := memory freeLists at: 0.

	nextChild := memory fetchPointer: memory freeChunkSmallerIndex ofFreeChunk: freeTreeRoot.
	parentOop := memory fetchPointer: memory freeChunkParentIndex ofFreeChunk: nextChild.
	self assert: parentOop equals: freeTreeRoot.
	
	nextChild := memory fetchPointer: memory freeChunkNextIndex ofFreeChunk: nextChild.
	parentOop := memory fetchPointer: memory freeChunkParentIndex ofFreeChunk: nextChild.
	self assert: parentOop equals: 0.

	nextChild := memory fetchPointer: memory freeChunkNextIndex ofFreeChunk: nextChild.
	parentOop := memory fetchPointer: memory freeChunkParentIndex ofFreeChunk: nextChild.
	self assert: parentOop equals: 0.
]

{ #category : #'tests-5-allocation-strategy' }
VMSpurOldSpaceTest >> testChildSiblingNodesInFreeTreeShouldNotHaveSmaller [

	| freeTreeRoot size child1 child2 nextChildOop child3 smallerOop smallerThanSmaller siblingOop |
	size := 800.
	child1 := memory allocateOldSpaceChunkOfBytes: size.
	child2 := memory allocateOldSpaceChunkOfBytes: size.
	child3 := memory allocateOldSpaceChunkOfBytes: size.	

	"Create a smaller than smaller chunk to check that this is not propagated to smaller siblings"
	smallerThanSmaller := memory allocateOldSpaceChunkOfBytes: 792.

	memory freeChunkWithBytes: size at: child1.
	memory freeChunkWithBytes: size at: child2.
	memory freeChunkWithBytes: size at: child3.
	memory freeChunkWithBytes: 792 at: smallerThanSmaller.
		
	freeTreeRoot := memory freeLists at: 0.

	nextChildOop := memory fetchPointer: memory freeChunkSmallerIndex ofFreeChunk: freeTreeRoot.
	smallerOop := memory fetchPointer: memory freeChunkSmallerIndex ofFreeChunk: nextChildOop.
	self assert: (memory startOfObject: smallerOop) equals: smallerThanSmaller.
	
	siblingOop := memory fetchPointer: memory freeChunkNextIndex ofFreeChunk: nextChildOop.
	smallerOop := memory fetchPointer: memory freeChunkSmallerIndex ofFreeChunk: siblingOop.
	self assert: smallerOop equals: 0.

	siblingOop := memory fetchPointer: memory freeChunkNextIndex ofFreeChunk: siblingOop.
	smallerOop := memory fetchPointer: memory freeChunkSmallerIndex ofFreeChunk: siblingOop.
	self assert: smallerOop equals: 0.
]

{ #category : #'tests-5-allocation-strategy' }
VMSpurOldSpaceTest >> testDeallocateShouldNotChangeRoot [

	| freeRoot address |	
	address := memory allocateOldSpaceChunkOfBytes: 800.

	freeRoot := memory freeLists at: 0.
	memory freeChunkWithBytes: 800 at: address.
	
	self assert: freeRoot equals: (memory freeLists at: 0)
]

{ #category : #'tests-5-allocation-strategy' }
VMSpurOldSpaceTest >> testEqualSizeChildNodeInFreeTreeShouldBeInsertedAfterHead [

	| smallerChild freeTreeRoot size child1 child2 nextChild child3 |
	size := 800.
	child1 := memory allocateOldSpaceChunkOfBytes: size.
	child2 := memory allocateOldSpaceChunkOfBytes: size.
	child3 := memory allocateOldSpaceChunkOfBytes: size.
	memory freeChunkWithBytes: size at: child1.
	memory freeChunkWithBytes: size at: child2.
	memory freeChunkWithBytes: size at: child3.
		
	freeTreeRoot := memory freeLists at: 0.
	smallerChild := memory fetchPointer: memory freeChunkSmallerIndex ofFreeChunk: freeTreeRoot.
	
	self assert: smallerChild equals: child1.
	nextChild := memory fetchPointer: memory freeChunkNextIndex ofFreeChunk: child1.
	self assert: nextChild equals: child3.
	nextChild := memory fetchPointer: memory freeChunkNextIndex ofFreeChunk: child3.
	self assert: nextChild equals: child2.
]

{ #category : #'tests-5-allocation-strategy' }
VMSpurOldSpaceTest >> testEqualSizeChildNodeShouldBeNextNode [

	| smallerChild freeTreeRoot size child1 child2 nextChild |
	size := 800.
	child1 := memory allocateOldSpaceChunkOfBytes: size.
	child2 := memory allocateOldSpaceChunkOfBytes: size.
	memory freeChunkWithBytes: size at: child1.
	memory freeChunkWithBytes: size at: child2.
		
	freeTreeRoot := memory freeLists at: 0.
	smallerChild := memory fetchPointer: memory freeChunkSmallerIndex ofFreeChunk: freeTreeRoot.
	
	self assert: smallerChild equals: child1.
	nextChild := memory fetchPointer: memory freeChunkNextIndex ofFreeChunk: child1.
	self assert: nextChild equals: child2.
]

{ #category : #'tests-3-free-lists' }
VMSpurOldSpaceTest >> testFreeAChunkShouldBePutAsHeadOfFreeList [
	| firstAddress secondAddress freeListHead chunkSize |
	chunkSize := 32.

	firstAddress := memory allocateOldSpaceChunkOfBytes: chunkSize.
	secondAddress := memory allocateOldSpaceChunkOfBytes: chunkSize.
	memory freeChunkWithBytes: chunkSize at: firstAddress.
	memory freeChunkWithBytes: chunkSize at: secondAddress.
	
	freeListHead := self freeListForSize: chunkSize.
	self assert: freeListHead equals: secondAddress
]

{ #category : #'tests-2-allocation-basic' }
VMSpurOldSpaceTest >> testFreeChunkDoesNotGetMergedWithExistingFreeChunks [

	| secondAddress |
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	memory freeChunkWithBytes: 160 at: secondAddress.

	self assert: memory allFreeObjects size equals: 2
]

{ #category : #'tests-3-free-lists' }
VMSpurOldSpaceTest >> testFreeChunkShouldKnowNextChunkOfSameSize [
	| firstAddress secondAddress freeListHead nextFreeChunk allocationSize |
	allocationSize := 32.
	
	firstAddress := memory allocateOldSpaceChunkOfBytes: allocationSize.
	secondAddress := memory allocateOldSpaceChunkOfBytes: allocationSize.
	memory freeChunkWithBytes: allocationSize at: firstAddress.
	memory freeChunkWithBytes: allocationSize at: secondAddress.
	
	freeListHead := self freeListForSize: allocationSize.
	nextFreeChunk := self nextNodeOf: freeListHead.

	self assert: nextFreeChunk equals: firstAddress
]

{ #category : #'tests-3-free-lists' }
VMSpurOldSpaceTest >> testFreeChunkShouldKnowPreviousChunkOfSameSize [
	| firstAddress secondAddress freeListHead nextFreeChunk allocationSize previousFreeChunk |
	allocationSize := 32.
	
	firstAddress := memory allocateOldSpaceChunkOfBytes: allocationSize.
	secondAddress := memory allocateOldSpaceChunkOfBytes: allocationSize.
	memory freeChunkWithBytes: allocationSize at: firstAddress.
	memory freeChunkWithBytes: allocationSize at: secondAddress.
	
	freeListHead := self freeListForSize: allocationSize.
	nextFreeChunk := self nextNodeOf: freeListHead.

	previousFreeChunk := self previousNodeOf: nextFreeChunk.
	self assert: previousFreeChunk equals: freeListHead
]

{ #category : #'tests-2-allocation-basic' }
VMSpurOldSpaceTest >> testFreeChunksWithSameSizeShouldBeListedAsDifferentFreeChunks [

	| secondAddress newAddress |
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	memory freeChunkWithBytes: 160 at: secondAddress.
	newAddress := memory allocateOldSpaceChunkOfBytes: 80.
	memory freeChunkWithBytes: 80 at: newAddress.
	
	self assert: memory allFreeObjects size equals: 3
]

{ #category : #'tests-3-free-lists' }
VMSpurOldSpaceTest >> testFreeChunksWithSameSizeShouldShareSingleHead [
	| secondAddress allocationSize firstAddress |
	allocationSize := 32.
	
	firstAddress := memory allocateOldSpaceChunkOfBytes: allocationSize.
	secondAddress := memory allocateOldSpaceChunkOfBytes: allocationSize.
	memory freeChunkWithBytes: allocationSize at: firstAddress.
	memory freeChunkWithBytes: allocationSize at: secondAddress.
	
	self assert: memory allFreeListHeads size equals: 1
]

{ #category : #'tests-3-free-lists' }
VMSpurOldSpaceTest >> testFreeListsShouldBeIndexedBySlotSize [

	| firstAddress freeListHead |
	
	2 to: memory numFreeLists - 1 do: [ :numberOfSlots | | byteSize |
		byteSize := numberOfSlots * memory allocationUnit.
		
		firstAddress := memory allocateOldSpaceChunkOfBytes: byteSize.
		memory freeChunkWithBytes: byteSize at: firstAddress.
	
		freeListHead := memory freeLists at: numberOfSlots.
		self assert: freeListHead equals: firstAddress
	]
]

{ #category : #'tests-1-startup' }
VMSpurOldSpaceTest >> testInitialFreeListShouldBeEmpty [

	2 to: memory numFreeLists - 1 do: [ :numberOfSlots |
		self
			assert: (memory freeLists at: numberOfSlots)
			equals: 0
	]
]

{ #category : #'tests-1-startup' }
VMSpurOldSpaceTest >> testInitialFreeTreeRootHasNoLargerNode [

	| bigChunk nextNode |
	bigChunk := self freeTreeRootOop.
	nextNode := self largerNodeOf: bigChunk.

	self assert: nextNode equals: 0.
]

{ #category : #'tests-1-startup' }
VMSpurOldSpaceTest >> testInitialFreeTreeRootHasNoNextNode [

	| bigChunk nextNode |
	bigChunk := self freeTreeRootOop.
	nextNode := self nextNodeOf: bigChunk.

	self assert: nextNode equals: 0.
]

{ #category : #'tests-1-startup' }
VMSpurOldSpaceTest >> testInitialFreeTreeRootHasNoParentNode [

	| bigChunk nextNode |
	bigChunk := self freeTreeRootOop.
	nextNode := self parentNodeOf: bigChunk.

	self assert: nextNode equals: 0.
]

{ #category : #'tests-1-startup' }
VMSpurOldSpaceTest >> testInitialFreeTreeRootHasNoPreviousNode [

	| bigChunk nextNode |
	bigChunk := self freeTreeRootOop.
	nextNode := self previousNodeOf: bigChunk.

	self assert: nextNode equals: 0.
]

{ #category : #'tests-1-startup' }
VMSpurOldSpaceTest >> testInitialFreeTreeRootHasNoSmallerNode [

	| bigChunk nextNode |
	bigChunk := self freeTreeRootOop.
	nextNode := self smallerNodeOf: bigChunk.

	self assert: nextNode equals: 0.
]

{ #category : #'tests-1-startup' }
VMSpurOldSpaceTest >> testInitialFreeTreeRootIsFreeObject [

	self assert: (memory isFreeObject: self freeTreeRootOop)
]

{ #category : #'tests-1-startup' }
VMSpurOldSpaceTest >> testInitialFreeTreeRootSizeShouldBeTotalFreeSpace [

	self
		assert: (memory bytesInObject: self freeTreeRootOop)
		equals: memory totalFreeListBytes
]

{ #category : #'tests-4-free-tree' }
VMSpurOldSpaceTest >> testLargeFreeChunkInFreeTreeNodeShouldStoreChunkOop [

	| firstAddress byteSize smallerNodeOop |
	
	byteSize := 256 "large chunk min size" * memory allocationUnit.
	firstAddress := memory allocateOldSpaceChunkOfBytes: byteSize.
	memory freeChunkWithBytes: byteSize at: firstAddress.
	
	smallerNodeOop := self smallerNodeOf: self freeTreeRootOop.
	self assert: (memory startOfObject: smallerNodeOop) equals: firstAddress
]

{ #category : #'tests-5-allocation-strategy' }
VMSpurOldSpaceTest >> testNewBigFreeChunkShouldBeFreeTreeChild [

	| firstAddress freeRoot rootSize moreThanHalf newRoot largerChildOop |
	freeRoot := memory freeLists at: 0.
	rootSize := memory bytesInObject: freeRoot.
	
	moreThanHalf := ((rootSize / memory allocationUnit) / 2) ceiling + 1 * memory allocationUnit.
	
	"Create a free chunk of more than half of the root, the root has changed"
	firstAddress := memory allocateOldSpaceChunkOfBytes: moreThanHalf.
	memory freeChunkWithBytes: moreThanHalf at: firstAddress.
	newRoot := memory freeLists at: 0.

	"Nodes in the free tree are organized as oops. Each oop points to the base header of the object"
	largerChildOop := memory fetchPointer: memory freeChunkLargerIndex ofFreeChunk: newRoot.
	"instead, the address returned by allocateOldSpaceChunkOfBytes: returns always an address, not an oop."
	"To get the real address where the oop starts use #startOfObject:"
	self assert: (memory startOfObject: largerChildOop) equals: firstAddress
]

{ #category : #'tests-5-allocation-strategy' }
VMSpurOldSpaceTest >> testNewBigFreeChunkShouldHaveRootAsParent [

	| firstAddress freeRoot rootSize moreThanHalf newRoot largerChildOop parentNodeOop |
	freeRoot := memory freeLists at: 0.
	rootSize := memory bytesInObject: freeRoot.
	
	moreThanHalf := ((rootSize / memory allocationUnit) / 2) ceiling + 1 * memory allocationUnit.
	self assert: moreThanHalf > (rootSize / 2).
	
	"Create a free chunk of more than half of the root, the root has changed"
	firstAddress := memory allocateOldSpaceChunkOfBytes: moreThanHalf.
	memory freeChunkWithBytes: moreThanHalf at: firstAddress.
	newRoot := memory freeLists at: 0.

	"Nodes in the free tree are organized as oops. Each oop points to the base header of the object"
	largerChildOop := memory fetchPointer: memory freeChunkLargerIndex ofFreeChunk: newRoot.
	parentNodeOop := memory fetchPointer: memory freeChunkParentIndex ofFreeChunk: largerChildOop.
	
	self assert: parentNodeOop equals: newRoot
]

{ #category : #'tests-1-startup' }
VMSpurOldSpaceTest >> testNewMemoryShouldHaveSingleFreeObject [

	self assert: memory allFreeObjects size equals: 1
]

{ #category : #'tests-2-allocation-basic' }
VMSpurOldSpaceTest >> testNewObjectShouldBeOld [
	
	| oop |
	oop := memory allocateSlotsInOldSpace: 0 format: 0 classIndex: self zeroSizedObjectClassIndex.
	
	self assert: (memory isOldObject: oop)
]

{ #category : #'tests-2-allocation-basic' }
VMSpurOldSpaceTest >> testPartiallyReusingFreeChunkShouldKeepNumberOfEntriesInFreeList [

	| secondAddress freeChunksBefore |
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.

	memory freeChunkWithBytes: 160 at: secondAddress.
	freeChunksBefore := memory allFreeObjects size.
	memory allocateOldSpaceChunkOfBytes: 80.
	
	self assert: memory allFreeObjects size equals: freeChunksBefore.
]

{ #category : #'tests-2-allocation-basic' }
VMSpurOldSpaceTest >> testReuseFreeChunkShouldRemoveEntryFromFreeList [

	| secondAddress |
	secondAddress := memory allocateOldSpaceChunkOfBytes: 160.
	memory freeChunkWithBytes: 160 at: secondAddress.
	memory allocateOldSpaceChunkOfBytes: 160.
	
	self assert: memory allFreeObjects size equals: 1
]

{ #category : #'tests-3-free-lists' }
VMSpurOldSpaceTest >> testSingleFreeChunkListNextShouldBeZero [
	| firstAddress freeListHead allocationSize |
	allocationSize := 32.

	firstAddress := memory allocateOldSpaceChunkOfBytes: allocationSize.
	memory freeChunkWithBytes: allocationSize at: firstAddress.

	freeListHead := self freeListForSize: allocationSize.
	self assert: (self nextNodeOf: freeListHead) equals: 0
]

{ #category : #'tests-3-free-lists' }
VMSpurOldSpaceTest >> testSingleFreeChunkListPreviousShouldBeZero [
	| firstAddress freeListHead allocationSize |
	allocationSize := 32.

	firstAddress := memory allocateOldSpaceChunkOfBytes: allocationSize.
	memory freeChunkWithBytes: allocationSize at: firstAddress.

	freeListHead := self freeListForSize: allocationSize.
	self assert: (self previousNodeOf: freeListHead) equals: 0
]

{ #category : #'tests-5-allocation-strategy' }
VMSpurOldSpaceTest >> testSmallerChildNodeShouldBeFreeTreeChild [

	| smallerChild freeTreeRoot parentNode smallerSize rootSize |
	smallerSize := 800.
	rootSize := memory bytesInObject: (memory freeLists at: 0).
	self assert: smallerSize < (rootSize / 2).

	memory freeChunkWithBytes: smallerSize at: (memory allocateOldSpaceChunkOfBytes: smallerSize).
	freeTreeRoot := memory freeLists at: 0.
	smallerChild := memory fetchPointer: memory freeChunkSmallerIndex ofFreeChunk: freeTreeRoot.
	
	parentNode := memory fetchPointer: memory freeChunkParentIndex ofFreeChunk: smallerChild.
	
	self assert: parentNode equals: freeTreeRoot
]
