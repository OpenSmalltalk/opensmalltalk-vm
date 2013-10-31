Class {
	#name : #NewspeakCogMethodSurrogate64,
	#superclass : #CogMethodSurrogate64,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
NewspeakCogMethodSurrogate64 class >> alignedByteSize [
	^40 + self baseHeaderSize
]

{ #category : #accessing }
NewspeakCogMethodSurrogate64 >> nextMethod [
	| v |
	^(v := memory unsignedLongLongAt: address + 33 + baseHeaderSize) ~= 0 ifTrue:
		[cogit cCoerceSimple: v to: #'CogMethod *']
]

{ #category : #accessing }
NewspeakCogMethodSurrogate64 >> nextMethod: aValue [
	^memory
		unsignedLongLongAt: address + baseHeaderSize + 33
		put: ((aValue ifNotNil: [aValue asUnsignedInteger] ifNil: [0]))
]
