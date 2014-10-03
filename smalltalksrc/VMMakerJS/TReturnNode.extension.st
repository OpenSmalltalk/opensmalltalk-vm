Extension { #name : #TReturnNode }

{ #category : #'*vmmakerjs' }
TReturnNode >> emitJSCodeOn: aStream level: level generator: aCodeGen [

	(expression isSwitch
	 or: [expression isCaseStmt]) ifTrue:
		[^expression emitJSCodeOn: aStream addToEndOfCases: self level: level generator: aCodeGen].

	('void' = aCodeGen currentMethod returnType) ifTrue: [
		"If the function is void, don't say 'return x' instead say ' x; return' "
		expression isLeaf ifFalse: [
			expression emitJSCodeAsArgumentOn: aStream level: level generator: aCodeGen.	
			aStream nextPutAll: ';'; space.
		].
		aStream nextPutAll: 'return'.
	] ifFalse: [
		aStream nextPutAll: 'return'.
		aStream space.
		expression emitJSCodeAsArgumentOn: aStream level: level generator: aCodeGen
	].
]
