Class {
	#name : #CMakeVMMakerSqueakHistoryIanPiumartaHelp,
	#superclass : #CMakeVMMakerSqueakHistoryHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakHistoryIanPiumartaHelp class >> bookName [ 
	^'Ian Piumarta''s CMake'
]

{ #category : #pages }
CMakeVMMakerSqueakHistoryIanPiumartaHelp class >> ianPiumarta [ 
	^HelpTopic
		title:'Ian Piumurta''s CMake System'
		contents:
'Ian Piumurta wrote a hand-crafted CMake System for the Standard Interpreter.

You can download it here.

It makes heavy use of templates and macros

It is responsible for the switch to CMake Templates from the pharo string concatenation based approach.

Its structure is:

I am confident that the development of this system will/should proceed towards the CMake model Ian created. Specifically in the simplification
and refactoring of the generateByTemplate method in xyz


'
]

{ #category : #accessing }
CMakeVMMakerSqueakHistoryIanPiumartaHelp class >> key [
	^'CMakeVMMakerSqueakHistoryIanPiumartaHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakHistoryIanPiumartaHelp class >> overview [ 
	^HelpTopic
		title:'Overview'
		contents:
'Ian Piumurta wrote a hand-crafted CMake System for the Standard Interpreter.

You can download it here.

It makes heavy use of templates and macros

It is responsible for the switch to CMake Templates from the pharo string concatenation based approach.

Its structure is:

I am confident that the development of this system will/should proceed towards the CMake model Ian created. Specifically in the simplification
and refactoring of the generateByTemplate method in xyz


'
]

{ #category : #pages }
CMakeVMMakerSqueakHistoryIanPiumartaHelp class >> pages [
	^#( overview)
]
