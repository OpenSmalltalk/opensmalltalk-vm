"
This is a concrete class which generates a thread-aware VM and threaded FFI CogVM for Mac using the Cocoa library. This VM is normally known as CogMTVM.

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #CogMTCocoaIOSConfig,
	#superclass : #CogCocoaIOSConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #settings }
CogMTCocoaIOSConfig >> commonCompilerFlags [
	^super commonCompilerFlags, #('-DCOGMTVM=1')
]

{ #category : #'source files' }
CogMTCocoaIOSConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #accessing }
CogMTCocoaIOSConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
CogMTCocoaIOSConfig >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ CoInterpreterMT
]

{ #category : #plugins }
CogMTCocoaIOSConfig >> versionExternalPlugins [ 
	^Array 
		with: #ThreadedIA32FFIPlugin
]
