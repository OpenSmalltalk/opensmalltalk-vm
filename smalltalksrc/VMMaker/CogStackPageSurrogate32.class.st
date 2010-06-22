"
I am a surrogate for stack pages that have room to save the callng-convention's registers
"
Class {
	#name : #CogStackPageSurrogate32,
	#superclass : #CogSimpleStackPageSurrogate32,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #'instance creation' }
CogStackPageSurrogate32 class >> alignedByteSize [
	^52
]

{ #category : #accessing }
CogStackPageSurrogate32 >> savedRegister0 [
	^memory unsignedLongAt: address + 41
]

{ #category : #accessing }
CogStackPageSurrogate32 >> savedRegister0: aValue [
	^memory unsignedLongAt: address + 41 put: aValue
]

{ #category : #accessing }
CogStackPageSurrogate32 >> savedRegister1 [
	^memory unsignedLongAt: address + 45
]

{ #category : #accessing }
CogStackPageSurrogate32 >> savedRegister1: aValue [
	^memory unsignedLongAt: address + 45 put: aValue
]

{ #category : #accessing }
CogStackPageSurrogate32 >> savedRegister2 [
	^memory unsignedLongAt: address + 49
]

{ #category : #accessing }
CogStackPageSurrogate32 >> savedRegister2: aValue [
	^memory unsignedLongAt: address + 49 put: aValue
]

{ #category : #accessing }
CogStackPageSurrogate32 >> savedRegister: n [
	^memory unsignedLongLongAt: address + 41 + (n - 1 * 4)
]

{ #category : #accessing }
CogStackPageSurrogate32 >> savedRegister: n put: aValue [
	^memory unsignedLongLongAt: address + 41 + (n - 1 * 4) put: aValue
]
