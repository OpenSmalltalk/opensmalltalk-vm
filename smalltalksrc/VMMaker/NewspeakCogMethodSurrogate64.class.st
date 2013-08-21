Class {
	#name : #NewspeakCogMethodSurrogate64,
	#superclass : #CogMethodSurrogate64,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
NewspeakCogMethodSurrogate64 class >> alignedByteSize [
	^48
]

{ #category : #accessing }
NewspeakCogMethodSurrogate64 >> nextMethod [
	| v |
	^(v := memory unsignedLongLongAt: address + 41) ~= 0 ifTrue:
		[cogit cCoerceSimple: v to: #'CogMethod *']
]

{ #category : #accessing }
NewspeakCogMethodSurrogate64 >> nextMethod: aValue [
	^memory
		unsignedLongLongAt: address + 41
		put: ((aValue ifNotNil: [aValue asUnsignedInteger] ifNil: [0]))
]
