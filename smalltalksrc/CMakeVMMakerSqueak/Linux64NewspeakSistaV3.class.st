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
	#name : #Linux64NewspeakSistaV3,
	#superclass : #Linux64Config,
	#category : #'CMakeVMMakerSqueak-LinuxX86-64'
}

{ #category : #cmake }
Linux64NewspeakSistaV3 >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #'source generation' }
Linux64NewspeakSistaV3 >> cogitClass [
	^SistaStackToRegisterMappingCogit

]

{ #category : #cmake }
Linux64NewspeakSistaV3 >> dirBuildLanguageVMMM [
	^self newspeakSistaV3
]

{ #category : #cmake }
Linux64NewspeakSistaV3 >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
Linux64NewspeakSistaV3 >> executableName [
	^ self vmSistaExecutableName
]

{ #category : #'source generation' }
Linux64NewspeakSistaV3 >> interpreterClass [
	^ CoInterpreter

]
