Class {
	#name : #CogWindowsDebugConfig,
	#superclass : #CogWindowsConfig,
	#category : #'CMakeVMMaker-Windows'
}

{ #category : #'as yet unclassified' }
CogWindowsDebugConfig >> compilerFlags [
	^ String streamContents:  [ :stream |
	self commonCompilerFlags asStringOn: stream delimiter: ' '. 
	self compilerFlagsDebug asStringOn: stream delimiter: ' ' ]
]

{ #category : #'as yet unclassified' }
CogWindowsDebugConfig >> setExtraTargetProperties: maker [

	maker addExternalLibraries: self externalLibraries.
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: '${outputDir}'.


]
