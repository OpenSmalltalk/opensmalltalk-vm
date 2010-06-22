"
I am a surrogate for stack pages that have room to save the callng-convention's registers
"
Class {
	#name : #CogStackPageSurrogate64,
	#superclass : #CogSimpleStackPageSurrogate64,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
CogStackPageSurrogate64 class >> alignedByteSize [
	^104
]

{ #category : #accessing }
CogStackPageSurrogate64 >> savedRegister0 [
	^memory unsignedLongLongAt: address + 81
]

{ #category : #accessing }
CogStackPageSurrogate64 >> savedRegister0: aValue [
	^memory unsignedLongLongAt: address + 81 put: aValue
]

{ #category : #accessing }
CogStackPageSurrogate64 >> savedRegister1 [
	^memory unsignedLongLongAt: address + 89
]

{ #category : #accessing }
CogStackPageSurrogate64 >> savedRegister1: aValue [
	^memory unsignedLongLongAt: address + 89 put: aValue
]

{ #category : #accessing }
CogStackPageSurrogate64 >> savedRegister2 [
	^memory unsignedLongLongAt: address + 97
]

{ #category : #accessing }
CogStackPageSurrogate64 >> savedRegister2: aValue [
	^memory unsignedLongLongAt: address + 97 put: aValue
]

{ #category : #accessing }
CogStackPageSurrogate64 >> savedRegister: n [
	^memory unsignedLongLongAt: address + 81 + (n - 1 * 8)
]

{ #category : #accessing }
CogStackPageSurrogate64 >> savedRegister: n put: aValue [
	^memory unsignedLongLongAt: address + 81 + (n - 1 * 8) put: aValue
]
