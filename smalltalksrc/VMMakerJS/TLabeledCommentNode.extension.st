Extension { #name : #TLabeledCommentNode }

{ #category : #'*vmmakerjs' }
TLabeledCommentNode >> emitJSCodeOn: aStream level: level generator: aCodeGen [
	"Emit a C comment with optional label."

	self printOptionalLabelOn: aStream.
	aStream nextPutAll: '/* '.
	aStream nextPutAll: comment.
	aStream nextPutAll: ' */'.
]
