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
	#name : #SqueakMacOSSqueakStackV3Config,
	#superclass : #SqueakMacOSV3Config,
	#category : #'CMakeVMMakerSqueak-MacOS'
}

{ #category : #'source files' }
SqueakMacOSSqueakStackV3Config >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #cmake }
SqueakMacOSSqueakStackV3Config >> excludeFromBuild [
	^false

]

{ #category : #accessing }
SqueakMacOSSqueakStackV3Config >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
SqueakMacOSSqueakStackV3Config >> interpreterClass [
	^ StackInterpreter
]

{ #category : #'source generation' }
SqueakMacOSSqueakStackV3Config >> prepareForGeneration [
	^ self prepareForStackVMGeneration

]
