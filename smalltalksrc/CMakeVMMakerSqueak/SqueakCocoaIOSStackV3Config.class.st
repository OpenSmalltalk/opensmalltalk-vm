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
	#name : #SqueakCocoaIOSStackV3Config,
	#superclass : #SqueakCocoaIOSCogV3FamilyConfig,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #settings }
SqueakCocoaIOSStackV3Config >> commonCompilerFlags [ 
	^ super commonCompilerFlags
]

{ #category : #'source files' }
SqueakCocoaIOSStackV3Config >> coreSources [ 
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #accessing }
SqueakCocoaIOSStackV3Config >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
SqueakCocoaIOSStackV3Config >> interpreterClass [
	^ StackInterpreter
]

{ #category : #accessing }
SqueakCocoaIOSStackV3Config >> pluginsDir [ 
	^'${srcDir}/plugins'
]

{ #category : #'source generation' }
SqueakCocoaIOSStackV3Config >> prepareForGeneration [
	^ self prepareForStackVMGeneration

]

{ #category : #settings }
SqueakCocoaIOSStackV3Config >> setGlobalOptions: maker [
   super setGlobalOptions: maker.
   maker set: 'CMAKE_C_COMPILER' to: 'clang'.
   maker set: 'CMAKE_CXX_COMPILER' to: 'clang++'.
]

{ #category : #plugins }
SqueakCocoaIOSStackV3Config >> versionExternalPlugins [ 
	^Array 
		with: #ThreadedIA32FFIPlugin
		with: #IA32ABIPlugin
]
