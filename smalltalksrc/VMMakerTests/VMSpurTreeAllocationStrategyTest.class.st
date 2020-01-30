Class {
	#name : #VMSpurTreeAllocationStrategyTest,
	#superclass : #VMSpurInitializedOldSpaceTest,
	#instVars : [
		'sizesInBreadthFirstOrder',
		'chunkAddresses'
	],
	#category : #VMMakerTests
}

{ #category : #accessing }
VMSpurTreeAllocationStrategyTest >> addressOfChunkOf: aSize [

	^ chunkAddresses at: aSize
]

{ #category : #running }
VMSpurTreeAllocationStrategyTest >> setUp [

	"          1120
	          /    \
	      1056     1184
	      /   \    /   \
	  1024  1088  1152  1216
	"
	| parent childNumber |
	
	super setUp.
	
	chunkAddresses := Dictionary new.
	1024 to: 1216 by: 32 do: [ :size |
		chunkAddresses at: size put: (memory allocateOldSpaceChunkOfBytes: size)
	].
	"Allocate the rest of the memory so it does not bother our test."
	memory allocateOldSpaceChunkOfBytes: memory totalFreeListBytes.

	sizesInBreadthFirstOrder := #( 1120 1056 1184 1024 1088 1152 1216 ).
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
VMSpurTreeAllocationStrategyTest >> sizeOfChildInBreadthFirstOrder: anInteger [ 

	^ sizesInBreadthFirstOrder at: anInteger
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test01AllocateBestFitTreeRootWithChildrenShouldReplaceNodeWithSmaller [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 1) - 16.
	
	self assert: (memory bytesInObject: self freeTreeRootOop) equals: (self sizeOfChildInBreadthFirstOrder: 2)
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyTest >> test01AllocateExactTreeRootWithChildrenShouldReplaceNodeWithSmaller [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 1).
	
	self assert: (memory bytesInObject: self freeTreeRootOop) equals: (self sizeOfChildInBreadthFirstOrder: 2)
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test01AllocateSmallerThanLiliputianDiffFromTreeRootWithChildrenShouldUseLargerThanRoot [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 1) - 8.
	
	"Reuse node of 1152 bytes"
	self assert: (self smallerNodeOf: (self largerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test02AllocateBestFitTreeRootWithChildrenShouldReInsertSmallerLargerChildFromRoot [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 1) - 16.

	self assert: (memory bytesInObject: (self largerNodeOf: self freeTreeRootOop)) equals: (self sizeOfChildInBreadthFirstOrder: 5)
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyTest >> test02AllocateExactTreeRootWithChildrenShouldReInsertSmallerLargerChildFromRoot [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 1).

	self assert: (memory bytesInObject: (self largerNodeOf: self freeTreeRootOop)) equals: (self sizeOfChildInBreadthFirstOrder: 5)
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test02AllocateSmallerThanLiliputianDiffFromTreeRootWithChildrenShouldInsertLeftOverInFreeList [

	| allocatedSize |
	allocatedSize := (self sizeOfChildInBreadthFirstOrder: 1) - 8.
	memory allocateOldSpaceChunkOfBytes: allocatedSize.
	
	"Reuse node of 1152 bytes to allocate 1112, leaving 40 left over bytes in free tree"
	self denyFreeListEmpty: (self freeListForSize: 1152 - allocatedSize).
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test03AllocateBestFitTreeRootWithChildrenShouldReplaceSmallerChildWithSmallerSmaller [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 1) - 16.
	
	self assert: (memory bytesInObject: (self smallerNodeOf: self freeTreeRootOop)) equals: (self sizeOfChildInBreadthFirstOrder: 4)
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyTest >> test03AllocateExactTreeRootWithChildrenShouldReplaceSmallerChildWithSmallerSmaller [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 1).
	
	self assert: (memory bytesInObject: (self smallerNodeOf: self freeTreeRootOop)) equals: (self sizeOfChildInBreadthFirstOrder: 4)
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test03AllocateSmallerThanLiliputianDiffFromTreeRootWithChildrenShouldUseLargerThanRootAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self addressOfChunkOf: 1152.
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 1) - 8.
	
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test04AllocateBestFitTreeRootWithChildrenShouldInsertLiliputianInFreeList [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 1) - 16.
	
	self denyFreeListEmpty: (self freeListForSize: 16)
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyTest >> test04AllocateExactSmallerTreeNodeShouldReplaceNodeWithSmaller [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 2).

	self assert: (memory bytesInObject: (self smallerNodeOf: self freeTreeRootOop)) equals: (self sizeOfChildInBreadthFirstOrder: 4)
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test04AllocateSmallerThanLiliputianDiffFromSmallerWithChildrenShouldUseLargestSmallerThanRoot [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 2) - 8.
	
	"Reuse node of 1088 bytes"
	self assert: (self largerNodeOf: (self smallerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test05AllocateBestFitSmallerTreeNodeShouldReplaceNodeWithSmaller [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 2) - 16.

	self assert: (memory bytesInObject: (self smallerNodeOf: self freeTreeRootOop)) equals: (self sizeOfChildInBreadthFirstOrder: 4)
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyTest >> test05AllocateExactSmallerTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self smallerNodeOf: self freeTreeRootOop.
	
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 2).
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test05AllocateSmallerThanLiliputianDiffFromSmallerWithChildrenShouldInsertLeftOverInFreeList [

	| allocatedSize |
	allocatedSize := (self sizeOfChildInBreadthFirstOrder: 2) - 8.
	memory allocateOldSpaceChunkOfBytes: allocatedSize.
	
	"Reuse node of 1088 bytes to allocate 1048, leaving 40 left over bytes in free tree"
	self denyFreeListEmpty: (self freeListForSize: 1088 - allocatedSize)
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test06AllocateBestFitSmallerTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self smallerNodeOf: self freeTreeRootOop.
	
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 2) - 16.
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyTest >> test06AllocateExactBiggerTreeNodeShouldReplaceNodeWithSmaller [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 3).
	
	self assert: (memory bytesInObject: (self largerNodeOf: self freeTreeRootOop)) equals: (self sizeOfChildInBreadthFirstOrder: 6)
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test06AllocateSmallerThanLiliputianDiffFromSmallerWithChildrenShouldUseSmallerThanRootAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self addressOfChunkOf: 1088.
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 2) - 8.
	
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test07AllocateBestFitSmallerTreeNodeShouldInsertLiliputianInFreeList [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 2) - 16.
	
	self denyFreeListEmpty: (self freeListForSize: 16)
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyTest >> test07AllocateExactBiggerTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self largerNodeOf: self freeTreeRootOop.
	
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 3).
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test07AllocateSmallerThanLiliputianDiffFromSmallerLeafShouldUseIntermediateNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 4) - 8.
	
	"Reuse node of 1056 bytes, move the node of 1024 up, and reinsert the node of 1088"
	self assert: (memory bytesInObject: (self smallerNodeOf: self freeTreeRootOop)) equals: 1024.
	self assert: (memory bytesInObject: (self largerNodeOf: (self smallerNodeOf: self freeTreeRootOop))) equals: 1088
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyTest >> test08AllocateExactSmallerOfSmallerLeafTreeNodeShouldRemoveNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 4).

	self assert: (self smallerNodeOf: (self smallerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test08AllocateSmallerThanLiliputianDiffFromSmallerLeafShouldInsertLeftOverInFreeList [
	| allocatedSize |
	allocatedSize :=  (self sizeOfChildInBreadthFirstOrder: 4) - 8.
	memory allocateOldSpaceChunkOfBytes: allocatedSize.
	
	"Reuse node of 1056 bytes to allocate 1016, leaving 40 left over bytes in free tree"
	self denyFreeListEmpty: (self freeListForSize: 1056 - allocatedSize).
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyTest >> test09AllocateExactSmallerOfSmallerLeafTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self smallerNodeOf: (self smallerNodeOf: self freeTreeRootOop).
	
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 4).
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test09AllocateSecondSmallerThanLiliputianDiffFromSmallerLeafShouldUseRootNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 5) - 8.
	
	"Reuse node of 1120 bytes to allocate 1080, move the node of 1056 up as root, and reinsert the node of 1184 on the right"
	self assert: (memory bytesInObject: self freeTreeRootOop) equals: 1056.
	self assert: (memory bytesInObject: (self largerNodeOf: (self largerNodeOf: self freeTreeRootOop))) equals: 1184
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyTest >> test10AllocateExactLargerOfSmallerLeafTreeNodeShouldRemoveNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 5).
	
	self assert: (self largerNodeOf: (self smallerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test10AllocateSecondSmallerThanLiliputianDiffFromSmallerLeafShouldInsertLeftOverInFreeList [

	| allocatedSize |
	allocatedSize := (self sizeOfChildInBreadthFirstOrder: 5) - 8.
	memory allocateOldSpaceChunkOfBytes: allocatedSize.
	
	"Reuse node of 1120 bytes to allocate 1080, leaving 40 left over bytes in free tree"
	self denyFreeListEmpty: (self freeListForSize: 1120 - allocatedSize).
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyTest >> test11AllocateExactLargerOfSmallerLeafTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self largerNodeOf: (self smallerNodeOf: self freeTreeRootOop).
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 5).
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test11AllocateSmallerThanLiliputianDiffFromLargerWithChildrenShouldUseLargestLeafNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 3) - 8.
	
	"Reuse node of 1216 bytes to allocate 1176, removing it from the tree"
	self assert: (self largerNodeOf: (self largerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyTest >> test12AllocateExactSmallerOfLargerLeafTreeNodeShouldRemoveNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 6).

	self assert: (self smallerNodeOf: (self largerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test12AllocateSmallerThanLiliputianDiffFromLargerWithChildrenShouldInsertLeftOverInFreeList [

	| allocatedSize |
	
	allocatedSize := (self sizeOfChildInBreadthFirstOrder: 3) - 8.
	memory allocateOldSpaceChunkOfBytes: allocatedSize.
	
	"Reuse node of 1216 bytes to allocate 1176, leaving 40 left over bytes in free tree"
	self denyFreeListEmpty: (self freeListForSize: 1216 - allocatedSize).
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyTest >> test13AllocateExactSmallerOfLargerLeafTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self smallerNodeOf: (self largerNodeOf: self freeTreeRootOop).
	
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 6).
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test13AllocateSmallerThanLiliputianDiffFromSmallerLeafInLargerSideShouldUseIntermediateLargerNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 6) - 8.
	
	"Reuse node of 1184 bytes to allocate 1144, moving up the child of 1152"
	self assert: (memory bytesInObject: (self largerNodeOf: self freeTreeRootOop)) equals: 1152
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyTest >> test14AllocateExactLargerOfLargerLeafTreeNodeShouldRemoveChildNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 7).
	
	self assert: (self largerNodeOf: (self largerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test14AllocateSmallerThanLiliputianDiffFromSmallerLeafInLargerSideShouldInsertLeftOverInFreeList [

	| allocatedSize |
	
	allocatedSize := (self sizeOfChildInBreadthFirstOrder: 6) - 8.
	memory allocateOldSpaceChunkOfBytes: allocatedSize.
	
	"Reuse node of 1184 bytes to allocate 1144, moving up the child of 1152"
	self denyFreeListEmpty: (self freeListForSize: 1184 - allocatedSize).
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test15AllocateBestFitBiggerTreeNodeShouldReplaceNodeWithSmaller [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 3) - 16.
	
	self assert: (memory bytesInObject: (self largerNodeOf: self freeTreeRootOop)) equals: (self sizeOfChildInBreadthFirstOrder: 6)
]

{ #category : #'tests-09-exact-fit' }
VMSpurTreeAllocationStrategyTest >> test15AllocateExactLargerOfLargerLeafTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self largerNodeOf: (self largerNodeOf: self freeTreeRootOop).
	
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 7).
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-11-bestfit-smaller-than-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test15AllocateSmallerThanLiliputianDiffFromLargestLeaShouldFindNoMemory [

	self assert: (memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 7) - 8) equals: nil
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test16AllocateBestFitBiggerTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self largerNodeOf: self freeTreeRootOop.
	
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 3)  - 16.
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test17AllocateBestFitLargerTreeNodeShouldInsertLiliputianInFreeList [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 3) - 16.
	
	self denyFreeListEmpty: (self freeListForSize: 16)
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test20AllocateBestFitSmallerOfSmallerLeafTreeNodeShouldRemoveNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 4) - 16.

	self assert: (self smallerNodeOf: (self smallerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test21AllocateBestFitSmallerOfSmallerLeafTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self smallerNodeOf: (self smallerNodeOf: self freeTreeRootOop).
	
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 4) - 16.
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test22AllocateBestFitSmallerOfSmallerLeafTreeNodeShouldInsertLiliputianInFreeList [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 4) - 16.
	
	self denyFreeListEmpty: (self freeListForSize: 16)
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test25AllocateBestFitLargerOfSmallerLeafTreeNodeShouldRemoveNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 5) - 16.
	
	self assert: (self largerNodeOf: (self smallerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test26AllocateBestFitLargerOfSmallerLeafTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self largerNodeOf: (self smallerNodeOf: self freeTreeRootOop).
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 5) - 16.
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test27AllocateBestFitLargerOfSmallerLeafTreeNodeShouldShouldInsertLiliputianInFreeList [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 5) - 16.
	
	self denyFreeListEmpty: (self freeListForSize: 16)
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test30AllocateBestFitSmallerOfLargerLeafTreeNodeShouldRemoveNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 6) - 16.

	self assert: (self smallerNodeOf: (self largerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test31AllocateBestFitSmallerOfLargerLeafTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self smallerNodeOf: (self largerNodeOf: self freeTreeRootOop).
	
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 6) - 16.
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test32AllocateBestFitSmallerOfLargerLeafTreeNodeShouldInsertLiliputianInFreeList [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 6) - 16.

	self denyFreeListEmpty: (self freeListForSize: 16)
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test35AllocateBestFitLargerOfLargerLeafTreeNodeShouldRemoveChildNode [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 7) - 16.

	self assert: (self largerNodeOf: (self largerNodeOf: self freeTreeRootOop)) equals: 0
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test36AllocateBestFitLargerOfLargerLeafTreeNodeShouldReuseNodeAddress [

	| desiredAddress allocatedAddress |
	desiredAddress := self largerNodeOf: (self largerNodeOf: self freeTreeRootOop).
	
	allocatedAddress := memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 7) - 16.
	self assert: allocatedAddress equals: desiredAddress
]

{ #category : #'tests-10-bestfit-liliputian-leftovers' }
VMSpurTreeAllocationStrategyTest >> test37AllocateBestFitLargerOfLargerLeafTreeNodeShouldInsertLiliputianInFreeList [

	memory allocateOldSpaceChunkOfBytes: (self sizeOfChildInBreadthFirstOrder: 7) - 16.
	
	self denyFreeListEmpty: (self freeListForSize: 16)
]
