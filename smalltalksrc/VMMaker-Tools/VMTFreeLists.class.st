Class {
	#name : #VMTFreeLists,
	#superclass : #Object,
	#instVars : [
		'memory'
	],
	#category : #'VMMaker-Tools'
}

{ #category : #'instance-creation' }
VMTFreeLists class >> on: aMemory [

	^ self new
		memory: aMemory;
		yourself
]

{ #category : #accessing }
VMTFreeLists >> children [
	
	| children |
	children := OrderedCollection new.
	children add: (VMTFreeTreeNodeEdge2 memory: memory label: 'Free Tree' oop: (memory freeLists at: 0)).
	children add: (VMTFreeTreeNodeEdge2 memory: memory label: 'Unused' oop: (memory freeLists at: 1)).
	2 to: 63 do: [ :i |
		children add: (VMTFreeListNodeEdge memory: memory label: 'Free Chunks of ', (i * 8) asString, ' bytes' oop: (memory freeLists at: i))].
	^ children
]

{ #category : #accessing }
VMTFreeLists >> memory: aMemory [
	memory := aMemory
]
