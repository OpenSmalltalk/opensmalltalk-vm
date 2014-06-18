"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakSunOS32x86Builder 
	configureABuildFor: #MYCLASSNAMEHERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

"
Class {
	#name : #SqueakSunOS32x86NewspeakCogV3Config,
	#superclass : #SqueakSunOS32x86Config,
	#category : #'CMakeVMMakerSqueak-SunOS32x86'
}

{ #category : #cmake }
SqueakSunOS32x86NewspeakCogV3Config >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #'source generation' }
SqueakSunOS32x86NewspeakCogV3Config >> cogitClass [
	^ StackToRegisterMappingCogit 
]

{ #category : #cmake }
SqueakSunOS32x86NewspeakCogV3Config >> dirBuildLanguageVMMM [
	^self newspeakCogV3
]

{ #category : #cmake }
SqueakSunOS32x86NewspeakCogV3Config >> dirInstall [
	"the directory of the finished product.. the place where 'make install' puts stuff.
	SystemNavigation default browseMethodsWhoseNamesContain: 'outputDir'
      "
	^self newspeakCogV3
]

{ #category : #cmake }
SqueakSunOS32x86NewspeakCogV3Config >> excludeFromBuild [
	^false

]

{ #category : #cmake }
SqueakSunOS32x86NewspeakCogV3Config >> executableName [
	^ self vmCogExecutableName
]

{ #category : #'source generation' }
SqueakSunOS32x86NewspeakCogV3Config >> interpreterClass [
	^ CoInterpreter

]
