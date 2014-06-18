"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakWin32x86Builder 
	configureABuildFor: #MYCLASSNAMEHERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #Win32x86NewspeakSistaSpurConfig,
	#superclass : #SqueakWin32x86Config,
	#category : #'CMakeVMMakerSqueak-Win32x86'
}

{ #category : #'source generation' }
Win32x86NewspeakSistaSpurConfig >> cogitClass [
	^SistaStackToRegisterMappingCogit

]

{ #category : #cmake }
Win32x86NewspeakSistaSpurConfig >> dirBuildLanguageVMMM [
	^self newspeakSistaSpur
]

{ #category : #cmake }
Win32x86NewspeakSistaSpurConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
Win32x86NewspeakSistaSpurConfig >> executableName [
	^ self vmSistaExecutableName
]

{ #category : #'source generation' }
Win32x86NewspeakSistaSpurConfig >> interpreterClass [
	^ CoInterpreter

]
