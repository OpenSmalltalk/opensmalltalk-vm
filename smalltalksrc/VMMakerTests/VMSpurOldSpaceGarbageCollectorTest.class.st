Class {
	#name : #VMSpurOldSpaceGarbageCollectorTest,
	#superclass : #VMSpurInitializedOldSpaceTest,
	#category : #VMMakerTests
}

{ #category : #tests }
VMSpurOldSpaceGarbageCollectorTest >> testAnOldObjectReferencedFromVMVariableShouldBeKept [

	| anObjectOop |
	
	anObjectOop := self newOldSpaceObjectWithSlots: 0.

	self keepObjectInVMVariable1: anObjectOop.
	
	memory fullGC.
	
	self assert: anObjectOop equals: self keptObjectInVMVariable1
]
