Class {
	#name : #StackInterpreterDebugMacOSConfig,
	#superclass : #StackInterpreterMacOSConfig,
	#category : #'CMakeVMMaker-MacOS'
}

{ #category : #'compiler flags' }
StackInterpreterDebugMacOSConfig >> compilerFlags [

    ^  self compilerFlagsDebug
]
