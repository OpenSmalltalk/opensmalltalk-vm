"
An exception class for the use of VMMaker
"
Class {
	#name : #VMMakerException,
	#superclass : #Error,
	#category : #'Slang-Core'
}

{ #category : #'priv handling' }
VMMakerException >> isResumable [
	^true
]
