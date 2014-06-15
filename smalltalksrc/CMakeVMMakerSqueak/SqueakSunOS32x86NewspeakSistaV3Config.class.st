"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakSunOS32x86Builder 
	configureABuildFor: #MYCLASSNAMEHERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

"
Class {
	#name : #SqueakSunOS32x86NewspeakSistaV3Config,
	#superclass : #SqueakSunOS32x86Config,
	#category : #'CMakeVMMakerSqueak-SunOS32x86'
}

{ #category : #cmake }
SqueakSunOS32x86NewspeakSistaV3Config >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
SqueakSunOS32x86NewspeakSistaV3Config >> dirBuildLanguageVMMM [
	^self newspeakSistaV3
]

{ #category : #cmake }
SqueakSunOS32x86NewspeakSistaV3Config >> excludeFromBuild [
	^false

]
