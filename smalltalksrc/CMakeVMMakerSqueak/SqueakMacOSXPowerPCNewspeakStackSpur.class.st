"
A MacOSXPowerPCSqueakCogSpur  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


SqueakMacOSPowerPCBuilder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #SqueakMacOSXPowerPCNewspeakStackSpur,
	#superclass : #SqueakMacOSXPowerPCConfig,
	#category : #'CMakeVMMakerSqueak-MacOSPowerPC'
}

{ #category : #'as yet unclassified' }
SqueakMacOSXPowerPCNewspeakStackSpur class >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default   allBuildConfigurations
]

{ #category : #cmake }
SqueakMacOSXPowerPCNewspeakStackSpur >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
SqueakMacOSXPowerPCNewspeakStackSpur >> dirBuildLanguageVMMM [
	^self newspeakStackSpur
]

{ #category : #cmake }
SqueakMacOSXPowerPCNewspeakStackSpur >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #'as yet unclassified' }
SqueakMacOSXPowerPCNewspeakStackSpur >> todo [
	self flag:'tty'
]
