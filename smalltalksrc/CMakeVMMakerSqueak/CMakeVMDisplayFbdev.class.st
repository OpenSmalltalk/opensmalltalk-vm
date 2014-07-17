Class {
	#name : #CMakeVMDisplayFbdev,
	#superclass : #CMakeVMDriverWrapper,
	#category : #'CMakeVMMakerSqueak-VMDriver'
}

{ #category : #'initialize-release' }
CMakeVMDisplayFbdev >> initialize [
	super initialize.
	driver:='vm-display-fbdev'
]
