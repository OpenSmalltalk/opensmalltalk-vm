Class {
	#name : #UnicornTimeout,
	#superclass : #Error,
	#instVars : [
		'target'
	],
	#category : #VMMakerTests
}

{ #category : #accessing }
UnicornTimeout >> target [
	^ target
]

{ #category : #accessing }
UnicornTimeout >> target: anObject [
	target := anObject
]
