"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


SqueakLinux32x86_64Builder 
	configureABuildFor: #MY  NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #Linux64NewspeakSistaSpur,
	#superclass : #Linux64Config,
	#category : #'CMakeVMMakerSqueak-LinuxX86-64'
}

{ #category : #cmake }
Linux64NewspeakSistaSpur >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #'source generation' }
Linux64NewspeakSistaSpur >> cogitClass [
	^SistaStackToRegisterMappingCogit

]

{ #category : #cmake }
Linux64NewspeakSistaSpur >> dirBuildLanguageVMMM [
	^self newspeakSistaSpur
]

{ #category : #cmake }
Linux64NewspeakSistaSpur >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
Linux64NewspeakSistaSpur >> executableName [
	^ self vmSistaExecutableName
]

{ #category : #'source generation' }
Linux64NewspeakSistaSpur >> interpreterClass [
	^ CoInterpreter

]
