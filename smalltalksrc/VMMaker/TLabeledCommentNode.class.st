Class {
	#name : #TLabeledCommentNode,
	#superclass : #TParseNode,
	#instVars : [
		'label',
		'asmLabel'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #accessing }
TLabeledCommentNode >> asmLabel [

	^asmLabel
]

{ #category : #accessing }
TLabeledCommentNode >> asmLabel: labelString [

	asmLabel := labelString
]

{ #category : #'C code generation' }
TLabeledCommentNode >> emitCCodeOn: aStream level: level generator: aCodeGen [
	"Emit a C comment with optional label."

	self printOptionalLabelOn: aStream.
	aStream nextPutAll: '/* '.
	aStream nextPutAll: comment.
	aStream nextPutAll: ' */'.
	asmLabel notNil ifTrue:
		[aStream crtab: level.
		 aCodeGen outputAsmLabel: asmLabel on: aStream]
]

{ #category : #testing }
TLabeledCommentNode >> isComment [
	"Answer true if the receiver is just a comment (i.e., it has no label)."

	^label = nil
]

{ #category : #testing }
TLabeledCommentNode >> isLabel [

	^true
]

{ #category : #testing }
TLabeledCommentNode >> isLeaf [

	^true
]

{ #category : #accessing }
TLabeledCommentNode >> label [

	^label
]

{ #category : #printing }
TLabeledCommentNode >> printOn: aStream level: level [

	self printOptionalLabelOn: aStream.
	aStream nextPut: $".
	aStream nextPutAll: comment.
	aStream nextPut: $".
]

{ #category : #printing }
TLabeledCommentNode >> printOptionalLabelOn: aStream [

	label ~= nil ifTrue: [
		self unindentOneTab: aStream.
		aStream nextPutAll: label.
		aStream nextPut: $:.
		aStream tab.	
	].
]

{ #category : #accessing }
TLabeledCommentNode >> setComment: commentString [

	label := nil.
	comment := commentString.
]

{ #category : #accessing }
TLabeledCommentNode >> setLabel: labelString [

	label := labelString.
]

{ #category : #accessing }
TLabeledCommentNode >> setLabel: labelString comment: commentString [

	label := labelString.
	comment := commentString.
]

{ #category : #'C code generation' }
TLabeledCommentNode >> unindentOneTab: aStream [
	"Remove the last tab from the given stream if possible."

	(aStream isKindOf: ReadWriteStream) ifFalse: [ ^self ].
	aStream position > 0 ifTrue: [
		aStream position: aStream position - 1.
		"restore stream position if previous char was not a tab"
		aStream peek = Character tab ifFalse: [ aStream next ].
	].
]
