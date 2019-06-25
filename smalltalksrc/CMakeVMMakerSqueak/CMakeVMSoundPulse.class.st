"
A CMakeVMSoundPulse is a data-bucket that holds configration information
"
Class {
	#name : #CMakeVMSoundPulse,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMSoundPulse >> initialize [
	super initialize.
	module :='vm-sound-pulse'
]
