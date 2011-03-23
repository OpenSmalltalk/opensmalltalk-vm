Class {
	#name : #MTCogMsWindowsConfig,
	#superclass : #CogMsWindowsConfig,
	#category : #'CMakeVMMaker-Windows'
}

{ #category : #'compiler flags' }
MTCogMsWindowsConfig >> compilerFlags [
	^ super compilerFlags, ' -DCOGMTVM=1'
]

{ #category : #'plugin extra rules' }
MTCogMsWindowsConfig >> configureReentrantIA32FFIPlugin: maker [
	self error: 'use ThreadedIA32FFIPlugin instead'

]

{ #category : #'source files' }
MTCogMsWindowsConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #plugins }
MTCogMsWindowsConfig >> defaultExternalPlugins [

	^ #(
		ThreadedIA32FFIPlugin "SqueakFFIPrims"
	
		"Win32OSProcessPlugin"
	)
]

{ #category : #accessing }
MTCogMsWindowsConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
MTCogMsWindowsConfig >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ CoInterpreterMT
]
