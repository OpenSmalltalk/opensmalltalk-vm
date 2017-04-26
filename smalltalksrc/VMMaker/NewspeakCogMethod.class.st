"
A NewspeakCogMethod is a specialization of CogMethod for Newspeak.  It adds support for the unpairdMethodsList and for implicit receiver caches.  Since the unpairedMethodList only holds methods that are inst var accessors, these cannot have implicit receiver caches.  Therefore we use the same variable for either the next link in the unpairedMethodList or the reference to the method's implciit receiver caches, which keeps the header size down.

Instance Variables
	nextMethodOrIRCs:		<0 or CogMethod * or oop>

nextMethodOrIRCs
	- either 0 or the next link in the unpairedMethodList or the first field of a method's implciit receiver caches

"
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
