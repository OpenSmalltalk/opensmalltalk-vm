Class {
	#name : #ReenterMachineCode,
	#superclass : #Notification,
	#instVars : [
		'returnValue'
	],
	#category : 'VMMaker-JITSimulation'
}

{ #category : #accessing }
ReenterMachineCode >> returnValue [
	"Answer the value of returnValue"

	^ returnValue
]

{ #category : #accessing }
ReenterMachineCode >> returnValue: anObject [
	"Set the value of returnValue"

	returnValue := anObject
]
