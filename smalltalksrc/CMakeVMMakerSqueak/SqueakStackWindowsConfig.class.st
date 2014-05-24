"
This is a configuration for building StackVM on Win32 platform.


For more information, check the class comments of all the superclasses.

Usage:
SqueakStackWindowsConfig generateWithSources
Or:
SqueakStackWindowsConfig generate



"
Class {
	#name : #SqueakStackWindowsConfig,
	#superclass : #SqueakCogWindowsConfig,
	#category : #'CMakeVMMakerSqueak-Windows'
}

{ #category : #'source files' }
SqueakStackWindowsConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #accessing }
SqueakStackWindowsConfig >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
SqueakStackWindowsConfig >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ StackInterpreter
]

{ #category : #'source generation' }
SqueakStackWindowsConfig >> prepareForGeneration [
	^ self prepareForStackVMGeneration
]
