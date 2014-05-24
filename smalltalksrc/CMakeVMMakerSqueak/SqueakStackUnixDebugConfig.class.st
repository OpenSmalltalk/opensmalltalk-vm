"
This is a concrete class which generates a DEBUG StackVM for Unix systems. This VM is normally known as a debug StackVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.

Usage:
SqueakStackUnixDebugConfig generateWithSources
Or:
SqueakStackUnixDebugConfig generate

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #SqueakStackUnixDebugConfig,
	#superclass : #SqueakStackUnixConfig,
	#category : #'CMakeVMMakerSqueak-Unix'
}

{ #category : #'as yet unclassified' }
SqueakStackUnixDebugConfig >> defaultExternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultExternalPlugins copyWithoutAll: #(#ThreadedIA32FFIPlugin #InternetConfigPlugin #FT2Plugin))
]

{ #category : #'as yet unclassified' }
SqueakStackUnixDebugConfig >> defaultInternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultInternalPlugins copyWithoutAll: #(#IA32ABIPlugin #JoystickTabletPlugin #StarSqueakPlugin #SurfacePlugin #SqueakFFIPrims #ThreadedIA32FFIPlugin))
]
