Class {
	#name : #VMMockSchedulerAssociation,
	#superclass : #VMMockObject,
	#instVars : [
		'key',
		'value'
	],
	#category : #'VMMakerCompatibilityForPharo6-Tests'
}

{ #category : #'instance-creation' }
VMMockSchedulerAssociation class >> on: aVMMockProcess [ 
	
	^ self new
		value: aVMMockProcess;
		yourself
]

{ #category : #accessing }
VMMockSchedulerAssociation >> value: aVMMockProcess [ 
	value := aVMMockProcess
]
