"
A Linux32x86Config is a Squeak Compatibility Layer between the Pharo code in CMakeVMMaker and CMakeVMakerSqueak.

I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


I am not meant to be built.

SqueakLinux32x86Builder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp


"
Class {
	#name : #Linux32x86Config,
	#superclass : #SqueakUnixConfig,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'as yet unclassified' }
Linux32x86Config class >> initialize [
	isAbstractBaseClass:=true
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> addVMDriversBuild: aMaker [
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
Linux32x86Config >> addVMDriversBuildAssert: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> addVMDriversBuildAssertITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> addVMDriversBuildDebug: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> addVMDriversBuildDebugITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> addVMDriversBuildITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> addVMDriversBuildMultiThreaded: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> addVMDriversBuildMultiThreadedAssert: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> addVMDriversBuildMultiThreadedDebug: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake configuration' }
Linux32x86Config >> availableBuildTypes [
	 ^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes
"	subclasses should use

  ^super availableBuildTypes copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   "
	

]

{ #category : #'compiler flags' }
Linux32x86Config >> commonCompilerFlags [
	^{	}

]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> coreSourcesBuild [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'cointerp.c'
		)
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> coreSourcesBuildAssert [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> coreSourcesBuildAssertITimerHeartbeat [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> coreSourcesBuildDebug [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> coreSourcesBuildDebugITimerHeartbeat [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> coreSourcesBuildITimerHeartbeat [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> coreSourcesBuildMultiThreaded [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'cointerpmt.c'
		)
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> coreSourcesBuildMultiThreadedAssert [
	^self coreSourcesBuildMultiThreaded	
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> coreSourcesBuildMultiThreadedDebug [
	^self coreSourcesBuildMultiThreaded	
]

{ #category : #sources }
Linux32x86Config >> crossSources [ 
	^#(
			'sqHeapMap.c'
			'sqTicker.c'
			'sqExternalSemaphores.c'
			'sqNamedPrims.c'
			'sqVirtualMachine.c'
		)
]

{ #category : #plugins }
Linux32x86Config >> defaultExternalPlugins [
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
Linux32x86Config >> defaultInternalPlugins [
" tty 2014.06.10  cut-n-paste from Cog/build.linux32x86/newspeak.cog.spur/build/plugins.int
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
   " InflatePlugin"               "moduleName->ZipPlugin"   "already included with the DeflatePlugin"
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
Linux32x86Config >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x86
]

{ #category : #cmake }
Linux32x86Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build"
	^true
]

{ #category : #cmake }
Linux32x86Config >> executableName [
	"AbstractBaseClass configurations are not meant to be executable"
	^ self vmIShouldNotBeHereExecutableName
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuild [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildAssert [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildAssertITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildDebug [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildDebugITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildMultiThreaded [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildMultiThreadedAssert [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildMultiThreadedDebug [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraPluginSettingsBuild: maker [
	maker isExternal ifTrue: [
		"copy lib to results dir "
		maker set: 'LIBRARY_OUTPUT_PATH' to: '${outputDir}' 
	].

]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraPluginSettingsBuildAssert: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraPluginSettingsBuildAssertITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraPluginSettingsBuildDebug: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraPluginSettingsBuildDebugITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraPluginSettingsBuildITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraPluginSettingsBuildMultiThreaded: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraPluginSettingsBuildMultiThreadedAssert: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraPluginSettingsBuildMultiThreadedDebug: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraVMSettingsBuild: aMaker [
	| versionC |
	"self generateConfigH.   supplanted by new auto generate of config"
	
	"add a generated version.c"
	
	versionC := 'version.c'.
	
	aMaker cmd: 'add_custom_command' params: 'OUTPUT ',
		versionC , '
		COMMAND ${platformsDir}/unix/config/verstamp ',versionC,' gcc
		COMMENT "Generating version.c"
	'.
	
	
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraVMSettingsBuildAssert: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraVMSettingsBuildAssertITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraVMSettingsBuildDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraVMSettingsBuildDebugITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraVMSettingsBuildITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraVMSettingsBuildMultiThreaded: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraVMSettingsBuildMultiThreadedAssert: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> extraVMSettingsBuildMultiThreadedDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildAssertITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildDebugITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildMultiThreaded [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildMultiThreadedAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildMultiThreadedDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuild [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^ { 
		'-Wl'
           . '-z'
           . 'now'

	   }

]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildAssert [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildAssertITimerHeartbeat [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildDebug [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildDebugITimerHeartbeat [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildITimerHeartbeat [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildMultiThreaded [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildMultiThreadedAssert [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildMultiThreadedDebug [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> linkFlagsBuild [
	"Answer array of libraries to link to
	SystemNavigation default browseMethodsWhoseNamesContain: 'libsBuild'"
	^ { 
		'-lpthread'
           . '-luuid'
	   }
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> linkFlagsBuildAssert [
	^self linkFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> linkFlagsBuildAssertITimerHeartbeat [
	^self linkFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> linkFlagsBuildDebug [
	^self linkFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> linkFlagsBuildDebugITimerHeartbeat [
	^self linkFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> linkFlagsBuildITimerHeartbeat [
	^self linkFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> linkFlagsBuildMultiThreaded [
	^self linkFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> linkFlagsBuildMultiThreadedAssert [
	^self linkFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> linkFlagsBuildMultiThreadedDebug [
	^self linkFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuild: gen [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActionsBuild:'"
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildAssertITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildDebugITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildMultiThreaded: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildMultiThreadedAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildMultiThreadedDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuild [
	self flag:'tty'. "pharo does not support newspeak or sista., yet sets this in CogUnixConfig. Is this appropriate here? Revisit when coding newspeak etc"
	^ #( '${targetPlatform}/plugins/B3DAcceleratorPlugin')

	

"SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'"
	

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildAssert [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildAssertITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildDebug [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildDebugITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildMultiThreaded [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildMultiThreadedAssert [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildMultiThreadedDebug [
	^self preferredIncludesBuild

]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuild: aMaker [
	self flag:'tty'. "I am nervous about this method up here in this class, but pharo has it in CogUnixConfig, so using as is for now"

	aMaker setTargetProperties: 'LINK_FLAGS "-m32"'.
		
	aMaker puts: 'set_source_files_properties( ${srcVMDir}/cogit.c PROPERTIES 
		COMPILE_FLAGS "-O1 -fno-omit-frame-pointer -momit-leaf-frame-pointer -mno-rtd -mno-accumulate-outgoing-args")'.
		
	
	aMaker 
		cmd: 'set_source_files_properties'
		params: ' ${targetPlatform}/vm/sqUnixHeartbeat.c PROPERTIES 
		COMPILE_FLAGS "-O1 -fno-omit-frame-pointer -mno-rtd -mno-accumulate-outgoing-args"'.
	aMaker
		cmd:'set_target_properties'
		params: '${_name} PROPERTIES LINK_FLAGS "-undefined gl"'.


	aMaker addExternalLibraries: 
		#(
			'uuid'  ""
			'ssl'  ""
			'crypto' ""
			'm'  
			'dl' 
			'pthread' 
		).
					

	aMaker set: 'EXECUTABLE_OUTPUT_PATH' toString: self outputDir fullName.
	self addVMDrivers: aMaker.
]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildAssert: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildAssertITimerHeartbeat: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildDebug: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildDebugITimerHeartbeat: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildITimerHeartbeat: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildMultiThreaded: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildMultiThreadedAssert: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildMultiThreadedDebug: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystemBuild:'"
"
	aMaker set: 'CMAKE_C_COMPILER' to: '/usr/bin/gcc'.
	aMaker set: 'CMAKE_CXX_COMPILER' to: '/usr/bin/g++'.
"
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuild: aMaker [
	"do nothing (so far) on Unix.
	
	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsBuild:'
	"

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildMultiThreaded: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuild [ 
	^#()
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildAssertITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildDebug [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildDebugITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildMultiThreaded [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildMultiThreadedAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildMultiThreadedDebug [ 
	^ self standardIncludesBuild
]
