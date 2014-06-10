"
Experimental configuration for compiling using clang compiler

For more information, check the class comments of all the superclasses.


Usage:
  SqueakCocoaIOSStackV3CLANGConfig generate
Or:
  SqueakCocoaIOSStackV3CLANGConfig generateWithSources
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me

"
Class {
	#name : #SqueakCocoaIOSStackV3CLANGConfig,
	#superclass : #SqueakCocoaIOSSqueakStackV3Config,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #'source files' }
SqueakCocoaIOSStackV3CLANGConfig >> coreSources [ 
" can't use GCC stuff "
	^ #(
		'interp.c'
		)
]

{ #category : #cmake }
SqueakCocoaIOSStackV3CLANGConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
SqueakCocoaIOSStackV3CLANGConfig >> excludeFromBuild [
	^false

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
