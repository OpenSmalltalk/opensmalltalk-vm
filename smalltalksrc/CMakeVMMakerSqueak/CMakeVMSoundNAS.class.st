"
A CMakeVMSoundNAS is a data-bucket that holds configration information
"
Class {
	#name : #CMakeVMSoundNAS,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMSoundNAS >> initialize [
	super initialize.
	module :='vm-sound-NAS'
]
