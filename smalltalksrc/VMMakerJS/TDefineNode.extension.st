Extension { #name : #TDefineNode }

{ #category : #'*vmmakerjs' }
TDefineNode >> emitJSCodeOn: aStream level: level generator: aCodeGen [
	"Emit a C literal."

	aStream nextPutAll: name.
]
