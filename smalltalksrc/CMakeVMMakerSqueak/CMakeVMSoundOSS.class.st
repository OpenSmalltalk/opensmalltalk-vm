Class {
	#name : #CMakeVMSoundOSS,
	#superclass : #CMakeVMDriverWrapper,
	#category : #'CMakeVMMakerSqueak-VMDriver'
}

{ #category : #'initialize-release' }
CMakeVMSoundOSS >> initialize [
	super initialize.
	driver:='vm-sound-OSS'
]
