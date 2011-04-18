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
