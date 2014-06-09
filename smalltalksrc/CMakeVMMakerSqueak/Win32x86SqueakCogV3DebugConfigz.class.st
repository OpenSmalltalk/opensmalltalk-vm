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
	#name : #Win32x86SqueakCogV3DebugConfigz,
	#superclass : #Win32x86SqueakCogV3Config,
	#category : #'CMakeVMMakerSqueak-IslandOfMisfitToys'
}

{ #category : #directories }
Win32x86SqueakCogV3DebugConfigz >> compilerFlags [
	^ String streamContents:  [ :stream |
	self commonCompilerFlags asStringOn: stream delimiter: ' '. 
	self compilerFlagsDebug asStringOn: stream delimiter: ' ' ]
]

{ #category : #cmake }
Win32x86SqueakCogV3DebugConfigz >> excludeFromBuild [
	^true

]

{ #category : #utils }
Win32x86SqueakCogV3DebugConfigz >> setExtraTargetProperties: maker [

	maker addExternalLibraries: self externalLibraries.
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: '${outputDir}'.


]
