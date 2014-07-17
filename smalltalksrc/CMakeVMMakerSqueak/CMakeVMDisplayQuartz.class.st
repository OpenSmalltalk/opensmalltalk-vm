Class {
	#name : #CMakeVMDisplayQuartz,
	#superclass : #CMakeVMPlugin,
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #'initialize-release' }
CMakeVMDisplayQuartz >> initialize [
	super initialize.
	driver:='vm-display-Quartz'
]
