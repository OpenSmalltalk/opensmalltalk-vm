Class {
	#name : #ReadOnlyArrayWrapper,
	#superclass : #Object,
	#instVars : [
		'theArray'
	],
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #'instance creation' }
ReadOnlyArrayWrapper class >> around: anArray [
	^self new array: anArray; yourself
]

{ #category : #accessing }
ReadOnlyArrayWrapper >> array [
	^theArray
]

{ #category : #accessing }
ReadOnlyArrayWrapper >> array: anArray [
	theArray := anArray
]

{ #category : #accessing }
ReadOnlyArrayWrapper >> at: index [
	^theArray at: index
]

{ #category : #accessing }
ReadOnlyArrayWrapper >> at: index put: value [
	"Oh where is imutability when you need it??"
	self error: 'attempt to modify memory!!'
]

{ #category : #accessing }
ReadOnlyArrayWrapper >> size [
	^theArray size
]
