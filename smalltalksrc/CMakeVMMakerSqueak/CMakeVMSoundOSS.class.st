Class {
	#name : #CMakeVMSoundOSS,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMSoundOSS >> initialize [
	super initialize.
	driver:='vm-sound-OSS'
]
