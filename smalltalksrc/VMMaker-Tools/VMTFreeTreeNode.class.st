Class {
	#name : #VMTFreeTreeNode,
	#superclass : #VMTFreeListNode,
	#category : #'VMMaker-Tools'
}

{ #category : #accessing }
VMTFreeTreeNode >> edges [
	
	| edges |
	edges := OrderedCollection new.
	edges add: (VMTFreeTreeNodeEdge2 memory: memory label: 'Smaller' oop: self smallerOop).
	edges add: (VMTFreeTreeNodeEdge2 memory: memory label: 'Larger' oop: self largerOop).
	^ edges
]

{ #category : #testing }
VMTFreeTreeNode >> hasChildren [
	
	^ self smallerOop ~= 0 or: [ self largerOop ~= 0 ]
]

{ #category : #accessing }
VMTFreeTreeNode >> largerOop [

	^ memory
		fetchPointer: memory freeChunkLargerIndex
		ofFreeChunk: nodeOop
]

{ #category : #accessing }
VMTFreeTreeNode >> smallerOop [
	
	^ memory
		fetchPointer: memory freeChunkSmallerIndex
		ofFreeChunk: nodeOop
]
