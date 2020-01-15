Class {
	#name : #VMSpurOldSpaceTest,
	#superclass : #VMSpurInitializedOldSpaceTest,
	#category : #VMMakerTests
}

{ #category : #tests }
VMSpurOldSpaceTest >> testNewObjectShouldBeOld [
	
	| oop |
	oop := memory allocateSlotsInOldSpace: 0 format: 0 classIndex: self zeroSizedObjectClassIndex.
	
	self assert: (memory isOldObject: oop)
]
