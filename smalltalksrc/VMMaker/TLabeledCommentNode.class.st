Class {
	#name : #TLabeledCommentNode,
	#superclass : #TParseNode,
	#instVars : [
		'label',
		'asmLabel'
	],
	#category : 'VMMaker-Translation to C'
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
	comment ifNotNil:
		[(aCodeGen previousCommentMarksInlining: (label isNil and: [asmLabel isNil and: [comment beginsWith: 'begin ']])) ifTrue:
			[^true].
		 aStream nextPutAll: '/* '; nextPutAll: comment; nextPutAll: ' */'.
		 aCodeGen previousCommenter: self].
	(asmLabel notNil "only output labels in the interpret function."
	 and: [aCodeGen currentMethod selector == #interpret]) ifTrue:
		[aStream crtab: level.
		 aCodeGen outputAsmLabel: asmLabel on: aStream]
]

{ #category : #'C code generation' }
TLabeledCommentNode >> emitCCommentOn: aStream level: level generator: aCodeGen [
	"Override to avoid outputting comments since this is done explicitly in statement lists."
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

{ #category : #testing }
TLabeledCommentNode >> needsTrailingSemicolon [
	"Answer if, when emitted as a statement (in particular in a TStmtList), the
	 receiver needs a trailing semicolon.  Comments do not.  You'd think that
	 labels do not, but we put them at the end of blocks where there needs
	 to be a null statement following the label and before the end of block."
	^self isComment not
]

{ #category : #enumerating }
TLabeledCommentNode >> nodesDo: aBlock parent: parent [
	aBlock value: self value: parent
]

{ #category : #printing }
TLabeledCommentNode >> printOn: aStream level: level [

	self printOptionalLabelOn: aStream.
	comment ifNotNil:
		[aStream nextPut: $".
		 aStream nextPutAll: comment.
		 aStream nextPut: $"]
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
