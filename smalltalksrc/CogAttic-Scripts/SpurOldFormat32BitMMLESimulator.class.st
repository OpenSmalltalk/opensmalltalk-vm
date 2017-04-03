Class {
	#name : #SpurOldFormat32BitMMLESimulator,
	#superclass : #Spur32BitMMLESimulator,
	#category : #'CogAttic-Bootstrapping'
}

{ #category : #'method access' }
SpurOldFormat32BitMMLESimulator >> literalCountOfMethodHeader: header [
	self assert: (self isIntegerObject: header).
	^header >> 10 bitAnd: 16rFF
]

{ #category : #'method access' }
SpurOldFormat32BitMMLESimulator >> primitiveIndexOfMethodHeader: methodHeader [
	| primBits |
	primBits := (self integerValueOf: methodHeader) bitAnd: 16r100001FF.
	^(primBits bitAnd: 16r1FF) + (primBits >> 19)
]
