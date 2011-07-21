"
This is a concrete class which generates a StackVM for FreeBSD.

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #StackFreeBSDConfig,
	#superclass : #CogFreeBSDConfig,
	#category : #'CMakeVMMaker-FreeBSD'
}

{ #category : #'as yet unclassified' }
StackFreeBSDConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #'source generation' }
StackFreeBSDConfig >> interpreterClass [
	^ StackInterpreter
]

{ #category : #'source generation' }
StackFreeBSDConfig >> prepareForGeneration [

	"force using LF on Macs"
	CrLfFileStream defaultToLF.

	^ self prepareForStackVMGeneration

]
