"
CogDebugMacOSConfig is a concrete class which generates a DEBUG CogVM for Mac using Carbon library. This VM is normally known as a debug CogVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.
"
Class {
	#name : #CogDebugMacOSConfig,
	#superclass : #CogMacOSConfig,
	#category : #'CMakeVMMaker-MacOS'
}

{ #category : #'compiler flags' }
CogDebugMacOSConfig >> compilerFlags [

    ^  self compilerFlagsDebug
]
