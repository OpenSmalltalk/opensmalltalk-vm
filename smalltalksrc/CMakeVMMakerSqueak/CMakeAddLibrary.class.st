"
I encapsulate the simplest version of the CMake add_library command.

If you want additional versions, either copy me or enhance me.

You can see the documentation with
cmake --help-command add_library

add_library
-----------

Add a library to the project using the specified source files.

::

 add_library(<name> [STATIC | SHARED | MODULE]
             [EXCLUDE_FROM_ALL]
             source1 [source2 ...])


"
Class {
	#name : #CMakeAddLibrary,
	#superclass : #CMakeTemplate,
	#instVars : [
		'library',
		'type',
		'sources',
		'exclude'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #'initialize-release' }
CMakeAddLibrary >> initialize [
	library := '<name>'.
	type := '[STATIC | SHARED | MODULE]'.
	exclude := '  [EXCLUDE_FROM_ALL]'.
	sources := OrderedCollection with: 'source1' with: '[source2....]' .
	self content:'  add_library(', library, ' ' , ' ' , type, ' ' , ' ' ,  exclude , ' ' ,self sources,  ')'

]

{ #category : #accessing }
CMakeAddLibrary >> library: lString type: tString exclude: eString sources: anObject [
	library := lString.
	type := tString.
	exclude:= eString.
	sources := anObject.
	self content:'  add_library(', library, ' ' , ' ' , type, ' ' , ' ' ,  exclude , ' ' ,self sources,  ')'
	
]

{ #category : #accessing }
CMakeAddLibrary >> library: lString type: tString sources: anObject [
	library := lString.
	type := tString.
	exclude:= ''.
	sources := anObject.
	self content:'  add_library(', library, ' ' , ' ' , type, ' ' , ' ' ,  exclude , ' ' ,self sources,  ')'
	
]

{ #category : #accessing }
CMakeAddLibrary >> list: aString elements: anObject [
	list:=aString.
	elements := anObject.
	self content:'  list( APPEND ', list, ' ' , self elements,  ')'
	
]

{ #category : #accessing }
CMakeAddLibrary >> sources [
	self flag:'tty'. "see CMakeListAppend>>elements for inject method to use If I have doublequotes are needed. "
	^ String streamContents: [:stream | sources asStringOn: stream delimiter: ' ' ]

]

{ #category : #accessing }
CMakeAddLibrary >> sources: anObject [

	sources := anObject
]

{ #category : #accessing }
CMakeAddLibrary >> type [

	^ type
]

{ #category : #accessing }
CMakeAddLibrary >> type: anObject [

	type := anObject
]
