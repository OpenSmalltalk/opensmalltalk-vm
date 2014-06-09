"
This is a concrete class which generates a StackVM for Mac using the Cocoa library

For more information, check the class comments of all the superclasses.



Usage:
  SqueakCocoaIOSStackV3Config generate
Or:
  SqueakCocoaIOSStackV3Config generateWithSources
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me

"
Class {
	#name : #SqueakCocoaIOSSqueakStackV3Config,
	#superclass : #SqueakCocoaIOSCogV3FamilyConfig,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #settings }
SqueakCocoaIOSSqueakStackV3Config >> commonCompilerFlags [ 
	^ super commonCompilerFlags
]

{ #category : #'source files' }
SqueakCocoaIOSSqueakStackV3Config >> coreSources [ 
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #cmake }
SqueakCocoaIOSSqueakStackV3Config >> excludeFromBuild [
	^false

]

{ #category : #accessing }
SqueakCocoaIOSSqueakStackV3Config >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
SqueakCocoaIOSSqueakStackV3Config >> interpreterClass [
	^ StackInterpreter
]

{ #category : #accessing }
SqueakCocoaIOSSqueakStackV3Config >> pluginsDir [ 
	^'${srcDir}/plugins'
]

{ #category : #'source generation' }
SqueakCocoaIOSSqueakStackV3Config >> prepareForGeneration [
	^ self prepareForStackVMGeneration

]

{ #category : #settings }
SqueakCocoaIOSSqueakStackV3Config >> setGlobalOptions: maker [
   super setGlobalOptions: maker.
   maker set: 'CMAKE_C_COMPILER' to: 'clang'.
   maker set: 'CMAKE_CXX_COMPILER' to: 'clang++'.
]

{ #category : #plugins }
SqueakCocoaIOSSqueakStackV3Config >> versionExternalPlugins [ 
	^Array 
		with: #ThreadedIA32FFIPlugin
		with: #IA32ABIPlugin
]
