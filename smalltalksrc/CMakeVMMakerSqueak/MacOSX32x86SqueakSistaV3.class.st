"
A MacOSX32x86SqueakSistaV3  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakMacOSX32x86Builder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #MacOSX32x86SqueakSistaV3,
	#superclass : #SqueakMacOSX32x86Config,
	#category : #'CMakeVMMakerSqueak-MacOSX32x86'
}

{ #category : #cmake }
MacOSX32x86SqueakSistaV3 >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #'source generation' }
MacOSX32x86SqueakSistaV3 >> cogitClass [
	^SistaStackToRegisterMappingCogit

]

{ #category : #cmake }
MacOSX32x86SqueakSistaV3 >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakSistaV3
]

{ #category : #cmake }
MacOSX32x86SqueakSistaV3 >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
MacOSX32x86SqueakSistaV3 >> executableName [
	^ self vmSistaExecutableName
]

{ #category : #'source generation' }
MacOSX32x86SqueakSistaV3 >> interpreterClass [
	^ CoInterpreter

]
