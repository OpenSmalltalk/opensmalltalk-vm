Class {
	#name : #CogObjectHeaderSurrogate,
	#superclass : #Object,
	#instVars : [
		'address',
		'memory'
	],
	#category : #'VMMaker-MemoryManagerSimulation'
}

{ #category : #accessing }
CogObjectHeaderSurrogate class >> alignedByteSize [
	^8
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> classIndex [
	^memory unsignedShortAt: address + 1
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> classIndex: aValue [
	^memory
		unsignedShortAt: address + 1
		put: aValue
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> format [
	^(memory unsignedByteAt: address + 4) bitAnd: 16r1F
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> format: aValue [
	self assert: (aValue between: 0 and: 16r1F).
	memory
		unsignedByteAt: address + 4
		put: ((memory unsignedByteAt: address + 4) bitAnd: 16rE0) + aValue.
	^aValue
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> isGrey [
	^(((memory unsignedByteAt: address + 4) bitShift: -6) bitAnd: 16r1) ~= 0
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> isGrey: aValue [
	memory
		unsignedByteAt: address + 4
		put: (((memory unsignedByteAt: address + 4) bitAnd: 16rBF) + ((aValue ifTrue: [1] ifFalse: [0]) bitShift: 6)).
	^aValue
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> isImmutable [
	^(((memory unsignedByteAt: address + 3) bitShift: -7) bitAnd: 16r1) ~= 0
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> isImmutable: aValue [
	memory
		unsignedByteAt: address + 3
		put: (((memory unsignedByteAt: address + 3) bitAnd: 16r7F) + ((aValue ifTrue: [1] ifFalse: [0]) bitShift: 7)).
	^aValue
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> isMarked [
	^(((memory unsignedByteAt: address + 4) bitShift: -5) bitAnd: 16r1) ~= 0
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> isMarked: aValue [
	memory
		unsignedByteAt: address + 4
		put: (((memory unsignedByteAt: address + 4) bitAnd: 16rDF) + ((aValue ifTrue: [1] ifFalse: [0]) bitShift: 5)).
	^aValue
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> isPinned [
	^(((memory unsignedByteAt: address + 3) bitShift: -6) bitAnd: 16r1) ~= 0
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> isPinned: aValue [
	memory
		unsignedByteAt: address + 3
		put: (((memory unsignedByteAt: address + 3) bitAnd: 16rBF) + ((aValue ifTrue: [1] ifFalse: [0]) bitShift: 6)).
	^aValue
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> isRemembered [
	^(((memory unsignedByteAt: address + 4) bitShift: -7) bitAnd: 16r1) ~= 0
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> isRemembered: aValue [
	memory
		unsignedByteAt: address + 4
		put: (((memory unsignedByteAt: address + 4) bitAnd: 16r7F) + ((aValue ifTrue: [1] ifFalse: [0]) bitShift: 7)).
	^aValue
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> objHash [
	^(memory unsignedLongAt: address + 5) bitAnd: 16rFFFFFF
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> objHash: aValue [
	self assert: (aValue between: 0 and: 16rFFFFFF).
	memory
		unsignedLongAt: address + 5
		put: ((memory unsignedLongAt: address + 5) bitAnd: 16rFF000000) + aValue.
	^aValue
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> slotSize [
	^memory unsignedByteAt: address + 8
]

{ #category : #accessing }
CogObjectHeaderSurrogate >> slotSize: aValue [
	^memory
		unsignedByteAt: address + 8
		put: aValue
]
