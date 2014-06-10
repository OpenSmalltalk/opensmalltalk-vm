"
A MacOSXPowerPCSqueakCogSpur  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

"
Class {
	#name : #SqueakMacOSXPowerPCNewspeakSistaSpur,
	#superclass : #SqueakMacOSXPowerPCConfig,
	#category : #'CMakeVMMakerSqueak-MacOSPowerPC'
}

{ #category : #'as yet unclassified' }
SqueakMacOSXPowerPCNewspeakSistaSpur class >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default   allBuildConfigurations
]

{ #category : #cmake }
SqueakMacOSXPowerPCNewspeakSistaSpur >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
SqueakMacOSXPowerPCNewspeakSistaSpur >> dirBuildLanguageVMMM [
	^self newspeakSistaSpur
]

{ #category : #cmake }
SqueakMacOSXPowerPCNewspeakSistaSpur >> excludeFromBuild [
	^false

]

{ #category : #'as yet unclassified' }
SqueakMacOSXPowerPCNewspeakSistaSpur >> todo [
	self flag:'tty'
]
