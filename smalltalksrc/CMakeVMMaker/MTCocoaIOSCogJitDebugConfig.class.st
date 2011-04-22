"
MTCocoaIOSCogJitConfig is a concrete class which generates a DEBUG thread-aware VM and threaded FFI CogVM for Mac using the Cocoa library. This VM is normally known as a debug CogMTVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.
"
Class {
	#name : #MTCocoaIOSCogJitDebugConfig,
	#superclass : #MTCocoaIOSCogJitConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #'bundle strings' }
MTCocoaIOSCogJitDebugConfig >> SqueakDebug [ 
	^1
]

{ #category : #testing }
MTCocoaIOSCogJitDebugConfig >> isRelease [ 
	"I'm a debug"
	^false
]
