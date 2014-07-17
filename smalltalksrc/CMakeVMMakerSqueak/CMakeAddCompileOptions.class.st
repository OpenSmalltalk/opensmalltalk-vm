"
cmake --help-command add_compile_options
add_compile_options
-------------------

Adds options to the compilation of source files.

::

 add_compile_options(<option> ...)

Adds options to the compiler command line for sources in the current
directory and below.  This command can be used to add any options, but
alternative commands exist to add preprocessor definitions
(``target_compile_definitions()`` and ``add_definitions()``) or
include directories (``target_include_directories()`` and
``include_directories()``).  See documentation of the
``directory`` and
`` target`` ``COMPILE_OPTIONS`` properties.

Arguments to ``add_compile_options`` may use ""generator expressions"" with
the syntax ``$<...>``.  See the ``cmake-generator-expressions(7)``
manual for available expressions.  See the ``cmake-buildsystem(7)``
manual for more on defining buildsystem properties.

"
Class {
	#name : #CMakeAddCompileOptions,
	#superclass : #CMakeTemplate,
	#instVars : [
		'options'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #'initialize-release' }
CMakeAddCompileOptions >> initialize [
	options := OrderedCollection with: '-enable-FOO' with: '--disable-BAR' .
	self content:'  add_compile_options(',self options,')'
]

{ #category : #accessing }
CMakeAddCompileOptions >> options [
	^ String streamContents: [:stream | options asStringOn: stream delimiter: ' ' ]

]

{ #category : #accessing }
CMakeAddCompileOptions >> options: anObject [
	options := anObject.
	self content:'  add_compile_options(',self options,')'

]
