Class {
	#name : #CogDebugUnixConfig,
	#superclass : #CogUnixConfig,
	#category : #'CMakeVMMaker-Unix-Cog'
}

{ #category : #'as yet unclassified' }
CogDebugUnixConfig >> compilerFlags [

	^ self compilerFlagsDebug
]
