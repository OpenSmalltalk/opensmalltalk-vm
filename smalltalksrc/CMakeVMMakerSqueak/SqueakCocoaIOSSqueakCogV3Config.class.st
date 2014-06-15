"
This is a concrete class which generates a CogVM for Mac using the Cocoa library

I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


SqueakIOSBuilder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

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
SqueakCocoaIOSSqueakCogV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogV3
]

{ #category : #cmake }
SqueakCocoaIOSSqueakCogV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
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
