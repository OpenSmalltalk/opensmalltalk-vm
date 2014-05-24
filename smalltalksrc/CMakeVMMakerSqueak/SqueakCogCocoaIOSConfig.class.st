"
This is a concrete class which generates a CogVM for Mac using the Cocoa library

For more information, check the class comments of all the superclasses.


Usage:
SqueakCogCocoaIOSConfig generateWithSources
Or:
SqueakCogCocoaIOSConfig generate
"
Class {
	#name : #SqueakCogCocoaIOSConfig,
	#superclass : #SqueakCogFamilyCocoaIOSConfig,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #'source generation' }
SqueakCogCocoaIOSConfig >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ StackToRegisterMappingCogit 
]

{ #category : #settings }
SqueakCogCocoaIOSConfig >> commonCompilerFlags [
	^super commonCompilerFlags, #('-DCOGVM')
]

{ #category : #'source files' }
SqueakCogCocoaIOSConfig >> coreSources [ 
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #accessing }
SqueakCogCocoaIOSConfig >> executableName [
	^ 'CogVM'
]

{ #category : #'source generation' }
SqueakCogCocoaIOSConfig >> interpreterClass [
	^ CoInterpreter
]

{ #category : #accessing }
SqueakCogCocoaIOSConfig >> pluginsDir [ 
	^'${srcDir}/plugins'
]

{ #category : #'source generation' }
SqueakCogCocoaIOSConfig >> prepareForGeneration [
	^ self prepareForCogGeneration

]

{ #category : #plugins }
SqueakCogCocoaIOSConfig >> versionExternalPlugins [ 
	^Array 
		with: #ThreadedIA32FFIPlugin
		with: #IA32ABIPlugin
]
