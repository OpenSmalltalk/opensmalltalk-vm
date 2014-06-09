"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

This is a concrete class which generates a thread-aware VM and threaded FFI CogVM for Win32. This VM is normally known as CogMTVM.


For more information, check the class comments of all the superclasses.

Usage:
Win32x86SqueakCogV3MultiThreadedConfig generateWithSources
Or:
Win32x86SqueakCogV3MultiThreadedConfig generate
Or: 
find my Builder in CMakeVMMakerSqueak-Builder category and use that to invoke me.
"
Class {
	#name : #Win32x86SqueakCogV3MultiThreadedConfigz,
	#superclass : #Win32x86SqueakCogV3Config,
	#category : #'CMakeVMMakerSqueak-IslandOfMisfitToys'
}

{ #category : #'compiler flags' }
Win32x86SqueakCogV3MultiThreadedConfigz >> compilerFlags [
	^ super compilerFlags, ' -DCOGMTVM=1'
]

{ #category : #'plugin extra rules' }
Win32x86SqueakCogV3MultiThreadedConfigz >> configureReentrantIA32FFIPlugin: maker [
	self error: 'use ThreadedIA32FFIPlugin instead'

]

{ #category : #'source files' }
Win32x86SqueakCogV3MultiThreadedConfigz >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #plugins }
Win32x86SqueakCogV3MultiThreadedConfigz >> defaultExternalPlugins [

	^ #(
		ThreadedIA32FFIPlugin "SqueakFFIPrims"
	
		"Win32OSProcessPlugin"
	)
]

{ #category : #cmake }
Win32x86SqueakCogV3MultiThreadedConfigz >> excludeFromBuild [
	^false

]

{ #category : #accessing }
Win32x86SqueakCogV3MultiThreadedConfigz >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
Win32x86SqueakCogV3MultiThreadedConfigz >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ CoInterpreterMT
]
