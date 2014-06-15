"
A MacOSX32x86NewspeakCogSpur configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


SqueakMacOSX32x86Builder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

"
Class {
	#name : #MacOSX32x86NewspeakCogSpur,
	#superclass : #SqueakMacOSX32x86Config,
	#category : #'CMakeVMMakerSqueak-MacOSX32x86'
}

{ #category : #cmake }
MacOSX32x86NewspeakCogSpur >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
MacOSX32x86NewspeakCogSpur >> dirBuildLanguageVMMM [
	^self newspeakCogSpur
]

{ #category : #cmake }
MacOSX32x86NewspeakCogSpur >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]
