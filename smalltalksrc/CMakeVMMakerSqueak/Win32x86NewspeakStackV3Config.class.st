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
	#name : #Win32x86NewspeakStackV3Config,
	#superclass : #SqueakWin32x86Config,
	#category : #'CMakeVMMakerSqueak-Win32x86'
}

{ #category : #'source generation' }
Win32x86NewspeakStackV3Config >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #'source files' }
Win32x86NewspeakStackV3Config >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #cmake }
Win32x86NewspeakStackV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
Win32x86NewspeakStackV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
Win32x86NewspeakStackV3Config >> executableName [
	^ self vmStackExecutableName
]

{ #category : #'source generation' }
Win32x86NewspeakStackV3Config >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ StackInterpreter
]
