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
	#name : #SqueakSunOS32x86SqueakStackSpurConfig,
	#superclass : #SqueakSunOS32x86Config,
	#category : #'CMakeVMMakerSqueak-SunOS32x86'
}

{ #category : #cmake }
SqueakSunOS32x86SqueakStackSpurConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #'source generation' }
SqueakSunOS32x86SqueakStackSpurConfig >> cogitClass [
	^ StackToRegisterMappingCogit 
]

{ #category : #cmake }
SqueakSunOS32x86SqueakStackSpurConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackSpur
]

{ #category : #cmake }
SqueakSunOS32x86SqueakStackSpurConfig >> dirInstall [
	"the directory of the finished product.. the place where 'make install' puts stuff.
	SystemNavigation default browseMethodsWhoseNamesContain: 'outputDir'
      "
	^self squeakStackSpur
]

{ #category : #cmake }
SqueakSunOS32x86SqueakStackSpurConfig >> excludeFromBuild [
	^false

]

{ #category : #cmake }
SqueakSunOS32x86SqueakStackSpurConfig >> executableName [
	^ self vmStackExecutableName
]

{ #category : #'source generation' }
SqueakSunOS32x86SqueakStackSpurConfig >> interpreterClass [
	^ StackInterpreter
]
