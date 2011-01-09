Class {
	#name : #CogBlockMethodSurrogate32,
	#superclass : #CogMethodSurrogate,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
CogBlockMethodSurrogate32 class >> alignedByteSize [
	^8
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmHomeMethod [
	^CogMethodSurrogate32 new
		at: address - self homeOffset
		memory: memory
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
	^memory unsignedByteAt: address + 5
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmNumArgs: aValue [
	^memory
		unsignedByteAt: address + 5
		put: aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmRefersToYoung [
	^(((memory unsignedByteAt: address + 6) bitShift: -3) bitAnd: 16r1) ~= 0
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmRefersToYoung: aValue [
	memory
		unsignedByteAt: address + 6
		put: (((memory unsignedByteAt: address + 6) bitAnd: 16rF7) + ((aValue ifTrue: [1] ifFalse: [0]) bitShift: 3)).
	^aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmType [
	^(memory unsignedByteAt: address + 6) bitAnd: 16r7
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmType: aValue [
	self assert: (aValue between: 0 and: 16r7).
	memory
		unsignedByteAt: address + 6
		put: ((memory unsignedByteAt: address + 6) bitAnd: 16rF8) + aValue.
	^aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmUsageCount [
	^((memory unsignedByteAt: address + 6) bitShift: -5) bitAnd: 16r7
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> cmUsageCount: aValue [
	self assert: (aValue between: 0 and: 16r7).
	memory
		unsignedByteAt: address + 6
		put: ((memory unsignedByteAt: address + 6) bitAnd: 16r1F) + (aValue bitShift: 5).
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
CogBlockMethodSurrogate32 >> stackCheckOffset [
	^memory unsignedShortAt: address + 7
]

{ #category : #accessing }
CogBlockMethodSurrogate32 >> stackCheckOffset: aValue [
	^memory
		unsignedShortAt: address + 7
		put: aValue
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

{ #category : #accessing }
CogBlockMethodSurrogate32 >> typeEtAlWord [
	^memory unsignedLongAt: address + 5
]
