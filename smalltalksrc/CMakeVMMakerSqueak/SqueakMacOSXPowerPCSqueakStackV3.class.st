"
A MacOSXPowerPCSqueakStackV3  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakMacOSPowerPCBuilder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #SqueakMacOSXPowerPCSqueakStackV3,
	#superclass : #SqueakMacOSXPowerPCConfig,
	#category : #'CMakeVMMakerSqueak-MacOSPowerPC'
}

{ #category : #'as yet unclassified' }
SqueakMacOSXPowerPCSqueakStackV3 class >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default   allBuildConfigurations
]

{ #category : #cmake }
SqueakMacOSXPowerPCSqueakStackV3 >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #'source generation' }
SqueakMacOSXPowerPCSqueakStackV3 >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #cmake }
SqueakMacOSXPowerPCSqueakStackV3 >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
SqueakMacOSXPowerPCSqueakStackV3 >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
SqueakMacOSXPowerPCSqueakStackV3 >> executableName [
	^ self vmStackExecutableName
]

{ #category : #'source generation' }
SqueakMacOSXPowerPCSqueakStackV3 >> interpreterClass [
	^ StackInterpreter
]
