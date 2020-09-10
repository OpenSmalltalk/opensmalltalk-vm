Class {
	#name : #VMAbstractBuilder,
	#superclass : #Object,
	#instVars : [
		'interpreter',
		'memory'
	],
	#category : #'VMMakerTests-Builders'
}

{ #category : #accessing }
VMAbstractBuilder >> collection: aCollection at: anIndex put: anOop [
	"convinience method to put an oop at a specific place
	No need to take care of the size of the collection, I'm taking care of it!"
	aCollection size > anIndex 
		ifTrue: [ ^ aCollection at: anIndex + 1 put: anOop ].
	
	aCollection size to: anIndex do: [ :i | aCollection add: memory nilObject ].
	aCollection at: anIndex + 1 put: anOop
	
]

{ #category : #accessing }
VMAbstractBuilder >> interpreter [
	^ interpreter
]

{ #category : #accessing }
VMAbstractBuilder >> interpreter: anObject [
	interpreter := anObject
]

{ #category : #accessing }
VMAbstractBuilder >> memory [
	^ memory
]

{ #category : #accessing }
VMAbstractBuilder >> memory: anObject [
	memory := anObject
]
