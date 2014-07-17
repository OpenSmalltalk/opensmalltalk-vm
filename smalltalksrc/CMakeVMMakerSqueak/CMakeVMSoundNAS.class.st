Class {
	#name : #CMakeVMSoundNAS,
	#superclass : #CMakeVMDriverWrapper,
	#category : #'CMakeVMMakerSqueak-VMDriver'
}

{ #category : #'initialize-release' }
CMakeVMSoundNAS >> initialize [
	super initialize.
	driver:='vm-sound-NAS'
]
