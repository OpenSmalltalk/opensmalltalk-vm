"
StackInterpreterMacOSConfig is a concrete class which generates a StackVM for Mac using the Carbon library.

This configuration generates sources/build files for building Stack-based interpreter on Mac OS X.
It is using a Carbon framework , which will be replaced by Cocoa soon. (see CocoaIOSConfig and its subclasses).


"
Class {
	#name : #StackInterpreterMacOSConfig,
	#superclass : #CogMacOSConfig,
	#category : #'CMakeVMMaker-MacOS'
}

{ #category : #'source files' }
StackInterpreterMacOSConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #accessing }
StackInterpreterMacOSConfig >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
StackInterpreterMacOSConfig >> interpreterClass [
	^ StackInterpreter
]

{ #category : #'source generation' }
StackInterpreterMacOSConfig >> prepareForGeneration [

	"force using LF on Macs"
	CrLfFileStream defaultToLF.

	^ self prepareForStackVMGeneration

]
