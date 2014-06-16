"
A MacOSX32x86NewspeakStackSpur  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakMacOSX32x86Builder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

"
Class {
	#name : #MacOSX32x86NewspeakSistaSpur,
	#superclass : #SqueakMacOSX32x86Config,
	#category : #'CMakeVMMakerSqueak-MacOSX32x86'
}

{ #category : #cmake }
MacOSX32x86NewspeakSistaSpur >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
MacOSX32x86NewspeakSistaSpur >> dirBuildLanguageVMMM [
	^self newspeakSistaSpur
]

{ #category : #cmake }
MacOSX32x86NewspeakSistaSpur >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
MacOSX32x86NewspeakSistaSpur >> executableName [
	^ self vmSistaExecutableName
]
