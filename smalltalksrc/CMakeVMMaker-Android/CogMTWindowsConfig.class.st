"
This is a concrete class which generates a thread-aware VM and threaded FFI CogVM for Win32. This VM is normally known as CogMTVM.


Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #CogMTWindowsConfig,
	#superclass : #CogWindowsConfig,
	#category : #'CMakeVMMaker-Windows'
}

{ #category : #'compiler flags' }
CogMTWindowsConfig >> compilerFlags [
	^ super compilerFlags, ' -DCOGMTVM=1'
]

{ #category : #'plugin extra rules' }
CogMTWindowsConfig >> configureReentrantIA32FFIPlugin: maker [
	self error: 'use ThreadedIA32FFIPlugin instead'

]

{ #category : #'source files' }
CogMTWindowsConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #plugins }
CogMTWindowsConfig >> defaultExternalPlugins [

	^ #(
		ThreadedIA32FFIPlugin "SqueakFFIPrims"
	
		"Win32OSProcessPlugin"
	)
]

{ #category : #accessing }
CogMTWindowsConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
CogMTWindowsConfig >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ CoInterpreterMT
]
