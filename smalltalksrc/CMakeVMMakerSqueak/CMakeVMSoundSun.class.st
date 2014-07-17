Class {
	#name : #CMakeVMSoundSun,
	#superclass : #CMakeVMDriverWrapper,
	#category : #'CMakeVMMakerSqueak-VMDriver'
}

{ #category : #'initialize-release' }
CMakeVMSoundSun >> initialize [
	super initialize.
	driver:='vm-sound-Sun'
]
