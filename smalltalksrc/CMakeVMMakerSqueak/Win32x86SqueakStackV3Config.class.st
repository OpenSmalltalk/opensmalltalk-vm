"
This is a configuration for building StackVM on Win32 platform.


For more information, check the class comments of all the superclasses.

Usage:
SqueakStackWindowsConfig generateWithSources
Or:
SqueakStackWindowsConfig generate



"
Class {
	#name : #Win32x86SqueakStackV3Config,
	#superclass : #Win32x86SqueakCogV3Config,
	#category : #'CMakeVMMakerSqueak-Win32x86'
}

{ #category : #'source files' }
Win32x86SqueakStackV3Config >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #accessing }
Win32x86SqueakStackV3Config >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
Win32x86SqueakStackV3Config >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ StackInterpreter
]

{ #category : #'source generation' }
Win32x86SqueakStackV3Config >> prepareForGeneration [
	^ self prepareForStackVMGeneration
]
