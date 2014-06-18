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
	#name : #SqueakFreeBSDNewspeakStackSpurConfig,
	#superclass : #SqueakBSDConfig,
	#category : #'CMakeVMMakerSqueak-BSD32x86'
}

{ #category : #'source generation' }
SqueakFreeBSDNewspeakStackSpurConfig >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #cmake }
SqueakFreeBSDNewspeakStackSpurConfig >> dirBuildLanguageVMMM [
	^self newspeakStackSpur
]

{ #category : #cmake }
SqueakFreeBSDNewspeakStackSpurConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
SqueakFreeBSDNewspeakStackSpurConfig >> executableName [
	^ self vmStackExecutableName
]

{ #category : #'source generation' }
SqueakFreeBSDNewspeakStackSpurConfig >> interpreterClass [
	^ StackInterpreter
]
