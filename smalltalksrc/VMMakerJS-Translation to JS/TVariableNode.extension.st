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

{ #category : #'*vmmakerjs' }
TVariableNode >> isFloatIn: aCodeGen [
	| type |
	type := aCodeGen typeOfVariable: name.
	type isNil ifTrue: [^false].
	(type includes: $*) ifTrue: [^false].
	(type beginsWithAnyOf: #('register ' 'static ')) ifTrue: [type := type copyAfter: $ ].
	(type beginsWithAnyOf: #('double ' 'float ')) ifTrue: [^true].
	(type beginsWithAnyOf: #('int ' 'unsigned ' 'sqInt ' 'usqInt ' 'var ')) ifTrue: [^false].
	self halt: 'need to handle ', type
]
