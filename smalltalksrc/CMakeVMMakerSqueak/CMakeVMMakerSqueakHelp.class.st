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
CMakeVMMakerSqueakHelp class >> introduction [
	^HelpTopic
		title:'Introduction to CMakeVMMakerSqueak'
		contents:
'CMakeVMMakerSqueak is a Squeak extension (not a fork) of Igor Stasenko''s CMakeVMMaker package for Pharo.

 

  The package''s goal is to (eventually) replace the GNU-Build system for Eliot Miranda''s Cog Virtual Machines. (http://www.mirandabanda.org/cog/)					

   
     

'
]

{ #category : #accessing }
CMakeVMMakerSqueakHelp class >> pages [
	^#(introduction)
]
