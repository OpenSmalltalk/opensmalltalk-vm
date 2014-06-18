"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakBSDx86Builder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp


"
Class {
	#name : #SqueakFreeBSDSqueakStackV3Config,
	#superclass : #SqueakBSDConfig,
	#category : #'CMakeVMMakerSqueak-BSD32x86'
}

{ #category : #'source generation' }
SqueakFreeBSDSqueakStackV3Config >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #cmake }
SqueakFreeBSDSqueakStackV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
SqueakFreeBSDSqueakStackV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
SqueakFreeBSDSqueakStackV3Config >> executableName [
	^ self vmStackExecutableName
]

{ #category : #'source generation' }
SqueakFreeBSDSqueakStackV3Config >> interpreterClass [
	^ StackInterpreter
]
