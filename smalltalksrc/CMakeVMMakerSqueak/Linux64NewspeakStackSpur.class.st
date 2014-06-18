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
	#name : #Linux64NewspeakStackSpur,
	#superclass : #Linux64Config,
	#category : #'CMakeVMMakerSqueak-LinuxX86-64'
}

{ #category : #cmake }
Linux64NewspeakStackSpur >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #'source generation' }
Linux64NewspeakStackSpur >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #cmake }
Linux64NewspeakStackSpur >> dirBuildLanguageVMMM [
	^self newspeakStackSpur
]

{ #category : #cmake }
Linux64NewspeakStackSpur >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #accessing }
Linux64NewspeakStackSpur >> executableName [
	^ self vmStackExecutableName
]

{ #category : #'source generation' }
Linux64NewspeakStackSpur >> interpreterClass [
	^ StackInterpreter
]
