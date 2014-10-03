Extension { #name : #TAssignmentNode }

{ #category : #'*vmmakerjs' }
TAssignmentNode >> emitJSCodeAsArgumentOn: aStream level: level generator: aCodeGen [
	aStream nextPut: $(.
	self emitJSCodeOn: aStream level: level generator: aCodeGen.
	aStream nextPut: $)
]

{ #category : #'*vmmakerjs' }
TAssignmentNode >> emitJSCodeAsExpressionOn: aStream level: level generator: aCodeGen [
	aStream nextPut: $(.
	self emitJSCodeOn: aStream level: level generator: aCodeGen.
	aStream nextPut: $)
]

{ #category : #'*vmmakerjs' }
TAssignmentNode >> emitJSCodeOn: aStream level: level generator: aCodeGen [
	expression isSwitch ifTrue:
		[^expression emitJSCodeOn: aStream addToEndOfCases: self level: level generator: aCodeGen].
	variable emitJSCodeOn: aStream level: level generator: aCodeGen.
	self isVariableUpdatingAssignment
		ifTrue:
			[aStream
				space;
				nextPutAll: expression selector;	"+ or -"
				nextPut: $=;
				space.
			expression args first emitJSCodeAsArgumentOn: aStream level: level generator: aCodeGen]
		ifFalse:
			[aStream space; nextPut: $=; space.
			 expression emitJSCodeAsArgumentOn: aStream level: level generator: aCodeGen]
]
