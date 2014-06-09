"
This is a concrete class which generates a CogVM for Mac using the Cocoa library

For more information, check the class comments of all the superclasses.


Usage:
  SqueakCocoaIOSCogV3Config generate
Or:
  SqueakCocoaIOSCogV3Config generateWithSources
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me

"
Class {
	#name : #SqueakCocoaIOSSqueakCogV3Config,
	#superclass : #SqueakCocoaIOSCogV3FamilyConfig,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #'source generation' }
SqueakCocoaIOSSqueakCogV3Config >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ StackToRegisterMappingCogit 
]

{ #category : #settings }
SqueakCocoaIOSSqueakCogV3Config >> commonCompilerFlags [
	^super commonCompilerFlags, #('-DCOGVM')
]

{ #category : #'source files' }
SqueakCocoaIOSSqueakCogV3Config >> coreSources [ 
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #cmake }
SqueakCocoaIOSSqueakCogV3Config >> excludeFromBuild [
	^false

]

{ #category : #accessing }
SqueakCocoaIOSSqueakCogV3Config >> executableName [
	^ 'CogVM'
]

{ #category : #'source generation' }
SqueakCocoaIOSSqueakCogV3Config >> interpreterClass [
	^ CoInterpreter
]

{ #category : #accessing }
SqueakCocoaIOSSqueakCogV3Config >> pluginsDir [ 
	^'${srcDir}/plugins'
]

{ #category : #'source generation' }
SqueakCocoaIOSSqueakCogV3Config >> prepareForGeneration [
	^ self prepareForCogGeneration

]

{ #category : #plugins }
SqueakCocoaIOSSqueakCogV3Config >> versionExternalPlugins [ 
	^Array 
		with: #ThreadedIA32FFIPlugin
		with: #IA32ABIPlugin
]
