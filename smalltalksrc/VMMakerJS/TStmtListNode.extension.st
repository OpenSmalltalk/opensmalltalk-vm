Extension { #name : #TStmtListNode }

{ #category : #'*vmmakerjs' }
TStmtListNode >> emitJSCodeAsArgumentOn: aStream level: level generator: aCodeGen [

	| statementWasComment |
	statementWasComment := false.
	statements
		do:
			[:s |
			s emitJSCommentOn: aStream level: level.
			s emitJSCodeAsArgumentOn: aStream level: 0 generator: aCodeGen.
			statementWasComment := s isComment]
		separatedBy:
			[((self endsWithCloseBracket: aStream)
			  or: [statementWasComment]) ifFalse: [aStream nextPut: $,]]
]

{ #category : #'*vmmakerjs' }
TStmtListNode >> emitJSCodeAsExpressionOn: aStream level: level generator: aCodeGen [
	^self emitJSCodeAsArgumentOn: aStream level: level generator: aCodeGen
]

{ #category : #'*vmmakerjs' }
TStmtListNode >> emitJSCodeOn: aStream level: level generator: aCodeGen [

	self emitJSCommentOn: aStream level: level.
	statements do: [:s |
		s emitJSCommentOn: aStream level: level.
		aStream tab: level.
		s emitJSCodeOn: aStream level: level generator: aCodeGen.
		(((self endsWithCloseBracket: aStream) not
			and: [(s isComment) not])
				and: [s requiresCLineTerminator])
			ifTrue: [aStream nextPut: $;].
		aStream cr].

]
