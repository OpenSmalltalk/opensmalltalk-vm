"
A CMakeTemplate is encapsulates CMake commands, variables and definitions.
Generators output my contents into their files.

If you need a custom version of my subclasses, just set 'content: your custom content here' on the appropriate subclass (or on me)	


"
Class {
	#name : #CMakeTemplate,
	#superclass : #CMakeGenerator,
	#instVars : [
		'content'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #accessing }
CMakeTemplate >> content [

	^ content
]

{ #category : #accessing }
CMakeTemplate >> content: anObject [

	content := anObject
]
