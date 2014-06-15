"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakWin32x86Builder 
	configureABuildFor: #MYCLASSNAMEHERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

"
Class {
	#name : #Win32x86NewspeakSistaV3Config,
	#superclass : #SqueakWin32x86CogFamilyConfig,
	#category : #'CMakeVMMakerSqueak-Win32x86'
}

{ #category : #'source files' }
Win32x86NewspeakSistaV3Config >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #cmake }
Win32x86NewspeakSistaV3Config >> dirBuildLanguageVMMM [
	^self newspeakSistaV3
]

{ #category : #cmake }
Win32x86NewspeakSistaV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #accessing }
Win32x86NewspeakSistaV3Config >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
Win32x86NewspeakSistaV3Config >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ StackInterpreter
]

{ #category : #'source generation' }
Win32x86NewspeakSistaV3Config >> prepareForGeneration [
	^ self prepareForStackVMGeneration
]
