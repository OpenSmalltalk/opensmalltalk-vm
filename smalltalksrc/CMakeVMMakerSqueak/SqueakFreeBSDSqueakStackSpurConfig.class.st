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
	#name : #SqueakFreeBSDSqueakStackSpurConfig,
	#superclass : #SqueakBSDConfig,
	#category : #'CMakeVMMakerSqueak-BSD32x86'
}

{ #category : #cmake }
SqueakFreeBSDSqueakStackSpurConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackSpur
]

{ #category : #cmake }
SqueakFreeBSDSqueakStackSpurConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]
