"
A CMakeVMSoundNull is a data-bucket that holds configration information
"
Class {
	#name : #CMakeVMSoundNull,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMSoundNull >> initialize [
	super initialize.
	module :='vm-sound-null'
]
