Class {
	#name : #CMakeVMSoundNull,
	#superclass : #CMakeVMDriverWrapper,
	#category : #'CMakeVMMakerSqueak-VMDriver'
}

{ #category : #'initialize-release' }
CMakeVMSoundNull >> initialize [
	super initialize.
	driver:='vm-sound-null'
]
