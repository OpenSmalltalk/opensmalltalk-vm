Extension { #name : #TConstantNode }

{ #category : #'*vmmakerjs' }
TConstantNode >> emitJSCodeOn: aStream level: level generator: aCodeGen [
	"Emit a C literal."

	aStream nextPutAll: (aCodeGen jsLiteralFor: value).
]

{ #category : #'*vmmakerjs' }
TConstantNode >> isConstantZero [
	^ value = 0
]

{ #category : #'*vmmakerjs' }
TConstantNode >> isFloatIn: aCodeGen [
	^value isFloat
]
