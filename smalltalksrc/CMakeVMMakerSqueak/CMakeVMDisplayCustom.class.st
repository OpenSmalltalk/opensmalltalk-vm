Class {
	#name : #CMakeVMDisplayCustom,
	#superclass : #CMakeVMDriverWrapper,
	#category : #'CMakeVMMakerSqueak-VMDriver'
}

{ #category : #'initialize-release' }
CMakeVMDisplayCustom >> initialize [
	super initialize.
	driver:='vm-display-custom'
]
