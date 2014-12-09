Class {
	#name : #CMakeVMMakerSqueakPluginGeneratorHelp,
	#superclass : #CMakeVMMakerSqueakGeneratorsHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakPluginGeneratorHelp class >> bookName [ 
	^'Plugin Generator'
]

{ #category : #accessing }
CMakeVMMakerSqueakPluginGeneratorHelp class >> key [
	^'CMakeVMMakerSqueakPluginGeneratorHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakPluginGeneratorHelp class >> overview [
	^HelpTopic
		title: 'Overview'
		contents:
'Write me'
]

{ #category : #accessing }
CMakeVMMakerSqueakPluginGeneratorHelp class >> pages [
	^#(overview)
]
