"
This is a concrete class which generates a CogVM for Mac using the Cocoa library

For more information, check the class comments of all the superclasses.


Usage:
SqueakCogCocoaIOSConfig generateWithSources
Or:
SqueakCogCocoaIOSConfig generate
"
Class {
	#name : #SqueakCocoaIOSCogV3Config,
	#superclass : #SqueakCocoaIOSCogV3FamilyConfig,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #'source generation' }
SqueakCocoaIOSCogV3Config >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ StackToRegisterMappingCogit 
]

{ #category : #settings }
SqueakCocoaIOSCogV3Config >> commonCompilerFlags [
	^super commonCompilerFlags, #('-DCOGVM')
]

{ #category : #'source files' }
SqueakCocoaIOSCogV3Config >> coreSources [ 
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #accessing }
SqueakCocoaIOSCogV3Config >> executableName [
	^ 'CogVM'
]

{ #category : #'source generation' }
SqueakCocoaIOSCogV3Config >> interpreterClass [
	^ CoInterpreter
]

{ #category : #accessing }
SqueakCocoaIOSCogV3Config >> pluginsDir [ 
	^'${srcDir}/plugins'
]

{ #category : #'source generation' }
SqueakCocoaIOSCogV3Config >> prepareForGeneration [
	^ self prepareForCogGeneration

]

{ #category : #plugins }
SqueakCocoaIOSCogV3Config >> versionExternalPlugins [ 
	^Array 
		with: #ThreadedIA32FFIPlugin
		with: #IA32ABIPlugin
]
