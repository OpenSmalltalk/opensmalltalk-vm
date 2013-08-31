Class {
	#name : #ShootoutTreeNode,
	#superclass : #Object,
	#instVars : [
		'left',
		'right',
		'item'
	],
	#category : #'Cog-Benchmarks'
}

{ #category : #'instance creation' }
ShootoutTreeNode class >> bottomUpTree: anItem depth: anInteger [
	^(anInteger > 0)
		ifTrue: [
			self
				left: (self bottomUpTree: 2*anItem - 1 depth: anInteger - 1)
				right: (self bottomUpTree: 2*anItem depth: anInteger - 1) 
				item: anItem
			]
		ifFalse: [self left: nil right: nil item: anItem]
]

{ #category : #'instance creation' }
ShootoutTreeNode class >> left: leftChild right: rightChild item: anItem [
	^(super new) left: leftChild right: rightChild item: anItem
]

{ #category : #accessing }
ShootoutTreeNode >> itemCheck [
	^left isNil
		ifTrue: [item] ifFalse: [item + (left itemCheck - right itemCheck)]
]

{ #category : #'initialize-release' }
ShootoutTreeNode >> left: leftChild right: rightChild item: anItem [
	left := leftChild.
	right := rightChild.
	item := anItem
]
