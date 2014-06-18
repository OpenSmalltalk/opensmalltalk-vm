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
	#name : #Win32x86SqueakSistaV3Config,
	#superclass : #SqueakWin32x86Config,
	#category : #'CMakeVMMakerSqueak-Win32x86'
}

{ #category : #'source generation' }
Win32x86SqueakSistaV3Config >> cogitClass [
	^SistaStackToRegisterMappingCogit

]

{ #category : #cmake }
Win32x86SqueakSistaV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakSistaV3
]

{ #category : #cmake }
Win32x86SqueakSistaV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
Win32x86SqueakSistaV3Config >> executableName [
	^ self vmSistaExecutableName
]

{ #category : #'source generation' }
Win32x86SqueakSistaV3Config >> interpreterClass [
	^ CoInterpreter

]
