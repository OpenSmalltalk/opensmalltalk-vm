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
	#name : #Win32x86SqueakSistaSpurConfig,
	#superclass : #SqueakWin32x86CogFamilyConfig,
	#category : #'CMakeVMMakerSqueak-Win32x86'
}

{ #category : #'source files' }
Win32x86SqueakSistaSpurConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #cmake }
Win32x86SqueakSistaSpurConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakSistaSpur
]

{ #category : #cmake }
Win32x86SqueakSistaSpurConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #accessing }
Win32x86SqueakSistaSpurConfig >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
Win32x86SqueakSistaSpurConfig >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ StackInterpreter
]

{ #category : #'source generation' }
Win32x86SqueakSistaSpurConfig >> prepareForGeneration [
	^ self prepareForStackVMGeneration
]
