Class {
	#name : #StackEvtUnixDebugConfig,
	#superclass : #StackEvtUnixConfig,
	#category : #'CMakeVMMaker-Unix'
}

{ #category : #'compiler flags' }
StackEvtUnixDebugConfig >> compilerFlags [

	^  self commonCompilerFlags, ' ' ,self compilerFlagsDebug
]
