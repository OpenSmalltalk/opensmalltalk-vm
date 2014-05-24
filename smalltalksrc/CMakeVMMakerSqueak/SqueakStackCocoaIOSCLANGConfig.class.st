"
Experimental configuration for compiling using clang compiler

For more information, check the class comments of all the superclasses.

Usage:

SqueakStackCocoaIOSCLANGConfig generateWithSources
OR:
SqueakStackCocoaIOSCLANGConfig generate

"
Class {
	#name : #SqueakStackCocoaIOSCLANGConfig,
	#superclass : #SqueakStackCocoaIOSConfig,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #'source files' }
SqueakStackCocoaIOSCLANGConfig >> coreSources [ 
" can't use GCC stuff "
	^ #(
		'interp.c'
		)
]

{ #category : #settings }
SqueakStackCocoaIOSCLANGConfig >> setExtraTargetProperties: maker [


	maker set: 'CMAKE_C_COMPILER' to: 'clang'.
	
	super setExtraTargetProperties: maker
]

{ #category : #settings }
SqueakStackCocoaIOSCLANGConfig >> setGlobalOptions: maker [
	maker set: 'CMAKE_C_COMPILER' to: '/usr/bin/clang'.
	maker set: 'CMAKE_CXX_COMPILER' to: '/usr/bin/clang++'.
]
