"
A MacOSXPowerPCSqueakCogSpur  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

"
Class {
	#name : #SqueakMacOSXPowerPCSqueakSistaSpur,
	#superclass : #SqueakMacOSXPowerPCConfig,
	#category : #'CMakeVMMakerSqueak-MacOSPowerPC'
}

{ #category : #'as yet unclassified' }
SqueakMacOSXPowerPCSqueakSistaSpur class >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default   allBuildConfigurations
]

{ #category : #cmake }
SqueakMacOSXPowerPCSqueakSistaSpur >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
SqueakMacOSXPowerPCSqueakSistaSpur >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakSistaSpur
]

{ #category : #cmake }
SqueakMacOSXPowerPCSqueakSistaSpur >> excludeFromBuild [
	^false

]

{ #category : #'as yet unclassified' }
SqueakMacOSXPowerPCSqueakSistaSpur >> todo [
	self flag:'tty'
]
