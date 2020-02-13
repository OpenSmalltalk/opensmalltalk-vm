Class {
	#name : #VMTFreeListNodeEdge,
	#superclass : #Object,
	#instVars : [
		'memory',
		'label',
		'nodeOop'
	],
	#category : #'VMMaker-Tools'
}

{ #category : #'instance-creation' }
VMTFreeListNodeEdge class >> memory: aMemory label: aLabel oop: anOop [
	
	^ self new
		memory: aMemory;
		label: aLabel;
		nodeOop: anOop;
		yourself
]

{ #category : #accessing }
VMTFreeListNodeEdge >> address [

	^ ''
]

{ #category : #accessing }
VMTFreeListNodeEdge >> children [
	
	^ { VMTFreeTreeNode on: nodeOop memory: memory }
]

{ #category : #accessing }
VMTFreeListNodeEdge >> hasChildren [
	
	^ nodeOop ~= 0
]

{ #category : #accessing }
VMTFreeListNodeEdge >> label [
	^ label
]

{ #category : #accessing }
VMTFreeListNodeEdge >> label: anObject [
	label := anObject
]

{ #category : #accessing }
VMTFreeListNodeEdge >> memory [
	^ memory
]

{ #category : #accessing }
VMTFreeListNodeEdge >> memory: anObject [
	memory := anObject
]

{ #category : #accessing }
VMTFreeListNodeEdge >> nodeOop [
	^ nodeOop
]

{ #category : #accessing }
VMTFreeListNodeEdge >> nodeOop: anObject [
	nodeOop := anObject
]

{ #category : #printing }
VMTFreeListNodeEdge >> printOn: aStream [

	aStream
		nextPutAll: label;
		nextPutAll: ' -> ';
		nextPutAll: nodeOop hex
]

{ #category : #accessing }
VMTFreeListNodeEdge >> size [

	^ ''
]
