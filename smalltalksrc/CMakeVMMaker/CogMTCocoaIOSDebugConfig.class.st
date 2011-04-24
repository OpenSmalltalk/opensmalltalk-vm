"
This is a concrete class which generates a DEBUG thread-aware VM and threaded FFI CogVM for Mac using the Cocoa library. This VM is normally known as a debug CogMTVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #CogMTCocoaIOSDebugConfig,
	#superclass : #CogMTCocoaIOSConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #'bundle strings' }
CogMTCocoaIOSDebugConfig >> SqueakDebug [ 
	^1
]

{ #category : #testing }
CogMTCocoaIOSDebugConfig >> isRelease [ 
	"I'm a debug"
	^false
]
