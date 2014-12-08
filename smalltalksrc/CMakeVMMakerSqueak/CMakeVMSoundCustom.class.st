"
A CMakeVMSoundCustom is a data-bucket that holds configration information
"
Class {
	#name : #CMakeVMSoundCustom,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMSoundCustom >> initialize [
	super initialize.
	module :='vm-sound-custom'
]
