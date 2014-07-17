Class {
	#name : #CMakeVMDisplayQuartz,
	#superclass : #CMakeVMDriverWrapper,
	#category : #'CMakeVMMakerSqueak-VMDriver'
}

{ #category : #'initialize-release' }
CMakeVMDisplayQuartz >> initialize [
	super initialize.
	driver:='vm-display-Quartz'
]
