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
	#name : #SqueakMacOSXPowerPCNewspeakCogV3,
	#superclass : #SqueakMacOSXPowerPCConfig,
	#category : #'CMakeVMMakerSqueak-MacOSPowerPC'
}

{ #category : #'as yet unclassified' }
SqueakMacOSXPowerPCNewspeakCogV3 class >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default   allBuildConfigurations
]

{ #category : #cmake }
SqueakMacOSXPowerPCNewspeakCogV3 >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
SqueakMacOSXPowerPCNewspeakCogV3 >> dirBuildLanguageVMMM [
	^self newspeakCogV3
]

{ #category : #cmake }
SqueakMacOSXPowerPCNewspeakCogV3 >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #'as yet unclassified' }
SqueakMacOSXPowerPCNewspeakCogV3 >> todo [
	self flag:'tty'
]
