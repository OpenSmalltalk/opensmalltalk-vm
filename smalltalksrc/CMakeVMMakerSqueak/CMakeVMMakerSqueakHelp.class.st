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
	^'CMakeVMMakerSqueak'
]

{ #category : #accessing }
CMakeVMMakerSqueakHelp class >> key [
	^'CMakeVMMakerSqueakHelp'
]

{ #category : #accessing }
CMakeVMMakerSqueakHelp class >> pages [
	^#( CMakeVMMakerSqueakStartHereHelp  CMakeVMMakerSqueakDeveloperHelp CMakeVMMakerSqueakTutorialsHelp )
]
