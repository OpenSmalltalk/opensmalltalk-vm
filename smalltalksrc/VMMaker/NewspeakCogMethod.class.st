Class {
	#name : #NewspeakCogMethod,
	#superclass : #CogMethod,
	#instVars : [
		'nextMethodOrIRCs'
	],
	#category : 'VMMaker-JIT'
}

{ #category : #'class initialization' }
NewspeakCogMethod class >> initialize [
	"self initialize"
	(Smalltalk classNamed: #NewspeakCogMethodSurrogate32) ifNotNil:
		[:cms32|
		self checkGenerateSurrogate: cms32 bytesPerWord: 4].
	(Smalltalk classNamed: #NewspeakCogMethodSurrogate64) ifNotNil:
		[:cms64|
		self checkGenerateSurrogate: cms64 bytesPerWord: 8]
]

{ #category : #translation }
NewspeakCogMethod class >> structTypeName [
	^#CogMethod
]

{ #category : #accessing }
NewspeakCogMethod >> nextMethodOrIRCs [
	"Answer the value of nextMethodOrIRCs"

	^ nextMethodOrIRCs
]

{ #category : #accessing }
NewspeakCogMethod >> nextMethodOrIRCs: anObject [
	"Set the value of nextMethodOrIRCs"

	^nextMethodOrIRCs := anObject
]
