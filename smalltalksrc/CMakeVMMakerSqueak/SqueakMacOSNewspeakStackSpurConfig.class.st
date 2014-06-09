"
This is a concrete class which generates a StackVM for Mac using the Carbon library.

This configuration generates sources/build files for building Stack-based interpreter on Mac OS X.
It is using a Carbon framework , which will be replaced by Cocoa soon. (see CocoaIOSConfig and its subclasses).

For more information, check the class comments of all the superclasses.

Usage:
SqueakMacOSStackV3Config generateWithSources.
Or:
SqueakMacOSStackV3Config generate.
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me



"
Class {
	#name : #SqueakMacOSNewspeakStackSpurConfig,
	#superclass : #SqueakMacOSV3Config,
	#category : #'CMakeVMMakerSqueak-MacOS'
}

{ #category : #'source files' }
SqueakMacOSNewspeakStackSpurConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #cmake }
SqueakMacOSNewspeakStackSpurConfig >> excludeFromBuild [
	^false

]

{ #category : #accessing }
SqueakMacOSNewspeakStackSpurConfig >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
SqueakMacOSNewspeakStackSpurConfig >> interpreterClass [
	^ StackInterpreter
]

{ #category : #'source generation' }
SqueakMacOSNewspeakStackSpurConfig >> prepareForGeneration [
	^ self prepareForStackVMGeneration

]
