"
A MacOSXPowerPCSqueakCogSpur  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

"
Class {
	#name : #SqueakMacOSXPowerPCSqueakSistaV3,
	#superclass : #SqueakMacOSXPowerPCConfig,
	#category : #'CMakeVMMakerSqueak-MacOSPowerPC'
}

{ #category : #'as yet unclassified' }
SqueakMacOSXPowerPCSqueakSistaV3 class >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default   allBuildConfigurations
]

{ #category : #cmake }
SqueakMacOSXPowerPCSqueakSistaV3 >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
SqueakMacOSXPowerPCSqueakSistaV3 >> excludeFromBuild [
	^false

]

{ #category : #'as yet unclassified' }
SqueakMacOSXPowerPCSqueakSistaV3 >> todo [
	self flag:'tty'
]
