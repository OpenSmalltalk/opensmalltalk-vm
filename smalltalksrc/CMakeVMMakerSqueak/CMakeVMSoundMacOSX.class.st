Class {
	#name : #CMakeVMSoundMacOSX,
	#superclass : #CMakeVMDriverWrapper,
	#category : #'CMakeVMMakerSqueak-VMDriver'
}

{ #category : #'initialize-release' }
CMakeVMSoundMacOSX >> initialize [
	super initialize.
	driver:='vm-sound-MacOSX'
]
