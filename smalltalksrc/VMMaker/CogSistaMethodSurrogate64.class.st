Class {
	#name : #CogSistaMethodSurrogate64,
	#superclass : #CogMethodSurrogate64,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
CogSistaMethodSurrogate64 class >> alignedByteSize [
	^40 + self baseHeaderSize
]

{ #category : #accessing }
CogSistaMethodSurrogate64 class >> offsetOf: aByteSymbol [
	"These should be generated!!"
	self assert: self objectMemoryClass baseHeaderSize = BaseHeaderSize.
	^aByteSymbol == #counters
		ifTrue: [32 + BaseHeaderSize]
		ifFalse: [super offsetOf: aByteSymbol]
]

{ #category : #accessing }
CogSistaMethodSurrogate64 >> counters [
	^memory unsignedLongLongAt: address + 33 + baseHeaderSize
]

{ #category : #accessing }
CogSistaMethodSurrogate64 >> counters: aValue [
	^memory
		unsignedLongLongAt: address + 33 + baseHeaderSize
		put: aValue
]
