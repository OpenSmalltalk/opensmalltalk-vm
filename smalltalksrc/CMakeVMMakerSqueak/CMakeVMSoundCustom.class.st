Class {
	#name : #CMakeVMSoundCustom,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMSoundCustom >> initialize [
	super initialize.
	driver:='vm-sound-custom'
]
