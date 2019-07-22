Class {
	#name : #VMLinkedList,
	#superclass : #VMMockObject,
	#instVars : [
		'firstLink',
		'lastLink'
	],
	#category : #'VMMakerCompatibilityForPharo6-Tests'
}

{ #category : #accessing }
VMLinkedList >> add: aProcess [
	self haltIf: [ aProcess isInteger ].
	firstLink
		ifNil: [ firstLink := aProcess]
		ifNotNil: [ lastLink nextLink: aProcess ].
	lastLink := aProcess.
	^ aProcess
]
