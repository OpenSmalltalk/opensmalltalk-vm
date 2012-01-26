"
This is a concrete class which generates a StackVM for Mac using the Carbon library.

This configuration generates sources/build files for building Stack-based interpreter on Mac OS X.
It is using a Carbon framework , which will be replaced by Cocoa soon. (see CocoaIOSConfig and its subclasses).

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #StackMacOSConfig,
	#superclass : #CogMacOSConfig,
	#category : #'CMakeVMMaker-MacOS'
}

{ #category : #'source files' }
StackMacOSConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #accessing }
StackMacOSConfig >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
StackMacOSConfig >> interpreterClass [
	^ StackInterpreter
]

{ #category : #'source generation' }
StackMacOSConfig >> prepareForGeneration [
	^ self prepareForStackVMGeneration

]
