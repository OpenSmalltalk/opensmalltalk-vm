Class {
	#name : #CMakeVMSoundALSA,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMSoundALSA >> initialize [
	super initialize.
	driver:='vm-sound-ALSA'
]
