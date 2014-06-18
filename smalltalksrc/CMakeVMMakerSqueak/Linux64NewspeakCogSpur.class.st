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
	#name : #Linux64NewspeakCogSpur,
	#superclass : #Linux64Config,
	#category : #'CMakeVMMakerSqueak-LinuxX86-64'
}

{ #category : #cmake }
Linux64NewspeakCogSpur >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #'source generation' }
Linux64NewspeakCogSpur >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #cmake }
Linux64NewspeakCogSpur >> dirBuildLanguageVMMM [
	^self newspeakCogSpur
]

{ #category : #cmake }
Linux64NewspeakCogSpur >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
Linux64NewspeakCogSpur >> executableName [
	^ self vmCogExecutableName
]

{ #category : #'source generation' }
Linux64NewspeakCogSpur >> interpreterClass [
	^ CoInterpreter

]
