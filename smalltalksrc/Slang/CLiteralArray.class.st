Class {
	#name : #CLiteralArray,
	#superclass : #Object,
	#instVars : [
		'object'
	],
	#category : #'Slang-Types'
}

{ #category : #'instance creation' }
CLiteralArray class >> on: anArrayLiteral [
	^self new setObject: anArrayLiteral; yourself
]

{ #category : #accessing }
CLiteralArray >> at: offset [
	^object at: offset + 1
]

{ #category : #accessing }
CLiteralArray >> at: offset put: val [
	^object at: offset + 1 put: val
]

{ #category : #accessing }
CLiteralArray >> setObject: anArrayLiteral [
	object := anArrayLiteral
]
