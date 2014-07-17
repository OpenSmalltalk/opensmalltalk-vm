Class {
	#name : #CMakeVMSoundCustom,
	#superclass : #CMakeVMDriverWrapper,
	#category : #'CMakeVMMakerSqueak-VMDriver'
}

{ #category : #'initialize-release' }
CMakeVMSoundCustom >> initialize [
	super initialize.
	driver:='vm-sound-custom'
]
