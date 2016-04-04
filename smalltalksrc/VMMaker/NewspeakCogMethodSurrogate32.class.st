Class {
	#name : #NewspeakCogMethodSurrogate32,
	#superclass : #CogMethodSurrogate32,
	#category : 'VMMaker-JITSimulation'
}

{ #category : #accessing }
NewspeakCogMethodSurrogate32 class >> alignedByteSize [
	^24 + self baseHeaderSize
]

{ #category : #accessing }
NewspeakCogMethodSurrogate32 >> nextMethodOrIRCs [
	^memory unsignedLongAt: address + 21 + baseHeaderSize
]

{ #category : #accessing }
NewspeakCogMethodSurrogate32 >> nextMethodOrIRCs: aValue [
	^memory
		unsignedLongAt: address + baseHeaderSize + 21
		put: aValue
]
