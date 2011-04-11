"
A TNotImplementedNode is a translation node for a parse node that cannot be translated, or for which translation is not yet implemented.

"
Class {
	#name : #TNotImplementedNode,
	#superclass : #TParseNode,
	#instVars : [
		'parseNode'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #accessing }
TNotImplementedNode >> parseNode [
	"Answer the value of parseNode"

	^ parseNode
]

{ #category : #accessing }
TNotImplementedNode >> parseNode: anObject [
	"Set the value of parseNode"

	parseNode := anObject
]
