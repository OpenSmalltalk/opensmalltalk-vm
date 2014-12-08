"
A CMakeVMSoundMacOSX is a data-bucket that holds configration information
"
Class {
	#name : #CMakeVMSoundMacOSX,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMSoundMacOSX >> initialize [
	super initialize.
	module :='vm-sound-MacOSX'
]
