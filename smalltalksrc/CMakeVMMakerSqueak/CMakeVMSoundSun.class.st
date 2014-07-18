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
