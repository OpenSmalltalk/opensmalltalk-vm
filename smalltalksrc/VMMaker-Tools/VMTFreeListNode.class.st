Class {
	#name : #VMTFreeListNode,
	#superclass : #Object,
	#instVars : [
		'nodeOop',
		'memory'
	],
	#category : #'VMMaker-Tools'
}

{ #category : #'instance-creation' }
VMTFreeListNode class >> on: anOop memory: aMemory [
	
	anOop = 0 ifTrue: [ self halt ].
	^ self new
		memory: aMemory;
		nodeOop: anOop;
		yourself
]

{ #category : #accessing }
VMTFreeListNode >> address [
	
	^ memory startOfObject: nodeOop
]

{ #category : #accessing }
VMTFreeListNode >> children [
	
	^ self edges
]

{ #category : #accessing }
VMTFreeListNode >> edges [
	
	| edges |
	edges := OrderedCollection new.
	edges add: (VMTFreeTreeNodeEdge2 memory: memory label: 'Next' oop: self nextOop).
	edges add: (VMTFreeTreeNodeEdge2 memory: memory label: 'Previous' oop: self previousOop).
	^ edges
]

{ #category : #accessing }
VMTFreeListNode >> hasChildren [
	
	^ self nextOop ~= 0 or: [ self previousOop ~= 0 ]
]

{ #category : #accessing }
VMTFreeListNode >> memory [
	^ memory
]

{ #category : #accessing }
VMTFreeListNode >> memory: anObject [
	memory := anObject
]

{ #category : #accessing }
VMTFreeListNode >> nextOop [

	^ memory
		fetchPointer: memory freeChunkNextIndex
		ofFreeChunk: nodeOop
]

{ #category : #accessing }
VMTFreeListNode >> nodeOop [
	^ nodeOop
]

{ #category : #accessing }
VMTFreeListNode >> nodeOop: anObject [
	nodeOop := anObject
]

{ #category : #accessing }
VMTFreeListNode >> previousOop [

	^ memory
		fetchPointer: memory freeChunkPrevIndex
		ofFreeChunk: nodeOop
]

{ #category : #accessing }
VMTFreeListNode >> printOn: aStream [

	aStream
		nextPutAll: 'FreeTreeNode(';
		nextPutAll: nodeOop hex;
		nextPutAll: ')'
]

{ #category : #accessing }
VMTFreeListNode >> size [

	^ memory bytesInObject: nodeOop
]
