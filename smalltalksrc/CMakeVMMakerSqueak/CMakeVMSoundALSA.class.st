Class {
	#name : #CMakeVMSoundALSA,
	#superclass : #CMakeVMDriverWrapper,
	#category : #'CMakeVMMakerSqueak-VMDriver'
}

{ #category : #'initialize-release' }
CMakeVMSoundALSA >> initialize [
	super initialize.
	driver:='vm-sound-ALSA'
]
