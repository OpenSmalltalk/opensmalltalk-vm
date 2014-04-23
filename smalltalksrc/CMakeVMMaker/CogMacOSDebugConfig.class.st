"
This is a concrete class which generates a DEBUG CogVM for Mac using Carbon library. This VM is normally known as a debug CogVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #CogMacOSDebugConfig,
	#superclass : #CogMacOSConfig,
	#category : #'CMakeVMMaker-MacOS'
}

{ #category : #'compiler flags' }
CogMacOSDebugConfig >> compilerFlags [

    ^  self compilerFlagsDebug
]
