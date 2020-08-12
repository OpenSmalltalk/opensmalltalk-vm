Class {
	#name : #VMMockProcess,
	#superclass : #VMMockObject,
	#instVars : [
		'nextLink',
		'suspendedContext',
		'priority',
		'myList',
		'threadId'
	],
	#category : #'VMMaker-MT-Tests'
}

{ #category : #accessing }
VMMockProcess >> initialize [

	super initialize.
	nextLink := nil.
	myList := nil.
	priority := 5.
	threadId := 0.
]

{ #category : #testing }
VMMockProcess >> isAffined [

	^ threadId > 0
]

{ #category : #testing }
VMMockProcess >> isTemporarilyAffined [

	"If it is not tagged, it's temporary"
	^ self isAffined and: [ threadId even ]
]

{ #category : #accessing }
VMMockProcess >> myList [
	^ myList
]

{ #category : #accessing }
VMMockProcess >> priority: anInteger [ 

	priority := anInteger
]

{ #category : #accessing }
VMMockProcess >> suspendedContext [
	^ suspendedContext
]

{ #category : #accessing }
VMMockProcess >> suspendedContext: aVMMockContext [ 
	suspendedContext := aVMMockContext
]

{ #category : #accessing }
VMMockProcess >> threadIndex [

	^ threadId >> 1
]
