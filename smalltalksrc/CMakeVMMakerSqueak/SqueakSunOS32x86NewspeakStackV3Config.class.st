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
	#name : #SqueakSunOS32x86NewspeakStackV3Config,
	#superclass : #SqueakSunOS32x86Config,
	#category : #'CMakeVMMakerSqueak-SunOS32x86'
}

{ #category : #cmake }
SqueakSunOS32x86NewspeakStackV3Config >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #'source generation' }
SqueakSunOS32x86NewspeakStackV3Config >> cogitClass [
	^ StackToRegisterMappingCogit 
]

{ #category : #cmake }
SqueakSunOS32x86NewspeakStackV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
SqueakSunOS32x86NewspeakStackV3Config >> dirInstall [
	"the directory of the finished product.. the place where 'make install' puts stuff.
	SystemNavigation default browseMethodsWhoseNamesContain: 'outputDir'
      "
	^self newspeakStackV3
]

{ #category : #cmake }
SqueakSunOS32x86NewspeakStackV3Config >> excludeFromBuild [
	^false

]

{ #category : #cmake }
SqueakSunOS32x86NewspeakStackV3Config >> executableName [
	^ self vmStackExecutableName
]

{ #category : #'source generation' }
SqueakSunOS32x86NewspeakStackV3Config >> interpreterClass [
	^ StackInterpreter
]
