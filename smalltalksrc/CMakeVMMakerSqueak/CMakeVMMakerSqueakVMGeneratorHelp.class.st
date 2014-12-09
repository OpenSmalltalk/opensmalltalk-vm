Class {
	#name : #CMakeVMMakerSqueakVMGeneratorHelp,
	#superclass : #CMakeVMMakerSqueakGeneratorsHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakVMGeneratorHelp class >> bookName [ 
	^'VM Generator'
]

{ #category : #accessing }
CMakeVMMakerSqueakVMGeneratorHelp class >> key [
	^'CMakeVMMakerSqueakVMGeneratorHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakVMGeneratorHelp class >> overview [
	^HelpTopic
		title: 'Overview'
		contents:
'Write me'
]

{ #category : #accessing }
CMakeVMMakerSqueakVMGeneratorHelp class >> pages [
	^#(overview)
]
