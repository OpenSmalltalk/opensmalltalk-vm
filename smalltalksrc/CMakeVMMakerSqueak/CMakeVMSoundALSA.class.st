"
A CMakeVMSoundALSA is a data-bucket that holds configration information
"
Class {
	#name : #CMakeVMSoundALSA,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMSoundALSA >> initialize [
	super initialize.
	module :='vm-sound-ALSA'
]
