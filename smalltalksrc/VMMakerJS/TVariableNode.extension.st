Extension { #name : #TVariableNode }

{ #category : #'*vmmakerjs' }
TVariableNode >> emitJSCodeOn: aStream level: level generator: aCodeGen [

	name = 'nil'
		ifTrue: [ aStream nextPutAll: (aCodeGen jsLiteralFor: nil) ]
		ifFalse: [ aStream nextPutAll: (aCodeGen returnPrefixFromVariable: name) ].
]

{ #category : #'*vmmakerjs' }
TVariableNode >> isBitBltPtr [
	^#('sourceBits' 'destBits') includes: self name
]

{ #category : #'*vmmakerjs' }
TVariableNode >> isConstantNull [
	^ name = 'nil'
]
