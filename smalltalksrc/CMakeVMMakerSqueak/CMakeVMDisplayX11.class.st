Class {
	#name : #CMakeVMDisplayX11,
	#superclass : #CMakeVMDriverWrapper,
	#category : #'CMakeVMMakerSqueak-VMDriver'
}

{ #category : #'initialize-release' }
CMakeVMDisplayX11 >> initialize [
	super initialize.
	driver:='vm-display-X11'
]
