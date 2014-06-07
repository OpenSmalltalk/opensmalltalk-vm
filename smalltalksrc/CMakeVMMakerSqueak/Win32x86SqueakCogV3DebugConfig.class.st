"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

Usage:
Win32x86SqueakCogV3DebugConfig generateWithSources
Or:
Win32x86SqueakCogV3DebugConfig generate
Or: 
find my Builder in CMakeVMMakerSqueak-Builder category and use that to invoke me.

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
