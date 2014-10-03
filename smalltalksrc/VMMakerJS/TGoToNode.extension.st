Extension { #name : #TGoToNode }

{ #category : #'*vmmakerjs' }
TGoToNode >> emitJSCodeOn: aStream level: level generator: aCodeGen [
	"Emit a C goto statement."

	aStream nextPutAll: 'goto '.
	aStream nextPutAll: label.
]
