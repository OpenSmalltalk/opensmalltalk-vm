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
	#name : #SqueakMacOSNewspeakStackV3Config,
	#superclass : #SqueakMacOSV3Config,
	#category : #'CMakeVMMakerSqueak-MacOS'
}

{ #category : #'source files' }
SqueakMacOSNewspeakStackV3Config >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #cmake }
SqueakMacOSNewspeakStackV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. default is squeak.cog.v3"
	^self newspeakStackV3
]

{ #category : #cmake }
SqueakMacOSNewspeakStackV3Config >> excludeFromBuild [
	^false

]

{ #category : #accessing }
SqueakMacOSNewspeakStackV3Config >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
SqueakMacOSNewspeakStackV3Config >> interpreterClass [
	^ StackInterpreter
]

{ #category : #'source generation' }
SqueakMacOSNewspeakStackV3Config >> prepareForGeneration [
	^ self prepareForStackVMGeneration

]
