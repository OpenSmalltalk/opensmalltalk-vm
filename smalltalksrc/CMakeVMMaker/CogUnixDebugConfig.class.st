"
THis is a concrete class which generates a DEBUG CogVM for Unix systems. This VM is normally known as a debug CogVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.


Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #CogUnixDebugConfig,
	#superclass : #CogUnixConfig,
	#category : #'CMakeVMMaker-Unix'
}

{ #category : #'as yet unclassified' }
CogUnixDebugConfig >> compilerFlags [
	^  String streamContents:  [ :stream |
	self commonCompilerFlags asStringOn: stream delimiter: ' '. 
	self compilerFlagsDebug asStringOn: stream delimiter: ' ' ]
]
