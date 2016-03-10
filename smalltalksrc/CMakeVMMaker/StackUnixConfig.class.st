"
This is a concrete class which generates a StackVM for Unix.

Usage: 
StackInterpreterUnixConfig generateWithSources


Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #StackUnixConfig,
	#superclass : #CogUnixConfig,
	#category : #'CMakeVMMaker-Unix'
}

{ #category : #sources }
StackUnixConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #accessing }
StackUnixConfig >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
StackUnixConfig >> interpreterClass [
	^ StackInterpreter
]

{ #category : #'source generation' }
StackUnixConfig >> prepareForGeneration [
	^ self prepareForStackVMGeneration

]
