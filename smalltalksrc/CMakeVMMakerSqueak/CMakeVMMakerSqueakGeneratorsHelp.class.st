Class {
	#name : #CMakeVMMakerSqueakGeneratorsHelp,
	#superclass : #CMakeVMMakerSqueakDeveloperHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakGeneratorsHelp class >> bookName [ 
	^'Generators'
]

{ #category : #accessing }
CMakeVMMakerSqueakGeneratorsHelp class >> key [
	^'CMakeVMMakerSqueakGeneratorsHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakGeneratorsHelp class >> overview [
	^HelpTopic
		title: 'Overview'
		contents:
'Generators Generate.'
]

{ #category : #accessing }
CMakeVMMakerSqueakGeneratorsHelp class >> pages [
	^#(overview CMakeVMMakerSqueakVMGeneratorHelp CMakeVMMakerSqueakPluginGeneratorHelp CMakeVMMakerSqueakDistroGeneratorHelp)
]
