Extension { #name : #TParseNode }

{ #category : #'*vmmakerjs' }
TParseNode >> emitJSCodeAsArgumentOn: aStream level: level generator: aCodeGen [
	^self emitJSCodeOn: aStream level: level generator: aCodeGen
]

{ #category : #'*vmmakerjs' }
TParseNode >> emitJSCodeAsExpressionOn: aStream level: level generator: aCodeGen [
	^self emitJSCodeOn: aStream level: level generator: aCodeGen
]

{ #category : #'*vmmakerjs' }
TParseNode >> emitJSCodeOn: aStream level: lev generator: gen [
	self subclassResponsibility.
]

{ #category : #'*vmmakerjs' }
TParseNode >> emitJSCommentOn: aStream level: level [
	"Emit the transferred Smalltalk comments as C comments."

	comment ifNotNil: [
		comment isString ifTrue: [^self].	"safety catch"
		aStream cr.
		1 to: comment size do: [:index | 
			aStream 
				tab: level;
				nextPutAll: '/* ';
				nextPutAll: (comment at: index);
				nextPutAll: ' */';
				cr].
		aStream cr]
]
