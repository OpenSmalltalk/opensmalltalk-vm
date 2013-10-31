Class {
	#name : #NewspeakCogMethodSurrogate32,
	#superclass : #CogMethodSurrogate32,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
NewspeakCogMethodSurrogate32 class >> alignedByteSize [
	^24 + self baseHeaderSize
]

{ #category : #accessing }
NewspeakCogMethodSurrogate32 >> nextMethod [
	| v |
	^(v := memory unsignedLongAt: address + 21 + baseHeaderSize) ~= 0 ifTrue:
		[cogit cCoerceSimple: v to: #'CogMethod *']
]

{ #category : #accessing }
NewspeakCogMethodSurrogate32 >> nextMethod: aValue [
	^memory
		unsignedLongAt: address + baseHeaderSize + 21
		put: ((aValue ifNotNil: [aValue asUnsignedInteger] ifNil: [0]))
]
