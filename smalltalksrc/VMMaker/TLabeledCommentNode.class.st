Class {
	#name : #TLabeledCommentNode,
	#superclass : #TParseNode,
	#instVars : [
		'label'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'as yet unclassified' }
TLabeledCommentNode >> copyTree [

	^self class new
		setLabel: label
		comment: comment
]

{ #category : #'as yet unclassified' }
TLabeledCommentNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	"Emit a C comment with optional label."

	self printOptionalLabelOn: aStream.
	aStream nextPutAll: '/* '.
	aStream nextPutAll: comment.
	aStream nextPutAll: ' */'.
]

{ #category : #'as yet unclassified' }
TLabeledCommentNode >> isComment [
	"Answer true if the receiver is just a comment (i.e., it has no label)."

	^label = nil
]

{ #category : #'as yet unclassified' }
TLabeledCommentNode >> isLabel [

	^true
]

{ #category : #'as yet unclassified' }
TLabeledCommentNode >> isLeaf [

	^true
]

{ #category : #'as yet unclassified' }
TLabeledCommentNode >> label [

	^label
]

{ #category : #'as yet unclassified' }
TLabeledCommentNode >> printOn: aStream level: level [

	self printOptionalLabelOn: aStream.
	aStream nextPut: $".
	aStream nextPutAll: comment.
	aStream nextPut: $".
]

{ #category : #'as yet unclassified' }
TLabeledCommentNode >> printOptionalLabelOn: aStream [

	label ~= nil ifTrue: [
		self unindentOneTab: aStream.
		aStream nextPutAll: label.
		aStream nextPut: $:.
		aStream tab.	
	].
]

{ #category : #'as yet unclassified' }
TLabeledCommentNode >> setComment: commentString [

	label := nil.
	comment := commentString.
]

{ #category : #'as yet unclassified' }
TLabeledCommentNode >> setLabel: labelString [

	label := labelString.
]

{ #category : #'as yet unclassified' }
TLabeledCommentNode >> setLabel: labelString comment: commentString [

	label := labelString.
	comment := commentString.
]

{ #category : #'as yet unclassified' }
TLabeledCommentNode >> unindentOneTab: aStream [
	"Remove the last tab from the given stream if possible."

	(aStream isKindOf: ReadWriteStream) ifFalse: [ ^self ].
	aStream position > 0 ifTrue: [
		aStream position: aStream position - 1.
		"restore stream position if previous char was not a tab"
		aStream peek = Character tab ifFalse: [ aStream next ].
	].
]
