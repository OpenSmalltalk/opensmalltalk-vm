"
A CMakeVMDisplayCustom  is a data-bucket that holds configration information
"
Class {
	#name : #CMakeVMDisplayCustom,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMDisplayCustom >> initialize [
	super initialize.
	module :='vm-display-custom'
]
