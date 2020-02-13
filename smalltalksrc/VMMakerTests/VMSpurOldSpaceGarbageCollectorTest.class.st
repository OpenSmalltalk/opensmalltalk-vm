Class {
	#name : #VMSpurOldSpaceGarbageCollectorTest,
	#superclass : #VMSpurInitializedOldSpaceTest,
	#category : #VMMakerTests
}

{ #category : #testing }
VMSpurOldSpaceGarbageCollectorTest >> isValidFirstBridge [

	^ memory segmentManager
		isValidSegmentBridge: (memory segmentManager bridgeAt: 0)
]

{ #category : #tests }
VMSpurOldSpaceGarbageCollectorTest >> testAnOldObjectNotReferencedShouldGoToOblivion [

	| oldFreeSpaceSize |
	
	memory fullGC.
	oldFreeSpaceSize := memory totalFreeListBytes.
	1halt.	
	
	self newOldSpaceObjectWithSlots: 0.	
	memory fullGC.
	
	self assert: memory totalFreeListBytes equals: oldFreeSpaceSize.
]

{ #category : #tests }
VMSpurOldSpaceGarbageCollectorTest >> testAnOldObjectReferencedFromVMVariableShouldBeKeptAndNotMove [

	| anObjectOop |
	
	anObjectOop := self newOldSpaceObjectWithSlots: 0.

	self keepObjectInVMVariable1: anObjectOop.
	
	memory fullGC.
	
	self assert: anObjectOop equals: self keptObjectInVMVariable1
]
