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
	#name : #SqueakFreeBSDNewspeakSistaV3Config,
	#superclass : #SqueakBSDConfig,
	#category : #'CMakeVMMakerSqueak-BSD32x86'
}

{ #category : #'source generation' }
SqueakFreeBSDNewspeakSistaV3Config >> cogitClass [
	^SistaStackToRegisterMappingCogit

]

{ #category : #cmake }
SqueakFreeBSDNewspeakSistaV3Config >> dirBuildLanguageVMMM [
	^self newspeakSistaV3
]

{ #category : #cmake }
SqueakFreeBSDNewspeakSistaV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
SqueakFreeBSDNewspeakSistaV3Config >> executableName [
	^ self vmSistaExecutableName
]

{ #category : #'source generation' }
SqueakFreeBSDNewspeakSistaV3Config >> interpreterClass [
	^ CoInterpreter

]
