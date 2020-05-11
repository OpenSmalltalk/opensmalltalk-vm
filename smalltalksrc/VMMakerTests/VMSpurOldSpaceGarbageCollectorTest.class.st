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

	| oldFreeSpaceSize obj2 keptObjectSize |
	
	"The free objects are only reclaimed when there is a object after it. 
	For example if I have a free object and then only free space, the compactor assumes 
	that the heap is compacted, but it does not compact the free list. So the last free chunk is never 
	count on.
	This is a ""feature"" of the compactor. Changing the compactor strategy may change this behavior."
	
	memory fullGC.
	oldFreeSpaceSize := memory totalFreeListBytes.
	
	self newOldSpaceObjectWithSlots: 0.	
	obj2 := self newOldSpaceObjectWithSlots: 0.
	
	self keepObjectInVMVariable1: obj2.
	keptObjectSize := memory bytesInObject: obj2.
	
	memory fullGC.
	
	self assert: memory totalFreeListBytes equals: oldFreeSpaceSize - keptObjectSize.
]

{ #category : #tests }
VMSpurOldSpaceGarbageCollectorTest >> testAnOldObjectReferencedFromVMVariableShouldBeKept [
	| anObjectOop |
	
	anObjectOop := self newOldSpaceObjectWithSlots: 0.

	self keepObjectInVMVariable1: anObjectOop.
	
	memory fullGC.
	
	self deny: (memory isFreeObject: anObjectOop)
]

{ #category : #tests }
VMSpurOldSpaceGarbageCollectorTest >> testAnOldObjectReferencedFromVMVariableShouldBeNotMoved [

	| anObjectOop |
	
	anObjectOop := self newOldSpaceObjectWithSlots: 0.

	self keepObjectInVMVariable1: anObjectOop.
	
	memory fullGC.
	
	self assert: anObjectOop equals: self keptObjectInVMVariable1
]
