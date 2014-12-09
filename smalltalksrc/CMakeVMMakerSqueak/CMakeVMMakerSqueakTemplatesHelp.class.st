Class {
	#name : #CMakeVMMakerSqueakTemplatesHelp,
	#superclass : #CMakeVMMakerSqueakDeveloperHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakTemplatesHelp class >> bookName [ 
	^'CMake Templates'
]

{ #category : #accessing }
CMakeVMMakerSqueakTemplatesHelp class >> key [
	^'CMakeVMMakerSqueakTemplatesHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakTemplatesHelp class >> overview [
	^HelpTopic
		title: 'Overview'
		contents:
'CMake Templates wrap CMake constructs

Motivation: Ian Piumarta''s template approach is compelling. and the string concatenation approach of CMakeVMMaker was too hard on my feeble mind. 

Most are subclasses of CMakeTemplate.
Custom Templates are handy groupings of basic templates.
Composite Templates encapsulate odd or large blocks of CMake constructs.


The templates allow us to think in CMake while coding in Smalltalk.

They are easy to implement as needed.

They are re-usable

CMake constructs can be viewed by invoking ''cmake --help''.



So far the most important constructs are:

cmake --help-command-list
cmake --help-module-list
cmake --help-property-list
cmake --help-variable-list


We will probably have to fine tune the organization as we add to the library of templates.

'
]

{ #category : #accessing }
CMakeVMMakerSqueakTemplatesHelp class >> pages [
	^#(overview)
]
