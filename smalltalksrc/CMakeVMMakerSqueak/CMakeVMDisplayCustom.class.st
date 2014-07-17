Class {
	#name : #CMakeVMDisplayCustom,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMDisplayCustom >> initialize [
	super initialize.
	driver:='vm-display-custom'
]
