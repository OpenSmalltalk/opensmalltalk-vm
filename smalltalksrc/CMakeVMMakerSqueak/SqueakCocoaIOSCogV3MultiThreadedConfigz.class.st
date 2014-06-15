"
This is a concrete class which generates a thread-aware VM and threaded FFI CogVM for Mac using the Cocoa library. This VM is normally known as CogMTVM.

For more information, check the class comments of all the superclasses.


Usage:
  SqueakCocoaIOSCogV3MultiThreadedConfig generate
Or:
  SqueakCocoaIOSCogV3MultiThreadedConfig generateWithSources
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me


"
Class {
	#name : #SqueakCocoaIOSCogV3MultiThreadedConfigz,
	#superclass : #SqueakCocoaIOSSqueakCogV3Config,
	#category : #'CMakeVMMakerSqueak-IslandOfMisfitToys'
}

{ #category : #settings }
SqueakCocoaIOSCogV3MultiThreadedConfigz >> commonCompilerFlags [
	^super commonCompilerFlags, #('-DCOGMTVM=1')
]

{ #category : #'source files' }
SqueakCocoaIOSCogV3MultiThreadedConfigz >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #cmake }
SqueakCocoaIOSCogV3MultiThreadedConfigz >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #accessing }
SqueakCocoaIOSCogV3MultiThreadedConfigz >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
SqueakCocoaIOSCogV3MultiThreadedConfigz >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ CoInterpreterMT
]

{ #category : #plugins }
SqueakCocoaIOSCogV3MultiThreadedConfigz >> versionExternalPlugins [ 
	^#()
]
