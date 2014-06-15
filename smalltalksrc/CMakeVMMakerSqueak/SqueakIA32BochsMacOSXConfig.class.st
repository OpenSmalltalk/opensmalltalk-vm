"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakIA32BochsBuilder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp


"
Class {
	#name : #SqueakIA32BochsMacOSXConfig,
	#superclass : #SqueakIA32BochsConfig,
	#category : #'CMakeVMMakerSqueak-IA32-Bochs'
}

{ #category : #cmake }
SqueakIA32BochsMacOSXConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogSpur
]

{ #category : #'as yet unclassified' }
SqueakIA32BochsMacOSXConfig >> todo [
	self flag:'tty'
]
