"
This is a concrete class which generates a thread-aware VM and threaded FFI CogVM for Mac using the Cocoa library. This VM is normally known as CogMTVM.

For more information, check the class comments of all the superclasses.

Usage:
SqueakCogMTCocoaIOSConfig generateWithSources
or:
SqueakCogMTCocoaIOSConfig generate

"
Class {
	#name : #SqueakCogMTCocoaIOSConfig,
	#superclass : #SqueakCogCocoaIOSConfig,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #settings }
SqueakCogMTCocoaIOSConfig >> commonCompilerFlags [
	^super commonCompilerFlags, #('-DCOGMTVM=1')
]

{ #category : #'source files' }
SqueakCogMTCocoaIOSConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #accessing }
SqueakCogMTCocoaIOSConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
SqueakCogMTCocoaIOSConfig >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ CoInterpreterMT
]

{ #category : #plugins }
SqueakCogMTCocoaIOSConfig >> versionExternalPlugins [ 
	^#()
]
