"
Experimental configuration for compiling using clang compiler

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #StackCocoaIOSCLANGConfig,
	#superclass : #StackCocoaIOSConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #'source files' }
StackCocoaIOSCLANGConfig >> coreSources [ 
" can't use GCC stuff "
	^ #(
		'interp.c'
		)
]

{ #category : #settings }
StackCocoaIOSCLANGConfig >> setExtraTargetProperties: maker [


	maker set: 'CMAKE_C_COMPILER' to: 'clang'.
	
	super setExtraTargetProperties: maker
]

{ #category : #settings }
StackCocoaIOSCLANGConfig >> setGlobalOptions: maker [
	maker set: 'CMAKE_C_COMPILER' to: '/usr/bin/clang'.
	maker set: 'CMAKE_CXX_COMPILER' to: '/usr/bin/clang++'.
]
