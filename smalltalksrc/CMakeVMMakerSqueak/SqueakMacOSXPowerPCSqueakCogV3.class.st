"
A MacOSXPowerPCSqueakCogSpur  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

"
Class {
	#name : #SqueakMacOSXPowerPCSqueakCogV3,
	#superclass : #SqueakMacOSXPowerPCConfig,
	#category : #'CMakeVMMakerSqueak-MacOSPowerPC'
}

{ #category : #'as yet unclassified' }
SqueakMacOSXPowerPCSqueakCogV3 class >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default   allBuildConfigurations
]

{ #category : #cmake }
SqueakMacOSXPowerPCSqueakCogV3 >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
SqueakMacOSXPowerPCSqueakCogV3 >> excludeFromBuild [
	^false

]

{ #category : #'as yet unclassified' }
SqueakMacOSXPowerPCSqueakCogV3 >> todo [
	self flag:'tty'
]
