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
	#name : #Linux32x86NewspeakStackSpurConfig,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'source generation' }
Linux32x86NewspeakStackSpurConfig >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #cmake }
Linux32x86NewspeakStackSpurConfig >> dirBuildLanguageVMMM [
	^self newspeakStackSpur
]

{ #category : #cmake }
Linux32x86NewspeakStackSpurConfig >> excludeFromBuild [
	^true

]

{ #category : #cmake }
Linux32x86NewspeakStackSpurConfig >> executableName [
	^ self vmStackExecutableName
]

{ #category : #'source generation' }
Linux32x86NewspeakStackSpurConfig >> interpreterClass [
	^ StackInterpreter
]
