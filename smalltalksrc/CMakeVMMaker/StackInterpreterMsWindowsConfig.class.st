"
StackInterpreterMsWindowsConfig is a configuration for building StackVM on Win32 platform.
"
Class {
	#name : #StackInterpreterMsWindowsConfig,
	#superclass : #CogMsWindowsConfig,
	#category : #'CMakeVMMaker-Windows'
}

{ #category : #'source files' }
StackInterpreterMsWindowsConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #accessing }
StackInterpreterMsWindowsConfig >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
StackInterpreterMsWindowsConfig >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ StackInterpreter
]

{ #category : #'source generation' }
StackInterpreterMsWindowsConfig >> prepareForGeneration [
	^ self prepareForStackVMGeneration
]
