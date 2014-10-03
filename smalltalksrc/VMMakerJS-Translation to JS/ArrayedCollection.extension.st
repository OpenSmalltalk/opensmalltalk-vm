Extension { #name : #ArrayedCollection }

{ #category : #'*vmmakerjs' }
ArrayedCollection class >> jscg: cg generateCoerceToOopFrom: aNode on: aStream [
	"N.B.  The is used both for generation and simulation so answer the result (for interpretation)"
	self instSize > 0 ifTrue: 
		[self error: 'cannot auto-coerce arrays with named instance variables'].
	^cg generateCoerceToObjectFromPtr: aNode on: aStream
]

{ #category : #'*vmmakerjs' }
ArrayedCollection class >> jscg: cg generateCoerceToValueFrom: aNode on: aStream [
	"N.B.  The could be used both for generation and simulation so answer the result (for interpretation)"
	^cg 
		generateCoerceToPtr: (self jscgDeclareJSForVar: '')
		fromObject: aNode on: aStream
]
