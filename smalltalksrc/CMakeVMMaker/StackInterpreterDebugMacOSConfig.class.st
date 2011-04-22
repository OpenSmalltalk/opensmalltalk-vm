"
StackInterpreterDebugMacOSConfig is a concrete class which generates a DEBUG StackVM for Mac using Carbon library. This VM is normally known as a debug StackVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.
"
Class {
	#name : #StackInterpreterDebugMacOSConfig,
	#superclass : #StackInterpreterMacOSConfig,
	#category : #'CMakeVMMaker-MacOS'
}

{ #category : #'compiler flags' }
StackInterpreterDebugMacOSConfig >> compilerFlags [

    ^  self compilerFlagsDebug
]
