"
A CMakeInclude looks like 

INCLUDE(fileName)

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
	self content:'  include (',file,')'
]

{ #category : #'initialize-release' }
CMakeInclude >> initialize [
	file := 'foo'.
	self content:'
  INCLUDE(',file,')'
]
