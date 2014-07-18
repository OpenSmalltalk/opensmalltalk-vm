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
