Class {
	#name : #CogBlockMethodSurrogate64,
	#superclass : #CogMethodSurrogate,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
CogBlockMethodSurrogate64 class >> alignedByteSize [
	^12
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> cmHomeMethod [
	^CogMethodSurrogate64 new
		at: address - self homeOffset
		memory: memory
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> cmIsUnlinked [
	^(((memory unsignedByteAt: address + 10) bitShift: -4) bitAnd: 16r1) ~= 0
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> cmIsUnlinked: aValue [
	memory
		unsignedByteAt: address + 10
		put: (((memory unsignedByteAt: address + 10) bitAnd: 16rEF) + ((aValue ifTrue: [1] ifFalse: [0]) bitShift: 4)).
	^aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> cmNumArgs [
	^memory unsignedByteAt: address + 9
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> cmNumArgs: aValue [
	^memory
		unsignedByteAt: address + 9
		put: aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> cmRefersToYoung [
	^(((memory unsignedByteAt: address + 10) bitShift: -3) bitAnd: 16r1) ~= 0
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> cmRefersToYoung: aValue [
	memory
		unsignedByteAt: address + 10
		put: (((memory unsignedByteAt: address + 10) bitAnd: 16rF7) + ((aValue ifTrue: [1] ifFalse: [0]) bitShift: 3)).
	^aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> cmType [
	^(memory unsignedByteAt: address + 10) bitAnd: 16r7
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> cmType: aValue [
	self assert: (aValue between: 0 and: 16r7).
	memory
		unsignedByteAt: address + 10
		put: ((memory unsignedByteAt: address + 10) bitAnd: 16rF8) + aValue.
	^aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> cmUsageCount [
	^((memory unsignedByteAt: address + 10) bitShift: -5) bitAnd: 16r7
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> cmUsageCount: aValue [
	self assert: (aValue between: 0 and: 16r7).
	memory
		unsignedByteAt: address + 10
		put: ((memory unsignedByteAt: address + 10) bitAnd: 16r1F) + (aValue bitShift: 5).
	^aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> homeOffset [
	^memory unsignedShortAt: address + 1
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> homeOffset: aValue [
	^memory
		unsignedShortAt: address + 1
		put: aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> padToWord [
	^memory unsignedLongAt: address + 5
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> padToWord: aValue [
	^memory
		unsignedLongAt: address + 5
		put: aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> stackCheckOffset [
	^memory unsignedShortAt: address + 11
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> stackCheckOffset: aValue [
	^memory
		unsignedShortAt: address + 11
		put: aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> startpc [
	^memory unsignedShortAt: address + 3
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> startpc: aValue [
	^memory
		unsignedShortAt: address + 3
		put: aValue
]

{ #category : #accessing }
CogBlockMethodSurrogate64 >> typeEtAlWord [
	^memory unsignedLongLongAt: address + 9
]
