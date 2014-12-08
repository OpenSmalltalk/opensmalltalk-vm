"
A CMakeVMDisplayX11 is a data-bucket that holds configration information
"
Class {
	#name : #CMakeVMDisplayX11,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMDisplayX11 >> initialize [
	super initialize.
	module :='vm-display-X11'
]
