"
An exception class for the use of VMMaker
"
Class {
	#name : #VMMakerException,
	#superclass : #Error,
	#category : 'VMMaker-Building'
}

{ #category : #'priv handling' }
VMMakerException >> isResumable [
	^true
]
