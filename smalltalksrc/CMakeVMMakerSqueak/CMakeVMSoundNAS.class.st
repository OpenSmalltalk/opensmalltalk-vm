Class {
	#name : #CMakeVMSoundNAS,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMSoundNAS >> initialize [
	super initialize.
	driver:='vm-sound-NAS'
]
