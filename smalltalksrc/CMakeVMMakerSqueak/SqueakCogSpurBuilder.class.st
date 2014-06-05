Class {
	#name : #SqueakCogSpurBuilder,
	#superclass : #Object,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #'as yet unclassified' }
SqueakCogSpurBuilder >> todo [
	self flag:'tty'
"massive refactor this to support assert, debug, i-timer, mt and production builds"
]
