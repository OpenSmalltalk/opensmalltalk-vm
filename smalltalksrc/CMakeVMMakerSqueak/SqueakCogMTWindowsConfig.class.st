"
This is a concrete class which generates a thread-aware VM and threaded FFI CogVM for Win32. This VM is normally known as CogMTVM.


For more information, check the class comments of all the superclasses.

Usage:
SqueakCogMTWindowsConfig generateWithSources
Or:
SqueakCogMTWindowsConfig generate

"
Class {
	#name : #SqueakCogMTWindowsConfig,
	#superclass : #SqueakCogWindowsConfig,
	#category : #'CMakeVMMakerSqueak-Windows'
}

{ #category : #'compiler flags' }
SqueakCogMTWindowsConfig >> compilerFlags [
	^ super compilerFlags, ' -DCOGMTVM=1'
]

{ #category : #'plugin extra rules' }
SqueakCogMTWindowsConfig >> configureReentrantIA32FFIPlugin: maker [
	self error: 'use ThreadedIA32FFIPlugin instead'

]

{ #category : #'source files' }
SqueakCogMTWindowsConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #plugins }
SqueakCogMTWindowsConfig >> defaultExternalPlugins [

	^ #(
		ThreadedIA32FFIPlugin "SqueakFFIPrims"
	
		"Win32OSProcessPlugin"
	)
]

{ #category : #accessing }
SqueakCogMTWindowsConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
SqueakCogMTWindowsConfig >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ CoInterpreterMT
]
