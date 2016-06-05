"
A CMakeTemplate  is a wrapper for CMake commands, variables and definitions.
Generators output my contents into their files.

N.B. The motivations for this approach are:

1. I found the Pharo methods  in CMakeGenerator 's (cmake commands protocol) difficult to parse and debug.
2, As I developed it bacame apparent that the key to making this project work is to ""THINK IN CMake"". 
3. I find the Seaside approach of using Components to generate a web-page is a useful idiom for generating CMake files.
4. Using wrappers for the CMake commands eases re-use and consistency that radically sped up development. 
5. It is easy to add new templates. Just find the CMake construct you want, subclass me, and model it such that its output generates the correct CMake ""thing"" 

cmake   --help-commands
cmake   --help-command
cmake   --help-command-list
cmake   --help-commands 
cmake   --help-module
cmake   --help-module-list
cmake   --help-modules 
cmake   --help-policy 
cmake   --help-policy-list 
cmake   --help-policies 
cmake   --help-property 
cmake   --help-property-list 
cmake   --help-properties
cmake   --help-variable var
cmake   --help-variable-list 
cmake   --help-variables




If you need a custom version of my subclasses, just set 'content: your custom content here' on the appropriate subclass (or on me)	


"
Class {
	#name : #CMakeTemplate,
	#superclass : #CMakeGeneratorForSqueak,
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
