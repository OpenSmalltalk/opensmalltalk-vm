Class {
	#name : #ReenterInterpreter,
	#superclass : #Notification,
	#instVars : [
		'returnValue'
	],
	#category : #'VMMaker-JITSimulation'
}

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
