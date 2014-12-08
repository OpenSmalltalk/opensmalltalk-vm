"
A CMakeVMDisplayNull is a data-bucket that holds configration information
"
Class {
	#name : #CMakeVMDisplayNull,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMDisplayNull >> initialize [
	super initialize.
	module :='vm-display-null'
]
