"
This is a concrete class which generates an event-driven StackVM for Unix.

Usage: 
StackEvtUnixConfig generateWithSources

An event-driven Stack VM is an experiment to make VM return to the host process each time it asks for an event.
If there are events to process, the host resumes VM, otherwise VM does not get control until any event is available.

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #StackEvtUnixConfig,
	#superclass : #CogUnixConfig,
	#category : #'CMakeVMMaker-Unix'
}

{ #category : #'as yet unclassified' }
StackEvtUnixConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #'as yet unclassified' }
StackEvtUnixConfig >> crossSources [
	"answer the same set of source files except that sqTicker.c is dropped"

  ^ super crossSources select: [ :file | (file = 'sqTicker.c') not ].


]

{ #category : #accessing }
StackEvtUnixConfig >> executableName [
	"the name of the VM executable"
	^ 'EventVM'.
]

{ #category : #'source generation' }
StackEvtUnixConfig >> interpreterClass [
	^ StackEvtInterpreter
]

{ #category : #'as yet unclassified' }
StackEvtUnixConfig >> platformSources [
	"answer the same set of source files except that sqUnixMain.c is replaced with sqUnixEvtMain.c,
	sqUnixHeartbeat.c is replaced with sqUnixEvtBeat.c"

  ^ super platformSources collect: [ :file | (file = 'sqUnixMain.c') 
											ifTrue: 'sqUnixEvtMain.c'  
											ifFalse: [(file = 'sqUnixHeartbeat.c') 
												ifTrue: 'sqUnixEvtBeat.c'
												ifFalse: file]
											].


]

{ #category : #'source generation' }
StackEvtUnixConfig >> prepareForGeneration [

	"force using LF on Macs"
	CrLfFileStream defaultToLF.

	^ self prepareForStackVMGeneration

]
