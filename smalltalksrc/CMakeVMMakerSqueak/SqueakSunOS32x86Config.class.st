"
A SqueakSunOS32x86CogConfig provides common informatin for my subclasses.

I am not meant to be built.

SqueakSunOS32x86Builder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #SqueakSunOS32x86Config,
	#superclass : #SqueakUnixConfig,
	#category : #'CMakeVMMakerSqueak-SunOS32x86'
}

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuild: aMaker [
	aMaker message: 'addVMDrivers: aMaker'.
	 self 
		addDriver: 'vm-display-null' 
		sources: #( 
			'${targetPlatform}/vm-display-null/sqUnixDisplayNull' )
		generator: aMaker
		externalLibs: #();
		
		addDriver: 'vm-display-X11' 
		sources: #( 
			'${targetPlatform}/vm-display-X11/sqUnixX11'
			'${targetPlatform}/vm-display-X11/sqUnixMozilla' )
		generator: aMaker
		externalLibs: (self externalLibs);

		addDriver: 'vm-sound-ALSA' 
		sources: #( 
			'${targetPlatform}/vm-sound-ALSA/sqUnixSoundALSA' )
		generator: aMaker
		externalLibs: #();

		addDriver: 'vm-sound-null' 
		sources: #( 
			'${targetPlatform}/vm-sound-null/sqUnixSoundNull' )
		generator: aMaker
		externalLibs: #().

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildAssert: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildAssertITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildDebug: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildDebugITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildMultiThreaded: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildMultiThreadedAssert: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildMultiThreadedDebug: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake configuration' }
SqueakSunOS32x86Config >> availableBuildTypes [
	 ^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes
"	subclasses should use

  ^super availableBuildTypes copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   "
	

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuild [
	self flag:'tty'. "Is this correct for this platform?"
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildAssert [
	^self coreSourcesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildAssertITimerHeartbeat [
	^self coreSourcesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildDebug [
	^self coreSourcesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildDebugITimerHeartbeat [
	^self coreSourcesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildITimerHeartbeat [
	^self coreSourcesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildMultiThreaded [
	^self coreSourcesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildMultiThreadedAssert [
	^self coreSourcesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildMultiThreadedDebug [
	^self coreSourcesBuild

]

{ #category : #plugins }
SqueakSunOS32x86Config >> defaultExternalPlugins [
	^#(	)
]

{ #category : #plugins }
SqueakSunOS32x86Config >> defaultInternalPlugins [
	^#(	)
]

{ #category : #cmake }
SqueakSunOS32x86Config >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirSunOS32x86
]

{ #category : #cmake }
SqueakSunOS32x86Config >> excludeFromBuild [
	^true

]

{ #category : #cmake }
SqueakSunOS32x86Config >> executableName [
	"AbstractBaseClass configurations are not meant to be executable"
	^ self vmIShouldNotBeHereExecutableName
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuild [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildAssert [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildAssertITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildDebug [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildDebugITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildMultiThreaded [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildMultiThreadedAssert [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildMultiThreadedDebug [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraPluginSettingsBuild: aMaker [
	"default browseMethodsWhoseNamesContain: 'extraPluginSettingsBuild' "
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraPluginSettingsBuildAssert: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraPluginSettingsBuildAssertITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraPluginSettingsBuildDebug: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraPluginSettingsBuildDebugITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraPluginSettingsBuildITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraPluginSettingsBuildMultiThreaded: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraPluginSettingsBuildMultiThreadedAssert: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraPluginSettingsBuildMultiThreadedDebug: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuild: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettingsBuild:'"
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuildAssertITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuildDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuildDebugITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuildITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuildMultiThreaded: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuildMultiThreadedAssert: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuildMultiThreadedDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildAssertITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildDebugITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildMultiThreaded [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildMultiThreadedAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildMultiThreadedDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuild: gen [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActionsBuild:'"
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildAssertITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildDebugITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildMultiThreaded: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildMultiThreadedAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildMultiThreadedDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuild [
"SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'"
	^ #( )

	

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildAssert [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildAssertITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildDebug [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildDebugITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildMultiThreaded [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildMultiThreadedAssert [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildMultiThreadedDebug [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [
	"do nothing (so far) on Unix.
	
	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystemBuild:'
	"
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuild: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsBuild'
	"
	self flag:'tty'. "I do not know that SunOS uses these compilers. This probably needs to change"
	aMaker set: 'CMAKE_C_COMPILER' to: '/usr/bin/gcc'.
	aMaker set: 'CMAKE_CXX_COMPILER' to: '/usr/bin/g++'.

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildMultiThreaded: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuild [ 
	^ #()
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildAssertITimerHeartbeat [
	^self standardIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildDebug [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildDebugITimerHeartbeat [
	^self standardIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildMultiThreaded [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildMultiThreadedAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildMultiThreadedDebug [ 
	^ self standardIncludesBuild
]
