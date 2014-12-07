"
A CMakeIncludeDirectories 

 cmake --help-command include_directories
include_directories
-------------------

Add include directories to the build.

::

 include_directories([AFTER|BEFORE] [SYSTEM] dir1 [dir2 ...])

Add the given directories to those the compiler uses to search for
include files.  Relative paths are interpreted as relative to the
current source directory.

The include directories are added to the ``INCLUDE_DIRECTORIES``
directory property for the current ``CMakeLists`` file.  They are also
added to the ``INCLUDE_DIRECTORIES`` target property for each
target in the current ``CMakeLists`` file.  The target property values
are the ones used by the generators.

By default the directories specified are appended onto the current list of
directories.  This default behavior can be changed by setting
``CMAKE_INCLUDE_DIRECTORIES_BEFORE`` to ``ON``.  By using
``AFTER`` or ``BEFORE`` explicitly, you can select between appending and
prepending, independent of the default.

If the ``SYSTEM`` option is given, the compiler will be told the
directories are meant as system include directories on some platforms.
Signalling this setting might achieve effects such as the compiler
skipping warnings, or these fixed-install system files not being
considered in dependency calculations - see compiler docs.

Arguments to ``include_directories`` may use ""generator expressions"" with
the syntax ""$<...>"".  See the ``cmake-generator-expressions(7)``
manual for available expressions.  See the ``cmake-buildsystem(7)``
manual for more on defining buildsystem properties.

"
Class {
	#name : #CMakeIncludeDirectories,
	#superclass : #CMakeTemplate,
	#instVars : [
		'afterorbefore',
		'system',
		'dirs'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #accessing }
CMakeIncludeDirectories >> afterOrBefore: aString dirs: anObject [
	dirs := anObject..
	afterorbefore:= aString.
	system := ''.
	self content:'  include_directories(', afterorbefore, ' ' , system, ' ' ,self dirs,')'
]

{ #category : #accessing }
CMakeIncludeDirectories >> afterOrBefore: aString system: sString dirs: anObject [
	dirs := anObject..
	afterorbefore:= aString.
	system := sString.
	self content:'  include_directories(', afterorbefore, ' ' , system, ' ' ,self dirs,')'
]

{ #category : #accessing }
CMakeIncludeDirectories >> afterorbefore [

	^ afterorbefore
]

{ #category : #accessing }
CMakeIncludeDirectories >> dirs [
	self flag:'tty'. "see CMakeListAppend>>elements for inject method to use If I have doublequotes are needed. "
	^ String streamContents: [:stream | dirs asStringOn: stream delimiter: ' ' ]

]

{ #category : #accessing }
CMakeIncludeDirectories >> dirs: anObject [
	dirs := anObject..
	afterorbefore:= ''.
	system := ''.
	self content:'  include_directories(', afterorbefore, ' ' , system, ' ' ,self dirs,')'
]

{ #category : #'initialize-release' }
CMakeIncludeDirectories >> initialize [
	dirs:= OrderedCollection with: 'foo' with: 'bar' with: 'directories' with:'dude'.
	afterorbefore := '[AFTER|BEFORE]'.
	system:= '[SYSTEM]'.
	self content:'  include_directories(', afterorbefore, ' ' , system, ' ' ,self dirs,')'
]

{ #category : #accessing }
CMakeIncludeDirectories >> system [

	^ system
]

{ #category : #accessing }
CMakeIncludeDirectories >> system: anObject [

	system := anObject
]

{ #category : #accessing }
CMakeIncludeDirectories >> system: sString dirs: anObject [
	dirs := anObject..
	afterorbefore:= ''.
	system := sString.
	self content:'  include_directories(', afterorbefore, ' ' , system, ' ' ,self dirs,')'
]
