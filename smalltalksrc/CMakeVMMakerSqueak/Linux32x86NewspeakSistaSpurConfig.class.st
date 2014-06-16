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
	#name : #Linux32x86NewspeakSistaSpurConfig,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #cmake }
Linux32x86NewspeakSistaSpurConfig >> dirBuildLanguageVMMM [
	^self newspeakSistaSpur
]

{ #category : #cmake }
Linux32x86NewspeakSistaSpurConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build"
	^true "tty 2014.06.10 not implemented on gnu side"
]

{ #category : #cmake }
Linux32x86NewspeakSistaSpurConfig >> executableName [
	^ self vmSistaExecutableName
]
