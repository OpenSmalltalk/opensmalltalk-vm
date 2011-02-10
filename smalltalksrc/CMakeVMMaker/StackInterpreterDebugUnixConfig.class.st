"
To generate Stack-based interpreter unix VM with debug info.


Usage: 
StackInterpreterDebugUnixConfig generateWithSources
"
Class {
	#name : #StackInterpreterDebugUnixConfig,
	#superclass : #StackInterpreterUnixConfig,
	#category : #'CMakeVMMaker-Unix-Cog'
}

{ #category : #'compiler flags' }
StackInterpreterDebugUnixConfig >> compilerFlags [

	^ self compilerFlagsDebug
]
