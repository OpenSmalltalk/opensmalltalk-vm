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
	#name : #Linux32x86NewspeakCogSpurConfig,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #cmake }
Linux32x86NewspeakCogSpurConfig >> dirBuildLanguageVMMM [
	^self newspeakCogSpur
]

{ #category : #cmake }
Linux32x86NewspeakCogSpurConfig >> excludeFromBuild [
	^true

]

{ #category : #'source generation' }
Linux32x86NewspeakCogSpurConfig >> prepareForGeneration [
	^ self prepareForCogGeneration

]

{ #category : #'as yet unclassified' }
Linux32x86NewspeakCogSpurConfig >> todo [
	self flag:'tty'
]
