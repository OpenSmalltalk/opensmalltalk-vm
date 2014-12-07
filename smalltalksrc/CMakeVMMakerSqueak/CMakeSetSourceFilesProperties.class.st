"
A CMakeSetSourceFilesProperties looks like this:

TODO: generalize to match the cmake documentation.

SET_SOURCE_FILES_PROPERTIES(file PROPERTIES prop1 value1)


cmake --help-command set_source_files_properties
---------------------------

Source files can have properties that affect how they are built.

::

 set_source_files_properties([file1 [file2 [...]]]
                             PROPERTIES prop1 value1
                             [prop2 value2 [...]])

Set properties associated with source files using a key/value paired
list.  See properties documentation for those known to CMake.
Unrecognized properties are ignored.  Source file properties are
visible only to targets added in the same directory (CMakeLists.txt).

"
Class {
	#name : #CMakeSetSourceFilesProperties,
	#superclass : #CMakeTemplate,
	#instVars : [
		'files',
		'propertiesandvalues'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #accessing }
CMakeSetSourceFilesProperties >> files [
	self flag:'tty'. "see CMakeListAppend>>elements for inject method to use If I have doublequotes are needed. "
	^ String streamContents: [:stream | files asStringOn: stream delimiter: ' ' ]

]

{ #category : #accessing }
CMakeSetSourceFilesProperties >> files: fOrderedCollection propertiesandvalues: pOrderedCollection [

	files := fOrderedCollection.
	propertiesandvalues := pOrderedCollection.
	self content:'  set_source_files_properties (', self files, ' ' , 'PROPERTIES ',  self propertiesandvalues ,  ')'
]

{ #category : #'initialize-release' }
CMakeSetSourceFilesProperties >> initialize [
	self
		initializeFiles;
		initializePropertiesAndValues.
	self content:'  set_source_files_properties (', self files, ' ' , 'PROPERTIES ',  self propertiesandvalues ,  ')'

]

{ #category : #'initialize-release' }
CMakeSetSourceFilesProperties >> initializeFiles [
	files:= OrderedCollection new.
	files
		addLast:('[file1');
		addLast:('[file2');
		addLast:('[...]]]').

]

{ #category : #'initialize-release' }
CMakeSetSourceFilesProperties >> initializePropertiesAndValues [
	propertiesandvalues := OrderedCollection new.
	propertiesandvalues
		addLast:('prop1 value1');
		addLast:('[prop 2 value2');
		addLast:('[...]]').

]

{ #category : #accessing }
CMakeSetSourceFilesProperties >> propertiesandvalues [
 	^ String streamContents: [:stream | propertiesandvalues asStringOn: stream delimiter: ' ' ]

]
