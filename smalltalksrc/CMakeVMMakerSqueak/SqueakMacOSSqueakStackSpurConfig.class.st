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
	#name : #SqueakMacOSSqueakStackSpurConfig,
	#superclass : #SqueakMacOSV3Config,
	#category : #'CMakeVMMakerSqueak-MacOS'
}

{ #category : #'source generation' }
SqueakMacOSSqueakStackSpurConfig >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #'source files' }
SqueakMacOSSqueakStackSpurConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #cmake }
SqueakMacOSSqueakStackSpurConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. default is squeak.cog.v3"
	^self squeakStackSpur
]

{ #category : #cmake }
SqueakMacOSSqueakStackSpurConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
SqueakMacOSSqueakStackSpurConfig >> executableName [
	^ self vmStackExecutableName
]

{ #category : #'source generation' }
SqueakMacOSSqueakStackSpurConfig >> interpreterClass [
	^ StackInterpreter
]
