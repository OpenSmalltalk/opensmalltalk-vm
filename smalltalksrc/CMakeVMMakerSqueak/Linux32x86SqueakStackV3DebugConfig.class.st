"
I need to go away. In the meantime....

This is a concrete class which generates a DEBUG StackVM for Unix systems. This VM is normally known as a debug StackVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.

Usage:
Linux32x86SqueakStackV3DebugConfig generateWithSources
Or:
Linux32x86SqueakStackV3DebugConfig generate

Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me

"
Class {
	#name : #Linux32x86SqueakStackV3DebugConfig,
	#superclass : #Linux32x86SqueakStackV3Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'as yet unclassified' }
Linux32x86SqueakStackV3DebugConfig class >> availableBuilds [
	self flag:'tty'. "having debug sublclasses makes no sense with the generateForRelease, generateForDebug ,generateForFOO idiom going forward. I need to go away"
	^#(  #debug )

]

{ #category : #'as yet unclassified' }
Linux32x86SqueakStackV3DebugConfig >> defaultExternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultExternalPlugins copyWithoutAll: #(#ThreadedIA32FFIPlugin #InternetConfigPlugin #FT2Plugin))
]

{ #category : #'as yet unclassified' }
Linux32x86SqueakStackV3DebugConfig >> defaultInternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultInternalPlugins copyWithoutAll: #(#IA32ABIPlugin #JoystickTabletPlugin #StarSqueakPlugin #SurfacePlugin #SqueakFFIPrims #ThreadedIA32FFIPlugin))
]
