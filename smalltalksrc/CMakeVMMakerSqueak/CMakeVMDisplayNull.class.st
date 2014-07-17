Class {
	#name : #CMakeVMDisplayNull,
	#superclass : #CMakeVMDriverWrapper,
	#category : #'CMakeVMMakerSqueak-VMDriver'
}

{ #category : #'initialize-release' }
CMakeVMDisplayNull >> initialize [
	super initialize.
	driver:='vm-display-null'
]
