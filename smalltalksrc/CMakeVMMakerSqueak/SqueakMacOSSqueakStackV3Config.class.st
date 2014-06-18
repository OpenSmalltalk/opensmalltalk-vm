"
This is a concrete class which generates a StackVM for Mac using the Carbon library.

This configuration generates sources/build files for building Stack-based interpreter on Mac OS X.
It is using a Carbon framework , which will be replaced by Cocoa soon. (see CocoaIOSConfig and its subclasses).

SqueakMacOSBuilder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #SqueakMacOSSqueakStackV3Config,
	#superclass : #SqueakMacOSV3Config,
	#category : #'CMakeVMMakerSqueak-MacOS'
}

{ #category : #'source generation' }
SqueakMacOSSqueakStackV3Config >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #'source files' }
SqueakMacOSSqueakStackV3Config >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #cmake }
SqueakMacOSSqueakStackV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. default is squeak.cog.v3"
	^self squeakStackV3
]

{ #category : #cmake }
SqueakMacOSSqueakStackV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
SqueakMacOSSqueakStackV3Config >> executableName [
	^ self vmStackExecutableName
]

{ #category : #'source generation' }
SqueakMacOSSqueakStackV3Config >> interpreterClass [
	^ StackInterpreter
]
