"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

I am not meant to be built.

SqueakBSDx86Builder 
	configureABuildFor: #MY SUBCLASS NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp


"
Class {
	#name : #SqueakBSDConfig,
	#superclass : #SqueakUnixConfig,
	#category : #'CMakeVMMakerSqueak-BSD32x86'
}

{ #category : #'as yet unclassified' }
SqueakBSDConfig class >> initialize [
	isAbstractBaseClass:=true
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> addVMDriversBuild: aMaker [
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
SqueakBSDConfig >> addVMDriversBuildAssert: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> addVMDriversBuildAssertITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> addVMDriversBuildDebug: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> addVMDriversBuildDebugITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> addVMDriversBuildITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> addVMDriversBuildMultiThreaded: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> addVMDriversBuildMultiThreadedAssert: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> addVMDriversBuildMultiThreadedDebug: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake configuration' }
SqueakBSDConfig >> availableBuildTypes [
	 ^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes
"	subclasses should use

  ^super availableBuildTypes copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   "
	

]

{ #category : #'compiler flags' }
SqueakBSDConfig >> commonCompilerFlags [
	"avoid premature optimization. push this decision down lower if it is needed at all"
	^{'-m32'}

]

{ #category : #'compiler flags' }
SqueakBSDConfig >> compilerFlagsAssert [

	^ {
		'-g3'. 
		'-O0'. 
		'-msse2'. 
		'-D_GNU_SOURCE'. 
		'-DITIMER_HEARTBEAT=1'. 
		'-DNO_VM_PROFILE=1'. 
		'-DDEBUGVM=1' }
]

{ #category : #'compiler flags' }
SqueakBSDConfig >> compilerFlagsDebug [

	^ {
		'-g3'. 
		'-O0'. 
		'-msse2'. 
		'-D_GNU_SOURCE'. 
		'-DITIMER_HEARTBEAT=1'. 
		'-DNO_VM_PROFILE=1'. 
		'-DDEBUGVM=1' }
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> coreSourcesBuild [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'cointerp.c'
		)
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> coreSourcesBuildAssert [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> coreSourcesBuildAssertITimerHeartbeat [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> coreSourcesBuildDebug [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> coreSourcesBuildDebugITimerHeartbeat [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> coreSourcesBuildITimerHeartbeat [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> coreSourcesBuildMultiThreaded [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'cointerpmt.c'
		)
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> coreSourcesBuildMultiThreadedAssert [
	^self coreSourcesBuildMultiThreaded	
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> coreSourcesBuildMultiThreadedDebug [
	^self coreSourcesBuildMultiThreaded	
]

{ #category : #plugins }
SqueakBSDConfig >> defaultExternalPlugins [
" tty 2014.06.10  cut-n-paste from Cog/build.linux32x86/newspeak.cog.spur/build/plugins.ext"
	^ #(B3DAcceleratorPlugin 
		BochsIA32Plugin 
	      ThreadedFFIPlugin    "moduleName->SqueakFFIPrims "
		"FFIPlugin"                   "moduleName->SqueakFFIPrims "
		SqueakSSLPlugin       "moduleName->SqueakSSL" 
		LocalePlugin 
		UnixOSProcessPlugin 
		UUIDPlugin)


"N.B. Regarding ThreadedFFIPlugin and FFIPlugin from eem:

Use  ThreadedFFIPlugin.  The FFIPlugin is obsolete (it requires assembler support files, and is non-reentrant).  This should generate in src/plugins/SqueakFFIPrims/{SqueakFFIPrims.c,ARM32FFIPlugin.c,IA32FFIPlugin.c} and you should compile only src/plugins/SqueakFFIPrims/SqueakFFIPrims.c.  src/plugins/SqueakFFIPrims/SqueakFFIPrims.c is a simple wrapper that includes ARM32FFIPlugin.c or IA32FFIPlugin.c as appropriate (and others can be added as they are developed).


"
]

{ #category : #plugins }
SqueakBSDConfig >> defaultInternalPlugins [
" N.B. THESE MAY BE WILDLY INAPPROPRIATE FOR BSD. cut-n-pasted from Linux32x86Config.
   N.B. moduleName->XYZ means XYZ appears in the GNU-Build's plugins.int/ext. However, Smalltalk requires the class name.
                                 XYZSmalltalkClass  moduleName->XYZ as it appears in plugins.int/ext
"
	^ #(
	    ADPCMCodecPlugin
    AsynchFilePlugin
    BalloonEnginePlugin "moduleName -->B2DPlugin"
    BitBltSimulation        "moduleName->BitBltPlugin"
    BMPReadWriterPlugin
    CroquetPlugin
    DeflatePlugin               "moduleName->ZipPlugin"
    DropPlugin
    DSAPlugin                    "moduleName->DSAPrims"
    FFTPlugin
    FileCopyPlugin
    FilePlugin
    FloatArrayPlugin
    FloatMathPlugin
    IA32ABIPlugin             "moduleName->IA32ABI"
    InflatePlugin               "moduleName->ZipPlugin"
    JoystickTabletPlugin
    JPEGReaderPlugin
    JPEGReadWriter2Plugin
    KlattSynthesizerPlugin  "moduleName->Klatt"
    LargeIntegersPlugin      "moduleName->LargeIntegers"
    Matrix2x3Plugin
    MIDIPlugin
    MiscPrimitivePlugin
    Mpeg3Plugin
    RePlugin
    SecurityPlugin
    SerialPlugin
    SocketPlugin
    SoundCodecPlugin        "moduleName->SoundCodecPrims"
    SoundGenerationPlugin
    SoundPlugin
    StarSqueakPlugin
    SurfacePlugin
    VMProfileLinuxSupportPlugin)
]

{ #category : #cmake }
SqueakBSDConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirBSD32x86
]

{ #category : #cmake }
SqueakBSDConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
SqueakBSDConfig >> executableName [
	"AbstractBaseClass configurations are not meant to be executable"
	^ self vmIShouldNotBeHereExecutableName
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> externalPluginsBuild [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> externalPluginsBuildAssert [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> externalPluginsBuildAssertITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> externalPluginsBuildDebug [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> externalPluginsBuildDebugITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> externalPluginsBuildITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> externalPluginsBuildMultiThreaded [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> externalPluginsBuildMultiThreadedAssert [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> externalPluginsBuildMultiThreadedDebug [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraPluginSettingsBuild: maker [
	maker isExternal ifTrue: [
		"copy lib to results dir "
		maker set: 'LIBRARY_OUTPUT_PATH' to: '${outputDir}' 
	].

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraPluginSettingsBuildAssert: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraPluginSettingsBuildAssertITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraPluginSettingsBuildDebug: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraPluginSettingsBuildDebugITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraPluginSettingsBuildITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraPluginSettingsBuildMultiThreaded: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraPluginSettingsBuildMultiThreadedAssert: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraPluginSettingsBuildMultiThreadedDebug: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraVMSettingsBuild: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettingsBuild:'"
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraVMSettingsBuildAssert: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraVMSettingsBuildAssertITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraVMSettingsBuildDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraVMSettingsBuildDebugITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraVMSettingsBuildITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraVMSettingsBuildMultiThreaded: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraVMSettingsBuildMultiThreadedAssert: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> extraVMSettingsBuildMultiThreadedDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> internalPluginsBuildAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> internalPluginsBuildAssertITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> internalPluginsBuildDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> internalPluginsBuildDebugITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> internalPluginsBuildITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> internalPluginsBuildMultiThreaded [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> internalPluginsBuildMultiThreadedAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> internalPluginsBuildMultiThreadedDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> postBuildActionsBuild: gen [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActionsBuild:'"
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> postBuildActionsBuildAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> postBuildActionsBuildAssertITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> postBuildActionsBuildDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> postBuildActionsBuildDebugITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> postBuildActionsBuildITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> postBuildActionsBuildMultiThreaded: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> postBuildActionsBuildMultiThreadedAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> postBuildActionsBuildMultiThreadedDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> preferredIncludesBuild [
"SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'"
	^ #( )

	

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> preferredIncludesBuildAssert [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> preferredIncludesBuildAssertITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> preferredIncludesBuildDebug [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> preferredIncludesBuildDebugITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> preferredIncludesBuildITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> preferredIncludesBuildMultiThreaded [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> preferredIncludesBuildMultiThreadedAssert [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> preferredIncludesBuildMultiThreadedDebug [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [
	"do nothing (so far) on Unix.
	
	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystemBuild:'
	"
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsBuild: aMaker [
	self flag:'tty'. "assume this is correct for BSD. it may not be"
	aMaker set: 'CMAKE_C_COMPILER' to: '/usr/bin/gcc'.
	aMaker set: 'CMAKE_CXX_COMPILER' to: '/usr/bin/g++'.

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsBuildAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsBuildDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsBuildMultiThreaded: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> setGlobalOptionsBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> standardIncludesBuild [ 
	^#()
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> standardIncludesBuildAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> standardIncludesBuildAssertITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> standardIncludesBuildDebug [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> standardIncludesBuildDebugITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> standardIncludesBuildITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> standardIncludesBuildMultiThreaded [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> standardIncludesBuildMultiThreadedAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakBSDConfig >> standardIncludesBuildMultiThreadedDebug [ 
	^ self standardIncludesBuild
]
