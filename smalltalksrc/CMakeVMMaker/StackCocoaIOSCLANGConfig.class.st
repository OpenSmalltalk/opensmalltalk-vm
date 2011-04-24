"
Experimental configuration for compiling using clang compiler

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #StackCocoaIOSCLANGConfig,
	#superclass : #StackCocoaIOSConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #'as yet unclassified' }
StackCocoaIOSCLANGConfig >> coreSources [ 
" can't use GCC stuff "
	^ #(
		'interp.c'
		)
]

{ #category : #'as yet unclassified' }
StackCocoaIOSCLANGConfig >> setExtraTargetProperties: maker [


	maker set: 'CMAKE_C_COMPILER' to: 'clang'.
	
	super setExtraTargetProperties: maker
]
