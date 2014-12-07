"
CMakeAddDefinitions wraps its cmake command namesake

cmake --help-command add_definitions
add_definitions
---------------

Adds -D define flags to the compilation of source files.

::

 add_definitions(-DFOO -DBAR ...)

Adds definitions to the compiler command line for sources in the current
directory and below.  This command can be used to add any flags, but
it is intended to add preprocessor definitions.  Flags
beginning in -D or /D that look like preprocessor definitions are
automatically added to the ``COMPILE_DEFINITIONS`` directory
property for the current directory.  Definitions with non-trivial values
may be left in the set of flags instead of being converted for reasons of
backwards compatibility.  See documentation of the
``directory``,
``target``,
``source file`` ``COMPILE_DEFINITIONS``
properties for details on adding preprocessor definitions to specific
scopes and configurations.

See the ``cmake-buildsystem(7)`` manual for more on defining
buildsystem properties.

"
Class {
	#name : #CMakeAddDefinitions,
	#superclass : #CMakeTemplate,
	#instVars : [
		'definitions'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #accessing }
CMakeAddDefinitions >> definitions [
	self flag:'tty'. "see CMakeListAppend>>elements for inject method to use If I have doublequotes are needed. "
	^ String streamContents: [:stream | definitions asStringOn: stream delimiter: ' ' ]

]

{ #category : #accessing }
CMakeAddDefinitions >> definitions: anObject [
	definitions := anObject.
	self content:'  add_definitions(',self definitions,')'.

]

{ #category : #'initialize-release' }
CMakeAddDefinitions >> initialize [
	definitions:= OrderedCollection with: '-DFOO' with: '-DBAR' .
	self content:'  add_definitions(',self definitions,')'
]
