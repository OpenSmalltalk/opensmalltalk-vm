"
A Linux64x86w32BitConfig is an Abstract base class that provides common information for my subclasses.
I am not meant to be built.

I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakLinux64x86w32CompatBuilder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	enableMessageTracking: true;
	generateByTemplate.



HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp



"
Class {
	#name : #Linux64x64Config,
	#superclass : #SqueakUnixConfig,
	#category : #'CMakeVMMakerSqueak-Linux64x64'
}

{ #category : #cmake }
Linux64x64Config >> availableBuildTypes [
 	 ^SqueakCMakeVMMakerAbstractBuilder  default  noBuildTypes
"

subclasses should use

  ^super allBuildTypes copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   "
	

]

{ #category : #'cmake buildType redirects' }
Linux64x64Config >> coreSourcesBuild [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #'cmake buildType redirects' }
Linux64x64Config >> coreSourcesBuildMultiThreaded [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'cointerpmt.c'
		)
]

{ #category : #plugins }
Linux64x64Config >> defaultExternalPlugins [
	^ #(
		B3DAcceleratorPlugin
		ThreadedIA32FFIPlugin "SqueakFFIPrims"
		"UUIDPlugin"
		"UnixOSProcessPlugin ?? "	
		JPEGReaderPlugin 
		JPEGReadWriter2Plugin 			
		RePlugin
		InternetConfigPlugin
	)

"debug"
]

{ #category : #plugins }
Linux64x64Config >> defaultInternalPlugins [
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
Linux64x64Config >> dirBuildPlatform [
	^self dirLinux64x64
]

{ #category : #cmake }
Linux64x64Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
Linux64x64Config >> executableName [
	"AbstractBaseClass configurations are not meant to be executable"
	^ self vmIShouldNotBeHereExecutableName
]

{ #category : #compiling }
Linux64x64Config >> externalLibraries [
	^#(

			'uuid'  ""
			 'ssl'  ""
			 'crypto' ""
			 'm'      	"C math library"
			 'dl'      "dynamic linking library"
			 'pthread' "POSIX threads library"
			 'SM'   "session management library for X11"
			 'ICE'   "ICE is the Inter Client Exchange protocol, part of X11"
			 'GL'    "libGL implements the GLX interface as well as the main OpenGL API entrypoints"
			 'X11'
			 'nsl'    "network services library"
		)
				
]

{ #category : #'cmake buildType redirects' }
Linux64x64Config >> externalPluginsBuild [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
Linux64x64Config >> extraPluginSettingsBuild: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'extraPluginSettingsBuild:'"
	(aMaker config enabledebugmessages)
		ifTrue:[	
			aMaker config templates 
				addLast: ((CMakeMessage new) message: (self class name), ' extraPluginSettingsBuild:' )].

	aMaker isExternal 
		ifTrue:[aMaker templates addLast:((CMakeSet new) variable:'LIBRARY_OUTPUT_PATH' value:'${outputDir}')].

]

{ #category : #'cmake buildType redirects' }
Linux64x64Config >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
Linux64x64Config >> linkerFlagsBuild [
	^#(	'-Wl'
            '-z'
            'now'
	   ) 

]

{ #category : #'cmake buildType redirects' }
Linux64x64Config >> preferredIncludesBuild [
	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: (self class name), ' preferredIncludesBuild' )
	].
	templates
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${targetPlatform}/plugins/B3DAcceleratorPlugin')).

	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_PATH =  ${CMAKE_INCLUDE_PATH}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_SYSTEM_INCLUDE_PATH =  ${CMAKE_SYSTEM_INCLUDE_PATH}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES = ${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES =  ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_FIND_ROOT_PATH_MODE_INCLUDE =  ${CMAKE_FIND_ROOT_PATH_MODE_INCLUDE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_FIND_ROOT_PATH_MODE_INCLUDE =  ${CMAKE_INCLUDE_CURRENT_DIR}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_CURRENT_DIR_IN_INTERFACE =  ${CMAKE_INCLUDE_CURRENT_DIR_IN_INTERFACE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_DIRECTORIES_BEFORE =  ${CMAKE_INCLUDE_DIRECTORIES_BEFORE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE =  ${CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE}' )
	].
]
