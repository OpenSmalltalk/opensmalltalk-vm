Class {
	#name : #CogSistaMethodSurrogate64,
	#superclass : #CogMethodSurrogate64,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
CogSistaMethodSurrogate64 class >> alignedByteSize [
	^48
]

{ #category : #accessing }
CogSistaMethodSurrogate64 class >> offsetOf: aByteSymbol [
	"These should be generated!!"
	self assert: self objectMemoryClass baseHeaderSize = BaseHeaderSize.
	^aByteSymbol == #numCounters
		ifTrue: [32 + BaseHeaderSize]
		ifFalse: [super offsetOf: aByteSymbol]
]

{ #category : #accessing }
CogSistaMethodSurrogate64 >> numCounters [
	^memory unsignedLongLongAt: address + 41
]

{ #category : #accessing }
CogSistaMethodSurrogate64 >> numCounters: aValue [
	^memory
		unsignedLongLongAt: address + 41
		put: aValue
]
