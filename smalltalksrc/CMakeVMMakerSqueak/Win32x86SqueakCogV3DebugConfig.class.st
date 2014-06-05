"
A SqueakCogWindowsDebugConfig adds a debugging stuff to its parent config

Usage:
SqueakCogMTWindowsDebugConfig generateWithSources
Or:
SqueakCogMTWindowsDebugConfig generate

"
Class {
	#name : #Win32x86SqueakCogV3DebugConfig,
	#superclass : #Win32x86SqueakCogV3Config,
	#category : #'CMakeVMMakerSqueak-Win32x86'
}

{ #category : #'as yet unclassified' }
Win32x86SqueakCogV3DebugConfig >> compilerFlags [
	^ String streamContents:  [ :stream |
	self commonCompilerFlags asStringOn: stream delimiter: ' '. 
	self compilerFlagsDebug asStringOn: stream delimiter: ' ' ]
]

{ #category : #'as yet unclassified' }
Win32x86SqueakCogV3DebugConfig >> setExtraTargetProperties: maker [

	maker addExternalLibraries: self externalLibraries.
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: '${outputDir}'.


]
