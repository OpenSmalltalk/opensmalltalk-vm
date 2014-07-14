"
A CMakeSetTemplate 's contents look like INCLUDE(fileName)

"
Class {
	#name : #CMakeInclude,
	#superclass : #CMakeTemplate,
	#instVars : [
		'file'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #accessing }
CMakeInclude >> file: fString [ 
	file := fString.
	self content:'
  INCLUDE(',file,')'
]

{ #category : #'initialize-release' }
CMakeInclude >> initialize [
	file := 'foo'.
	self content:'
  INCLUDE(',file,')'
]
