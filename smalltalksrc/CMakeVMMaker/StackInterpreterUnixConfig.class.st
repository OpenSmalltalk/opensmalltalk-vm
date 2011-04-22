"
StackInterpreterUnixConfig is a concrete class which generates a StackVM for Unix.

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
StackInterpreterUnixConfig >> interpreterClass [
	^ StackInterpreter
]

{ #category : #'source generation' }
StackInterpreterUnixConfig >> prepareForGeneration [

	"force using LF on Macs"
	CrLfFileStream defaultToLF.

	^ self prepareForStackVMGeneration

]
