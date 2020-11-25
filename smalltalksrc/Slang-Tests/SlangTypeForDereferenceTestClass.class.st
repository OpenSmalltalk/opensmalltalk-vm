Class {
	#name : #SlangTypeForDereferenceTestClass,
	#superclass : #SlangClass,
	#category : #'Slang-Tests'
}

{ #category : #'as yet unclassified' }
SlangTypeForDereferenceTestClass >> aMethodReturningAMessageSendToSelf [
	^ self aMethodReturningAPointerType
]

{ #category : #'as yet unclassified' }
SlangTypeForDereferenceTestClass >> aMethodReturningAPointerType [
	<var:#a type:#'int*'>
	| a |
	^ a
]

{ #category : #'as yet unclassified' }
SlangTypeForDereferenceTestClass >> aMethodReturningAnAtOnAMatrix [
	<var:#a type:#'int**'>
	| a |
	^ a at: 2
]

{ #category : #'as yet unclassified' }
SlangTypeForDereferenceTestClass >> aMethodReturningAnAtOnAnArray [
	<var:#a type:#'int*'>
	| a |
	^ a at: 2
]

{ #category : #'as yet unclassified' }
SlangTypeForDereferenceTestClass >> aMethodReturningTwoAtOnAMatrix [
	<var:#a type:#'int**'>
	| a |
	^ (a at: 2) at: 2
]
