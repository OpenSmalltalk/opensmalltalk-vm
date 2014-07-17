Class {
	#name : #CMakeVMSoundSun,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMSoundSun >> initialize [
	super initialize.
	driver:='vm-sound-Sun'
]
