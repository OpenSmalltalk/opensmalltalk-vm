Class {
	#name : #VMSpurTreeAllocationStrategyForSmallTreeTest,
	#superclass : #VMSpurInitializedOldSpaceTest,
	#instVars : [
		'sizesInBreadthFirstOrder',
		'chunkAddresses'
	],
	#category : #'VMMakerTests-MemoryTests'
}

{ #category : #accessing }
VMSpurTreeAllocationStrategyForSmallTreeTest >> addressOfChunkOf: aSize [

	^ chunkAddresses at: aSize
]

{ #category : #running }
VMSpurTreeAllocationStrategyForSmallTreeTest >> setUp [

	super setUp.
	self setUpTree.
]

{ #category : #running }
VMSpurTreeAllocationStrategyForSmallTreeTest >> setUpTree [

	"          560
	          /    \
	       528     592
	      /   \    /   \
	  512    544  576  608
	"
	| parent childNumber |
	
	chunkAddresses := Dictionary new.
	512 to: 608 by: 16 do: [ :size |
		chunkAddresses at: size put: (memory allocateOldSpaceChunkOfBytes: size)
	].
	"Allocate the rest of the memory so it does not bother our test."
	memory allocateOldSpaceChunkOfBytes: memory totalFreeListBytes.

	sizesInBreadthFirstOrder := #( 560 528 592 512 544 576 608).
	sizesInBreadthFirstOrder do: [ :e |
		memory freeChunkWithBytes: e at: (chunkAddresses at: e) ].
	
	
	parent := self freeTreeRootOop.
	childNumber := 1.
	self assert: (memory bytesInObject: parent) equals: (sizesInBreadthFirstOrder at: childNumber).
	self assert: (memory bytesInObject: (self smallerNodeOf: parent)) equals: (sizesInBreadthFirstOrder at: childNumber * 2).
	self assert: (memory bytesInObject: (self largerNodeOf: parent)) equals: (sizesInBreadthFirstOrder at: childNumber * 2 + 1).
	
	parent := self smallerNodeOf: self freeTreeRootOop.
	childNumber := 2.
	self assert: (memory bytesInObject: (self smallerNodeOf: parent)) equals: (sizesInBreadthFirstOrder at: childNumber * 2).
	self assert: (memory bytesInObject: (self largerNodeOf: parent)) equals: (sizesInBreadthFirstOrder at: childNumber * 2 + 1).
	
	parent := self largerNodeOf: self freeTreeRootOop.
	childNumber := 3.
	self assert: (memory bytesInObject: (self smallerNodeOf: parent)) equals: (sizesInBreadthFirstOrder at: childNumber * 2).
	self assert: (memory bytesInObject: (self largerNodeOf: parent)) equals: (sizesInBreadthFirstOrder at: childNumber * 2 + 1).
]

{ #category : #accessing }
VMSpurTreeAllocationStrategyForSmallTreeTest >> sizeOfChildInBreadthFirstOrder: anInteger [ 

	^ sizesInBreadthFirstOrder at: anInteger
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test01AllocateExactTreeRootWithChildrenShouldReplaceNodeWithSmaller [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 1).
	
	self assert: (memory bytesInObject: self freeTreeRootOop) equals: (self sizeOfChildInBreadthFirstOrder: 2)
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test01AllocateSmallerThanLiliputianDiffFromTreeRootWithChildrenShouldUseLargerThanRoot [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 1) - 8.
	
	"Reuse node of 1152 bytes"
	self assert: (self smallerNodeOf: (self largerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test02AllocateExactTreeRootWithChildrenShouldReInsertSmallerLargerChildFromRoot [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 1).

	self assert: (memory bytesInObject: (self largerNodeOf: self freeTreeRootOop)) equals: (self sizeOfChildInBreadthFirstOrder: 5)
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test02AllocateSmallerThanLiliputianDiffFromTreeRootWithChildrenShouldInsertLeftOverInFreeList [

	| allocatedSize |
	allocatedSize := (self sizeOfChildInBreadthFirstOrder: 1) - 8.
	memory allocateOldSpaceChunkOfBytes: allocatedSize.
	
	"Reuse node of 1152 bytes to allocate 1112, leaving 40 left over bytes in free tree"
	self denyFreeListEmpty: (self freeListForSize: 1152 - allocatedSize).
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test03AllocateExactTreeRootWithChildrenShouldReplaceSmallerChildWithSmallerSmaller [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 1).
	
	self assert: (memory bytesInObject: (self smallerNodeOf: self freeTreeRootOop)) equals: (self sizeOfChildInBreadthFirstOrder: 4)
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test03AllocateSmallerThanLiliputianDiffFromTreeRootWithChildrenShouldUseLargerThanRootAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self addressOfChunkOf: (self sizeOfChildInBreadthFirstOrder: 6).
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 1) - 8.
	
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test04AllocateExactSmallerTreeNodeShouldReplaceNodeWithSmaller [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 2).

	self assert: (memory bytesInObject: (self smallerNodeOf: self freeTreeRootOop)) equals: (self sizeOfChildInBreadthFirstOrder: 4)
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test04AllocateSmallerThanLiliputianDiffFromSmallerWithChildrenShouldUseLargestSmallerThanRoot [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 2) - 8.
	
	"Reuse node of 1088 bytes"
	self assert: (self largerNodeOf: (self smallerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test05AllocateExactSmallerTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := memory startOfObject: (self smallerNodeOf: self freeTreeRootOop).
	
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 2).
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test05AllocateSmallerThanLiliputianDiffFromSmallerWithChildrenShouldInsertLeftOverInFreeList [

	| allocatedSize |
	allocatedSize := (self sizeOfChildInBreadthFirstOrder: 2) - 8.
	memory allocateOldSpaceChunkOfBytes: allocatedSize.
	
	"Reuse node of 1088 bytes to allocate 1048, leaving 40 left over bytes in free tree"
	self denyFreeListEmpty: (self freeListForSize: 1088 - allocatedSize)
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test06AllocateExactBiggerTreeNodeShouldReplaceNodeWithSmaller [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 3).
	
	self assert: (memory bytesInObject: (self largerNodeOf: self freeTreeRootOop)) equals: (self sizeOfChildInBreadthFirstOrder: 6)
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test06AllocateSmallerThanLiliputianDiffFromSmallerWithChildrenShouldUseSmallerThanRootAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self addressOfChunkOf: (self sizeOfChildInBreadthFirstOrder: 5).
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 2) - 8.
	
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test07AllocateExactBiggerTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := memory startOfObject: (self largerNodeOf: self freeTreeRootOop).
	
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 3).
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test07AllocateSmallerThanLiliputianDiffFromSmallerLeafShouldUseIntermediateNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 4) - 8.
	
	"Reuse node 2, move the node 4 up, and reinsert the node 5"
	self assert: (memory bytesInObject: (self smallerNodeOf: self freeTreeRootOop)) equals: (self sizeOfChildInBreadthFirstOrder: 4).
	self assert: (memory bytesInObject: (self largerNodeOf: (self smallerNodeOf: self freeTreeRootOop))) equals: (self sizeOfChildInBreadthFirstOrder: 5)
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test08AllocateExactSmallerOfSmallerLeafTreeNodeShouldRemoveNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 4).

	self assert: (self smallerNodeOf: (self smallerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test08AllocateSmallerThanLiliputianDiffFromSmallerLeafShouldInsertLeftOverInFreeList [
	| allocatedSize |
	allocatedSize :=  (self sizeOfChildInBreadthFirstOrder: 4) - 8.
	memory allocateOldSpaceChunkOfBytes: allocatedSize.
	
	"Reuse node of 1056 bytes to allocate 1016, leaving 40 left over bytes in free tree"
	self denyFreeListEmpty: (self freeListForSize: 1056 - allocatedSize).
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test09AllocateExactSmallerOfSmallerLeafTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self smallerNodeOf: (self smallerNodeOf: self freeTreeRootOop).
	
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 4).
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test09AllocateSecondSmallerThanLiliputianDiffFromSmallerLeafShouldUseRootNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 5) - 8.
	
	"Reuse node 1, move the node of 2 up as root, and reinsert the node 3 on the right"
	self assert: (memory bytesInObject: self freeTreeRootOop) equals: (self sizeOfChildInBreadthFirstOrder: 2).
	self assert: (memory bytesInObject: (self largerNodeOf: (self largerNodeOf: self freeTreeRootOop))) equals: (self sizeOfChildInBreadthFirstOrder: 3)
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test10AllocateExactLargerOfSmallerLeafTreeNodeShouldRemoveNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 5).
	
	self assert: (self largerNodeOf: (self smallerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test10AllocateSecondSmallerThanLiliputianDiffFromSmallerLeafShouldInsertLeftOverInFreeList [

	| allocatedSize |
	allocatedSize := (self sizeOfChildInBreadthFirstOrder: 5) - 8.
	memory allocateOldSpaceChunkOfBytes: allocatedSize.
	
	"Reuse node of 1120 bytes to allocate 1080, leaving 40 left over bytes in free tree"
	self denyFreeListEmpty: (self freeListForSize: 1120 - allocatedSize).
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test11AllocateExactLargerOfSmallerLeafTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := memory startOfObject: (self largerNodeOf: (self smallerNodeOf: self freeTreeRootOop)).
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 5).
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test11AllocateSmallerThanLiliputianDiffFromLargerWithChildrenShouldUseLargestLeafNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 3) - 8.
	
	"Reuse node of 1216 bytes to allocate 1176, removing it from the tree"
	self assert: (self largerNodeOf: (self largerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test12AllocateExactSmallerOfLargerLeafTreeNodeShouldRemoveNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 6).

	self assert: (self smallerNodeOf: (self largerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test12AllocateSmallerThanLiliputianDiffFromLargerWithChildrenShouldInsertLeftOverInFreeList [

	| allocatedSize |
	
	allocatedSize := (self sizeOfChildInBreadthFirstOrder: 3) - 8.
	memory allocateOldSpaceChunkOfBytes: allocatedSize.
	
	"Reuse node of 1216 bytes to allocate 1176, leaving 40 left over bytes in free tree"
	self denyFreeListEmpty: (self freeListForSize: 1216 - allocatedSize).
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test13AllocateExactSmallerOfLargerLeafTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := memory startOfObject: (self smallerNodeOf: (self largerNodeOf: self freeTreeRootOop)).
	
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 6).
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test13AllocateSmallerThanLiliputianDiffFromSmallerLeafInLargerSideShouldUseIntermediateLargerNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 6) - 8.
	
	"Reuse node 3, moving up the child 6"
	self assert: (memory bytesInObject: (self largerNodeOf: self freeTreeRootOop)) equals: (self sizeOfChildInBreadthFirstOrder: 6)
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test14AllocateExactLargerOfLargerLeafTreeNodeShouldRemoveChildNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 7).
	
	self assert: (self largerNodeOf: (self largerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test14AllocateSmallerThanLiliputianDiffFromSmallerLeafInLargerSideShouldInsertLeftOverInFreeList [

	| allocatedSize |
	
	allocatedSize := (self sizeOfChildInBreadthFirstOrder: 6) - 8.
	memory allocateOldSpaceChunkOfBytes: allocatedSize.
	
	"Reuse node of 1184 bytes to allocate 1144, moving up the child of 1152"
	self denyFreeListEmpty: (self freeListForSize: 1184 - allocatedSize).
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test15AllocateExactLargerOfLargerLeafTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := memory startOfObject: (self largerNodeOf: (self largerNodeOf: self freeTreeRootOop)).
	
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 7).
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyForSmallTreeTest >> test15AllocateSmallerThanLiliputianDiffFromLargestLeaShouldFindNoMemory [

	self assert: (memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 7) - 8) equals: nil
]
