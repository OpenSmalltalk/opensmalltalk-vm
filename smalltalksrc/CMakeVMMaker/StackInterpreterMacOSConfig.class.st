Class {
	#name : #StackInterpreterMacOSConfig,
	#superclass : #CogMacOSConfig,
	#category : #CMakeVMMaker
}

{ #category : #'as yet unclassified' }
StackInterpreterMacOSConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #'as yet unclassified' }
StackInterpreterMacOSConfig >> executableName [
	^ 'StackVM'
]

{ #category : #'as yet unclassified' }
StackInterpreterMacOSConfig >> generateSourceFiles [
	self generateStackSources
]
