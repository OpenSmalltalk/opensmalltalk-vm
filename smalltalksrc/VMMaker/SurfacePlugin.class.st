"
This plugin is a fake. It doesn't do anything useful. It's sole purpose is to wrap the C code that's associated with the SurfacePlugin into the main VM generation process. Since the C code isn't easily generated from ST code this is (unfortunately) necessary. But look on the bright side - you don't have to define any weird stuff for the C compiler. Isn't that great?! (just kidding...) 
"
Class {
	#name : #SurfacePlugin,
	#superclass : #InterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
SurfacePlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
SurfacePlugin class >> requiresCrossPlatformFiles [
	"If there cross platform files to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
SurfacePlugin class >> translateInDirectory: directory doInlining: inlineFlag [
"handle a special case external file rather than normal generated code."
	| cg |
	self initialize.

	cg := self buildCodeGeneratorForVMClass: StackInterpreter.

	"We rely on the fake entry points implemented on the instance side to allow the export list to be accurate. Please update them if you change the code"
	^cg exportedPrimitiveNames asArray
]

{ #category : #'fake entry points' }
SurfacePlugin >> initialiseModule [
	"Fake entry point"
	<export: true>
]

{ #category : #'fake entry points' }
SurfacePlugin >> ioFindSurface [
	"Fake entry point"
	<export: true>
]

{ #category : #'fake entry points' }
SurfacePlugin >> ioGetSurfaceFormat [
	"Fake entry point"
	<export: true>
]

{ #category : #'fake entry points' }
SurfacePlugin >> ioLockSurface [
	"Fake entry point"
	<export: true>
]

{ #category : #'fake entry points' }
SurfacePlugin >> ioRegisterSurface [
	"Fake entry point"
	<export: true>
]

{ #category : #'fake entry points' }
SurfacePlugin >> ioShowSurface [
	"Fake entry point"
	<export: true>
]

{ #category : #'fake entry points' }
SurfacePlugin >> ioUnlockSurface [
	"Fake entry point"
	<export: true>
]

{ #category : #'fake entry points' }
SurfacePlugin >> ioUnregisterSurface [
	"Fake entry point"
	<export: true>
]

{ #category : #'fake entry points' }
SurfacePlugin >> shutdownModule [
	"Fake entry point"
	<export: true>
]
