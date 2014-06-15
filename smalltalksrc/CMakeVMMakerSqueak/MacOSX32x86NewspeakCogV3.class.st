"
A MacOSX32x86NewspeakCogV3  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


SqueakMacOSX32x86Builder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #MacOSX32x86NewspeakCogV3,
	#superclass : #SqueakMacOSX32x86Config,
	#category : #'CMakeVMMakerSqueak-MacOSX32x86'
}

{ #category : #cmake }
MacOSX32x86NewspeakCogV3 >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
MacOSX32x86NewspeakCogV3 >> dirBuildLanguageVMMM [
	^self newspeakCogV3
]

{ #category : #cmake }
MacOSX32x86NewspeakCogV3 >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]
