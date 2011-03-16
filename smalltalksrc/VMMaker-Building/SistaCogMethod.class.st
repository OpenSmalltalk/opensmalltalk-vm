Class {
	#name : #SistaCogMethod,
	#superclass : #CogMethod,
	#instVars : [
		'numCounters'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
SistaCogMethod class >> structTypeName [
	"Provide the typedef name."
	^superclass structTypeName
]

{ #category : #accessing }
SistaCogMethod >> numCounters [
	"Answer the value of numCounters"

	^ numCounters
]

{ #category : #accessing }
SistaCogMethod >> numCounters: anObject [
	"Set the value of numCounters"

	^numCounters := anObject
]
