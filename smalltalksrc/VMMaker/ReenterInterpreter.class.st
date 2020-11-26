Class {
	#name : #ReenterInterpreter,
	#superclass : #Notification,
	#instVars : [
		'returnValue',
		'properties'
	],
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
ReenterInterpreter >> properties [
	
	^ properties ifNil: [ properties := Dictionary new ]
]

{ #category : #accessing }
ReenterInterpreter >> returnValue [
	"Answer the value of returnValue"

	^ returnValue
]

{ #category : #accessing }
ReenterInterpreter >> returnValue: anObject [
	"Set the value of returnValue"

	returnValue := anObject
]
