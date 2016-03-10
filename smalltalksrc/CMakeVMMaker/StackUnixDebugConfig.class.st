"
This is a concrete class which generates a DEBUG StackVM for Unix systems. This VM is normally known as a debug StackVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.


Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #StackUnixDebugConfig,
	#superclass : #StackUnixConfig,
	#category : #'CMakeVMMaker-Unix'
}

{ #category : #'compiler flags' }
StackUnixDebugConfig >> compilerFlags [
	^  String streamContents:  [ :stream |
	self commonCompilerFlags asStringOn: stream delimiter: ' '. 
	self compilerFlagsDebug asStringOn: stream delimiter: ' ' ]
]
