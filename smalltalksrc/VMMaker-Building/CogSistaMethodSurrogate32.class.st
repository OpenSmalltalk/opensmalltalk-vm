Class {
	#name : #CogSistaMethodSurrogate32,
	#superclass : #CogMethodSurrogate32,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
CogSistaMethodSurrogate32 class >> alignedByteSize [
	^28
]

{ #category : #accessing }
CogSistaMethodSurrogate32 class >> offsetOf: aByteSymbol [
	"These should be generated!!"
	self assert: self objectMemoryClass baseHeaderSize = BaseHeaderSize.
	^aByteSymbol == #numCounters
		ifTrue: [20 + BaseHeaderSize]
		ifFalse: [super offsetOf: aByteSymbol]
]

{ #category : #accessing }
CogSistaMethodSurrogate32 >> numCounters [
	^memory unsignedLongAt: address + 21 + baseHeaderSize
]

{ #category : #accessing }
CogSistaMethodSurrogate32 >> numCounters: aValue [
	^memory
		unsignedLongAt: address + 21 + baseHeaderSize
		put: aValue
]
