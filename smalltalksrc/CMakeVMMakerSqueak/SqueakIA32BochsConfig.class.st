"
N.B. I honestly have no idea how to use this. tty (:

I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


I am not meant to be built.

SqueakIA32BochsBuilder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp


"
Class {
	#name : #SqueakIA32BochsConfig,
	#superclass : #CPlatformConfigForSqueak,
	#category : #'CMakeVMMakerSqueak-IA32-Bochs'
}

{ #category : #accessing }
SqueakIA32BochsConfig class >> availableBuilds [
	"SqueakCMakeVMMakerAbstractBuilder  allBuildConfigurations
	^#(#assert #debug  #release )"
	^SqueakCMakeVMMakerAbstractBuilder noBuildConfigurations
]

{ #category : #cmake }
SqueakIA32BochsConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default  noBuildConfigurations

]

{ #category : #plugins }
SqueakIA32BochsConfig >> defaultExternalPlugins [
	^ #()
]

{ #category : #plugins }
SqueakIA32BochsConfig >> defaultInternalPlugins [
	^ #()
]

{ #category : #cmake }
SqueakIA32BochsConfig >> dirBuildPlatform [
	^self dirIA32Bochs
]

{ #category : #cmake }
SqueakIA32BochsConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]
