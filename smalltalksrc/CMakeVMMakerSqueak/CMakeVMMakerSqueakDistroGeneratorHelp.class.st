Class {
	#name : #CMakeVMMakerSqueakDistroGeneratorHelp,
	#superclass : #CMakeVMMakerSqueakGeneratorsHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakDistroGeneratorHelp class >> bookName [ 
	^'Distro Generator'
]

{ #category : #accessing }
CMakeVMMakerSqueakDistroGeneratorHelp class >> key [
	^'CMakeVMMakerSqueakDistroGeneratorHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakDistroGeneratorHelp class >> overview [
	^HelpTopic
		title: 'Overview'
		contents:
'Write me'
]

{ #category : #accessing }
CMakeVMMakerSqueakDistroGeneratorHelp class >> pages [
	^#(overview)
]
