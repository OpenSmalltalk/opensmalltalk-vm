"
A Special subclass of VMMaker for building MAc OS-9 browser-plugin vms
"
Class {
	#name : #MacOSPowerPCOS9BrowserVMMaker,
	#superclass : #MacOSPowerPCOS9VMMaker,
	#category : 'VMMaker-Building'
}

{ #category : #initialisation }
MacOSPowerPCOS9BrowserVMMaker class >> isActiveVMMakerClassFor: platformName [
	^false
]

{ #category : #initialize }
MacOSPowerPCOS9BrowserVMMaker >> initialize [
	super initialize.
	forBrowser _ true
]
