"
A MacOSX32x86SqueakCogV3  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakMacOSX32x86Builder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

"
Class {
	#name : #MacOSX32x86SqueakCogV3,
	#superclass : #SqueakMacOSX32x86Config,
	#category : #'CMakeVMMakerSqueak-MacOSX32x86'
}

{ #category : #cmake }
MacOSX32x86SqueakCogV3 >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
MacOSX32x86SqueakCogV3 >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogV3
]

{ #category : #cmake }
MacOSX32x86SqueakCogV3 >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]
