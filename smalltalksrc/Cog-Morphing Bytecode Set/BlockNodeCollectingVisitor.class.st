Class {
	#name : #BlockNodeCollectingVisitor,
	#superclass : #ParseNodeVisitor,
	#instVars : [
		'blockNodes'
	],
	#category : #'Cog-Scripts'
}

{ #category : #accessing }
BlockNodeCollectingVisitor >> blockNodes [
	^blockNodes
]

{ #category : #visiting }
BlockNodeCollectingVisitor >> visitBlockNode: aBlockNode [
	(blockNodes ifNil: [blockNodes := OrderedCollection new]) addLast: aBlockNode.
	super visitBlockNode: aBlockNode
]
