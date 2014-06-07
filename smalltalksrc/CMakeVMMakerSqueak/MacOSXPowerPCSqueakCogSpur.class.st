"
A MacOSXPowerPCSqueakCogSpur  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

"
Class {
	#name : #MacOSXPowerPCSqueakCogSpur,
	#superclass : #SqueakMacOSV3Config,
	#category : #'CMakeVMMakerSqueak-MacOSPowerPC'
}

{ #category : #'as yet unclassified' }
MacOSXPowerPCSqueakCogSpur class >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder allBuildConfigurations
]

{ #category : #'as yet unclassified' }
MacOSXPowerPCSqueakCogSpur >> todo [
	self flag:'tty'
]
