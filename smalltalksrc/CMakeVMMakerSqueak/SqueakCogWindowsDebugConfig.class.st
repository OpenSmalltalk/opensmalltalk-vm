"
A SqueakCogWindowsDebugConfig adds a debugging stuff to its parent config

Usage:
SqueakCogMTWindowsDebugConfig generateWithSources
Or:
SqueakCogMTWindowsDebugConfig generate

"
Class {
	#name : #SqueakCogWindowsDebugConfig,
	#superclass : #SqueakCogWindowsConfig,
	#category : #'CMakeVMMakerSqueak-Windows'
}

{ #category : #'as yet unclassified' }
SqueakCogWindowsDebugConfig >> compilerFlags [
	^ String streamContents:  [ :stream |
	self commonCompilerFlags asStringOn: stream delimiter: ' '. 
	self compilerFlagsDebug asStringOn: stream delimiter: ' ' ]
]

{ #category : #'as yet unclassified' }
SqueakCogWindowsDebugConfig >> setExtraTargetProperties: maker [

	maker addExternalLibraries: self externalLibraries.
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: '${outputDir}'.


]
