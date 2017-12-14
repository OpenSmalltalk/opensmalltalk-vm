"
A ThreadedFFICalloutStateForX64SysV is a holder for the callout state maintained while marshalling an FFI call on an X64 (x86-64) system using the System V ABI.
"
Class {
	#name : #ThreadedFFICalloutStateForX64SysV,
	#superclass : #ThreadedFFICalloutStateForX64,
	#category : #'VMMaker-Plugins-FFI'
}

{ #category : #accessing }
ThreadedFFICalloutStateForX64SysV class >> pluginClass [
	^ThreadedX64SysVFFIPlugin
]
