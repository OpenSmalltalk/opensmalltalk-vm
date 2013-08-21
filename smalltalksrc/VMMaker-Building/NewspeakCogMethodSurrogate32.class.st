Class {
	#name : #NewspeakCogMethodSurrogate32,
	#superclass : #CogMethodSurrogate32,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
NewspeakCogMethodSurrogate32 class >> alignedByteSize [
	^28
]

{ #category : #accessing }
NewspeakCogMethodSurrogate32 >> nextMethod [
	| v |
	^(v := memory unsignedLongAt: address + 25) ~= 0 ifTrue:
		[cogit cCoerceSimple: v to: #'CogMethod *']
]

{ #category : #accessing }
NewspeakCogMethodSurrogate32 >> nextMethod: aValue [
	^memory
		unsignedLongAt: address + 25
		put: ((aValue ifNotNil: [aValue asUnsignedInteger] ifNil: [0]))
]
