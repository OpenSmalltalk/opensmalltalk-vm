Class {
	#name : #CogWindowsDebugConfig,
	#superclass : #CogWindowsConfig,
	#category : #'CMakeVMMaker-Windows'
}

{ #category : #'as yet unclassified' }
CogWindowsDebugConfig >> compilerFlags [
	"depends on config ..."
	^ self commonCompilerFlags, ' ' , self compilerFlagsDebug
]

{ #category : #'as yet unclassified' }
CogWindowsDebugConfig >> setExtraTargetProperties: maker [

	maker addExternalLibraries: self externalLibraries.
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: '${outputDir}'.


]
