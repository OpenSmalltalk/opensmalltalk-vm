"
A MacOSX32x86SqueakSistaSpur  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakMacOSX32x86Builder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

"
Class {
	#name : #MacOSX32x86SqueakSistaSpur,
	#superclass : #SqueakMacOSX32x86Config,
	#category : #'CMakeVMMakerSqueak-MacOSX32x86'
}

{ #category : #cmake }
MacOSX32x86SqueakSistaSpur >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #'source generation' }
MacOSX32x86SqueakSistaSpur >> cogitClass [
	^SistaStackToRegisterMappingCogit

]

{ #category : #cmake }
MacOSX32x86SqueakSistaSpur >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakSistaSpur
]

{ #category : #cmake }
MacOSX32x86SqueakSistaSpur >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
MacOSX32x86SqueakSistaSpur >> executableName [
	^ self vmSistaExecutableName
]

{ #category : #'source generation' }
MacOSX32x86SqueakSistaSpur >> interpreterClass [
	^ CoInterpreter

]
