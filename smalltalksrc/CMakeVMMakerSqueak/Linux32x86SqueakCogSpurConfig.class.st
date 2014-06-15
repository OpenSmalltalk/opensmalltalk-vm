"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


I am not meant to be built.

SqueakLinux32x86Builder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

"
Class {
	#name : #Linux32x86SqueakCogSpurConfig,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #cmake }
Linux32x86SqueakCogSpurConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogSpur
]

{ #category : #cmake }
Linux32x86SqueakCogSpurConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #'source generation' }
Linux32x86SqueakCogSpurConfig >> prepareForGeneration [
	^ self prepareForCogGeneration

]

{ #category : #'as yet unclassified' }
Linux32x86SqueakCogSpurConfig >> todo [
	self flag:'tty'
]
