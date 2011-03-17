"
StackInterpreterMsWindowsConfig generateWithSources.

Configuration for building Stack-based VM on Win32 platform.
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
StackInterpreterMsWindowsConfig >> generateSourceFiles [
	self generateStackSources
]
