Extension { #name : #RBVariableNode }

{ #category : #'*VMMakerCompatibilityForPharo6-C translation' }
RBVariableNode >> asTranslatorNodeIn: aTMethod [
	"Answer a TParseNode subclass equivalent of me"
	name = 'true' ifTrue: [^ TConstantNode new setValue: true].
	name = 'false' ifTrue: [^ TConstantNode new setValue: false].
	^ TVariableNode new setName: name
]

{ #category : #'*VMMakerCompatibilityForPharo6-testing' }
RBVariableNode >> isVariableNode [
	^true
]

{ #category : #'*VMMakerCompatibilityForPharo6-accessing' }
RBVariableNode >> key [
	^name
]
