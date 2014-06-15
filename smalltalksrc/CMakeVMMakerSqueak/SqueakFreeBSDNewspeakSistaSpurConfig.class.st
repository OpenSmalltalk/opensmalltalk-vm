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
	#name : #SqueakFreeBSDNewspeakSistaSpurConfig,
	#superclass : #SqueakBSDConfig,
	#category : #'CMakeVMMakerSqueak-BSD32x86'
}

{ #category : #cmake }
SqueakFreeBSDNewspeakSistaSpurConfig >> dirBuildLanguageVMMM [
	^self newspeakSistaSpur
]

{ #category : #cmake }
SqueakFreeBSDNewspeakSistaSpurConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]
