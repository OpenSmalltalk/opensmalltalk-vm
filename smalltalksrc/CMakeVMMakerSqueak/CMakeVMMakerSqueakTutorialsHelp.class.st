Class {
	#name : #CMakeVMMakerSqueakTutorialsHelp,
	#superclass : #CMakeVMMakerSqueakHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakTutorialsHelp class >> bookName [ 
	^'Tutorials'
]

{ #category : #accessing }
CMakeVMMakerSqueakTutorialsHelp class >> key [
	^'CMakeVMMakerSqueakTutorialsHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialsHelp class >> pages [
	^#( CMakeVMMakerSqueakTutorialEndUserHelp CMakeVMMakerSqueakTutorialNewConfigurationHelp CMakeVMMakerSqueakTutorialNewBuilderHelp)
	

]

{ #category : #accessing }
CMakeVMMakerSqueakTutorialsHelp class >> priority [

	^ 2
]
