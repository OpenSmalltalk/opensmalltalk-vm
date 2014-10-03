Extension { #name : #TVariableNode }

{ #category : #'*vmmakerjs' }
TVariableNode >> emitJSCodeOn: aStream level: level generator: aCodeGen [

	name = 'nil'
		ifTrue: [ aStream nextPutAll: (aCodeGen cLiteralFor: nil) ]
		ifFalse: [ aStream nextPutAll: (aCodeGen returnPrefixFromVariable: name) ].
]
