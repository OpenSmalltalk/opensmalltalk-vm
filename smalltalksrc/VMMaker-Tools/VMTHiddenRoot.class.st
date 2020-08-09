Class {
	#name : #VMTHiddenRoot,
	#superclass : #Object,
	#instVars : [
		'memory',
		'index',
		'label',
		'oop'
	],
	#category : #'VMMaker-Tools'
}

{ #category : #accessing }
VMTHiddenRoot >> index [
	^ index
]

{ #category : #accessing }
VMTHiddenRoot >> index: anObject [
	index := anObject
]

{ #category : #accessing }
VMTHiddenRoot >> label [
	^ label
]

{ #category : #accessing }
VMTHiddenRoot >> label: anObject [
	label := anObject
]

{ #category : #accessing }
VMTHiddenRoot >> memory [
	^ memory
]

{ #category : #accessing }
VMTHiddenRoot >> memory: anObject [
	memory := anObject
]

{ #category : #accessing }
VMTHiddenRoot >> oop [
	^ oop
]

{ #category : #accessing }
VMTHiddenRoot >> oop: anObject [
	oop := anObject
]
