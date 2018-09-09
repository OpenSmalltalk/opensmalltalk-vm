Extension { #name : #RBLiteralValueNode }

{ #category : #'*VMMakerCompatibilityForPharo6-testing' }
RBLiteralValueNode >> isConstantNumber [
	^value isNumber
]

{ #category : #'*VMMakerCompatibilityForPharo6-testing' }
RBLiteralValueNode >> isNodeNil [
	^value == nil
]
