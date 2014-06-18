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
	#name : #SqueakSunOS32x86NewspeakCogSpurConfig,
	#superclass : #SqueakSunOS32x86Config,
	#category : #'CMakeVMMakerSqueak-SunOS32x86'
}

{ #category : #cmake }
SqueakSunOS32x86NewspeakCogSpurConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #'source generation' }
SqueakSunOS32x86NewspeakCogSpurConfig >> cogitClass [
	^ StackToRegisterMappingCogit 
]

{ #category : #cmake }
SqueakSunOS32x86NewspeakCogSpurConfig >> dirBuildLanguageVMMM [
	^self newspeakCogSpur
]

{ #category : #cmake }
SqueakSunOS32x86NewspeakCogSpurConfig >> dirInstall [
	"the directory of the finished product.. the place where 'make install' puts stuff.
	SystemNavigation default browseMethodsWhoseNamesContain: 'outputDir'
      "
	^self newspeakCogSpur
]

{ #category : #cmake }
SqueakSunOS32x86NewspeakCogSpurConfig >> excludeFromBuild [
	^false

]

{ #category : #cmake }
SqueakSunOS32x86NewspeakCogSpurConfig >> executableName [
	^ self vmCogExecutableName
]

{ #category : #'source generation' }
SqueakSunOS32x86NewspeakCogSpurConfig >> interpreterClass [
	^ CoInterpreter

]
