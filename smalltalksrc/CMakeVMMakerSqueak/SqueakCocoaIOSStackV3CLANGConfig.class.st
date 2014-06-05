"
Experimental configuration for compiling using clang compiler

For more information, check the class comments of all the superclasses.

Usage:

SqueakStackCocoaIOSCLANGConfig generateWithSources
OR:
SqueakStackCocoaIOSCLANGConfig generate

"
Class {
	#name : #SqueakCocoaIOSStackV3CLANGConfig,
	#superclass : #SqueakCocoaIOSStackV3Config,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #'source files' }
SqueakCocoaIOSStackV3CLANGConfig >> coreSources [ 
" can't use GCC stuff "
	^ #(
		'interp.c'
		)
]

{ #category : #settings }
SqueakCocoaIOSStackV3CLANGConfig >> setExtraTargetProperties: maker [


	maker set: 'CMAKE_C_COMPILER' to: 'clang'.
	
	super setExtraTargetProperties: maker
]

{ #category : #settings }
SqueakCocoaIOSStackV3CLANGConfig >> setGlobalOptions: maker [
	maker set: 'CMAKE_C_COMPILER' to: '/usr/bin/clang'.
	maker set: 'CMAKE_CXX_COMPILER' to: '/usr/bin/clang++'.
]
