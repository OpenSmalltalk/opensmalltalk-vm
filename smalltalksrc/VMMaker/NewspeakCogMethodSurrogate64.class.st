Class {
	#name : #NewspeakCogMethodSurrogate64,
	#superclass : #CogMethodSurrogate64,
	#category : 'VMMaker-JITSimulation'
}

{ #category : #accessing }
NewspeakCogMethodSurrogate64 class >> alignedByteSize [
	^40 + self baseHeaderSize
]

{ #category : #accessing }
NewspeakCogMethodSurrogate64 >> nextMethodOrIRCs [
	^memory unsignedLong64At: address + 33 + baseHeaderSize
]

{ #category : #accessing }
NewspeakCogMethodSurrogate64 >> nextMethodOrIRCs: aValue [
	^memory
		unsignedLong64At: address + baseHeaderSize + 33
		put: aValue
]
