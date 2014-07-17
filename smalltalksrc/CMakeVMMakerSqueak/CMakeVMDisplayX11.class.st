Class {
	#name : #CMakeVMDisplayX11,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMDisplayX11 >> initialize [
	super initialize.
	driver:='vm-display-X11'
]
