Class {
	#name : #CogDebugMacOSConfig,
	#superclass : #CogMacOSConfig,
	#category : #'CMakeVMMaker-MacOS'
}

{ #category : #'compiler flags' }
CogDebugMacOSConfig >> compilerFlags [

    ^  self compilerFlagsDebug
]
