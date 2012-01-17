"
This is a concrete class which generates a StackVM for Mac using the Cocoa library

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #StackCocoaIOSConfig,
	#superclass : #CogFamilyCocoaIOSConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #settings }
StackCocoaIOSConfig >> compilerFlagsRelease [ 
	^super compilerFlagsRelease, #('-DSTACKVM')
]

{ #category : #'source files' }
StackCocoaIOSConfig >> coreSources [ 
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #accessing }
StackCocoaIOSConfig >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
StackCocoaIOSConfig >> interpreterClass [
	^ StackInterpreter
]

{ #category : #accessing }
StackCocoaIOSConfig >> pluginsDir [ 
	^'${srcDir}/plugins'
]

{ #category : #'source generation' }
StackCocoaIOSConfig >> prepareForGeneration [

	^ self prepareForStackVMGeneration

]

{ #category : #accessing }
StackCocoaIOSConfig >> srcDir [ 
	"Answer the value of srcDir"

	^ srcDir ifNil: [ srcDir := (self topDir / self srcDirName) fullName ]
]

{ #category : #plugins }
StackCocoaIOSConfig >> versionExternalPlugins [ 
	^Array 
		with: #ThreadedIA32FFIPlugin
		with: #IA32ABIPlugin
]
