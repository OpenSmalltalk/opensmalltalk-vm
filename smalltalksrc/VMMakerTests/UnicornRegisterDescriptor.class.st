Class {
	#name : #UnicornRegisterDescriptor,
	#superclass : #Object,
	#instVars : [
		'simulator',
		'name'
	],
	#category : #'VMMakerTests-Unicorn'
}

{ #category : #accessing }
UnicornRegisterDescriptor >> name [
	^ name
]

{ #category : #accessing }
UnicornRegisterDescriptor >> name: anObject [
	name := anObject
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
