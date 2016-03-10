Class {
	#name : #StackEvtUnixDebugConfig,
	#superclass : #StackEvtUnixConfig,
	#category : #'CMakeVMMaker-Unix'
}

{ #category : #'compiler flags' }
StackEvtUnixDebugConfig >> compilerFlags [
	^ String streamContents:  [ :stream |
	self commonCompilerFlags asStringOn: stream delimiter: ' '. 
	self compilerFlagsDebug asStringOn: stream delimiter: ' ' ]
]
