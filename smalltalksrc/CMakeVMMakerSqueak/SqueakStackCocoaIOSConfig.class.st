"
This is a concrete class which generates a StackVM for Mac using the Cocoa library

For more information, check the class comments of all the superclasses.


Usage:
SqueakStackCocoaIOSConfig generateWithSources
Or:
SqueakStackCocoaIOSConfig generate

"
Class {
	#name : #SqueakStackCocoaIOSConfig,
	#superclass : #SqueakCogFamilyCocoaIOSConfig,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #settings }
SqueakStackCocoaIOSConfig >> commonCompilerFlags [ 
	^ super commonCompilerFlags
]

{ #category : #'source files' }
SqueakStackCocoaIOSConfig >> coreSources [ 
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #accessing }
SqueakStackCocoaIOSConfig >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
SqueakStackCocoaIOSConfig >> interpreterClass [
	^ StackInterpreter
]

{ #category : #accessing }
SqueakStackCocoaIOSConfig >> pluginsDir [ 
	^'${srcDir}/plugins'
]

{ #category : #'source generation' }
SqueakStackCocoaIOSConfig >> prepareForGeneration [
	^ self prepareForStackVMGeneration

]

{ #category : #settings }
SqueakStackCocoaIOSConfig >> setGlobalOptions: maker [
   super setGlobalOptions: maker.
   maker set: 'CMAKE_C_COMPILER' to: 'clang'.
   maker set: 'CMAKE_CXX_COMPILER' to: 'clang++'.
]

{ #category : #plugins }
SqueakStackCocoaIOSConfig >> versionExternalPlugins [ 
	^Array 
		with: #ThreadedIA32FFIPlugin
		with: #IA32ABIPlugin
]
