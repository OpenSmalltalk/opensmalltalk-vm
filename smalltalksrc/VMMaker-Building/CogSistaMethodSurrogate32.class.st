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
	^aByteSymbol == #numCounters
		ifTrue: [24]
		ifFalse: [super offsetOf: aByteSymbol]
]

{ #category : #accessing }
CogSistaMethodSurrogate32 >> numCounters [
	^memory unsignedLongAt: address + 25
]

{ #category : #accessing }
CogSistaMethodSurrogate32 >> numCounters: aValue [
	^memory
		unsignedLongAt: address + 25
		put: aValue
]
