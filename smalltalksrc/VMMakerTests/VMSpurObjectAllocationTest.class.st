Class {
	#name : #VMSpurObjectAllocationTest,
	#superclass : #VMSpurInitializedOldSpaceTest,
	#category : #'VMMakerTests-MemoryTests'
}

{ #category : #tests }
VMSpurObjectAllocationTest >> testAllocateObjectInNewSpaceMovesFreeStart [

	| oldFreeStart |
	oldFreeStart := memory freeStart.
	memory allocateSlots: 0 format: memory arrayFormat classIndex: memory arrayClassIndexPun.
	
	self assert: memory freeStart > oldFreeStart
]

{ #category : #tests }
VMSpurObjectAllocationTest >> testAllocateObjectInOldSpaceMovesFreeStart [

	| oldFreeStart |
	oldFreeStart := memory freeStart.
	memory
		allocateSlots: (memory scavengeThreshold / memory wordSize) floor + (memory wordSize * 2)
		format: memory arrayFormat
		classIndex: memory arrayClassIndexPun.
	
	self assert: memory freeStart equals: oldFreeStart
]
