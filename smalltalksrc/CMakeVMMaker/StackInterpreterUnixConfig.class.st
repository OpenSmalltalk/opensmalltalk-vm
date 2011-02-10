"
Usage: 
StackInterpreterUnixConfig generateWithSources
"
Class {
	#name : #StackInterpreterUnixConfig,
	#superclass : #CogUnixConfig,
	#category : #'CMakeVMMaker-Unix-Cog'
}

{ #category : #'as yet unclassified' }
StackInterpreterUnixConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #'source generation' }
StackInterpreterUnixConfig >> generateSourceFiles [

	self generateStackSources
]
