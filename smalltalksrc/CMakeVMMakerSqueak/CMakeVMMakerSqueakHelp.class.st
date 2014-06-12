"
A CMakeVMMakerSqueakHelp provides an overview and use help on CMakeVMMakerSqueak
"
Class {
	#name : #CMakeVMMakerSqueakHelp,
	#superclass : #CustomHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakHelp class >> bookName [
	^'CMakeVMMaker'
]

{ #category : #accessing }
CMakeVMMakerSqueakHelp class >> pages [
	^#(CMakeVMMakerSqueakDeveloperHelp)
]
