"
N.B. I honestly have no idea how to use this. tty (:

I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


I am not meant to be built.

SqueakIA32BochsBuilder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp


"
Class {
	#name : #SqueakIA32BochsConfig,
	#superclass : #CPlatformConfigForSqueak,
	#category : #'CMakeVMMakerSqueak-IA32-Bochs'
}

{ #category : #cmake }
SqueakIA32BochsConfig >> availableBuildTypes [
	 ^SqueakCMakeVMMakerAbstractBuilder  default  noBuildTypes
"	subclasses should use

  ^super availableBuildTypes copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   "
	

]

{ #category : #plugins }
SqueakIA32BochsConfig >> defaultExternalPlugins [
	^ #()
]

{ #category : #plugins }
SqueakIA32BochsConfig >> defaultInternalPlugins [
	^ #()
]

{ #category : #cmake }
SqueakIA32BochsConfig >> dirBuildPlatform [
	^self dirIA32Bochs
]

{ #category : #cmake }
SqueakIA32BochsConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
SqueakIA32BochsConfig >> executableName [
	"AbstractBaseClass configurations are not meant to be executable"
	^ self vmIShouldNotBeHereExecutableName
]

{ #category : #'cmake buildType redirects' }
SqueakIA32BochsConfig >> externalPluginsBuild [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
SqueakIA32BochsConfig >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]
