Class {
	#name : #CogBlockMethodSurrogate32,
	#superclass : #CogMethodSurrogate,
	#category : 'VMMaker-JITSimulation'
}

{ #category : #accessing }
CogBlockMethodSurrogate32 class >> alignedByteSize [
	^4 + self baseHeaderSize
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cbUsesInstVars [
	^(((memory unsignedByteAt: address + 3 + baseHeaderSize) bitShift: -1) bitAnd: 16r1) ~= 0
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cbUsesInstVars: aValue [
	memory
		unsignedByteAt: address + baseHeaderSize + 3
		put: (((memory unsignedByteAt: address + baseHeaderSize + 3) bitAnd: 16rFD) + ((aValue ifTrue: [1] ifFalse: [0]) bitShift: 1)).
	^aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmHomeMethod [
	^cogit cogMethodSurrogateAt: address - self homeOffset
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmIsUnlinked [
	^(((memory unsignedByteAt: address + 6) bitShift: -4) bitAnd: 16r1) ~= 0
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmIsUnlinked: aValue [
	memory
		unsignedByteAt: address + 6
		put: (((memory unsignedByteAt: address + 6) bitAnd: 16rEF) + ((aValue ifTrue: [1] ifFalse: [0]) bitShift: 4)).
	^aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmNumArgs [
	^memory unsignedByteAt: address + 1 + baseHeaderSize
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmNumArgs: aValue [
	^memory
		unsignedByteAt: address + baseHeaderSize + 1
		put: aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmRefersToYoung [
	^(((memory unsignedByteAt: address + 2 + baseHeaderSize) bitShift: -3) bitAnd: 16r1) ~= 0
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmRefersToYoung: aValue [
	memory
		unsignedByteAt: address + baseHeaderSize + 2
		put: (((memory unsignedByteAt: address + baseHeaderSize + 2) bitAnd: 16rF7) + ((aValue ifTrue: [1] ifFalse: [0]) bitShift: 3)).
	^aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmType [
	^(memory unsignedByteAt: address + 2 + baseHeaderSize) bitAnd: 16r7
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmType: aValue [
	self assert: (aValue between: 0 and: 16r7).
	memory
		unsignedByteAt: address + baseHeaderSize + 2
		put: ((memory unsignedByteAt: address + baseHeaderSize + 2) bitAnd: 16rF8) + aValue.
	^aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmUsageCount [
	^((memory unsignedByteAt: address + 2 + baseHeaderSize) bitShift: -5) bitAnd: 16r7
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmUsageCount: aValue [
	self assert: (aValue between: 0 and: 16r7).
	memory
		unsignedByteAt: address + baseHeaderSize + 2
		put: ((memory unsignedByteAt: address + baseHeaderSize + 2) bitAnd: 16r1F) + (aValue bitShift: 5).
	^aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmUsesPenultimateLit [
	^((memory unsignedByteAt: address + 3 + baseHeaderSize) bitAnd: 16r1) ~= 0
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmUsesPenultimateLit: aValue [
	memory
		unsignedByteAt: address + baseHeaderSize + 3
		put: (((memory unsignedByteAt: address + baseHeaderSize + 3) bitAnd: 16rFE) + (aValue ifTrue: [1] ifFalse: [0])).
	^aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cpicHasMNUCase [
	^(((memory unsignedByteAt: address + 2 + baseHeaderSize) bitShift: -4) bitAnd: 16r1) ~= 0
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cpicHasMNUCase: aValue [
	memory
		unsignedByteAt: address + baseHeaderSize + 2
		put: (((memory unsignedByteAt: address + baseHeaderSize + 2) bitAnd: 16rEF) + ((aValue ifTrue: [1] ifFalse: [0]) bitShift: 4)).
	^aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> homeOffset [
	^memory unsignedShortAt: address + 1
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> homeOffset: aValue [
	^memory
		unsignedShortAt: address + 1
		put: aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> padToWord [
	^memory unsignedLongAt: address + 5
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> padToWord: aValue [
	^memory
		unsignedLongAt: address + 5
		put: aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> stackCheckOffset [
	^((memory unsignedShortAt: address + 3 + baseHeaderSize) bitShift: -4) bitAnd: 16rFFF
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> stackCheckOffset: aValue [
	self assert: (aValue between: 0 and: 16rFFF).
	memory
		unsignedShortAt: address + baseHeaderSize + 3
		put: ((memory unsignedShortAt: address + baseHeaderSize + 3) bitAnd: 16rF) + (aValue bitShift: 4).
	^aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> startpc [
	^memory unsignedShortAt: address + 3
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> startpc: aValue [
	^memory
		unsignedShortAt: address + 3
		put: aValue
]
