Class {
	#name : #StackInterpreterFreeBSDConfig,
	#superclass : #CogFreeBSDConfig,
	#category : #'CMakeVMMaker-FreeBSD-Cog'
}

{ #category : #'as yet unclassified' }
StackInterpreterFreeBSDConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #'source generation' }
StackInterpreterFreeBSDConfig >> interpreterClass [
	^ StackInterpreter
]

{ #category : #'source generation' }
StackInterpreterFreeBSDConfig >> prepareForGeneration [

	"force using LF on Macs"
	CrLfFileStream defaultToLF.

	^ self prepareForStackVMGeneration

]
