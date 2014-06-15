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
	#name : #Linux32x86NewspeakCogV3Config,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #cmake }
Linux32x86NewspeakCogV3Config >> dirBuildLanguageVMMM [
	^self newspeakCogV3
]

{ #category : #cmake }
Linux32x86NewspeakCogV3Config >> excludeFromBuild [
	^true

]

{ #category : #'source generation' }
Linux32x86NewspeakCogV3Config >> prepareForGeneration [
	^ self prepareForCogGeneration

]

{ #category : #'as yet unclassified' }
Linux32x86NewspeakCogV3Config >> todo [
	self flag:'tty'
]
