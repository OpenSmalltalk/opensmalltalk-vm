"
A CMakeVMSoundOSS is a data-bucket that holds configration information
"
Class {
	#name : #CMakeVMSoundOSS,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMSoundOSS >> initialize [
	super initialize.
	module :='vm-sound-OSS'
]
