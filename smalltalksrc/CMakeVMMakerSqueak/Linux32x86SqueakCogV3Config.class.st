"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


I am not meant to be built.

SqueakLinux32x86Builder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

"
Class {
	#name : #Linux32x86SqueakCogV3Config,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'source generation' }
Linux32x86SqueakCogV3Config >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ StackToRegisterMappingCogit 
]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuild [
	^{}
]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildAssert [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildAssertITimerHeartbeat [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildDebug [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildDebugITimerHeartbeat [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildITimerHeartbeat [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildMultiThreaded [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildMultiThreadedAssert [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildMultiThreadedDebug [
	^self compilerFlagsBuild

]

{ #category : #cmake }
Linux32x86SqueakCogV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogV3
]

{ #category : #'cmake directory ' }
Linux32x86SqueakCogV3Config >> dirInstall [
	"the directory of the finished product.. the place where 'make install' puts stuff.
	SystemNavigation default browseMethodsWhoseNamesContain: 'outputDir'
      "
	^self squeakCogV3
]

{ #category : #cmake }
Linux32x86SqueakCogV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^false
]

{ #category : #cmake }
Linux32x86SqueakCogV3Config >> executableName [
	^ self vmCogExecutableName
]

{ #category : #'source generation' }
Linux32x86SqueakCogV3Config >> interpreterClass [
	^ CoInterpreter
]
