"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


SqueakLinux32x86_64Builder 
	configureABuildFor: #MY  NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #Linux64SqueakStackV3,
	#superclass : #Linux64Config,
	#category : #'CMakeVMMakerSqueak-LinuxX86-64'
}

{ #category : #cmake }
Linux64SqueakStackV3 >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
Linux64SqueakStackV3 >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #'as yet unclassified' }
Linux64SqueakStackV3 >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x8664
]

{ #category : #cmake }
Linux64SqueakStackV3 >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]
