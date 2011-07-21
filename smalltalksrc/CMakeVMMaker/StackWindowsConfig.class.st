"
This is a configuration for building StackVM on Win32 platform.


Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #StackWindowsConfig,
	#superclass : #CogWindowsConfig,
	#category : #'CMakeVMMaker-Windows'
}

{ #category : #'source files' }
StackWindowsConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #accessing }
StackWindowsConfig >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
StackWindowsConfig >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ StackInterpreter
]

{ #category : #'source generation' }
StackWindowsConfig >> prepareForGeneration [

	CrLfFileStream defaultToLF. "For strange reason it works like that"
	
	^ self prepareForStackVMGeneration
]
