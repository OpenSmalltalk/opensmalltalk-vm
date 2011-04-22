"
CogDebugUnixConfig is a concrete class which generates a DEBUG CogVM for Unix systems. This VM is normally known as a debug CogVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.
"
Class {
	#name : #CogDebugUnixConfig,
	#superclass : #CogUnixConfig,
	#category : #'CMakeVMMaker-Unix-Cog'
}

{ #category : #'as yet unclassified' }
CogDebugUnixConfig >> compilerFlags [

	^  self commonCompilerFlags, ' ' ,self compilerFlagsDebug
]
