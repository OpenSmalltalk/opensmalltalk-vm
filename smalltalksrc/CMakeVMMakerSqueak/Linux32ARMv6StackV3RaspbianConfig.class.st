"
This is a concrete class which generates a StackVM for Raspbian (debian on RaspberryPi).

I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakLinux32ARMv6Builder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp


"
Class {
	#name : #Linux32ARMv6StackV3RaspbianConfig,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32ARMv6'
}

{ #category : #'source generation' }
Linux32ARMv6StackV3RaspbianConfig >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #'plugin extra rules' }
Linux32ARMv6StackV3RaspbianConfig >> configureBitBltSimulation: maker [
	"extra rules for BitBltSimulation"

	maker includeDirectories: '${pluginCross}'.

	maker addCrossSources: #(
		'BitBltGeneric.c'
		'BitBltDispatch.c'
	).
	
]

{ #category : #plugins }
Linux32ARMv6StackV3RaspbianConfig >> defaultExternalPlugins [
	self flag:'tty'. "InternetConfigPlugin not available default svn co of Cog for unix. "
	^ #(
		B3DAcceleratorPlugin
		JPEGReaderPlugin 
		JPEGReadWriter2Plugin 			
		RePlugin
"		InternetConfigPlugin"
	)
]

{ #category : #plugins }
Linux32ARMv6StackV3RaspbianConfig >> defaultInternalPlugins [
" took from unixbuild/bld/plugins.int"
	^ #(
		ADPCMCodecPlugin 
		AsynchFilePlugin 
		BalloonEnginePlugin "B2DPlugin" 
		BitBltSimulation "BitBltPlugin"
		BMPReadWriterPlugin 
		CroquetPlugin 
		DeflatePlugin  "ZipPlugin"
		DropPlugin 
		DSAPlugin "DSAPrims" 
		FFTPlugin 
		FileCopyPlugin 
		FilePlugin 
		FloatArrayPlugin 
		FloatMathPlugin 
		JoystickTabletPlugin 
		KlattSynthesizerPlugin "Klatt"
		LargeIntegersPlugin "LargeIntegers"
		Matrix2x3Plugin 
		MIDIPlugin 
		MiscPrimitivePlugin 
		Mpeg3Plugin  	
		SecurityPlugin 
		SerialPlugin 
		SocketPlugin 
		SoundCodecPlugin "SoundCodecPrims"
		SoundGenerationPlugin 
		SoundPlugin 
		StarSqueakPlugin 
		SurfacePlugin	
		LocalePlugin
		)
]

{ #category : #cmake }
Linux32ARMv6StackV3RaspbianConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
Linux32ARMv6StackV3RaspbianConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirARMv6
]

{ #category : #cmake }
Linux32ARMv6StackV3RaspbianConfig >> excludeFromBuild [
	^true

]

{ #category : #cmake }
Linux32ARMv6StackV3RaspbianConfig >> executableName [
	^ self vmStackExecutableName
]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6StackV3RaspbianConfig >> extraPluginSettingsBuild: aMaker [

	aMaker isExternal ifTrue: [
		"copy lib to results dir "
		aMaker set: 'LIBRARY_OUTPUT_PATH' to: '${outputDir}' 
	].	
	
	aMaker set: #linkFlags toString: '${linkFlags}'

]

{ #category : #'source generation' }
Linux32ARMv6StackV3RaspbianConfig >> interpreterClass [
	^ StackInterpreter
]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6StackV3RaspbianConfig >> setExtraTargetPropertiesBuild: aMaker [

	"maker setTargetProperties: 'LINK_FLAGS ""'."
		
	aMaker puts: 'set_source_files_properties( ${srcVMDir}/cogit.c PROPERTIES 
		COMPILE_FLAGS "-O1 -fno-omit-frame-pointer -momit-leaf-frame-pointer")'.
		
	
	aMaker 
		cmd: 'set_source_files_properties'
		params: ' ${targetPlatform}/vm/sqUnixHeartbeat.c PROPERTIES 
		COMPILE_FLAGS "-O1 -fno-omit-frame-pointer"'.
						
	
	aMaker addExternalLibraries: 
		#(
			'm'  "math lib"
			'dl'  "dynamic loader"
			'pthread' "posix threads" 
		).
		
	aMaker set: 'EXECUTABLE_OUTPUT_PATH' toString: self outputDir fullName.
	self addVMDrivers: aMaker.
]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6StackV3RaspbianConfig >> setExtraTargetPropertiesBuildAssert: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6StackV3RaspbianConfig >> setExtraTargetPropertiesBuildAssertITimerHeartbeat: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6StackV3RaspbianConfig >> setExtraTargetPropertiesBuildDebug: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6StackV3RaspbianConfig >> setExtraTargetPropertiesBuildDebugITimerHeartbeat: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6StackV3RaspbianConfig >> setExtraTargetPropertiesBuildITimerHeartbeat: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6StackV3RaspbianConfig >> setExtraTargetPropertiesBuildMultiThreaded: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6StackV3RaspbianConfig >> setExtraTargetPropertiesBuildMultiThreadedAssert: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6StackV3RaspbianConfig >> setExtraTargetPropertiesBuildMultiThreadedDebug: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]
