Class {
	#name : #UnicornRegisterDescriptor,
	#superclass : #Object,
	#instVars : [
		'simulator',
		'name',
		'alias'
	],
	#category : #VMMakerTests
}

{ #category : #'as yet unclassified' }
UnicornRegisterDescriptor >> alias [
	^ alias
]

{ #category : #'as yet unclassified' }
UnicornRegisterDescriptor >> alias: aString [ 
	
	alias := aString
]

{ #category : #accessing }
UnicornRegisterDescriptor >> name [
	^ name
]

{ #category : #accessing }
UnicornRegisterDescriptor >> name: anObject [
	name := anObject
]

{ #category : #accessing }
UnicornRegisterDescriptor >> printOn: aStream [

	(self value isKindOf: Boolean )
		ifTrue: [ ^ aStream print: self value ].
		
	aStream print: self value hex	

]

{ #category : #accessing }
UnicornRegisterDescriptor >> simulator [
	^ simulator
]

{ #category : #accessing }
UnicornRegisterDescriptor >> simulator: anObject [
	simulator := anObject
]

{ #category : #accessing }
UnicornRegisterDescriptor >> value [

	^ simulator perform: name
]
