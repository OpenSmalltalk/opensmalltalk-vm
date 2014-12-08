"
A CMakeVMSoundSun is a data-bucket that holds configration information
"
Class {
	#name : #CMakeVMSoundSun,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMSoundSun >> initialize [
	super initialize.
	module :='vm-sound-Sun'
]
