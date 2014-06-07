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
	#name : #SqueakCocoaIOSCogV3MultiThreadedConfig,
	#superclass : #SqueakCocoaIOSCogV3Config,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #settings }
SqueakCocoaIOSCogV3MultiThreadedConfig >> commonCompilerFlags [
	^super commonCompilerFlags, #('-DCOGMTVM=1')
]

{ #category : #'source files' }
SqueakCocoaIOSCogV3MultiThreadedConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #accessing }
SqueakCocoaIOSCogV3MultiThreadedConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
SqueakCocoaIOSCogV3MultiThreadedConfig >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ CoInterpreterMT
]

{ #category : #plugins }
SqueakCocoaIOSCogV3MultiThreadedConfig >> versionExternalPlugins [ 
	^#()
]
