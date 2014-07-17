Class {
	#name : #CMakeVMDisplayNull,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMDisplayNull >> initialize [
	super initialize.
	driver:='vm-display-null'
]
