Class {
	#name : #SqueakStackSpurBuilder,
	#superclass : #Object,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #'as yet unclassified' }
SqueakStackSpurBuilder >> todo [
	self flag:'tty'
"massive refactor this to support assert, debug, i-timer, mt and production builds"
]
