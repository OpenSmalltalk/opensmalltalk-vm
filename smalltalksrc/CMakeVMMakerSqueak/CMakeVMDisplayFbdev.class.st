"
A CMakeVMDisplayFbdev  is a data-bucket that holds configration information
"
Class {
	#name : #CMakeVMDisplayFbdev,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMDisplayFbdev >> initialize [
	super initialize.
	module :='vm-display-fbdev'
]
