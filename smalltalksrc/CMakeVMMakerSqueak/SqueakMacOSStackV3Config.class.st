"
This is a concrete class which generates a StackVM for Mac using the Carbon library.

This configuration generates sources/build files for building Stack-based interpreter on Mac OS X.
It is using a Carbon framework , which will be replaced by Cocoa soon. (see CocoaIOSConfig and its subclasses).

For more information, check the class comments of all the superclasses.

Usage:
SqueakStackMacOSConfig generateWithSources.
Or:
SqueakStackMacOSConfig generate.



"
Class {
	#name : #SqueakMacOSStackV3Config,
	#superclass : #SqueakMacOSCogV3Config,
	#category : #'CMakeVMMakerSqueak-MacOS'
}

{ #category : #'as yet unclassified' }
SqueakMacOSStackV3Config >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #'as yet unclassified' }
SqueakMacOSStackV3Config >> executableName [
	^ 'StackVM'
]

{ #category : #'as yet unclassified' }
SqueakMacOSStackV3Config >> interpreterClass [
	^ StackInterpreter
]

{ #category : #'as yet unclassified' }
SqueakMacOSStackV3Config >> prepareForGeneration [
	^ self prepareForStackVMGeneration

]
