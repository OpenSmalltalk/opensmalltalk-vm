Class {
	#name : #CMakeVMSoundNull,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMSoundNull >> initialize [
	super initialize.
	driver:='vm-sound-null'
]
