"
This is a concrete class which generates a StackVM for Mac using the Cocoa library

For more information, check the class comments of all the superclasses.


I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakIOSBuilder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
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
SqueakCocoaIOSSqueakStackV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
SqueakCocoaIOSSqueakStackV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
SqueakCocoaIOSSqueakStackV3Config >> executableName [
	^ self vmStackExecutableName
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
