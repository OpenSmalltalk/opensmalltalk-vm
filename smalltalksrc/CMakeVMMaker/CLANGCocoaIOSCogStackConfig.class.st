Class {
	#name : #CLANGCocoaIOSCogStackConfig,
	#superclass : #CocoaIOSCogStackConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #'as yet unclassified' }
CLANGCocoaIOSCogStackConfig >> coreSources [ 
" can't use GCC stuff "
	^ #(
		'interp.c'
		)
]

{ #category : #'as yet unclassified' }
CLANGCocoaIOSCogStackConfig >> setExtraTargetProperties: maker [


	maker set: 'CMAKE_C_COMPILER' to: 'clang'.
	
	super setExtraTargetProperties: maker
]
