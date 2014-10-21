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
	self isVariableUpdatingAssignment
		ifTrue:
			[(expression args first isConstant and: [expression args first value = 1])
				ifTrue: [aStream nextPutAll: expression selector, expression selector.
					variable emitJSCodeOn: aStream level: level generator: aCodeGen]
				ifFalse: [
					variable emitJSCodeOn: aStream level: level generator: aCodeGen.
					aStream nextPutAll: ' ', expression selector, '= '.
					expression args first emitJSCodeAsArgumentOn: aStream level: level generator: aCodeGen]]
		ifFalse:
			[ | coerceToInt |
			coerceToInt := (variable isFloatIn: aCodeGen) not and: [expression isFloatIn: aCodeGen].
			variable emitJSCodeOn: aStream level: level generator: aCodeGen.
			aStream nextPutAll: ' = '.
			expression emitJSCodeAsArgumentOn: aStream level: level generator: aCodeGen.
			coerceToInt ifTrue: [aStream nextPutAll: '|0'].]
]

{ #category : #'*vmmakerjs' }
TAssignmentNode >> isFloatIn: aCodeGen [
	^variable isFloatIn: aCodeGen
]
