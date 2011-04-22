"
StackInterpreterDebugUnixConfig is a concrete class which generates a DEBUG StackVM for Unix systems. This VM is normally known as a debug StackVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.
"
Class {
	#name : #StackInterpreterDebugUnixConfig,
	#superclass : #StackInterpreterUnixConfig,
	#category : #'CMakeVMMaker-Unix-Cog'
}

{ #category : #'compiler flags' }
StackInterpreterDebugUnixConfig >> compilerFlags [

	^  self commonCompilerFlags, ' ' ,self compilerFlagsDebug
]
