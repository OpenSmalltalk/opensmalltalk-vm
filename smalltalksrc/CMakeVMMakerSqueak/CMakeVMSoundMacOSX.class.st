Class {
	#name : #CMakeVMSoundMacOSX,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMSoundMacOSX >> initialize [
	super initialize.
	driver:='vm-sound-MacOSX'
]
